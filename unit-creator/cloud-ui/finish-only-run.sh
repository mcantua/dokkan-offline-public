#!/usr/bin/env bash
# One genuine hosted Duo WK boundary. No app packages, original game launch or other suites.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CLOUD="$ROOT/unit-creator/cloud-ui"
WORK="$CLOUD/finish-work"
TOOLS="$ROOT/downloads/unit-creator-cloud-tools"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode_27.1.app/Contents/Developer}"
test "$(uname -s)" = Darwin || { echo 'Requires an authorized hosted macOS runner' >&2; exit 1; }
test ! -e "$WORK" || { echo 'Existing diagnostic directory preserved; use a fresh hosted checkout' >&2; exit 1; }
mkdir -p "$WORK/evidence" "$TOOLS"
python3 - "$ROOT" <<'PY'
import importlib.util,json,pathlib,plistlib,subprocess,sys
root=pathlib.Path(sys.argv[1]);work=root/'unit-creator/cloud-ui/finish-work'
version=subprocess.check_output(['xcodebuild','-version'],text=True).strip()
sdk=subprocess.check_output(['xcrun','--sdk','iphonesimulator','--show-sdk-version'],text=True).strip()
if not version.startswith('Xcode 27.1\n') or sdk!='27.1':raise SystemExit('Genuine Xcode27.1/simulator SDK27.1 required; no version-field substitution')
inventory=json.loads(subprocess.check_output(['xcrun','simctl','list','-j']))
if 'com.apple.CoreSimulator.SimDeviceType.iPhone-Duo' not in {v['identifier'] for v in inventory['devicetypes']} or 'com.apple.CoreSimulator.SimRuntime.iOS-27-1' not in {v['identifier'] for v in inventory['runtimes'] if v.get('isAvailable')}:raise SystemExit('Genuine hosted Duo/iOS27.1 runtime unavailable')
arch=subprocess.check_output(['uname','-m'],text=True).strip()
if arch not in ('arm64','x86_64'):raise SystemExit('Unsupported hosted simulator architecture')
(work/'evidence/toolchain.json').write_text(json.dumps({'source_commit':subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),'xcode':version,'sdk':sdk,'architecture':arch,'scope':'One internal embedded Creator WK boundary on genuine hosted Duo; no physical device, original game launch or app package'},indent=2)+'\n')
# Reconstruct only the selected Eclipse master needed by the failing native scenario.
spec=importlib.util.spec_from_file_location('reconstruct',root/'unit-creator/cloud-ui/reconstruct-data.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
files=m.embedded_files(root/'test-page/UnitCreator-test.html');manifest,tables=m.snapshot(files,'data/db/')
(work/'db').mkdir()
provenance={'source':'Committed browser table rows reconstructed for one internal native Creator diagnostic','limitations':['Not original SQLite bytes; indexes/triggers/views/foreign-key declarations and binary fidelity are not recoverable','Not release game content or game-runtime evidence'],'eclipse':m.create_database(work/'db/reference.db',manifest,tables)}
(work/'evidence/data-provenance.json').write_text(json.dumps(provenance,indent=2)+'\n')
base={'CODE_SIGNING_ALLOWED':'NO','CLANG_ENABLE_OBJC_ARC':'YES','IPHONEOS_DEPLOYMENT_TARGET':'16.4','TARGETED_DEVICE_FAMILY':'1,2','ONLY_ACTIVE_ARCH':'YES','ARCHS':arch}
native='../../../offline-dokkan/'
host_sources=[{'path':'../FinishOnlyHost.m'},{'path':native+'creator-ui/site','type':'folder','buildPhase':'resources'},{'path':'db','type':'folder','buildPhase':'resources'}]
host_sources += [{'path':native+'mobile/ios/'+name} for name in ['ODCreatorController.m','ODCreatorSession.m','ODBattleStore.m','ODBattleCoordinator.m','ODDuoLauncher.m','ODDuoAccountController.m']]
host_sources += [{'path':native+'adapter/ios'},{'path':native+'adapter/od_bridge.c'},{'path':native+'core','includes':['*.c','*.h'],'excludes':['od_cli.c','test_*.c','check_*.c']},{'path':native+'content/content.c'},{'path':native+'content/master_archive.c'},{'path':native+'content/asset_catalog.c'},{'path':'../../../downloads/sqlite-amalgamation/source/sqlite3.c'}]
# The current controller references the complete scoped native tools. Compile
# the same committed authored components and class-renamed retained engines;
# omitting them would fail at link time before the actual Finish scenario.
own=root/'offline-dokkan/original-client'
host_sources += [{'path':'../../../'+str(p.relative_to(root))} for p in sorted(own.rglob('*')) if p.suffix in ('.c','.m')]
frameworks=['UIKit','WebKit','JavaScriptCore','Foundation','Security','Metal','CoreGraphics','QuartzCore']
manifest_path=own/'creator-tools/build-source.json'
if manifest_path.exists():
    setup=json.loads(manifest_path.read_text())
    if setup.get('schema')!=1 or setup['extra_objc_sources']!=['unit-creator/ios-objc/Host.m','unit-creator/ios-objc/Player.m']:
        raise SystemExit('Unexpected scoped Creator source inputs')
    renames=setup['apply_defines_only_to_extra_sources']
    if not all(k.replace('_','').isalnum() and v.replace('_','').isalnum() for k,v in renames.items()):
        raise SystemExit('Invalid scoped Creator class rename')
    flags=' '.join('-D'+k+'='+v for k,v in renames.items())
    host_sources += [{'path':'../../../'+p,'compilerFlags':flags} for p in setup['extra_objc_sources']]
    frameworks=list(dict.fromkeys(frameworks+setup['required_frameworks']))
    if not all(f.replace('_','').isalnum() for f in frameworks):raise SystemExit('Invalid native framework input')
host_settings={'PRODUCT_BUNDLE_IDENTIFIER':'com.personaldokkan.creatorfinishcheck','PRODUCT_NAME':'CreatorFinishOnly','INFOPLIST_FILE':'Info.plist','HEADER_SEARCH_PATHS':'$(SRCROOT)/../../../downloads/sqlite-amalgamation/source','GCC_PREPROCESSOR_DEFINITIONS':['$(inherited)','SQLITE_THREADSAFE=1','SQLITE_OMIT_LOAD_EXTENSION','SQLITE_DQS=0']}
targets={'CreatorFinishOnly':{'type':'application','platform':'iOS','sources':host_sources,'settings':{'base':host_settings},'dependencies':[{'sdk':s+'.framework'} for s in frameworks]+[{'sdk':'libz.tbd'}]},'CreatorFinishOnlyTests':{'type':'bundle.unit-test','platform':'iOS','sources':[{'path':'../FinishOnlyTests'}],'settings':{'base':{'PRODUCT_BUNDLE_IDENTIFIER':'com.personaldokkan.creatorfinishcheck.tests','GENERATE_INFOPLIST_FILE':'YES','TEST_HOST':'$(BUILT_PRODUCTS_DIR)/CreatorFinishOnly.app/CreatorFinishOnly','BUNDLE_LOADER':'$(TEST_HOST)'}},'dependencies':[{'target':'CreatorFinishOnly'},{'sdk':'XCTest.framework'},{'sdk':'WebKit.framework'}]}}
project={'name':'CreatorFinishOnly','options':{'minimumXcodeGenVersion':'2.46.0','deploymentTarget':{'iOS':'16.4'}},'settings':{'base':base},'targets':targets,'schemes':{'CreatorFinishOnly':{'build':{'targets':{'CreatorFinishOnly':'all','CreatorFinishOnlyTests':['test']}},'test':{'gatherCoverageData':False,'targets':['CreatorFinishOnlyTests']}}}}
(work/'project.yml').write_text(json.dumps(project,indent=2)+'\n')
info={'CFBundleExecutable':'CreatorFinishOnly','CFBundleIdentifier':'com.personaldokkan.creatorfinishcheck','CFBundleName':'Creator Finish Diagnostic','CFBundlePackageType':'APPL','CFBundleShortVersionString':'0.0.1','CFBundleVersion':'1','MinimumOSVersion':'16.4','UIDeviceFamily':[1,2],'UILaunchScreen':{},'UIUserInterfaceStyle':'Dark','UIApplicationSceneManifest':{'UIApplicationSupportsMultipleScenes':False,'UISceneConfigurations':{'UIWindowSceneSessionRoleApplication':[{'UISceneConfigurationName':'Default','UISceneDelegateClassName':'ODFinishScene'}]}},'UISupportedInterfaceOrientations':['UIInterfaceOrientationPortrait','UIInterfaceOrientationLandscapeLeft','UIInterfaceOrientationLandscapeRight']}
(work/'Info.plist').write_bytes(plistlib.dumps(info))
PY
python3 "$ROOT/offline-dokkan/creator-ui/build.py"
python3 "$ROOT/offline-dokkan/mobile/setup-sqlite.py"
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
cleanup(){
  if [[ -n "$OWNED_SIMULATOR" ]]; then
    xcrun simctl shutdown "$OWNED_SIMULATOR" >/dev/null 2>&1 || true
    xcrun simctl delete "$OWNED_SIMULATOR" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT
OWNED_SIMULATOR="$(xcrun simctl create "Creator Finish Duo ${GITHUB_RUN_ID:-manual}" com.apple.CoreSimulator.SimDeviceType.iPhone-Duo com.apple.CoreSimulator.SimRuntime.iOS-27-1)"
[[ "$OWNED_SIMULATOR" =~ ^[0-9A-Fa-f-]{36}$ ]] || { OWNED_SIMULATOR="";echo 'Invalid owned simulator UUID' >&2;exit 1; }
xcrun simctl boot "$OWNED_SIMULATOR"
xcrun simctl bootstatus "$OWNED_SIMULATOR" -b
set +e
xcodebuild test -project "$WORK/CreatorFinishOnly.xcodeproj" -scheme CreatorFinishOnly \
  -destination "platform=iOS Simulator,id=$OWNED_SIMULATOR" -parallel-testing-enabled NO \
  -only-testing:CreatorFinishOnlyTests/ODCreatorFinishOnlyTests/testSavedDraftPrepareAndFinishOnDuo \
  -derivedDataPath "$WORK/DerivedData" -resultBundlePath "$WORK/evidence/FinishOnly.xcresult" \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tee "$WORK/evidence/xcodebuild.log"
NATIVE_EXIT=${PIPESTATUS[0]}
set -e
CONTAINER="$(xcrun simctl get_app_container "$OWNED_SIMULATOR" com.personaldokkan.creatorfinishcheck data 2>/dev/null || true)"
python3 - "$CONTAINER" "$WORK/evidence" <<'PY'
from pathlib import Path
import shutil,sys
source=Path(sys.argv[1]);destination=Path(sys.argv[2])
if sys.argv[1]:
 for name in ['finish-only-result.json','finish-only-wk.png','duo-launcher.png','duo-offline-dokkan-account.png','duo-unit-creator.png','duo-import-confirmation.png']:
  p=source/'Library'/name
  if p.is_file():shutil.copy2(p,destination/name)
PY
exit "$NATIVE_EXIT"
