/* Original Forge native character-only pause/delay. MIT.
 * Executed queued setter/gate/clock evidence: native-preview-character-pause.py.
 * These commands hold phase/key time and CHARACTER LWF progress while effect
 * LWF, camera and existing snapshot schedulers continue; they never become pauseAll or select a character ID. */
export function nativePauseInteger(value){const n=Number(value);return Number.isNaN(n)?0:Math.trunc(Math.max(-2147483648,Math.min(2147483647,n)));}
export class CharacterPauseState {
 constructor(){this.pause=0;this.delay=0;this.period=0;this.counter=0;this.paused=false;}
 pauseFor(duration){this.pause=nativePauseInteger(duration);}
 delayFor(duration,period){this.delay=Math.max(1,nativePauseInteger(duration));this.period=Math.max(1,nativePauseInteger(period));}
 snapshot(){return {pause:this.pause,delay:this.delay,period:this.period,counter:this.counter};}
 step(stride=1){if(stride!==1&&stride!==2)throw Error('Choose a supported native character-step speed.');let updateCharacters=true,advancePhaseClock=true,paused=false;if(this.pause>0||this.delay>=1){updateCharacters=false;advancePhaseClock=false;paused=true;if(this.pause<=0){const remainder=this.counter%this.period;this.counter=(this.counter+1)|0;if(remainder===0){updateCharacters=true;advancePhaseClock=true;paused=false;}}if(this.pause>0)this.pause-=stride;if(this.delay>0)this.delay-=stride;if(this.pause<=0&&this.delay<=0){paused=false;advancePhaseClock=true;}}this.paused=paused;return {updateCharacters,advancePhaseClock,paused,...this.snapshot()};}
}
export function installCharacterPauseBinders(mark,num,push){
 if(typeof mark!=='function'||typeof num!=='function'||typeof push!=='function')throw Error('The native character-pause binder is incompatible.');
 // Install after the original bindings, replacing their incorrect signatures.
 mark('pauseChara',L=>{push({type:'pauseChara',frame:nativePauseInteger(num(L,1)),duration:nativePauseInteger(num(L,2))});});
 mark('delayChara',L=>{push({type:'delayChara',frame:nativePauseInteger(num(L,1)),duration:nativePauseInteger(num(L,2)),interval:nativePauseInteger(num(L,3))});});
}
export class CharacterPauseCommands {
 constructor(runner){this.runner=runner;this.state=new CharacterPauseState();this.last=null;this.originalSync=null;this.lastSync=null;this.controlled=false;}
 prepare(){this.clear();}
 execute(command){if(command.type!=='pauseChara'&&command.type!=='delayChara'&&command.type!=='delayAll')return false;if(this.runner._isMovieModeCutinFrame?.(command.frame))return false;this.controlled=true;const args=command.args||[];if(command.type==='pauseChara')this.state.pauseFor(command.duration??args[1]);else this.state.delayFor(command.duration??args[1],command.interval??command.flag??args[2]);return true;}
 applySync(paused){const chara=this.runner.chara;if(chara?.setSyncPause){const actual=!!chara._syncPaused;if(this.originalSync===null)this.originalSync=actual;else if(this.lastSync!==null&&actual!==this.lastSync)this.originalSync=actual;const desired=this.originalSync||paused;if(actual!==desired)chara.setSyncPause(desired);this.lastSync=desired;}}
 beforeCharacterStep(frame,stride=1){this.last=this.state.step(stride);if(!this.controlled)return this.last;this.applySync(this.last.paused);if(this.state.pause<=0&&this.state.delay<=0){this.restoreSync();this.controlled=false;}return this.last;}
 resume(){if(this.controlled)this.applySync(this.state.paused);}

 restoreSync(){const chara=this.runner.chara;if(this.originalSync!==null&&chara?.setSyncPause&&!!chara._syncPaused===this.lastSync&&!!chara._syncPaused!==this.originalSync)chara.setSyncPause(this.originalSync);this.originalSync=null;this.lastSync=null;}

 seek(target){const replay=replayPauseTimeline(this.runner.commands,target,this.runner.highSpeed?2:1,Math.trunc(Number(this.runner.phase)||0),{skipCommand:c=>!!this.runner._isMovieModeCutinFrame?.(c.frame)});this.restoreSync();this.state=new CharacterPauseState();Object.assign(this.state,replay.character);this.state.paused=replay.characterPaused;this.controlled=this.state.pause>0||this.state.delay>0;this.last=null;return replay;}
 clear(){this.restoreSync();this.controlled=false;this.state=new CharacterPauseState();this.last=null;}
}

// Original all-view +bc/+c0 gate. No public global-delay setter is inferred:
// the supplied Lua delayAll binding actually calls DelayCharacter.
export class GlobalPauseState {
 constructor(){this.pause=0;this.delay=0;this.period=0;this.counter=0;}
 pauseFor(duration){this.pause=Math.max(1,nativePauseInteger(duration));}
 snapshot(){return {pause:this.pause,delay:this.delay,period:this.period,counter:this.counter};}
 step(stride=1){if(stride!==1&&stride!==2)throw Error('Choose a supported native global-step speed.');let execute=true;if(this.pause>0||this.delay>=1){execute=false;if(this.pause<=0){execute=this.counter%this.period===0;this.counter=(this.counter+1)|0;}if(this.pause>0)this.pause-=stride;if(this.delay>0)this.delay-=stride;if(this.pause<=0&&this.delay<1)execute=true;}return {execute,...this.snapshot()};}
}
function pausePhase(command){return Math.trunc(Number(command.forgePhase??command.phase)||0);}
export function replayPauseTimeline(commands,target,stride=1,phase=0,{maxExecutions=2000000,skipCommand,onExecution}={}){
 if(!Number.isSafeInteger(target)||target<0||target>1000000||![1,2].includes(stride)||!Number.isSafeInteger(phase)||!Number.isSafeInteger(maxExecutions)||maxExecutions<1||maxExecutions>2000000)throw Error('Choose a supported pause-preview frame and speed.');
 const global=new GlobalPauseState(),character=new CharacterPauseState(),due=(Array.isArray(commands)?commands:[]).map((command,index)=>({command,index})).filter(({command})=>['pauseAll','pauseChara','delayChara','delayAll'].includes(command.type)&&pausePhase(command)===phase&&!skipCommand?.(command)).sort((a,b)=>(Number(a.command.frame)||0)-(Number(b.command.frame)||0)||Number(a.command.forgeOrder??a.index)-Number(b.command.forgeOrder??b.index));let frame=0,index=0,executions=0,executedControllerCount=0,last=null,lastCharacterFrame=null;
 while(executions<maxExecutions){executions++;const globalGate=global.step(stride);if(!globalGate.execute)continue;executedControllerCount++;while(index<due.length&&(Number(due[index].command.frame)||0)<=frame){const command=due[index++].command,args=command.args||[];if(command.type==='pauseAll')global.pauseFor(command.duration??args[1]);else if(command.type==='pauseChara')character.pauseFor(command.duration??args[1]);else character.delayFor(command.duration??args[1],command.interval??command.flag??args[2]);}onExecution?.({frame,stride,phase,elapsedExecutions:executions,executedControllerCount,lastCharacterFrame});last=character.step(stride);if(last.updateCharacters)lastCharacterFrame=frame;const sampledFrame=frame,nextFrame=frame+(last.advancePhaseClock?stride:0);if(sampledFrame>=target)return {sampledFrame,nextFrame,executions,elapsedExecutions:executions,elapsedSeconds:executions/60,executedControllerCount,stride,phase,lastCharacterFrame,global:global.snapshot(),character:character.snapshot(),characterPaused:last.paused,characterGate:last};frame=nextFrame;}
 throw Error('This pause sequence takes too long to seek safely. Shorten its pause or choose an earlier preview frame.');
}
