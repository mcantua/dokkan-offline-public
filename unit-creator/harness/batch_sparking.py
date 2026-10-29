import json, sys, random, sqlite3
from harness import Session
N = int(sys.argv[1]); seed = int(sys.argv[2])
sp = sqlite3.connect("file:/home/claude/work/apk/assets/sparking-reference.db?mode=ro", uri=True)
ref = sqlite3.connect("file:/home/claude/work/apk/assets/reference.db?mode=ro", uri=True)
refids = {r[0] for r in ref.execute("select id from cards")}
# prefer sparking-only cards (not in eclipse) — the interesting case
ids = [r[0] for r in sp.execute("select id from cards where id % 10 = 1 and hp_max > 300")]
only = [i for i in ids if i not in refids]
rng = random.Random(seed)
pick = sorted(set(rng.sample(only, min(N, len(only))) + rng.sample(ids, min(N // 3, len(ids)))))
print("sparking-only candidates:", len(only), "picked", len(pick))
s = Session().open(); s.page.wait_for_timeout(2500)
res = s.page.evaluate("""async (ids) => {
  const info = await Native.call('sparkingInfo'), einfo = await Native.call('info');
  const out = [];
  for (const id of ids) {
    const r = { id };
    try {
      const project = await Forge.loadTemplate(o => Native.call('querySparking', o), info.schema, id, Forge.SLOT_FLOOR + out.length * 1000);
      project.source.database = 'sparking';
      project.provenance = { sourceDatabase: 'Sparking', sourceCardId: id, sourceVersion: info.meta.latestVersion };
      project.sourceDependencies = await ForgeSparkingDependencies.collect(project, { sourceQuery: o => Native.call('querySparking', o), targetQuery: o => Native.call('query', o), sourceSchema: info.schema, targetSchema: einfo.schema });
      const v = Forge.validate({ ...project, sourceDependencies: undefined });
      r.errors = v.errors;
      const dv = ForgeSparkingDependencies.validate(project.sourceDependencies, einfo.schema).filter(i => i.severity === 'error').map(i => i.message);
      r.depErrors = [...(project.sourceDependencies.issues || []).filter(i => i.severity === 'error').map(i => i.message), ...dv];
      if (!v.errors.length) {
        const entries = Forge.exportEntries(project);
        r.sql = entries.find(e => e.path.endsWith('.sql')).text;
        for (const [t, rows] of Object.entries(Forge.materializeAll(project))) {
          const cols = new Set((einfo.schema[t] || []).map(c => c.name));
          const bad = rows.flatMap(row => Object.keys(row).filter(k => !cols.has(k)));
          if (bad.length) (r.schemaDiff = r.schemaDiff || []).push(t + ':' + [...new Set(bad)].join('/'));
        }
      }
    } catch (e) { r.throw = String(e && e.stack || e).slice(0, 600); }
    out.push(r);
  }
  return out;
}""", pick)
s.report("sparking-batch")
work = sqlite3.connect("/home/claude/work/harness/work.db")
def stmts(sql):
    buf = ""
    for line in sql.splitlines(keepends=True):
        if not buf and line.startswith("--"): continue
        buf += line
        if sqlite3.complete_statement(buf): yield buf; buf = ""
from collections import Counter
c = Counter()
for r in res:
    if "throw" in r: c["throw"] += 1; print("THROW", r["id"], r["throw"][:300]); continue
    if r["errors"]: c["invalid"] += 1; print("INVALID", r["id"], r["errors"][:2]); continue
    if r["depErrors"]: c["deperr"] += 1; print("DEPERR", r["id"], r["depErrors"][:2])
    if r.get("schemaDiff"): c["schemadiff"] += 1; print("SCHEMADIFF", r["id"], r["schemaDiff"][:3])
    work.execute("BEGIN")
    try:
        for st in stmts(r["sql"]): work.execute(st)
        c["sqlok"] += 1
    except Exception as e:
        c["sqlerr"] += 1; print("SQLERR", r["id"], e, st[:160])
    work.execute("ROLLBACK")
print(dict(c), "of", len(res))
