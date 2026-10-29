import os
os.environ["FORGE_STATE"] = "/home/claude/work/harness/state-pclassic"; os.environ["FRESH"] = "1"
from harness import Session
s = Session(viewport=(1280, 900)).open(); pg = s.page
while pg.evaluate("window.__forgeWorkspaceStartup") != "ready": pg.wait_for_timeout(100)
pg.evaluate("createUnit(1018651)")
for _ in range(100):
    if pg.locator("#bld").count() and pg.evaluate("document.getElementById('busy').hidden"): break
    pg.wait_for_timeout(200)
pg.wait_for_timeout(600)
pg.locator('.bld-more summary').click(); pg.wait_for_timeout(300); pg.locator('[data-b="mode:classic"]').click(); pg.wait_for_timeout(1000)
desc = lambda: pg.evaluate("(()=>{const id=Forge.card(state.project).passive_skill_set_id;return state.project.tables.passive_skill_sets.find(s=>s.id===id).itemized_description})()")
pg.evaluate("state.step=3; state.expert=false; renderEditor()"); pg.wait_for_timeout(800)
print("presets:", pg.locator('[data-action^="preset-"]').count())
print("dbg before:", pg.evaluate("JSON.stringify({builder:state.builder,view:state.view,step:state.step,lines:state.project.builderLines, PM:!!window.ForgePassiveMerge})")[:400])
pg.locator('[data-action="preset-ki"]').first.click(); pg.wait_for_timeout(1200)
print("dbg after:", pg.evaluate("JSON.stringify({lines:state.project.builderLines, n:state.project.tables.passive_skill_set_relations.filter(r=>r.passive_skill_set_id===Forge.card(state.project).passive_skill_set_id).length, stage:state.abilityStage})")[:600])
print("--- classic after Extra Ki preset\n" + desc())
# copy a passive in classic mode
print([b for b in pg.evaluate("[...document.querySelectorAll('#main button')].map(b=>b.textContent.trim()+'|'+[...b.attributes].map(a=>a.name+'='+a.value).join(','))") if 'opy' in b][:5]); pg.locator('[data-guide="copy:passive"]').first.click(); pg.wait_for_timeout(800)
pg.fill("#fd-root [data-fd-text]", "Super Saiyan God SS Vegito"); pg.wait_for_timeout(2000)
pg.locator("#fd-root .fd-tile").first.click(); pg.wait_for_timeout(2500)
pg.click("#copy-kit-apply"); pg.wait_for_timeout(3000)
print("summary:", pg.inner_text("#dialog-content")[:500].replace("\n", " "))
pg.click("#dialog-close"); pg.wait_for_timeout(300)
print("--- classic after copy\n" + desc())
print("errors:", pg.evaluate("Forge.validate(state.project).errors"))
s.report("pclassic"); s.close()
