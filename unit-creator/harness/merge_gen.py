import os, json, sys
os.environ["FORGE_STATE"] = "/home/claude/work/harness/state-mergeall"; os.environ["FRESH"] = "0"
from harness import Session
s = Session(viewport=(412, 915)).open(); pg = s.page; w = lambda ms=600: pg.wait_for_timeout(ms)
while pg.evaluate("window.__forgeWorkspaceStartup") != "ready": w(100)
key = pg.evaluate("Native.call('projects').then(r=>r[0].key)")
pg.evaluate(f"openUnit({json.dumps(key)})"); w(3000)
out = pg.evaluate("""async()=>{const p=state.project,set=Forge.primaryPassive(p),rows=ForgePassiveMerge.setRows(p,set.id);
  const und=rows.filter(r=>!ForgeBuilder.decodePassive(r)&&![103].includes(Number(r.efficacy_type)));
  return {n:rows.length,undec:und.map(r=>r.efficacy_type+':'+ForgeGuide.effectSummary(r)).slice(0,60)}}""")
print(out["n"]); print("\n".join(out["undec"]))
