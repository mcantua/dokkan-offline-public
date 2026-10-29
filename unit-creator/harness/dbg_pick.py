import os, json
os.environ["FORGE_STATE"] = "/home/claude/work/harness/state-studio3"
from harness import Session
SP = "/tmp/claude-0/-home-claude/fc61b99f-cb57-56bc-b827-ee4cb4796a4c/scratchpad/"
s = Session(viewport=(412, 915)).open(); pg = s.page; w=lambda ms=600: pg.wait_for_timeout(ms)
while pg.evaluate("window.__forgeWorkspaceStartup") != "ready": w(100)
pg.locator("[data-open]").first.click(); w(2000)
pg.evaluate("navigate('animations')"); w(2000)
pg.locator('[data-studio="browse"]').first.click(); w(2500)
print("before search:", pg.inner_text("#studio-results")[:300].replace("\n"," | "))
pg.fill("#studio-search", "Kamehameha"); w(3000)
print("after:", pg.inner_text("#studio-results")[:500].replace("\n"," | "))
print("btns:", pg.evaluate("[...document.querySelectorAll('#studio-results [data-studio]')].slice(0,6).map(b=>b.dataset.studio+'|'+b.textContent)"))
print("ids:", pg.evaluate("document.querySelectorAll('#studio-results').length"))
pg.screenshot(path=SP+"dbg-pick.png")
print(s.errors[:3]); print([c for c in s.console if 'TOAST' in c][:3])
s.close()
