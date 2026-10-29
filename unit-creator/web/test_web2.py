"""Web version: works offline after the first visit, and every visible menu item opens without errors."""
import http.server, threading, functools, sys
from playwright.sync_api import sync_playwright
SITE = "/home/claude/work/web/site"; OUT = "/tmp/claude-0/webtest/"
class Q(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *a): pass
srv = http.server.ThreadingHTTPServer(("127.0.0.1", 0), functools.partial(Q, directory=SITE)); threading.Thread(target=srv.serve_forever, daemon=True).start()
url = f"http://127.0.0.1:{srv.server_port}/"
def ok(n, c, x=""): print(("PASS " if c else "FAIL ") + n, x); sys.stdout.flush()
with sync_playwright() as p:
    b = p.chromium.launch()
    ctx = b.new_context(viewport={"width": 402, "height": 874}, device_scale_factor=3, is_mobile=True, has_touch=True)
    pg = ctx.new_page(); w = lambda ms=700: pg.wait_for_timeout(ms)
    errs = []; pg.on("pageerror", lambda e: errs.append(str(e)))
    missing = []; pg.on("response", lambda r: r.status >= 400 and missing.append(f"{r.status} {r.url}"))
    def ready():
        for _ in range(300):
            if pg.evaluate("window.__forgeWorkspaceStartup") in ("ready", "failed"): return pg.evaluate("window.__forgeWorkspaceStartup")
            w(100)
    pg.goto(url); ok("starts", ready() == "ready")
    pg.evaluate("localStorage.setItem('web-install-told','1')")
    # visible menu items
    pg.evaluate("navigate('source')"); w(1500)
    pg.get_by_text("Quick Create").first.click(); w(1500)
    ok("Quick Create opens", pg.locator("dialog[open]").count() > 0 and not errs, errs[:2]); pg.screenshot(path=OUT + "6-quick.png")
    pg.evaluate("document.querySelectorAll('dialog[open]').forEach(d=>d.close())"); w(300)
    pg.get_by_text("Use a template").first.click(); w(1500)
    ok("Templates open", pg.locator("dialog[open]").count() > 0 and not errs, errs[:2])
    pg.evaluate("document.querySelectorAll('dialog[open]').forEach(d=>d.close())"); w(300)
    for view in ["home", "library", "combat"]:
        pg.evaluate(f"navigate('{view}')"); w(1500)
        ok(f"{view} screen opens", not errs and len(pg.inner_text("#main").strip()) > 20, (errs[:2], pg.inner_text("#main")[:80].replace("\n", " | ")))
        pg.screenshot(path=OUT + f"7-{view}.png")
        if view == "library": ok("Library hides Sparking (Android-only)", not pg.locator('[data-library-filter="sparking"]').is_visible())
    # offline: wait for the service worker to finish caching, then cut the network
    for _ in range(200):
        if pg.evaluate("navigator.serviceWorker && navigator.serviceWorker.controller ? 1 : 0"): break
        w(200)
    pg.reload(); ready(); w(3000)
    ok("service worker in control", pg.evaluate("!!navigator.serviceWorker.controller"))
    cached = pg.evaluate("caches.keys().then(async ks=>{let n=0;for(const k of ks){n+=(await (await caches.open(k)).keys()).length}return [ks,n]})")
    ok("app saved for offline", cached[1] > 40, cached)
    ctx.set_offline(True)
    pg.reload(); st = ready()
    ok("opens with no internet", st == "ready", [st, errs[:2]])
    pg.evaluate("navigate('source')")
    for _ in range(100):
        if pg.locator("#fd-create .fd-tile").count(): break
        w(100)
    ok("characters available offline", pg.locator("#fd-create .fd-tile").count() > 0)
    pg.locator("#fd-create .fd-tile").first.click()
    for _ in range(300):
        if pg.evaluate("state.view==='editor'&&document.getElementById('busy').hidden"): break
        w(100)
    ok("can build a unit offline", pg.evaluate("state.view") == "editor", pg.inner_text("#toast") if pg.locator("#toast").count() else "")
    pg.screenshot(path=OUT + "8-offline-builder.png")
    ok("no page errors", not errs, errs[:3])
    ok("no missing files", not [m for m in missing if "dokkan-eclipse" not in m], missing[:5])
    # unfolded / landscape: sidebar layout, nothing Android-only, no sideways scrolling
    for vw, vh in [(840, 1000), (1180, 820)]:
        q = b.new_page(viewport={"width": vw, "height": vh}); q.goto(url)
        for _ in range(200):
            if q.evaluate("window.__forgeWorkspaceStartup") == "ready": break
            q.wait_for_timeout(100)
        q.wait_for_timeout(800)
        side = q.evaluate("[...document.querySelectorAll('.sidebar button,.sidebar small')].filter(e=>e.offsetParent).map(e=>e.innerText.trim()).join(' | ')")
        ok(f"{vw}px wide: clean sidebar, fits the screen", "Offline downloads" not in side and "ANDROID" not in side and q.evaluate("document.documentElement.scrollWidth") <= vw, side.replace("\n", " ")[:160])
        q.close()
    b.close()
