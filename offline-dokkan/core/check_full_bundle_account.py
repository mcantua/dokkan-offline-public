"""One saved-account check for a validated full Creator packet.

Public creator.import and creator.finish must reject the descriptor.
The native finish grants one owned copy on local-player and keeps it.
Uses a tiny synthetic master. No game rows and no phone launch.
"""
import ctypes
import hashlib
import json
import sqlite3
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent
lib = ctypes.CDLL(str(ROOT / "build/libodcore.so"))
lib.od_open.argtypes = [ctypes.c_char_p] * 3 + [ctypes.POINTER(ctypes.c_void_p)]
lib.od_execute.argtypes = [ctypes.c_void_p] + [ctypes.c_char_p] * 4 + [ctypes.POINTER(ctypes.c_void_p)]
lib.od_creator_finish_bundle.argtypes = [
    ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p, ctypes.c_char_p,
    ctypes.c_void_p, ctypes.c_size_t, ctypes.POINTER(ctypes.c_void_p)]
lib.od_creator_finish_bundle.restype = ctypes.c_int
lib.od_creator_accepted_bundle.argtypes = [
    ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p, ctypes.c_int64,
    ctypes.c_int64, ctypes.c_char_p, ctypes.POINTER(ctypes.c_void_p),
    ctypes.POINTER(ctypes.c_size_t), ctypes.POINTER(ctypes.c_void_p),
    ctypes.POINTER(ctypes.c_void_p)]
lib.od_creator_accepted_bundle.restype = ctypes.c_int
lib.od_last_error.argtypes = [ctypes.c_void_p]
lib.od_last_error.restype = ctypes.c_char_p
lib.od_close.argtypes = lib.od_free.argtypes = [ctypes.c_void_p]

SOURCE = "ab" * 32
CONTENT = "sha256:" + SOURCE
SCOPE = "cd" * 32
PROFILE = "local-player"


def packet(member_count=1):
    body = {
        "format": "od-native-creator-full-bundle-v2",
        "content_id": CONTENT,
        "profile_id": PROFILE,
        "save_scope": SCOPE,
        "definition_id": "local-finish-unit",
        "version": 1,
        "project_sha256": "11" * 32,
        "source_sha256": SOURCE,
        "member_count": member_count,
        "materialization_utc": 1,
        "resources": [],
        "engine_admission": "pending-master-cipher-resource-and-form-progression-binding",
        "members": [{"key": "root"}],
        "tables": {},
        "transform_links": [],
        "source_dependencies": [],
        "shared_actions": [],
    }
    raw = json.dumps(body, separators=(",", ":"), sort_keys=True).encode()
    assert b"\0" not in raw
    return raw


def definition(raw):
    card = {
        "id": 1, "name": "Synthetic", "rarity": 5, "element": 0, "lv_max": 150,
        "skill_lv_max": 10, "hp_init": 100, "hp_max": 1000, "atk_init": 100,
        "atk_max": 1000, "def_init": 100, "def_max": 1000,
        "leader_skill_set_id": 1, "passive_skill_set_id": 1,
    }
    return {
        "format": "offline-dokkan-definition", "schema_version": 1,
        "definition_id": "local-finish-unit", "version": 1,
        "source": {"content_id": CONTENT, "master_id": 1},
        "rarity": "LR", "fully_awakened": True, "card": card, "tables": {},
        "full_bundle": {
            "format": "od-full-creator-binding-v2",
            "projection": "progression-root-v1",
            "content_id": CONTENT, "profile_id": PROFILE, "save_scope": SCOPE,
            "definition_id": "local-finish-unit", "version": 1,
            "project_sha256": "11" * 32,
            "full_bundle_sha256": hashlib.sha256(raw).hexdigest(),
            "member_count": 1,
        },
    }


with tempfile.TemporaryDirectory(prefix="full-bundle-account-", dir=ROOT / "build") as temp:
    work = Path(temp)
    master, save = work / "master.db", work / "player.db"
    with sqlite3.connect(master) as db:
        db.execute("""CREATE TABLE cards(
            id INTEGER PRIMARY KEY, name TEXT NOT NULL, rarity INTEGER NOT NULL,
            element INTEGER NOT NULL, lv_max INTEGER NOT NULL, skill_lv_max INTEGER NOT NULL,
            hp_init INTEGER NOT NULL, hp_max INTEGER NOT NULL, atk_init INTEGER NOT NULL,
            atk_max INTEGER NOT NULL, def_init INTEGER NOT NULL, def_max INTEGER NOT NULL,
            leader_skill_set_id INTEGER NOT NULL, passive_skill_set_id INTEGER NOT NULL)""")
        db.execute("INSERT INTO cards VALUES(1,'Synthetic',5,0,150,10,100,1000,100,1000,100,1000,1,1)")
        db.execute("CREATE TABLE card_awakening_routes(id INTEGER PRIMARY KEY, card_id INTEGER, awaked_card_id INTEGER, type TEXT)")
        db.execute("CREATE TABLE leader_skill_sets(id INTEGER PRIMARY KEY)")
        db.execute("CREATE TABLE passive_skill_sets(id INTEGER PRIMARY KEY)")
        db.execute("INSERT INTO leader_skill_sets VALUES(1)")
        db.execute("INSERT INTO passive_skill_sets VALUES(1)")
    handle = ctypes.c_void_p()
    assert lib.od_open(str(save).encode(), str(master).encode(), CONTENT.encode(), ctypes.byref(handle)) == 0

    def call(operation, args, command=None, error=None):
        result = ctypes.c_void_p()
        rc = lib.od_execute(handle, operation.encode(), PROFILE.encode(),
                            command.encode() if command else None,
                            json.dumps(args, separators=(",", ":")).encode(), ctypes.byref(result))
        if error:
            assert rc < 0 and lib.od_last_error(handle).decode() == error, lib.od_last_error(handle)
            return None
        assert rc == 0, (operation, lib.od_last_error(handle))
        try:
            return json.loads(ctypes.string_at(result))
        finally:
            lib.od_free(result)

    def finish_bundle(raw, document, command, error=None):
        result = ctypes.c_void_p()
        buffer = ctypes.create_string_buffer(raw)
        rc = lib.od_creator_finish_bundle(handle, PROFILE.encode(), command.encode(),
                                           json.dumps(document, separators=(",", ":")).encode(),
                                           buffer, len(raw), ctypes.byref(result))
        if error:
            assert rc < 0 and lib.od_last_error(handle).decode() == error, lib.od_last_error(handle)
            return None
        assert rc == 0, lib.od_last_error(handle)
        try:
            return json.loads(ctypes.string_at(result))
        finally:
            lib.od_free(result)

    call("profile.create", {}, "open")
    with sqlite3.connect(save) as state:
        identity = state.execute("SELECT v FROM meta WHERE k='projection_identity'").fetchone()[0]
    SCOPE = hashlib.sha256(json.dumps([identity, PROFILE, CONTENT], separators=(",", ":")).encode()).hexdigest()
    raw = packet()
    document = definition(raw)
    call("creator.finish", {"definition": document}, "public-finish", error="FULL_BUNDLE_NATIVE_VALIDATION_REQUIRED")
    call("creator.import", {"definition": document}, "public-import", error="FULL_BUNDLE_NATIVE_VALIDATION_REQUIRED")
    bad = bytearray(raw)
    bad[-2] = ord("0") if bad[-2] != ord("0") else ord("1")
    finish_bundle(bytes(bad), document, "bad-hash", error="FULL_BUNDLE_HASH_MISMATCH")
    assert call("profile.snapshot", {})["cards"] == []
    saved = finish_bundle(raw, document, "finish:collection-v1")
    owned = saved["instance_id"]

    def read_bundle(instance, scope=SCOPE, error=None):
        blob = ctypes.c_void_p()
        length = ctypes.c_size_t()
        registered = ctypes.c_void_p()
        receipt = ctypes.c_void_p()
        rc = lib.od_creator_accepted_bundle(handle, PROFILE.encode(), b"local-finish-unit",
            1, instance, scope.encode(), ctypes.byref(blob), ctypes.byref(length),
            ctypes.byref(registered), ctypes.byref(receipt))
        if error:
            assert rc < 0 and lib.od_last_error(handle).decode() == error
            assert not blob.value and not length.value and not registered.value and not receipt.value
            return
        assert rc == 0, lib.od_last_error(handle)
        try:
            assert ctypes.string_at(blob, length.value) == raw
            assert json.loads(ctypes.string_at(registered)) == document
            proof = json.loads(ctypes.string_at(receipt))
            assert proof["instance_id"] == owned and proof["save_scope"] == SCOPE
            assert proof["full_bundle_sha256"] == hashlib.sha256(raw).hexdigest()
            assert proof["profile_revision"] >= 1 and proof["projection_generation"] >= 1
        finally:
            for value in (blob, registered, receipt): lib.od_free(value)

    read_bundle(owned)
    read_bundle(owned, scope="ff" * 32, error="FULL_BUNDLE_SAVE_SCOPE_MISMATCH")
    read_bundle(owned + 1, error="FULL_BUNDLE_ACCEPTED_OWNERSHIP_UNAVAILABLE")
    assert saved["newly_owned"] is True and saved["definition_id"] == "local-finish-unit"
    assert finish_bundle(raw, document, "finish:collection-v1")["instance_id"] == owned
    again = finish_bundle(raw, document, "fresh-intent")
    assert again["instance_id"] == owned and again["newly_owned"] is False
    team = call("team.set", {"slot": 0, "members": [owned]}, "team")
    assert team["teams"][0]["members"] == [owned]
    snapshot = call("profile.snapshot", {})
    assert snapshot["profile_id"] == PROFILE and len(snapshot["cards"]) == 1
    assert snapshot["cards"][0]["instance_id"] == owned and snapshot["cards"][0]["level"] == 1
    lib.od_close(handle)
    handle = ctypes.c_void_p()
    assert lib.od_open(str(save).encode(), str(master).encode(), CONTENT.encode(), ctypes.byref(handle)) == 0
    reopened = call("profile.snapshot", {})
    read_bundle(owned)
    assert len(reopened["cards"]) == 1 and reopened["teams"][0]["members"] == [owned]
    lib.od_close(handle)
print("PASS full bundle stays out of public Finish and imports once into the saved local-player account")
