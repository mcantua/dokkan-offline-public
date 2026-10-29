import os
os.environ["FORGE_STATE"]="/home/claude/work/harness/state-tforms"; os.environ["FRESH"]="1"
from harness import Session
s=Session(viewport=(412,915)).open(); pg=s.page
while pg.evaluate("window.__forgeWorkspaceStartup")!="ready": pg.wait_for_timeout(100)
pg.evaluate("window.__tf=ForgeTemplateForms.include; ForgeTemplateForms.include=async p=>({project:p,added:[],skipped:[]})")
pg.evaluate("createUnit(1018651)"); pg.wait_for_timeout(3000)
pg.evaluate("ForgeTemplateForms.include=window.__tf")
print("forms before:", pg.evaluate("(state.project.formProjects||[]).length"))
pg.locator('[data-b="tab:transform"]').first.click(); pg.wait_for_timeout(600)
pg.click('[data-b="tf-include"]'); pg.wait_for_timeout(3000)
print("forms after:", pg.evaluate("(state.project.formProjects||[]).map(f=>Forge.card(f).name)"), pg.evaluate("Forge.validate(state.project).errors"))
print("toast:", pg.inner_text("#toast"))
pg.locator('[data-b^="form-enter:"]').first.click(); pg.wait_for_timeout(2500)
pg.locator('[data-b="tab:transform"]').first.click(); pg.wait_for_timeout(600)
print("in form:", pg.inner_text(".bld-main")[:300].replace("\n"," | "))
s.report("tfinc"); s.close()
