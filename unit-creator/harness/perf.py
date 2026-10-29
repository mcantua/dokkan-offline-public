import os, json, time
os.environ.setdefault("FORGE_STATE","/home/claude/work/harness/state-builder")
from harness import Session
RATE=float(os.environ.get("RATE","4"))
s=Session(viewport=(412,915)); pg=s.page
cdp=pg.context.new_cdp_session(pg); cdp.send("Emulation.setCPUThrottlingRate",{"rate":RATE})
reqs=[]; pg.on("request", lambda r: reqs.append(r.url.replace("https://forge.local/","")))
calls=[]; orig=s.native.call
def wrapped(m,a):
    t=time.time(); 
    try: return orig(m,a)
    finally: calls.append((m, round((time.time()-t)*1000)))
s.native.call=wrapped
pg.add_init_script("""window.__lt=[];new PerformanceObserver(l=>{for(const e of l.getEntries())window.__lt.push(Math.round(e.duration))}).observe({type:'longtask',buffered:true});""")
t0=time.time(); pg.goto("https://forge.local/index.html")
exec("while pg.evaluate(\"window.__forgeWorkspaceStartup\") not in (\"ready\",\"failed\"): pg.wait_for_timeout(50)")
print("state:", pg.evaluate("window.__forgeWorkspaceStartup"), s.errors[:3], s.native.log[-3:])
print("startup ms:", round((time.time()-t0)*1000))
print("native calls:", calls[:20])
print("long tasks:", pg.evaluate("window.__lt"))
print("requests:", len(reqs), [r for r in reqs if r.endswith('.json')])
nav=pg.evaluate("JSON.stringify(performance.getEntriesByType('navigation')[0].toJSON())"); n=json.loads(nav); print("DOMContentLoaded:", round(n["domContentLoadedEventEnd"]), "load:", round(n["loadEventEnd"]))
# open unit
pg.evaluate("window.__lt=[]")
t=time.time(); pg.locator("[data-open]").first.click(); pg.wait_for_selector("#bld"); print("open unit ms:", round((time.time()-t)*1000), "lt", pg.evaluate("window.__lt"))
# typing cost
pg.evaluate("window.__lt=[]")
t=time.time(); pg.locator('[data-bind="card:name"]').press_sequentially("Speedy Name", delay=0); pg.wait_for_timeout(50); print("type 11 chars ms:", round((time.time()-t)*1000), "lt", pg.evaluate("window.__lt"))
for tab in ["leader","passive","supers","links","look","save","basics"]:
    pg.evaluate("window.__lt=[]"); t=time.time(); pg.locator(f'[data-b="tab:{tab}"]').first.click(); pg.wait_for_timeout(30)
    print("tab", tab, round((time.time()-t)*1000), "lt", pg.evaluate("window.__lt"))
print("project bytes:", pg.evaluate("JSON.stringify(state.project).length"))
s.close()
