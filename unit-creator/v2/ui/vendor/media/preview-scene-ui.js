/* Original Forge preview for source-backed native text-label scene helpers.
 * Exact resource/font/size evidence: docs/SCENE-UI-PREVIEW.md.
 * Explicit preview inputs supply runtime battle text/count; none is inferred
 * from a script, character ID or ability description. Other battle UI is not
 * represented by invented labels/effects. */
export const SCENE_UI_RESOURCES=Object.freeze({font:'/assets/fonts/en/black.otf',red:'/assets/layout/en/image/ingame/battle/ing_label_base_red.png'});
const LABEL_SHOW=new Set(['showCountdownLabel','showMessageLabel','showMessageLabelFlexible']);
const CONTEXT_COMMANDS=new Set(['setTriggerGaugeVisible','showEfficacyCutinLabel','hideEfficacyCutinLabel','adjustAttackerLabel','adjustEnemyLabel','hideKoScreen','fadeKoLabel','showAttackBreakEffects']);
let faceSequence=0;
const own=(object,key)=>Object.prototype.hasOwnProperty.call(object,key);
export function sceneUIContext(request=globalThis.__forgeAnimation){
 const input=request?.sceneUI;if(input==null)return null;
 if(!input||typeof input!=='object'||Array.isArray(input))throw Error('Invalid battle-label preview context.');
 const context={};
 if(own(input,'countdown')){if(!Number.isInteger(input.countdown)||input.countdown<0||input.countdown>9999)throw Error('Choose a countdown from 0 to 9999.');context.countdown=input.countdown;}
 if(own(input,'message')){if(typeof input.message!=='string'||!input.message.trim()||input.message.length>1000||/[\x00-\x08\x0b\x0c\x0e-\x1f]/.test(input.message))throw Error('Enter a readable preview battle message (up to 1000 characters).');context.message=input.message;}
 return context;
}
export function sceneUILabel(command,context){
 if(command.type==='showCountdownLabel')return context&&own(context,'countdown')?{kind:'countdown',text:String(context.countdown)+'...',fontSize:38}:null;
 if(command.type==='showMessageLabel'||command.type==='showMessageLabelFlexible')return context?.message?{kind:'message',text:context.message,fontSize:30}:null;
 // Both original native queued callbacks converge on 0x1f79360.
 return null;
}
async function boundedBytes(url,limit){
 const response=await fetch(url);if(!response.ok)throw Error('Battle-label resource unavailable: '+url);
 const declared=Number(response.headers.get('content-length'));if(Number.isFinite(declared)&&declared>limit)throw Error('Battle-label resource exceeds its preview limit.');
 if(!response.body?.getReader){const bytes=await response.arrayBuffer();if(bytes.byteLength>limit)throw Error('Battle-label resource exceeds its preview limit.');return bytes;}
 const reader=response.body.getReader(),parts=[];let length=0;try{for(;;){const part=await reader.read();if(part.done)break;length+=part.value.byteLength;if(length>limit){await reader.cancel();throw Error('Battle-label resource exceeds its preview limit.');}parts.push(part.value);}}finally{reader.releaseLock();}
 const bytes=new Uint8Array(length);let offset=0;for(const part of parts){bytes.set(part,offset);offset+=part.byteLength;}return bytes.buffer;
}
export class SceneUICommands {
 constructor(runner){this.runner=runner;this.overrideContext=undefined;this.context=sceneUIContext();this.panel=null;this.panelStatus=null;this.resources=null;this.pending=null;this.canvas=null;this.notice=null;this.current=null;this.labels=[];this.visible=true;this.messages=new Set();this.frame=0;}
 _host(){return this.runner.lwf?.host||null;}
 _context(){return this.overrideContext===undefined?sceneUIContext():this.overrideContext;}
 _mountPanel(commands){
  this.panelCommands=commands;
  const countdown=commands.some(c=>c.type==='showCountdownLabel'),message=commands.some(c=>c.type==='showMessageLabel'||c.type==='showMessageLabelFlexible');
  if(!countdown&&!message){this.panel?.remove();this.panel=null;return;}
  if(this.panel){this.panel.querySelector('[data-count-row]').hidden=!countdown;this.panel.querySelector('[data-message-row]').hidden=!message;return;}
  const panel=document.createElement('details');panel.dataset.forgeSceneUiControls='true';panel.style.cssText='box-sizing:border-box;position:relative;z-index:2;grid-column:1/-1;width:100%;max-width:700px;margin:12px auto;padding:12px;border:1px solid #526174;border-radius:10px;background:#18222c;color:#f5f7fa;font:16px sans-serif;';
  const summary=document.createElement('summary');summary.textContent='Battle text preview (optional)';summary.style.cursor='pointer';panel.appendChild(summary);
  const hint=document.createElement('p');hint.textContent='This move receives text from the battle. Enter preview values to see its labels. These values only change this preview.';panel.appendChild(hint);
  const form=document.createElement('form');form.style.cssText='display:grid;gap:12px;';
  const countRow=document.createElement('label');countRow.dataset.countRow='true';countRow.textContent='Count left';countRow.hidden=!countdown;const count=document.createElement('input');count.type='number';count.min='0';count.max='9999';count.step='1';count.inputMode='numeric';count.setAttribute('aria-label','Preview countdown, 0 to 9999');count.style.cssText='display:block;box-sizing:border-box;width:100%;font:16px sans-serif;padding:8px;';countRow.appendChild(count);form.appendChild(countRow);
  const messageRow=document.createElement('label');messageRow.dataset.messageRow='true';messageRow.textContent='Battle message';messageRow.hidden=!message;const text=document.createElement('textarea');text.maxLength=1000;text.rows=3;text.setAttribute('aria-label','Preview battle message, up to 1000 characters');text.style.cssText='display:block;box-sizing:border-box;width:100%;font:16px sans-serif;padding:8px;resize:vertical;';messageRow.appendChild(text);form.appendChild(messageRow);
  const buttons=document.createElement('div');buttons.style.cssText='display:flex;gap:8px;flex-wrap:wrap;';const apply=document.createElement('button');apply.type='submit';apply.textContent='Apply & restart preview';const reset=document.createElement('button');reset.type='button';reset.textContent='Clear preview text';for(const button of[apply,reset]){button.style.cssText='font:16px sans-serif;padding:10px 12px;';buttons.appendChild(button);}form.appendChild(buttons);
  const status=document.createElement('p');status.setAttribute('role','status');status.style.margin='0';form.appendChild(status);panel.appendChild(form);this.panel=panel;this.panelStatus=status;
  const context=this._context()||{};count.value=own(context,'countdown')?String(context.countdown):'';text.value=context.message||'';panel.open=(countdown&&!own(context,'countdown'))||(message&&!context.message);
  const applyContext=async clear=>{apply.disabled=true;reset.disabled=true;status.textContent='Preparing preview…';try{if(this.runner.ready===false)throw Error('Wait for this move to finish loading, then apply the preview text.');const input={};if(!clear){if(count.value!=='')input.countdown=Number(count.value);if(text.value.trim())input.message=text.value;}const candidate=sceneUIContext({sceneUI:input}),sourceCommands=this.panelCommands;await this._preloadContext(sourceCommands,candidate);if(!panel.isConnected||this.panelCommands!==sourceCommands)throw Error('The move changed while loading. Apply the preview text again.');this.overrideContext=candidate;this.context=candidate;if(clear){count.value='';text.value='';}this.runner.stop?.({silent:true});if(this.runner.play?.()===false)throw Error('The move is not ready to restart yet.');status.textContent=clear?'Preview text cleared.':'Preview restarted with your text.';}catch(error){status.textContent=error.message;}finally{apply.disabled=false;reset.disabled=false;}};
  form.addEventListener('submit',event=>{event.preventDefault();void applyContext(false);});reset.addEventListener('click',()=>{void applyContext(true);});
  const host=this._host(),mode=host?.closest?.('#modeLua');if(mode)mode.appendChild(panel);else{const anchor=host?.closest?.('.stage-wrap')||host?.closest?.('.stage-fit');if(anchor?.parentNode)anchor.parentNode.insertBefore(panel,anchor.nextSibling);else document.body.appendChild(panel);}
 }
 _warn(text){if(this.messages.has(text))return;this.messages.add(text);this.runner.log?.('Battle UI preview: '+text);const host=this._host();if(!host)return;if(!this.notice){const node=document.createElement('div');node.dataset.forgeSceneUiNotice='true';node.setAttribute('role','status');node.style.cssText='position:absolute;left:12px;right:12px;bottom:12px;padding:8px 12px;background:rgba(20,24,32,.9);color:white;font:16px sans-serif;z-index:10001;pointer-events:none;';host.appendChild(node);this.notice=node;}this.notice.textContent=[...this.messages].join(' ');}
 async preload(commands=[]){
  this.context=this._context();this._mountPanel(commands);await this._preloadContext(commands,this.context);
 }
 async _preloadContext(commands,context){
  if(!commands.some(command=>LABEL_SHOW.has(command.type)&&sceneUILabel(command,context)))return;
  if(this.resources)return;if(this.pending)return this.pending;
  this.pending=(async()=>{const[font,imageBytes]=await Promise.all([boundedBytes(SCENE_UI_RESOURCES.font,4*1024*1024),boundedBytes(SCENE_UI_RESOURCES.red,2*1024*1024)]);
   if(typeof FontFace!=='function')throw Error('This device cannot load the original battle-label font.');const fontFamily='ForgeNativeSceneLabel'+(++faceSequence);const face=new FontFace(fontFamily,font);await face.load();
   const blob=new Blob([imageBytes],{type:'image/png'}),url=URL.createObjectURL(blob),image=new Image();try{await new Promise((resolve,reject)=>{image.onload=resolve;image.onerror=()=>reject(Error('The original battle-label background cannot be decoded.'));image.src=url;});}finally{URL.revokeObjectURL(url);}
   if(image.naturalWidth!==506||image.naturalHeight!==136)throw Error('This game version uses an unsupported battle-label layout.');document.fonts.add(face);this.resources={face,image,fontFamily};
  })();try{await this.pending;}finally{this.pending=null;}
 }
 prepare(){this.clear();this.context=this._context();}
 execute(command){
  if(command.type==='setVisibleUI'){this.visible=Number(command.visible??command.args?.[1])!==0;this.render();if(!this.current)this._warn('The full game HUD is not present in this animation preview.');return true;}
  if(command.type==='hideCountdownLabel'||command.type==='hideMessageLabel'){const removed=this.labels.shift();if(removed?.canvas){removed.canvas.hidden=true;removed.canvas.remove();}this.current=this.labels[this.labels.length-1]||null;this.render();return true;}
  if(LABEL_SHOW.has(command.type)){
   const label=sceneUILabel(command,this.context);if(!label){this._warn(command.type==='showCountdownLabel'?'Choose a preview countdown to show this battle label.':'Enter preview battle-message text to show this label.');return true;}
   if(!this.resources)throw Error('Original battle-label resources have not finished loading.');this.labels.push(label);this.current=label;this.render();return true;
  }
  if(CONTEXT_COMMANDS.has(command.type)){this._warn('This move also uses battle HUD, enemy-order or result-screen content that this preview has not reconstructed.');return true;}
  return false;
 }
 update(frame){this.frame=Number(frame)||0;}
 render(){if(!this.visible){for(const label of this.labels)if(label.canvas)label.canvas.hidden=true;return;}for(const label of this.labels)this._paint(label);this.canvas=this.current?.canvas||null;}
 _paint(label){if(!label||!this.visible){if(label.canvas)label.canvas.hidden=true;return;}const host=this._host();if(!host||!this.resources)return;if(!label.canvas){label.canvas=document.createElement('canvas');label.canvas.dataset.forgeSceneUiLabel='true';label.canvas.width=506;label.canvas.height=136;label.canvas.style.cssText='position:absolute;left:50%;top:50%;transform:translate(-50%,-50%);z-index:9999;pointer-events:none;';host.appendChild(label.canvas);}const canvas=label.canvas;canvas.hidden=false;const ctx=canvas.getContext('2d');ctx.clearRect(0,0,506,136);ctx.drawImage(this.resources.image,0,0);ctx.font=label.fontSize+'px '+this.resources.fontFamily;ctx.textAlign='center';ctx.textBaseline='middle';ctx.fillStyle='#fff';const lines=label.text.split('\n'),lineHeight=label.fontSize;for(let i=0;i<lines.length;i++)ctx.fillText(lines[i],253,68-label.fontSize*.1+(i-(lines.length-1)/2)*lineHeight);canvas.dataset.labelKind=label.kind;canvas.setAttribute('aria-label',label.text);}
 clear(){for(const label of this.labels)label.canvas?.remove();this.canvas?.remove();this.notice?.remove();this.canvas=null;this.notice=null;this.current=null;this.labels=[];this.visible=true;this.messages.clear();this.frame=0;}
}
