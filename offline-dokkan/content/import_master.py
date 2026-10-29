#!/usr/bin/env python3
"""Import a consistent read-only master snapshot; never modify the source/save.

Host utility for cloud/native packaging. Imported files and the registry belong
in ignored offline-dokkan/data, not Git. No game decryption or key extraction.
"""
import argparse
import contextlib
import datetime
import hashlib
import json
import os
from pathlib import Path
import sqlite3
import stat
import tempfile
from urllib.parse import quote

MAX_BYTES = 2 * 1024 * 1024 * 1024
REQUIRED = {
    "cards": {"id", "lv_max", "skill_lv_max"},
    "quests": {"id", "area_id"},
    "sugoroku_maps": {"id", "quest_id", "act"},
    "training_items": {"id"},
    "awakening_items": {"id"},
}


def digest(path):
    fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    with os.fdopen(fd, "rb") as stream:
        info = os.fstat(stream.fileno())
        if not stat.S_ISREG(info.st_mode) or info.st_size > MAX_BYTES:
            raise ValueError("MASTER_FILE_INVALID")
        return hashlib.file_digest(stream, "sha256").hexdigest()


def read_only(path):
    connection = sqlite3.connect("file:" + quote(str(Path(path).absolute()), safe="/") + "?mode=ro", uri=True, timeout=10)
    connection.execute("PRAGMA query_only=ON")
    connection.execute("PRAGMA trusted_schema=OFF")
    connection.execute("PRAGMA temp_store=MEMORY")
    return connection


def validate(connection):
    if connection.execute("PRAGMA quick_check").fetchall() != [("ok",)]:
        raise ValueError("MASTER_INTEGRITY_INVALID")
    schema = connection.execute("SELECT type,name,sql FROM sqlite_schema WHERE name NOT LIKE 'sqlite_%'").fetchall()
    if any(kind not in ("table", "index") or "VIRTUAL TABLE" in (sql or "").upper() for kind, _, sql in schema):
        raise ValueError("MASTER_SCHEMA_UNSUPPORTED")
    tables = {name for kind, name, _ in schema if kind == "table"}
    for table, required in REQUIRED.items():
        columns = {row[1] for row in connection.execute('PRAGMA table_info("' + table + '")')}
        if table not in tables or not required.issubset(columns):
            raise ValueError("MASTER_REQUIRED_TABLES_MISSING")
    cards = connection.execute("SELECT count(*) FROM cards").fetchone()[0]
    if cards < 1:
        raise ValueError("MASTER_CARDS_MISSING")
    return {"cards": cards, "tables": len(tables)}


@contextlib.contextmanager
def registry(library):
    root = Path(library)
    root.mkdir(mode=0o700, parents=True, exist_ok=True)
    if root.is_symlink() or not root.is_dir():
        raise ValueError("CONTENT_LIBRARY_INVALID")
    path = root / "content-index.sqlite3"
    if path.is_symlink():
        raise ValueError("CONTENT_INDEX_UNSAFE")
    connection = sqlite3.connect(path, timeout=10)
    os.chmod(path, 0o600)
    connection.execute("PRAGMA synchronous=FULL")
    connection.executescript("""
      CREATE TABLE IF NOT EXISTS snapshots(
        content_id TEXT PRIMARY KEY, game TEXT NOT NULL CHECK(game IN ('eclipse','sparking')),
        sha256 TEXT NOT NULL, bytes INTEGER NOT NULL CHECK(bytes>0), cards INTEGER NOT NULL,
        tables_count INTEGER NOT NULL, imported_at TEXT NOT NULL);
      CREATE TABLE IF NOT EXISTS active(
        game TEXT PRIMARY KEY CHECK(game IN ('eclipse','sparking')),
        content_id TEXT NOT NULL REFERENCES snapshots(content_id));
    """)
    connection.execute("PRAGMA foreign_keys=ON")
    try:
        yield connection
    except BaseException:
        connection.rollback()
        raise
    finally:
        connection.close()


def import_master(source, library, game):
    if game not in ("eclipse", "sparking"):
        raise ValueError("GAME_INVALID")
    source = Path(source).absolute()
    info = source.lstat()
    if not stat.S_ISREG(info.st_mode) or info.st_size < 100 or info.st_size > MAX_BYTES:
        raise ValueError("MASTER_FILE_INVALID")
    root = Path(library).absolute()
    with registry(root) as index:
        masters = root / "masters"
        masters.mkdir(mode=0o700, exist_ok=True)
        if masters.is_symlink():
            raise ValueError("CONTENT_LIBRARY_UNSAFE")
        fd, name = tempfile.mkstemp(prefix=".import-", suffix=".sqlite3", dir=masters)
        os.close(fd)
        candidate = Path(name)
        promoted = None
        try:
            with contextlib.closing(read_only(source)) as origin, contextlib.closing(sqlite3.connect(candidate)) as target:
                origin.execute("BEGIN")
                # Begin/read pins one SQLite transaction, including a source WAL.
                validate(origin)
                opened = source.lstat()
                if (opened.st_dev, opened.st_ino) != (info.st_dev, info.st_ino):
                    raise ValueError("MASTER_SOURCE_CHANGED")
                page_size = origin.execute("PRAGMA page_size").fetchone()[0]
                def progress(status, remaining, total):
                    if total * page_size > MAX_BYTES:
                        raise ValueError("MASTER_SNAPSHOT_TOO_LARGE")
                origin.backup(target, pages=256, progress=progress, sleep=0.05)
                target.execute("PRAGMA journal_mode=DELETE")
                details = validate(target)
                target.commit()
            if candidate.stat().st_size > MAX_BYTES:
                raise ValueError("MASTER_SNAPSHOT_TOO_LARGE")
            with candidate.open("rb") as stream:
                os.fsync(stream.fileno())
            checksum = digest(candidate)
            content_id = game + ":sha256:" + checksum
            destination = masters / (checksum + ".sqlite3")
            os.chmod(candidate, 0o400)
            try:
                os.link(candidate, destination, follow_symlinks=False)
                promoted = destination
            except FileExistsError:
                if digest(destination) != checksum:
                    raise ValueError("MASTER_CACHE_CONFLICT")
            index.execute("BEGIN IMMEDIATE")
            index.execute("INSERT OR IGNORE INTO snapshots VALUES(?,?,?,?,?,?,?)",
                          (content_id, game, checksum, candidate.stat().st_size, details["cards"], details["tables"],
                           datetime.datetime.now(datetime.timezone.utc).isoformat()))
            index.commit()
            return {"content_id": content_id, "game": game, "sha256": checksum,
                    "bytes": destination.stat().st_size, **details, "activated": False}
        except BaseException:
            index.rollback()
            if promoted is not None:
                promoted.unlink(missing_ok=True)
            raise
        finally:
            candidate.unlink(missing_ok=True)
            for suffix in ("-journal", "-wal", "-shm"):
                Path(str(candidate) + suffix).unlink(missing_ok=True)


def activate(library, game, content_id):
    """Choose content for new host sessions only. Existing core handles stay pinned."""
    with registry(library) as index:
        row = index.execute("SELECT sha256,bytes FROM snapshots WHERE content_id=? AND game=?", (content_id, game)).fetchone()
        if row is None:
            raise ValueError("CONTENT_MISSING")
        path = Path(library) / "masters" / (row[0] + ".sqlite3")
        if path.stat().st_size != row[1] or digest(path) != row[0]:
            raise ValueError("MASTER_INTEGRITY_INVALID")
        with contextlib.closing(read_only(path)) as master:
            validate(master)
        index.execute("BEGIN IMMEDIATE")
        index.execute("INSERT INTO active VALUES(?,?) ON CONFLICT(game) DO UPDATE SET content_id=excluded.content_id", (game, content_id))
        index.commit()
        return {"game": game, "content_id": content_id, "activated": True}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("--library", type=Path, required=True)
    parser.add_argument("--game", choices=("eclipse", "sparking"), required=True)
    parser.add_argument("--activate", action="store_true")
    args = parser.parse_args()
    result = import_master(args.source, args.library, args.game)
    if args.activate:
        result.update(activate(args.library, args.game, result["content_id"]))
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
