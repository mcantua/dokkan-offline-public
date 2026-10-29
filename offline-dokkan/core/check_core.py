"""One combined domain/integrity check. Uses tiny synthetic masters; no game data is bundled."""
import ctypes
import json
import pathlib
import shutil
import sqlite3
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent
lib = ctypes.CDLL(str(ROOT / "build/libodcore.so"))
lib.od_open.argtypes = [ctypes.c_char_p] * 3 + [ctypes.POINTER(ctypes.c_void_p)]
lib.od_open.restype = ctypes.c_int
lib.od_execute.argtypes = [ctypes.c_void_p] + [ctypes.c_char_p] * 4 + [ctypes.POINTER(ctypes.c_void_p)]
lib.od_execute.restype = ctypes.c_int
lib.od_last_error.argtypes = [ctypes.c_void_p]
lib.od_last_error.restype = ctypes.c_char_p
lib.od_close.argtypes = [ctypes.c_void_p]
lib.od_free.argtypes = [ctypes.c_void_p]
for fn in [lib.od_export_save, lib.od_import_save]:
    fn.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
    fn.restype = ctypes.c_int

with tempfile.TemporaryDirectory(prefix="core-", dir=ROOT / "build") as temp:
    work = pathlib.Path(temp)
    master, save = work / "master.db", work / "player.db"
    with sqlite3.connect(master) as db:
        for table in ["awakening_items", "training_items", "support_items", "equipment_skill_items", "act_items"]:
            db.execute(f"CREATE TABLE {table}(id INTEGER PRIMARY KEY)")
            db.executemany(f"INSERT INTO {table} VALUES(?)", [(1,), (2,), (3,)])

        db.execute("CREATE TABLE cards(id INTEGER PRIMARY KEY,lv_max INTEGER,skill_lv_max INTEGER)")
        db.executemany("INSERT INTO cards VALUES(?,150,20)", [(1,), (2,), (3,)])
        db.execute("CREATE TABLE quests(id INTEGER PRIMARY KEY,prev_quest_id INTEGER)")
        db.executemany("INSERT INTO quests VALUES(?,?)", [(1,0), (2,1)])
        db.execute("CREATE TABLE sugoroku_maps(id INTEGER PRIMARY KEY,quest_id INTEGER,act INTEGER)")
        db.executemany("INSERT INTO sugoroku_maps VALUES(?,?,?)", [(1,1,5), (2,2,7), (3,1,999)])

    def opened():
        p = ctypes.c_void_p()
        assert lib.od_open(str(save).encode(), str(master).encode(), b"synthetic-content-v1", ctypes.byref(p)) == 0
        return p

    core = opened()
    def call(op, args=None, command=None, profile="player", error=None):
        out = ctypes.c_void_p()
        raw = json.dumps(args or {}, separators=(",", ":")).encode()
        rc = lib.od_execute(core, op.encode(), profile.encode(), command.encode() if command else None, raw, ctypes.byref(out))
        if error:
            assert rc < 0, (op, "unexpected success")
            assert lib.od_last_error(core).decode() == error, lib.od_last_error(core)
            assert not out.value
            return
        assert rc == 0, (op, lib.od_last_error(core))
        try: return json.loads(ctypes.string_at(out))
        finally: lib.od_free(out)

    first = call("profile.create", {"initial_stamina": 20}, command="open-1")
    assert first["inventory"] == [] and first["cards"] == []
    assert call("profile.create", {"initial_stamina": 20}, command="open-1") == first
    call("profile.create", {"changed": True}, "open-1", error="COMMAND_CONFLICT")
    lib.od_close(core); core = opened()
    assert call("profile.snapshot")["revision"] == first["revision"]
    print("PASS profile/restart and command replay/conflict")

    rewards = {"source": "mission-1", "rewards": [{"kind": "stone", "id": 0, "quantity": 2}, {"kind": "medal", "id": 1, "quantity": 2}, {"kind": "training", "id": 1, "quantity": 2}]}
    result = call("inventory.grant", rewards, "reward-1")
    quantities = {r["kind"]: r["quantity"] for r in result["inventory"]}
    assert quantities == {"stone": 20, "medal": 12, "training": 6}, quantities
    assert call("inventory.grant", rewards, "reward-1") == result
    call("inventory.grant", rewards, "reward-new-intent")
    assert {r["kind"]: r["quantity"] for r in call("profile.snapshot")["inventory"]} == quantities
    before = call("profile.snapshot")
    bad = {"source": "bad", "rewards": [{"kind": "stone", "id": 0, "quantity": 1}, {"kind": "medal", "id": 999, "quantity": 1}]}
    call("inventory.grant", bad, "bad-reward", error="INVALID_REWARD")
    assert call("profile.snapshot") == before
    call("inventory.grant", {"source": "overflow", "rewards": [{"kind": "stone", "id": 0, "quantity": 9007199254740991}]}, "overflow", error="INVALID_REWARD")
    call("inventory.grant", {"source":"bool", "rewards":[{"kind":"medal","id":True,"quantity":1}]}, "bool", error="INVALID_REWARD")
    print("PASS exclusive multipliers, reward-source replay and atomic rejection")

    card = call("card.add", {"master_id": 1}, "card-1")["cards"][0]
    assert card["level"] == card["sa_level"] == 1 and card["potential"] == {}
    call("team.set", {"slot": 0, "members": [card["instance_id"]]}, "team-1")
    call("team.set", {"slot": 1, "members": [card["instance_id"], card["instance_id"]]}, "bad-team", error="DUPLICATE_TEAM_MEMBER")
    call("team.set", {"slot": 1, "members": [999]}, "foreign-team", error="CARD_NOT_OWNED")
    call("card.add", {"master_id": 999}, "bad-card", error="CARD_NOT_FOUND")
    print("PASS owned card defaults and team ownership/references")

    plan = {"run_id": "run-1", "map_id": 1, "team_slot": 0, "assets_ready": True, "rewards": [{"kind": "stone", "id": 0, "quantity": 1}]}
    started = call("run.start", plan, "start-1")
    assert call("run.start", plan, "start-1") == started
    settled = call("run.finish", {"run_id": "run-1", "outcome": "clear"}, "finish-1")
    assert {r["kind"]: r["quantity"] for r in settled["inventory"]}["stone"] == 30
    assert call("run.finish", {"run_id": "run-1", "outcome": "clear"}, "finish-1") == settled
    assert call("run.finish", {"run_id": "run-1", "outcome": "clear"}, "finish-retry-new-id") == settled
    assert call("profile.snapshot")["revision"] == settled["revision"]
    assert settled["stamina"] == 15
    assert {r["kind"]: r["quantity"] for r in call("profile.snapshot")["inventory"]}["stone"] == 30
    locked = dict(plan, run_id="locked", map_id=2)
    # Quest 2 unlocked only after finishing quest 1.
    call("run.start", dict(plan, run_id="too-expensive", map_id=3), "cost-failure", error="INSUFFICIENT_STAMINA")
    call("run.start", dict(plan, run_id="missing-assets", assets_ready=False), "asset-failure", error="CONTENT_MISSING")
    call("run.finish", {"run_id":"run-1", "outcome":"failed"}, "changed-finish", error="RUN_OUTCOME_CONFLICT")
    print("PASS persisted run, real entry cost, content gate and immutable exactly-once settlement")

    exported = work / "export.db"
    assert lib.od_export_save(core, str(exported).encode()) == 0
    exported_bytes = exported.read_bytes()
    assert lib.od_export_save(core, str(exported).encode()) < 0 and exported.read_bytes() == exported_bytes
    before = call("profile.snapshot")
    call("card.add", {"master_id": 2}, "card-2")
    assert lib.od_import_save(core, str(exported).encode()) == 0
    assert call("profile.snapshot") == before
    malformed = work / "malformed.db"
    shutil.copy2(exported, malformed)
    with sqlite3.connect(malformed) as db: db.execute("CREATE TRIGGER injected AFTER INSERT ON profiles BEGIN DELETE FROM inventory; END")
    assert lib.od_import_save(core, str(malformed).encode()) < 0
    assert call("profile.snapshot") == before
    incompatible = work / "incompatible.db"
    shutil.copy2(exported, incompatible)
    with sqlite3.connect(incompatible) as db: db.execute("UPDATE meta SET v='different' WHERE k='content'")
    assert lib.od_import_save(core, str(incompatible).encode()) < 0
    assert call("profile.snapshot") == before
    bad_team = work / "bad-team.db"
    shutil.copy2(exported, bad_team)
    with sqlite3.connect(bad_team) as db: db.execute("UPDATE teams SET members='[999]'")
    assert lib.od_import_save(core, str(bad_team).encode()) < 0
    high_level = work / "high-level.db"
    shutil.copy2(exported, high_level)
    with sqlite3.connect(high_level) as db: db.execute("UPDATE owned_cards SET level=999")
    assert lib.od_import_save(core, str(high_level).encode()) < 0
    assert call("profile.snapshot") == before
    print("PASS consistent export, import restoration and hostile/incompatible/team/level rejection")
    lib.od_close(core)
print("5 focused core scenarios passed")
