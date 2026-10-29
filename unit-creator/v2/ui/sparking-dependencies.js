(function(root,factory){if(typeof module==='object'&&module.exports)module.exports=factory();else root.ForgeSparkingDependencies=factory();})(typeof globalThis==='object'?globalThis:this,function(){
  'use strict';
  const clone=x=>JSON.parse(JSON.stringify(x)),timestamps=new Set(['created_at','updated_at']),LIMIT=5000;
  const ident=x=>{if(!/^[a-zA-Z_][a-zA-Z0-9_]*$/.test(x))throw Error('Invalid dependency table or column.');return '"'+x+'"';};
  const quote=x=>x==null?'NULL':typeof x==='number'&&Number.isFinite(x)?String(x):typeof x==='string'?"'"+x.replace(/'/g,"''")+"'":(()=>{throw Error('Unsupported dependency value.');})();
  function same(a,b){return Object.keys(a).filter(k=>!timestamps.has(k)).every(k=>a[k]===b[k]);}
  function affinity(t){t=String(t).toUpperCase();return /INT/.test(t)?'integer':/CHAR|CLOB|TEXT/.test(t)?'text':/BLOB/.test(t)||!t?'blob':/REAL|FLOA|DOUB/.test(t)?'real':'numeric';}
  function validate(bundle,targetSchema){
    const issues=[];let count=0;
    for(const [table,rows] of Object.entries(bundle.tables||{})){
      ident(table);if(!Array.isArray(rows))throw Error('Invalid dependency rows.');const source=bundle.schema?.[table]||[],target=targetSchema?(targetSchema[table]||[]):source,columns=new Map(target.map(c=>[c.name,c]));
      if(!columns.size)issues.push({severity:'error',code:'SCHEMA_MISSING',table,message:'The Eclipse database does not support dependency table '+table+'.'});
      const seen=new Set();for(const row of rows){if(++count>LIMIT)throw Error('The unit has too many shared dependencies.');if(!Number.isSafeInteger(row.id)||row.id<=0||seen.has(row.id))throw Error('Invalid or duplicate shared dependency ID.');seen.add(row.id);
        for(const [field,value] of Object.entries(row)){ident(field);quote(value);if(!columns.has(field)||source.some(c=>c.name===field&&affinity(c.type)!==affinity(columns.get(field)?.type)))issues.push({severity:'error',code:'SCHEMA_MISMATCH',table,id:row.id,field,message:'The source and Eclipse dependency schemas differ at '+table+'.'+field+'.'});}
        for(const c of target)if(c.notnull&&c.dflt_value==null&&row[c.name]==null)issues.push({severity:'error',code:'REQUIRED_FIELD',table,id:row.id,field:c.name,message:'A required Eclipse dependency field is missing.'});
      }
    }return issues;
  }
  async function collect(project,{sourceQuery,targetQuery,sourceSchema,targetSchema,effectIds=[]}){
    if(typeof sourceQuery!=='function'||typeof targetQuery!=='function'||!sourceSchema||!targetSchema||project?.tables?.cards?.length!==1)throw Error('Load the Sparking source and Eclipse database before checking dependencies.');
    const result={tables:{},schema:{},issues:[],assetPaths:[]},seen=new Map(),assets=new Set(),issueKeys=new Set();let reads=0;
    const issue=(code,table,id,message,severity='error',field)=>{const key=[code,table,id,field].join(':');if(!issueKeys.has(key)){issueKeys.add(key);result.issues.push({severity,code,table,id,...(field?{field}:{}),message});}};
    async function query(fn,table,filters){if(++reads>10000)throw Error('The source dependency graph exceeds the supported size.');return await fn({table,filters,limit:LIMIT});}
    function path(p){if(!p||p.length>500||p.split('/').some(x=>!x||x==='.'||x==='..')||/[\\:\x00-\x1f\x7f]/.test(p))throw Error('Unsafe dependency asset reference.');assets.add(p);}
    function script(name,folder,table,id){if(!name)return;if(!/^\w+$/.test(name)){issue('SCRIPT_PATH_UNSUPPORTED',table,id,'This source script uses an unsupported filename.');return;}path('lua/ab_script/'+folder+'/'+name+'.lua');issue('SCRIPT_DEPENDENCIES_UNSCANNED',table,id,'This original script must be imported and checked for effect, audio and movie dependencies. Its filename alone does not prove those resources are present.','warning');}
    async function need(table,id){
      if(id==null||Number(id)===0)return null;id=Number(id);const embedded=(project.tables[table]||[]).find(r=>Number(r.id)===id);if(!Number.isSafeInteger(id)||id<0&&!embedded){issue('REFERENCE_INVALID',table,id,'A source dependency ID is invalid.');return null;}
      const key=table+':'+id;if(seen.has(key))return seen.get(key);
      if(!sourceSchema[table]||!targetSchema[table]){issue('SCHEMA_MISSING',table,id,'The source or Eclipse database lacks dependency table '+table+'.');seen.set(key,null);return null;}
      const source=embedded||(await query(sourceQuery,table,{id}))[0];
      if(!source){issue('SOURCE_ROW_MISSING',table,id,'The source database references a missing '+table+' record.');seen.set(key,null);return null;}seen.set(key,source);
      // Project-owned rows are already exported privately by Forge; do not duplicate them globally.
      if(!embedded){const existing=(await query(targetQuery,table,{id}))[0];if(existing){if(!same(source,existing))issue('TARGET_ROW_CONFLICT',table,id,'Eclipse already has a different '+table+' record with this ID. Its shared data must not be overwritten.');}
        else {result.tables[table]=result.tables[table]||[];result.schema[table]=clone(sourceSchema[table]);result.tables[table].push(clone(source));}}
      if(table==='characters')path('ingame/battle/character/'+String(id).padStart(5,'0')+'.cpk');
      if(table==='special_views'){
        const name=source.script_name||'',prefix=/^(sp|bs|ut|st|fi|pse|as|tf|trs|rv|rev|enl|c)/.exec(name)?.[1],folders={sp:'attack_sp',bs:'active_skill',ut:'ultimate_special',st:'standby_skill',fi:'finish_skill',pse:'passive_skill_effect',as:'ab_sys',tf:'transformation',trs:'transformation',rv:'revival',rev:'revival',enl:'enlarge',c:'attack_counter'};
        if(prefix)script(name,folders[prefix],table,id);else if(name)issue('SCRIPT_PATH_UNSUPPORTED',table,id,'Import the source Lua archive to locate this script exactly.');
        if(source.cut_in_card_id&&!embedded){const target=(await query(targetQuery,'cards',{id:source.cut_in_card_id}))[0];if(!target)issue('CUTIN_CARD_MISSING','cards',source.cut_in_card_id,'The original cut-in references another card absent from Eclipse.');}
      }
      if(table==='revival_views'){await need('effect_packs',source.effect_pack_id);if(source.script_name)script(source.script_name,'revival',table,id);}
      if(table==='transformation_views')for(const f of ['begin_script_name','end_script_name'])script(source[f],'transformation',table,id);
      if(table==='metamorphic_views')for(const f of ['begin_script_name','continue_script_name','end_script_name']){const name=source[f];if(name){if(/^enl/.test(name))script(name,'enlarge',table,id);else if(/^(?:tf|trs)/.test(name))script(name,'transformation',table,id);else issue('SCRIPT_PATH_UNSUPPORTED',table,id,'Import the source Lua archive to locate this giant-form script exactly.');}}
      if(table==='effect_packs'){
        if(!/^\w+$/.test(source.pack_name||''))issue('EFFECT_PATH_UNSUPPORTED',table,id,'This effect uses an unsupported resource pack name.');
        else if(Number(source.category)===1)path('ingame/battle/effect/'+source.pack_name+'.cpk');
        else if(Number(source.category)===5)path('ingame/battle/sp_effect/'+source.pack_name+'.cpk');
        else issue('EFFECT_CATEGORY_UNVERIFIED',table,id,'This effect category needs its original resource path verified.','warning');
        issue('EFFECT_MEDIA_UNSCANNED',table,id,'Verify this pack against the source asset manifest. Effect category does not determine whether its content is LWF, a movie, or both.','warning');
      }
      return source;
    }
    const card=Object.assign({},project.tables.cards[0],project.cardOverrides||{});await need('characters',card.character_id);await need('card_unique_infos',card.card_unique_info_id);
    if(card.card_unique_info_id&&sourceSchema.card_unique_info_set_relations&&targetSchema.card_unique_info_set_relations){
      const relations=await query(sourceQuery,'card_unique_info_set_relations',{card_unique_info_id:card.card_unique_info_id});
      for(const row of relations)await need('card_unique_info_set_relations',row.id);
    }
    for(const [table,rows] of Object.entries(project.tables))for(const row of rows){
      for(const field of ['view_id','special_view_id','costume_special_view_id','bonus_view_id1','bonus_view_id2'])if(row[field])await need('special_views',row[field]);
      if(table==='active_skill_sets'&&row.ultimate_special_id)await need('ultimate_specials',row.ultimate_special_id);
    }
    for(const source of Object.values(project.abilityAnimationSources||{})){
      if(source.view?.id){const table=Number(source.effect)===109?'revival_views':source.viewTable;if(table)await need(table,source.view.id);}
      if(source.params?.length)issue('BATTLE_PARAMETER_GROUP_UNSCANNED','battle_params',source.params[0]?.param_no,'This form uses a shared parameter group; its complete group and target collisions require verification.','warning');
    }
    if(!Array.isArray(effectIds)||effectIds.length>LIMIT||effectIds.some(id=>!Number.isSafeInteger(id)||id<=0||id>2147483647))throw Error('Provide only verified positive native effect IDs from the source script inventory.');
    for(const id of new Set(effectIds))await need('effect_packs',id);
    result.issues.push(...validate(result,targetSchema));result.assetPaths=Array.from(assets).sort();return result;
  }
  function sql(bundle){
    const errors=[...(bundle.issues||[]),...validate(bundle)].filter(i=>i.severity==='error');if(errors.length)throw Error(errors[0].message);
    const rows=[];for(const table of Object.keys(bundle.tables||{}).sort())for(const row of [...bundle.tables[table]].sort((a,b)=>a.id-b.id))rows.push([table,row]);if(!rows.length)return '';
    const guard='"__forge_sparking_dependency_guard"',out=['-- Original shared Sparking dependencies; existing differing records abort this patch.', 'CREATE TEMP TABLE IF NOT EXISTS '+guard+' ("ok" INTEGER CHECK ("ok" = 1));','DELETE FROM '+guard+';'];
    for(const [table,row] of rows){const keys=Object.keys(row),equal=keys.filter(k=>!timestamps.has(k)).map(k=>ident(k)+' IS '+quote(row[k])).join(' AND ');out.push('INSERT INTO '+guard+' ("ok") SELECT 0 WHERE EXISTS (SELECT 1 FROM '+ident(table)+' WHERE "id" = '+quote(row.id)+' AND NOT ('+equal+'));');out.push('INSERT OR IGNORE INTO '+ident(table)+' ('+keys.map(ident).join(', ')+') VALUES ('+keys.map(k=>quote(row[k])).join(', ')+');');}
    out.push('DROP TABLE '+guard+';');return out.join('\n')+'\n';
  }
  return {collect,validate,sql};
});
