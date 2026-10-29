import os, subprocess, json
os.environ["FORGE_STATE"] = "/home/claude/work/harness/state-ucopy2"; os.environ["FRESH"] = "1"
from harness import Session
SP = "/tmp/claude-0/sim/ucopy/"
s = Session(viewport=(412, 915)).open(); pg = s.page; w = lambda ms=600: pg.wait_for_timeout(ms)
errs = []; pg.on("pageerror", lambda e: errs.append(str(e)))
while pg.evaluate("window.__forgeWorkspaceStartup") != "ready": w(100)
pg.evaluate("createUnit(1014761)")
for _ in range(200):
    if pg.evaluate("state.view==='editor' && !!state.project && document.getElementById('busy').hidden"): break
    w(100)
w(1000)
print("forms before:", pg.evaluate("(state.project.formProjects||[]).length"), "links:", pg.evaluate("(state.project.transformLinks||[]).length"))
for mode in ["replace", "add"]:
    r = pg.evaluate(f"""async()=>{{const d=await ForgeUnitCopy.gameDonor({{id:1029981,name:'Majin Buu'}});const r=ForgeUnitCopy.build(d,new Set(['passive','supers','active']),{{passive:'{mode}',supers:'replace'}});
      const v=Forge.validate(r.work);let err='';try{{Forge.sql(r.work)}}catch(e){{err=e.message}}return {{errors:v.errors.slice(0,4),warnings:v.warnings.slice(0,3),err,forms:(r.work.formProjects||[]).length,links:(r.work.transformLinks||[]).length,notes:r.notes}}}}""")
    print(mode, json.dumps(r)[:600])
print("errors:", errs[:3])
