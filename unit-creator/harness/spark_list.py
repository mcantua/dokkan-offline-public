import os
os.environ["FORGE_STATE"] = "/home/claude/work/harness/state-v2shots"
from harness import Session
SP = "/tmp/claude-0/-home-claude/fc61b99f-cb57-56bc-b827-ee4cb4796a4c/scratchpad/v2/"
s = Session(viewport=(412, 915)).open(); pg = s.page; w = lambda ms=700: pg.wait_for_timeout(ms)
while pg.evaluate("window.__forgeWorkspaceStartup") != "ready": w(100)
pg.evaluate("navigate('library')"); w(1500); pg.locator('[data-library-filter="sparking"]').click(); w(3000)
txt = pg.inner_text("#main")
i = txt.find("Sparking characters"); print(txt[i:i+600].replace("\n", " | "))
inp = pg.locator('#main input[placeholder*="Ultra Vegito"]')
print("search box:", inp.count())
if inp.count():
    inp.first.fill("Super Saiyan 3 Vegeta (DAIMA)"); w(4000)
    t = pg.inner_text("#main"); i = t.find("Find a Sparking"); print(t[i:i+700].replace("\n", " | "))
print("errors", s.errors[:2])
s.close()
