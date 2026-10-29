(function(root,factory){
  if(typeof module==='object'&&module.exports)module.exports=factory(require('./sparking-script-resources.js'),require('./sparking-dependencies.js'),require('./sparking-helper-resources.js'),async bytes=>require('node:crypto').createHash('sha256').update(bytes).digest('hex'));
  else root.ForgeSparkingAnimationImport=factory(root.ForgeSparkingScriptResources,root.ForgeSparkingDependencies,root.ForgeSparkingHelperResources,async bytes=>{
    if(!root.crypto?.subtle)throw Error('Update Android System WebView before checking imported animation sources.');
    return Array.from(new Uint8Array(await root.crypto.subtle.digest('SHA-256',bytes)),n=>n.toString(16).padStart(2,'0')).join('');
  });
})(typeof globalThis==='object'?globalThis:this,function(Inventory,Dependencies,Helpers,digest){
  'use strict';
  const MAX_EFFECTS=1024,MAX_ANIMATIONS=256,MAX_ISSUES=20000,MAX_JSON=20*1024*1024,timestamps=new Set(['created_at','updated_at']);
  function clone(value){const text=JSON.stringify(value);if(typeof text!=='string'||text.length>MAX_JSON)throw Error('This animation dependency bundle exceeds the supported project size.');return JSON.parse(text);}
  function canonical(value){if(Array.isArray(value))return '['+value.map(canonical).join(',')+']';if(value&&typeof value==='object')return '{'+Object.keys(value).sort().map(k=>JSON.stringify(k)+':'+canonical(value[k])).join(',')+'}';return JSON.stringify(value);}
  function ids(values){if(!Array.isArray(values)||values.length>MAX_EFFECTS*(MAX_ANIMATIONS+2)||values.some(n=>!Number.isSafeInteger(n)||n<=0||n>2147483647))throw Error('The imported clip has invalid native effect references.');const result=Array.from(new Set(values)).sort((a,b)=>a-b);if(result.length>MAX_EFFECTS)throw Error('This unit uses too many Sparking effects. Split it into smaller sequences (maximum1024 distinct effects).');return result;}
  function path(value,script=false){if(typeof value!=='string'||!value||value.length>500||/[\\:\x00-\x1f\x7f?#]/.test(value)||value.split('/').some(p=>!p||p==='.'||p==='..'))throw Error('This animation has an unsafe original source path.');if(script){if(value.startsWith('lua/'))value=value.slice(4);if(!value.startsWith('ab_script/')||!value.endsWith('.lua'))throw Error('Choose an original Sparking Lua animation.');}else if(/^(?:se|voice)\//.test(value)){if(!/^(?:se\/[A-Za-z0-9_-]{1,80}\.(?:acb|awb)|voice\/(?:(?:en|ja)\/)?([A-Za-z0-9_-]{1,80})\/\1\.(?:acb|awb))$/.test(value))throw Error('Choose an original sound or matching voice-bank pair.');}else if(!/^(?:lua\/ab_script\/|ingame\/|movie\/|character\/|sound\/|bgm\/|item\/|outgame\/|script\/|sd_battle\/|sugoroku\/)/.test(value))throw Error('This dependency is not a supported game resource path.');return value;}
  function version(value){if(!Number.isSafeInteger(value)||value<=0)throw Error('Refresh the Sparking source information before importing this animation.');return value;}
  function key(value){if(!/^[a-zA-Z_][a-zA-Z0-9_]*$/.test(value)||['__proto__','prototype','constructor'].includes(value))throw Error('Invalid shared dependency table or column.');return value;}
  function normalize(bundle){
    const input=bundle==null?{}:clone(bundle),out={tables:{},schema:{},issues:[],assetPaths:[],effectIds:ids(input.effectIds||[]),animations:[]};
    if(!input||typeof input!=='object'||Array.isArray(input))throw Error('Invalid animation dependency bundle.');
    for(const [table,rows] of Object.entries(input.tables||{})){key(table);if(!Array.isArray(rows))throw Error('Invalid shared dependency rows.');for(const row of rows)for(const field of Object.keys(row||{}))key(field);out.tables[table]=clone(rows);out.schema[table]=clone(input.schema?.[table]||[]);}
    const errors=Dependencies.validate(out).filter(i=>i.severity==='error');if(errors.length)throw Error(errors[0].message);
    if(!Array.isArray(input.issues||[])||(input.issues||[]).length>MAX_ISSUES)throw Error('The dependency report is too large.');
    out.issues=clone(input.issues||[]);for(const issue of out.issues)if(!issue||!['warning','error'].includes(issue.severity)||typeof issue.code!=='string'||typeof issue.message!=='string'||issue.message.length>4000)throw Error('Invalid animation dependency diagnostic.');
    if(!Array.isArray(input.assetPaths||[])||(input.assetPaths||[]).length>10000)throw Error('Too many animation resource paths.');out.assetPaths=Array.from(new Set((input.assetPaths||[]).map(p=>path(p)))).sort();
    if(!Array.isArray(input.animations||[])||(input.animations||[]).length>MAX_ANIMATIONS)throw Error('Too many imported animation sources.');
    for(const entry of input.animations||[]){if(!entry||entry.sourceDatabase!=='sparking'||typeof entry.sha256!=='string'||!/^([a-f0-9]{64})$/.test(entry.sha256))throw Error('An imported animation lost its source fingerprint.');const source={sourceDatabase:'sparking',path:path(entry.path,true),sha256:entry.sha256,version:version(entry.version),effectIds:ids(entry.effectIds||[]),unresolved:clone(entry.unresolved||[])};if(!Array.isArray(source.unresolved)||source.unresolved.length>10000)throw Error('Invalid source resource diagnostics.');for(const item of source.unresolved)if(!item||typeof item.reason!=='string'||typeof item.command!=='string'||item.reason.length>4000||!Number.isSafeInteger(item.line)||item.line<0||!Number.isSafeInteger(item.column)||item.column<0)throw Error('Invalid source resource diagnostic.');out.animations.push(source);}
    if(new Set(out.animations.map(a=>a.version)).size>1)throw Error('These clips use different Sparking content versions. Use matching source data before combining them.');
    const all=ids(out.effectIds.concat(...out.animations.map(a=>a.effectIds)));if(all.length!==out.effectIds.length||all.some((id,i)=>id!==out.effectIds[i]))throw Error('The imported animation effect routing does not match its recorded sources.');
    return out;
  }
  function merge(existingBundle,newBundle){
    const a=normalize(existingBundle),b=normalize(newBundle);
    if(a.animations.length&&b.animations.length&&a.animations[0].version!==b.animations[0].version)throw Error('These clips use different Sparking content versions. Use matching source data before combining them.');
    const result=clone(a);result.effectIds=ids(a.effectIds.concat(b.effectIds));
    for(const [table,rows] of Object.entries(b.tables)){
      if(result.schema[table]&&canonical(result.schema[table])!==canonical(b.schema[table]))throw Error('These clips use different shared dependency schemas in '+table+'.');
      if(!result.tables[table]){result.tables[table]=[];result.schema[table]=clone(b.schema[table]);}
      for(const row of rows){const prior=result.tables[table].find(r=>r.id===row.id);if(prior){const clean=r=>Object.fromEntries(Object.entries(r).filter(([k])=>!timestamps.has(k)));if(canonical(clean(prior))!==canonical(clean(row)))throw Error('These clips require different '+table+' definitions for ID '+row.id+'. Keep compatible source clips or use a different sequence.');}else result.tables[table].push(clone(row));}
    }
    const issues=new Map();for(const issue of a.issues.concat(b.issues))issues.set(canonical(issue),issue);result.issues=Array.from(issues.values());
    result.assetPaths=Array.from(new Set(a.assetPaths.concat(b.assetPaths))).sort();const animations=new Map();
    for(const entry of a.animations.concat(b.animations)){
      const k=[entry.path,entry.sha256,entry.version].join(':');if(animations.has(k)&&canonical(animations.get(k))!==canonical(entry))throw Error('This original animation fingerprint has conflicting resource references.');animations.set(k,entry);
    }
    result.animations=Array.from(animations.values());for(const rows of Object.values(result.tables))rows.sort((x,y)=>x.id-y.id);
    return normalize(result);
  }
  async function plan(project,source,{sourceQuery,targetQuery,sourceSchema,targetSchema,version:sourceVersion,commonSource}={}){
    if(!project||(project.tables?.cards?.length!==1&&project.format!=='dokkan-animation-gallery'))throw Error('Open a unit before importing this animation.');
    const markers=[source?.sourceDatabase,source?.catalog?.sourceDatabase].filter(v=>v!=null&&v!=='');if(!markers.length||markers.some(v=>v!=='sparking'))throw Error('This import planner accepts only original Sparking animation sources.');
    const text=source.text,declaredSHA=source.sha256,nativeVersion=version(sourceVersion),owned=(project.tables.effect_packs||[]).map((_,i)=>Number(project.targetId)+i);
    if(project.source?.database==='sparking'&&project.provenance?.sourceVersion!==nativeVersion)throw Error('This Sparking unit and clip use different or unrecorded content versions. Use matching source data before importing this clip.');
    const priorAnimations=project.sourceDependencies?.animations||[];
    if(!Array.isArray(priorAnimations)||priorAnimations.length>MAX_ANIMATIONS)throw Error('The unit has invalid imported animation provenance.');
    if(priorAnimations.some(a=>!a||a.version!==nativeVersion))throw Error('This unit already contains clips from a different Sparking content version. Use matching source data before importing another clip.');
    if(typeof text!=='string'||text.length>2*1024*1024)throw Error('Choose a complete original Lua animation up to2MiB.');
    const sourcePath=path(source.path||source.catalog?.path,true),sourceSHA=await digest(new TextEncoder().encode(text));
    if(declaredSHA!=null&&(typeof declaredSHA!=='string'||!/^([a-fA-F0-9]{64})$/.test(declaredSHA)||declaredSHA.toLowerCase()!==sourceSHA))throw Error('The Sparking animation text differs from its original fingerprint. Reload its source before importing.');
    const inventory=Inventory.inventory(text);
    let helper=null;
    if(commonSource&&Helpers){
      helper=await Helpers.inventory(text,{commonText:commonSource.text,commonSHA256:commonSource.sha256});
      if(helper.verifiedCommonSHA256&&helper.complete){const resolved=new Set(helper.helperUses.map(use=>[use.command,use.line,use.column].join(':')));inventory.unresolved=inventory.unresolved.filter(item=>!resolved.has([item.command,item.line,item.column].join(':')));}
      inventory.unresolved.push(...helper.unresolved);
    }
    const effectIds=ids(inventory.effectIds.concat(helper?.effectIds||[]));
    if(inventory.unresolved.some(i=>i.command==='parse'||i.command==='inventory'))throw Error('The original Lua cannot be inventoried safely. Choose a valid, smaller source animation.');
    if(effectIds.some(id=>owned.includes(id)))throw Error('This Sparking effect ID conflicts with an effect or edited movie owned by this unit. Reserve a different unit slot before importing.');
    const bundle=await Dependencies.collect({tables:{cards:[{id:1}]}},{sourceQuery,targetQuery,sourceSchema,targetSchema,effectIds});
    const errors=bundle.issues.filter(i=>i.severity==='error');if(errors.length){const error=Error(errors[0].message);error.issues=clone(bundle.issues);throw error;}
    bundle.effectIds=effectIds;bundle.animations=[{sourceDatabase:'sparking',path:sourcePath,sha256:sourceSHA,version:nativeVersion,effectIds,unresolved:clone(inventory.unresolved)}];
    for(const item of inventory.unresolved)bundle.issues.push({severity:'warning',code:'SCRIPT_EFFECT_UNRESOLVED',sourcePath,line:item.line,column:item.column,message:item.command+': '+item.reason});
    bundle.issues.push({severity:'warning',code:'SCRIPT_AUDIO_UNSCANNED',sourcePath,message:'This effect inventory does not verify every sound cue, voice bank, helper-generated resource or embedded animation dependency. Import matching resources and test the finished move in Eclipse.'});
    return normalize(bundle);
  }
  return {plan,merge};
});
