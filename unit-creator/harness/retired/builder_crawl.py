"""Exercise every builder control on several source cards, then export and verify the SQL."""
import os, sys, json, shutil, glob, subprocess
os.environ["FORGE_STATE"] = "/home/claude/work/harness/state-bcrawl"
shutil.rmtree(os.environ["FORGE_STATE"], ignore_errors=True)
from harness import Session
SOURCES = [int(x) for x in (sys.argv[1:] or ["1025731", "1002841", "1027251", "1003111", "1018721", "1020091"])]
s = Session(viewport=(1280, 900)).open(); pg = s.page
def wait(ms=250): pg.wait_for_timeout(ms)
toasts = []
pg.on("console", lambda m: toasts.append(m.text) if "TOAST-ERROR" in m.text else None)
def click_all(selector, limit=40):
    n = 0
    while n < limit:
        loc = pg.locator(selector)
        if loc.count() <= n: break
        try: loc.nth(n).click(timeout=3000); wait(200)
        except Exception as e: print("   click fail", selector, n, str(e)[:120])
        n += 1
def tab(k): pg.locator(f'[data-b="tab:{k}"]').first.click(); wait(400)
results = {}
for src in SOURCES:
    toasts.clear(); before = len(s.errors)
    pg.evaluate(f"createUnit({src})"); wait(2500)
    if not pg.locator("#bld").count(): print(src, "no builder"); continue
    for k in ["rarity:5", "class:2", "type:1", "class:1"]: pg.locator(f'[data-b="{k}"]').click(); wait(150)
    tab("leader"); wait(1200)
    if pg.locator('[data-b="leader-new"]').count(): pg.locator('[data-b="leader-new"]').click(); wait(300)
    for preset in ["all-170", "super-200", "extreme-200"]: pg.locator(f'[data-b="leader-preset:{preset}"]').click(); wait(300)
    pg.locator('[data-b="lg-add"]').click(); wait(300)
    for who in ["types", "classTypes", "super", "all", "categories"]:
        pg.locator('[data-lg="1"][data-lf="who"]').select_option(who); wait(300)
    pg.locator('[data-lg="1"][data-lf="ki"]').select_option("2"); wait(200)
    tab("passive")
    keys = pg.evaluate("ForgeBuilder.PASSIVE.map(e=>e.key)")
    for key in keys:
        pg.locator('[data-b="adding:on"]').first.click(); wait(150)
        pg.locator(f'[data-b="passive-add:{key}"]').click(); wait(250)
        ed = pg.locator(".bld-ability.open")
        for sel in ed.locator("select[data-bf]").all():
            opts = sel.locator("option").all()
            if len(opts) > 1: sel.select_option(index=len(opts) - 1); wait(120)
        nums = ed.locator("input[type=number][data-bf]")
        if nums.count(): nums.first.fill("7"); nums.first.dispatch_event("change"); wait(120)
        if ed.locator("[data-cadd]").count():
            ed.locator("[data-cadd]").select_option("hpBelow"); wait(250)
    # conditions of various kinds on the last effect
    for ck in ["turn", "allies", "supers", "slot"]:
        loc = pg.locator(".bld-ability.open [data-cadd]")
        if loc.count(): loc.select_option(ck); wait(250)
    loc = pg.locator(".bld-ability.open [data-cmode]")
    if loc.count(): loc.select_option("any"); wait(250)
    click_all('[data-b^="open:passive:"]', 12)
    tab("supers")
    pg.evaluate("document.querySelectorAll('#bld details').forEach(d=>d.open=true)"); wait(200)
    if pg.locator('[data-b="super-add:Hyper"]:visible').count(): pg.locator('[data-b="super-add:Hyper"]').click(); wait(400)
    if pg.locator('[data-b="super-add:Normal"]:visible').count(): pg.locator('[data-b="super-add:Normal"]').click(); wait(400)
    for key in pg.evaluate("ForgeBuilder.SA_EFFECTS.map(e=>e.key)"):
        sel = pg.locator('[data-bsel^="special-add:"]').first
        if sel.count(): sel.select_option(key); wait(200)
    for sel in pg.locator('[data-bsel^="power:"]').all(): sel.select_option("immense"); wait(200)
    tab("active")
    if pg.locator('[data-b="active-create"]').count(): pg.locator('[data-b="active-create"]').click(); wait(1200)
    for key in pg.evaluate("ForgeBuilder.ACTIVE_EFFECTS.map(e=>e.key)"):
        sel = pg.locator('[data-bsel^="activefx-add:"]').first
        if sel.count(): sel.select_option(key); wait(200)
    for sel in pg.locator('[data-bsel^="active-turn:"]').all(): sel.select_option("2"); wait(200)
    tab("transform")
    pg.locator('[data-b="tf-how:active"]').click(); wait(200)
    pg.evaluate("document.querySelectorAll('details').forEach(d=>d.open=true)"); wait(200)
    pg.locator('[data-b="tf-into:card"]').click(); wait(200)
    pg.locator('[data-b="tf-create"]').click(); wait(600)
    pg.fill("#fd-root [data-fd-text]", "Goku"); wait(1200)
    pg.locator("#fd-root [data-fd-pick]").first.click(); wait(2500)
    pg.locator('[data-b="tf-how:passive"]').click(); wait(200)
    pg.evaluate("document.querySelectorAll('details').forEach(d=>d.open=true)"); wait(200)
    pg.locator('[data-b="tf-into:custom"]').click(); wait(200)
    pg.locator('[data-b="tf-create"]').click(); wait(600)
    pg.fill("#fd-root [data-fd-text]", "Frieza"); wait(1200)
    pg.locator("#fd-root [data-fd-pick]").first.click(); wait(3500)
    for t in ["links", "look", "save"]: tab(t)
    card = pg.inner_text("#bld-card")
    n0 = len(s.native.exports)
    pg.locator('[data-export="eclp"]').first.click(); wait(6000)
    ok = None
    if len(s.native.exports) > n0:
        req = json.load(open(s.native.exports[-1]))
        sql = [e for e in req["entries"] if e["path"].endswith(".sql")][0]["text"]
        open("/tmp/claude-0/crawl.sql", "w").write(sql)
        r = subprocess.run(["python3", "apply_sql.py", "/tmp/claude-0/crawl.sql"], capture_output=True, text=True)
        ok = r.stdout.strip().splitlines()
    results[src] = {"errors": s.errors[before:], "toasts": list(toasts), "export": ok}
    print(src, "page errors:", len(s.errors) - before, "toasts:", sorted(set(toasts)), "export:", ok and ok[:4])
s.close()
