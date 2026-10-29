"""Phone screenshots of the main screens for a visual review."""
import os
os.environ["FORGE_STATE"] = "/home/claude/work/harness/state-v2shots"; os.environ["FRESH"] = "1"
from harness import Session
SP = "/tmp/claude-0/-home-claude/fc61b99f-cb57-56bc-b827-ee4cb4796a4c/scratchpad/v2/"
os.makedirs(SP, exist_ok=True)
s = Session(viewport=(412, 915)).open(); pg = s.page; w = lambda ms=700: pg.wait_for_timeout(ms)
while pg.evaluate("window.__forgeWorkspaceStartup") != "ready": w(100)
w(800); pg.screenshot(path=SP + "01-home.png")
pg.evaluate("createUnit(1018721)")
for _ in range(100):
    if pg.evaluate("state.view==='editor' && document.getElementById('busy').hidden"): break
    w(200)
w(1200); pg.screenshot(path=SP + "02-basics.png")
for i, t in enumerate(["leader", "passive", "supers", "active", "transform", "links", "look", "save"]):
    if pg.locator(f'[data-b="tab:{t}"]').count():
        pg.locator(f'[data-b="tab:{t}"]').first.click(); w(1200)
        pg.screenshot(path=SP + f"{i+3:02d}-{t}.png", full_page=True)
pg.evaluate("navigate('library')"); w(1500); pg.screenshot(path=SP + "20-library.png", full_page=True)
pg.evaluate("navigate('animations')"); w(2000); pg.screenshot(path=SP + "21-animate.png")
pg.evaluate("navigate('ai')"); w(1500); pg.screenshot(path=SP + "22-ai.png", full_page=True)
print("errors", len(s.errors), s.errors[:2])
s.close()
