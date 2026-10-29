"""One pass over every feature of the app (web build, real game DB). Each step is independent."""
import http.server, threading, functools, sys, traceback
from playwright.sync_api import sync_playwright
SITE = "/home/claude/work/web/site"; OUT = "/tmp/claude-0/eclipsetest/feat-"
class Q(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *a): pass
srv = http.server.ThreadingHTTPServer(("127.0.0.1", 0), functools.partial(Q, directory=SITE)); threading.Thread(target=srv.serve_forever, daemon=True).start()
res = []
def ok(n, c, x=""):
    res.append((n, bool(c))); print(("PASS " if c else "FAIL ") + n, "" if c else str(x)[:300]); sys.stdout.flush()
with sync_playwright() as p:
    b = p.chromium.launch(); ctx = b.new_context(viewport={"width": 412, "height": 915}, accept_downloads=True); pg = ctx.new_page()
    w = lambda ms=700: pg.wait_for_timeout(ms)
    errs = []; pg.on("pageerror", lambda e: errs.append(str(e)))
    pg.goto(f"http://127.0.0.1:{srv.server_port}/")
    for _ in range(300):
        if pg.evaluate("window.__forgeWorkspaceStartup") in ("ready", "failed"): break
        w(100)
    ok("app starts", pg.evaluate("window.__forgeWorkspaceStartup") == "ready")
    def step(name, fn):
        n0 = len(errs)
        try:
            r = fn(); ok(name, r is not False and len(errs) == n0, errs[n0:] if len(errs) > n0 else r)
        except Exception as e:
            ok(name, False, repr(e)[:300])
    # ---- main screens
    for view in ["home", "library", "source", "animations", "combat", "movies", "assets", "ai"]:
        step("screen: " + view, lambda v=view: (pg.evaluate(f"navigate('{v}')"), w(1500), pg.evaluate("document.querySelector('main').innerText.length") > 20)[-1])
    # ---- settings + help + tour
    step("settings opens (game data, offline, clean-up)", lambda: (pg.evaluate("ForgeShell && ForgeShell.go ? ForgeShell.go('settings') : document.querySelector('[data-shell=settings],.shell-settings,[aria-label*=Settings]')?.click()"), w(1500), pg.locator("[data-offline-cleanup]").count() > 0 or pg.locator("text=Clean up old files now").count() > 0)[-1])
    pg.keyboard.press("Escape"); w(300)
    step("welcome tour opens", lambda: (pg.evaluate("ForgeShell.tour()"), w(800), pg.evaluate("!!document.getElementById('shell-tour')?.open"))[-1])
    pg.evaluate("document.getElementById('shell-tour')?.close()")
    step("offline downloads dialog", lambda: (pg.evaluate("ForgeOffline.open()"), w(1500), pg.locator('[data-pack="everything"]').count() == 1 and pg.locator('[name="offline-net"]').count() == 2)[-1])
    pg.evaluate("document.getElementById('dialog').close()")
    # ---- quick create a unit
    def create():
        pg.evaluate("ForgeQuickCreate.open()"); w(600)
        pg.fill("#qc-finder [data-fd-text]", "goku"); w(4000)
        pg.locator("#qc-finder [data-fd-pick]").first.click(); w(1500); pg.click("#qc-next"); w(300)
        pg.click('[data-qc-rarity="LR"]'); w(300); pg.click("#qc-create")
        for _ in range(300):
            if pg.evaluate("state.view==='editor' && !!state.project && document.getElementById('busy').hidden"): break
            w(100)
        w(1500)
        return pg.evaluate("state.view") == "editor"
    step("quick create a unit", create)
    tab = lambda k: (pg.evaluate(f"ForgeBuilderUI.tab('{k}')"), w(1200))
    # ---- every builder tab renders
    for k in ["basics", "leader", "passive", "intro", "supers", "active", "special", "transform", "links", "look", "save"]:
        step("tab: " + k, lambda k=k: (tab(k), pg.evaluate("document.querySelector('main').innerText.length") > 50)[-1])
    # ---- leader
    def leader():
        tab("leader"); name1 = pg.evaluate("state.project.tables.leader_skill_sets[0]?.name || ''")
        pg.locator('[data-b="leader-preset:super-200"]').click(); w(800)
        n = pg.evaluate("(state.project.tables.leader_skills||[]).length")
        pg.locator('[data-b="lg-add"]').first.click(); w(600)
        return n > 0 and "200" in pg.evaluate("Forge.card(state.project) && (state.project.tables.leader_skill_sets||[]).map(s=>s.description).join(' ')")
    step("leader: quick start + add tier + description", leader)
    # ---- passive families: add every family once
    def passive():
        tab("passive")
        fams = pg.evaluate("ForgePassiveFamilies.FAMILIES.map(f=>f.id)")
        bad = []
        for f in fams:
            try: pg.evaluate(f"ForgePassiveFamilies.add(ForgePassiveFamilies.FAMILIES.find(x=>x.id==='{f}'))"); w(250)
            except Exception as e: bad.append(f)
        desc = pg.evaluate("Forge.primaryPassive(state.project)?.itemized_description || ''")
        return (not bad and len(fams) >= 20 and len(desc) > 100) or {"bad": bad, "n": len(fams)}
    step("passive: add every ability family", passive)
    step("passive: name condition picker", lambda: (pg.evaluate("ForgeNameSets.load()"), w(2500), len(pg.evaluate("ForgeNameSets.list()")) > 50 and len(pg.evaluate("ForgeNameSets.matches('Goku')")) > 10)[-1])
    # ---- intro
    def intro():
        tab("intro"); pg.locator('[data-intro="add"]').first.click(); w(1200)
        sc = pg.locator("[data-intro-scene]")
        if sc.count(): sc.first.click(); w(1200)
        return pg.evaluate("(state.project.tables.passive_skills||[]).some(r=>r.passive_skill_effect_id)")
    step("intro: add an entrance scene", intro)
    # ---- special skills
    for act in ["counter-add", "revive-add", "domain-add", "standby-add"]:
        def sp(a=act):
            tab("special"); pg.evaluate(f"ForgeSpecial.action('{a}')"); w(1500)
            sv = pg.locator("#sp-save")
            if sv.count(): sv.click(); w(1200)
            return True
        step("special: " + act, sp)
    # ---- supers: add an effect + animation choice exists
    def supers():
        tab("supers"); sel = pg.locator('[data-bsel^="sa-add:"], select[data-bsel*="fx-add"]').first
        if sel.count():
            opt = sel.locator("option").nth(1).get_attribute("value"); sel.select_option(opt); w(900)
        return pg.locator(".bld-super [data-animchoice]").count() > 0
    step("supers: effect + animation choice", supers)
    # ---- active
    def active():
        tab("active")
        if pg.locator('[data-b="active-create"]').count(): pg.locator('[data-b="active-create"]').click(); w(1500)
        return pg.evaluate("(state.project.tables.active_skill_sets||[]).length") > 0
    step("active skill: create", active)
    step("look: animation choices", lambda: (tab("look"), pg.locator("[data-animchoice]").count() >= 2)[-1])
    step("links & categories render", lambda: (tab("links"), pg.locator("main select, main input").count() > 3)[-1])
    def save():
        tab("save")
        v = pg.evaluate("Forge.validate(state.project)")
        return (len(v.get("errors", [])) == 0) or v.get("errors")
    step("save: unit validates for export", save)
    # ---- library sparking + offline/new data/storage questions (no errors)
    step("library: sparking list", lambda: (pg.evaluate("navigate('library')"), w(1500), True)[-1])
    ok("no page errors overall", not errs, errs[:3])
    pg.screenshot(path=OUT + "end.png")
    b.close()
print("SUMMARY", sum(1 for _, c in res if c), "passed,", sum(1 for _, c in res if not c), "failed")
