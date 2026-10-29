import os, json
os.environ["FORGE_STATE"] = "/home/claude/work/harness/state-dbgadd"; os.environ["FRESH"]="1"
from harness import Session
s = Session(viewport=(412, 915)).open(); pg = s.page; w=lambda ms=600: pg.wait_for_timeout(ms)
while pg.evaluate("window.__forgeWorkspaceStartup") != "ready": w(100)
calls=[]; orig=s.native.call
def wrap(m,a):
    calls.append((m, json.dumps(a)[:300]))
    return orig(m,a)
s.native.call=wrap
pg.evaluate("navigate('animations')"); w(2500)
pg.locator('[data-studio="browse"]').first.click(); w(1500)
pg.fill("#studio-search", "Goku & Vegeta (Angel)"); w(2500)
calls.clear()
pg.locator('#studio-results [data-studio^="add:"]').first.click(); w(3000)
for c in calls: print("ADD", c)
calls.clear()
pg.evaluate("document.querySelectorAll('dialog[open]').forEach(d=>d.close())")
print("clips:", pg.inner_text("#simple-sequence-summary") if pg.locator("#simple-sequence-summary").count() else "?")
print([c for c in s.console if "TOAST" in c][:3])
s.close()
