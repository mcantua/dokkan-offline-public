import os
os.environ["FORGE_STATE"] = "/home/claude/work/harness/state-tlshot"; os.environ["FRESH"] = "1"
from harness import Session
s = Session(viewport=(412, 493)).open(); pg = s.page; w = lambda ms=600: pg.wait_for_timeout(ms)
while pg.evaluate("window.__forgeWorkspaceStartup") != "ready": w(100)
w(600); pg.locator(".mobile-nav button", has_text="Animate").first.click(); w(1200)
def add(term):
    pg.locator('[data-studio="browse"]').first.click(); w(1200)
    pg.select_option("#studio-kind", "all"); w(800); pg.fill("#studio-search", term); w(2000)
    pg.locator('#studio-results [data-studio^="add:"]').first.click(); w(1200)
    pg.evaluate("document.querySelectorAll('dialog.sequence-picker[open]').forEach(d=>d.querySelector('[aria-label=\"Close picker\"]')?.click())"); w(300)
for t in ["Kamehameha", "Final Flash", "Galick"]: add(t)
pg.evaluate("studioProject().clips[0].to=3.2;studioProject().clips[1].from=1;studioProject().clips[1].to=3.5;studioProject().clips[2].to=4.1;studioChange();renderStudioTimeline()"); w(300)
pg.evaluate("ForgeDock.native('docked'); ForgeDock.position(Math.round(4.2*60), 600, 'p')"); w(300)
pg.locator(".tl-clip").nth(1).click(); w(300)
pg.evaluate("document.getElementById('toast')?.classList.remove('show')"); w(400)
pg.screenshot(path="/tmp/claude-0/sim/anim/tl-phone.png")
