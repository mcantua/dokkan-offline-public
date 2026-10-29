'use strict';
const assert=require('node:assert/strict'),crypto=require('node:crypto'),fs=require('node:fs'),path=require('node:path');
const root=path.resolve(__dirname,'../../..'),Forge=require(path.join(root,'unit-creator/v2/ui/core.js')),Bundle=require(path.join(root,'offline-dokkan/original-client/creator-bundle/full_bundle.js'));
const hash=x=>crypto.createHash('sha256').update(x).digest('hex'),digest='ab'.repeat(32),scope='cd'.repeat(32),content='sha256:'+digest;
const card={id:1,name:'Capture boundary',rarity:4,element:10,lv_max:120,skill_lv_max:10,hp_init:100,hp_max:1000,atk_init:100,atk_max:1000,def_init:100,def_max:1000,resource_id:10,leader_skill_set_id:0,passive_skill_set_id:0};
const columns=Object.entries(card).map(([name,value])=>({name,type:typeof value==='string'?'TEXT':'INTEGER',notnull:0,dflt_value:null,pk:name==='id'?1:0}));
const schema={cards:columns,card_awakening_routes:[]};
const project={format:'dokkan-unit-forge',version:1,key:'resource-boundary',source:{cardId:1,database:'sparking',contentId:content},targetId:11000001,patch:{uuid:'resource-boundary',name:'Capture boundary',version:'1.0.0'},tables:{cards:[card]},schema,cardOverrides:{},assets:[{path:'lua/test-helper.sql',key:'media/test-helper.lua'}],awaken:false};
const assetBytes=Buffer.from('-- retained as bytes; never executed\n');
async function query(q){if(q.table==='cards')return q.ids?(q.ids.includes(1)?[card]:[]):q.filters?.id===1?[card]:[];return [];}
const host={contentId:content,sourceSHA256:digest,sourceHashVerified:true,saveScope:scope,projectSHA256:hash(JSON.stringify(project)),definitionId:'resource-boundary',version:1,sourceDatabase:'sparking',schema,query,projects:[],sha256Text:async text=>hash(text),describeAsset:async key=>{assert.equal(key,'media/test-helper.lua');return {verified:true,sha256:hash(assetBytes),size:assetBytes.length,save_scope:scope,content_id:content};},listAssets:async()=>[]};
(async()=>{
  if(process.argv.includes('--shared-only')){
    const destination='lua/ab_script/attack_sp/sp0001.lua';
    const shared=structuredClone(project);shared.assets=[{path:destination,key:'media/test-helper.lua'}];
    shared.sourceDependencies={tables:{},schema:{},issues:[],assetPaths:[destination],animations:[{sourceDatabase:'sparking',path:'ab_script/attack_sp/sp0001.lua',sha256:hash(assetBytes),version:1,effectIds:[],unresolved:[]}]};
    const candidate=await Bundle.stage(shared,{...host,projectSHA256:hash(JSON.stringify(shared))});
    assert.equal(candidate.resources.entries[0].sha256,shared.sourceDependencies.animations[0].sha256);
    const forged=structuredClone(shared);forged.sourceDependencies.animations[0].sha256='00'.repeat(32);
    await assert.rejects(Bundle.stage(forged,host),e=>e.code==='FULL_BUNDLE_SHARED_ANIMATION_HASH_MISMATCH');
    const absent=structuredClone(shared);absent.assets=[];
    await assert.rejects(Bundle.stage(absent,host),e=>e.code==='FULL_BUNDLE_SHARED_RESOURCE_CAPTURE_REQUIRED');
    assert.equal(candidate.gameplay_ready,false);
    const evidence={kind:'one-focused-authored-shared-animation-capture-boundary',fixture:'existing synthetic Forge/Forms fixture; exact importer path mapping and native-scoped asset descriptor',checks:{matching_captured_script_accepted:true,forged_declared_script_hash_rejected:true,uncaptured_declared_asset_rejected:true,original_engine_admission_stays_false:true},targeted_invocations:1,native_compilation_or_runtime_verified:false,source_master_or_gameplay_verified:false,original_game_executed:false,personal_connection_used:false};
    fs.writeFileSync(path.join(root,'offline-dokkan/original-client/creator-bundle/shared-resource-binding-evidence.json'),JSON.stringify(evidence,null,2)+'\n');
    console.log('Shared-animation capture boundary passed: matched captured bytes; forged hash and missing capture rejected. Native code uncompiled.');
    return;
  }
  const before=JSON.stringify(project),candidate=await Bundle.stage(project,host),entries=candidate.resources.entries;
  assert.equal(entries.length,1);assert.equal(entries[0].path,'lua/test-helper.sql');assert.equal(entries[0].kind,'asset');assert.equal(entries[0].sha256,hash(assetBytes));
  assert.equal(candidate.resources.compatibilityExports.length,3);assert(candidate.resources.compatibilityExports.some(e=>e.path==='files/'+Forge.filename(candidate.project)+'.sql'));
  assert.equal(JSON.stringify(project),before);assert.equal(candidate.gameplay_ready,false);assert.equal(candidate.original_client_attached,false);
  const child=structuredClone(project);child.key='child';child.targetId+=1000;child.awaken={cardId:1};
  await assert.rejects(Bundle.stage({...project,formProjects:[child]},host),e=>e.code==='FULL_BUNDLE_PROJECT_INVALID');
  const evidence={kind:'one-focused-authored-full-bundle-resource-boundary',fixture:'synthetic card/schema and scoped attachment bytes; actual Forge and Forms stage path',checks:{safe_sql_suffix_attachment_retained:true,only_three_canonical_compatibility_exports_skipped:true,false_awakening_not_rejected:true,awakening_form_rejected_before_materialization:true,input_project_unchanged:true,gameplay_admission_stays_false:true},native_compilation_or_runtime_verified:false,source_master_or_gameplay_verified:false,original_game_executed:false,personal_connection_used:false};
  fs.writeFileSync(path.join(root,'offline-dokkan/original-client/creator-bundle/resource-capture-evidence.json'),JSON.stringify(evidence,null,2)+'\n');
  console.log('Full-bundle resource boundary passed: safe SQL-suffix attachment retained; canonical SQL remains compatibility-only; awakening form rejected. Native code uncompiled.');
})().catch(e=>{console.error(e.code||e.message);process.exitCode=1;});
