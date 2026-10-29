import json, sys, random, sqlite3, re
from harness import Session
N = int(sys.argv[1]) if len(sys.argv) > 1 else 60
seed = int(sys.argv[2]) if len(sys.argv) > 2 else 1
dbname = sys.argv[3] if len(sys.argv) > 3 else "eclipse"
ref = sqlite3.connect("file:/home/claude/work/apk/assets/reference.db?mode=ro", uri=True)
# sample playable-ish cards (ids ending 1, hp_max>300), weighted toward high rarity / complex kits
ids = [r[0] for r in ref.execute("select id from cards where id % 10 = 1 and hp_max > 300 and id < 9000000 order by id")]
rng = random.Random(seed)
complex_ids = [r[0] for r in ref.execute("select distinct card_id from card_active_skills union select distinct card_id from card_standby_skill_set_relations union select distinct card_id from card_finish_skill_set_relations")]
pick = sorted(set(rng.sample(ids, min(N, len(ids))) + rng.sample([i for i in complex_ids if i % 10 == 1], min(N//2, len(complex_ids)))))
s = Session().open()
s.page.wait_for_timeout(2500)
results = s.page.evaluate("""async (ids) => {
  const q = o => Native.call('query', o);
  const info = await Native.call('info');
  const out = [];
  for (const id of ids) {
    const r = { id };
    try {
      const p = await Forge.loadTemplate(q, info.schema, id, 1950000001);
      await ForgeGuide.allocateId(p, q, []); await Forge.hydrateNativeRecords(p, q, info.schema);
      r.target = p.targetId;
      const v = Forge.validate(p); r.errors = v.errors; r.warnings = v.warnings;
      if (!v.errors.length) {
        const entries = Forge.exportEntries(p);
        r.sql = entries.find(e => e.path.endsWith('.sql')).text;
        r.roster = Forge.playerRosterEligibility(p).issues;
        try {
          const audit = await ForgeExportAudit.check(p, { schema: info.schema, query: q, assetStatus: keys => Native.call('assetStatus', { keys }), readDecoration: async () => '' });
          r.audit = audit.errors;
        } catch (e) { r.auditThrow = String(e && e.stack || e); }
      }
    } catch (e) { r.throw = String(e && e.stack || e); }
    out.push(r);
  }
  return out;
}""", pick)
s.report("batch")
json.dump(results, open(f"batch-{seed}.json", "w"))
# apply SQL to a fresh in-memory copy each time (rollback)
work = sqlite3.connect("/home/claude/work/harness/work.db")
def stmts(sql):
    buf = ""
    for line in sql.splitlines(keepends=True):
        if not buf and line.startswith("--"): continue
        buf += line
        if sqlite3.complete_statement(buf): yield buf; buf = ""
summary = {"ok": 0, "throw": 0, "invalid": 0, "sqlerr": 0, "audit": 0}
for r in results:
    if "throw" in r: summary["throw"] += 1; print("THROW", r["id"], r["throw"][:400]); continue
    if r.get("errors"): summary["invalid"] += 1; print("INVALID", r["id"], r["errors"][:3]); continue
    if r.get("audit") or r.get("auditThrow"): summary["audit"] += 1; print("AUDIT", r["id"], (r.get("audit") or [])[:3], (r.get("auditThrow") or "")[:300])
    work.execute("BEGIN")
    try:
        for st in stmts(r["sql"]): work.execute(st)
        summary["ok"] += 1
    except Exception as e:
        summary["sqlerr"] += 1; print("SQLERR", r["id"], e, st[:200])
    work.execute("ROLLBACK")
print(summary, "of", len(results))
