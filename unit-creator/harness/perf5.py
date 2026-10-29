import os, json, time, collections
os.environ.setdefault("FORGE_STATE","/home/claude/work/harness/state-builder")
from harness import Session
s=Session(viewport=(412,915)); pg=s.page
cdp=pg.context.new_cdp_session(pg); cdp.send("Emulation.setCPUThrottlingRate",{"rate":4})
pg.goto("https://forge.local/index.html")
while pg.evaluate("window.__forgeWorkspaceStartup") not in ("ready","failed"): pg.wait_for_timeout(50)
pg.wait_for_timeout(500)
cdp.send("Tracing.start",{"categories":"devtools.timeline,disabled-by-default-devtools.timeline","transferMode":"ReturnAsStream"})
pg.locator("[data-open]").first.click(); pg.wait_for_selector("#bld"); pg.wait_for_timeout(400)
done=[]
cdp.on("Tracing.tracingComplete", lambda e: done.append(e))
cdp.send("Tracing.end")
while not done: pg.wait_for_timeout(50)
h=done[0]["stream"]; data=""
while True:
    r=cdp.send("IO.read",{"handle":h}); data+=r["data"]
    if r.get("eof"): break
ev=json.loads(data); ev=ev["traceEvents"] if isinstance(ev,dict) else ev
c=collections.Counter()
for e in ev:
    if e.get("ph")=="X" and e.get("dur"): c[e["name"]]+=e["dur"]
print([(k,round(v/1000)) for k,v in c.most_common(18)])
s.close()
