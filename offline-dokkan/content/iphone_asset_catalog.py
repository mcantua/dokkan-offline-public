#!/usr/bin/env python3
"""Admit byte-identical iPhone bundle resources into an imported content catalog.

This is content identity evidence, not a claim that downloaded Android content,
an archive decoder or the original iPhone game has run successfully.
"""
import argparse
from collections import Counter
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import plistlib
import re
import sqlite3
import stat
import zipfile

from export_asset_catalog import canonical

MAX_ENTRIES = 20000
MAX_TOTAL = 4 * 1024**3
MAX_FILE = 512 * 1024**2
RESOURCE_ROOTS = frozenset("""
bgm se voice layout outgame character script item ingame sd_battle sugoroku movie
card_category lua gasha packaged_movies card_transform potential dokkan_field
mydata download_scene origin card_metamorphic kobetu_battle fonts shader
card_costume card thumb condition_special panel_mission comic_text dbstory
genkai_battle
""".split())
RESOURCE_EXTENSIONS = frozenset((".cpk", ".acb", ".awb", ".ttf", ".otf",
    ".png", ".pvr", ".ktx", ".webp", ".vsh", ".fsh", ".lua", ".luac"))


def sha_stream(stream, limit):
    digest, length, header = hashlib.sha256(), 0, b""
    while True:
        data = stream.read(1024 * 1024)
        if not data:
            return digest.hexdigest(), length, header
        length += len(data)
        if length > limit:
            raise ValueError("Resource limit exceeded")
        if not header:
            header = data[:16]
        digest.update(data)


def file_kind(header, extension):
    # No raw header bytes or arbitrary strings are included in the output.
    for magic, name in ((b"CPK ", "cri-cpk"), (b"@UTF", "cri-utf"),
                        (b"AFS2", "cri-awb"), (b"\x89PNG\r\n\x1a\n", "png"),
                        (b"\x00\x01\x00\x00", "truetype"), (b"OTTO", "opentype"),
                        (b"\x1bLua", "lua-bytecode"), (b"SQLite format 3\0", "sqlite3")):
        if header.startswith(magic):
            return name
    return "opaque-" + extension.lstrip(".")


def resource_mapping(relative):
    """Only these two explicit structural candidates may reach hash admission."""
    relative = canonical(relative)
    mapping = "bundle-root"
    if relative.startswith("tutorial0/"):
        relative = relative[len("tutorial0/"):]
        mapping = "tutorial-resource-candidate"
    path = PurePosixPath(relative)
    if (path.parts[0] not in RESOURCE_ROOTS or
            path.suffix.lower() not in RESOURCE_EXTENSIONS):
        return None
    selected = "assets/" + relative
    # Match the stricter native catalog namespace before publishing a reference.
    if (any(ord(c) < 32 or ord(c) == 127 or c in "\\:%?#" for c in selected) or
            any(len(part.encode()) > 255 for part in selected.split("/")) or
            len(selected.encode()) > 1024):
        raise ValueError("Native resource path rejected")
    return selected, mapping


def manifest_assets(path, expected_hash, package):
    path = Path(path)
    if path.stat().st_size > 32 * 1024**2:
        raise ValueError("Manifest limit exceeded")
    raw = path.read_bytes()
    if hashlib.sha256(raw).hexdigest() != expected_hash:
        raise ValueError("Source manifest changed")
    rows = json.loads(raw)
    if not isinstance(rows, list) or len(rows) > 200000:
        raise ValueError("Invalid manifest")
    prefix = "user/0/" + package + "/files/"
    result, seen = {}, set()
    for row in rows:
        if not isinstance(row, dict):
            raise ValueError("Invalid manifest record")
        original = canonical(row.get("path"))
        if original in seen:
            raise ValueError("Duplicate manifest path")
        seen.add(original)
        if not original.startswith(prefix + "assets/"):
            continue
        relative = original[len(prefix):]
        if relative == "assets/User" or relative.startswith("assets/User/"):
            continue
        size, digest = row.get("size"), row.get("sha256")
        if (type(size) is not int or not 0 <= size <= 8 * 1024**3 or
                not isinstance(digest, str) or not re.fullmatch("[a-f0-9]{64}", digest)):
            raise ValueError("Invalid asset identity")
        result[relative] = (size, digest)
    return result


def build_catalog(ipa, manifest, output, *, ipa_sha256, manifest_sha256,
                  package, bundle_id, version):
    for value in (ipa_sha256, manifest_sha256):
        if not isinstance(value, str) or not re.fullmatch("[a-f0-9]{64}", value):
            raise ValueError("Expected pinned SHA-256")
    if (not re.fullmatch("[A-Za-z0-9_.]+", package) or
            not re.fullmatch("[A-Za-z0-9_.-]+", bundle_id) or
            not re.fullmatch("[0-9.]+", version)):
        raise ValueError("Invalid source identity")
    ipa, output = Path(ipa), Path(output)
    staged = output.with_name(output.name + ".partial")
    if (output.exists() or output.is_symlink() or staged.exists() or staged.is_symlink() or
            output.resolve() in (ipa.resolve(), Path(manifest).resolve())):
        raise ValueError("Existing inputs/outputs were preserved")
    assets = manifest_assets(manifest, manifest_sha256, package)
    admitted, mappings, aliases, counts, formats = {}, {}, {}, Counter(), Counter()
    seed = None
    with ipa.open("rb") as source:
        before = os.fstat(source.fileno())
        if not stat.S_ISREG(before.st_mode) or before.st_size > 8 * 1024**3:
            raise ValueError("Invalid client input")
        digest, _, _ = sha_stream(source, 8 * 1024**3)
        if digest != ipa_sha256:
            raise ValueError("Client input changed")
        source.seek(0)
        with zipfile.ZipFile(source) as archive:
            entries = archive.infolist()
            if len(entries) > MAX_ENTRIES or sum(x.file_size for x in entries) > MAX_TOTAL:
                raise ValueError("ZIP resource limits exceeded")
            names = set()
            for entry in entries:
                canonical(entry.filename[:-1] if entry.is_dir() else entry.filename)
                if entry.filename in names or stat.S_ISLNK(entry.external_attr >> 16):
                    raise ValueError("Duplicate/symlink ZIP entry")
                names.add(entry.filename)
            infos = [x for x in entries if re.fullmatch(r"Payload/[^/]+\.app/Info\.plist", x.filename)]
            if len(infos) != 1 or infos[0].file_size > 2 * 1024**2:
                raise ValueError("Expected one bounded app identity")
            info = plistlib.loads(archive.read(infos[0]))
            if (info.get("CFBundleIdentifier") != bundle_id or
                    info.get("CFBundleShortVersionString") != version):
                raise ValueError("Wrong client identity/version")
            prefix = infos[0].filename.rsplit("/", 1)[0] + "/"
            for entry in entries:
                if not entry.filename.startswith(prefix) or entry.is_dir():
                    continue
                relative = entry.filename[len(prefix):]
                # This seed is inspected as opaque input, never installed as a full master.
                if relative == "database.db":
                    with archive.open(entry) as stream:
                        sha, size, header = sha_stream(stream, 2 * 1024**2)
                    seed = {"bytes": size, "sha256": sha,
                            "plaintext_sqlite": header == b"SQLite format 3\0",
                            "full_master_admitted": False}
                mapped = resource_mapping(relative)
                if mapped is None:
                    counts["non_resource_entries_excluded"] += 1
                    continue
                path, rule = mapped
                counts["resource_candidates"] += 1
                if path not in assets:
                    counts["absent_from_export"] += 1
                    continue
                size, expected = assets[path]
                if size != entry.file_size:
                    counts["different_size"] += 1
                    continue
                if size > MAX_FILE:
                    raise ValueError("Resource exceeds comparison limit")
                with archive.open(entry) as stream:
                    sha, read_size, header = sha_stream(stream, MAX_FILE)
                if read_size != size or sha != expected:
                    counts["different_sha256"] += 1
                    continue
                kind = file_kind(header, PurePosixPath(path).suffix.lower())
                counts["byte_identical_entries"] += 1
                formats[kind] += 1
                aliases[entry.filename] = (entry.filename, path, rule, kind)
                # Prefer an exact bundle-root path over a verified tutorial fallback.
                if path in admitted and mappings[path][2] == "bundle-root":
                    continue
                admitted[path] = (path, size, sha, PurePosixPath(path).suffix.lower())
                mappings[path] = (path, entry.filename, rule, kind)
        after = os.fstat(source.fileno())
        if (before.st_size, before.st_mtime_ns, before.st_ino) != (after.st_size, after.st_mtime_ns, after.st_ino):
            raise ValueError("Client changed during comparison")
    if not admitted:
        raise ValueError("No byte-identical resources found")
    counts["unique_admitted_references"] = len(admitted)
    metadata = {"schema": "1", "manifest_sha256": manifest_sha256,
                "source_package": package, "source_version": version,
                "ipa_sha256": ipa_sha256, "iphone_bundle_id": bundle_id,
                "iphone_app_prefix": prefix, "verified_alias_schema": "1",
                "asset_bytes_verified": "true", "ios_compatibility_verified": "false",
                "runtime_paths_verified": "false", "private_user_records_excluded": "all"}
    output.parent.mkdir(parents=True, exist_ok=True)
    db, created = None, False
    try:
        with staged.open("xb"):
            created = True
        db = sqlite3.connect(staged)
        db.executescript("CREATE TABLE metadata(key TEXT PRIMARY KEY,value TEXT NOT NULL);"
            "CREATE TABLE assets(path TEXT PRIMARY KEY,bytes INTEGER NOT NULL,sha256 TEXT NOT NULL,extension TEXT NOT NULL);"
            "CREATE TABLE ipa_matches(path TEXT PRIMARY KEY,zip_entry TEXT NOT NULL,mapping TEXT NOT NULL,format TEXT NOT NULL);"
            "CREATE TABLE ipa_aliases(zip_entry TEXT PRIMARY KEY,path TEXT NOT NULL,mapping TEXT NOT NULL,format TEXT NOT NULL);")
        with db:
            db.executemany("INSERT INTO metadata VALUES(?,?)", metadata.items())
            db.executemany("INSERT INTO assets VALUES(?,?,?,?)", sorted(admitted.values()))
            db.executemany("INSERT INTO ipa_matches VALUES(?,?,?,?)", sorted(mappings.values()))
            db.executemany("INSERT INTO ipa_aliases VALUES(?,?,?,?)", sorted(aliases.values()))
        db.close()
        db = None
        os.chmod(staged, 0o400)
        # Publish without replacing a concurrently created working catalog.
        os.link(staged, output, follow_symlinks=False)
        staged.unlink()
    except BaseException:
        if db is not None:
            db.close()
        if created and staged.exists():
            staged.unlink()
        raise
    return {"schema": 1, "ipa_sha256": ipa_sha256, "manifest_sha256": manifest_sha256,
            "bundle_id": bundle_id, "version": version, "counts": dict(counts),
            "verified_entry_formats": dict(formats), "catalog_reference_bytes": sum(x[1] for x in admitted.values()),
            "bundled_seed": seed, "runtime_paths_verified": False,
            "all_android_assets_compatible": False, "original_game_launch_verified": False}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("ipa", type=Path)
    parser.add_argument("manifest", type=Path)
    parser.add_argument("output", type=Path)
    for argument in ("ipa-sha256", "manifest-sha256", "package", "bundle-id", "version"):
        parser.add_argument("--" + argument, required=True)
    args = parser.parse_args()
    try:
        result = build_catalog(args.ipa, args.manifest, args.output,
            ipa_sha256=args.ipa_sha256, manifest_sha256=args.manifest_sha256,
            package=args.package, bundle_id=args.bundle_id, version=args.version)
    except (ValueError, OSError, sqlite3.Error, zipfile.BadZipFile, plistlib.InvalidFileException,
            json.JSONDecodeError, KeyError, TypeError):
        raise SystemExit("Resource comparison failed; originals and existing catalogs were preserved.")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
