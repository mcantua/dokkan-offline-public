"""v2.27 timeline: Start here / End here, Fit, tap the ruler, pinch zoom, smooth playhead, no rebuild while trimming."""
import os
os.environ["FORGE_STATE"] = "/home/claude/work/harness/state-tleasy"; os.environ["FRESH"] = "1"
from harness import Session
OUT = "/tmp/claude-0/sim/tleasy/"; os.makedirs(OUT, exist_ok=True)
s = Session(viewport=(412, 915)).open(); pg = s.page; w = lambda ms=600: pg.wait_for_timeout(ms)
errs = []; pg.on("pageerror", lambda e: errs.append(str(e)))
def ok(name, cond, extra=""): print(("PASS " if cond else "FAIL ") + name, extra)
while pg.evaluate("window.__forgeWorkspaceStartup") != "ready": w(100)
w(600); pg.locator(".mobile-nav button", has_text="Animate").first.click(); w(1200)
def add(term):
    pg.locator('[data-studio="browse"]').first.click(); w(1200)
    pg.select_option("#studio-kind", "all"); w(800); pg.fill("#studio-search", term); w(2000)
    pg.locator('#studio-results [data-studio^="add:"]').first.click(); w(1200)
    pg.evaluate("document.querySelectorAll('dialog.sequence-picker[open]').forEach(d=>d.querySelector('[aria-label=\"Close picker\"]')?.click())"); w(300)
for t in ["Kamehameha", "Final Flash"]: add(t)
def sel(i):
    if pg.evaluate(f"!document.querySelector('.tl-clip[data-tl-clip=\"{i}\"]').classList.contains('tl-sel')"): pg.locator(".tl-clip").nth(i).click(); w(300)
clips = lambda: pg.evaluate("studioProject().clips.map(c=>[c.from,c.to])")
px = lambda: pg.evaluate("(()=>{const c=document.querySelector('.tl-clip'),p=studioProject();return (parseFloat(c.style.width)+2)/(p.clips[0].to-p.clips[0].from)})()")
width = pg.evaluate("document.getElementById('tl-scroll').clientWidth")
total = pg.evaluate("(()=>{const t=ForgeSequence.timeline(studioProject().clips);return t[t.length-1].end})()")
ok("auto-fit on open", abs(px() * total - (width - 28)) < 40, [round(px(), 1), total, width])
pg.click("#tl-zoom-in"); w(300); z1 = px(); pg.click("#tl-fit"); w(300)
ok("Fit button", z1 > px() and abs(px() * total - (width - 28)) < 40, [round(z1, 1), round(px(), 1)])
# tap the ruler at 20 s
s.native.dock_calls = []
pg.evaluate("ForgeDock.native('docked'); ForgeDock.position(0, 1800, 's')"); w(200)
box = pg.locator("#tl-content").bounding_box(); pad = round(width / 2)
pg.mouse.click(box["x"] + pad + 10 * px(), pg.locator("#tl-ruler").bounding_box()["y"] + 10); w(500)
ok("ruler tap moves the line", pg.inner_text("#tl-clock").startswith("0:10"), [pg.inner_text("#tl-clock"), s.native.dock_calls])
pg.evaluate(f"(()=>{{const sc=document.getElementById('tl-scroll');sc.scrollLeft=Math.round(20*{px()});sc.dispatchEvent(new Event('scroll'));}})()"); w(500)
# Start here on move 2 (line at 20 s, move 2 starts at 15 s)
sel(1)
pg.click('.tl-tool[data-tl="cut-start"]'); w(900)
ok("Start here", clips()[1] == [5, 15], [clips(), pg.inner_text("#tl-clock")])
# End here on move 1 at 9.5 s
pg.evaluate(f"(()=>{{const sc=document.getElementById('tl-scroll');sc.scrollLeft=Math.round(9.5*{px()});sc.dispatchEvent(new Event('scroll'));}})()"); w(500)
sel(0)
pg.click('.tl-tool[data-tl="cut-end"]'); w(900)
c = clips(); ok("End here", c[0][0] == 0 and abs(c[0][1] - 9.5) < 0.15, [c, pg.inner_text("#tl-clock")])
pg.screenshot(path=OUT + "1-tools.png")
# line outside every move → friendly message
pg.evaluate("(()=>{const sc=document.getElementById('tl-scroll');sc.scrollLeft=sc.scrollWidth;sc.dispatchEvent(new Event('scroll'));})()"); w(500)
pg.click('.tl-tool[data-tl="cut-start"]'); w(500)
ok("message when the line is off the moves", "Slide the timeline" in pg.inner_text("#toast"), pg.inner_text("#toast"))
# pinch zoom with two touch pointers
before = px()
pg.evaluate("""(()=>{const sc=document.getElementById('tl-scroll'),r=sc.getBoundingClientRect(),y=r.top+40,mk=(t,id,x)=>sc.dispatchEvent(new PointerEvent(t,{pointerId:id,pointerType:'touch',clientX:x,clientY:y,bubbles:true}));
 mk('pointerdown',11,r.left+150);mk('pointerdown',12,r.left+200);mk('pointermove',12,r.left+260);mk('pointermove',11,r.left+90);mk('pointerup',11,r.left+90);mk('pointerup',12,r.left+260);})()"""); w(500)
ok("pinch zoom in", px() > before * 2.5, [round(before, 1), round(px(), 1)])
# smooth playhead between reports, no stepping back
pg.click("#tl-fit"); w(300)
s.native.last_preview = None
pg.evaluate("ForgeDock.position(300, 1500, 'p')"); w(400)
a = pg.evaluate("studioProject() && document.getElementById('tl-clock').textContent")
pg.evaluate("ForgeDock.position(318, 1500, 'p')"); w(50)
b = pg.inner_text("#tl-clock")
sec = lambda: (lambda t: int(t.split(":")[0]) * 60 + float(t.split(":")[1]))(pg.inner_text("#tl-clock").split(" / ")[0])
pg.evaluate("ForgeDock.position(600, 1500, 'p')"); w(1500)
ok("line never runs far ahead of a stalled picture", 10.0 <= sec() <= 10.35, sec())
pg.evaluate("ForgeDock.position(120, 1500, 'p')"); w(300); pg.evaluate("ForgeDock.position(420, 1500, 'p')"); w(600)
ok("a jump isn't mistaken for 2x speed", 7.0 <= sec() <= 7.35, sec())

t1 = float(a.split(" / ")[0].split(":")[1]); t2 = float(b.split(" / ")[0].split(":")[1])
ok("line glides between reports", t1 > 5.2, a)
ok("no step back on a late report", t2 >= t1 - 0.05, [a, b])
pg.evaluate("ForgeDock.position(318, 1500, 's')"); w(300)
# no preview rebuild while the Trim window is open
sel(0)
n0 = s.native.calls.count("previewAnimation") if hasattr(s.native, "calls") else None
pg.click('.tl-tool[data-tl="trim"]'); w(500)
pg.evaluate("(()=>{const c=studioProject().clips[0];c.to=Math.max(c.from+1,c.to-1);studioChange();})()"); w(2000)
opened_during = pg.evaluate("!!document.querySelector('dialog.sequence-picker[open]')")
lp_during = s.native.last_preview
pg.evaluate("document.querySelector('dialog.sequence-picker [data-tl-sheet=\"done\"]').click()"); w(2000)
ok("rebuild waits for the Trim window", opened_during and lp_during is None and s.native.last_preview is not None, [opened_during, lp_during is None, s.native.last_preview is not None])
pg.screenshot(path=OUT + "2-final.png")
print("errors:", errs[:3])
