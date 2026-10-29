import os, json, subprocess
os.environ["FORGE_STATE"] = "/home/claude/work/harness/state-pcopy"; os.environ["FRESH"] = "1"
from harness import Session
SP = "/tmp/claude-0/-home-claude/fc61b99f-cb57-56bc-b827-ee4cb4796a4c/scratchpad/"
SRC = int(os.environ.get("SRC", "1018651")); DONOR = os.environ.get("DONOR", "Gohan (Beast)")
s = Session(viewport=(412, 915)).open(); pg = s.page
while pg.evaluate("window.__forgeWorkspaceStartup") != "ready": pg.wait_for_timeout(100)
pg.evaluate(f"createUnit({SRC})")
for _ in range(100):
    if pg.locator("#bld").count() and pg.evaluate("document.getElementById('busy').hidden"): break
    pg.wait_for_timeout(200)
pg.wait_for_timeout(800)
pg.locator('[data-b="tab:passive"]').first.click(); pg.wait_for_timeout(600)
before = pg.evaluate("(()=>{const id=Forge.card(state.project).passive_skill_set_id;const set=state.project.tables.passive_skill_sets.find(s=>s.id===id);return {text:set.itemized_description,rows:ForgePassiveMerge.setRows(state.project,id).length}})()")
print("BEFORE rows", before["rows"]); print(before["text"]); print("----")
pg.locator('[data-guide="copy:passive"]').first.click(); pg.wait_for_timeout(800)
pg.fill("#fd-root [data-fd-text]", DONOR); pg.wait_for_timeout(2000)
pg.locator("#fd-root .fd-tile").first.click(); pg.wait_for_timeout(2500)
print("dialog:", pg.inner_text("#dialog-content")[:200].replace("\n", " | "))
pg.screenshot(path=SP + "copy-dialog.png")
pg.click("#copy-kit-apply"); pg.wait_for_timeout(3000)
print("summary:", pg.inner_text("#dialog-content")[:900])
pg.screenshot(path=SP + "copy-summary.png")
after = pg.evaluate("(()=>{const id=Forge.card(state.project).passive_skill_set_id;const set=state.project.tables.passive_skill_sets.find(s=>s.id===id);return {id,text:set.itemized_description,rows:ForgePassiveMerge.setRows(state.project,id).map(r=>ForgeBuilder.passiveLine(r)),sets:state.project.tables.passive_skill_sets.length,err:Forge.validate(state.project).errors}})()")
print("AFTER rows", len(after["rows"]), "sets", after["sets"], "errors", after["err"])
print(after["text"])
print("ROW LINES:", after["rows"])
pg.click("#dialog-close"); pg.wait_for_timeout(300)
pg.screenshot(path=SP + "copy-tab.png", full_page=True)
sql = pg.evaluate("Forge.sql(state.project)")
open(SP + "pcopy.sql", "w").write(sql)
print(subprocess.run(["python3", "apply_sql.py", SP + "pcopy.sql"], capture_output=True, text=True).stdout.strip().splitlines()[-1:])
print(subprocess.run(["python3", "-c", f"exec(open('overwrite_check.py').read().split('def main')[0]);print(check(open('{SP}pcopy.sql').read()))"], capture_output=True, text=True).stdout.strip())
s.report("pcopy"); s.close()
