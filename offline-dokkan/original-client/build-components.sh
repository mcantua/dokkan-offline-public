#!/usr/bin/env bash
# Compile authored Duo components only. No original game files, DBs, IPA or signing.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OWN="$ROOT/offline-dokkan/original-client"
WORK="$ROOT/offline-dokkan/private/component-build"
STARTUP_ENTRY=0
DIAGNOSTIC_ENTRY=0
if [[ "${1:-}" == --original-startup-entry && $# == 1 ]]; then
    STARTUP_ENTRY=1
elif [[ "${1:-}" == --original-startup-diagnostic-entry && $# == 1 ]]; then
    DIAGNOSTIC_ENTRY=1
elif [[ $# != 0 ]]; then
    echo 'Usage: build-components.sh [--original-startup-entry | --original-startup-diagnostic-entry]' >&2
    exit 1
fi
if [[ "$STARTUP_ENTRY" == 1 ]]; then
    # Reject the known unfinished composition before downloading SQLite or
    # invoking any compiler. A linked component library is not a playable app.
    python3 - "$OWN/loader/startup-source.json" <<'PY'
import json,sys
entry=json.load(open(sys.argv[1]))
if entry.get('native_factory_implemented') is not True:
    raise SystemExit('Original-game startup factory is unfinished; no production library was built. Use the default component target only when its check is authorized.')
PY
fi
test "$(uname -s)" = Darwin || { echo 'Requires genuine hosted Xcode27.1; no SDK version substitution.' >&2; exit 1; }
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode_27.1.app/Contents/Developer}"
test "$(xcrun --sdk iphoneos --show-sdk-version)" = 27.1
test ! -e "$WORK" || { echo 'Existing component build preserved; use a fresh cloud checkout.' >&2; exit 1; }
mkdir -p "$WORK/objects" "$WORK/evidence"
python3 "$ROOT/offline-dokkan/mobile/setup-sqlite.py"
SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
CLANG="$(xcrun --find clang)"
python3 - "$ROOT" "$CLANG" "$SDK" "$WORK" "$STARTUP_ENTRY" "$DIAGNOSTIC_ENTRY" <<'PY'
from pathlib import Path
import hashlib,json,re,subprocess,sys
root,clang,sdk,work=Path(sys.argv[1]),sys.argv[2],sys.argv[3],Path(sys.argv[4])
startup_entry=sys.argv[5]=='1'
diagnostic_entry=sys.argv[6]=='1'
own=root/'offline-dokkan/original-client';offline=root/'offline-dokkan'
sources=list((offline/'core').glob('*.c'))
sources=[p for p in sources if p.name!='od_cli.c' and not p.name.startswith(('test_','check_'))]
sources += [offline/'adapter/od_bridge.c',offline/'adapter/ios/ODNativeCore.m']
sources += [offline/'content'/p for p in ('content.c','master_archive.c','asset_catalog.c')]
sources += [offline/'mobile/ios'/p for p in ('ODCreatorController.m','ODCreatorSession.m','ODBattleStore.m','ODBattleCoordinator.m')]
sources += sorted(p for p in own.rglob('*') if p.suffix in ('.c','.m','.mm'))
extra=[];defines=[];frameworks=['UIKit','Foundation','WebKit','JavaScriptCore','Security','Metal','CoreGraphics','QuartzCore']
manifest_path=own/'creator-tools/build-source.json'
if manifest_path.exists():
    setup=json.loads(manifest_path.read_text())
    if setup.get('schema')!=1:raise SystemExit('Invalid scoped Creator build manifest')
    extra=[root/p for p in setup['extra_objc_sources']]
    if extra!=[root/'unit-creator/ios-objc/Host.m',root/'unit-creator/ios-objc/Player.m']:
        raise SystemExit('Unexpected scoped Creator source inputs')
    defines=['-D'+k+'='+v for k,v in setup['apply_defines_only_to_extra_sources'].items()]
    if not all(k.replace('_','').isalnum() and v.replace('_','').isalnum() for k,v in setup['apply_defines_only_to_extra_sources'].items()):
        raise SystemExit('Invalid native class rename')
    frameworks=list(dict.fromkeys(frameworks+setup['required_frameworks']))
    if not all(f.replace('_','').isalnum() for f in frameworks):raise SystemExit('Invalid native framework input')
    sources += extra
sources += [root/'downloads/sqlite-amalgamation/source/sqlite3.c']
if len(sources)!=len(set(sources)) or not all(p.is_file() for p in sources):raise SystemExit('Component source inventory invalid')
source_commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
if not re.fullmatch(r'[0-9a-f]{40}',source_commit):raise SystemExit('Invalid build source identity')
common=[clang,'-target','arm64-apple-ios16.4','-isysroot',sdk,'-O2','-fblocks','-D_DARWIN_C_SOURCE=1','-DOD_BUILD_SOURCE_SHA="'+source_commit+'"','-DSQLITE_THREADSAFE=1','-DSQLITE_OMIT_LOAD_EXTENSION','-DSQLITE_DQS=0','-I'+str(root/'downloads/sqlite-amalgamation/source')]
if startup_entry:
    entry=json.loads((own/'loader/startup-source.json').read_text())
    if entry.get('schema')!=1 or entry.get('production_compile_define')!='OD_UNIFIED_DUO_STARTUP_ENTRY=1' or root/entry.get('entry_source','') not in sources:
        raise SystemExit('Invalid original-game startup source manifest')
    common += ['-D'+entry['production_compile_define']]
if diagnostic_entry:
    entry=json.loads((own/'loader/startup-diagnostic-source.json').read_text())
    if (entry.get('schema')!=1 or entry.get('diagnostic_compile_define')!='OD_ORIGINAL_DUO_DIAGNOSTIC_ENTRY=1'
            or entry.get('native_factory_implemented') is not True
            or root/entry.get('entry_source','') not in sources
            or entry.get('required_host_purpose')!='original-startup-diagnostic'):
        raise SystemExit('Invalid original-client diagnostic source manifest')
    common += ['-D'+entry['diagnostic_compile_define']]
objects=[];manifest=[];failed=[]
for index,source in enumerate(sources):
    obj=work/'objects'/('%03d.o'%index)
    if source.suffix=='.mm':
        # Original callback ABI requires the actual Apple C++ standard library.
        # Keep this language selection local to Objective-C++ sources.
        flags=['-std=c++17','-stdlib=libc++','-fobjc-arc','-Wall','-Wextra','-Werror']
    else:
        flags=['-fobjc-arc','-Wall','-Wextra','-Werror'] if source.suffix=='.m' else ['-std=c11','-Wall','-Wextra','-Werror']
    if source in extra:
        # Retained editor engines use required callback signatures with unused
        # parameters. Match their existing Xcode baseline only for these two
        # files; keep deprecated API warnings visible and every other error.
        flags += ['-Wno-error=deprecated-declarations','-Wno-unused-parameter']+defines
    # Public SQLite carries its own platform diagnostics, already documented.
    if source.name=='sqlite3.c':flags=['-std=c11']
    # Compile each unit once and collect errors in this same cloud job; avoid
    # another full hosted build merely to discover the next translation unit.
    result=subprocess.run(common+flags+['-c',str(source),'-o',str(obj)])
    if result.returncode:
        failed.append(str(source.relative_to(root)))
        continue
    objects.append(str(obj));manifest.append({'source':str(source.relative_to(root)),'sha256':hashlib.sha256(source.read_bytes()).hexdigest()})
if failed:
    raise SystemExit('Native compilation failed in: '+', '.join(failed))
output=work/'OfflineDokkanHost.dylib'
framework_args=[arg for f in frameworks for arg in ('-framework',f)]
cxx=any(source.suffix=='.mm' for source in sources)
cxx_link=['-lc++'] if cxx else []
subprocess.run(common+['-dynamiclib','-install_name','@rpath/OfflineDokkanHost.dylib','-Wl,-dead_strip']+objects+framework_args+cxx_link+['-lz','-o',str(output)],check=True)
report={'scope':'Authored Duo component library only; no original engine, assets, master, signing or app package','source_commit':subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip(),'device_sdk':'27.1','architecture':'arm64','deployment_target':'16.4','objective_cxx_standard':('c++17' if cxx else None),'cxx_runtime':('Apple libc++' if cxx else None),'sources':manifest,'scoped_legacy_class_defines':defines,'frameworks':frameworks,'original_startup_entry_enabled':startup_entry,'original_startup_diagnostic_entry_enabled':diagnostic_entry,'native_factory_implementation_required':startup_entry,'dylib_sha256':hashlib.sha256(output.read_bytes()).hexdigest(),'dylib_bytes':output.stat().st_size,'original_game_launch_verified':False}
(work/'evidence/component-build.json').write_text(json.dumps(report,indent=2)+'\n')
print('Authored Duo component library compiled with genuine device SDK27.1; no app/runtime completion claimed.')
PY
