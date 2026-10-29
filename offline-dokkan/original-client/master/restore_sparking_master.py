#!/usr/bin/env python3
"""Restore the supplied current master with the existing Creator SQLCipher4 codec.

The passphrase is read only in memory from the user's pinned original APK,
using SparkingSetup.java's existing verified version map. It is never accepted
as an argument, written, printed or embedded. Host.m's existing mode4 page
authentication/format is reused with standard Python crypto primitives.
"""
import argparse
import hashlib
import hmac
import json
import os
from pathlib import Path
import re
import resource
import sqlite3
import stat
import struct
import time
import zipfile

from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from master_contract import MasterContract

ROOT = Path(__file__).resolve().parents[3]
PAGE, RESERVE, ITERATIONS = 4096, 80, 256000
MAX_LIBRARY, MAX_DATABASE = 16 * 1024 * 1024, 512 * 1024 * 1024
LIBRARY = "lib/arm64-v8a/libbase.so"


class RestoreError(ValueError):
    """Only fixed diagnostic codes raised by this module, never backend data."""


def fail(code):
    raise RestoreError(code)


def wipe(value):
    if isinstance(value, bytearray):
        value[:] = b"\0" * len(value)


def apk_passphrase(apk):
    """Use the same pinned library/hash/offset admission as SparkingSetup.java."""
    spec = ROOT / "unit-creator/dock/src/com/personal/aihub/SparkingSetup.java"
    source = spec.read_text()
    matches = re.findall(r'if\s*\(\s*"([0-9a-f]{64})"\.equals\(sha\)\)\s*'
                         r'return new Version\("([0-9.]{1,16})",\s*([0-9]+),\s*([0-9]+)\);', source)
    versions = {sha: (version, int(db)) for sha, version, _, db in matches}
    if len(versions) != len(matches) or not versions:
        fail("APK_ADMISSION_SPEC_UNSUPPORTED")
    data = None
    try:
        with zipfile.ZipFile(apk) as z:
            candidates = [item for item in z.infolist() if item.filename == LIBRARY]
            if (len(candidates) != 1 or candidates[0].is_dir() or
                    not 600000 <= candidates[0].file_size <= MAX_LIBRARY or
                    candidates[0].compress_size > MAX_LIBRARY):
                fail("APK_LIBRARY_UNSUPPORTED")
            with z.open(candidates[0]) as stream:
                data = bytearray(stream.read(MAX_LIBRARY + 1))
            if len(data) != candidates[0].file_size:
                fail("APK_LIBRARY_INVALID")
        digest = hashlib.sha256(data).hexdigest()
        if digest not in versions:
            fail("APK_LIBRARY_VERSION_UNSUPPORTED")
        version, offset = versions[digest]
        if len(data) <= offset + 64 or data[offset + 64] != 0:
            fail("APK_DATABASE_FORMAT_UNAVAILABLE")
        password = bytearray(data[offset:offset + 64])
        if len(password) != 64 or any(c not in b"0123456789abcdefABCDEF" for c in password):
            wipe(password)
            fail("APK_DATABASE_FORMAT_UNAVAILABLE")
        return password, {"source_version": version, "library_sha256": digest,
                          "admission_source": "unit-creator/dock/src/com/personal/aihub/SparkingSetup.java"}
    finally:
        wipe(data)


def restore(apk, source, output, expected_source_sha256, expected_bytes):
    apk, source, output = Path(apk).absolute(), Path(source).absolute(), Path(output).absolute()
    if (not re.fullmatch(r"[0-9a-f]{64}", expected_source_sha256) or
            type(expected_bytes) is not int or not PAGE <= expected_bytes <= MAX_DATABASE or
            expected_bytes % PAGE or output in (apk, source) or output.exists() or output.is_symlink() or
            any(p.is_symlink() for p in output.parents)):
        fail("RESTORE_INPUT_INVALID")
    output.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    stage = output.with_name(output.name + ".restoring")
    if stage.exists() or stage.is_symlink():
        fail("RESTORE_STAGE_PRESERVED")
    password = enc_key = mac_key = None
    created = False
    source_digest, plain_digest = hashlib.sha256(), hashlib.sha256()
    try:
        password, provenance = apk_passphrase(apk)
        fd = os.open(source, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
        with os.fdopen(fd, "rb") as encrypted:
            before = os.fstat(encrypted.fileno())
            if not stat.S_ISREG(before.st_mode) or before.st_size != expected_bytes:
                fail("RESTORE_SOURCE_LENGTH_MISMATCH")
            first = encrypted.read(PAGE)
            if len(first) != PAGE or first.startswith(b"SQLite format 3\0"):
                fail("RESTORE_ENCRYPTED_INPUT_REQUIRED")
            salt = first[:16]
            enc_key = bytearray(hashlib.pbkdf2_hmac("sha512", password, salt, ITERATIONS, 32))
            mac_salt = bytes(v ^ 0x3a for v in salt)
            mac_key = bytearray(hashlib.pbkdf2_hmac("sha512", enc_key, mac_salt, 2, 32))
            wipe(password)
            password = None
            encrypted.seek(0)
            usable = PAGE - RESERVE
            with stage.open("xb") as plain:
                created = True
                os.chmod(stage, 0o600)
                for page_number in range(1, expected_bytes // PAGE + 1):
                    page = encrypted.read(PAGE)
                    if len(page) != PAGE:
                        fail("RESTORE_SOURCE_CHANGED")
                    source_digest.update(page)
                    offset = 16 if page_number == 1 else 0
                    auth = hmac.new(mac_key, digestmod="sha512")
                    auth.update(page[offset:usable + 16])
                    auth.update(struct.pack("<I", page_number))
                    if not hmac.compare_digest(auth.digest(), page[usable + 16:]):
                        fail("RESTORE_PAGE_AUTHENTICATION_FAILED")
                    decryptor = Cipher(algorithms.AES(enc_key), modes.CBC(page[usable:usable + 16])).decryptor()
                    data = decryptor.update(page[offset:usable]) + decryptor.finalize()
                    if page_number == 1:
                        if (int.from_bytes(data[:2], "big") != PAGE or data[4] < RESERVE or data[5:8] != bytes((64, 32, 32))):
                            fail("RESTORE_SQLITE_HEADER_UNSUPPORTED")
                        data = b"SQLite format 3\0" + data
                    data += b"\0" * RESERVE
                    if len(data) != PAGE:
                        fail("RESTORE_PAGE_LENGTH_INVALID")
                    plain.write(data)
                    plain_digest.update(data)
                if encrypted.read(1):
                    fail("RESTORE_SOURCE_CHANGED")
                plain.flush()
                os.fsync(plain.fileno())
            after = os.fstat(encrypted.fileno())
            if ((before.st_dev, before.st_ino, before.st_size, before.st_mtime_ns) !=
                    (after.st_dev, after.st_ino, after.st_size, after.st_mtime_ns) or
                    source_digest.hexdigest() != expected_source_sha256):
                fail("RESTORE_SOURCE_CHANGED")
        result_hash = plain_digest.hexdigest()
        with MasterContract(stage, result_hash, expected_bytes) as master:
            # The ordinary 20M-instruction query budget is for narrow schema/
            # settings reads. Fixed full-file integrity work needs its own
            # bounded deadline on this authenticated, size-pinned snapshot.
            deadline = time.monotonic() + 60
            master.db.set_progress_handler(lambda: int(time.monotonic() > deadline), 10000)
            try:
                if master.db.execute("PRAGMA quick_check").fetchall() != [("ok",)]:
                    fail("RESTORE_SQLITE_INTEGRITY_FAILED")
            finally:
                master.work = 0
                master.db.set_progress_handler(master._budget, 1000)
            summary = master.summary()
            table_count = master.db.execute("SELECT count(*) FROM sqlite_schema WHERE type='table' AND name NOT LIKE 'sqlite_%'").fetchone()[0]
        os.chmod(stage, 0o400)
        os.link(stage, output, follow_symlinks=False)
        stage.unlink()
        return {"format": "sqlcipher4-authenticated-master-restoration", "schema": 1,
                "source_encrypted_sha256": source_digest.hexdigest(), "source_bytes": expected_bytes,
                "plaintext_sha256": result_hash, "plaintext_bytes": expected_bytes,
                "authenticated_pages": expected_bytes // PAGE, "sqlite_quick_check": "ok",
                "cards": summary["cards"], "tables": table_count, "codec": "existing Host.m SqlCipherDecrypt mode4",
                "apk_provenance": provenance, "keys_written_or_emitted": False,
                "original_source_modified": False, "original_client_runtime_admitted": False}
    except BaseException:
        if created and stage.exists():
            stage.unlink()
        raise
    finally:
        wipe(password)
        wipe(enc_key)
        wipe(mac_key)


def main():
    # No process core dump should persist in-memory format material on failure.
    resource.setrlimit(resource.RLIMIT_CORE, (0, 0))
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("apk", type=Path)
    p.add_argument("encrypted_master", type=Path)
    p.add_argument("plaintext_output", type=Path)
    p.add_argument("--source-sha256", required=True)
    p.add_argument("--source-bytes", type=int, required=True)
    args = p.parse_args()
    try:
        print(json.dumps(restore(args.apk, args.encrypted_master, args.plaintext_output,
                                 args.source_sha256, args.source_bytes), indent=2))
    except RestoreError as error:
        raise SystemExit(str(error) + "; originals and prior outputs preserved.")
    except (ValueError, OSError, sqlite3.Error, zipfile.BadZipFile, KeyError, TypeError):
        # Never print crypto/backend exceptions, private paths or arbitrary input.
        raise SystemExit("MASTER_RESTORATION_FAILED; originals and prior outputs preserved.")


if __name__ == "__main__":
    main()
