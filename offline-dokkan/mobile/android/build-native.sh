#!/bin/bash
# Cloud/Linux NDK build using already provisioned public dependencies. No downloads or game files.
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
REPO=$(cd "$HERE/../../.." && pwd)
OD="$REPO/offline-dokkan"
NDK=${OD_NDK_ROOT:-$REPO/downloads/android-sdk/ndk/android-ndk-r28b}
TOOLS="$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin"
SQLITE="$REPO/downloads/sqlite-amalgamation/source"
OUT=${OD_ANDROID_BUILD:-$OD/adapter/build/android-native}
test -f "$NDK/source.properties" && test -x "$TOOLS/clang" || { echo 'Provision Android NDK r28b first.' >&2; exit 1; }
python3 "$OD/mobile/setup-sqlite.py" --check
SOURCE_PIN=$(python3 "$HERE/native-fingerprint.py")
CORE_SOURCES=()
for SOURCE in "$OD/core/"*.c; do
  case "${SOURCE##*/}" in od_cli.c|test_*.c|check_*.c) continue;; esac
  CORE_SOURCES+=("$SOURCE")
done
mkdir -p "$OUT"
WORK=""
cleanup(){ if [ -n "$WORK" ]; then rm -rf "$WORK"; fi; }
trap cleanup EXIT
for ABI in arm64-v8a x86_64; do
  case "$ABI" in arm64-v8a) TARGET=aarch64-linux-android26;; x86_64) TARGET=x86_64-linux-android26;; esac
  CC="$TOOLS/$TARGET-clang"
  test -x "$CC" || { echo 'Missing Android target compiler.' >&2; exit 1; }
  WORK=$(mktemp -d "$OUT/.compile-$ABI-XXXXXX")
  COMMON=(-O2 -std=c11 -fPIC -DSQLITE_THREADSAFE=1 -DSQLITE_OMIT_LOAD_EXTENSION=1 -DSQLITE_DQS=0 -I"$SQLITE")
  mkdir -p "$OUT/$ABI"
  SQLITE_PIN=$(python3 - "$SQLITE" "$NDK/source.properties" "$TARGET" <<'PY'
import hashlib,pathlib,sys
source,properties,target=sys.argv[1:];digest=hashlib.sha256(b'c11-O2-fPIC-hidden-threadsafe1-omit-extensions-dqs0-v1')
for file in [pathlib.Path(source)/'sqlite3.c',pathlib.Path(source)/'sqlite3.h',pathlib.Path(properties)]:digest.update(file.read_bytes())
digest.update(target.encode());print(digest.hexdigest())
PY
  )
  if [ ! -f "$OUT/$ABI/sqlite.o" ] || [ ! -f "$OUT/$ABI/sqlite.sha256" ] || [ "$(cat "$OUT/$ABI/sqlite.sha256")" != "$SQLITE_PIN" ]; then
    "$CC" "${COMMON[@]}" -fvisibility=hidden -c "$SQLITE/sqlite3.c" -o "$WORK/sqlite.o"
    mv "$WORK/sqlite.o" "$OUT/$ABI/sqlite.o"
    printf '%s\n' "$SQLITE_PIN" > "$OUT/$ABI/sqlite.sha256"
  fi
  "$CC" "${COMMON[@]}" -Wall -Wextra -Werror -fvisibility=hidden -shared \
    "$OD/adapter/od_bridge.c" "$OD/adapter/android/od_jni.c" \
    "$HERE/master_archive_jni.c" "$OD/content/master_archive.c" \
    "${CORE_SOURCES[@]}" "$OD/content/content.c" \
    "$OUT/$ABI/sqlite.o" -lm -lz -Wl,--no-undefined -Wl,-soname,libodbridge.so \
    -Wl,-z,max-page-size=16384 -Wl,-z,common-page-size=16384 -o "$WORK/libodbridge.so"
  DYNAMIC=$("$TOOLS/llvm-readelf" -d "$WORK/libodbridge.so")
  SYMBOLS=$("$TOOLS/llvm-readelf" --dyn-syms --wide "$WORK/libodbridge.so")
  if rg -q 'NEEDED.*libsqlite' <<< "$DYNAMIC"; then
    echo 'Unexpected private system SQLite dependency.' >&2; exit 1
  fi
  for METHOD in nativeOpen nativeExecute nativeSave nativeClose; do
    rg -q "Java_com_personal_offlinedokkan_OfflineCore_$METHOD" <<< "$SYMBOLS" || { echo 'Missing JNI host export.' >&2; exit 1; }
  done
  rg -q 'Java_com_personal_offlinedokkan_OfflineMasterArchive_extract' <<< "$SYMBOLS" || { echo 'Missing JNI archive picker export.' >&2; exit 1; }
  rg -q 'Java_com_personal_offlinedokkan_OfflinePlayerStore_snapshot' <<< "$SYMBOLS" || { echo 'Missing JNI private legacy snapshot export.' >&2; exit 1; }
  mv "$WORK/libodbridge.so" "$OUT/$ABI/libodbridge.so"
  python3 - "$OUT/$ABI" "$SOURCE_PIN" <<'PY'
import hashlib,json,pathlib,sys
out=pathlib.Path(sys.argv[1]);(out/'native-build.json').write_text(json.dumps({'source_sha256':sys.argv[2],'library_sha256':hashlib.sha256((out/'libodbridge.so').read_bytes()).hexdigest()})+'\n')
PY
  cleanup; WORK=""
  echo "Built $ABI native save engine with bundled public SQLite (API26+, 16KB alignment)."
done
test "$(python3 "$HERE/native-fingerprint.py")" = "$SOURCE_PIN" || { echo 'Native source changed during compilation; relink before packaging.' >&2; exit 1; }
