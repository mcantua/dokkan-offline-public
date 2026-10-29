"""One real-master fresh-player → run entry → trusted-clock ACT recovery scenario."""
import ctypes
import hashlib
import json
from pathlib import Path
import sqlite3
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parents[1]
master = Path(sys.argv[1]).resolve()
with master.open('rb') as stream:
    original_hash = hashlib.file_digest(stream, 'sha256').hexdigest()
content = ('sha256:' + original_hash).encode()
lib = ctypes.CDLL(str(ROOT/'build/libodcore.so'))
lib.od_open.argtypes = [ctypes.c_char_p]*3+[ctypes.POINTER(ctypes.c_void_p)]
lib.od_execute.argtypes = [ctypes.c_void_p]+[ctypes.c_char_p]*4+[ctypes.POINTER(ctypes.c_void_p)]
lib.od_execute_clocked.argtypes = [ctypes.c_void_p]+[ctypes.c_char_p]*4+[ctypes.c_int64,ctypes.POINTER(ctypes.c_void_p)]
lib.od_last_error.argtypes = [ctypes.c_void_p]
lib.od_last_error.restype = ctypes.c_char_p
lib.od_close.argtypes = lib.od_free.argtypes = [ctypes.c_void_p]
lib.od_export_save.argtypes = lib.od_import_save.argtypes = [ctypes.c_void_p,ctypes.c_char_p]
with sqlite3.connect(master.as_uri()+'?mode=ro', uri=True) as data:
    data.row_factory = sqlite3.Row
    capacity = data.execute('SELECT act_max FROM rank_statuses WHERE rank=1').fetchone()[0]
    source_card = dict(data.execute('SELECT * FROM cards WHERE id=1002351').fetchone())
    assert data.execute('SELECT act FROM sugoroku_maps WHERE id=10').fetchone()[0] == 1

def opened(save):
    core = ctypes.c_void_p()
    assert lib.od_open(str(save).encode(), str(master).encode(), content, ctypes.byref(core)) == 0
    return core

with tempfile.TemporaryDirectory(prefix='player-act-', dir=ROOT/'build') as temporary:
    work = Path(temporary)
    save = work/'player.db'
    core = opened(save)
    def call(operation, args=None, command=None, now=None, error=None):
        result = ctypes.c_void_p()
        values = [core, operation.encode(), b'local-player', command.encode() if command else None,
                  json.dumps(args or {}, separators=(',', ':')).encode()]
        rc = lib.od_execute(*values, ctypes.byref(result)) if now is None else lib.od_execute_clocked(*values, now, ctypes.byref(result))
        if error:
            assert rc < 0 and lib.od_last_error(core).decode() == error, (operation, lib.od_last_error(core))
            return
        assert rc == 0, (operation, lib.od_last_error(core))
        try:
            return json.loads(ctypes.string_at(result))
        finally:
            lib.od_free(result)
    created = call('profile.create', command='create', now=1000)
    assert created['stamina'] == created['stamina_max'] == capacity and created['rank'] == 1 and created['rank_experience'] == 0
    assert created['inventory'] == created['cards'] == created['teams'] == []
    assert created['stamina_recovery'] == {'policy':'offline-rank1-act-v1', 'seconds_per_point':300, 'anchor_utc':1000}
    assert call('profile.create', command='create', now=999999) == created
    assert call('profile.create', command='new-create', now=999999)['stamina'] == capacity
    # A user-created unit supplies the team; no starter card/currency is invented.
    document = {'format':'offline-dokkan-definition','schema_version':1,'definition_id':'act-player-unit','version':1,
                'source':{'content_id':content.decode(),'master_id':source_card['id']},'rarity':'UR',
                'fully_awakened':True,'card':source_card,'tables':{}}
    owned = call('creator.finish', {'definition':document}, 'finish')['instance_id']
    call('team.set', {'slot':0,'members':[owned]}, 'team')
    # A trusted rewardless encounter settles without inventing currency/items.
    arguments = {'run_id':'act-run-1','map_id':10,'team_slot':0,'assets_ready':True,'rewards':[]}
    started = call('run.start', arguments, 'start', now=10000)
    assert started['stamina'] == capacity-1 and started['stamina_recovery']['anchor_utc'] == 10000
    assert call('run.start', arguments, 'start', now=20000) == started
    finished = call('run.finish', {'run_id':'act-run-1','outcome':'clear'}, 'finish-empty')
    assert finished['inventory'] == [] and finished['stamina'] == capacity-1
    assert call('run.finish', {'run_id':'act-run-1','outcome':'clear'}, 'finish-empty') == finished
    assert call('run.finish', {'run_id':'act-run-1','outcome':'clear'}, 'new-clear-intent') == finished
    with sqlite3.connect(save) as settled:
        assert settled.execute("SELECT clears FROM quest_progress WHERE profile='local-player' AND quest_id=1").fetchone()[0] == 1
        assert settled.execute("SELECT count(*) FROM reward_sources WHERE profile='local-player' AND source='run:act-run-1'").fetchone()[0] == 1
    call('inventory.grant', {'source':'empty-grant','rewards':[]}, 'bad-empty-grant', error='INVALID_ARGUMENT')
    # Idle time spent at capacity must not bank ACT for the first debit.
    assert call('profile.refresh', command='not-yet', now=10299)['stamina'] == capacity-1
    recovered = call('profile.refresh', command='recover', now=10300)
    assert recovered['stamina'] == capacity and recovered['stamina_recovery']['anchor_utc'] == 10300
    assert call('profile.refresh', command='recover', now=999999) == recovered
    assert call('profile.refresh', command='full', now=20000)['stamina'] == capacity
    arguments['run_id'] = 'act-run-2'
    second = call('run.start', arguments, 'second-start', now=20000)
    assert second['stamina'] == capacity-1
    assert call('profile.refresh', command='backward', now=19000)['stamina'] == capacity-1
    before = call('profile.snapshot')
    # A duplicate run ID fails after recovery/debit and rolls both back together.
    call('run.start', arguments, 'duplicate-run', now=20600, error='DATABASE_ERROR')
    assert call('profile.snapshot') == before
    assert call('profile.refresh', command='after-failure', now=20600)['stamina'] == capacity
    call('profile.refresh', {'now_utc':999999}, 'forged-time', now=21000, error='CLOCKED_ARGUMENT_FORBIDDEN')
    exported = work/'legacy8.db'
    assert lib.od_export_save(core, str(exported).encode()) == 0
    lib.od_close(core)
    # A schema8 save imports without granting or resetting any legacy ACT.
    with sqlite3.connect(exported) as old:
        for name, in old.execute("SELECT name FROM sqlite_schema WHERE type='trigger' AND name LIKE '_od_projection_%'").fetchall():
            old.execute('DROP TRIGGER "' + name + '"')
        old.execute('DROP TRIGGER _od_identity_profile')
        for table in ('od_original_team_selection','od_original_team_bindings','od_original_tutorial',
                      'created_full_bundles','offline_identity','creator_projection'):
            old.execute('DROP TABLE ' + table)
        old.execute("DELETE FROM meta WHERE k='projection_identity'")
        old.execute('DROP TABLE player_progress')
        old.execute('PRAGMA user_version=8')
        old.execute('UPDATE profiles SET stamina=0')
    legacy_hash = hashlib.sha256(exported.read_bytes()).hexdigest()
    core = opened(save)
    assert lib.od_import_save(core, str(exported).encode()) == 0
    assert hashlib.sha256(exported.read_bytes()).hexdigest() == legacy_hash
    assert call('profile.create', command='legacy-reopen', now=30000)['stamina'] == 0
    attached = call('profile.refresh', command='attach-clock', now=30000)
    assert attached['stamina'] == 0 and attached['stamina_max'] == capacity
    assert call('profile.refresh', command='legacy-recover', now=30300)['stamina'] == 1
    lib.od_close(core)
    # Over-cap balances are legitimate legacy state; recovery never destroys them.
    with sqlite3.connect(exported) as old:
        old.execute('UPDATE profiles SET stamina=?', (capacity+7,))
    core = opened(save)
    assert lib.od_import_save(core, str(exported).encode()) == 0
    assert call('profile.refresh', command='overflow-attach', now=40000)['stamina'] == capacity+7
    assert call('profile.refresh', command='overflow-wait', now=50000)['stamina'] == capacity+7
    lib.od_close(core)
    core = opened(save)
    assert call('profile.snapshot')['stamina'] == capacity+7
    lib.od_close(core)
    # Exercise the real native capability filter: client clocks/amounts/run policies
    # cannot cross it. This tiny wrapper links the core just checked above.
    bridge_path = work/'bridge.so'
    subprocess.run(['cc','-O2','-std=c11','-Wall','-Wextra','-Werror','-fPIC','-shared',
                    str(REPO/'offline-dokkan/adapter/od_bridge.c'),'-I'+str(REPO/'downloads/sqlite-header'),
                    '-L'+str(ROOT/'build'),'-lodcore','-Wl,-rpath,'+str(ROOT/'build'),
                    '-Wl,-l:libsqlite3.so.0','-lpthread','-o',str(bridge_path)],check=True)
    bridge = ctypes.CDLL(str(bridge_path))
    bridge.od_bridge_open.argtypes = [ctypes.c_char_p]*3+[ctypes.POINTER(ctypes.c_void_p)]*2
    bridge.od_bridge_execute.argtypes = [ctypes.c_void_p]+[ctypes.c_char_p]*4+[ctypes.POINTER(ctypes.c_void_p)]*2
    bridge.od_bridge_close.argtypes = bridge.od_bridge_free.argtypes = [ctypes.c_void_p]
    host = ctypes.c_void_p()
    error = ctypes.c_void_p()
    assert bridge.od_bridge_open(str(work/'native-player.db').encode(),str(master).encode(),content,ctypes.byref(host),ctypes.byref(error)) == 0
    def native(operation,args,command='native-intent',failure=None):
        result=ctypes.c_void_p();error=ctypes.c_void_p()
        rc=bridge.od_bridge_execute(host,operation.encode(),b'local-player',command.encode(),json.dumps(args).encode(),ctypes.byref(result),ctypes.byref(error))
        try:
            if failure:
                assert rc<0 and ctypes.string_at(error).decode()==failure
                return
            assert rc==0
            return json.loads(ctypes.string_at(result))
        finally:
            if result.value:bridge.od_bridge_free(result)
            if error.value:bridge.od_bridge_free(error)
    fresh_native=native('profile.create',{})
    assert fresh_native['stamina']==capacity and fresh_native['stamina_recovery']['anchor_utc']>0
    native('profile.refresh',{'now_utc':1},failure='INVALID_ARGUMENT')
    native('profile.create',{'initial_stamina':999},failure='INVALID_ARGUMENT')
    native('run.start',arguments,failure='UNSUPPORTED_OPERATION')
    bridge.od_bridge_close(host)
with master.open('rb') as stream:
    assert hashlib.file_digest(stream,'sha256').hexdigest()==original_hash
print('PASS one real-master fresh ACT/run/recovery/retry/rollback/legacy-preservation/native-clock-boundary scenario; no gameplay rendering or device install claimed.')
