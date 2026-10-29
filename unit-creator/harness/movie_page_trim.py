import http.server, threading, functools
from playwright.sync_api import sync_playwright
H = functools.partial(http.server.SimpleHTTPRequestHandler, directory="/home/claude/work/harness/fakeplayer")
srv = http.server.ThreadingHTTPServer(("127.0.0.1", 0), H); threading.Thread(target=srv.serve_forever, daemon=True).start()
js = open("/home/claude/work/v2/ui/movie-page.js").read()
with sync_playwright() as p:
    b = p.chromium.launch(); pg = b.new_page()
    errs = []; pg.on("pageerror", lambda e: errs.append(str(e)))
    pg.goto(f"http://127.0.0.1:{srv.server_port}/tools/usm-player/")
    pg.evaluate("r=>{window.__forgeAnimation=r}", {"mode": "movie", "resourcePath": "movie/x.usm", "name": "Scene", "dock": True, "trim": {"from": 1, "to": 2}})
    pg.evaluate(js); pg.wait_for_timeout(500)
    pg.evaluate("const v=document.getElementById('video');v.muted=true;fetch('clip.webm').then(r=>r.blob()).then(b=>{v.src=URL.createObjectURL(b);v.load();});"); pg.wait_for_timeout(1500)
    print("hooked?", pg.evaluate("getEventListeners ? 1 : 0") if False else "", pg.evaluate("document.getElementById('video').dataset.forgeMovie"))
    print("manual seek:", pg.evaluate("(async()=>{const v=document.getElementById('video');v.currentTime=1;await new Promise(r=>setTimeout(r,300));return v.currentTime})()"))
    print("before play:", pg.evaluate("[document.getElementById('video').currentTime, document.getElementById('video').readyState, document.getElementById('video').seekable.length]"))
    pg.evaluate("document.getElementById('video').play()"); 
    samples = []
    for _ in range(14):
        pg.wait_for_timeout(250); samples.append(round(pg.evaluate("document.getElementById('video').currentTime"), 2))
    print("title:", pg.inner_text("#forge-movie-bar h1")); print("times:", samples); print("errors:", errs)
    b.close()
srv.shutdown()
