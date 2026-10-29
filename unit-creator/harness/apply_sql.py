"""Apply an exported unit SQL file to an in-memory copy of the reference DB and run integrity checks."""
import sqlite3, sys, json
sys.path.insert(0, "/home/claude/work/harness")
from integrity import check
src = sqlite3.connect("file:/home/claude/work/apk/assets/reference.db?mode=ro", uri=True)
db = sqlite3.connect(":memory:")
src.backup(db)
sql = open(sys.argv[1]).read()
db.isolation_level = None
probs = check(db, sql)
# transformation rows must point at an existing card and a battle_params group
for table, f1, f3 in (("passive_skills", "eff_value1", "eff_value3"), ("active_skills", "eff_val1", "eff_val3")):
    for rid, target, group in db.execute(f"select id,{f1},{f3} from {table} where efficacy_type=103 and id>=9000000"):
        if not db.execute("select 1 from cards where id=?", (target,)).fetchone(): probs.append(f"{table}#{rid} transforms into missing card {target}")
        if not db.execute("select 1 from battle_params where param_no=?", (group,)).fetchone(): probs.append(f"{table}#{rid} battle_params group {group} missing")
for sid, in db.execute("select distinct sub_target_type_set_id from leader_skills where id>=9000000 and sub_target_type_set_id>0"):
    if not db.execute("select 1 from sub_target_types where sub_target_type_set_id=?", (sid,)).fetchone(): probs.append(f"sub target set {sid} has no members")
print("problems:", len(probs))
for p in probs[:30]: print("  ", p)
sys.exit(1 if probs else 0)
