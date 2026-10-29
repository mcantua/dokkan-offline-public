#!/usr/bin/env python3
"""Pin SQLite3.50.4 source for our mobile native engine (never Android's private system SQLite)."""
import argparse
import hashlib
import io
import pathlib
import urllib.request
import zipfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
PREFIX = ROOT / "downloads/sqlite-amalgamation"
URL = "https://www.sqlite.org/2025/sqlite-amalgamation-3500400.zip"
SHA256 = "1d3049dd0f830a025a53105fc79fd2ab9431aea99e137809d064d8ee8356b032"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    archive = PREFIX / "sqlite-amalgamation-3500400.zip"
    if not archive.is_file() or hashlib.sha256(archive.read_bytes()).hexdigest() != SHA256:
        if args.check: raise SystemExit("Missing/changed pinned SQLite source archive")
        PREFIX.mkdir(parents=True, exist_ok=True)
        data = urllib.request.urlopen(URL).read()
        if hashlib.sha256(data).hexdigest() != SHA256: raise SystemExit("Pinned SQLite source hash mismatch")
        part = archive.with_suffix(".part");part.write_bytes(data);part.replace(archive)
    with zipfile.ZipFile(io.BytesIO(archive.read_bytes())) as source:
        for name in ("sqlite3.c", "sqlite3.h", "sqlite3ext.h"):
            data = source.read("sqlite-amalgamation-3500400/" + name)
            path = PREFIX / "source" / name
            if args.check:
                if not path.is_file() or path.read_bytes() != data: raise SystemExit("Missing/changed pinned SQLite source: " + name)
            else:
                path.parent.mkdir(exist_ok=True)
                part = path.with_suffix(".part");part.write_bytes(data);part.replace(path)
    if '#define SQLITE_VERSION        "3.50.4"' not in (PREFIX / "source/sqlite3.h").read_text(): raise SystemExit("Unexpected SQLite version")
    if not args.check:
        (PREFIX / "SOURCE.md").write_text("# Pinned mobile SQLite\n\nSQLite3.50.4 public-domain amalgamation from the official upstream HTTPS source. Used for the own-app native engine, not copied from a game or Android private system library.\n\nURL: " + URL + "\nSHA256: " + SHA256 + "\n\nArchive/extracted source are ignored; the script verifies archive and extracted source. SQLite JSON and STRICT support are required. Both mobile targets link this same version with thread safety and extension loading disabled; no AI/game/signing keys are present.\n")
    print("Pinned public SQLite3.50.4 source verified.")


if __name__ == "__main__": main()
