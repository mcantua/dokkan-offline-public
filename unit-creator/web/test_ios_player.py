"""End to end: an animation preview in the iPhone build, against the REAL Eclipse player.
Stands in for the iPhone's native side (ios-objc/Player.m): a private HTTP server on 127.0.0.1 that
hands every request to ForgePreviewServer.handle in the main page, a second page as the player panel,
and the player* actions. Usage: python3 test_ios_player.py [animation path]"""
import asyncio, json, os, sys, re, base64, time, pathlib
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ios_mock import IosMock
from playwright.async_api import async_playwright

OUT = "/tmp/claude-0/iostest/player/"; os.makedirs(OUT, exist_ok=True)
fails = []
def ok(n, c, x=""):
    print(("PASS " if c else "FAIL ") + n, x if not isinstance(x, str) else x[:300]); sys.stdout.flush()
    if not c: fails.append(n)
SEC = {"Cache-Control": "no-store", "Cross-Origin-Opener-Policy": "same-origin", "Cross-Origin-Embedder-Policy": "require-corp",
       "Cross-Origin-Resource-Policy": "same-origin", "X-Content-Type-Options": "nosniff", "Referrer-Policy": "no-referrer",
       "Content-Security-Policy": "default-src 'self' data: blob:; script-src 'self' 'unsafe-inline' 'unsafe-eval' blob:; connect-src 'self' blob:; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; media-src 'self' blob: data:; worker-src 'self' blob:; frame-src 'none'; object-src 'none'; base-uri 'self'; form-action 'none'"}

class Native:
    def __init__(self, mock): self.mock = mock; self.main = None; self.player = None; self.port = 0; self.log = []; self.layout = "closed"; self.notes = []; self.overlay = None; self.requests = []; self.status = {}
    async def serve(self, reader, writer):
        try:
            head = await reader.readuntil(b"\r\n\r\n")
            lines = head.decode().split("\r\n")[:-2]
            method, target, _ = lines[0].split(" ")
            headers = {}
            for l in lines[1:]:
                k, _, v = l.partition(":"); headers[k.strip().lower()] = v.strip()
            req = {"method": method, "target": target, "headers": headers}
            n = int(headers.get("content-length") or 0)
            if n:
                body = await reader.readexactly(n)
                rel = "cache/uploads/%d-%s.bin" % (time.time_ns(), os.urandom(4).hex())
                p = self.mock.root / rel; p.parent.mkdir(parents=True, exist_ok=True); p.write_bytes(body)
                req["bodyFile"] = rel; req["bodyLength"] = len(body)
            ans = await self.main.evaluate("r => window.ForgePreviewServer.handle(r)", req)
            if req.get("bodyFile") and not ans.get("keepBody"): (self.mock.root / req["bodyFile"]).unlink(missing_ok=True)
            st = ans.get("status") or 200
            self.requests.append((method, target, st)); self.status[st] = self.status.get(st, 0) + 1
            if "file" in ans:
                f = ans["file"]
                path = (self.mock.site / f[5:]) if f.startswith("site:") else (self.mock.root / f)
                data = path.read_bytes() if path.is_file() else None
                if data is None: st, data = 404, b"Not found"
            elif "base64" in ans: data = base64.b64decode(ans["base64"])
            else: data = (ans.get("body") or "").encode()
            h = dict(ans.get("headers") or {})
            rng = headers.get("range") if ans.get("range") else None
            if rng and st == 200 and data:
                m = re.match(r"^bytes=(\d*)-(\d*)$", rng); total = len(data)
                if m and (m.group(1) or m.group(2)):
                    a, b = m.group(1), m.group(2)
                    s, e = (max(0, total - int(b)), total - 1) if not a else (int(a), min(int(b), total - 1) if b else total - 1)
                    if s < total and s <= e: st = 206; h["Content-Range"] = "bytes %d-%d/%d" % (s, e, total); data = data[s:e + 1]
            out = "HTTP/1.1 %d Response\r\n" % st
            for k, v in h.items():
                if k.lower() not in ("content-length", "connection"): out += "%s: %s\r\n" % (k, v)
            out += "Content-Length: %d\r\nConnection: close\r\n" % (0 if method == "HEAD" else len(data))
            for k, v in SEC.items():
                if k not in h: out += "%s: %s\r\n" % (k, v)
            writer.write(out.encode() + b"\r\n" + (b"" if method == "HEAD" else data))
            await writer.drain()
        except Exception as e:
            self.log.append("serve error: %r" % e)
        finally:
            writer.close()
    async def emit(self, d):
        d = dict(d); d["type"] = "player"
        try: await self.main.evaluate("d => dispatchEvent(new CustomEvent('forge-host',{detail:d}))", d)
        except Exception as e: self.log.append("emit %r" % e)
    async def op(self, m):
        op = m["op"]
        if op == "serverInfo": return {"port": self.port, "origin": "http://127.0.0.1:%d" % self.port}
        if op == "playerOpen":
            self.layout = "full" if m.get("full") else "docked"; self.opened = m
            asyncio.ensure_future(self.player.goto(m["url"]))
            return True
        if op == "playerLayout":
            if m["mode"] == "closed": asyncio.ensure_future(self.player.goto("about:blank"))
            self.layout = m["mode"]; await self.emit({"event": "mode", "mode": self.layout}); return self.layout
        if op == "playerEval": return await self.player.evaluate(m["script"])
        if op == "playerNote": self.notes.append(m.get("text")); return True
        if op == "playerOverlay": self.overlay = m; return True
        if op in ("playerBar", "playerCookieClear"): return True
        if op == "playerSnapshot":
            r = await self.player.evaluate("""(()=>{const e=document.getElementById('stage');if(!e)return null;const r=e.getBoundingClientRect();return {x:r.x,y:r.y,width:r.width,height:r.height}})()""")
            if not r: raise Exception("Keep the complete animation stage visible before recording.")
            png = await self.player.screenshot(clip=r)
            rel = "cache/uploads/stage-%s.png" % os.urandom(6).hex(); (self.mock.root / rel).parent.mkdir(parents=True, exist_ok=True); (self.mock.root / rel).write_bytes(png)
            return {"file": rel, "bytes": len(png)}
        if op == "saveDocument": self.saved_doc = m; return {"saved": True}
        return await asyncio.get_event_loop().run_in_executor(None, self.mock.host, m)

async def main(anim):
    mock = IosMock("/home/claude/work/web/site-ios", "/tmp/claude-0/fakenet", real_net=True)
    nat = Native(mock)
    server = await asyncio.start_server(nat.serve, "127.0.0.1", 0)
    nat.port = server.sockets[0].getsockname()[1]
    async with async_playwright() as p:
        b = await p.chromium.launch(args=["--autoplay-policy=no-user-gesture-required"])
        ctx = await b.new_context(viewport={"width": 402, "height": 874}, device_scale_factor=2, is_mobile=True, has_touch=True)
        async def hostcall(source, m):
            try: return {"ok": True, "value": await nat.op(m)}
            except Exception as e: return {"ok": False, "error": str(e)}
        await ctx.expose_binding("__iosHost", hostcall)
        await ctx.add_init_script("""window.webkit = { messageHandlers: { ForgeHost: { postMessage(m) { return window.__iosHost(m).then(r => { if (!r.ok) throw new Error(r.error); return r.value; }); } },
            ForgeFiles: { postMessage(m) {} } } };""")
        main_page = await ctx.new_page(); nat.main = main_page
        errs = []; main_page.on("pageerror", lambda e: errs.append(str(e)))
        pctx = await b.new_context(viewport={"width": 402, "height": 420}, device_scale_factor=2)
        player = await pctx.new_page(); nat.player = player
        perrs = []; player.on("pageerror", lambda e: perrs.append(str(e)))
        pconsole = []; player.on("console", lambda m: pconsole.append(m.type + ": " + m.text) if m.type in ("error", "warning") else None)
        player.on("load", lambda: asyncio.ensure_future(nat.emit({"event": "finished", "url": player.url})))
        player.on("framenavigated", lambda f: asyncio.ensure_future(nat.emit({"event": "started", "url": f.url})) if f == player.main_frame else None)
        last_title = [""]
        async def watch_title():
            while True:
                try:
                    t = await player.title()
                    if t != last_title[0] and t.startswith("forge-dock:"): last_title[0] = t; await nat.emit({"event": "title", "title": t})
                except Exception: pass
                await asyncio.sleep(0.15)
        asyncio.ensure_future(watch_title())
        await main_page.goto(mock.url)
        for _ in range(300):
            st = await main_page.evaluate("window.__forgeWorkspaceStartup")
            if st in ("ready", "failed"): break
            await asyncio.sleep(0.1)
        ok("app ready", st == "ready", errs[:2])
        t0 = time.time()
        args = {"mode": "lua", "path": anim, "name": "Test move", "attackerId": 1023571, "enemyId": 1000020}
        if anim.endswith(".usm"): args = {"mode": "movie", "resourcePath": anim, "name": "Test movie"}
        if anim.endswith(".lwf"): args = {"mode": "pack", "resourcePath": anim, "name": "Test pack"}
        r = await main_page.evaluate("a => Native.call('previewAnimation', a)", args)
        ok("previewAnimation answers like Android", r == {"opened": True, "online": True}, r)
        mounted = False
        for _ in range(900):
            try: mounted = await player.evaluate("!!(window.__forgePreviewBootstrap && window.__forgePreviewBootstrap.mounted)")
            except Exception: mounted = False
            if mounted: break
            await asyncio.sleep(0.2)
        ok("player page loaded, request handed over and page script mounted", mounted, {"notes": nat.notes, "overlay": nat.overlay, "log": nat.log[:3], "perrs": perrs[:3], "status": nat.status, "last": nat.requests[-5:]})
        ok("the player runs on the private 127.0.0.1 server", player.url.startswith("http://127.0.0.1:%d/tools/" % nat.port), player.url)
        ok("isolation for the movie engine (crossOriginIsolated)", await player.evaluate("self.crossOriginIsolated"))
        if args["mode"] == "movie":
            v = None
            for _ in range(900):
                v = await player.evaluate("(()=>{const v=document.querySelector('video');return v?{t:v.currentTime,rs:v.readyState,src:v.currentSrc.slice(0,80),err:v.error&&v.error.message}:null})()")
                if v and v["t"] > 1: break
                await asyncio.sleep(0.3)
            await player.screenshot(path=OUT + "movie.png")
            ok("game movie converts and plays", bool(v and v["t"] > 1), {"video": v, "console": pconsole[-6:], "perrs": perrs[:3], "posts": [x for x in nat.requests if x[0] != "GET"][:5]})
            ok("converted movie handed to the app (prepared-movies)", any(x[0] == "POST" and x[2] == 201 for x in nat.requests), [x for x in nat.requests if "prepared" in x[1]][:4])
            ok("no page errors in the player", not perrs, perrs[:3])
            print("requests:", len(nat.requests), "statuses:", nat.status); print(*pconsole[-6:], sep="\n  ")
            await b.close(); server.close(); print("ALL PASS" if not fails else "%d FAILED: %s" % (len(fails), fails)); return
        if args["mode"] == "pack":
            st = None
            for _ in range(300):
                st = await player.evaluate("(document.body.innerText.match(/Ready[^\\n]*/)||[''])[0]")
                if st: break
                await asyncio.sleep(0.3)
            ok("visual pack loads (Ready, like Android it waits for Play)", bool(st), st)
            await player.screenshot(path=OUT + "pack.png")
            ok("no page errors in the player", not perrs, perrs[:3])
            await b.close(); server.close(); print("ALL PASS" if not fails else "%d FAILED: %s" % (len(fails), fails)); return
        # wait until it plays
        playing = None
        for _ in range(600):
            playing = last_title[0]
            if re.match(r"forge-dock:pos:\d+:\d+:p:", playing or ""): break
            await asyncio.sleep(0.2)
        await player.screenshot(path=OUT + "playing.png")
        ok("animation plays (player reports its position to the app)", bool(re.match(r"forge-dock:pos:\d+:\d+:p:", playing or "")), {"title": playing, "secs": round(time.time() - t0, 1), "console": pconsole[-5:], "perrs": perrs[:3]})
        pos = await main_page.evaluate("new Promise(r => { addEventListener('forge-dock-position', e => r(e.detail), { once: true }); setTimeout(() => r(null), 4000); })")
        ok("main screen receives the play position", bool(pos and pos.get("last", 0) > 0), pos)
        await asyncio.sleep(2)
        await player.screenshot(path=OUT + "playing2.png")
        cap = await player.evaluate("fetch('/_forge/stage-capture').then(async r=>[r.status, r.headers.get('content-type'), r.status==200?(await r.arrayBuffer()).byteLength:await r.text()])")
        ok("'Save video' frame capture route (stage snapshot)", cap[0] == 200 and cap[1] == "image/png" and cap[2] > 1000, cap)
        ok("startup overlay hidden once ready", nat.overlay and nat.overlay.get("show") is False, nat.overlay)
        bad503 = [x for x in nat.requests if x[2] == 503 and not x[1].startswith("/account/")]
        ok("no 503 errors from the server (Android ignores /account/ too)", not bad503, bad503[:5])
        ok("player patches applied (no 'public player changed' notes)", not any("changed" in (n or "") for n in nat.notes), nat.notes)
        # dock controls from the app
        d = await main_page.evaluate("Native.call('previewDock', {action:'pause'})")
        await asyncio.sleep(1)
        ok("previewDock pause reaches the player", d.get("open") is True and ":s:" in last_title[0] or ":p:" not in last_title[0], [d, last_title[0]])
        d = await main_page.evaluate("Native.call('previewDock', {action:'toggle'})")
        ok("dock toggles full/docked", d.get("handled") is True and nat.layout in ("full", "docked"), [d, nat.layout])
        d = await main_page.evaluate("Native.call('previewDock', {action:'close'})")
        ok("dock closes", d.get("open") is False and nat.layout == "closed", [d, nat.layout])
        ok("no page errors in the app", not errs, errs[:3])
        ok("no page errors in the player", not perrs, perrs[:3])
        print("requests:", len(nat.requests), "statuses:", nat.status)
        print("player console (last 8):", *pconsole[-8:], sep="\n  ")
        await b.close()
    server.close()
    print("ALL PASS" if not fails else "%d FAILED: %s" % (len(fails), fails))

if __name__ == "__main__":
    asyncio.run(main(sys.argv[1] if len(sys.argv) > 1 else "ab_script/finish_skill/fs0001.lua"))
