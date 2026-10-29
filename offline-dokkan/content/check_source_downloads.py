#!/usr/bin/env python3
"""One focused fake-HTTPS transfer/import scenario; no live game/network claim."""
import hashlib
import io
import json
from pathlib import Path
import sqlite3
import tempfile
import urllib.error

import source_downloads as source


class Response(io.BytesIO):
    def __init__(self, url, data, headers=None, status=200):
        super().__init__(data)
        self.url, self.status = url, status
        self.headers = {"Content-Length": str(len(data)), **(headers or {})}

    def geturl(self):
        return self.url


class FakeHTTPS:
    def __init__(self, records):
        self.records, self.requests = records, []

    def open(self, request, timeout):
        self.requests.append(request)
        reply = self.records[request.full_url]
        if isinstance(reply, BaseException):
            raise reply
        return Response(request.full_url, *reply)


def rejected(fn, code):
    try:
        fn()
    except ValueError as error:
        assert str(error) == code, (str(error), code)
    else:
        raise AssertionError("Expected " + code)


def main():
    with tempfile.TemporaryDirectory(prefix="offline-source-check-") as temporary:
        root = Path(temporary)
        library = root / "private-content"
        master = root / "tiny-source.sqlite3"
        with sqlite3.connect(master) as db:
            db.executescript("CREATE TABLE cards(id INTEGER,lv_max INTEGER,skill_lv_max INTEGER);INSERT INTO cards VALUES(1,80,10);CREATE TABLE quests(id INTEGER,area_id INTEGER);CREATE TABLE sugoroku_maps(id INTEGER,quest_id INTEGER,act INTEGER);CREATE TABLE training_items(id INTEGER);CREATE TABLE awakening_items(id INTEGER);")
        raw = master.read_bytes()
        original = hashlib.sha256(raw).hexdigest()
        db_url = source.PROVIDERS["eclipse"]["database"]
        http = FakeHTTPS({db_url: (raw,)})
        imported = source.download_database("eclipse", library, original, http)
        assert imported["cards"] == 1 and not imported["activated"] and not imported["player_changed"]
        assert imported["source"] == "eclipse" and imported["download"]["sha256"] == original
        assert hashlib.sha256(master.read_bytes()).hexdigest() == original
        with sqlite3.connect(library / "content-index.sqlite3") as index:
            assert index.execute("SELECT count(*) FROM active").fetchone()[0] == 0
        snapshot_names = sorted(p.name for p in (library / "masters").iterdir())
        spark_db = source.PROVIDERS["sparking"]["database"]
        rejected(lambda: source.download_database("sparking", library, opener=FakeHTTPS({spark_db: (b"encrypted-not-plaintext",)})), "PLAINTEXT_MASTER_REQUIRED_NO_DECRYPTION")
        assert sorted(p.name for p in (library / "masters").iterdir()) == snapshot_names
        rejected(lambda: source.download_database("eclipse", library, "0" * 64, http), "SOURCE_HASH_MISMATCH")

        resource = b"own synthetic content, no game files"
        digest = hashlib.sha256(resource).hexdigest()
        path = "character/thumb/own-check.png"
        primary, mirror = [prefix + path for prefix in source.PROVIDERS["eclipse"]["asset_roots"]]
        redirect = urllib.error.HTTPError(primary, 302, "redirect", {"Location": mirror}, io.BytesIO())
        cached = source.download_asset("eclipse", path, library, len(resource), digest, opener=FakeHTTPS({primary: redirect, mirror: (resource,)}))
        asset = Path(cached["cache_path"])
        assert asset.read_bytes() == resource and cached["url"] == mirror and not cached["player_changed"]
        rejected(lambda: source.download_asset("eclipse", path, library, len(resource), "0" * 64, opener=FakeHTTPS({primary: (resource,)})), "SOURCE_HASH_MISMATCH")
        assert asset.read_bytes() == resource
        bad_redirect = urllib.error.HTTPError(primary, 302, "redirect", {"Location": "https://example.com/secret"}, io.BytesIO())
        rejected(lambda: source.download_asset("eclipse", path, library, len(resource), digest, opener=FakeHTTPS({primary: bad_redirect})), "DOWNLOAD_URL_NOT_ALLOWED")
        downgrade = urllib.error.HTTPError(primary, 302, "redirect", {"Location": primary.replace("https:", "http:")}, io.BytesIO())
        rejected(lambda: source.download_asset("eclipse", path, library, len(resource), digest, opener=FakeHTTPS({primary: downgrade})), "DOWNLOAD_URL_NOT_ALLOWED")
        for bad_path in ("../secret", "character/../secret", "character//x", "character/%2e%2e/x", "user/accounts", "character/x?token=x", "/character/x"):
            rejected(lambda path=bad_path: source.permitted_urls("eclipse", "asset", path), "ASSET_PATH_INVALID")
        rejected(lambda: source._download(primary, {primary}, library / ".downloads", 3, opener=FakeHTTPS({primary: (resource, {"Content-Length": "3"})})), "SOURCE_TOO_LARGE")
        rejected(lambda: source._download(primary, {primary}, library / ".downloads", 100, expected_size=4, opener=FakeHTTPS({primary: (b"abcd", {"Content-Length": "5"})})), "SOURCE_SIZE_MISMATCH")
        rejected(lambda: source._download(primary, {primary}, library / ".downloads", 100, opener=FakeHTTPS({primary: (resource, {"Content-Encoding": "gzip"})})), "SOURCE_ENCODING_UNSUPPORTED")

        xxh = source.XXHash64()
        try:
            assert xxh.value() == "17241709254077376921"  # Public seed0 empty-string vector.
            xxh.update(resource[:10]);xxh.update(resource[10:])
            expected = xxh.value()
        finally:
            xxh.close()
        spark_asset = source.PROVIDERS["sparking"]["asset_roots"][0] + path
        manifest = {"latest_version": "own-check", "assets": [{"file_path": path, "url": spark_asset, "size": len(resource), "algorithm": "xxhash", "hash": expected}]}
        manifest_url = source.PROVIDERS["sparking"]["manifest"]
        network = FakeHTTPS({manifest_url: (json.dumps(manifest).encode(),), spark_asset: (resource,)})
        checked_manifest = source.download_manifest("sparking", library, network)
        downloaded = source.download_asset("sparking", path, library, manifest_path=checked_manifest["path"], opener=network)
        assert downloaded["xxhash64"] == expected and downloaded["sha256"] == digest
        assert network.requests[0].headers["Accept-encoding"] == "identity"
        manifest["assets"][0]["hash"] = None
        bad_manifest = root / "bad-manifest.json";bad_manifest.write_text(json.dumps(manifest))
        rejected(lambda: source.download_asset("sparking", path, library, manifest_path=bad_manifest, opener=network), "MANIFEST_ASSET_CHECKSUM_INVALID")
        manifest["assets"][0]["hash"] = str(int(expected) ^ 1)
        bad_manifest.write_text(json.dumps(manifest))
        rejected(lambda: source.download_asset("sparking", path, library, manifest_path=bad_manifest, opener=network), "SOURCE_HASH_MISMATCH")
        alias = root / "alias";alias.symlink_to(library, target_is_directory=True)
        rejected(lambda: source.private_directory(alias / "child"), "CONTENT_LIBRARY_UNSAFE")
        assert list((library / ".downloads").iterdir()) == []
        assert sorted(p.name for p in (library / "masters").iterdir()) == snapshot_names
        assert asset.read_bytes() == resource
        assert not list(library.rglob("*player*"))
    print("Passed one focused fake-HTTPS source download scenario: pinned URLs/redirects, bounds, SHA/xxHash, plaintext SQLite import, no activation/player changes, cache preservation and staging cleanup. No live server/native/gameplay check.")


if __name__ == "__main__":
    main()
