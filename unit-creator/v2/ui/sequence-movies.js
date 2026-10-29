/* Turn movie cuts into owned movie resources before retiming their Lua scene. */
(function(){
 'use strict';
 function movieCalls(text){
  const tree=luaparse.parse(text,{ranges:true,luaVersion:'5.1'}),values=new Map(),calls=[];
  function number(n){if(!n)return NaN;if(n.type==='NumericLiteral')return n.value;if(n.type==='Identifier')return values.get(n.name)??NaN;if(n.type==='UnaryExpression'&&n.operator==='-')return -number(n.argument);if(n.type==='BinaryExpression'){const a=number(n.left),b=number(n.right);return ({'+':()=>a+b,'-':()=>a-b,'*':()=>a*b,'/':()=>a/b,'%':()=>a%b})[n.operator]?.()??NaN;}return NaN;}
  function visit(n){if(!n||typeof n!=='object')return;
   if(n.type==='AssignmentStatement'||n.type==='LocalStatement'){n.variables.forEach((v,i)=>{if(v.type==='Identifier')values.set(v.name,number(n.init[i]));});}
   if(n.type==='CallExpression'&&n.base?.type==='Identifier'&&n.base.name==='setupMovie'){
    const frame=number(n.arguments[0]),id=number(n.arguments[1]);if(!Number.isFinite(frame)||!Number.isSafeInteger(id)||id<=0)throw Error('This movie uses dynamic scene timing. It can be reused whole in Advanced editor.');
    calls.push({frame,id,args:n.arguments.map(a=>text.slice(...a.range)),range:n.range});
   }
   for(const [key,value] of Object.entries(n))if(key!=='range'){if(Array.isArray(value))value.forEach(visit);else if(value&&typeof value==='object')visit(value);}
  }
  visit(tree);if(!calls.length||calls.length>8)throw Error('Choose a movie scene with up to eight video sections.');return calls;
 }
 async function sourceMovie(unit,row,{signal=new AbortController().signal}={}){
  if(!row||Number(row.category)!==5||!/^[A-Za-z0-9_]+$/.test(row.pack_name||''))throw Error('The video resource for this animation could not be found.');
  const name=row.pack_name+'.usm',paths=['movie/en/ingame/battle/sp_effect/','movie/ingame/battle/sp_effect/','movie/en/ingame/battle/effect/','movie/ingame/battle/effect/'].map(root=>root+name);
  const attached=paths.map(path=>(unit.assets||[]).find(asset=>asset.path===path)).find(Boolean);if(attached)return attached;
  const imported=await Native.call('assets',{query:name,limit:500});
  for(const path of paths){const found=imported.find(asset=>asset.path===path||asset.path==='tutorial0/'+path);if(found)return found;}
  let error;
  for(const path of paths){if(signal.aborted)throw new DOMException('Movie cut cancelled.','AbortError');try{return await Native.call('downloadAsset',{path});}catch(failure){error=failure;}}
  throw Error('This game movie could not be downloaded. Import its matching movie resources and try again. '+(error?.message||''));
 }
 async function trim(unit,clip,{signal=new AbortController().signal,progress=()=>{}}={}){
  if(!clip.report?.video||clip.from===0&&!clip.source.sequenceMovieTrim)return;
  const baseline=JSON.stringify(unit),next=Forge.clone(unit),original=Forge.clone(clip.source.sequenceOriginalSource||clip.source),calls=movieCalls(original.text),replacements=[],bindings=[];
  for(let i=0;i<calls.length;i++){
   const call=calls[i];if(call.frame>=clip.to*60)continue;
   progress('Preparing movie cut '+(i+1)+' of '+calls.length+'…');
   const owned=ForgeMovieModel.inspect(next).find(b=>b.effectPackId===call.id),rows=owned?[]:await Native.call('query',{table:'effect_packs',ids:[call.id],limit:1}),row=owned?null:rows[0];
   if(!owned&&(!row||Number(row.category)!==5||!/^[A-Za-z0-9_]+$/.test(row.pack_name||'')))throw Error('The video resource for this animation could not be found.');
   const asset=owned?next.assets.find(a=>a.path===owned.path):await sourceMovie(next,row,{signal});if(!asset)throw Error('The attached movie file is missing. Import the complete animation again.');const url=await Native.call('assetUrl',{key:asset.key||asset.assetKey}),response=await fetch(url,{signal});
   if(!response.ok)throw Error('This movie could not be loaded. Import its game resources and try again.');if(Number(response.headers.get('content-length'))>160*1024*1024)throw Error('This source movie is too large to trim on this device.');
   const bytes=new Uint8Array(await response.arrayBuffer());if(bytes.length>160*1024*1024)throw Error('This source movie is too large to trim on this device.');
   const input=ForgeMovieInput.readMovie(bytes),fps=input.rate.n/input.rate.d,from=Math.max(0,Math.round((clip.from-call.frame/60)*fps)),to=Math.min(input.frames,Math.round((clip.to-call.frame/60)*fps));
   if(from>=to){call.args[0]=String(Math.ceil(clip.to*60)+1);replacements.push({range:call.range,text:'setupMovie('+call.args.join(',')+')'});continue;}
   const {editMovie}=await import('./vendor/media/editor.js'),width=Math.min(540,input.width)-Math.min(540,input.width)%2,height=Math.max(2,Math.round(input.height*width/input.width/2)*2),edited=await editMovie({name:'forge-sequence-cut',width,height,rate:{n:30,d:1},quality:36,audioMode:'auto',clips:[{...input,startFrame:from,endFrame:to}],signal},e=>progress(e?.message||'Preparing movie cut…'));
   const saved=await ForgeMovieEditor.store(edited.data,clip.label,signal,progress),plan=ForgeMovieModel.plan(next,{schema:state.info.schema,assetKey:saved.key,size:saved.size,metadata:saved,storageTag:saved.storageTag,name:clip.label.slice(0,120)}),key=ForgeMovieModel.apply(next,plan),binding=ForgeMovieModel.inspect(next).find(b=>b.key===key),variable='__forge_sequence_movie_'+i;
   bindings.push({key,variable});call.args[0]=String(Math.max(call.frame,Math.round(clip.from*60)));call.args[1]=variable;replacements.push({range:call.range,text:'setupMovie('+call.args.join(',')+')'});
  }
  let text=original.text;for(const r of replacements.sort((a,b)=>b.range[0]-a.range[0]))text=text.slice(0,r.range[0])+r.text+text.slice(r.range[1]);
  for(const b of bindings)text='local '+b.variable+'='+ForgeMovieModel.inspect(next).find(v=>v.key===b.key).effectPackId+'\n'+text;
  if(signal.aborted)throw new DOMException('Movie cut cancelled.','AbortError');if(studioOwner()!==unit||JSON.stringify(unit)!==baseline)throw Error('Your unit changed while the movie was cutting. Try that cut again.');
  unit.assets=next.assets;unit.movieBindings=next.movieBindings;unit.tables.effect_packs=next.tables.effect_packs;unit.schema.effect_packs=next.schema.effect_packs;
  const source={...original,text,sequenceOriginalSource:original,sequenceMovieBindings:bindings,sequenceMovieTrim:{from:clip.from,to:clip.to}};delete source.movieBindingKey;clip.source=source;clip.report=ForgeMotion.analyze(text);
 }
 window.ForgeSequenceMovies={trim,movieCalls,sourceMovie};
})();
