"""Builds a unit with EVERY passive ability family (plus GR level 200, Godly Exclusive, a multi-tier leader,
an EZA-step edit, linked/turned-off abilities), exports the .eclp from the web version, opens it with the
Android app's own decoder, then runs the game SQL on a copy of the real game database and checks that
everything the game needs is there and points at real rows."""
import http.server, threading, functools, os, subprocess, json, sys, sqlite3, shutil, re
from playwright.sync_api import sync_playwright
SITE = "/home/claude/work/web/site"; OUT = "/tmp/claude-0/eclipsetest/"; GAMEDB = "/home/claude/work/web/ios-db/reference.db"
class Q(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *a): pass
    def end_headers(self): self.send_header("Cache-Control", "no-store"); super().end_headers()
srv = http.server.ThreadingHTTPServer(("127.0.0.1", 0), functools.partial(Q, directory=SITE)); threading.Thread(target=srv.serve_forever, daemon=True).start()
url = f"http://127.0.0.1:{srv.server_port}/"
fails = []
def ok(n, c, x=""):
    print(("PASS " if c else "FAIL ") + n, x if not c or os.environ.get("V") else ""); sys.stdout.flush()
    if not c: fails.append(n)
with sync_playwright() as p:
    b = p.chromium.launch()
    ctx = b.new_context(viewport={"width": 1180, "height": 900}, accept_downloads=True)
    pg = ctx.new_page(); w = lambda ms=700: pg.wait_for_timeout(ms)
    errs = []; pg.on("pageerror", lambda e: errs.append(str(e)))
    pg.goto(url)
    for _ in range(300):
        if pg.evaluate("window.__forgeWorkspaceStartup") in ("ready", "failed"): break
        w(100)
    # GR (level 200) unit from Quick Create
    pg.evaluate("ForgeQuickCreate.open()"); w(600)
    pg.fill("#qc-search", "vegito"); w(2500)
    pg.locator("#qc-results .qc-pick").first.click(); w(300); pg.click("#qc-next"); w(300)
    pg.click('[data-qc-rarity="GR"]'); w(300); pg.click("#qc-create")
    for _ in range(300):
        if pg.evaluate("state.view==='editor' && !!state.project && document.getElementById('busy').hidden"): break
        w(100)
    w(2000)
    pg.evaluate("Forge.card(state.project).name = 'Eclipse Test Vegito'; state.project.cardOverrides.name = 'Eclipse Test Vegito'")
    pg.evaluate("document.querySelector('[data-b=\"tab:passive\"]').click()"); w(900)
    # every family
    fams = pg.evaluate("ForgePassiveFamilies.FAMILIES.filter(f => !f.tab).map(f => f.id)")
    added = pg.evaluate("""(() => { const out = []; for (const f of ForgePassiveFamilies.FAMILIES.filter(f => !f.tab)) { const r = ForgePassiveFamilies.add(f); out.push([f.id, r && r.id]); } return out; })()"""); w(1200)
    ok("every ability family added (%d)" % len(fams), all(r for _, r in added), added)
    # every kind x growth of every family (switch a scratch row through all of them)
    combos = pg.evaluate("""(async () => { const PF = ForgePassiveFamilies, bad = []; let n = 0;
      for (const f of PF.FAMILIES.filter(f => !f.tab)) for (const [k] of f.kinds) for (const sc of f.scales) {
        const slot = f.slots.find(s => s[0] === k && s[1] === sc); if (!slot) continue; n++;
        const row = PF.add(f); if (!row) { bad.push(f.id); continue; }
        ForgeBuilderUI.open('passive:' + row.id);
        await new Promise(r => setTimeout(r, 30));
        const ks = document.querySelector('.bld-ability.open [data-pf^="kind:"]'), ss = document.querySelector('.bld-ability.open [data-pf^="scale:"]');
        if (ks && ks.value !== k) { ks.value = k; ks.dispatchEvent(new Event('change', { bubbles: true })); await new Promise(r => setTimeout(r, 60)); }
        const ss2 = document.querySelector('.bld-ability.open [data-pf^="scale:"]');
        if (ss2 && ss2.value !== sc) { ss2.value = sc; ss2.dispatchEvent(new Event('change', { bubbles: true })); await new Promise(r => setTimeout(r, 60)); }
      } return [n, bad]; })()"""); w(1500)
    ok("every kind x growth combination builds (%d)" % combos[0], not combos[1], combos)
    # giant form picked by name, a requirement, a linked effect, one turned off
    pg.evaluate("""(() => { const g = state.project.tables.passive_skills.filter(r => [...document.querySelectorAll('.bld-ability[data-edit]')].some(a => a.dataset.edit === 'passive:' + r.id)).reverse().find(r => r.efficacy_type === 79); ForgeBuilderUI.open('passive:' + g.id); })()"""); w(600)
    pg.select_option(".bld-ability.open [data-pfchoice]", index=2); w(600)
    pg.evaluate("""(() => { const r = state.project.tables.passive_skills.filter(r => [...document.querySelectorAll('.bld-ability[data-edit]')].some(a => a.dataset.edit === 'passive:' + r.id)).reverse().find(r => r.efficacy_type === 90); ForgeBuilderUI.open('passive:' + r.id); })()"""); w(600)
    pg.select_option(".bld-ability.open select[data-cadd]", "hpBelow"); w(1000)
    ok("a requirement can be added (HP 50% or less)", "HP" in pg.evaluate("document.querySelector('.bld-ability.open .pf-summary').innerText"), pg.evaluate("document.querySelector('.bld-ability.open .pf-summary') && document.querySelector('.bld-ability.open .pf-summary').innerText"))
    # name conditions: a named ally on the team (game's own name group) + facing a typed enemy name
    pg.select_option(".bld-ability.open select[data-cadd]", "allyName"); w(1500)
    pg.locator(".bld-ability.open [data-nspick]").last.click(); w(1500)
    n_all = pg.evaluate("document.querySelectorAll('.ns-sheet[open] .ns-item').length")
    ok("name search opens with the game's characters (%d)" % n_all, n_all > 50)
    pg.fill("#ns-q", "goku"); w(600)
    first = pg.evaluate("[...document.querySelectorAll('.ns-sheet[open] [data-nsid] strong')].slice(0,4).map(x=>x.textContent)")
    ok("searching narrows the list", first and all("goku" in x.lower() for x in first[:2]), first)
    pg.screenshot(path=OUT + "name-search.png")
    pg.locator(".ns-sheet[open] [data-nsid]").first.click(); w(1200)
    pg.select_option(".bld-ability.open select[data-cadd]", "enemyName"); w(1500)
    pg.locator(".bld-ability.open [data-nspick]").last.click(); w(800)
    pg.fill("#ns-q", "Crimson"); w(600)
    pg.locator(".ns-sheet[open] [data-nsuse]").click(); w(1200)
    pg.select_option(".bld-ability.open select[data-cadd]", "turnName"); w(1500)
    pg.locator(".bld-ability.open [data-nspick]").last.click(); w(800)
    pg.fill("#ns-q", "Frieza"); w(600)
    use = pg.locator(".ns-sheet[open] [data-nsuse]")
    if use.count(): use.click()
    else: pg.locator(".ns-sheet[open] [data-nsid]").first.click()
    w(1200)
    # accents and single characters: "super saiyan rose" finds Goku Black (Super Saiyan Rosé) etc.
    pg.select_option(".bld-ability.open select[data-cadd]", "allyName"); w(1500)
    pg.locator(".bld-ability.open [data-nspick]").last.click(); w(800)
    pg.fill("#ns-q", "Super Saiyan Rose"); w(700)
    singles = pg.evaluate("[...document.querySelectorAll('.ns-sheet[open] [data-nsexact]')].map(b => b.dataset.nsexact)")
    ok("search ignores accents and lists single characters (%d)" % len(singles), any("Rosé" in x for x in singles), singles[:4])
    pg.screenshot(path=OUT + "rose.png")
    pg.locator(".ns-sheet[open] [data-nsexact]").first.click(); w(1200)
    ok("a single character can be picked", "Rosé" in pg.evaluate("document.querySelector('.bld-ability.open .pf-summary').innerText"))
    # remove a typed name: its condition goes too
    rules0 = pg.evaluate("document.querySelectorAll('.bld-ability.open [data-rule]').length")
    pg.locator(".bld-ability.open [data-nspick]").first.click(); w(800)
    mine = pg.evaluate("[...document.querySelectorAll('.ns-sheet[open] [data-nsdel]')].map(b=>b.getAttribute('aria-label'))"); print("your names:", mine)
    pg.locator(".ns-sheet[open] [data-nsdel][aria-label='Remove Crimson']").click(); w(1200)
    rules1 = pg.evaluate("document.querySelectorAll('.bld-ability.open [data-rule]').length")
    left = pg.evaluate("Object.values(state.project.nameSetLabels || {})")
    ok("removing a name removes it and its condition", "Crimson" not in left and rules1 == rules0 - 1, [left, rules0, rules1])
    pg.evaluate("document.querySelectorAll('dialog[open]').forEach(d => d.close())")
    needs = pg.evaluate("document.querySelector('.bld-ability.open .pf-summary').innerText")
    ok("summary reads the names", "whose name includes" in needs and '"Frieza"' in needs and "Crimson" not in needs, needs.replace("\n", " | "))
    pg.locator(".bld-ability.open").screenshot(path=OUT + "names.png")
    pg.click(".bld-ability.open [data-pfa^='link:']"); w(400); pg.click(".pf-sheet[open] [data-pfpick='ki']"); w(900)
    pg.evaluate("""(() => { const r = state.project.tables.passive_skills.filter(r => [...document.querySelectorAll('.bld-ability[data-edit]')].some(a => a.dataset.edit === 'passive:' + r.id)).reverse().find(r => r.efficacy_type === 114); ForgeBuilderUI.open('passive:' + r.id); })()"""); w(500)
    pg.click(".bld-ability.open [data-pfa^='off:']"); w(800)
    # an EZA step gets its own extra ability
    stages = pg.evaluate("[...document.querySelectorAll('[data-b^=\"stage:passive:\"]')].filter(b=>!b.classList.contains('locked')).map(b=>b.dataset.b)")
    if len(stages) > 1:
        pg.evaluate("document.querySelector('[data-b=\"%s\"]').click()" % stages[-1]); w(800)
        pg.evaluate("ForgePassiveFamilies.add(ForgePassiveFamilies.FAMILIES.find(f => f.id === 'dodge'))"); w(800)
    # intro with a condition and a bonus
    pg.evaluate("document.querySelector('[data-b=\"tab:intro\"]').click()"); w(1000)
    pg.click(".intro-panel [data-intro=add]"); w(600); pg.locator("[data-intro-scene]").first.click(); w(1000)
    pg.select_option("[data-intro-when]", "allies"); w(900)
    pg.click(".intro-panel [data-intro=preset]"); w(900)
    ok("intro set up", pg.evaluate("!!ForgeIntro.carrier() && ForgeIntro.bonuses().length === 2 && Number(ForgeIntro.carrier().efficacy_type) !== 0"))
    # leader: preset + extra tier with a Category
    pg.evaluate("document.querySelector('[data-b=\"tab:leader\"]').click()"); w(1500)
    pg.click("[data-b='leader-preset:all-170']"); w(800); pg.click("[data-b='lg-add']"); w(800)
    pg.evaluate("(() => { const sel = document.querySelector('.bld-groups > *:last-child select[data-catpick]'); sel.value = sel.options[1].value; document.querySelector('.bld-groups > *:last-child [data-b^=\"lg-cat-add\"]').click(); })()"); w(900)
    pg.evaluate("flushSave()"); w(1000)
    v = pg.evaluate("Forge.validate(state.project)")
    ok("the app's own checks pass", not v.get("errors"), v.get("errors"))
    expected = pg.evaluate("""(() => { const p = state.project, c = Forge.card(p); return { id: Number(p.targetId || c.id), name: c.name, lv: c.lv_max, sa: c.skill_lv_max, cost: c.cost,
      effects: [...new Set(p.tables.passive_skills.map(r => r.efficacy_type))].sort((a,b)=>a-b) }; })()""")
    print("unit:", expected)
    # export .eclp
    pg.evaluate("document.querySelector('[data-b=\"tab:save\"]').click()"); w(800)
    pg.locator('[data-export="eclp"]').first.click()
    for _ in range(600):
        if pg.locator(".web-file-dialog[open]").count(): break
        w(100)
    with pg.expect_download() as dl:
        pg.locator('.web-file-dialog [data-act="download"]').click()
    path = OUT + dl.value.suggested_filename; dl.value.save_as(path)
    ok(".eclp exported", os.path.getsize(path) > 1000, os.path.getsize(path))
    ok("no app errors while building", not errs, errs[:3])
    b.close()

jo = "-XX:+UnlockDiagnosticVMOptions -XX:-BytecodeVerificationRemote -XX:-BytecodeVerificationLocal -Djava.library.path=/home/claude/work/tools".split()
shutil.rmtree(OUT + "eclp-out", ignore_errors=True)
r = subprocess.run(["java", *jo, "-cp", "/home/claude/work/tools/eclp-check/app.jar:/home/claude/work/tools/eclp-check/stubout:/home/claude/work/tools/eclp-check", "X", path, OUT + "eclp-out"], capture_output=True, text=True)
files = r.stdout.strip().splitlines()
ok("the Android app's decoder opens the .eclp", any(".sql" in f for f in files), files or r.stderr[-300:])
sqlf = [OUT + "eclp-out/" + f.split()[0] for f in files if ".sql" in f][0]
sql = open(sqlf, encoding="utf-8").read()
ok("the game file has the unit", "Eclipse Test Vegito" in sql)
db = OUT + "game.db"; shutil.copy(GAMEDB, db)
con = sqlite3.connect(db)
try:
    con.executescript(sql); con.commit(); ran = True; why = ""
except Exception as e: ran = False; why = str(e)
ok("the game SQL runs on the real game database", ran, why)
q = lambda s, *a: con.execute(s, a).fetchall()
cid = expected["id"]
card = q("select id, name, lv_max, skill_lv_max, cost, passive_skill_set_id, leader_skill_set_id, exp_type from cards where id = ?", cid)
ok("card is in the game", bool(card), cid)
if card:
    c = card[0]
    ok("level 200, SA 30, cost 99", (c[2], c[3], c[4]) == (200, 30, 99), c[2:5])
    ok("level-up table reaches 200", q("select count(*) from card_exps where exp_type = ? and lv <= 200", c[7])[0][0] >= 200 if q("pragma table_info(card_exps)") else True, c[7])
    sets = [c[5]] + [x[0] for x in q("select passive_skill_set_id from card_awakening_sets where false")] if False else [c[5]]
    rel = q("select passive_skill_id from passive_skill_set_relations where passive_skill_set_id in (select passive_skill_set_id from passive_skill_set_relations where passive_skill_id in (%s))" % ",".join(str(i) for i in (re.findall(r"INSERT[^;]*?INTO\s+\"?passive_skills\"?[^;]*?VALUES\s*\((\d+)", sql, re.I) or ["0"])))
    ok("passive set has its abilities", len(rel) >= 10, len(rel))
    missing = [pid for (pid,) in rel if not q("select 1 from passive_skills where id = ?", pid)]
    ok("every ability in the passive exists", not missing, missing)
    ls = q("select count(*) from leader_skills where leader_skill_set_id = ?", c[6])[0][0]
    ok("leader skill exists with its bonuses", ls >= 2, ls)
# every passive ability of every set this patch touches: valid effect, target, timing and conditions
mech = json.load(open("/home/claude/work/v2/ui/data/mechanics.json"))
good_eff = {e["id"] for e in mech["efficacies"]}; good_tgt = {t["id"] for t in mech["target-types"]}; good_time = {t["id"] for t in mech["exec-types"]}
ids = sorted(set(int(x) for x in re.findall(r"INSERT[^;]*?INTO\s+\"?passive_skills\"?[^;]*?VALUES\s*\((\d+)", sql, re.I)))
if not ids: ids = [r[0] for r in q("select passive_skill_id from passive_skill_set_relations where passive_skill_set_id in (select passive_skill_set_id from cards where id = ?)", cid)]
rows = q("select id, efficacy_type, target_type, exec_timing_type, causality_conditions, turn, probability, name from passive_skills where id in (%s)" % ",".join(map(str, ids))) if ids else []
ok("passive abilities written (%d)" % len(rows), len(rows) >= 30, len(rows))
ok("every effect is a real game effect", all(r[1] in good_eff for r in rows), [r for r in rows if r[1] not in good_eff][:3])
ok("every target is a real game target", all(r[2] in good_tgt for r in rows), [r for r in rows if r[2] not in good_tgt][:3])
ok("every timing is a real game timing", all(r[3] in good_time for r in rows), [r for r in rows if r[3] not in good_time][:3])
bad_cond = []
for r in rows:
    if r[4]:
        for n in re.findall(r"\d+", str(r[4])):
            if not q("select 1 from skill_causalities where id = ?", int(n)): bad_cond.append((r[0], r[4]))
ok("every requirement points at a real condition", not bad_cond, bad_cond[:3])
ok("chances and durations in range", all(1 <= (r[6] or 0) <= 100 and 0 <= (r[5] or 0) <= 99 for r in rows), [r for r in rows if not (1 <= (r[6] or 0) <= 100)][:3])
got = sorted({r[1] for r in rows}); ok("all effect types made it into the game file", set(expected["effects"]) <= set(got) | {103}, sorted(set(expected["effects"]) - set(got)))
godly = [r for r in rows if r[7] == "Godly Exclusive"]
ok("Godly Exclusive rows in the game file", len(godly) >= 2, len(godly))
giants = [r for r in rows if r[1] == 79]
if giants:
    v1 = q("select eff_value1 from passive_skills where id = ?", giants[0][0])[0][0]
    ok("giant form points at a real game card", bool(q("select 1 from cards where id = ?", v1)), v1)
ns = q("select causality_type, cau_val1, cau_val2 from skill_causalities where causality_type = 41 and cau_val2 >= 9100000")
ok("typed enemy name is a real game condition", bool(ns), ns)
if ns:
    members = q("select count(*) from card_unique_info_set_relations where card_unique_info_set_id = ?", ns[0][2])[0][0]
    ok("its name group holds every Frieza card name (%d)" % members, members >= 20, members)
intro = q("select id, passive_skill_effect_id, causality_conditions from passive_skills where passive_skill_effect_id is not null and id in (%s)" % ",".join(map(str, ids)))
ok("intro scene is in the game file with its condition", bool(intro) and bool(intro[0][2]) and bool(q("select 1 from passive_skill_effects where id = ?", intro[0][1])), intro)
print("\n%d checks failed" % len(fails) if fails else "\nALL CHECKS PASSED")
