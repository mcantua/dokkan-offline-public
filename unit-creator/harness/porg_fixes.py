"""Checks for the review findings: arrows, kept timing/duration, leftover sets, EZA stage target, sphere changes, empty passive."""
import os, json, subprocess
os.environ["FORGE_STATE"] = "/home/claude/work/harness/state-porgfix"; os.environ["FRESH"] = "1"
from harness import Session
SP = "/tmp/claude-0/sim/porgfix/"; os.makedirs(SP, exist_ok=True)
s = Session(viewport=(412, 915)).open(); pg = s.page; w = lambda ms=600: pg.wait_for_timeout(ms)
errs = []; pg.on("pageerror", lambda e: errs.append(str(e)))
while pg.evaluate("window.__forgeWorkspaceStartup") != "ready": w(100)
def ok(name, cond, extra=""): print(("PASS " if cond else "FAIL ") + name, extra)
# 1. a lowering line is not turned into a boost
t = pg.evaluate("""()=>ForgePassiveMerge.organizeText('*When attacking with 12 or more Ki*\\n- ATK 100%{passiveImg:up_g}\\n- DEF 50%{passiveImg:down_r}',{lowered:[]})""")
ok("down arrow kept", "DEF 50%{passiveImg:down_r}" in t and "ATK 100%" in t, repr(t))
t2 = pg.evaluate("""()=>ForgePassiveMerge.organizeText('*Start of turn*\\n- DEF 50%{passiveImg:up_g}\\n- DEF 50%{passiveImg:down_r}',{lowered:[]})""")
ok("up and down not summed", "down_r" in t2 and "up_g" in t2, repr(t2))
pg.evaluate("createUnit(1018721)")
for _ in range(200):
    if pg.evaluate("state.view==='editor' && !!state.project && document.getElementById('busy').hidden"): break
    w(100)
w(1000)
# 2. lowering / combining keeps timing 3, 7-turn duration, sub-target
r = pg.evaluate("""()=>{const p=Forge.clone(state.project);ForgeGuide.isolateAbilityStage(p,'base','passive');const id=ForgeGuide.stageAbilityId(p,'base','passive');
  const add=(f)=>{const row=ForgeBuilder.addPassiveAbility(p,'atk',{amount:f.a},{timing:1,target:1,turn:1,chance:100});Object.assign(row,f.set);return row;};
  const a=add({a:250,set:{exec_timing_type:3,turn:7}}),b=add({a:250,set:{exec_timing_type:3,turn:7}});
  const rep=ForgePassiveMerge.organize(p,id);const rows=ForgePassiveMerge.setRows(p,id).filter(x=>Number(x.exec_timing_type)===3);
  return rows.map(x=>[x.efficacy_type,x.eff_value1,x.exec_timing_type,x.turn])}""")
ok("timing 3 + 7 turns kept", r and all(x[2] == 3 and x[3] == 7 for x in r), r)
# 6. different Ki Sphere changes both stay
r = pg.evaluate("""()=>{const p=Forge.clone(state.project);ForgeGuide.isolateAbilityStage(p,'base','passive');const id=ForgeGuide.stageAbilityId(p,'base','passive');
  ForgeBuilder.addPassiveAbility(p,'sphereChange',{from:0,to:5},{timing:1,target:1,turn:1,chance:100});ForgeBuilder.addPassiveAbility(p,'sphereChange',{from:1,to:5},{timing:1,target:1,turn:1,chance:100});
  ForgePassiveMerge.organize(p,id);return ForgePassiveMerge.setRows(p,id).filter(x=>Number(x.efficacy_type)===51).map(x=>x.eff_value1+'>'+x.eff_value2)}""")
ok("both sphere changes kept", len(r) == 2, r)
# 3. combining doesn't leave unused passive sets
before = pg.evaluate("(state.project.tables.passive_skill_sets||[]).length")
pg.locator('[data-b="tab:passive"]').first.click(); w(800)
pg.evaluate("ForgePassiveOrganize.versions({id:1014761,name:'Super Saiyan Goku'})")
for _ in range(150):
    if pg.locator("#porg-go").count(): break
    w(200)
n = pg.evaluate("document.getElementById('porg-go').textContent")
pg.locator("#porg-go").click()
for _ in range(1500):
    if pg.locator("#porg-apply").count(): break
    w(400)
pg.locator("#porg-apply").click(); w(1500)
info = pg.evaluate("""()=>{const p=state.project,used=new Set([Forge.card(p).passive_skill_set_id,...(p.tables.optimal_awakening_growths||[]).map(g=>g.passive_skill_set_id)]);
  const v=Forge.validate(p);let sql='',err='';try{sql=Forge.sql(p)}catch(e){err=e.message}
  return {sets:(p.tables.passive_skill_sets||[]).length,unused:(p.tables.passive_skill_sets||[]).filter(s=>!used.has(s.id)).length,errors:v.errors.slice(0,3),err,sql}}""")
open(SP + "goku.sql", "w").write(info.pop("sql"))
ok("no unused sets after combining", info["unused"] == 0, (n, before, info))
print("   apply:", subprocess.run(["python3", "apply_sql.py", SP + "goku.sql"], capture_output=True, text=True).stdout.strip().splitlines()[-1:])
# 4. on an EZA step, the EZA passive is organized and the base passive is untouched
pg.evaluate("ForgeGuideUI.undo()"); w(1200)
pg.evaluate("createUnit(1008421)")  # Vegito with EZA
for _ in range(200):
    if pg.evaluate("state.view==='editor' && !!state.project && document.getElementById('busy').hidden && Forge.card(state.project).name==='Vegito'"): break
    w(100)
w(1000)
pg.locator('[data-b="tab:passive"]').first.click(); w(800)
stages = pg.evaluate("[...document.querySelectorAll('[data-b^=\"stage:passive:\"]')].map(b=>b.dataset.b)")
print("   stages:", stages)
base = pg.evaluate("JSON.stringify(ForgePassiveMerge.setRows(state.project,Forge.primaryPassive(state.project).id).map(r=>[r.id,r.eff_value1]))")
pg.locator(f'[data-b="{stages[-1]}"]').click(); w(800)
pg.evaluate("ForgePassiveOrganize.versions({id:1008431,name:'Vegito'})")
for _ in range(150):
    if pg.locator("#porg-go").count(): break
    w(200)
pg.locator("#porg-go").click()
for _ in range(1500):
    if pg.locator("#porg-apply").count(): break
    w(400)
pg.locator("#porg-apply").click(); w(1500)
after = pg.evaluate("JSON.stringify(ForgePassiveMerge.setRows(state.project,Forge.primaryPassive(state.project).id).map(r=>[r.id,r.eff_value1]))")
eza = pg.evaluate("""()=>{const g=ForgeBuilder.stageGroups(state.project,'passive');const last=g[g.length-1];return [last.key,ForgePassiveMerge.setRows(state.project,last.setId).length]}""")
v = pg.evaluate("""()=>{const p=state.project,v=Forge.validate(p);let sql='',err='';try{sql=Forge.sql(p)}catch(e){err=e.message}return {errors:v.errors.slice(0,3),err,sql}}""")
open(SP + "eza.sql", "w").write(v.pop("sql"))
ok("base passive untouched on EZA step", base == after, eza)
print("   eza export:", v, subprocess.run(["python3", "apply_sql.py", SP + "eza.sql"], capture_output=True, text=True).stdout.strip().splitlines()[-1:])
# 5. empty passive: organize says nothing to do
print("errors:", errs[:3])
