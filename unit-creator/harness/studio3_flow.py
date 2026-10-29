"""Simple Animation editor: build a two-clip animation, trim it, use it for a Super Attack and a
counter, then export and check the patch."""
import os, json, subprocess
os.environ["FORGE_STATE"] = "/home/claude/work/harness/state-studio3"; os.environ["FRESH"] = "1"
from harness import Session
SP = "/tmp/claude-0/-home-claude/fc61b99f-cb57-56bc-b827-ee4cb4796a4c/scratchpad/"
s = Session(viewport=(412, 915)).open(); pg = s.page; w = lambda ms=600: pg.wait_for_timeout(ms)
while pg.evaluate("window.__forgeWorkspaceStartup") != "ready": w(100)
pg.evaluate("createUnit(1018721)")
for _ in range(100):
    if pg.evaluate("state.view==='editor' && document.getElementById('busy').hidden"): break
    w(200)
w(800)
# counter through the passive tab
pg.locator('[data-b="tab:passive"]').first.click(); w(); pg.locator('[data-b="adding:on"]').click(); w(300)
pg.locator('[data-guide="add-counter"]').click(); w(1500)
if pg.locator('[data-studio^="counter-profile:"]').count(): pg.locator('[data-studio^="counter-profile:"]').first.click(); w(2500)
pg.evaluate("document.querySelectorAll('dialog[open]').forEach(d=>d.close())")
pg.evaluate("navigate('animations')"); w(2000)
def add(term):
    pg.locator('[data-studio="browse"]').first.click(); w(1500)
    pg.select_option("#studio-kind", "all"); w(1200)
    pg.fill("#studio-search", term); w(2500)
    n = pg.locator('#studio-results [data-studio^="add:"]').count()
    print("results for", term, n)
    pg.locator('#studio-results [data-studio^="add:"]').first.click(); w(1500)
    pg.evaluate("document.querySelectorAll('dialog.sequence-picker[open]').forEach(d=>d.querySelector('[aria-label=\"Close picker\"]')?.click())"); w(400)
add("Kamehameha"); add("Final Flash")
print("summary:", pg.inner_text("#simple-sequence-summary"))
pg.locator(".tl-clip").nth(0).click(); w(300); pg.click('.tl-tool[data-tl="trim"]'); w(500)
pg.locator("dialog.sequence-picker[open] .trim-to .trim-value").click(); pg.keyboard.press("Control+A"); pg.keyboard.type("1.5"); pg.keyboard.press("Enter"); w(600)
pg.click("dialog.sequence-picker[open] [data-tl-sheet='done']"); w(300)
print("after trim:", pg.inner_text("#simple-sequence-summary"))
pg.screenshot(path=SP + "studio3-compose.png", full_page=True)
pg.click('#tl-save'); w(400); pg.locator('dialog.sequence-picker[open] [data-studio="assign"]').click(); w(1500)
dlg = pg.locator("#dialog[open]")
print("assign dialog:", dlg.inner_text()[:600].replace("\n", " | ") if dlg.count() else "none")
pg.screenshot(path=SP + "studio3-assign.png")
if dlg.count() and pg.locator("#dialog select").count():
    sel = pg.locator("#dialog select").first; opts = sel.locator("option").all_inner_texts(); print("targets:", opts)
    idx = [i for i, o in enumerate(opts) if o.lower().startswith("super")] or [0]
    sel.select_option(index=idx[0]); w(300)
    btns = pg.evaluate("[...document.querySelectorAll('#dialog button')].filter(b=>b.offsetParent).map(b=>b.textContent.trim())"); print("dialog buttons:", btns)
    for b in pg.locator("#dialog button").all():
        t = b.inner_text().strip()
        if t.lower().startswith(("use", "assign", "apply", "save")) and b.is_visible(): b.click(); w(2500); break
print("assignments:", pg.evaluate("Object.keys(state.project.animationAssignments||{})"))
print("errors:", pg.evaluate("Forge.validate(state.project).errors"))
sql = pg.evaluate("Forge.sql(state.project)"); open(SP + "studio3.sql", "w").write(sql)
print(subprocess.run(["python3", "apply_sql.py", SP + "studio3.sql"], capture_output=True, text=True).stdout.strip().splitlines()[-1:])
print(subprocess.run(["python3", "-c", f"exec(open('overwrite_check.py').read().split('def main')[0]);print(check(open('{SP}studio3.sql').read()))"], capture_output=True, text=True).stdout.strip())
# full export through the app's own Save flow
pg.evaluate("ForgeBuilderUI && (state.builder=true)"); pg.evaluate("navigate('editor')"); w(1500)
if pg.locator('[data-b="tab:save"]').count():
    pg.locator('[data-b="tab:save"]').first.click(); w(800)
    if pg.locator('[data-export="eclp"]').count(): pg.locator('[data-export="eclp"]').first.click(); w(6000)
print("exports:", s.native.exports[-1:] if s.native.exports else [])
s.report("studio3"); s.close()
