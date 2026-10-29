import os, json
os.environ["FORGE_STATE"] = "/home/claude/work/harness/state-psync"; os.environ["FRESH"] = "1"
from harness import Session
SP = "/tmp/claude-0/-home-claude/fc61b99f-cb57-56bc-b827-ee4cb4796a4c/scratchpad/"
s = Session(viewport=(412, 915)).open(); pg = s.page
while pg.evaluate("window.__forgeWorkspaceStartup") != "ready": pg.wait_for_timeout(100)
pg.evaluate("createUnit(1018651)")
for _ in range(100):
    if pg.locator("#bld").count() and pg.evaluate("document.getElementById('busy').hidden"): break
    pg.wait_for_timeout(200)
pg.wait_for_timeout(800)
pg.locator('[data-b="tab:passive"]').first.click(); pg.wait_for_timeout(800)
desc = lambda: pg.evaluate("(()=>{const id=Forge.card(state.project).passive_skill_set_id;return state.project.tables.passive_skill_sets.find(s=>s.id===id).itemized_description})()")
print("auto checkbox:", pg.is_checked('[data-bauto="passive"]'))
print("START\n" + desc())
# 1. add an ability (Raise DEF) -> description gets a new line
pg.locator('[data-b="adding:on"]').click(); pg.wait_for_timeout(300)
pg.locator('[data-b="passive-add:def"]').click(); pg.wait_for_timeout(1200)
print("--- after add DEF\n" + desc())
# 2. edit the first official ability (ATK & DEF 70%) to 120
first = pg.locator(".bld-ability").first
first.locator('[data-b^="open:passive"]').first.click(); pg.wait_for_timeout(500)
box = pg.locator('.bld-ability.open').first
inputs = box.locator('input[type=number]')
inputs.nth(0).fill("120"); inputs.nth(0).dispatch_event("change"); pg.wait_for_timeout(300)
inputs.nth(1).fill("120"); inputs.nth(1).dispatch_event("change"); pg.wait_for_timeout(800)
print("--- after edit ATK&DEF 120\n" + desc())
# 3. push past the meta -> balance check
inputs = pg.locator('.bld-ability.open').first.locator('input[type=number]')
inputs.nth(0).fill("450"); inputs.nth(0).dispatch_event("change"); pg.wait_for_timeout(800)
pg.locator('[data-b="tab:basics"]').first.click(); pg.wait_for_timeout(300); pg.locator('[data-b="tab:passive"]').first.click(); pg.wait_for_timeout(800)
print("balance:", pg.inner_text(".bld-balance").replace("\n", " | ") if pg.locator(".bld-balance").count() else "none")
pg.screenshot(path=SP + "balance.png", full_page=True)
pg.locator('[data-b="passive-fit"]').click(); pg.wait_for_timeout(800)
print("toast:", pg.inner_text("#toast"), "| balance after:", pg.locator(".bld-balance").count())
print("--- after fit\n" + desc())
# 4. remove the DEF ability we added
dels = pg.locator('[data-b^="passive-del:"]')
dels.last.click(); pg.wait_for_timeout(600)
if pg.locator("#bld-confirm").count(): pg.locator("#bld-confirm").click(); pg.wait_for_timeout(800)
print("--- after remove last\n" + desc())
# 5. AI helper adds Ki +2 at start of turn twice -> combined
r = pg.evaluate("""(async()=>{const p=state.project;const out=ForgeAIConnect.applyActions(p,[{do:'passive',abilities:[{ability:'ki',values:{amount:2},when:'turnStart',who:'self'},{ability:'ki',values:{amount:2},when:'turnStart',who:'self'}]}],await ForgeAIConnect.context());ForgeBuilderUI.refreshTexts();scheduleSave();renderEditor();return out})()""")
print("AI:", json.dumps(r)[:600])
pg.wait_for_timeout(800)
print("--- after AI\n" + desc())
print("errors:", pg.evaluate("Forge.validate(state.project).errors"))
s.report("psync"); s.close()
