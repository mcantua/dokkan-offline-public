"""Copy From Unit fixes: custom animations of my other unit revert to game originals; clearing one
animation doesn't delete an intro effect with the same private id; Super fallback is a game view."""
import os, json
os.environ["FORGE_STATE"] = "/home/claude/work/harness/state-ucfix"; os.environ["FRESH"] = "1"
from harness import Session
s = Session(viewport=(412, 915)).open(); pg = s.page; w = lambda ms=600: pg.wait_for_timeout(ms)
errs = []; pg.on("pageerror", lambda e: errs.append(str(e)))
def ok(name, cond, extra=""): print(("PASS " if cond else "FAIL ") + name, extra)
while pg.evaluate("window.__forgeWorkspaceStartup") != "ready": w(100)
def create(cid):
    pg.evaluate(f"createUnit({cid})")
    for _ in range(200):
        if pg.evaluate("state.view==='editor' && !!state.project && document.getElementById('busy').hidden"): break
        w(100)
    w(800)
create(1014761)
# unit A: give its first Super Attack and Active Skill (if any) a fake custom animation
a = pg.evaluate("""async()=>{const p=state.project,rel=p.tables.card_specials[0],orig=rel.view_id;
  ForgeGuide.ensure(p,state.info.schema,'special_views');p.tables.special_views.push(Object.assign(Forge.rowDefault(p.schema.special_views),{id:-1,script_name:'x'}));
  rel.view_id=-1;p.animationAssignments=p.animationAssignments||{};p.animationAssignments['super:'+rel.id]={id:-1,file:'f.lua'};
  p.generatedFiles=[{owner:'super:'+rel.id,path:'f.lua',text:'--'}];scheduleSave();await flushSave();return {key:p.key,orig,rel:rel.id}}""")
d = pg.evaluate(f"""async()=>{{const d=await ForgeUnitCopy.myDonor({json.dumps(a['key'])});const r=d.project.tables.card_specials.find(x=>x.id==={a['rel']});return [r.view_id,d.reverted,Object.keys(d.project.animationAssignments).length]}}""")
ok("custom Super animation reverts to the game's", d[0] == a["orig"] and d[1] == 1 and d[2] == 0, (d, a["orig"]))
create(1018721)
# unit B: a custom intro effect -1 and a custom Active animation view -1 (same private id, different tables)
r = pg.evaluate("""async()=>{const p=state.project;
  ForgeGuide.ensure(p,state.info.schema,'passive_skill_effects');ForgeGuide.ensure(p,state.info.schema,'special_views');
  p.tables.passive_skill_effects.push(Object.assign(Forge.rowDefault(p.schema.passive_skill_effects),{id:-1}));
  p.tables.special_views.push(Object.assign(Forge.rowDefault(p.schema.special_views),{id:-1}));
  p.animationAssignments={'active:123':{id:-1},'intro:5':{id:-1}};
  const cards=await Native.call('query',{table:'card_active_skills',limit:50});const donorId=cards.map(c=>c.card_id).find(i=>i%10===1&&i<2000000);
  const d=await ForgeUnitCopy.gameDonor({id:donorId,name:'donor'});const res=ForgeUnitCopy.build(d,new Set(['active']),{});
  return [res.work.tables.passive_skill_effects.some(x=>x.id===-1),res.work.tables.special_views.some(x=>x.id===-1),!!res.work.animationAssignments['intro:5']]}""")
ok("intro effect survives clearing the Active animation", r[0] and not r[1] and r[2], r)
# my unit A (now reverted) → Super Attacks onto B: no negative views
r = pg.evaluate(f"""async()=>{{const d=await ForgeUnitCopy.myDonor({json.dumps(a['key'])});const res=ForgeUnitCopy.build(d,new Set(['supers']),{{supers:'replace'}});
  return (res.work.tables.card_specials||[]).map(x=>x.view_id)}}""")
ok("copied Supers use game animations", r and all(v and v > 0 for v in r), r)
print("errors:", errs[:3])
