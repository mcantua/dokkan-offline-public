"""Durable definition-scoped Creator rows; deliberately detached from the game.

The native core remains the ownership/progression authority. This is a private
per-save materialization of core-validated settings, not a replacement save. No
source card ID or game runtime ID is allocated or globally overridden.
"""
import hashlib
import json
import os
from pathlib import Path
import re
import sqlite3
import stat

from master_contract import MAX_DEFINITION, TABLES, fail

APP_ID = 0x4F444F56
KEY = re.compile(r"[A-Za-z0-9_.:-]{1,100}\Z")
HASH = re.compile(r"[0-9a-f]{64}\Z")
# Established source-column relationships, matching the existing strict native
# core's reference_table() and Forge's source loader. No '*_id' inference.
REFERENCES = dict(zip(
    "card_id passive_skill_set_id passive_skill_id target_passive_skill_set_id "
    "additional_passive_skill_set_id leader_skill_set_id special_set_id card_special_id "
    "active_skill_set_id standby_skill_set_id finish_skill_set_id finish_special_id "
    "card_category_id dokkan_field_id character_id card_unique_info_id potential_board_id "
    "awaked_card_id card_awakening_set_id".split(),
    "cards passive_skill_sets passive_skills passive_skill_sets passive_skill_sets "
    "leader_skill_sets special_sets card_specials active_skill_sets standby_skill_sets "
    "finish_skill_sets finish_specials card_categories dokkan_fields characters "
    "card_unique_infos potential_boards cards card_awakening_sets".split()))
REFERENCES.update({"link_skill%d_id" % i: "link_skills" for i in range(1, 8)})
DDL = {
    "overlay_meta": "CREATE TABLE overlay_meta(key TEXT PRIMARY KEY,value TEXT NOT NULL) STRICT",
    "overlay_revisions": "CREATE TABLE overlay_revisions(definition_id TEXT NOT NULL,version INTEGER NOT NULL CHECK(version>0),document TEXT NOT NULL CHECK(json_valid(document)),digest TEXT NOT NULL,projection_generation INTEGER NOT NULL CHECK(projection_generation>0),PRIMARY KEY(definition_id,version)) STRICT",
    "overlay_heads": "CREATE TABLE overlay_heads(definition_id TEXT PRIMARY KEY,version INTEGER NOT NULL,FOREIGN KEY(definition_id,version) REFERENCES overlay_revisions(definition_id,version)) STRICT",
    "overlay_rows": "CREATE TABLE overlay_rows(definition_id TEXT NOT NULL,version INTEGER NOT NULL,table_name TEXT NOT NULL,source_row_id INTEGER NOT NULL,row_json TEXT NOT NULL CHECK(json_valid(row_json)),PRIMARY KEY(definition_id,version,table_name,source_row_id),FOREIGN KEY(definition_id,version) REFERENCES overlay_revisions(definition_id,version)) STRICT",
    "overlay_bindings": "CREATE TABLE overlay_bindings(instance_key TEXT PRIMARY KEY,definition_id TEXT NOT NULL REFERENCES overlay_heads(definition_id)) STRICT",
    "overlay_commands": "CREATE TABLE overlay_commands(command_id TEXT PRIMARY KEY,request_digest TEXT NOT NULL,receipt TEXT NOT NULL CHECK(json_valid(receipt))) STRICT",
}


def canonical(value):
    data = json.dumps(value, ensure_ascii=False, allow_nan=False, sort_keys=True,
                      separators=(",", ":"))
    if len(data.encode("utf-8")) > MAX_DEFINITION:
        fail("OVERLAY_DOCUMENT_LIMIT")
    return data


def key(value):
    if not isinstance(value, str) or not KEY.fullmatch(value):
        fail("OVERLAY_KEY_INVALID")
    return value


def projection_scope(state):
    """Stable private scope shared with the native host (compact ASCII JSON)."""
    if (not isinstance(state, dict) or not isinstance(state.get("save_identity"), str) or
            not re.fullmatch(r"[0-9a-f]{32}", state["save_identity"]) or
            not isinstance(state.get("profile_id"), str) or
            not re.fullmatch(r"[A-Za-z0-9_.:-]{1,127}", state["profile_id"]) or
            not isinstance(state.get("content_id"), str) or
            not re.fullmatch(r"(?:(?:eclipse|sparking):)?sha256:[0-9a-f]{64}", state["content_id"])):
        fail("OVERLAY_PROJECTION_IDENTITY_INVALID")
    return hashlib.sha256(canonical([state["save_identity"], state["profile_id"],
                                     state["content_id"]]).encode("ascii")).hexdigest()


class OverlayStore:
    """One sidecar per trusted native save identity and selected master hash.

    Caller opens an active MasterContract and supplies a private dedicated path,
    SHA-256 save scope (never an account email/path), and the actual native
    projection generation. Native callers must commit through the existing strict core
    first. A hook may attach only after independently verifying ownership, projection
    generation, original lookup context and all pending runtime contracts.
    """

    def __init__(self, path, master, save_scope_sha256):
        if master.db is None or not isinstance(save_scope_sha256, str) or not HASH.fullmatch(save_scope_sha256):
            fail("OVERLAY_HOST_CONTEXT_INVALID")
        self.path, self.master, self.scope = Path(path).absolute(), master, save_scope_sha256
        self.db = None
        if self.path == master.path or self.path.is_symlink() or any(p.is_symlink() for p in self.path.parents):
            fail("OVERLAY_PATH_UNSAFE")
        self.path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
        created = False
        try:
            fd = os.open(self.path, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
            os.close(fd)
            created = True
        except FileExistsError:
            info = self.path.stat(follow_symlinks=False)
            if (not stat.S_ISREG(info.st_mode) or info.st_mode & 0o077 or
                    (info.st_dev, info.st_ino) == (master.before.st_dev, master.before.st_ino)):
                fail("OVERLAY_PATH_UNSAFE")
        try:
            self.db = sqlite3.connect(self.path.as_uri() + "?mode=rw", uri=True,
                                      isolation_level=None, timeout=10)
            self.db.execute("PRAGMA trusted_schema=OFF")
            self.db.execute("PRAGMA foreign_keys=ON")
            if not created:
                # Do not change journal mode/checkpoint an unrelated SQLite file.
                self._check_identity()
            self.db.execute("PRAGMA journal_mode=DELETE")
            self.db.execute("PRAGMA synchronous=FULL")
            if created:
                self.db.execute("BEGIN IMMEDIATE")
                self.db.execute("PRAGMA application_id=" + str(APP_ID))
                for sql in DDL.values():
                    self.db.execute(sql)
                self.db.executemany("INSERT INTO overlay_meta VALUES(?,?)", [
                    ("schema", "1"), ("content_id", master.content_id),
                    ("save_scope_sha256", self.scope), ("projection_generation", "0")])
                self.db.execute("COMMIT")
            self._check_identity()
        except BaseException:
            self.close()
            raise

    def _check_identity(self):
        if self.db.execute("PRAGMA application_id").fetchone()[0] != APP_ID:
            fail("OVERLAY_FORMAT_UNSUPPORTED")
        actual = self.db.execute("SELECT type,name,sql FROM sqlite_schema WHERE name NOT LIKE 'sqlite_%'").fetchall()
        if len(actual) != len(DDL) or any(kind != "table" or name not in DDL or
                " ".join(sql.split()) != " ".join(DDL[name].split()) for kind, name, sql in actual):
            fail("OVERLAY_SCHEMA_UNSUPPORTED")
        meta = dict(self.db.execute("SELECT key,value FROM overlay_meta"))
        required = {"schema", "content_id", "save_scope_sha256", "projection_generation"}
        if (set(meta) not in (required, required | {"projection_state"}) or
                meta["schema"] != "1" or meta["content_id"] != self.master.content_id or
                meta["save_scope_sha256"] != self.scope or not re.fullmatch(r"0|[1-9][0-9]{0,15}", meta["projection_generation"])):
            fail("OVERLAY_IDENTITY_MISMATCH")

    def reconcile(self, snapshot, definitions):
        """Durably mirror one trusted schema10 core projection generation.

        Fetch definitions with od_projection_definition for this same generation.
        Read projection_snapshot() after commit and give its persisted state to
        od_projection_ack. A stale core ack leaves a pending intent for restart.
        """
        if (not isinstance(snapshot, dict) or set(snapshot) != {"generation", "applied_generation", "state"} or
                type(snapshot["generation"]) is not int or not 1 <= snapshot["generation"] <= 2**53 - 1 or
                type(snapshot["applied_generation"]) is not int or
                not 0 <= snapshot["applied_generation"] <= snapshot["generation"]):
            fail("OVERLAY_PROJECTION_INVALID")
        generation, state = snapshot["generation"], snapshot["state"]
        if (not isinstance(state, dict) or set(state) != {"format", "schema_version", "content_id", "save_identity", "profile_id", "definitions", "bindings"} or
                state["format"] != "od-native-creator-projection" or type(state["schema_version"]) is not int or
                state["schema_version"] != 1 or state["content_id"] != self.master.content_id or
                projection_scope(state) != self.scope or not isinstance(state["definitions"], list) or
                not isinstance(state["bindings"], list) or len(state["definitions"]) > 10000 or len(state["bindings"]) > 100000):
            fail("OVERLAY_PROJECTION_IDENTITY_INVALID")
        state_json = canonical(state)
        if not isinstance(definitions, list) or len(definitions) != len(state["definitions"]):
            fail("OVERLAY_PROJECTION_DOCUMENTS_MISSING")
        documents, heads, all_rows, byte_count = {}, {}, [], 0
        for ref in state["definitions"]:
            if (not isinstance(ref, dict) or set(ref) != {"definition_id", "version"} or
                    type(ref["version"]) is not int or not 1 <= ref["version"] <= 2**53 - 1):
                fail("OVERLAY_PROJECTION_REFERENCE_INVALID")
            key(ref["definition_id"])
            pair = (ref["definition_id"], ref["version"])
            if pair in documents:
                fail("OVERLAY_PROJECTION_DUPLICATE")
            documents[pair] = None
            heads[pair[0]] = max(heads.get(pair[0], 0), pair[1])
        for definition in definitions:
            document = canonical(definition)
            byte_count += len(document.encode("utf-8"))
            if byte_count > 64 * 1024 * 1024:
                fail("OVERLAY_PROJECTION_DOCUMENT_LIMIT")
            definition = json.loads(document)
            self.master.validate_settings(definition)
            self._references(definition)
            pair = (definition["definition_id"], definition["version"])
            if pair not in documents or documents[pair] is not None:
                fail("OVERLAY_PROJECTION_DOCUMENT_CONFLICT")
            documents[pair] = (document, hashlib.sha256(document.encode()).hexdigest())
            for table, rows in self._rowsets(definition).items():
                all_rows.extend((pair[0], pair[1], table, row["id"], canonical(row)) for row in rows)
        bindings, seen = [], set()
        for binding in state["bindings"]:
            fields = {"instance_id", "definition_id", "version", "master_id", "potential_locked", "addons", "exclusive_kind", "exclusive_always_on"}
            if (not isinstance(binding, dict) or set(binding) != fields or
                    type(binding["instance_id"]) is not int or not 1 <= binding["instance_id"] <= 2**53 - 1 or
                    binding["instance_id"] in seen or heads.get(binding["definition_id"]) != binding["version"]):
                fail("OVERLAY_PROJECTION_BINDING_INVALID")
            pair = (binding["definition_id"], binding["version"])
            if pair not in documents or documents[pair] is None:
                fail("OVERLAY_PROJECTION_DOCUMENTS_MISSING")
            definition = json.loads(documents[pair][0])
            if binding["master_id"] != definition["source"]["master_id"]:
                fail("OVERLAY_PROJECTION_BINDING_INVALID")
            seen.add(binding["instance_id"])
            bindings.append(("instance:" + str(binding["instance_id"]), binding["definition_id"]))
        self.db.execute("BEGIN IMMEDIATE")
        try:
            stored = int(self.db.execute("SELECT value FROM overlay_meta WHERE key='projection_generation'").fetchone()[0])
            if generation < stored:
                fail("OVERLAY_PROJECTION_STALE")
            previous = self.db.execute("SELECT value FROM overlay_meta WHERE key='projection_state'").fetchone()
            if generation == stored and previous and previous[0] != state_json:
                fail("OVERLAY_PROJECTION_STATE_CONFLICT")
            for pair, (document, digest) in documents.items():
                existing = self.db.execute("SELECT digest,document FROM overlay_revisions WHERE definition_id=? AND version=?", pair).fetchone()
                if existing and existing != (digest, document):
                    fail("OVERLAY_DEFINITION_VERSION_CONFLICT")
                self.db.execute("INSERT OR IGNORE INTO overlay_revisions VALUES(?,?,?,?,?)", (*pair, document, digest, generation))
            # Authoritative scope replaces bindings/heads atomically, preserving
            # immutable row revisions and every external owned progression row.
            self.db.execute("DELETE FROM overlay_bindings")
            self.db.execute("DELETE FROM overlay_heads")
            self.db.executemany("INSERT INTO overlay_heads VALUES(?,?)", sorted(heads.items()))
            for pair in documents:
                self.db.execute("DELETE FROM overlay_rows WHERE definition_id=? AND version=?", pair)
            self.db.executemany("INSERT INTO overlay_rows VALUES(?,?,?,?,?)", all_rows)
            self.db.executemany("INSERT INTO overlay_bindings VALUES(?,?)", bindings)
            self.db.execute("UPDATE overlay_meta SET value=? WHERE key='projection_generation'", (str(generation),))
            self.db.execute("INSERT INTO overlay_meta VALUES('projection_state',?) ON CONFLICT(key) DO UPDATE SET value=excluded.value", (state_json,))
            self.master.verify_unchanged()
            self.db.execute("COMMIT")
        except BaseException:
            if self.db.in_transaction:
                self.db.execute("ROLLBACK")
            raise
        return self.projection_snapshot()

    def projection_snapshot(self):
        row = self.db.execute("SELECT value FROM overlay_meta WHERE key='projection_state'").fetchone()
        if row is None:
            fail("OVERLAY_PROJECTION_NOT_RECONCILED")
        generation = int(self.db.execute("SELECT value FROM overlay_meta WHERE key='projection_generation'").fetchone()[0])
        return {"generation": generation, "state": json.loads(row[0])}

    def close(self):
        if self.db is not None:
            if self.db.in_transaction:
                self.db.execute("ROLLBACK")
            self.db.close()
            self.db = None

    def __enter__(self):
        return self

    def __exit__(self, kind, value, traceback):
        self.close()

    def _rowsets(self, definition):
        return {"cards": [definition["card"]], **definition["tables"]}

    def _references(self, definition):
        rowsets = self._rowsets(definition)
        local = {table: {row["id"] for row in rows} for table, rows in rowsets.items()}
        for table, rows in rowsets.items():
            for row in rows:
                baseline = self.master.db.execute('SELECT * FROM "' + table + '" WHERE id=?', (row["id"],)).fetchone()
                names = [d[0] for d in self.master.db.execute('SELECT * FROM "' + table + '" LIMIT 0').description]
                baseline = dict(zip(names, baseline))
                for column, value in row.items():
                    target = REFERENCES.get(column)
                    if target is None:
                        if column.endswith("_id") and baseline.get(column) != value:
                            fail("OVERLAY_REFERENCE_MAPPING_UNVERIFIED")
                        continue
                    if value is None or value == 0:
                        continue
                    if type(value) is not int:
                        fail("OVERLAY_REFERENCE_INVALID")
                    if value in local.get(target, set()):
                        continue
                    try:
                        found = self.master.db.execute('SELECT 1 FROM "' + target + '" WHERE id=?', (value,)).fetchone()
                    except sqlite3.Error:
                        fail("OVERLAY_REFERENCE_TABLE_MISSING")
                    if found is None:
                        fail("OVERLAY_REFERENCE_MISSING")

    def apply(self, definition, *, projection_generation, expected_version, command_id):
        """Atomically publish settings from a committed Creator projection generation.

        Versions use compare-and-swap; exact command retries return the original
        receipt. A definition never changes its source card or creator identity.
        Scoped source row IDs are preserved without game ID allocation/remapping.
        """
        key(command_id)
        if (type(projection_generation) is not int or not 1 <= projection_generation <= 2**53 - 1 or
                type(expected_version) is not int or not 0 <= expected_version <= 2**53 - 1):
            fail("OVERLAY_REVISION_INVALID")
        # Take a detached canonical copy so caller mutation cannot alter checks.
        document = canonical(definition)
        definition = json.loads(document)
        proof = self.master.validate_settings(definition)
        self._references(definition)
        definition_id, version = definition["definition_id"], definition["version"]
        request = canonical({"definition": definition, "projection_generation": projection_generation,
                             "expected_version": expected_version})
        request_digest = hashlib.sha256(request.encode()).hexdigest()
        digest = hashlib.sha256(document.encode()).hexdigest()
        self.db.execute("BEGIN IMMEDIATE")
        try:
            replay = self.db.execute("SELECT request_digest,receipt FROM overlay_commands WHERE command_id=?", (command_id,)).fetchone()
            if replay:
                if replay[0] != request_digest:
                    fail("OVERLAY_COMMAND_CONFLICT")
                self.db.execute("COMMIT")
                return json.loads(replay[1])
            active = self.db.execute("SELECT version FROM overlay_heads WHERE definition_id=?", (definition_id,)).fetchone()
            active_version = active[0] if active else 0
            if active_version != expected_version or version <= active_version:
                fail("OVERLAY_VERSION_CONFLICT")
            stored_core = int(self.db.execute("SELECT value FROM overlay_meta WHERE key='projection_generation'").fetchone()[0])
            if projection_generation < stored_core:
                fail("OVERLAY_CORE_REVISION_STALE")
            if active:
                previous = json.loads(self.db.execute("SELECT document FROM overlay_revisions WHERE definition_id=? AND version=?", (definition_id, active_version)).fetchone()[0])
                if previous["source"] != definition["source"] or previous.get("creator") != definition.get("creator"):
                    fail("OVERLAY_DEFINITION_IDENTITY_CONFLICT")
            self.db.execute("INSERT INTO overlay_revisions VALUES(?,?,?,?,?)", (definition_id, version, document, digest, projection_generation))
            self.db.execute("INSERT INTO overlay_heads VALUES(?,?) ON CONFLICT(definition_id) DO UPDATE SET version=excluded.version", (definition_id, version))
            for table, rows in self._rowsets(definition).items():
                self.db.executemany("INSERT INTO overlay_rows VALUES(?,?,?,?,?)", [
                    (definition_id, version, table, row["id"], canonical(row)) for row in rows])
            self.db.execute("UPDATE overlay_meta SET value=? WHERE key='projection_generation'", (str(projection_generation),))
            receipt = {"definition_id": definition_id, "version": version, "projection_generation": projection_generation,
                       "document_sha256": digest, "settings_rows": proof["validated_settings_rows"],
                       "original_client_attached": False}
            self.db.execute("INSERT INTO overlay_commands VALUES(?,?,?)", (command_id, request_digest, canonical(receipt)))
            self.master.verify_unchanged()
            self.db.execute("COMMIT")
            return receipt
        except BaseException:
            if self.db.in_transaction:
                self.db.execute("ROLLBACK")
            raise

    def bind_owned(self, instance_key, definition_id, *, projection_generation):
        """Mirror an existing core-owned instance; never mint a card or progression.

        Native host must establish ownership using the authoritative core. This
        method is private host tooling and must not be exposed to page/client JS.
        """
        key(instance_key)
        key(definition_id)
        self.db.execute("BEGIN IMMEDIATE")
        try:
            self._require_revision(projection_generation)
            previous = self.db.execute("SELECT definition_id FROM overlay_bindings WHERE instance_key=?", (instance_key,)).fetchone()
            if previous and previous[0] != definition_id:
                fail("OVERLAY_INSTANCE_REBIND_FORBIDDEN")
            if self.db.execute("SELECT 1 FROM overlay_heads WHERE definition_id=?", (definition_id,)).fetchone() is None:
                fail("OVERLAY_DEFINITION_MISSING")
            self.db.execute("INSERT OR IGNORE INTO overlay_bindings VALUES(?,?)", (instance_key, definition_id))
            self.db.execute("COMMIT")
        except BaseException:
            self.db.execute("ROLLBACK")
            raise

    def _require_revision(self, projection_generation):
        stored = int(self.db.execute("SELECT value FROM overlay_meta WHERE key='projection_generation'").fetchone()[0])
        if type(projection_generation) is not int or projection_generation != stored:
            fail("OVERLAY_CORE_REVISION_MISMATCH")

    def scoped_row(self, instance_key, table, source_row_id, *, projection_generation, version=None):
        """Read a scoped sidecar row for a trusted instance, never global fallback.

        None means no staged override; it does not authorize the original engine
        to fall back silently for a custom ability. Hook attachment is unresolved.
        """
        key(instance_key)
        if table not in TABLES or type(source_row_id) is not int or source_row_id < 1:
            fail("OVERLAY_LOOKUP_INVALID")
        self._require_revision(projection_generation)
        bound = self.db.execute("SELECT b.definition_id,h.version FROM overlay_bindings b JOIN overlay_heads h USING(definition_id) WHERE instance_key=?", (instance_key,)).fetchone()
        if bound is None:
            fail("OVERLAY_OWNED_BINDING_MISSING")
        selected = bound[1] if version is None else version
        if type(selected) is not int or selected < 1:
            fail("OVERLAY_REVISION_INVALID")
        if self.db.execute("SELECT 1 FROM overlay_revisions WHERE definition_id=? AND version=?", (bound[0], selected)).fetchone() is None:
            fail("OVERLAY_REVISION_MISSING")
        row = self.db.execute("SELECT row_json FROM overlay_rows WHERE definition_id=? AND version=? AND table_name=? AND source_row_id=?", (bound[0], selected, table, source_row_id)).fetchone()
        return json.loads(row[0]) if row else None

    def binding_snapshot(self, instance_key, *, projection_generation):
        key(instance_key)
        self._require_revision(projection_generation)
        row = self.db.execute("SELECT b.definition_id,h.version,r.digest FROM overlay_bindings b JOIN overlay_heads h USING(definition_id) JOIN overlay_revisions r ON r.definition_id=h.definition_id AND r.version=h.version WHERE instance_key=?", (instance_key,)).fetchone()
        if row is None:
            fail("OVERLAY_OWNED_BINDING_MISSING")
        return {"definition_id": row[0], "version": row[1], "projection_generation": projection_generation,
                "document_sha256": row[2],
                "content_id": self.master.content_id,
                "save_scope_sha256": self.scope, "original_client_attached": False}
