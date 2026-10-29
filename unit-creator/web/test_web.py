"""Web version end to end in a browser: loads from a plain web server (no Android bridge), finds a
character, builds a unit, saves it (survives reload), exports .eclp (checked by the Android decoder),
exports and re-imports the editable .json, and checks the Android-only parts are hidden."""
import http.server, threading, functools, os, subprocess, json, time, sys
from playwright.sync_api import sync_playwright
SITE = "/home/claude/work/web/site"; OUT = "/tmp/claude-0/webtest/"
class Q(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *a): pass
    def end_headers(self): self.send_header("Cache-Control", "no-store"); super().end_headers()
srv = http.server.ThreadingHTTPServer(("127.0.0.1", 0), functools.partial(Q, directory=SITE)); threading.Thread(target=srv.serve_forever, daemon=True).start()
url = f"http://127.0.0.1:{srv.server_port}/"
def ok(n, c, x=""): print(("PASS " if c else "FAIL ") + n, x); sys.stdout.flush()
IPHONE_UA = "Mozilla/5.0 (iPhone; CPU iPhone OS 26_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Mobile/15E148 Safari/604.1"
with sync_playwright() as p:
    b = p.chromium.launch()
    ctx = b.new_context(viewport={"width": 402, "height": 874}, device_scale_factor=3, is_mobile=True, has_touch=True, user_agent=IPHONE_UA, accept_downloads=True)
    pg = ctx.new_page(); w = lambda ms=700: pg.wait_for_timeout(ms)
    errs = []; pg.on("pageerror", lambda e: errs.append(str(e)))
    missing = []; pg.on("response", lambda r: r.status >= 400 and missing.append(f"{r.status} {r.url}"))
    bad = []; pg.on("requestfailed", lambda r: bad.append(r.url + " " + str(r.failure)))
    t0 = time.time(); pg.goto(url)
    for _ in range(300):
        st = pg.evaluate("window.__forgeWorkspaceStartup")
        if st in ("ready", "failed"): break
        w(100)
    ok("app starts from a plain website", st == "ready", [st, round(time.time() - t0, 1), errs[:2]])
    ok("uses the web bridge", pg.evaluate("!!(window.forgeNative&&forgeNative.web)"))
    info = pg.evaluate("Native.call('info').then(i=>[i.count,i.meta.date,Object.keys(i.schema).length])")
    ok("game data loads", info[0] > 1000, info)
    pg.screenshot(path=OUT + "1-home.png")
    pg.evaluate("navigate('source')")
    for _ in range(200):
        if pg.evaluate("!!document.querySelector('#fd-create .fd-tile')"): break
        w(100)
    ok("Create screen with the finder", pg.locator("#fd-create .fd-tile").count() > 0, pg.inner_text("#fd-create .fd-count"))
    pg.fill("#fd-create [data-fd-text]", "Vegito"); w(600)
    pg.locator('#fd-create [data-fd="rarity"][data-fv="5"]').click(); w(500)
    ok("search + filters", "character" in pg.inner_text("#fd-create .fd-count"), pg.inner_text("#fd-create .fd-count"))
    pg.screenshot(path=OUT + "2-create.png")
    pg.get_by_text("Describe to AI").click(); w(1200)
    ok("Describe to AI opens (copy & paste mode, no key needed)", "Copy prompt" in pg.inner_text("dialog[open]") and not pg.locator("#aic-settings-open").is_visible())
    pg.evaluate("document.querySelectorAll('dialog[open]').forEach(d=>d.close())"); w(300)
    for _ in range(40):
        if pg.locator("#web-install").count(): break
        w(100)
    ok("iPhone gets the Add to Home Screen tip", pg.locator("#web-install").count() == 1)
    pg.screenshot(path=OUT + "2b-install-tip.png")
    pg.locator("#web-install button").click(); w(300)
    ok("tip closes and stays closed", pg.locator("#web-install").count() == 0 and pg.evaluate("localStorage.getItem('web-install-told')") == "1")
    pg.locator("#fd-create .fd-tile").first.click()
    for _ in range(300):
        if pg.evaluate("state.view==='editor'&&!!state.project&&document.getElementById('busy').hidden"): break
        w(100)
    ok("unit created", pg.evaluate("state.view") == "editor", pg.evaluate("state.project&&Forge.card(state.project).name"))
    w(1500)
    for t in ["leader", "passive", "special", "supers", "transform", "links", "look", "save", "basics"]:
        pg.evaluate(f"document.querySelector('[data-b=\"tab:{t}\"]')?.click()"); w(700)
    ok("every builder step opens", not errs, errs[:2])
    pg.fill('[data-bind="card:name"]', "Web Vegito"); pg.dispatch_event('[data-bind="card:name"]', "change"); w(1500)
    pg.evaluate("flushSave()"); w(800)
    key = pg.evaluate("state.project.key")
    pg.screenshot(path=OUT + "3-builder.png")
    # export .eclp
    pg.evaluate("document.querySelector('[data-b=\"tab:save\"]').click()"); w(800)
    pg.locator('[data-export="eclp"]').first.click()
    for _ in range(400):
        if pg.locator(".web-file-dialog[open]").count(): break
        w(100)
    ok("export prepares the file", pg.locator(".web-file-dialog[open]").count() == 1, pg.inner_text(".web-file-dialog") if pg.locator(".web-file-dialog[open]").count() else pg.inner_text("#toast"))
    pg.screenshot(path=OUT + "4-export.png")
    with pg.expect_download() as dl:
        pg.locator('.web-file-dialog [data-act="download"]').click()
    path = OUT + dl.value.suggested_filename; dl.value.save_as(path)
    ok(".eclp downloaded", os.path.getsize(path) > 1000, [dl.value.suggested_filename, os.path.getsize(path)])
    jo = "-XX:+UnlockDiagnosticVMOptions -XX:-BytecodeVerificationRemote -XX:-BytecodeVerificationLocal -Djava.library.path=/home/claude/work/tools".split()
    r = subprocess.run(["java", *jo, "-cp", "/home/claude/work/tools/eclp-check/app.jar:/home/claude/work/tools/eclp-check/stubout:/home/claude/work/tools/eclp-check", "X", path, OUT + "eclp-out"], capture_output=True, text=True)
    files = r.stdout.strip().splitlines()
    ok("the Android app's decoder opens it", any("files/" in f and ".sql" in f for f in files) and any("forge-project.json" in f for f in files), files or r.stderr[-300:])
    sql = open([OUT + "eclp-out/" + f.split()[0] for f in files if f.endswith(".sql") or ".sql " in f][0], encoding="utf-8").read()
    ok("the game file has the unit", "Web Vegito" in sql)
    # persistence
    pg.reload()
    for _ in range(300):
        if pg.evaluate("window.__forgeWorkspaceStartup") == "ready": break
        w(100)
    units = pg.evaluate("Native.call('projects').then(r=>r.map(x=>x.name))")
    ok("saved units survive a reload", "Web Vegito" in units, units)
    # .json backup and import
    pg.evaluate(f"Native.call('loadProject',{{key:'{key}'}}).then(p=>{{state.project=p;state.view='editor';renderEditor();}})"); w(1500)
    pg.evaluate("void exportProject('json')"); w(800)
    with pg.expect_download() as dl2:
        pg.locator('.web-file-dialog [data-act="download"]').click()
    jpath = OUT + dl2.value.suggested_filename; dl2.value.save_as(jpath)
    ok("editable backup (.json)", json.load(open(jpath))["format"] == "dokkan-unit-forge")
    pg.evaluate("navigate('library')"); w(1000)
    pg.evaluate("void importFile()"); w(600)
    pg.set_input_files(".web-file-dialog input[type=file]", jpath); w(2500)
    n = pg.evaluate("Native.call('projects').then(r=>r.length)")
    ok("importing a unit file adds a copy", n == 2 and pg.evaluate("state.view") == "editor", [n, pg.evaluate("state.view")])
    # importing the web .eclp also works
    pg.evaluate("void importFile()"); w(600)
    pg.set_input_files(".web-file-dialog input[type=file]", path)
    for _ in range(300):
        if pg.evaluate("Native.call('projects').then(r=>r.length)") == 3: break
        w(200)
    ok("importing the web .eclp works too", pg.evaluate("Native.call('projects').then(r=>r.length)") == 3)
    # Android-only parts
    pg.evaluate("document.querySelector('.shell-more-button').click()"); w(500)
    more = pg.inner_text("#shell-more")
    ok("More menu hides Android-only tools", "Download game files" not in more and "Game movies" not in more, more.replace("\n", " | ")[:300])
    pg.evaluate("document.querySelectorAll('dialog[open]').forEach(d=>d.close())")
    pg.evaluate("navigate('animations')"); w(800)
    ok("Animate explains it's Android-only for now", "coming to the web version" in pg.inner_text("#main"))
    pg.evaluate("ForgeSettings.open()"); w(1500)
    ok("Settings → Game data works", "newest characters" in pg.inner_text("#set-game") , pg.inner_text("#set-game").replace("\n", " | ")[:200])
    pg.screenshot(path=OUT + "5-settings.png")
    ok("no page errors", not errs, errs[:3])
    ok("no missing files", not missing, missing[:5])
    ok("no failed requests", not [u for u in bad if "dokkan-eclipse.com" not in u and "ERR_ABORTED" not in u], [u for u in bad if "dokkan-eclipse.com" not in u and "ERR_ABORTED" not in u][:5])
    print("aborted (fine):", len([u for u in bad if "ERR_ABORTED" in u]))
    b.close()
