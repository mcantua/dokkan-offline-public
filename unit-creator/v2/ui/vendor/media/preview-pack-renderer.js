/* Forge standalone LWF preview bridge. MIT.
 * Source artwork has no battle-parent controller: its parent RGBA is identity.
 * Every bitmap still uses the native PNG, fragment geometry and color pipeline.
 * The exact-hash PackPlayer adapter owns invocation and resource lifetimes. */
import {CompositorCommands} from './preview-compositor.js';
import {registerAtlasFit,forgetAtlasSource} from './preview-atlas-provenance.js';
const states=new WeakMap();
const state=pack=>{let value=states.get(pack);if(!value){value={token:{},binding:null,originals:new Set(),fits:new Set()};states.set(pack,value);}return value;};
const aborted=()=>{const error=new Error('The artwork preview changed while it was loading.');error.name='AbortError';return error;};
function dispose(value){const binding=value.binding;if(!binding)return;value.binding=null;binding.closed=true;if(binding.lwf.render===binding.wrapper){if(binding.descriptor)Object.defineProperty(binding.lwf,'render',binding.descriptor);else delete binding.lwf.render;}binding.compositor.clear();}
export function clearPackRenderer(pack){const value=state(pack);value.token={};dispose(value);for(const url of value.fits)forgetAtlasSource(url);value.fits.clear();for(const url of value.originals)URL.revokeObjectURL(url);value.originals.clear();}
export function beginPackPrepare(pack){clearPackRenderer(pack);pack.pause();try{pack.lwf?.destroy?.();}catch{}pack.lwf=null;pack.movie=null;pack.clip=null;for(const url of pack.blobUrls.values())URL.revokeObjectURL(url);pack.blobUrls.clear();return state(pack).token;}
export function beginPackLoad(pack){const value=state(pack);value.token={};dispose(value);pack.pause();try{pack.lwf?.destroy?.();}catch{}pack.lwf=null;pack.movie=null;pack.clip=null;return value.token;}
export function assertPackOperation(pack,token,{lwf,url}={}){if(state(pack).token===token)return;if(lwf)try{lwf.destroy?.();}catch{}if(url)URL.revokeObjectURL(url);throw aborted();}
export function preservePackAtlas(pack,token,fittedURL,sourceURL,options){assertPackOperation(pack,token,{url:fittedURL});if(!registerAtlasFit(fittedURL,sourceURL,options))throw Error('The original artwork atlas relationship could not be recorded.');const value=state(pack);value.originals.add(sourceURL);value.fits.add(fittedURL);}
export async function bindPackRenderer(pack,token,{Compositor=CompositorCommands}={}){assertPackOperation(pack,token);const value=state(pack),lwf=pack.lwf;if(!lwf||typeof lwf.render!=='function')throw Error('The artwork renderer did not load.');dispose(value);const runner={phase:0,commands:[],chara:{chars:new Map([[0,{canvas:pack.canvas,lwf,alpha:1}]])},activeEffects:new Map(),log:message=>pack.log(message)},compositor=new Compositor(runner),binding={lwf,compositor,closed:false,descriptor:Object.getOwnPropertyDescriptor(lwf,'render'),original:lwf.render,wrapper:null};value.binding=binding;
 try{await compositor.preload([]);assertPackOperation(pack,token);if(binding.closed||pack.lwf!==lwf)throw aborted();binding.wrapper=function(...args){if(binding.closed)return binding.original.apply(this,args);compositor.update(0);const result=binding.original.apply(this,args);compositor.render();return result;};lwf.render=binding.wrapper;return binding;}catch(error){if(value.binding===binding)dispose(value);throw error;}
}
