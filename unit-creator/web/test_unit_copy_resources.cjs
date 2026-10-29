/* Real-master My Unit copy/export fixture. Synthetic PNG/audio/movie bytes test references, not media decoding. */
const fs=require('fs'),path=require('path'),vm=require('vm'),child=require('child_process'),crypto=require('crypto');
const root=path.resolve(__dirname,'..'),ui=path.join(root,'v2/ui'),db=process.argv[2],out=process.argv[3];
global.window=global;global.crypto=crypto.webcrypto;
for(const [name,file]of Object.entries({Forge:'core',ForgeGuide:'guide-model',ForgeBuilder:'builder-model',ForgeMotion:'motion',ForgeMovieModel:'movie-model',ForgeArt:'art-model',ForgeSuperAttacks:'super-attacks',ForgePassiveMerge:'passive-merge',ForgeActionHooks:'action-hooks',ForgeForms:'forms-model',ForgeUnitRebase:'unit-rebase'}))global[name]=require(path.join(ui,file));
global.esc=String;global.number=String;global.document={body:{},querySelector:()=>null};global.MutationObserver=class{observe(){}};global.requestAnimationFrame=()=>{};
const sql=`import sqlite3,json,sys\nd=sqlite3.connect('file:'+sys.argv[1]+'?mode=ro',uri=True);d.row_factory=sqlite3.Row\na=json.loads(sys.argv[2])\nif 'schema' in a: print(json.dumps({r[0]:[dict(c) for c in d.execute('PRAGMA table_info("'+r[0]+'")')] for r in d.execute("SELECT name FROM sqlite_master WHERE type='table'")}))\nelif 'first' in a: print(json.dumps(d.execute("SELECT c.id FROM cards c JOIN card_specials s ON c.id=s.card_id WHERE c.id%10=1 AND c.rarity>=4 AND c.hp_max>1000 AND c.id<3000000 ORDER BY c.id LIMIT 1").fetchone()[0]))\nelse:\n t=a['table'];assert t.replace('_','').isalnum();q='SELECT * FROM "'+t+'"';args=[]\n if a.get('filters'): q+=' WHERE '+' AND '.join('"'+k+'"=?' for k in a['filters']);args=list(a['filters'].values())\n q+=' LIMIT '+str(a.get('limit',5000));print(json.dumps([dict(r) for r in d.execute(q,args)]))\n`;
const query=a=>JSON.parse(child.execFileSync('python3',['-c',sql,db,JSON.stringify(a)],{maxBuffer:16*1024*1024}));
const schema=query({schema:true}),assets=new Map();let donor,destination,checks=0;
function ok(label,condition){if(!condition)throw Error(label);checks++;console.log('PASS '+label);}
global.state={info:{schema},project:null,links:[],categories:[]};
global.Native={call:async(method,args={})=>{
 if(method==='loadProject')return Forge.clone(donor);
 if(method==='query'||method==='querySparking')return query(args);
 if(method==='projects')return[donor,destination].map(p=>({key:p.key,targetId:p.targetId}));
 if(method==='readAsset'){const value=assets.get(args.key);if(!value)throw Error('Missing fixture asset');return{base64:Buffer.from(value).toString('base64')};}
 if(method==='assetStatus')return args.keys.map(key=>({key,available:assets.has(key)}));
 throw Error('Unexpected fixture bridge '+method);
}};
vm.runInThisContext(fs.readFileSync(path.join(ui,'unit-copy.js'),'utf8'),{filename:'unit-copy.js'});
(async()=>{
 const card=query({first:true});donor=await Forge.loadTemplate(async a=>query(a),schema,card,97001001);destination=Forge.clone(donor);destination.key='destination-unit';destination.targetId=97001011;state.project=destination;
 donor.key='donor-unit';donor.cardOverrides.bg_effect_id=null;
 const png=Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGNgYGD4DwABBAEAX+XDSwAAAABJRU5ErkJggg==','base64'),stem=String(Forge.card(donor).resource_id).padStart(7,'0'),originals=[];
 for(const suffix of ['_character','_bg','_effect','_circle','_cutin','sp_cutin_1']){const game='character/card/'+stem+'/card_'+stem+suffix+'.png',key='import-fixture/'+game;assets.set(key,png);originals.push({key,path:game});}
 const thumb='character/thumb/card_'+stem+'_thumb.png';assets.set('import-fixture/'+thumb,png);originals.push({key:'import-fixture/'+thumb,path:thumb});
 const art=await ForgeArt.plan(donor,originals,{group:'import-fixture',replacements:[{role:'character',key:originals[0].key}],readAsset:async key=>assets.get(key)});ForgeArt.apply(donor,art);
 const movieKey='generated-movie-fixture/movie.usm';assets.set(movieKey,new Uint8Array(2048));
 const plan=ForgeMovieModel.plan(donor,{schema,assetKey:movieKey,size:2048,storageTag:'a'.repeat(32),metadata:{width:32,height:32,frames:30,rate:{n:30,d:1}},name:'Synthetic movie'});const movie=ForgeMovieModel.apply(donor,plan);
 const musicPath='bgm/forge_sequence_'+donor.targetId+'_test.mp3',musicKey='import-fixture/song.mp3';assets.set(musicKey,Buffer.from('SYNTHETIC AUDIO'));donor.assets.push({path:musicPath,key:musicKey,owner:'forge-sequence-music'});
 const rel=donor.tables.card_specials[0];ForgeSuperAttacks.setStyle(donor,schema,rel.id,'Condition');ForgeBuilder.applyCondition(donor,schema,rel,{mode:'all',items:[{key:'turn',values:{turn:4}}]});
 const clips=[ForgeMotion.createClip({path:'ab_script/attack_sp/sp0001.lua',text:'setMoveKey(0,0,0,0,0);endPhase(60);',label:'Synthetic scene'}),ForgeMovieModel.makeClip(donor,movie)];
 ForgeGuide.applyComposition(donor,schema,clips,'super:'+rel.id,'My complete move',{music:{kind:'file',path:musicPath,title:'My music'}});
 const passive=Forge.primaryPassive(donor),ids=new Set(donor.tables.passive_skill_set_relations.filter(row=>row.passive_skill_set_id===passive.id).map(row=>row.passive_skill_id)),intro=ForgeGuide.targets(donor).find(target=>target.kind==='intro'&&ids.has(target.row));
 if(!intro)throw Error('This fixture needs a start-of-turn passive.');ForgeGuide.applyComposition(donor,schema,[clips[0]],intro.key,'My Intro');
 const originalDonor=JSON.stringify(donor),originalDestination=JSON.stringify(destination),saved=await ForgeUnitCopy.myDonor(donor.key);
 ok('My Unit donor keeps editable assignments and generated scripts',Object.keys(saved.project.animationAssignments).length===2&&saved.project.generatedFiles.length===2&&JSON.stringify(donor)===originalDonor);
 const prepared=await ForgeUnitCopy.prepare(saved,new Set(['supers','art']),{supers:'replace'},destination),copied=prepared.work;
 ok('preparation changes neither source nor destination',JSON.stringify(donor)===originalDonor&&JSON.stringify(destination)===originalDestination);
 const target=copied.tables.card_specials.find(r=>copied.animationAssignments['super:'+r.id]),assignment=copied.animationAssignments['super:'+target.id];
 ok('custom Super Attack is recompiled under destination private script ID',assignment.file.includes(String(copied.targetId+500))&&!assignment.file.includes(String(donor.targetId+500))&&copied.generatedFiles.some(f=>f.owner==='super:'+target.id));
 ok('copied attack retains activation conditions and gameplay effects',target.style==='Condition'&&!!target.causality_conditions&&copied.tables.specials.length===donor.tables.specials.length&&copied.tables.skill_causalities.some(r=>r.causality_type===5));
 ok('authored movie is rekeyed without donor namespace collision',copied.movieBindings.length===1&&copied.movieBindings[0].path.includes(String(copied.targetId))&&!copied.movieBindings[0].path.includes(String(donor.targetId))&&copied.assets.find(a=>a.owner==='forge-authored-movie').key===movieKey);
 ok('sequence music gets destination path while bytes remain immutable',assignment.music.path.includes(String(copied.targetId))&&copied.assets.some(a=>a.path===assignment.music.path&&a.key===musicKey));
 ok('custom art pack and aliases move into destination namespace',copied.artBinding.resourceId===97001010&&copied.packedAssets.length>0&&copied.assets.filter(a=>a.owner==='forge-card-art').every(a=>a.path.includes('97001010')));
 ok('complete copied unit passes native-row export validation',Forge.validate(copied).errors.length===0);
 const ff=require(path.join(ui,'vendor/fflate.js')),cpk=require(path.join(ui,'cpk-writer.js')),files={};
 for(const e of Forge.exportEntries(copied)){files[e.path]=e.cpk?cpk.encode(e.cpk.map(x=>({path:x.path,data:assets.get(x.assetKey)}))):e.assetKey?assets.get(e.assetKey):new TextEncoder().encode(e.text);if(!files[e.path])throw Error('Missing export fixture '+e.path);}
 fs.writeFileSync(out,ff.zipSync(files));const reopened=JSON.parse(new TextDecoder().decode(ff.unzipSync(fs.readFileSync(out))['forge-project.json']));
 ok('real ZIP roundtrip retains editable clips, artwork and all attachment bytes',Forge.validate(reopened).errors.length===0&&Object.keys(reopened.animationAssignments).length===1&&Object.keys(files).some(p=>p.endsWith('.cpk'))&&Object.keys(files).some(p=>p.endsWith('.usm')));
 const conflict=Forge.clone(destination);conflict.assets.push({path:musicPath.replace(String(donor.targetId),String(destination.targetId)),key:'different/song.mp3'});let rejected=false;try{await ForgeUnitCopy.prepare(saved,new Set(['supers']),{supers:'replace'},conflict);}catch(e){rejected=/different file/.test(e.message);}ok('resource conflicts reject before touching the unit',rejected&&destination.assets.length===0);
 const beforeAnimations=JSON.stringify(destination),animations=await ForgeUnitCopy.prepare(saved,new Set(['animations']),{},destination);
 ok('animation-only copy keeps destination effects and activation settings',JSON.stringify(destination)===beforeAnimations&&JSON.stringify(animations.work.tables.specials)===JSON.stringify(destination.tables.specials)&&animations.work.tables.card_specials.every((r,i)=>r.special_set_id===destination.tables.card_specials[i].special_set_id&&r.style===destination.tables.card_specials[i].style&&r.causality_conditions===destination.tables.card_specials[i].causality_conditions)&&Object.keys(animations.work.animationAssignments).length>0);
 const passiveCopy=await ForgeUnitCopy.prepare(saved,new Set(['passive']),{passive:'replace'},destination);
 ok('passive replacement maps and recompiles its custom Intro target',Object.keys(passiveCopy.work.animationAssignments).some(key=>key.startsWith('intro:'))&&Forge.validate(passiveCopy.work).errors.length===0);
 const added=await ForgeUnitCopy.prepare(saved,new Set(['passive']),{passive:'add'},destination);
 ok('passive addition preserves custom animated row outside effect merging',Object.keys(added.work.animationAssignments).some(key=>key.startsWith('intro:'))&&Forge.validate(added.work).errors.length===0);
 let introConflict=false;try{await ForgeUnitCopy.prepare(saved,new Set(['passive']),{passive:'add'},passiveCopy.work);}catch(e){introConflict=/already has an Intro/.test(e.message);}ok('two Intro designs reject explicitly before either is lost',introConflict);
 console.log(checks+' focused real-master unit copy/export assertions passed. Media bytes are synthetic; decoder/game acceptance is not claimed.');
})().catch(e=>{console.error(e.stack);process.exitCode=1;});
