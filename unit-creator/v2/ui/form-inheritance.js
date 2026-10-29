/* A form follows its base's gameplay settings; its passive, moves, Domain, art and identity stay local. */
(function(root,factory){
  if(typeof module==='object'&&module.exports)module.exports=factory(require('./core'),require('./guide-model'),require('./movie-model'));
  else root.ForgeFormInheritance=factory(root.Forge,root.ForgeGuide,root.ForgeMovieModel);
})(typeof globalThis!=='undefined'?globalThis:this,function(F,G,M){
  'use strict';
  const GROUPS=['stats','leader','links','categories','gameplay'];
  const selected=value=>({...Object.fromEntries(GROUPS.map(k=>[k,value?.[k]!==false])),passive:false});
  // These fields identify the form or belong to the explicitly excluded artwork / Super attack.
  const LOCAL=new Set(['id','name','character_id','card_unique_info_id','resource_id','face_x','face_y','aura_id','aura_scale','aura_offset_x','aura_offset_y','is_aura_front','bg_effect_id','special_motion','skill_lv_max','created_at','updated_at','open_at']);
  const GAME=['card_motions','card_standby_skill_set_relations','standby_skill_sets','standby_skills','standby_skill_set_finish_skill_set_relations','card_finish_skill_set_relations','finish_skill_sets','finish_skills','finish_specials'];
  const DEPS=['sub_target_type_sets','sub_target_types','skill_causalities'];
  function conditionIds(value,ids){if(typeof value==='number')ids.add(value);else if(Array.isArray(value))value.slice(1).forEach(v=>conditionIds(v,ids));}
  function fingerprint(base,groups){const c=F.card(base);return JSON.stringify({card:c,tables:Object.fromEntries(Object.entries(base.tables).filter(([t])=>t!=='cards'&&(DEPS.includes(t)||t==='optimal_awakening_growths'||groups.leader&&['leader_skill_sets','leader_skills'].includes(t)||groups.gameplay&&GAME.includes(t)||groups.categories&&t==='card_card_categories'))),auto:base.builderAuto,animations:[base.abilityAnimationSources,base.animationReferences,base.animationAssignments,base.generatedFiles,base.normalAttackStyle]});}
  function copy(base,form,options={}){
    if(!base?.tables?.cards?.length||!form?.tables?.cards?.length||base.key===form.key)throw Error('Choose a separate base unit and transformation form.');
    const groups=selected(options.groups),work=F.clone(form),card=F.card(base),old=work.inheritedBaseSettings||{},oldCard=F.card(work);
    const oldGrowth=F.clone(work.tables.optimal_awakening_growths||[]),oldTargets=G.targets(work);
    work.cardOverrides=work.cardOverrides||{};
    for(const [field,value] of Object.entries(card)){
      if(LOCAL.has(field)||['leader_skill_set_id','passive_skill_set_id'].includes(field))continue;
      const group=/^(hp|atk|def)_(init|max)$/.test(field)?'stats':/^link_skill\d_id$/.test(field)?'links':'gameplay';
      if(groups[group])work.cardOverrides[field]=F.clone(value);
    }
    const donor={schema:base.schema,tables:{},abilityAnimationSources:base.abilityAnimationSources};
    const add=t=>{if(base.schema[t])donor.tables[t]=F.clone(base.tables[t]||[]);};
    if(groups.leader){add('leader_skill_sets');add('leader_skills');}
    if(groups.categories)add('card_card_categories');
    if(groups.gameplay)GAME.forEach(add);
    const whole=new Set(Object.keys(donor.tables));
    // Follow custom supporting records (views, battle parameters, etc.) without copying
    // the template's excluded move or artwork tables as a side effect.
    const excluded=/^(cards|passive_.*|card_specials|specials|special_sets|extra_special_options|card_active_skills|active_skill_sets|active_skills|dokkan_field.*|card_awakening_routes)$/;
    const include=(t,id)=>{if(!t||excluded.test(t)||whole.has(t)||!base.schema[t])return false;const r=(base.tables[t]||[]).find(v=>v.id===id);if(!r||(donor.tables[t]||[]).some(v=>v.id===id))return false;(donor.tables[t]||(donor.tables[t]=[])).push(F.clone(r));return true;};
    let changed=true;while(changed){changed=false;for(const rows of Object.values(donor.tables))for(const r of rows)for(const [field,id]of Object.entries(r))if(field!=='id'&&field!=='card_id')changed=include(F.foreign[field]||(field.endsWith('_id')?field.slice(0,-3)+'s':null),id)||changed;for(const ref of base.animationReferences||[])if((donor.tables[ref.table]||[]).some(r=>r.id===ref.row))changed=include(ref.targetTable,ref.targetId)||changed;}
    // Carry the exact local category and condition records used by the inherited abilities.
    const subs=new Set(),causes=new Set();
    for(const rows of Object.values(donor.tables))for(const row of rows){if(row.sub_target_type_set_id)subs.add(row.sub_target_type_set_id);if(row.causality_conditions){let c;try{c=JSON.parse(row.causality_conditions);}catch{throw Error('A base ability has an unreadable condition. Review it before copying.');}conditionIds(c.compiled,causes);}}
    donor.tables.sub_target_type_sets=(base.tables.sub_target_type_sets||[]).filter(r=>subs.has(r.id));
    donor.tables.sub_target_types=(base.tables.sub_target_types||[]).filter(r=>subs.has(r.sub_target_type_set_id));
    donor.tables.skill_causalities=(base.tables.skill_causalities||[]).filter(r=>causes.has(r.id));
    // Dependencies can also be used by the excluded local moves: retain those records.
    const protectedDeps={};for(const t of Object.keys(donor.tables))protectedDeps[t]=new Set();for(const t of DEPS)protectedDeps[t]=new Set();
    const localSubs=new Set(),localCauses=new Set();
    for(const [t,rows] of Object.entries(work.tables))if(!Object.prototype.hasOwnProperty.call(donor.tables,t))for(const r of rows){if(r.sub_target_type_set_id)localSubs.add(r.sub_target_type_set_id);if(r.causality_conditions)try{conditionIds(JSON.parse(r.causality_conditions).compiled,localCauses);}catch{}}
    protectedDeps.sub_target_type_sets=localSubs;protectedDeps.skill_causalities=localCauses;
    for(const r of work.tables.sub_target_types||[])if(localSubs.has(r.sub_target_type_set_id))protectedDeps.sub_target_types.add(r.id);
    for(const [t,rows]of Object.entries(work.tables))if(!whole.has(t))for(const r of rows)for(const [field,id]of Object.entries(r)){if(Object.prototype.hasOwnProperty.call(donor.tables,t)&&(old.owned||old.ownedLeader||{})[t]?.includes(r.id))continue;if(field==='id')continue;const target=F.foreign[field]||(field.endsWith('_id')?field.slice(0,-3)+'s':null);protectedDeps[target]?.add(id);}
    for(const ref of work.animationReferences||[])if(!whole.has(ref.table))protectedDeps[ref.targetTable]?.add(ref.targetId);
    for(const [t,ids] of Object.entries(old.owned||old.ownedLeader||{}))if(Object.prototype.hasOwnProperty.call(donor.tables,t))work.tables[t]=(work.tables[t]||[]).filter(r=>!ids.includes(r.id)||protectedDeps[t]?.has(r.id));
    // Whole ability groups are replaced, avoiding unused template sets and stale stage pointers.
    for(const t of whole)work.tables[t]=[];
    const maps={},owned={},inserted={};
    for(const [t,rows] of Object.entries(donor.tables)){
      if(!base.schema[t])continue;G.ensure(work,base.schema,t);maps[t]=new Map();owned[t]=[];inserted[t]=[];
      const reserved=new Set(work.tables[t].map(r=>r.id));let next=Math.min(0,...reserved,...Object.values(old.maps?.[t]||{}))-1;
      for(const source of rows){let id=old.maps?.[t]?.[source.id];if(!Number.isSafeInteger(id)||reserved.has(id))id=next--;reserved.add(id);maps[t].set(source.id,id);owned[t].push(id);const r={...F.clone(source),id};work.tables[t].push(r);inserted[t].push(r);}
    }
    const mapped=(t,id)=>maps[t]?.get(id)??id;
    const rewrite=n=>typeof n==='number'?mapped('skill_causalities',n):Array.isArray(n)?n.map((v,i)=>i?rewrite(v):v):n;
    for(const [t,rows] of Object.entries(inserted))for(const r of rows){
      for(const [field,value] of Object.entries(r)){if(field==='id')continue;if(field==='card_id'){r[field]=work.source.cardId;continue;}const target=F.foreign[field]||(field.endsWith('_id')?field.slice(0,-3)+'s':null);if(target)r[field]=mapped(target,value);}
      if(r.causality_conditions){const c=JSON.parse(r.causality_conditions);c.compiled=rewrite(c.compiled);if(typeof c.source==='string')c.source=c.source.replace(/-?\d+/g,n=>String(mapped('skill_causalities',Number(n))));r.causality_conditions=JSON.stringify(c);}
      if(Number(r.efficacy_type)===110){const target={1:'active_skills',2:'passive_skills',14:'standby_skills',15:'finish_skills'}[Number(r.eff_value1??r.eff_val1)],field='eff_value2' in r?'eff_value2':'eff_val2';if(target)r[field]=mapped(target,r[field]);let vals;try{vals=JSON.parse(r.efficacy_values);}catch{}if(Array.isArray(vals)&&target){vals[1]=mapped(target,vals[1]);r.efficacy_values=JSON.stringify(vals);}}
    }
    if(groups.leader)work.cardOverrides.leader_skill_set_id=mapped('leader_skill_sets',card.leader_skill_set_id);
    // Each form owns its passive at every awakening stage. Keep local stages and
    // use that form's base passive for new stages introduced by the base unit.
    if(groups.gameplay&&base.schema.optimal_awakening_growths){
      G.ensure(work,base.schema,'optimal_awakening_growths');
      const growth=F.clone(base.tables.optimal_awakening_growths||[]);
      for(const local of oldGrowth)if(!growth.some(r=>Number(r.step)===Number(local.step)))growth.push(F.clone(local));
      work.tables.optimal_awakening_growths=growth;
    }
    for(const r of work.tables.optimal_awakening_growths||[]){
      const b=(base.tables.optimal_awakening_growths||[]).find(v=>Number(v.step)===Number(r.step)),local=oldGrowth.find(v=>Number(v.step)===Number(r.step));
      r.passive_skill_set_id=local?.passive_skill_set_id??oldCard.passive_skill_set_id;
      if(groups.leader)r.leader_skill_set_id=mapped('leader_skill_sets',b?.leader_skill_set_id??card.leader_skill_set_id);
      if(groups.gameplay)r.skill_lv_max=local?.skill_lv_max??oldCard.skill_lv_max;
    }
    work.builderAuto=work.builderAuto||{};for(const kind of ['leader'])if(groups[kind])for(const [from,to]of maps[kind+'_skill_sets']||[])work.builderAuto[kind+':'+to]=base.builderAuto?.[kind+':'+from]??false;
    work.abilityAnimationSources=work.abilityAnimationSources||{};for(const [key,input] of Object.entries(base.abilityAnimationSources||{})){const at=key.lastIndexOf(':'),t=key.slice(0,at),id=Number(key.slice(at+1));if(maps[t]?.has(id))work.abilityAnimationSources[t+':'+mapped(t,id)]=F.clone(input);}
    work.animationReferences=(work.animationReferences||[]).filter(r=>!whole.has(r.table));
    for(const ref of base.animationReferences||[])if(maps[ref.table]?.has(ref.row))work.animationReferences.push({...F.clone(ref),row:mapped(ref.table,ref.row),targetId:mapped(ref.targetTable,ref.targetId)});
    for(const [t,rows] of Object.entries(inserted))for(const r of rows)if(Number(r.efficacy_type)===110){const target={1:'active_skills',2:'passive_skills',14:'standby_skills',15:'finish_skills'}[Number(r.eff_value1??r.eff_val1)],field='eff_value2' in r?'eff_value2':'eff_val2';if(target&&Number(r[field])<0&&(work.tables[target]||[]).some(v=>v.id===r[field])){work.animationReferences.push({table:t,row:r.id,field,targetTable:target,targetId:r[field]});let vals;try{vals=JSON.parse(r.efficacy_values);}catch{}if(Array.isArray(vals))work.animationReferences.push({table:t,row:r.id,field:'efficacy_values',index:1,targetTable:target,targetId:r[field]});}}
    // Normal/Standby/Finish animations follow those inherited abilities; passive animations remain local.
    // Excluded moves and the form's own transformation/Domain triggers retain their bindings.
    const assignmentKeys=[],removeKeys=new Set((old.assignmentKeys||[]).filter(key=>oldTargets.some(t=>t.key===key&&whole.has(t.table))));
    for(const target of oldTargets)if(whole.has(target.table))removeKeys.add(target.key);
    work.animationAssignments=work.animationAssignments||{};for(const key of removeKeys)delete work.animationAssignments[key];
    work.generatedFiles=(work.generatedFiles||[]).filter(f=>!removeKeys.has(f.owner));
    const keyMap=key=>{const bits=key.split(':');for(let i=0;i<bits.length-1;i++)if(maps[bits[i]]?.has(Number(bits[i+1])))bits[i+1]=String(mapped(bits[i],Number(bits[i+1])));if(['counter','intro'].includes(bits[0])&&bits.length===2)bits[1]=String(mapped('passive_skills',Number(bits[1])));if(bits[0]==='normal'&&bits.length===2)bits[1]=String(mapped('card_motions',Number(bits[1])));return bits.join(':');};
    if(groups.gameplay){if(base.normalAttackStyle)work.normalAttackStyle={...F.clone(base.normalAttackStyle),sourceRows:base.normalAttackStyle.sourceRows.map(r=>({...r,id:mapped('card_motions',r.id),card_id:work.source.cardId})),sourceOrder:base.normalAttackStyle.sourceOrder.map(id=>mapped('card_motions',id)),ownedRows:base.normalAttackStyle.ownedRows.map(r=>({...r,id:mapped('card_motions',r.id),card_id:work.source.cardId}))};else delete work.normalAttackStyle;}
    const beforeAnimation=Object.fromEntries(Object.entries(work.tables).map(([t,rows])=>[t,new Set(rows.map(r=>r.id))]));
    for(const target of G.targets(base))if(maps[target.table]?.has(target.row)||target.kind==='normal'&&groups.gameplay){
      const a=base.animationAssignments?.[target.key];if(!a)continue;const key=keyMap(target.key);
      const clips=M.copyClips(base,work,a.clips);
      if(a.music?.kind==='file'){const asset=base.assets?.find(v=>v.path===a.music.path);if(asset&&!work.assets.some(v=>v.path===asset.path))work.assets.push(F.clone(asset));}
      if(target.kind==='counter')G.reserveCounterScripts(work,G.counterNumbers(base));
      if(a.mode==='original'&&a.originalSource)G.applyOriginal(work,base.schema,a.originalSource,key,a.name);
      else G.applyComposition(work,base.schema,clips,key,a.name,{music:a.music});
      assignmentKeys.push(key);
      if(base.uiLabels?.animations?.[target.key]){work.uiLabels=work.uiLabels||{};work.uiLabels.animations=work.uiLabels.animations||{};work.uiLabels.animations[key]=base.uiLabels.animations[target.key];}
    }
    for(const [t,rows]of Object.entries(work.tables))for(const r of rows)if(!beforeAnimation[t]?.has(r.id)&&!(t==='effect_packs'&&work.movieBindings?.some(b=>b.rowId===r.id)))(owned[t]||(owned[t]=[])).push(r.id);
    work.inheritedBaseSettings={version:3,baseKey:base.key,groups,linked:options.linked!==false,pending:false,fingerprint:fingerprint(base,groups),owned,assignmentKeys,maps:Object.fromEntries(Object.entries(maps).map(([t,m])=>[t,Object.fromEntries(m)]))};
    work.updatedAt=new Date(Math.max(Date.now(),(Date.parse(form.updatedAt)||0)+1)).toISOString();Object.assign(form,work);return form;
  }
  function syncPending(base){if(!base)return;for(const form of base.formProjects||[]){const m=form.inheritedBaseSettings;if(m?.linked===false)continue;if(m?.baseKey&&m.baseKey!==base.key)continue;const groups=m?.version>=2?selected(m.groups):selected();if(m?.version!==3||m.fingerprint!==fingerprint(base,groups)){copy(base,form,{groups});base.updatedAt=new Date(Math.max(Date.now(),(Date.parse(base.updatedAt)||0)+1)).toISOString();}}}
  return {GROUPS,selected,copy,syncPending};
});
