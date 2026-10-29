#!/usr/bin/env bash
# Genuine hosted-Xcode unsigned candidates only. Never signs in to Apple or installs a phone app.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
[[ "${GITHUB_ACTIONS:-}" == true ]] || { echo 'This entrypoint is restricted to GitHub-hosted cloud Actions; local use needs separate explicit approval/workflow' >&2; exit 1; }
[[ "$(uname -s)" == Darwin ]] || { echo 'Requires an authorized hosted macOS/Xcode executor' >&2; exit 1; }
export SDKROOT="$(xcrun --sdk iphoneos --show-sdk-path)"
export IPHONEOS_DEPLOYMENT_TARGET=16.4
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-$root/app-installer/core/target}"
export CC_aarch64_apple_ios="$(xcrun --sdk iphoneos --find clang)"
export AR_aarch64_apple_ios="$(xcrun --sdk iphoneos --find ar)"
export CFLAGS_aarch64_apple_ios="-isysroot $SDKROOT -target arm64-apple-ios16.4"
export CXXFLAGS_aarch64_apple_ios="$CFLAGS_aarch64_apple_ios"
export RUSTC_WRAPPER="" RUSTC_WORKSPACE_WRAPPER=""
[[ "$(rustc --version)" == "rustc 1.99.1 "* ]] || { echo 'Pinned Rust1.99.1 is required to match delivered runtime source/notices' >&2; exit 1; }
rustup target add aarch64-apple-ios
cargo build --manifest-path "$root/app-installer/core/Cargo.toml" --locked --release --target aarch64-apple-ios
python3 - "$root" <<'PYRECEIPT'
from pathlib import Path
import hashlib,json,os,subprocess,sys
root=Path(sys.argv[1]);sys.dont_write_bytecode=True;sys.path.insert(0,str(root/'app-installer/build'))
from licensing import load_graph
library=Path(os.environ['CARGO_TARGET_DIR'])/'aarch64-apple-ios/release/libapp_installer_core.a'
sdk=Path(os.environ['SDKROOT']);settings=sdk/'SDKSettings.plist'
if not settings.is_file():settings=sdk/'SDKSettings.json'
_,_,_,graph=load_graph()
receipt={'schema_version':1,'test_fixture':False,'build_succeeded':True,'target':'aarch64-apple-ios',
 'file':library.name,'bytes':library.stat().st_size,'sha256':hashlib.sha256(library.read_bytes()).hexdigest(),
 'rustc_version':subprocess.check_output(['rustc','--version'],text=True).strip(),
 'source_commit':subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip(),
 'source_tree_sha256':subprocess.check_output([sys.executable,str(root/'app-installer/build/source-fingerprint.py')],text=True).strip(),
 'locked_dependency_graph_hash':graph,'sdk_version':subprocess.check_output(['xcrun','--sdk','iphoneos','--show-sdk-version'],text=True).strip(),
 'sdk_settings_sha256':hashlib.sha256(settings.read_bytes()).hexdigest()}
(library.parent/'AppInstaller-device-build-receipt.json').write_text(json.dumps(receipt,indent=2)+'\n')
PYRECEIPT
python3 "$root/app-installer/build/package-device-cloud.py"
