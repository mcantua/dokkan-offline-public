"""Timeline editor fixes: other previews take over the window; commands while loading; player failure;
no auto-reopen after closing; separate-window setting; pick mode cleared by ×."""
import os
os.environ["FORGE_STATE"] = "/home/claude/work/harness/state-tlfix"; os.environ["FRESH"] = "1"
from harness import Session
s = Session(viewport=(412, 520)).open(); pg = s.page; w = lambda ms=600: pg.wait_for_timeout(ms)
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
w(2200)
# monitor opened (loading). Tap play while loading → no seek yet, queued
s.native.dock_calls = []
pg.evaluate("ForgeDock.native('docked')"); w(200)
pg.click("#tl-play"); w(300)
ok("play while loading is queued", "seek" not in s.native.dock_calls, s.native.dock_calls)
pg.evaluate("ForgeDock.position(0, 1800, 's')"); w(400)
ok("queued play sent when ready", "seek" in s.native.dock_calls, s.native.dock_calls)
pg.evaluate("ForgeDock.position(120, 1800, 'p')"); w(200)
clock = pg.inner_text("#tl-clock")
# another preview (picker ▶ Watch) takes over: timeline no longer follows it
pg.evaluate("Native.call('previewAnimation',{name:'x',text:'-- x'}).catch(()=>{})"); w(300)
pg.evaluate("ForgeDock.position(1500, 3000, 'p')"); w(300)
ok("other preview not followed", pg.inner_text("#tl-clock") == clock, (clock, pg.inner_text("#tl-clock")))
# play reopens our own timeline
n = len(s.native.previews) if hasattr(s.native, "previews") else None
lp_before = s.native.last_preview
pg.click("#tl-play"); w(500)
ok("play reopens the timeline", s.native.last_preview is not lp_before and (s.native.last_preview or {}).get("dockSize") == "small")
# player failure resets the editor
pg.evaluate("ForgeDock.position(0, 1800, 's')"); w(200)
pg.evaluate("ForgeDock.native('failed')"); w(300)
ok("failure resets play button", pg.inner_text("#tl-play").startswith("▶") and not pg.evaluate("document.getElementById('tl-play').classList.contains('tl-loading')"))
# closed window is not reopened by an edit
pg.evaluate("ForgeDock.native('closed')"); w(200)
lp_before = s.native.last_preview
pg.locator('[data-pt-menu="0"]').click(); w(400); pg.locator('[data-sl-act="down"]').click(); w(2000)
ok("edit doesn't reopen a closed window", s.native.last_preview is lp_before)
# separate window: entering the editor doesn't auto-open a full-screen preview
pg.evaluate("ForgeDock.separateWindow(true)"); w(300)
pg.locator(".mobile-nav button", has_text="Home").first.click(); w(800)
lp_before = s.native.last_preview
pg.locator(".mobile-nav button", has_text="Animate").first.click(); w(2000)
ok("separate window: no auto preview", s.native.last_preview is lp_before)
pg.evaluate("ForgeDock.separateWindow(false)"); w(300)
print("errors:", errs[:3])
