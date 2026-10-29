/* Original Forge effect attachment arithmetic. MIT.
 * Native getter1f82948, real per-instance LWF records33b7900/33ba7cc and
 * depth function1f8ea88; tests/native-effect-attachment.py. No battle state is
 * inferred. This helper reads the live rendered named instance, not a tag label. */
const f=Math.fround,finite=(value,fallback=0)=>Number.isFinite(Number(value))?Number(value):fallback;
export function nativeAttachmentDepth(z){const clamped=f(Math.max(-128,Math.min(128,f(finite(z))))),factor=clamped<0?f(0.0065104165114462376):f(0.0078125);return f(1-f(clamped*factor));}
export function nativeAttachmentPoint({position=[0,0],scale=[1,1],z=0,hugeScale=1,hugeEnabled=false,local=null}={}){
 const origin=position.map(value=>f(finite(value)));if(!local)return{position:origin,depth:1};const depth=nativeAttachmentDepth(z),huge=f(hugeEnabled?finite(hugeScale,1):1),scaled=scale.map(value=>f(f(f(finite(value,1))*depth)*huge));return{position:origin.map((value,index)=>f(f(f(finite(local[index]))*scaled[index])+value)),depth};
}
export function liveAttachmentInstance(actor,tag=0){
 const lwf=actor?.useSp?actor.spLwf:actor?.lwf,n=Math.max(-2147483648,Math.min(2147483647,Math.trunc(finite(tag)))),name='t'+(n<0?'-'+String(-n).padStart(2,'0'):String(n).padStart(3,'0'));
 if(!lwf?.data||typeof lwf.z$Fj!=='function')return{known:false,reason:'The loaded character runtime does not expose its native instance table.'};
 // Same string→instanceID→current-instance selection used by native LWF::
 // GetInstance. Recursive Movie searches can pick a different duplicate tag.
 const strings=lwf.data.strings,names=lwf.data.instanceNames;if(!Array.isArray(strings)||!Array.isArray(names))return{known:false,reason:'The character instance-name table is unavailable.'};
 const index=names.findIndex(entry=>strings[entry.stringId]===name);if(index<0)return{known:true,name,local:null};const instance=lwf.z$Fj(index);if(!instance)return{known:true,name,local:null};const matrix=instance.z$c;
 if(!matrix||![matrix.translateX,matrix.translateY].every(Number.isFinite))return{known:false,reason:'The current attachment pose has not produced its native matrix.'};
 const scene=actor.movie;if(typeof scene?.localToGlobal!=='function')return{known:false,reason:'The character scene origin is unavailable.'};const origin=scene.localToGlobal({x:0,y:0}),axisX=scene.localToGlobal({x:1,y:0}),axisY=scene.localToGlobal({x:0,y:1});if(!origin||![origin.x,origin.y,axisX?.x,axisX?.y,axisY?.x,axisY?.y].every(Number.isFinite)||axisX.x-origin.x!==1||axisX.y-origin.y!==0||axisY.x-origin.x!==0||axisY.y-origin.y!==1)return{known:false,reason:'The character scene has an unsupported attachment-coordinate transform.'};
 // The public player deliberately centers its attached scene in a canvas.
 // Native LWFLayer::setMovie attaches at the local origin, so remove only the
 // actually rendered scene-origin translation, never a guessed stage factor.
 return{known:true,name,local:[f(f(matrix.translateX)-f(origin.x)),f(-f(f(matrix.translateY)-f(origin.y)))],instance,matrix};
}
const sizeScales=[.8,.9,1.1,1.2,1.35,1.45,1.5,1.65,1.75,2.25,2.5].map(f);
export function nativeEffectBaseScale(effectId,actor){
 const id=Math.trunc(finite(effectId));if(id>=300&&id<=342||id===700){const raw=actor?.card?.character_size??actor?.characterSize;if(raw===null||raw===undefined||!Number.isFinite(Number(raw)))return null;const size=Math.trunc(Number(raw));return size>=0&&size<=10?sizeScales[size]:1;}if(id>=200&&id<=243&&actor?.hugeScaleActive){if(!Number.isFinite(Number(actor.hugeMul)))return null;return f(Number(actor.hugeMul));}return 1;
}
export function liveAttachmentPoint(actor,tag=0){
 if(!actor||![Number(actor.x),Number(actor.y)].every(Number.isFinite))return{known:false,reason:'The followed character position is unavailable.'};const named=liveAttachmentInstance(actor,tag);if(!named.known)return named;
 return{...named,...nativeAttachmentPoint({position:[actor.x,actor.y],scale:[actor.sx??1,actor.sy??1],z:actor.z,hugeScale:actor.hugeMul??1,hugeEnabled:!!actor.hugeScaleActive,local:named.local})};
}
// The native 0x20 mode records one real starting anchor; it must never follow
// the later pose merely because the public layer has a generic follow flag.
// Historical poses are not fabricated when seeking before any live capture.
export class EffectAttachmentState{
 constructor(runner,{initialSide=()=>false,history}={}){this.runner=runner;this.history=typeof history==='function'?history:null;this.initialSide=typeof initialSide==='function'?initialSide:()=>!!initialSide;this.source=null;this.fixed=new WeakMap();this.cold=new WeakMap();this.keySignatures=new WeakMap();}
 prepare(commands){if(this.source!==commands){this.reset();this.source=commands;}}
 execute(command){if(command?.type==='entryEffect'&&!this.runner._forgeVisualSeeking){this.fixed.delete(command);this.cold.delete(command);}return false;}
 _keys(keys){if(!Array.isArray(keys))return '';if(!this.keySignatures.has(keys))this.keySignatures.set(keys,JSON.stringify(keys));return this.keySignatures.get(keys);}
 _signature(actor){return JSON.stringify([this._keys(actor.posKeys),this._keys(actor.sclKeys),!!this.runner.highSpeed,!!this.initialSide(),actor.card?.id??null,!!actor.hugeScaleActive,actor.hugeMul??1,actor.refOverride?[actor.x,actor.y,actor.z,actor.sx,actor.sy,actor.anime,actor.movie?.currentFrame]:null]);}
 resolve({entry,actor,frame,updateToken}={}){
  if(!entry||!actor)return{known:false,reason:'The followed character is unavailable.'};
  const mode=Math.trunc(finite(entry.attr))&0x60;if(!mode)return{known:true,position:[0,0],depth:1};
  const sample=()=>liveAttachmentPoint(actor,entry.tparam??0);
  if(mode&0x40)return sample();
  const signature=this._signature(actor),lwf=actor.lwf,spLwf=actor.spLwf,card=actor.card,old=this.fixed.get(entry);
  if(old&&old.signature===signature&&old.lwf===lwf&&old.spLwf===spLwf&&old.card===card){
   const initialFrame=Math.trunc(finite(frame))===old.frame;if(this.runner._forgeVisualSeeking)old.previewToken=updateToken;
   // A paused render reuses its actual update token. A new controller Exec may
   // hold the same phase frame, but native fixed mode already cleared follow
   // bits, so its first-only size must not be reapplied on that later update.
   const firstUpdate=this.runner._forgeVisualSeeking?initialFrame:old.point.reconstructed?initialFrame&&(!updateToken||old.updateToken===updateToken||old.previewToken===updateToken):!!updateToken&&(old.updateToken===updateToken||initialFrame&&old.previewToken===updateToken);
   return{...old.point,position:old.point.position.slice(),captured:true,firstUpdate};
  }
  const cold=this.cold.get(entry);if(this.runner._forgeVisualSeeking||cold){if(cold&&cold.signature===signature&&cold.lwf===lwf&&cold.spLwf===spLwf&&cold.card===card&&cold.frame===Math.trunc(finite(frame)))return{...cold.point};const reconstructed=this.history?.({entry,actor,frame,updateToken});if(reconstructed?.known){const point={...reconstructed,position:reconstructed.position.slice()};this.cold.delete(entry);this.fixed.set(entry,{signature,lwf,spLwf,card,frame:reconstructed.captureFrame,updateToken,point});return{...point,captured:true,firstUpdate:Math.trunc(finite(frame))===reconstructed.captureFrame};}const point=reconstructed||{known:false,reason:'Play this scene from the beginning once to capture this effect’s starting attachment before seeking.'};this.cold.set(entry,{signature,lwf,spLwf,card,frame:Math.trunc(finite(frame)),point});return point;}
  if(finite(frame)<finite(entry.frame))return{known:false,reason:'This attached effect has not started yet.'};
  const point=sample();if(point.known)this.fixed.set(entry,{signature,lwf,spLwf,card,frame:Math.trunc(finite(frame)),updateToken,point:{known:true,position:point.position.slice(),depth:point.depth}});return{...point,firstUpdate:!!point.known};
 }
 reset(){this.fixed=new WeakMap();this.cold=new WeakMap();this.keySignatures=new WeakMap();}
}
