"""Whole-app speed check on a phone-speed CPU (RATE x slower). Prints one line per action."""
import os, json, time, sys, collections
os.environ["FORGE_STATE"] = os.environ.get("PSTATE", "/home/claude/work/harness/state-perfall"); os.environ.setdefault("FRESH", "1")
from harness import Session
RATE = float(os.environ.get("RATE", "4")); PROF = os.environ.get("PROF", "")
s = Session(viewport=(412, 915)); pg = s.page
cdp = pg.context.new_cdp_session(pg); cdp.send("Emulation.setCPUThrottlingRate", {"rate": RATE})
pg.add_init_script("""window.__lt=[];new PerformanceObserver(l=>{for(const e of l.getEntries())window.__lt.push(Math.round(e.duration))}).observe({type:'longtask',buffered:true});""")
errs = []; pg.on("pageerror", lambda e: errs.append(str(e)))
results = {}
def prof_start(name):
    if PROF == name: cdp.send("Profiler.enable"); cdp.send("Profiler.setSamplingInterval", {"interval": 200}); cdp.send("Profiler.start")
def prof_stop(name):
    if PROF != name: return
    prof = cdp.send("Profiler.stop")["profile"]; nodes = {n["id"]: n for n in prof["nodes"]}
    self_t = collections.Counter()
    for sid, d in zip(prof["samples"], prof["timeDeltas"]):
        n = nodes[sid]["callFrame"]; self_t[(n["functionName"] or "(anon)") + " " + n["url"].split("/")[-1] + ":" + str(n["lineNumber"] + 1)] += d
    print("  PROFILE", name, [(k, round(v / 1000)) for k, v in self_t.most_common(25)])
cdp.send("Performance.enable")
def metrics():
    m = {x["name"]: x["value"] for x in cdp.send("Performance.getMetrics")["metrics"]}
    return {k: m.get(k, 0) for k in ["ScriptDuration", "RecalcStyleDuration", "LayoutDuration", "TaskDuration", "Nodes"]}
def measure(name, fn, settle=None):
    pg.evaluate("window.__lt=[]"); prof_start(name); m0 = metrics(); t = time.time(); fn()
    if settle: settle()
    ms = round((time.time() - t) * 1000); m1 = metrics(); prof_stop(name); lt = pg.evaluate("window.__lt")
    d = {k: round((m1[k] - m0[k]) * (1000 if k != "Nodes" else 1)) for k in m0}
    results[name] = {"ms": ms, **d}; print(f"{name:24s} {ms:6d} ms  script {d['ScriptDuration']:5d} style {d['RecalcStyleDuration']:5d} layout {d['LayoutDuration']:5d} task {d['TaskDuration']:5d}  nodes {int(m1['Nodes'])}  long {len(lt)}/{max(lt) if lt else 0}"); sys.stdout.flush()
def until(js, limit=60000):
    t = time.time()
    while not pg.evaluate(js):
        if (time.time() - t) * 1000 > limit: print("   TIMEOUT", js); return
        pg.wait_for_timeout(30)
measure("startup", lambda: pg.goto("https://forge.local/index.html"), lambda: until("window.__forgeWorkspaceStartup==='ready'"))
if os.environ.get("ONLY")=="startup": s.close(); sys.exit()
pg.wait_for_timeout(1500)
measure("open Create (first)", lambda: pg.evaluate("navigate('source')"), lambda: until("!!document.querySelector('#fd-create .fd-tile')"))
measure("open Home", lambda: pg.evaluate("navigate('home')"), lambda: until("state.view==='home'"))
measure("open Create (again)", lambda: pg.evaluate("navigate('source')"), lambda: until("!!document.querySelector('#fd-create .fd-tile')"))
def typing():
    pg.locator("#fd-create [data-fd-text]").press_sequentially("Super Saiyan", delay=60)
measure("finder typing", typing, lambda: until("/character/.test(document.querySelector('#fd-create .fd-count').textContent)"))
measure("finder LR chip", lambda: pg.locator('#fd-create [data-fd="rarity"][data-fv="5"]').click(), lambda: until("/character/.test(document.querySelector('#fd-create .fd-count').textContent)"))
measure("create unit", lambda: pg.evaluate("createUnit(1018721)"), lambda: until("state.view==='editor'&&!!state.project&&document.getElementById('busy').hidden&&!!document.querySelector('#bld')"))
pg.wait_for_timeout(1500)
for tab in ["leader", "passive", "special", "supers", "transform", "links", "look", "save", "basics"]:
    measure("tab " + tab, lambda: pg.locator(f'[data-b="tab:{tab}"]').first.click(), lambda: pg.wait_for_timeout(50))
def type_name():
    pg.locator('[data-bind="card:name"]').first.press_sequentially(" Speedy", delay=60)
if pg.locator('[data-bind="card:name"]').count(): measure("type in name", type_name, lambda: pg.wait_for_timeout(100))
measure("open Settings", lambda: pg.evaluate("ForgeSettings.open()"), lambda: until("!!document.querySelector('.settings-sheet[open] #set-look')"))
pg.evaluate("document.querySelector('.settings-sheet').close()")
measure("open Animate", lambda: pg.evaluate("navigate('animations')"), lambda: until("!!document.getElementById('tl')"))
# idle CPU on the editor
pg.evaluate("navigate('editor')"); pg.wait_for_timeout(2500)
cdp.send("Profiler.enable"); cdp.send("Profiler.start"); pg.wait_for_timeout(4000)
prof = cdp.send("Profiler.stop")["profile"]
busy = sum(d for sid, d in zip(prof["samples"], prof["timeDeltas"]) if not any(x in ({n["id"]: n for n in prof["nodes"]}[sid]["callFrame"]["functionName"]) for x in ["(idle)", "(program)"]))
print(f"{'idle editor busy':28s} {round(busy/1000):6d} ms of 4000")
print("errors:", errs[:3])
json.dump(results, open(os.environ.get("POUT", "/tmp/claude-0/perf.json"), "w"))
s.close()
