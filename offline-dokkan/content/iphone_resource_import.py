#!/usr/bin/env python3
"""Stage exact hash-admitted iPhone resources; selectively extract pinned ZIP members."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import sqlite3
import stat
import zipfile

from export_asset_catalog import canonical
from iphone_asset_catalog import resource_mapping, sha_stream


def _identity(file):
    s = os.fstat(file.fileno())
    if not stat.S_ISREG(s.st_mode):
        raise ValueError("Expected regular input")
    return s.st_dev, s.st_ino, s.st_size, s.st_mtime_ns


def _hash(value):
    if not isinstance(value, str) or len(value) != 64 or any(c not in "0123456789abcdef" for c in value):
        raise ValueError("Expected pinned SHA-256")
    return value


def _copy(stream, output, expected_bytes, expected_hash, owned_fd=None):
    h, total = hashlib.sha256(), 0
    with (output.open("xb") if owned_fd is None else os.fdopen(owned_fd, "wb")) as destination:
        for data in iter(lambda: stream.read(1024 * 1024), b""):
            total += len(data)
            if total > expected_bytes:
                raise ValueError("Unexpected member length")
            h.update(data)
            destination.write(data)
        if total != expected_bytes or h.hexdigest() != expected_hash:
            raise ValueError("Unexpected member bytes")
        destination.flush()
        os.fsync(destination.fileno())
        os.fchmod(destination.fileno(), 0o400)


def _catalog(path, catalog_sha256, manifest_sha256, ipa_sha256):
    path = Path(path)
    if path.stat().st_size > 16 * 1024**2:
        raise ValueError("Catalog limit exceeded")
    with path.open("rb") as source:
        before = _identity(source)
        digest, _, _ = sha_stream(source, 16 * 1024**2)
        if digest != _hash(catalog_sha256) or _identity(source) != before:
            raise ValueError("Catalog changed")
    with sqlite3.connect(path.resolve().as_uri() + "?mode=ro&immutable=1", uri=True) as db:
        db.execute("PRAGMA trusted_schema=OFF")
        meta = dict(db.execute("SELECT key,value FROM metadata"))
        if (meta.get("schema") != "1" or meta.get("verified_alias_schema") != "1" or
                meta.get("manifest_sha256") != _hash(manifest_sha256) or
                meta.get("ipa_sha256") != _hash(ipa_sha256)):
            raise ValueError("Wrong catalog identity")
        rows = db.execute("SELECT a.path,a.bytes,a.sha256,m.zip_entry FROM assets a "
                          "JOIN ipa_matches m ON a.path=m.path ORDER BY a.path").fetchall()
    if not 1 <= len(rows) <= 100000 or sum(r[1] for r in rows) > 1024**3:
        raise ValueError("Invalid resource set")
    prefix = meta.get("iphone_app_prefix", "")
    if not prefix.startswith("Payload/") or not prefix.endswith(".app/") or prefix.count("/") != 2:
        raise ValueError("Invalid bundle prefix")
    for path, size, sha, member in rows:
        canonical(path)
        canonical(member)
        if (type(size) is not int or not 0 <= size <= 512 * 1024**2 or
                not member.startswith(prefix) or resource_mapping(member[len(prefix):])[0] != path):
            raise ValueError("Invalid admitted resource")
        _hash(sha)
    return meta, rows


def stage_resources(ipa, catalog, destination, *, catalog_sha256, manifest_sha256, ipa_sha256):
    """Source root becomes complete only after the final import receipt is written.

    Each selected resource is independently rehashed; the entire IPA need not be
    rehashed for an import whose catalog and resource bytes are already pinned.
    Existing roots/stages are preserved and never merged or overwritten.
    """
    ipa, destination = Path(ipa), Path(destination)
    if destination.exists() or destination.is_symlink():
        raise ValueError("An existing source root was preserved")
    meta, rows = _catalog(catalog, catalog_sha256, manifest_sha256, ipa_sha256)
    created = False
    try:
        destination.mkdir(mode=0o700)
        created = True
        with ipa.open("rb") as source:
            before = _identity(source)
            with zipfile.ZipFile(source) as archive:
                entries = archive.infolist()
                names = [entry.filename for entry in entries]
                if len(names) > 20000 or len(set(names)) != len(names):
                    raise ValueError("Invalid ZIP inventory")
                for path, size, sha, member in rows:
                    entry = archive.getinfo(member)
                    if (entry.is_dir() or stat.S_ISLNK(entry.external_attr >> 16) or
                            entry.file_size != size):
                        raise ValueError("Invalid selected ZIP member")
                    target = destination / path
                    target.parent.mkdir(parents=True, exist_ok=True)
                    part = target.with_name(target.name + ".partial")
                    with archive.open(entry) as stream:
                        _copy(stream, part, size, sha)
                    os.link(part, target, follow_symlinks=False)
                    part.unlink()
            if _identity(source) != before:
                raise ValueError("Source client changed")
        result = {"schema": 1, "catalog_sha256": catalog_sha256,
                  "manifest_sha256": manifest_sha256, "ipa_sha256": ipa_sha256,
                  "resources": len(rows), "bytes": sum(r[1] for r in rows),
                  "selected_resource_hashes_verified": True, "whole_ipa_rehashed": False,
                  "original_client_path_hook_installed": False, "codec_execution_verified": False}
        with (destination / ".od-iphone-import.json").open("x") as out:
            out.write(json.dumps(result, indent=2) + "\n")
            out.flush()
            os.fsync(out.fileno())
        return result
    except BaseException:
        if created:
            shutil.rmtree(destination)
        raise


def extract_member(archive_path, member, output, *, archive_bytes, member_bytes, member_sha256):
    """Select one exact member from a seekable cloud ZIP; never copy the full ZIP.

    A mounted cloud original is required for an archive beyond connector limits.
    Source identity here is its pinned length plus selected member identity, not
    a claim that the entire large archive has been rehashed.
    """
    archive_path, output = Path(archive_path), Path(output)
    member = canonical(member)
    expected = _hash(member_sha256)
    partial = output.with_name(output.name + ".partial")
    if (output.exists() or output.is_symlink() or partial.exists() or partial.is_symlink() or
            output.resolve() == archive_path.resolve() or
            type(member_bytes) is not int or not 0 < member_bytes <= 512 * 1024**2):
        raise ValueError("Existing files were preserved")
    created = False
    try:
        with archive_path.open("rb") as source:
            before = _identity(source)
            if before[2] != archive_bytes:
                raise ValueError("Wrong archive length")
            with zipfile.ZipFile(source) as archive:
                entries = archive.infolist()
                if len(entries) > 200000:
                    raise ValueError("ZIP inventory limit exceeded")
                candidates = [entry for entry in entries if entry.filename == member]
                if (len(candidates) != 1 or candidates[0].file_size != member_bytes or
                        candidates[0].is_dir() or stat.S_ISLNK(candidates[0].external_attr >> 16)):
                    raise ValueError("Selected member is absent or invalid")
                output.parent.mkdir(parents=True, exist_ok=True)
                with archive.open(candidates[0]) as stream:
                    # Reserve ownership first, so failures never erase a prior stage.
                    fd = os.open(partial, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
                    created = True
                    _copy(stream, partial, member_bytes, expected, owned_fd=fd)
            if _identity(source) != before:
                raise ValueError("Source archive changed")
        os.link(partial, output, follow_symlinks=False)
        partial.unlink()
        return {"bytes": member_bytes, "sha256": expected, "original_archive_modified": False,
                "whole_archive_downloaded_or_rehashed": False}
    except BaseException:
        if created and partial.exists():
            partial.unlink()
        raise


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    stage = commands.add_parser("stage")
    for argument in ("ipa", "catalog", "destination"):
        stage.add_argument(argument, type=Path)
    for argument in ("catalog-sha256", "manifest-sha256", "ipa-sha256"):
        stage.add_argument("--" + argument, required=True)
    extract = commands.add_parser("extract-member")
    extract.add_argument("archive", type=Path)
    extract.add_argument("member")
    extract.add_argument("output", type=Path)
    extract.add_argument("--archive-bytes", type=int, required=True)
    extract.add_argument("--member-bytes", type=int, required=True)
    extract.add_argument("--member-sha256", required=True)
    args = parser.parse_args()
    try:
        if args.command == "stage":
            result = stage_resources(args.ipa, args.catalog, args.destination,
                catalog_sha256=args.catalog_sha256, manifest_sha256=args.manifest_sha256,
                ipa_sha256=args.ipa_sha256)
        else:
            result = extract_member(args.archive, args.member, args.output,
                archive_bytes=args.archive_bytes, member_bytes=args.member_bytes,
                member_sha256=args.member_sha256)
    except (ValueError, OSError, sqlite3.Error, zipfile.BadZipFile, KeyError, TypeError):
        raise SystemExit("Content import failed; original inputs and prior working copies were preserved.")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
