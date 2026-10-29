"""Run the Forge web UI in headless Chromium against the mock native bridge."""
import json, os, re, sys, mimetypes, pathlib, traceback
from playwright.sync_api import sync_playwright
sys.path.insert(0, os.path.dirname(__file__))
from native_mock import Native, UI

ALLOWED_DATA = {"data/mechanics.js", "data/guide-data.js", "data/animation-availability.js", "data/movie-catalog.js", "data/sparking-reference.json"}

def mime(p):
    p = p.lower()
    for ext, m in ((".wasm", "application/wasm"), (".html", "text/html"), (".js", "application/javascript"), (".css", "text/css"), (".json", "application/json"), (".png", "image/png"), (".svg", "image/svg+xml")):
        if p.endswith(ext):
            return m
    return "application/octet-stream"


class Session:
    def __init__(self, headless=True, viewport=(412, 915)):
        self.native = Native()
        self.errors, self.console = [], []
        self.pw = sync_playwright().start()
        self.browser = self.pw.chromium.launch(headless=headless, args=["--no-sandbox"])
        self.ctx = self.browser.new_context(viewport={"width": viewport[0], "height": viewport[1]}, ignore_https_errors=True)
        self.page = self.ctx.new_page()
        self.page.on("pageerror", lambda e: self.errors.append("pageerror: " + str(e) + "\n" + (e.stack or "")))
        self.page.on("console", lambda m: self.console.append(f"{m.type}: {m.text} @ {m.location.get('url','')}:{m.location.get('lineNumber','')}") if m.type in ("error", "warning") else None)
        self.page.on("requestfailed", lambda r: self.console.append("requestfailed: " + r.url[:200] + " " + str(r.failure)))
        self.ctx.route("**/*", self._route)
        self.quiet = ("dokkan-eclipse.com/cdn", "cdn.dokkan-eclipse.com")
        self.page.expose_function("__mockNative", self._native)
        self.page.add_init_script("""
          new MutationObserver(() => {}).observe(document, {childList:true});
          document.addEventListener('DOMContentLoaded', () => {
            const t = document.getElementById('toast');
            if (t) new MutationObserver(() => { if (t.className.includes('error') && t.textContent) console.error('TOAST-ERROR: ' + t.textContent); }).observe(t, {attributes:true, childList:true, characterData:true, subtree:true});
          });
          window.forgeNative = { call: (m, a) => window.__mockNative(m, JSON.stringify(a || {})).then(r => { const o = JSON.parse(r); if (!o.ok) throw new Error(o.error); return o.result; }) };
        """)

    def _native(self, method, args):
        try:
            res = self.native.call(method, json.loads(args))
            return json.dumps({"ok": True, "result": res})
        except Exception as e:
            if not str(e).startswith("Unsupported action (mock)"):
                self.native.log.append("ERR " + method + ": " + repr(e))
            return json.dumps({"ok": False, "error": str(e) or "The operation failed."})

    def _route(self, route):
        url = route.request.url
        m = re.match(r"https://forge\.local/([^?#]*)", url)
        if not m:
            self.console.append("external request blocked: " + url)
            return route.abort()
        path = m.group(1) or "index.html"
        if path.startswith("local-asset/"):
            import urllib.parse
            from native_mock import STATE
            f = STATE / "assets" / urllib.parse.unquote(path[len("local-asset/"):])
            if f.is_file(): return route.fulfill(status=200, body=f.read_bytes(), headers={"content-type": mime(path)})
            return route.fulfill(status=404, body="")
        f = UI / path
        if (path.startswith("data/") and path not in ALLOWED_DATA) or not f.is_file():
            self.console.append("404: " + path)
            return route.fulfill(status=404, body="")
        return route.fulfill(status=200, body=f.read_bytes(), headers={"content-type": mime(path)})

    def open(self):
        self.page.goto("https://forge.local/index.html")
        self.page.wait_for_load_state("networkidle")
        return self

    def close(self):
        self.browser.close(); self.pw.stop()

    def report(self, label=""):
        print("==", label, "errors:", len(self.errors), "console:", len(self.console))
        for e in self.errors: print("  ", e[:1500])
        for c in self.console:
            if any(q in c for q in self.quiet) or "Failed to load resource" in c: continue
            print("  ", c[:500])
        errs = [l for l in self.native.log if l.startswith("ERR")]
        for e in errs: print("  native", e[:400])
        if self.native.unknown: print("   unknown native:", sorted(set(self.native.unknown)))
        self.errors.clear(); self.console.clear(); self.native.unknown.clear()
        self.native.log = [l for l in self.native.log if not l.startswith("ERR")]
