/* Animation documents live independently of card projects. Media stays in the
 * app's asset store; assigning a document copies its editable resources. */
(function(){
 'use strict';
 const FORMAT='dokkan-animation-gallery',DB='forge-animation-gallery',VERSION=1;
 let active=null,owner=null,database=null,dirty=false,timer=null,queue=Promise.resolve(),revision=0,lastDeleted=null,past=[],future=[],lastSnapshot=null,reconciling=null,importing=false;
 const clone=value=>Forge.clone(value),h=esc;
 const id=()=>crypto.randomUUID?.()||('animation-'+Date.now().toString(36)+'-'+Math.random().toString(36).slice(2));
 const BACKUP='dokkan-animation-backup',MAX_RESOURCES=64*1024*1024,MAX_DOCUMENT=8*1024*1024;
 const resourceExtension=/\.(png|jpg|jpeg|webp|gif|bmp|lwf|lua|usm|ogg|mp3|m4a|aac|wav|flac|awb|acb|atlas|plist|json|xml|tmx|bytes|cpk|fsh|vsh|fnt|ttf|otf|strings|txt|bin)$/i;
 const backupPath=p=>/^resources\/[1-9][0-9]{0,2}\.[a-z0-9]+$/.test(p)&&Number(p.split('/')[1].split('.')[0])<=256&&resourceExtension.test(p);
 function portable(doc){
  validate(doc);
  const allowed=['format','version','key','createdAt','updatedAt','draft','targetId','source','schema','tables','assets','movieBindings','animationStudio','provenance','sourceDependencies'];
  const next=Object.fromEntries(allowed.filter(k=>Object.prototype.hasOwnProperty.call(doc,k)).map(k=>[k,clone(doc[k])])),seen={count:0};
  function inspect(value,depth=0){if(depth>32||++seen.count>100000)throw Error('This animation is too deeply nested or complex to back up.');if(value&&typeof value==='object')for(const [key,item]of Object.entries(value)){if(/^(?:__proto__|prototype|constructor|password|api[_-]?key|access[_-]?token|refresh[_-]?token|secret|signing[_-]?key|sparking[_-]?key|credentials)$/i.test(key))throw Error('Connection details and private keys cannot be stored in an animation backup.');inspect(item,depth+1);}}
  inspect(next);
  if(!Number.isSafeInteger(next.targetId)||next.targetId<1||next.targetId>1999999000||!['eclipse','sparking'].includes(next.source?.database)||typeof next.animationStudio.name!=='string'||!next.animationStudio.name.trim()||next.animationStudio.name.length>120||next.animationStudio.clips.length>24||next.assets.length>256)throw Error('This animation has unsupported identity, name or resource data.');
  const errors=ForgeMotion.validate(next.animationStudio.clips);if(errors.length)throw Error(errors[0]);
  if(Object.keys(next.tables).some(k=>k!=='effect_packs')||Object.keys(next.schema).some(k=>k!=='effect_packs'))throw Error('Animation backups cannot contain unit or database tables.');
  if(!Array.isArray(next.tables.effect_packs)||next.tables.effect_packs.length>48||!Array.isArray(next.schema.effect_packs)||!Array.isArray(next.movieBindings)||next.movieBindings.length>48)throw Error('This animation has unsupported movie resources.');
  const paths=new Set();for(const asset of next.assets){if(!asset||!Forge.safePath(asset.path)||!resourceExtension.test(asset.path)||/\.(?:db|sqlite|sql)$/i.test(asset.path)||/(?:^|\/)(?:_databases|credentials|secrets|signing|ai-connections|sprk-format-key|sparking-database-format|key-info)(?:\/|\.|$)/i.test(asset.path)||paths.has(asset.path)||typeof asset.key!=='string'||!Forge.safePath(asset.key))throw Error('Animation resources must have unique safe game paths.');paths.add(asset.path);}
  if(new TextEncoder().encode(JSON.stringify(next)).length>MAX_DOCUMENT)throw Error('Animation editing data exceeds the 8 MiB backup limit.');
  return next;
 }
 function remap(value,mapping){if(typeof value==='string')return Object.prototype.hasOwnProperty.call(mapping,value)?mapping[value]:value;if(Array.isArray(value))return value.map(item=>remap(item,mapping));if(value&&typeof value==='object')return Object.fromEntries(Object.entries(value).map(([key,item])=>[key,remap(item,mapping)]));return value;}
 function resourceKeys(doc){const keys=new Set(doc.assets.map(a=>a.key));function visit(value){if(!value||typeof value!=='object')return;for(const [key,item]of Object.entries(value)){if(key==='assetKey'&&typeof item==='string'&&item)keys.add(item);else visit(item);}}visit(doc.animationStudio);return [...keys];}
 async function resourceBytes(key,remaining){
  if(!Forge.safePath(key)||!resourceExtension.test(key)||/(?:^|\/)(?:_databases|credentials|secrets|signing)(?:\/|\.)/i.test(key))throw Error('This animation references an unsupported or private resource.');
  const address=await Native.call('assetUrl',{key}),url=new URL(address,location.href);
  if(url.protocol!=='blob:'&&url.origin!==location.origin)throw Error('Animation backups can read only files already stored in this app.');
  const response=await fetch(address);if(!response.ok)throw Error('An animation resource is missing. Restore its original file before making a backup.');
  const size=Number(response.headers.get('content-length'));if(size>remaining)throw Error('Animation resources exceed the 64 MiB backup limit.');
  const reader=response.body?.getReader(),chunks=[];let bytes=0;
  if(reader)try{while(true){const part=await reader.read();if(part.done)break;bytes+=part.value.length;if(bytes>remaining){await reader.cancel();throw Error('Animation resources exceed the 64 MiB backup limit.');}chunks.push(part.value);}}finally{reader.releaseLock();}
  else{const chunk=new Uint8Array(await response.arrayBuffer());bytes=chunk.length;if(bytes>remaining)throw Error('Animation resources exceed the 64 MiB backup limit.');chunks.push(chunk);}
  if(!bytes)throw Error('An animation resource is empty.');const data=new Uint8Array(bytes);let at=0;for(const chunk of chunks){data.set(chunk,at);at+=chunk.length;}return data;
 }
 async function exportBackup(doc=current()){
  if(!doc)throw Error('Open an animation before saving its backup.');await flush();
  const copy=portable(doc),keys=resourceKeys(copy),mapping={},resources=[],entries=[];let total=0;
  if(keys.length>256)throw Error('Use up to 256 resource files in one animation backup.');
  if(!crypto.subtle)throw Error('This browser needs secure file checks before it can make an animation backup.');
  for(let i=0;i<keys.length;i++){const key=keys[i],extension=key.match(resourceExtension)?.[1].toLowerCase();if(!extension)throw Error('This animation references an unsupported file.');const path='resources/'+(i+1)+'.'+extension,bytes=await resourceBytes(key,MAX_RESOURCES-total);total+=bytes.length;const hash=new Uint8Array(await crypto.subtle.digest('SHA-256',bytes));resources.push({path,bytes:bytes.length,sha256:[...hash].map(n=>n.toString(16).padStart(2,'0')).join('')});mapping[key]=path;entries.push({path,assetKey:key});}
  const document=remap(copy,mapping);document.animationStudio.target='';
  const text=JSON.stringify({format:BACKUP,version:1,document,resources});if(new TextEncoder().encode(text).length>MAX_DOCUMENT)throw Error('Animation editing data exceeds the 8 MiB backup limit.');
  const name=(copy.animationStudio.name.replace(/[\\/:*?"<>|\x00-\x1f]/g,'_').trim()||'My animation').slice(0,100)+'-animation.zip';
  const result=await Native.call('export',{kind:'zip',name,entries:[{path:'animation.json',text},...entries]});
  if(result?.saved)toast('Animation backup saved with '+resources.length+' resource file'+(resources.length===1?'':'s')+'.');return result;
 }
 async function importBackup(){
  if(importing)throw Error('Finish the current animation import first.');
  await flush();await flushSave();await reconcileImports();importing=true;let result,saved=false;
  try{
   result=await Native.call('importAnimationBackup');if(!result||result.canceled||result.cancelled||!result.document)return;
   if(!/^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$/.test(result.importToken||''))throw Error('Update the app before importing animation resources safely.');
   let doc=portable(result.document);const mapping=result.resources;
   if(!mapping||typeof mapping!=='object'||Object.keys(mapping).length>256||resourceKeys(doc).some(key=>!backupPath(key)||typeof mapping[key]!=='string'||!Forge.safePath(mapping[key])))throw Error('This animation backup has missing or unsafe resource references.');
   doc=remap(doc,mapping);const now=new Date().toISOString();doc.key=id();doc.createdAt=doc.updatedAt=now;doc.draft=false;doc.animationStudio.target='';delete doc.deletedAt;
   await transaction('readwrite',store=>store.put(doc));saved=true;
   try{await Native.call('animationImportLeases',{action:'commit',token:result.importToken});}catch(e){toast('Your animation is saved. Its import recovery will finish next time you open My animations.',true);}
   toast('Animation imported to My animations. Your units and current draft were kept.');
  }catch(error){
   if(!saved&&result?.importToken)try{await Native.call('animationImportLeases',{action:'discard',token:result.importToken});}catch(e){toast('The import could not finish. Its temporary files are kept for safe recovery next time.',true);}
   throw error;
  }finally{importing=false;}
  return show();
 }
 async function reconcileImports(){
  if(importing)return;
  if(reconciling)return reconciling;
  reconciling=(async()=>{
   const leases=await Native.call('animationImportLeases',{action:'pending'});if(!Array.isArray(leases)||leases.length>64)throw Error('Pending animation imports could not be checked safely.');
   if(!leases.length)return;
   const docs=await transaction('readonly',store=>{const request=store.getAll();return ()=>request.result;}),references=new Set();
   function collect(value,depth=0){if(depth>64)throw Error('A saved animation reference could not be checked safely.');if(typeof value==='string')references.add(value);else if(Array.isArray(value))value.forEach(item=>collect(item,depth+1));else if(value&&typeof value==='object')Object.values(value).forEach(item=>collect(item,depth+1));}
   docs.forEach(doc=>collect(doc)); // Tombstones are retained too: Undo removal must keep their files.
   for(const lease of leases){
    if(!Array.isArray(lease.resources)||lease.resources.length>256||!lease.resources.every(key=>typeof key==='string'&&Forge.safePath(key)))throw Error('A pending animation import contains invalid resource references.');
    const used=lease.resources.some(key=>references.has(key));
    await Native.call('animationImportLeases',{action:used?'commit':'discard',token:lease.token});
   }
  })().finally(()=>{reconciling=null;});return reconciling;
 }
 async function recoverImports(){try{await reconcileImports();}catch(e){toast('Pending animation files were kept: '+(e.message||String(e)),true);}}
 const archiveFields=new Set(['format','version','key','createdAt','updatedAt','draft','deletedAt','targetId','source','schema','tables','assets','movieBindings','animationStudio','provenance','sourceDependencies']);
 function archiveDocument(document){
  const doc=clone(validate(document));
  if(Object.keys(doc).some(key=>!archiveFields.has(key))||!/^[A-Za-z0-9_-]{1,100}$/.test(doc.key)||!Number.isSafeInteger(doc.targetId)||doc.targetId<1||doc.targetId>1999999000||!['eclipse','sparking'].includes(doc.source?.database)||typeof doc.animationStudio.name!=='string'||doc.animationStudio.name.length>120||doc.animationStudio.clips.length>24||doc.assets.length>256||!Array.isArray(doc.movieBindings)||doc.movieBindings.length>48||!Array.isArray(doc.tables.effect_packs)||doc.tables.effect_packs.length>48||!Array.isArray(doc.schema.effect_packs)||doc.schema.effect_packs.length>256||Object.keys(doc.tables).some(key=>key!=='effect_packs')||Object.keys(doc.schema).some(key=>key!=='effect_packs'))throw Error('One gallery document has unsupported editing data. Nothing was backed up or overwritten.');
  function inspect(value,depth=0){if(depth>64)throw Error('Gallery editing data is nested too deeply.');if(value&&typeof value==='object')for(const [key,item]of Object.entries(value)){if(/^(?:__proto__|prototype|constructor|password|api[_-]?key|access[_-]?token|refresh[_-]?token|secret|signing[_-]?key|sparking[_-]?key|credentials)$/i.test(key))throw Error('Gallery backups cannot contain connections or private keys.');inspect(item,depth+1);}}
  inspect(doc);if(new TextEncoder().encode(JSON.stringify(doc)).length>8*1024*1024)throw Error('One gallery document exceeds 8 MiB.');
  for(const asset of doc.assets)if(!asset||!Forge.safePath(asset.key)||!Forge.safePath(asset.path))throw Error('A gallery attachment has an unsafe reference.');
  return doc;
 }
 function archiveDocuments(value){
  if(!Array.isArray(value)||value.length>1000)throw Error('A creations archive can include up to 1,000 gallery documents.');
  const keys=new Set(),documents=value.map(archiveDocument);let total=0;
  for(const doc of documents){if(keys.has(doc.key)||(total+=new TextEncoder().encode(JSON.stringify(doc)).length)>16*1024*1024)throw Error('Gallery documents are duplicate or exceed 16 MiB total.');keys.add(doc.key);}return documents;
 }
 async function archiveSnapshot(){
  await flush();await reconcileImports();
  return transaction('readonly',(store,settings)=>{const all=store.getAll(),current=settings.get('current'),removed=settings.get('lastDeleted');return ()=>({format:'dokkan-animation-gallery-snapshot',version:1,documents:archiveDocuments(all.result),currentKey:current.result||'',lastDeleted:removed.result||''});});
 }
 const canonical=value=>JSON.stringify((function sorted(item){if(Array.isArray(item))return item.map(sorted);if(item&&typeof item==='object')return Object.fromEntries(Object.keys(item).sort().map(key=>[key,sorted(item[key])]));return item;})(value));
 async function restoreArchiveSnapshot(snapshot){
  if(!snapshot||snapshot.format!=='dokkan-animation-gallery-snapshot'||snapshot.version!==1||snapshot.verifiedFiles!==true)throw Error('Gallery files must be verified before restoring their editing data.');
  const documents=archiveDocuments(snapshot.documents);if(snapshot.count!==documents.length)throw Error('Gallery archive document count does not match.');
  await flush();
  return transaction('readwrite',(store,settings)=>{
   const all=store.getAll(),current=settings.get('current'),removed=settings.get('lastDeleted');let pending=3,result;
   const ready=()=>{if(--pending)return;try{
    const existing=new Map(all.result.map(doc=>[doc.key,doc])),accepted=new Set();result={restored:0,unchanged:0,conflicts:[]};
    for(const doc of documents){const old=existing.get(doc.key);if(old){if(canonical(old)===canonical(doc)){result.unchanged++;accepted.add(doc.key);}else result.conflicts.push({key:doc.key,name:doc.animationStudio.name||'Untitled animation'});}else{store.put(doc);result.restored++;accepted.add(doc.key);}}
    if(!current.result&&accepted.has(snapshot.currentKey))settings.put(snapshot.currentKey,'current');
    if(!removed.result&&accepted.has(snapshot.lastDeleted))settings.put(snapshot.lastDeleted,'lastDeleted');
   }catch(error){try{store.transaction.abort();}catch{} }};
   all.onsuccess=current.onsuccess=removed.onsuccess=ready;return ()=>result;
  });
 }
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
  const d=await db();return new Promise((resolve,reject)=>{const tx=d.transaction(['animations','settings'],mode);let result;tx.oncomplete=()=>{try{resolve(typeof result==='function'?result():result);}catch(error){reject(error);}};tx.onerror=tx.onabort=()=>reject(Error('Your animation could not be saved. Keep it open and free some device storage, then try again.'));try{result=work(tx.objectStore('animations'),tx.objectStore('settings'));}catch(e){tx.abort();reject(e);}});
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
 async function create(){return studioBusy('Starting an animation',async()=>{await flush();await flushSave();await recoverImports();active=fresh();owner=state.project?.key||null;resetHistory();dirty=true;revision++;state.studioTarget=null;Object.assign(studioState,{search:'',kind:'all',offset:0,unitId:0,tab:'characters',sourceDatabase:'eclipse'});await flush();state.view='animations';updateNav();await renderStudio();});}
 async function restore(){if(active)return active;await recoverImports();owner=state.project?.key||null;const key=await transaction('readonly',(_store,settings)=>{const r=settings.get('current');return ()=>r.result;});const saved=key?await read(key):null;active=saved&&!saved.deletedAt?validate(saved):fresh();resetHistory();dirty=!saved||!!saved.deletedAt;revision++;if(dirty)await flush();return active;}
 async function exit(){await flush();active=null;owner=null;resetHistory();dirty=false;revision++;}
 async function open(key){return studioBusy('Opening your animation',async()=>{await flush();await recoverImports();const doc=validate(await read(key));if(doc.deletedAt)throw Error('This animation was removed from the gallery.');active=clone(doc);owner=state.project?.key||null;resetHistory();dirty=true;revision++;state.studioTarget=null;state.view='animations';studioState.sourceDatabase=doc.source?.database||'eclipse';await flush();updateNav();return renderStudio();});}
 function snapshot(unit){const doc=fresh();doc.targetId=unit.targetId;doc.source={database:unit.source?.database||'eclipse'};doc.provenance=clone(unit.provenance||{});doc.animationStudio=clone(unit.animationStudio);doc.animationStudio.target='';doc.schema.effect_packs=clone(unit.schema.effect_packs||state.info.schema.effect_packs||[]);doc.tables.effect_packs=clone(unit.tables.effect_packs||[]);doc.movieBindings=clone(unit.movieBindings||[]);doc.assets=clone(unit.assets||[]);if(unit.sourceDependencies)doc.sourceDependencies=clone(unit.sourceDependencies);return doc;}
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
  const assets=[...ForgeMovieModel.previewAssets(owner),...(owner.assets||[]).map(a=>({path:a.path,key:a.key}))],seen=new Map();
  for(const a of assets){const prior=seen.get(a.path);if(prior&&prior.key!==a.key)throw Error('Two animation resources use the same path. Choose compatible clips.');seen.set(a.path,a);}
  const dependencies=owner.sourceDependencies?.animations||[],versions=[...new Set(dependencies.map(a=>a.version))];if(versions.length>1)throw Error('Choose clips from one matching Sparking version.');
  return {attackerId:actor,enemyId:actor===1000020?1000010:1000020,assets:[...seen.values()],effectPacks:ForgeMovieModel.previewRows(owner),...(owner.source.database==='sparking'?{sourceDatabase:'sparking'}:{}),...(versions.length?{sparkingVersion:versions[0],sparkingEffectIds:[...new Set(dependencies.flatMap(a=>a.effectIds||[]))]}:{})};
 }
 async function copyToUnit(doc,unit,target=''){
  validate(doc);await flush();await flushSave();
  if(state.project!==unit)throw Error('The selected unit changed. Choose it again.');
  const before=JSON.stringify(unit),next=clone(unit),sequence=clone(doc.animationStudio);
  sequence.clips=ForgeMovieModel.copyClips(doc,next,sequence.clips);
  next.assets=next.assets||[];const assets=new Map(next.assets.map(a=>[a.path,a]));
  for(const a of doc.assets||[])if(a.owner!==ForgeMovieModel.OWNER){const prior=assets.get(a.path);if(prior&&prior.key!==a.key)throw Error('This unit already uses a different version of an animation resource.');if(!prior){next.assets.push(clone(a));assets.set(a.path,a);}}
  const current=()=>state.project===unit&&JSON.stringify(unit)===before;
  for(const c of sequence.clips){await ForgeSparkingContent.attachAnimation(next,c.source,{persist:false,isCurrent:current});await ForgeSparkingContent.checkEclipseAnimation(next,c.source);}
  if(!current())throw Error('Your unit changed while the animation loaded. Select it again.');
  sequence.target=ForgeGuide.targets(next).some(t=>t.key===target)?target:'';sequence.dirty=true;next.animationStudio=sequence;
  Object.assign(unit,next);scheduleSave();await flushSave();await exit();state.studioTarget=sequence.target||null;state.view='animations';studioState.mode='compose';updateNav();await renderStudio();studioAssignDialog();
 }
 async function chooseUnit(doc){
  await flushSave();const units=await Native.call('projects');
  dialog('Choose a unit for this animation','<p>'+h(doc.animationStudio.name)+'</p><label class="field">Find your unit<input type="search" id="gallery-unit-search" placeholder="Unit name or custom ID…"></label><div id="gallery-units"></div>');
  const draw=()=>{const rows=units.filter(u=>ForgeSequence.matches(u.name+' '+u.targetId,$('#gallery-unit-search').value));$('#gallery-units').innerHTML=rows.length?rows.map(u=>'<button type="button" class="sequence-unit-choice" data-gallery-unit="'+h(u.key)+'"><strong>'+h(u.name)+'</strong><span>'+h(u.sourceName?'Based on '+u.sourceName:'Your unit')+'</span></button>').join(''):'<p>No saved units match. Create a unit, then choose this animation from its move settings.</p>';document.querySelectorAll('[data-gallery-unit]').forEach(b=>b.onclick=async()=>{try{b.disabled=true;await flushSave();if(ForgeFormsUI.active())await ForgeFormsUI.leave('editor');await openUnit(b.dataset.galleryUnit);$('#dialog').close();await copyToUnit(doc,state.project);}catch(e){b.disabled=false;toast(e.message,true);}});};$('#gallery-unit-search').oninput=draw;draw();
 }
 async function undo(redo=false){if(!active)return;const from=redo?future:past,to=redo?past:future;if(!from.length)return;to.push(clone(active));active=from.pop();changed(false);return renderStudio();}
 async function duplicate(key){const doc=clone(validate(await read(key)));doc.key=id();doc.createdAt=doc.updatedAt=new Date().toISOString();doc.animationStudio.name+=' copy';doc.draft=true;delete doc.deletedAt;await transaction('readwrite',store=>store.put(doc));return doc.key;}
 async function remove(key){await flush();const doc=validate(await read(key)),replacement=active?.key===key?fresh():null;doc.deletedAt=new Date().toISOString();await transaction('readwrite',(store,settings)=>{store.put(doc);settings.put(key,'lastDeleted');if(replacement){store.put(replacement);settings.put(replacement.key,'current');}});if(replacement){active=replacement;resetHistory();dirty=false;if(state.view==='animations')await renderStudio();}lastDeleted=key;}
 async function undoRemove(){if(!lastDeleted)return;const doc=validate(await read(lastDeleted));delete doc.deletedAt;await transaction('readwrite',(store,settings)=>{store.put(doc);settings.delete('lastDeleted');});lastDeleted=null;}
 async function show({unit=null,target=''}={}){
  const rows=await list();await recoverImports();lastDeleted=await transaction('readonly',(_store,settings)=>{const r=settings.get('lastDeleted');return ()=>r.result||null;});let busy=false;
  dialog(unit?'Choose from My animations':'My animations','<div class="row"><button class="button" id="gallery-new">New animation</button><button class="button ghost" id="gallery-import">Import animation backup</button>'+(lastDeleted?'<button class="button ghost" id="gallery-undo">Undo removal</button>':'')+'</div><p class="hint">Animation ZIP backups include the editable clips and attached resources: up to 64 MiB of files, 256 files and 8 MiB of editing data. They do not install into the game. Keep your backup before uninstalling; saved gallery documents are local to this app.</p><label class="field">Find an animation<input type="search" id="gallery-search" placeholder="Name, character, attack or song…"></label><div id="animation-gallery-list"></div>');
  const run=fn=>async()=>{if(busy)return;busy=true;const controls=[...document.querySelectorAll('[data-gallery-action],#gallery-new,#gallery-import,#gallery-undo,#gallery-search')].map(e=>[e,e.disabled]);for(const [e]of controls)e.disabled=true;try{await fn();}catch(e){toast(e.message,true);}finally{busy=false;for(const [e,disabled]of controls)if(e.isConnected)e.disabled=disabled;}};
  $('#gallery-new').onclick=run(async()=>{$('#dialog').close();await create();});
  $('#gallery-import').onclick=run(importBackup);
  if($('#gallery-undo'))$('#gallery-undo').onclick=run(async()=>{await undoRemove();return show({unit,target});});
  const draw=()=>{const query=$('#gallery-search').value,found=rows.filter(doc=>ForgeSequence.matches([doc.animationStudio.name,doc.animationStudio.music?.title,...doc.animationStudio.clips.map(c=>c.label+' '+(c.source.catalog?.unitName||'')+' '+(c.source.catalog?.moveName||''))].join(' '),query));
   $('#animation-gallery-list').innerHTML=found.length?'<div class="animation-gallery-grid">'+found.map(doc=>{const s=doc.animationStudio,total=ForgeSequence.timeline(s.clips).slice(-1)[0]?.end||0;return '<article class="animation-gallery-card"><h3>'+h(s.name)+'</h3><p>'+s.clips.length+' clips · '+ForgeSequence.clock(total)+(doc.draft?' · Draft':'')+'</p><p class="hint">'+h(s.music?.title||'Scene audio')+'</p><div class="row"><button class="button ghost small" data-gallery-action="edit" data-key="'+h(doc.key)+'">Edit</button><button class="button small" data-gallery-action="use" data-key="'+h(doc.key)+'"'+(!s.clips.length?' disabled':'')+'>Use on '+(unit?'this unit':'a unit')+'</button><button class="button ghost small" data-gallery-action="preview" data-key="'+h(doc.key)+'"'+(!s.clips.length?' disabled':'')+'>Preview</button></div><details class="beginner-details"><summary>More</summary><div class="row"><button class="button ghost small" data-gallery-action="backup" data-key="'+h(doc.key)+'">Save animation backup</button><button class="button ghost small" data-gallery-action="copy" data-key="'+h(doc.key)+'">Make a copy</button><button class="button subtle small" data-gallery-action="remove" data-key="'+h(doc.key)+'">Remove</button></div></details></article>';}).join('')+'</div>':'<p>No animations found. Choose New animation to start without a unit.</p>';
   document.querySelectorAll('[data-gallery-action]').forEach(b=>b.onclick=run(async()=>{const doc=validate(await read(b.dataset.key));switch(b.dataset.galleryAction){case 'edit':$('#dialog').close();return open(doc.key);case 'preview':return Native.call('previewAnimation',{name:doc.animationStudio.name,text:ForgeMotion.compile(doc.animationStudio.clips,{damage:false,music:doc.animationStudio.music}),...previewRequest(doc)});case 'use':$('#dialog').close();return unit?copyToUnit(doc,unit,target):chooseUnit(doc);case 'backup':return exportBackup(doc);case 'copy':await duplicate(doc.key);return show({unit,target});case 'remove':await remove(doc.key);return show({unit,target});}}));
  };$('#gallery-search').oninput=draw;draw();
 }
 const previousFlush=flushSave;
 flushSave=async function(){await flush();return previousFlush();};
 addEventListener('pagehide',()=>{flush().catch(()=>{});});
 document.addEventListener('visibilitychange',()=>{if(document.hidden)flush().catch(()=>{});});
 // The unit that was open when the independent animation was started; opening another unit
 // returns the editor to that unit's own animations.
 const ownerKey=()=>owner;
 window.ForgeAnimationGallery={FORMAT,current,ownerKey,restore,create,open,exit,changed,flush,list,read,save,commitPrepared,previewRequest,prepareSource,undo,copyToUnit,chooseUnit,show,duplicate,remove,exportBackup,importBackup,portable,reconcileImports,archiveSnapshot,restoreArchiveSnapshot};
})();
