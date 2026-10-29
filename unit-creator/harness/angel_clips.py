"""Independent animation: preview and add every Goku & Vegeta (Angel) clip (the CDN 404 report)."""
import os, json
os.environ["FORGE_STATE"] = "/home/claude/work/harness/state-angel"; os.environ["FRESH"] = "1"
from harness import Session
s = Session(viewport=(412, 915)).open(); pg = s.page; w = lambda ms=600: pg.wait_for_timeout(ms)
while pg.evaluate("window.__forgeWorkspaceStartup") != "ready": w(100)
src = []; orig = s.native.call
def wrap(m, a):
    if m in ("animationSource", "previewAnimation"): src.append((m, a.get("path")))
    return orig(m, a)
s.native.call = wrap
pg.evaluate("navigate('animations')"); w(2000)
if pg.locator('[data-studio="gallery-new"]').count(): pg.locator('[data-studio="gallery-new"]').first.click(); w(1500)
pg.evaluate("document.querySelectorAll('dialog#dialog[open]').forEach(d=>{const b=[...d.querySelectorAll('button')].find(b=>/create|start|ok/i.test(b.textContent));b&&b.click()})"); w(1200)
pg.locator('[data-studio="browse"]').first.click(); w(1500)
pg.select_option("#studio-kind", "all"); w(1000)
fails = 0
def search(term):
    if not pg.locator("dialog.sequence-picker[open]").count():
        pg.locator('[data-studio="browse"]').first.click(); w(1200); pg.select_option("#studio-kind", "all"); w(800)
    pg.fill("#studio-search", term); w(2200)
for term in ["Special Fusion", "Vegeta's Pride", "Cooperation Between Rivals", "Final Kamehameha"]:
    for act in ("preview", "add"):
        search(term)
        name = pg.evaluate("document.querySelector('#studio-results .animation-tile h3')?.textContent")
        pg.evaluate("document.getElementById('toast').textContent=''"); src.clear()
        pg.locator(f'#studio-results [data-studio="{act}:0"]').first.click(); w(1500)
        t = pg.inner_text("#toast").strip(); bad = "404" in t or "not in Eclipse" in t; fails += bad
        print(f"{str(name)[:36]:36} {act:7} {src[-1:]} {'FAIL '+t[:90] if bad else 'ok'}")
pg.evaluate("document.querySelectorAll('dialog[open]').forEach(d=>d.close())"); w(500)
print("summary:", pg.inner_text("#simple-sequence-summary") if pg.locator("#simple-sequence-summary").count() else "?")
print("fails:", fails, "errors:", s.errors[:2])
s.close()
