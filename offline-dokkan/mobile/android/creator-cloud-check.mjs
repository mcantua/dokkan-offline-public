// Actual shared Creator WebView reached through adb on our owned cloud emulator.
// No desktop browser, replacement native bridge or mocked core response.
import fs from 'node:fs';
import path from 'node:path';
import {execFileSync} from 'node:child_process';

const evidence=process.env.UC_ANDROID_EVIDENCE,adb=process.env.UC_ADB;
const phase=process.argv[2],reportPath=path.join(evidence,'offline-android-creator-result.json');
const pause=ms=>new Promise(resolve=>setTimeout(resolve,ms));
const requireValue=(value,message)=>{if(!value)throw Error(message);};
let endpoint;
for(let n=0;n<120;n++){
  try{const pages=await(await fetch('http://127.0.0.1:9223/json/list')).json();endpoint=pages.find(p=>p.type==='page'&&p.url==='https://offline.creator.local/index.html')?.webSocketDebuggerUrl;if(endpoint)break;}catch{}
  await pause(500);
}
requireValue(endpoint,'Actual Offline Creator WebView unavailable');
const socket=new WebSocket(endpoint),pending=new Map(),exceptions=[];let sequence=0;
await new Promise((resolve,reject)=>{socket.addEventListener('open',resolve,{once:true});socket.addEventListener('error',()=>reject(Error('Actual Offline Creator CDP failed')),{once:true});});
socket.addEventListener('message',({data})=>{
  const message=JSON.parse(data);
  if(message.id){const item=pending.get(message.id);if(!item)return;pending.delete(message.id);clearTimeout(item.timer);message.error?item.reject(Error(message.error.message)):item.resolve(message.result);}
  else if(message.method==='Runtime.exceptionThrown')exceptions.push(String(message.params.exceptionDetails.exception?.description||message.params.exceptionDetails.text).slice(0,1000));
});
function command(method,params={}){return new Promise((resolve,reject)=>{const id=++sequence,timer=setTimeout(()=>{pending.delete(id);reject(Error(method+' timed out'));},120000);pending.set(id,{resolve,reject,timer});socket.send(JSON.stringify({id,method,params}));});}
async function js(expression){const value=await command('Runtime.evaluate',{expression,awaitPromise:true,returnByValue:true,userGesture:true});if(value.exceptionDetails)throw Error(value.exceptionDetails.exception?.description||value.exceptionDetails.text);return value.result.value;}
async function ready(){for(let n=0;n<450;n++){if(await js(`window.__forgeWorkspaceStartup==='ready'&&!!window.OfflineCreatorUI&&!!window.OfflineCreator`))return;await pause(200);}throw Error('Actual Offline Creator did not start');}
function screenshot(name){fs.writeFileSync(path.join(evidence,name),execFileSync(adb,['-s','emulator-5554','exec-out','screencap','-p'],{maxBuffer:32*1024*1024}));}
await command('Runtime.enable');
try{
  await ready();
  if(phase==='finish'){
    const result=await js(`(async()=>{
      document.querySelectorAll('dialog[open]').forEach(dialog=>dialog.close());
      let battleProtected=false;try{await OfflineGameHost.loadBattle()}catch(error){battleProtected=error.message==='BATTLE_TRUSTED_PLAN_REQUIRED'}
      if(!battleProtected)throw Error('Isolated native battle runtime did not preserve trusted-plan authority');
      await createUnit(1002351);
      if(!state.project||state.project.source.database!=='eclipse')throw Error('Wrong selected native master');
      state.project.cardOverrides.name='Native Offline Creator check';scheduleSave();await flushSave();
      const key=state.project.key,host=OfflineCreatorHost,first=await host.call('offlineCreatorPrepare',{key});
      const projectDefinition=prepared=>OfflineDokkanCreator.projectToDefinition(prepared.project,{...prepared.context,isUnchangedMasterRows:async table=>prepared.unchangedTables.includes(table)});
      const original=await projectDefinition(first);
      state.project.cardOverrides.name='Native Offline Creator finished';scheduleSave();await flushSave();
      let stale=false,forged=false;
      try{await host.call('offlineCreatorFinish',{key,snapshot:first.snapshot,definition:original});}catch(error){stale=error.message==='CREATOR_SNAPSHOT_STALE';}
      const prepared=await host.call('offlineCreatorPrepare',{key}),definition=await projectDefinition(prepared);
      const wrong=structuredClone(definition);wrong.card.name='Not the saved project';
      try{await host.call('offlineCreatorFinish',{key,snapshot:prepared.snapshot,definition:wrong});}catch(error){forged=error.message==='CREATOR_PROJECTION_MISMATCH';}
      // Reach the actual Java whitelist directly, rather than only its JS wrapper.
      const authority=await new Promise((resolve,reject)=>{
        const id=9007199254740000,previous=window.__offlineCreatorReply;
        const timer=setTimeout(()=>{window.__offlineCreatorReply=previous;reject(Error('Native capability rejection timed out'));},30000);
        window.__offlineCreatorReply=message=>{if(message.id!==id)return previous(message);clearTimeout(timer);window.__offlineCreatorReply=previous;resolve(message.ok===false&&message.error==='UNSUPPORTED_OFFLINE_CREATOR_OPERATION');};
        window.OfflineCreator.postMessage(JSON.stringify({id,op:'sql',args:{sql:'DELETE FROM cards'}}));
      });
      const imported=await OfflineCreatorUI.finish(),replayed=await OfflineCreatorUI.finish();
      const versions=await Native.call('listProjectVersions',{key}),named=await Native.call('saveProjectVersion',{key,label:'Native saved version',expectedCurrentRevision:versions.currentRevision});
      return {isolatedBattleProtected:battleProtected,key,definitionId:imported.definitionId,version:imported.version,imported:imported.imported,instanceId:imported.instanceId,available:imported.available,newest:imported.library.main_id===imported.definitionId,storedName:imported.library.definitions.find(row=>row.definition_id===imported.definitionId)?.name,replayEqual:imported.definitionId===replayed.definitionId&&imported.version===replayed.version&&imported.instanceId===replayed.instanceId&&imported.library.epoch===replayed.library.epoch&&imported.library.revision===replayed.library.revision,staleRejected:stale,forgedProjectionRejected:forged,arbitrarySqlRejected:authority,savedVersion:!!named.saved,bannerDrawable:imported.banner?.drawable,source:state.project.source.database,scheme:location.protocol,innerWidth,pageWidth:document.documentElement.scrollWidth,actualJavaBridge:!!window.OfflineCreator};
    })()`);
    requireValue(result.isolatedBattleProtected&&result.imported&&result.newest&&result.replayEqual&&result.staleRejected&&result.forgedProjectionRejected&&result.arbitrarySqlRejected&&result.savedVersion,'Native Creator save/projection/capability/idempotency guard failed');
    requireValue(Number.isSafeInteger(result.instanceId)&&result.instanceId>0&&result.available===true,'Finishing a local custom unit must make one actual owned instance available');
    requireValue(result.storedName==='Native Offline Creator finished'&&result.scheme==='https:'&&result.source==='eclipse'&&result.actualJavaBridge&&result.bannerDrawable===false,'Native Creator source/result was not confirmed');
    requireValue(result.pageWidth<=result.innerWidth+1,'Native Creator must fit the emulator display');
    await js(`(async()=>{await document.fonts.ready;await new Promise(resolve=>requestAnimationFrame(()=>requestAnimationFrame(resolve)));return true;})()`);
    screenshot('offline-android-creator-finished.png');
    requireValue(exceptions.length===0,'Unhandled actual Creator WebView exception');
    fs.writeFileSync(reportPath,JSON.stringify({scope:'Actual shared Creator WebView, read-only selected master, Java private project store and JNI/C core in our own cloud Android app; our original game progression, not a finished battle scene',...result,native_store_reopened:false,unhandled_js_exceptions:exceptions,not_verified:['Playable battles and finished game screens','Drawable Creator banner','Physical folding/touch/keyboard','Other Android APIs']},null,2)+'\n');
  }else if(phase==='reopen'){
    const report=JSON.parse(fs.readFileSync(reportPath));
    const reopened=await js(`(async()=>{const key=${JSON.stringify(report.key)},project=await Native.call('loadProject',{key}),versions=await Native.call('listProjectVersions',{key});return {name:project.cardOverrides.name,source:project.source.database,versions:versions.versions.length,hasPinnedMaster:/^sha256:[a-f0-9]{64}$/.test(project.source.contentId)};})()`);
    requireValue(reopened.name===report.storedName&&reopened.source==='eclipse'&&reopened.versions>0&&reopened.hasPinnedMaster,'Creator project or versions did not survive force-stop/relaunch');
    requireValue(exceptions.length===0,'Unhandled actual Creator exception after reopen');
    report.native_store_reopened=reopened;report.unhandled_js_exceptions.push(...exceptions);fs.writeFileSync(reportPath,JSON.stringify(report,null,2)+'\n');
    screenshot('offline-android-creator-reopened.png');
  }else throw Error('Unknown native Creator check phase');
  console.log('Actual Offline Android Creator '+phase+' flow passed.');
}finally{socket.close();}
