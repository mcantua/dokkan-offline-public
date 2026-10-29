"""Report any exported row whose (table, id) already exists in the game database (would overwrite it)."""
import sqlite3, sys, re, json, glob
db = sqlite3.connect("file:/home/claude/work/apk/assets/reference.db?mode=ro", uri=True)
pat = re.compile(r'INSERT (?:OR REPLACE )?INTO "(\w+)" \(([^)]*)\) VALUES \((-?\d+)')
def check(sql):
    hits = []
    for t, cols, i in pat.findall(sql):
        if not cols.startswith('"id"'): continue
        try:
            if db.execute(f'select 1 from "{t}" where id=?', (int(i),)).fetchone(): hits.append((t, int(i)))
        except sqlite3.OperationalError: pass
    return hits
files = sys.argv[1:]
total = 0
for f in files:
    if f.endswith(".json"):
        req = json.load(open(f)); sqls = [e["text"] for e in req.get("entries", []) if e["path"].endswith(".sql")]
    else: sqls = [open(f).read()]
    for s in sqls:
        h = check(s); total += len(h)
        if h: print(f, h[:10])
print("files:", len(files), "overwrites:", total)
