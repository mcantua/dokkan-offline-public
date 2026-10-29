#!/usr/bin/env bash
# One hosted Duo simulator shot of the in-game Creator menu chrome.
# No release package, original game launch, or Finish suite.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CLOUD="$ROOT/unit-creator/cloud-ui"
WORK="$CLOUD/menu-shot-work"
TOOLS="$ROOT/downloads/unit-creator-cloud-tools"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode_27.1.app/Contents/Developer}"
test "$(uname -s)" = Darwin || { echo 'Requires an authorized hosted macOS runner' >&2; exit 1; }
test ! -e "$WORK" || { echo 'Existing menu-shot directory preserved; use a fresh hosted checkout' >&2; exit 1; }
mkdir -p "$WORK/evidence" "$TOOLS"
python3 "$ROOT/offline-dokkan/creator-ui/build.py"
python3 "$ROOT/offline-dokkan/mobile/setup-sqlite.py"
python3 - "$ROOT" <<'PY'
import json,pathlib,plistlib,subprocess,sys
root=pathlib.Path(sys.argv[1]);work=root/'unit-creator/cloud-ui/menu-shot-work'
version=subprocess.check_output(['xcodebuild','-version'],text=True).strip()
sdk=subprocess.check_output(['xcrun','--sdk','iphonesimulator','--show-sdk-version'],text=True).strip()
if not version.startswith('Xcode 27.1\n') or sdk!='27.1':raise SystemExit('Genuine Xcode27.1/simulator SDK27.1 required')
inventory=json.loads(subprocess.check_output(['xcrun','simctl','list','-j']))
if 'com.apple.CoreSimulator.SimDeviceType.iPhone-Duo' not in {v['identifier'] for v in inventory['devicetypes']} or 'com.apple.CoreSimulator.SimRuntime.iOS-27-1' not in {v['identifier'] for v in inventory['runtimes'] if v.get('isAvailable')}:raise SystemExit('Genuine hosted Duo/iOS27.1 runtime unavailable')
arch=subprocess.check_output(['uname','-m'],text=True).strip()
if arch not in ('arm64','x86_64'):raise SystemExit('Unsupported hosted simulator architecture')
base={'CODE_SIGNING_ALLOWED':'NO','CLANG_ENABLE_OBJC_ARC':'YES','IPHONEOS_DEPLOYMENT_TARGET':'16.4','TARGETED_DEVICE_FAMILY':'1,2','ONLY_ACTIVE_ARCH':'YES','ARCHS':arch}
native='../../../offline-dokkan/'
host_sources=[{'path':'../FinishOnlyHost.m'},{'path':native+'creator-ui/site','type':'folder','buildPhase':'resources'}]
host_sources += [{'path':native+'mobile/ios/'+name} for name in ['ODCreatorController.m','ODCreatorSession.m','ODBattleStore.m','ODBattleCoordinator.m']]
host_sources += [{'path':native+'adapter/ios'},{'path':native+'adapter/od_bridge.c'},{'path':native+'core','includes':['*.c','*.h'],'excludes':['od_cli.c','test_*.c','check_*.c']},{'path':native+'content/content.c'},{'path':native+'content/master_archive.c'},{'path':native+'content/asset_catalog.c'},{'path':'../../../downloads/sqlite-amalgamation/source/sqlite3.c'}]
own=root/'offline-dokkan/original-client'
host_sources += [{'path':'../../../'+str(p.relative_to(root))} for p in sorted(own.rglob('*')) if p.suffix in ('.c','.m')]
frameworks=['UIKit','WebKit','JavaScriptCore','Foundation','Security','Metal','CoreGraphics','QuartzCore']
setup=json.loads((own/'creator-tools/build-source.json').read_text())
if setup.get('schema')!=1 or setup['extra_objc_sources']!=['unit-creator/ios-objc/Host.m','unit-creator/ios-objc/Player.m']:
    raise SystemExit('Unexpected scoped Creator source inputs')
renames=setup['apply_defines_only_to_extra_sources']
flags=' '.join('-D'+k+'='+v for k,v in renames.items())
host_sources += [{'path':'../../../'+p,'compilerFlags':flags} for p in setup['extra_objc_sources']]
frameworks=list(dict.fromkeys(frameworks+setup['required_frameworks']))
host_settings={'PRODUCT_BUNDLE_IDENTIFIER':'com.personaldokkan.creatormenushot','PRODUCT_NAME':'CreatorMenuShot','INFOPLIST_FILE':'Info.plist','HEADER_SEARCH_PATHS':'$(SRCROOT)/../../../downloads/sqlite-amalgamation/source','GCC_PREPROCESSOR_DEFINITIONS':['$(inherited)','SQLITE_THREADSAFE=1','SQLITE_OMIT_LOAD_EXTENSION','SQLITE_DQS=0']}
targets={'CreatorMenuShot':{'type':'application','platform':'iOS','sources':host_sources,'settings':{'base':host_settings},'dependencies':[{'sdk':s+'.framework'} for s in frameworks]+[{'sdk':'libz.tbd'}]},'CreatorMenuShotTests':{'type':'bundle.unit-test','platform':'iOS','sources':[{'path':'../MenuShotTests'}],'settings':{'base':{'PRODUCT_BUNDLE_IDENTIFIER':'com.personaldokkan.creatormenushot.tests','GENERATE_INFOPLIST_FILE':'YES','TEST_HOST':'$(BUILT_PRODUCTS_DIR)/CreatorMenuShot.app/CreatorMenuShot','BUNDLE_LOADER':'$(TEST_HOST)'}},'dependencies':[{'target':'CreatorMenuShot'},{'sdk':'XCTest.framework'},{'sdk':'WebKit.framework'}]}}
project={'name':'CreatorMenuShot','options':{'minimumXcodeGenVersion':'2.46.0','deploymentTarget':{'iOS':'16.4'}},'settings':{'base':base},'targets':targets,'schemes':{'CreatorMenuShot':{'build':{'targets':{'CreatorMenuShot':'all','CreatorMenuShotTests':['test']}},'test':{'gatherCoverageData':False,'targets':['CreatorMenuShotTests']}}}}
(work/'project.yml').write_text(json.dumps(project,indent=2)+'\n')
info={'CFBundleExecutable':'CreatorMenuShot','CFBundleIdentifier':'com.personaldokkan.creatormenushot','CFBundleName':'Creator Menu Shot','CFBundlePackageType':'APPL','CFBundleShortVersionString':'0.0.1','CFBundleVersion':'1','MinimumOSVersion':'16.4','UIDeviceFamily':[1,2],'UILaunchScreen':{},'UIUserInterfaceStyle':'Dark','UIApplicationSceneManifest':{'UIApplicationSupportsMultipleScenes':False,'UISceneConfigurations':{'UIWindowSceneSessionRoleApplication':[{'UISceneConfigurationName':'Default','UISceneDelegateClassName':'ODFinishScene'}]}},'UISupportedInterfaceOrientations':['UIInterfaceOrientationPortrait','UIInterfaceOrientationLandscapeLeft','UIInterfaceOrientationLandscapeRight']}
(work/'Info.plist').write_bytes(plistlib.dumps(info))
PY
if [[ ! -f "$TOOLS/xcodegen.zip" ]]; then
  curl --fail --location --silent --show-error 'https://github.com/yonaskolb/XcodeGen/releases/download/2.46.0/xcodegen.zip' -o "$TOOLS/xcodegen.zip"
fi
echo "4d9e34b62172d645eed6457cac13fc222569974098ef4ee9c3368bedf0196806  $TOOLS/xcodegen.zip" | shasum -a 256 -c -
mkdir -p "$TOOLS/xcodegen";ditto -x -k "$TOOLS/xcodegen.zip" "$TOOLS/xcodegen"
XCODEGEN="$(python3 - "$TOOLS/xcodegen" <<'PY'
from pathlib import Path
import sys
paths=[p for p in Path(sys.argv[1]).rglob('xcodegen') if p.is_file()]
if len(paths)!=1:raise SystemExit('Expected one pinned XcodeGen executable')
print(paths[0])
PY
)"
chmod +x "$XCODEGEN"
"$XCODEGEN" generate --spec "$WORK/project.yml" --project "$WORK"
OWNED_SIMULATOR=""
SHOT_PID=""
cleanup(){
  if [[ -n "$SHOT_PID" ]]; then kill "$SHOT_PID" >/dev/null 2>&1 || true; fi
  if [[ -n "$OWNED_SIMULATOR" ]]; then
    xcrun simctl shutdown "$OWNED_SIMULATOR" >/dev/null 2>&1 || true
    xcrun simctl delete "$OWNED_SIMULATOR" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT
OWNED_SIMULATOR="$(xcrun simctl create "Creator Menu Duo ${GITHUB_RUN_ID:-manual}" com.apple.CoreSimulator.SimDeviceType.iPhone-Duo com.apple.CoreSimulator.SimRuntime.iOS-27-1)"
[[ "$OWNED_SIMULATOR" =~ ^[0-9A-Fa-f-]{36}$ ]] || { OWNED_SIMULATOR="";echo 'Invalid owned simulator UUID' >&2;exit 1; }
export OWNED_SIMULATOR
xcrun simctl boot "$OWNED_SIMULATOR"
xcrun simctl bootstatus "$OWNED_SIMULATOR" -b
(
  for _ in $(seq 1 40); do
    sleep 2
    container="$(xcrun simctl get_app_container "$OWNED_SIMULATOR" com.personaldokkan.creatormenushot data 2>/dev/null || true)"
    if [[ -n "$container" && -f "$container/Library/creator-menu-ready" ]]; then
      sleep 1
      xcrun simctl io "$OWNED_SIMULATOR" screenshot "$WORK/evidence/creator-in-game-menu-simulator.png" || true
      break
    fi
  done
) &
SHOT_PID=$!
set +e
xcodebuild test -project "$WORK/CreatorMenuShot.xcodeproj" -scheme CreatorMenuShot \
  -destination "platform=iOS Simulator,id=$OWNED_SIMULATOR" -parallel-testing-enabled NO \
  -only-testing:CreatorMenuShotTests/ODCreatorMenuShotTests/testInGameCreatorMenuChrome \
  -derivedDataPath "$WORK/DerivedData" -resultBundlePath "$WORK/evidence/MenuShot.xcresult" \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tee "$WORK/evidence/xcodebuild.log"
NATIVE_EXIT=${PIPESTATUS[0]}
set -e
wait "$SHOT_PID" || true
SHOT_PID=""
CONTAINER="$(xcrun simctl get_app_container "$OWNED_SIMULATOR" com.personaldokkan.creatormenushot data 2>/dev/null || true)"
python3 - "$CONTAINER" "$WORK/evidence" <<'PY'
from pathlib import Path
import shutil,sys
source=Path(sys.argv[1]);destination=Path(sys.argv[2])
if sys.argv[1]:
    for name in ['creator-in-game-menu-window.png']:
        path=source/'Library'/name
        if path.is_file():shutil.copy2(path,destination/name)
PY
exit "$NATIVE_EXIT"
