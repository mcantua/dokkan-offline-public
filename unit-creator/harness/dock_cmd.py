"""Player page <-> editor: start paused at a frame, position reports, seek/play/pause commands."""
import http.server, threading, functools
from playwright.sync_api import sync_playwright
class Q(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *a): pass
srv = http.server.ThreadingHTTPServer(("127.0.0.1", 0), functools.partial(Q, directory="/home/claude/work/harness/fakeplayer")); threading.Thread(target=srv.serve_forever, daemon=True).start()
url = f"http://127.0.0.1:{srv.server_port}/tools/lua-player/"
page_js = open("/home/claude/work/v2/ui/animation-page.js").read()
with sync_playwright() as p:
    b = p.chromium.launch(); pg = b.new_page(viewport={"width": 412, "height": 400})
    errs = []; pg.on("pageerror", lambda e: errs.append(str(e)))
    pg.goto(url); pg.wait_for_timeout(200)
    pg.evaluate("r => { window.__forgeAnimation = r; }", {"dock": True, "autoplay": True, "localPreview": True, "text": "-- clip", "name": "Mine", "startAt": 300, "startPaused": True})
    pg.evaluate(page_js); pg.wait_for_timeout(1500)
    pg.evaluate("""() => { window.titles=[]; new MutationObserver(()=>titles.push(document.title)).observe(document.querySelector('title')||document.head,{childList:true,subtree:true,characterData:true});
      window.__forgeRunner = {playing:true, frame:0, maxFrame:900, userPaused:false, pause(){this.userPaused=true;}, async resume(){this.userPaused=false;}, async scrubToFrame(f){this.frame=f;}};
      dispatchEvent(new CustomEvent('forge-preview-playing')); }""")
    pg.wait_for_timeout(600)
    print("start paused at:", pg.evaluate("[__forgeRunner.frame, __forgeRunner.userPaused]"), "controls shown:", pg.evaluate("document.getElementById('forge-dock-controls').classList.contains('show')"))
    print("title report:", pg.title().split(":")[:5])
    pg.evaluate("ForgeDockPage.command({type:'seek',frame:450,play:true})"); pg.wait_for_timeout(400)
    print("seek+play:", pg.evaluate("[__forgeRunner.frame, __forgeRunner.userPaused]"), pg.title().split(":")[1:5])
    pg.evaluate("__forgeRunner.frame=600"); pg.wait_for_timeout(400)
    print("periodic report:", pg.title().split(":")[1:5])
    pg.evaluate("ForgeDockPage.command({type:'pause'})"); pg.wait_for_timeout(300)
    print("pause:", pg.evaluate("[window.paused||0]"), pg.title().split(":")[1:5])
    print("time label:", pg.inner_text("#forge-dock-controls .time"))
    print("errors:", errs); b.close()
srv.shutdown()
