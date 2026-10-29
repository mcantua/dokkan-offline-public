#!/usr/bin/env bash
# Own GitHub-hosted Ubuntu emulator only. No personal device, account or release key.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORK="$ROOT/unit-creator/cloud-ui/android-work"
SDK="$ROOT/downloads/android-sdk"
mkdir -p "$WORK/evidence" "$WORK/avd" "$WORK/android-user" "$WORK/emulator-user" "$ROOT/unit-creator/apk/assets"
export ANDROID_SDK_ROOT="$SDK" ANDROID_HOME="$SDK"
export ANDROID_AVD_HOME="$WORK/avd" ANDROID_USER_HOME="$WORK/android-user" ANDROID_EMULATOR_HOME="$WORK/emulator-user"
export UC_ANDROID_EVIDENCE="$WORK/evidence" UC_ADB="$SDK/platform-tools/adb"
export UC_NATIVE_TOOLS="$ROOT/downloads/unit-creator-java-tools"
test -r /dev/kvm && test -w /dev/kvm || { echo 'Hosted KVM unavailable; no software/desktop-browser substitute' >&2; exit 1; }
python3 "$ROOT/unit-creator/tools/setup-android-tools.py" --emulator
# Check host loader/runtime dependencies before reconstructing DBs or building
# an APK. Keep the actual loader diagnostic if this disposable host is missing one.
if ! "$SDK/emulator/emulator" -version > "$WORK/evidence/emulator-version.txt" 2>&1; then
  cat "$WORK/evidence/emulator-version.txt" >&2
  ldd "$SDK/emulator/qemu/linux-x86_64/qemu-system-x86_64" >&2 || true
  exit 1
fi
python3 - "$WORK" "$SDK" <<'PY'
import json,pathlib,subprocess,sys
work,sdk=map(pathlib.Path,sys.argv[1:]);device=work/'avd/UnitCreatorCloud.avd';device.mkdir()
(work/'avd/UnitCreatorCloud.ini').write_text('avd.ini.encoding=UTF-8\npath='+str(device)+'\ntarget=android-35\n')
(device/'config.ini').write_text('AvdId=UnitCreatorCloud\navd.ini.encoding=UTF-8\nabi.type=x86_64\ntag.id=google_apis\nhw.cpu.arch=x86_64\nhw.cpu.ncore=2\nhw.ramSize=3072\nhw.gpu.enabled=yes\nhw.gpu.mode=swiftshader\nhw.lcd.width=1080\nhw.lcd.height=2340\nhw.lcd.density=420\nhw.keyboard=yes\ndisk.dataPartition.size=3G\nimage.sysdir.1='+str(sdk/'system-images/android-35/google_apis/x86_64')+'\n')
report={'scope':'Owned ephemeral GitHub-hosted API35 x86_64 emulator; no personal phone/account','source_commit':subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),'node':subprocess.check_output(['node','--version'],text=True).strip(),'emulator':(work/'evidence/emulator-version.txt').read_text().splitlines()[:3],'SDK35':'official SHA256-pinned','data':'Reconstructed actual committed browser snapshots, not byte-identical original DBs'}
(work/'evidence/toolchain.json').write_text(json.dumps(report,indent=2)+'\n')
PY
OWNED_PID=""
cleanup() { if [[ -n "$OWNED_PID" ]]; then kill "$OWNED_PID" >/dev/null 2>&1 || true; wait "$OWNED_PID" 2>/dev/null || true; fi; }
trap cleanup EXIT
"$SDK/emulator/emulator" -avd UnitCreatorCloud -port 5554 -accel on -no-window -no-audio -no-metrics -no-boot-anim -no-snapshot -gpu swiftshader -camera-back none -camera-front none > "$WORK/evidence/emulator.log" 2>&1 &
OWNED_PID=$!
for ((i=0;i<180;i++)); do
  kill -0 "$OWNED_PID" 2>/dev/null || { tail -80 "$WORK/evidence/emulator.log" >&2; echo 'Owned Android emulator exited before boot' >&2; exit 1; }
  if [[ "$("$UC_ADB" -s emulator-5554 shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ]]; then break; fi
  if ((i==179)); then tail -80 "$WORK/evidence/emulator.log" >&2; echo 'Owned Android emulator did not boot' >&2; exit 1; fi
  sleep 2
done
"$UC_ADB" -s emulator-5554 shell input keyevent 82
python3 "$ROOT/unit-creator/tools/setup-smali.py"
python3 "$ROOT/unit-creator/tools/setup-native-tools.py" --java-only
python3 "$ROOT/unit-creator/cloud-ui/reconstruct-data.py" --output "$ROOT/unit-creator/apk/assets" --report "$WORK/evidence/data-provenance.json"
export UC_CLOUD_RECONSTRUCTED_DATA_REPORT="$WORK/evidence/data-provenance.json"
# The native resource packager uses Pillow for the owned launcher artwork.
# Hosted images do not necessarily contain this local build dependency.
python3 -m pip install --disable-pip-version-check --only-binary=:all: Pillow==12.3.0
python3 "$ROOT/unit-creator/tools/build-development.py"
cp "$ROOT/unit-creator/out/development-android-check.json" "$WORK/evidence/package.json"
"$UC_ADB" -s emulator-5554 install "$ROOT/unit-creator/out/Dokkan-Unit-Creator-Development-2.36.3.apk"
# Managed permission on this disposable app only; permission-dialog touch is explicitly unverified.
"$UC_ADB" -s emulator-5554 shell appops set com.dokkanunitcreator.development MANAGE_EXTERNAL_STORAGE allow
connect_webview() {
  local socket="" pid=""
  for ((j=0;j<90;j++)); do
    pid="$("$UC_ADB" -s emulator-5554 shell pidof com.dokkanunitcreator.development | tr -d '\r')"
    if [[ "$pid" =~ ^[0-9]+$ ]] && "$UC_ADB" -s emulator-5554 shell cat /proc/net/unix | tr -d '\r' | rg -q "@webview_devtools_remote_${pid}$"; then socket="webview_devtools_remote_$pid"; fi
    if [[ -n "$socket" ]]; then break; fi
    sleep 1
  done
  [[ "$socket" =~ ^webview_devtools_remote_[0-9]+$ ]] || { echo 'Actual app WebView debugger unavailable' >&2; return 1; }
  "$UC_ADB" -s emulator-5554 forward tcp:9222 "localabstract:$socket"
}
"$UC_ADB" -s emulator-5554 shell am start -W -n com.dokkanunitcreator.development/com.personal.aihub.CreatorActivity
connect_webview
node "$ROOT/unit-creator/cloud-ui/android-check.mjs" create
"$UC_ADB" -s emulator-5554 shell am force-stop com.dokkanunitcreator.development
"$UC_ADB" -s emulator-5554 forward --remove tcp:9222
"$UC_ADB" -s emulator-5554 shell am start -W -n com.dokkanunitcreator.development/com.personal.aihub.CreatorActivity
connect_webview
node "$ROOT/unit-creator/cloud-ui/android-check.mjs" reopen
python3 "$ROOT/unit-creator/tools/setup-android-tools.py" --ndk
python3 "$ROOT/offline-dokkan/mobile/setup-sqlite.py"
bash "$ROOT/offline-dokkan/mobile/android/build-native.sh"
bash "$ROOT/offline-dokkan/mobile/android/build-host.sh"
"$UC_ADB" -s emulator-5554 install "$ROOT/offline-dokkan/mobile/android/build/Offline-Dokkan-Save-Manager-development.apk"
python3 "$ROOT/offline-dokkan/mobile/android/cloud-check.py"
cp "$ROOT/offline-dokkan/mobile/android/build/verification.json" "$WORK/evidence/offline-package.json"
echo 'Actual hosted Android launch/Create/save/force-stop/reopen check passed.'
