import os
os.environ["FORGE_STATE"]="/home/claude/work/harness/state-tforms"; os.environ["FRESH"]="1"
from harness import Session
s=Session(viewport=(1280,900)).open(); pg=s.page
while pg.evaluate("window.__forgeWorkspaceStartup")!="ready": pg.wait_for_timeout(100)
pg.evaluate("createUnit(1018721)"); pg.wait_for_timeout(3000)
pg.evaluate("ForgeBuilderUI.open && ForgeBuilderUI.open()"); pg.wait_for_timeout(800)
pg.locator('[data-b="tab:transform"]').first.click(); pg.wait_for_timeout(500)
print(pg.evaluate("JSON.stringify({links:state.project.transformLinks, forms:state.project.formProjects.map(f=>[f.key,f.targetId,f.source.cardId])})"))
pg.click('[data-b="tf-into:custom"]'); pg.click('[data-b="tf-create"]'); pg.wait_for_timeout(800)
pg.fill("#guide-unit-search","Vegeta"); pg.wait_for_timeout(1500)
print("pick:", pg.locator(".guide-pick").first.inner_text())
pg.locator(".guide-pick").first.click(); pg.wait_for_timeout(4000)
print(pg.evaluate("""JSON.stringify({links:state.project.transformLinks, forms:(state.project.formProjects||[]).map(f=>[f.key,f.targetId,f.source.cardId, ForgeForms.slots(f).map(x=>x.targetId)]), root:ForgeForms.slots(state.project).map(x=>[x.table,x.row,x.targetId]), err:Forge.validate(state.project).errors})"""))
print(s.console[-5:])
s.close()
