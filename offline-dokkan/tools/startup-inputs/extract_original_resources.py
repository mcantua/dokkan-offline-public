"""Restore the existing original-iPhone safe resource set in Google's cloud.

Uses iphone_asset_catalog.resource_mapping unchanged. No app build, game
execution, save/key/provisioning extraction, source overwrite, or Mac copy.
Runtime Drive IDs are supplied only by the private notebook configuration.
"""
import hashlib
import io
import json
from pathlib import Path
import plistlib
import re
import stat
import tempfile
import zipfile

from iphone_asset_catalog import (resource_mapping, MAX_ENTRIES, MAX_TOTAL,
                                 MAX_FILE)
from export_asset_catalog import canonical

SOURCE_SIZE = 1144358271
SOURCE_SHA256 = "0ea61911a09c4e7735f2d7b32b7b2c6c6977c1f4acf0a9db278049528b662816"
EXPECTED_RESOURCES = 1067
PART_BYTES = 31 * 1024 * 1024
OWNER = "odOriginalResources"
PREFIX = "Private-iPhone-original-resources"
FRAMEWORK_INFO = "Frameworks/AdjustSigSdk.framework/Info.plist"
# Stronger exclusion inside the existing resource allowlist; never expands it.
PRIVATE_COMPONENTS = frozenset(("user", "save", "saves", "private", "keys",
    "keychain", "provisioning", "_codesignature", "codesignature"))


def valid_id(value):
    if not isinstance(value, str) or not re.fullmatch(r"[A-Za-z0-9_-]{10,160}", value):
        raise ValueError("Invalid runtime Drive ID")
    return value


def digest_file(path, expected_size):
    digest = hashlib.sha256()
    size = 0
    with Path(path).open("rb") as source:
        for chunk in iter(lambda: source.read(8 * 1024 * 1024), b""):
            size += len(chunk)
            if size > expected_size:
                raise ValueError("Cloud source exceeded its exact pinned size")
            digest.update(chunk)
    if size != expected_size:
        raise ValueError("Incomplete cloud source")
    return digest.hexdigest()


def select_entries(archive, expected_count=EXPECTED_RESOURCES):
    entries = archive.infolist()
    if len(entries) > MAX_ENTRIES or sum(x.file_size for x in entries) > MAX_TOTAL:
        raise ValueError("Original ZIP exceeds existing resource inventory limits")
    names = set()
    for entry in entries:
        canonical(entry.filename[:-1] if entry.is_dir() else entry.filename)
        if (entry.filename in names or stat.S_ISLNK(entry.external_attr >> 16) or
                entry.flag_bits & 1):
            raise ValueError("Duplicate, symlink, or encrypted ZIP entry")
        names.add(entry.filename)
    roots = [x.filename.rsplit("/", 1)[0] + "/" for x in entries
             if re.fullmatch(r"Payload/[^/]+\.app/Info\.plist", x.filename)]
    if len(roots) != 1:
        raise ValueError("Expected one original iPhone app root")
    prefix = roots[0]
    selected = []
    info_count = 0
    for entry in entries:
        if entry.is_dir() or not entry.filename.startswith(prefix):
            continue
        relative = entry.filename[len(prefix):]
        if relative == FRAMEWORK_INFO:
            if entry.file_size > 128 * 1024:
                raise ValueError("Framework metadata is oversized")
            selected.append((entry, relative, None, "required-framework-info"))
            info_count += 1
            continue
        mapping = resource_mapping(relative)
        if mapping is None:
            continue
        if any(part.casefold() in PRIVATE_COMPONENTS for part in relative.split("/")):
            raise ValueError("Private path component inside a resource candidate; review required")
        if entry.file_size > MAX_FILE:
            raise ValueError("Original resource exceeds existing member limit")
        canonical_path, rule = mapping
        selected.append((entry, relative, canonical_path, rule))
    count = sum(rule != "required-framework-info" for _, _, _, rule in selected)
    if count != expected_count or info_count != 1:
        raise ValueError("Safe resource count or exact framework metadata changed; no output admitted")
    return sorted(selected, key=lambda row: row[0].header_offset)


def stream_parts(archive, selected, publish_part, part_bytes=PART_BYTES):
    """Split raw selected bytes, preserving original bundle/tutorial aliases."""
    if not 65536 <= part_bytes < 32 * 1024 * 1024:
        raise ValueError("Part size must stay below 32 MiB")
    pending = bytearray()
    position = 0
    parts = []
    members = []

    def flush():
        nonlocal pending
        if not pending:
            return
        data = bytes(pending)
        index = len(parts) + 1
        sha = hashlib.sha256(data).hexdigest()
        md5 = hashlib.md5(data).hexdigest()  # Drive transfer checksum, not source trust.
        identity = publish_part(index, data, sha, md5)
        parts.append({"index": index, "name": f"{PREFIX}.part-{index:04d}.bin",
                      "id": identity, "stream_offset": position - len(data),
                      "size": len(data), "sha256": sha, "md5": md5})
        pending = bytearray()

    for entry, relative, canonical_path, rule in selected:
        start = position
        digest = hashlib.sha256()
        count = 0
        with archive.open(entry) as source:
            if rule == "required-framework-info":
                data = source.read(128 * 1024 + 1)
                if len(data) != entry.file_size:
                    raise ValueError("Framework metadata size mismatch")
                parsed = plistlib.loads(data)
                if (not isinstance(parsed, dict) or
                        parsed.get("CFBundleExecutable") != "AdjustSigSdk" or
                        parsed.get("CFBundlePackageType") != "FMWK"):
                    raise ValueError("Exact framework metadata identity mismatch")
                source = io.BytesIO(data)
            while True:
                chunk = source.read(min(1024 * 1024, part_bytes - len(pending)))
                if not chunk:
                    break
                count += len(chunk)
                if count > entry.file_size:
                    raise ValueError("Original resource decompression exceeded recorded length")
                digest.update(chunk)
                pending.extend(chunk)
                position += len(chunk)
                if len(pending) == part_bytes:
                    flush()
        if count != entry.file_size:
            raise ValueError("Original resource length mismatch")
        members.append({"bundle_relative_path": relative, "canonical_candidate_path": canonical_path,
                        "mapping": rule, "stream_offset": start, "size": count,
                        "sha256": digest.hexdigest(), "source_zip_crc32": f"{entry.CRC:08x}"})
    flush()
    return {"format": "od-original-iphone-resource-parts-v1",
            "source": {"size": SOURCE_SIZE, "sha256": SOURCE_SHA256,
                       "whole_ipa_sha256_verified": True},
            "selector": "iphone_asset_catalog.resource_mapping",
            "resource_candidates": sum(x[3] != "required-framework-info" for x in selected),
            "framework_metadata_members": 1, "total_selected_bytes": position,
            "part_limit_bytes": part_bytes, "parts": parts, "members": members,
            "bundle_and_tutorial_aliases_preserved": True,
            "existing_startup_inputs_required": [
                {"path": "Frameworks/AdjustSigSdk.framework/AdjustSigSdk", "size": 649088,
                 "sha256": "564cdec07867697f3e23b8df760a5c3d9c067ff5dec2780dd905c83eaf2f96cd"},
                {"path": "database.db", "size": 535552,
                 "sha256": "667e554a9cfb8c4765f05a1d85f0fdf707ade61562b50e3e5cd98ac52f997ba3"}],
            "native_execution_verified": False, "complete_startup_resource_set_proven": False,
            "gameplay_verified": False}


def run_original_resources(source_id, folder_id):
    import google.auth
    from googleapiclient.discovery import build
    from googleapiclient.http import MediaIoBaseDownload, MediaIoBaseUpload

    valid_id(source_id)
    valid_id(folder_id)
    credentials, _ = google.auth.default(scopes=["https://www.googleapis.com/auth/drive"])
    service = build("drive", "v3", credentials=credentials, cache_discovery=False)
    meta = service.files().get(fileId=source_id, fields="size,trashed,mimeType").execute()
    if meta.get("trashed") or int(meta.get("size", -1)) != SOURCE_SIZE:
        raise ValueError("Original IPA metadata changed")
    folder = service.files().get(fileId=folder_id, fields="mimeType,trashed").execute()
    if folder.get("trashed") or folder.get("mimeType") != "application/vnd.google-apps.folder":
        raise ValueError("Configured destination is not an existing Drive folder")
    query = f"'{folder_id}' in parents and trashed=false and name contains '{PREFIX}'"
    existing = {}
    token = None
    while True:
        listing = service.files().list(q=query, fields="files(id,name,size,md5Checksum,appProperties),nextPageToken",
                                      pageSize=1000, pageToken=token).execute()
        for record in listing.get("files", []):
            name = record["name"]
            if name in existing:
                raise ValueError("Duplicate resource output names require review")
            existing[name] = record
        token = listing.get("nextPageToken")
        if not token:
            break

    def publish(name, data, sha, md5, allow_manifest_update=False):
        previous = existing.get(name)
        if previous:
            properties = previous.get("appProperties", {})
            if (previous["id"] == source_id or properties.get(OWNER) != "v1" or
                    properties.get("sourceSha256") != SOURCE_SHA256):
                raise ValueError("Existing output is unowned or belongs to different source; preserved")
            identical = (int(previous.get("size", -1)) == len(data) and
                         previous.get("md5Checksum") == md5 and properties.get("sha256") == sha)
            if identical:
                return previous["id"]
            if not allow_manifest_update:
                raise ValueError("Existing resource part differs; never overwrite a working part")
        properties = {OWNER: "v1", "sourceSha256": SOURCE_SHA256, "sha256": sha}
        media = MediaIoBaseUpload(io.BytesIO(data), mimetype="application/octet-stream", resumable=False)
        if previous:
            result = service.files().update(fileId=previous["id"], body={"appProperties": properties},
                                             media_body=media, fields="id,size,md5Checksum").execute()
        else:
            result = service.files().create(body={"name": name, "parents": [folder_id],
                                                  "appProperties": properties}, media_body=media,
                                             fields="id,size,md5Checksum").execute()
        if int(result.get("size", -1)) != len(data) or result.get("md5Checksum") != md5:
            raise ValueError("Drive server size/transfer checksum did not verify")
        return result["id"]

    print("Downloading and SHA-256 checking the unchanged IPA inside Google’s cloud.")
    with tempfile.TemporaryDirectory(prefix="dokkan-original-resources-", dir="/content") as scratch:
        source_path = Path(scratch) / "original.ipa"
        with source_path.open("wb") as output:
            downloader = MediaIoBaseDownload(output, service.files().get_media(fileId=source_id),
                                             chunksize=8 * 1024 * 1024)
            done = False
            while not done:
                _, done = downloader.next_chunk()
                if output.tell() > SOURCE_SIZE:
                    raise ValueError("Cloud download exceeded original pinned size")
        if digest_file(source_path, SOURCE_SIZE) != SOURCE_SHA256:
            raise ValueError("Original IPA SHA-256 mismatch; no resources extracted")
        print("Original IPA SHA-256 verified. Streaming the existing safe resource set into Drive parts.")
        with zipfile.ZipFile(source_path) as archive:
            selected = select_entries(archive)
            def publish_part(index, data, sha, md5):
                name = f"{PREFIX}.part-{index:04d}.bin"
                result = publish(name, data, sha, md5)
                print("Verified cloud resource part", index, "bytes", len(data))
                return result
            manifest = stream_parts(archive, selected, publish_part)
        manifest_bytes = (json.dumps(manifest, indent=2, sort_keys=True) + "\n").encode()
        manifest_sha = hashlib.sha256(manifest_bytes).hexdigest()
        manifest_id = publish(PREFIX + "-manifest.json", manifest_bytes, manifest_sha,
                              hashlib.md5(manifest_bytes).hexdigest(), allow_manifest_update=True)
        # Manifest is tiny; verify its actual bytes, not only Drive metadata.
        downloaded = service.files().get_media(fileId=manifest_id).execute()
        if hashlib.sha256(downloaded).hexdigest() != manifest_sha:
            raise ValueError("Manifest SHA-256 readback failed")
    print("Finished: original safe iPhone resources and framework metadata are in Google Drive.")
    print("Temporary Google-cloud IPA copy removed; original preserved. No app build or game launch.")
    print("Resource candidates:", manifest["resource_candidates"], "Selected bytes:", manifest["total_selected_bytes"])
    print("Parts:", len(manifest["parts"]), "Manifest SHA-256:", manifest_sha)
    print("Manifest: https://drive.google.com/file/d/" + manifest_id + "/view")
    return {"manifest_id": manifest_id, "manifest_sha256": manifest_sha,
            "parts": len(manifest["parts"]), "selected_bytes": manifest["total_selected_bytes"]}
