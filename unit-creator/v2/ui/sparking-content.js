(function(root) {
  "use strict";
  const SPARK_PAGE=120;
  let query="",offset=0,request=0,timer;
  async function mount(target) {
    if(!target)return;
    const owner=++request;
    target.innerHTML='<section class="panel"><h2>Sparking characters</h2><p role="status">Opening your Sparking collection…</p></section>';
    try {
      const info=await Native.call("sparkingInfo");
      if(owner!==request||!target.isConnected)return;
      target.innerHTML='<section class="panel"><h2>Sparking characters</h2><p>'+ (info.available?number(info.count)+' cards from the actual Sparking game database. Browse them offline and make an editable copy.':"Download the game's current character and skill database after importing the original Sparking 6.5.5 APK or its ZIP.")+'</p><p class="hint">The character download is about 113 MB and needs several hundred MB of free space. Character artwork, movies and other game resources are separate. Sparking additions may require matching assets and skills in Eclipse.</p><div class="row"><button class="button ghost" data-sparking-import>Import Sparking APK / ZIP</button>'+(info.keyConfigured?'<button class="button" data-sparking-download>'+(info.available?'Update characters':'Download characters')+'</button>':'')+'</div>'+(info.available?'<div class="source-controls"><label class="field">Find a Sparking character<input data-sparking-unit-search type="search" placeholder="Ultra Vegito, Piccolo…" value="'+esc(query)+'"></label></div><div data-sparking-units></div>':'')+'</section>';
      target.querySelector('[data-sparking-import]').onclick=()=>importFile().catch(e=>toast(e.message,true));
      const download=target.querySelector('[data-sparking-download]');
      if(download)download.onclick=async()=>{
        try { await databaseTask("Downloading Sparking characters",()=>Native.call("updateSparking"));offset=0;await mount(target);toast("Sparking characters are ready. Your Eclipse database and saved units were kept."); }
        catch(e){toast(e.message,true);}
      };
      if(info.available){
        const input=target.querySelector('[data-sparking-unit-search]');
        input.oninput=()=>{query=input.value;offset=0;clearTimeout(timer);timer=setTimeout(()=>list(target,info,owner),180);};
        await list(target,info,owner);
      }
    } catch(e) {if(owner===request&&target.isConnected)target.innerHTML='<section class="panel"><h2>Sparking characters</h2><p class="notice warning">'+esc(e.message)+'</p></section>';}
  }
  async function list(target,info,owner) {
    const area=target.querySelector('[data-sparking-units]');if(!area)return;
    const currentQuery=query,currentOffset=offset;
    try {
      const raw=await Native.call("querySparking",{table:"cards",search:{column:"name",text:currentQuery},offset:currentOffset,limit:SPARK_PAGE+1});
      // one entry per character: its fully awakened, playable card (EZA badges included)
      const more=raw.length>SPARK_PAGE,CV=window.ForgeCardVersions,rows=CV?await CV.collapse(raw.slice(0,SPARK_PAGE),{database:"sparking"}):raw;
      if(owner!==request||!target.isConnected||query!==currentQuery||offset!==currentOffset)return;
      const shown=rows;
      area.innerHTML='<p class="hint" role="status">'+(shown.length?shown.length+(shown.length===1?' character':' characters')+' · one per character, fully awakened':(more?'No fully awakened characters on this page — tap Next':'No matching characters'))+'</p><div class="unit-grid">'+shown.map(card=>'<article class="unit-tile"><div class="tile-body"><span class="chip teal">SPARKING SOURCE</span><h3>'+esc(card.name)+'</h3>'+(CV?CV.badge(card,'sparking'):'')+'<p>'+esc(Forge.rarities[card.rarity]||'Unit')+' · '+esc(Forge.elements[card.element]||'')+'</p><div class="row"><button class="button ghost small" data-sparking-copy="'+esc(card.id)+'">Create editable copy</button><button class="button subtle small" data-sparking-preview="'+esc(card.id)+'">Preview animations</button></div></div></article>').join('')+'</div><nav class="row" aria-label="Sparking character pages"><button class="button ghost" data-sparking-back'+(!offset?' disabled':'')+'>Previous</button><button class="button ghost" data-sparking-next'+(!more?' disabled':'')+'>Next</button></nav><p class="hint">This catalogue includes regular cards and Sparking additions. These are real game records, separate from the community reference guide. A new copy receives its own unit slot; live Eclipse compatibility is not implied.</p>';
      area.querySelector('[data-sparking-back]').onclick=()=>{offset=Math.max(0,offset-SPARK_PAGE);list(target,info,owner);};
      area.querySelector('[data-sparking-next]').onclick=()=>{offset+=SPARK_PAGE;list(target,info,owner);};
      area.querySelectorAll('[data-sparking-copy]').forEach(button=>button.onclick=()=>copy(Number(button.dataset.sparkingCopy),info).catch(e=>toast(e.message,true)));
      area.querySelectorAll('[data-sparking-preview]').forEach(button=>button.onclick=()=>browse(Number(button.dataset.sparkingPreview)).catch(e=>toast(e.message,true)));
    }catch(e){if(owner===request&&target.isConnected)area.innerHTML='<p class="notice warning">'+esc(e.message)+'</p>';}
  }
  async function browse(id) {
    await flushSave();
    Object.assign(studioState,{sourceDatabase:"sparking",unitId:id,offset:0,search:"",kind:"all",mode:"browse",tab:"characters",files:[],stamp:""});
    state.view="animations";updateNav();await renderStudio();window.scrollTo(0,0);
  }
  async function copy(id,info) {
    await flushSave();
    await busy("Preparing the Sparking character and skills",async()=>{
      state.projects=await Native.call("projects");
      const next=Forge.nextUnitId(state.projects,null,97000001);
      const project=await Forge.loadTemplate(options=>Native.call("querySparking",options),info.schema,id,next);
      project.source.database="sparking";
      project.provenance={sourceDatabase:"Sparking",sourceCardId:id,importedAt:new Date().toISOString(),sourceVersion:info.meta?.latestVersion};
      project.patch.name=project.source.name+" — Eclipse copy";
      project.patch.description="Based on Sparking source card "+id+". Original individual author was not recorded in the game database. Matching custom assets and Eclipse gameplay compatibility require verification.";
      project.sourceDependencies=await root.ForgeSparkingDependencies.collect(project,{sourceQuery:o=>Native.call("querySparking",o),targetQuery:o=>Native.call("query",o),sourceSchema:info.schema,targetSchema:state.info.schema});
      if(typeof studioState!=="undefined"){studioState.sourceDatabase="sparking";studioState.files=[];}
      state.project=project;state.step=0;state.previewUrl="";stashDraft();
      await flushSave();
    });
    state.view="editor";updateNav();renderEditor();window.scrollTo(0,0);
    toast("Editable Sparking copy saved. Review matching resources before installing its ECLP in Eclipse.");
  }
  async function prepare(project) {
    const info=await Native.call("sparkingInfo");
    if((project.provenance?.sourceVersion && info.meta?.latestVersion!==project.provenance.sourceVersion)||(project.sourceDependencies?.animations||[]).some(a=>a.version!==info.meta?.latestVersion)) {
      if(project.sourceDependencies)return project.sourceDependencies;
      throw Error("This older Sparking copy needs its original game data to prepare missing dependencies. Its saved design and attached files were kept.");
    }
    const previous=project.sourceDependencies, effectIds=previous?.effectIds||[];
    const origin=project.source?.database==="sparking"?project:{tables:{cards:[{id:1}]}};
    project.sourceDependencies=await root.ForgeSparkingDependencies.collect(origin,{sourceQuery:o=>Native.call("querySparking",o),targetQuery:o=>Native.call("query",o),sourceSchema:info.schema,targetSchema:state.info.schema,effectIds});
    project.sourceDependencies.effectIds=effectIds;
    if(previous?.animations?.length){project.sourceDependencies.animations=Forge.clone(previous.animations);project.sourceDependencies.issues.push({severity:"warning",code:"SCRIPT_AUDIO_UNSCANNED",message:"Imported animations still need their original helper, sound and voice resources checked before Eclipse gameplay."});for(const a of previous.animations)if(a.unresolved?.length)project.sourceDependencies.issues.push({severity:"warning",code:"ANIMATION_RESOURCES_UNRESOLVED",message:"Some original animation helper resources still need review before Eclipse gameplay."});}
    return project.sourceDependencies;
  }
  function projectPanel(project) {
    if(project?.source?.database!=="sparking"&&!project?.sourceDependencies?.animations?.length)return "";
    const issues=project.sourceDependencies?.issues||[],resourceNotes=[...(project.sparkingResources?.missing||[]).map(path=>"Original file unavailable: "+path),...(project.sparkingResources?.warnings||[])],count=Object.values(project.sourceDependencies?.tables||{}).reduce((n,rows)=>n+rows.length,0);
    return '<section class="panel" id="sparking-project-resources"><h2>Sparking game files</h2><p>'+count+' shared game records are included with their original identities. Your editable unit uses its own new slot.</p>'+(project.source?.database==="sparking"?'<button class="button ghost" id="sparking-unit-resources">Get matching game files</button>':'<p>Original effects from your chosen Sparking animations are attached. Your character stays in its original collection.</p>')+'<p class="hint">Downloads only what Sparking made itself (custom characters, moves, effects, stages) from Sparking. Original game files come from Eclipse instead, so nothing is downloaded twice. It keeps your attached replacements. Effects referenced inside scripts may need additional game files.</p>'+(project.sparkingResources?'<p class="hint">'+project.sparkingResources.files.length+' downloaded files attached to this unit.</p>':'')+(resourceNotes.length?'<details><summary>Files needing review ('+resourceNotes.length+')</summary><ul>'+resourceNotes.map(note=>'<li>'+esc(note)+'</li>').join('')+'</ul></details>':'')+(issues.length?'<details><summary>Compatibility notes ('+issues.length+')</summary><ul>'+issues.map(i=>'<li>'+esc(i.message)+'</li>').join('')+'</ul></details>':'')+'</section>';
  }
  function bindProject(target) {
    if(root.ForgeSparkingAudio&&!target.querySelector('[data-sparking-audio]')) {
      const section=target.querySelector('#sparking-project-resources');
      if(section){const audio=document.createElement('button');audio.className='button ghost';audio.dataset.sparkingAudio='';audio.textContent='Sound and voice files';audio.onclick=()=>root.ForgeSparkingAudio.open(state.project).catch(e=>toast(e.message,true));section.append(audio);}
    }
    const button=target.querySelector('#sparking-unit-resources');
    if(button)button.onclick=()=>resources(state.project).catch(e=>toast(e.message,true));
  }
  async function fetchPaths(required,version,existing=[]) {
    required=[...new Set(required)];
    const cached=new Set(existing.filter(a=>a.source==="sparking"&&a.sourceVersion===version).map(a=>a.path));
    required=required.filter(path=>!cached.has(path)&&!(path.endsWith(".cpk")&&cached.has("movie/en/"+path.replace(/\.cpk$/,".usm"))));
    const assets=[],warnings=[];
      const movies=required.filter(path=>/^ingame\/battle\/(effect|sp_effect)\/.+\.cpk$/.test(path)).map(path=>"movie/en/"+path.replace(/\.cpk$/,'.usm'));
      const all=[...new Set([...required,...movies])],available=new Set(),missing=[],fromEclipse=new Set();
      // Only Sparking's own custom-made files come from Sparking. Originals are Eclipse's copies, saved once
      // where previews find them (not attached, so this unit's ECLP stays small: Eclipse already has them).
      const SC=root.ForgeSparkingCustom,paths=[];
      for(const path of all){
        let original=false;
        try{original=SC?await SC.isOriginal(path):false;}catch(e){original=false;}
        if(!original){paths.push(path);continue;}
        try{await SC.fetchOriginal(path);fromEclipse.add(path);available.add(path);}
        catch(e){missing.push(path);}   // never fetched from Sparking: it's an original game file
      }
      for(let i=0;i<paths.length;i+=64){const found=await Native.call("findSparkingAssets",{version:version,paths:paths.slice(i,i+64)});found.available.forEach(path=>available.add(path));missing.push(...found.missing);}
      const toDownload=[...available].filter(path=>!fromEclipse.has(path));
      for(let i=0;i<toDownload.length;i+=8){const batch=await Native.call("downloadSparkingAssets",{version:version,paths:toDownload.slice(i,i+8)});assets.push(...batch.assets);warnings.push(...(batch.warnings||[]));}
      const missingRequired=missing.filter(path=>required.includes(path)&&!(path.endsWith('.cpk')&&available.has("movie/en/"+path.replace(/\.cpk$/,'.usm'))));
      return {assets:assets.map(asset=>({...asset,sourceVersion:version})),missing:missingRequired,warnings:[...new Set(warnings)],fromEclipse:[...fromEclipse]};
  }
  // Reused by saved units and temporary previews; downloading never changes the editor.
  async function fetchResources(project,extraSource) {

      const info=await Native.call("sparkingInfo"),options={sourceQuery:o=>Native.call("querySparking",o),targetQuery:o=>Native.call("query",o),sourceSchema:info.schema,targetSchema:state.info.schema};
      let plan=await root.ForgeSparkingDependencies.collect(project,options);
      const assets=[],warnings=[],effectIds=new Set(project.sourceDependencies?.effectIds||[]);
      const scriptPaths=[...new Set([...plan.assetPaths.filter(path=>path.endsWith('.lua')), ...(extraSource?.path ? ["lua/"+extraSource.path] : []), "lua/ab_script/common/common.lua"])];
      const common=await Native.call("animationSource",{path:"ab_script/common/common.lua",sourceDatabase:"sparking"});
      for(const path of scriptPaths){
        const original=path==="lua/ab_script/common/common.lua"?common:extraSource?.path===path.slice(4) ? extraSource : await Native.call("animationSource",{path:path.slice(4),sourceDatabase:"sparking"});
        assets.push({key:original.assetKey,path,sourcePath:path,size:original.size,sha256:original.sha256,source:"sparking"});
        // A shared helper is not an independently invoked character animation.
        if(path==="lua/ab_script/common/common.lua")continue;
        const inventory=root.ForgeSparkingScriptResources.inventory(original.text);
        const helper=root.ForgeSparkingHelperResources?await root.ForgeSparkingHelperResources.inventory(original.text,{commonText:common.text,commonSHA256:common.sha256}):null;
        for(const id of inventory.effectIds.concat(helper?.effectIds||[]))effectIds.add(id);
        if(helper?.verifiedCommonSHA256&&helper.complete){const resolved=new Set(helper.helperUses.map(use=>[use.command,use.line,use.column].join(':')));inventory.unresolved=inventory.unresolved.filter(item=>!resolved.has([item.command,item.line,item.column].join(':')));}
        if(helper?.unresolved?.length)inventory.unresolved.push(...helper.unresolved);
        if(inventory.unresolved.length)warnings.push("Some resources used by an animation could not be determined automatically. Its original file was kept; review it before Eclipse gameplay.");
      }
      plan=await root.ForgeSparkingDependencies.collect(project,{...options,effectIds:[...effectIds]});
      plan.effectIds=[...effectIds];
      if(project.sourceDependencies?.animations?.length)plan.animations=Forge.clone(project.sourceDependencies.animations);
      const card=Forge.card(project),resource=card.resource_id||project.source.resourceId,character=String(card.character_id||"").padStart(5,"0");
      const required=[...new Set([...plan.assetPaths.filter(path=>!path.endsWith('.lua')),"character/card/"+resource+".cpk","character/card_bg/"+resource+".cpk","character/thumb/card_"+resource+"_thumb.png",...(card.character_id?["ingame/battle/character/"+character+".cpk","script/image/character/"+character+".cpk"]:[])])];
      const downloaded=await fetchPaths(required,project.provenance?.sourceVersion,project.assets||[]);
      return {plan,assets:[...assets,...downloaded.assets],missing:downloaded.missing,warnings:[...new Set([...warnings,...downloaded.warnings])]};
  }

  async function preview(entry,source) {
    const info=await Native.call("sparkingInfo"),id=Number(entry.unitId||1000010);
    if(!Number.isSafeInteger(id)||id<=0)throw Error("Choose a character for this animation.");
    const project=await Forge.loadTemplate(o=>Native.call("querySparking",o),info.schema,id,97000001);
    project.source.database="sparking";project.provenance={sourceVersion:info.meta?.latestVersion};
    const result=await fetchResources(project,source);
    project.assets=result.assets;
    if(result.missing.length||result.warnings.length)toast("Available original files are ready. Some animation resources could not be resolved; the preview may be incomplete.");
    return {...root.ForgePreviewBindings.request(project),name:source.label,path:source.path,text:source.text,assetKey:source.assetKey};
  }
  async function checkEclipseAnimation(project,source) {
    if(project.source?.database!=="sparking"||(source.sourceDatabase||source.catalog?.sourceDatabase)!=="eclipse")return;
    const inventory=ForgeSparkingScriptResources.inventory(source.text),clean=row=>JSON.stringify(Object.fromEntries(Object.entries(row||{}).filter(([key])=>!["created_at","updated_at"].includes(key)).sort(([a],[b])=>a.localeCompare(b))));
    const effects=new Set(inventory.effectIds);
    if(root.ForgeSparkingHelperResources){
      const [original,donor]=await Promise.all([Native.call("animationSource",{path:"ab_script/common/common.lua",sourceDatabase:"eclipse",originalOnly:true}),Native.call("animationSource",{path:"ab_script/common/common.lua",sourceDatabase:"sparking"})]);
      if(original.text!==donor.text)throw Error("These game collections use different shared animation helpers. Use matching source data before combining them.");
      const helper=await root.ForgeSparkingHelperResources.inventory(source.text,{commonText:original.text,commonSHA256:original.sha256});
      for(const id of helper.effectIds)effects.add(id);
    }
    for(const id of effects){
      const [from,to]=await Promise.all([Native.call("query",{table:"effect_packs",filters:{id},limit:1}),Native.call("querySparking",{table:"effect_packs",filters:{id},limit:1})]);
      if(!from[0]||!to[0]||clean(from[0])!==clean(to[0]))throw Error("This animation uses different effects in the two game collections. Choose a matching move or start from an Eclipse character; your current unit was kept.");
    }
  }
  async function ensureAnimations(project) {
    const clips=[...(project.animationStudio?.clips||[]),...Object.values(project.animationAssignments||{}).flatMap(a=>a.clips||[]),...(project.actionHooks?.dodge?.clips||[])],seen=new Set();
    for(const clip of clips) {
      const source=clip.source,identity=(source?.path||"")+"\0"+(source?.text||"");if(seen.has(identity))continue;seen.add(identity);
      if((source?.sourceDatabase||source?.catalog?.sourceDatabase)==="sparking") {
        const prepared=(project.sourceDependencies?.animations||[]).some(a=>a.path===source.path&&a.sha256===source.sha256);
        if(!prepared)await attachAnimation(project,source);
      }else if(source)await checkEclipseAnimation(project,source);
    }
  }
  async function attachAnimation(project,source,{persist=true,isCurrent=()=>typeof studioOwner==='function'?studioOwner()===project:state.project===project}={}) {
    if((source.sourceDatabase||source.catalog?.sourceDatabase)!=="sparking")return;
    const before=JSON.stringify(project),info=await Native.call("sparkingInfo"),version=info.meta?.latestVersion;
    const donor=await Native.call("animationSource",{path:"ab_script/common/common.lua",sourceDatabase:"sparking"});
    // Compare originals before collecting helper resources; never overwrite global Lua.
    if(project.source?.database!=="sparking") {
      const original=await Native.call("animationSource",{path:"ab_script/common/common.lua",sourceDatabase:"eclipse",originalOnly:true});
      if(original.text!==donor.text)throw Error("These game collections use different shared animation helpers. Choose a compatible animation or start from a Sparking character; your design was kept.");
    }
    const plan=await root.ForgeSparkingAnimationImport.plan(project,source,{sourceQuery:o=>Native.call("querySparking",o),targetQuery:o=>Native.call("query",o),sourceSchema:info.schema,targetSchema:state.info.schema,version,commonSource:donor});
    const error=plan.issues.find(i=>i.severity==="error");if(error)throw Error(error.message);
    const downloaded=await fetchPaths(plan.assetPaths.filter(path=>!path.endsWith('.lua')),version,project.assets||[]);
    if(downloaded.missing.length)throw Error("Some original files for this animation are unavailable. Choose another compatible move; your current unit was kept.");
    const merged=root.ForgeSparkingAnimationImport.merge(project.sourceDependencies,plan);
    const owned=new Map((project.assets||[]).map(a=>[a.path,a]));
    for(const asset of downloaded.assets){const prior=owned.get(asset.path);if(prior?.source==="sparking"&&prior.sha256&&prior.sha256!==asset.sha256)throw Error("Two selected animations use different versions of the same game file. Use matching versions before combining them.");}
    if(!isCurrent()||JSON.stringify(project)!==before)throw Error("Your unit changed while this animation was prepared. Its downloaded files remain in Assets; choose the move again.");
    project.assets=project.assets||[];for(const asset of downloaded.assets)if(!owned.has(asset.path)){project.assets.push(asset);owned.set(asset.path,asset);}
    project.sourceDependencies=merged;
    if(plan.issues.length||downloaded.warnings.length)toast("Original animation files attached. Some helper or audio resources still need review before Eclipse gameplay.");
    if(persist){if(window.ForgeAnimationGallery?.current()===project)ForgeAnimationGallery.changed();else scheduleSave();}
  }
  async function resources(project) {
    const original=JSON.stringify(project);
    const result=await databaseTask("Getting the original Sparking game files",()=>fetchResources(project));
    if(state.project!==project||JSON.stringify(project)!==original)throw Error("This unit changed while its files downloaded. The downloaded files are kept under Assets; attach them to the current design there.");
    const occupied=new Set((project.assets||[]).map(a=>a.path));project.assets=project.assets||[];
    for(const asset of result.assets)if(!occupied.has(asset.path)){project.assets.push(asset);occupied.add(asset.path);}
    project.sourceDependencies=result.plan;
    project.sparkingResources={version:project.provenance?.sourceVersion,files:project.assets.filter(a=>a.source==="sparking").map(a=>({path:a.path,sha256:a.sha256})),missing:result.missing,warnings:result.warnings};
    if(!project.previewKey){const thumb=project.assets.find(a=>a.source==="sparking"&&a.path.endsWith('_thumb.png'));if(thumb)project.previewKey=thumb.key;}
    scheduleSave();await flushSave();state.previewUrl=await projectPreviewUrl(project);renderEditor();
    toast(result.missing.length||result.warnings.length?"Available original files attached. Some files still need review under Sparking game files.":"Sparking's custom files attached (they go in this unit's ECLP). Original game files come from Eclipse.");
  }
  root.ForgeSparkingContent={fetchPaths,mount,prepare,resources,preview,attachAnimation,checkEclipseAnimation,ensureAnimations,projectPanel,bindProject,create:async id=>copy(id,await Native.call("sparkingInfo"))};
})(window);
