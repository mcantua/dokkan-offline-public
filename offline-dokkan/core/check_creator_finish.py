"""One focused real-master Creator Finish/collection/team/edit/save scenario.

Pass an existing private master path; no game rows are copied into source.
"""
import copy
import ctypes
import hashlib
import json
from pathlib import Path
import sqlite3
import sys
import tempfile

ROOT = Path(__file__).resolve().parent
master = Path(sys.argv[1]).resolve()
with master.open('rb') as f:
    digest = hashlib.file_digest(f, 'sha256').hexdigest()
content = ('sha256:' + digest).encode()
lib = ctypes.CDLL(str(ROOT / 'build/libodcore.so'))
lib.od_open.argtypes = [ctypes.c_char_p] * 3 + [ctypes.POINTER(ctypes.c_void_p)]
lib.od_execute.argtypes = [ctypes.c_void_p] + [ctypes.c_char_p] * 4 + [ctypes.POINTER(ctypes.c_void_p)]
lib.od_last_error.argtypes = [ctypes.c_void_p]
lib.od_last_error.restype = ctypes.c_char_p
lib.od_close.argtypes = lib.od_free.argtypes = [ctypes.c_void_p]
lib.od_export_save.argtypes = lib.od_import_save.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
with sqlite3.connect(master.as_uri() + '?mode=ro', uri=True) as data:
    data.row_factory = sqlite3.Row
    card = dict(data.execute('SELECT * FROM cards WHERE id=1007471').fetchone())
    level_two = data.execute('SELECT exp_total FROM card_exps WHERE exp_type=? AND lv=2', (card['exp_type'],)).fetchone()[0]

def opened(save):
    handle = ctypes.c_void_p()
    assert lib.od_open(str(save).encode(), str(master).encode(), content, ctypes.byref(handle)) == 0
    return handle

with tempfile.TemporaryDirectory(prefix='creator-finish-', dir=ROOT/'build') as temp:
    work = Path(temp)
    save = work / 'player.db'
    core = opened(save)
    def call(operation, args=None, command=None, profile='p', error=None):
        result = ctypes.c_void_p()
        rc = lib.od_execute(core, operation.encode(), profile.encode(), command.encode() if command else None,
                            json.dumps(args or {}, separators=(',', ':')).encode(), ctypes.byref(result))
        if error:
            assert rc < 0 and lib.od_last_error(core).decode() == error, (operation, lib.od_last_error(core))
            return
        assert rc == 0, (operation, lib.od_last_error(core))
        try:
            return json.loads(ctypes.string_at(result))
        finally:
            lib.od_free(result)

    call('profile.create', command='open')
    doc = {'format':'offline-dokkan-definition', 'schema_version':1,
           'definition_id':'local-finish-unit', 'version':1,
           'source':{'content_id':content.decode(), 'master_id':card['id']},
           'rarity':'LR', 'fully_awakened':True, 'card':card, 'tables':{},
           'creator':{'id':'local-creator', 'name':'Local Creator'}}
    # An existing imported settings version must also become usable without minting
    # another definition or treating a legacy import receipt as collection ownership.
    call('creator.import', {'definition':doc}, 'legacy-import')
    assert call('profile.snapshot')['cards'] == []
    result = call('creator.finish', {'definition':doc}, 'finish:collection-v1')
    owned = result['instance_id']
    assert result['library']['revision'] == result['revision']
    assert result['newly_owned'] and result['available'] and result['library']['main_id'] == doc['definition_id']
    assert call('creator.finish', {'definition':doc}, 'finish:collection-v1') == result
    again = call('creator.finish', {'definition':doc}, 'fresh-intent')
    assert again['instance_id'] == owned and not again['newly_owned']
    snapshot = call('profile.snapshot')
    assert len(snapshot['cards']) == 1 and not snapshot['inventory']
    row = snapshot['cards'][0]
    assert row['instance_id'] == owned and row['level'] == row['sa_level'] == 1
    assert row['created_definition']['potential_locked'] == 1 and row['created_definition']['addons'] == []
    assert row['created_definition']['origin_version'] == 1 and row['created_definition']['version'] == 1
    team = call('team.set', {'slot':0, 'members':[owned]}, 'team')
    assert team['teams'][0]['members'] == [owned]
    progressed = call('card.experience.grant', {'instance_id':owned, 'source':'focused-progress', 'quantity':level_two}, 'xp')
    assert progressed['cards'][0]['level'] == 2
    call('card.lock', {'instance_id':owned, 'locked':True}, 'lock')
    edited = copy.deepcopy(doc)
    edited['version'] = 2
    edited['card']['name'] = 'Locally edited character'
    edited['card']['atk_max'] += 100
    changed = call('creator.finish', {'definition':edited}, 'edit:collection-v1')
    assert changed['instance_id'] == owned and not changed['newly_owned'] and changed['version'] == 2
    current = call('profile.snapshot')
    assert len(current['cards']) == 1 and current['teams'][0]['members'] == [owned]
    assert current['cards'][0]['level'] == 2 and current['cards'][0]['experience'] == level_two and current['cards'][0]['locked'] == 1
    assert current['cards'][0]['created_definition']['version'] == 2 and current['cards'][0]['created_definition']['origin_version'] == 1
    assert current['created_definitions'][0]['document']['card']['name'] == edited['card']['name']
    # Invalid new settings roll back both registration and any would-be owned copy.
    invalid = copy.deepcopy(edited)
    invalid['definition_id'] = 'invalid-new-definition'
    invalid['version'] = 1
    invalid['card']['hp_max'] = True
    call('creator.finish', {'definition':invalid}, 'invalid', error='INVALID_DEFINITION_STATS')
    assert call('profile.snapshot') == current
    lib.od_close(core)
    core = opened(save)
    assert call('profile.snapshot') == current
    exported = work/'saved.db'
    assert lib.od_export_save(core, str(exported).encode()) == 0
    assert lib.od_import_save(core, str(exported).encode()) == 0
    assert call('profile.snapshot') == current
    with sqlite3.connect(exported) as bad:
        bad.execute('UPDATE creator_collection SET origin_version=2')
    assert lib.od_import_save(core, str(exported).encode()) < 0
    assert call('profile.snapshot') == current
    # A new command after retained response expiry still returns the same permanent
    # ownership binding rather than awarding another copy.
    lib.od_close(core)
    with sqlite3.connect(save) as stored:
        stored.execute("UPDATE commands SET result='null' WHERE operation='creator.finish'")
    core = opened(save)
    recovered = call('creator.finish', {'definition':edited}, 'after-expiry')
    assert recovered['instance_id'] == owned and not recovered['newly_owned']
    assert len(call('profile.snapshot')['cards']) == 1
    lib.od_close(core)

    # Check only the changed migration boundary and oldest supported entry path.
    legacy7 = work/'legacy7.db'
    core = opened(legacy7)
    call('profile.create', command='legacy-open')
    call('creator.import', {'definition':doc}, 'old-settings')
    lib.od_close(core)
    with sqlite3.connect(legacy7) as old:
        # Build an actual v7 fixture from today's core by removing its newer
        # native projection schema as well as the prior v8/v9 additions.
        for name, in old.execute("SELECT name FROM sqlite_schema WHERE type='trigger' AND name LIKE '_od_projection_%'").fetchall():
            old.execute('DROP TRIGGER "' + name + '"')
        old.execute('DROP TRIGGER _od_identity_profile')
        old.execute('DROP TABLE offline_identity')
        old.execute('DROP TABLE creator_projection')
        old.execute("DELETE FROM meta WHERE k='projection_identity'")
        old.execute('DROP TABLE player_progress')
        old.execute('DROP TABLE creator_collection')
        old.execute('PRAGMA user_version=7')
    for source in [legacy7, work/'legacy1.db']:
        if source.name == 'legacy1.db':
            with sqlite3.connect(source) as old:
                old.executescript((ROOT/'fixtures/schema-v1.sql').read_text())
                old.execute('INSERT INTO meta VALUES(?,?)', ('content', content.decode()))
                old.execute("INSERT INTO profiles(id,stamina) VALUES('p',7)")
        original_hash = hashlib.sha256(source.read_bytes()).hexdigest()
        target = work/(source.stem+'-target.db')
        core = opened(target)
        assert lib.od_import_save(core, str(source).encode()) == 0
        assert hashlib.sha256(source.read_bytes()).hexdigest() == original_hash
        migrated = call('profile.snapshot')
        assert migrated['cards'] == []
        lib.od_close(core)
        core = opened(source)
        lib.od_close(core)
        with sqlite3.connect(source) as old:
            assert old.execute('PRAGMA user_version').fetchone()[0] == 11
with master.open('rb') as f:
    assert hashlib.file_digest(f, 'sha256').hexdigest() == digest
print('PASS one real-master Creator Finish → collection/team → progress-preserving edit/retry/reopen/save/migration scenario; original master unchanged. Gameplay/rendering/native runtime are not asserted.')
