/* Native character-opacity keys, reconstructed from original ARM64 execution.
 * Lua values truncate to signed integers; keys enter at frame0. Empty trees do
 * not change native opacity255. Before-first returns0, interpolated values clamp
 * then truncate, final endpoints wrap into the actual Node byte. MIT. */
import { interpolateComponent } from './native-tcb.js';
import { replayPauseTimeline } from './preview-character-pause.js';
export function nativeAlphaInteger(value){const n=Number(value);return Number.isNaN(n)?0:Math.trunc(Math.max(-2147483648,Math.min(2147483647,n)));}
const byte=value=>((nativeAlphaInteger(value)%256)+256)%256;
const phase=command=>nativeAlphaInteger(command.forgePhase??command.phase??0);
export function characterAlphaPlans(commands=[]){
 const groups=new Map(),ordered=commands.map((command,index)=>({command,index,order:Number.isSafeInteger(command.forgeOrder)?command.forgeOrder:index})).sort((a,b)=>a.order-b.order||a.index-b.index);
 for(const{command}of ordered){if(command.type!=='setAlphaKey')continue;const args=command.args||[],actor=nativeAlphaInteger(command.chara??args[1]),p=phase(command),key=p+':'+actor;let plan=groups.get(key);if(!plan)groups.set(key,plan={phase:p,actor,keys:[]});const frame=nativeAlphaInteger(command.keyFrame??command.frame??args[0]),value=Math.fround(nativeAlphaInteger(command.alpha??args[2]));if(!plan.keys.some(key=>key.frame===frame))plan.keys.push({frame,value,t:.5,c:-1,b:0});}
 for(const plan of groups.values())plan.keys.sort((a,b)=>a.frame-b.frame);return groups;
}
export function sampleCharacterAlpha(keys,frame){
 if(!keys?.length)return null;const at=nativeAlphaInteger(frame);if(at<keys[0].frame)return 0;const last=keys[keys.length-1];if(at>=last.frame)return byte(last.value);const value=interpolateComponent(keys,at,key=>key.value);return byte(Math.max(0,Math.min(255,value)));
}
export function installCharacterAlphaBinders(mark,num,push){
 if(typeof mark!=='function'||typeof num!=='function'||typeof push!=='function')throw Error('The native character-transparency binder is incompatible.');
 mark('setAlphaKey',L=>push({type:'setAlphaKey',frame:0,keyFrame:nativeAlphaInteger(num(L,1)),chara:nativeAlphaInteger(num(L,2)),alpha:nativeAlphaInteger(num(L,3))}));
}
export class CharacterAlphaCommands{
 constructor(runner){this.runner=runner;this.plans=new Map();this.saved=new Map();this.samples=new Map();this.warned=new Set();this.frame=null;}
 prepare(commands=[]){this.clear();this.plans=characterAlphaPlans(commands);}
 execute(command){return command.type==='setAlphaKey';}
 _warn(message){if(!this.warned.has(message)){this.warned.add(message);this.runner.log?.(message);}}
 _apply(){
  for(const[actor,value]of this.samples){const character=this.runner.chara?.chars?.get?.(actor);if(!character){this._warn('An animation character is unavailable for this transparency preview.');continue;}let saved=this.saved.get(character);if(!saved){saved={alpha:{own:Object.prototype.hasOwnProperty.call(character,'alpha'),value:character.alpha},native:{own:Object.prototype.hasOwnProperty.call(character,'forgeCharacterAlpha'),value:character.forgeCharacterAlpha},lastAlpha:null,lastNative:null};this.saved.set(character,saved);}character.alpha=value/255;character.forgeCharacterAlpha=value;saved.lastAlpha=character.alpha;saved.lastNative=value;this.runner.chara?._apply?.(character);}
 }
 update(frame,context){
  if(context?.updateCharacters===false)return;let at=nativeAlphaInteger(frame);
  if(this.runner._forgeVisualSeeking){const replay=replayPauseTimeline(this.runner.commands,Math.max(0,at),this.runner.highSpeed?2:1,nativeAlphaInteger(this.runner.phase),{skipCommand:command=>!!this.runner._isMovieModeCutinFrame?.(command.frame)});at=replay.lastCharacterFrame;if(at===null)return;}
  this.frame=at;this.samples.clear();const current=nativeAlphaInteger(this.runner.phase);for(const plan of this.plans.values())if(plan.phase===current)this.samples.set(plan.actor,sampleCharacterAlpha(plan.keys,at));this._apply();
 }
 render(){this._apply();}
 clear(){for(const[character,saved]of this.saved){if(character.alpha===saved.lastAlpha){if(saved.alpha.own)character.alpha=saved.alpha.value;else delete character.alpha;}if(character.forgeCharacterAlpha===saved.lastNative){if(saved.native.own)character.forgeCharacterAlpha=saved.native.value;else delete character.forgeCharacterAlpha;}this.runner.chara?._apply?.(character);}this.saved.clear();this.samples.clear();this.plans.clear();this.warned.clear();this.frame=null;}
}
