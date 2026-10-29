"""v2.29 parts editor: add a part → Choose the part window opens; play, tap Start here / End here (exact
frame from the player), fine steps, watch my part (stops at the end), Done; part cards; menu; whole animation."""
import os
os.environ["FORGE_STATE"] = "/home/claude/work/harness/state-parts"; os.environ["FRESH"] = "1"
from harness import Session
OUT = "/tmp/claude-0/sim/parts/"; os.makedirs(OUT, exist_ok=True)
s = Session(viewport=(412, 915)).open(); pg = s.page; w = lambda ms=600: pg.wait_for_timeout(ms)
errs = []; pg.on("pageerror", lambda e: errs.append(str(e)))
def ok(n, c, x=""): print(("PASS " if c else "FAIL ") + n, x)
while pg.evaluate("window.__forgeWorkspaceStartup") != "ready": w(100)
w(600); pg.locator(".mobile-nav button", has_text="Animate").first.click(); w(1200)
def add(term):
    pg.locator('[data-studio="browse"]').first.click(); w(1200)
    pg.select_option("#studio-kind", "all"); w(800); pg.fill("#studio-search", term); w(2000)
    pg.locator('#studio-results [data-studio^="add:"]').first.click(); w(1500)
clips = lambda: pg.evaluate("studioProject().clips.map(c=>[c.from,c.to])")
seeks = lambda: [a for a in s.native.dock_args if a.get("action") == "seek"]
add("Kamehameha")
ok("adding opens 'Choose the part'", pg.locator("dialog.sequence-picker[open] #pt").count() == 1, pg.inner_text("dialog.sequence-picker").split("\n")[:3] if pg.locator("dialog.sequence-picker[open]").count() else "")
lp = s.native.last_preview or {}
ok("the move shows in the preview (paused)", lp.get("startPaused") is True, lp.get("startAt"))
pg.evaluate("ForgeDock.native('docked'); ForgeDock.position(0, 900, 's')"); w(200)
pg.screenshot(path=OUT + "1-choose.png")
s.native.dock_args = []
pg.click("#pt-play"); w(300)
ok("Play plays the move", seeks() and seeks()[-1]["play"] is True, seeks()[-1:])
pg.evaluate("ForgeDock.position(150, 900, 'p')"); w(200)
ok("button turns into Pause", "Pause" in pg.inner_text("#pt-play"))
# tap Start here while playing: pauses and takes the player's exact frame
pg.evaluate("setTimeout(()=>ForgeDock.position(183, 900, 's'), 120)")
pg.click("#pt-start"); w(600)
ok("Start here pauses", "pause" in [a.get("action") for a in s.native.dock_args])
ok("start = exact frame (3.05 s → 3.1)", pg.inner_text("#pt-start-v") == "0:03.1", pg.inner_text("#pt-start-v"))
# fine steps
pg.click("#pt-prev"); w(300); pg.click("#pt-prev"); w(300)
ok("◀ 0.1 s steps back and shows that frame", seeks()[-1]["frame"] == round(2.9 * 60) and seeks()[-1]["play"] is False, seeks()[-1])
pg.click("#pt-start"); w(400)
ok("Start here while paused uses the shown frame", pg.inner_text("#pt-start-v") == "0:02.9", pg.inner_text("#pt-start-v"))
# end before start is refused
pg.click("#pt-back"); w(300); pg.click("#pt-end"); w(400)
ok("an end before the start is refused", pg.inner_text("#pt-end-v") != "0:00.0" and "after the start" in pg.inner_text("#toast"), pg.inner_text("#toast"))
pg.click("#pt-play"); w(200); pg.evaluate("ForgeDock.position(500, 900, 'p')"); w(200)
pg.evaluate("setTimeout(()=>ForgeDock.position(540, 900, 's'), 120)")
pg.click("#pt-end"); w(600)
ok("End here", pg.inner_text("#pt-end-v") == "0:09.0", pg.inner_text("#pt-end-v"))
ok("shows what it keeps", "6.1 s" in pg.inner_text("#pt-keeps"), pg.inner_text("#pt-keeps"))
pg.screenshot(path=OUT + "2-marked.png")
s.native.dock_args = []
pg.click("#pt-watch"); w(300)
ok("Watch my part starts at the start", seeks() and seeks()[-1]["frame"] == round(2.9 * 60) and seeks()[-1]["play"], seeks()[-1:])
pg.evaluate("ForgeDock.position(%d, 900, 'p')" % (9 * 60 + 1)); w(300)
ok("…and stops at the end", "pause" in [a.get("action") for a in s.native.dock_args])
pg.click("#pt-done"); w(1000)
ok("Done keeps the part", clips() == [[2.9, 9.0]], clips())
ok("part card shows the times", "0:02.9 → 0:09.0" in pg.inner_text('.pt-card[data-pt="0"]'), pg.inner_text('.pt-card[data-pt="0"]').replace("\n", " | "))
# second part, keep whole
add("Final Flash"); pg.evaluate("ForgeDock.position(0, 900, 's')"); w(200)
pg.click("#pt-whole"); w(200); pg.click("#pt-done"); w(1000)
ok("second part, whole move", len(clips()) == 2 and clips()[1][0] == 0, clips())
ok("card says the whole move", "The whole move" in pg.inner_text('.pt-card[data-pt="1"]'))
pg.screenshot(path=OUT + "3-parts.png", full_page=True)
# change part later via the card
pg.click('[data-pt-choose="0"]'); w(500)
ok("✂ Choose the part reopens with the marks", pg.inner_text("#pt-start-v") == "0:02.9" and pg.inner_text("#pt-end-v") == "0:09.0")
pg.evaluate("document.querySelectorAll('dialog[open]').forEach(d=>d.querySelector('[aria-label=\"Close picker\"]')?.click())"); w(300)
# menu
pg.click('[data-pt-menu="0"]'); w(400); pg.click('[data-sl-act="down"]'); w(800)
ok("play it later", clips()[1] == [2.9, 9.0], clips())
pg.click('[data-pt-menu="1"]'); w(400); pg.click('[data-sl-act="copy"]'); w(800)
ok("use another part of the move opens the chooser on the copy", len(clips()) == 3 and pg.locator("#pt").count() == 1, clips())
pg.evaluate("document.querySelectorAll('dialog[open]').forEach(d=>d.querySelector('[aria-label=\"Close picker\"]')?.click())"); w(300)
pg.click('[data-pt-menu="2"]'); w(400); pg.click('[data-sl-act="remove"]'); w(800)
ok("remove", len(clips()) == 2, clips())
# whole animation
s.native.last_preview = None
pg.click("#tl-play"); w(500)
lp = s.native.last_preview or {}
ok("Play my animation plays all parts", lp.get("startPaused") is False and "text" in lp, lp.get("startAt"))
print("errors:", errs[:3])
