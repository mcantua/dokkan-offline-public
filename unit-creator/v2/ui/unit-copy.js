"use strict";
// Copy from a unit: pick any character in the game (or one of your own units), tick what you want
// (stats, Leader Skill, Passive Skill, Super Attacks, Active Skill, transformations, links,
// categories, artwork, aura, animations…), see exactly what will change, then apply it in one step.
// Everything is prepared on a copy of your unit first, so nothing changes until you tap Apply, and
// ↶ Undo takes the whole copy back. Abilities keep their activation conditions and targets.
window.ForgeUnitCopy = (() => {
  const G = () => window.ForgeGuide, B = () => window.ForgeBuilder;
  const FEATURES = [
    ["stats", "HP, ATK & DEF", "Base stats (starting and maximum)."],
    ["identity", "Rarity, Type & Class", "For example LR, Super, STR."],
    ["leader", "Leader Skill", "Replaces your Leader Skill."],
    ["passive", "Passive Skill", "Add it to yours or replace yours. Transformations, counters and additional attacks inside it come along."],
    ["transform", "Transformation only", "Just the “transforms into …” part of their passive, added to yours."],
    ["supers", "Super Attacks & Ultra Super Attacks", "With their damage, effects, conditions and animations."],
    ["active", "Active Skill", "With its conditions, effects and animation."],
    ["standby", "Standby & Finish Skills", "Charge-up moves and finishers, if they have any."],
    ["links", "Link Skills", "All 7 links."],
    ["categories", "Categories", "Replaces your categories."],
    ["art", "Card artwork", "Their in-game picture."],
    ["aura", "Aura", "Aura colour, size and position."],
    ["animations", "Animations only", "Their Super Attack, Active Skill and normal attack animations on YOUR moves. Your moves' damage and effects stay yours."]
  ];
  const STYLE_ORDER = { Normal: 0, Hyper: 1, Condition: 2, Extra: 3, FullPower: 4 };
  const STYLE_NAME = { Normal: "Super Attack", Hyper: "Ultra Super Attack", Condition: "Conditional Super Attack", Extra: "EX Super Attack", FullPower: "Full-power attack" };
  const STATS = ["hp_init", "hp_max", "atk_init", "atk_max", "def_init", "def_max"];
  const AURA = ["aura_id", "aura_scale", "aura_offset_x", "aura_offset_y", "is_aura_front"];
  const ACTIVE_TABLES = ["ultimate_specials", "active_skill_sets", "active_skills", "card_active_skills", "dokkan_field_active_skill_set_relations"];
  const STANDBY_TABLES = ["finish_specials", "standby_skill_sets", "standby_skills", "card_standby_skill_set_relations", "finish_skill_sets", "finish_skills", "card_finish_skill_set_relations", "standby_skill_set_finish_skill_set_relations"];
  const CONDITION_TABLES = ["skill_causalities", "sub_target_type_sets", "sub_target_types"];
  const html = (s) => esc(String(s == null ? "" : s));
  const fmt = (n) => (typeof number === "function" ? number(n) : String(n));

  // ------------------------------------------------------------------ donors
  const dbOf = (p) => (p && p.source && p.source.database === "sparking" ? "sparking" : "eclipse");
  async function schemaOf(db) { return db === "sparking" ? (await Native.call("sparkingInfo")).schema : state.info.schema; }
  async function gameDonor(card) {
    const p = state.project, db = dbOf(p), schema = await schemaOf(db), query = (o) => Native.call(db === "sparking" ? "querySparking" : "query", o);
    const donor = await Forge.loadTemplate(query, schema, card.id, p.targetId);
    donor.schema = donor.schema || schema;
    // Ultimate Super Attacks behind Active Skills are read separately, like the passive/leader copy does.
    for (const r of donor.tables.active_skill_sets || []) if (r.ultimate_special_id) {
      G().ensure(donor, schema, "ultimate_specials");
      const rows = await query({ table: "ultimate_specials", ids: [r.ultimate_special_id], limit: 1 });
      if (rows.length && !donor.tables.ultimate_specials.some((x) => x.id === rows[0].id)) donor.tables.ultimate_specials.push(rows[0]);
    }
    return { project: donor, name: card.name, kind: "game", cardId: Number(card.id) };
  }
  async function myDonor(key) {
    const donor = await Native.call("loadProject", { key });
    if (!donor || donor.format !== "dokkan-unit-forge" || !donor.tables || !donor.cardOverrides) throw Error("That saved unit could not be read.");
    donor.schema = donor.schema || state.info.schema;
    return { project: Forge.clone(donor), name: Forge.card(donor).name || "Your unit", kind: "mine", cardId: Number(donor.source && donor.source.cardId) };
  }
  // ------------------------------------------------------------------ helpers on the working copy
  // Imports donor rows (new private ids) together with any custom conditions/targets they use,
  // and points their condition formulas at the imported condition copies.
  function importWithConditions(work, donor, tables) {
    const conditionTables = CONDITION_TABLES.filter((t) => (donor.tables[t] || []).length);
    const maps = G().importOwned(work, donor, conditionTables.concat(tables));
    const causes = maps.skill_causalities;
    if (causes && causes.size) {
      const rewrite = (n) => typeof n === "number" ? (causes.get(n) ?? n) : Array.isArray(n) ? n.map((v, i) => i ? rewrite(v) : v) : n;
      for (const t of tables) for (const row of work.tables[t] || []) {
        if (!maps[t] || ![...maps[t].values()].includes(row.id) || !row.causality_conditions) continue;
        try {
          const c = JSON.parse(row.causality_conditions);
          c.compiled = rewrite(c.compiled);
          if (c.source) c.source = String(c.source).replace(/-?\d+/g, (n) => String(causes.get(Number(n)) ?? n));
          row.causality_conditions = JSON.stringify(c);
        } catch {}
      }
    }
    return maps;
  }
  // Only tables that exist in the game data and actually have rows are handed on.
  function subset(donor, tables) {
    const keep = (t) => donor.schema && donor.schema[t];
    return { schema: donor.schema, abilityAnimationSources: donor.abilityAnimationSources, abilityAnimationOverrides: donor.abilityAnimationOverrides, tables: Object.fromEntries(tables.filter(keep).map((t) => [t, donor.tables[t] || []]).concat(CONDITION_TABLES.filter((t) => keep(t) && (donor.tables[t] || []).length).map((t) => [t, donor.tables[t]]))) };
  }
  function setName(p, table, id) { const s = (p.tables[table] || []).find((r) => r.id === id); return s ? s.name || "" : ""; }
  function supersOf(p) { return (p.tables.card_specials || []).slice().sort((a, b) => (STYLE_ORDER[a.style] ?? 9) - (STYLE_ORDER[b.style] ?? 9) || (a.lv_start || 0) - (b.lv_start || 0) || a.id - b.id); }
  function superLabel(p, rel) { return (setName(p, "special_sets", rel.special_set_id) || STYLE_NAME[rel.style] || "Super Attack") + (rel.style && rel.style !== "Normal" ? " (" + (STYLE_NAME[rel.style] || rel.style) + ")" : ""); }
  function linkNames(c) { return Array.from({ length: 7 }, (_, i) => c["link_skill" + (i + 1) + "_id"]).filter(Boolean).map((id) => ((state.links || []).find((l) => l.id === id) || {}).name || ("Link " + id)); }
  function categoryNames(p) { return (p.tables.card_card_categories || []).map((r) => ((state.categories || []).find((c) => c.id === r.card_category_id) || {}).name).filter(Boolean); }
  function passiveSetRows(p, setId) { const ids = new Set((p.tables.passive_skill_set_relations || []).filter((r) => r.passive_skill_set_id === setId).map((r) => r.passive_skill_id)); return (p.tables.passive_skills || []).filter((r) => ids.has(r.id)); }
  function primaryPassiveRows(p) { const set = Forge.primaryPassive(p); return set ? passiveSetRows(p, set.id) : []; }
  const isTransform = (r) => [103, 79].includes(Number(r.efficacy_type));
  function describeSet(set) { return set ? String(set.itemized_description || set.description || "").replace(/\{passiveImg:[^}]*\}/g, "").replace(/\*/g, "").trim() : ""; }
  // Removes the current unit's rows of one family before the donor's are copied in.
  function dropOwned(work, relationTable, setTable, setField, childTables) {
    const rels = work.tables[relationTable] || [], ids = new Set(rels.map((r) => r[setField]));
    work.tables[relationTable] = [];
    if (setTable) work.tables[setTable] = (work.tables[setTable] || []).filter((r) => !ids.has(r.id));
    for (const [table, field] of childTables || []) work.tables[table] = (work.tables[table] || []).filter((r) => !ids.has(r[field]));
  }
  function clearAnimation(work, key) {
    const a = work.animationAssignments && work.animationAssignments[key];
    if (!a) return;
    // the id belongs to one table only: intro animations → passive_skill_effects, normal attacks and
    // counters → none (script files only), everything else → special_views
    const kind = String(key).split(":")[0], table = kind === "intro" ? "passive_skill_effects" : ["normal", "counter", "dodge"].includes(kind) ? null : "special_views";
    if (table && work.tables[table]) work.tables[table] = work.tables[table].filter((r) => r.id !== a.id || r.id > 0);
    work.generatedFiles = (work.generatedFiles || []).filter((f) => f.owner !== key);
    delete work.animationAssignments[key];
  }

  function copiedResources(work, donor) {
    const byPath=new Map((work.assets||[]).map(a=>[a.path.normalize('NFC').toLowerCase(),a])),paths=new Map();
    work.assets=work.assets||[];
    for(const asset of donor.assets||[]){
      if(['forge-card-art','forge-battle-poses','forge-authored-movie'].includes(asset.owner))continue;
      if(!Forge.safePath(asset.path)||!Forge.safePath(asset.key))throw Error('The selected animation contains an unsafe resource reference.');
      const copy=Forge.clone(asset);
      if(copy.owner==='forge-sequence-music')copy.path=copy.path.replace('forge_sequence_'+donor.targetId+'_','forge_sequence_'+work.targetId+'_');
      else if(window.ForgeUnitRebase?.namespace(copy.path,donor.targetId))throw Error('This animation uses an unregistered private resource. Restore its complete editable project before copying it.');
      const canonical=copy.path.normalize('NFC').toLowerCase(),prior=byPath.get(canonical);
      if(prior&&prior.key!==copy.key)throw Error('This unit already has a different file at '+copy.path+'. Choose compatible resources before copying.');
      if(!prior){work.assets.push(copy);byPath.set(canonical,copy);}paths.set(asset.path,copy.path);
    }
    const before=work.sourceDependencies?.animations||[],incoming=donor.sourceDependencies?.animations||[],versions=new Set([...before,...incoming].map(a=>a.version));
    if(versions.size>1)throw Error('These animations require different Sparking content versions. Copy from one matching version.');
    if(incoming.length){work.sourceDependencies=work.sourceDependencies||{};const combined=new Map(before.map(a=>[a.path,Forge.clone(a)]));for(const item of incoming){const previous=combined.get(item.path);if(previous&&JSON.stringify(previous)!==JSON.stringify(item))throw Error('Two animation dependencies disagree about the same game resource.');combined.set(item.path,Forge.clone(item));}work.sourceDependencies.animations=[...combined.values()];}
    return music=>music?{...Forge.clone(music),...music.path?{path:paths.get(music.path)||music.path}:{}}:music;
  }

  function applyAssignments(work, donor, pending) {
    if(!pending.length)return;
    const music=copiedResources(work,donor),targets=()=>G().targets(work),seen=new Set();
    for(const item of pending){
      const target=item.to?targets().find(t=>t.key===item.to):targets().find(t=>t.table===item.table&&t.row===item.row&&t.kind===item.kind&&t.phase===item.phase);
      if(!target)throw Error('A copied custom animation lost its move or activation target. Nothing was applied.');
      if(seen.has(target.key))throw Error('Two copied custom animations target the same move. Copy them separately.');seen.add(target.key);
      const assignment=donor.animationAssignments[item.from];
      if(!assignment||!Array.isArray(assignment.clips)||!assignment.clips.length)throw Error('This move is missing its editable custom animation. Restore the complete saved project.');
      if(target.kind==='counter'&&!work.counterScriptReservations?.numbers?.[target.key])throw Error('Prepare this custom counter through the full copy window so its script can be reserved safely.');
      const clips=ForgeMovieModel.copyClips(donor,work,assignment.clips);
      clearAnimation(work,target.key);
      const schema={...donor.schema,...work.schema};
      if(assignment.mode==='original')G().applyOriginal(work,schema,assignment.originalSource||clips[0].source,target.key,assignment.name);
      else G().applyComposition(work,schema,clips,target.key,assignment.name,{music:music(assignment.music)});
    }
    const paths=new Map();
    for(const file of [...work.assets||[],...work.generatedFiles||[]]){
      const key=file.path.normalize('NFC').toLowerCase();if(paths.has(key))throw Error('Two copied resources use the same game path. Nothing was applied.');paths.set(key,file);
    }
  }

  const FORM_TABLES=['passive_skills','active_skills','standby_skills','finish_skills'];
  function linkedForm(donor,table,row,rootLinks=true){
    const link=rootLinks&&(donor.transformLinks||[]).find(item=>item.table===table&&item.row===row.id),forms=donor.formProjects||[];
    if(link){const child=forms.find(form=>form.key===link.targetKey&&Number(form.targetId)===Number(link.targetId));if(!child||ForgeForms.target(row,table).targetId!==Number(link.targetId))throw Error('A copied transformation is missing its saved form or its target changed. Restore the complete source unit.');return child;}
    const target=ForgeForms.target(row,table).targetId,privateForm=forms.find(form=>Number(form.targetId)===target);if(privateForm)return privateForm;
    if(target>=Forge.SLOT_FLOOR&&target<=Forge.SLOT_CEILING)throw Error('A linked custom form is missing from the source unit. Restore its complete editable project before copying.');
    const sourceForms=forms.filter(form=>Number(form.source?.cardId)===target);if(sourceForms.length>1)throw Error('Several saved forms use the same original character. Choose a distinct source for each linked form before copying.');return sourceForms[0]||null;
  }
  function setFormTarget(row,table,id){const info=ForgeForms.target(row,table);row[info.field]=Number(id);if(info.values){info.values[0]=Number(id);row.efficacy_values=JSON.stringify(info.values);}}
  function retargetParams(member,moved,only){
    const change=value=>moved.has(Number(value))?moved.get(Number(value)):value;
    for(const [key,input]of Object.entries(member.abilityAnimationSources||{}))if(!only||only.has(key))for(const param of input.params||[])param.value=change(param.value);
    if(!only)for(const param of member.tables.battle_params||[])param.value=change(param.value);
  }
  async function prepareForms(result,donor){
    const requests=result.formTransfers||[],work=result.work;if(!requests.length)return;
    if(!window.ForgeForms||!window.ForgeUnitRebase)throw Error('Update the app before copying linked transformations.');
    const selected=new Map(),edges=new Map(),visiting=new Set(),finished=new Set(),rootId=Number(donor.targetId),rootSource=Number(donor.source.cardId);
    function visit(form){
      if(visiting.has(form.key))throw Error('This transformation chain contains a form cycle. Keep a one-way chain before copying.');if(finished.has(form.key))return;
      if(form.formProjects!==undefined||form.transformLinks!==undefined)throw Error('Keep linked forms directly inside the starting unit before copying.');
      selected.set(form.key,form);visiting.add(form.key);const links=[];
      for(const table of FORM_TABLES)for(const row of form.tables[table]||[]){if(Number(row.efficacy_type)!==103)continue;const target=ForgeForms.target(row,table).targetId;
        if(target===rootId||target===rootSource&&target!==Number(form.source.cardId))throw Error('This form returns to the source unit. Form cycles cannot be copied into a different starting unit.');
        const child=linkedForm(donor,table,row,false);
        if(child){if(child.key===form.key)throw Error('This transformation points back to the same saved form. Choose a one-way transformation chain.');links.push({table,row:row.id,key:child.key});visit(child);}
        else if(target>=Forge.SLOT_FLOOR&&target<=Forge.SLOT_CEILING)throw Error('A linked custom form is missing from the source unit. Restore its complete editable project before copying.');
      }
      edges.set(form.key,links);visiting.delete(form.key);finished.add(form.key);
    }
    for(const request of requests)if(request.formKey){const form=(donor.formProjects||[]).find(item=>item.key===request.formKey);if(!form)throw Error('A selected transformation lost its saved form.');visit(form);}
    if((work.formProjects||[]).length+selected.size>ForgeForms.MAX_FORMS)throw Error('A unit can keep up to four additional transformation forms. Remove an unneeded form before copying this chain.');
    const sourceOwners=new Map([[Number(work.source.cardId),work.key]]);
    for(const member of selected.size?[...work.formProjects||[],...selected.values()]:[]){const source=Number(member.source.cardId);if(sourceOwners.has(source)||source===rootSource)throw Error('Linked forms must use distinct original character IDs so their transformation targets stay unambiguous.');sourceOwners.set(source,member.key);}
    const moved=new Map([[rootId,Number(work.targetId)],[rootSource,Number(work.targetId)]]),copied=new Map();
    if(selected.size){
      const db=dbOf(work),schema=db==='sparking'?await schemaOf(db):state.info.schema,method=db==='sparking'?'querySparking':'query',projects=await Native.call('projects');if(!Array.isArray(projects))throw Error('Your unit library could not be checked for free transformation slots.');
      const reservations=[...projects,work,donor,...(donor.formProjects||[])].map((project,index)=>({...project,key:'copy-reserved-'+index+'-'+project.key}));
      const readAsset=async key=>{const response=await Native.call('readAsset',{key,maxBytes:12*1024*1024});return Uint8Array.from(atob(response.base64),c=>c.charCodeAt(0));};
      const encode=bytes=>{let result='';for(let at=0;at<bytes.length;at+=32768)result+=String.fromCharCode(...bytes.subarray(at,at+32768));return btoa(result);};
      for(const original of selected.values()){
        const standalone=Forge.clone(original);standalone.key='unit-form-'+(crypto.randomUUID?.()||Date.now().toString(36)+'-'+Math.random().toString(36).slice(2));delete standalone.versions;
        for(const asset of standalone.assets||[])if(!['forge-card-art','forge-battle-poses','forge-authored-movie','forge-sequence-music'].includes(asset.owner)&&ForgeUnitRebase.namespace(asset.path,original.targetId))throw Error('A linked form has an unregistered private resource. Restore its complete editable resource bindings before copying.');
        const reserved=await ForgeUnitRebase.reserve(standalone,{query:args=>Native.call(method,args),projects:reservations,schema,listAssets:args=>Native.call('assets',args),readAsset,storeDecoration:text=>Native.call('storeDecoration',{text}),storeLwf:(bytes,options)=>Native.call('storeLwf',{name:options.name,data:encode(bytes)}),prepareCounters:project=>{if(!window.ForgeCounterReservations)throw Error('Update the app before copying custom counters.');return ForgeCounterReservations.prepare(project,{schema});}}),form=reserved.project;
        const paths=new Map();for(const asset of form.assets||[])if(asset.owner==='forge-sequence-music'){const path=asset.path.replace('forge_sequence_'+original.targetId+'_','forge_sequence_'+form.targetId+'_');paths.set(asset.path,path);asset.path=path;}
        if(paths.size)for(const [key,assignment]of Object.entries(form.animationAssignments||{})){if(assignment.music?.path&&paths.has(assignment.music.path))assignment.music.path=paths.get(assignment.music.path);if(assignment.mode==='original')G().applyOriginal(form,schema,assignment.originalSource||assignment.clips[0].source,key,assignment.name);else G().applyComposition(form,schema,assignment.clips,key,assignment.name,{music:assignment.music});}
        const now=new Date().toISOString();form.createdAt=form.updatedAt=now;copied.set(original.key,form);moved.set(Number(original.targetId),Number(form.targetId));moved.set(Number(original.source.cardId),Number(form.targetId));reservations.push(form);
      }
      for(const [key,form]of copied){for(const edge of edges.get(key)||[])setFormTarget(form.tables[edge.table].find(row=>row.id===edge.row),edge.table,copied.get(edge.key).source.cardId);retargetParams(form,moved);}
      work.formProjects=[...work.formProjects||[],...copied.values()];
      result.changes.push(['Linked transformation forms','Your existing forms are kept',copied.size+' additional form'+(copied.size===1?'':'s')+' with new private slots and editable resources']);
    }
    const imported=new Set();
    for(const request of requests){imported.add(request.table+':'+request.row);if(!request.formKey)continue;const form=copied.get(request.formKey),row=(work.tables[request.table]||[]).find(row=>row.id===request.row);if(!row)throw Error('A copied transformation ability was removed while preparing its form.');setFormTarget(row,request.table,form.targetId);work.transformLinks=work.transformLinks||[];work.transformLinks.push({table:request.table,row:request.row,targetKey:form.key,targetId:Number(form.targetId)});}
    retargetParams(work,moved,imported);
  }

  async function prepare(d,picked,options={},base=state.project){
    const before=JSON.stringify(base),result=build(d,picked,{...options,deferResources:true},base),work=result.work,donor=d.project;
    work.assets=work.assets||[];
    if(result.pending.some(item=>item.kind==='counter')){
      if(!window.ForgeCounterReservations)throw Error('Update the app before copying custom counterattacks.');
      await ForgeCounterReservations.prepare(work,{schema:state.info.schema});
    }
    applyAssignments(work,donor,result.pending);
    await prepareForms(result,donor);
    if(picked.has('art')&&donor.artBinding){
      if(!window.ForgeArt)throw Error('Update the app before copying custom artwork.');
      const project=Forge.clone(donor);project.targetId=work.targetId;
      const projects=await Native.call('projects'),occupied=projects.filter(row=>row.key!==base.key).flatMap(row=>row.reservedIds||[row.targetId]).map(id=>Math.floor(Number(id)/10)*10);
      const method=dbOf(work)==='sparking'?'querySparking':'query',existing=await Native.call(method,{table:'cards',filters:{resource_id:Math.floor(work.targetId/10)*10},limit:1});
      if(existing.length)throw Error('The destination artwork namespace already belongs to a game character. Reserve a new custom unit slot first.');
      const readAsset=async key=>{const r=await Native.call('readAsset',{key,maxBytes:12*1024*1024});return Uint8Array.from(atob(r.base64),c=>c.charCodeAt(0));};
      const prepared=await ForgeArt.plan(project,donor.assets||[],{group:'saved-custom-artwork',replacements:ForgeArt.replacements(donor),occupiedResourceIds:occupied,readAsset,storeDecoration:text=>Native.call('storeDecoration',{text})});
      ForgeArt.apply(project,prepared);
      const existingPaths=new Map((work.assets||[]).map(a=>[a.path.normalize('NFC').toLowerCase(),a]));
      for(const a of project.assets.filter(a=>a.owner==='forge-card-art'))if(existingPaths.has(a.path.normalize('NFC').toLowerCase()))throw Error('An attachment already owns the copied artwork path. Nothing was applied.');
      const packed=project.packedAssets?.filter(a=>a.owner==='forge-card-art')||[];
      if(packed.some(a=>(work.packedAssets||[]).some(b=>a.path.normalize('NFC').toLowerCase()===b.path.normalize('NFC').toLowerCase())))throw Error('An attachment already owns the copied artwork archive.');
      const priorOverrides=Object.fromEntries(['resource_id','bg_effect_id'].map(key=>[key,{present:Object.prototype.hasOwnProperty.call(work.cardOverrides,key),value:work.cardOverrides[key]}]));
      work.assets.push(...project.assets.filter(a=>a.owner==='forge-card-art'));work.packedAssets=[...work.packedAssets||[],...packed];work.artBinding=Forge.clone(project.artBinding);work.artBinding.originalOverrides=priorOverrides;
      if(work.previewKey)work.artBinding.previousPreviewKey=work.previewKey;else delete work.artBinding.previousPreviewKey;
      work.cardOverrides.resource_id=project.cardOverrides.resource_id;work.cardOverrides.bg_effect_id=donor.artBinding.staticBackground?null:project.cardOverrides.bg_effect_id;
      if(donor.artBinding.staticBackground)work.artBinding.staticBackground=true;
      if(donor.previewKey)work.previewKey=donor.previewKey;
    }
    const existingFormKeys=new Set((base.formProjects||[]).map(form=>form.key));
    const originalAssets=new Set((base.assets||[]).map(a=>a.path+'\0'+a.key)),donorKeys=new Set((donor.assets||[]).map(a=>a.key)),copiedAnimation=result.pending.length||picked.has('passive')&&donor.actionHooks?.dodge;
    const keys=[...new Set([...(work.formProjects||[]).filter(form=>!existingFormKeys.has(form.key)).flatMap(form=>(form.assets||[]).map(a=>a.key).concat(form.previewKey?[form.previewKey]:[])),...(work.assets||[]).filter(a=>!originalAssets.has(a.path+'\0'+a.key)||copiedAnimation&&donorKeys.has(a.key)||picked.has('art')&&a.owner==='forge-card-art').map(a=>a.key).concat(picked.has('art')&&work.previewKey?[work.previewKey]:[])])];
    for(let at=0;at<keys.length;at+=500){const status=await Native.call('assetStatus',{keys:keys.slice(at,at+500)});if(!Array.isArray(status)||status.some(a=>!a.available)||status.length!==keys.slice(at,at+500).length)throw Error('A copied attachment is missing. Restore the source unit’s resources before applying.');}
    const validation=Forge.validate(work);if(validation.errors.length)throw Error(validation.errors[0]);
    if(JSON.stringify(base)!==before)throw Error('Your unit changed while the copy was prepared. Start again.');
    return result;
  }

  // ------------------------------------------------------------------ what the donor has
  function inventory(d) {
    const p = d.project, c = Forge.card(p), passive = Forge.primaryPassive(p), rows = primaryPassiveRows(p), leader = (p.tables.leader_skill_sets || []).find((s) => s.id === c.leader_skill_set_id);
    const supers = supersOf(p), actives = p.tables.card_active_skills || [], standby = (p.tables.card_standby_skill_set_relations || []).length + (p.tables.card_finish_skill_set_relations || []).length;
    const own = state.project, sameDb = dbOf(p) === dbOf(own);
    return {
      stats: { ok: STATS.some((k) => c[k]), detail: "HP " + fmt(c.hp_max) + " · ATK " + fmt(c.atk_max) + " · DEF " + fmt(c.def_max) },
      identity: { ok: true, detail: (Forge.rarities[c.rarity] || "") + " " + (Forge.elements[c.element] || "") },
      leader: { ok: !!leader, detail: leader ? leader.name || "Leader Skill" : "No Leader Skill" },
      passive: { ok: !!passive && rows.length > 0, detail: passive ? (passive.name || "Passive Skill") + " · " + rows.length + " abilit" + (rows.length === 1 ? "y" : "ies") : "No Passive Skill" },
      transform: { ok: rows.some(isTransform), detail: rows.some(isTransform) ? "Transforms (passive)" : "Doesn't transform through its passive" },
      supers: { ok: sameDb && supers.length > 0, detail: sameDb ? supers.map((r) => superLabel(p, r)).join(" · ") || "No Super Attacks" : "From the other game collection (Eclipse/Sparking)" },
      active: { ok: sameDb && actives.length > 0, detail: actives.length ? actives.map((r) => setName(p, "active_skill_sets", r.active_skill_set_id) || "Active Skill").join(" · ") : "No Active Skill" },
      standby: { ok: sameDb && standby > 0, detail: standby ? standby + " skill" + (standby === 1 ? "" : "s") : "None" },
      links: { ok: linkNames(c).length > 0, detail: linkNames(c).join(", ") || "None" },
      categories: { ok: (p.tables.card_card_categories || []).length > 0, detail: categoryNames(p).slice(0, 6).join(", ") + (categoryNames(p).length > 6 ? "…" : "") || "None" },
      art: { ok: !!(c.resource_id || d.cardId), detail: d.kind === "mine" && p.artBinding ? "Their custom artwork and attached card resources" : "Their card picture" },
      aura: { ok: true, detail: c.aura_id ? "Special aura" : "No special aura" },
      animations: { ok: sameDb && ((supers.some((r) => Number(r.view_id) > 0 || p.animationAssignments?.["super:"+r.id]) && (own.tables.card_specials || []).length > 0) || ((p.tables.active_skill_sets || []).some((s) => Number(s.special_view_id) > 0 || p.animationAssignments?.["active:"+s.id]) && (own.tables.card_active_skills || []).length > 0) || (p.tables.card_motions || []).some((r) => r.filename)), detail: "Super Attack, Active Skill and normal attack animations" }
    };
  }

  // ------------------------------------------------------------------ build the result
  function build(d, picked, options, base = state.project) {
    const before = base, work = Forge.clone(before), donor = d.project, dc = Forge.card(donor), changes = [], notes = [], pending = [], formTransfers = [];
    const remember = maps => {
      for(const table of FORM_TABLES)for(const [oldId,row]of maps[table]||[]){const source=(donor.tables[table]||[]).find(item=>item.id===oldId);if(Number(source?.efficacy_type)!==103)continue;const form=linkedForm(donor,table,source);if(form&&!options.deferResources)throw Error('Prepare this transformation through the full copy window so its forms and resources can be reserved safely.');formTransfers.push({table,row,sourceRow:oldId,formKey:form?.key||null});const oldKey=table+':'+oldId;if(donor.abilityAnimationOverrides?.[oldKey]){work.abilityAnimationOverrides=work.abilityAnimationOverrides||{};work.abilityAnimationOverrides[table+':'+row]=Forge.clone(donor.abilityAnimationOverrides[oldKey]);}}
      for(const target of G().targets(donor)) { const row=maps[target.table]?.get(target.row);if(row==null)continue;const assignment=donor.animationAssignments?.[target.key],source=(donor.tables[target.table]||[]).find(r=>r.id===target.row),field=target.kind==="intro"?"passive_skill_effect_id":target.field;if(!assignment&&field&&Number(source?.[field])<0)throw Error("This saved move lost its editable custom animation. Restore its complete project before copying.");if(assignment)pending.push({from:target.key,table:target.table,row,kind:target.kind,phase:target.phase}); } };
    if(dbOf(donor)!==dbOf(work)&&["supers","active","standby","animations"].some(key=>picked.has(key)))throw Error("Copy these moves within the same Eclipse or Sparking collection so their gameplay resources keep the correct version.");
    const schemaFix = (tables) => { for (const t of tables) if (donor.schema && donor.schema[t]) G().ensure(work, donor.schema, t); };
    if (picked.has("stats")) {
      const b = Forge.card(work);
      for (const k of STATS) if (dc[k] != null) work.cardOverrides[k] = dc[k];
      changes.push(["HP, ATK & DEF", "HP " + fmt(b.hp_max) + " · ATK " + fmt(b.atk_max) + " · DEF " + fmt(b.def_max), "HP " + fmt(dc.hp_max) + " · ATK " + fmt(dc.atk_max) + " · DEF " + fmt(dc.def_max)]);
    }
    if (picked.has("identity")) {
      const b = Forge.card(work);
      work.cardOverrides.rarity = dc.rarity;
      work.cardOverrides.element = dc.element;
      changes.push(["Rarity, Type & Class", (Forge.rarities[b.rarity] || "") + " " + (Forge.elements[b.element] || ""), (Forge.rarities[dc.rarity] || "") + " " + (Forge.elements[dc.element] || "")]);
    }
    if (picked.has("leader")) {
      const was = (work.tables.leader_skill_sets || []).find((s) => s.id === Forge.card(work).leader_skill_set_id);
      schemaFix(["leader_skill_sets", "leader_skills"]);
      const maps = importWithConditions(work, donor, ["leader_skill_sets", "leader_skills"]);
      const id = maps.leader_skill_sets.get(G().stageAbilityId(donor, "base", "leader"));
      if (id == null) throw Error(d.name + " has no Leader Skill to copy.");
      G().setStageAbility(work, "base", "leader", id);
      const now = work.tables.leader_skill_sets.find((s) => s.id === id);
      changes.push(["Leader Skill", (was && was.name) || "—", (now.name || "Leader Skill") + (now.description ? " — " + now.description : "")]);
    }
    if (picked.has("passive")) {
      // options.targetSet: add into this passive set (e.g. the EZA step open in the Card Builder)
      const fixed = options.targetSet != null && (work.tables.passive_skill_sets || []).some((s) => s.id === options.targetSet);
      const was = fixed ? work.tables.passive_skill_sets.find((s) => s.id === options.targetSet) : Forge.primaryPassive(work), wasName = was ? was.name || "Passive Skill" : "—";
      schemaFix(["passive_skill_sets", "passive_skills", "passive_skill_set_relations"]);
      const donorSetOld = G().stageAbilityId(donor, options.passiveStage && G().stageSet(donor, options.passiveStage, "passive") ? options.passiveStage : "base", "passive");
      const adding = !!(options.passive === "add" && was && (fixed || passiveSetRows(work, was.id).length) && window.ForgePassiveMerge);
      // adding: bring only the chosen passive, not the donor's other (EZA stage) passives
      const src = adding ? ForgePassiveMerge.onlySet(donor, donorSetOld) : donor;
      const maps = importWithConditions(work, src, ["passive_skill_sets", "passive_skills", "passive_skill_set_relations", "passive_skill_set_additions", "dokkan_field_passive_skill_relations"].filter((t) => src.tables[t]));
      remember(maps);
      const donorSet = maps.passive_skill_sets.get(donorSetOld);
      if (donorSet == null) throw Error(d.name + " has no Passive Skill to copy.");
      if (adding) {
        if (!fixed) G().isolateAbilityStage(work, "base", "passive");
        const target = fixed ? options.targetSet : G().stageAbilityId(work, "base", "passive");
        const customRows=new Set([...pending.filter(item=>item.table==="passive_skills").map(item=>item.row),...formTransfers.filter(item=>item.table==="passive_skills"&&item.formKey).map(item=>item.row)]);
        const customIntro=pending.some(item=>item.table==='passive_skills'&&item.kind==='intro'),existingIds=new Set((work.tables.passive_skill_set_relations||[]).filter(rel=>rel.passive_skill_set_id===target).map(rel=>rel.passive_skill_id));
        if(customIntro&&(work.tables.passive_skills||[]).some(row=>existingIds.has(row.id)&&row.passive_skill_effect_id!=null&&Number(row.passive_skill_effect_id)!==0))throw Error('This passive already has an Intro animation. Replace the passive or choose one Intro so neither custom move is silently removed.');
        for(const rel of work.tables.passive_skill_set_relations||[])if(rel.passive_skill_set_id===donorSet&&customRows.has(rel.passive_skill_id))rel.passive_skill_set_id=target;
        const merged = ForgePassiveMerge.copyPassive(work, target, donorSet);
        // tidy straight away: exact copies become one, matching boosts combined, kept within today's meta
        const tf = merged.skipped.filter((t) => /under Transformations/.test(t)).length;
        if (tf) notes.push(tf + " transformation" + (tf === 1 ? " was" : "s were") + " left out of the passive — add them under Transformations on the Passive Skill step.");
        const tidy = options.organize === false || customRows.size ? null : ForgePassiveMerge.organize(work, target);
        if(customRows.size)notes.push("Custom animations and linked transformations keep their own activation rules and are not combined with other effects.");
        if (tidy) for (const line of ForgePassiveMerge.organizeSummary(tidy).slice(1)) notes.push(line);
        work.builderAuto = work.builderAuto || {};
        work.builderAuto["passive:" + target] = false;
        if (work.builderLines) delete work.builderLines[target];
        const now = (work.tables.passive_skill_sets || []).find((s) => s.id === target);
        changes.push(["Passive Skill (added to yours)", wasName, describeSet(now) || ForgePassiveMerge.summary(merged) || "Combined"]);
      } else {
        G().setStageAbility(work, "base", "passive", donorSet);
        if ((work.formProjects || []).length) notes.push("Your unit's own transformed forms are kept. Whether it still transforms now depends on the new passive — check Transformations on the Passive Skill step.");
        const now = work.tables.passive_skill_sets.find((s) => s.id === donorSet);
        changes.push(["Passive Skill (replaces yours)", wasName, (now.name || "Passive Skill") + (describeSet(now) ? " — " + describeSet(now) : "")]);
      }
    } else if (picked.has("transform")) {
      const rows = primaryPassiveRows(donor).filter(isTransform);
      if (!rows.length) throw Error(d.name + " doesn't transform through its passive.");
      schemaFix(["passive_skills", "passive_skill_set_relations"]);
      if (!Forge.primaryPassive(work)) throw Error("Your unit needs a Passive Skill first (add any ability on the Passive Skill step).");
      G().isolateAbilityStage(work, "base", "passive");
      const target = G().stageAbilityId(work, "base", "passive"), part = subset(donor, []);
      part.tables.passive_skills = rows;
      const maps = importWithConditions(work, part, ["passive_skills"]);remember(maps);
      for (const id of maps.passive_skills.values()) work.tables.passive_skill_set_relations.push(Object.assign(Forge.rowDefault(work.schema.passive_skill_set_relations || donor.schema.passive_skill_set_relations), { id: Forge.localId(work, "passive_skill_set_relations"), passive_skill_set_id: target, passive_skill_id: id }));
      changes.push(["Transformation", "—", "Transforms like " + d.name + " (into the same forms). Make the forms your own later under Transformations on the Passive Skill step."]);
    }
    if (picked.has("supers")) {
      const old = supersOf(work).map((r) => r.id), wasNames = supersOf(work).map((r) => superLabel(work, r)), added = [];
      for (const rel of supersOf(donor)) {
        const part = subset(donor, ["card_specials", "special_sets", "specials", "extra_special_options"]);
        part.tables.card_specials = [rel];
        part.tables.special_sets = (donor.tables.special_sets || []).filter((s) => s.id === rel.special_set_id);
        part.tables.specials = (donor.tables.specials || []).filter((s) => s.special_set_id === rel.special_set_id);
        part.tables.extra_special_options = (donor.tables.extra_special_options || []).filter((o) => o.card_special_id === rel.id);
        const row = ForgeSuperAttacks.copy(work, part);
        if(donor.animationAssignments?.["super:"+rel.id])pending.push({from:"super:"+rel.id,to:"super:"+row.id});
        else if(Number(row.view_id)<0)throw Error("This saved Super Attack is missing its editable custom animation. Restore its complete project before copying it.");
        added.push(superLabel(work, row));
      }
      if (options.supers !== "add") for (const id of old) B().removeSuper(work, id);
      changes.push([options.supers === "add" ? "Super Attacks (added)" : "Super Attacks (replace yours)", wasNames.join(" · ") || "—", added.join(" · ")]);
    }
    if (picked.has("active")) {
      const wasNames = (work.tables.card_active_skills || []).map((r) => setName(work, "active_skill_sets", r.active_skill_set_id)).filter(Boolean);
      schemaFix(ACTIVE_TABLES);
      for (const key of Object.keys(work.animationAssignments || {})) if (key.startsWith("active:")) clearAnimation(work, key);
      dropOwned(work, "card_active_skills", "active_skill_sets", "active_skill_set_id", [["active_skills", "active_skill_set_id"], ["dokkan_field_active_skill_set_relations", "active_skill_set_id"]]);
      remember(importWithConditions(work, donor, ACTIVE_TABLES.filter((t) => donor.tables[t])));
      const nowNames = (work.tables.card_active_skills || []).map((r) => setName(work, "active_skill_sets", r.active_skill_set_id)).filter(Boolean);
      changes.push(["Active Skill", wasNames.join(" · ") || "—", nowNames.join(" · ") || "—"]);
    }
    if (picked.has("standby")) {
      schemaFix(STANDBY_TABLES);
      for (const key of Object.keys(work.animationAssignments || {})) if (key.startsWith("standby:") || key.startsWith("finish:")) clearAnimation(work, key);
      dropOwned(work, "card_standby_skill_set_relations", "standby_skill_sets", "standby_skill_set_id", [["standby_skills", "standby_skill_set_id"]]);
      dropOwned(work, "card_finish_skill_set_relations", "finish_skill_sets", "finish_skill_set_id", [["finish_skills", "finish_skill_set_id"]]);
      remember(importWithConditions(work, donor, STANDBY_TABLES.filter((t) => donor.tables[t])));
      changes.push(["Standby & Finish Skills", "—", (work.tables.standby_skill_sets || []).map((s) => s.name).concat((work.tables.finish_skill_sets || []).map((s) => s.name)).filter(Boolean).join(" · ") || "Copied"]);
    }
    if (picked.has("links")) {
      const b = linkNames(Forge.card(work));
      for (let i = 1; i <= 7; i++) work.cardOverrides["link_skill" + i + "_id"] = dc["link_skill" + i + "_id"] || null;
      changes.push(["Link Skills", b.join(", ") || "—", linkNames(dc).join(", ")]);
    }
    if (picked.has("categories")) {
      const b = categoryNames(work);
      work.schema.card_card_categories = work.schema.card_card_categories || state.info.schema.card_card_categories;
      work.tables.card_card_categories = [];
      (donor.tables.card_card_categories || []).forEach((r, i) => work.tables.card_card_categories.push(Object.assign(Forge.rowDefault(work.schema.card_card_categories), { id: Forge.localId(work, "card_card_categories"), card_id: work.source.cardId, card_category_id: r.card_category_id, num: i + 1 })));
      changes.push(["Categories", b.join(", ") || "—", categoryNames(work).join(", ")]);
    }
    if (picked.has("art")) {
      const b = (work.uiLabels && work.uiLabels.art) || "Current artwork";
      if (work.artBinding && window.ForgeArt) ForgeArt.restore(work);
      if(donor.artBinding){
        if(!options.deferResources)throw Error("Prepare this custom artwork through the full copy window so its private files can be checked.");
      }else{
        work.cardOverrides.resource_id = dc.resource_id || Math.floor(Number(d.cardId) / 10) * 10;
        work.cardOverrides.bg_effect_id = dc.bg_effect_id != null ? dc.bg_effect_id : null;
      }
      work.uiLabels = work.uiLabels || {};
      work.uiLabels.art = d.name;
      work.uiLabels.artCardId = d.cardId;
      delete work.previewKey;
      changes.push(["Card artwork", b, d.name + "’s artwork"]);
    }
    if (picked.has("aura")) {
      const b = (work.uiLabels && work.uiLabels.aura) || "Current aura";
      for (const k of AURA) work.cardOverrides[k] = dc[k];
      work.uiLabels = work.uiLabels || {};
      work.uiLabels.aura = dc.aura_id ? d.name + "’s aura" : "No special aura (from " + d.name + ")";
      changes.push(["Aura", b, work.uiLabels.aura]);
    }
    if (picked.has("animations")) {
      const done = [];
      if (!picked.has("supers")) {
        const mine = supersOf(work), theirs = supersOf(donor).filter((r) => Number(r.view_id) > 0 || donor.animationAssignments?.["super:"+r.id]).map(r=>Forge.clone(r));
        mine.forEach((rel) => {
          const match = theirs.find((t) => t.style === rel.style && !t.used) || theirs.find((t) => t.style === "Normal" && !t.used) || theirs.find((t) => !t.used);
          if (!match) return;
          match.used = true;
          clearAnimation(work, "super:" + rel.id);
          if(donor.animationAssignments?.["super:"+match.id])pending.push({from:"super:"+match.id,to:"super:"+rel.id});
          else rel.view_id = match.view_id;
          done.push(superLabel(work, rel) + " ← " + superLabel(donor, match));
        });
        theirs.forEach((t) => delete t.used);
      }
      if (!picked.has("active")) {
        const mySet = (work.tables.active_skill_sets || []).find((s) => (work.tables.card_active_skills || []).some((r) => r.active_skill_set_id === s.id));
        const their = (donor.tables.active_skill_sets || []).find((s) => Number(s.special_view_id) > 0 || donor.animationAssignments?.["active:"+s.id]);
        if (mySet && their) { clearAnimation(work, "active:" + mySet.id); if(donor.animationAssignments?.["active:"+their.id])pending.push({from:"active:"+their.id,to:"active:"+mySet.id});else mySet.special_view_id = their.special_view_id; done.push("Active Skill"); }
      }
      const motions = (donor.tables.card_motions || []).filter((r) => r.filename);
      if (motions.length) {
        schemaFix(["card_motions"]);
        for (const key of Object.keys(work.animationAssignments || {})) if (key.startsWith("normal:")) clearAnimation(work, key);
        work.tables.card_motions = [];
        const map=new Map();for (const r of motions) {const row=Object.assign(Forge.clone(r), { id: Forge.localId(work, "card_motions"), card_id: work.source.cardId });work.tables.card_motions.push(row);map.set(r.id,row.id);}remember({card_motions:map});
        done.push("Normal attacks");
      }
      if (!done.length && !picked.has("supers") && !picked.has("active")) throw Error(d.name + " has no animations that can be copied onto your moves.");
      work.uiLabels = work.uiLabels || {};
      if (done.length) changes.push(["Animations", "Your current animations", done.join(" · ")]);
      notes.push("Only the animations changed; your moves keep their own damage and effects.");
    }
    if(picked.has('passive')&&donor.actionHooks?.dodge){
      if(!window.ForgeActionHooks)throw Error('Update the app before copying custom Dodge animations.');
      const dodge=donor.actionHooks.dodge,existing=work.actionHooks?.dodge;
      if(options.passive==='add'&&existing&&JSON.stringify(existing)!==JSON.stringify(dodge))throw Error('This unit already has a different custom Dodge animation. Copy the passive with Replace, or choose one Dodge design.');
      if(existing&&existing.original?.text!==dodge.original?.text)throw Error('These Dodge animations use different original game versions. Reapply them from matching game data before copying.');
      const music=copiedResources(work,donor),clips=ForgeMovieModel.copyClips(donor,work,dodge.clips);
      ForgeActionHooks.apply(work,clips,dodge.original,dodge.name,{music:music(dodge.music)});
    }
    if(pending.length&&!options.deferResources)applyAssignments(work,donor,pending);
    return { work, changes, notes, pending, formTransfers };
  }

  // ------------------------------------------------------------------ screens
  function closeDialog() { const d = document.getElementById("dialog"); if (d && d.open) d.close(); }
  function open() {
    const p = state.project;
    if (!p) return toast("Open one of your units first.", true);
    if (p.awaken) return toast("EZA projects change an existing card; copy abilities on each step instead.", true);
    dialog("Copy from a unit", '<div class="ucopy-dialog" data-no-ai></div><p>Take anything from another unit — a character in the game or one of your own — and put it on <strong>' + html(Forge.card(p).name || "your unit") + '</strong>. You\'ll see every change before anything happens.</p>' +
      '<div class="ucopy-sources"><button type="button" class="button ucopy-source" id="ucopy-game"><strong>🎮 A character from the game</strong><small>Any card in the game, including EZA versions.</small></button><button type="button" class="button ghost ucopy-source" id="ucopy-mine"><strong>📁 One of my units</strong><small>Something you made earlier.</small></button></div><div class="row"><button type="button" class="button ghost" id="ucopy-cancel0">Cancel</button></div>');
    document.getElementById("ucopy-cancel0").onclick = closeDialog;
    document.getElementById("ucopy-game").onclick = () => { closeDialog(); ForgeGuideUI.pickUnit("Copy from which character?", (card) => load(() => gameDonor(card)), { sourceDatabase: dbOf(p), allVersions: true }); };
    document.getElementById("ucopy-mine").onclick = () => pickMine().catch((e) => toast(e.message, true));
  }
  async function pickMine() {
    const rows = (await Native.call("projects")).filter((r) => r.key !== state.project.key);
    if (!rows.length) return toast("You don't have another unit yet.", true);
    dialog("Copy from which of your units?", '<div class="ucopy-dialog" data-no-ai></div><label class="field">Find your unit<input id="ucopy-search" type="search" placeholder="Unit name…"></label><div class="guide-picks" id="ucopy-list"></div><div class="row"><button type="button" class="button ghost" id="ucopy-back0">← Back</button></div>');
    document.getElementById("ucopy-back0").onclick = () => open();
    const draw = () => {
      const q = document.getElementById("ucopy-search").value.trim().toLowerCase();
      const list = rows.filter((r) => !q || String(r.name).toLowerCase().includes(q));
      document.getElementById("ucopy-list").innerHTML = list.map((r) => '<button type="button" class="guide-pick" data-ucopy-key="' + html(r.key) + '"><span><strong>' + html(r.name) + "</strong><small>" + html(r.sourceName || "") + "</small></span></button>").join("") || "<p>No units match.</p>";
      document.querySelectorAll("[data-ucopy-key]").forEach((b) => b.onclick = () => load(() => myDonor(b.dataset.ucopyKey)));
    };
    document.getElementById("ucopy-search").oninput = draw;
    draw();
  }
  async function load(fetch) {
    const p = state.project;
    let d = null;
    await busy("Reading that unit", async () => { d = await fetch(); });
    if (!d) return;   // busy already showed what went wrong
    if (state.project !== p) return toast("Your unit changed. Start the copy again.", true);
    choose(d);
  }
  function choose(d, picked = new Set(), options = { passive: "add", supers: "replace" }) {
    const inv = inventory(d);
    dialog("Copy from " + d.name, '<div class="ucopy-dialog" data-no-ai></div><p>Tick what you want to copy onto your unit.</p><div class="ucopy-list">' + FEATURES.map(([key, label, help]) => {
      const it = inv[key], disabled = !it.ok;
      return '<label class="ucopy-item' + (disabled ? " off" : "") + '"><input type="checkbox" data-ucopy="' + key + '"' + (picked.has(key) && !disabled ? " checked" : "") + (disabled ? " disabled" : "") + '><span><strong>' + html(label) + '</strong><small>' + html(it.detail || help) + "</small>" + (it.warn ? '<small class="ucopy-warn">' + html(it.warn) + "</small>" : "") + "</span></label>" +
        (key === "passive" ? '<div class="ucopy-mode" data-ucopy-mode="passive"><label><input type="radio" name="ucopy-passive" value="add"' + (options.passive !== "replace" ? " checked" : "") + '> Add to my passive</label><label><input type="radio" name="ucopy-passive" value="replace"' + (options.passive === "replace" ? " checked" : "") + "> Replace my passive</label></div>" : "") +
        (key === "supers" ? '<div class="ucopy-mode" data-ucopy-mode="supers"><label><input type="radio" name="ucopy-supers" value="replace"' + (options.supers !== "add" ? " checked" : "") + '> Replace mine</label><label><input type="radio" name="ucopy-supers" value="add"' + (options.supers === "add" ? " checked" : "") + "> Add to mine</label></div>" : "");
    }).join("") + '</div><div class="row ucopy-quick"><button type="button" class="button ghost small" id="ucopy-kit">Pick the whole kit</button><button type="button" class="button ghost small" id="ucopy-none">Clear</button></div><div class="row"><button type="button" class="button" id="ucopy-preview">See the changes →</button><button type="button" class="button ghost" id="ucopy-cancel">Cancel</button></div>');
    const boxes = () => [...document.querySelectorAll("[data-ucopy]")];
    const sync = () => {
      const on = new Set(boxes().filter((b) => b.checked).map((b) => b.dataset.ucopy));
      document.querySelectorAll("[data-ucopy-mode]").forEach((m) => m.hidden = !on.has(m.dataset.ucopyMode));
      // a copied passive already contains the transformation; supers bring their own animations
      const t = document.querySelector('[data-ucopy="transform"]');
      if (t && inv.transform.ok) { t.disabled = on.has("passive"); if (on.has("passive")) t.checked = false; t.closest(".ucopy-item").classList.toggle("off", on.has("passive")); }
      document.getElementById("ucopy-preview").disabled = !on.size;
    };
    boxes().forEach((b) => b.onchange = sync);
    document.getElementById("ucopy-kit").onclick = () => { boxes().forEach((b) => { if (!b.disabled) b.checked = ["stats", "identity", "leader", "passive", "supers", "active", "standby", "links", "categories"].includes(b.dataset.ucopy); }); const r = document.querySelector('input[name="ucopy-passive"][value="replace"]'); if (r) r.checked = true; sync(); };
    document.getElementById("ucopy-none").onclick = () => { boxes().forEach((b) => { b.checked = false; }); sync(); };
    document.getElementById("ucopy-cancel").onclick = closeDialog;
    document.getElementById("ucopy-preview").onclick = () => {
      const on = new Set(boxes().filter((b) => b.checked && !b.disabled).map((b) => b.dataset.ucopy));
      const opts = { passive: (document.querySelector('input[name="ucopy-passive"]:checked') || {}).value || "add", supers: (document.querySelector('input[name="ucopy-supers"]:checked') || {}).value || "replace" };
      preview(d, on, opts).catch(e=>toast(e.message||String(e),true));
    };
    sync();
  }
  async function preview(d, picked, options) {
    ForgeGuideUI?.checkpoint?.();
    const p = state.project, before=JSON.stringify(p), result = await prepare(d, picked, options, p);
    if(state.project!==p||JSON.stringify(p)!==before)throw Error("Your unit changed while the copy was prepared. Start the copy again.");
    dialog("What will change", '<div class="ucopy-dialog" data-no-ai></div><p>From <strong>' + html(d.name) + "</strong> to <strong>" + html(Forge.card(p).name || "your unit") + '</strong>:</p><div class="ucopy-changes">' + result.changes.map(([what, from, to]) => '<div class="ucopy-change"><strong>' + html(what) + '</strong><span class="ucopy-from">' + html(from) + '</span><span class="ucopy-arrow" aria-hidden="true">↓</span><span class="ucopy-to">' + html(to) + "</span></div>").join("") + "</div>" +
      result.notes.map((n) => '<p class="hint">' + html(n) + "</p>").join("") + '<p class="hint">Nothing has changed yet. After applying, ↶ Undo takes it all back in one step.</p><div class="row"><button type="button" class="button" id="ucopy-apply">Apply to my unit</button><button type="button" class="button ghost" id="ucopy-back">← Back</button></div>');
    document.getElementById("ucopy-back").onclick = () => choose(d, picked, options);
    document.getElementById("ucopy-apply").onclick = async () => {
      if (state.project !== p || JSON.stringify(p)!==before) return toast("Your unit changed. Start the copy again.", true);
      ForgeGuideUI?.checkpoint?.();
      // fields the copy removed (e.g. custom artwork links) must go from your unit too
      for (const k of Object.keys(p)) if (!(k in result.work)) delete p[k];
      Object.assign(p, result.work);
      if (picked.has("art")) { state.previewUrl = ""; if (typeof projectPreviewUrl === "function") projectPreviewUrl(p).then((u) => { if (state.project === p) { state.previewUrl = u; if (typeof renderPreview === "function") renderPreview(); } }).catch(() => {}); }
      closeDialog();
      if (window.ForgeBuilderUI && ForgeBuilderUI.refreshTexts && state.builder) ForgeBuilderUI.refreshTexts();
      scheduleSave();
      ForgeGuideUI?.checkpoint?.();
      await flushSave();
      renderEditor();
      toast("Copied " + result.changes.length + " thing" + (result.changes.length === 1 ? "" : "s") + " from " + d.name + ". ↶ Undo takes it back.");
    };
  }
  // Toolbar button in the card builder, next to Presets.
  let queued = false;
  function inject() {
    queued = false;
    const tools = document.querySelector(".bld-tools");
    if (tools && !tools.querySelector(".ucopy-button") && !(state.project && state.project.awaken)) {
      const b = document.createElement("button");
      b.type = "button";
      b.className = "button ghost small ucopy-button";
      b.textContent = "⧉ Copy from a unit";
      b.onclick = () => open();
      (tools.querySelector(".shell-presets-button") || tools.querySelector('[data-b="ai-helper"]') || tools.firstChild)?.after(b);
    }
  }
  new MutationObserver(() => { if (!queued) { queued = true; requestAnimationFrame(inject); } }).observe(document.body, { childList: true, subtree: true });
  return { open, build, prepare, inventory, gameDonor, myDonor, FEATURES };
})();
