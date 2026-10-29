#!/usr/bin/env python3
"""One extracted-SQL migration/formation scenario plus actual JS projection.

Never opens a game database or a user save. This does not compile/execute the
C control flow, bridge, Objective-C, original client or an application build.
"""
import ast
import hashlib
import json
from pathlib import Path
import re
import sqlite3
import subprocess
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
LITERALS = r'((?:"(?:\\.|[^"\\])*"\s*)+)'


def joined(text):
    return ''.join(ast.literal_eval(value) for value in re.findall(r'"(?:\\.|[^"\\])*"', text))


def constant(source, name):
    match = re.search(r'\b' + re.escape(name) + r'\s*(?:\[\])?\s*=\s*' + LITERALS + ';', source)
    assert match, 'Missing SQL constant ' + name
    return joined(match.group(1))


def returned(source, name):
    match = re.search(r'\b' + re.escape(name) + r'\(void\)\s*\{\s*return\s*' + LITERALS + ';', source)
    assert match, 'Missing schema function ' + name
    return joined(match.group(1))


def statements(source):
    return [joined(match.group(1)) for match in re.finditer(LITERALS, source)]


core = (HERE / 'od_core.c').read_text()
module = (HERE / 'original_teams.c').read_text()
schedule = (HERE / 'schedules_store.c').read_text()
kai = (HERE / 'kai_training.c').read_text()
ddl = [constant(core, 'SCHEMA')]
for version in range(2, 13):
    if version == 5:
        ddl.append(returned(schedule, 'od_schedule_store_schema'))
    if version == 6:
        ddl.append(returned(schedule, 'od_schedule_store_schema_v2'))
    if version == 7:
        ddl.append(returned(kai, 'od_kai_training_schema'))
    ddl.append(constant(core, 'SCHEMA_V' + str(version)))
if '--metadata-only' in sys.argv:
    # Second check: only the newly changed reference/context persistence and
    # real GET/POST candidate normalization. Prior migration/layout proof is reused.
    db = sqlite3.connect(':memory:', isolation_level=None)
    db.execute('PRAGMA foreign_keys=ON')
    db.executescript(''.join(ddl) + constant(module, 'schema_sql') + constant(core, 'SCHEMA_V13'))
    owner = 'synthetic-owner'
    db.execute('INSERT INTO profiles(id,revision) VALUES(?,1)', (owner,))
    db.executemany('INSERT INTO owned_cards(id,profile,master_id) VALUES(?,?,1)', [(11, owner), (12, owner)])
    sqls = statements(module)
    team_insert = next(sql for sql in sqls if sql.startswith('INSERT INTO teams(profile,slot,members)'))
    binding_insert = next(sql for sql in sqls if sql.startswith('INSERT INTO od_original_team_bindings('))
    reference_valid = constant(module, 'reference_validation_sql')
    context_valid = constant(module, 'context_validation_sql')
    selection_sql = constant(module, 'selection_sql')
    snapshot_sql = constant(module[module.index('int od_original_teams_snapshot'):], 'sql')
    references = {'referenced_sugoroku_map_id': -2147483648,
                  'referenced_z_battle_stage_id': 2147483647,
                  'referenced_card_ids': [-2147483648, 0, 2147483647]}
    context = {'sugoroku_map_id': 0, 'z_battle_stage_id': 4294967295, 'origin_battle_id': 7}
    def accepted(sql, value):
        return db.execute(sql, (json.dumps(value),)).fetchone()[0] == 1
    assert accepted(reference_valid, references) and accepted(context_valid, context)
    for field, value in [('referenced_sugoroku_map_id', -2147483649),
                         ('referenced_z_battle_stage_id', True),
                         ('referenced_card_ids', [2147483648])]:
        assert not accepted(reference_valid, dict(references, **{field: value}))
    assert not accepted(reference_valid, dict(references, extra=1))
    assert not accepted(reference_valid, {'referenced_card_ids': []})
    for bad in ({'origin_battle_id': -1}, {'origin_battle_id': 4294967296},
                {'origin_battle_id': True}, {'grant_stones': 1}):
        assert not accepted(context_valid, bad)
    slots = '[11,0,12,0,0,0]'
    db.execute('BEGIN IMMEDIATE')
    db.execute(team_insert, (owner, 0, slots))
    db.execute(binding_insert, (owner, 0, 7, 'Synthetic native formation', 'original_bgm', slots, json.dumps(references)))
    db.execute(selection_sql, (owner, json.dumps({'selected_team_num': 7, 'advisory_context': context})))
    db.execute('COMMIT')
    # Unknown historical/new metadata stays SQL NULL, never fabricated zeros.
    db.execute(team_insert, (owner, 1, '[]'))
    db.execute(binding_insert, (owner, 1, 8, 'Unknown references', None, '[0,0,0,0,0,0]', None))
    assert db.execute('SELECT reference_fields FROM od_original_team_bindings WHERE slot=1').fetchone()[0] is None
    # Actual upsert NULL is the C result of omitted/null references; preserve prior.
    db.execute(binding_insert, (owner, 0, 7, 'Synthetic native formation', 'original_bgm', slots, None))
    db.execute(selection_sql, (owner, '{}'))
    native = json.loads(db.execute(snapshot_sql, (owner,)).fetchone()[0])
    assert native['bindings'][0]['references'] == references
    assert native['bindings'][1]['references'] is None and native['advisory_context'] == context
    # Unknown references intentionally block a complete native GET response.
    # Keep that preservation assertion above, then use a complete one-team
    # snapshot for the real request-normalizer persistence handoff below.
    db.execute('DELETE FROM teams WHERE profile=? AND slot=1', (owner,))
    native = json.loads(db.execute(snapshot_sql, (owner,)).fetchone()[0])
    teams = [{'slot': row[0], 'members': json.loads(row[1])} for row in db.execute('SELECT slot,members FROM teams ORDER BY slot')]
    fixture = {'original_client_teams': native, 'teams': teams, 'revision': 1}
    checker = ROOT / 'offline-dokkan/original-client/protocol/player-home-team/check_native_team_metadata.js'
    result = subprocess.run(['node', str(checker)], input=json.dumps(fixture), text=True, check=True, capture_output=True)
    normalized = json.loads(result.stdout)
    mutation = normalized['mutation']; row = mutation['teams'][0]
    assert accepted(reference_valid, row['references']) and accepted(context_valid, mutation['advisory_context'])
    db.execute('BEGIN IMMEDIATE')
    db.execute(binding_insert, (owner, 0, row['native_num'], row['name'], row['team_bgm_filename'], json.dumps(row['card_slots']), json.dumps(row['references'])))
    db.execute(selection_sql, (owner, json.dumps(mutation)))
    db.execute('COMMIT')
    after = json.loads(db.execute(snapshot_sql, (owner,)).fetchone()[0])
    assert after['bindings'][0]['references'] == row['references'] and after['advisory_context'] == mutation['advisory_context']
    assert db.execute('SELECT count(*) FROM owned_cards').fetchone()[0] == 2
    assert db.execute('SELECT count(*) FROM inventory').fetchone()[0] == 0
    assert db.execute('SELECT revision FROM profiles WHERE id=?', (owner,)).fetchone()[0] == 1
    assert not db.execute('PRAGMA foreign_key_check').fetchone()
    evidence = {'kind': 'schema13-native-team-changed-metadata-sql-and-js', 'runs': 1,
        'prior_migration_layout_tutorial_evidence_reused': 'original-player-state-evidence.json',
        'actual_reference_and_context_sql_validation': True, 'signed32_and_unsigned32_bounds_and_json_bool_rejection': True,
        'unknown_references_remain_null': True, 'omitted_metadata_preserves_prior': True,
        'actual_snapshot_to_get_post_normalizer_to_persisted_sql': True,
        'no_ownership_inventory_progression_grants': True, 'foreign_key_check_passed': True,
        'core_c_control_flow_or_command_replay_executed': False, 'objc_bridge_or_gameplay_executed': False,
        'app_builds': 0, 'http_route_admitted': False,
        'source_sha256': {name: hashlib.sha256((HERE / name).read_bytes()).hexdigest() for name in ('od_core.c', 'original_teams.c')}}
    (HERE / 'original-team-metadata-evidence.json').write_text(json.dumps(evidence, indent=2) + '\n')
    print('Changed native-team metadata SQL→actual GET/POST JS→SQL passed; native C/ObjC/game remain unexecuted.')
    sys.exit(0)

db = sqlite3.connect(':memory:', isolation_level=None)
db.execute('PRAGMA foreign_keys=ON')
db.executescript(''.join(ddl))
db.execute("INSERT INTO meta VALUES('content','synthetic-master')")
db.execute("INSERT INTO profiles(id,revision) VALUES('legacy',3)")
db.execute("INSERT INTO owned_cards(id,profile,master_id) VALUES(91,'legacy',1)")
db.execute("INSERT INTO teams VALUES('legacy',19,'[91]')")
baseline = list(db.execute("SELECT profile,slot,members FROM teams"))
migration = constant(module, 'schema_sql') + constant(core, 'SCHEMA_V13')
try:
    db.executescript("BEGIN IMMEDIATE;" + migration +
                     "INSERT INTO od_original_tutorial VALUES('legacy',-1,0,'original-tutorial-entry-v1');")
except sqlite3.IntegrityError:
    db.execute('ROLLBACK')
else:
    raise AssertionError('Invalid migration fixture unexpectedly committed')
assert db.execute('PRAGMA user_version').fetchone()[0] == 12
assert not db.execute("SELECT 1 FROM sqlite_schema WHERE name='od_original_tutorial'").fetchone()
assert list(db.execute("SELECT profile,slot,members FROM teams")) == baseline
db.executescript('BEGIN IMMEDIATE;' + migration + 'COMMIT;')
assert db.execute('PRAGMA user_version').fetchone()[0] == 13
assert db.execute('SELECT count(*) FROM od_original_tutorial').fetchone()[0] == 0
assert list(db.execute("SELECT profile,slot,members FROM teams")) == baseline

owner = 'synthetic-owner'
db.execute('INSERT INTO profiles(id) VALUES(?)', (owner,))
seed = next(sql for sql in statements(core) if sql.startswith('INSERT INTO od_original_tutorial VALUES'))
db.execute(seed, {'p': owner})
assert db.execute('SELECT progress,is_finished FROM od_original_tutorial WHERE profile=?', (owner,)).fetchone() == (0, 0)
assert not db.execute('SELECT 1 FROM owned_cards WHERE profile=?', (owner,)).fetchone()
db.executemany('INSERT INTO owned_cards(id,profile,master_id) VALUES(?,?,1)', [(11, owner), (12, owner), (13, owner), (99, 'legacy')])
db.execute("INSERT INTO commands VALUES(?,'synthetic-consumption','fixture','{}','{}')", (owner,))
db.execute("INSERT INTO elder_kai_configs VALUES(?,'synthetic-kai',1,0,'{}')", (owner,))
db.execute("INSERT INTO sa_training_events VALUES(1,?,'synthetic-consumption',11,'synthetic-kai',1,'{}',2,1,2,'[13]')", (owner,))
db.execute('INSERT INTO owned_consumptions VALUES(13,?,1,0)', (owner,))
valid = constant(module, 'valid')
record = {'teams': [{'native_num': 7, 'name': 'Synthetic formation', 'team_bgm_filename': None,
                     'card_slots': [11, 0, 12, 0, 0, 0]}], 'selected_team_num': 7}
assert db.execute(valid, (json.dumps(record), owner)).fetchone()[0] == 1
for slots in ([11, 0, 99, 0, 0, 0], [11, 0, 13, 0, 0, 0], [11, 0, 11, 0, 0, 0], [11, 0, -1, 0, 0, 0]):
    bad = json.loads(json.dumps(record)); bad['teams'][0]['card_slots'] = slots
    assert db.execute(valid, (json.dumps(bad), owner)).fetchone()[0] == 0

slot_sql = constant(module, 'slot_sql')
sqls = statements(module)
team_insert = next(sql for sql in sqls if sql.startswith('INSERT INTO teams(profile,slot,members)'))
binding_insert = next(sql for sql in sqls if sql.startswith('INSERT INTO od_original_team_bindings('))
validate = constant(module, 'validation_sql')
db.execute('BEGIN IMMEDIATE')
slot = db.execute(slot_sql, (owner, 7)).fetchone()[0]
assert slot == 0
slots = json.dumps(record['teams'][0]['card_slots'])
db.execute(team_insert, (owner, slot, slots))
db.execute(binding_insert, (owner, slot, 7, 'Synthetic formation', None, slots, None))
db.execute(constant(module, 'selection_sql'), (owner, json.dumps(record)))
assert not db.execute(validate).fetchone()
assert db.execute(slot_sql, (owner, 7)).fetchone()[0] == 0
assert db.execute(slot_sql, (owner, 17)).fetchone()[0] == 1
db.execute('COMMIT')
before = list(db.execute('SELECT profile,slot,members FROM teams'))
db.execute('BEGIN IMMEDIATE')
db.execute("UPDATE teams SET members='[12,11]' WHERE profile=? AND slot=0", (owner,))
assert db.execute(validate).fetchone(), 'Stale compact edit was not detected'
db.execute('ROLLBACK')
assert list(db.execute('SELECT profile,slot,members FROM teams')) == before

# Execute the actual source checkpoint SQL and prove rollback covers revision
# with the same persisted state; this is SQL proof, not C command-cache proof.
update = next(sql for sql in statements(core) if sql.startswith('UPDATE od_original_tutorial SET progress='))
db.execute('BEGIN IMMEDIATE')
db.execute(update, {'p': owner, 'a': '{"progress":12345}'})
db.execute('UPDATE profiles SET revision=revision+1 WHERE id=?', (owner,))
db.execute('ROLLBACK')
assert db.execute('SELECT progress FROM od_original_tutorial WHERE profile=?', (owner,)).fetchone()[0] == 0
db.execute('BEGIN IMMEDIATE')
db.execute(update, {'p': owner, 'a': '{"progress":12345}'})
db.execute('UPDATE profiles SET revision=revision+1 WHERE id=?', (owner,))
db.execute('COMMIT')
assert db.execute('SELECT progress,is_finished FROM od_original_tutorial WHERE profile=?', (owner,)).fetchone() == (12345, 0)
assert not db.execute('PRAGMA foreign_key_check').fetchone()
snapshot_sql = constant(module[module.index('int od_original_teams_snapshot'):], 'sql')
native = json.loads(db.execute(snapshot_sql, (owner,)).fetchone()[0])
teams = [{'slot': row[0], 'members': json.loads(row[1])} for row in db.execute('SELECT slot,members FROM teams WHERE profile=? ORDER BY slot', (owner,))]
fixture = {'original_client_teams': native, 'teams': teams, 'revision': db.execute('SELECT revision FROM profiles WHERE id=?', (owner,)).fetchone()[0]}
check = ROOT / 'offline-dokkan/original-client/protocol/player-home-team/check_core_team_projection.js'
subprocess.run(['node', str(check)], input=json.dumps(fixture), text=True, check=True)
fresh_script = """const p=require(process.argv[1]);const assert=require('assert');const s={rank:1,rank_experience:0,stamina_max:20,source_rank:{rank:1,exp_total:0,act_max:20,friends_capacity:50},original_client_tutorial:{schema:1,policy:'original-tutorial-entry-v1',progress:12345,is_finished:false}};const r=p.evaluate(s,{});assert.deepStrictEqual(r.sections.user.tutorial,{progress:12345,is_finished:false});assert(r.unresolved.includes('tutorial.contents_lv'));assert(!r.unresolved.includes('tutorial.progress'));delete s.original_client_tutorial;assert(p.evaluate(s,{}).unresolved.includes('tutorial.progress'));assert.throws(()=>p.evaluate(s,{user:{tutorial:{progress:0}}}),/PRE_SERVER_SENTINEL_REJECTED/);"""
subprocess.run(['node', '-e', fresh_script, str(ROOT / 'offline-dokkan/original-client/protocol/fresh-state-policy.js')], check=True)
evidence = {'kind': 'schema13-original-player-sql-and-js-scenario', 'runs': 1,
    'scope': 'actual extracted schema/mutation/validation SQL in memory, actual JS projection and fresh-state policy',
    'migration_rollback_and_legacy_state_preserved': True, 'legacy_profiles_not_reset': True,
    'new_profile_empty_collection_and_start_control_state': True, 'checkpoint_rollback_and_persistence_sql': True,
    'opaque_team_key_and_six_position_formation_preserved': True, 'invalid_foreign_consumed_duplicate_layout_rejected': True,
    'generic_stale_layout_detected_before_commit': True, 'foreign_key_check_passed': True,
    'core_c_control_flow_or_command_replay_executed': False, 'objc_bridge_or_gameplay_executed': False,
    'app_builds': 0, 'http_route_admitted': False,
    'source_sha256': {name: hashlib.sha256((HERE / name).read_bytes()).hexdigest() for name in ('od_core.c', 'original_teams.c')}}
(HERE / 'original-player-state-evidence.json').write_text(json.dumps(evidence, indent=2) + '\n')
print('Combined schema13 SQL and actual JS scenario passed; native C/ObjC/game remain unexecuted.')
