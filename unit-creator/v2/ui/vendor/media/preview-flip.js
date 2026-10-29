/* Original Forge side/position adapter. MIT.
 * tests/native-preview-flip.py executes the unchanged supplied ARM64 Lua
 * binders, queued callbacks, position trees and effect scale instructions.
 * Key insertion runs at frame zero in Lua invocation order; a later side
 * toggle changes effect rendering, never the already inserted position keys. */
const number=(value,fallback=0)=>Number.isFinite(Number(value))?Number(value):fallback;
const phase=command=>number(command.forgePhase??command.phase);
const order=(commands)=>commands.map((command,index)=>({command,index,order:Number.isSafeInteger(command.forgeOrder)?command.forgeOrder:index})).sort((a,b)=>a.order-b.order||a.index-b.index);
const workId=player=>number(player.workIdNum??String(player.workId??'').split('_')[0],NaN);
export class FlipCommands {
 constructor(runner,{initialSide=false}={}){
  this.runner=runner;this.initialSide=!!initialSide;this.side=this.initialSide;this.commands=null;this.copies=new WeakMap();this.clones=new WeakSet();this.signs=new WeakMap();this.auto=new Map();this.layer=null;this.originalApply=null;this.applyWrapper=null;
  // Preserve the actual caller's side selection. The hosted player deliberately
  // forces its own enemySide=false; changing that would alter unrelated paths.
  const original=runner.setEnemySide,owner=this;
  if(typeof original==='function')runner.setEnemySide=function(on,...args){owner.initialSide=!!on;owner.side=owner.initialSide;owner.commands=null;return original.call(this,on,...args);};
 }
 _plan(commands=this.runner.commands){
  if(this.commands===commands)return;
  this.commands=commands;this.copies=new WeakMap();this.clones=new WeakSet();this.signs=new WeakMap();this.auto.clear();let side=this.initialSide,unsupported=false;
  for(const {command}of order(Array.isArray(commands)?commands:[])){
   if(command.type==='setEnableAutoXFlip'){const args=command.args||[],id=Math.trunc(number(args[0],NaN));if(Number.isInteger(id))this.auto.set(id,Math.trunc(number(args[1]))!==0);continue;}
   if(phase(command)!==0){if(['flipAttackerSide','setMoveKey','setEffMoveKey'].includes(command.type))unsupported=true;continue;}
   if(command.type==='flipAttackerSide'&&Math.trunc(number(command.args?.[0]??command.frame))===0)side=!side;
   else if(command.type==='setMoveKey'||command.type==='setEffMoveKey')this.signs.set(command,side?-1:1);
  }
  if(unsupported&&!this.warnedPhase){this.runner.log?.('Side-flip position keys across additional battle phases still need verification; those keys retain their original values.');this.warnedPhase=true;}
 }
 characterCommands(commands=[]){
  this._plan(this.runner.commands||commands);
  return commands.map(command=>{if(command.type!=='setMoveKey'||command.forgePreviousPosition)return command;const sign=this.signs.get(command);if(sign!==-1)return command;const copy={...command,x:-Math.fround(number(command.x))};if(Array.isArray(command.args)){copy.args=command.args.slice();copy.args[2]=copy.x;}return copy;});
 }
 effectCommand(command){
  if(!command||command.type!=='setEffMoveKey'||this.clones.has(command))return command;this._plan();
  if(this.copies.has(command))return this.copies.get(command);
  if(this.signs.get(command)!==-1)return command;
  const args=command.args?.slice(),x=-Math.fround(number(command.a??args?.[2]));if(args)args[2]=x;
  const copy={...command,a:x,...(args?{args}:{})};this.copies.set(command,copy);this.clones.add(copy);return copy;
 }
 effectCommands(commands=[]){this._plan();return commands.map(command=>this.effectCommand(command));}
 prepare(commands=this.runner.commands){this.clear();this._plan(commands);this.side=this.initialSide;this._bind();}
 execute(command){if(command.type==='setEnableAutoXFlip'){this._plan();return true;}if(command.type!=='flipAttackerSide')return false;this.side=!this.side;this._refresh();return true;}
 _bind(){
  const layer=this.runner.lwf;if(!layer||typeof layer._applyFx!=='function'||this.layer===layer)return;
  this._unbind();const owner=this,original=layer._applyFx;this.layer=layer;this.originalApply=original;
  this.applyWrapper=function(player,...args){
   if(!player)return original.call(this,player,...args);
   const enabled=owner.auto.has(workId(player))?owner.auto.get(workId(player)):!(number(player.attr)&0x1000);
   if(!owner.side||!enabled)return original.call(this,player,...args);
   const scale=player.sx;player.sx=-(scale==null?1:number(scale,1));try{return original.call(this,player,...args);}finally{player.sx=scale;}
  };layer._applyFx=this.applyWrapper;
 }
 _players(){const players=new Set();for(const effect of this.runner.activeEffects?.values?.()||[])for(const p of Array.isArray(effect.player)?effect.player:[effect.player])if(p)players.add(p);for(const entry of this.runner._fxPrepared?.values?.()||[])for(const p of Array.isArray(entry.player)?entry.player:[entry.player])if(p)players.add(p);return players;}
 _refresh(){this._bind();for(const player of this._players())this.layer?._applyFx?.(player);}
 update(){this._refresh();}
 render(){this._refresh();}
 _unbind(){if(this.layer&&this.layer._applyFx===this.applyWrapper)this.layer._applyFx=this.originalApply;this.layer=null;this.originalApply=null;this.applyWrapper=null;}
 clear(){const players=this._players();this._unbind();for(const player of players)this.runner.lwf?._applyFx?.(player);this.side=this.initialSide;this.commands=null;this.copies=new WeakMap();this.clones=new WeakSet();this.signs=new WeakMap();this.auto.clear();}
}
