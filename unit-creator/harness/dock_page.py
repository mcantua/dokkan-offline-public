"""animation-page.js in the in-app player: compact stage, auto-play, controls, Tools/back."""
import http.server, threading, functools, sys
from playwright.sync_api import sync_playwright
SP = "/tmp/claude-0/-home-claude/fc61b99f-cb57-56bc-b827-ee4cb4796a4c/scratchpad/"
UI = sys.argv[1] if len(sys.argv) > 1 else "/home/claude/work/v2/ui"
H = functools.partial(http.server.SimpleHTTPRequestHandler, directory="/home/claude/work/harness/fakeplayer")
srv = http.server.ThreadingHTTPServer(("127.0.0.1", 0), H); threading.Thread(target=srv.serve_forever, daemon=True).start()
url = f"http://127.0.0.1:{srv.server_port}/tools/lua-player/"
page_js = open(UI + "/animation-page.js").read()
with sync_playwright() as p:
    b = p.chromium.launch()
    for label, req, vp in [("docked", {"dock": True, "autoplay": True, "localPreview": True, "text": "-- clip\nfunction main() end", "name": "Kamehameha", "attackerId": 1}, (412, 400)),
                           ("export", {"dock": True, "autoplay": True, "localPreview": True, "text": "-- FORGE_SEQUENCE_EXPORT 90\n-- x", "name": "Video"}, (412, 860)),
                           ("window", {"localPreview": True, "text": "-- clip", "name": "Old"}, (412, 860))]:
        pg = b.new_page(viewport={"width": vp[0], "height": vp[1]})
        errs = []; pg.on("pageerror", lambda e: errs.append(str(e)))
        pg.goto(url); pg.wait_for_timeout(200)
        pg.evaluate("r => { window.__forgeAnimation = r; }", req)
        pg.evaluate(page_js); pg.wait_for_timeout(2500)
        info = pg.evaluate("""() => { const f=document.querySelector('.stage-fit').getBoundingClientRect(), c=document.getElementById('forge-dock-controls');
          return {dock: document.body.classList.contains('forge-dock'), classic: document.body.classList.contains('forge-dock-classic'), plays: window.plays||0, loaded: window.loaded||null,
            phone: document.getElementById('phoneCrop').checked, fit: [Math.round(f.x),Math.round(f.y),Math.round(f.width),Math.round(f.height)],
            controls: c ? getComputedStyle(c).display : null, status: document.querySelector('.forge-dock-status')?.textContent ?? null,
            overlay: document.getElementById('forge-dock-overlay') ? !document.getElementById('forge-dock-overlay').hidden : null,
            panelHidden: getComputedStyle(document.querySelector('.panel')).display, start: document.getElementById('forge-animation-start').disabled } }""")
        print(label, info, errs[:2])
        pg.screenshot(path=SP + f"dockpage-{label}.png")
        if label == "docked":
            pg.evaluate("""() => { window.__forgeRunner = {playing:true, frame:60, maxFrame:300, userPaused:false, pause(){this.userPaused=true;}, async resume(){this.userPaused=false;}, async scrubToFrame(f){this.frame=f; window.scrubbed=f;}}; dispatchEvent(new CustomEvent('forge-preview-playing')); }""")
            pg.wait_for_timeout(300)
            print("  hidden at start:", pg.evaluate("!document.getElementById('forge-dock-controls').classList.contains('show')"))
            pg.screenshot(path=SP + "dockpage-clean.png")
            pg.mouse.click(200, 150); pg.wait_for_timeout(300)
            print("  shown after tap:", pg.evaluate("document.getElementById('forge-dock-controls').classList.contains('show')"), pg.inner_text("#forge-dock-controls .time"))
            pg.screenshot(path=SP + "dockpage-controls.png")
            pg.wait_for_timeout(3400)
            print("  faded after 3s:", pg.evaluate("!document.getElementById('forge-dock-controls').classList.contains('show')"))
            pg.mouse.click(200, 150); pg.wait_for_timeout(300)
            pg.click("#forge-dock-controls .play"); pg.wait_for_timeout(200)
            print("  paused:", pg.evaluate("[window.paused||0, document.querySelector('#forge-dock-controls .play').textContent]"))
            box = pg.locator("#forge-dock-controls .track").bounding_box()
            pg.mouse.click(box["x"] + box["width"] * 0.5, box["y"] + box["height"] / 2); pg.wait_for_timeout(300)
            print("  seek to half:", pg.evaluate("window.scrubbed"))
            pg.click("#forge-dock-controls .more"); pg.wait_for_timeout(200)
            pg.screenshot(path=SP + "dockpage-menu.png")
            pg.click("#forge-dock-controls .speed")
            print("  speed:", pg.evaluate("window.speed"))
            pg.click("#forge-dock-controls .close"); pg.wait_for_timeout(100)
            print("  close title:", pg.title().split(":")[:2])
            pg.evaluate("dispatchEvent(new CustomEvent('forge-preview-done'))"); pg.wait_for_timeout(300)
            print("  done:", pg.evaluate("[document.getElementById('forge-dock-controls').className, getComputedStyle(document.querySelector('#forge-dock-controls .play')).display]"))
            pg.screenshot(path=SP + "dockpage-done.png")
            pg.click("#forge-dock-controls .again"); pg.wait_for_timeout(500)
            print("  again plays:", pg.evaluate("window.plays"))
            pg.evaluate("document.getElementById('forge-dock-controls').classList.add('show')"); pg.wait_for_timeout(200); pg.click("#forge-dock-controls .more"); pg.click("#forge-dock-controls .tools"); pg.wait_for_timeout(300)
            print("  tools:", pg.evaluate("[document.body.classList.contains('forge-dock'), getComputedStyle(document.querySelector('.panel')).display, getComputedStyle(document.getElementById('forge-dock-tools')).display]"), pg.title().split(":")[:2])
            pg.click("#forge-dock-tools"); pg.wait_for_timeout(300)
            print("  back:", pg.evaluate("document.body.classList.contains('forge-dock')"))
            pg.set_viewport_size({"width": 412, "height": 860}); pg.wait_for_timeout(500)
            f = pg.evaluate("(()=>{const r=document.querySelector('.stage-fit').getBoundingClientRect();return [Math.round(r.width),Math.round(r.height)]})()")
            print("  full-screen fit:", f)
            pg.screenshot(path=SP + "dockpage-full.png")
        pg.close()
    b.close()
srv.shutdown()
