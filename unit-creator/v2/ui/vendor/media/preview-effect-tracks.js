/* Original Forge native effect-track adapter. MIT.
 * Native callbacks/tree/selector/update arithmetic are exercised by
 * tests/native-effect-track-values.py and native-preview-effect-selector.py.
 * This applies external keys to loaded LWF players; it does not simulate the
 * game controller, reconstruct absent battle attachment geometry or edit Lua. */
import { interpolateComponent } from './native-tcb.js';
import { EffectAttachmentState, nativeEffectBaseScale } from './preview-effect-attachment.js';
import {fixedBaseAttachmentHistory} from './preview-effect-history.js';
const f=Math.fround,number=(value,fallback=0)=>Number.isFinite(Number(value))?Number(value):fallback;
const integer=value=>Math.max(-2147483648,Math.min(2147483647,Math.trunc(number(value))));
const phase=command=>integer(command.forgePhase??command.phase),id=command=>integer(command.workId??command.args?.[1]);
const kinds=Object.freeze({setEffMoveKey:'move',setEffScaleKey:'scale',setEffRotateKey:'rotate',setEffColorKey:'color',setEffAlphaKey:'alpha'});
function invocationOrder(commands){return commands.map((command,index)=>({command,index,order:Number.isSafeInteger(command.forgeOrder)?command.forgeOrder:index})).sort((a,b)=>a.order-b.order||a.index-b.index);}
function insert(keys,key){if(!keys.some(old=>old.frame===key.frame)){keys.push(key);keys.sort((a,b)=>a.frame-b.frame);}}
function component(keys,frame,index){if(!keys.length)return null;if(frame<keys[0].frame)return 0;return interpolateComponent(keys,frame,key=>key.values[index]??0);}
function byte(value,clamp=true){const x=integer(f(value));return clamp?Math.max(0,Math.min(255,x)):((x%256)+256)%256;}
export function nativeEffectSample(tracks,frame,{anchor=[0,0],rgba=[255,255,255,255]}={}){
 const at=integer(frame),base=rgba.map(value=>f(byte(value)/255)),sample=(kind,index=0)=>component(tracks[kind]||[],at,index);
 const move=[sample('move'),sample('move',1)],scale=[sample('scale'),sample('scale',1)],rotation=sample('rotate'),color=[sample('color'),sample('color',1),sample('color',2)],alpha=sample('alpha');
 const alphaKeys=tracks.alpha||[],interpolated=alphaKeys.length>1&&at>=alphaKeys[0].frame&&at<alphaKeys[alphaKeys.length-1].frame;
 return{move:move[0]===null?null:move.map((value,index)=>f(f(number(anchor[index]))+value)),scale:scale[0]===null?null:scale,rotate:rotation,color:color[0]===null?rgba.slice(0,3).map(value=>byte(value)):color.map((value,index)=>byte(f(value*base[index]))),alpha:alpha===null?byte(rgba[3]):byte(f(alpha*base[3]),interpolated)};
}
export function effectTrackPlan(commands,{initialSide=false,effectCommands=value=>value}={}){
 const original=Array.isArray(commands)?commands:[],shadows=effectCommands(original),ordered=invocationOrder(original),mirror=new Map();let side=!!initialSide;
 for(const{command,index}of ordered){if(phase(command)!==0)continue;if(command.type==='flipAttackerSide'&&integer(command.args?.[0]??command.frame)===0)side=!side;else if(command.type==='setEffRotateKey')mirror.set(index,side?-1:1);}
 const groups=new Map();
 const group=command=>{const key=phase(command)+':'+id(command);if(!groups.has(key))groups.set(key,{phase:phase(command),workId:id(command),entry:null,tracks:{move:[],scale:[],rotate:[],color:[],alpha:[]}});return groups.get(key);};
 for(const{command,index}of ordered){
  const kind=kinds[command.type];if(kind){const source=shadows[index]||command,args=source.args||[],values=[source.a??args[2],source.b??args[3],source.c??args[4]].map(value=>f(number(value)));if(kind==='rotate')values[0]=f(values[0]*(mirror.get(index)??1));if(kind==='scale')values[2]=1;insert(group(command).tracks[kind],{frame:integer(source.frame??args[0]),values,t:.5,c:-1,b:0});}
  else if(command.type==='entryEffect'){const plan=group(command);if(!plan.entry)plan.entry=command;}
 }
 // Native view Update inserts its initial offset after the explicit key queue.
 // Same-frame explicit keys therefore retain ownership of their first record.
 for(const plan of groups.values())if(plan.entry){const entry=plan.entry,start=integer(entry.frame);let entrySide=!!initialSide;for(const{command}of ordered)if(command.type==='flipAttackerSide'&&phase(command)===plan.phase&&integer(command.args?.[0]??command.frame)<=start)entrySide=!entrySide;insert(plan.tracks.move,{frame:start,values:[f(number(entry.x)*(entrySide?-1:1)),f(number(entry.y)),0],t:.5,c:1,b:0});}
 return groups;
}
export class EffectTracksCommands{
 constructor(runner,{initialSide=()=>false,attachmentState}={}){this.runner=runner;this.initialSide=typeof initialSide==='function'?initialSide:()=>!!initialSide;this.attachments=attachmentState||new EffectAttachmentState(runner,{initialSide:this.initialSide,history:context=>fixedBaseAttachmentHistory(runner,context)});this.updateToken={};this.plans=new Map();this.saved=new Map();this.frame=0;this.warned=new Set();}
 prepare(commands=[]){this.clear();this.attachments.prepare?.(commands);this.plans=effectTrackPlan(commands,{initialSide:this.initialSide(),effectCommands:value=>this.runner.forgeVisual?.effectCommands?.(value)??value});}
 execute(command){this.attachments.execute?.(command);return Object.prototype.hasOwnProperty.call(kinds,command.type);}
 _warn(message){if(!this.warned.has(message)){this.warned.add(message);this.runner.log?.(message);}}
 _save(player){if(this.saved.has(player))return;const state={};for(const key of['x','y','z','sx','sy','rot','alpha','parentOffX','parentOffY','parentScaleX','parentScaleY','followParent','forgeEffectColor','forgeEffectAlpha'])state[key]={own:Object.prototype.hasOwnProperty.call(player,key),value:player[key]};this.saved.set(player,state);}
 update(frame){this.frame=integer(frame);this.updateToken={};this._apply();}
 render(){this._apply();}
 _apply(){
  const currentPhase=integer(this.runner.phase),seen=new Set();
  for(const prepared of this.runner._fxPrepared?.values?.()||[]){
   const cmd=prepared.cmd;if(!cmd||cmd.type!=='entryEffect')continue;
   const plan=this.plans.get(phase(cmd)+':'+id(cmd));if(!plan?.entry||plan.phase!==currentPhase)continue;
   for(const player of Array.isArray(prepared.player)?prepared.player:[prepared.player]){
    if(!player||seen.has(player)||player.expired||player.dormant||this.frame<integer(cmd.frame))continue;seen.add(player);this._save(player);
    const rgba=prepared.pack?.rgba;if(!rgba||!['r','g','b','a'].every(key=>Number.isFinite(Number(rgba[key])))){this._warn('This effect is missing its game color metadata; its preview color and opacity cannot be verified.');}
    let attachmentScale=1;const validRGBA=rgba&&['r','g','b','a'].every(key=>Number.isFinite(Number(rgba[key]))),sample=nativeEffectSample(plan.tracks,this.frame,{rgba:validRGBA?[rgba.r,rgba.g,rgba.b,rgba.a]:[255,255,255,255]});
    if(sample.move){const[x,y]=sample.move;player.parentOffX=x;player.parentOffY=y;const mode=integer(cmd.attr)&0x60;if(mode){const actor=this.runner.chara?.chars?.get?.(Number(cmd.target??player.parentCharaId)),point=this.attachments.resolve({entry:plan.entry,actor,frame:this.frame,updateToken:this.updateToken});if(point.known){player.followParent=false;player.x=f(f(point.position[0])+x);player.y=f(f(point.position[1])+y);const base=(mode&0x40)||point.firstUpdate?nativeEffectBaseScale(cmd.effectId??player.effectId,actor):1;if(base===null)this._warn('The followed character’s size metadata is unavailable for this effect.');else{attachmentScale=f(base*((mode&0x40)?point.depth:1));player.parentScaleX=1;player.parentScaleY=1;}}else{if(actor){player.x=f(f(number(actor.x))+x);player.y=f(f(number(actor.y))+y);}this._warn(point.reason||'The effect’s attachment placement is unavailable in this preview.');}}else{player.x=x;player.y=y;}}
    player.sx=f((sample.scale?.[0]??1)*attachmentScale);player.sy=f((sample.scale?.[1]??1)*attachmentScale);
    player.rot=sample.rotate??0;
    // Native color and alpha factors come from the actual effect_pack bytes.
    // Unknown metadata must not replace the player's existing appearance.
    if(validRGBA){player.forgeEffectColor=sample.color;player.forgeEffectAlpha=sample.alpha;player.alpha=sample.alpha/255;}
    this.runner.lwf?._applyFx?.(player);
   }
  }
 }
 clear(){for(const[player,state]of this.saved){for(const[key,saved]of Object.entries(state)){if(saved.own)player[key]=saved.value;else delete player[key];}this.runner.lwf?._applyFx?.(player);}this.saved.clear();this.plans.clear();this.warned.clear();this.frame=0;}
}
