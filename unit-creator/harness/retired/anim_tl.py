"""Timeline editor: empty state, moves as blocks, playhead follows the player, split at playhead,
edge-drag trim, trim sheet, move/copy/delete, play/seek commands, preview refresh after edits."""
import os, json
os.environ["FORGE_STATE"] = "/home/claude/work/harness/state-animtl"; os.environ["FRESH"] = "1"
from harness import Session
OUT = "/tmp/claude-0/sim/anim/"
s = Session(viewport=(412, 520)).open(); pg = s.page; w = lambda ms=600: pg.wait_for_timeout(ms)
errs = []; pg.on("pageerror", lambda e: errs.append(str(e)))
while pg.evaluate("window.__forgeWorkspaceStartup") != "ready": w(100)
w(600); pg.locator(".mobile-nav button", has_text="Animate").first.click(); w(1200)
pg.screenshot(path=OUT + "tl-empty.png")
print("empty:", pg.locator(".tl-empty").count(), "| topbar hidden:", pg.evaluate("getComputedStyle(document.querySelector('.topbar')).display"))
def add(term):
    pg.locator('[data-studio="browse"]').first.click(); w(1200)
    pg.select_option("#studio-kind", "all"); w(800); pg.fill("#studio-search", term); w(2000)
    pg.locator('#studio-results [data-studio^="add:"]').first.click(); w(1200)
    pg.evaluate("document.querySelectorAll('dialog.sequence-picker[open]').forEach(d=>d.querySelector('[aria-label=\"Close picker\"]')?.click())"); w(300)
for t in ["Kamehameha", "Final Flash", "Galick"]: add(t)
clips = lambda: pg.evaluate("studioProject().clips.map(c=>[c.from,c.to])")
print("blocks:", pg.locator(".tl-clip").count(), clips(), "|", pg.inner_text("#simple-sequence-summary"))
w(900)
lp = s.native.last_preview or {}
print("monitor request:", lp.get("dockSize"), lp.get("startAt"), lp.get("startPaused"), "text" in lp)
pg.evaluate("ForgeDock.native('docked'); ForgeDock.position(240, 2700, 'p')"); w(300)
print("follows player:", pg.inner_text("#tl-clock"), "scroll:", pg.evaluate("document.getElementById('tl-scroll').scrollLeft"), "play icon:", pg.inner_text("#tl-play"))
pg.screenshot(path=OUT + "tl-playing.png")
# user slides the timeline to 20.0 s (inside move 2): player pauses and seeks
s.native.dock_calls = []
pg.evaluate("(()=>{const sc=document.getElementById('tl-scroll');const c=document.querySelector('.tl-clip');const px=(parseFloat(c.style.width)+2)/15;sc.scrollLeft=Math.round(20*px);sc.dispatchEvent(new Event('scroll'));})()"); w(500)
print("slide:", pg.inner_text("#tl-clock"), "dock calls:", s.native.dock_calls)
pg.locator(".tl-clip").nth(1).click(); w(300)
print("tools:", pg.evaluate("[...document.querySelectorAll('.tl-tool')].map(b=>b.innerText.replace(/\\n/g,' '))"))
pg.screenshot(path=OUT + "tl-selected.png")
pg.click('.tl-tool[data-tl="split"]'); w(1200)
print("after split:", clips(), "| selected:", pg.evaluate("document.querySelector('.tl-sel')?.dataset.tlClip"))
# drag the end handle of the selected move 1 second to the left
pg.evaluate("document.querySelector('.tl-sel .tl-h-end').scrollIntoView({inline:'center',block:'nearest'})"); w(500)
h = pg.locator(".tl-sel .tl-h-end").bounding_box()
pg.mouse.move(h["x"] + 10, h["y"] + 20); pg.mouse.down(); pg.mouse.move(h["x"] - 38, h["y"] + 20, steps=5); pg.mouse.up(); w(800)
print("after edge drag:", clips())
pg.click('.tl-tool[data-tl="trim"]'); w(500)
print("trim sheet:", pg.locator("dialog.sequence-picker[open] .trim-value").count())
pg.screenshot(path=OUT + "tl-trim.png")
pg.click("dialog.sequence-picker[open] [data-tl-sheet='done']"); w(300)
pg.click('.tl-tool[data-studio^="up:"]'); w(500)
print("after earlier:", pg.evaluate("document.querySelector('.tl-sel')?.dataset.tlClip"), len(clips()))
pg.click('.tl-tool[data-studio^="copy:"]'); w(500); print("after copy:", len(clips()))
pg.click('.tl-tool[data-studio^="remove:"]'); w(500); print("after delete:", len(clips()), "| tools hint:", pg.locator(".tl-tools-hint").count())
s.native.last_preview = None; w(1200)
print("refresh after edits:", (s.native.last_preview or {}).get("startPaused"), (s.native.last_preview or {}).get("startAt"))
s.native.dock_calls = []
pg.evaluate("ForgeDock.position(Math.round(0*60), 2000, 's')"); w(200)
pg.click("#tl-play"); w(400); print("play:", s.native.dock_calls)
pg.click("#tl-save"); w(400); print("save sheet:", pg.evaluate("[...document.querySelectorAll('dialog.sequence-picker[open] .tl-sheet-btn')].map(b=>b.textContent)"))
pg.evaluate("document.querySelectorAll('dialog.sequence-picker[open]').forEach(d=>d.querySelector('[aria-label=\"Close picker\"]')?.click())"); w(200)
pg.click("#tl-more"); w(400); print("more sheet:", pg.evaluate("[...document.querySelectorAll('dialog.sequence-picker[open] .tl-sheet-btn')].map(b=>b.textContent)"))
pg.evaluate("document.querySelectorAll('dialog.sequence-picker[open]').forEach(d=>d.querySelector('[aria-label=\"Close picker\"]')?.click())"); w(200)
s.native.dock_calls = []
pg.locator(".mobile-nav button", has_text="Home").first.click(); w(800)
print("leaving closes preview:", s.native.dock_calls, "| topbar:", pg.evaluate("getComputedStyle(document.querySelector('.topbar')).display"))
print("errors:", errs)
