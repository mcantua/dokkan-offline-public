"""Foldable check for the iPhone build: one running app is resized between outer-screen and inner-screen
sizes (like folding/unfolding — no reload), checking layout fit, kept place/state, the fold hooks, the
Settings screen report, and finder smoothness with a 4x slowed CPU. Usage: python3 test_ios_duo.py"""
import sys, os, json, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ios_mock import IosMock
from playwright.sync_api import sync_playwright
OUT = "/tmp/claude-0/iostest/duo/"; os.makedirs(OUT, exist_ok=True)
fails = []
def ok(n, c, x=""):
    print(("PASS " if c else "FAIL ") + n, json.dumps(x, default=str)[:400]); sys.stdout.flush()
    if not c: fails.append(n)
# iPhone Duo (apple.com/iphone-duo/specs): outer 1398 x 2034 px (460 ppi), inner 1878 x 2670 px (430 ppi).
# At the iPhone's 3x scale that's 466 x 678 and 626 x 890 points. If Apple runs the inner display at 2x
# instead, it's 939 x 1335 points, so that is checked too. Safe areas are typical Dynamic Island values
# (the real ones show in Settings -> This iPhone's screen).
DISPLAYS = {  # name: (w, h, safe-area insets)
    # MEASURED on Apple's iPhone Duo simulator (Xcode 27.1, iOS 27.1 SDK), outer display, app built for 27.1:
    # 466 x 678 points @3x (1398 x 2034 px); status bar + cameras in a column on the right: safe area right 84,
    # bottom 34; the column's occluded part ends at y = 174 (docs/IPHONE-DUO-DISPLAY.md)
    "outer portrait":      (466, 678, dict(top=0, bottom=34, left=0, right=84)),
    # inner display: 2007 x 2853 px render buffer @3x = 669 x 951 points (panel 1878 x 2670, downsampled) —
    # measured from the real phone (devicectl displays). Insets not measured yet: both rail sides and none
    "inner portrait":      (669, 951, dict(top=0, bottom=34, left=0, right=84)),
    "inner portrait top":  (669, 951, dict(top=62, bottom=34, left=0, right=0)),
    "inner landscape":     (951, 669, dict(top=0, bottom=21, left=0, right=84)),
    "inner landscape left":(951, 669, dict(top=0, bottom=21, left=84, right=0)),
    "outer landscape":     (678, 466, dict(top=0, bottom=21, left=84, right=0)),
    # earlier estimates, kept as extra sizes
    "inner 626x890":       (626, 890, dict(top=62, bottom=34, left=0, right=0)),
    "inner 890x626":       (890, 626, dict(top=0, bottom=21, left=62, right=62)),
}
OUTER = [(466, 678), (678, 466)]
INNER = [(669, 951), (951, 669), (626, 890), (890, 626)]
EDGES = """(sa) => { const W = innerWidth, H = innerHeight, bad = [];
  for (const e of document.querySelectorAll('body *')) {
    if (!e.getClientRects().length || e.closest('details:not([open])') && !e.closest('summary')) continue;
    const own = [...e.childNodes].some(n => n.nodeType === 3 && n.textContent.trim()) || /^(BUTTON|INPUT|SELECT|TEXTAREA|IMG|SVG|A)$/.test(e.tagName);
    if (!own) continue;
    if (document.documentElement.classList.contains('duo-rail') && e.closest('.mobile-nav')) continue;   // checked separately: it belongs in the column
    const s = getComputedStyle(e); if (s.visibility === 'hidden' || +s.opacity === 0) continue;
    const b0 = e.getBoundingClientRect(); const r = { left: b0.left, top: b0.top, right: b0.right, bottom: b0.bottom };
    for (let p = e.parentElement; p && p !== document.body; p = p.parentElement) { const ps = getComputedStyle(p);   // what a scrolling box hides isn't on screen
      if (ps.overflowX !== 'visible' || ps.overflowY !== 'visible' || p.tagName === 'DIALOG') { const q = p.getBoundingClientRect();
        r.left = Math.max(r.left, q.left); r.top = Math.max(r.top, q.top); r.right = Math.min(r.right, q.right); r.bottom = Math.min(r.bottom, q.bottom); } }
    r.width = r.right - r.left; r.height = r.bottom - r.top;
    if (r.width < 2 || r.height < 2 || r.bottom <= 0 || r.top >= H || r.right <= 0 || r.left >= W) continue;
    let fixed = false; for (let p = e; p; p = p.parentElement) { const ps = getComputedStyle(p).position; if (ps === 'fixed' || p.tagName === 'DIALOG' && p.open) { fixed = true; break; } }
    const why = r.top < sa.top - 0.5 ? 'under status bar' : r.left < sa.left - 0.5 ? 'under left edge' : r.right > W - sa.right + 0.5 ? 'under right edge' : fixed && r.bottom > H - sa.bottom + 0.5 ? 'under home bar' : '';
    if (why) bad.push(why + ': ' + (e.id ? '#' + e.id : e.tagName.toLowerCase() + '.' + [...e.classList].slice(0, 2).join('.')) + ' "' + (e.textContent || '').trim().slice(0, 20) + '" ' + [r.left, r.top, r.right, r.bottom].map(Math.round));
  }
  return bad.slice(0, 6); }"""
OVERFLOW = """() => { const w = document.documentElement.clientWidth; const bad = [];
  for (const e of document.querySelectorAll('body *')) { if (!e.offsetParent && getComputedStyle(e).position !== 'fixed') continue; const cd = e.closest('details:not([open])'); if (cd && !e.closest('summary')) continue;
    const r = e.getBoundingClientRect(); if (r.width && (r.right > w + 1 || r.left < -1) && getComputedStyle(e).overflowX !== 'hidden') {
      let p = e.parentElement, clipped = false; while (p) { const s = getComputedStyle(p); if (/(auto|scroll|hidden|clip)/.test(s.overflowX) && p !== document.body && p !== document.documentElement) { clipped = true; break; } p = p.parentElement; }
      if (!clipped) bad.push((e.id ? '#' + e.id : e.tagName.toLowerCase() + '.' + [...e.classList].slice(0,2).join('.')) + ' ' + Math.round(r.left) + '..' + Math.round(r.right)); } }
  return { pageWidth: document.documentElement.scrollWidth, w, bad: bad.slice(0, 6) }; }"""
m = IosMock("/home/claude/work/web/site-ios", "/tmp/claude-0/fakenet", real_net=True)
with sync_playwright() as p:
    b = p.chromium.launch(); ctx = m.context(b, viewport={"width": 393, "height": 852})
    # what main.m injects at document start (real memory/cores instead of Safari's capped values)
    ctx.add_init_script("(function(){var d={memory:8,memoryGB:7.5,cores:6,maxFps:120,machine:'mock'};window.__forgeNativeDevice=d;"
                        "Object.defineProperty(Navigator.prototype,'deviceMemory',{get:function(){return d.memory},configurable:true});"
                        "Object.defineProperty(Navigator.prototype,'hardwareConcurrency',{get:function(){return d.cores},configurable:true});})();")
    pg = ctx.new_page(); errs = []; pg.on("pageerror", lambda e: errs.append(str(e)))
    pg.goto(m.url)
    for _ in range(600):
        if pg.evaluate("window.__forgeWorkspaceStartup") in ("ready", "failed"): break
        pg.wait_for_timeout(100)
    ok("starts; phone is not treated as a low-end device", not pg.evaluate("document.documentElement.classList.contains('tier-low')"), pg.evaluate("document.documentElement.className"))
    # ---- character finder: smoothness with a slowed CPU
    cdp = ctx.new_cdp_session(pg); cdp.send("Emulation.setCPUThrottlingRate", {"rate": 4})
    pg.evaluate("""window.__lt=[];new PerformanceObserver(l=>{for(const e of l.getEntries())__lt.push(Math.round(e.duration))}).observe({type:'longtask',buffered:false})""")
    t0 = time.time(); pg.evaluate("navigate('source')")
    for _ in range(300):
        if pg.evaluate("!!document.querySelector('#fd-create .fd-tile')"): break
        pg.wait_for_timeout(50)
    open_ms = round((time.time() - t0) * 1000); pg.wait_for_timeout(1500)
    tiles = pg.evaluate("document.querySelectorAll('#fd-create .fd-tile').length")
    pg.evaluate("window.__lt=[]")
    scroll = pg.evaluate("""async () => { const s = document.scrollingElement; const frames = []; let last = performance.now();
      for (let i = 0; i < 90; i++) { s.scrollTop += 60; await new Promise(r => requestAnimationFrame(r)); const t = performance.now(); frames.push(t - last); last = t; }
      frames.sort((a, b) => a - b); return { median: Math.round(frames[45]), p95: Math.round(frames[85]), worst: Math.round(frames[89]) }; }""")
    lt = pg.evaluate("__lt")
    ok("finder opens and scrolls without long stalls (CPU slowed 4x)", scroll["p95"] < 50 and max(lt or [0]) < 250, {"openMs": open_ms, "tiles": tiles, "scrollFrameMs": scroll, "longTasksMs": lt[:12]})
    pg.fill("#fd-create [data-fd-text]", "Goku"); t0 = time.time(); pg.wait_for_timeout(50)
    pg.evaluate("window.__lt=[]"); pg.wait_for_timeout(700)
    ok("finder search stays responsive", max(pg.evaluate("__lt") or [0]) < 250, pg.evaluate("__lt"))
    cdp.send("Emulation.setCPUThrottlingRate", {"rate": 1})
    # ---- fold / unfold with the finder scrolled: no reload, place kept, layout fits
    pg.evaluate("document.scrollingElement.scrollTop = 1400"); pg.wait_for_timeout(300)
    marker = pg.evaluate("window.__noReload = 1")
    anchor = pg.evaluate("(() => { const e = document.elementFromPoint(innerWidth/2, 20); const t = e && e.closest('.fd-tile'); return t ? t.textContent.trim().slice(0, 40) : null })()")
    for (w, h) in OUTER + INNER + [(393, 852)]:
        pg.evaluate("__forgeFold.begin()"); pg.set_viewport_size({"width": w, "height": h}); pg.evaluate("__forgeFold.end()"); pg.wait_for_timeout(400)
        o = pg.evaluate(OVERFLOW)
        pg.screenshot(path=f"{OUT}finder-{w}x{h}.png")
        ok(f"finder fits {w}x{h}", o["pageWidth"] <= w and not o["bad"], o)
    near = pg.evaluate("(() => { const e = document.elementFromPoint(innerWidth/2, 20); const t = e && e.closest('.fd-tile'); return [document.scrollingElement.scrollTop, t ? t.textContent.trim().slice(0, 40) : null] })()")
    ok("fold/unfold kept the app running and your place in the list", pg.evaluate("window.__noReload") == 1 and near[0] > 600 and not pg.evaluate("document.documentElement.classList.contains('forge-resizing')"), {"before": anchor, "after": near})
    # ---- editor: open a unit, fold back and forth, nothing lost
    pg.evaluate("document.scrollingElement.scrollTop = 0")
    pg.locator("#fd-create .fd-tile").first.click()
    for _ in range(300):
        if pg.evaluate("state.view==='editor'&&!!state.project&&document.getElementById('busy').hidden"): break
        pg.wait_for_timeout(100)
    pg.evaluate("document.querySelector('[data-b=\"tab:basics\"]')?.click()"); pg.wait_for_timeout(300)
    pg.fill('[data-bind="card:name"]', "Fold Test"); pg.dispatch_event('[data-bind="card:name"]', "change"); pg.wait_for_timeout(600)
    for t in ["passive", "supers", "look"]:
        pg.evaluate(f"document.querySelector('[data-b=\"tab:{t}\"]')?.click()"); pg.wait_for_timeout(300)
        pg.evaluate("document.querySelector('details.bld-more').open = true"); pg.wait_for_timeout(100)
        for (w, h) in OUTER + INNER[:2]:
            pg.set_viewport_size({"width": w, "height": h}); pg.wait_for_timeout(350)
            o = pg.evaluate(OVERFLOW)
            if t == "look": pg.screenshot(path=f"{OUT}editor-{t}-{w}x{h}.png")
            ok(f"builder '{t}' fits {w}x{h}", o["pageWidth"] <= w and not o["bad"], o)
    pg.evaluate("document.querySelector('[data-b=\"tab:basics\"]')?.click()"); pg.wait_for_timeout(400)
    ok("unit and its edits survive folding", pg.evaluate("state.view==='editor' && document.querySelector('[data-bind=\"card:name\"]')?.value") == "Fold Test" and pg.evaluate("window.__noReload") == 1)
    # ---- every main screen on every display, with the screen edges (status bar, Dynamic Island, home bar)
    for name, (w, h, sa) in DISPLAYS.items():
        pg.set_viewport_size({"width": w, "height": h})
        cdp.send("Emulation.setSafeAreaInsetsOverride", {"insets": sa}); pg.wait_for_timeout(300)
        for view in ["home", "library", "source", "animations", "editor", "settings"]:
            if view == "editor": pg.evaluate("navigate('editor')")
            elif view == "settings": pg.evaluate("ForgeSettings.open()")
            else: pg.evaluate(f"navigate('{view}')")
            pg.wait_for_timeout(900 if view in ("source", "settings") else 500)
            pg.evaluate("document.scrollingElement.scrollTop = 0; document.querySelectorAll('dialog[open]').forEach(d => d.scrollTop = 0)"); pg.wait_for_timeout(100)
            o = pg.evaluate(OVERFLOW); e = pg.evaluate(EDGES, sa)
            if view in ("home", "editor", "settings"): pg.screenshot(path=f"{OUT}{name.replace(' ', '-').replace('@', '')}-{view}.png")
            ok(f"{name} ({w}x{h}) {view}: fits and stays clear of the screen edges", o["pageWidth"] <= w and not o["bad"] and not e, {"overflow": o["bad"], "edges": e})
            if view == "settings": pg.evaluate("document.querySelector('dialog.settings-sheet')?.close()")
    cdp.send("Emulation.setSafeAreaInsetsOverride", {"insets": {}})
    # ---- edges sent by the app itself (UIKit safe area + iPhone Duo camera regions, main.m -pushGeometry):
    # WebKit's env() doesn't know the camera regions, so the page must follow the --sa-* values
    NATIVE = {"inner landscape camera": (890, 626, dict(top=0, right=84, bottom=21, left=56)),
              "outer portrait camera": (466, 678, dict(top=40, right=84, bottom=34, left=0))}
    for name, (w, h, sa) in NATIVE.items():
        pg.set_viewport_size({"width": w, "height": h})
        pg.evaluate("sa => { const s = document.documentElement.style; s.setProperty('--sa-t', sa.top + 'px'); s.setProperty('--sa-r', sa.right + 'px'); s.setProperty('--sa-b', sa.bottom + 'px'); s.setProperty('--sa-l', sa.left + 'px'); }", sa)
        for view in ["home", "editor"]:
            pg.evaluate(f"navigate('{view}')"); pg.wait_for_timeout(500)
            pg.evaluate("document.scrollingElement.scrollTop = 0"); pg.wait_for_timeout(100)
            o = pg.evaluate(OVERFLOW); e = pg.evaluate(EDGES, sa)
            pg.screenshot(path=f"{OUT}{name.replace(' ', '-')}-{view}.png")
            ok(f"{name} ({w}x{h}) {view}: follows the app's own screen edges", o["pageWidth"] <= w and not o["bad"] and not e, {"overflow": o["bad"], "edges": e})
    pg.evaluate("['t','r','b','l'].forEach(k => document.documentElement.style.removeProperty('--sa-' + k))")
    # ---- iPhone Duo rail: the tab bar stands in the status column below the status bar (as measured: right, 84 wide,
    # status/cameras down to y=174); nothing at the bottom, the content stays left of the column
    RAIL = {"outer portrait": (466, 678, dict(top=0, right=84, bottom=34, left=0), "right", 174),
            "inner portrait": (669, 951, dict(top=0, right=84, bottom=34, left=0), "right", 174),
            "inner landscape": (951, 669, dict(top=0, right=84, bottom=34, left=0), "right", 178),   # measured on the phone
            "inner landscape left": (951, 669, dict(top=0, right=0, bottom=21, left=84), "left", 174)}
    for name, (w, h, sa, side, top) in RAIL.items():
        pg.set_viewport_size({"width": w, "height": h})
        pg.evaluate("""([sa, side, top]) => { const r = document.documentElement, s = r.style;
          s.setProperty('--sa-t', sa.top + 'px'); s.setProperty('--sa-r', sa.right + 'px'); s.setProperty('--sa-b', sa.bottom + 'px'); s.setProperty('--sa-l', sa.left + 'px');
          s.setProperty('--rail-w', (side === 'right' ? sa.right : sa.left) + 'px'); s.setProperty('--rail-top', top + 'px');
          r.classList.add('duo-rail'); r.classList.toggle('duo-rail-left', side === 'left'); window.dispatchEvent(new CustomEvent('forgedisplay')); }""", [sa, side, top])
        for view in ["home", "editor", "library"]:
            pg.evaluate(f"navigate('{view}')"); pg.wait_for_timeout(500)
            pg.evaluate("document.scrollingElement.scrollTop = 0"); pg.wait_for_timeout(100)
            nav = pg.evaluate("""() => { const n = document.querySelector('.mobile-nav'); if (!n || !n.getClientRects().length) return null;
              const r = n.getBoundingClientRect(); const bs = [...n.querySelectorAll('button')].filter(b => b.getClientRects().length).map(b => b.getBoundingClientRect());
              return { l: r.left, t: r.top, r: r.right, b: r.bottom, buttons: bs.length, lastBottom: Math.max(...bs.map(b => b.bottom)), navH: getComputedStyle(document.documentElement).getPropertyValue('--nav-h') }; }""")
            o = pg.evaluate(OVERFLOW); e = pg.evaluate(EDGES, sa)
            pg.screenshot(path=f"{OUT}rail-{name.replace(' ', '-')}-{view}.png")
            rw = sa["right"] or sa["left"]
            in_rail = nav is not None and ((nav["l"] >= w - rw - 1 if side == "right" else nav["r"] <= rw + 1) and nav["t"] >= top and nav["b"] <= h - sa["bottom"] + 1 and nav["lastBottom"] <= nav["b"] + 1 and nav["navH"].strip() == "0px")
            ok(f"rail {name} ({w}x{h}) {view}: tab bar in the status column, content clear of it", in_rail and o["pageWidth"] <= w and not o["bad"] and not e, {"nav": nav, "overflow": o["bad"], "edges": e})
    pg.evaluate("""() => { const r = document.documentElement; r.classList.remove('duo-rail', 'duo-rail-left'); ['t','r','b','l'].forEach(k => r.style.removeProperty('--sa-' + k)); window.dispatchEvent(new CustomEvent('forgedisplay')); }""")
    # ---- Settings: the screen report
    for (w, h) in [OUTER[1], INNER[0]]:
        pg.set_viewport_size({"width": w, "height": h}); pg.wait_for_timeout(200)
        pg.evaluate("ForgeSettings.open()"); pg.wait_for_timeout(1800)
        rep = pg.evaluate("document.querySelector('#set-iphone .ios-display')?.innerText || ''")
        o = pg.evaluate(OVERFLOW)
        pg.screenshot(path=f"{OUT}settings-{w}x{h}.png")
        ok(f"Settings shows the screen report at {w}x{h}", "Window" in rep and "measured" in rep and o["pageWidth"] <= w, rep.replace("\n", " | ")[:300])
        pg.evaluate("document.querySelector('dialog.settings-sheet')?.close()")
    ok("no script errors", not errs, errs[:3])
    b.close()
print("\n%d failed" % len(fails), fails)
sys.exit(1 if fails else 0)
