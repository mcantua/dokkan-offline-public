import {nativeTaskClock} from './preview-task-clock.js';
import {liveAttachmentInstance} from './preview-effect-attachment.js';
/* Original Forge adapter, MIT. Native source evidence: native-preview-kakimoji.
 * Kakimoji is a separate UI wrapper around effect10000+smallId, with native
 * Cocos fade/scale/move/shake actions. It is not a generic battle entryEffect.
 */
const f=Math.fround;
const integer=value=>(Number(value)||0)|0;
export function nativeKakimojiPlan(command,movieFrames) {
  if(!Number.isInteger(movieFrames)||movieFrames<0)throw Error('The original word animation has no readable frame count.');
  const args=command.args||[],requested=integer(args[2]),kind=[2,3,4].includes(requested)?requested:1;
  const fadeIn=f(.1),hold=f(movieFrames/30+f(.3)),fadeOut=f(kind===3?.1:.15);
  return{effectId:10000+integer(args[1]),kind,frame:Number(command.frame??args[0])||0,target:integer(args[3]),tag:integer(args[4]),x:f(Number(args[5])||0),y:f(Number(args[6])||0),movieFrames,fadeIn,hold,fadeOut,total:f(f(fadeIn+hold)+fadeOut)};
}
export function nativeKakimojiSample(plan,seconds) {
  const elapsed=f(Math.max(0,seconds)),p=f(Math.max(0,Math.min(1,f(elapsed/plan.fadeIn)))),eased=f(p*p);
  const sx=plan.kind===2?f(5-3*eased):2,sy=plan.kind===2?sx:plan.kind===3?2:f(2*p),dy=plan.kind===3?f(-64+64*eased):0;
  const fadeStart=f(plan.fadeIn+plan.hold);
  let opacity=Math.trunc(f(255*p));
  if(elapsed>=fadeStart){const out=f(Math.max(0,Math.min(1,f(f(elapsed-fadeStart)/plan.fadeOut))));opacity=Math.trunc(f(255-255*out));}
  return{sx,sy,dy,opacity:Math.max(0,Math.min(255,opacity)),shake:plan.kind===4&&elapsed>=plan.fadeIn&&elapsed<fadeStart,ended:elapsed>=plan.total,movieFrame:Math.min(plan.movieFrames,Math.max(0,Math.floor(f(elapsed*30))))};
}
export function nativeKakimojiAnchor(plan,actor,named,viewportCenter=[0,0]) {
  let base=viewportCenter;
  if(plan.target>=0&&plan.tag>=0&&actor){
    base=[Number(actor.x)||0,Number(actor.y)||0];
    // Unlike EffectView's getter, the genuine comic callback reads the
    // active tag record directly: no actor/depth/huge-scale recipe here.
    if(named?.known===true&&Array.isArray(named.local)&&named.local.length===2&&named.local.every(Number.isFinite))base=named.local;
  }
  return {x:f(f(base[0])+plan.x),y:f(f(base[1])+plan.y)};
}
export function nativeKakimojiParentAlpha(wrapperOpacity,masterOpacity=255) {
  if(![wrapperOpacity,masterOpacity].every(value=>Number.isInteger(value)&&value>=0&&value<=255))throw Error('The word-animation transparency metadata is invalid.');
  // Original Node::updateDisplayedOpacity divides in double and truncates.
  return Math.trunc(wrapperOpacity*masterOpacity/255);
}
export function nativeKakimojiMasterRGBA(rgba) {
  const values=rgba&&['r','g','b','a'].map(key=>rgba[key]);
  if(!values||!values.every(value=>Number.isInteger(value)&&value>=0&&value<=255))throw Error('The original word-animation colors are missing or invalid.');
  return {r:values[0],g:values[1],b:values[2],a:values[3]};
}
export function nativeKakimojiShake(xRand,yRand) {
  const axis=value=>f(20*f(value/2147483648)-10);
  return{x:axis(xRand),y:axis(yRand)};
}
export class KakimojiCommands {
  constructor(runner,{fetchPack,createLayer,random=Math.random,resolveTag=liveAttachmentInstance}={}){this.runner=runner;this.fetchPack=fetchPack;this.createLayer=createLayer;this.random=random;this.resolveTag=resolveTag;this.layer=null;this.container=null;this.prepared=new Map();this.active=[];this.frame=0;this.nativeMode=false;this.opacityProviders=new WeakMap();}
  async preload(commands=[]) {
    const selected=commands.filter(command=>command.type==='entryKakimoji');if(!selected.length)return;
    this.clear();this.layer?.clear?.();this.container?.remove();this.prepared.clear();this.opacityProviders=new WeakMap();this.groupedOpacityNotice=false;this.attachmentNotice=false;
    const host=this.runner.lwf?.host;if(!host)throw Error('The word-animation preview layer is unavailable.');
    this.container=document.createElement('div');this.container.dataset.forgeKakimojiLayer='true';this.container.style.display='contents';host.appendChild(this.container);
    if(this.createLayer)this.layer=this.createLayer(this.container);
    else{const Layer=this.runner.lwf.constructor;if(typeof Layer?.prototype?.addEffect!=='function')throw Error('This preview build cannot load original word animations.');this.layer=new Layer(this.container,this.runner.log);}
    const fetchPack=this.fetchPack||(await import('/tools/lua-player/js/effect-pack.js')).fetchEffectPack;
    for(let index=0;index<selected.length;index++){
      const command=selected[index],effectId=10000+integer(command.args?.[1]),pack=await fetchPack(effectId,{enemy:this.runner.enemySide});
      if(!pack.found||!pack.lwf?.url||!pack.scene_name)throw Error('An original comic-word animation is missing from this game database.');
      const rgba=nativeKakimojiMasterRGBA(pack.rgba),url=pack.lwf.url,base=url.slice(0,url.lastIndexOf('/')+1);
      const player=await this.layer.addEffect({lwfUrl:url,baseUrl:base,sceneName:pack.scene_name,zIndex:440,instanceKey:'forge_word_'+index,startFrame:Number(command.frame)||0,effectId,dormant:true,attr:0});
      if(!player?.lwf)throw Error('An original comic-word animation could not be loaded.');
      const frames=Number((player.movie||player.lwf.rootMovie)?.totalFrames),plan=nativeKakimojiPlan(command,frames);
      this.prepared.set(command,{command,player,plan,rgba});
    }
  }
  compositorTargets() {
    const records=new Map();
    for(const record of this.prepared.values())if(record.player?.lwf)records.set(record.player,record);
    for(const record of this.active)if(record.player?.lwf)records.set(record.player,record);
    const active=new Set(this.active.map(record=>record.player));
    return [...records].map(([player,record])=>{
      let capability=this.opacityProviders.get(player);
      if(!capability){capability={enabled:false};capability.setPerQuadOpacity=enabled=>{capability.enabled=enabled===true;};this.opacityProviders.set(player,capability);}
      const rgba=record.rgba||{r:255,g:255,b:255,a:255},wrapperOpacity=active.has(player)?record.sample?.opacity??0:255;
      return {player,nativeParentAlpha:nativeKakimojiParentAlpha(wrapperOpacity,rgba.a),colorRGB:[rgba.r/255,rgba.g/255,rgba.b/255],groupedOpacity:false,setPerQuadOpacity:capability.setPerQuadOpacity};
    });
  }
  execute(command) {
    if(command.type!=='entryKakimoji')return false;
    const prepared=this.prepared.get(command);if(!prepared)throw Error('The original comic-word animation has not finished loading.');
    const {plan}=prepared;
    // Original queued callback snapshots the actor before this Exec updates
    // that actor's position keys; a missing tag takes the native base fallback.
    const actor=plan.target>=0&&plan.tag>=0?this.runner.chara?.chars?.get?.(plan.target):null;
    const named=actor?this.resolveTag(actor,plan.tag):null,position=nativeKakimojiAnchor(plan,actor,named);
    if(actor&&named?.known===false&&!this.attachmentNotice){this.runner.log?.('This word animation uses the character position because its current attachment pose is unavailable.');this.attachmentNotice=true;}
    this.active.push({...prepared,position,lastFrame:null,seconds:0,sample:null,jitter:{x:0,y:0},firstCocosTick:true});return true;
  }
  update(frame,context) {
    this.frame=Number(frame);
    if(context?.nativeExecution===true)this.nativeMode=true;
    if(this.runner._forgeVisualSeeking){
      this.nativeMode=true;
      for(const task of this.active){
        if(task.lastFrame===null)this.layer.activatePlayer(task.player);
        task.lastFrame=this.frame;task.seconds=0;task.sample=nativeKakimojiSample(task.plan,0);
        this.layer._seekPlayerToElapsed(task.player,0);
      }
      return;
    }
    for(let index=this.active.length-1;index>=0;index--){
      const task=this.active[index],{player,plan}=task;if(this.frame<plan.frame)continue;
      if(task.lastFrame===null){
        this.layer.activatePlayer(player);
        // Cocos ActionInterval::step starts at elapsed0 on its first tick.
        // Explicit seeks reconstruct the prior discrete logical update grid.
        const step=Math.max(1,Number(this.runner.step)||2),firstTick=Math.ceil(plan.frame/step)*step;
        task.seconds=this.runner._forgeVisualSeeking?f(Math.max(0,this.frame-firstTick)/60):0;
        if(this.runner._forgeVisualSeeking)task.firstCocosTick=false;
      }else if(this.nativeMode&&!this.runner._forgeVisualSeeking)continue;
      else if(this.frame>task.lastFrame)task.seconds=f(task.seconds+f((this.frame-task.lastFrame)/60));
      else continue;
      task.lastFrame=this.frame;task.sample=nativeKakimojiSample(plan,task.seconds);
      if(task.sample.ended){this.layer._softRetire(player);this.active.splice(index,1);continue;}
      if(task.sample.shake){const draw=()=>Math.floor(this.random()*2147483648);task.jitter=nativeKakimojiShake(draw(),draw());}else task.jitter={x:0,y:0};
      this.layer._seekPlayerToElapsed(player,task.sample.movieFrame);
    }
  }
  tick(seconds) {
    if(!Number.isFinite(seconds)||seconds<0)throw Error('Invalid comic-word scheduler time.');
    if(!this.nativeMode)return;
    for(let index=this.active.length-1;index>=0;index--){
      const task=this.active[index],{player,plan}=task;if(task.lastFrame===null)continue;
      if(task.firstCocosTick){task.firstCocosTick=false;task.seconds=0;}
      else task.seconds=f(task.seconds+f(seconds));
      task.sample=nativeKakimojiSample(plan,task.seconds);
      if(task.sample.ended){this.layer._softRetire(player);this.active.splice(index,1);continue;}
      if(task.sample.shake){const draw=()=>Math.floor(this.random()*2147483648);task.jitter=nativeKakimojiShake(draw(),draw());}else task.jitter={x:0,y:0};
      this.layer._seekPlayerToElapsed(player,task.sample.movieFrame);
    }
  }
  render() {
    this.layer?.renderOnly();
    for(const task of this.active){if(!task.sample||!task.position)continue;const{player,sample,position,jitter}=task;
      const width=Number(player.stageW)||852,height=Number(player.stageH)||1536;
      // The public generic setter converts scale0 to1. This owned wrapper
      // preserves the actual native flattened initial scale and position.
      player.wrap.style.transform='translate('+f(width*.5+position.x+jitter.x)+'px, '+f(height*.5-position.y-sample.dy-jitter.y)+'px) scale('+sample.sx+', '+sample.sy+')';
      const perQuad=this.opacityProviders.get(player)?.enabled===true;
      player.wrap.style.opacity=String(perQuad?1:nativeKakimojiParentAlpha(sample.opacity,task.rgba?.a??255)/255);player.wrap.style.zIndex='440';
      if(!perQuad&&!this.groupedOpacityNotice){this.runner.log?.('Comic-word artwork keeps grouped transparency in this preview; overlapping artwork may differ from the game.');this.groupedOpacityNotice=true;}
    }
  }
  seek(target) {
    this.nativeMode=true;
    for(let index=this.active.length-1;index>=0;index--){
      const task=this.active[index],clock=nativeTaskClock(this.runner,task.plan.frame,target,Math.trunc(Number(task.command.forgePhase??0)));
      task.seconds=clock.cocosSeconds;task.firstCocosTick=clock.schedulerTicks===0;
      task.sample=nativeKakimojiSample(task.plan,task.seconds);
      if(task.sample.ended){this.layer._softRetire(task.player);this.active.splice(index,1);continue;}
      if(task.sample.shake){const draw=()=>Math.floor(this.random()*2147483648);task.jitter=nativeKakimojiShake(draw(),draw());}else task.jitter={x:0,y:0};
      this.layer._seekPlayerToElapsed(task.player,task.sample.movieFrame);
    }
    this.render();
  }
  clear(){for(const record of this.prepared.values()){const capability=this.opacityProviders.get(record.player);if(capability)capability.enabled=false;}for(const task of this.active)this.layer?._softRetire?.(task.player);this.active=[];this.frame=0;this.nativeMode=false;}
}
