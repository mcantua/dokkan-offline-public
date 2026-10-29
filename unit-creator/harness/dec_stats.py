import os, json
os.environ["FORGE_STATE"]="/home/claude/work/harness/state-tforms"
from harness import Session
s=Session().open(); pg=s.page
while pg.evaluate("window.__forgeWorkspaceStartup")!="ready": pg.wait_for_timeout(100)
r=pg.evaluate("""async()=>{
 const cards=await Native.call('query',{table:'cards',filters:{rarity:5},limit:2000});
 const ids=cards.filter(c=>c.id<2000000&&c.id%10==1).map(c=>c.passive_skill_set_id).filter(Boolean).slice(-80);
 const rel=[];for(const id of ids){rel.push(...await Native.call('query',{table:'passive_skill_set_relations',filters:{passive_skill_set_id:id},limit:200}))}
 const rows=[];const pids=[...new Set(rel.map(r=>r.passive_skill_id))];for(let i=0;i<pids.length;i+=900)rows.push(...await Native.call('query',{table:'passive_skills',ids:pids.slice(i,i+900),limit:1000}));
 const why={};let ok=0;for(const r of rows){if(ForgeBuilder.decodePassive(r)){ok++;continue}
   let k='eff'+r.efficacy_type;try{const v=JSON.parse(r.efficacy_values||'{}');if(Array.isArray(v)||Object.keys(v).length)k+=' json'}catch{}; if(r.sub_target_type_set_id)k+=' sub';why[k]=(why[k]||0)+1}
 return {sets:ids.length,rows:rows.length,ok,why:Object.entries(why).sort((a,b)=>b[1]-a[1]).slice(0,25), sample:rows.slice(0,3)}}""")
print(json.dumps(r)[:3000])
s.close()
