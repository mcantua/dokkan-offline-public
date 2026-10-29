'use strict';
const {createHash}=require('node:crypto');
function applyLwfPatches(text,manifest){
 if(typeof text!=='string'||!manifest||manifest.version!==1||manifest.path!=='/tools/lwf-player/js/lwf-pack.js'||!Array.isArray(manifest.patches)||!manifest.patches.length)throw Error('Unsupported visual-player adaptation.');
 if(createHash('sha256').update(text,'utf8').digest('hex')!==manifest.sourceSha256)throw Error('The animation website updated its visual player. Update Forge to use its latest timeline integration.');
 let result=text;for(const patch of manifest.patches){if(typeof patch.find!=='string'||!patch.find||typeof patch.replace!=='string')throw Error('Invalid visual-player adaptation.');const index=result.indexOf(patch.find);if(index<0||result.indexOf(patch.find,index+patch.find.length)>=0)throw Error('The visual player no longer matches its timeline adapter.');result=result.slice(0,index)+patch.replace+result.slice(index+patch.find.length);}return result;
}
module.exports={applyLwfPatches};
