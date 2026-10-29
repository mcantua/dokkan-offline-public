"""Character finder (Create + pick dialogs) and Settings → Game data."""
import os
os.environ["FORGE_STATE"] = "/home/claude/work/harness/state-finder"; os.environ["FRESH"] = "1"
from harness import Session
SP = "/tmp/claude-0/sim/finder/"; os.makedirs(SP, exist_ok=True)
s = Session(viewport=(412, 915)).open(); pg = s.page; w = lambda ms=600: pg.wait_for_timeout(ms)
errs = []; pg.on("pageerror", lambda e: errs.append(str(e)))
def ok(name, cond, extra=""): print(("PASS " if cond else "FAIL ") + name, extra)
def count():
    for _ in range(300):
        t = pg.inner_text("#fd-create .fd-count") if pg.locator("#fd-create .fd-count").count() else ""
        if t and "…" not in t: return t
        w(100)
    return "timeout"
def n(t):
    import re
    m = re.match(r"([\d,]+)", t); return int(m.group(1).replace(",", "")) if m else 0
while pg.evaluate("window.__forgeWorkspaceStartup") != "ready": w(100)
import time; t0 = time.time()
pg.evaluate("navigate('source')"); w(500)
all_ = count(); print("   first index build: %.1fs" % (time.time() - t0))
ok("finder on Create", pg.locator("#fd-create .fd-tile").count() > 0 and not pg.locator(".source-controls").is_visible(), all_)
pg.screenshot(path=SP + "1-create.png")
pg.fill("#fd-create [data-fd-text]", "Vegito"); w(400); a = count()
first = pg.locator("#fd-create .fd-name").all_inner_texts()[:6]
ok("name search", n(a) > 0 and n(a) < n(all_) and all("vegito" in x.lower() for x in first), [a, first])
pg.locator('#fd-create [data-fd="rarity"][data-fv="5"]').click(); w(300); b = count()
ok("LR filter", 0 < n(b) <= n(a), b)
rar = pg.locator("#fd-create .fd-rar").all_inner_texts(); ok("all LR", all(r == "LR" for r in rar), set(rar))
pg.screenshot(path=SP + "2-vegito-lr.png")
pg.locator('#fd-create [data-fd="rarity"][data-fv=""]').click(); pg.locator('#fd-create [data-fd="type"][data-fv="1"]').click(); w(300); c = count()
els = set(pg.locator("#fd-create .fd-el").all_inner_texts()); ok("TEQ filter", els and all("TEQ" in e for e in els), [c, els])
pg.locator('#fd-create [data-fd="cls"][data-fv="1"]').click(); w(300); d = count()
els = set(pg.locator("#fd-create .fd-el").all_inner_texts()); ok("Super TEQ", n(d) <= n(c) and all(e.startswith("Super") or "Super" in e for e in els), [d, els])
pg.locator("#fd-create [data-fd-clear]").click(); w(300); e = count()
ok("clear", n(e) == n(all_), e)
pg.locator("#fd-create .fd-more summary").click(); w(200)
cat = pg.evaluate("(state.categories||[]).find(c=>/fusion/i.test(c.name))")
pg.fill("#fd-create [data-fd-cat]", cat["name"]); pg.dispatch_event("#fd-create [data-fd-cat]", "change"); w(300); f = count()
names = pg.locator("#fd-create .fd-name").all_inner_texts()[:8]
ok("category filter", 0 < n(f) < n(all_), [cat["name"], f, names])
pg.select_option('#fd-create [data-fd-sel="eza"]', "eza"); w(300); g = count()
ok("EZA filter", 0 < n(g) <= n(f), g)
pg.select_option('#fd-create [data-fd-sel="sort"]', "atk"); w(300); count()
pg.screenshot(path=SP + "3-more.png", full_page=True)
pg.locator("#fd-create [data-fd-clear]").click(); w(300); count()
pg.select_option('#fd-create [data-fd-sel="sort"]', "oldest") if pg.locator('#fd-create [data-fd-sel="sort"]').is_visible() else None
pg.fill("#fd-create [data-fd-text]", "Gogeta"); w(400); count()
pg.locator("#fd-create .fd-tile").first.click()
for _ in range(200):
    if pg.evaluate("state.view==='editor' && !!state.project && document.getElementById('busy').hidden"): break
    w(100)
ok("tile creates a unit", pg.evaluate("state.view") == "editor", pg.evaluate("state.project && Forge.card(state.project).name"))
w(1000)
# pick dialog through ForgeGuideUI.pickUnit
pg.evaluate("window.__picked=null; ForgeGuideUI.pickUnit ? ForgeGuideUI.pickUnit('Pick a test character', c=>{window.__picked=c.id}) : ForgeFinder.pick('Pick a test character', c=>{window.__picked=c.id})"); w(800)
ok("pick dialog uses finder", pg.locator("#dialog[open] #fd-root .fd-tile").count() > 0)
pg.fill("#dialog #fd-root [data-fd-text]", "Broly"); w(500)
pg.locator('#dialog [data-fd="rarity"][data-fv="4"]').click(); w(800)
pg.screenshot(path=SP + "4-pick.png")
pg.locator("#dialog #fd-root .fd-tile").first.click(); w(1200)
ok("pick returns card", bool(pg.evaluate("window.__picked")), pg.evaluate("window.__picked"))
# Settings → Game data
pg.evaluate("ForgeSettings.open()"); w(1500)
st = pg.inner_text("#set-game")
ok("settings game data", "Your characters are from" in st and pg.locator('#set-game [data-imp="update"]').count() == 1, st.replace("\n", " | "))
pg.screenshot(path=SP + "5-settings.png")
pg.locator('#set-game [data-imp="update"]').click(); w(2500)
ok("update error shown", pg.locator("#import-hub[open]").count() == 1 and "didn't work" in pg.inner_text("#import-hub #imp-status"), pg.inner_text("#import-hub #imp-status"))
print("errors:", errs[:3])
