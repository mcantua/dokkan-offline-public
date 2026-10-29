/* Forge original bounded fixed-attachment history. MIT.
 * A tag absent from the actual selected LWF instance-name table always takes
 * native getter1f82948's actor-base/depth1 branch, with no renderer refresh.
 * That branch needs exact historical controller position, not an invented
 * earlier LWF pose or an assumed RAF/scheduler clock. Named-pose replay remains
 * explicit until that independent clock/context can be established. */
import {evalVec3Track} from './native-tcb.js';
import {replayPauseTimeline} from './preview-character-pause.js';
const f=Math.fround,n=value=>Number.isFinite(Number(value))?Math.trunc(Number(value)):null;
const phase=command=>n(command?.forgePhase??command?.phase??0),actorId=command=>n(command?.chara??command?.args?.[1]);
const unknown=reason=>({known:false,reason});
export const attachmentTagName=value=>{const number=Math.max(-2147483648,Math.min(2147483647,n(value)??0));return't'+(number<0?'-'+String(-number).padStart(2,'0'):String(number).padStart(3,'0'));};
export function fixedBaseAttachmentHistory(runner,{entry,actor,frame,maxExecutions=100000}={}){
 const fallback='Play this scene from the beginning once to capture this effect’s starting attachment before seeking.';
 if(!entry||!actor||actor.refOverride)return unknown(fallback);const commands=runner?.commands,id=n(actor.id??entry.target),entryFrame=n(entry.frame),selected=n(frame),selectedPhase=phase(entry);
 if(!Array.isArray(commands)||!commands.includes(entry)||id===null||entryFrame===null||entryFrame<0||selected===null||selected<entryFrame||selectedPhase!==n(runner.phase??0))return unknown(fallback);
 if((runner.forgePhaseEnds?.selected?.length||0)>1||new Set(commands.map(phase)).size>1)return unknown('Starting attachments across multiple battle phases still need verification. '+fallback);
 if(runner._isMovieModeCutinFrame?.(entryFrame))return unknown(fallback);
 let replay;try{replay=replayPauseTimeline(commands,entryFrame,runner.highSpeed?2:1,selectedPhase,{maxExecutions,skipCommand:c=>!!runner._isMovieModeCutinFrame?.(c.frame)});}catch{return unknown(fallback);}
 if(selected<replay.sampledFrame)return unknown('This effect has not reached its first native update at this speed.');
 const ordered=commands.map((command,index)=>({command,index})).filter(({command})=>phase(command)===selectedPhase&&n(command.frame)!==null&&n(command.frame)<=replay.sampledFrame).sort((a,b)=>n(a.command.frame)-n(b.command.frame)||(n(a.command.forgeOrder)??a.index)-(n(b.command.forgeOrder)??b.index));
 let anime=id===0?0:100;for(const{command}of ordered)if(actorId(command)===id&&['changeAnime','changeAnimeAndStop'].includes(command.type)){const number=n(command.anime??command.args?.[2]);if(number===null)return unknown(fallback);anime=number;}
 const family=((anime%100)+100)%100,sp=family===30||family===31,lwf=sp?actor.spLwf:actor.lwf,name=attachmentTagName(entry.tparam??0),strings=lwf?.data?.strings,names=lwf?.data?.instanceNames;
 if(!Array.isArray(strings)||!Array.isArray(names))return unknown('The original character pack for this starting attachment is unavailable.');
 for(const candidate of[actor.lwf,actor.spLwf].filter(Boolean)){const table=candidate.data;if(!Array.isArray(table?.strings)||!Array.isArray(table?.instanceNames))return unknown(fallback);if(table.instanceNames.some(row=>table.strings[row.stringId]===name))return unknown(fallback);}
 // Source position trees already carry the actual native first-insert/side
 // shadows used by CharaLayer. Never sample its present x/y as a past value.
 const keys=actor.posKeys,last=replay.lastCharacterFrame;
 if(!Array.isArray(keys)||!keys.length||keys.length>30000||last===null||keys.some(k=>!Number.isFinite(Number(k.frame))||!Number.isFinite(Number(k.x))||!Number.isFinite(Number(k.y))||k.z!=null&&!Number.isFinite(Number(k.z)))||Math.min(...keys.map(k=>Number(k.frame)))>last)return unknown('This effect starts before a verified character placement. Choose starting positions or play from the beginning.');
 const shadows=runner.forgeVisual?.characterCommands?.(commands)||commands;
 for(const{command}of ordered)if(command.type==='setLastPosKey'&&actorId(command)===id&&!shadows.some(key=>key.type==='setMoveKey'&&key.forgePreviousPosition&&actorId(key)===id&&n(key.frame)===n(command.frame)))return unknown('Choose starting positions before reconstructing this attachment.');
 let position;try{position=evalVec3Track(keys,last,'pos');}catch{return unknown(fallback);}if(!position||![position.x,position.y].every(Number.isFinite))return unknown(fallback);
 return{known:true,position:[f(position.x),f(position.y)],depth:1,captureFrame:replay.sampledFrame,characterFrame:last,reconstructed:true,historyKind:'native-base-with-absent-tag',tag:name,family:sp?'sp':'battle'};
}
