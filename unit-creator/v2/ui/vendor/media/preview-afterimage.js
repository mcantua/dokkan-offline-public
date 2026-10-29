/* Original Forge adapter for native ActionBankCharaView afterimages. MIT.
 * Original native math: tests/native-preview-afterimage.py.
 * afterPose MUST be called once per actual, fully rendered actor update;
 * tick(deltaSeconds) separately follows the Cocos snapshot scheduler. Neither RAF counts nor Lua-frame gaps are inferred.
 * A seek clears trails: pixels from unrendered historical poses are not made up.
 */
const f32=Math.fround;
const byte=value=>((Math.trunc(Number(value)||0)%256)+256)%256;
export function afterimageStep(position,velocity){return{x:f32(f32(position.x)+f32(velocity.x)),y:f32(f32(position.y)+f32(velocity.y))};}
export function afterimageOpacity(elapsed){return Math.trunc(f32(40-40*f32(Math.min(1,Math.max(0,Number(elapsed)||0)))))/255;}
export function tintAfterimage(data,rgb){for(let i=0;i<data.length;i+=4){data[i]=Math.round(data[i]*rgb[0]/255);data[i+1]=Math.round(data[i+1]*rgb[1]/255);data[i+2]=Math.round(data[i+2]*rgb[2]/255);}return data;}
// Exact shallow Movie::SearchBitmapInstance traversal, not first paint order.
export function nativeFirstBitmap(movie){
 if(!Array.isArray(movie?.z$2))return null;
 const child=movie.z$2.find(object=>object&&(object.type===2||object.type===8));
 if(!child||!Array.isArray(child.z$2))return null;
 return child.z$2.find(object=>object&&(object.type===3||object.type===4)&&object.z$ca)||null;
}
export function bitmapLocalQuad(bitmap){
 const renderer=bitmap?.z$ca,context=renderer?.z$b,fragment=context?.z$P,lwf=bitmap?.lwf,texture=lwf?.data?.textures?.[fragment?.z$oe];
 if(!fragment||!texture||![3,4].includes(bitmap.type))throw Error('The native bitmap texture context is unavailable.');
 const crop=bitmap.type===4?lwf.data.bitmapExs?.[bitmap.z$$]:null;
 if(bitmap.type===4&&!crop)throw Error('The bitmap crop is unavailable.');
 const u=Number(crop?.z$R??0),v=Number(crop?.z$S??0),w=Number(crop?.z$q??1),h=Number(crop?.z$k??1),fw=Number(fragment.z$q),fh=Number(fragment.z$k),scale=f32(Number(texture.scale));
 if(![u,v,w,h,fw,fh,scale,fragment.x,fragment.y].every(Number.isFinite)||scale<=0||w<=0||h<=0||fw<=0||fh<=0)throw Error('Invalid native bitmap geometry.');
 const x=f32(Number(fragment.x)+f32(f32(u)*f32(fw))),y=f32(Number(fragment.y)+f32(f32(v)*f32(fh)));
 const left=f32(x/scale),top=f32(y/scale),right=f32(f32(x+f32(f32(w)*f32(fw)))/scale),bottom=f32(f32(y+f32(f32(h)*f32(fh)))/scale);
 return{left,top,right,bottom};
}
export class AfterimageCommands {
 constructor(runner){this.runner=runner;this.actors=new Map();this.trails=[];this.pixels=0;this.active=false;this.warned=new Set();}
 prepare(commands=[]){this.clear();this.active=commands.some(command=>command.type==='setZanzou'&&Number(command.args?.[2]??0)!==0);}
 _state(actor){let value=this.actors.get(actor);if(!value){value={enabled:false,counter:0,color:[255,255,255],velocity:{x:0,y:0}};this.actors.set(actor,value);}return value;}
 execute(command){
  if(!['setZanzou','setZanzouSpeed','setZanzouColor'].includes(command.type))return false;
  const a=command.args||[],actor=Number(command.chara??a[1]);if(!Number.isInteger(actor))throw Error('Invalid afterimage character.');const state=this._state(actor);
  if(command.type==='setZanzou'){state.enabled=Number(a[2]??0)!==0;}
  else if(command.type==='setZanzouSpeed'){if(![a[2],a[3]].every(value=>Number.isFinite(Number(value??0))))throw Error('Invalid afterimage drift.');state.velocity={x:f32(Number(a[2]??0)),y:f32(Number(a[3]??0))};}
  else state.color=[a[2],a[3],a[4]].map(byte);
  return true;
 }
 _warn(message){if(!this.warned.has(message)){this.warned.add(message);this.runner.log?.('Afterimage preview: '+message);}}
 _remove(trail){trail.wrap.remove();this.pixels-=trail.pixels;}
 tick(deltaSeconds){
  const dt=Number(deltaSeconds);if(!Number.isFinite(dt)||dt<0)throw Error('Invalid afterimage elapsed time.');
  // Native snapshot velocity is one addition per snapshot Update, not vx*dt.
  for(const trail of this.trails){if(trail.firstTick){trail.firstTick=false;trail.elapsed=0;}else trail.elapsed=f32(f32(trail.elapsed)+f32(dt));trail.position=afterimageStep(trail.position,trail.velocity);trail.wrap.style.transform=`translate(${trail.position.x}px,${-trail.position.y}px)`;trail.body.style.opacity=String(afterimageOpacity(trail.elapsed));}
  this.trails=this.trails.filter(trail=>{if(trail.elapsed>=1){this._remove(trail);return false;}return true;});
 }
 afterPose(){
  for(const[actor,state]of this.actors){
   if(!state.enabled){state.counter=0;continue;}
   if(state.counter%3===0)this._capture(actor,state);state.counter=(state.counter+1)>>>0;
  }
 }
 _capture(actor,state){
  const c=this.runner.chara?.chars?.get(actor),parent=c?.wrap?.parentNode,bitmap=nativeFirstBitmap(c?.movie);
  if(!bitmap||!parent){this._warn('this character scene has no native first-bitmap renderer.');return;}
  const renderer=bitmap.z$ca,context=renderer?.z$b,command=renderer?.z$7a,image=context?.z$Ha,matrix=bitmap.z$c;
  if(!command||!image||!matrix||context.pattern){this._warn('this bitmap renderer has no supported retained texture quad.');return;}
  let quad;try{quad=bitmapLocalQuad(bitmap);}catch(error){this._warn(error.message);return;}
  const width=quad.right-quad.left,height=quad.bottom-quad.top,pixels=Math.ceil(width)*Math.ceil(height);
  const rect=[context.z$R,context.z$S,context.z$q,context.z$k].map(Number),iw=Number(image.naturalWidth||image.width),ih=Number(image.naturalHeight||image.height);
  if(![width,height,...rect,iw,ih,matrix.translateX,matrix.translateY].every(Number.isFinite)||width<=0||height<=0||pixels>4194304||rect[0]<0||rect[1]<0||rect[2]<=0||rect[3]<=0||rect[0]+rect[2]>iw||rect[1]+rect[3]>ih){this._warn('the retained bitmap exceeds its texture or bounded snapshot size.');return;}
  while(this.trails.length&&this.pixels+pixels>16777216){this._remove(this.trails.shift());this._warn('older trails were released to keep snapshot memory bounded.');}
  const canvas=document.createElement('canvas');canvas.width=Math.ceil(width);canvas.height=Math.ceil(height);canvas.style.cssText=`display:block;position:absolute;left:0;top:0;width:${width}px;height:${height}px;pointer-events:none;`;
  const ctx=canvas.getContext('2d',{willReadFrequently:true});if(!ctx){this._warn('a snapshot canvas could not be allocated.');return;}
  try{if(context.z$P.z$fb){ctx.translate(0,canvas.height);ctx.rotate(-Math.PI/2);ctx.drawImage(image,...rect,0,0,canvas.height,canvas.width);}else ctx.drawImage(image,...rect,0,0,canvas.width,canvas.height);
   if(state.color.some(value=>value!==255)){const pixels=ctx.getImageData(0,0,canvas.width,canvas.height);tintAfterimage(pixels.data,state.color);ctx.putImageData(pixels,0,0);}}
  catch(error){this._warn('this bitmap cannot be read for a snapshot: '+error.message);return;}
  // Native copies local quad vertices, not the source Node transform. It uses
  // anchor(0,.5), scale(1,-1), plus half the retained LWF bitmap translation.
  // The browser preview uses the original Director default content-scale1.
  // Device-specific active content scale/global projection remain separate.
  const transform=new DOMMatrix(c.wrap.style.transform||undefined),x=transform.m41+quad.left+f32(f32(matrix.translateX)*.5),y=transform.m42+quad.top-f32(f32(matrix.translateY)*.5)-ih*.5;
  const wrap=document.createElement('div'),body=document.createElement('div');wrap.dataset.forgeAfterimage=String(actor);wrap.setAttribute('aria-hidden','true');wrap.style.cssText='position:absolute;left:0;top:0;width:0;height:0;z-index:-2;pointer-events:none;';body.style.cssText=`position:absolute;left:0;top:0;width:0;height:0;transform:translate(${x}px,${y}px);opacity:${40/255};pointer-events:none;`;body.appendChild(canvas);wrap.appendChild(body);parent.appendChild(wrap);
  this.trails.push({wrap,body,pixels,elapsed:0,firstTick:true,position:{x:0,y:0},velocity:{...state.velocity}});this.pixels+=pixels;
 }
 // Existing trails remain until their own fade ends when the source is disabled.
 // Rendering never advances time or captures another copy of the same pose.
 update(){}
 render(){}
 clear(){for(const trail of this.trails)this._remove(trail);this.trails=[];this.actors.clear();this.pixels=0;this.active=false;this.warned.clear();}
}
