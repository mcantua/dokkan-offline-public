#!/bin/bash
# Builds only the data-free own-app development save-manager host, not a patched Dokkan game.
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
REPO=$(cd "$HERE/../../.." && pwd)
SDK=${OD_SDK_ROOT:-$REPO/downloads/android-sdk}
BT="$SDK/build-tools/android-15"
PLATFORM="$SDK/platforms/android-35/android.jar"
SIGNING="$REPO/unit-creator/out/development-signing.jks"
PASSWORD_FILE="$REPO/unit-creator/out/.development-signing-password"
OUT="$HERE/build"
NATIVE=${OD_ANDROID_BUILD:-$REPO/offline-dokkan/adapter/build/android-native}
CREATOR_SITE="$REPO/offline-dokkan/creator-ui/site"
for TOOL in "$BT/aapt2" "$BT/d8" "$BT/zipalign" "$PLATFORM" "$BT/lib/apksigner.jar" "$SIGNING" "$PASSWORD_FILE"; do
  test -f "$TOOL" || { echo 'Missing provisioned SDK/tool or shared private development identity.' >&2; exit 1; }
done
mkdir -p "$OUT"
python3 "$REPO/offline-dokkan/creator-ui/build.py"
WORK=$(mktemp -d "$OUT/.package-XXXXXX")
trap 'rm -rf "$WORK"' EXIT
for ABI in arm64-v8a x86_64; do test -f "$NATIVE/$ABI/libodbridge.so" || { echo 'Build the NDK engine first.' >&2; exit 1; }; done
SOURCE_PIN=$(python3 - "$HERE" "$NATIVE" <<'PY'
import hashlib,json,pathlib,subprocess,sys
here,native=map(pathlib.Path,sys.argv[1:]);current=subprocess.check_output(['python3',str(here/'native-fingerprint.py')],text=True).strip()
for abi in ('arm64-v8a','x86_64'):
 receipt=json.loads((native/abi/'native-build.json').read_text())
 if receipt['source_sha256']!=current or receipt['library_sha256']!=hashlib.sha256((native/abi/'libodbridge.so').read_bytes()).hexdigest():raise SystemExit('Native engine changed or is stale; relink current source before packaging.')
print(current)
PY
)
mkdir -p "$WORK/classes" "$WORK/dex"
"$REPO/unit-creator/tools/javac" --release 8 -Xlint:-options -cp "$PLATFORM" -d "$WORK/classes" \
  "$REPO/offline-dokkan/adapter/android/com/personal/offlinedokkan/OfflineCore.java" \
  "$HERE/com/personal/offlinedokkan/"*.java
"$REPO/unit-creator/tools/jar" cf "$WORK/classes.jar" -C "$WORK/classes" .
"$BT/d8" --min-api 26 --lib "$PLATFORM" --output "$WORK/dex" "$WORK/classes.jar"
"$BT/aapt2" link -o "$WORK/resources.apk" -I "$PLATFORM" --manifest "$HERE/AndroidManifest.xml" \
  --min-sdk-version 26 --target-sdk-version 35 --version-code 1 --version-name 0.1.0
python3 - "$WORK" "$NATIVE" "$CREATOR_SITE" <<'PY'
import hashlib,json,pathlib,sys,zipfile
work,native,site=map(pathlib.Path,sys.argv[1:])
manifest=json.loads((site/'ui-manifest.json').read_text())
assert manifest['gameDataIncluded'] is False
files=manifest['files']
assert set(files)=={p.relative_to(site).as_posix() for p in site.rglob('*') if p.is_file() and p.name!='ui-manifest.json'}
with zipfile.ZipFile(work/'resources.apk') as src,zipfile.ZipFile(work/'unsigned.apk','w') as out:
 for entry in src.infolist():out.writestr(entry,src.read(entry))
 def put(name,data):
  entry=zipfile.ZipInfo(name,(1980,1,1,0,0,0));entry.compress_type=zipfile.ZIP_STORED;out.writestr(entry,data)
 put('classes.dex',(work/'dex/classes.dex').read_bytes())
 for abi in ('arm64-v8a','x86_64'):put('lib/'+abi+'/libodbridge.so',(native/abi/'libodbridge.so').read_bytes())
 for name,digest in files.items():
  item=pathlib.PurePosixPath(name)
  assert not item.is_absolute() and '..' not in item.parts
  payload=(site/name).read_bytes();assert hashlib.sha256(payload).hexdigest()==digest
  put('assets/offline-creator/'+name,payload)
 put('assets/offline-creator/ui-manifest.json',(site/'ui-manifest.json').read_bytes())
 put('assets/THIRD-PARTY-NOTICES.txt',b'Own Offline Dokkan native save-manager development host.\nSQLite3.50.4 is public-domain upstream source: https://www.sqlite.org/copyright.html\nNo Bandai Namco app, master database, game assets, or private signing/game/AI keys are bundled.\n')
PY
"$BT/zipalign" -f -P 16 4 "$WORK/unsigned.apk" "$WORK/aligned.apk"
java -jar "$BT/lib/apksigner.jar" sign --ks "$SIGNING" --ks-key-alias unitcreator-development \
  --ks-pass "file:$PASSWORD_FILE" --out "$WORK/signed.apk" "$WORK/aligned.apk"
java -jar "$BT/lib/apksigner.jar" verify "$WORK/signed.apk"
"$BT/zipalign" -c -P 16 4 "$WORK/signed.apk"
test "$(python3 "$HERE/native-fingerprint.py")" = "$SOURCE_PIN" || { echo 'Native source changed during packaging; relink before publishing.' >&2; exit 1; }
python3 - "$WORK/signed.apk" "$OUT" "$SOURCE_PIN" <<'PY'
import hashlib,json,pathlib,sys,zipfile
apk,out=map(pathlib.Path,sys.argv[1:3])
with zipfile.ZipFile(apk) as z:
 names=z.namelist()
 assert 'classes.dex' in names and 'AndroidManifest.xml' in names
 assert 'assets/offline-creator/index.html' in names and 'assets/offline-creator/projection-tables.json' in names
 assert not any(n.startswith('assets/offline-creator/data/') for n in names)
 assert all('lib/'+a+'/libodbridge.so' in names for a in ('arm64-v8a','x86_64'))
 assert not any(n.lower().endswith(('.db','.jks','.p12','.ipa','.apk')) for n in names)
 assert not any('password' in n.lower() or 'signing' in n.lower() for n in names)
 ui_manifest_sha256=hashlib.sha256(z.read('assets/offline-creator/ui-manifest.json')).hexdigest()
receipt={'kind':'data-free native local-save-manager development candidate','version':'0.1.0','version_code':1,'abis':['arm64-v8a','x86_64'],'sha256':hashlib.sha256(apk.read_bytes()).hexdigest(),'native_source_sha256':sys.argv[3],'creator_ui_manifest_sha256':ui_manifest_sha256,'signature_and_zip_alignment_verified':True,'device_install_launch_verified':False,'playable_battles_verified':False}
(out/'verification.json').write_text(json.dumps(receipt,indent=2)+'\n')
apk.replace(out/'Offline-Dokkan-Save-Manager-development.apk')
print('Packaged data-free development APK. Signing/alignment checked; installation and game compatibility are unverified.')
PY
