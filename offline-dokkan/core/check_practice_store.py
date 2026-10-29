#!/usr/bin/env python3
"""One actual C Core ledger scenario; readonly supplied master, temporary own profile.
No original client/native combat executes. Covers migration, source/scope/authority,
exact-once finish, unknown-reply replay, explicit known-revision retry and restart.
"""
import argparse
import ctypes
import hashlib
import json
from pathlib import Path
import sqlite3
import tempfile

ROOT = Path(__file__).resolve().parent
p = argparse.ArgumentParser(description=__doc__)
p.add_argument('master', type=Path)
p.add_argument('--content', required=True)
a = p.parse_args()
master = a.master.resolve()
prior_master = master.stat()
with sqlite3.connect(master.as_uri() + '?mode=ro&immutable=1', uri=True) as db:
    rows = db.execute("SELECT parameters FROM tutorial_phases WHERE number=3 AND tutorial_scene_url='internal:Tutorial::BattleSetupScene'").fetchall()
    assert len(rows) == 1
    phase_hash = hashlib.sha256(rows[0][0].encode()).hexdigest()
lib = ctypes.CDLL(str(ROOT / 'build/libodcore.so'))
lib.od_open.argtypes = [ctypes.c_char_p]*3 + [ctypes.POINTER(ctypes.c_void_p)]
lib.od_execute.argtypes = [ctypes.c_void_p] + [ctypes.c_char_p]*4 + [ctypes.POINTER(ctypes.c_void_p)]
lib.od_original_client_apply.argtypes = [ctypes.c_void_p] + [ctypes.c_char_p]*4 + [ctypes.c_int64, ctypes.c_char_p, ctypes.POINTER(ctypes.c_void_p)]
lib.od_offline_player_snapshot.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.POINTER(ctypes.c_void_p)]
lib.od_last_error.argtypes = [ctypes.c_void_p]
lib.od_last_error.restype = ctypes.c_char_p
lib.od_close.argtypes = lib.od_free.argtypes = [ctypes.c_void_p]
profile = b'practice-check-owner'
with tempfile.TemporaryDirectory(prefix='practice-ledger-', dir=ROOT/'build') as temporary:
    save = Path(temporary)/'player.db'
    def opened():
        result = ctypes.c_void_p()
        assert lib.od_open(str(save).encode(), str(master).encode(), a.content.encode(), ctypes.byref(result)) == 0
        return result
    core = opened()
    def output(fn, *values, error=None):
        value = ctypes.c_void_p()
        rc = fn(*values, ctypes.byref(value))
        if error:
            assert rc < 0 and not value.value and lib.od_last_error(core).decode() == error, (rc, lib.od_last_error(core))
            return
        assert rc == 0, (rc, lib.od_last_error(core))
        try:
            return json.loads(ctypes.string_at(value))
        finally:
            lib.od_free(value)
    def ordinary(op, payload, command, error=None):
        return output(lib.od_execute, core, op.encode(), profile, command.encode(), json.dumps(payload).encode(), error=error)
    def snapshot():
        return output(lib.od_offline_player_snapshot, core, profile)
    ordinary('profile.create', {}, 'create')
    baseline = snapshot()
    lib.od_close(core)
    # Only this check's disposable own DB is adjusted to exercise migration.
    with sqlite3.connect(save) as db:
        db.execute('DROP TABLE offline_practice_sessions')
        db.execute('PRAGMA user_version=14')
    core = opened()
    assert snapshot() == baseline
    with sqlite3.connect(save) as db:
        assert db.execute('PRAGMA user_version').fetchone()[0] == 15
        identity = db.execute("SELECT v FROM meta WHERE k='projection_identity'").fetchone()[0]
    scope = hashlib.sha256(json.dumps([identity, profile.decode(), a.content], separators=(',', ':')).encode()).hexdigest()
    payload = {'session_id':'practice-check-1', 'parameters_sha256':phase_hash, 'phase_number':3}
    def native(op, command, revision, values=payload, expected_scope=scope, error=None):
        return output(lib.od_original_client_apply, core, op.encode(), profile, command.encode(), expected_scope.encode(), revision,
            json.dumps(values, separators=(',', ':')).encode(), error=error)
    r = baseline['revision']
    ordinary('native.practice.begin', {}, 'public-forbidden', error='ORIGINAL_PLAYER_NATIVE_AUTHORITY_REQUIRED')
    native('practice.finish', 'missing-finish', r, error='PRACTICE_SESSION_NOT_FOUND')
    native('practice.begin', 'bad-source', r, dict(payload, parameters_sha256='0'*64), error='PRACTICE_SOURCE_HASH_MISMATCH')
    native('practice.begin', 'bad-scope', r, expected_scope='0'*64, error='ORIGINAL_PLAYER_SCOPE_CHANGED')
    assert snapshot() == baseline
    prepared = native('practice.begin', 'begin', r)
    assert prepared['state'] == 'prepared' and prepared['prepared_revision'] == r+1
    assert native('practice.begin', 'begin', r) == prepared
    # The actual native callback boundary is simulated only as a trusted Core
    # intent here. This does not claim a real battle or callback occurred.
    settled = native('practice.finish', 'finish', r+1)
    assert settled['state'] == 'native-finish-observed' and settled['finish_revision'] == r+2
    second = dict(payload, session_id='practice-check-2')
    native('practice.begin', 'begin-second', r+2, second)
    # A lost finish reply followed by another legitimate revision still replays
    # the exact original intent instead of recording another completion.
    assert native('practice.finish', 'finish', r+1) == settled
    assert snapshot()['revision'] == r+3
    # Exact known precommit revision failure permits a NEW explicit intent.
    native('practice.finish', 'second-stale', r+2, second, error='ORIGINAL_PLAYER_REVISION_CHANGED')
    second_settled = native('practice.finish', 'second-retry1', r+3, second)
    assert second_settled['finish_revision'] == r+4
    native('practice.finish', 'second-observed-again', r+4, second)
    saved = snapshot()
    assert saved['revision'] == r+4
    assert saved['offline_practice']['native_finish_count'] == 2
    assert saved['offline_practice']['prepared_count'] == 0
    assert {k:v for k,v in saved.items() if k not in ('revision','offline_practice')} == {
        k:v for k,v in baseline.items() if k not in ('revision','offline_practice')}
    with sqlite3.connect(save) as db:
        for table in ('quest_progress','runs','reward_sources','owned_cards','teams','inventory'):
            assert db.execute('SELECT count(*) FROM '+table).fetchone()[0] == 0
    lib.od_close(core)
    core = opened()
    assert snapshot() == saved
    lib.od_close(core)
now = master.stat()
assert (prior_master.st_dev,prior_master.st_ino,prior_master.st_size,prior_master.st_mtime_ns) == (now.st_dev,now.st_ino,now.st_size,now.st_mtime_ns)
print('PASS C practice ledger: v14 migration, authority/source/scope, lost-reply replay, explicit stale-revision retry, unchanged game state, durable reopen; no original gameplay executed')
