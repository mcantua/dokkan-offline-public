/* Copies one real Super Attack, including its conditions and EX gameplay options. */
(function(root,factory){
  if(typeof module==='object'&&module.exports)module.exports=factory(require('./core'),require('./guide-model'),require('./builder-model'));
  else root.ForgeSuperAttacks=factory(root.Forge,root.ForgeGuide,root.ForgeBuilder);
})(typeof globalThis!=='undefined'?globalThis:this,function(F,G,B){
 'use strict';
 const styles={Normal:'Super Attack',Hyper:'Ultra Super Attack',Condition:'Conditional Super Attack',Extra:'EX Super Attack',FullPower:'Full-power attack'};
 const missingEX=p=>(p.tables.card_specials||[]).filter(r=>r.style==='Extra'&&r.id>0&&!(p.tables.extra_special_options||[]).some(o=>o.card_special_id===r.id));
 async function hydrateEX(p,query,schema){
  const missing=missingEX(p);if(!missing.length||!schema.extra_special_options)return false;
  const groups=await Promise.all(missing.map(r=>query({table:'extra_special_options',filters:{card_special_id:r.id},limit:10})));
  G.ensure(p,schema,'extra_special_options');let changed=false;
  for(const rows of groups)for(const row of rows)if(!p.tables.extra_special_options.some(r=>r.card_special_id===row.card_special_id)){p.tables.extra_special_options.push(F.clone(row));changed=true;}
  return changed;
 }
 function setStyle(p,schema,id,style){
  if(!styles[style])throw Error('Choose a supported attack type.');
  const row=(p.tables.card_specials||[]).find(r=>r.id===id);if(!row)throw Error('Choose an existing attack.');
  if(style==='Extra')G.ensure(p,schema,'extra_special_options');
  row.style=style;const exOpt=(p.tables.extra_special_options||[]).find(r=>r.card_special_id===id);row.priority=style==='Extra'?({0:20,1:30,2:40}[Number(exOpt?.extra_special_type)||0]):style==='Condition'?10:0;
  if(style==='Condition'){row.special_asset_id=2;if(!row.causality_conditions)B.applyCondition(p,schema,row,{mode:'all',items:[{key:'turn',values:{turn:4}}]});}
  // In the game only Conditional Super Attacks carry activation rules (and special_asset_id 2);
  // every other style has neither, so switching away clears them.
  else{row.special_asset_id=null;row.causality_conditions=null;if(B.pruneCausalities)B.pruneCausalities(p);}
  if(style==='Extra'&&!p.tables.extra_special_options.some(r=>r.card_special_id===id))p.tables.extra_special_options.push({...F.rowDefault(schema.extra_special_options),id:F.localId(p,'extra_special_options'),card_special_id:id,probability:70,extra_special_type:0,bgm_id:null});
  if(style==='Extra'){const o=p.tables.extra_special_options.find(r=>r.card_special_id===id),set=(p.tables.special_sets||[]).find(x=>x.id===row.special_set_id),t=Number(o?.extra_special_type)||0;if(set&&o)set.causality_description='Activates with a '+(o.probability||70)+'% chance '+['when the 1st attack in a turn is a Super Attack','when performing an additional Super Attack','when the 1st Super Attack performs a critical hit'][t];}
  if(style!=='Extra'&&p.tables.extra_special_options)p.tables.extra_special_options=p.tables.extra_special_options.filter(r=>r.card_special_id!==id);
 }
 async function read(query,schema,cardId,relationId){
  const donor={schema,tables:{}};
  const get=async(t,filters)=>{if(!schema[t])return[];const rows=await query({table:t,filters,limit:5000});donor.tables[t]=(donor.tables[t]||[]).concat(rows.filter(r=>!(donor.tables[t]||[]).some(v=>v.id===r.id)));return rows;};
  const rel=(await get('card_specials',{card_id:cardId})).find(r=>r.id===relationId);
  if(!rel)throw Error('That attack is no longer available. Choose another attack.');
  donor.tables.card_specials=[rel];await get('special_sets',{id:rel.special_set_id});await get('specials',{special_set_id:rel.special_set_id});await get('extra_special_options',{card_special_id:rel.id});
  if(!donor.tables.special_sets?.length)throw Error('The selected attack is missing its gameplay effects.');
  const causes=new Set(),subs=new Set(),visit=n=>{if(typeof n==='number')causes.add(n);else if(Array.isArray(n))n.slice(1).forEach(visit);};
  for(const rows of Object.values(donor.tables))for(const row of rows){if(row.causality_conditions)visit(JSON.parse(row.causality_conditions).compiled);if(row.sub_target_type_set_id)subs.add(row.sub_target_type_set_id);}
  for(const id of causes)await get('skill_causalities',{id});for(const id of subs){await get('sub_target_type_sets',{id});await get('sub_target_types',{sub_target_type_set_id:id});}
  if(rel.style==='Extra'&&!donor.tables.extra_special_options?.length)throw Error('This EX attack has no EX activation setup in the selected database.');
  return donor;
 }
 function copy(p,donor,replaceId=null){
  const work=F.clone(p),tables=['skill_causalities','sub_target_type_sets','sub_target_types','special_sets','specials','card_specials','extra_special_options'].filter(t=>donor.tables[t]),maps=G.importOwned(work,donor,tables);
  const rewrite=n=>typeof n==='number'?(maps.skill_causalities?.get(n)??n):Array.isArray(n)?n.map((v,i)=>i?rewrite(v):v):n;
  for(const t of tables)for(const row of work.tables[t])if([...maps[t].values()].includes(row.id)&&row.causality_conditions){const c=JSON.parse(row.causality_conditions);c.compiled=rewrite(c.compiled);if(c.source)c.source=c.source.replace(/-?\d+/g,n=>String(maps.skill_causalities?.get(Number(n))??n));row.causality_conditions=JSON.stringify(c);}
  if(replaceId!=null)B.removeSuper(work,replaceId);
  const row=work.tables.card_specials.find(r=>r.id===maps.card_specials.get(donor.tables.card_specials[0].id));
  work.builderAuto=work.builderAuto||{};work.builderAuto['sa:'+row.special_set_id]=false;
  Object.assign(p,work);return row;
 }
 async function pick(replaceId=null){
  const p=state.project,method=p.source?.database==='sparking'?'querySparking':'query',schema=p.source?.database==='sparking'?(await Native.call('sparkingInfo')).schema:state.info.schema;
  return ForgeGuideUI.pickUnit('Choose a character’s Super Attack',async card=>{
   const rels=await Native.call(method,{table:'card_specials',filters:{card_id:card.id},limit:100});
   if(!rels.length){dialog('No Super Attacks','<p>This card has no Super Attacks. Choose another version of the character.</p><button class="button" id="attack-pick-another">Choose another character</button>');document.getElementById('attack-pick-another').onclick=()=>pick(replaceId);return;}
   const sets=await Native.call(method,{table:'special_sets',ids:[...new Set(rels.map(r=>r.special_set_id))],limit:100});
   dialog('Choose one attack from '+card.name,'<p>Only this attack, its effects and its activation rules will be copied.</p><div class="guide-picks">'+rels.map(r=>{const set=sets.find(s=>s.id===r.special_set_id);return '<button class="guide-pick" data-copy-super="'+r.id+'"><span><strong>'+esc(set?.name||styles[r.style])+'</strong><small>'+esc(styles[r.style]||r.style)+' · '+r.eball_num_start+' Ki'+(r.lv_start?' · SA level '+r.lv_start:'')+'</small><small>'+esc(set?.description||'')+'</small></span></button>';}).join('')+'</div>');
   document.querySelectorAll('[data-copy-super]').forEach(button=>button.onclick=async()=>{
    if(button.disabled)return;button.disabled=true;
    try{const donor=await read(o=>Native.call(method,o),schema,card.id,Number(button.dataset.copySuper));if(state.project!==p)throw Error('The selected unit changed. Choose the attack again.');copy(p,donor,replaceId);document.getElementById('dialog').close();scheduleSave();await flushSave();renderEditor();toast('Super Attack copied with its gameplay effects and activation rules.');}catch(e){toast(e.message,true);button.disabled=false;}
   });
  },{sourceDatabase:p.source?.database||'eclipse',allVersions:true});
 }
 return{styles,setStyle,read,copy,pick,missingEX,hydrateEX};
});
