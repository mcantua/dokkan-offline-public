"""The iPhone build's Android features, end to end in a browser with the iPhone stand-in (ios_mock.py,
real Eclipse network). Usage: python3 test_ios_full.py [--sync]"""
import sys, os, json, time, base64, subprocess, struct, zlib
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ios_mock import IosMock
from playwright.sync_api import sync_playwright
OUT = "/tmp/claude-0/iostest/full/"; os.makedirs(OUT, exist_ok=True)
fails = []
def ok(n, c, x=""):
    s = json.dumps(x, default=str)[:300] if not isinstance(x, str) else x[:300]
    print(("PASS " if c else "FAIL ") + n, s); sys.stdout.flush()
    if not c: fails.append(n)
def png(w, h):
    raw = b"".join(b"\x00" + bytes([200, 50, 50, 255]) * w for _ in range(h))
    ch = lambda t, d: struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
    return b"\x89PNG\r\n\x1a\n" + ch(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)) + ch(b"IDAT", zlib.compress(raw)) + ch(b"IEND", b"")
m = IosMock("/home/claude/work/web/site-ios", "/tmp/claude-0/fakenet", real_net=True)
with sync_playwright() as p:
    b = p.chromium.launch(); ctx = m.context(b); pg = ctx.new_page()
    errs = []; pg.on("pageerror", lambda e: errs.append(str(e)))
    bad = []; pg.on("response", lambda r: r.status >= 400 and "/__file/" not in r.url and bad.append(f"{r.status} {r.url}"))
    call = lambda meth, a=None: pg.evaluate("([m,a]) => Native.call(m, a||{}).then(r=>({ok:true,r}), e=>({ok:false,e:e.message}))", [meth, a])
    t0 = time.time(); pg.goto(m.url)
    for _ in range(600):
        st = pg.evaluate("window.__forgeWorkspaceStartup")
        if st in ("ready", "failed"): break
        pg.wait_for_timeout(100)
    ok("app starts on the real game database (SQLite)", st == "ready", [st, round(time.time() - t0, 1), errs[:2]])
    info = call("info")["r"]
    ok("info: same shape as Android", info["count"] > 10000 and "cards" in info["schema"] and info["database"] == {"canRestore": False} and info["meta"]["date"] == "2026-10-14", {k: info[k] for k in ("count", "meta", "database")})
    q = call("query", {"table": "cards", "search": {"column": "name", "text": "Vegito"}, "limit": 3})["r"]
    ok("query runs real SQL (LIKE, limit)", len(q) == 3 and all("Vegito" in r["name"] for r in q), [r["name"] for r in q])
    ok("query error messages match Android", call("query", {"table": "nope"})["e"] == "Table is not in this database." and call("query", {"table": "cards", "order": "zz"})["e"] == "Unknown sort column")
    ci = call("cardIndex")["r"]
    ok("cardIndex (finder list)", len(ci) > 1000 and len(ci[0]) == 12, ci[0])
    menu = pg.evaluate("[...document.querySelectorAll('[data-shell-go],[data-nav]')].filter(e=>e.offsetParent||getComputedStyle(e).display!=='none').map(e=>e.dataset.shellGo||e.dataset.nav)")
    ok("Android-only menus are back (offline, movies, AI)", not pg.evaluate("document.documentElement.classList.contains('web-version')"), menu)
    # ---- units as files + saved versions
    pg.evaluate("navigate('source')")
    for _ in range(200):
        if pg.evaluate("!!document.querySelector('#fd-create .fd-tile')"): break
        pg.wait_for_timeout(100)
    pg.wait_for_timeout(2500)
    th = pg.evaluate("[...document.querySelectorAll('img')].filter(i=>i.src.includes('/__thumb?u=')).slice(0,3).map(i=>[i.complete, i.naturalWidth])")
    ok("character thumbnails come from saved copies (offline-ready, like Android)", len(th) > 0 and any(w > 0 for c, w in th) and any(f.name.endswith(".body") for f in (m.root / "preview-cache").glob("*")), th)
    pg.fill("#fd-create [data-fd-text]", "Gogeta"); pg.wait_for_timeout(500)
    pg.locator("#fd-create .fd-tile").first.click()
    for _ in range(300):
        if pg.evaluate("state.view==='editor'&&!!state.project&&document.getElementById('busy').hidden"): break
        pg.wait_for_timeout(100)
    ok("unit created", pg.evaluate("state.view") == "editor")
    pg.wait_for_timeout(1200)
    for t in ["leader", "passive", "special", "supers", "transform", "links", "look", "save", "basics"]:
        pg.evaluate(f"document.querySelector('[data-b=\"tab:{t}\"]')?.click()"); pg.wait_for_timeout(500)
    ok("every builder step opens", not errs, errs[:2])
    pg.fill('[data-bind="card:name"]', "iOS Gogeta"); pg.dispatch_event('[data-bind="card:name"]', "change"); pg.wait_for_timeout(1200)
    pg.evaluate("flushSave()"); pg.wait_for_timeout(800)
    key = pg.evaluate("state.project.key")
    ok("unit saved as a file like Android (projects/<key>.json)", (m.root / "projects" / (key + ".json")).is_file(), key)
    pr = call("projects")["r"]
    ok("projects list", any(x["key"] == key and x["name"] == "iOS Gogeta" for x in pr), pr[:1])
    v = call("saveProjectVersion", {"key": key, "label": "First version"})
    ok("save a version", v["ok"] and v["r"]["saved"] and len(v["r"]["versions"]) == 1, v)
    lv = call("listProjectVersions", {"key": key})["r"]
    rv = call("restoreProjectVersion", {"key": key, "versionKey": v["r"]["versionKey"], "expectedCurrentRevision": lv["currentRevision"]})
    ok("restore a version (keeps a 'Before restoring' copy)", rv["ok"] and rv["r"]["versions"][0]["label"] == "Before restoring an earlier version", rv.get("e") or [x["label"] for x in rv["r"]["versions"]])
    ok("version errors match Android", call("restoreProjectVersion", {"key": key, "versionKey": v["r"]["versionKey"], "expectedCurrentRevision": "0" * 64})["e"].startswith("This project changed after"))
    # ---- export / import
    pg.evaluate(f"Native.call('loadProject',{{key:'{key}'}}).then(p=>{{state.project=p;state.view='editor';renderEditor();}})"); pg.wait_for_timeout(1500)
    pg.evaluate("document.querySelector('[data-b=\"tab:save\"]').click()"); pg.wait_for_timeout(800)
    n0 = len(m.saved_docs)
    pg.locator('[data-export="eclp"]').first.click()
    for _ in range(400):
        if len(m.saved_docs) > n0: break
        pg.wait_for_timeout(100)
    ok(".eclp export goes to the iPhone Save dialog", len(m.saved_docs) > n0, [d["name"] for d in m.saved_docs])
    if len(m.saved_docs) > n0:
        path = OUT + "unit.eclp"; open(path, "wb").write(m.saved_docs[-1]["bytes"])
        jo = "-XX:+UnlockDiagnosticVMOptions -XX:-BytecodeVerificationRemote -XX:-BytecodeVerificationLocal -Djava.library.path=/home/claude/work/tools".split()
        r = subprocess.run(["java", *jo, "-cp", "/home/claude/work/tools/eclp-check/app.jar:/home/claude/work/tools/eclp-check/stubout:/home/claude/work/tools/eclp-check", "X", path, OUT + "eclp-out"], capture_output=True, text=True)
        ok("the Android app's decoder opens it", ".sql" in r.stdout and "forge-project.json" in r.stdout, r.stdout.splitlines()[:4] or r.stderr[-200:])
    pg.wait_for_timeout(1000)
    zr = call("export", {"name": "patch.zip", "kind": "zip", "entries": [{"path": "metadata.json", "text": "{}"}, {"path": "files/a.sql", "text": "select 1;"}]})
    ok("ZIP export (Android-only before)", zr["ok"] and m.saved_docs[-1]["bytes"][:2] == b"PK", zr)
    # import a picture (single game file) → assets, readAsset, assetUrl
    pic = OUT + "card_1000010_character.png"; open(pic, "wb").write(png(64, 48))
    pg.evaluate("void (window.__imp = Native.call('import').then(r=>window.__impR=r, e=>window.__impE=e.message))"); pg.wait_for_timeout(600)
    pg.set_input_files(".web-file-dialog input[type=file]", pic)
    for _ in range(100):
        if pg.evaluate("window.__impR||window.__impE"): break
        pg.wait_for_timeout(100)
    ir = pg.evaluate("window.__impR||window.__impE")
    ok("import a picture", isinstance(ir, dict) and ir.get("kind") == "assets", ir)
    akey = ir["asset"]["key"] if isinstance(ir, dict) and ir.get("asset") else ""
    al = call("assets", {"query": "card_1000010"})["r"]
    ok("assets list (Library → imported files)", any(a["key"] == akey for a in al), al[:2])
    ra = call("readAsset", {"key": akey})
    ok("readAsset checks the image like Android", ra["ok"] and ra["r"]["width"] == 64 and ra["r"]["height"] == 48 and ra["r"]["mime"] == "image/png", ra.get("e") or {k: ra["r"][k] for k in ("width", "height", "mime")})
    url = call("assetUrl", {"key": akey})["r"]
    ok("assetUrl loads in the app", pg.evaluate("u => fetch(u).then(r=>r.ok&&r.headers.get('content-type'))", url) == "image/png", url)
    sa = call("storeAsset", {"data": base64.b64encode(png(16, 16)).decode(), "name": "Edit"})
    ok("storeAsset (strict PNG)", sa["ok"] and sa["r"]["key"].startswith("generated-"), sa.get("e"))
    ok("storeAsset error matches Android", call("storeAsset", {"data": base64.b64encode(b"GIF89a" + b"\0" * 20).decode()})["e"] == "Artwork edits must be PNG images.")
    # ---- real Eclipse data
    da = call("downloadAsset", {"path": "character/thumb/card_1000010_thumb/card_1000010_thumb.png"})
    ok("downloadAsset from Eclipse", da["ok"] and da["r"]["size"] > 1000, da.get("e") or da["r"])
    br = call("browseAssets", {"path": "character/thumb"})
    ok("browseAssets (Eclipse folder listing)", br["ok"] and isinstance(br["r"].get("items"), list), br.get("e") or len(br["r"].get("items", [])))
    af = call("animationFiles")["r"]
    ok("animationFiles", isinstance(af, list) and len(af) > 2000, len(af) if isinstance(af, list) else af)
    src = call("animationSource", {"path": "ab_script/finish_skill/fi0001.lua"})
    ok("animationSource (downloads and keeps the script)", src["ok"] and "fcolor_r" in src["r"]["text"] and src["r"]["cached"] is False, src.get("e"))
    ok("animationSource second time is saved", call("animationSource", {"path": "ab_script/finish_skill/fi0001.lua"})["r"]["cached"] is True)
    cat = call("animationCatalog", {"search": "Kamehameha"})
    ok("animationCatalog", cat["ok"] and len(cat["r"]["items"]) > 0, cat.get("e") or cat["r"]["items"][:1])
    vis = call("animationVisuals", {"unitId": 1023571})
    ok("animationVisuals (poses for a card)", vis["ok"] and any("Battle poses" in i["name"] for i in vis["r"]["items"]), vis.get("e") or vis["r"])
    cu = call("checkUpdates")["r"]
    ok("checkUpdates (Eclipse database)", cu.get("ok") is True and cu.get("lastModified", 0) > 0, cu)
    pc = call("previewCache", {})["r"]
    ok("previewCache settings", "maxBytes" in pc and pc["maxBytes"] == 2147483648, pc)
    ok("previewCache rejects bad sizes like Android", call("previewCache", {"maxBytes": 5})["e"] == "Choose one of the preview storage sizes.")
    pt = call("previewTools", {})["r"]
    ok("previewTools status (55 player files)", pt["totalFiles"] == 55, {k: pt[k] for k in ("totalFiles", "preparedFiles", "ready")})
    ol = call("offlineLibrary", {"action": "status"})["r"]
    ok("offlineLibrary status", ol["wifiOnly"] is True and "storage" in ol and ol["network"].get("connected") is True, ol)
    # ---- Sparking (built-in catalogue)
    si = call("sparkingInfo")
    ok("sparkingInfo installs the built-in Sparking catalogue", si["ok"] and si["r"]["available"] and si["r"]["count"] > 1000 and si["r"]["meta"]["latestVersion"] == 1791992148, si.get("e") or {k: si["r"].get(k) for k in ("available", "count", "keyConfigured")})
    qs = call("querySparking", {"table": "cards", "limit": 2})
    ok("querySparking", qs["ok"] and len(qs["r"]) == 2, qs.get("e"))
    ok("updateSparking needs the Sparking APK first (same message)", call("updateSparking")["e"].startswith("Import the original Sparking 6.5.5 APK"))
    # ---- AI with your own key (key stays native)
    sv = call("aiSaveConnection", {"provider": "openai", "apiKey": "test-placeholder", "model": "gpt-5-mini"})
    ok("AI key saved natively, only a hint comes back", sv["ok"] and sv["r"]["hasKey"] and sv["r"]["keyHint"] == "…7890" and "sk-test" not in json.dumps(sv["r"]) and m.secrets.get("ai.openai") == "test-placeholder", sv)
    ok("AI key never stored in app files", not any("sk-test" in f.read_text(errors="ignore") for f in m.root.rglob("*.json")))
    st = call("aiStart", {"provider": "openai", "path": "/chat/completions", "body": {"model": "gpt-5-mini", "messages": []}})["r"]
    res = None
    for _ in range(30):
        res = call("aiPoll", {"job": st["job"]})["r"]
        if res.get("done"): break
        pg.wait_for_timeout(100)
    ok("AI request (start/poll) with the key added natively", res.get("done") and res["status"] == 200 and m.ai_log[-1]["url"] == "https://api.openai.com/v1/chat/completions" and m.ai_log[-1]["key"] == "test-placeholder", [res, m.ai_log[-1:]])
    ok("AI remove", call("aiRemoveConnection", {"provider": "openai"})["r"] == {"removed": True} and "ai.openai" not in m.secrets)
    # ---- the database update (optional: 100 MB)
    if "--sync" in sys.argv:
        t1 = time.time(); sy = call("sync")
        ok("sync: newest Eclipse database downloaded, checked and activated", sy["ok"] and sy["r"]["database"]["canRestore"] is True and sy["r"]["meta"]["sourceType"] == "eclipse-current", sy.get("e") or [sy["r"]["meta"], round(time.time() - t1)])
        rs = call("restoreDatabase")
        ok("restoreDatabase swaps back", rs["ok"] and rs["r"]["meta"]["date"] == "2026-10-14", rs.get("e") or rs["r"]["meta"])
    # ---- wipe
    w = call("wipeData", {"confirm": "DELETE", "units": True, "files": True, "downloads": True, "ai": True})
    ok("wipeData like Android", w["ok"] and w["r"] == {"units": True, "files": True, "downloads": True, "ai": True, "ok": True} and call("projects")["r"] == [], w)
    ok("wipeData needs confirmation", call("wipeData", {"units": True})["e"] == "Not confirmed.")
    ok("no page errors", not errs, errs[:3])
    ok("no failed app requests", not bad, bad[:5])
    pg.screenshot(path=OUT + "end.png")
    b.close()
print("ALL PASS" if not fails else f"{len(fails)} FAILED: {fails}")
