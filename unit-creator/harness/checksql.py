import json, sqlite3, shutil, sys, os
req = json.load(open(sys.argv[1]))
entries = {e["path"]: e for e in req["entries"]}
print("entries:", [(p, len(e.get("text","")) if "text" in e else e.get("assetKey") or "cpk") for p,e in entries.items()])
meta = json.loads(entries["metadata.json"]["text"]); print("metadata:", meta)
sqlp = [p for p in entries if p.endswith(".sql")][0]
sql = entries[sqlp]["text"]
db = "/home/claude/work/harness/work.db"
if not os.path.exists(db): shutil.copy("/home/claude/work/apk/assets/reference.db", db)
c = sqlite3.connect(db)
c.execute("BEGIN")
inserted=[]
import re
try:
    stmts=[]; buf=""
    for line in sql.splitlines(keepends=True):
        if not buf and line.startswith("--"): continue
        buf+=line
        if sqlite3.complete_statement(buf): stmts.append(buf); buf=""
    assert not buf.strip(), "trailing incomplete SQL: "+buf[:200]
    for stmt in stmts:
        c.execute(stmt)
        t=re.match(r'\s*INSERT (?:OR REPLACE )?INTO "(\w+)"', stmt)
        if t: inserted.append((t.group(1), c.execute("select last_insert_rowid()").fetchone()[0]))
    print("SQL applied OK, statements:", len(inserted))
except Exception as e:
    print("SQL ERROR:", e, "\n", stmt[:500]); raise SystemExit
foreign = {"card_category_id":"card_categories","special_category_id":"special_categories","view_id":"special_views","special_view_id":"special_views","cut_in_card_id":"cards","card_id":"cards","passive_skill_set_id":"passive_skill_sets","passive_skill_id":"passive_skills","leader_skill_set_id":"leader_skill_sets","special_set_id":"special_sets","active_skill_set_id":"active_skill_sets","standby_skill_set_id":"standby_skill_sets","finish_skill_set_id":"finish_skill_sets","link_skill1_id":"link_skills","link_skill2_id":"link_skills","link_skill3_id":"link_skills","link_skill4_id":"link_skills","link_skill5_id":"link_skills","link_skill6_id":"link_skills","link_skill7_id":"link_skills","card_unique_info_id":"card_unique_infos","character_id":"characters","leader_skill_id":"leader_skills","finish_special_id":"finish_specials","dokkan_field_id":"dokkan_fields"}
from collections import Counter
print("tables:", dict(Counter(t for t,_ in inserted)))
problems=0
for t,rid in inserted:
    cur=c.execute(f'SELECT * FROM "{t}" WHERE rowid=?',(rid,)); cols=[d[0] for d in cur.description]; row=cur.fetchone()
    for col,v in zip(cols,row):
        if col in foreign and v not in (None,0) and foreign[col] in [r[0] for r in c.execute("select name from sqlite_master")]:
            if not c.execute(f'SELECT 1 FROM "{foreign[col]}" WHERE id=?',(v,)).fetchone():
                problems+=1; print(f"  dangling {t}.{col}={v} -> {foreign[col]}")
print("dangling refs:", problems)
c.execute("ROLLBACK")
