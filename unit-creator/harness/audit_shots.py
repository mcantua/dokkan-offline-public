import os
os.environ["FORGE_STATE"] = "/home/claude/work/harness/state-audit"; os.environ["FRESH"] = "1"
from harness import Session
OUT = "/tmp/claude-0/audit/"
s = Session(viewport=(412, 915)).open(); pg = s.page; w = lambda ms=600: pg.wait_for_timeout(ms)
errs = []; pg.on("pageerror", lambda e: errs.append(str(e)))
while pg.evaluate("window.__forgeWorkspaceStartup") != "ready": w(100)
w(800)
def close_all():
    pg.evaluate("document.querySelectorAll('dialog[open]').forEach(d=>d.close())"); w(200)
def shot(name, full=True):
    pg.evaluate("document.getElementById('toast')?.classList.remove('show')")
    pg.screenshot(path=OUT + name + ".png", full_page=full)
    print("shot", name, pg.evaluate("document.documentElement.scrollHeight"))
shot("01-home")
for v in ["source", "library", "combat", "movies", "assets", "ai"]:
    try:
        pg.evaluate(f"ForgeShell.go('{v}')"); w(1800); shot("02-" + v)
    except Exception as e: print("fail", v, e)
pg.evaluate("ForgeShell.go('home')"); w(800)
pg.locator(".shell-more-button").click(); w(500); shot("03-more", False); close_all()
for g in ["quick", "templates", "offline", "recover", "tour"]:
    try:
        pg.evaluate(f"ForgeShell.go('{g}')"); w(1500); shot("04-" + g, False); close_all()
    except Exception as e: print("fail", g, e)
pg.evaluate("createUnit(1018721)")
for _ in range(100):
    if pg.evaluate("state.view==='editor' && document.getElementById('busy').hidden"): break
    w(200)
w(800); shot("05-editor-0")
steps = pg.evaluate("[...document.querySelectorAll('.stepper button, .simple-steps button, [data-step]')].filter(b=>b.offsetParent).map(b=>b.innerText.replace(/\\n/g,' ').slice(0,30))")
print("steps:", steps)
n = pg.evaluate("[...document.querySelectorAll('.stepper button, .simple-steps button')].filter(b=>b.offsetParent).length")
for i in range(1, min(n, 10)):
    try:
        pg.evaluate(f"[...document.querySelectorAll('.stepper button, .simple-steps button')].filter(b=>b.offsetParent)[{i}].click()"); w(1200)
        shot(f"05-editor-{i}")
    except Exception as e: print("fail step", i, e)
print("errors:", errs[:5])
