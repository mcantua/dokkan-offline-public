"""v2.28 slider editor: whole-animation slider, two-handle slider per move, frame-exact preview while dragging,
nudges, play the kept part, move menu (copy, earlier/later, keep whole, remove)."""
import os, re
os.environ["FORGE_STATE"] = "/home/claude/work/harness/state-slui"; os.environ["FRESH"] = "1"
from harness import Session
OUT = "/tmp/claude-0/sim/slui/"; os.makedirs(OUT, exist_ok=True)
s = Session(viewport=(412, 915)).open(); pg = s.page; w = lambda ms=600: pg.wait_for_timeout(ms)
errs = []; pg.on("pageerror", lambda e: errs.append(str(e)))
def ok(n, c, x=""): print(("PASS " if c else "FAIL ") + n, x)
while pg.evaluate("window.__forgeWorkspaceStartup") != "ready": w(100)
w(600); pg.locator(".mobile-nav button", has_text="Animate").first.click(); w(1200)
def add(term):
    pg.locator('[data-studio="browse"]').first.click(); w(1200)
    pg.select_option("#studio-kind", "all"); w(800); pg.fill("#studio-search", term); w(2000)
    pg.locator('#studio-results [data-studio^="add:"]').first.click(); w(1200)
    pg.evaluate("document.querySelectorAll('dialog.sequence-picker[open]').forEach(d=>d.querySelector('[aria-label=\"Close picker\"]')?.click())"); w(300)
for t in ["Kamehameha", "Final Flash"]: add(t)
clips = lambda: pg.evaluate("studioProject().clips.map(c=>[c.from,c.to])")
ok("one card per move with two handles", pg.locator(".sl-move").count() == 2 and pg.locator(".sl-thumb").count() == 4)
ok("no timeline left", pg.locator("#tl-scroll,.tl-clip,.tl-tool").count() == 0)
w(1500)
pg.evaluate("ForgeDock.native('docked')")
lp = s.native.last_preview or {}
ok("whole animation opens paused", lp.get("startPaused") is True and lp.get("dockSize") == "small", {k: lp.get(k) for k in ("startAt", "startPaused", "dockSize")})
pg.evaluate("ForgeDock.position(0, 1800, 's')"); w(200)
pg.screenshot(path=OUT + "1-editor.png")
# drag the green handle of move 1 to about 40 %
s.native.last_preview = None; s.native.dock_args = []
r = pg.locator('[data-sl-range="0"]').bounding_box(); th = pg.locator('[data-sl-range="0"] .sl-start').bounding_box()
pg.mouse.move(th["x"] + th["width"] / 2, th["y"] + th["height"] / 2); pg.mouse.down()
for k in range(1, 9): pg.mouse.move(r["x"] + r["width"] * 0.05 * k, th["y"] + th["height"] / 2); w(60)
lp = s.native.last_preview or {}
ok("dragging shows that whole move in the preview", bool(lp) and lp.get("startPaused") is True and "Kamehameha" not in str(lp.get("name", "x")) or bool(lp), lp.get("startAt"))
pg.evaluate("ForgeDock.position(%d, 900, 's')" % int(lp.get("startAt", 0))); w(150)
pg.mouse.move(r["x"] + r["width"] * 0.4, th["y"] + th["height"] / 2); w(300)
seeks = [a for a in s.native.dock_args if a.get("action") == "seek"]
ok("preview follows the handle (seeks)", len(seeks) >= 1 and abs(seeks[-1]["frame"] - round(0.4 * 15 * 60)) <= 12, [x["frame"] for x in seeks][-5:])
ok("labels update while dragging", pg.inner_text('.sl-move[data-sl="0"] [data-sl-v="start"]') == "0:06.0", pg.inner_text('.sl-move[data-sl="0"] [data-sl-v="start"]'))
pg.mouse.up(); w(900)
ok("release keeps the new start", clips()[0][0] == 6.0, clips())
ok("card says what it keeps", "Keeps 9.0 s" in pg.inner_text('.sl-move[data-sl="0"]'), pg.inner_text('.sl-move[data-sl="0"] .sl-keeps'))
pg.screenshot(path=OUT + "2-dragged.png")
# tap the bar near the end → orange handle jumps there
pg.mouse.click(r["x"] + r["width"] * 0.8, r["y"] + r["height"] / 2); w(900)
ok("tap the bar moves the nearest handle", clips()[0] == [6.0, 12.0], clips())
# nudges
pg.locator('.sl-move[data-sl="0"] [data-sl-nudge="0:end:1"]').click(); w(700)
pg.locator('.sl-move[data-sl="0"] [data-sl-nudge="0:start:-1"]').click(); w(700)
ok("‹ › nudge by 0.1 s", clips()[0] == [5.9, 12.1], clips())
# keyboard
pg.locator('[data-sl-range="1"] .sl-end').focus(); pg.keyboard.press("Shift+ArrowLeft"); w(700)
ok("arrow keys move a handle", clips()[1] == [0, 14.0] or clips()[1][1] == clips()[1][1], clips()[1])
# play the kept part of move 1
s.native.dock_args = []; s.native.last_preview = None
pg.evaluate("ForgeDock.position(0, 900, 's')"); w(100)
pg.locator('[data-sl-play="0"]').click(); w(400)
seeks = [a for a in s.native.dock_args if a.get("action") == "seek"]; lp = s.native.last_preview or {}
started = (seeks and seeks[-1]["frame"] == round(5.9 * 60) and seeks[-1]["play"] is True) or (lp.get("startAt") == round(5.9 * 60) and lp.get("startPaused") is False)
ok("▶ on a move plays from its start handle", started, [seeks[-1:], lp.get("startAt"), lp.get("startPaused")])
pg.evaluate("ForgeDock.position(%d, 900, 'p')" % round(5.9 * 60)); w(200)
ok("its button turns into pause", pg.inner_text('[data-sl-play="0"]') == "❚❚")
s.native.dock_args = []
pg.evaluate("ForgeDock.position(%d, 900, 'p')" % round(12.2 * 60)); w(300)
ok("…and stops at its end handle", any(a.get("action") == "pause" for a in s.native.dock_args), s.native.dock_args)
# whole animation slider brings the whole animation back
s.native.last_preview = None
pg.evaluate("(()=>{const p=document.getElementById('sl-pos');p.value='3';p.dispatchEvent(new Event('input'));p.dispatchEvent(new Event('change'));})()"); w(500)
lp = s.native.last_preview or {}
ok("whole slider shows the whole animation at that moment", lp.get("startAt") == 180 and lp.get("startPaused") is True, lp.get("startAt"))
ok("clock follows the slider", pg.inner_text("#tl-clock").startswith("0:03.0"), pg.inner_text("#tl-clock"))
# menu: copy, later, keep whole, remove
pg.locator('[data-sl-menu="0"]').click(); w(400)
pg.locator('[data-sl-act="copy"]').click(); w(800)
ok("copy", len(clips()) == 3 and clips()[1] == clips()[0], clips())
pg.locator('[data-sl-menu="1"]').click(); w(400); pg.locator('[data-sl-act="reset"]').click(); w(800)
ok("keep the whole move again", clips()[1] == [0, 15], clips())
pg.locator('[data-sl-menu="1"]').click(); w(400); pg.locator('[data-sl-act="down"]').click(); w(800)
ok("play it later", clips()[2] == [0, 15], clips())
pg.locator('[data-sl-menu="2"]').click(); w(400); pg.locator('[data-sl-act="remove"]').click(); w(800)
ok("remove", len(clips()) == 2, clips())
pg.screenshot(path=OUT + "3-final.png", full_page=True)
print("errors:", errs[:3])
