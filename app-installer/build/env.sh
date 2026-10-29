#!/usr/bin/env bash
# Source from build/check commands; all downloaded tools and caches stay in this repo.
AI_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export AI_DOWNLOADS_ROOT="${AI_DOWNLOADS_ROOT:-$AI_ROOT/downloads}"
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-$AI_ROOT/app-installer/core/target}"
export AI_BUILD_OUTPUT_DIR="${AI_BUILD_OUTPUT_DIR:-$AI_ROOT/builds}"
python3 - "$AI_ROOT" "$AI_DOWNLOADS_ROOT" "$CARGO_TARGET_DIR" "$AI_BUILD_OUTPUT_DIR" <<'PY'
from pathlib import Path
import sys
root,downloads,target,output=map(lambda s:Path(s).resolve(),sys.argv[1:])
downloads.relative_to(root/'downloads')
for path in [target,output]: path.relative_to(root)
PY
export CARGO_HOME="$AI_DOWNLOADS_ROOT/rust-toolchain/cargo"
export RUSTUP_HOME="$AI_DOWNLOADS_ROOT/rust-toolchain/rustup"
export PATH="$CARGO_HOME/bin:$PATH"
export RUSTC="$CARGO_HOME/bin/rustc"
export RUSTDOC="$CARGO_HOME/bin/rustdoc"
export CARGO_INCREMENTAL=0
# Compiler wrappers/caches outside the chosen local toolchain must not affect this build.
export RUSTC_WRAPPER=""
export RUSTC_WORKSPACE_WRAPPER=""
export IOS_SDK_PATH="${IOS_SDK_PATH:-$AI_DOWNLOADS_ROOT/apple-sdk/source/iPhoneOS16.5.sdk}"
export SDKROOT="$IOS_SDK_PATH"
export IPHONEOS_DEPLOYMENT_TARGET=16.4
AI_LLVM="$AI_DOWNLOADS_ROOT/llvm/root/usr/lib/llvm-19"
export AI_CLANG="${CLANG:-$AI_LLVM/bin/clang}"
# Deliberately do not inherit another checkout's LLVM-library path.
export LD_LIBRARY_PATH="$AI_DOWNLOADS_ROOT/llvm/root/usr/lib/x86_64-linux-gnu"
export CC_aarch64_apple_ios="$AI_ROOT/app-installer/build/clang-ios.sh"
export CXX_aarch64_apple_ios="$AI_ROOT/app-installer/build/clang-ios.sh"
export AR_aarch64_apple_ios="$AI_LLVM/bin/llvm-ar"
export RANLIB_aarch64_apple_ios="$AI_LLVM/bin/llvm-ranlib"
export CARGO_TARGET_AARCH64_APPLE_IOS_LINKER="$AI_ROOT/app-installer/build/clang-ios.sh"
export CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER="$AI_ROOT/app-installer/build/clang-host.sh"
export CC_x86_64_unknown_linux_gnu="$AI_LLVM/bin/clang"
export CXX_x86_64_unknown_linux_gnu="$AI_LLVM/bin/clang++"
export AR_x86_64_unknown_linux_gnu="$AI_LLVM/bin/llvm-ar"
export RANLIB_x86_64_unknown_linux_gnu="$AI_LLVM/bin/llvm-ranlib"
export CFLAGS_aarch64_apple_ios="-isysroot $IOS_SDK_PATH -miphoneos-version-min=16.4"
export CXXFLAGS_aarch64_apple_ios="$CFLAGS_aarch64_apple_ios"
