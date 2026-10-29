"""Stand-in for the iPhone app's native side (ios-objc/Host.m) so the iPhone version can be tested in
Chromium. Same routes (/__net, /__file, /__mirror) and the same ForgeHost / ForgeFiles messages.
The "internet" is a folder of fixtures: FAKE_NET/<host>/<path> (the sandbox can't reach the real sites).

    from ios_mock import IosMock
    m = IosMock(site_dir, fake_net_dir); ctx = m.context(browser, viewport=…); page = ctx.new_page(); page.goto(m.url)
"""
import sqlite3, urllib.request, urllib.error, http.server, threading, functools, os, json, base64, shutil, tempfile, urllib.parse, pathlib, time, mimetypes

mimetypes.add_type("text/javascript", ".js"); mimetypes.add_type("application/wasm", ".wasm"); mimetypes.add_type("text/plain", ".lua")

def xxh64(data, seed=0):
    M = (1 << 64) - 1; P1, P2, P3, P4, P5 = 11400714785074694791, 14029467366897019727, 1609587929392839161, 9650029242287828579, 2870177450012600261
    rotl = lambda x, r: ((x << r) | (x >> (64 - r))) & M
    rnd = lambda acc, lane: (rotl((acc + lane * P2) & M, 31) * P1) & M
    n = len(data); i = 0
    if n >= 32:
        v = [(seed + P1 + P2) & M, (seed + P2) & M, seed & M, (seed - P1) & M]
        while i + 32 <= n:
            for k in range(4): v[k] = rnd(v[k], int.from_bytes(data[i + 8 * k:i + 8 * k + 8], "little"))
            i += 32
        h = (rotl(v[0], 1) + rotl(v[1], 7) + rotl(v[2], 12) + rotl(v[3], 18)) & M
        for k in range(4): h = (((h ^ rnd(0, v[k])) * P1) + P4) & M
    else: h = (seed + P5) & M
    h = (h + n) & M
    while i + 8 <= n: h = ((rotl(h ^ rnd(0, int.from_bytes(data[i:i + 8], "little")), 27) * P1) + P4) & M; i += 8
    if i + 4 <= n: h = ((rotl(h ^ ((int.from_bytes(data[i:i + 4], "little") * P1) & M), 23) * P2) + P3) & M; i += 4
    while i < n: h = (rotl(h ^ ((data[i] * P5) & M), 11) * P1) & M; i += 1
    h ^= h >> 33; h = (h * P2) & M; h ^= h >> 29; h = (h * P3) & M; h ^= h >> 32
    return h

class IosMock:
    def __init__(self, site, fake_net, storage=None, real_net=False):
        self.real_net = real_net
        self.site = pathlib.Path(site); self.net = pathlib.Path(fake_net)
        self.root = pathlib.Path(storage or tempfile.mkdtemp(prefix="ios-storage-")); (self.root / "cache").mkdir(parents=True, exist_ok=True)
        self._dbs = {}; self.bundled_db = pathlib.Path(site).parent / "ios-db"
        self.ai_log = []; self.clipboard = ""; self.ai_answer = {"status": 200, "text": '{"choices":[{"message":{"content":"Connected"}}]}'}
        self.saved_docs = []
        self.secrets = {}; self.shared = []; self.saved = []; self.opened = []; self.net_log = []; self.share_answer = True
        mock = self
        class H(http.server.BaseHTTPRequestHandler):
            protocol_version = "HTTP/1.1"
            def log_message(self, *a): pass
            def send(self, status, body=b"", headers=None):
                self.send_response(status)
                h = {"Content-Type": "text/plain; charset=utf-8", "Cache-Control": "no-store", "Access-Control-Allow-Origin": "*", "Access-Control-Expose-Headers": "*"}
                h.update(headers or {}); h["Content-Length"] = str(len(body))
                for k, v in h.items(): self.send_header(k, v)
                self.end_headers()
                if self.command != "HEAD": self.wfile.write(body)
            def body(self):
                n = int(self.headers.get("Content-Length") or 0); return self.rfile.read(n) if n else b""
            def serve_file(self, f):
                if not f.is_file(): return self.send(404, b"Not found")
                data = f.read_bytes(); size = len(data); rng = self.headers.get("Range")
                h = {"Content-Type": mimetypes.guess_type(str(f))[0] or "application/octet-stream", "Accept-Ranges": "bytes"}
                if rng and rng.startswith("bytes=") and size:
                    a, _, b = rng[6:].partition("-")
                    start, end = (size - int(b), size - 1) if not a else (int(a), min(int(b), size - 1) if b else size - 1)
                    if start >= size: return self.send(416, b"", {"Content-Range": f"bytes */{size}"})
                    h["Content-Range"] = f"bytes {start}-{end}/{size}"
                    return self.send(206, data[start:end + 1], h)
                self.send(200, data, h)
            def resolve(self, rel):
                rel = urllib.parse.unquote(rel).strip("/")
                if any(p in ("..", ".") for p in rel.split("/")): return None
                return (mock.root / rel) if rel else mock.root
            def fake(self, url):
                u = urllib.parse.urlsplit(url); p = u.path.lstrip("/")
                f = mock.net / u.netloc / (p or "index.html")
                if f.is_dir(): f = f / "index.html"
                return f
            def route(self):
                u = urllib.parse.urlsplit(self.path); path = u.path
                if path == "/__net":
                    target = urllib.parse.parse_qs(u.query).get("u", [""])[0]
                    mock.net_log.append(target)
                    f = self.fake(target)
                    if f.is_file(): return self.serve_file(f)
                    if mock.real_net:
                        hdrs = {k[15:]: v for k, v in self.headers.items() if k.lower().startswith("x-forge-header-")}
                        try:
                            r = urllib.request.urlopen(urllib.request.Request(target, method=self.command, headers=hdrs), timeout=60)
                            data = r.read() if self.command != "HEAD" else b""; st = r.status; ct = r.headers.get("Content-Type", "application/octet-stream"); lm = r.headers.get("Last-Modified")
                        except urllib.error.HTTPError as e: data = e.read(); st = e.code; ct = "text/plain"; lm = None
                        h = {"Content-Type": ct, "X-Forge-Status": str(st), "X-Forge-Final-Url": target}
                        if lm: h["Last-Modified"] = lm
                        return self.send(st, data, h)
                    return self.send(404, b"not in fake internet", {"X-Forge-Status": "404"})
                if path.startswith("/__file/"):
                    f = self.resolve(path[8:])
                    if f is None: return self.send(403, b"Forbidden")
                    if self.command in ("GET", "HEAD"): return self.serve_file(f)
                    if self.command in ("PUT", "POST"):
                        data = self.body(); f.parent.mkdir(parents=True, exist_ok=True)
                        with open(f, "ab" if "append=1" in u.query and f.exists() else "wb") as fh: fh.write(data)
                        return self.send(200, json.dumps({"ok": True, "bytes": len(data)}).encode(), {"Content-Type": "application/json"})
                    if self.command == "DELETE":
                        shutil.rmtree(f, ignore_errors=True) if f.is_dir() else f.unlink(missing_ok=True)
                        return self.send(200, b'{"ok":true}')
                if path == "/__thumb":
                    u2 = urllib.parse.parse_qs(u.query).get("u", [""])[0]
                    import hashlib
                    body = mock.root / "preview-cache" / (hashlib.sha256(u2.encode()).hexdigest() + ".body")
                    if body.is_file(): return self.serve_file(body)
                    try: data = urllib.request.urlopen(urllib.request.Request(u2, headers={"User-Agent": "DokkanUnitForge/2.7"}), timeout=30).read()
                    except Exception: return self.send(404, b"Not available")
                    body.parent.mkdir(parents=True, exist_ok=True); body.write_bytes(data)
                    (body.parent / (body.name[:-5] + ".json")).write_text(json.dumps({"url": u2, "type": "image/png"}))
                    return self.send(200, data, {"Content-Type": "image/png"})
                if path.startswith("/__mirror/"):
                    rest = path[10:]; host, _, p = rest.partition("/")
                    p = urllib.parse.unquote(p) or ""
                    if not p or p.endswith("/"): p += "index.html"
                    local = mock.root / "cache/mirror" / host.lower() / p
                    if not local.is_file():
                        src = self.fake("https://" + host + "/" + p); mock.net_log.append("mirror:" + host + "/" + p)
                        if not src.is_file(): return self.send(404, b"Not available")
                        local.parent.mkdir(parents=True, exist_ok=True); shutil.copy(src, local)
                    return self.serve_file(local)
                if path == "/": path = "/index.html"
                f = (mock.site / urllib.parse.unquote(path).lstrip("/")).resolve()
                if not str(f).startswith(str(mock.site.resolve())): return self.send(403, b"Forbidden")
                self.serve_file(f)
            do_GET = do_HEAD = do_PUT = do_POST = do_DELETE = route
            def do_OPTIONS(self): self.send(204, b"", {"Access-Control-Allow-Methods": "*", "Access-Control-Allow-Headers": "*"})
        self.srv = http.server.ThreadingHTTPServer(("127.0.0.1", 0), H)
        threading.Thread(target=self.srv.serve_forever, daemon=True).start()
        self.origin = f"http://127.0.0.1:{self.srv.server_port}"
        self.url = self.origin + "/index.html"

    # ---- ForgeHost messages (same answers as Host.m) ----
    def _path(self, rel):
        rel = (rel or "").strip("/")
        if any(p in ("..", ".") for p in rel.split("/")): raise Exception("That file location isn't allowed.")
        return self.root / rel if rel else self.root
    def entry(self, name, p):
        st = p.stat(); return {"name": name, "dir": p.is_dir(), "size": 0 if p.is_dir() else st.st_size, "mtime": int(st.st_mtime * 1000)}
    def host(self, m, page=None):
        op = m.get("op"); p = self._path(m["path"]) if "path" in m else None
        if op == "info": return {"version": "2.30.1", "build": "88", "system": "26.0", "model": "iPhone", "freeBytes": 50_000_000_000, "root": str(self.root)}
        if op == "list":
            if not p.is_dir(): return []
            if m.get("deep"): return [self.entry(str(f.relative_to(p)), f) for f in p.rglob("*") if f.is_file()]
            return [self.entry(f.name, f) for f in p.iterdir()]
        if op == "stat": return self.entry(p.name, p) if p.exists() else None
        if op == "usage":
            fs = [f for f in p.rglob("*") if f.is_file() and (not m.get("suffix") or f.name.endswith(m["suffix"]))] if p.exists() else []
            return {"bytes": sum(f.stat().st_size for f in fs), "count": len(fs)}
        if op == "remove":
            if p == self.root:
                for c in p.iterdir(): shutil.rmtree(c) if c.is_dir() else c.unlink()
            elif p.is_dir(): shutil.rmtree(p)
            else: p.unlink(missing_ok=True)
            return True
        if op == "mkdir": p.mkdir(parents=True, exist_ok=True); return True
        if op == "move":
            to = self._path(m["to"]); to.parent.mkdir(parents=True, exist_ok=True)
            if to.exists(): shutil.rmtree(to) if to.is_dir() else to.unlink()
            shutil.move(str(p), str(to)); return True
        if op == "write":
            data = base64.b64decode(m["base64"]) if "base64" in m else str(m.get("text", "")).encode()
            p.parent.mkdir(parents=True, exist_ok=True)
            with open(p, "ab" if m.get("append") and p.exists() else "wb") as fh: fh.write(data)
            return len(data)
        if op == "download":
            url = m["url"]; self.net_log.append("download:" + url)
            u = urllib.parse.urlsplit(url); src = self.net / u.netloc / (u.path.lstrip("/") or "index.html")
            if not src.is_file() and self.real_net:
                try:
                    r = urllib.request.urlopen(urllib.request.Request(url, headers=m.get("headers") or {}), timeout=120)
                    data = r.read(); st = r.status; ct = r.headers.get("Content-Type", ""); lm = r.headers.get("Last-Modified")
                except urllib.error.HTTPError as e: return {"status": e.code, "saved": False, "bytes": 0, "finalUrl": url, "contentType": ""}
                p.parent.mkdir(parents=True, exist_ok=True); p.write_bytes(data)
                return {"status": st, "saved": True, "bytes": len(data), "finalUrl": url, "contentType": ct, "lastModified": lm}
            if not src.is_file():
                return {"status": 404, "saved": False, "bytes": 0, "finalUrl": url, "contentType": ""}
            p.parent.mkdir(parents=True, exist_ok=True); shutil.copy(src, p)
            if page is not None:
                page.evaluate("d => dispatchEvent(new CustomEvent('forge-host',{detail:d}))", {"type": "progress", "id": m.get("id"), "bytes": p.stat().st_size, "total": p.stat().st_size})
            return {"status": 200, "saved": True, "bytes": p.stat().st_size, "finalUrl": url, "contentType": mimetypes.guess_type(url)[0] or ""}
        if op in ("sql", "sqlBatch", "installDatabases", "sqlClose"):
            self.install_dbs()
            if op == "installDatabases": return True
            f = self._path(m.get("db", ""))
            if op == "sqlClose": self._dbs.pop(str(f), None); return True
            if not f.is_file(): raise Exception("The game database is missing.")
            key = str(f)
            if key not in self._dbs:
                con = sqlite3.connect(("file:%s?mode=ro" % f) if not m.get("writable") else str(f), uri=not m.get("writable"), check_same_thread=False)
                con.text_factory = lambda b: b.decode("utf-8", "replace")
                self._dbs[key] = con
            con = self._dbs[key]
            sqls = m.get("sqls") if op == "sqlBatch" else [m.get("sql", "")]
            res = None
            for q in sqls:
                cur = con.execute(q, m.get("params", []) if len(sqls) == 1 else [])
                cols = [d[0] for d in (cur.description or [])]
                rows = [[(v if not isinstance(v, bytes) else {"base64": base64.b64encode(v).decode()}) for v in r] for r in cur.fetchall()]
                res = {"columns": cols, "rows": rows, "changes": con.total_changes}
            if m.get("writable"): con.commit()
            return res
        if op == "sha256":
            import hashlib; h = hashlib.sha256(); n = 0
            with open(p, "rb") as fh:
                for chunk in iter(lambda: fh.read(1 << 20), b""): h.update(chunk); n += len(chunk)
            return {"sha256": h.hexdigest(), "bytes": n}
        if op == "copy":
            to = self._path(m["to"]); to.parent.mkdir(parents=True, exist_ok=True); shutil.copy(p, to); return True
        if op == "network": return {"connected": True, "metered": False}
        if op == "hashes":
            import hashlib; data = p.read_bytes()
            return {"sha256": hashlib.sha256(data).hexdigest(), "xxhash64": str(xxh64(data)), "bytes": len(data)}
        if op == "sprkDecode":
            from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
            key = bytes.fromhex(self.secrets.get("sparking.sprk", "")); data = p.read_bytes()
            if len(key) != 32: raise Exception("Import the supported Sparking APK before opening an SPRK patch.")
            if data[:5] != b"SPRK\x01": raise Exception("Unsupported Sparking patch header. Only the verified SPRK version1 format is supported.")
            d = Cipher(algorithms.AES(key), modes.CTR(data[5:21])).decryptor()
            to = self._path(m["to"]); to.parent.mkdir(parents=True, exist_ok=True); to.write_bytes(d.update(data[21:]) + d.finalize()); return True
        if op == "sprkEncode":   # same as Host.m: "SPRK" 01 IV[16] AES-256-CTR(zip); IV given (hex) or random
            from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
            key = bytes.fromhex(self.secrets.get("sparking.sprk", ""))
            if len(key) != 32: raise Exception("Set up Sparking first: Library \u203a Sparking (it needs your Sparking APK once).")
            iv = bytes.fromhex(m["iv"]) if len(m.get("iv", "")) == 32 else os.urandom(16)
            e = Cipher(algorithms.AES(key), modes.CTR(iv)).encryptor()
            to = self._path(m["to"]); to.parent.mkdir(parents=True, exist_ok=True)
            to.write_bytes(b"SPRK\x01" + iv + e.update(p.read_bytes()) + e.finalize()); return True
        if op.startswith("gameFolder"):   # same answers as Player.m -gameFolder:
            game = m.get("game"); folders = self.__dict__.setdefault("game_folders", {})
            if game not in ("sparking", "eclipse"): raise Exception("Choose Eclipse or Sparking.")
            if op == "gameFolderStatus": d = folders.get(game); return {"linked": bool(d), "ok": bool(d) and d.is_dir(), "name": d.name if d else ""}
            if op == "gameFolderUnlink": folders.pop(game, None); return True
            if op == "gameFolderLink":
                d = getattr(self, "folder_answer", {}).get(game)
                if not d: return {"linked": False}
                d.mkdir(parents=True, exist_ok=True); folders[game] = d; return {"linked": True, "name": d.name}
            if op == "gameFolderCopyIn":
                d = folders.get(game); rel = m.get("rel") or ""
                if not d: return {"linked": False}
                if not rel or rel.startswith("/") or ".." in rel or "\\" in rel: raise Exception("Bad file path.")
                src = d / rel
                if not src.is_file(): return {"linked": True, "missing": True}
                self.copied_in = getattr(self, "copied_in", []) + [rel]
                to = self._path(m["to"]); to.parent.mkdir(parents=True, exist_ok=True); to.write_bytes(src.read_bytes())
                return {"linked": True, "copied": True, "bytes": to.stat().st_size}
            if op == "gameFolderWrite":
                import hashlib
                d = folders.get(game)
                if not d: return {"linked": False}
                if not d.is_dir(): return {"linked": False, "lost": True}
                dest = d / os.path.basename(m["name"]); new = p.read_bytes(); existed = dest.exists()
                same = existed and (bool(m.get("onlyIfMissing")) or hashlib.sha256(dest.read_bytes()).digest() == hashlib.sha256(new).digest())
                if not same: dest.write_bytes(new)
                old = os.path.basename(m.get("replaces") or ""); removed = False
                if old and old != dest.name and not old.startswith(".") and (d / old).exists(): (d / old).unlink(); removed = True
                return {"linked": True, "written": not same, "existed": existed, "same": same, "removedOld": removed, "folder": d.name}
        if op == "sqlcipherDecrypt": raise Exception("SQLCipher decryption runs on the iPhone only.")
        if op == "cancel": return True
        if op == "secretHint":
            v = self.secrets.get(m["key"], "")
            return {"hasKey": bool(v), "keyHint": ("\u2026" + v[-4:]) if len(v) > 4 else ("set" if v else "")}
        if op == "aiRequest":
            self.ai_log.append({k: m.get(k) for k in ("provider", "url", "method", "body")} | {"key": self.secrets.get("ai." + m.get("provider", ""), "")})
            return self.ai_answer(m) if callable(self.ai_answer) else self.ai_answer
        if op == "aiCancel": return True
        if op == "copyText": self.clipboard = m.get("text", ""); return True
        if op == "display":
            w, h = getattr(self, "display_size", (390, 844))
            return {"window": {"width": w, "height": h}, "screen": {"width": w, "height": h}, "native": {"width": w * 3, "height": h * 3},
                    "scale": 3, "nativeScale": 3, "maxFps": 120, "safeArea": {"top": 47, "left": 0, "bottom": 34, "right": 0},
                    "orientation": 1, "idiom": 0, "machine": "mock", "system": "18.0", "memoryGB": 7.5, "cores": 6, "lowPower": False, "thermal": 0}
        if op == "secretSet":
            if m["value"]: self.secrets[m["key"]] = m["value"]
            else: self.secrets.pop(m["key"], None)
            return True
        if op == "secretDelete": self.secrets.pop(m["key"], None); return True

        if op == "saveDocument": self.saved_docs.append({"path": m["path"], "name": m.get("name"), "bytes": p.read_bytes()}); return {"saved": self.share_answer}
        if op.startswith("player") or op == "serverInfo": raise Exception("The animation player is not ready yet.")
        if op == "share": self.shared.append({"path": m["path"], "name": m.get("name"), "bytes": p.stat().st_size if p.is_file() else -1}); return self.share_answer
        if op == "openURL": self.opened.append(m["url"]); return True
        if op == "keepAwake": return True
        raise Exception("Unknown action: %s" % op)

    def install_dbs(self):
        d = self.root / "db"; d.mkdir(parents=True, exist_ok=True)
        if not self.bundled_db.is_dir(): return
        for f in self.bundled_db.glob("*.db"):
            dest = d / f.name
            if not dest.exists():
                os.symlink(f, dest)   # like the app: linked, read-only

    def context(self, browser, **kw):
        kw.setdefault("viewport", {"width": 402, "height": 874}); kw.setdefault("device_scale_factor", 3)
        kw.setdefault("is_mobile", True); kw.setdefault("has_touch", True)
        kw.setdefault("user_agent", "Mozilla/5.0 (iPhone; CPU iPhone OS 26_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148")
        ctx = browser.new_context(**kw)
        mock = self; pages = {}
        def hostcall(source, m):
            try: return {"ok": True, "value": mock.host(m, source["page"])}
            except Exception as e: return {"ok": False, "error": str(e)}
        def filescall(source, m):
            mock.saved.append({"name": m["name"], "bytes": base64.b64decode(m["base64"])})
            return mock.share_answer
        ctx.expose_binding("__iosHost", hostcall)
        ctx.expose_binding("__iosFiles", filescall)
        ctx.add_init_script("""
          window.webkit = { messageHandlers: {
            ForgeHost: { postMessage(m) { return window.__iosHost(m).then(r => { if (!r.ok) throw new Error(r.error); return r.value; }); } },
            ForgeFiles: { postMessage(m) { window.__iosFiles(m).then(saved => dispatchEvent(new CustomEvent('forge-file-saved', { detail: { id: m.id, saved } }))); } },
          } };""")
        return ctx
