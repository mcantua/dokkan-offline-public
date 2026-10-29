import os
os.environ["FORGE_STATE"] = "/home/claude/work/harness/state-v2shots"
from harness import Session
SP = "/tmp/claude-0/-home-claude/fc61b99f-cb57-56bc-b827-ee4cb4796a4c/scratchpad/v2/"
s = Session(viewport=(412, 915)).open(); pg = s.page; w = lambda ms=700: pg.wait_for_timeout(ms)
while pg.evaluate("window.__forgeWorkspaceStartup") != "ready": w(100)
pg.locator("[data-open]").first.click(); w(2500)
pg.locator('[data-b="tab:look"]').first.click(); w(1000)
for label in ["Customize in-game artwork", "Customize battle poses", "Use another character", "Choose editor preview image", "Create art with AI"]:
    b = pg.locator(f'#main button:has-text("{label}")')
    if not b.count(): print("missing", label); continue
    before = len(s.errors)
    b.first.click(); w(2500)
    d = pg.locator("dialog[open]")
    print(label, "->", d.first.inner_text()[:220].replace("\n", " | ") if d.count() else pg.inner_text("#main")[:200].replace("\n", " | "), "ERR" if len(s.errors) > before else "")
    pg.screenshot(path=SP + "art-" + label.split()[0] + ".png")
    pg.evaluate("document.querySelectorAll('dialog[open]').forEach(d=>d.close())"); w(300)
    if pg.evaluate("state.view") != "editor": pg.evaluate("navigate('editor')"); w(1500); pg.locator('[data-b="tab:look"]').first.click(); w(800)
print("errors", s.errors[:3]); print([c for c in s.console if "TOAST" in c][:5])
s.close()
