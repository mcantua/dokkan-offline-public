"""Focused Sparking delta-integrity and real browser catalog/template check. No native keys needed."""
import base64
import functools
import gzip
import http.server
import json
import os
import pathlib
import shutil
import sqlite3
import tempfile
import threading
from playwright.sync_api import sync_playwright
import build

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[1]

def pack_db(database):
    con = sqlite3.connect("file:" + str(database) + "?mode=ro", uri=True)
    packed, schema = {}, {}
    for (name,) in con.execute("select name from sqlite_master where type='table' order by name").fetchall():
        cur = con.execute('PRAGMA table_info("%s")' % name)
        schema[name] = [dict(zip([c[0] for c in cur.description], row)) for row in cur.fetchall()]
        cur = con.execute('select * from "%s"' % name)
        rows = [[v.decode("utf-8", "replace") if isinstance(v, bytes) else v for v in row] for row in cur.fetchall()]
        packed[name] = json.dumps({"c": [c[0] for c in cur.description], "r": rows}, ensure_ascii=False, separators=(",", ":"))
    con.close()
    return packed, schema

class Quiet(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *args): pass

with tempfile.TemporaryDirectory(prefix=".sparking-browser-", dir=HERE) as temp:
    folder = pathlib.Path(temp)
    packed, schema = pack_db(HERE.parent / "apk/assets/reference.db")
    spark = build.build_sparking_delta(packed, folder / "data/sparking-db")
    assert spark and spark["count"] == 19308
    cache = {}
    with sqlite3.connect("file:" + str(HERE.parent / "apk/assets/sparking-reference.db") + "?mode=ro", uri=True) as con:
        for name in spark["schema"]:
            file = spark["files"][name]
            if file not in cache: cache[file] = json.loads(gzip.decompress((folder / "data/sparking-db" / file).read_bytes()))
            delta = cache[file][name]
            if delta.get("base"):
                base = json.loads(packed[name])["r"]
                rebuilt = []
                for row in delta["r"]:
                    if isinstance(row, int): rebuilt.append(base[row])
                    elif row[0] == -1: rebuilt.append(row[1:])
                    else:
                        changed = base[row[0]][:]
                        for i in range(1, len(row), 2): changed[row[i]] = row[i + 1]
                        rebuilt.append(changed)
            else: rebuilt = delta["r"]
            original = [[v.decode("utf-8", "replace") if isinstance(v, bytes) else v for v in row] for row in con.execute('select * from "%s"' % name)]
            assert rebuilt == original, name
        base_ids = {row[0] for row in json.loads(packed["cards"])["r"]}
        candidates = [{"id": row[0], "name": row[1]} for row in con.execute("select id,name from cards where id % 10=1 and hp_max>300 and passive_skill_set_id is not null and leader_skill_set_id is not null") if row[0] not in base_ids]
    print("PASS: all 233 delta tables reconstruct the supplied Sparking rows exactly", flush=True)
    (folder / "data/db").mkdir(parents=True)
    main = {"schema": schema, "files": {name: "all.json.gz" for name in packed}, "bundled": True, "count": 17786, "date": "2026-10-14", "sparkingAvailable": True, "sparkingSnapshotId": spark["snapshotId"]}
    (folder / "data/db/manifest.json.gz").write_bytes(gzip.compress(json.dumps(main).encode()))
    (folder / "data/db/all.json.gz").write_bytes(gzip.compress(("{" + ",".join(json.dumps(name) + ":" + value for name, value in packed.items()) + "}").encode()))
    for file in list((folder / "data").rglob("*.gz")):
        file.with_name(file.name + ".b64.txt").write_text(base64.b64encode(file.read_bytes()).decode())
    os.link(ROOT / "test-page/UnitCreator-test.html", folder / "check.html")
    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), functools.partial(Quiet, directory=folder))
    threading.Thread(target=server.serve_forever, daemon=True).start()
    base = f"http://127.0.0.1:{server.server_port}/"
    try:
        with sync_playwright() as p:
            browser = p.chromium.launch(executable_path=shutil.which("chromium"))
            page = browser.new_page(viewport={"width": 430, "height": 932})
            page.route("**/*", lambda r: r.continue_() if r.request.url.startswith((base, "data:", "blob:")) else r.abort())
            page.goto(base + "check.html", wait_until="domcontentloaded")
            page.wait_for_function("window.__forgeWorkspaceStartup==='ready'", timeout=60000)
            page.evaluate("document.querySelectorAll('dialog[open]').forEach(d=>d.close())")
            page.evaluate("base=>{const original=window.fetch;window.fetch=(input,options)=>{const u=String(input);return original(u.startsWith(window.__forgeStandaloneBase+'data/')?base+u.slice(window.__forgeStandaloneBase.length):input,options);};}", base)
            page.add_script_tag(content=(HERE / "src/web-native.js").read_text())
            page.add_script_tag(content=(HERE.parent / "v2/ui/card-versions.js").read_text())
            page.add_script_tag(content=(HERE.parent / "v2/ui/sparking-content.js").read_text())
            page.add_style_tag(content=(HERE / "src/web.css").read_text())
            info = page.evaluate("async()=>{state.info=await Native.call('info');return Native.call('sparkingInfo');}")
            assert info["available"] and info["count"] == 19308 and not info["keyConfigured"]
            chosen = page.evaluate("async candidates=>{await ForgeCardVersions.load('sparking');for(const c of candidates){const id=ForgeCardVersions.finalId(c.id,'sparking');const row=(await Native.call('querySparking',{table:'cards',ids:[id],limit:1}))[0];if(row&&ForgeCardVersions.isPlayerCard(row,'sparking')){const catalog=await Native.call('sparkingCatalog',{search:row.name,offset:0,limit:120});if(catalog.items.some(x=>x.id===id))return {id,name:row.name,catalog};}}throw Error('No Sparking-only playable card found');}", candidates)
            ids = [row["id"] for row in chosen["catalog"]["items"]]
            assert len(ids) == len(set(ids))
            assert page.evaluate("rows=>rows.every(c=>ForgeCardVersions.finalId(c.id,'sparking')===c.id)", chosen["catalog"]["items"])
            page.evaluate("navigate('library')")
            page.locator('[data-library-filter="sparking"]').click()
            search = page.locator('[data-sparking-unit-search]')
            search.wait_for(timeout=60000); search.fill(chosen["name"])
            button = page.locator(f'[data-sparking-copy="{chosen["id"]}"]')
            button.wait_for(timeout=60000); button.click()
            page.wait_for_function("state.view==='editor'&&state.project?.source?.database==='sparking'&&document.getElementById('busy').hidden", timeout=60000)
            assert page.evaluate("state.project.source.cardId") == chosen["id"]
            assert page.evaluate("state.project.provenance.sourceSnapshot") == spark["snapshotId"]
            assert page.evaluate("Native.call('loadProject',{key:state.project.key}).then(p=>p.source.database)") == "sparking"
            page.set_viewport_size({"width": 951, "height": 669})
            assert page.evaluate("document.documentElement.scrollWidth<=innerWidth+1")
            print("PASS: offline Sparking-only catalog search, awakened/deduplicated choices, real editable template, save and inner layout", flush=True)
            browser.close()
    finally: server.shutdown()
