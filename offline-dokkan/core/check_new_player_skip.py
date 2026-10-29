#!/usr/bin/env python3
"""One changed-policy schema14 SQL preservation check and actual projection.

Synthetic in-memory data only. Does not open a save/master, compile C/ObjC or
execute native command/scope control flow, an app build or the original game.
"""
import ast
import hashlib
import json
from pathlib import Path
import re
import sqlite3
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
LITERAL = r'((?:"(?:\\.|[^"\\])*"\s*)+)'

def joined(value):
    return ''.join(ast.literal_eval(s) for s in re.findall(r'"(?:\\.|[^"\\])*"', value))

def constant(source, name):
    match = re.search(r'\b' + name + r'\s*(?:\[\])?\s*=\s*' + LITERAL + ';', source)
    assert match, name
    return joined(match.group(1))

def returned(source, name):
    match = re.search(r'\b' + name + r'\(void\)\s*\{\s*return\s*' + LITERAL + ';', source)
    assert match, name
    return joined(match.group(1))

core = (HERE / 'od_core.c').read_text()
module = (HERE / 'original_teams.c').read_text()
schedule = (HERE / 'schedules_store.c').read_text()
kai = (HERE / 'kai_training.c').read_text()
ddl = constant(core, 'SCHEMA')
for version in range(2, 14):
    if version == 5:
        ddl += returned(schedule, 'od_schedule_store_schema')
    if version == 6:
        ddl += returned(schedule, 'od_schedule_store_schema_v2')
    if version == 7:
        ddl += returned(kai, 'od_kai_training_schema')
    if version == 13:
        ddl += constant(module, 'schema_sql')
    ddl += constant(core, 'SCHEMA_V' + str(version))
db = sqlite3.connect(':memory:', isolation_level=None)
db.execute('PRAGMA foreign_keys=ON')
db.executescript(ddl)
db.execute("INSERT INTO profiles(id,revision) VALUES('legacy',7)")
db.execute("INSERT INTO profiles(id,revision) VALUES('older-missing',4)")
db.execute("INSERT INTO od_original_tutorial VALUES('legacy',12345,0,'original-tutorial-entry-v1')")
db.execute("INSERT INTO owned_cards(id,profile,master_id) VALUES(11,'legacy',1)")
db.execute("INSERT INTO teams VALUES('legacy',3,'[11]')")
prior = list(db.execute('SELECT * FROM od_original_tutorial'))
prior_profiles = list(db.execute('SELECT * FROM profiles ORDER BY id'))
prior_cards = list(db.execute('SELECT * FROM owned_cards'))
prior_teams = list(db.execute('SELECT * FROM teams'))
migration = constant(core, 'SCHEMA_V14')
try:
    db.executescript("BEGIN IMMEDIATE;" + migration +
        "INSERT INTO od_original_tutorial VALUES('older-missing',1,1,'offline-new-player-skip-v1');")
except sqlite3.IntegrityError:
    db.execute('ROLLBACK')
else:
    raise AssertionError('Invalid skip tuple unexpectedly committed')
assert db.execute('PRAGMA user_version').fetchone()[0] == 13
assert list(db.execute('SELECT * FROM od_original_tutorial')) == prior
assert not db.execute("SELECT 1 FROM sqlite_schema WHERE name='od_original_tutorial_v13'").fetchone()
db.executescript('BEGIN IMMEDIATE;' + migration + 'COMMIT;')
assert db.execute('PRAGMA user_version').fetchone()[0] == 14
assert list(db.execute('SELECT * FROM od_original_tutorial')) == prior
assert list(db.execute('SELECT * FROM profiles ORDER BY id')) == prior_profiles
assert list(db.execute('SELECT * FROM owned_cards')) == prior_cards
assert list(db.execute('SELECT * FROM teams')) == prior_teams
assert not db.execute("SELECT 1 FROM od_original_tutorial WHERE profile='older-missing'").fetchone()
sqls = [joined(m.group(1)) for m in re.finditer(LITERAL, core)]
seed = next(s for s in sqls if s.startswith('INSERT INTO od_original_tutorial VALUES(:p'))
owner = 'synthetic-new-player'
db.execute('INSERT INTO profiles(id) VALUES(?)', (owner,))
db.execute(seed, {'p': owner})
assert db.execute('SELECT progress,is_finished,policy FROM od_original_tutorial WHERE profile=?', (owner,)).fetchone() == (0, 1, 'offline-new-player-skip-v1')
assert not db.execute('SELECT 1 FROM owned_cards WHERE profile=?', (owner,)).fetchone()
assert not db.execute('SELECT 1 FROM teams WHERE profile=?', (owner,)).fetchone()
assert not db.execute('SELECT 1 FROM inventory WHERE profile=?', (owner,)).fetchone()
guard = next(s for s in sqls if s.startswith('SELECT count(*) FROM od_original_tutorial WHERE profile=:p AND is_finished=0'))
assert db.execute(guard, {'p': owner}).fetchone()[0] == 0
assert db.execute(guard, {'p': 'legacy'}).fetchone()[0] == 1
update = next(s for s in sqls if s.startswith('UPDATE od_original_tutorial SET progress='))
db.execute(update, {'p': owner, 'a': '{"progress":10102}'})
assert db.execute('SELECT changes()').fetchone()[0] == 0
assert db.execute('SELECT progress,is_finished FROM od_original_tutorial WHERE profile=?', (owner,)).fetchone() == (0, 1)
# A direct repeated seed also cannot replace a preserved old row. Actual Core
# !replay/profile-creation control flow is source-reviewed, not executed here.
try:
    db.execute(seed, {'p': 'legacy'})
except sqlite3.IntegrityError:
    pass
else:
    raise AssertionError('Legacy tutorial checkpoint replaced')
assert list(db.execute("SELECT * FROM od_original_tutorial WHERE profile='legacy'")) == prior
snapshot_sql = next(s for s in sqls if s.startswith("SELECT COALESCE((SELECT json_object('schema',1,'policy',policy,'progress',progress,'is_finished'"))
new_record = json.loads(db.execute(snapshot_sql, {'p': owner}).fetchone()[0])
legacy_record = json.loads(db.execute(snapshot_sql, {'p': 'legacy'}).fetchone()[0])
assert new_record == {'schema': 1, 'policy': 'offline-new-player-skip-v1', 'progress': 0, 'is_finished': True}
assert legacy_record['progress'] == 12345 and legacy_record['is_finished'] is False
assert json.loads(db.execute(snapshot_sql, {'p': 'older-missing'}).fetchone()[0]) is None
assert not db.execute('PRAGMA foreign_key_check').fetchone()
# One integration assertion using the ACTUAL new SQL tuple, not a repeat of
# the player's already-passed full changed-policy projection negatives.
js = r"""const fs=require('fs'),assert=require('assert'),projector=require(process.argv[1]),fresh=require(process.argv[2]);const t=JSON.parse(fs.readFileSync(0,'utf8'));const expected={profile_id:'synthetic-new-player',content_id:'synthetic-master',save_scope_sha256:'ab'.repeat(32)};const snapshot={...expected,revision:0,wire_identity:{id:1,name:'Offline Player'},rank:1,rank_experience:0,stamina_max:20,source_rank:{rank:1,exp_total:0,act_max:20,friends_capacity:50},cards:[],teams:[],original_client_tutorial:t};const result=projector.projectNewProfilePlayer({admission:{...expected,clean:true},player_snapshot:snapshot},expected);assert.deepStrictEqual(result.response.user.tutorial,{progress:0,is_finished:true});assert(!result.http_route_admitted);assert.deepStrictEqual(fresh.evaluate(snapshot,{}).sections.user.tutorial,{progress:0,is_finished:true});"""
subprocess.run(['node', '-e', js, str(ROOT / 'offline-dokkan/original-client/protocol/resources-projector.js'), str(ROOT / 'offline-dokkan/original-client/protocol/fresh-state-policy.js')], input=json.dumps(new_record), text=True, check=True)
evidence = {'kind': 'schema14-new-player-no-intro-preservation', 'runs': 1,
    'scope': 'synthetic actual extracted migration/seed/snapshot/guard SQL plus actual new SQL tuple through JS projection/fresh policy',
    'schema13_failure_rolls_back': True, 'schema13_existing_rows_profiles_cards_teams_preserved': True,
    'older_missing_tutorial_rows_not_backfilled': True, 'new_only_skip_tuple_zero_true': True,
    'new_player_no_cards_items_or_teams_granted': True, 'skip_profile_checkpoint_sql_guard_rejects': True,
    'snapshot_emits_actual_json_boolean': True, 'actual_sql_tuple_projects_new_player_skip': True,
    'foreign_key_check_passed': True, 'core_c_control_flow_or_import_execution_verified': False,
    'objc_or_original_game_executed': False, 'app_builds': 0,
    'source_sha256': {'od_core.c': hashlib.sha256((HERE / 'od_core.c').read_bytes()).hexdigest()}}
(HERE / 'new-player-skip-evidence.json').write_text(json.dumps(evidence, indent=2) + '\n')
print('Schema14 legacy preservation/new-only skip SQL→actual JS projection passed; native code/game remain unexecuted.')
