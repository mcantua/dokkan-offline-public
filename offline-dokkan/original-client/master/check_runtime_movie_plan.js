'use strict';
// One synthetic authored-movie scenario through the real Forms/Movie models.
// USM bytes are opaque synthetic fixture data; this is not decoder/native proof.
const assert=require('node:assert/strict'),crypto=require('node:crypto'),fs=require('node:fs'),path=require('node:path');
const Forge=require('../../../unit-creator/v2/ui/core.js'),Movies=require('../../../unit-creator/v2/ui/movie-model.js'),Planner=require('./runtime_movie_plan.js');
const hash=value=>crypto.createHash('sha256').update(value).digest('hex'),digest='ab'.repeat(32),scope='cd'.repeat(32),content='sha256:'+digest,stamp=1700000000000;
const columns=values=>Object.entries(values).map(([name,value])=>({name,type:typeof value==='string'?'TEXT':'INTEGER',notnull:0,dflt_value:null,pk:name==='id'?1:0}));
const card={id:1,name:'Movie fixture',rarity:4,element:10,lv_max:120,skill_lv_max:10,hp_init:100,hp_max:1000,atk_init:100,atk_max:1000,def_init:100,def_max:1000,resource_id:10,leader_skill_set_id:0,passive_skill_set_id:0};
const effect={id:1,category:5,name:'Movie',pack_name:'movie',scene_name:'ef_001',red:255,green:255,blue:255,alpha:255,lite_flicker_rate:70,created_at:'',updated_at:''};
const schema={cards:columns(card),effect_packs:columns(effect)};
const project={format:'dokkan-unit-forge',version:1,key:'movie-fixture',source:{cardId:1,database:'sparking',contentId:content},targetId:97010001,patch:{uuid:'movie-fixture',name:'Movie fixture',version:'1.0.0'},tables:{cards:[card]},schema:{cards:schema.cards},cardOverrides:{},assets:[]};
const movieBytes=Buffer.alloc(1536,42),movieSHA=hash(movieBytes);
Movies.apply(project,Movies.plan(project,{schema,assetKey:'media/owned-movie.usm',size:movieBytes.length,metadata:{width:640,height:360,frames:120,rate:{n:30,d:1},preservedAudio:true},storageTag:'11'.repeat(16),name:'Owned movie'}));
function fixedRows(p){const RealDate=Date;globalThis.Date=class extends RealDate{constructor(...args){super(...(args.length?args:[stamp]));}static now(){return stamp;}};try{return Forge.materializeAll(p);}finally{globalThis.Date=RealDate;}}
function inputFor(p){
  const projectSHA=hash(JSON.stringify(p)),movie=Movies.inspect(p)[0],resources=movie?[{kind:'captured-asset',path:movie.path,size:movieBytes.length,sha256:movieSHA}]:[];
  const bundle={format:'od-native-creator-full-bundle-v2',engine_admission:'pending-master-cipher-resource-and-form-progression-binding',content_id:content,save_scope:scope,profile_id:'local-player',definition_id:'movie-fixture',version:1,project_sha256:projectSHA,source_sha256:digest,member_count:1,materialization_utc:stamp,members:[{key:p.key,source:p.source,runtime_card_id:p.targetId}],tables:fixedRows(p),transform_links:[],resources,source_dependencies:[],shared_actions:[]};
  const bundleSHA=hash(JSON.stringify(bundle)),descriptor={format:'od-full-creator-binding-v2',projection:'progression-root-v1',content_id:content,save_scope:scope,profile_id:'local-player',definition_id:'movie-fixture',version:1,project_sha256:projectSHA,full_bundle_sha256:bundleSHA,member_count:1};
  const definition={format:'offline-dokkan-definition',schema_version:1,definition_id:'movie-fixture',version:1,fully_awakened:true,source:{content_id:content,master_id:1},full_bundle:descriptor},definitionSHA=hash(JSON.stringify(definition));
  const accepted={format:'od-accepted-creator-project-v1',content_id:content,save_scope:scope,definition_id:'movie-fixture',version:1,instance_id:1,project_sha256:projectSHA,definition_sha256:definitionSHA,accepted:true};
  const receipt={format:'od-accepted-full-bundle-receipt-v1',content_id:content,save_scope:scope,profile_id:'local-player',definition_id:'movie-fixture',version:1,instance_id:1,profile_revision:1,projection_generation:1,project_sha256:projectSHA,definition_sha256:definitionSHA,full_bundle_sha256:bundleSHA,member_count:1};
  return {project:p,fullBundle:bundle,definition,acceptedBinding:accepted,fullBundleReceipt:receipt,nativeByteHashesVerified:true,nativeByteHashes:{project:projectSHA,definition:definitionSHA,fullBundle:bundleSHA}};
}
function hostFor(input){return {schema,reservations:[],contextIsCurrent:()=>true,query:async()=>[],listAssets:async()=>[],sha256Text:async text=>hash(text),attestAcceptedResource:async path=>({path,sha256:movieSHA,size:movieBytes.length,content_id:content,save_scope:scope,project_sha256:input.nativeByteHashes.project,full_bundle_sha256:input.nativeByteHashes.fullBundle})};}
(async()=>{
  const before=JSON.stringify(project),old=Movies.inspect(project)[0],input=inputFor(project),plan=await Planner.planAcceptedMovies(input,hostFor(input));
  assert.equal(JSON.stringify(project),before);assert.equal(plan.resources.length,1);assert.equal(plan.resources[0].accepted_path,old.path);assert.notEqual(plan.resources[0].runtime_path,old.path);
  assert.equal(plan.resources[0].sha256,movieSHA);assert.equal(plan.resources[0].size,movieBytes.length);assert.equal(plan.resources[0].preserve_bytes,true);assert.equal('assetKey' in plan.resources[0],false);
  const movie=plan.movie_bindings[0],row=plan.tables.effect_packs.find(row=>row.id===movie.runtime_effect_pack_id);
  assert.equal(row.pack_name,movie.pack_name);assert.equal(movie.path,plan.resources[0].runtime_path);assert.equal(movie.private_unit_id,plan.runtimeIds[0]);assert.equal(plan.tables.cards.length,2);
  assert.equal(plan.plan_sha256,hash(plan.plan_json));assert.equal(plan.original_client_attached,false);assert.equal(plan.resource_publication_admitted,false);assert.equal(plan.runtime_allocation_admitted,false);
  const badHost=hostFor(input),attest=badHost.attestAcceptedResource;badHost.attestAcceptedResource=async path=>({...await attest(path),sha256:'00'.repeat(32)});
  await assert.rejects(Planner.planAcceptedMovies(input,badHost),/RUNTIME_MOVIE_PLAN_CAPTURE_MISMATCH/);
  const unsupported=structuredClone(project);unsupported.battlePoseBinding={};const unsupportedInput=inputFor(unsupported);
  await assert.rejects(Planner.planAcceptedMovies(unsupportedInput,hostFor(unsupportedInput)),/RUNTIME_MOVIE_PLAN_UNSUPPORTED_RESOURCE_BRANCH/);
  const staleHost=hostFor(input);staleHost.contextIsCurrent=()=>false;
  await assert.rejects(Planner.planAcceptedMovies(input,staleHost),/RUNTIME_MOVIE_PLAN_CONTEXT_CHANGED/);
  const evidence={kind:'one-focused-authored-movie-runtime-candidate',fixture:'synthetic card/schema/USM-descriptor data; actual MovieModel.plan/apply and Forms.reserve->UnitRebase->MovieModel.rebase; native callbacks simulated',checks:{accepted_project_unchanged:true,actual_movie_pack_and_destination_rebased:true,declared_immutable_bytes_hash_size_preserved:true,materialized_effect_pack_binds_destination:true,native_root_rows_retained:true,no_asset_key_or_fd_authority_in_resource_map:true,changed_capture_rejected:true,other_resource_branch_rejected:true,stale_context_rejected:true,publication_allocation_engine_gates_stay_closed:true},targeted_invocations:1,native_resource_fd_or_transaction_verified:false,usm_decode_verified:false,app_build_or_original_game_execution:false};
  fs.writeFileSync(path.join(__dirname,'runtime-movie-plan-evidence.json'),JSON.stringify(evidence,null,2)+'\n');
  console.log('Authored movie candidate boundary passed: actual model rebase, immutable hash/size preservation, changed capture/unsupported branch/stale context rejection. Native publication remains closed.');
})().catch(error=>{console.error(error.message);process.exitCode=1;});
