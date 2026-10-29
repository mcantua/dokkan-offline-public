/* Trusted native/cloud compiler. The real Creator performs materialization. */
(function(root,factory) {
  if (typeof module === 'object' && module.exports) {
    const api=factory(require('../../../unit-creator/v2/ui/core.js'));
    module.exports=api;
    if (require.main === module) {
      try { process.stdout.write(JSON.stringify(api.compile(JSON.parse(require('fs').readFileSync(0,'utf8'))))); }
      catch (_) { process.stderr.write('RUNTIME_FORGE_REJECTED\n'); process.exitCode=1; }
    }
  } else root.ODRuntimeForge=factory(root.Forge);
})(typeof globalThis!=='undefined'?globalThis:this,function(Forge) {
  'use strict';
  function compile(input) {
try {
  const project = Forge.clone(input.project);
  const members = [project, ...(project.formProjects || [])];
  if (members.length !== input.runtimeIds.length) throw Error('RUNTIME_MEMBER_COUNT');
  const changed = new Map(members.map((p, i) => [Number(p.targetId), input.runtimeIds[i]]));
  // Current strict Finish admits a single card. Multi-form admission must supply
  // an accepted immutable full bundle before this compiler can accept forms.
  if (members.length !== 1) throw Error('RUNTIME_FULL_BUNDLE_ADMISSION_REQUIRED');
  if ((project.movieBindings || []).length || (project.assets || []).length ||
      (project.generatedFiles || []).length || (project.packedAssets || []).length || project.sourceDependencies ||
      Object.keys(project.animationAssignments || {}).length || project.actionHooks)
    throw Error('RUNTIME_RESOURCE_ADMISSION_REQUIRED');
  for (const member of members) member.targetId = changed.get(Number(member.targetId));
  const check = Forge.validate(project);
  if (check.errors.length) throw Error('RUNTIME_FORGE_VALIDATION_FAILED');
  const tables = Forge.materializeAll(project);
  const next = Forge.nextUnitId(input.reservations, 'runtime-next', input.floor);
  return {tables, runtimeIds: input.runtimeIds,
    next, foreign: Forge.foreign, warnings: check.warnings.length};
} catch (_) { throw Error('RUNTIME_FORGE_REJECTED'); }
  }
  const fullCodes=new Set(['RUNTIME_FULL_BUNDLE_ARGUMENT_INVALID','RUNTIME_FULL_BUNDLE_ACCEPTED_BYTES_REQUIRED',
    'RUNTIME_FULL_BUNDLE_BINDING_MISMATCH','RUNTIME_FULL_BUNDLE_FORGE_VALIDATION_FAILED',
    'RUNTIME_FULL_BUNDLE_MATERIALIZATION_CHANGED','RUNTIME_FULL_BUNDLE_RESOURCE_ADMISSION_REQUIRED',
    'RUNTIME_FULL_BUNDLE_REBASE_OVERLAP_UNSUPPORTED','RUNTIME_FULL_BUNDLE_REFERENCE_REWRITE_REQUIRED','RUNTIME_FULL_BUNDLE_AUTHORED_SLOT_UNSUPPORTED']);
  const record=value=>value!==null&&typeof value==='object'&&!Array.isArray(value);
  const hex=value=>typeof value==='string'&&/^[a-f0-9]{64}$/.test(value);
  const canonical=value=>Array.isArray(value)?'['+value.map(canonical).join(',')+']':record(value)?
    '{'+Object.keys(value).sort().map(key=>JSON.stringify(key)+':'+canonical(value[key])).join(',')+'}':JSON.stringify(value);
  function fullFail(code){throw Error(code);}
  function memberList(project){
    if(!record(project)||project.formProjects!==undefined&&!Array.isArray(project.formProjects))fullFail('RUNTIME_FULL_BUNDLE_ARGUMENT_INVALID');
    const members=[project,...project.formProjects||[]];
    if(members.length<1||members.length>5||members.some(member=>!record(member)))fullFail('RUNTIME_FULL_BUNDLE_ARGUMENT_INVALID');
    return members;
  }
  function atMaterializationTime(stamp,fn){
    const RealDate=Date;
    globalThis.Date=class extends RealDate{constructor(...args){super(...(args.length?args:[stamp]));}static now(){return stamp;}};
    try{return fn();}finally{globalThis.Date=RealDate;}
  }
  function noResourceRebase(members,bundle){
    if(!Array.isArray(bundle.resources)||bundle.resources.length||!Array.isArray(bundle.source_dependencies)||bundle.source_dependencies.length||
       !Array.isArray(bundle.shared_actions)||bundle.shared_actions.length)fullFail('RUNTIME_FULL_BUNDLE_RESOURCE_ADMISSION_REQUIRED');
    for(const member of members){
      if((member.assets||[]).length||(member.generatedFiles||[]).length||(member.packedAssets||[]).length||
         (member.movieBindings||[]).length||member.sourceDependencies||member.actionHooks||member.artBinding||member.battlePoseBinding||
         Object.keys(member.animationAssignments||{}).length||Object.keys(member.abilityAnimationOverrides||{}).length)
        fullFail('RUNTIME_FULL_BUNDLE_RESOURCE_ADMISSION_REQUIRED');
      if(member.awaken!==undefined&&member.awaken!==null&&(!['number','boolean'].includes(typeof member.awaken)||Boolean(member.awaken)))
        fullFail('RUNTIME_FULL_BUNDLE_ARGUMENT_INVALID');
    }
  }
  function transformationTarget(row,table){
    // Same decoded target contract as ForgeForms.target/reserve. Only the
    // established efficacy103 target position is changed; other values stay.
    let values;try{const parsed=JSON.parse(row.efficacy_values||'{}');if(Array.isArray(parsed))values=parsed;}catch(_){ }
    const field=table==='passive_skills'?'eff_value1':'eff_val1';
    return {field,values,targetId:Number(values?values[0]:row[field])};
  }
  function rebaseForms(project,ids){
    const members=memberList(project),moved=new Map(members.map((member,index)=>[member.targetId,ids[index]]));
    for(let index=0;index<members.length;index++)members[index].targetId=ids[index];
    for(const member of members)for(const table of ['passive_skills','active_skills','standby_skills','finish_skills'])
      for(const row of member.tables?.[table]||[]){
        if(Number(row.efficacy_type)!==103)continue;
        const target=transformationTarget(row,table);
        if(!moved.has(target.targetId))continue;
        row[target.field]=moved.get(target.targetId);
        if(target.values){target.values[0]=moved.get(target.targetId);row.efficacy_values=JSON.stringify(target.values);}
      }
    for(const link of project.transformLinks||[]){
      const child=members.slice(1).find(member=>member.key===link.targetKey),row=(project.tables?.[link.table]||[]).find(item=>item.id===link.row);
      if(!child||!row||Number(row.efficacy_type)!==103)fullFail('RUNTIME_FULL_BUNDLE_REFERENCE_REWRITE_REQUIRED');
      const target=transformationTarget(row,link.table);
      row[target.field]=child.targetId;
      if(target.values){target.values[0]=child.targetId;row.efficacy_values=JSON.stringify(target.values);}
      link.targetId=child.targetId;
    }
    return project;
  }
  function assertNoUnmappedPrivateIdentities(before,after){
    const moved=new Set();
    if(canonical(Object.keys(before).sort())!==canonical(Object.keys(after).sort()))fullFail('RUNTIME_FULL_BUNDLE_MATERIALIZATION_CHANGED');
    for(const [table,rows] of Object.entries(before)){
      if(!Array.isArray(rows)||!Array.isArray(after[table])||rows.length!==after[table].length)fullFail('RUNTIME_FULL_BUNDLE_MATERIALIZATION_CHANGED');
      for(let index=0;index<rows.length;index++)if(rows[index].id!==after[table][index].id)moved.add(rows[index].id);
    }
    // Unsupported encoded/private-reference rewrites reject rather than
    // treating an arbitrary numeric field as an understood ability operand.
    function inspect(value,depth){
      if(depth>32)fullFail('RUNTIME_FULL_BUNDLE_REFERENCE_REWRITE_REQUIRED');
      if(typeof value==='number'){if(moved.has(value))fullFail('RUNTIME_FULL_BUNDLE_REFERENCE_REWRITE_REQUIRED');return;}
      if(typeof value==='string'){
        for(const token of value.match(/-?\d+/g)||[])if(moved.has(Number(token)))fullFail('RUNTIME_FULL_BUNDLE_REFERENCE_REWRITE_REQUIRED');
        return;
      }
      if(Array.isArray(value)){for(const item of value)inspect(item,depth+1);return;}
      if(record(value))for(const item of Object.values(value))inspect(item,depth+1);
    }
    const displayFields=new Set(['name','description','itemized_description','short_description','created_at','updated_at']);
    for(const rows of Object.values(after))for(const row of rows)for(const [field,value] of Object.entries(row))if(!displayFields.has(field))inspect(value,0);
  }
  function materializeAcceptedFullBundle(input){
    try{
      if(!record(input)||input.nativeByteHashesVerified!==true||!record(input.nativeByteHashes))fullFail('RUNTIME_FULL_BUNDLE_ACCEPTED_BYTES_REQUIRED');
      const project=Forge.clone(input.project),bundle=input.fullBundle,definition=input.definition,binding=input.acceptedBinding,hashes=input.nativeByteHashes;
      const members=memberList(project),ids=input.runtimeIds;
      if(!record(bundle)||!record(definition)||!record(binding)||!record(definition.full_bundle)||!Array.isArray(ids)||ids.length!==members.length||
         !Array.isArray(input.reservations)||input.reservations.length>2000||!Number.isSafeInteger(input.floor)||
         input.floor<97000001||input.floor>98999001||input.floor%1000!==1||
         ids.some((id,index)=>!Number.isSafeInteger(id)||id!==input.floor+1000*index||id<97000001||id>98999001))
        fullFail('RUNTIME_FULL_BUNDLE_ARGUMENT_INVALID');
      const descriptor=definition.full_bundle;
      if(bundle.format!=='od-native-creator-full-bundle-v2'||descriptor.format!=='od-full-creator-binding-v2'||descriptor.projection!=='progression-root-v1'||
         binding.format!=='od-accepted-creator-project-v1'||binding.accepted!==true||bundle.profile_id!=='local-player'||descriptor.profile_id!==bundle.profile_id||
         !hex(hashes.project)||!hex(hashes.definition)||!hex(hashes.fullBundle)||hashes.project!==binding.project_sha256||hashes.definition!==binding.definition_sha256||
         hashes.project!==bundle.project_sha256||hashes.project!==descriptor.project_sha256||hashes.fullBundle!==descriptor.full_bundle_sha256||
         bundle.member_count!==members.length||descriptor.member_count!==members.length||!Array.isArray(bundle.members)||bundle.members.length!==members.length||
         !Number.isSafeInteger(bundle.materialization_utc)||bundle.materialization_utc<0||bundle.materialization_utc>253402300799000)
        fullFail('RUNTIME_FULL_BUNDLE_BINDING_MISMATCH');
      for(const field of ['content_id','save_scope','definition_id','version'])if(bundle[field]!==binding[field]||descriptor[field]!==binding[field])fullFail('RUNTIME_FULL_BUNDLE_BINDING_MISMATCH');
      if(definition.format!=='offline-dokkan-definition'||definition.schema_version!==1||definition.fully_awakened!==true||
         definition.source?.master_id!==members[0].source?.cardId||canonical(bundle.transform_links)!==canonical(project.transformLinks||[])||
         definition.definition_id!==binding.definition_id||definition.version!==binding.version||definition.source?.content_id!==binding.content_id||
         !Number.isSafeInteger(binding.version)||binding.version<1||!Number.isSafeInteger(binding.instance_id)||binding.instance_id<1||!hex(binding.save_scope)||
         typeof binding.content_id!=='string'||!/^(?:(?:eclipse|sparking):)?sha256:[a-f0-9]{64}$/.test(binding.content_id)||bundle.source_sha256!==binding.content_id.split(':').slice(-1)[0])fullFail('RUNTIME_FULL_BUNDLE_BINDING_MISMATCH');
      for(let index=0;index<members.length;index++){
        const member=members[index],accepted=bundle.members[index];
        if(!record(accepted)||accepted.key!==member.key||accepted.runtime_card_id!==member.targetId||canonical(accepted.source)!==canonical(member.source)||
           member.source?.contentId!==binding.content_id||!Number.isSafeInteger(member.targetId)||member.targetId<1)
          fullFail('RUNTIME_FULL_BUNDLE_BINDING_MISMATCH');
        // Actual Forge accepts additional manual/legacy slot shapes. Their
        // native-root row count and cross-namespace rewrites need a separate
        // proven migration; preserve the accepted bytes and reject explicitly.
        if(member.targetId<97000001||member.targetId>98999001||member.targetId%1000!==1)
          fullFail('RUNTIME_FULL_BUNDLE_AUTHORED_SLOT_UNSUPPORTED');
      }
      noResourceRebase(members,bundle);
      const beforeCheck=Forge.validate(project);if(beforeCheck.errors.length)fullFail('RUNTIME_FULL_BUNDLE_FORGE_VALIDATION_FAILED');
      return atMaterializationTime(bundle.materialization_utc,()=>{
        const beforeTables=Forge.materializeAll(project);
        if(canonical(beforeTables)!==canonical(bundle.tables))fullFail('RUNTIME_FULL_BUNDLE_MATERIALIZATION_CHANGED');
        const identity=members.every((member,index)=>member.targetId===ids[index]);
        if(!identity&&members.some(member=>ids.some(id=>id<=member.targetId+999&&id+999>=member.targetId)))fullFail('RUNTIME_FULL_BUNDLE_REBASE_OVERLAP_UNSUPPORTED');
        const acceptedMembers=members.map(member=>({key:member.key,source_card_id:member.source.cardId,accepted_runtime_card_id:member.targetId}));
        rebaseForms(project,ids);
        const check=Forge.validate(project);if(check.errors.length)fullFail('RUNTIME_FULL_BUNDLE_FORGE_VALIDATION_FAILED');
        const tables=Forge.materializeAll(project);
        assertNoUnmappedPrivateIdentities(beforeTables,tables);
        const rootIds=ids.map(id=>Math.floor(id/10)*10),cardIds=new Set((tables.cards||[]).map(card=>card.id));
        if(cardIds.size!==ids.length*2||tables.cards.length!==ids.length*2||[...ids,...rootIds].some(id=>!cardIds.has(id)))fullFail('RUNTIME_FULL_BUNDLE_MATERIALIZATION_CHANGED');
        return {tables,runtimeIds:ids,next:Forge.nextUnitId(input.reservations,'runtime-next',input.floor),foreign:Forge.foreign,warnings:check.warnings.length,
          members:acceptedMembers.map((member,index)=>({...member,runtime_card_id:ids[index]})),native_root_card_ids:rootIds,
          full_bundle_sha256:hashes.fullBundle,complete_member_materialization:true,encoded_references_complete:true,
          encoded_reference_scope:'private-owned-row-identities-only-v1',source_reference_validation_required:true,
          resource_admission_complete:false,original_client_attached:false,gameplay_ready:false};
      });
    }catch(error){throw Error(fullCodes.has(error?.message)?error.message:'RUNTIME_FULL_BUNDLE_REJECTED');}
  }
  return Object.freeze({compile,materializeAcceptedFullBundle});
});
