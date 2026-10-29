'use strict';
// Hash-checked changes limited to eight public-player JavaScript modules.
const {createHash}=require('node:crypto');
const PATHS=new Set(['/tools/lua-player/js/binders.js','/tools/lua-player/js/runner.js','/tools/lua-player/js/tcb-keys.js','/tools/lua-player/js/lwf-player.js','/tools/lua-player/js/recorder.js','/tools/lua-player/js/atlas-fit.js','/static/vendor/lwf/lwf.js','/tools/lua-player/js/app.js']);
function applyTrainingPatches(text,manifest){
 if(typeof text!=='string'||!manifest||manifest.version!==1||!PATHS.has(manifest.path)||!Array.isArray(manifest.patches)||!manifest.patches.length||manifest.patches.length>32)throw Error('Unsupported item-scene player adaptation.');
 if(createHash('sha256').update(text,'utf8').digest('hex')!==manifest.sourceSha256)throw Error('The animation website updated its item-scene player. Update Forge before previewing these scenes.');
 let output=text;
 for(const patch of manifest.patches){
  if(typeof patch.find!=='string'||!patch.find||typeof patch.replace!=='string')throw Error('Invalid item-scene player adaptation.');
  const start=output.indexOf(patch.find);if(start<0||output.indexOf(patch.find,start+patch.find.length)>=0)throw Error('The item-scene player no longer matches its local adapter.');
  output=output.slice(0,start)+patch.replace+output.slice(start+patch.find.length);
 }
 return output;
}
module.exports={applyTrainingPatches};
