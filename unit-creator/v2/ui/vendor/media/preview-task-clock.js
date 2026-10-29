/* Original Forge task-clock reconstruction. MIT.
 * Shared native pause replay defines the first completed controller execution
 * sampling the selected frame. Two controller calls form one30fps stage tick.
 */
import {replayPauseTimeline} from './preview-character-pause.js';
export function nativeTaskClock(runner,start,target,phase=0){
 const begin=Math.max(0,Math.trunc(Number(start)||0)),selected=Math.max(0,Math.trunc(Number(target)||0)),stride=runner.highSpeed?2:1;
 let entry=null,previous=null,characterUpdates=0;
 const result=replayPauseTimeline(runner.commands,selected,stride,phase,{skipCommand:c=>!!runner._isMovieModeCutinFrame?.(c.frame),onExecution:sample=>{
  if(previous&&previous.frame>=begin&&sample.lastCharacterFrame===previous.frame)characterUpdates++;
  if(!entry&&sample.frame>=begin)entry=sample;
  previous=sample;
 }});
 if(previous&&previous.frame>=begin&&result.characterGate.updateCharacters)characterUpdates++;
 if(!entry)return{executingCalls:0,characterUpdates:0,schedulerTicks:0,cocosSeconds:0,stride,result};
 const executingCalls=result.executedControllerCount-entry.executedControllerCount+1;
 const schedulerTicks=Math.max(0,Math.floor(result.elapsedExecutions/2)-Math.ceil(entry.elapsedExecutions/2)+1);
 let cocosSeconds=0;
 // ActionInterval's first Cocos step sets elapsed0, not deltaTime.
 for(let tick=1;tick<schedulerTicks;tick++)cocosSeconds=Math.fround(cocosSeconds+Math.fround(1/30));
 return{executingCalls,characterUpdates,schedulerTicks,cocosSeconds,stride,result};
}
