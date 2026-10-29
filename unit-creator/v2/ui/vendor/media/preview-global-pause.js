/* Original Forge all-view pause gate. MIT. Original ARM64 evidence:
 * tests/native-preview-global-pause.py. delayAll is a character-delay alias in
 * the supplied native build, rather than an invented global modulo command. */
import {nativePauseInteger,GlobalPauseState,replayPauseTimeline} from './preview-character-pause.js';
export function installGlobalPauseBinders(mark,num,push){if(typeof mark!=='function'||typeof num!=='function'||typeof push!=='function')throw Error('The native all-view pause binder is incompatible.');mark('pauseAll',L=>{push({type:'pauseAll',frame:nativePauseInteger(num(L,1)),duration:nativePauseInteger(num(L,2))});});mark('delayAll',L=>{push({type:'delayAll',frame:nativePauseInteger(num(L,1)),duration:nativePauseInteger(num(L,2)),interval:nativePauseInteger(num(L,3))});});}
export class GlobalPauseCommands {
 constructor(runner){this.runner=runner;this.state=new GlobalPauseState();this.controlled=false;this.originalRemain=null;this.lastRemain=null;this.last=null;}
 prepare(){this.clear();}
 execute(command){if(command.type!=='pauseAll'||this.runner._isMovieModeCutinFrame?.(command.frame))return false;if(!this.controlled)this.originalRemain=Number(this.runner.pauseRemain)||0;this.controlled=true;this.state.pauseFor(command.duration??command.args?.[1]);this._remaining();return true;}
 _remaining(){if(!this.controlled)return;if(this.lastRemain!==null&&this.runner.pauseRemain!==this.lastRemain)this.originalRemain=Number(this.runner.pauseRemain)||0;this.lastRemain=Math.max(this.originalRemain||0,this.state.pause,this.state.delay,0);this.runner.pauseRemain=this.lastRemain;}

 _release(){if(this.originalRemain!==null&&this.runner.pauseRemain===this.lastRemain)this.runner.pauseRemain=this.originalRemain;this.originalRemain=null;this.lastRemain=null;this.controlled=false;}
 beforeGlobalStep(frame,stride=1){this.last=this.state.step(stride);if(this.controlled){this._remaining();if(this.state.pause<=0&&this.state.delay<=0)this._release();}return this.last;}
 seek(target){const replay=replayPauseTimeline(this.runner.commands,target,this.runner.highSpeed?2:1,Math.trunc(Number(this.runner.phase)||0),{skipCommand:c=>!!this.runner._isMovieModeCutinFrame?.(c.frame)});this._release();this.state=new GlobalPauseState();Object.assign(this.state,replay.global);this.controlled=this.state.pause>0||this.state.delay>0;if(this.controlled){this.originalRemain=Number(this.runner.pauseRemain)||0;this._remaining();}this.last=null;return replay;}
 clear(){this._release();this.state=new GlobalPauseState();this.last=null;}
}
