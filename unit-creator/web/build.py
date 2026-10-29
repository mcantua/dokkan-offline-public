#!/usr/bin/env python3
"""Builds the web version (site/) from the Android app's screens (v2/ui) + web/src.

  python3 build.py            -> /home/claude/work/web/site
Upload everything inside site/ to a GitHub Pages repository (or any static host).
"""
import gzip, json, os, re, shutil, sqlite3, hashlib, pathlib, datetime

W = pathlib.Path("/home/claude/work")
UI = W / "v2/ui"
SRC = W / "web/src"
SITE = W / "web/site"
DB = W / "apk/assets/reference.db"   # = assets/reference.db inside the APK
# Android-only heavy parts not used by the web version yet (animation previews / movie tools)
SKIP = re.compile(r"^vendor/media/(?!preview-opponent-scenes\.js$)")
DATA_CHUNK = 700_000   # bytes (compressed) per data bundle

def build():
    if SITE.exists(): shutil.rmtree(SITE)
    SITE.mkdir(parents=True)
    n = 0
    for p in UI.rglob("*"):
        if p.is_file():
            rel = p.relative_to(UI).as_posix()
            if SKIP.match(rel): continue
            dst = SITE / rel; dst.parent.mkdir(parents=True, exist_ok=True); shutil.copy2(p, dst); n += 1
    (SITE / "web").mkdir(exist_ok=True)
    for p in SRC.iterdir():
        if p.is_file() and p.suffix in (".js", ".css") and p.name not in ("sw.js", "artifact.js") and not p.name.startswith("ios"): shutil.copy2(p, SITE / "web" / p.name)
    for p in (SRC / "static").rglob("*"):
        if p.is_file(): dst = SITE / p.relative_to(SRC / "static"); dst.parent.mkdir(parents=True, exist_ok=True); shutil.copy2(p, dst)
    # ---- game data: tables packed into ~12 compressed bundles (GitHub's upload page takes 100 files
    # at a time), grouped by when the app needs them: start + character finder, new unit, the rest.
    out = SITE / "data/db"; out.mkdir(parents=True, exist_ok=True)
    con = sqlite3.connect(DB)
    schema, packed, files, total = {}, {}, {}, 0
    names = [r[0] for r in con.execute("select name from sqlite_master where type='table' order by name") if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", r[0])]
    for t in names:
        cur = con.execute("PRAGMA table_info(\"%s\")" % t); cols = [d[0] for d in cur.description]
        schema[t] = [dict(zip(cols, r)) for r in cur.fetchall()]
        cur = con.execute('select * from "%s"' % t); rows = [[(v.decode("utf-8", "replace") if isinstance(v, bytes) else v) for v in r] for r in cur.fetchall()]
        packed[t] = json.dumps({"c": [d[0] for d in cur.description], "r": rows}, separators=(",", ":"), ensure_ascii=False)
    order = json.loads((SRC / "table-order.json").read_text())
    phases = {"start": 0, "finder": 0, "create": 1, "tabs": 2}
    seen, groups = set(), [[], [], []]
    for phase, t in order:
        if t in packed and t not in seen: seen.add(t); groups[phases.get(phase, 2)].append(t)
    groups[2] += [t for t in names if t not in seen]
    est = {t: len(gzip.compress(packed[t].encode(), 6)) for t in names}
    chunks = []
    for g in groups:
        cur, size = [], 0
        for t in g:
            if cur and size + est[t] > DATA_CHUNK: chunks.append(cur); cur, size = [], 0
            cur.append(t); size += est[t]
        if cur: chunks.append(cur)
    for i, chunk in enumerate(chunks):
        data = ("{" + ",".join(json.dumps(t) + ":" + packed[t] for t in chunk) + "}").encode()
        gz = gzip.compress(data, 9, mtime=0)
        name = "part%02d.%s.json.gz" % (i + 1, hashlib.sha256(gz).hexdigest()[:10])   # name changes when the data changes
        (out / name).write_bytes(gz); total += len(gz)
        for t in chunk: files[t] = name
    count = con.execute("select count(*) from cards").fetchone()[0]
    date = datetime.date.fromtimestamp(DB.stat().st_mtime).isoformat()
    meta_path = W / "harness/native_mock.py"
    m = re.search(r'"date": "(\d{4}-\d{2}-\d{2})"', meta_path.read_text()) if meta_path.exists() else None
    if m: date = m.group(1)
    manifest = {"schema": schema, "files": files, "bundled": True, "count": count, "date": date}
    (out / "manifest.json.gz").write_bytes(gzip.compress(json.dumps(manifest, separators=(",", ":")).encode(), 9, mtime=0))
    # ---- index.html: web pieces first, home-screen app tags, safe network rules
    html = (SITE / "index.html").read_text()
    html = html.replace('<script src="compat.js"></script>', '<script src="compat.js"></script><script src="web/argon2.js"></script><script src="web/zstd.js"></script><script src="web/eclp.js"></script><script src="web/web-native.js"></script>', 1)
    assert "web/web-native.js" in html
    html = html.replace('<link rel="stylesheet" href="perf.css">', '<link rel="stylesheet" href="perf.css"><link rel="stylesheet" href="web/web.css">', 1)
    html = html.replace("</head>", '<script src="web/web-ui.js" defer></script></head>', 1)
    # One script file for the start, one for the rest, one style file: fewer files to upload, faster start.
    keep = {"web/argon2.js"}   # also loaded by the export worker
    def bundle(pattern, kind, ext, tag, html):
        tags = list(re.finditer(pattern, html))
        assert tags, kind
        srcs = [m.group(1) for m in tags]
        parts = []
        for src in srcs:
            text = (SITE / src).read_text()
            if ext == "css" and "/" in src:   # keep relative font/image paths working from the top folder
                base = src.rsplit("/", 1)[0] + "/"
                text = re.sub(r"url\((?!data:|/|https?:)['\"]?([^'\")]+)['\"]?\)", lambda m: "url(" + base + m.group(1) + ")", text)
            parts.append("/* ---- %s ---- */\n%s\n" % (src, text))
        body = (";\n" if ext == "js" else "") + "".join(parts)
        name = "%s.%s.%s" % (kind, hashlib.sha256(body.encode()).hexdigest()[:10], ext)
        (SITE / name).write_text(body)
        first = True
        def repl(m):
            nonlocal first
            if first: first = False; return tag % name
            return ""
        html = re.sub(pattern, repl, html)
        for src in srcs:
            if src not in keep: (SITE / src).unlink()
        return html, len(srcs)
    html, n_head = bundle(r'<script src="([^"]+)"></script>', "start", "js", '<script src="%s"></script>', html)
    html, n_defer = bundle(r'<script src="([^"]+)" defer></script>', "app", "js", '<script src="%s" defer></script>', html)
    html, n_css = bundle(r'<link rel="stylesheet" href="([^"]+)">', "app", "css", '<link rel="stylesheet" href="%s">', html)
    html = html.replace("</head>", '<link rel="manifest" href="manifest.webmanifest"><link rel="apple-touch-icon" href="icons/icon-180.png"><meta name="apple-mobile-web-app-capable" content="yes"><meta name="mobile-web-app-capable" content="yes"><meta name="apple-mobile-web-app-status-bar-style" content="black-translucent"><meta name="apple-mobile-web-app-title" content="Unit Creator"><meta name="theme-color" content="#0b1230"></head>', 1)
    html = html.replace("<small>ANDROID DEVELOPMENT</small>", "<small>WEB VERSION</small>", 1)
    html = html.replace("worker-src 'self';", "worker-src 'self'; manifest-src 'self';", 1)
    (SITE / "index.html").write_text(html)
    for d in sorted((p for p in SITE.rglob("*") if p.is_dir()), key=lambda p: -len(p.parts)):
        if not any(d.iterdir()): d.rmdir()
    # ---- offline cache list for the service worker
    shell = sorted(p.relative_to(SITE).as_posix() for p in SITE.rglob("*") if p.is_file() and not p.as_posix().startswith(str(out)) and p.suffix in (".html", ".js", ".css", ".json", ".png", ".svg", ".webmanifest", ".woff2", ".ttf"))
    version = hashlib.sha256("".join(shell).encode() + json.dumps(files).encode()).hexdigest()[:12]
    sw = (SRC / "sw.js").read_text().replace("__VERSION__", version).replace("__SHELL__", json.dumps(["./"] + shell)).replace("__DATA__", json.dumps(sorted("data/db/" + n for n in set(files.values())) + ["data/db/manifest.json.gz"]))
    (SITE / "sw.js").write_text(sw)
    (SITE / ".nojekyll").write_text("")
    size = sum(p.stat().st_size for p in SITE.rglob("*") if p.is_file())
    count_files = sum(1 for p in SITE.rglob("*") if p.is_file())
    print(f"site: {count_files} files ({n_head}+{n_defer} scripts, {n_css} styles bundled; {len(files)} data tables in {len(chunks)} parts, {total/1e6:.1f} MB), total {size/1e6:.1f} MB, version {version}")
    assert count_files <= 95, "too many files for GitHub's upload page"

HOSTED = W / "web/site-artifact"

def build_artifact():
    """The same app as a Claude artifact page: no page skeleton (Claude adds it), no offline
    service worker or home-screen files, and web/artifact.js first (turns on Claude storage/saving)."""
    if HOSTED.exists(): shutil.rmtree(HOSTED)
    shutil.copytree(SITE, HOSTED)
    for junk in ["sw.js", "manifest.webmanifest", ".nojekyll"]: (HOSTED / junk).unlink(missing_ok=True)
    shutil.rmtree(HOSTED / "icons", ignore_errors=True)
    for p in HOSTED.glob("*.cjs"): p.unlink()          # Android animation tools, not used here
    shutil.copy2(SRC / "artifact.js", HOSTED / "web/artifact.js")
    import base64
    for p in list((HOSTED / "data/db").glob("*.gz")):   # hosting serves no binary data files: base64 text
        p.with_name(p.name + ".b64.txt").write_text(base64.b64encode(p.read_bytes()).decode()); p.unlink()
    for p in list(HOSTED.rglob("*")):
        if p.is_file() and not p.suffix: p.rename(p.with_name(p.name + ".txt"))   # hosting needs a file type
    html = (HOSTED / "index.html").read_text()
    head = html[html.index("<head>") + 6:html.index("</head>")]
    body = html[html.index("<body>") + 6:html.rindex("</body>")]
    title = re.search(r"<title>.*?</title>", head).group(0)
    head = head.replace(title, "")
    head = re.sub(r"<meta[^>]*>", "", head)
    head = re.sub(r'<link rel="(manifest|apple-touch-icon)"[^>]*>', "", head)
    head = head.replace("<script ", '<script src="web/artifact.js"></script><script ', 1)
    page = title + "<style>:root{color-scheme:dark}body{background:#070b1a}</style>\n" + head.strip() + "\n" + body
    (HOSTED / "index.html").write_text(page)
    files = sorted(p.relative_to(HOSTED).as_posix() for p in HOSTED.rglob("*") if p.is_file() and p.name != "index.html")
    entries = [{"path": f} if f.endswith((".js", ".css", ".json", ".txt", ".ttf")) else {"path": f, "contentType": "text/plain"} for f in files]
    (W / "web/artifact-files.json").write_text(json.dumps(entries))
    size = sum(p.stat().st_size for p in HOSTED.rglob("*") if p.is_file())
    print(f"artifact: {len(files) + 1} files, {size/1e6:.1f} MB")

IOS = W / "web/site-ios"
IOS_DB = W / "web/ios-db"
# loaded in this order right after compat.js (each builds on the ones before)
IOS_SCRIPTS = ["ios-host.js", "ios-native.js", "ios-formats.js", "ios-preview.js", "ios-player.js", "ios-assets.js", "ios-sparking.js", "ios-offline.js", "ios-io.js"]

def build_ios():
    """The iPhone app (.ipa): the WHOLE Android app screens (nothing trimmed, movie engine included),
    with the iPhone bridge (web-native.js + ios-host.js + ios-native.js) in place of the Android one.
    The game databases ship as-is (web/ios-db) and are queried with the phone's own SQLite."""
    if IOS.exists(): shutil.rmtree(IOS)
    shutil.copytree(UI, IOS)
    (IOS / "web").mkdir(exist_ok=True)
    for name in ["argon2.js", "argon2-worker.js", "zstd.js", "eclp.js", "web-native.js", "web.css"] + IOS_SCRIPTS + ["ios-ui.js", "ios.css"]:
        assert (SRC / name).exists() or name not in IOS_SCRIPTS[:6], name
        if (SRC / name).exists(): shutil.copy2(SRC / name, IOS / "web" / name)
    html = (IOS / "index.html").read_text()
    html = html.replace('<script src="compat.js"></script>', '<script src="compat.js"></script><script src="web/argon2.js"></script><script src="web/zstd.js"></script><script src="web/eclp.js"></script><script src="web/web-native.js"></script>' + "".join('<script src="web/%s"></script>' % n for n in IOS_SCRIPTS), 1)
    assert "web/ios-native.js" in html
    html = html.replace("</head>", '<link rel="stylesheet" href="web/ios.css"><script src="web/ios-ui.js" defer></script></head>', 1)
    html = html.replace("<small>ANDROID DEVELOPMENT</small>", "<small>IPHONE APP</small>", 1)
    (IOS / "index.html").write_text(html)
    m = re.search(r'"date": "(\d{4}-\d{2}-\d{2})"', (W / "harness/native_mock.py").read_text())
    date = m.group(1) if m else datetime.date.today().isoformat()
    (IOS / "web/ios-meta.json").write_text(json.dumps({"source": "Eclipse game data · " + date, "date": date}))
    IOS_DB.mkdir(parents=True, exist_ok=True)
    for name in ["reference.db", "sparking-reference.db"]:
        src = W / "apk/assets" / name
        if src.exists() and (not (IOS_DB / name).exists() or (IOS_DB / name).stat().st_mtime < src.stat().st_mtime):
            shutil.copy2(src, IOS_DB / name)
            # read-only inside the app: plain rollback journal (WAL would need side files)
            con = sqlite3.connect(IOS_DB / name); con.execute("PRAGMA journal_mode=DELETE"); con.close()
    size = sum(p.stat().st_size for p in IOS.rglob("*") if p.is_file())
    print(f"ios: {sum(1 for p in IOS.rglob('*') if p.is_file())} files, {size/1e6:.1f} MB + databases {sum(p.stat().st_size for p in IOS_DB.glob('*.db'))/1e6:.0f} MB")

if __name__ == "__main__":
    build()
    build_artifact()
    build_ios()
