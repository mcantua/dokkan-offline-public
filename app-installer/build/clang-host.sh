#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
exec "$AI_CLANG" --target=x86_64-unknown-linux-gnu -fuse-ld=lld -B"$AI_LLVM/bin" "$@"
