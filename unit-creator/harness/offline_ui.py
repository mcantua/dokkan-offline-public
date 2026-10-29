"""Offline downloads dialog, progress pill, player setting and Back handling for the in-app player."""
import os, json
os.environ["FORGE_STATE"] = "/home/claude/work/harness/state-offline"; os.environ["FRESH"] = "1"
from harness import Session
SP = "/tmp/claude-0/-home-claude/fc61b99f-cb57-56bc-b827-ee4cb4796a4c/scratchpad/"
s = Session(viewport=(412, 915)).open(); pg = s.page; w = lambda ms=600: pg.wait_for_timeout(ms)
while pg.evaluate("window.__forgeWorkspaceStartup") != "ready": w(100)
pg.evaluate("createUnit(1018721)")
for _ in range(100):
    if pg.evaluate("state.view==='editor' && document.getElementById('busy').hidden"): break
    w(200)
w(1500)
print("projects:", len(s.native.m_projects({})))
pg.evaluate("navigate('animations')"); w(1500)
# Downloads live under More → Download game files (no longer repeated in the Animate menu)
pg.evaluate("document.querySelector('.shell-more-button').click()"); w(500)
pg.locator('#shell-more [data-shell-go="offline"]').click(); w(1200)
print("dialog:", pg.inner_text("#dialog-content")[:500].replace("\n", " | "))
pg.screenshot(path=SP + "offline-dialog.png", full_page=False)
pg.check('[data-pack="units"]'); w(300)
pg.click("#offline-start"); w(8000)
print("start call:", [c for c in s.native.offline_calls if c.get("action")=="start"])
print("pill:", pg.evaluate("document.getElementById('offline-pill')&&[document.getElementById('offline-pill').hidden,document.getElementById('offline-pill').textContent]"))
print("phase:", pg.inner_text("#offline-phase"), "|", pg.inner_text("#offline-detail"))
pg.screenshot(path=SP + "offline-running.png")
w(4000)
print("after:", pg.inner_text("#offline-phase"), "|", pg.evaluate("[...document.querySelectorAll('[data-done]')].map(e=>e.textContent)"))
# settings
pg.evaluate("document.querySelector('.offline-more').open=true"); w(300)
pg.check('[name="offline-player"][value="window"]'); w(500)
print("dock setting:", s.native.dock)
pg.check("#offline-mode"); w(500)
print("offline mode:", getattr(s.native, "cache_offline", None))
pg.click("#dialog-close"); w(500)
pg.evaluate("document.querySelectorAll('dialog.sequence-picker[open]').forEach(d=>d.querySelector('[aria-label=\"Close picker\"]')?.click())"); w(300)
# Back: full -> docked -> closed, dialogs first
s.native.dock.update(open=True, full=True)
pg.evaluate("ForgeDock.native('full')")
r1 = pg.evaluate("forgeHandleBack()"); w(300)
r2 = pg.evaluate("forgeHandleBack()"); w(300)
print("back results:", r1, r2, "state:", pg.evaluate("ForgeDock.state()"), "calls:", s.native.dock_calls[-3:], "dock:", s.native.dock)
print("view after backs:", pg.evaluate("state.view"))
print("errors:", s.errors[:3])
s.close()
