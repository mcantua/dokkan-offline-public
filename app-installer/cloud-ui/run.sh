#!/usr/bin/env bash
# Hosted macOS only. Compiles production sources, never authenticates or installs on a phone.
set -euo pipefail
case "${AI_RUST_TEST_SCOPE:-all}" in all|login-startup|pairing-public) ;; *) echo 'Unsupported Rust verification scope' >&2; exit 2;; esac
case "${AI_NATIVE_TEST_SCOPE:-all}" in all|responsive|accessibility|authorization-cancel|pairing-document|pairing-public) ;; *) echo 'Unsupported native verification scope' >&2; exit 2;; esac
if [[ "${AI_PACKAGE_DEVICE_CANDIDATES:-0}" != 1 && "${AI_RUN_NATIVE_CHECKS:-1}" != 1 ]]; then
  echo 'Select candidate packaging or native checks.' >&2
  exit 2
fi
[[ "$(uname -s)" == Darwin && "${GITHUB_ACTIONS:-}" == true ]] || {
  echo 'This workflow runs only on the selected hosted macOS executor. Personal Mac use needs separate explicit approval.' >&2
  exit 1
}
root="$(cd "$(dirname "$0")/../.." && pwd)"
[[ "$(basename "$root")" == dokkan-offline-public && "${GITHUB_REPOSITORY:-}" == mcantua/dokkan-offline-public ]] || { echo 'Only the active public repository is allowed.' >&2; exit 1; }
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
python3 - "$root" "$arch" "$target" <<'PY'
import json,pathlib,subprocess,sys
root=pathlib.Path(sys.argv[1]); out=root/'app-installer/cloud-ui/work/evidence'
report={'source_commit':subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),
 'architecture':sys.argv[2],'rust_target':sys.argv[3] if __import__('os').environ.get('AI_RUN_NATIVE_CHECKS','1')=='1' else 'aarch64-apple-ios',
 'xcode':subprocess.check_output(['xcodebuild','-version'],text=True).strip(),
 'simulator_sdk':subprocess.check_output(['xcrun','--sdk','iphonesimulator','--show-sdk-version'],text=True).strip(),
 'scope':'Genuine SDK27.1+. Actual simulator selection and pre-app health are recorded separately. No Apple login or phone use; geometry fixtures do not verify hardware folds.',
 'pairing_public_new_test_counts':{'vendor':8,'helper':2,'transport':2,'native':2 if __import__('os').environ.get('AI_NATIVE_TEST_SCOPE')=='pairing-public' else 1},
 'native_checks_requested':__import__('os').environ.get('AI_RUN_NATIVE_CHECKS','1')=='1',
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
export MACOSX_DEPLOYMENT_TARGET=12.0
export PYTHONDONTWRITEBYTECODE=1
if [[ "${AI_RUN_NATIVE_CHECKS:-1}" == 1 ]]; then rustup target add "$target"; fi
# New-build regression checks are host binaries: never compile these against the iOS simulator sysroot.
native_reused=0
if [[ "${AI_RUST_TEST_SCOPE:-all}" == pairing-public ]]; then
  mkdir -p "$work/evidence/pairing-proof"
  public_group() {
    local group="$1" previous="$2" log="$3"; shift 3
    if [[ -n "$previous" ]]; then
      python3 "$cloud/pairing-public-proof.py" reuse --group "$group" --run-id "$previous"
      return
    fi
    [[ "${AI_PACKAGE_DEVICE_CANDIDATES:-0}" != 1 ]] || { echo 'Final public package requires prior passing proof; run affected checks first.' >&2; exit 2; }
    python3 "$cloud/pairing-public-proof.py" snapshot --group "$group"
    SDKROOT="$(xcrun --sdk macosx --show-sdk-path)" "$@" 2>&1 | tee "$work/evidence/pairing-proof/$log"
    python3 "$cloud/pairing-public-proof.py" finish --group "$group"
  }
  public_group vendor "${AI_REUSE_PAIRING_VENDOR_RUN:-}" rust-pairing.log cargo test --manifest-path "$root/downloads/idevice/idevice-0.1.68/Cargo.toml" --locked --no-default-features --features ring,remote_pairing --lib -- remote_pairing::authentication_tests:: remote_pairing::rp_pairing_file::tests:: remote_pairing::tlv::tests::
  public_group helper "${AI_REUSE_PAIRING_HELPER_RUN:-}" rust-helper.log cargo test --manifest-path "$root/downloads/idevice/idevice-0.1.68/Cargo.toml" --locked --no-default-features --features app-installer-rp-bootstrap --example app-installer-rp-bootstrap
  public_group transport "${AI_REUSE_PAIRING_TRANSPORT_RUN:-}" rust-transport.log cargo test --manifest-path "$root/app-installer/core/Cargo.toml" --locked --lib engine::transport::tests::public_remote_transport_
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
package_candidates() {
if [[ "${AI_PACKAGE_DEVICE_CANDIDATES:-0}" == 1 ]]; then
  if bash "$root/app-installer/build/package-rp-bootstrap-public.sh" && \
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
}
if [[ -n "${AI_REUSE_PAIRING_NATIVE_RUN:-}" ]]; then
  [[ "${AI_NATIVE_TEST_SCOPE:-all}" == pairing-document || "${AI_NATIVE_TEST_SCOPE:-all}" == pairing-public ]] || { echo 'Native public proof requires its exact scope.' >&2; exit 2; }
  python3 "$cloud/pairing-public-proof.py" reuse --group native --run-id "$AI_REUSE_PAIRING_NATIVE_RUN"
  native_reused=1
fi
if [[ "${AI_RUN_NATIVE_CHECKS:-1}" != 1 || "$native_reused" == 1 ]]; then
  if [[ "${AI_RUST_TEST_SCOPE:-all}" == pairing-public && "${AI_PACKAGE_DEVICE_CANDIDATES:-0}" == 1 && "$native_reused" != 1 ]]; then
    echo 'Final public package also requires matching native proof.' >&2; exit 2
  fi
  package_candidates
  exit "$package_failed"
fi
if [[ "${AI_NATIVE_TEST_SCOPE:-all}" == pairing-document || "${AI_NATIVE_TEST_SCOPE:-all}" == pairing-public ]]; then
  python3 "$cloud/pairing-public-proof.py" snapshot --group native
fi
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
  pairing-document) native_test_args+=("-only-testing:AppInstallerCloudUITests/PairingDocumentReadTests/testCoordinatedPairingDocumentAcceptsMaterializedBytesAndRejectsUnsafeReads") ;;
  pairing-public) native_test_args+=("-only-testing:AppInstallerCloudUITests/PairingDocumentReadTests/testCoordinatedPairingDocumentAcceptsMaterializedBytesAndRejectsUnsafeReads" "-only-testing:AppInstallerCloudUITests/PairingConnectionGuardTests/testPinnedFormatAndDiscoveryMetadataRejectMixedOrUnpinnedInputs") ;;
  responsive) native_test_args+=("-only-testing:AppInstallerCloudUITests/AppInstallerCloudUITests/test02ResponsiveMainUsesLabelledTestOnlyFixture") ;;
  accessibility) native_test_args+=("-only-testing:AppInstallerCloudUITests/AppInstallerCloudUITests/test03AccessibilityTextKeepsControlsReadable" "-only-testing:AppInstallerCloudUITests/AppInstallerCloudUITests/test04KeyboardKeepsFocusedFieldsReachable") ;;
  authorization-cancel) native_test_args+=("-only-testing:AppInstallerCloudUITests/SecureStoreBootstrapTests/testCancellingOrdinaryPendingAuthenticationRejectsDelayedSyntheticSuccess") ;;
  *) echo 'Unsupported native test selection' >&2; exit 2;;
esac
xcodebuild test-without-building -project "$work/AppInstallerCloudSmoke.xcodeproj" -scheme AppInstallerCloudSmoke \
  -destination "platform=iOS Simulator,id=$owned_simulator" -parallel-testing-enabled NO \
  -derivedDataPath "$work/DerivedData" -resultBundlePath "$work/evidence/CloudUISmoke.xcresult" \
  CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- "${native_test_args[@]}" 2>&1 | tee "$work/evidence/xcodebuild.log"

if [[ "${AI_NATIVE_TEST_SCOPE:-all}" == pairing-document || "${AI_NATIVE_TEST_SCOPE:-all}" == pairing-public ]]; then
  cp "$work/evidence/xcodebuild.log" "$work/evidence/pairing-proof/native.log"
  python3 "$cloud/pairing-public-proof.py" finish --group native
fi
stop_display_driver
package_candidates
exit "$package_failed"
