import os, json, time
os.environ.setdefault("FORGE_STATE","/home/claude/work/harness/state-builder")
from harness import Session
s=Session(viewport=(412,915)); pg=s.page
cdp=pg.context.new_cdp_session(pg); cdp.send("Emulation.setCPUThrottlingRate",{"rate":4}); cdp.send("Performance.enable")
def m():
    return {x["name"]:x["value"] for x in cdp.send("Performance.getMetrics")["metrics"]}
def section(name, fn):
    a=m(); t=time.time(); fn(); el=round((time.time()-t)*1000); b=m()
    d={k:round((b[k]-a[k])*1000) for k in ("ScriptDuration","RecalcStyleDuration","LayoutDuration","TaskDuration")}
    print(f"{name:12} {el:5}ms", d, "styleRecalcs", int(b["RecalcStyleCount"]-a["RecalcStyleCount"]), "layouts", int(b["LayoutCount"]-a["LayoutCount"]))
pg.goto("https://forge.local/index.html")
while pg.evaluate("window.__forgeWorkspaceStartup") not in ("ready","failed"): pg.wait_for_timeout(50)
print("DOM nodes home", pg.evaluate("document.getElementsByTagName('*').length"), "animations", pg.evaluate("document.getAnimations().map(a=>a.animationName+':'+(a.effect&&a.effect.target&&a.effect.target.className))"))
section("idle home 2s", lambda: pg.wait_for_timeout(2000))
section("open", lambda: (pg.locator("[data-open]").first.click(), pg.wait_for_selector("#bld"), pg.wait_for_timeout(300)))
print("DOM nodes builder", pg.evaluate("document.getElementsByTagName('*').length"), "stylesheets rules", pg.evaluate("[...document.styleSheets].reduce((n,s)=>{try{return n+s.cssRules.length}catch{return n}},0)"))
section("idle bld 2s", lambda: pg.wait_for_timeout(2000))
section("type", lambda: (pg.locator('[data-bind="card:name"]').press_sequentially("Speedy Name"), pg.wait_for_timeout(300)))
for tab in ["passive","supers","links","look","basics"]:
    section("tab "+tab, lambda: (pg.locator(f'[data-b="tab:{tab}"]').first.click(), pg.wait_for_timeout(300)))
section("scroll", lambda: [ (pg.mouse.wheel(0,400), pg.wait_for_timeout(50)) for _ in range(10)])
print("animations", pg.evaluate("document.getAnimations().map(a=>a.animationName)"))
s.close()
