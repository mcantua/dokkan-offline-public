#!/usr/bin/env python3
"""Verify private resource parts into new cloud-only source staging trees.

Preserves original bundle aliases; Documents aliases come only from the pinned
existing compatibility catalog. Never builds an app, opens a save, decodes a
database, or writes an existing application/container. No network is used.
"""
import argparse
import bisect
import ctypes
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import sqlite3
import stat
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[3]
PRIVATE = ROOT / "offline-dokkan/private"
sys.path[:0] = [str(ROOT / "offline-dokkan/content"),
                str(ROOT / "offline-dokkan/tools/startup-inputs")]
from iphone_asset_catalog import resource_mapping, MAX_TOTAL, MAX_FILE
from extract_original_resources import (SOURCE_SIZE, SOURCE_SHA256,
    EXPECTED_RESOURCES, PART_BYTES, PREFIX, FRAMEWORK_INFO, PRIVATE_COMPONENTS)

CATALOG_SHA256 = "a45b7c9f308e6d07452fd07ac2eeea28981be034554a73e35094552ba9163384"
CATALOG_BYTES = 36864
COMPATIBLE_REFERENCES = 27
EXPORT_MANIFEST_SHA256 = "2196f85c0d09e41967d6b0c08a1860fe57037c1f172cd8c048e9cad70f0f5a33"
STARTUP_INPUTS = {
    "Frameworks/AdjustSigSdk.framework/AdjustSigSdk": (649088,"564cdec07867697f3e23b8df760a5c3d9c067ff5dec2780dd905c83eaf2f96cd"),
    "database.db": (535552,"667e554a9cfb8c4765f05a1d85f0fdf707ade61562b50e3e5cd98ac52f997ba3"),
}


def digest(value):
    return isinstance(value, str) and re.fullmatch(r"[0-9a-f]{64}", value) is not None


def identity(info):
    return (info.st_dev, info.st_ino, info.st_size, info.st_mtime_ns, info.st_ctime_ns)


def directory(path):
    path = Path(path)
    if not path.is_absolute() or any(x in (".", "..") for x in path.parts):
        raise ValueError("Absolute native cloud directory required")
    fd = os.open("/", os.O_RDONLY | os.O_DIRECTORY | os.O_CLOEXEC)
    try:
        for part in path.parts[1:]:
            child = os.open(part, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW | os.O_CLOEXEC, dir_fd=fd)
            os.close(fd)
            fd = child
        return fd
    except BaseException:
        os.close(fd)
        raise


def readonly(path):
    path = Path(path)
    parent = directory(path.parent)
    try:
        fd = os.open(path.name, os.O_RDONLY | os.O_NOFOLLOW | os.O_CLOEXEC | os.O_NONBLOCK, dir_fd=parent)
    finally:
        os.close(parent)
    if not stat.S_ISREG(os.fstat(fd).st_mode):
        os.close(fd)
        raise ValueError("Regular input required")
    return fd


def hash_fd(fd, size):
    result = hashlib.sha256()
    at = 0
    while at < size:
        chunk = os.pread(fd, min(1024 * 1024, size-at), at)
        if not chunk:
            raise ValueError("Incomplete resource input")
        result.update(chunk)
        at += len(chunk)
    return result.hexdigest()


def read_pinned(path, limit, expected):
    if not digest(expected):
        raise ValueError("Expected exact SHA-256")
    fd = readonly(path)
    try:
        before = os.fstat(fd)
        if not 0 < before.st_size <= limit:
            raise ValueError("Input size outside its bound")
        chunks = []
        at = 0
        while at < before.st_size:
            data = os.pread(fd, min(1024 * 1024, before.st_size-at), at)
            if not data:
                raise ValueError("Incomplete input")
            chunks.append(data)
            at += len(data)
        raw = b"".join(chunks)
        if hashlib.sha256(raw).hexdigest() != expected or identity(before) != identity(os.fstat(fd)):
            raise ValueError("Input identity changed")
        return raw
    finally:
        os.close(fd)


def admit_manifest(raw):
    manifest = json.loads(raw)
    source = manifest.get("source", {})
    if (manifest.get("format") != "od-original-iphone-resource-parts-v1" or
        source.get("size") != SOURCE_SIZE or source.get("sha256") != SOURCE_SHA256 or
        source.get("whole_ipa_sha256_verified") is not True or
        manifest.get("selector") != "iphone_asset_catalog.resource_mapping" or
        manifest.get("bundle_and_tutorial_aliases_preserved") is not True or
        manifest.get("resource_candidates") != EXPECTED_RESOURCES or
        manifest.get("framework_metadata_members") != 1):
        raise ValueError("Wrong reviewed extraction source")
    parts, members = manifest.get("parts"), manifest.get("members")
    if not isinstance(parts, list) or not 1 <= len(parts) <= 128 or not isinstance(members, list) or len(members) != EXPECTED_RESOURCES+1:
        raise ValueError("Unexpected resource part/member inventory")
    position = 0
    for index, part in enumerate(parts, 1):
        size = part.get("size")
        if (part.get("index") != index or part.get("name") != f"{PREFIX}.part-{index:04d}.bin" or
            part.get("stream_offset") != position or type(size) is not int or not 0 < size <= PART_BYTES or
            not digest(part.get("sha256"))):
            raise ValueError("Invalid resource part")
        position += size
    if not 0 < position <= MAX_TOTAL or manifest.get("total_selected_bytes") != position:
        raise ValueError("Invalid resource stream extent")
    total = 0
    by_path = {}
    framework_count = 0
    for member in members:
        path = member.get("bundle_relative_path")
        size = member.get("size")
        if (not isinstance(path, str) or path in by_path or member.get("stream_offset") != total or
            type(size) is not int or not 0 <= size <= MAX_FILE or not digest(member.get("sha256")) or
            any(x.casefold() in PRIVATE_COMPONENTS for x in path.split("/"))):
            raise ValueError("Invalid or private resource member")
        if path == FRAMEWORK_INFO:
            if size > 128*1024 or member.get("mapping") != "required-framework-info" or member.get("canonical_candidate_path") is not None:
                raise ValueError("Invalid original framework metadata")
            framework_count += 1
        else:
            mapped = resource_mapping(path)
            if mapped is None or mapped != (member.get("canonical_candidate_path"), member.get("mapping")):
                raise ValueError("Resource mapping differs from reviewed selector")
        by_path[path] = member
        total += size
    if total != position or framework_count != 1:
        raise ValueError("Resource member coverage mismatch")
    return manifest, by_path


def compatible_aliases(catalog_path, members):
    raw = read_pinned(catalog_path, CATALOG_BYTES, CATALOG_SHA256)
    if len(raw) != CATALOG_BYTES:
        raise ValueError("Wrong original compatibility catalog size")
    db = sqlite3.connect(":memory:")
    try:
        db.deserialize(raw)
        db.execute("PRAGMA query_only=ON")
        db.execute("PRAGMA trusted_schema=OFF")
        meta = dict(db.execute("SELECT key,value FROM metadata"))
        if (meta.get("ipa_sha256") != SOURCE_SHA256 or meta.get("manifest_sha256") != EXPORT_MANIFEST_SHA256 or
            meta.get("verified_alias_schema") != "1" or meta.get("asset_bytes_verified") != "true"):
            raise ValueError("Wrong compatibility catalog source")
        prefix = meta.get("iphone_app_prefix", "")
        if not re.fullmatch(r"Payload/[^/]+\.app/", prefix):
            raise ValueError("Invalid original bundle prefix")
        rows = list(db.execute("SELECT a.path,a.bytes,a.sha256,m.zip_entry,m.mapping FROM assets a JOIN ipa_matches m USING(path) ORDER BY a.path"))
        if len(rows) != COMPATIBLE_REFERENCES:
            raise ValueError("Incomplete existing compatible reference set")
        output = []
        for canonical, size, sha, original, mapping in rows:
            if not original.startswith(prefix):
                raise ValueError("Original alias belongs to another bundle")
            relative = original[len(prefix):]
            member = members.get(relative)
            if (not member or member["size"] != size or member["sha256"] != sha or
                resource_mapping(relative) != (canonical, mapping) or not canonical.startswith("assets/")):
                raise ValueError("Compatible reference lacks exact original bytes")
            if db.execute("SELECT 1 FROM ipa_aliases WHERE zip_entry=? AND path=? AND mapping=?", (original,canonical,mapping)).fetchone() is None:
                raise ValueError("Preferred original alias was not admitted")
            output.append({"canonical_path": canonical, "bundle_relative_path": relative,
                           "size": size, "sha256": sha})
        return output
    finally:
        db.close()


def write_member(path, chunks, expected_size, expected_sha):
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    result = hashlib.sha256()
    total = 0
    with path.open("xb") as output:
        for chunk in chunks:
            total += len(chunk)
            if total > expected_size:
                raise ValueError("Resource exceeds exact member size")
            output.write(chunk)
            result.update(chunk)
        output.flush()
        os.fsync(output.fileno())
    if total != expected_size or result.hexdigest() != expected_sha:
        raise ValueError("Resource member SHA-256 mismatch")
    os.chmod(path, 0o400)


def publish_new_directory(stage, output):
    # This is an explicitly cloud-Linux source tool, not a Mac/device helper.
    # renameat2 NOREPLACE never replaces even an empty concurrently-created tree.
    if not sys.platform.startswith("linux"):
        raise ValueError("Cloud Linux staging required")
    libc = ctypes.CDLL(None, use_errno=True)
    rename = libc.renameat2
    rename.argtypes = [ctypes.c_int,ctypes.c_char_p,ctypes.c_int,ctypes.c_char_p,ctypes.c_uint]
    rename.restype = ctypes.c_int
    if rename(-100,os.fsencode(stage),-100,os.fsencode(output),1):
        raise OSError(ctypes.get_errno(), "New source staging tree could not be published")


def stage_resources(manifest_path, expected_manifest_sha256, parts_root, catalog_path, startup_root, output):
    for location in (manifest_path,parts_root,catalog_path,startup_root,output):
        if any(part.casefold() in {"save","saves"} for part in Path(location).parts):
            raise ValueError("Save directories are outside source staging scope")
    output = Path(output).absolute()
    private = PRIVATE.resolve(strict=True)
    parent = output.parent.resolve(strict=True)
    if not parent.is_relative_to(private) or output.name in ("", ".", "..") or os.path.lexists(output):
        raise ValueError("Absent private cloud output required; existing files preserved")
    output = parent/output.name
    if os.path.lexists(output):
        raise ValueError("Existing canonical output preserved")
    parent_fd = directory(parent)
    os.close(parent_fd)
    raw = read_pinned(Path(manifest_path).absolute(), 8*1024*1024, expected_manifest_sha256)
    manifest, members = admit_manifest(raw)
    aliases = compatible_aliases(Path(catalog_path).absolute(), members)
    required = {x["path"]:(x["size"],x["sha256"]) for x in manifest.get("existing_startup_inputs_required",[])}
    if required != STARTUP_INPUTS or len(manifest["existing_startup_inputs_required"]) != len(STARTUP_INPUTS):
        raise ValueError("Original startup binary pins changed")
    startup = {}
    for path,(size,sha) in STARTUP_INPUTS.items():
        startup[path] = read_pinned(Path(startup_root).absolute()/path,size,sha)
        if len(startup[path]) != size or path in members:
            raise ValueError("Original startup input size/path mismatch")
    part_directory = directory(Path(parts_root).absolute())
    opened = []
    stage = None
    stage_identity = None
    try:
        for part in manifest["parts"]:
            fd = os.open(part["name"],os.O_RDONLY|os.O_NOFOLLOW|os.O_CLOEXEC|os.O_NONBLOCK,dir_fd=part_directory)
            opened.append((fd,os.fstat(fd),part))
            info = opened[-1][1]
            if not stat.S_ISREG(info.st_mode) or info.st_size != part["size"] or hash_fd(fd,info.st_size) != part["sha256"]:
                raise ValueError("Resource part SHA-256 mismatch")
            if identity(info) != identity(os.fstat(fd)):
                raise ValueError("Resource part changed during verification")
        starts = [part["stream_offset"] for _,_,part in opened]
        def slices(member):
            at, remaining = member["stream_offset"],member["size"]
            while remaining:
                index = bisect.bisect_right(starts,at)-1
                fd,_,part = opened[index]
                offset = at-part["stream_offset"]
                count = min(1024*1024,remaining,part["size"]-offset)
                data = os.pread(fd,count,offset)
                if len(data) != count:
                    raise ValueError("Resource stream changed during staging")
                yield data
                at += count
                remaining -= count
        stage = Path(tempfile.mkdtemp(prefix=".original-resource-staging-",dir=parent))
        stage_identity = os.lstat(stage)
        for relative,member in members.items():
            write_member(stage/"bundle"/relative,slices(member),member["size"],member["sha256"])
        for relative,data in startup.items():
            size,sha = STARTUP_INPUTS[relative]
            write_member(stage/"bundle"/relative,(data,),size,sha)
        for alias in aliases:
            source = stage/"bundle"/alias["bundle_relative_path"]
            with source.open("rb") as input_file:
                write_member(stage/"documents"/alias["canonical_path"],iter(lambda:input_file.read(1024*1024),b""),alias["size"],alias["sha256"])
        for fd,before,part in opened:
            after = os.stat(part["name"],dir_fd=part_directory,follow_symlinks=False)
            if identity(before) != identity(os.fstat(fd)) or identity(before) != identity(after):
                raise ValueError("Resource part changed before publication")
        receipt = {"format":"od-original-resource-source-staging-v1", "source_ipa_sha256":SOURCE_SHA256,
                   "extraction_manifest_sha256":expected_manifest_sha256,"compatible_catalog_sha256":CATALOG_SHA256,
                   "original_bundle_members":len(members)+len(startup),"original_resource_candidates":EXPECTED_RESOURCES,
                   "canonical_documents_aliases":aliases,"all_original_aliases_preserved":True,
                   "canonical_aliases_derived_from_structural_candidates_only":False,
                   "preferred_master_or_user_state_staged":False,"original_opaque_bundle_seed_staged":True,
                   "actual_app_documents_written":False,
                   "genuine_shell_and_prepared_engine_included":False,
                   "native_execution_verified":False,"playable_build":False}
        (stage/"staging-receipt.json").write_text(json.dumps(receipt,indent=2,sort_keys=True)+"\n")
        os.chmod(stage/"staging-receipt.json",0o400)
        publish_new_directory(stage,output)
        stage = None
        return receipt
    finally:
        for fd,_,_ in opened:
            os.close(fd)
        os.close(part_directory)
        if stage is not None:
            info = os.lstat(stage)
            if (info.st_dev,info.st_ino) == (stage_identity.st_dev,stage_identity.st_ino) and shutil.rmtree.avoids_symlink_attacks:
                shutil.rmtree(stage)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifest",type=Path)
    parser.add_argument("parts",type=Path)
    parser.add_argument("compatible_catalog",type=Path)
    parser.add_argument("startup_inputs",type=Path)
    parser.add_argument("output",type=Path)
    parser.add_argument("--manifest-sha256",required=True)
    args = parser.parse_args()
    try:
        receipt = stage_resources(args.manifest,args.manifest_sha256,args.parts,args.compatible_catalog,args.startup_inputs,args.output)
    except (OSError,ValueError,KeyError,TypeError,AttributeError,sqlite3.Error,json.JSONDecodeError):
        raise SystemExit("Original-resource source staging stopped; original parts and existing outputs preserved.")
    print(json.dumps({"original_bundle_members":receipt["original_bundle_members"],
        "canonical_documents_aliases":len(receipt["canonical_documents_aliases"]),
        "scope":"Private cloud source staging only; no app build, native launch or live Documents write"}))


if __name__ == "__main__":
    main()
