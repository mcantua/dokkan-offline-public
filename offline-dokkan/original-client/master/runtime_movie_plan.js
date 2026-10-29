/* Native-only asynchronous candidate plan. Does not publish resources or rows. */
(function(root,factory){
  if(typeof module==='object'&&module.exports)module.exports=factory(
    require('../../../unit-creator/v2/ui/core.js'),
    require('../../../unit-creator/v2/ui/forms-model.js'),
    require('../../../unit-creator/v2/ui/movie-model.js'));
  else root.ODRuntimeMoviePlan=factory(root.Forge,root.ForgeForms,root.ForgeMovieModel);
})(typeof globalThis!=='undefined'?globalThis:this,function(Forge,Forms,Movies){
  'use strict';
  const record=value=>value!==null&&typeof value==='object'&&!Array.isArray(value);
  const hex=value=>typeof value==='string'&&/^[a-f0-9]{64}$/.test(value);
  const canonical=value=>Array.isArray(value)?'['+value.map(canonical).join(',')+']':record(value)?
    '{'+Object.keys(value).sort().map(key=>JSON.stringify(key)+':'+canonical(value[key])).join(',')+'}':JSON.stringify(value);
  const codes=new Set(['RUNTIME_MOVIE_PLAN_INPUT_INVALID','RUNTIME_MOVIE_PLAN_NATIVE_CONTEXT_REQUIRED',
    'RUNTIME_MOVIE_PLAN_BINDING_MISMATCH','RUNTIME_MOVIE_PLAN_UNSUPPORTED_RESOURCE_BRANCH',
    'RUNTIME_MOVIE_PLAN_ACCEPTED_MATERIALIZATION_CHANGED','RUNTIME_MOVIE_PLAN_FORGE_REJECTED',
    'RUNTIME_MOVIE_PLAN_CAPTURE_MISSING','RUNTIME_MOVIE_PLAN_CAPTURE_MISMATCH','RUNTIME_MOVIE_PLAN_CONTEXT_CHANGED',
    'RUNTIME_MOVIE_PLAN_RESOURCE_BINDING_CHANGED','RUNTIME_MOVIE_PLAN_INPUT_CHANGED']);
  const fail=code=>{throw Error(code);};
  function members(project){
    if(!record(project)||project.formProjects!==undefined&&!Array.isArray(project.formProjects))fail('RUNTIME_MOVIE_PLAN_INPUT_INVALID');
    const list=[project,...project.formProjects||[]];
    if(list.length<1||list.length>5||list.some(member=>!record(member)))fail('RUNTIME_MOVIE_PLAN_INPUT_INVALID');
    return list;
  }
  function fixedMaterialize(project,stamp){
    // Only synchronous materialization changes Date. No global state is held
    // across Forms.reserve's asynchronous native queries/attestations.
    const RealDate=Date;
    globalThis.Date=class extends RealDate{constructor(...args){super(...(args.length?args:[stamp]));}static now(){return stamp;}};
    try{return Forge.materializeAll(project);}finally{globalThis.Date=RealDate;}
  }
  function checkedInput(input){
    if(!record(input)||input.nativeByteHashesVerified!==true||!record(input.nativeByteHashes))fail('RUNTIME_MOVIE_PLAN_NATIVE_CONTEXT_REQUIRED');
    const pinned=Forge.clone(input),p=pinned.project,b=pinned.fullBundle,d=pinned.definition,a=pinned.acceptedBinding,r=pinned.fullBundleReceipt,h=pinned.nativeByteHashes;
    if(!record(b)||!record(d)||!record(a)||!record(d.full_bundle)||!record(r))fail('RUNTIME_MOVIE_PLAN_INPUT_INVALID');
    const group=members(p),descriptor=d.full_bundle;
    if(a.format!=='od-accepted-creator-project-v1'||a.accepted!==true||!Number.isSafeInteger(a.instance_id)||a.instance_id<1||
       b.format!=='od-native-creator-full-bundle-v2'||b.engine_admission!=='pending-master-cipher-resource-and-form-progression-binding'||
       d.format!=='offline-dokkan-definition'||d.schema_version!==1||d.fully_awakened!==true||
       descriptor.format!=='od-full-creator-binding-v2'||descriptor.projection!=='progression-root-v1'||
       r.format!=='od-accepted-full-bundle-receipt-v1'||r.instance_id!==a.instance_id||
       !Number.isSafeInteger(r.profile_revision)||r.profile_revision<0||!Number.isSafeInteger(r.projection_generation)||r.projection_generation<1||
       !hex(h.project)||!hex(h.definition)||!hex(h.fullBundle)||h.project!==a.project_sha256||h.project!==descriptor.project_sha256||h.project!==b.project_sha256||h.project!==r.project_sha256||
       h.definition!==a.definition_sha256||h.definition!==r.definition_sha256||h.fullBundle!==descriptor.full_bundle_sha256||h.fullBundle!==r.full_bundle_sha256||
       b.profile_id!=='local-player'||descriptor.profile_id!==b.profile_id||r.profile_id!==b.profile_id||
       b.member_count!==group.length||descriptor.member_count!==group.length||r.member_count!==group.length||
       !Array.isArray(b.members)||b.members.length!==group.length||!record(b.tables)||
       !Number.isSafeInteger(b.materialization_utc)||b.materialization_utc<0||b.materialization_utc>253402300799000)
      fail('RUNTIME_MOVIE_PLAN_BINDING_MISMATCH');
    for(const field of ['content_id','save_scope','definition_id','version'])if(b[field]!==a[field]||descriptor[field]!==a[field]||r[field]!==a[field])fail('RUNTIME_MOVIE_PLAN_BINDING_MISMATCH');
    if(d.definition_id!==a.definition_id||d.version!==a.version||d.source?.content_id!==a.content_id||d.source?.master_id!==p.source?.cardId||
       !Number.isSafeInteger(a.version)||a.version<1||!hex(a.save_scope)||typeof a.content_id!=='string'||
       !/^(?:(?:eclipse|sparking):)?sha256:[a-f0-9]{64}$/.test(a.content_id)||b.source_sha256!==a.content_id.split(':').slice(-1)[0]||
       canonical(b.transform_links)!==canonical(p.transformLinks||[]))fail('RUNTIME_MOVIE_PLAN_BINDING_MISMATCH');
    for(let index=0;index<group.length;index++){
      const member=group[index],accepted=b.members[index];
      if(!record(accepted)||accepted.key!==member.key||accepted.runtime_card_id!==member.targetId||canonical(accepted.source)!==canonical(member.source)||member.source?.contentId!==a.content_id)fail('RUNTIME_MOVIE_PLAN_BINDING_MISMATCH');
    }
    return pinned;
  }
  function movieSubset(project,bundle){
    if(!Array.isArray(bundle.resources)||!Array.isArray(bundle.source_dependencies)||bundle.source_dependencies.length||!Array.isArray(bundle.shared_actions)||bundle.shared_actions.length)fail('RUNTIME_MOVIE_PLAN_UNSUPPORTED_RESOURCE_BRANCH');
    const declared=new Map();
    for(const resource of bundle.resources){
      if(!record(resource)||resource.kind!=='captured-asset'||!Forge.safePath(resource.path)||!hex(resource.sha256)||!Number.isSafeInteger(resource.size)||resource.size<=1000||resource.size>96*1024*1024||declared.has(resource.path))fail('RUNTIME_MOVIE_PLAN_UNSUPPORTED_RESOURCE_BRANCH');
      declared.set(resource.path,resource);
    }
    const movies=[];
    for(const member of members(project)){
      if(member.sourceDependencies||member.actionHooks||member.artBinding||member.battlePoseBinding||(member.packedAssets||[]).length||
         (member.generatedFiles||[]).length||Object.keys(member.animationAssignments||{}).length||Object.keys(member.abilityAnimationOverrides||{}).length||
         member.awaken!==undefined&&member.awaken!==null&&(!['number','boolean'].includes(typeof member.awaken)||Boolean(member.awaken)))
        fail('RUNTIME_MOVIE_PLAN_UNSUPPORTED_RESOURCE_BRANCH');
      const list=Movies.inspect(member),assets=member.assets||[];
      for(const row of member.tables?.effect_packs||[])if(typeof row.pack_name==='string'&&row.pack_name.startsWith('forge_movie_')&&!list.some(movie=>movie.rowId===row.id))fail('RUNTIME_MOVIE_PLAN_UNSUPPORTED_RESOURCE_BRANCH');
      if(!Array.isArray(assets)||assets.length!==list.length)fail('RUNTIME_MOVIE_PLAN_UNSUPPORTED_RESOURCE_BRANCH');
      for(const asset of assets)if(!record(asset)||asset.owner!=='forge-authored-movie'||!list.some(movie=>movie.key===asset.movieKey&&movie.path===asset.path))fail('RUNTIME_MOVIE_PLAN_UNSUPPORTED_RESOURCE_BRANCH');
      for(const movie of list){
        const resource=declared.get(movie.path);
        if(!resource||resource.size!==movie.size)fail('RUNTIME_MOVIE_PLAN_CAPTURE_MISSING');
        movies.push({memberKey:member.key,movie,resource});
      }
    }
    if(movies.length!==declared.size||new Set(movies.map(item=>item.movie.path)).size!==declared.size)fail('RUNTIME_MOVIE_PLAN_RESOURCE_BINDING_CHANGED');
    return movies;
  }
  async function planAcceptedMovies(input,host){
    try{
      if(!record(host)||typeof host.contextIsCurrent!=='function'||typeof host.query!=='function'||typeof host.listAssets!=='function'||
         typeof host.attestAcceptedResource!=='function'||typeof host.sha256Text!=='function'||!Array.isArray(host.reservations)||host.reservations.length>2000||!record(host.schema))
        fail('RUNTIME_MOVIE_PLAN_NATIVE_CONTEXT_REQUIRED');
      const pinned=checkedInput(input),before=JSON.stringify(input.project),project=Forge.clone(pinned.project),bundle=pinned.fullBundle,binding=pinned.acceptedBinding,hashes=pinned.nativeByteHashes;
      async function current(){if(await host.contextIsCurrent()!==true)fail('RUNTIME_MOVIE_PLAN_CONTEXT_CHANGED');}
      async function call(fn,...args){await current();const result=await fn(...args);await current();return result;}
      await current();
      const originalMovies=movieSubset(project,bundle);
      const validation=Forge.validate(project);if(validation.errors.length)fail('RUNTIME_MOVIE_PLAN_FORGE_REJECTED');
      if(canonical(fixedMaterialize(project,bundle.materialization_utc))!==canonical(bundle.tables))fail('RUNTIME_MOVIE_PLAN_ACCEPTED_MATERIALIZATION_CHANGED');
      for(const item of originalMovies){
        const proof=await call(host.attestAcceptedResource,item.movie.path);
        if(!record(proof)||proof.path!==item.movie.path||proof.sha256!==item.resource.sha256||proof.size!==item.resource.size||
           proof.content_id!==binding.content_id||proof.save_scope!==binding.save_scope||proof.project_sha256!==hashes.project||proof.full_bundle_sha256!==hashes.fullBundle)
          fail('RUNTIME_MOVIE_PLAN_CAPTURE_MISMATCH');
      }
      // Reuse the real Forms -> UnitRebase -> MovieModel path. The caller's
      // native capabilities supply actual readonly collision/catalog queries;
      // never invent an empty resource list or derive an asset key from a path.
      const reserved=await Forms.reserve(project,{schema:Forge.clone(host.schema),projects:Forge.clone(host.reservations),
        query:async options=>{const rows=await call(host.query,Forge.clone(options));if(!Array.isArray(rows)||rows.length>5000)fail('RUNTIME_MOVIE_PLAN_NATIVE_CONTEXT_REQUIRED');return rows;},
        listAssets:async options=>{const rows=await call(host.listAssets,Forge.clone(options));if(!Array.isArray(rows)||rows.length>500)fail('RUNTIME_MOVIE_PLAN_NATIVE_CONTEXT_REQUIRED');return rows;}});
      if((reserved.createdAssets||[]).length)fail('RUNTIME_MOVIE_PLAN_UNSUPPORTED_RESOURCE_BRANCH');
      const runtime=reserved.project,group=members(runtime),resources=[],movieBindings=[];
      if(group.length!==bundle.members.length||Forge.validate(runtime).errors.length)fail('RUNTIME_MOVIE_PLAN_FORGE_REJECTED');
      for(const item of originalMovies){
        const member=group.find(value=>value.key===item.memberKey),movie=member&&Movies.inspect(member).find(value=>value.key===item.movie.key);
        const row=member&&Movies.previewRows(member).find(value=>value.id===movie?.effectPackId);
        if(!movie||!row||movie.rowId!==item.movie.rowId||movie.slot!==item.movie.slot||movie.storageTag!==item.movie.storageTag||movie.size!==item.movie.size||canonical(movie.metadata)!==canonical(item.movie.metadata)||movie.privateUnitId!==member.targetId||!Forge.safePath(movie.path))fail('RUNTIME_MOVIE_PLAN_RESOURCE_BINDING_CHANGED');
        resources.push({accepted_path:item.movie.path,runtime_path:movie.path,sha256:item.resource.sha256,size:item.resource.size,preserve_bytes:true});
        movieBindings.push({member_key:member.key,movie_key:movie.key,accepted_project_row_id:movie.rowId,accepted_effect_pack_id:item.movie.effectPackId,runtime_effect_pack_id:movie.effectPackId,pack_name:row.pack_name,path:movie.path,private_unit_id:movie.privateUnitId,metadata:Forge.clone(movie.metadata)});
      }
      const tables=fixedMaterialize(runtime,bundle.materialization_utc),runtimeIds=group.map(member=>member.targetId);
      for(const movie of movieBindings){const row=(tables.effect_packs||[]).find(value=>value.id===movie.runtime_effect_pack_id);if(!row||row.pack_name!==movie.pack_name)fail('RUNTIME_MOVIE_PLAN_RESOURCE_BINDING_CHANGED');}
      const output={format:'od-runtime-authored-movie-plan-candidate-v1',identity:{content_id:binding.content_id,save_scope:binding.save_scope,definition_id:binding.definition_id,version:binding.version,instance_id:binding.instance_id,project_sha256:hashes.project,definition_sha256:hashes.definition,full_bundle_sha256:hashes.fullBundle,profile_revision:pinned.fullBundleReceipt.profile_revision,projection_generation:pinned.fullBundleReceipt.projection_generation},
        runtimeIds,members:group.map((member,index)=>({key:member.key,source_card_id:member.source.cardId,accepted_runtime_card_id:bundle.members[index].runtime_card_id,runtime_card_id:member.targetId})),
        tables,foreign:Forge.foreign,native_root_card_ids:runtimeIds.map(id=>Math.floor(id/10)*10),resources,movie_bindings:movieBindings,
        encoded_references_complete:false,source_reference_validation_required:true,runtime_allocation_admitted:false,resource_publication_admitted:false,original_client_attached:false,gameplay_ready:false,
        unresolved:['native-writer-allocation-and-generation-revalidation','complete-row-and-encoded-reference-admission','atomic-resource-and-derived-master-publication','original-engine-path-cold-reload-and-decoder-proof']};
      if(JSON.stringify(input.project)!==before)fail('RUNTIME_MOVIE_PLAN_INPUT_CHANGED');
      const planJSON=canonical(output);if(planJSON.length>32*1024*1024)fail('RUNTIME_MOVIE_PLAN_INPUT_INVALID');
      const planSHA=await call(host.sha256Text,planJSON);if(!hex(planSHA))fail('RUNTIME_MOVIE_PLAN_NATIVE_CONTEXT_REQUIRED');
      await current();if(JSON.stringify(input.project)!==before)fail('RUNTIME_MOVIE_PLAN_INPUT_CHANGED');
      return {...output,plan_json:planJSON,plan_sha256:planSHA,plan_encoding:'canonical-json-v1'};
    }catch(error){throw Error(codes.has(error?.message)?error.message:'RUNTIME_MOVIE_PLAN_REJECTED');}
  }
  return Object.freeze({planAcceptedMovies});
});
