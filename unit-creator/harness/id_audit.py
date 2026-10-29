"""Find visible internal numbers/IDs on every main screen and Card Builder step."""
import os, re, json
os.environ["FORGE_STATE"] = "/home/claude/work/harness/state-idaudit"; os.environ["FRESH"] = "1"
from harness import Session
s = Session(viewport=(412, 915)).open(); pg = s.page; w = lambda ms=600: pg.wait_for_timeout(ms)
while pg.evaluate("window.__forgeWorkspaceStartup") != "ready": w(100)
PAT = re.compile(r"(\b(?:ID|id)\b[^\n]{0,30}|\b\d{6,10}\b|#\d{3,}|\bview \d+|\bset \d+|\bcategory \d+|Category \d+|Link \d+)")
found = {}
def scan(label):
    txt = pg.evaluate("document.body.innerText")
    hits = sorted(set(m.group(0).strip() for m in PAT.finditer(txt)))
    hits = [h for h in hits if not re.fullmatch(r"\d{1,3}(,\d{3})+", h)]
    if hits: found[label] = hits[:12]
pg.evaluate("createUnit(1018721)")
for _ in range(200):
    if pg.evaluate("state.view==='editor' && !!state.project && document.getElementById('busy').hidden"): break
    w(100)
w(1000)
for tab in ["basics", "leader", "passive", "supers", "active", "transform", "links", "look", "save"]:
    try:
        pg.locator(f'[data-b="tab:{tab}"]').first.click(); w(1200)
        pg.evaluate("document.querySelectorAll('#bld details').forEach(d=>d.open=true)"); w(300)
        scan("builder:" + tab)
    except Exception as e:
        found["builder:" + tab] = ["(error) " + str(e)[:80]]
for nav in ["home", "library", "animations", "assets", "source"]:
    try:
        pg.evaluate(f"navigate('{nav}')"); w(1800); scan("view:" + nav)
    except Exception as e:
        found["view:" + nav] = ["(error) " + str(e)[:80]]
print(json.dumps(found, indent=1))
