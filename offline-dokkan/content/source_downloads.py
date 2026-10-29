#!/usr/bin/env python3
"""Explicit source-data downloads for our own game, never a game-mode selector.

Cloud/development host utility. No login, keys, decryption, activation, player
changes or automatic launch-time networking. Uses normal system TLS/proxy trust.
"""
import argparse
import contextlib
import ctypes
import ctypes.util
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import tempfile
import urllib.error
import urllib.parse
import urllib.request

from import_master import import_master, MAX_BYTES

ASSET_MAX = 192 * 1024 * 1024
MANIFEST_MAX = 20 * 1024 * 1024
CHUNK = 65536
PROVIDERS = {
    "eclipse": {
        "database": "https://dokkan-eclipse.com/cdn/uncompressed/sqlite/current/en/database_decrypted.db",
        "asset_roots": ["https://dokkan-eclipse.com/cdn/uncompressed/", "https://cdn.dokkan-eclipse.com/uncompressed/"],
    },
    "sparking": {
        "database": "https://ddl.dokkan-sparking.com/dokkan/assets/global/en/sqlite/current/en/database.db",
        "manifest": "https://dokkan-sparking.com/client_assets",
        "asset_roots": ["https://ddl.dokkan-sparking.com/dokkan/assets/global/en/"],
    },
}
ASSET_GROUPS = {"character", "ingame", "script", "movie", "sound", "lua", "bgm", "item", "card_category", "sd_battle", "outgame", "sugoroku", "se", "voice"}


def source_record(source):
    if source not in PROVIDERS:
        raise ValueError("SOURCE_INVALID")
    return PROVIDERS[source]


def asset_path(path):
    # Exact ASCII game resource paths only. Reject encodings and account files.
    if not isinstance(path, str) or not 1 <= len(path) <= 500 or not re.fullmatch(r"[A-Za-z0-9_./-]+", path):
        raise ValueError("ASSET_PATH_INVALID")
    parts = path.split("/")
    if any(part in ("", ".", "..") for part in parts) or parts[0] not in ASSET_GROUPS:
        raise ValueError("ASSET_PATH_INVALID")
    return path


def permitted_urls(source, kind, path=None):
    record = source_record(source)
    if kind == "asset":
        path = asset_path(path)
        return {root + path for root in record["asset_roots"]}
    if kind not in ("database", "manifest") or kind not in record:
        raise ValueError("SOURCE_OPERATION_UNAVAILABLE")
    return {record[kind]}


def validate_url(url, permitted):
    if not isinstance(url, str) or len(url) > 1024 or any(ord(c) < 33 or ord(c) > 126 for c in url):
        raise ValueError("DOWNLOAD_URL_INVALID")
    try:
        parsed = urllib.parse.urlsplit(url)
        valid = parsed.scheme == "https" and parsed.hostname and parsed.port in (None, 443) and not (parsed.username or parsed.password or parsed.query or parsed.fragment)
    except ValueError:
        valid = False
    # Literal allowlist also excludes alternate escapes, IP literals, suffixes,
    # nonstandard ports and redirects to unrelated resources on a trusted host.
    if not valid or url not in permitted:
        raise ValueError("DOWNLOAD_URL_NOT_ALLOWED")
    return url


def private_directory(root):
    root = Path(root).absolute()
    # Refuse existing symlinks in the complete destination hierarchy.
    for part in (root, *root.parents):
        if part.is_symlink():
            raise ValueError("CONTENT_LIBRARY_UNSAFE")
    root.mkdir(mode=0o700, parents=True, exist_ok=True)
    if not root.is_dir():
        raise ValueError("CONTENT_LIBRARY_INVALID")
    return root


class XXHash64:
    """Use the public upstream xxHash streaming ABI, never game crypto."""
    def __init__(self):
        library = ctypes.util.find_library("xxhash")
        if not library:
            raise ValueError("PUBLIC_XXHASH_RUNTIME_REQUIRED")
        self.lib = ctypes.CDLL(library)
        self.lib.XXH64_createState.restype = ctypes.c_void_p
        self.lib.XXH64_freeState.argtypes = [ctypes.c_void_p]
        self.lib.XXH64_reset.argtypes = [ctypes.c_void_p, ctypes.c_uint64]
        self.lib.XXH64_update.argtypes = [ctypes.c_void_p, ctypes.c_void_p, ctypes.c_size_t]
        self.lib.XXH64_digest.argtypes = [ctypes.c_void_p]
        self.lib.XXH64_digest.restype = ctypes.c_uint64
        self.state = self.lib.XXH64_createState()
        if not self.state:
            raise MemoryError("XXHASH_STATE_UNAVAILABLE")
        if self.lib.XXH64_reset(self.state, 0):
            self.close()
            raise ValueError("XXHASH_INITIALIZATION_FAILED")

    def update(self, data):
        if self.lib.XXH64_update(self.state, data, len(data)):
            raise ValueError("XXHASH_UPDATE_FAILED")

    def value(self):
        return str(self.lib.XXH64_digest(self.state))

    def close(self):
        if self.state:
            self.lib.XXH64_freeState(self.state)
            self.state = None


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def _download(url, allowed, staging, limit, expected_size=None, sha256=None, xxhash64=None, opener=None, headers=None):
    validate_url(url, allowed)
    if type(limit) is not int or not 0 < limit <= MAX_BYTES:
        raise ValueError("DOWNLOAD_LIMIT_INVALID")
    if expected_size is not None and (type(expected_size) is not int or not 0 < expected_size <= limit):
        raise ValueError("DOWNLOAD_SIZE_INVALID")
    if sha256 is not None and (not isinstance(sha256, str) or not re.fullmatch(r"[0-9a-f]{64}", sha256)):
        raise ValueError("DOWNLOAD_HASH_INVALID")
    if xxhash64 is not None and (not isinstance(xxhash64, str) or not re.fullmatch(r"0|[1-9][0-9]{0,19}", xxhash64) or int(xxhash64) > 2**64 - 1):
        raise ValueError("DOWNLOAD_HASH_INVALID")
    staging = private_directory(staging)
    fd, name = tempfile.mkstemp(prefix=".download-", dir=staging)
    candidate = Path(name)
    checksum = hashlib.sha256()
    xxh = None
    try:
        if xxhash64 is not None:
            xxh = XXHash64()
        opener = opener or urllib.request.build_opener(NoRedirect())
        request_headers = {"User-Agent": "Offline-Dokkan-Data/0.1", "Accept-Encoding": "identity", **(headers or {})}
        response = None
        for hop in range(4):
            request = urllib.request.Request(url, headers=request_headers)
            try:
                response = opener.open(request, timeout=30)
                break
            except urllib.error.HTTPError as error:
                try:
                    if error.code not in (301, 302, 303, 307, 308):
                        raise ValueError("SOURCE_HTTP_" + str(error.code)) from None
                    location = error.headers.get("Location")
                    if not location or hop == 3:
                        raise ValueError("SOURCE_REDIRECT_LIMIT")
                    url = validate_url(urllib.parse.urljoin(url, location), allowed)
                finally:
                    error.close()
        if response is None:
            raise ValueError("SOURCE_RESPONSE_MISSING")
        with response, os.fdopen(fd, "wb") as output:
            fd = -1
            if response.status != 200:
                raise ValueError("SOURCE_HTTP_" + str(response.status))
            # Also check the actual response URL in case a caller injects an
            # opener with redirect handling. Production uses NoRedirect above.
            validate_url(response.geturl(), allowed)
            if response.headers.get("Content-Encoding", "identity").lower() not in ("", "identity"):
                raise ValueError("SOURCE_ENCODING_UNSUPPORTED")
            declared = response.headers.get("Content-Length")
            if declared is not None:
                if not re.fullmatch(r"[0-9]+", declared) or not 0 < int(declared) <= limit:
                    raise ValueError("SOURCE_LENGTH_INVALID")
                if expected_size is not None and int(declared) != expected_size:
                    raise ValueError("SOURCE_SIZE_MISMATCH")
            total = 0
            while True:
                data = response.read(min(CHUNK, limit - total + 1))
                if not data:
                    break
                total += len(data)
                if total > limit:
                    raise ValueError("SOURCE_TOO_LARGE")
                checksum.update(data)
                if xxh:
                    xxh.update(data)
                output.write(data)
            if not total or (expected_size is not None and total != expected_size) or (declared is not None and total != int(declared)):
                raise ValueError("SOURCE_SIZE_MISMATCH")
            actual_hash = checksum.hexdigest()
            if (sha256 is not None and actual_hash != sha256) or (xxh and xxh.value() != xxhash64):
                raise ValueError("SOURCE_HASH_MISMATCH")
            output.flush()
            os.fsync(output.fileno())
        return candidate, {"bytes": total, "sha256": actual_hash, "url": url}
    except BaseException:
        candidate.unlink(missing_ok=True)
        raise
    finally:
        if fd >= 0:
            os.close(fd)
        if xxh:
            xxh.close()


def _publish(candidate, root, folder, suffix, checksum):
    destination_root = private_directory(Path(root) / folder)
    destination = destination_root / (checksum + suffix)
    os.chmod(candidate, 0o400)
    try:
        os.link(candidate, destination, follow_symlinks=False)
    except FileExistsError:
        fd = os.open(destination, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
        with os.fdopen(fd, "rb") as stored:
            info = os.fstat(stored.fileno())
            if not stat.S_ISREG(info.st_mode) or info.st_size != candidate.stat().st_size or hashlib.file_digest(stored, "sha256").hexdigest() != checksum:
                raise ValueError("SOURCE_CACHE_CONFLICT")
    directory_fd = os.open(destination_root, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    try:
        os.fsync(directory_fd)
    finally:
        os.close(directory_fd)
    return destination


def download_database(source, library, expected_sha256=None, opener=None):
    root = private_directory(library)
    allowed = permitted_urls(source, "database")
    candidate, downloaded = _download(source_record(source)["database"], allowed, root / ".downloads", MAX_BYTES, sha256=expected_sha256, opener=opener)
    try:
        with candidate.open("rb") as stream:
            if stream.read(16) != b"SQLite format 3\0":
                raise ValueError("PLAINTEXT_MASTER_REQUIRED_NO_DECRYPTION")
        result = import_master(candidate, root, source)
        return {**result, "source": source, "download": downloaded, "player_changed": False, "activated": False}
    finally:
        candidate.unlink(missing_ok=True)


def _json(path, limit):
    path = Path(path)
    fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    with os.fdopen(fd, "rb") as stream:
        info = os.fstat(stream.fileno())
        if not stat.S_ISREG(info.st_mode) or info.st_size > limit:
            raise ValueError("MANIFEST_FILE_INVALID")
        def unique(items):
            result = {}
            for key, value in items:
                if key in result:
                    raise ValueError("MANIFEST_DUPLICATE_KEY")
                result[key] = value
            return result
        return json.loads(stream.read(limit + 1), object_pairs_hook=unique)


def manifest_entries(manifest):
    assets = manifest.get("assets") if isinstance(manifest, dict) else None
    if not isinstance(assets, list) or len(assets) > 100000:
        raise ValueError("MANIFEST_SHAPE_INVALID")
    paths = set()
    for item in assets:
        if not isinstance(item, dict) or not isinstance(item.get("file_path"), str) or item["file_path"] in paths:
            raise ValueError("MANIFEST_ENTRY_INVALID")
        paths.add(item["file_path"])
    return assets


def download_manifest(source, library, opener=None):
    root = private_directory(library)
    allowed = permitted_urls(source, "manifest")
    headers = {"Accept": "application/json", "X-AssetVersion": "0", "Sparking_Asset_Version": "0"}
    candidate, downloaded = _download(source_record(source)["manifest"], allowed, root / ".downloads", MANIFEST_MAX, opener=opener, headers=headers)
    try:
        manifest = _json(candidate, MANIFEST_MAX)
        assets = manifest_entries(manifest)
        destination = _publish(candidate, root, "source-manifests", ".json", downloaded["sha256"])
        return {"source": source, **downloaded, "path": str(destination), "entries": len(assets), "player_changed": False}
    finally:
        candidate.unlink(missing_ok=True)


def download_asset(source, path, library, size=None, sha256=None, manifest_path=None, opener=None):
    root = private_directory(library)
    allowed = permitted_urls(source, "asset", path)
    url = source_record(source)["asset_roots"][0] + path
    xxhash64 = None
    if manifest_path is not None:
        if source != "sparking":
            raise ValueError("SOURCE_MANIFEST_UNAVAILABLE")
        matches = [item for item in manifest_entries(_json(manifest_path, MANIFEST_MAX)) if item["file_path"] == path]
        if len(matches) != 1:
            raise ValueError("MANIFEST_ASSET_MISSING")
        item = matches[0]
        if item.get("algorithm") != "xxhash":
            raise ValueError("MANIFEST_HASH_UNSUPPORTED")
        size, xxhash64 = item.get("size"), item.get("hash")
        if type(size) is not int or not 0 < size <= ASSET_MAX or not isinstance(xxhash64, str) or not re.fullmatch(r"0|[1-9][0-9]{0,19}", xxhash64) or int(xxhash64) > 2**64 - 1:
            raise ValueError("MANIFEST_ASSET_CHECKSUM_INVALID")
        url = validate_url(item.get("url"), allowed)
    elif size is None or sha256 is None:
        raise ValueError("VERIFIED_SIZE_AND_SHA256_REQUIRED")
    candidate, downloaded = _download(url, allowed, root / ".downloads", ASSET_MAX, expected_size=size, sha256=sha256, xxhash64=xxhash64, opener=opener)
    try:
        destination = _publish(candidate, root, "assets", ".bin", downloaded["sha256"])
        return {"source": source, "resource_path": path, **downloaded, "xxhash64": xxhash64, "cache_path": str(destination), "player_changed": False}
    finally:
        candidate.unlink(missing_ok=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("registry", help="Show known sources without making network requests")
    for command in ("database", "manifest", "asset"):
        sub = commands.add_parser(command)
        sub.add_argument("--source", choices=tuple(PROVIDERS), required=True)
        sub.add_argument("--library", type=Path, required=True)
        if command == "database":
            sub.add_argument("--sha256", help="Optional independently verified source-byte SHA256")
        if command == "asset":
            sub.add_argument("--path", required=True)
            sub.add_argument("--bytes", type=int)
            sub.add_argument("--sha256")
            sub.add_argument("--manifest", type=Path)
    args = parser.parse_args()
    if args.command == "registry":
        result = {"purpose": "Development data sources for one original Offline Dokkan game; not game modes", "sources": PROVIDERS}
    elif args.command == "database":
        result = download_database(args.source, args.library, args.sha256)
    elif args.command == "manifest":
        result = download_manifest(args.source, args.library)
    else:
        result = download_asset(args.source, args.path, args.library, args.bytes, args.sha256, args.manifest)
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
