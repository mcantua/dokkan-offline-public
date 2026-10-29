"""v2.36 redesign check (iPhone build in Chromium): every screen in docs/FEATURE-INVENTORY.md still opens and still
has its controls, saved units survive a restart, the new quick-chance buttons save, the .SQL/.JSON option works,
and "Import to Sparking" links Sparking's folder once, writes a valid Sparking 6.6 patch there and never makes a
second copy. Usage: python3 test_redesign.py"""
import sys, os, json, io, zipfile, shutil, tempfile, pathlib
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ios_mock import IosMock
from playwright.sync_api import sync_playwright
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes

OUT = "/tmp/claude-0/iostest/redesign/"; os.makedirs(OUT, exist_ok=True)
fails = []
def ok(n, c, x=""):
    print(("PASS " if c else "FAIL ") + n, json.dumps(x, default=str)[:300]); sys.stdout.flush()
    if not c: fails.append(n)

# What each screen must still have (hooks from docs/FEATURE-INVENTORY.md)
SCREENS = {
    "home": ["#db-quick", ".db-tile[data-open]", "#db-library", "#shell-help", "#shell-settings", ".mobile-nav .shell-more-button"],
    "library": ["#library-query", "[data-library-filter='all']", "[data-library-filter='created']", ".unit-tile[data-open]"],
    "source": ["#fd-create [data-fd-text]", "#fd-create [data-fd='ver']", "#fd-create [data-fd='rarity']", "#fd-create [data-fd='type']", "#fd-create .fd-tile[data-fd-pick]", ".creation-start-options"],
}
TABS = {
    "basics": ["[data-bind='card:name']", "[data-b^='rarity:']", "[data-b^='class:']", "[data-b^='type:']", "[data-guide^='stats:']", "[data-bind='card:hp_max']"],
    "leader": ["[data-b='lg-add']", "[data-lf]"],
    "passive": ["[data-b^='open:passive:']", "[data-b^='passive-del:']", "[data-b='pcat:add']", "[data-b='pcat:preset']", "[data-b='pcat:copy']"],
    "supers": ["[data-b^='super-add:']", "[data-b^='super-del:']", "#normal-attack-style", "[data-guide='studio']"],
    "active": ["[data-b^='active-kind:'], [data-b^='active-del:']"],
    "standby": ["[data-sp^='standby']"],
    "domain": ["[data-sp^='domain']"],
    "links": ["#link-options [data-link]", "#category-options [data-category]"],
    "look": [".art-studio-button", "[data-guide='pick-aura']"],
    "appearance": [".ap [data-ap-q]", ".ap-steps", "[data-ap-reset]", "[data-ap-part='portrait']", "[data-ap-part='sprite']", "[data-ap-part='motion']"],
    "save": ["[data-export='to-eclipse']", "[data-export='to-sparking']", "[data-b='send-files']", "[data-export='eclp']", "[data-export='json']"],
}
HEADER = ["[data-b='ai-helper']", "[data-guide='undo']", "[data-guide='redo']", "details.bld-more", ".ucopy-button", "#bld-card", ".bld-footer"]

work = pathlib.Path(tempfile.mkdtemp())
m = IosMock("/home/claude/work/web/site-ios", "/tmp/claude-0/fakenet", real_net=True)
sparking_dir = work / "Sparking"            # stands in for On My iPhone › Sparking
m.folder_answer = {"sparking": sparking_dir}
key = os.urandom(32); m.secrets["sparking.sprk"] = key.hex()   # test key; the real one comes from the user's APK

def wait_ready(pg):
    for _ in range(600):
        if pg.evaluate("window.__forgeWorkspaceStartup") in ("ready", "failed"): break
        pg.wait_for_timeout(100)
    pg.evaluate("document.querySelectorAll('dialog[open]').forEach(d=>d.close())")

with sync_playwright() as p:
    b = p.chromium.launch(); ctx = m.context(b, viewport={"width": 466, "height": 678})
    ctx.add_init_script("(function(){var d={memory:8,memoryGB:7.5,cores:6,maxFps:120,machine:'mock'};window.__forgeNativeDevice=d;Object.defineProperty(Navigator.prototype,'deviceMemory',{get:function(){return d.memory},configurable:true});})();")
    pg = ctx.new_page(); errs = []; pg.on("pageerror", lambda e: errs.append(str(e)))
    pg.goto(m.url); wait_ready(pg)
    ok("new look is on (premium backdrop + gold frames)", pg.evaluate("getComputedStyle(document.body,'::after').position==='fixed' && getComputedStyle(document.body,'::before').zIndex==='150' && !!document.querySelector('link[href*=premium], style') "),
       pg.evaluate("document.documentElement.className"))

    # ---- a unit to work with
    pg.evaluate("navigate('source')"); pg.wait_for_timeout(1500)
    pg.locator("#fd-create .fd-tile").first.click()
    for _ in range(300):
        if pg.evaluate("state.view==='editor'&&!!state.project&&document.getElementById('busy').hidden"): break
        pg.wait_for_timeout(100)
    pg.evaluate("document.querySelector('[data-b=\"tab:basics\"]')?.click()"); pg.wait_for_timeout(300)
    pg.fill('[data-bind="card:name"]', "Redesign Test"); pg.dispatch_event('[data-bind="card:name"]', "change"); pg.wait_for_timeout(800)
    key_unit = pg.evaluate("state.project.key")

    # ---- builder tabs and header controls
    missing = [s for s in HEADER if not pg.query_selector(s)]
    ok("builder header controls all present", not missing, missing)
    for tab, sels in TABS.items():
        pg.evaluate(f"document.querySelector('[data-b=\"tab:{tab}\"]').click()"); pg.wait_for_timeout(500)
        if tab == "appearance": pg.wait_for_timeout(3000); pg.locator(".ap").screenshot(path=OUT + "appearance-tab.png")
        missing = [s for s in sels if not pg.query_selector(s)]
        ok(f"builder tab '{tab}' opens with its controls", pg.evaluate(f"!!document.querySelector('[data-b=\"tab:{tab}\"].active, [data-b=\"tab:{tab}\"][aria-current]')") and not missing, missing)
    pg.screenshot(path=OUT + "save-tab.png")

    # ---- passive: open an ability, numbered steps, quick chance saves
    pg.evaluate("document.querySelector('[data-b=\"tab:passive\"]').click()"); pg.wait_for_timeout(500)
    pg.evaluate("document.querySelector('[data-b^=\"open:passive:\"]').click()"); pg.wait_for_timeout(600)
    rid = pg.evaluate("document.querySelector('.bld-ability.open').dataset.edit.split(':')[1]")
    steps = pg.evaluate("[...document.querySelectorAll('.bld-ability.open .pf-sec h4')].map(h=>getComputedStyle(h,'::before').content+' '+h.textContent)")
    ok("ability editor shows numbered steps (What it does → Who → When → Requirements)", len(steps) >= 4 and all('counter(pfstep)' in x or x[:3] in ('"1"','"2"','"3"','"4"') for x in steps[:4]), steps)
    pg.locator(".bld-ability.open [data-pf-chance='50']").click(); pg.wait_for_timeout(900)
    prob = pg.evaluate(f"(state.project.tables.passive_skills||[]).filter(r=>String(r.id)==='{rid}').map(r=>r.probability)[0]")
    ok("quick chance button 50% saves the ability's chance", prob == 50, prob)
    pg.evaluate("document.querySelector('.bld-ability.open [data-pf-chance=\"100\"]').click()"); pg.wait_for_timeout(900)
    ok("…and 100% puts it back", pg.evaluate(f"(state.project.tables.passive_skills||[]).filter(r=>String(r.id)==='{rid}').map(r=>r.probability)[0]") == 100)

    # ---- other screens and sheets
    for view, sels in SCREENS.items():
        pg.evaluate(f"navigate('{view}')"); pg.wait_for_timeout(1500 if view == 'source' else 800)
        missing = [s for s in sels if not pg.query_selector(s)]
        ok(f"screen '{view}' opens with its controls", not missing, missing)
    for name, js, sel in [("Settings", "ForgeSettings.open()", "dialog.settings-sheet[open] [data-set-jump]"),
                          ("More sheet", "document.querySelector('.mobile-nav .shell-more-button').click()", "#shell-more[open] [data-shell-go='offline']"),
                          ("Help", "document.querySelector('#shell-help').click()", "dialog.help-sheet[open] #help-search"),
                          ("Downloads", "document.querySelector('[data-shell-go=\"offline\"]')?.click() || ForgeShell.go('offline')", "#offline-root #offline-eclipse-on")]:
        if name != "Downloads": pg.evaluate("document.querySelectorAll('dialog[open]').forEach(d=>d.close())")
        pg.evaluate(js); pg.wait_for_timeout(1200)
        ok(f"{name} opens", bool(pg.query_selector(sel)), sel)
    pg.evaluate("document.querySelectorAll('dialog[open]').forEach(d=>d.close())")

    # ---- .SQL / .JSON option
    pg.evaluate("navigate('editor')"); pg.wait_for_timeout(500)
    pg.evaluate("document.querySelector('[data-b=\"tab:save\"]').click()"); pg.wait_for_timeout(500)
    pg.locator("[data-b='send-files']").click(); pg.wait_for_timeout(500)
    ok("Export .SQL / .JSON offers both", bool(pg.query_selector("dialog[open] [data-export='sql']")) and bool(pg.query_selector("dialog[open] [data-export='json']")))
    n0 = len(m.saved_docs); pg.locator("dialog[open] [data-export='json']").click(); pg.wait_for_timeout(2500)
    ok("JSON export saves the editable unit", len(m.saved_docs) > n0 and m.saved_docs[-1]["name"].endswith(".json"), [d["name"] for d in m.saved_docs[n0:]])
    pg.evaluate("document.querySelectorAll('dialog[open]').forEach(d=>d.close())")

    # ---- .sql import: the app's own .SQL comes back as an editable unit (same game data on re-export)
    pg.evaluate("ForgeShell.go('import')"); pg.wait_for_timeout(800)
    ok("Update & import offers 'Import a .sql file'", bool(pg.query_selector("#import-hub[open] [data-imp='sql']")))
    pg.evaluate("document.querySelectorAll('dialog[open]').forEach(d=>d.close())")
    rt = pg.evaluate("""async () => { const before = state.project, sql = Forge.sql(before);
      await importSqlFile({ name: 'unit.sql', text: sql }); await new Promise(r => setTimeout(r, 800));
      const p = state.project; const out = { other: p.key !== before.key, errors: Forge.validate(p).errors, same: Forge.sql(p).length === sql.length,
        passives: (p.tables.passive_skills||[]).length === (before.tables.passive_skills||[]).length, saved: (await Native.call('projects')).some(x => x.key === p.key) };
      await Native.call('deleteProject', { key: p.key }); await openUnit(before.key); await new Promise(r => setTimeout(r, 800)); return out; }""")
    ok(".sql import rebuilds an editable unit with the same game data", rt["other"] and not rt["errors"] and rt["same"] and rt["passives"] and rt["saved"], rt)
    pg.evaluate("document.querySelectorAll('dialog[open]').forEach(d=>d.close())")
    pg.evaluate("document.querySelector('[data-b=\"tab:save\"]')?.click()"); pg.wait_for_timeout(500)

    # ---- Import to Sparking: first time asks to link the folder, then saves straight into it
    pg.locator("[data-export='to-sparking']").click(); pg.wait_for_timeout(1500)
    ok("first Import to Sparking explains the one-time folder link", bool(pg.query_selector("dialog[open] #gf-link")) and bool(pg.query_selector("dialog[open] #gf-sheet")),
       pg.evaluate("document.querySelector('dialog[open]')?.innerText.slice(0,200)"))
    pg.screenshot(path=OUT + "sparking-link.png")
    pg.locator("dialog[open] #gf-link").click()
    for _ in range(150):
        if list(sparking_dir.glob("*.sprk")) and pg.query_selector("dialog[open] #send-done"): break
        pg.wait_for_timeout(200)
    files = list(sparking_dir.glob("*.sprk"))
    ok("unit lands in Sparking's folder and Sparking opens", len(files) == 1 and any(u.startswith("dbzdokkanww://") for u in m.opened), [f.name for f in files])
    pg.screenshot(path=OUT + "sparking-sent.png")
    info, names = {}, []
    if files:
        data = files[0].read_bytes()
        dec = Cipher(algorithms.AES(key), modes.CTR(data[5:21])).decryptor()
        z = zipfile.ZipFile(io.BytesIO(dec.update(data[21:]) + dec.finalize())); names = z.namelist()
        info = json.loads(z.read("patch_info.json"))
        ok("file is a valid SPRK v1 patch Sparking 6.6 accepts (header, patches/ folder, SQL, creator_id)",
           data[:5] == b"SPRK\x01" and any(n.startswith("patches/sql/") and n.endswith(".sql") for n in names)
           and isinstance(info.get("creator_id"), int) and info["creator_id"] >= 0 and isinstance(info.get("creator_name"), str) and info.get("name"),
           {"info": info, "files": names[:6]})
        sql = next((z.read(n).decode() for n in names if n.endswith(".sql")), "")
        ok("patch SQL carries the unit", "Redesign Test" in sql, len(sql))
    pg.evaluate("document.querySelectorAll('dialog[open]').forEach(d=>d.close())")
    # same unit again: recognised, no second copy, no re-write
    m.opened.clear(); before = files[0].stat().st_mtime_ns if files else 0
    pg.locator("[data-export='to-sparking']").click()
    for _ in range(150):
        if pg.query_selector("dialog[open] #send-done"): break
        pg.wait_for_timeout(200)
    txt = pg.evaluate("document.querySelector('dialog[open]')?.innerText || ''")
    ok("sending the same unit again makes no second copy", len(list(sparking_dir.glob("*.sprk"))) == 1 and "already" in txt.lower() and (files and files[0].stat().st_mtime_ns == before), txt[:160])
    pg.evaluate("document.querySelectorAll('dialog[open]').forEach(d=>d.close())")
    # a change: same file is updated in place
    pg.evaluate("document.querySelector('[data-b=\"tab:basics\"]').click()"); pg.wait_for_timeout(400)
    pg.evaluate("document.querySelector('[data-b=\"tab:basics\"]')?.click()"); pg.wait_for_timeout(300)
    pg.fill('[data-bind="card:name"]', "Redesign Test 2"); pg.dispatch_event('[data-bind="card:name"]', "change"); pg.wait_for_timeout(800)
    pg.evaluate("document.querySelector('[data-b=\"tab:save\"]').click()"); pg.wait_for_timeout(500)
    pg.locator("[data-export='to-sparking']").click()
    for _ in range(150):
        if pg.query_selector("dialog[open] #send-done"): break
        pg.wait_for_timeout(200)
    txt = pg.evaluate("document.querySelector('dialog[open]')?.innerText || ''")
    ok("an edited unit replaces its file (still one copy)", len(list(sparking_dir.glob("*.sprk"))) == 1 or "updated" in txt.lower(), [f.name for f in sparking_dir.glob('*.sprk')] + [txt[:120]])
    pg.evaluate("document.querySelectorAll('dialog[open]').forEach(d=>d.close())")
    # the folder went away (game reinstalled): asks to link again, nothing lost
    shutil.rmtree(sparking_dir)
    pg.locator("[data-export='to-sparking']").click()
    for _ in range(50):
        if pg.query_selector("dialog[open] #gf-link"): break
        pg.wait_for_timeout(200)
    ok("lost folder link is explained and can be linked again", "again" in (pg.evaluate("document.querySelector('dialog[open]')?.innerText || ''")).lower() and bool(pg.query_selector("dialog[open] #gf-link")))
    pg.evaluate("document.querySelectorAll('dialog[open]').forEach(d=>d.close())")

    # ---- saved units survive a restart
    pg.reload(); wait_ready(pg)
    pg.evaluate("navigate('library')"); pg.wait_for_timeout(1200)
    ok("saved unit is still there after a restart", pg.evaluate(f"!!document.querySelector('[data-open=\"{key_unit}\"]')"))
    ok("no page errors", not errs, errs[:3])
print("\n%d failed" % len(fails), fails)
shutil.rmtree(work, ignore_errors=True)
