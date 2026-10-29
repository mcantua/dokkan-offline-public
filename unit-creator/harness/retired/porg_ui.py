"""Passive step: 'Copy every version of a character' → combine → organize → apply; 'Organize & balance'; undo; export check."""
import os, json, subprocess, sys
os.environ["FORGE_STATE"] = "/home/claude/work/harness/state-porg"; os.environ["FRESH"] = "1"
from harness import Session
SP = "/tmp/claude-0/sim/porg/"; os.makedirs(SP, exist_ok=True)
s = Session(viewport=(412, 915)).open(); pg = s.page; w = lambda ms=600: pg.wait_for_timeout(ms)
errs = []; pg.on("pageerror", lambda e: errs.append(str(e)))
while pg.evaluate("window.__forgeWorkspaceStartup") != "ready": w(100)
CID = int(sys.argv[1]) if len(sys.argv) > 1 else 1014761
pg.evaluate("createUnit(1018721)")
for _ in range(200):
    if pg.evaluate("state.view==='editor' && !!state.project && document.getElementById('busy').hidden"): break
    w(100)
w(1000)
pg.locator('[data-b="tab:passive"]').first.click(); w(800)
print("buttons:", pg.locator(".porg-every").count(), pg.locator(".porg-tidy").count())
pg.screenshot(path=SP + "1-step.png")
before = pg.evaluate("ForgePassiveMerge.setRows(state.project,Forge.primaryPassive(state.project).id).length")
def wait_for(sel, n=150):
    for _ in range(n):
        if pg.locator(sel).count(): return
        w(200)
# 1) the button opens the name search; each name shown once
pg.locator(".porg-every").first.click(); w(500)
pg.fill("#porg-search", "Vegito"); w(1500)
names = pg.locator(".porg-name").all_inner_texts()
print("names:", [n.replace("\n", " ") for n in names[:8]], "| duplicates:", len(names) - len(set(names)))
pg.screenshot(path=SP + "1b-search.png")
pg.locator('[data-porg-name="Vegito"]').click(); wait_for("#porg-go")
print("hero:", pg.inner_text(".porg-hero").replace("\n", " "), "| button:", pg.inner_text("#porg-go"))
print("rows:", [r.replace("\n", " ") for r in pg.locator(".porg-row").all_inner_texts()])
pg.screenshot(path=SP + "2-basket.png")
# 2) add another character
pg.locator("#porg-add").click(); w(500)
pg.fill("#porg-search", "Super Gogeta"); w(1500)
pg.locator('[data-porg-name="Super Gogeta"]').click(); wait_for(".porg-chip >> nth=1")
print("chips:", pg.locator(".porg-chip").all_inner_texts(), "|", pg.inner_text("#porg-go"))
# 3) choose: untick all Gogeta rows and one Vegito
pg.locator(".porg-pick summary").click(); w(300)
rows = pg.locator("[data-porg-card]")
nv = 5
for i in range(nv, rows.count()): rows.nth(i).uncheck()
rows.nth(4).uncheck(); w(300)
print("after choosing:", pg.inner_text("#porg-go"), "| big:", pg.inner_text(".porg-big"))
pg.screenshot(path=SP + "2b-choose.png", full_page=True)
pg.locator("#porg-go").click()
for _ in range(1500):
    if pg.locator("#porg-apply").count(): break
    w(400)
pg.screenshot(path=SP + "3-result.png")
print(pg.inner_text("#dialog-content")[:900])
pg.locator("#porg-apply").click(); w(1500)
after = pg.evaluate("""()=>{const p=state.project,set=Forge.primaryPassive(p),rows=ForgePassiveMerge.setRows(p,set.id);
  const v=Forge.validate(p);let sql='',err='';try{sql=Forge.sql(p)}catch(e){err=e.message}
  return {rows:rows.length,lines:(set.itemized_description||'').split('\\n').length,issues:ForgePassiveMerge.balanceIssues(rows).map(i=>i.text),errors:v.errors.slice(0,3),err,sql}}""")
open(SP + "a.sql", "w").write(after.pop("sql"))
print("rows", before, "->", after)
print("apply:", subprocess.run(["python3", "apply_sql.py", SP + "a.sql"], capture_output=True, text=True).stdout.strip().splitlines()[-1:])
# Organize & balance again: should be settled
pg.locator(".porg-tidy").first.click(); w(800)
print("tidy again:", pg.inner_text("#dialog-content")[:300].replace("\n", " | "))
pg.locator("#porg-cancel").click(); w(300)
pg.evaluate("ForgeGuideUI.undo()"); w(1500)
print("undo rows:", pg.evaluate("ForgePassiveMerge.setRows(state.project,Forge.primaryPassive(state.project).id).length"), "(expected", before, ")")
print("errors:", errs[:3])
# strongest stage = the Super EZA passive for a card with Super EZA
chk = pg.evaluate("""async()=>{const d=await ForgeUnitCopy.gameDonor({id:1003211,name:'x'});const G=ForgeGuide,st=G.abilityStages(d.project).filter(s=>G.stageSet(d.project,s.id,'passive'));
 const last=st[st.length-1].id,set=G.stageAbilityId(d.project,last,'passive');const g=(d.project.tables.optimal_awakening_growths||[]).slice().sort((a,b)=>b.step-a.step)[0];
 return [st.map(s=>s.id),set,g&&g.step,g&&g.passive_skill_set_id]}""")
print("super EZA stage:", chk)
