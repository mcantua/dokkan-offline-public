#!/usr/bin/env python3
"""Select only the pinned current master from a seekable private cloud ZIP."""
import argparse
import errno
import hashlib
import json
import os
from pathlib import Path
import stat
import tempfile
import zipfile

SOURCE_ID = "16343EAlxRNmwtlc3HuKMxpOAwjFAz4L7"
ARCHIVE_BYTES = 26650901563
MASTER_BYTES = 114827264
MASTER_SHA256 = "f37296ef05e31000d9868741b18525a5d41311ccc152acb82c848b7b1c8ef14d"
MASTER_SUFFIX = "user/0/com.sparkingDokkan.GLB/files/assets/sqlite/current/en/database.db"


def _safe(path):
    return (isinstance(path, str) and 0 < len(path.encode()) <= 2048 and
            not path.startswith("/") and not any(ord(c) < 32 or ord(c) == 127 or c in "\\:%?#" for c in path) and
            not any(x in ("", ".", "..") for x in path.split("/")))


def _identity(stream):
    s = os.fstat(stream.fileno())
    if not stat.S_ISREG(s.st_mode):
        raise ValueError("Expected regular source")
    return s.st_dev, s.st_ino, s.st_size, s.st_mtime_ns


def _digest(path, size, expected):
    if path.is_symlink():
        return False
    try:
        with path.open("rb") as source:
            before = _identity(source)
            if before[2] != size:
                return False
            h = hashlib.sha256()
            for data in iter(lambda: source.read(1024 * 1024), b""):
                h.update(data)
            return h.hexdigest() == expected and before == _identity(source)
    except OSError:
        return False


def _publish(temporary, output):
    """No replace: hard-link publication, or owned reservation on Drive FUSE.

    Google Drive cloud mounts may lack hard links. The fallback atomically
    replaces only our own still-empty exclusive reservation, never a pre-existing
    file. A reader must still require the pinned length/hash before admission.
    """
    try:
        os.link(temporary, output, follow_symlinks=False)
        temporary.unlink()
        return
    except OSError as error:
        if error.errno not in (errno.EPERM, errno.EOPNOTSUPP, errno.ENOSYS, errno.EXDEV):
            raise
    fd = os.open(output, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
    owned = None
    try:
        owned = os.fstat(fd)
        current = output.lstat()
        if (current.st_dev, current.st_ino, current.st_size, current.st_mtime_ns) != (
                owned.st_dev, owned.st_ino, 0, owned.st_mtime_ns):
            raise ValueError("Publication reservation changed")
        os.replace(temporary, output)
        owned = None
    finally:
        os.close(fd)
        if owned is not None:
            try:
                current = output.lstat()
                if (current.st_dev, current.st_ino, current.st_size, current.st_mtime_ns) == (
                        owned.st_dev, owned.st_ino, 0, owned.st_mtime_ns):
                    output.unlink()
            except FileNotFoundError:
                pass


def extract_export_master(source, output, *, archive_bytes=ARCHIVE_BYTES,
                          master_bytes=MASTER_BYTES, master_sha256=MASTER_SHA256):
    source, output = Path(source), Path(output)
    receipt_path = output.with_suffix(output.suffix + ".receipt.json")
    if (source.is_symlink() or output.is_symlink() or receipt_path.is_symlink() or
            output.resolve() == source.resolve() or not 0 < master_bytes <= 128 * 1024**2 or
            len(master_sha256) != 64 or any(c not in "0123456789abcdef" for c in master_sha256)):
        raise ValueError("Input/output identity rejected")
    output.parent.mkdir(parents=True, exist_ok=True)
    lock = output.with_name(output.name + ".extract-lock")
    temporary = None
    lock_fd = os.open(lock, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
    try:
        with source.open("rb") as original:
            before = _identity(original)
            if before[2] != archive_bytes:
                raise ValueError("Original ZIP length does not match the pinned export")
            reused = output.exists()
            if reused:
                if not _digest(output, master_bytes, master_sha256):
                    raise ValueError("Different existing output preserved")
            else:
                with zipfile.ZipFile(original) as archive:
                    entries = archive.infolist()
                    if len(entries) > 200000:
                        raise ValueError("ZIP inventory limit exceeded")
                    selected = [x for x in entries if
                                (x.filename == MASTER_SUFFIX or x.filename.endswith("/" + MASTER_SUFFIX))]
                    if (len(selected) != 1 or not _safe(selected[0].filename) or
                            selected[0].is_dir() or stat.S_ISLNK(selected[0].external_attr >> 16) or
                            selected[0].file_size != master_bytes):
                        raise ValueError("Expected one exact safe pinned master member")
                    fd, name = tempfile.mkstemp(prefix=".current-export-master-", suffix=".partial", dir=output.parent)
                    temporary = Path(name)
                    total, h = 0, hashlib.sha256()
                    with os.fdopen(fd, "wb") as target, archive.open(selected[0]) as stream:
                        for data in iter(lambda: stream.read(1024 * 1024), b""):
                            total += len(data)
                            if total > master_bytes:
                                raise ValueError("Selected member exceeded its pinned length")
                            h.update(data)
                            target.write(data)
                        if total != master_bytes or h.hexdigest() != master_sha256:
                            raise ValueError("Selected master did not match the pinned export")
                        target.flush()
                        os.fsync(target.fileno())
                        os.fchmod(target.fileno(), 0o400)
                if before != _identity(original):
                    raise ValueError("Original ZIP changed during selective reading")
                _publish(temporary, output)
                temporary = None
            if before != _identity(original):
                raise ValueError("Original ZIP changed")
        result = {"schema": 1, "source_archive_drive_id": SOURCE_ID,
                  "source_archive_bytes": archive_bytes, "source_member_suffix": MASTER_SUFFIX,
                  "master_bytes": master_bytes, "master_sha256": master_sha256,
                  "original_archive_modified": False, "whole_archive_copied_or_rehashed": False,
                  "player_data_or_keys_read": False, "reused_verified_output": reused,
                  "game_master_admitted": False}
        with output.open("rb") as check:
            result["plaintext_sqlite"] = check.read(16) == b"SQLite format 3\0"
        if receipt_path.exists():
            prior = json.loads(receipt_path.read_text())
            if any(prior.get(k) != result[k] for k in ("source_archive_drive_id", "master_bytes", "master_sha256")):
                raise ValueError("Different existing receipt preserved")
        else:
            fd, name = tempfile.mkstemp(prefix=".current-master-receipt-", suffix=".partial", dir=output.parent)
            temporary = Path(name)
            with os.fdopen(fd, "w") as receipt:
                receipt.write(json.dumps(result, indent=2) + "\n")
                receipt.flush()
                os.fsync(receipt.fileno())
            _publish(temporary, receipt_path)
            temporary = None
        return result
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)
        os.close(lock_fd)
        lock.unlink()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    try:
        result = extract_export_master(args.source, args.output)
    except (ValueError, OSError, zipfile.BadZipFile, json.JSONDecodeError, KeyError):
        raise SystemExit("Selective extraction stopped; source ZIP and prior working files were preserved. No keys or account data were emitted.")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
