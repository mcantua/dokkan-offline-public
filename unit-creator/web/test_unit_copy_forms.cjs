/* New linked-form scenario only: real master, private graph/media, ZIP and SQL. */
const fs=require('fs'),path=require('path'),vm=require('vm'),child=require('child_process'),crypto=require('crypto');
const root=path.resolve(__dirname,'..'),ui=path.join(root,'v2/ui'),db=process.argv[2],out=process.argv[3];
global.window=global;global.crypto=crypto.webcrypto;
for(const [name,file]of Object.entries({Forge:'core',ForgeGuide:'guide-model',ForgeBuilder:'builder-model',ForgeMotion:'motion',ForgeMovieModel:'movie-model',ForgeArt:'art-model',ForgeSuperAttacks:'super-attacks',ForgePassiveMerge:'passive-merge',ForgeActionHooks:'action-hooks',ForgeForms:'forms-model',ForgeUnitRebase:'unit-rebase'}))global[name]=require(path.join(ui,file));
global.esc=String;global.number=String;global.document={body:{},querySelector:()=>null};global.MutationObserver=class{observe(){}};global.requestAnimationFrame=()=>{};
const sql=`import sqlite3,json,sys
d=sqlite3.connect('file:'+sys.argv[1]+'?mode=ro',uri=True);d.row_factory=sqlite3.Row;a=json.loads(sys.argv[2])
if 'schema' in a: print(json.dumps({r[0]:[dict(c) for c in d.execute('PRAGMA table_info("'+r[0]+'")')] for r in d.execute("SELECT name FROM sqlite_master WHERE type='table'")}))
elif 'sources' in a: print(json.dumps([r[0] for r in d.execute("SELECT DISTINCT c.id FROM cards c JOIN card_specials s ON c.id=s.card_id WHERE c.id%10=1 AND c.rarity>=4 AND c.hp_max>1000 AND c.id<3000000 ORDER BY c.id LIMIT 4")]))
else:
 t=a['table'];assert t.replace('_','').isalnum();q='SELECT * FROM "'+t+'"';args=[];where=[]
 for k,v in a.get('filters',{}).items(): where.append('"'+k+'"=?');args.append(v)
 if 'ids' in a: where.append('id IN ('+','.join('?' for _ in a['ids'])+')');args+=a['ids']
 if where:q+=' WHERE '+' AND '.join(where)
 q+=' LIMIT '+str(a.get('limit',5000));print(json.dumps([dict(r) for r in d.execute(q,args)]))
`;
const query=a=>JSON.parse(child.execFileSync('python3',['-c',sql,db,JSON.stringify(a)],{maxBuffer:16*1024*1024})),schema=query({schema:true}),assets=new Map();let donor,destination;
global.state={info:{schema},project:null,links:[],categories:[]};
global.Native={call:async(method,args={})=>{if(method==='query'||method==='querySparking')return query(args);if(method==='projects')return[donor,destination];if(method==='assets')return[];if(method==='assetStatus')return args.keys.map(key=>({key,available:assets.has(key)}));if(method==='readAsset')return{base64:Buffer.from(assets.get(args.key)).toString('base64')};throw Error('Unexpected fixture bridge '+method);}};
vm.runInThisContext(fs.readFileSync(path.join(ui,'unit-copy.js'),'utf8'),{filename:'unit-copy.js'});
const ok=(label,value)=>{if(!value)throw Error(label);console.log('PASS '+label);};
(async()=>{
 const sources=query({sources:true}),members=[];for(let i=0;i<4;i++)members.push(await Forge.loadTemplate(async args=>query(args),schema,sources[i],97000001+i*1000));
 [donor,destination]=members;const first=members[2],second=members[3];donor.key='source-root';destination.key='destination';first.key='source-first';second.key='source-second';state.project=destination;
 // Distinct original source IDs let the existing exporter map the entire one-way chain.
 const entry=Forge.addPassive(donor,{efficacy_type:103,eff_value1:first.targetId,eff_value3:700001});
 const chain=Forge.addPassive(first,{efficacy_type:103,eff_value1:second.source.cardId,eff_value3:700002});
 donor.abilityAnimationSources=donor.abilityAnimationSources||{};donor.abilityAnimationSources['passive_skills:'+entry.id]={values:[first.targetId,0,700001],params:[{...Forge.rowDefault(schema.battle_params),id:1,param_no:700001,idx:0,value:donor.source.cardId}]};
 first.abilityAnimationSources=first.abilityAnimationSources||{};first.abilityAnimationSources['passive_skills:'+chain.id]={values:[second.source.cardId,0,700002],params:[{...Forge.rowDefault(schema.battle_params),id:2,param_no:700002,idx:0,value:donor.source.cardId}]};
 donor.formProjects=[first,second];donor.transformLinks=[{table:'passive_skills',row:entry.id,targetKey:first.key,targetId:first.targetId}];
 const movieKey='generated-movie-fixture/movie.usm';assets.set(movieKey,new Uint8Array(2048));const movie=ForgeMovieModel.apply(first,ForgeMovieModel.plan(first,{schema,assetKey:movieKey,size:2048,storageTag:'b'.repeat(32),metadata:{width:32,height:32,frames:30,rate:{n:30,d:1}},name:'Form movie'}));
 const musicKey='import-fixture/song.mp3',musicPath='bgm/forge_sequence_'+first.targetId+'_form.mp3';assets.set(musicKey,Buffer.from('SYNTHETIC'));first.assets.push({key:musicKey,path:musicPath,owner:'forge-sequence-music'});
 ForgeGuide.applyComposition(first,schema,[ForgeMovieModel.makeClip(first,movie)],'super:'+first.tables.card_specials[0].id,'Custom form move',{music:{kind:'file',path:musicPath,title:'Form music'}});
 ok('source linked graph is valid before copying',Forge.validate(donor).errors.length===0);
 const before=JSON.stringify(donor),targetBefore=JSON.stringify(destination),prepared=await ForgeUnitCopy.prepare({project:donor,kind:'mine',name:'Linked source',cardId:donor.source.cardId},new Set(['transform']),{},destination),copied=prepared.work,forms=copied.formProjects;
 ok('prepared copy clones reachable forms with fresh keys and nonoverlapping slots without changing either unit',JSON.stringify(donor)===before&&JSON.stringify(destination)===targetBefore&&forms.length===2&&forms.every(f=>![first.key,second.key].includes(f.key)&&![first.targetId,second.targetId,destination.targetId].includes(f.targetId))&&Math.abs(forms[0].targetId-forms[1].targetId)>=1000);
 const attached=forms.find(f=>f.source.cardId===first.source.cardId),final=forms.find(f=>f.source.cardId===second.source.cardId),tables=Forge.materializeAll(copied),link=copied.transformLinks.find(l=>l.targetKey===attached.key);
 ok('root link and chained transformation export into the new owned graph',link&&tables.passive_skills.some(r=>r.efficacy_type===103&&r.eff_value1===attached.targetId)&&tables.passive_skills.some(r=>r.efficacy_type===103&&r.eff_value1===final.targetId));
 ok('private battle parameters return to destination, never the source custom unit',tables.battle_params.some(r=>r.value===destination.targetId)&&!tables.battle_params.some(r=>r.value===donor.targetId));
 const assignment=Object.values(attached.animationAssignments)[0];ok('linked editable movie/music resources rebase with their fresh form',attached.movieBindings[0].path.includes(String(attached.targetId))&&assignment.file.includes(String(attached.targetId+500))&&assignment.music.path.includes(String(attached.targetId))&&attached.assets.some(a=>a.key===movieKey)&&Forge.validate(copied).errors.length===0);
 const ff=require(path.join(ui,'vendor/fflate.js')),files={};for(const item of Forge.exportEntries(copied))files[item.path]=item.assetKey?assets.get(item.assetKey):new TextEncoder().encode(item.text);fs.writeFileSync(out,ff.zipSync(files));
 const cyclic=Forge.clone(donor),last=cyclic.formProjects[1];Forge.addPassive(last,{efficacy_type:103,eff_value1:first.source.cardId});let rejected=false;try{await ForgeUnitCopy.prepare({project:cyclic,kind:'mine',name:'cycle'},new Set(['transform']),{},destination);}catch(e){rejected=/cycle/.test(e.message);}ok('cyclic source graph rejected before destination changes',rejected&&JSON.stringify(destination)===targetBefore);
})().catch(error=>{console.error(error.stack);process.exitCode=1;});
