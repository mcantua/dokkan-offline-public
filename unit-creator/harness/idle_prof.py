import os, collections
os.environ.setdefault("FORGE_STATE","/home/claude/work/harness/state-builder")
from harness import Session
s=Session(viewport=(412,915)); pg=s.page
cdp=pg.context.new_cdp_session(pg)
pg.goto("https://forge.local/index.html")
while pg.evaluate("window.__forgeWorkspaceStartup")!="ready": pg.wait_for_timeout(100)
pg.wait_for_timeout(3000)
cdp.send("Profiler.enable"); cdp.send("Profiler.start")
calls=[]; orig=s.native.call
s.native.call=lambda m,a: (calls.append(m), orig(m,a))[1]
pg.wait_for_timeout(4000)
prof=cdp.send("Profiler.stop")["profile"]
nodes={n["id"]:n for n in prof["nodes"]}; c=collections.Counter()
for sid,d in zip(prof["samples"],prof["timeDeltas"]):
    n=nodes[sid]["callFrame"]; c[(n["functionName"] or "(anon)")+" "+n["url"].split("/")[-1]+":"+str(n["lineNumber"])]+=d
print([(k,round(v/1000)) for k,v in c.most_common(12) if "idle" not in k])
print("native calls while idle:", collections.Counter(calls))
print("animations:", pg.evaluate("document.getAnimations().map(a=>a.animationName+'|'+(a.effect&&a.effect.target&&a.effect.target.className))"))
s.close()
