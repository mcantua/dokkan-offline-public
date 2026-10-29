#!/usr/bin/env bash
# Genuine Xcode27.1 device compile, after native tests pass. No Apple login/signing or phone install.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORK="$ROOT/unit-creator/cloud-ui/work"
test "$(xcrun --sdk iphoneos --show-sdk-version)" = 27.1 || { echo 'Actual iPhoneOS27.1 SDK required' >&2; exit 1; }
python3 - "$WORK" <<'PY'
import pathlib,plistlib,sys
work=pathlib.Path(sys.argv[1]);info=plistlib.loads((work/'Info.plist').read_bytes())
info.update(CFBundleExecutable='App',CFBundleIdentifier='com.dokkanunitcreator.ios',CFBundleName='Unit Creator',CFBundleDisplayName='Unit Creator')
(work/'DeviceInfo.plist').write_bytes(plistlib.dumps(info))
PY
xcodebuild build -project "$WORK/UnitCreatorCloud.xcodeproj" -target UnitCreator \
  -configuration Release -sdk iphoneos -arch arm64 \
  SYMROOT="$WORK/DeviceProducts" OBJROOT="$WORK/DeviceObjects" \
  PRODUCT_NAME=App EXECUTABLE_NAME=App PRODUCT_BUNDLE_IDENTIFIER=com.dokkanunitcreator.ios \
  INFOPLIST_FILE="$WORK/DeviceInfo.plist" CODE_SIGNING_ALLOWED=NO \
  2>&1 | tee "$WORK/evidence/device-build.log"
python3 - "$ROOT" "$WORK" <<'PY'
import hashlib,importlib.util,json,pathlib,plistlib,stat,subprocess,sys,zipfile
root,work=map(pathlib.Path,sys.argv[1:]);app=work/'DeviceProducts/Release-iphoneos/App.app'
spec=importlib.util.spec_from_file_location('macho',root/'unit-creator/ios-objc/macho_sdk.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
info=plistlib.loads((app/'Info.plist').read_bytes());sdk=m.sdk_version((app/'App').read_bytes())
if sdk!='27.1.0' or info.get('CFBundleIdentifier')!='com.dokkanunitcreator.ios' or info.get('CFBundleExecutable')!='App' or info.get('CFBundleShortVersionString')!='2.36.3' or info.get('CFBundleVersion')!='128':raise SystemExit('Genuine device candidate metadata/platform mismatch')
if info.get('DTSDKName')!='iphoneos27.1' or info.get('DTPlatformName')!='iphoneos':raise SystemExit('Device candidate is not built with actual iPhoneOS27.1')
archive=work/'evidence/UnitCreator-genuine-device-bootstrap.zip';files={}
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as out:
 for file in sorted(app.rglob('*')):
  rel=file.relative_to(app)
  if rel.parts[0]=='db' or rel.as_posix()=='cloud-data-provenance.json':continue
  if file.is_symlink():raise SystemExit('Unexpected device app symlink')
  if file.is_file():
   out.write(file,'Payload/App.app/'+rel.as_posix());files[rel.as_posix()]=hashlib.sha256(file.read_bytes()).hexdigest()
with zipfile.ZipFile(archive) as checked:
 if checked.testzip():raise SystemExit('Device bootstrap ZIP CRC failure')
native={name:hashlib.sha256((root/'unit-creator/ios-objc'/name).read_bytes()).hexdigest() for name in ['main.m','Host.m','Host.h','Player.m','Player.h']}
report={'source_commit':subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),'kind':'Genuine SDK device bootstrap, not a complete IPA until original local DBs are restored','version':'2.36.3','build':'128','bundle':'com.dokkanunitcreator.ios','actual_sdk':'iPhoneOS27.1','macho_sdk':sdk,'platform':'iOS device (2), arm64; not simulator','apple_signed':False,'physical_install_verified':False,'databases':'Omitted deliberately; root restores supplied original DBs locally, never uploads/commits raw DBs','archive':archive.name,'sha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'bytes':archive.stat().st_size,'native_source_sha256':native,'files':files}
(work/'evidence/genuine-device-bootstrap.json').write_text(json.dumps(report,indent=2)+'\n')
print('Genuine SDK27.1 arm64 device bootstrap checked; game databases omitted, Apple provisioning still required.')
PY
# Build our separate Offline save-manager product without the private cloud-fixture entry path.
python3 - "$WORK" <<'PY'
import pathlib,plistlib,sys
work=pathlib.Path(sys.argv[1]);info=plistlib.loads((work/'OfflineInfo.plist').read_bytes())
info.update(CFBundleExecutable='OfflineDokkan',CFBundleIdentifier='com.personal.offlinedokkan.ios',CFBundleName='Offline Dokkan',CFBundleDisplayName='Offline Dokkan Development',CFBundleShortVersionString='0.1.0',CFBundleVersion='1')
(work/'OfflineDeviceInfo.plist').write_bytes(plistlib.dumps(info))
PY
xcodebuild build -project "$WORK/UnitCreatorCloud.xcodeproj" -target OfflineDokkanHost \
  -configuration Release -sdk iphoneos -arch arm64 \
  SYMROOT="$WORK/OfflineDeviceProducts" OBJROOT="$WORK/OfflineDeviceObjects" \
  PRODUCT_NAME=OfflineDokkan EXECUTABLE_NAME=OfflineDokkan PRODUCT_BUNDLE_IDENTIFIER=com.personal.offlinedokkan.ios \
  INFOPLIST_FILE="$WORK/OfflineDeviceInfo.plist" CODE_SIGNING_ALLOWED=NO \
  GCC_PREPROCESSOR_DEFINITIONS='SQLITE_THREADSAFE=1 SQLITE_OMIT_LOAD_EXTENSION=1 SQLITE_DQS=0 OD_CLOUD_FIXTURES=0' \
  GCC_SYMBOLS_PRIVATE_EXTERN=YES 2>&1 | tee "$WORK/evidence/offline-device-build.log"
python3 - "$ROOT" "$WORK" <<'PY'
import hashlib,importlib.util,json,pathlib,plistlib,subprocess,sys,zipfile
root,work=map(pathlib.Path,sys.argv[1:]);app=work/'OfflineDeviceProducts/Release-iphoneos/OfflineDokkan.app'
spec=importlib.util.spec_from_file_location('macho',root/'unit-creator/ios-objc/macho_sdk.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
info=plistlib.loads((app/'Info.plist').read_bytes())
if m.sdk_version((app/'OfflineDokkan').read_bytes())!='27.1.0' or info.get('DTSDKName')!='iphoneos27.1' or info.get('CFBundleShortVersionString')!='0.1.0' or info.get('CFBundleVersion')!='1':raise SystemExit('Offline genuine device metadata mismatch')
archive=work/'evidence/Offline-Dokkan-Save-Manager-Development-0.1.0.ipa'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as out:
 for file in sorted(app.rglob('*')):
  rel=file.relative_to(app)
  if rel.parts[0]=='db' or rel.as_posix()=='cloud-data-provenance.json':continue
  if file.is_symlink():raise SystemExit('Unexpected product app symlink')
  if file.is_file():
   if file.suffix.lower() in ('.db','.sqlite','.sqlite3'):raise SystemExit('Game/player data cannot ship in Offline product')
   out.write(file,'Payload/OfflineDokkan.app/'+rel.as_posix())
with zipfile.ZipFile(archive) as checked:
 if checked.testzip():raise SystemExit('Offline data-free IPA CRC failure')
report={'scope':'Actual data-free own native local-save manager, not original game/battle app','source_commit':subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),'version':'0.1.0','build':'1','bundle':'com.personal.offlinedokkan.ios','actual_sdk':'iPhoneOS27.1','platform':'arm64 iOS device (2), universal iPhone/Duo','fixture_compile_flag':0,'contains_game_data':False,'apple_signed':False,'device_install_ready':False,'sha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'bytes':archive.stat().st_size,'pending':['Apple provisioning/signing','Device install/launch','Physical folding/touch/keyboard','Original game contracts/scenes/gameplay']}
(work/'evidence/offline-device-candidate.json').write_text(json.dumps(report,indent=2)+'\n')
print('Data-free Offline native device IPA compiled with actual SDK27.1; unsigned, Apple provisioning still required.')
PY
