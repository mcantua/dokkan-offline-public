"""Mock of CreatorActivity's native bridge, faithful to the decompiled Java for the
methods the creator flow uses. Unknown methods are logged so we can see coverage."""
import json, os, re, sqlite3, time, uuid, base64, hashlib, pathlib

UI = pathlib.Path(os.environ.get("FORGE_UI", "/home/claude/work/apk/assets/ui"))
ASSETS = pathlib.Path("/home/claude/work/apk/assets")
STATE = pathlib.Path(os.environ.get("FORGE_STATE", "/home/claude/work/harness/state"))

IDENT = re.compile(r"^[a-zA-Z_][a-zA-Z0-9_]*$")


def ident(name):
    if not IDENT.match(name):
        raise IOError("Invalid database name")
    return '"' + name + '"'


def schema_of(db):
    out = {}
    for (name,) in db.execute("SELECT name FROM sqlite_master WHERE type='table'"):
        if IDENT.match(name):
            cur = db.execute("PRAGMA table_info(" + ident(name) + ")")
            cols = [d[0] for d in cur.description]
            out[name] = [dict(zip(cols, r)) for r in cur.fetchall()]
    return out


def rows(cur):
    cols = [d[0] for d in cur.description]
    res = []
    for r in cur.fetchall():
        o = {}
        for c, v in zip(cols, r):
            if isinstance(v, bytes):
                v = v.decode("utf-8", "replace")
            o[c] = v
        res.append(o)
    return res


def java_str(v):
    """String.valueOf on org.json values."""
    if v is True:
        return "true"
    if v is False:
        return "false"
    if isinstance(v, float) and v.is_integer():
        # org.json keeps doubles like 1.0 as "1.0"; JS JSON.stringify sends ints as ints
        return repr(v)
    return str(v)


class Native:
    def __init__(self):
        STATE.mkdir(parents=True, exist_ok=True)
        (STATE / "projects").mkdir(exist_ok=True)
        (STATE / "exports").mkdir(exist_ok=True)
        self.db = sqlite3.connect(f"file:{ASSETS/'reference.db'}?mode=ro", uri=True, check_same_thread=False)
        self.sdb = sqlite3.connect(f"file:{ASSETS/'sparking-reference.db'}?mode=ro", uri=True, check_same_thread=False)
        self.schema = schema_of(self.db)
        self.sschema = schema_of(self.sdb)
        self.log = []
        self.unknown = []
        self.exports = []
        import subprocess, threading
        self._jlock = threading.Lock()
        jo = "-XX:+UnlockDiagnosticVMOptions -XX:-BytecodeVerificationRemote -XX:-BytecodeVerificationLocal -Djava.library.path=/home/claude/tools".split()
        self.jvm = subprocess.Popen(["java", *jo, "-cp", "/home/claude/work/jvm/stubout:/home/claude/work/jvm/app.jar", "com.personal.aihub.JvmBridge", str(STATE)],
                                    stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, encoding="utf-8")

    def j(self, method, args):
        with self._jlock:
            self.jvm.stdin.write(json.dumps({"method": method, "args": args}) + "\n"); self.jvm.stdin.flush()
            res = json.loads(self.jvm.stdout.readline())
        if not res["ok"]:
            self.log.append("JVMERR " + method + ": " + res["error"] + " | " + res.get("trace", "")[:600])
            raise IOError(res["error"])
        return res["result"]

    # --- query (CreatorActivity.queryDatabase) ---
    def query_db(self, db, schema, a):
        table = a["table"]
        if table not in schema:
            raise IOError("Table is not in this database.")
        names = {c["name"] for c in schema[table]}
        params, where = [], []
        for k, v in (a.get("filters") or {}).items():
            if k not in names:
                raise IOError("Unknown column")
            if v is None:
                where.append(ident(k) + " IS NULL")
            else:
                where.append(ident(k) + " = ?")
                params.append(java_str(v))
        ids = a.get("ids")
        if ids is not None:
            if len(ids) == 0:
                return []
            if len(ids) > 1000:
                raise IOError("Too many row IDs")
            where.append('"id" IN (' + ",".join("?" * len(ids)) + ")")
            params += [str(int(i)) for i in ids]
        s = a.get("search")
        if s and s.get("text"):
            if s["column"] not in names:
                raise IOError("Unknown search column")
            where.append(ident(s["column"]) + " LIKE ?")
            params.append("%" + s["text"][:200] + "%")
        order = a.get("order", "id")
        if order not in names:
            raise IOError("Unknown sort column")
        limit = max(1, min(5000, int(a.get("limit", 100))))
        offset = max(0, int(a.get("offset", 0)))
        q = "SELECT * FROM " + ident(table) + (" WHERE " + " AND ".join(where) if where else "") + " ORDER BY " + ident(order) + f" LIMIT {limit} OFFSET {offset}"
        return rows(db.execute(q, params))

    def call(self, method, args):
        self.log.append(method)
        fn = getattr(self, "m_" + method, None)
        if fn is None:
            self.unknown.append(method)
            raise IOError("Unsupported action (mock): " + method)
        return fn(args or {})

    render = {"mode": "gpu", "auto": False}
    def m_renderMode(self, a):
        if a.get("set") in ("gpu", "software"):
            type(self).render = {"mode": a["set"], "auto": False}
        return dict(type(self).render)

    def m_info(self, a):
        return {"schema": self.schema, "count": self.db.execute("select count(*) from cards").fetchone()[0],
                "meta": {"source": "Bundled Eclipse English snapshot · 2026-10-14", "date": "2026-10-14"},
                "database": {"canRestore": False}}

    def m_query(self, a):
        return self.query_db(self.db, self.schema, a)

    def m_cardIndex(self, a):
        # mirrors ForgeFixes.cardIndex
        if os.environ.get("MOCK_NO_CARDINDEX") == "1": raise IOError("Unsupported action (mock): cardIndex")
        cols = {c["name"] for c in self.schema["cards"]}
        want = ["id", "name", "rarity", "element", "open_at", "hp_max", "atk_max", "def_max", "resource_id", "passive_skill_set_id", "leader_skill_set_id", "optimal_awakening_grow_type"]
        sel = ",".join('"%s"' % c if c in cols else "NULL" for c in want)
        out = []
        for r in self.db.execute("SELECT " + sel + " FROM cards WHERE id % 10 = 1 AND ((id >= 1000000 AND id < 3000000) OR id >= 10000000) AND hp_max > 300 AND passive_skill_set_id IS NOT NULL AND leader_skill_set_id IS NOT NULL ORDER BY id"):
            r = list(r); o = str(r[4] or "")[:10].replace("-", "")
            out.append([r[0], r[1] or "", r[2] or 0, r[3] or 0, int(o) if len(o) == 8 and o.isdigit() else 0, r[5] or 0, r[6] or 0, r[7] or 0, r[8] or 0, r[9], r[10], r[11]])
        return out

    def m_querySparking(self, a):
        return self.query_db(self.sdb, self.sschema, a)

    def m_sparkingInfo(self, a):
        return {"available": True, "keyConfigured": False, "count": self.sdb.execute("select count(*) from cards").fetchone()[0],
                "schema": self.sschema, "meta": {"source": "Sparking game database · built-in snapshot", "sourceType": "sparking-bundled",
                                                 "date": "2026-10-17", "latestVersion": 1791992148}}

    def m_projects(self, a):
        out = []
        for f in sorted((STATE / "projects").glob("*.json")):
            try:
                p = json.loads(f.read_text())
                c = p["tables"]["cards"][0]
                o = p.get("cardOverrides")
                g = (lambda k, d=None: (o or {}).get(k, c.get(k, d)))
                reserved = self.j("reservedIds", p)
                out.append({"key": p["key"], "name": g("name", ""), "targetId": p["targetId"], "reservedIds": reserved,
                            "updatedAt": p.get("updatedAt", ""), "rarity": g("rarity", 0), "element": g("element", 0),
                            "resourceId": g("resource_id", 0), "origin": p.get("libraryOrigin", "created"),
                            "sparkingAnimations": bool((p.get("sourceDependencies") or {}).get("animations")),
                            "sourceDatabase": (p.get("source") or {}).get("database", ""), "author": p["patch"].get("author", "")})
            except Exception as e:
                self.log.append("projects-skip:" + str(e))
        return out

    def _pfile(self, key):
        if not re.fullmatch(r"[a-zA-Z0-9_-]{1,100}", key or ""):
            raise IOError("Invalid project key")
        return STATE / "projects" / (key + ".json")

    def m_loadProject(self, a):
        return json.loads(self._pfile(a["key"]).read_text())

    def m_saveProject(self, a):
        p = a["project"]
        if p.get("format") != "dokkan-unit-forge":
            raise IOError("Unsupported project")
        f = self._pfile(p["key"])
        data = json.dumps(p, separators=(",", ":"))
        f.write_text(data)
        return {"saved": True, "revision": hashlib.sha256(data.encode()).hexdigest()}


    def m_export(self, a):
        name = a.get("name", "export.bin")
        out = STATE / "exports" / (str(len(self.exports)) + "-" + re.sub(r"[^A-Za-z0-9_.-]", "_", name) + ".request.json")
        out.write_text(json.dumps(a, indent=1))
        self.exports.append(str(out))
        if a.get("kind") in ("eclp", "zip") and "entries" in a:
            j = dict(a); j["out"] = str(out).replace(".request.json", "")
            self.j("export", j)
        return {"saved": True, "name": name}



    def m_patches(self, a):
        return []

    def m_animationFiles(self, a):
        idx = json.loads((UI / "data" / "preview-script-index.json").read_text())
        out = set()
        for s in idx["scripts"]:
            p = s.get("path") if isinstance(s, dict) else s
            if isinstance(p, str) and re.fullmatch(r"(?i)ab_script/[a-z0-9_/-]+\.lua", p): out.add(p)
        return sorted(out)

    def m_animationCatalog(self, a):
        sparking = a.get("sourceDatabase") == "sparking"
        db, schema = (self.sdb, self.sschema) if sparking else (self.db, self.schema)
        qs = [q["sql"] for q in json.loads((UI / "data" / "animation-queries.json").read_text()) if all(t in schema for t in q["tables"])]
        if not qs: return {"items": [], "more": False}
        params, where = [], []
        s = (a.get("search") or "")[:100]
        if s: where.append("(unitName LIKE ? OR moveName LIKE ?)"); params += ["%"+s+"%"]*2
        k = a.get("kind", "all")
        if k != "all": where.append("kind=?"); params.append(k)
        if int(a.get("unitId") or 0) > 0: where.append("unitId=?"); params.append(str(int(a["unitId"])))
        off = max(0, min(100000, int(a.get("offset") or 0)))
        sql = "SELECT * FROM (" + " UNION ALL ".join(qs) + ")" + (" WHERE " + " AND ".join(where) if where else "") + " ORDER BY unitId=0, unitName, moveName, unitId, key LIMIT ? OFFSET ?"
        r = rows(db.execute(sql, params + ["13", str(off)]))
        if sparking:
            for x in r: x["sourceDatabase"] = "sparking"
        more = len(r) > 12
        return {"items": r[:12], "more": more, "offset": off}

    def m_animationSource(self, a):
        # Like the device: the Eclipse CDN only has the published files, anything else is a 404.
        if a.get("sourceDatabase") != "sparking" and a["path"] not in set(self.m_animationFiles({})):
            raise IOError("Eclipse returned HTTP 404. You can import a local database or resource pack instead.")
        if os.environ.get("REAL_LUA"):
            import random
            rnd = random.Random(a["path"])
            lines = ["SP_%02d=\t%d\t;--fx" % (i, 155900 + rnd.randint(0, 99)) for i in range(1, 9)]
            lines += ["spep_0 = 0;", "setMoveKey( spep_0, 0, 0, 0, 0 );"]
            for f in range(0, 600, 2):
                lines.append("setMoveKey( spep_0 + %d, 0, %d, %d, 0 );" % (f, rnd.randint(-300, 300), rnd.randint(-300, 300)))
                lines.append("eff%d = entryEffect( spep_0 + %d, SP_0%d, 0x100, -1, 0, %d, %d );" % (f, f, 1 + f % 8, rnd.randint(-99, 99), rnd.randint(-99, 99)))
                lines.append("setEffScaleKey( spep_0 + %d, eff%d, 1.0, 1.0 );  -- scale" % (f, f))
            lines.append("endPhase( spep_0 + 600 );")
            return {"path": a["path"], "text": "\n".join(lines) + "\n", "cached": True}
        return {"path": a["path"], "text": "-- mock lua\nfunction main() end\n", "cached": True}

    def m_previewAnimation(self, a):
        self.last_preview = a
        return {"opened": True, "online": True}

    def m_textZoom(self, a):
        self.text_zoom = int(a.get("percent", 100)); return {"percent": self.text_zoom}

    def m_previewDock(self, a):
        st = getattr(self, "dock", {"open": False, "full": False, "separateWindow": False, "smooth": True, "quality": "auto", "startFull": True})
        act = a.get("action", "status")
        if act == "set" and "separateWindow" in a: st["separateWindow"] = bool(a["separateWindow"])
        if act == "set" and "smooth" in a: st["smooth"] = bool(a["smooth"])
        if act == "set" and "quality" in a: st["quality"] = a["quality"] if a["quality"] in ("auto", "smooth", "best") else "auto"
        if act == "set" and "startFull" in a: st["startFull"] = bool(a["startFull"])
        handled = st["open"] and act in ("close", "back", "full", "dock", "toggle")
        if handled:
            if act in ("close", "back"): st["open"] = False; st["full"] = False
            elif act == "dock": st["full"] = False
            elif act == "full": st["full"] = True
        self.dock = st
        self.dock_calls = getattr(self, "dock_calls", []) + [act]
        self.dock_args = getattr(self, "dock_args", []) + [dict(a)]
        return {**st, "handled": handled, "dockable": not st["separateWindow"]}

    def m_offlineLibrary(self, a):
        o = getattr(self, "offline", None) or {"wifiOnly": True, "movies": False, "completed": {}, "job": None}
        self.offline = o
        act = a.get("action", "status")
        self.offline_calls = getattr(self, "offline_calls", []) + [{k: (v if k not in ("cards", "scripts") else len(v)) for k, v in a.items()}]
        j = o["job"]
        if act == "start":
            if j and j["running"]: raise IOError("A download is already running. Pause or cancel it first.")
            o["wifiOnly"] = a.get("wifiOnly", True); o["movies"] = a.get("movies", False)
            o["job"] = j = {"running": True, "paused": False, "cancelled": False, "finished": False, "phase": "Animation scripts", "label": "sp0001.lua",
                            "waiting": "", "total": 100, "done": 0, "failed": 0, "skipped": 0, "savedBytes": 0, "error": "", "packs": a["packs"],
                            "startedAt": 0, "finishedAt": 0, "failures": []}
        elif act == "pause" and j: j["paused"] = True
        elif act == "resume" and j: j["paused"] = False
        elif act == "cancel" and j: j.update(running=False, cancelled=True, finished=True, phase="Cancelled")
        elif act == "wifiOnly": o["wifiOnly"] = a.get("value", True)
        elif act == "status" and j and j["running"] and not j["paused"]:
            j["done"] = min(j["total"], j["done"] + 25); j["savedBytes"] += 30 * 1048576
            if j["done"] >= j["total"]:
                j.update(running=False, finished=True, phase="Done")
                for p in j["packs"]: o["completed"][p] = {"at": 1761300000000, "failed": 0}
        return {"wifiOnly": o["wifiOnly"], "movies": o["movies"], "completed": o["completed"], "network": {"connected": True, "metered": False},
                "job": j, "storage": {"bytes": (j or {}).get("savedBytes", 0), "maxBytes": 2147483648, "free": 20 * 1073741824}}

    def m_previewTools(self, a):
        return {"ok": True}

    def m_animationVisuals(self, a):
        return {"items": []}

    def m_previewCache(self, a):
        if "offline" in a: self.cache_offline = bool(a["offline"])
        return {"offline": getattr(self, "cache_offline", False), "bytes": 0, "count": 0, "maxBytes": 2147483648}

    def m_importStatus(self, a):
        return {}

    def m_copy(self, a):
        return {"copied": True}

    def m_external(self, a):
        return {"opened": True}

    def m_assetUrl(self, a):
        return "https://forge.local/local-asset/" + a["key"]

    def m_storeAsset(self, a):
        return self.j('storeAsset', a)

    def m_readAsset(self, a):
        return self.j('readAsset', a)

    def m_storeDecoration(self, a):
        return self.j('storeDecoration', a)

    def m_storeLwf(self, a):
        return self.j('storeLwf', a)

    def m_assetStatus(self, a):
        return self.j('assetStatus', a)

    def m_listProjectVersions(self, a):
        return self.j('listProjectVersions', a)

    def m_saveProjectVersion(self, a):
        return self.j('saveProjectVersion', a)

    def m_loadProjectVersion(self, a):
        return self.j('loadProjectVersion', a)

    def m_restoreProjectVersion(self, a):
        return self.j('restoreProjectVersion', a)

    def m_downloadAsset(self, a):
        f = STATE / "assets" / a["path"]
        if not f.is_file(): raise IOError("Eclipse returned HTTP 404. You can import a local database or resource pack instead.")
        return {"key": a["path"], "path": a["path"], "size": f.stat().st_size}

    def m_storeMovie(self, a):
        import base64, uuid, subprocess
        ups = self.__dict__.setdefault("movie_uploads", {})
        act = a.get("action")
        if act == "begin":
            uid = uuid.uuid4().hex; ups[uid] = {"name": a.get("name", ""), "data": bytearray()}; return {"uploadId": uid}
        up = ups.get(a.get("uploadId"))
        if up is None: raise IOError("Invalid movie upload.")
        if act == "append":
            if a["offset"] != len(up["data"]): raise IOError("Out of order")
            up["data"] += base64.b64decode(a["data"]); return {"bytes": len(up["data"])}
        if act == "cancel": ups.pop(a["uploadId"], None); return {"cancelled": True}
        if act == "finish":
            ups.pop(a["uploadId"], None)
            tag = uuid.uuid4().hex; d = STATE / "assets" / tag; d.mkdir(parents=True, exist_ok=True); (d / "movie.usm").write_bytes(bytes(up["data"]))
            meta = json.loads(subprocess.run(["node", "-e", "const I=require('" + str(UI / "movie-input.js") + "');const m=I.readMovie(new Uint8Array(require('fs').readFileSync(process.argv[1])));console.log(JSON.stringify({width:m.width,height:m.height,frames:m.frames,rate:m.rate}))", str(d / "movie.usm")], capture_output=True, text=True, check=True).stdout)
            self.last_movie = d / "movie.usm"
            return {**meta, "storageTag": tag, "key": tag + "/movie.usm", "path": "movie.usm", "size": len(up["data"]), "name": up["name"], "image": False}
        raise IOError("Invalid movie upload action.")

    def m_assets(self, a):
        return self.j('assets', a)

    def m_sync(self, a):
        if os.environ.get("MOCK_SYNC_OK") != "1": raise IOError("Unsupported action (mock): sync")
        info = self.m_info({}); info["meta"] = {"source": "Eclipse download", "date": "2026-10-24"}; return info

    def m_checkUpdates(self, a):
        return {"ok": True, "status": 200, "lastModified": 1792800000000, "size": 104857600}

    def m_wipeData(self, a):
        import shutil
        if a.get("confirm") != "DELETE": raise IOError("Not confirmed.")
        done = {"ok": True}
        if a.get("units"):
            shutil.rmtree(STATE / "projects", ignore_errors=True); shutil.rmtree(STATE / "project-versions", ignore_errors=True); (STATE / "projects").mkdir(parents=True, exist_ok=True); done["units"] = True
        if a.get("files"):
            for n in ("assets", "lwf", "patches", "animation-sources"): shutil.rmtree(STATE / n, ignore_errors=True)
            (STATE / "assets").mkdir(parents=True, exist_ok=True); done["files"] = True
        if a.get("downloads"): done["downloads"] = True
        if a.get("ai"): done["ai"] = True
        self.wiped = done
        return done

    def m_deleteProject(self, a):
        key = a.get("key", "")
        if not re.fullmatch(r"[a-zA-Z0-9_-]{1,100}", key): raise IOError("Invalid project key")
        f = STATE / "projects" / (key + ".json")
        if not f.is_file(): raise IOError("This unit is no longer saved on this device.")
        f.unlink()
        import shutil; shutil.rmtree(STATE / "project-versions" / key, ignore_errors=True)
        return {"deleted": True, "key": key}


# ---- AI connection mock (mirrors ForgeAi.java behavior with canned provider replies) ----
import base64 as _b64, io as _io
def _png(w=96, h=144):
    from PIL import Image
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for x in range(20, 76):
        for y in range(20, 124): im.putpixel((x, y), (240, 120, 20, 255))
    b = _io.BytesIO(); im.save(b, "PNG"); return _b64.b64encode(b.getvalue()).decode()
AI_ACTIONS = {"actions": [
    {"do": "basics", "name": "AI Test Gogeta", "rarity": "LR", "class": "Super", "type": "AGL", "hp": 21000, "atk": 22000, "def": 13000},
    {"do": "leader", "groups": [{"who": "categories", "categories": ["Fusion"], "ki": 3, "hp": 170, "atk": 170, "def": 170}, {"who": "categories", "categories": ["Fusion"], "also": ["Potara"], "ki": 1, "hp": 30, "atk": 30, "def": 30}]},
    {"do": "passive", "name": "Fused Fighting Spirit", "replace": True, "abilities": [
        {"ability": "atkdef", "values": {"atk": 200, "def": 200}},
        {"ability": "ki", "values": {"amount": 3}},
        {"ability": "additional", "values": {"super": 50}, "when": "attacking", "conditions": [{"rule": "turn", "turn": 4}]},
        {"ability": "dr", "values": {"amount": 40}, "conditions": [{"rule": "allies", "category": "Fusion", "count": 2}], "match": "all"}]},
    {"do": "super", "which": "ultra", "name": "Big Bang Kamehameha", "damage": "mega-colossal", "effects": [{"effect": "atk", "values": {"amount": 100}, "who": "self", "turns": 99}]},
    {"do": "active", "kind": "attack", "name": "Ultimate Fusion Strike", "boost": 200, "conditions": [{"rule": "turn", "turn": 4}]},
    {"do": "links", "links": ["Fused Fighter", "Super Saiyan"]},
    {"do": "categories", "categories": ["Fusion", "Pure Saiyans"]},
    {"do": "art", "prompt": "Gogeta powering up"}]}
def _reply_text(body):
    text = json.dumps(body)
    if "Reply with exactly: Connected" in text: return "Connected"
    if "Rewrite this as one vivid" in text: return "A heroic fused warrior bursting with blue aura"
    return "Here is a full LR design.\n```json\n" + json.dumps(AI_ACTIONS) + "\n```"
def m_aiConnections(self, a):
    st = getattr(self, "_ai", {}); return {"connections": [dict(provider=k, hasKey=True, keyHint="…test", model=v.get("model", ""), imageModel=v.get("imageModel", ""), baseUrl=v.get("baseUrl", "")) for k, v in st.items()], "active": getattr(self, "_ai_active", "")}
def m_aiSaveConnection(self, a):
    self._ai = getattr(self, "_ai", {}); c = self._ai.get(a["provider"], {})
    if a["provider"] != "custom" and not a.get("apiKey") and not c: raise IOError("Paste your API key to connect " + a["provider"] + ".")
    c.update({k: a[k] for k in ("model", "imageModel", "baseUrl") if k in a}); self._ai[a["provider"]] = c; self._ai_active = a["provider"]
    self.ai_log = getattr(self, "ai_log", []); self.ai_log.append(("save", a["provider"])); return {"provider": a["provider"], "hasKey": True}
def m_aiRemoveConnection(self, a):
    getattr(self, "_ai", {}).pop(a["provider"], None); return {"removed": True}
def m_aiStart(self, a):
    self.ai_log = getattr(self, "ai_log", []); self.ai_log.append((a["provider"], a["path"], a.get("method")))
    p, path, body = a["provider"], a["path"], a.get("body") or {}
    if path.startswith("/models") and a.get("method") == "GET": res = {"data": [{"id": "model-a"}, {"id": "gpt-image-1.5"}]} if p != "gemini" else {"models": [{"name": "models/gemini-x", "supportedGenerationMethods": ["generateContent"]}, {"name": "models/gemini-3.1-flash-image"}]}
    elif path == "/images/generations": res = {"data": [{"b64_json": _png()}]}
    elif p == "gemini" and "IMAGE" in json.dumps(body.get("generationConfig", {})): res = {"candidates": [{"content": {"parts": [{"inlineData": {"mimeType": "image/png", "data": _png()}}]}}]}
    elif p == "gemini": res = {"candidates": [{"content": {"parts": [{"text": _reply_text(body)}]}}]}
    elif p == "anthropic": res = {"content": [{"type": "text", "text": _reply_text(body)}]}
    else: res = {"choices": [{"message": {"content": _reply_text(body)}}]}
    self._ai_jobs = getattr(self, "_ai_jobs", {}); jid = str(len(self._ai_jobs) + 1); self._ai_jobs[jid] = res
    return {"job": jid}
def m_aiPoll(self, a):
    res = self._ai_jobs.pop(a["job"], None)
    if res is None: raise IOError("This AI request is no longer available. Try again.")
    return {"done": True, "status": 200, "text": json.dumps(res)}
def m_aiCancel(self, a): return {"canceled": True}
for _n, _f in list(globals().items()):
    if _n.startswith("m_ai"): setattr(Native, _n, _f)
