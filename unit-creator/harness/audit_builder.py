import os
os.environ["FORGE_STATE"] = "/home/claude/work/harness/state-audit2"; os.environ["FRESH"] = "1"
from harness import Session
OUT = "/tmp/claude-0/audit/"
s = Session(viewport=(412, 915)).open(); pg = s.page; w = lambda ms=600: pg.wait_for_timeout(ms)
while pg.evaluate("window.__forgeWorkspaceStartup") != "ready": w(100)
pg.evaluate("createUnit(1018721)")
for _ in range(100):
    if pg.evaluate("state.view==='editor' && document.getElementById('busy').hidden"): break
    w(200)
w(1000)
tabs = pg.evaluate("[...document.querySelectorAll('.bld-tabs button')].map(b=>b.innerText.replace(/\\n/g,' '))")
print("tabs:", tabs)
for i in range(1, len(tabs)):
    pg.evaluate(f"document.querySelectorAll('.bld-tabs button')[{i}].click()"); w(1200)
    pg.evaluate("document.getElementById('toast')?.classList.remove('show')")
    pg.screenshot(path=OUT + f"06-bld-{i}.png", full_page=True)
    print(i, tabs[i], pg.evaluate("document.documentElement.scrollHeight"))
