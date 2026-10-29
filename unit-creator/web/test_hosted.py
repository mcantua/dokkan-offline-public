"""The Claude-hosted copy, run the way Claude serves it (page skeleton added, no service worker),
with stand-ins for Claude's storage ("db"), "user" and file saving ("downloads").
Checks: units are kept in Claude storage (survive wiping the browser's own storage), big units
are split under the 256 KiB document limit, .eclp comes as a .zip that holds a valid .eclp, and
the .json backup saves."""
import http.server, threading, functools, sys, os, json, base64, zipfile, subprocess, io
from playwright.sync_api import sync_playwright
SITE = "/home/claude/work/web/site-artifact"; OUT = "/tmp/claude-0/webtest/hosted/"; os.makedirs(OUT, exist_ok=True)
SKELETON = '<!doctype html><html><head><meta charset=utf8><meta name=viewport content="width=device-width,initial-scale=1,viewport-fit=cover"><style>:root{color-scheme:light;padding:env(safe-area-inset-top) 0 env(safe-area-inset-bottom)}body{margin:0;font:14px system-ui}img{max-width:100%}[hidden]{display:none!important}</style></head><body>%s</body></html>'
class Q(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *a): pass
    def do_GET(self):
        if self.path in ("/", "/index.html"):
            body = SKELETON.replace("%s", open(SITE + "/index.html").read()).encode()
            self.send_response(200); self.send_header("Content-Type", "text/html; charset=utf-8"); self.send_header("Content-Length", str(len(body))); self.end_headers(); self.wfile.write(body); return
        if self.path.endswith("sw.js"): self.send_error(404); return
        return super().do_GET()
srv = http.server.ThreadingHTTPServer(("127.0.0.1", 0), functools.partial(Q, directory=SITE)); threading.Thread(target=srv.serve_forever, daemon=True).start()
url = f"http://127.0.0.1:{srv.server_port}/"
def ok(n, c, x=""): print(("PASS " if c else "FAIL ") + n, x); sys.stdout.flush()
MOCK = r"""
(() => {
  const KEY = "__mockdb";
  const load = () => JSON.parse(localStorage.getItem(KEY) || "{}"), save = (d) => localStorage.setItem(KEY, JSON.stringify(d));
  const err = (code, message) => Object.assign(new Error(message), { code });
  const snap = (id, v) => ({ id, exists: v !== undefined, data: () => v, metadata: { fromCache: false, hasPendingWrites: false } });
  const docRef = (path) => ({ id: path.split("/").pop(), path,
    async get() { return snap(this.id, load()[path]); },
    async set(v) { const n = JSON.stringify(v).length; if (n > 262144) throw err("invalid_argument", "document over 256 KiB: " + n); const d = load(); d[path] = v; save(d); window.__mockWrites = (window.__mockWrites || 0) + 1; },
    async update(v) { const d = load(); if (!d[path]) throw err("invalid_argument", "missing"); d[path] = Object.assign({}, d[path], v); save(d); },
    async delete() { const d = load(); delete d[path]; save(d); } });
  const query = (col, filters, n) => ({
    where(f, op, v) { return query(col, filters.concat([[f, op, v]]), n); }, orderBy() { return this; }, limit(k) { return query(col, filters, k); },
    async get() { const d = load(); const docs = Object.keys(d).filter((p) => p.startsWith(col + "/") && p.split("/").length === col.split("/").length + 1).sort()
      .filter((p) => filters.every(([f, op, v]) => op === "==" ? d[p][f] === v : true)).slice(0, n || 1000).map((p) => snap(p.split("/").pop(), d[p])); return { docs, size: docs.length, empty: !docs.length, docChanges: () => [], metadata: {} }; } });
  const db = { doc: docRef, collection: (c) => Object.assign(query(c, [], 0), { path: c, doc: (id) => docRef(c + "/" + (id || Math.random().toString(36).slice(2))) }) };
  const user = { id: async () => "viewer123", isOwner: () => true, canEdit: () => true, can: () => true };
  const downloads = { async save({ filename, data }) {
    const allowed = "gif png jpg jpeg webp mp4 webm mov txt json md docx pptx epub csv ttf html svg pdf xlsx zip".split(" ");
    if (!allowed.includes(filename.split(".").pop().toLowerCase())) throw err("rejected_extension", "no");
    const buf = data instanceof Blob ? new Uint8Array(await data.arrayBuffer()) : typeof data === "string" ? new TextEncoder().encode(data) : new Uint8Array(data);
    let bin = ""; for (let i = 0; i < buf.length; i += 32768) bin += String.fromCharCode.apply(null, buf.subarray(i, i + 32768));
    await window.__saveMock(filename, btoa(bin)); return { status: "saved" }; } };
  const caps = { db, user, downloads };
  window.claude = { use: (name) => new Promise((r) => setTimeout(() => r(caps[name] || null), 50)) };
})();
"""
saved = {}
with sync_playwright() as p:
    b = p.chromium.launch()
    ctx = b.new_context(viewport={"width": 402, "height": 874}, device_scale_factor=3, is_mobile=True, has_touch=True)
    ctx.add_init_script(MOCK)
    ctx.expose_function("__saveMock", lambda name, b64: saved.__setitem__(name, base64.b64decode(b64)))
    pg = ctx.new_page(); w = lambda ms=700: pg.wait_for_timeout(ms)
    errs = []; pg.on("pageerror", lambda e: errs.append(str(e)))
    missing = []; pg.on("response", lambda r: r.status >= 400 and missing.append(f"{r.status} {r.url}"))
    def ready():
        for _ in range(300):
            st = pg.evaluate("window.__forgeWorkspaceStartup")
            if st in ("ready", "failed"): return st
            w(100)
    pg.goto(url); ok("starts inside Claude's page wrapper", ready() == "ready", errs[:2])
    ok("says units are saved to Claude", "Saved to your Claude account" in pg.evaluate("document.querySelector('.local-pill').textContent"))
    ok("knows it's hosted, no install tip / offline worker", pg.evaluate("window.__forgeWeb.hosted && !navigator.serviceWorker.controller") and pg.locator("#web-install").count() == 0)
    pg.evaluate("navigate('source')")
    for _ in range(200):
        if pg.locator("#fd-create .fd-tile").count(): break
        w(100)
    pg.fill("#fd-create [data-fd-text]", "Gogeta"); w(800)
    pg.locator("#fd-create .fd-tile").first.click()
    for _ in range(300):
        if pg.evaluate("state.view==='editor'&&!!state.project&&document.getElementById('busy').hidden"): break
        w(100)
    w(1500)
    pg.evaluate("document.querySelector('[data-b=\"tab:basics\"]')?.click()"); pg.wait_for_timeout(300)
    pg.fill('[data-bind="card:name"]', "Cloud Gogeta"); pg.dispatch_event('[data-bind="card:name"]', "change"); w(1200)
    pg.evaluate("flushSave()"); w(2500)
    store = pg.evaluate("JSON.parse(localStorage.getItem('__mockdb')||'{}')")
    heads = {k: v for k, v in store.items() if v.get("kind") == "project"}
    ok("unit saved to Claude storage", any(v["summary"]["name"] == "Cloud Gogeta" for v in heads.values()), list(store)[:3])
    ok("stored compressed, under the 256 KiB limit", all(len(json.dumps(v)) < 262144 for v in store.values()), max(len(json.dumps(v)) for v in store.values()))
    # wipe the browser's own storage: units must come back from Claude storage
    pg.evaluate("indexedDB.deleteDatabase('dokkan-unit-creator')"); w(500)
    pg.reload(); ready(); w(800)
    names = pg.evaluate("Native.call('projects').then(r=>r.map(x=>x.name))")
    ok("units survive the browser clearing its storage", "Cloud Gogeta" in names, names)
    key = pg.evaluate("Native.call('projects').then(r=>r[0].key)")
    pg.evaluate(f"Native.call('loadProject',{{key:'{key}'}}).then(p=>{{state.project=p;state.view='editor';renderEditor();}})"); w(1500)
    ok("unit opens from Claude storage", pg.evaluate("Forge.card(state.project).name") == "Cloud Gogeta")
    # big unit: split across documents
    big = pg.evaluate("""(async()=>{const p=JSON.parse(JSON.stringify(state.project)); p.key='unit-big-test'; p.notes=Array.from({length:60000},(_,i)=>Math.random().toString(36)).join(''); await Native.call('saveProject',{project:p}); await new Promise(r=>setTimeout(r,3000)); const back=await Native.call('loadProject',{key:'unit-big-test'}); return [back.notes.length===p.notes.length, Object.keys(JSON.parse(localStorage.getItem('__mockdb'))).filter(k=>k.includes('unit-big-test')).length];})()""")
    ok("very big unit is split and comes back whole", big[0] and big[1] > 1, big)
    pg.evaluate("Native.call('deleteProject',{key:'unit-big-test'})"); w(500)
    ok("deleting removes every piece", not [k for k in pg.evaluate("Object.keys(JSON.parse(localStorage.getItem('__mockdb')))") if "unit-big-test" in k])
    # .eclp export → zip
    pg.evaluate("document.querySelector('[data-b=\"tab:save\"]').click()"); w(800)
    pg.locator('[data-export="eclp"]').first.click()
    for _ in range(400):
        if pg.locator(".web-file-dialog[open]").count(): break
        w(100)
    ok("export window explains the zip", "tap the zip once" in pg.inner_text(".web-file-dialog"))
    pg.screenshot(path=OUT + "export.png")
    pg.locator('.web-file-dialog [data-act="save"]').click(); w(1500)
    zname = [n for n in saved if n.endswith(".eclp.zip")]
    ok(".eclp handed over as a .zip", bool(zname), list(saved))
    z = zipfile.ZipFile(io.BytesIO(saved[zname[0]])); ok("zip opens and holds the .eclp", z.testzip() is None and z.namelist() == [zname[0][:-4]], z.namelist())
    open(OUT + "x.eclp", "wb").write(z.read(z.namelist()[0]))
    jo = "-XX:+UnlockDiagnosticVMOptions -XX:-BytecodeVerificationRemote -XX:-BytecodeVerificationLocal -Djava.library.path=/home/claude/work/tools".split()
    r = subprocess.run(["java", *jo, "-cp", "/home/claude/work/tools/eclp-check/app.jar:/home/claude/work/tools/eclp-check/stubout:/home/claude/work/tools/eclp-check", "X", OUT + "x.eclp", OUT + "x-out"], capture_output=True, text=True)
    ok("the .eclp inside is valid (Android decoder)", "forge-project.json" in r.stdout and ".sql" in r.stdout, r.stdout[-200:] or r.stderr[-200:])
    ok("export window closed after saving", pg.locator(".web-file-dialog[open]").count() == 0)
    pg.evaluate("void exportProject('json')"); w(800)
    pg.locator('.web-file-dialog [data-act="save"]').click(); w(1000)
    jn = [n for n in saved if n.endswith(".json")]
    ok(".json backup saves", bool(jn) and json.loads(saved[jn[0]])["format"] == "dokkan-unit-forge", list(saved))
    pg.evaluate("ForgeSettings.open()"); w(1200)
    ok("no page errors", not errs, errs[:3])
    ok("no missing files", not [m for m in missing if "dokkan-eclipse" not in m], missing[:5])
    b.close()
