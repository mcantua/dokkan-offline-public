#!/usr/bin/env bash
# Build the small public-source Mac helper only on the selected hosted executor.
set -euo pipefail
[[ "${GITHUB_ACTIONS:-}" == true && "$(uname -s)" == Darwin ]] || { echo 'RP helper compilation requires the hosted Mac cloud job.' >&2; exit 1; }
root="$(cd "$(dirname "$0")/../.." && pwd)"
[[ "$(rustc --version)" == "rustc 1.99.1 "* ]] || { echo 'Pinned Rust 1.99.1 is required.' >&2; exit 1; }
command -v make >/dev/null
command -v perl >/dev/null
unset OPENSSL_NO_VENDOR OPENSSL_DIR OPENSSL_LIB_DIR OPENSSL_INCLUDE_DIR OPENSSL_STATIC
export SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"
export MACOSX_DEPLOYMENT_TARGET=12.0
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-$root/app-installer/core/target}"
export RUSTC_WRAPPER="" RUSTC_WORKSPACE_WRAPPER="" RUSTFLAGS="" CARGO_ENCODED_RUSTFLAGS=""
export CC_aarch64_apple_darwin="$(xcrun --sdk macosx --find clang)"
export CC_x86_64_apple_darwin="$CC_aarch64_apple_darwin"
export CXX_aarch64_apple_darwin="$(xcrun --sdk macosx --find clang++)"
export CXX_x86_64_apple_darwin="$CXX_aarch64_apple_darwin"
export AR_aarch64_apple_darwin="$(xcrun --sdk macosx --find ar)"
export AR_x86_64_apple_darwin="$AR_aarch64_apple_darwin"
export CFLAGS_aarch64_apple_darwin="-isysroot $SDKROOT -arch arm64 -mmacosx-version-min=12.0"
export CFLAGS_x86_64_apple_darwin="-isysroot $SDKROOT -arch x86_64 -mmacosx-version-min=12.0"
export CXXFLAGS_aarch64_apple_darwin="$CFLAGS_aarch64_apple_darwin"
export CXXFLAGS_x86_64_apple_darwin="$CFLAGS_x86_64_apple_darwin"
rustup target add aarch64-apple-darwin x86_64-apple-darwin
python3 "$root/app-installer/build/package-rp-bootstrap-cloud.py"
