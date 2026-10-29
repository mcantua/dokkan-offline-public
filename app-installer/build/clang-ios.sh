#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
exec "$AI_CLANG" --target=aarch64-apple-ios16.4 -isysroot "$IOS_SDK_PATH" -fuse-ld=lld -B"$AI_LLVM/bin" "$@"
