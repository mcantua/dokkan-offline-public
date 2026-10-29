#!/bin/zsh
# Dokkan Unit Creator — sign, install and check the display on the iPhone Duo (run on the Mac).
#   tools/duo-device-test.sh <UnitCreator-x.y.z.ipa> [install|check]
#     install: sign with the Mac's Apple Development identity, install, launch, read the display log, screenshot
#     check:   (app already installed) relaunch, read the display log, screenshot the active display
# Output: evidence/<time>/ (display-log.jsonl, screenshot-*.png, run.log). Does not handle any password.
setopt nullglob; set -u
R="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -f "$R/../config/private.local" ]]; then
  set -a
  source "$R/../config/private.local"
  set +a
fi
DEV="${DUO_UDID:-00000000-0000000000000000}"
TEAM=P4NRE7Q8ZT; BID="com.dokkanunitcreator.ios.$TEAM"
IPA="${1:-}"; MODE="${2:-install}"
E="$R/evidence/$(date +%Y%m%d-%H%M%S)"; mkdir -p "$E"
exec > >(tee "$E/run.log") 2>&1
st(){ echo "=== $(date '+%I:%M:%S %p') $1"; echo "$1" > "$R/evidence/status.txt"; }
fail(){ st "FAILED: $1"; exit 1; }
W="$R/tmp-sign"; rm -rf "$W"; mkdir -p "$W"
if [[ $MODE == install ]]; then
  [[ -f "$IPA" ]] || fail "no ipa: $IPA"
  xcrun devicectl list devices 2>/dev/null | grep -q "$DEV" || fail "iPhone Duo not found: plug it in with a cable, unlock it and tap Trust"
  st "provisioning profile for $BID"
  (cd "$R/signing" && xcodebuild -project DokkanSigning.xcodeproj -scheme DokkanSigning -configuration Debug -sdk iphoneos \
     -destination "id=$DEV" -derivedDataPath "$R/signing/DerivedData" -allowProvisioningUpdates -allowProvisioningDeviceRegistration build -quiet) || \
  (cd "$R/signing" && xcodebuild -project DokkanSigning.xcodeproj -scheme DokkanSigning -configuration Debug -sdk iphoneos \
     -destination "generic/platform=iOS" -derivedDataPath "$R/signing/DerivedData" -allowProvisioningUpdates build -quiet) || fail "profile"
  PROF="$(ls "$R"/signing/DerivedData/Build/Products/Debug-iphoneos/*.app/embedded.mobileprovision "$R"/signing/build/Debug-iphoneos/*.app/embedded.mobileprovision 2>/dev/null | head -1)"
  [[ -f "$PROF" ]] || fail "no embedded.mobileprovision"
  st "signing"
  (cd "$W" && unzip -q "$IPA") || fail unzip
  APP="$(echo "$W"/Payload/*.app)"
  security cms -D -i "$PROF" > "$W/profile.plist"
  /usr/libexec/PlistBuddy -x -c "Print :Entitlements" "$W/profile.plist" > "$W/ent.plist"
  IDENT="$(security find-identity -v -p codesigning | awk '/Apple Development/{print $2; exit}')"
  /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BID" "$APP/Info.plist"
  cp "$PROF" "$APP/embedded.mobileprovision"
  rm -rf "$APP/_CodeSignature"
  codesign --force --sign "$IDENT" --entitlements "$W/ent.plist" --generate-entitlement-der "$APP" || fail codesign
  codesign --verify --strict "$APP" || fail verify
  st "installing"
  xcrun devicectl device install app --device "$DEV" "$APP" --timeout 600 || fail install
fi
st "launching"
xcrun devicectl device info displays --device "$DEV" > "$E/displays.txt" 2>&1
xcrun devicectl device process launch --device "$DEV" --terminate-existing "$BID" || st "launch failed (phone locked?)"
sleep 12
st "reading display log"
xcrun devicectl device copy from --device "$DEV" --domain-type appDataContainer --domain-identifier "$BID" \
  --source Library/display-log.jsonl --destination "$E/display-log.jsonl" || st "no display log yet"
for line in "${(@f)$(grep -n 'active' "$E/displays.txt")}"; do :; done
python3 - "$E" "$DEV" <<'PY'
import re, subprocess, sys
e, dev = sys.argv[1], sys.argv[2]
s = open(e + "/displays.txt").read()
for part in re.split(r'(?=▿ \d+:)', s):
    if '(active)' in part and 'integrated' in part:
        u = re.search(r'uniqueId: (\S+)', part).group(1); name = re.search(r'▿ \d+: (\S+)', part).group(1)
        subprocess.run(['xcrun', 'devicectl', 'device', 'capture', 'screenshot', '--device', dev, '--display-unique-id', u,
                        '--destination', f'{e}/screenshot-{name}.png'])
PY
rm -rf "$W"
st "DONE $E"
