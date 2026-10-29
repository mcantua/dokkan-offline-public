/* Original Forge source-binding audit. MIT. No DOM, codec or network imports.
 * Observe the genuine Lua host's successful main chunk at bind/rebind time.
 * Common helpers and the exact upstream prelude are separate chunks.
 */
const hosts=new WeakMap(),bound=new WeakMap(),LIMIT=2*1024*1024;
export const PREVIEW_NOTIFICATION='onDodgeExecuted = onDodgeExecuted or function(frame) end\n';
export function installBgmSourceCapture(host,bank){
 if(!host||typeof host.run!=='function'||!bank)return;
 bound.delete(bank);
 const prior=hosts.get(host);if(prior){prior.bank=bank;return;}
 const state={bank,run:host.run};hosts.set(host,state);
 host.run=function(source,chunkName='script',...args){
  const common=chunkName==='prelude'||chunkName==='ab_script/common/common.lua';
  if(!common)bound.delete(state.bank);
  let result;
  try{result=state.run.call(this,source,chunkName,...args);}catch(error){bound.delete(state.bank);throw error;}
  if(!common&&typeof source==='string'&&source.length<=LIMIT&&new TextEncoder().encode(source).length<=LIMIT)bound.set(state.bank,Object.freeze({text:source,path:String(chunkName)}));
  return result;
 };
}
export function boundBgmSource(bank){return bound.get(bank)||null;}
export function matchesBgmSource(actual,expected,path,allowPreviewFile=false){
 if(!actual||typeof expected!=='string'||expected.length>LIMIT||typeof path!=='string')return false;
 if(actual.path===path&&actual.text===expected)return true;
 return allowPreviewFile&&actual.path==='local/forge-composition.lua'&&actual.text===PREVIEW_NOTIFICATION+expected;
}
