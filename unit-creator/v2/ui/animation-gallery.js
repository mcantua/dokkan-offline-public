/* Animation documents live independently of card projects. Media stays in the
 * app's asset store; assigning a document copies its editable resources. */
(function(){
 'use strict';
 const FORMAT='dokkan-animation-gallery',DB='forge-animation-gallery',VERSION=1;
 let active=null,owner=null,database=null,dirty=false,timer=null,queue=Promise.resolve(),revision=0,lastDeleted=null,past=[],future=[],lastSnapshot=null;
 const clone=value=>Forge.clone(value),h=esc;
 const id=()=>crypto.randomUUID?.()||('animation-'+Date.now().toString(36)+'-'+Math.random().toString(36).slice(2));
 function db(){
  if(database)return database;
  database=new Promise((resolve,reject)=>{
   const request=indexedDB.open(DB,VERSION);
   request.onupgradeneeded=()=>{const d=request.result;d.createObjectStore('animations',{keyPath:'key'});d.createObjectStore('settings');};
   request.onsuccess=()=>{const d=request.result;d.onversionchange=()=>{d.close();database=null;};resolve(d);};
   request.onerror=()=>{database=null;reject(Error('Your animation gallery could not be opened. Your current edits are still here.'));};
  });return database;
 }
 async function transaction(mode,work){
  const d=await db();return new Promise((resolve,reject)=>{const tx=d.transaction(['animations','settings'],mode);let result;tx.oncomplete=()=>resolve(typeof result==='function'?result():result);tx.onerror=tx.onabort=()=>reject(Error('Your animation could not be saved. Keep it open and free some device storage, then try again.'));try{result=work(tx.objectStore('animations'),tx.objectStore('settings'));}catch(e){tx.abort();reject(e);}});
 }
 async function read(key){return transaction('readonly',store=>{const r=store.get(key);return ()=>r.result;});}
 async function list(){await flush();return transaction('readonly',store=>{const r=store.getAll();return ()=>r.result.filter(a=>!a.deletedAt).sort((a,b)=>b.updatedAt.localeCompare(a.updatedAt));});}
 function current(){return state.view==='animations'?active:null;}
 function status(text){if(state.view==='animations'&&active&&$('#save-state'))$('#save-state').textContent=text;}
 function resetHistory(){past=[];future=[];lastSnapshot=active?clone(active):null;}
 function changed(record=true){if(!active)return;if(record&&lastSnapshot){past.push(lastSnapshot);if(past.length>20)past.shift();future=[];}lastSnapshot=clone(active);active.updatedAt=new Date(Math.max(Date.now(),Date.parse(active.updatedAt||0)+1||0)).toISOString();revision++;dirty=true;status('Saving animation…');clearTimeout(timer);timer=setTimeout(()=>flush().catch(e=>{status('Animation not saved');toast(e.message,true);}),400);}
 async function flush(){
  clearTimeout(timer);
  if(active&&dirty){const doc=active,snapshot=clone(active),version=revision;dirty=false;
   queue=queue.catch(()=>{}).then(()=>transaction('readwrite',(store,settings)=>{store.put(snapshot);settings.put(snapshot.key,'current');})).then(()=>{if(active===doc&&revision===version)status('Animation saved');}).catch(e=>{if(active===doc)dirty=true;throw e;});
  }return queue;
 }
 function fresh(){const now=new Date().toISOString();return {format:FORMAT,version:1,key:id(),createdAt:now,updatedAt:now,draft:true,targetId:1800000000+Math.floor(Math.random()*90000000),source:{database:'eclipse'},schema:{effect_packs:clone(state.info.schema.effect_packs||[])},tables:{effect_packs:[]},assets:[],movieBindings:[],animationStudio:{clips:[],name:'My animation',purpose:'super',target:'',dirty:true}};}
 function validate(doc){if(doc?.format!==FORMAT||doc.version!==1||typeof doc.key!=='string'||!Array.isArray(doc.animationStudio?.clips)||!Array.isArray(doc.assets)||!doc.tables||!doc.schema)throw Error('This saved animation could not be opened.');return doc;}
 async function create(){return studioBusy('Starting an animation',async()=>{await flush();await flushSave();active=fresh();owner=state.project?.key||null;resetHistory();dirty=true;revision++;state.studioTarget=null;Object.assign(studioState,{search:'',kind:'all',offset:0,unitId:0,tab:'characters',sourceDatabase:'eclipse'});await flush();state.view='animations';updateNav();await renderStudio();});}
 async function restore(){if(active)return active;owner=state.project?.key||null;const key=await transaction('readonly',(_store,settings)=>{const r=settings.get('current');return ()=>r.result;});const saved=key?await read(key):null;active=saved&&!saved.deletedAt?validate(saved):fresh();resetHistory();dirty=!saved||!!saved.deletedAt;revision++;if(dirty)await flush();return active;}
 async function exit(){await flush();active=null;owner=null;resetHistory();dirty=false;revision++;}
 async function open(key){return studioBusy('Opening your animation',async()=>{await flush();const doc=validate(await read(key));if(doc.deletedAt)throw Error('This animation was removed from the gallery.');active=clone(doc);owner=state.project?.key||null;resetHistory();dirty=true;revision++;state.studioTarget=null;state.view='animations';studioState.sourceDatabase=doc.source?.database||'eclipse';await flush();updateNav();return renderStudio();});}
 function snapshot(unit){const doc=fresh();doc.targetId=unit.targetId;doc.source={database:unit.source?.database||'eclipse'};doc.provenance=clone(unit.provenance||{});doc.animationStudio=clone(unit.animationStudio);doc.animationStudio.target='';doc.schema.effect_packs=clone(unit.schema.effect_packs||state.info.schema.effect_packs||[]);doc.tables.effect_packs=clone(unit.tables.effect_packs||[]);doc.movieBindings=clone(unit.movieBindings||[]);doc.assets=clone((unit.assets||[]).filter(a=>a.owner==='forge-sequence-music'&&a.path===unit.animationStudio?.music?.path||a.owner===ForgeMovieModel.OWNER||a.source==='sparking'));if(unit.sourceDependencies)doc.sourceDependencies=clone(unit.sourceDependencies);return doc;}
 async function save(){
  const owner=studioOwner(),sequence=studioProject();if(!sequence?.clips.length)throw Error('Add a clip before saving to My animations.');
  if(!sequence.name?.trim())throw Error('Give your animation a name.');
  const errors=ForgeMotion.validate(sequence.clips);if(errors.length)throw Error(errors[0]);
  if(active){active.draft=false;changed();await flush();}
  else {const doc=snapshot(owner);doc.draft=false;await transaction('readwrite',store=>store.put(doc));}
  toast('Saved to My animations. You can use it on any unit.');
 }
 async function commitPrepared(next){
  if(!active||next.key!==active.key||next.targetId!==active.targetId)throw Error('Your animation changed. Open its movie editor again.');
  const original=active,before=JSON.stringify(original);
  validate(next);const errors=ForgeMotion.validate(next.animationStudio.clips);if(errors.length)throw Error(errors[0]);
  if(!next.animationStudio.name?.trim())throw Error('Give your animation a name.');
  await flush();if(active!==original||JSON.stringify(active)!==before)throw Error('Your animation changed. Prepare the save again.');const snapshot=clone(next);
  snapshot.draft=false;snapshot.updatedAt=new Date(Math.max(Date.now(),Date.parse(original.updatedAt)+1)).toISOString();
  const pending=queue.catch(()=>{}).then(()=>{if(active!==original||JSON.stringify(active)!==before)throw Error('Your animation changed. Prepare the save again.');return transaction('readwrite',(store,settings)=>{store.put(snapshot);settings.put(snapshot.key,'current');});});
  queue=pending.catch(()=>{});await pending;
  if(active!==original||JSON.stringify(active)!==before)return {saved:true,current:false};
  past.push(clone(original));if(past.length>20)past.shift();future=[];active=clone(snapshot);lastSnapshot=clone(active);revision++;dirty=false;status('Animation saved');
  return {saved:true,current:true};
 }
 async function prepareSource(owner,source){
  if(owner.format!==FORMAT)return;
  if(!owner.animationStudio.clips.length){const sparking=(source.sourceDatabase||source.catalog?.sourceDatabase)==='sparking';owner.source.database=sparking?'sparking':'eclipse';if(sparking){const info=await Native.call('sparkingInfo');owner.provenance={sourceVersion:info.meta?.latestVersion};}}
 }
 function previewRequest(owner){
  if(owner?.format!==FORMAT)return ForgePreviewBindings.request(owner);
  const clips=owner.animationStudio.clips,actor=Number(clips.find(c=>Number(c.source.catalog?.unitId)>0)?.source.catalog.unitId)||1000010;
  const assets=[...ForgeMovieModel.previewAssets(owner),...(owner.assets||[]).filter(a=>a.owner==='forge-sequence-music'||a.source==='sparking').map(a=>({path:a.path,key:a.key}))],seen=new Map();
  for(const a of assets){const prior=seen.get(a.path);if(prior&&prior.key!==a.key)throw Error('Two animation resources use the same path. Choose compatible clips.');seen.set(a.path,a);}
  const dependencies=owner.sourceDependencies?.animations||[],versions=[...new Set(dependencies.map(a=>a.version))];if(versions.length>1)throw Error('Choose clips from one matching Sparking version.');
  return {attackerId:actor,enemyId:actor===1000020?1000010:1000020,assets:[...seen.values()],effectPacks:ForgeMovieModel.previewRows(owner),...(owner.source.database==='sparking'?{sourceDatabase:'sparking'}:{}),...(versions.length?{sparkingVersion:versions[0],sparkingEffectIds:[...new Set(dependencies.flatMap(a=>a.effectIds||[]))]}:{})};
 }
 async function copyToUnit(doc,unit,target=''){
  validate(doc);await flush();await flushSave();
  if(state.project!==unit)throw Error('The selected unit changed. Choose it again.');
  const before=JSON.stringify(unit),next=clone(unit),sequence=clone(doc.animationStudio);
  sequence.clips=ForgeMovieModel.copyClips(doc,next,sequence.clips);
  const assets=new Map((next.assets||[]).map(a=>[a.path,a]));
  for(const a of doc.assets||[])if(a.owner==='forge-sequence-music'&&a.path===sequence.music?.path||a.source==='sparking'){const prior=assets.get(a.path);if(prior&&prior.key!==a.key)throw Error('This unit already uses a different version of an animation resource.');if(!prior){next.assets.push(clone(a));assets.set(a.path,a);}}
  const current=()=>state.project===unit&&JSON.stringify(unit)===before;
  for(const c of sequence.clips){await ForgeSparkingContent.attachAnimation(next,c.source,{persist:false,isCurrent:current});await ForgeSparkingContent.checkEclipseAnimation(next,c.source);}
  if(!current())throw Error('Your unit changed while the animation loaded. Select it again.');
  sequence.target=ForgeGuide.targets(next).some(t=>t.key===target)?target:'';sequence.dirty=true;next.animationStudio=sequence;
  await exit();Object.assign(unit,next);state.studioTarget=sequence.target||null;state.view='animations';studioState.mode='compose';updateNav();scheduleSave();await flushSave();await renderStudio();studioAssignDialog();
 }
 async function chooseUnit(doc){
  await flushSave();const units=await Native.call('projects');
  dialog('Choose a unit for this animation','<p>'+h(doc.animationStudio.name)+'</p><label class="field">Find your unit<input type="search" id="gallery-unit-search" placeholder="Unit name or custom ID…"></label><div id="gallery-units"></div>');
  const draw=()=>{const rows=units.filter(u=>ForgeSequence.matches(u.name+' '+u.targetId,$('#gallery-unit-search').value));$('#gallery-units').innerHTML=rows.length?rows.map(u=>'<button type="button" class="sequence-unit-choice" data-gallery-unit="'+h(u.key)+'"><strong>'+h(u.name)+'</strong><span>'+h(u.sourceName?'Based on '+u.sourceName:'Your unit')+'</span></button>').join(''):'<p>No saved units match. Create a unit, then choose this animation from its move settings.</p>';document.querySelectorAll('[data-gallery-unit]').forEach(b=>b.onclick=async()=>{try{b.disabled=true;await flushSave();if(ForgeFormsUI.active())await ForgeFormsUI.leave('editor');await openUnit(b.dataset.galleryUnit);$('#dialog').close();await copyToUnit(doc,state.project);}catch(e){b.disabled=false;toast(e.message,true);}});};$('#gallery-unit-search').oninput=draw;draw();
 }
 async function undo(redo=false){if(!active)return;const from=redo?future:past,to=redo?past:future;if(!from.length)return;to.push(clone(active));active=from.pop();changed(false);return renderStudio();}
 async function duplicate(key){const doc=clone(validate(await read(key)));doc.key=id();doc.createdAt=doc.updatedAt=new Date().toISOString();doc.animationStudio.name+=' copy';doc.draft=true;delete doc.deletedAt;await transaction('readwrite',store=>store.put(doc));return doc.key;}
 async function remove(key){await flush();const doc=validate(await read(key));doc.deletedAt=new Date().toISOString();await transaction('readwrite',store=>store.put(doc));if(active?.key===key){active=fresh();resetHistory();dirty=false;if(state.view==='animations')await renderStudio();}lastDeleted=key;}
 async function undoRemove(){if(!lastDeleted)return;const doc=validate(await read(lastDeleted));delete doc.deletedAt;await transaction('readwrite',store=>store.put(doc));lastDeleted=null;}
 async function show({unit=null,target=''}={}){
  const rows=await list();let busy=false;
  dialog(unit?'Choose from My animations':'My animations','<div class="row"><button class="button" id="gallery-new">New animation</button>'+(lastDeleted?'<button class="button ghost" id="gallery-undo">Undo removal</button>':'')+'</div><label class="field">Find an animation<input type="search" id="gallery-search" placeholder="Name, character, attack or song…"></label><div id="animation-gallery-list"></div>');
  const run=fn=>async()=>{if(busy)return;busy=true;const controls=[...document.querySelectorAll('[data-gallery-action],#gallery-new,#gallery-undo,#gallery-search')].map(e=>[e,e.disabled]);for(const [e]of controls)e.disabled=true;try{await fn();}catch(e){toast(e.message,true);}finally{busy=false;for(const [e,disabled]of controls)if(e.isConnected)e.disabled=disabled;}};
  $('#gallery-new').onclick=run(async()=>{$('#dialog').close();await create();});
  if($('#gallery-undo'))$('#gallery-undo').onclick=run(async()=>{await undoRemove();return show({unit,target});});
  const draw=()=>{const query=$('#gallery-search').value,found=rows.filter(doc=>ForgeSequence.matches([doc.animationStudio.name,doc.animationStudio.music?.title,...doc.animationStudio.clips.map(c=>c.label+' '+(c.source.catalog?.unitName||'')+' '+(c.source.catalog?.moveName||''))].join(' '),query));
   $('#animation-gallery-list').innerHTML=found.length?'<div class="animation-gallery-grid">'+found.map(doc=>{const s=doc.animationStudio,total=ForgeSequence.timeline(s.clips).slice(-1)[0]?.end||0;return '<article class="animation-gallery-card"><h3>'+h(s.name)+'</h3><p>'+s.clips.length+' clips · '+ForgeSequence.clock(total)+(doc.draft?' · Draft':'')+'</p><p class="hint">'+h(s.music?.title||'Scene audio')+'</p><div class="row"><button class="button ghost small" data-gallery-action="edit" data-key="'+h(doc.key)+'">Edit</button><button class="button small" data-gallery-action="use" data-key="'+h(doc.key)+'"'+(!s.clips.length?' disabled':'')+'>Use on '+(unit?'this unit':'a unit')+'</button><button class="button ghost small" data-gallery-action="preview" data-key="'+h(doc.key)+'"'+(!s.clips.length?' disabled':'')+'>Preview</button></div><details class="beginner-details"><summary>More</summary><div class="row"><button class="button ghost small" data-gallery-action="copy" data-key="'+h(doc.key)+'">Make a copy</button><button class="button subtle small" data-gallery-action="remove" data-key="'+h(doc.key)+'">Remove</button></div></details></article>';}).join('')+'</div>':'<p>No animations found. Choose New animation to start without a unit.</p>';
   document.querySelectorAll('[data-gallery-action]').forEach(b=>b.onclick=run(async()=>{const doc=validate(await read(b.dataset.key));switch(b.dataset.galleryAction){case 'edit':$('#dialog').close();return open(doc.key);case 'preview':return Native.call('previewAnimation',{name:doc.animationStudio.name,text:ForgeMotion.compile(doc.animationStudio.clips,{damage:false,music:doc.animationStudio.music}),...previewRequest(doc)});case 'use':$('#dialog').close();return unit?copyToUnit(doc,unit,target):chooseUnit(doc);case 'copy':await duplicate(doc.key);return show({unit,target});case 'remove':await remove(doc.key);return show({unit,target});}}));
  };$('#gallery-search').oninput=draw;draw();
 }
 const previousFlush=flushSave;
 flushSave=async function(){await flush();return previousFlush();};
 addEventListener('pagehide',()=>{flush().catch(()=>{});});
 document.addEventListener('visibilitychange',()=>{if(document.hidden)flush().catch(()=>{});});
 // The unit that was open when the independent animation was started; opening another unit
 // returns the editor to that unit's own animations.
 const ownerKey=()=>owner;
 window.ForgeAnimationGallery={FORMAT,current,ownerKey,restore,create,open,exit,changed,flush,list,read,save,commitPrepared,previewRequest,prepareSource,undo,copyToUnit,chooseUnit,show,duplicate,remove};
})();
