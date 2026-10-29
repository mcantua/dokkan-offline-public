import os, json
os.environ["FORGE_STATE"] = "/home/claude/work/harness/state-studio3"
from harness import Session
s = Session(viewport=(412, 915)).open(); pg = s.page
while pg.evaluate("window.__forgeWorkspaceStartup") != "ready": pg.wait_for_timeout(100)
for args in [{"search":"Kamehameha","kind":"all","offset":0},{"search":"","kind":"all","offset":0}]:
    try: r = pg.evaluate("a=>Native.call('animationCatalog',a)", args); print(json.dumps(r)[:600])
    except Exception as e: print("ERR", str(e)[:300])
print(s.native.log[-5:])
s.close()
