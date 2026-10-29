#!/usr/bin/env bash
# Genuine hosted Xcode only; never Apple login, Tin's Mac, device install, or IPA generation.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CLOUD="$ROOT/unit-creator/cloud-ui"
WORK="$CLOUD/work"
TOOLS="$ROOT/downloads/unit-creator-cloud-tools"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode_27.1.app/Contents/Developer}"
test "$(uname -s)" = Darwin || { echo 'Requires an authorized hosted macOS runner' >&2; exit 1; }
mkdir -p "$WORK/evidence" "$TOOLS"
python3 - "$ROOT" <<'PY'
import json,pathlib,subprocess,sys
root=pathlib.Path(sys.argv[1]);work=root/'unit-creator/cloud-ui/work'
version=subprocess.check_output(['xcodebuild','-version'],text=True).strip()
sdk=subprocess.check_output(['xcrun','--sdk','iphonesimulator','--show-sdk-version'],text=True).strip()
if not version.startswith('Xcode 27.1\n') or sdk!='27.1': raise SystemExit('Genuine Xcode27.1 / simulator SDK27.1 required; no SDK mark substitution')
inventory=json.loads(subprocess.check_output(['xcrun','simctl','list','-j']))
(work/'evidence/toolchain.json').write_text(json.dumps({'source_commit':subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),'xcode':version,'sdk':sdk,'architecture':subprocess.check_output(['uname','-m'],text=True).strip(),'device_type':'com.apple.CoreSimulator.SimDeviceType.iPhone-Duo','runtime':'com.apple.CoreSimulator.SimRuntime.iOS-27-1','scope':'Hosted simulator only, no Apple credentials or physical phone access'},indent=2)+'\n')
types={t['identifier'] for t in inventory['devicetypes']};runtimes={r['identifier'] for r in inventory['runtimes'] if r.get('isAvailable')}
if 'com.apple.CoreSimulator.SimDeviceType.iPhone-Duo' not in types or 'com.apple.CoreSimulator.SimRuntime.iOS-27-1' not in runtimes: raise SystemExit('Genuine iPhone Duo type/iOS27.1 runtime unavailable; no ordinary-device substitution')
PY
python3 "$CLOUD/reconstruct-data.py" --output "$WORK/db" --report "$WORK/evidence/data-provenance.json"
python3 "$ROOT/offline-dokkan/creator-ui/build.py"
cp "$WORK/evidence/data-provenance.json" "$WORK/cloud-data-provenance.json"
python3 "$ROOT/offline-dokkan/mobile/setup-sqlite.py"
python3 - "$ROOT" <<'PY'
import importlib.util,pathlib,plistlib,subprocess,sys
root=pathlib.Path(sys.argv[1]);work=root/'unit-creator/cloud-ui/work'
spec=importlib.util.spec_from_file_location('web_build',root/'unit-creator/web/build.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
m.IOS_DB=work/'db';m.IOS=work/'site';m.build_ios() # Actual iPhone adapters, not standalone browser adapters.
arch=subprocess.check_output(['uname','-m'],text=True).strip()
if arch not in ('arm64','x86_64'): raise SystemExit('Unsupported hosted simulator architecture')
(work/'project.yml').write_text((work.parent/'project.yml').read_text().replace('__ARCH__',arch))
info={'CFBundleExecutable':'UnitCreator','CFBundleIdentifier':'com.dokkanunitcreator.cloudcheck','CFBundleName':'Unit Creator Cloud Check','CFBundleDisplayName':'Unit Creator Cloud Check','CFBundlePackageType':'APPL','CFBundleShortVersionString':'2.36.3','CFBundleVersion':'128','MinimumOSVersion':'16.4','UIDeviceFamily':[1,2],'UILaunchScreen':{},'UIUserInterfaceStyle':'Dark','UIViewControllerBasedStatusBarAppearance':True,'UIApplicationSceneManifest':{'UIApplicationSupportsMultipleScenes':False,'UISceneConfigurations':{'UIWindowSceneSessionRoleApplication':[{'UISceneConfigurationName':'Default','UISceneDelegateClassName':'SceneDelegate'}]}},'UISupportedInterfaceOrientations':['UIInterfaceOrientationPortrait','UIInterfaceOrientationLandscapeLeft','UIInterfaceOrientationLandscapeRight'],'NSAppTransportSecurity':{'NSAllowsLocalNetworking':True,'NSAllowsArbitraryLoads':True}}
(work/'Info.plist').write_bytes(plistlib.dumps(info))
offline=dict(info);offline.update(CFBundleExecutable='OfflineDokkanHost',CFBundleIdentifier='com.personaldokkan.offline.cloudcheck',CFBundleName='Offline Dokkan',CFBundleDisplayName='Offline Dokkan')
offline['UIApplicationSceneManifest']={'UIApplicationSupportsMultipleScenes':False,'UISceneConfigurations':{'UIWindowSceneSessionRoleApplication':[{'UISceneConfigurationName':'Default','UISceneDelegateClassName':'ODLocalScene'}]}}
(work/'OfflineInfo.plist').write_bytes(plistlib.dumps(offline))
PY
curl --fail --location --silent --show-error 'https://github.com/yonaskolb/XcodeGen/releases/download/2.46.0/xcodegen.zip' -o "$TOOLS/xcodegen.zip"
echo "4d9e34b62172d645eed6457cac13fc222569974098ef4ee9c3368bedf0196806  $TOOLS/xcodegen.zip" | shasum -a 256 -c -
mkdir -p "$TOOLS/xcodegen"; ditto -x -k "$TOOLS/xcodegen.zip" "$TOOLS/xcodegen"
XCODEGEN="$(find "$TOOLS/xcodegen" -type f -name xcodegen | head -1)"
test -n "$XCODEGEN" || { echo 'Pinned XcodeGen binary missing' >&2; exit 1; }
chmod +x "$XCODEGEN"
"$XCODEGEN" generate --spec "$WORK/project.yml" --project "$WORK"
OWNED_SIMULATOR=""
cleanup() {
  if [[ -n "$OWNED_SIMULATOR" ]]; then
    xcrun simctl shutdown "$OWNED_SIMULATOR" >/dev/null 2>&1 || true
    xcrun simctl delete "$OWNED_SIMULATOR" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT
xcrun simctl help > "$WORK/evidence/simctl-help.txt"
OWNED_SIMULATOR="$(xcrun simctl create "Unit Creator Duo check ${GITHUB_RUN_ID:-manual}" com.apple.CoreSimulator.SimDeviceType.iPhone-Duo com.apple.CoreSimulator.SimRuntime.iOS-27-1)"
[[ "$OWNED_SIMULATOR" =~ ^[0-9A-Fa-f-]{36}$ ]] || { OWNED_SIMULATOR=""; echo 'Invalid simulator UUID' >&2; exit 1; }
xcrun simctl boot "$OWNED_SIMULATOR"
xcrun simctl bootstatus "$OWNED_SIMULATOR" -b
xcrun simctl io "$OWNED_SIMULATOR" enumerate > "$WORK/evidence/duo-displays.txt"
xcodebuild test -project "$WORK/UnitCreatorCloud.xcodeproj" -scheme UnitCreatorCloud \
  -destination "platform=iOS Simulator,id=$OWNED_SIMULATOR" -parallel-testing-enabled NO \
  -derivedDataPath "$WORK/DerivedData" -resultBundlePath "$WORK/evidence/NativeCheck.xcresult" \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tee "$WORK/evidence/xcodebuild.log"
CONTAINER="$(xcrun simctl get_app_container "$OWNED_SIMULATOR" com.dokkanunitcreator.cloudcheck data)"
test -s "$CONTAINER/Library/cloud-native-check.json"
cp "$CONTAINER/Library/cloud-native-check.json" "$WORK/evidence/native-result.json"
cp "$CONTAINER/Library/cloud-native-window.png" "$WORK/evidence/native-window.png"
cp "$CONTAINER/Library/cloud-native-web.png" "$WORK/evidence/native-web.png"
cp "$CONTAINER/Library/standalone-file-check.json" "$WORK/evidence/standalone-file-check.json"
cp "$CONTAINER/Library/standalone-file.png" "$WORK/evidence/standalone-file.png"
OFFLINE_CONTAINER="$(xcrun simctl get_app_container "$OWNED_SIMULATOR" com.personaldokkan.offline.cloudcheck data)"
cp "$OFFLINE_CONTAINER/Library/offline-native-result.json" "$WORK/evidence/offline-native-result.json"
cp "$OFFLINE_CONTAINER/Library/offline-native-window.png" "$WORK/evidence/offline-native-window.png"
cp "$OFFLINE_CONTAINER/Library/offline-creator-result.json" "$WORK/evidence/offline-creator-result.json"
cp "$OFFLINE_CONTAINER/Library/offline-creator.png" "$WORK/evidence/offline-creator.png"
cp "$OFFLINE_CONTAINER/Library/offline-collection.png" "$WORK/evidence/offline-collection.png"
python3 - "$WORK/evidence/native-result.json" <<'PY'
import json,pathlib,sys
result=json.loads(pathlib.Path(sys.argv[1]).read_text())
assert result['geometry']['startup']=='ready' and result['geometry']['ios'] and result['geometry']['bridge']
assert result['native_file_roundtrip'] and all(n>1000 for n in result['native_card_counts'].values())
assert abs(result['geometry']['innerWidth']-result['windowWidth'])<=1
print('Genuine hosted native launch, both SQL snapshots, file round trip and initial Duo geometry passed.')
PY
