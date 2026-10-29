import os, sqlite3, random
os.environ["FORGE_STATE"]="/home/claude/work/harness/state-spg"
from harness import Session
sp = sqlite3.connect("file:/home/claude/work/apk/assets/sparking-reference.db?mode=ro", uri=True)
ids = [r[0] for r in sp.execute("select id from cards where id % 10 = 1 and hp_max > 300")]
pick = random.Random(3).sample(ids, 8)
s = Session().open(); s.page.wait_for_timeout(2500)
res = s.page.evaluate("""async (ids) => {
  const info = await Native.call('sparkingInfo'), einfo = await Native.call('info'), out = [];
  for (const id of ids) {
    const r = { id };
    try {
      const project = await Forge.loadTemplate(o => Native.call('querySparking', o), info.schema, id, Forge.SLOT_FLOOR);
      project.source.database = 'sparking';
      await ForgeGuide.allocateId(project, o => Native.call('query', o), []);
      project.sourceDependencies = await ForgeSparkingDependencies.collect(project, { sourceQuery: o => Native.call('querySparking', o), targetQuery: o => Native.call('query', o), sourceSchema: info.schema, targetSchema: einfo.schema });
      const entries = Forge.exportEntries(project);
      const sql = entries.find(e => e.path.endsWith('.sql')).text;
      try { await ForgeIdGuard.check('export', { kind: 'sql', text: sql }); r.guard = 'ok'; } catch (e) { r.guard = e.message; }
    } catch (e) { r.err = e.message; }
    out.push(r);
  }
  return out;
}""", pick)
for r in res: print(r)
s.close()
