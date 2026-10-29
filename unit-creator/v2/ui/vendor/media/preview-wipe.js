import {nativeTaskClock} from './preview-task-clock.js';
/* Original Forge adapter, MIT. Evidence: tests/fixtures/native-preview-wipe.json.
 * Actual source asset remains a user-downloaded preview resource, not bundled.
 */
export const WIPE_RESOURCE = '/assets/layout/en/image/ingame/sugoroku/transision.png';
const f = Math.fround;
export function nativeWipeGeometry(width, height, textureWidth, textureHeight) {
  const w = f(width), h = f(height), tw = f(textureWidth), th = f(textureHeight);
  return { width:w, height:h, textureWidth:tw, textureHeight:th, origin:[f(w*.5),f(h*.5)], travel:f(-(w*.5+tw*2)), rectangle:[0,0,f(w+4),h], leftCenter:[f(-w*.5-tw*.5+2),0], rightCenter:[f(w*.5+tw*.5+2),0], leftScale:[1,f(h/th)], rightScale:[-1,f(-h/th)] };
}
export function nativeWipeState(geometry) { return { state:1, progress:0, offset:geometry.travel, repeat:true, speed:1 }; }
export function advanceNativeWipe(state, geometry) {
  if (state.state !== 1 && state.state !== 2) return;
  state.progress = f(state.progress + f(state.speed / 5));
  if (state.state === 1) {
    if (state.progress > 1) {
      state.progress = 1; state.state = 3;
      if (state.repeat) { state.progress = 0; state.state = 2; state.repeat = false; }
      state.offset = 0;
    } else state.offset = f(geometry.travel * state.progress - geometry.travel);
  } else {
    if (state.progress > 1) { state.progress = 1; state.state = 0; }
    state.offset = f(geometry.travel * state.progress);
  }
  return [f(geometry.origin[0] + state.offset),geometry.origin[1]];
}
async function loadWipeImage() {
  const response = await fetch(WIPE_RESOURCE);
  if (!response.ok) throw Error('The original transition image is unavailable.');
  const limit = 4 * 1024 * 1024, declared = Number(response.headers.get('content-length'));
  if (Number.isFinite(declared) && declared > limit) throw Error('The transition image is too large to preview.');
  let blob;
  if (response.body?.getReader) {
    const reader=response.body.getReader(),parts=[];let length=0;
    try { for(;;) { const part=await reader.read();if(part.done)break;length+=part.value.byteLength;if(length>limit){await reader.cancel();throw Error('The transition image is too large to preview.');}parts.push(part.value); } }
    finally { reader.releaseLock(); }
    blob=new Blob(parts,{type:'image/png'});
  } else blob=await response.blob();
  if (blob.size > limit || blob.size < 24) throw Error('The transition image is invalid or too large.');
  const signature = new Uint8Array(await blob.slice(0,8).arrayBuffer());
  if ([137,80,78,71,13,10,26,10].some((value,index)=>signature[index]!==value)) throw Error('The transition image is not a PNG.');
  const url = URL.createObjectURL(blob), image = new Image();
  try {
    await new Promise((resolve,reject)=>{image.onload=resolve;image.onerror=()=>reject(Error('The transition image cannot be decoded.'));image.src=url;});
    if (!image.naturalWidth || !image.naturalHeight || image.naturalWidth > 8192 || image.naturalHeight > 8192) throw Error('The transition image dimensions are unsupported.');
    return {url,width:image.naturalWidth,height:image.naturalHeight};
  } catch(error) { URL.revokeObjectURL(url); throw error; }
}
export class WipeCommands {
  constructor(runner) { this.runner=runner; this.resource=null; this.pending=null; this.active=null; this.nativeMode=false; }
  async preload(commands=[]) {
    if (!commands.some(command=>command.type==='wipeInOut') || this.resource) return;
    if (!this.pending) this.pending=loadWipeImage();
    try { this.resource=await this.pending; } finally { this.pending=null; }
  }
  execute(command) {
    if (command.type !== 'wipeInOut') return false;
    if (!this.resource) throw Error('The original transition image has not finished loading.');
    this.clear();
    const host=this.runner.screenFade?.host||this.runner.lwf?.host, stage=host?.closest?.('#stage');
    const width=stage?.clientWidth||852, height=stage?.clientHeight||1536;
    const geometry=nativeWipeGeometry(width,height,this.resource.width,this.resource.height);
    this.active={command,start:Number(command.frame??command.args?.[0])||0,geometry,state:nativeWipeState(geometry),lastFrame:null,node:null,host};
    return true;
  }
  update(frame, context) {
    if(context?.nativeExecution === true)this.nativeMode=true;
    const active=this.active;if (!active || !active.host) return;
    const elapsed=Number(frame)-active.start;if (elapsed<0) return;
    if(!this.nativeMode || this.runner._forgeVisualSeeking){
      const step=Math.max(1,Math.round(Number(this.runner.step)||1));
      const ticks=active.lastFrame===null?Math.floor(elapsed/step)+1:Math.floor((frame-active.lastFrame)/step);
      for(let tick=0;tick<ticks;tick++)advanceNativeWipe(active.state,active.geometry);
      if(active.lastFrame===null)active.lastFrame=active.start+(ticks-1)*step;
      else active.lastFrame+=ticks*step;
    }
    this.render();
  }
  tick(seconds) {
    if(!Number.isFinite(seconds)||seconds<0)throw Error('Invalid transition scheduler time.');
    if(!this.nativeMode||!this.active)return;
    // The original Node::scheduleUpdate closure invokes this wipe once per
    // Cocos scheduler update. Its native arithmetic ignores delta seconds.
    advanceNativeWipe(this.active.state,this.active.geometry);this.render();
  }
  render() {
    const active=this.active;if(!active||!active.host)return;
    if(active.state.state===0){this.clear();return;}
    if(!active.node)this._create(active);
    active.node.style.left=String(f(active.geometry.origin[0]+active.state.offset))+'px';
    active.node.style.top=String(active.geometry.origin[1])+'px';
  }
  _create(active) {
    const g=active.geometry,node=document.createElement('div');node.dataset.forgeNativeWipe='true';
    // Existing screen-fade band; explicit player cutins at480 stay above it.
    node.style.cssText='position:absolute;width:0;height:0;pointer-events:none;z-index:450;';
    const middle=document.createElement('div');middle.style.cssText='position:absolute;left:'+(-g.width*.5)+'px;top:'+(-g.height*.5)+'px;width:'+(g.width+4)+'px;height:'+g.height+'px;background:rgb(1,1,1);';node.appendChild(middle);
    for(const[right,center]of[[false,g.leftCenter],[true,g.rightCenter]]){
      const image=document.createElement('img');image.src=this.resource.url;image.alt='';image.draggable=false;
      image.style.cssText='position:absolute;left:'+(center[0]-g.textureWidth*.5)+'px;top:'+(-g.height*.5)+'px;width:'+g.textureWidth+'px;height:'+g.height+'px;transform-origin:center center;'+(right?'transform:scale(-1,-1);':'');
      node.appendChild(image);
    }
    active.host.appendChild(node);active.node=node;
  }
  seek(target) {
    const active=this.active;if(!active)return;
    const clock=nativeTaskClock(this.runner,active.start,target,Math.trunc(Number(active.command.forgePhase??0)));
    active.state=nativeWipeState(active.geometry);
    for(let tick=0;tick<clock.schedulerTicks&&active.state.state!==0;tick++)advanceNativeWipe(active.state,active.geometry);
    this.nativeMode=true;this.render();
  }
  clear() { this.active?.node?.remove(); this.active=null; }
}
