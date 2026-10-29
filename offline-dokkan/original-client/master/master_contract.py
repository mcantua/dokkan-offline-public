#!/usr/bin/env python3
"""Read-only, source-pinned schema admission for original-client Creator work.

This establishes column compatibility, never original-engine behavior. It does
not decrypt, modify a master, assign game IDs, import a player, or execute SQL
from a definition. Original-client consumption requires a separate verified hook.
"""
import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import re
import sqlite3
import stat

MAX_MASTER = 2 * 1024 * 1024 * 1024
MAX_DEFINITION = 16 * 1024 * 1024
MAX_ROWS = 20000
IDENTIFIER = re.compile(r"[a-z][a-z0-9_]{0,95}\Z")
HASH = re.compile(r"[0-9a-f]{64}\Z")
TABLES = frozenset("""
cards leader_skill_sets leader_skills passive_skill_sets passive_skill_set_relations passive_skills
card_specials special_sets specials extra_special_options card_active_skills active_skill_sets
active_skills card_standby_skill_set_relations standby_skill_sets standby_skills
standby_skill_set_finish_skill_set_relations card_finish_skill_set_relations finish_skill_sets
finish_skills finish_specials card_card_categories card_categories dokkan_fields
dokkan_field_active_skill_set_relations dokkan_field_passive_skill_relations link_skills
skill_causalities sub_target_types transformation_descriptions
""".split())
CARD_COLUMNS = frozenset(("id", "character_id", "rarity", "lv_max", "skill_lv_max",
                          "hp_init", "hp_max", "atk_init", "atk_max", "def_init", "def_max"))
PINNED_EXPORT = {"bytes": 114827264,
                 "sha256": "f37296ef05e31000d9868741b18525a5d41311ccc152acb82c848b7b1c8ef14d"}


def fail(code):
    raise ValueError(code)


def strict_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            fail("DUPLICATE_FIELD")
        result[key] = value
    return result


def load_definition(path):
    with Path(path).open("rb") as stream:
        data = stream.read(MAX_DEFINITION + 1)
    if len(data) > MAX_DEFINITION:
        fail("DEFINITION_LIMIT")
    return json.loads(data, object_pairs_hook=strict_object,
                      parse_constant=lambda _: fail("NONFINITE_VALUE"))


def fingerprint(stream):
    stream.seek(0)
    return hashlib.file_digest(stream, "sha256").hexdigest()


def identity(info):
    return info.st_dev, info.st_ino, info.st_size, info.st_mtime_ns, info.st_ctime_ns


class MasterContract:
    """Host supplies a trusted selected-content hash, not a definition's claim.

    The input must be a standalone private snapshot, with no concurrent writers.
    An open descriptor plus before/after file identity/hash rejects replacement
    or modification before any result can be published. All queries are fixed or
    use identifiers admitted from the fixed TABLES allowlist.
    """

    def __init__(self, path, expected_sha256, expected_bytes=None, content_id=None):
        self.path = Path(path).absolute()
        if not isinstance(expected_sha256, str) or not HASH.fullmatch(expected_sha256):
            fail("HOST_CONTENT_PIN_REQUIRED")
        if expected_bytes is not None and (type(expected_bytes) is not int or expected_bytes < 1):
            fail("HOST_CONTENT_PIN_INVALID")
        self.expected = expected_sha256
        self.content_id = content_id or "sha256:" + expected_sha256
        if self.content_id not in {"sha256:" + expected_sha256, "eclipse:sha256:" + expected_sha256,
                                   "sparking:sha256:" + expected_sha256}:
            fail("HOST_CONTENT_ID_MISMATCH")
        self.expected_bytes = expected_bytes
        self.stream = self.db = None

    def __enter__(self):
        try:
            if self.path.is_symlink() or any(p.is_symlink() for p in self.path.parents):
                fail("MASTER_PATH_UNSAFE")
            self.stream = os.fdopen(os.open(self.path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK), "rb")
            self.before = os.fstat(self.stream.fileno())
            if not stat.S_ISREG(self.before.st_mode) or not 16 <= self.before.st_size <= MAX_MASTER:
                fail("MASTER_FILE_INVALID")
            if self.expected_bytes is not None and self.before.st_size != self.expected_bytes:
                fail("MASTER_LENGTH_MISMATCH")
            self._standalone()
            if self.stream.read(16) != b"SQLite format 3\0":
                fail("PLAINTEXT_SQLITE_REQUIRED")
            if fingerprint(self.stream) != self.expected:
                fail("MASTER_CONTENT_MISMATCH")
            self.db = sqlite3.connect(self.path.as_uri() + "?mode=ro&immutable=1", uri=True)
            self.db.execute("PRAGMA query_only=ON")
            self.db.execute("PRAGMA trusted_schema=OFF")
            self.db.execute("PRAGMA temp_store=MEMORY")
            self.db.setlimit(sqlite3.SQLITE_LIMIT_LENGTH, MAX_DEFINITION)
            self.db.setlimit(sqlite3.SQLITE_LIMIT_SQL_LENGTH, 8192)
            self.work = 0
            self.db.set_progress_handler(self._budget, 1000)
            objects = self.db.execute("SELECT type,name,instr(upper(coalesce(sql,'')),'VIRTUAL TABLE') "
                                      "FROM sqlite_schema WHERE name NOT LIKE 'sqlite_%' LIMIT 4097").fetchall()
            if len(objects) > 4096 or any(kind not in ("table", "index") or
                    virtual for kind, _, virtual in objects):
                fail("MASTER_SCHEMA_UNSUPPORTED")
            known = {name for kind, name, _ in objects if kind == "table"}
            self.columns = {}
            for table in sorted(TABLES & known):
                rows = self.db.execute('PRAGMA table_info("' + table + '")').fetchall()
                if not rows or len(rows) > 256 or any(not IDENTIFIER.fullmatch(row[1]) for row in rows):
                    fail("MASTER_COLUMNS_UNSUPPORTED")
                self.columns[table] = {row[1]: {"type": row[2].upper(), "notnull": bool(row[3]),
                                              "primary": row[5]} for row in rows}
            if not CARD_COLUMNS.issubset(self.columns.get("cards", {})):
                fail("MASTER_CARDS_SCHEMA_MISSING")
            self.verify_unchanged()
            return self
        except BaseException:
            self.close()
            raise

    def _budget(self):
        self.work += 1000
        return int(self.work > 20000000)

    def _standalone(self):
        for suffix in ("-wal", "-journal"):
            p = Path(str(self.path) + suffix)
            if p.is_symlink() or p.exists() and p.stat().st_size:
                fail("STANDALONE_MASTER_REQUIRED")

    def verify_unchanged(self):
        self._standalone()
        if (identity(self.before) != identity(os.fstat(self.stream.fileno())) or
                identity(self.before) != identity(self.path.stat(follow_symlinks=False)) or
                fingerprint(self.stream) != self.expected):
            fail("MASTER_CHANGED")

    def close(self):
        if self.db is not None:
            self.db.close()
            self.db = None
        if self.stream is not None:
            self.stream.close()
            self.stream = None

    def __exit__(self, kind, value, traceback):
        try:
            if kind is None:
                self.verify_unchanged()
        finally:
            self.close()

    def summary(self):
        card_count = self.db.execute("SELECT count(*) FROM cards").fetchone()[0]
        self.verify_unchanged()
        return {"schema": 1, "content_id": self.content_id,
                "bytes": self.before.st_size, "cards": card_count,
                "settings_tables_present": sorted(self.columns),
                "matches_current_android_export": self.expected == PINNED_EXPORT["sha256"] and
                    self.before.st_size == PINNED_EXPORT["bytes"],
                "column_admission_only": True, "original_client_runtime_admitted": False}

    def validate_settings(self, definition):
        """Validate original column shapes for a definition already admitted by core.

        This does not replace core semantic/ownership/fully-awakened validation.
        It returns no rows or scalar values; no global card override is installed.
        """
        if not isinstance(definition, dict):
            fail("DEFINITION_INVALID")
        allowed = {"format", "schema_version", "definition_id", "version", "source", "rarity",
                   "fully_awakened", "card", "tables", "creator"}
        if set(definition) - allowed:
            fail("ORIGINAL_RUNTIME_FEATURE_UNVERIFIED")
        if (definition.get("format") != "offline-dokkan-definition" or
                type(definition.get("schema_version")) is not int or definition["schema_version"] != 1 or
                type(definition.get("version")) is not int or definition["version"] < 1 or
                not isinstance(definition.get("definition_id"), str) or
                not re.fullmatch(r"[A-Za-z0-9_.:-]{1,100}", definition["definition_id"]) or
                definition.get("rarity") not in ("UR", "LR", "SLR", "GR") or
                definition.get("fully_awakened") is not True):
            fail("DEFINITION_FORMAT_UNSUPPORTED")
        source, card, tables = (definition.get(k) for k in ("source", "card", "tables"))
        if (not isinstance(source, dict) or set(source) != {"content_id", "master_id"} or
                source["content_id"] != self.content_id):
            fail("DEFINITION_CONTENT_MISMATCH")
        if (not isinstance(card, dict) or type(source["master_id"]) is not int or
                source["master_id"] < 1 or card.get("id") != source["master_id"] or
                type(card.get("id")) is not int or not isinstance(tables, dict) or
                "cards" in tables or len(tables) > len(TABLES)):
            fail("DEFINITION_ROWS_INVALID")
        if self.db.execute("SELECT 1 FROM cards WHERE id=?", (source["master_id"],)).fetchone() is None:
            fail("SOURCE_CARD_MISSING")
        row_count = 0
        projected = {"cards": [card], **tables}
        for table, rows in projected.items():
            if table not in self.columns or not isinstance(rows, list):
                fail("SETTINGS_TABLE_UNSUPPORTED")
            seen = set()
            for row in rows:
                row_count += 1
                if row_count > MAX_ROWS or not isinstance(row, dict) or not row or set(row) - self.columns[table].keys():
                    fail("SETTINGS_COLUMNS_UNSUPPORTED")
                if type(row.get("id")) is not int or not 1 <= row["id"] <= 2**53 - 1 or row["id"] in seen:
                    fail("SETTINGS_ROW_ID_INVALID")
                seen.add(row["id"])
                # Only existing source row IDs are established. New ID allocation
                # and reference rewriting require the original engine contract.
                if self.db.execute('SELECT 1 FROM "' + table + '" WHERE id=?', (row["id"],)).fetchone() is None:
                    fail("NEW_RUNTIME_ROW_ID_UNVERIFIED")
                for column, value in row.items():
                    spec = self.columns[table][column]
                    if value is None:
                        if spec["notnull"] or spec["primary"]:
                            fail("SETTINGS_NULL_INVALID")
                        continue
                    if isinstance(value, bool) or not isinstance(value, (str, int, float)):
                        fail("SETTINGS_VALUE_UNSUPPORTED")
                    kind = spec["type"]
                    if "INT" in kind and (type(value) is not int or abs(value) > 2**53 - 1):
                        fail("SETTINGS_INTEGER_INVALID")
                    if any(x in kind for x in ("CHAR", "TEXT", "JSON", "DATE")) and not isinstance(value, str):
                        fail("SETTINGS_TEXT_INVALID")
                    if isinstance(value, float) and not math.isfinite(value):
                        fail("SETTINGS_NUMBER_INVALID")
                    if isinstance(value, str) and (len(value.encode("utf-8")) > 1024 * 1024 or "\0" in value):
                        fail("SETTINGS_TEXT_LIMIT")
                    if "JSON" in kind:
                        try:
                            json.loads(value, object_pairs_hook=strict_object,
                                       parse_constant=lambda _: fail("NONFINITE_VALUE"))
                        except (ValueError, TypeError, RecursionError):
                            fail("SETTINGS_JSON_INVALID")
        self.verify_unchanged()
        return {"schema": 1, "content_id": self.content_id,
                "validated_settings_rows": row_count, "column_admission_only": True,
                "original_client_runtime_admitted": False,
                "remaining_contracts": ["per-save owned-instance binding", "original engine row lookup",
                                        "referential closure", "current master/resource compatibility"]}


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("master", type=Path)
    p.add_argument("--sha256", required=True)
    p.add_argument("--bytes", type=int)
    p.add_argument("--content-id")
    p.add_argument("--definition", type=Path)
    args = p.parse_args()
    try:
        with MasterContract(args.master, args.sha256, args.bytes, args.content_id) as master:
            result = master.validate_settings(load_definition(args.definition)) if args.definition else master.summary()
        print(json.dumps(result, indent=2))
    except (ValueError, OSError, sqlite3.Error, TypeError, RecursionError, OverflowError) as error:
        message = str(error)
        print(message if re.fullmatch(r"[A-Z_]{1,80}", message) else "MASTER_ADMISSION_FAILED")
        raise SystemExit(1)


if __name__ == "__main__":
    main()
