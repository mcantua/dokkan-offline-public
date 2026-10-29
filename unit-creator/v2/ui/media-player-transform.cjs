'use strict';
// Version-checked, class-local adaptations of the downloaded public player.
const {createHash}=require('node:crypto');
function applyPlayerPatches(text,manifest){
 if(typeof text!=='string'||!manifest||manifest.version!==1||!['/tools/lua-player/js/usm-player.js','/tools/lua-player/js/audio-bus.js'].includes(manifest.path)||!Array.isArray(manifest.patches)||manifest.patches.length<1)throw new Error('Unsupported movie-player adaptation.');
 const kind=manifest.path.endsWith('/audio-bus.js')?'sound':'movie';
 const digest=createHash('sha256').update(text,'utf8').digest('hex');
 if(digest!==manifest.sourceSha256)throw new Error('The animation website updated its '+kind+' player. Update Forge to use its latest '+kind+' integration.');
 let output=text;
 for(const patch of manifest.patches){
  if(typeof patch.find!=='string'||!patch.find||typeof patch.replace!=='string')throw new Error('Invalid movie-player adaptation.');
  const index=output.indexOf(patch.find);
  if(index<0||output.indexOf(patch.find,index+patch.find.length)>=0)throw new Error('The movie player no longer matches its local playback adapter.');
  output=output.slice(0,index)+patch.replace+output.slice(index+patch.find.length);
 }
 return output;
}
module.exports={applyPlayerPatches};
