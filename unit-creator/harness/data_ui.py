"""Import & update hub, update check, Delete my data."""
import os
os.environ["FORGE_STATE"] = "/home/claude/work/harness/state-dataui"; os.environ["FRESH"] = "1"
from harness import Session
SP = "/tmp/claude-0/sim/data/"; os.makedirs(SP, exist_ok=True)
s = Session(viewport=(412, 915)).open(); pg = s.page; w = lambda ms=600: pg.wait_for_timeout(ms)
errs = []; pg.on("pageerror", lambda e: errs.append(str(e)))
def ok(name, cond, extra=""): print(("PASS " if cond else "FAIL ") + name, extra)
while pg.evaluate("window.__forgeWorkspaceStartup") != "ready": w(100)
pg.evaluate("createUnit(1018721)")
for _ in range(200):
    if pg.evaluate("state.view==='editor' && !!state.project && document.getElementById('busy').hidden"): break
    w(100)
w(1500)
pg.evaluate("ForgeShell.go('import')"); w(1200)
ok("update screen", pg.locator("#import-hub[open] .imp-card").count() == 2, pg.inner_text("#imp-status"))
pg.screenshot(path=SP + "1-import.png")
pg.locator('#imp-actions [data-imp="update"]').click(); w(2500)
ok("failure explained", "didn't work" in pg.inner_text("#imp-status") and pg.locator('#imp-actions [data-imp="update"]').count() == 1, pg.inner_text("#imp-status"))
pg.screenshot(path=SP + "1b-import-error.png")
pg.evaluate("document.getElementById('import-hub').close()")
print("   projects before:", len(pg.evaluate("Native.call('projects')")))
pg.evaluate("ForgeSettings.open()"); w(600)
pg.locator("[data-set-wipe]").click(); w(500)
ok("wipe dialog", pg.locator("#wipe-go").is_disabled())
pg.screenshot(path=SP + "2-wipe.png")
pg.locator("#wipe-sure").check(); w(200)
ok("enabled after confirm", not pg.locator("#wipe-go").is_disabled())
pg.locator("#wipe-go").click(); w(3000)
while pg.evaluate("window.__forgeWorkspaceStartup") != "ready": w(100)
print("   projects after:", len(pg.evaluate("Native.call('projects')")), "| view:", pg.evaluate("state.view"))
print("errors:", errs[:3])
