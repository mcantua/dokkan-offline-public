/* Original Forge beginner recording control. MIT.
 * Forwards the existing player action; no additional capture/native interface.
 */
export function mountRecordControl(bar){
 if(!bar||bar.querySelector('#forge-record-preview'))return null;
 const button=document.createElement('button');button.id='forge-record-preview';button.type='button';
 button.textContent='Record preview video';button.disabled=true;
 button.title='Record this animation from the beginning and save the video on your device.';
 button.style.cssText='margin-left:12px;padding:10px;background:#245b50;color:white;border:0;border-radius:8px;max-width:100%;font:inherit;cursor:pointer';
 bar.append(button);
 let closed=false,autoStarted=false;
 const exportFrames=Number(globalThis.__forgeAnimation?.text?.match(/^-- FORGE_SEQUENCE_EXPORT ([0-9]{1,5})$/m)?.[1]||0);
 const selectedSong=/^-- FORGE_SEQUENCE_MUSIC /m.test(globalThis.__forgeAnimation?.text||'');
 const autoExport=Number.isInteger(exportFrames)&&exportFrames>0&&exportFrames<=5400;
 const sync=()=>{
  if(closed)return;
  const original=document.getElementById('btnRecord'),recording=/^stop\s+rec\b/i.test(original?.textContent?.trim()||'');
  const overlay=document.querySelector('[aria-label="Animation recording"]');
  button.disabled=!original||original.disabled||recording||!!overlay;
  button.textContent=recording?'Recording preview…':overlay?'Preparing video…':'Record preview video';
  if(autoExport&&!autoStarted&&original&&!original.disabled&&!overlay&&(!selectedSong||!document.querySelector('[data-forge-bgm-status="true"]'))){autoStarted=true;button.disabled=true;original.click();}
 };
 button.onclick=()=>{
  const original=document.getElementById('btnRecord');
  if(button.disabled||!original||original.disabled)return;
  button.disabled=true;
  original.click();
 };
 // A small fixed-cost poll also handles late player initialization and failure
 // recovery without watching every animation-frame/HUD DOM mutation.
 const timer=setInterval(sync,250);sync();
 const dispose=()=>{if(closed)return;closed=true;clearInterval(timer);button.onclick=null;};
 addEventListener('pagehide',dispose,{once:true});
 return Object.freeze({button,dispose});
}
