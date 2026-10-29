"""Scenario: copy every version's passive of one character onto a unit (Add), then inspect."""
import os, json, sys
os.environ["FORGE_STATE"] = "/home/claude/work/harness/state-mergeall"; os.environ["FRESH"] = "1"
from harness import Session
s = Session(viewport=(412, 915)).open(); pg = s.page; w = lambda ms=600: pg.wait_for_timeout(ms)
errs = []; pg.on("pageerror", lambda e: errs.append(str(e)))
while pg.evaluate("window.__forgeWorkspaceStartup") != "ready": w(100)
cid = int(sys.argv[1]) if len(sys.argv) > 1 else 1018721
pg.evaluate(f"createUnit({cid})")
for _ in range(200):
    if pg.evaluate("state.view==='editor' && !!state.project && document.getElementById('busy').hidden"): break
    w(100)
w(800)
versions = pg.evaluate(f"""async()=>{{const c=(await Native.call('query',{{table:'cards',ids:[{cid}],limit:1}}))[0];
  const rows=await Native.call('query',{{table:'cards',filters:{{card_unique_info_id:c.card_unique_info_id}},limit:500}});
  return rows.filter(r=>r.id%10===1&&r.id<9000000&&r.id!=={cid}).map(r=>[r.id,r.name,r.rarity])}}""")
print("versions:", len(versions))
out = pg.evaluate("""async(vs)=>{const log=[];for(const [id,name] of vs){try{const d=await ForgeUnitCopy.gameDonor({id,name});const r=ForgeUnitCopy.build(d,new Set(['passive']),{passive:'add'});Object.assign(state.project,r.work);log.push(name+': ok')}catch(e){log.push(name+': '+e.message)}}
  const set=Forge.primaryPassive(state.project),rows=ForgePassiveMerge.setRows(state.project,set.id);
  return {log,rows:rows.length,decoded:rows.filter(r=>ForgeBuilder.decodePassive(r)).length,issues:ForgePassiveMerge.balanceIssues(rows).map(i=>i.text+' '+i.total+'>'+i.cap),text:set.itemized_description,auto:(state.project.builderAuto||{})['passive:'+set.id]}}""", versions)
print("rows:", out["rows"], "decoded:", out["decoded"], "auto:", out["auto"])
print("balance issues:", out["issues"][:10])
print("text length:", len(out["text"]), "lines:", out["text"].count("\n")+1)
und = pg.evaluate("""()=>{const p=state.project,set=Forge.primaryPassive(p),rows=ForgePassiveMerge.setRows(p,set.id);
  const und=rows.filter(r=>!ForgeBuilder.decodePassive(r)&&Number(r.efficacy_type)!==103);
  const types={};for(const r of und){const k=r.efficacy_type+' calc'+r.calc_option;types[k]=(types[k]||0)+1}
  return {types,samples:und.map(r=>r.efficacy_type+'/c'+r.calc_option+'/t'+r.exec_timing_type+': '+ForgeGuide.effectSummary(r)+' | '+ForgeBuilder.passiveLine(r)).slice(0,70)}}""")
print(json.dumps(und["types"]))
print("\n".join(und["samples"]))
open("/tmp/claude-0/sim/merge-before.txt","w").write(out["text"])
print("errors:", errs[:3])

res = pg.evaluate("""()=>{const p=state.project,set=Forge.primaryPassive(p);const r=ForgePassiveMerge.organize(p,set.id);
  const v=Forge.validate(p);let sql='',err='';try{sql=Forge.sql(p)}catch(e){err=e.message}
  const rows=ForgePassiveMerge.setRows(p,set.id),basic=rows.filter(x=>Number(x.exec_timing_type)===1&&!x.causality_conditions&&Number(x.target_type)===1);
  const tot={ki:0,atk:0,def:0};for(const x of basic){const d=ForgeBuilder.decodePassive(x);if(!d)continue;if(d.key==='ki')tot.ki+=d.values.amount;if(d.key==='atk')tot.atk+=d.values.amount;if(d.key==='def')tot.def+=d.values.amount;if(d.key==='atkdef'){tot.atk+=d.values.atk;tot.def+=d.values.def}}
  const dump=basic.filter(x=>ForgeBuilder.decodePassive(x)&&['ki','atk','def','atkdef'].includes(ForgeBuilder.decodePassive(x).key)).map(x=>[x.id,x.efficacy_type,x.calc_option,x.turn,x.probability,x.is_once,x.sub_target_type_set_id,JSON.stringify(x.causality_conditions),x.eff_value1,x.eff_value2,x.efficacy_values].join(' '));
  return {dump,basic:tot,summary:ForgePassiveMerge.organizeSummary(r),text:r.text,errors:v.errors.slice(0,3),err,sql,issues:ForgePassiveMerge.balanceIssues(ForgePassiveMerge.setRows(p,set.id)).map(i=>i.text+' '+i.total+'>'+i.cap)}}""")
print("\n".join(res["summary"]))
print("basic rows total (gameplay):", res["basic"]); print("\n".join(res["dump"]))
print(pg.evaluate("""()=>{const p=state.project,set=Forge.primaryPassive(p),rows=ForgePassiveMerge.setRows(p,set.id);const a=rows.find(r=>r.id===-47),b=rows.find(r=>r.id===-198);
 return a&&b?[ForgePassiveMerge.sameAbility(a,b),JSON.stringify(a),JSON.stringify(b),(p.tables.passive_skill_set_relations||[]).filter(r=>r.passive_skill_id===-47||r.passive_skill_id===-198).map(r=>r.passive_skill_set_id+':'+r.passive_skill_id).join(',')]:'missing'}"""))
print("remaining issues:", res["issues"], "| errors:", res["errors"], res["err"])
open("/tmp/claude-0/sim/merge-after.txt","w").write(res["text"])
open("/tmp/claude-0/sim/merge-after.sql","w").write(res["sql"])
import subprocess
print(subprocess.run(["python3","apply_sql.py","/tmp/claude-0/sim/merge-after.sql"],capture_output=True,text=True).stdout.strip().splitlines()[-1:])
print(res["text"][:5000])

print("second run:", pg.evaluate("""()=>{const p=state.project,set=Forge.primaryPassive(p);const r=ForgePassiveMerge.organizeRows(p,set.id);return [r.before,r.after,r.duplicates,r.combined.length,ForgePassiveMerge.setRows(p,set.id).filter(x=>x.id===-198||x.id===-47).map(x=>x.id+':'+x.eff_value1)]}"""))
