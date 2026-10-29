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
  const contentHash=v=>{const m=/^(?:(?:eclipse|sparking):)?sha256:([0-9a-f]{64})$/.exec(v);return m?m[1]:null;};
  const references={card_id:'cards',passive_skill_set_id:'passive_skill_sets',passive_skill_id:'passive_skills',target_passive_skill_set_id:'passive_skill_sets',additional_passive_skill_set_id:'passive_skill_sets',leader_skill_set_id:'leader_skill_sets',special_set_id:'special_sets',card_special_id:'card_specials',active_skill_set_id:'active_skill_sets',standby_skill_set_id:'standby_skill_sets',finish_skill_set_id:'finish_skill_sets',finish_special_id:'finish_specials',card_category_id:'card_categories',dokkan_field_id:'dokkan_fields',character_id:'characters',card_unique_info_id:'card_unique_infos',potential_board_id:'potential_boards',awaked_card_id:'cards',card_awakening_set_id:'card_awakening_sets'};
  const referenceTable=column=>references[column]||(/^link_skill[1-7]_id$/.test(column)?'link_skills':null);
  const affinity=t=>{t=String(t||'').toUpperCase();return /INT/.test(t)?'integer':/CHAR|CLOB|TEXT/.test(t)?'text':/BLOB/.test(t)||!t?'blob':/REAL|FLOA|DOUB/.test(t)?'real':'numeric';};
  const stamp=name=>name==='created_at'||name==='updated_at';
  const fail=(code,createdAssets=[])=>{const e=Error(code);e.code=code;e.createdAssets=[...new Set(createdAssets)];throw e;};
  const pathKey=p=>p.normalize('NFC').toLowerCase();
  function members(project){return [project,...project.formProjects||[]];}
  function context(project,host){
    const digest=contentHash(host&&host.contentId);
    if(!record(host)||!content(host.contentId)||!hex(host.saveScope)||!hex(host.projectSHA256)||!key(host.definitionId)||!Number.isSafeInteger(host.version)||host.version<1||!['eclipse','sparking'].includes(host.sourceDatabase)||!record(host.schema)||typeof host.query!=='function'||!Array.isArray(host.projects))fail('FULL_BUNDLE_TRUSTED_CONTEXT_REQUIRED');
    if(!digest||host.sourceSHA256!==digest||host.sourceHashVerified!==true)fail('FULL_BUNDLE_SOURCE_HASH_REQUIRED');
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
    const hashes=new Map(),texts=new Map();
    function remember(blob){
      const prior=hashes.get(blob.sha256);
      if(prior!==undefined&&prior!==blob.size)fail('FULL_BUNDLE_CAPTURE_DEDUP_MISMATCH');
      hashes.set(blob.sha256,blob.size);return blob;
    }
    async function asset(assetKey){
      if(!Forge.safePath(assetKey)||typeof host.describeAsset!=='function')fail('FULL_BUNDLE_NATIVE_ASSET_ATTESTATION_REQUIRED');
      if(!described.has(assetKey)){
        const d=await host.describeAsset(assetKey);
        if(!record(d)||d.verified!==true||!hex(d.sha256)||!Number.isSafeInteger(d.size)||d.size<1||d.size>96*1024*1024||d.save_scope!==host.saveScope||d.content_id!==host.contentId)fail('FULL_BUNDLE_ASSET_SCOPE_OR_HASH_MISMATCH');
        described.set(assetKey,remember({assetKey,size:d.size,sha256:d.sha256}));
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
        const prior=texts.get(sha);if(prior!==undefined&&prior!==entry.text)fail('FULL_BUNDLE_CAPTURE_DEDUP_MISMATCH');
        texts.set(sha,entry.text);
        const size=new TextEncoder().encode(entry.text).length;
        if(size<1||size>2*1024*1024)fail('FULL_BUNDLE_GENERATED_TEXT_INVALID');
        output.push(remember({path:destination,kind:'generated-text',text:entry.text,sha256:sha,size}));
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
  async function validateReferences(tables,host){
    const owned=new Map(Object.entries(tables).map(([table,rows])=>[table,new Set(rows.map(row=>row.id))]));
    const confirmed=new Set();
    for(const rows of Object.values(tables))for(const row of rows)for(const [column,value] of Object.entries(row)){
      if(column==='id'||!column.endsWith('_id')||value==null||value===0)continue;
      const target=referenceTable(column);if(!target)continue;
      if(!Number.isSafeInteger(value)||value<1)fail('FULL_BUNDLE_REFERENCE_MISSING');
      if(owned.get(target)?.has(value))continue;
      const mark=target+':'+value;if(confirmed.has(mark))continue;
      const found=await host.query({table:target,ids:[value],limit:2});
      if(!Array.isArray(found)||found.length!==1||found[0].id!==value)fail('FULL_BUNDLE_REFERENCE_MISSING');
      confirmed.add(mark);
    }
  }
  async function validateShared(project,tables,host){
    const group=members(project);
    const dependencies=group.filter(member=>member.sourceDependencies).map(member=>({member_key:member.key,bundle:member.sourceDependencies}));
    const actions=group.filter(member=>member.actionHooks?.dodge);
    if(group.length>1&&(dependencies.length||actions.length))fail('FULL_BUNDLE_SHARED_DEPENDENCY_CONFLICT');
    const seen=new Map(),paths=new Map();let count=0;
    for(const item of dependencies){
      const bundle=item.bundle;if(!record(bundle))fail('FULL_BUNDLE_SHARED_DEPENDENCY_INVALID');
      for(const issue of bundle.issues||[])if(!record(issue)||issue.severity==='error')fail('FULL_BUNDLE_SHARED_DEPENDENCY_INVALID');
      const schema=bundle.schema||{};if(bundle.tables&&!record(bundle.tables))fail('FULL_BUNDLE_SHARED_DEPENDENCY_INVALID');
      for(const [table,rows] of Object.entries(bundle.tables||{})){
        const source=schema[table],target=host.schema[table];
        if(!/^[A-Za-z_][A-Za-z0-9_]*$/.test(table)||!Array.isArray(rows)||!Array.isArray(source)||!source.length||!Array.isArray(target)||!target.length)fail('FULL_BUNDLE_SHARED_DEPENDENCY_INVALID');
        const sourceColumns=new Map(source.map(column=>[column.name,column])),targetColumns=new Map(target.map(column=>[column.name,column]));
        const own=new Set((tables[table]||[]).map(row=>row.id));
        for(const row of rows){
          if(++count>5000||!record(row)||!Number.isSafeInteger(row.id)||row.id<1||own.has(row.id))fail(own.has(row.id)?'FULL_BUNDLE_SHARED_DEPENDENCY_CONFLICT':'FULL_BUNDLE_SHARED_DEPENDENCY_INVALID');
          for(const column of source){const master=targetColumns.get(column.name);if(!master||affinity(column.type)!==affinity(master.type))fail('FULL_BUNDLE_SHARED_DEPENDENCY_INVALID');if((column.notnull||column.pk)&&column.dflt_value==null&&row[column.name]==null)fail('FULL_BUNDLE_SHARED_DEPENDENCY_INVALID');}
          for(const [field,value] of Object.entries(row)){const column=sourceColumns.get(field);if(!column)fail('FULL_BUNDLE_SHARED_DEPENDENCY_INVALID');const kind=affinity(column.type);if(value==null){if(column.notnull)fail('FULL_BUNDLE_SHARED_DEPENDENCY_INVALID');continue;}if(kind==='integer'&&!Number.isSafeInteger(value)||kind==='text'&&typeof value!=='string'||(kind==='real'||kind==='numeric')&&typeof value!=='number'||kind==='blob')fail('FULL_BUNDLE_SHARED_DEPENDENCY_INVALID');}
          const sig=JSON.stringify(Object.fromEntries(Object.entries(row).filter(([field])=>!stamp(field)).sort(([a],[b])=>a<b?-1:a>b?1:0)));
          const sigKey=table+'\0'+row.id;if(seen.has(sigKey)&&seen.get(sigKey)!==sig)fail('FULL_BUNDLE_SHARED_DEPENDENCY_CONFLICT');seen.set(sigKey,sig);
          const found=await host.query({table,ids:[row.id],limit:2});
          if(!Array.isArray(found)||found.length>1)fail('FULL_BUNDLE_SHARED_DEPENDENCY_CONFLICT');
          if(found.length===1)for(const [field,value] of Object.entries(row))if(!stamp(field)&&(found[0][field]!==value))fail('FULL_BUNDLE_SHARED_DEPENDENCY_CONFLICT');
        }
      }
      for(const path of bundle.assetPaths||[])if(!Forge.safePath(path))fail('FULL_BUNDLE_SHARED_DEPENDENCY_INVALID');
      for(const animation of bundle.animations||[]){if(!record(animation)||!Forge.safePath(animation.path)||!hex(animation.sha256))fail('FULL_BUNDLE_SHARED_DEPENDENCY_INVALID');const path=pathKey(animation.path);if(paths.has(path)&&paths.get(path)!==animation.sha256)fail('FULL_BUNDLE_SHARED_DEPENDENCY_CONFLICT');paths.set(path,animation.sha256);}
    }
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
      await validateReferences(tables,host);
      await validateShared(runtime,tables,host);
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
          'encoded-ability-semantics-and-unknown-id-columns',
          'original-engine-master-path-cipher-and-cache','resource-copy-cpk-build-and-engine-path-binding',
          'single-owned-instance-form-progression-lease'],
        original_client_attached:false,core_bundle_accepted:false,gameplay_ready:false};
    }catch(error){fail(typeof error?.code==='string'&&error.code.startsWith('FULL_BUNDLE_')?error.code:'FULL_BUNDLE_STAGING_FAILED',
      [...created,...(Array.isArray(error?.createdAssets)?error.createdAssets:[])]);}
  }
  return Object.freeze({stage,validateRows});
});
