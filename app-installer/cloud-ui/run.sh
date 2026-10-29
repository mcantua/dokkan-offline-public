#!/usr/bin/env bash
# Hosted macOS only. Compiles production sources, never authenticates or installs on a phone.
set -euo pipefail
export AI_ORIGINAL_NATIVE_CHECKS="${AI_RUN_NATIVE_CHECKS:-1}"
if [[ "${AI_RUST_TEST_SCOPE:-all}" == pairing-handshake ]]; then
  [[ "${AI_RUN_NATIVE_CHECKS:-}" == 0 ]] || {
    echo 'Pairing handshake packaging requires native_checks=false; unchanged native checks must not repeat.' >&2
    exit 2
  }
elif [[ "${AI_RUST_TEST_SCOPE:-all}" == connection-diagnostics ]]; then
  # This focused Rust correction never reruns unrelated native checks, even if
  # the workflow's native input kept its default. Optional packaging stays intact.
  export AI_RUN_NATIVE_CHECKS=0
elif [[ "${AI_RUST_TEST_SCOPE:-all}" == refresh-recovery || "${AI_RUST_TEST_SCOPE:-all}" == pairing-recovery ]]; then
  # Related native changes use only the explicitly requested selector. An absent
  # request keeps this proof-reuse/package scope free of native test execution.
  export AI_RUN_NATIVE_CHECKS="${AI_RUN_NATIVE_CHECKS:-0}"
  export AI_ORIGINAL_NATIVE_CHECKS="$AI_RUN_NATIVE_CHECKS"
fi
if [[ "${AI_PACKAGE_DEVICE_CANDIDATES:-0}" != 1 && "${AI_RUN_NATIVE_CHECKS:-1}" != 1 && "${AI_RUST_TEST_SCOPE:-all}" != connection-diagnostics && "${AI_RUST_TEST_SCOPE:-all}" != secure-rp && "${AI_RUST_TEST_SCOPE:-all}" != refresh-recovery && "${AI_RUST_TEST_SCOPE:-all}" != pairing-recovery && "${AI_RUST_TEST_SCOPE:-all}" != pairing-handshake ]]; then
  echo 'Select candidate packaging, native checks or targeted Rust checks.' >&2
  exit 2
fi
[[ "$(uname -s)" == Darwin && "${GITHUB_ACTIONS:-}" == true ]] || {
  echo 'This workflow runs only on the selected hosted macOS executor. Personal Mac use needs separate explicit approval.' >&2
  exit 1
}
root="$(cd "$(dirname "$0")/../.." && pwd)"
cloud="$root/app-installer/cloud-ui"
work="$cloud/work"
tools="$root/downloads/cloud-ui-tools"
mkdir -p "$work/evidence" "$tools/tmp" "$tools/cargo" "$tools/rustup"
export CARGO_HOME="$tools/cargo" RUSTUP_HOME="$tools/rustup" TMPDIR="$tools/tmp"
export CARGO_TARGET_DIR="$root/app-installer/core/target"
export PATH="$CARGO_HOME/bin:$PATH"
export DEVELOPER_DIR="$(python3 "$cloud/select-xcode.py")"
export SDKROOT="$(xcrun --sdk iphonesimulator --show-sdk-path)"
export IPHONEOS_DEPLOYMENT_TARGET=16.4
arch="$(uname -m)"
case "$arch" in
  arm64) triple=aarch64-apple-darwin; target=aarch64-apple-ios-sim; rustup_sha=20ef5516c31b1ac2290084199ba77dbbcaa1406c45c1d978ca68558ef5964ef5;;
  x86_64) triple=x86_64-apple-darwin; target=x86_64-apple-ios; rustup_sha=9c331076f62b4d0edeae63d9d1c9442d5fe39b37b05025ec8d41c5ed35486496;;
  *) echo 'Unsupported hosted runner architecture' >&2; exit 1;;
esac
python3 - "$root" "$arch" "$target" "$triple" <<'PY'
import json,pathlib,subprocess,sys
root=pathlib.Path(sys.argv[1]); out=root/'app-installer/cloud-ui/work/evidence'
report={'source_commit':subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),
 'architecture':sys.argv[2],'rust_target':sys.argv[3] if __import__('os').environ.get('AI_RUN_NATIVE_CHECKS','1')=='1' else ('aarch64-apple-ios' if __import__('os').environ.get('AI_PACKAGE_DEVICE_CANDIDATES','0')=='1' else sys.argv[4]),
 'xcode':subprocess.check_output(['xcodebuild','-version'],text=True).strip(),
 'simulator_sdk':subprocess.check_output(['xcrun','--sdk','iphonesimulator','--show-sdk-version'],text=True).strip(),
 'scope':'Genuine SDK27.1+. Actual simulator selection and pre-app health are recorded separately. No Apple login or phone use; geometry fixtures do not verify hardware folds.',
 'native_checks_requested':__import__('os').environ.get('AI_ORIGINAL_NATIVE_CHECKS','1')=='1',
 'native_checks_enabled':__import__('os').environ.get('AI_RUN_NATIVE_CHECKS','1')=='1',
 'rust_test_target':sys.argv[4],
 'rust_test_filter':'connection_diagnostics_' if __import__('os').environ.get('AI_RUST_TEST_SCOPE','all')=='connection-diagnostics' else None,
 'rust_test_groups':(['core_connection','peer_auth','tunnel_security','helper','pinned_tls'] if __import__('os').environ.get('AI_RUST_TEST_SCOPE','all')=='secure-rp' else ['refresh_recovery'] if __import__('os').environ.get('AI_RUST_TEST_SCOPE','all')=='refresh-recovery' else ['rp_connectivity','helper_publication'] if __import__('os').environ.get('AI_RUST_TEST_SCOPE','all')=='pairing-recovery' else ['rp_setup_wire','helper_handshake'] if __import__('os').environ.get('AI_RUST_TEST_SCOPE','all')=='pairing-handshake' else []),
 'native_test_scope':__import__('os').environ.get('AI_NATIVE_TEST_SCOPE','all'),
 'rust_test_scope':__import__('os').environ.get('AI_RUST_TEST_SCOPE','all'),
 'physical_hardware_verified':False, 'pose_automation':'No undocumented fold CLI invoked; installed simctl help is captured for supported-control discovery.'}
(out/'source-report.json').write_text(json.dumps(report,indent=2)+'\n')
PY
# Create and own exactly one disposable simulator; never boot/delete a pre-existing device.
owned_simulator=""
display_driver_pid=""
stop_display_driver() {
  if [[ -n "$display_driver_pid" ]]; then
    kill -TERM "$display_driver_pid" >/dev/null 2>&1 || true
    wait "$display_driver_pid" || true
    display_driver_pid=""
  fi
}
cleanup_simulator() {
  local result=$?
  stop_display_driver
  local app="$work/DerivedData/Build/Products/Debug-iphonesimulator/AppInstaller.app"
  if [[ -d "$app" ]]; then
    codesign --display --entitlements :- "$app" > "$work/evidence/simulator-host-entitlements.plist" 2> "$work/evidence/simulator-signature-summary.txt" || true
  fi
  if [[ -n "$owned_simulator" ]]; then
    if [[ "$result" != 0 ]]; then
      python3 "$cloud/capture-simulator-failure.py" --simulator "$owned_simulator" --evidence "$work/evidence" || true
    fi
    xcrun simctl shutdown "$owned_simulator" >/dev/null 2>&1 || true
    xcrun simctl delete "$owned_simulator" >/dev/null 2>&1 || true
  fi
}
trap cleanup_simulator EXIT
curl --fail --location --silent --show-error "https://static.rust-lang.org/rustup/archive/1.28.2/$triple/rustup-init" -o "$tools/rustup-init"
echo "$rustup_sha  $tools/rustup-init" | shasum -a 256 -c -
chmod +x "$tools/rustup-init"
"$tools/rustup-init" -y --profile minimal --default-toolchain 1.99.1 --no-modify-path
rustup set auto-self-update disable
# Vendored OpenSSL builds need the declared hosted make/Perl and actual target
# clang/sysroots. Never silently select a Homebrew/system OpenSSL installation.
command -v make >/dev/null
command -v perl >/dev/null
unset OPENSSL_NO_VENDOR OPENSSL_DIR OPENSSL_LIB_DIR OPENSSL_INCLUDE_DIR OPENSSL_STATIC
mac_sdk="$(xcrun --sdk macosx --show-sdk-path)"
export CC_aarch64_apple_darwin="$(xcrun --sdk macosx --find clang)"
export CC_x86_64_apple_darwin="$CC_aarch64_apple_darwin"
export CXX_aarch64_apple_darwin="$(xcrun --sdk macosx --find clang++)"
export CXX_x86_64_apple_darwin="$CXX_aarch64_apple_darwin"
export AR_aarch64_apple_darwin="$(xcrun --sdk macosx --find ar)"
export AR_x86_64_apple_darwin="$AR_aarch64_apple_darwin"
export CFLAGS_aarch64_apple_darwin="-isysroot $mac_sdk -arch arm64 -mmacosx-version-min=12.0"
export CFLAGS_x86_64_apple_darwin="-isysroot $mac_sdk -arch x86_64 -mmacosx-version-min=12.0"
export MACOSX_DEPLOYMENT_TARGET=12.0
export CC_aarch64_apple_ios_sim="$(xcrun --sdk iphonesimulator --find clang)"
export CXX_aarch64_apple_ios_sim="$(xcrun --sdk iphonesimulator --find clang++)"
export AR_aarch64_apple_ios_sim="$(xcrun --sdk iphonesimulator --find ar)"
# cc derives the clang target from the Rust triple. A split -target value
# is mistaken for a second platform by OpenSSL Configure.
export CFLAGS_aarch64_apple_ios_sim="-isysroot $SDKROOT -mios-simulator-version-min=16.4"
export CXXFLAGS_aarch64_apple_ios_sim="$CFLAGS_aarch64_apple_ios_sim"
export RUSTC_WRAPPER="" RUSTC_WORKSPACE_WRAPPER="" RUSTFLAGS="" CARGO_ENCODED_RUSTFLAGS=""

if [[ "${AI_RUN_NATIVE_CHECKS:-1}" == 1 ]]; then rustup target add "$target"; fi
# New-build regression checks are host binaries: never compile these against the iOS simulator sysroot.
if [[ "${AI_RUST_TEST_SCOPE:-all}" == pairing-handshake ]]; then
  # Require only new canonical TLV/full synthetic SRP2 and typed helper1 proof.
  # No previous suite or native check is a fallback for mismatched evidence.
  for group in rp_setup_wire helper_handshake; do
    python3 "$cloud/reuse-rp-proof.py" --repo "$root" \
      --proof "$root/downloads/completion-verification/remote-pairing-working" \
      --group "$group" --output "$work/evidence/reused-rp-$group"
  done
elif [[ "${AI_RUST_TEST_SCOPE:-all}" == pairing-recovery ]]; then
  # Require only the new source-scoped vendor2/helper1 Linux results. A proof
  # mismatch stops the build rather than rerunning previous passing suites.
  for group in rp_connectivity helper_publication; do
    python3 "$cloud/reuse-rp-proof.py" --repo "$root" \
      --proof "$root/downloads/completion-verification/remote-pairing-working" \
      --group "$group" --output "$work/evidence/reused-rp-$group"
  done
elif [[ "${AI_RUST_TEST_SCOPE:-all}" == refresh-recovery ]]; then
  # Require the new, exact-source Linux refresh recovery proof. A mismatch stops
  # this run; old Rust suites never repeat. Native checks remain independently
  # controlled by their explicit request and selected scope.
  python3 "$cloud/reuse-rp-proof.py" --repo "$root" \
    --proof "$root/downloads/completion-verification/refresh-recovery-working" \
    --group refresh_recovery --output "$work/evidence/reused-rp-refresh_recovery"
elif [[ "${AI_RUST_TEST_SCOPE:-all}" == secure-rp ]]; then
  # Platform-independent focused checks can reuse exact-input Linux proof. The
  # receipt says Linux/reused, never fresh hosted execution. Missing/mismatched
  # proof falls back to only the two affected methods for that group.
  run_rp_group() {
    local group="$1" log="$2"; shift 2
    if python3 "$cloud/reuse-rp-proof.py" --repo "$root" \
      --proof "$root/downloads/completion-verification/remote-pairing-working" \
      --group "$group" --output "$work/evidence/reused-rp-$group"; then
      return
    fi
    SDKROOT="$mac_sdk" "$@" 2>&1 | tee "$work/evidence/$log"
    python3 "$cloud/reuse-rp-proof.py" --verify-log "$work/evidence/$log" --group "$group"
  }
  run_rp_group core_connection core-connection-diagnostics-tests.log cargo test --manifest-path "$root/app-installer/core/Cargo.toml" --locked --lib connection_diagnostics_
  run_rp_group peer_auth peer-auth-tests.log cargo test --manifest-path "$root/downloads/idevice/idevice-0.1.68/Cargo.toml" --locked --no-default-features --features ring,tcp,remote_pairing,openssl,tunnel_tcp_stack,rsd --lib rp_auth_
  run_rp_group tunnel_security tunnel-security-tests.log cargo test --manifest-path "$root/downloads/idevice/idevice-0.1.68/Cargo.toml" --locked --no-default-features --features ring,tcp,remote_pairing,openssl,tunnel_tcp_stack,rsd --lib security_
  run_rp_group pinned_tls pinned-tls-both-features.log cargo test --manifest-path "$root/downloads/idevice/idevice-0.1.68/Cargo.toml" --locked --no-default-features --features ring,tcp,remote_pairing,openssl,tunnel_tcp_stack,rsd --lib sni::tests::
  run_rp_group helper helper-tests.log cargo test --manifest-path "$root/app-installer/device/secure-rp-bootstrap/Cargo.toml" --locked --bin app-installer-rp-bootstrap tests::
elif [[ "${AI_RUST_TEST_SCOPE:-all}" == connection-diagnostics ]]; then
  SDKROOT="$(xcrun --sdk macosx --show-sdk-path)" cargo test --manifest-path "$root/app-installer/core/Cargo.toml" --locked --lib connection_diagnostics_ 2>&1 | tee "$work/evidence/connection-diagnostics-tests.log"
elif [[ "${AI_RUST_TEST_SCOPE:-all}" == login-startup ]]; then
  # Separate test executable: prior TLS tests cannot preinitialize its process-global provider.
  SDKROOT="$(xcrun --sdk macosx --show-sdk-path)" cargo test --manifest-path "$root/app-installer/core/Cargo.toml" --locked --test first_account_transport -- --test-threads=1 2>&1 | tee "$work/evidence/first-account-transport-tests.log"
  SDKROOT="$(xcrun --sdk macosx --show-sdk-path)" cargo test --manifest-path "$root/downloads/idevice/idevice-0.1.68/Cargo.toml" --locked --no-default-features --features ring --lib sni::tests:: 2>&1 | tee "$work/evidence/tls-tests.log"
elif [[ "${AI_RUST_TEST_SCOPE:-all}" != all ]]; then
  echo 'Unsupported Rust verification scope' >&2; exit 2
elif python3 "$cloud/reuse-core-proof.py" --repo "$root" \
  --proof "$root/downloads/completion-verification/hosted-core" --output "$work/evidence/reused-core"; then
  : # Exact source, successful raw logs and hosted context were verified; no new test claim.
else
  SDKROOT="$(xcrun --sdk macosx --show-sdk-path)" cargo test --manifest-path "$root/app-installer/core/Cargo.toml" --locked --lib 2>&1 | tee "$work/evidence/coretests.log"
  SDKROOT="$(xcrun --sdk macosx --show-sdk-path)" cargo test --manifest-path "$root/app-installer/core/Cargo.toml" --locked --test first_account_transport -- --test-threads=1 2>&1 | tee "$work/evidence/first-account-transport-tests.log"
  SDKROOT="$(xcrun --sdk macosx --show-sdk-path)" cargo test --manifest-path "$root/downloads/idevice/idevice-0.1.68/Cargo.toml" --locked --no-default-features --features ring --lib sni::tests:: 2>&1 | tee "$work/evidence/tls-tests.log"
  SDKROOT="$(xcrun --sdk macosx --show-sdk-path)" cargo test --manifest-path "$root/downloads/idevice/idevice-0.1.68/Cargo.toml" --locked --no-default-features --features ring,tcp,installation_proxy --lib services::installation_proxy::response_tests:: 2>&1 | tee "$work/evidence/installation-response-tests.log"
fi
export PYTHONDONTWRITEBYTECODE=1
# Targeted Python negative/regression checks already passed during the affected tasks.
# This final run verifies the actual candidate/source/kit outputs below instead of repeating them.
# Produce source-bound unsigned candidates independently of virtual OS startup.
package_failed=0
if [[ "${AI_PACKAGE_DEVICE_CANDIDATES:-0}" == 1 ]]; then
  if bash "$root/app-installer/build/package-rp-bootstrap-cloud.sh" && \
  bash "$root/app-installer/build/package-device-cloud.sh" && \
  python3 "$root/app-installer/device/validate-cloud-project.py" --execute --rust-library "$work/evidence/candidates/libapp_installer_core.a" --manifest "$work/evidence/candidates/cloud-device-library-manifest.json" && \
  python3 "$root/app-installer/device/make-bootstrap-kit.py" --execute \
    --rust-library "$work/evidence/candidates/libapp_installer_core.a" \
    --manifest "$work/evidence/candidates/cloud-device-library-manifest.json" \
    --review-ipa "$work/evidence/candidates/AppInstaller-duo-candidate.ipa" \
    --source-bundle "$work/evidence/candidates/AppInstaller-corresponding-source.tar.xz" \
    --output "$work/evidence/candidates/AppInstaller-native-bootstrap-kit.zip" --variant duo; then
    if [[ -n "${GITHUB_OUTPUT:-}" ]]; then printf '%s\n' 'candidate-ready=true' >> "$GITHUB_OUTPUT"; fi
  else
    package_failed=1
    echo 'Candidate packaging did not verify; continuing independent native checks.' >&2
  fi
fi
if [[ "${AI_RUN_NATIVE_CHECKS:-1}" != 1 ]]; then exit "$package_failed"; fi
# Any simulator fallback happens before our application is built or installed.
owned_simulator="$(python3 "$cloud/prepare-hosted-simulator.py" --evidence "$work/evidence")"
[[ "$owned_simulator" =~ ^[0-9A-Fa-f-]{36}$ ]] || { echo 'No owned healthy simulator UUID' >&2; exit 1; }
xcrun simctl help > "$work/evidence/simctl-help.txt" 2>&1
xcrun simctl io help > "$work/evidence/simctl-io-help.txt" 2>&1 || true
xcrun simctl io "$owned_simulator" enumerate > "$work/evidence/default-display-enumeration.txt"
curl --fail --location --silent --show-error 'https://github.com/yonaskolb/XcodeGen/releases/download/2.46.0/xcodegen.zip' -o "$tools/xcodegen.zip"
echo "4d9e34b62172d645eed6457cac13fc222569974098ef4ee9c3368bedf0196806  $tools/xcodegen.zip" | shasum -a 256 -c -
mkdir -p "$tools/xcodegen"
ditto -x -k "$tools/xcodegen.zip" "$tools/xcodegen"
xcodegen="$(find "$tools/xcodegen" -type f -name xcodegen | head -1)"
[[ -n "$xcodegen" ]] || { echo 'Pinned XcodeGen archive has no binary' >&2; exit 1; }
chmod +x "$xcodegen"
cargo build --manifest-path "$root/app-installer/core/Cargo.toml" --locked --release --target "$target"
[[ -s "$CARGO_TARGET_DIR/$target/release/libapp_installer_core.a" ]] || { echo "Simulator Rust archive was not created" >&2; exit 1; }
python3 - "$root" "$target" "$arch" <<'PY'
import pathlib,plistlib,shutil,sys
root,target,arch=pathlib.Path(sys.argv[1]),sys.argv[2],sys.argv[3]
cloud=root/'app-installer/cloud-ui';work=cloud/'work'
recipe=(cloud/'project.yml').read_text().replace('__RUST_TARGET__',target).replace('__ARCH__',arch)
(work/'project.yml').write_text(recipe)
p=plistlib.loads((root/'app-installer/ios/Info.plist').read_bytes())
for k in list(p):
 if k.startswith('DT') or k in ('CFBundleSupportedPlatforms','BuildMachineOSBuild'): p.pop(k)
p['CFBundleIdentifier']='org.tin.appinstaller.cloudsmoke'
p['CFBundleDisplayName']='Installer Cloud Smoke'
p['CFBundleExecutable']='AppInstaller'
p['CFBundleVersion']='1';p['CFBundleShortVersionString']='0.1.0'
p['CFBundleIcons']={'CFBundlePrimaryIcon':{'CFBundleIconFiles':['AppIcon60x60'],'UIPrerenderedIcon':False}}
(work/'Info.plist').write_bytes(plistlib.dumps(p))
resources=work/'Resources';resources.mkdir(exist_ok=True)
for size,scale in [(120,2),(180,3)]:
 shutil.copy2(root/f'app-installer/ios/assets/AppIcon{size}.png',resources/f'AppIcon60x60@{scale}x.png')
PY
"$xcodegen" generate --spec "$work/project.yml" --project "$work"
xcodebuild build-for-testing -project "$work/AppInstallerCloudSmoke.xcodeproj" -scheme AppInstallerCloudSmoke \
  -destination "platform=iOS Simulator,id=$owned_simulator" -parallel-testing-enabled NO \
  -derivedDataPath "$work/DerivedData" CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- \
  2>&1 | tee "$work/evidence/xcodebuild-build.log"
# Launch production code on the untouched simulator before XCTest injection.
xcrun simctl install "$owned_simulator" "$work/DerivedData/Build/Products/Debug-iphonesimulator/AppInstaller.app"
xcrun simctl launch "$owned_simulator" org.tin.appinstaller.cloudsmoke > "$work/evidence/production-launch.txt"
xcrun simctl io "$owned_simulator" screenshot --display=primary "$work/evidence/production-default-display.png"
# A harness-only correction reruns only its affected method. The five unchanged
# passing methods retain their source-bound evidence from the preceding run.
native_test_args=()
case "${AI_NATIVE_TEST_SCOPE:-all}" in
  all) ;;
  pairing-recovery) native_test_args+=("-only-testing:AppInstallerCloudUITests/PairingImportReadTests/testCoordinatedPairingReadUsesBoundedBytesAndHonorsCancellation") ;;
  responsive) native_test_args+=("-only-testing:AppInstallerCloudUITests/AppInstallerCloudUITests/test02ResponsiveMainUsesLabelledTestOnlyFixture") ;;
  accessibility) native_test_args+=("-only-testing:AppInstallerCloudUITests/AppInstallerCloudUITests/test03AccessibilityTextKeepsControlsReadable" "-only-testing:AppInstallerCloudUITests/AppInstallerCloudUITests/test04KeyboardKeepsFocusedFieldsReachable") ;;
  secure-rp) native_test_args+=("-only-testing:AppInstallerCloudUITests/AppInstallerCloudUITests/test02ResponsiveMainUsesLabelledTestOnlyFixture" "-only-testing:AppInstallerCloudUITests/AppInstallerPairingDiscoveryTests/testBoundedDiscoveryCancellationRejectsLateCallbacksAndFinishesOnce" "-only-testing:AppInstallerCloudUITests/PairingStoreValidationTests/testRemotePairingV2ImportAndRecoveryFormatGuardPreservesLegacySupport") ;;
  authorization-cancel) native_test_args+=("-only-testing:AppInstallerCloudUITests/SecureStoreBootstrapTests/testCancellingOrdinaryPendingAuthenticationRejectsDelayedSyntheticSuccess") ;;
  *) echo 'Unsupported native test selection' >&2; exit 2;;
esac
xcodebuild test-without-building -project "$work/AppInstallerCloudSmoke.xcodeproj" -scheme AppInstallerCloudSmoke \
  -destination "platform=iOS Simulator,id=$owned_simulator" -parallel-testing-enabled NO \
  -derivedDataPath "$work/DerivedData" -resultBundlePath "$work/evidence/CloudUISmoke.xcresult" \
  CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- "${native_test_args[@]}" 2>&1 | tee "$work/evidence/xcodebuild.log"

stop_display_driver
exit "$package_failed"
