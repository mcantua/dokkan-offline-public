/* Full-fidelity future native Creator bundle staging. Does not grant Core or
 * original-engine admission; no WebView handler, SQL execution or gameplay. */
(function(root, factory) {
  if(typeof module==='object'&&module.exports)module.exports=factory(
    require('../../../unit-creator/v2/ui/core'),
    require('../../../unit-creator/v2/ui/forms-model'));
  else root.ODCreatorFullBundle=factory(root.Forge,root.ForgeForms);
})(typeof globalThis!=='undefined'?globalThis:this,function(Forge,Forms){
  'use strict';
  const record=v=>v!==null&&typeof v==='object'&&!Array.isArray(v);
  const hex=v=>typeof v==='string'&&/^[0-9a-f]{64}$/.test(v);
  const key=v=>typeof v==='string'&&/^[A-Za-z0-9_.:-]{1,100}$/.test(v);
  const content=v=>typeof v==='string'&&/^(?:(?:eclipse|sparking):)?sha256:[0-9a-f]{64}$/.test(v);
  const fail=(code,createdAssets=[])=>{const e=Error(code);e.code=code;e.createdAssets=[...new Set(createdAssets)];throw e;};
  const pathKey=p=>p.normalize('NFC').toLowerCase();
  function members(project){return [project,...project.formProjects||[]];}
  function context(project,host){
    if(!record(host)||!content(host.contentId)||!hex(host.saveScope)||!hex(host.projectSHA256)||!key(host.definitionId)||!Number.isSafeInteger(host.version)||host.version<1||!['eclipse','sparking'].includes(host.sourceDatabase)||!record(host.schema)||typeof host.query!=='function'||!Array.isArray(host.projects))fail('FULL_BUNDLE_TRUSTED_CONTEXT_REQUIRED');
    if(host.ownedInstanceId!==undefined&&(!Number.isSafeInteger(host.ownedInstanceId)||host.ownedInstanceId<1))fail('FULL_BUNDLE_OWNED_BINDING_INVALID');
    if(!record(project)||project.format!=='dokkan-unit-forge'||project.version!==1||project.awaken)fail('FULL_BUNDLE_PROJECT_INVALID');
    if(typeof host.sha256Text!=='function')fail('FULL_BUNDLE_NATIVE_TEXT_HASH_REQUIRED');
    if(members(project).some(m=>(m.assets||[]).length||(m.generatedFiles||[]).length||(m.packedAssets||[]).length||m.artBinding||m.battlePoseBinding||(m.movieBindings||[]).length)&&typeof host.listAssets!=='function')fail('FULL_BUNDLE_NATIVE_RESOURCE_CATALOG_REQUIRED');
    for(const m of members(project))if(!record(m.source)||m.source.contentId!==host.contentId||(m.source.database||'eclipse')!==host.sourceDatabase)fail('FULL_BUNDLE_SOURCE_MISMATCH');
  }
  async function sourceEligibility(project,host){
    if(!Array.isArray(host.schema.cards)||!Array.isArray(host.schema.card_awakening_routes))fail('FULL_BUNDLE_SOURCE_SCHEMA_REQUIRED');
    for(const m of members(project)){
      const id=m.source.cardId;
      if(!Number.isSafeInteger(id)||id<1)fail('FULL_BUNDLE_SOURCE_CARD_INVALID');
      const cards=await host.query({table:'cards',ids:[id],limit:2});
      const routes=await host.query({table:'card_awakening_routes',filters:{card_id:id},limit:5000});
      if(!Array.isArray(cards)||cards.length!==1||cards[0].id!==id||!Array.isArray(routes)||routes.length>=5000)fail('FULL_BUNDLE_SOURCE_CARD_UNVERIFIED');
      if(routes.some(r=>r.awaked_card_id!==id&&['CardAwakeningRoute::Dokkan','CardAwakeningRoute::Zet'].includes(r.type)))fail('FULL_BUNDLE_SOURCE_NOT_FULLY_AWAKENED');
    }
  }
  function validateRows(tables,schema){
    if(!record(tables))fail('FULL_BUNDLE_TABLES_INVALID');let count=0;
    for(const [table,rows] of Object.entries(tables)){
      const columns=schema[table];
      if(!/^[a-z][a-z0-9_]*$/.test(table)||!Array.isArray(rows)||!Array.isArray(columns)||!columns.length||columns.length>256)fail('FULL_BUNDLE_SOURCE_SCHEMA_REQUIRED');
      const names=new Map(columns.map(c=>[c.name,c])),seen=new Set();
      for(const row of rows){
        if(++count>50000||!record(row)||!Number.isSafeInteger(row.id)||row.id<1||seen.has(row.id))fail('FULL_BUNDLE_ROW_INVALID');seen.add(row.id);
        for(const c of columns)if((c.notnull||c.pk)&&row[c.name]==null&&c.dflt_value==null)fail('FULL_BUNDLE_REQUIRED_COLUMN');
        for(const [name,value] of Object.entries(row)){
          const c=names.get(name);if(!c||!/^[_A-Za-z][_A-Za-z0-9]*$/.test(name))fail('FULL_BUNDLE_SOURCE_COLUMN_REQUIRED');
          if(value===null){if(c.notnull||c.pk)fail('FULL_BUNDLE_NULL_INVALID');continue;}
          if(typeof value==='string'){if(value.includes('\0')||value.length>1024*1024)fail('FULL_BUNDLE_VALUE_LIMIT');}
          else if(typeof value!=='number'||!Number.isFinite(value)||Number.isInteger(value)&&!Number.isSafeInteger(value))fail('FULL_BUNDLE_VALUE_INVALID');
          const type=String(c.type||'').toUpperCase();
          if(type.includes('INT')&&!Number.isSafeInteger(value))fail('FULL_BUNDLE_INTEGER_REQUIRED');
          if(/CHAR|TEXT|JSON|DATE/.test(type)&&typeof value!=='string')fail('FULL_BUNDLE_TEXT_REQUIRED');
        }
      }
    }return count;
  }
  async function resourceEntries(project,host){
    const output=[],seen=new Set(),described=new Map();
    async function asset(assetKey){
      if(!Forge.safePath(assetKey)||typeof host.describeAsset!=='function')fail('FULL_BUNDLE_NATIVE_ASSET_ATTESTATION_REQUIRED');
      if(!described.has(assetKey)){
        const d=await host.describeAsset(assetKey);
        if(!record(d)||d.verified!==true||!hex(d.sha256)||!Number.isSafeInteger(d.size)||d.size<1||d.size>96*1024*1024||d.save_scope!==host.saveScope||d.content_id!==host.contentId)fail('FULL_BUNDLE_ASSET_SCOPE_OR_HASH_MISMATCH');
        described.set(assetKey,{assetKey,size:d.size,sha256:d.sha256});
      }return {...described.get(assetKey)};
    }
    // Use the real exporter to retain all attachment/generated/CPK paths. The
    // SQL compatibility export is retained separately, never executed here.
    const exports=Forge.exportEntries(project),compatibility=[];
    for(const entry of exports){
      if(!Forge.safePath(entry.path))fail('FULL_BUNDLE_RESOURCE_PATH_INVALID');
      const p=pathKey(entry.path);if(seen.has(p))fail('FULL_BUNDLE_RESOURCE_COLLISION');seen.add(p);
      if(!entry.path.startsWith('files/')||entry.path.endsWith('.sql')){compatibility.push(Forge.clone(entry));continue;}
      const destination=entry.path.slice(6);if(!Forge.safePath(destination))fail('FULL_BUNDLE_RESOURCE_PATH_INVALID');
      if(typeof entry.assetKey==='string')output.push({path:destination,kind:'asset',...await asset(entry.assetKey)});
      else if(Array.isArray(entry.cpk)){
        const inner=new Set(),sources=[];
        for(const item of entry.cpk){if(!Forge.safePath(item.path)||inner.has(pathKey(item.path)))fail('FULL_BUNDLE_CPK_ENTRY_INVALID');inner.add(pathKey(item.path));sources.push({path:item.path,...await asset(item.assetKey)});}
        output.push({path:destination,kind:'cpk-build-required',entries:sources});
      }else if(typeof entry.text==='string'){
        if(typeof host.sha256Text!=='function')fail('FULL_BUNDLE_NATIVE_TEXT_HASH_REQUIRED');
        const sha=await host.sha256Text(entry.text);if(!hex(sha))fail('FULL_BUNDLE_TEXT_HASH_INVALID');
        output.push({path:destination,kind:'generated-text',text:entry.text,sha256:sha});
      }else fail('FULL_BUNDLE_RESOURCE_ENTRY_UNSUPPORTED');
    }
    // Forge intentionally exports shared Dodge separately. Keep its complete
    // settings and generated dispatcher; never silently omit or install it as
    // a global game override from a per-unit packet.
    const sharedActions=[];
    for(const m of members(project))if(m.actionHooks?.dodge){
      const files=(m.generatedFiles||[]).filter(f=>f.owner==='dodge:unit');
      sharedActions.push({member_key:m.key,settings:Forge.clone(m.actionHooks.dodge),generatedFiles:Forge.clone(files),admission:'shared-dispatcher-binding-required'});
    }
    return {entries:output,compatibilityExports:compatibility,sharedActions};
  }
  async function stage(project,host){
    context(project,host);const before=JSON.stringify(project);let created=[];
    try{
      const check=Forge.validate(project);if(check.errors.length)fail('FULL_BUNDLE_FORGE_VALIDATION_FAILED');
      await sourceEligibility(project,host);
      // All ID/resource/form rewriting stays in the existing full Creator path.
      const reserved=await Forms.reserve(project,{query:host.query,projects:host.projects,schema:host.schema,
        readAsset:host.readAsset,storeLwf:host.storeLwf,storeDecoration:host.storeDecoration,
        listAssets:host.listAssets,prepareCounters:host.prepareCounters});
      created=reserved.createdAssets||[];const runtime=reserved.project;
      const tables=Forge.materializeAll(runtime),rowCount=validateRows(tables,host.schema);
      for(const [table,rows] of Object.entries(tables))if(rows.length){
        const existing=await host.query({table,ids:rows.map(r=>r.id),limit:1});
        if(!Array.isArray(existing)||existing.length)fail('FULL_BUNDLE_SOURCE_OR_RUNTIME_COLLISION',created);
      }
      const resources=await resourceEntries(runtime,host);
      const runtimeProjectJSON=JSON.stringify(runtime),runtimeProjectSHA256=await host.sha256Text(runtimeProjectJSON);
      if(!hex(runtimeProjectSHA256))fail('FULL_BUNDLE_TEXT_HASH_INVALID',created);
      const sharedDependencies=[];
      for(const m of members(runtime))if(m.sourceDependencies)sharedDependencies.push({member_key:m.key,bundle:Forge.clone(m.sourceDependencies),admission:'source-dependency-identity-and-resource-binding-required'});
      if(JSON.stringify(project)!==before)fail('FULL_BUNDLE_PROJECT_CHANGED',created);
      return {format:'od-creator-full-bundle-candidate-v1',schema_version:1,
        identity:{content_id:host.contentId,save_scope:host.saveScope,definition_id:host.definitionId,
          version:host.version,project_sha256:host.projectSHA256,owned_instance_id:host.ownedInstanceId??null},
        project:runtime,runtimeProjectJSON,runtime_project_sha256:runtimeProjectSHA256,
        runtime_project_encoding:'utf8-json-stringify-v1',tables,rowCount,
        members:members(runtime).map(m=>({key:m.key,source_card_id:m.source.cardId,runtime_card_id:m.targetId,
          owned_instance_id:host.ownedInstanceId??null})),
        resources,sharedDependencies,createdAssetKeys:[...new Set(created)],
        unresolved:['native-full-bundle-core-acceptance','native-derived-master-transaction',
          'native-row-reference-closure-and-encoded-ability-semantics',
          'original-engine-master-path-cipher-and-cache','resource-copy-cpk-build-and-engine-path-binding',
          'single-owned-instance-form-progression-lease'],
        original_client_attached:false,core_bundle_accepted:false,gameplay_ready:false};
    }catch(error){fail(typeof error?.code==='string'&&error.code.startsWith('FULL_BUNDLE_')?error.code:'FULL_BUNDLE_STAGING_FAILED',
      [...created,...(Array.isArray(error?.createdAssets)?error.createdAssets:[])]);}
  }
  return Object.freeze({stage,validateRows});
});
