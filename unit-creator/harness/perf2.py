import os, json, time, collections
os.environ.setdefault("FORGE_STATE","/home/claude/work/harness/state-builder")
from harness import Session
s=Session(viewport=(412,915)); pg=s.page
cdp=pg.context.new_cdp_session(pg); cdp.send("Emulation.setCPUThrottlingRate",{"rate":4})
calls=[]; orig=s.native.call
def wrapped(m,a):
    t=time.time()
    try: return orig(m,a)
    finally: calls.append((m, (a.get("table") or a.get("sql","")[:60] if isinstance(a,dict) else ""), round((time.time()-t)*1000), len(json.dumps(a))))
s.native.call=wrapped
pg.goto("https://forge.local/index.html")
while pg.evaluate("window.__forgeWorkspaceStartup") not in ("ready","failed"): pg.wait_for_timeout(50)
pg.wait_for_timeout(500)
def section(name, fn, profile=False):
    calls.clear()
    if profile: cdp.send("Profiler.enable"); cdp.send("Profiler.start")
    t=time.time(); fn(); el=round((time.time()-t)*1000)
    if profile:
        prof=cdp.send("Profiler.stop")["profile"]
        nodes={n["id"]:n for n in prof["nodes"]}; self_t=collections.Counter()
        dt=prof["timeDeltas"]
        for sid,d in zip(prof["samples"],dt):
            n=nodes[sid]["callFrame"]; self_t[(n["functionName"] or "(anon)")+" "+n["url"].split("/")[-1]+":"+str(n["lineNumber"])]+=d
        print("  top self:", [(k,round(v/1000)) for k,v in self_t.most_common(14)])
    c=collections.Counter(m for m,_,_,_ in calls)
    print(name, el, "ms; native", dict(c), "bytes sent", sum(x[3] for x in calls))
section("open", lambda: (pg.locator("[data-open]").first.click(), pg.wait_for_selector("#bld"), pg.wait_for_timeout(300)), True)
section("type", lambda: (pg.locator('[data-bind="card:name"]').press_sequentially("Speedy Name"), pg.wait_for_timeout(1500)), True)
for tab in ["passive","supers","links"]:
    section("tab "+tab, lambda: (pg.locator(f'[data-b="tab:{tab}"]').first.click(), pg.wait_for_timeout(300)), True)
print("localStorage draft bytes", pg.evaluate("(localStorage.getItem('forge-draft')||'').length"))
s.close()
