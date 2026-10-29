"""The iPhone app's web layer (web/site-ios) in a browser with a fake iPhone app bridge
(window.webkit.messageHandlers.ForgeFiles, like the Swift app). Checks: starts, no service worker or
Add-to-Home-Screen tip, .eclp export goes to the native Save sheet (and the Android decoder opens it),
.json backup through the same path, cancelled save, units survive a reload, no missing files."""
import http.server, threading, functools, os, subprocess, json, time, sys, base64
from playwright.sync_api import sync_playwright
SITE = "/home/claude/work/web/site-ios"; OUT = "/tmp/claude-0/iostest/"; os.makedirs(OUT, exist_ok=True)
class Q(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *a): pass
    def end_headers(self): self.send_header("Cache-Control", "no-store"); super().end_headers()
srv = http.server.ThreadingHTTPServer(("127.0.0.1", 0), functools.partial(Q, directory=SITE)); threading.Thread(target=srv.serve_forever, daemon=True).start()
url = f"http://127.0.0.1:{srv.server_port}/index.html"
fails = []
def ok(n, c, x=""):
    print(("PASS " if c else "FAIL ") + n, x); sys.stdout.flush()
    if not c: fails.append(n)
UA = "Mozilla/5.0 (iPhone; CPU iPhone OS 26_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148"   # WKWebView UA: no "Safari"
FAKE_APP = """
window.__saved = []; window.__saveAnswer = true;
window.webkit = { messageHandlers: { ForgeFiles: { postMessage(m) {
  window.__saved.push({ name: m.name, base64: m.base64 });
  setTimeout(() => dispatchEvent(new CustomEvent('forge-file-saved', { detail: { id: m.id, saved: window.__saveAnswer } })), 50);
} } } };
"""
def wait_ready(pg):
    for _ in range(300):
        st = pg.evaluate("window.__forgeWorkspaceStartup")
        if st in ("ready", "failed"): return st
        pg.wait_for_timeout(100)
with sync_playwright() as p:
    b = p.chromium.launch()
    ctx = b.new_context(viewport={"width": 402, "height": 874}, device_scale_factor=3, is_mobile=True, has_touch=True, user_agent=UA)
    ctx.add_init_script(FAKE_APP)
    pg = ctx.new_page(); w = lambda ms=700: pg.wait_for_timeout(ms)
    errs = []; pg.on("pageerror", lambda e: errs.append(str(e)))
    missing = []; pg.on("response", lambda r: r.status >= 400 and missing.append(f"{r.status} {r.url}"))
    reqs = []; pg.on("request", lambda r: reqs.append(r.url))
    t0 = time.time(); pg.goto(url)
    st = wait_ready(pg)
    ok("app starts inside the iPhone app", st == "ready", [st, round(time.time() - t0, 1), errs[:2]])
    ok("marked as the iPhone app", pg.evaluate("document.documentElement.classList.contains('web-ios-app')"))
    ok("sidebar says IPHONE APP", "IPHONE APP" in pg.inner_html(".sidebar-bottom"))
    w(3500)
    ok("no Add to Home Screen tip", pg.locator("#web-install").count() == 0)
    ok("no service worker", pg.evaluate("navigator.serviceWorker ? navigator.serviceWorker.getRegistrations().then(r=>r.length) : 0") == 0 and not any(u.endswith("sw.js") for u in reqs))
    info = pg.evaluate("Native.call('info').then(i=>i.count)")
    ok("game data loads", info > 1000, info)
    pg.evaluate("navigate('source')")
    for _ in range(200):
        if pg.evaluate("!!document.querySelector('#fd-create .fd-tile')"): break
        w(100)
    pg.fill("#fd-create [data-fd-text]", "Goku"); w(600)
    pg.locator("#fd-create .fd-tile").first.click()
    for _ in range(300):
        if pg.evaluate("state.view==='editor'&&!!state.project&&document.getElementById('busy').hidden"): break
        w(100)
    ok("unit created", pg.evaluate("state.view") == "editor")
    w(1200)
    pg.fill('[data-bind="card:name"]', "iPhone Goku"); pg.dispatch_event('[data-bind="card:name"]', "change"); w(1200)
    pg.evaluate("flushSave()"); w(800)
    key = pg.evaluate("state.project.key")
    pg.screenshot(path=OUT + "1-builder.png")
    # .eclp → native Save sheet
    pg.evaluate("document.querySelector('[data-b=\"tab:save\"]').click()"); w(800)
    pg.locator('[data-export="eclp"]').first.click()
    for _ in range(400):
        if pg.evaluate("__saved.length"): break
        w(100)
    saved = pg.evaluate("__saved")
    ok("export goes straight to the iPhone Save sheet (no web dialog)", len(saved) == 1 and saved[0]["name"].endswith(".eclp") and pg.locator(".web-file-dialog[open]").count() == 0, [s["name"] for s in saved])
    path = OUT + "unit.eclp"; open(path, "wb").write(base64.b64decode(saved[0]["base64"]))
    jo = "-XX:+UnlockDiagnosticVMOptions -XX:-BytecodeVerificationRemote -XX:-BytecodeVerificationLocal -Djava.library.path=/home/claude/work/tools".split()
    r = subprocess.run(["java", *jo, "-cp", "/home/claude/work/tools/eclp-check/app.jar:/home/claude/work/tools/eclp-check/stubout:/home/claude/work/tools/eclp-check", "X", path, OUT + "eclp-out"], capture_output=True, text=True)
    files = r.stdout.strip().splitlines()
    ok("the Android app's decoder opens the .eclp", any(".sql" in f for f in files) and any("forge-project.json" in f for f in files), files or r.stderr[-300:])
    sqlf = [OUT + "eclp-out/" + f.split()[0] for f in files if ".sql" in f]
    ok("the game file has the unit", bool(sqlf) and "iPhone Goku" in open(sqlf[0], encoding="utf-8").read())
    w(800)
    ok("no error shown after saving", not errs, errs[:2])
    # .json backup through the same path
    pg.evaluate("void exportProject('json')")
    for _ in range(100):
        if pg.evaluate("__saved.length") == 2: break
        w(100)
    saved = pg.evaluate("__saved")
    j = json.loads(base64.b64decode(saved[-1]["base64"])) if len(saved) == 2 else {}
    ok("editable backup (.json) saves too", j.get("format") == "dokkan-unit-forge", saved[-1]["name"] if len(saved) == 2 else None)
    # user cancels the Save sheet: the app keeps working
    w(1200)
    pg.evaluate("__saveAnswer=false; void exportProject('json')")
    for _ in range(50):
        if len(pg.evaluate("__saved")) == 3: break
        w(100)
    w(800); print("  toast:", pg.inner_text("#toast") if pg.locator("#toast").count() else "", [s["name"] for s in pg.evaluate("__saved")])
    ok("cancelling the Save sheet is harmless", len(pg.evaluate("__saved")) == 3 and not errs, errs[:2])
    # persistence
    pg.reload(); wait_ready(pg)
    units = pg.evaluate("Native.call('projects').then(r=>r.map(x=>x.name))")
    ok("saved units survive a reload", "iPhone Goku" in units, units)
    # unfolded / landscape
    pg.set_viewport_size({"width": 884, "height": 1000}); w(800); pg.screenshot(path=OUT + "2-unfolded.png")
    pg.set_viewport_size({"width": 874, "height": 402}); w(800); pg.screenshot(path=OUT + "3-landscape.png")
    ok("no page errors", not errs, errs[:3])
    ok("no missing files", not missing, missing[:5])
    b.close()
print("ALL PASS" if not fails else f"{len(fails)} FAILED: {fails}")
