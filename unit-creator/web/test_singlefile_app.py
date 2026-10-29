"""Check the actual standalone app with real game data, using a local HTTP origin for browser storage.

Native phone features and Safari file-opening behavior are not covered by this Chromium check.
"""
import functools
import http.server
import json
import pathlib
import shutil
import threading
from playwright.sync_api import sync_playwright

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "test-page"

class Quiet(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *args): pass

server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), functools.partial(Quiet, directory=OUT))
threading.Thread(target=server.serve_forever, daemon=True).start()
url = f"http://127.0.0.1:{server.server_port}/UnitCreator-test.html"
checks, errors, requests = [], [], []

def check(name, passed, detail=None):
    checks.append({"name": name, "passed": bool(passed), "detail": detail})
    print(("PASS " if passed else "FAIL ") + name, flush=True)
    if not passed: raise AssertionError(f"{name}: {detail}")

def ready(page):
    page.wait_for_function("['ready','failed'].includes(window.__forgeWorkspaceStartup)", timeout=60000)
    check("app startup", page.evaluate("window.__forgeWorkspaceStartup") == "ready")
    page.evaluate("document.querySelectorAll('dialog[open]').forEach(d=>d.close())")

try:
    with sync_playwright() as p:
        browser = p.chromium.launch(executable_path=shutil.which("chromium"))
        context = browser.new_context(viewport={"width": 669, "height": 951}, device_scale_factor=1)
        context.route("**/*", lambda route: route.continue_() if route.request.url.startswith(("data:", "blob:", "http://127.0.0.1:")) else route.abort())
        page = context.new_page()
        page.on("pageerror", lambda e: errors.append(str(e)))
        page.on("request", lambda r: requests.append(r.url) if r.url.startswith("http://127.0.0.1:") else None)
        page.goto(url, wait_until="domcontentloaded")
        ready(page)
        check("version and change line", '2.36.3' in page.locator('#test-page-info').inner_text())
        info = page.evaluate("Native.call('info')")
        check("real character database available", info["count"] == 17786, info["count"])
        sparking = page.evaluate("Native.call('sparkingInfo')")
        check("embedded Sparking snapshot available", sparking["available"] and sparking["count"] == 19308)
        check("Sparking rows load without external files", bool(page.evaluate("Native.call('querySparking',{table:'cards',limit:1})")))
        page.set_viewport_size({"width": 466, "height": 678})
        page.wait_for_timeout(250)
        check("Duo outer browser layout fits", page.evaluate("document.documentElement.scrollWidth <= innerWidth + 1"))
        page.screenshot(path=str(OUT / "preview.png"), full_page=False)
        page.evaluate("navigate('source')")
        page.locator("#fd-create .fd-tile").first.wait_for(timeout=30000)
        page.fill("#fd-create [data-fd-text]", "Vegito")
        page.wait_for_timeout(700)
        check("character search", page.locator("#fd-create .fd-tile").count() > 0)
        page.locator("#fd-create .fd-tile").first.click()
        page.wait_for_function("state.view==='editor' && !!state.project && document.getElementById('busy').hidden", timeout=30000)
        check("create unit from template", page.evaluate("!!state.project"))
        for tab in ["appearance", "look", "basics", "leader", "passive", "supers", "active", "standby", "domain", "links", "save"]:
            page.locator(f'.bld-tab[data-b="tab:{tab}"]').click()
            page.wait_for_timeout(150)
            check("builder tab: " + tab, page.locator('#bld').count() == 1)
        page.locator('.bld-tab[data-b="tab:basics"]').click()
        page.fill('[data-bind="card:name"]', "Browser test unit")
        page.dispatch_event('[data-bind="card:name"]', "change")
        page.evaluate("flushSave()")
        page.wait_for_timeout(700)
        key = page.evaluate("state.project.key")
        check("edited unit saved", page.evaluate("k=>Native.call('loadProject',{key:k}).then(p=>Forge.card(p).name)", key) == "Browser test unit")
        page.reload(wait_until="domcontentloaded")
        ready(page)
        check("unit survives reload", page.evaluate("k=>Native.call('loadProject',{key:k}).then(p=>Forge.card(p).name)", key) == "Browser test unit")
        page.set_viewport_size({"width": 951, "height": 669})
        page.wait_for_timeout(300)
        check("wide browser layout fits", page.evaluate("document.documentElement.scrollWidth <= innerWidth + 1"))
        page.set_viewport_size({"width": 430, "height": 932})
        check("ordinary phone browser layout fits", page.evaluate("document.documentElement.scrollWidth <= innerWidth + 1"))
        check("no JavaScript errors", not errors, errors[:5])
        # One HTML document per navigation; no adjacent CSS/JS/data/font files may be requested.
        check("one file carries local dependencies", all(x.split('?',1)[0].endswith('/UnitCreator-test.html') or x.endswith('/favicon.ico') for x in requests), requests[:10])
        browser.close()
finally:
    server.shutdown()
    report = {"checks": checks, "errors": errors, "limitations": ["Chromium over local HTTP; downloaded file opening on Safari not tested", "Native phone services and inherited browser feature gaps are not covered", "External network requests were blocked; artwork may need the network"]}
    (OUT / "verification.json").write_text(json.dumps(report, indent=2) + "\n")
if any(not x["passed"] for x in checks): raise SystemExit(1)
print(f"{len(checks)} checks passed", flush=True)
