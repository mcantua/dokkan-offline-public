#!/usr/bin/env python3
"""Content fingerprint of actual native engine inputs; no game data or private paths."""
from pathlib import Path
import hashlib
import os

REPO = Path(__file__).resolve().parents[3]
OD = REPO / "offline-dokkan"


def fingerprint():
    sources = [OD / "adapter/od_bridge.c", OD / "adapter/od_bridge.h",
               OD / "adapter/android/od_jni.c", Path(__file__),
               Path(__file__).with_name("master_archive_jni.c"),
               Path(__file__).with_name("CMakeLists.txt"),
               Path(__file__).with_name("build-native.sh"),
               Path(os.environ.get("OD_NDK_ROOT", str(REPO / "downloads/android-sdk/ndk/android-ndk-r28b"))) / "source.properties"]
    sources += [p for p in (OD / "core").glob("*.c")
                if p.name != "od_cli.c" and not p.name.startswith(("test_", "check_"))]
    sources += list((OD / "core").glob("*.h"))
    sources += list((OD / "content").glob("*.c")) + list((OD / "content").glob("*.h"))
    sources += [REPO / "downloads/sqlite-amalgamation/source" / name for name in ("sqlite3.c", "sqlite3.h")]
    result = hashlib.sha256(b"offline-native-api26-sqlite-threadsafe1-dqs0-no-extensions-16kb-v1\0")
    for source in sorted(sources):
        label = source.relative_to(REPO) if source.is_relative_to(REPO) else Path("ndk/source.properties")
        result.update(str(label).encode() + b"\0")
        result.update(source.read_bytes())
        result.update(b"\0")
    return result.hexdigest()


if __name__ == "__main__":
    print(fingerprint())
