import os, collections
os.environ.setdefault("FORGE_STATE","/home/claude/work/harness/state-builder")
from harness import Session
SP="/tmp/claude-0/-home-claude/fc61b99f-cb57-56bc-b827-ee4cb4796a4c/scratchpad/"
s=Session(viewport=(412,915)).open(); pg=s.page
while pg.evaluate("window.__forgeWorkspaceStartup")!="ready": pg.wait_for_timeout(100)
pg.wait_for_timeout(300)
pg.click("#db-quick"); pg.wait_for_timeout(800)
pg.fill("#qc-search","Legendary Super Saiyan Broly"); pg.wait_for_timeout(2000)
print("qc:", pg.inner_text("#qc-results").replace("\n"," | ")[:500])
pg.screenshot(path=SP+"qc.png")
pg.keyboard.press("Escape"); pg.wait_for_timeout(300)
pg.evaluate("ForgeQuickCreate.ezaChoice()"); pg.wait_for_timeout(300); pg.click("#ez-seza"); pg.wait_for_timeout(800)
pg.fill("#guide-unit-search","Goku"); pg.wait_for_timeout(2500)
print("eza picker:", pg.inner_text("#guide-unit-range"), pg.locator(".guide-pick").count(), "badges", pg.locator(".guide-pick .cv-badge").count())
pg.screenshot(path=SP+"eza.png")
pg.check("#guide-unit-all"); pg.wait_for_timeout(1500)
print("all:", pg.inner_text("#guide-unit-range"))
print(collections.Counter(c.split(" @")[0][:90] for c in s.console).most_common(5))
s.report("vui"); s.close()
