#!/usr/bin/env python3
"""One focused integration check of the final, self-contained browser artifact.

Uses a disposable browser profile and blocks network artwork/services. Native
file-opening is checked separately in genuine WKWebView, not inferred here.
"""
import functools
import hashlib
import http.server
import json
from pathlib import Path
import shutil
import threading

from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "test-page"


class Quiet(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *_args):
        pass


def main():
    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), functools.partial(Quiet, directory=OUTPUT))
    threading.Thread(target=server.serve_forever, daemon=True).start()
    url = f"http://127.0.0.1:{server.server_port}/UnitCreator-test.html"
    checks, errors, local_requests = [], [], []
    browser_version = None

    def check(name, passed, detail=None):
        checks.append({"name": name, "passed": bool(passed), "detail": detail})
        print(("PASS " if passed else "FAIL ") + name, flush=True)
        if not passed:
            raise AssertionError(name)

    def ready(page):
        page.wait_for_function("['ready','failed'].includes(window.__forgeWorkspaceStartup)", timeout=90000)
        if page.evaluate("window.__forgeWorkspaceStartup") != "ready":
            raise AssertionError("The actual packed application did not start")
        page.evaluate("document.querySelectorAll('dialog[open]').forEach(d=>d.close())")
        page.locator("#db-quick").wait_for(state="visible", timeout=30000)
        page.evaluate("document.fonts.ready.then(()=>new Promise(r=>requestAnimationFrame(()=>requestAnimationFrame(r))))")

    try:
        with sync_playwright() as playwright:
            executable = shutil.which("chromium") or shutil.which("google-chrome") or shutil.which("chromium-browser")
            if not executable:
                raise RuntimeError("A Chromium browser must be installed before the final artifact check")
            browser = playwright.chromium.launch(executable_path=executable)
            browser_version = browser.version
            context = browser.new_context(viewport={"width": 466, "height": 678}, device_scale_factor=1)
            context.route("**/*", lambda route: route.continue_() if route.request.url in (url, url.rsplit("/", 1)[0] + "/favicon.ico") or route.request.url.startswith(("data:", "blob:")) else route.abort())
            page = context.new_page()
            page.on("pageerror", lambda error: errors.append(str(error)))
            page.on("request", lambda request: local_requests.append(request.url) if request.url.startswith(f"http://127.0.0.1:{server.server_port}/") else None)
            page.goto(url, wait_until="domcontentloaded", timeout=90000)
            ready(page)
            check("actual Home is visible with the current version", "2.36.3" in page.locator("#test-page-info").inner_text())
            check("both real embedded catalogs load", page.evaluate("async()=>{const a=await Native.call('info'),b=await Native.call('sparkingInfo'),row=await Native.call('querySparking',{table:'cards',limit:1});return a.count===17786&&b.available&&b.count===19308&&row.length===1}"))
            check("Duo outer browser layout fits", page.evaluate("document.documentElement.scrollWidth<=innerWidth+1"))
            page.screenshot(path=str(OUTPUT / "preview.png"))
            page.set_viewport_size({"width": 669, "height": 951})
            page.evaluate("new Promise(r=>requestAnimationFrame(()=>requestAnimationFrame(r)))")
            check("Duo inner browser layout fits", page.evaluate("document.documentElement.scrollWidth<=innerWidth+1"))
            check("original game resource parsers and movie tools are packaged", page.evaluate("!!(window.ForgeMovieInput&&window.ForgeUsmWriter&&window.__forgeWeb.formats&&window.__forgeWeb.preview&&window.__forgeWeb.movies)"))
            compatibility = page.evaluate("__forgeWeb.movies.compatibility.check()")
            check("embedded compatibility worker and WASM decoder actually load", compatibility.get("ready") and compatibility.get("vp9") and compatibility.get("hca") and bool(compatibility.get("version")), compatibility)
            # This changes only the temporary browser profile. It covers the final
            # gallery module and persistence, rather than repeating editor tests.
            result = page.evaluate("""async()=>{
              await ForgeAnimationGallery.create();
              const doc=ForgeAnimationGallery.current();
              doc.animationStudio.name='Packed-page persistence check';
              ForgeAnimationGallery.changed(); await ForgeAnimationGallery.flush();
              return {key:doc.key,noUnit:state.project===null||state.project===undefined,
                saved:(await ForgeAnimationGallery.read(doc.key)).animationStudio.name};
            }""")
            page.locator("#tl, #studio-context").first.wait_for(state="visible", timeout=30000)
            check("independent animation editing opens and saves", result["noUnit"] and result["saved"] == "Packed-page persistence check")
            page.reload(wait_until="domcontentloaded", timeout=90000)
            ready(page)
            restored = page.evaluate("key=>ForgeAnimationGallery.read(key).then(d=>d?.animationStudio?.name)", result["key"])
            check("saved animation survives reopening the packed page", restored == "Packed-page persistence check")
            check("no JavaScript exceptions", not errors, errors[:5])
            check("no adjacent scripts, fonts, styles or data are needed", all(request in (url, url.rsplit("/", 1)[0] + "/favicon.ico") for request in local_requests), local_requests[:8])
            browser.close()
    finally:
        server.shutdown()
        page_file = OUTPUT / "UnitCreator-test.html"
        report = {
            "html_sha256": hashlib.sha256(page_file.read_bytes()).hexdigest(),
            "html_bytes": page_file.stat().st_size,
            "browser": browser_version,
            "checks": checks,
            "errors": errors,
            "limitations": ["Chromium with a local HTTP origin and disposable storage", "Duo browser viewport sizes do not establish native folding or physical-device behavior", "External services and artwork were blocked", "Genuine WKWebView file-opening and native services are measured separately"],
        }
        (OUTPUT / "verification.json").write_text(json.dumps(report, indent=2) + "\n")


if __name__ == "__main__":
    main()
