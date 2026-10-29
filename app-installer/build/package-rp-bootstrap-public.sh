#!/usr/bin/env bash
# Build the public-source USB helper in hosted macOS; execute only --version.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
[[ "${GITHUB_ACTIONS:-}" == true && "$(uname -s)" == Darwin ]] || { echo 'Requires the authorized hosted macOS workflow.' >&2; exit 1; }
[[ "$(basename "$root")" == dokkan-offline-public && "${GITHUB_REPOSITORY:-}" == mcantua/dokkan-offline-public ]] || { echo 'Only the active public repository is allowed.' >&2; exit 1; }
[[ "$(git -C "$root" branch --show-current)" == chatgpt/app-installer-pairing-repair ]] || { echo 'Unexpected public source branch.' >&2; exit 1; }
[[ "$(rustc --version)" == 'rustc 1.99.1 '* ]] || { echo 'Pinned Rust1.99.1 is required.' >&2; exit 1; }
export PYTHONDONTWRITEBYTECODE=1
export SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"
export MACOSX_DEPLOYMENT_TARGET=12.0
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-$root/app-installer/core/target}"
export RUSTC_WRAPPER='' RUSTC_WORKSPACE_WRAPPER=''
helper="$root/downloads/idevice/idevice-0.1.68/Cargo.toml"
stage="$root/app-installer/cloud-ui/work/public-rp-helper"
mkdir -p "$stage"
# Fresh hosted caches must contain both locked graphs before offline fingerprinting.
cargo fetch --manifest-path "$root/app-installer/core/Cargo.toml" --locked
cargo fetch --manifest-path "$helper" --locked
source_before="$(python3 "$root/app-installer/build/source-fingerprint.py")"
rustup target add aarch64-apple-darwin x86_64-apple-darwin
for target in aarch64-apple-darwin x86_64-apple-darwin; do
  key="${target//-/_}"
  export "CC_${key}=$(xcrun --sdk macosx --find clang)"
  export "AR_${key}=$(xcrun --sdk macosx --find ar)"
  export "CXX_${key}=$(xcrun --sdk macosx --find clang++)"
  # cc supplies the target; split -target arguments break OpenSSL Configure.
  export "CFLAGS_${key}=-isysroot $SDKROOT -mmacosx-version-min=12.0"
  export "CXXFLAGS_${key}=-isysroot $SDKROOT -mmacosx-version-min=12.0"
  cargo build --manifest-path "$helper" --locked --release --no-default-features \
    --features app-installer-rp-bootstrap --example app-installer-rp-bootstrap --target "$target"
done
binary="$stage/app-installer-rp-bootstrap"
xcrun lipo -create \
  "$CARGO_TARGET_DIR/aarch64-apple-darwin/release/examples/app-installer-rp-bootstrap" \
  "$CARGO_TARGET_DIR/x86_64-apple-darwin/release/examples/app-installer-rp-bootstrap" -output "$binary"
chmod 755 "$binary"
codesign --force --sign - --timestamp=none "$binary"
codesign --verify --strict --all-architectures "$binary"
# Run the exact signed universal file on the hosted architecture. No device args.
version_output="$("$binary" --version)"
[[ "$version_output" == 'app-installer-rp-bootstrap 0.1.68' ]] || { echo 'Unexpected helper version output.' >&2; exit 1; }
python3 - "$root" "$stage" "$source_before" "$version_output" <<'PY'
from pathlib import Path
import hashlib,json,os,platform,re,stat,subprocess,sys
root,stage=map(Path,sys.argv[1:3]);sys.path.insert(0,str(root/'app-installer/build'))
from licensing import load_graph,HELPER_MANIFEST,HELPER_FEATURE
def command(args):return subprocess.check_output(args,cwd=root,text=True).strip()
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def canonical(value):return hashlib.sha256(json.dumps(value,sort_keys=True,separators=(',',':')).encode()).hexdigest()
fingerprint=command([sys.executable,str(root/'app-installer/build/source-fingerprint.py')])
if fingerprint!=sys.argv[3]:raise SystemExit('Source changed during universal helper build')
binary=stage/'app-installer-rp-bootstrap'
architectures=command(['xcrun','lipo','-archs',str(binary)]).split()
if sorted(architectures)!=['arm64','x86_64']:raise SystemExit('Helper is not exactly universal arm64+x86_64')
if stat.S_IMODE(binary.stat().st_mode)!=0o755:raise SystemExit('Unexpected helper executable mode')
sdk=Path(os.environ['SDKROOT']);settings=sdk/'SDKSettings.plist'
if not settings.is_file():settings=sdk/'SDKSettings.json'
sdk_version=command(['xcrun','--sdk','macosx','--show-sdk-version'])
build_commands={}
for arch in ('arm64','x86_64'):
    output=command(['xcrun','vtool','-arch',arch,'-show-build',str(binary)])
    if not re.search(r'platform\s+MACOS\b',output):raise SystemExit('Helper platform is not macOS')
    if not re.search(r'minos\s+12\.0(?:\.0)?\s',output+'\n'):raise SystemExit('Helper minimum macOS is not12.0')
    actual=re.search(r'\bsdk\s+(\d+(?:\.\d+){0,2})',output)
    if not actual or tuple(map(int,actual[1].split('.')))[:2]!=tuple(map(int,sdk_version.split('.')))[:2]:
        raise SystemExit('Helper Mach-O SDK differs from actual selected macOS SDK')
    build_commands[arch]=output
metadata,_,_,graph_hash=load_graph()
closures=[entry for entry in metadata['distribution_graphs'] if entry['manifest']==HELPER_MANIFEST]
targets=['aarch64-apple-darwin','x86_64-apple-darwin']
if sorted(entry['target'] for entry in closures)!=targets:raise SystemExit('Missing exact helper feature closures')
for entry in closures:
    if entry['features']!=[HELPER_FEATURE] or not entry['no_default_features']:
        raise SystemExit('Unexpected helper feature selection')
    idevice=[p for p in entry['packages'] if p['name']=='idevice']
    if len(idevice)!=1 or not {'max_level_off','release_max_level_off'}<=set(next(p for p in entry['packages'] if p['name']=='tracing')['features']):
        raise SystemExit('Helper fixed privacy feature selection is missing')
receipt={'schema_version':1,'project':'dokkan-offline-public','tool':'app-installer-rp-bootstrap',
 'version':'0.1.68','test_fixture':False,'source_commit':command(['git','rev-parse','HEAD']),
 'source_tree_sha256':fingerprint,'targets':targets,'architectures':['arm64','x86_64'],
 'minimum_macos':'12.0','ad_hoc_signed':True,'notarized':False,'build_succeeded':True,
 'version_output':sys.argv[4],'version_only_executed':True,'version_only_architecture':platform.machine(),
 'other_architecture_execution_verified':False,'usb_or_pairing_executed':False,'personal_resources_used':False,
 'binary':{'file':binary.name,'bytes':binary.stat().st_size,'sha256':sha(binary),'mode':0o755},
 'genuine_toolchain':{'rustc':command(['rustc','--version']),'rustc_verbose':command(['rustc','-Vv']),
    'xcode':command(['xcodebuild','-version']),'clang':command(['xcrun','--sdk','macosx','clang','--version']),
    'macos_sdk':sdk_version,'sdk_settings_sha256':sha(settings)},
 'mach_o_build_versions':build_commands,'locked_dependency_graph_hash':graph_hash,
 'target_graph_hashes':{entry['target']:canonical(entry) for entry in closures},
 'distribution_graphs':closures,'notice_delivery_pending':True,'corresponding_source_delivery_pending':True,
 'scope':'Exact public-source universal helper build and signed --version execution only. '
    'Full union notices and matching corresponding-source delivery must be sealed before kit distribution.'}
(stage/'RPBootstrapBuildManifest.json').write_text(json.dumps(receipt,indent=2)+'\n')
print(json.dumps({'file':binary.name,'bytes':binary.stat().st_size,'sha256':sha(binary),
 'source_tree_sha256':fingerprint,'distribution_ready':False}))
PY
