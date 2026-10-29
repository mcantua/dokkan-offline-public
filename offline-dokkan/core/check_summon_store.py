"""One focused persisted-summon/migration scenario; never reruns the base core suite."""
import copy
import ctypes
import hashlib
import json
import pathlib
import sqlite3
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent

def load(name):
    lib = ctypes.CDLL(str(ROOT / "build" / name))
    lib.od_open.argtypes = [ctypes.c_char_p] * 3 + [ctypes.POINTER(ctypes.c_void_p)]
    lib.od_execute.argtypes = [ctypes.c_void_p] + [ctypes.c_char_p] * 4 + [ctypes.POINTER(ctypes.c_void_p)]
    lib.od_last_error.argtypes = [ctypes.c_void_p]
    lib.od_last_error.restype = ctypes.c_char_p
    lib.od_close.argtypes = [ctypes.c_void_p]
    lib.od_free.argtypes = [ctypes.c_void_p]
    for fn in [lib.od_export_save, lib.od_import_save]:
        fn.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
    return lib

lib = load("libodcore.so")
with tempfile.TemporaryDirectory(prefix="summon-store-", dir=ROOT / "build") as tmp:
    work = pathlib.Path(tmp)
    master = work / "master.db"
    with sqlite3.connect(master) as db:
        db.execute("CREATE TABLE cards(id INTEGER PRIMARY KEY,lv_max INTEGER,skill_lv_max INTEGER)")
        db.executemany("INSERT INTO cards VALUES(?,150,20)", [(1,), (2,), (3,), (4,), (5,)])
        db.execute("CREATE TABLE sugoroku_maps(id INTEGER PRIMARY KEY)")
        db.execute("INSERT INTO sugoroku_maps VALUES(1)")

    def opened(path, library=lib):
        core = ctypes.c_void_p()
        assert library.od_open(str(path).encode(), str(master).encode(), b"synthetic-v2", ctypes.byref(core)) == 0
        return core

    save = work / "player.db"
    core = opened(save)

    def call(op, args=None, cmd=None, profile="player", error=None, library=lib, context=None):
        out = ctypes.c_void_p()
        rc = library.od_execute(context or core, op.encode(), profile.encode(), cmd.encode() if cmd else None,
                                json.dumps(args or {}, separators=(",", ":")).encode(), ctypes.byref(out))
        if error:
            assert rc < 0 and library.od_last_error(context or core).decode() == error, (op, library.od_last_error(context or core))
            return
        assert rc == 0, (op, library.od_last_error(context or core))
        try: return json.loads(ctypes.string_at(out))
        finally: library.od_free(out)

    call("profile.create", cmd="open")
    call("inventory.grant", {"source": "funding", "rewards": [{"kind": "stone", "id": 0, "quantity": 500}]}, "fund")
    # All probabilities are explicit. The private fixture later seeds a valid 49-miss state
    # to check the next multi guarantee without probabilistic assertions or repeated draws.
    config = {"banner_id": "test", "version": 1, "epoch": 1, "main_id": "main-gr",
              "policy": {"lr_ppm": 10000, "slr_ppm": 1000, "gr_ppm": 100, "multi_count": 2},
              "pool": [{"definition_id": "ur", "master_id": 1, "rarity": "UR", "weight_ppm": 988900},
                       {"definition_id": "lr", "master_id": 2, "rarity": "LR", "weight_ppm": 10000},
                       {"definition_id": "slr", "master_id": 3, "rarity": "SLR", "weight_ppm": 1000},
                       {"definition_id": "other-gr", "master_id": 4, "rarity": "GR", "weight_ppm": 99},
                       {"definition_id": "main-gr", "master_id": 5, "rarity": "GR", "weight_ppm": 1}]}
    call("banner.configure", config, "configure")
    assert call("banner.snapshot", {"banner_id": "test"})["version"] == 1
    before = call("profile.snapshot")
    bad = copy.deepcopy(config); bad["pool"][0]["weight_ppm"] = True
    call("banner.configure", bad, "bool-policy", error="INVALID_BANNER_POOL")
    bad = copy.deepcopy(config); bad["pool"][0]["weight_ppm"] -= 1; bad["pool"][1]["weight_ppm"] += 1
    call("banner.configure", bad, "changed-version", error="INVALID_BANNER_POOL")
    assert call("profile.snapshot") == before
    conflict = copy.deepcopy(config);conflict.update(epoch=2, main_id="ur")
    call("banner.configure", conflict, "immutable-version", error="BANNER_VERSION_CONFLICT")
    first = call("summon.draw", {"banner_id": "test", "kind": "multi"}, "draw-1")
    assert len(first["summon"]["draws"]) == 2 and first["summon"]["stone_cost"] == 50
    assert call("summon.draw", {"banner_id": "test", "kind": "multi"}, "draw-1") == first
    lib.od_close(core); core = opened(save)
    assert call("summon.draw", {"banner_id": "test", "kind": "multi"}, "draw-1") == first
    lib.od_close(core)
    with sqlite3.connect(save) as db: db.execute("UPDATE banner_pity SET misses=49 WHERE profile='player' AND banner_id='test'")
    core = opened(save)
    result = call("summon.draw", {"banner_id": "test", "kind": "multi"}, "draw-50")
    assert result["summon"]["main_feature_pulled"] and result["summon"]["pity_misses"] == 0
    assert any(x["definition_id"] == "main-gr" for x in result["summon"]["draws"])
    if result["summon"]["guaranteed"]: assert result["summon"]["draws"][-1]["definition_id"] == "main-gr"
    assert len(result["cards"]) == 4
    assert result["inventory"][0]["quantity"] == 4900
    assert all(x["level"] == x["sa_level"] == 1 and x["potential"] == {} for x in result["cards"])
    lib.od_close(core)
    with sqlite3.connect(save) as db: db.execute("UPDATE banner_pity SET misses=1 WHERE profile='player' AND banner_id='test'")
    core = opened(save)
    next_config = copy.deepcopy(config);next_config.update(version=2, epoch=2, main_id="ur")
    call("banner.configure", next_config, "new-main")
    assert call("banner.snapshot", {"banner_id": "test"})["pity_misses"] == 0
    current = call("profile.snapshot")
    assert call("banner.configure", next_config, "same-config") == current
    call("summon.draw", {"banner_id": "test", "kind": "single", "pool": []}, "injected-pool", error="INVALID_ARGUMENT")
    call("profile.create", cmd="poor-open", profile="poor")
    call("banner.configure", config, "poor-config", profile="poor")
    call("summon.draw", {"banner_id": "test", "kind": "single"}, "poor-draw", profile="poor", error="INSUFFICIENT_STONES")
    # Only retention/replay is under test here; full run settlement already passed the base scenario.
    lib.od_close(core)
    with sqlite3.connect(save) as db:
        for i in range(1, 131):
            db.execute("INSERT INTO runs(id,profile,map_id,quest_id,content,team_slot,team_snapshot,entry_cost,rewards,state,outcome,result) VALUES(?,'player',1,1,'synthetic-v2',0,'[1]',0,?,'finished','clear',?)",
                       (f"old-run-{i}", json.dumps({"rewards":[{"kind":"stone","id":0,"quantity":1}]}), json.dumps({"revision": i})))
    core = opened(save)
    for i in range(130): call("profile.create", {}, f"retention-{i}")
    current = call("profile.snapshot")
    call("summon.draw", {"banner_id":"test","kind":"multi"}, "draw-1", error="COMMAND_RESULT_EXPIRED")
    call("run.finish", {"run_id":"old-run-1","outcome":"clear"}, "expired-run", error="RUN_RESULT_EXPIRED")
    assert call("profile.snapshot") == current
    with sqlite3.connect(save) as db:
        assert db.execute("SELECT count(*) FROM commands WHERE profile='player' AND result!='null'").fetchone()[0] == 128
        assert db.execute("SELECT result FROM commands WHERE profile='player' AND id='draw-1'").fetchone()[0] == 'null'
        assert db.execute("SELECT count(*) FROM runs WHERE profile='player' AND result!='null'").fetchone()[0] == 128
    exported = work / "export.db"
    assert lib.od_export_save(core, str(exported).encode()) == 0
    with sqlite3.connect(exported) as db:
        db.execute("UPDATE owned_cards SET master_id=CASE WHEN master_id=3 THEN 4 ELSE 3 END WHERE id=1")
    assert lib.od_import_save(core, str(exported).encode()) < 0
    assert call("profile.snapshot") == current
    lib.od_close(core)

    # A frozen copy of OUR v1 schema is a migration fixture, not game data or an old release.
    legacy = work / "legacy.db"
    with sqlite3.connect(legacy) as db:
        db.executescript((ROOT / "fixtures/schema-v1.sql").read_text())
        db.execute("INSERT INTO meta VALUES('content','synthetic-v2')")
        db.execute("INSERT INTO profiles(id,revision,stamina) VALUES('legacy',2,7)")
        db.execute("INSERT INTO inventory VALUES('legacy','stone',0,10)")
    oldbackup = work / "legacy-export.db"
    with sqlite3.connect(legacy) as source, sqlite3.connect(oldbackup) as target: source.backup(target)
    core = opened(legacy)
    assert call("profile.snapshot", profile="legacy")["inventory"] == [{"kind":"stone","id":0,"quantity":10}]
    assert call("profile.snapshot", profile="legacy")["stamina"] == 7
    with sqlite3.connect(legacy) as db: assert db.execute("PRAGMA user_version").fetchone()[0] == 11
    digest = hashlib.sha256(oldbackup.read_bytes()).hexdigest()
    assert lib.od_import_save(core, str(oldbackup).encode()) == 0
    assert call("profile.snapshot", profile="legacy")["inventory"] == [{"kind":"stone","id":0,"quantity":10}]
    assert call("profile.snapshot", profile="legacy")["stamina"] == 7
    assert hashlib.sha256(oldbackup.read_bytes()).hexdigest() == digest
    lib.od_close(core)
print("PASS persisted secure-random summons: debit/grants/pity/replay/version/reset, immutable catalog, command/run retention tombstones, provenance rejection, v1 open/import migration")
