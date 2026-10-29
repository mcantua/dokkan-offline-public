'use strict';
// One synthetic immutable full-packet scenario; actual Forge materialization.
// This does not execute native code, a database writer or the original game.
const assert=require('node:assert/strict'),crypto=require('node:crypto'),fs=require('node:fs'),path=require('node:path');
const Forge=require('../../../unit-creator/v2/ui/core.js'),Runtime=require('./runtime_forge.js');
const hash=value=>crypto.createHash('sha256').update(value).digest('hex'),sourceHash='ab'.repeat(32),scope='cd'.repeat(32),content='sha256:'+sourceHash,stamp=1700000000000;
const schema=values=>Object.entries(values).map(([name,value])=>({name,type:typeof value==='string'?'TEXT':'INTEGER',notnull:0,dflt_value:null,pk:name==='id'?1:0}));
function member(key,sourceId,targetId,targetSource){
  const card={id:sourceId,name:key,rarity:4,element:10,lv_max:120,skill_lv_max:10,hp_init:100,hp_max:1000,atk_init:100,atk_max:1000,def_init:100,def_max:1000,resource_id:sourceId*10,leader_skill_set_id:0,passive_skill_set_id:0};
  const passive={id:-sourceId,efficacy_type:103,eff_value1:targetSource,eff_value2:0,eff_value3:0,efficacy_values:JSON.stringify([targetSource,0,0]),probability:100};
  return {format:'dokkan-unit-forge',version:1,key,source:{cardId:sourceId,database:'sparking',contentId:content},targetId,patch:{uuid:key,name:key,version:'1.0.0'},tables:{cards:[card],passive_skills:[passive]},schema:{cards:schema(card),passive_skills:schema(passive)},cardOverrides:{},assets:[]};
}
const root=member('synthetic-base',1,97010001,97011001),child=member('synthetic-form',2,97011001,1);
root.awaken=false;child.awaken=null;root.formProjects=[child];root.transformLinks=[{table:'passive_skills',row:-1,targetKey:child.key,targetId:child.targetId}];
function fixedMaterialize(project){const RealDate=Date;globalThis.Date=class extends RealDate{constructor(...args){super(...(args.length?args:[stamp]));}static now(){return stamp;}};try{return Forge.materializeAll(project);}finally{globalThis.Date=RealDate;}}
function packet(project){
  const projectBytes=JSON.stringify(project),projectSHA=hash(projectBytes),members=[project,...project.formProjects||[]];
  const bundle={format:'od-native-creator-full-bundle-v2',content_id:content,profile_id:'local-player',save_scope:scope,definition_id:'synthetic-full',version:1,project_sha256:projectSHA,source_sha256:sourceHash,member_count:members.length,materialization_utc:stamp,resources:[],tables:fixedMaterialize(project),members:members.map(p=>({key:p.key,source:p.source,runtime_card_id:p.targetId})),transform_links:project.transformLinks||[],source_dependencies:[],shared_actions:[]};
  const bundleSHA=hash(JSON.stringify(bundle)),definition={format:'offline-dokkan-definition',schema_version:1,definition_id:'synthetic-full',version:1,source:{content_id:content,master_id:1},fully_awakened:true,full_bundle:{format:'od-full-creator-binding-v2',projection:'progression-root-v1',content_id:content,profile_id:'local-player',save_scope:scope,definition_id:'synthetic-full',version:1,project_sha256:projectSHA,full_bundle_sha256:bundleSHA,member_count:members.length}};
  const definitionSHA=hash(JSON.stringify(definition));
  return {project,fullBundle:bundle,definition,acceptedBinding:{format:'od-accepted-creator-project-v1',content_id:content,save_scope:scope,definition_id:'synthetic-full',version:1,project_sha256:projectSHA,definition_sha256:definitionSHA,instance_id:1,accepted:true},nativeByteHashesVerified:true,nativeByteHashes:{project:projectSHA,definition:definitionSHA,fullBundle:bundleSHA},runtimeIds:[97000001,97001001],reservations:[],floor:97000001};
}
const before=JSON.stringify(root),input=packet(root),result=Runtime.materializeAcceptedFullBundle(input);
assert.equal(JSON.stringify(root),before);assert.deepEqual(result.runtimeIds,[97000001,97001001]);assert.equal(result.next,97000001);
assert.deepEqual(result.native_root_card_ids,[97000000,97001000]);assert.equal(result.tables.cards.length,4);
assert.deepEqual(result.members.map(m=>m.key),[root.key,child.key]);
const baseSkill=result.tables.passive_skills.find(row=>row.id===97000001),formSkill=result.tables.passive_skills.find(row=>row.id===97001001);
assert.equal(baseSkill.eff_value1,97001001);assert.equal(JSON.parse(baseSkill.efficacy_values)[0],97001001);assert.equal(JSON.parse(formSkill.efficacy_values)[0],97000001);
assert.equal(result.complete_member_materialization,true);assert.equal(result.encoded_references_complete,true);assert.equal(result.original_client_attached,false);assert.equal(result.gameplay_ready,false);
const hashMismatch=packet(root);hashMismatch.nativeByteHashes.project='00'.repeat(32);assert.throws(()=>Runtime.materializeAcceptedFullBundle(hashMismatch),/RUNTIME_FULL_BUNDLE_BINDING_MISMATCH/);
const resource=structuredClone(root);resource.assets=[{path:'lua/private.lua',key:'media/private.lua'}];assert.throws(()=>Runtime.materializeAcceptedFullBundle(packet(resource)),/RUNTIME_FULL_BUNDLE_RESOURCE_ADMISSION_REQUIRED/);
const unsupported=structuredClone(root);unsupported.tables.passive_skills[0].efficacy_values=JSON.stringify([97011001,0,0,97010001]);assert.throws(()=>Runtime.materializeAcceptedFullBundle(packet(unsupported)),/RUNTIME_FULL_BUNDLE_REFERENCE_REWRITE_REQUIRED/);
assert.throws(()=>Runtime.compile({project:root,runtimeIds:input.runtimeIds,reservations:[],floor:97000001}),/RUNTIME_FORGE_REJECTED/);
const evidence={kind:'one-focused-authored-accepted-full-runtime-materialization',fixture:'synthetic immutable two-form packet using actual Forge; no source game rows or native byte-hash execution',checks:{root_and_awakened_rows_retained:true,one_instance_member_mapping:true,explicit_and_encoded_transformation_targets_rebased:true,indirect_source_card_return_rebased:true,accepted_project_unchanged:true,hash_binding_mismatch_rejected:true,unproved_resource_rebase_rejected:true,unmapped_encoded_private_id_rejected:true,old_single_project_gate_unchanged:true},native_compilation_or_runtime_verified:false,native_transaction_or_original_game_verified:false,targeted_invocations:1,engine_admission:false};
fs.writeFileSync(path.join(__dirname,'full-runtime-forge-evidence.json'),JSON.stringify(evidence,null,2)+'\n');
console.log('Full runtime Forge boundary passed: two-form targets/encoded references/root rows retained; hash/resource/unmapped-reference gates reject. Native code uncompiled.');
