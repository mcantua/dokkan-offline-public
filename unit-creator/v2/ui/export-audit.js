(function(root,factory){
  if(typeof module==='object'&&module.exports)module.exports=factory(require('./core'));
  else root.ForgeExportAudit=factory(root.Forge);
})(typeof globalThis!=='undefined'?globalThis:this,function(Forge){
  'use strict';
  const members=p=>[p,...p.formProjects||[]],idColumns=s=>new Set((s||[]).map(c=>c.name));
  function inspect(project,tables,schema){
    const issues=[],references=new Map(),params=new Set();
    const issue=(code,message,detail)=>issues.push({code,message,detail});
    const available=new Map(Object.entries(tables).map(([name,rows])=>[name,new Set(rows.map(row=>Number(row.id)))]));
    const add=(table,id,detail)=>{
      if(id==null||Number(id)<=0)return;
      id=Number(id);
      if(!Number.isSafeInteger(id)){issue('invalid-reference','A move or ability contains an invalid game reference. Reapply that setting.',detail);return;}
      if(!idColumns(schema[table]).has('id')){issue('missing-table','Your selected game database is missing required character or move data. Update Game Data before exporting.',detail);return;}
      if(available.get(table)?.has(id))return;
      if(!references.has(table))references.set(table,new Map());
      references.get(table).set(id,detail);
    };
    for(const member of members(project)){
      if(member.awaken)continue; // EZA of a game card: the card itself already exists in the game.
      const id=Number(member.targetId),base=Math.floor(id/10)*10,rows=tables.cards||[],card=rows.find(row=>row.id===id),root=rows.find(row=>row.id===base);
      if(!card||!root)issue('missing-root','A required base-card record is missing. Update the creator and export the saved unit again.',{unit:Forge.card(member).name});
      if(card&&['character_id','card_unique_info_id'].some(field=>!Number.isSafeInteger(Number(card[field]))||Number(card[field])<1))issue('missing-identity','The source character identity is incomplete. Start from a valid playable source unit.',{unit:card.name});
      if(card&&root&&['resource_id','character_id','card_unique_info_id'].some(field=>card[field]!==root[field]))issue('root-mismatch','The card and its base record disagree about the character or artwork. Export it again with the current creator.',{unit:card.name});
      const binding=member.artBinding;
      if(!binding)continue;
      if(binding.resourceId!==base||card?.resource_id!==base)issue('art-namespace','Your artwork belongs to a different unit slot. Reapply it in the artwork editor.',{unit:card?.name});
      const stem=String(base).padStart(7,'0'),folder='character/card/'+stem+'/',thumb='character/thumb/card_'+stem+'_thumb/';
      const paths=[...['character','bg','effect','circle','cutin'].map(role=>folder+'card_'+stem+'_'+role+'.png'),folder+'card_'+stem+'sp_cutin_1.png',thumb+'card_'+stem+'_thumb.png'];
      const assets=new Map((member.assets||[]).map(a=>[a.path,a]));
      for(const path of paths){
        const asset=assets.get(path),prefix=path.startsWith(thumb)?thumb:folder,container=path.startsWith(thumb)?'character/thumb/card_'+stem+'_thumb.cpk':'character/card/'+stem+'.cpk',pack=(member.packedAssets||[]).find(a=>a.path===container);
        if(!asset||!pack?.entries?.some(e=>e.path===path.slice(prefix.length)&&e.assetPath===path))issue('missing-art','The in-game artwork pack is incomplete. Reapply your picture in the artwork editor before exporting.',{unit:card?.name,path});
      }
      if(Number(card?.bg_effect_id)>0){
        const bg='character/card_bg/'+stem+'/',pack=(member.packedAssets||[]).find(a=>a.path==='character/card_bg/'+stem+'.cpk');
        if(!['lwf','usm'].some(ext=>{const path=bg+'card_'+stem+'.'+ext;return assets.has(path)&&pack?.entries?.some(e=>e.path==='card_'+stem+'.'+ext&&e.assetPath===path);}))issue('missing-background','The animated card background is missing. Reapply the artwork or choose the still-picture option.',{unit:card?.name});
      }
    }
    for(const row of tables.cards||[])add('cards',Math.floor(Number(row.id)/10)*10,{table:'cards',row:row.id,field:'native base card'});
    for(const [table,rows]of Object.entries(tables))for(const row of rows){
      for(const [field,value]of Object.entries(row)){
        if(field==='id'||value==null||Number(value)<=0)continue;
        const explicit=Forge.foreign[field],inferred=field.endsWith('_id')?field.slice(0,-3)+'s':null,target=explicit||(idColumns(schema[inferred]).has('id')?inferred:null);
        if(target)add(target,value,{table,row:row.id,field});
      }
      if(row.causality_conditions){
        try{
          const condition=JSON.parse(row.causality_conditions),stack=[condition.compiled];let count=0;
          while(stack.length){if(++count>10000)throw Error('Condition too large');const value=stack.pop();if(Array.isArray(value))stack.push(...value);else if(typeof value==='number')add('skill_causalities',value,{table,row:row.id,field:'causality_conditions'});}
        }catch{issue('invalid-condition','An ability has damaged activation conditions. Choose its conditions again before exporting.',{table,row:row.id});}
      }
      if(['passive_skills','active_skills','standby_skills','finish_skills'].includes(table)&&Number(row.efficacy_type)===103){
        let values;try{const parsed=JSON.parse(row.efficacy_values||'{}');if(Array.isArray(parsed))values=parsed;}catch{}
        values=values|| (table==='passive_skills'?[row.eff_value1,row.eff_value2,row.eff_value3]:[row.eff_val1,row.eff_val2,row.eff_val3]);
        if(Number(values[0])>0){add('cards',values[0],{table,row:row.id,field:'transformation target'});add('cards',Math.floor(Number(values[0])/10)*10,{table,row:row.id,field:'transformation base card'});}
        if(Number(values[2])>0)params.add(Number(values[2]));
      }
    }
    return {issues,references,params};
  }
  async function check(project,{schema,query,assetStatus,readDecoration}={}){
    if(!schema||typeof query!=='function'||typeof assetStatus!=='function'||typeof readDecoration!=='function')throw Error('The export checker is unavailable. Update or reopen the creator before exporting.');
    const before=JSON.stringify(project),tables=Forge.materializeAll(project),issues=[];
    for(const [table,rows]of Object.entries(project.sourceDependencies?.tables||{}))tables[table]=[...tables[table]||[],...rows];
    const graph=inspect(project,tables,schema);issues.push(...graph.issues);
    const issue=(code,message,detail)=>issues.push({code,message,detail});
    let referenceCount=0;
    for(const [table,requests]of graph.references){
      const ids=[...requests.keys()];referenceCount+=ids.length;
      if(referenceCount>50000)throw Error('This unit has too many game references to check safely. Split it into smaller patches.');
      for(let start=0;start<ids.length;start+=500){
        const batch=ids.slice(start,start+500),rows=await query({table,ids:batch,limit:batch.length});
        if(!Array.isArray(rows))throw Error('The game database could not be checked. Reopen Game Data and try again.');
        const found=new Set(rows.map(row=>Number(row.id)));
        for(const id of batch)if(!found.has(id))issue('missing-record','Some character, move, or ability data is missing from your selected game database. Update Game Data or choose a different source.',{...requests.get(id),targetTable:table,targetId:id});
      }
    }
    for(const param of graph.params){
      if((tables.battle_params||[]).some(row=>row.param_no===param))continue;
      if(!schema.battle_params||(await query({table:'battle_params',filters:{param_no:param},limit:1})).length===0)issue('missing-transform-profile','A transformation is missing its game settings. Choose a complete transforming source unit.',{param});
    }
    const allAssets=members(project).flatMap(member=>member.assets||[]),keys=[...new Set(allAssets.map(a=>a.key))];
    for(let start=0;start<keys.length;start+=500){
      const batch=keys.slice(start,start+500),status=await assetStatus(batch);
      if(!Array.isArray(status))throw Error('The attached files could not be checked. Reopen the creator and try again.');
      const found=new Map(status.map(item=>[item.key,item]));
      for(const key of batch)if(found.get(key)?.available!==true||!(found.get(key)?.bytes>0))issue('missing-file','An attached picture, animation, or sound file is missing, empty, or too large. Import the complete unit file or reattach the content.',{key});
    }
    for(const member of members(project)){
      if(!member.artBinding)continue;
      const decoration=new Map((member.assets||[]).filter(a=>/\/card_[0-9]+_decoration_[0-9]+\.json$/.test(a.path)).map(a=>[a.key,a]));
      for(const [key]of decoration){
        if(issues.some(i=>i.code==='missing-file'&&i.detail.key===key))continue;
        try{
          const data=JSON.parse(await readDecoration(key));
          if(data.card_id!==member.targetId||!Array.isArray(data.parameters))throw Error('wrong card');
          for(const p of data.parameters){
            if(p?.type!=='sampler2D')continue;
            if(typeof p.value!=='string'||!Forge.safePath(p.value))throw Error('unsafe texture');
            if(p.value.startsWith('character/card/')||p.value.startsWith('character/card_bg/')){
              const kind=p.value.startsWith('character/card_bg/')?'card_bg':'card',prefix='character/'+kind+'/'+member.artBinding.resourceId+'/',oldPrefix='character/'+kind+'/'+String(member.artBinding.sourceId).padStart(7,'0')+'/';
              if(p.value.startsWith(oldPrefix)||p.value.startsWith(prefix)&&!(member.assets||[]).some(a=>a.path===p.value))throw Error('stale or missing texture');
            }
          }
        }catch{issue('decoration-reference','The saved artwork points to missing or different character images. Reapply it in the artwork editor.',{key,unit:Forge.card(member).name});}
      }
    }
    if(JSON.stringify(project)!==before)throw Error('Your design changed while its files were checked. Export again.');
    return {errors:[...new Set(issues.map(i=>i.message))],issues,checked:{externalReferences:referenceCount,attachedFiles:keys.length,forms:members(project).length},scope:'Selected-database references and attached artwork/file integrity only. This is not Eclipse gameplay verification.'};
  }
  return {inspect,check};
});
