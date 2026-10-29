/* Simple sequence data shared by the editor and compiler. */
(function(root,factory){if(typeof module==='object'&&module.exports)module.exports=factory();else root.ForgeSequence=factory();})(typeof globalThis!=='undefined'?globalThis:this,function(){
 'use strict';
 function music(value){
  if(!value||value.kind==='original')return null;
  if(value.kind==='none')return {kind:'none'};
  const title=String(value.title||'My song').slice(0,120);
  if(value.kind==='file'&&/^bgm\/forge_sequence_[a-z0-9_]+\.(mp3|m4a|aac|wav|ogg|flac)$/i.test(value.path||''))return {kind:'file',path:value.path,title};
  if(value.kind==='game'&&/^bgm_[0-9]{3,10}$/.test(value.package||'')&&Number(value.package.slice(4))>0&&Number(value.package.slice(4))<=2147483647)return {kind:'game',package:value.package,title};
  throw Error('Choose your song again.');
 }
 function timeline(clips){let frame=0;return clips.map(c=>{const frames=Math.round(c.to*60)-Math.round(c.from*60),start=frame;frame+=frames;return {start:start/60,end:frame/60,duration:frames/60};});}
 const clock=seconds=>{const tenths=Math.round(seconds*10),s=Math.floor(tenths/10);return Math.floor(s/60)+':'+String(s%60).padStart(2,'0')+'.'+tenths%10;};
 const normalize=value=>String(value||'').normalize('NFKD').replace(/[\u0300-\u036f]/g,'').toLowerCase().replace(/[^a-z0-9]+/g,' ').trim();
 function matches(value,query){const text=normalize(value);return normalize(query).split(/\s+/).every(t=>text.includes(t));}
 return {music,timeline,clock,normalize,matches};
});
