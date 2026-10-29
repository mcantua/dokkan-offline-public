import os, json, time, collections
os.environ.setdefault("FORGE_STATE","/home/claude/work/harness/state-builder")
from harness import Session
s=Session(viewport=(412,915)); pg=s.page
cdp=pg.context.new_cdp_session(pg); cdp.send("Emulation.setCPUThrottlingRate",{"rate":4})
cdp.send("Profiler.enable"); cdp.send("Profiler.setSamplingInterval",{"interval":200}); cdp.send("Profiler.start")
pg.goto("https://forge.local/index.html")
while pg.evaluate("window.__forgeWorkspaceStartup") not in ("ready","failed"): pg.wait_for_timeout(50)
prof=cdp.send("Profiler.stop")["profile"]
nodes={n["id"]:n for n in prof["nodes"]}
parent={}
for n in prof["nodes"]:
    for c in n.get("children",[]): parent[c]=n["id"]
byurl=collections.Counter(); byfn=collections.Counter()
for sid,d in zip(prof["samples"],prof["timeDeltas"]):
    n=nodes[sid]; u=n["callFrame"]["url"].split("/")[-1] or n["callFrame"]["functionName"]
    byurl[u]+=d; byfn[n["callFrame"]["functionName"]+" "+u+":"+str(n["callFrame"]["lineNumber"])]+=d
print([(k,round(v/1000)) for k,v in byurl.most_common(20)])
print([(k,round(v/1000)) for k,v in byfn.most_common(20)])
s.close()
