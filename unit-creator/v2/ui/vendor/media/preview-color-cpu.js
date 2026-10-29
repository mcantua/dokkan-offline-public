/* Original Forge bounded software fallback for the ActionBank color/blur pass.
 * MIT. Rebuild the tiny standalone WASM with scripts/media/build-cpu-color.py. */
const MAX_PIXELS=16*1024*1024, MAX_WASM_BYTES=512*1024;
let compiled=null, instance=null, pending=null, capture=null, floating=null;
const outputStatus=new WeakMap();
export function softwareColorStatus(output){return outputStatus.get(output)||null;}
function validateModule(module){
  if(WebAssembly.Module.imports(module).length)throw Error('The software color renderer has unexpected dependencies.');
  const exports=new Set(WebAssembly.Module.exports(module).map(value=>value.name));
  for(const name of ['memory','shade','shadeWindow','shadeWindowColor','shadeWindowVertex','shadeWindowSprite','__heap_base'])if(!exports.has(name))throw Error('The software color renderer is incomplete.');
}
export async function preloadCPUColor(bytes){
  if(bytes===undefined&&compiled)return;
  if(bytes===undefined&&pending)return pending;
  const loading=(async()=>{
    let data=bytes;
    if(data===undefined){const response=await fetch(new URL('./preview-color-cpu.wasm',import.meta.url));if(!response.ok)throw Error('The software color renderer could not be loaded.');data=await response.arrayBuffer();}
    const view=data instanceof Uint8Array?data:new Uint8Array(data);
    if(!view.byteLength||view.byteLength>MAX_WASM_BYTES)throw Error('Invalid software color renderer size.');
    const module=await WebAssembly.compile(view);validateModule(module);compiled=module;releaseCPUColor();
  })();
  if(bytes===undefined)pending=loading;
  try{await loading;}finally{if(pending===loading)pending=null;}
}
function dimensions(width,height){
  if(!Number.isInteger(width)||!Number.isInteger(height)||width<1||height<1||width*height>MAX_PIXELS)throw Error('This picture exceeds the software color renderer size limit.');
}
function shadeData(pixels,width,height,rect,tint,blur,{raw=false,blurY=-blur,window=null,colorRGB=[1,1,1],vertexRGBA=null,nativeAddRGB=null,nativeSpriteFlags=null,outputSize=null}={}){
  dimensions(width,height);
  if(!(pixels instanceof Uint8Array||pixels instanceof Uint8ClampedArray)||pixels.byteLength!==width*height*4)throw Error('Invalid picture data for software color rendering.');
  if(!Array.isArray(rect)||rect.length!==4||rect.some(value=>!Number.isFinite(value)))throw Error('Invalid software color crop.');
  const[x,y,w,h]=rect,fullWidth=window?.width??width,fullHeight=window?.height??height;
  dimensions(fullWidth,fullHeight);
  if(window&&(!Number.isInteger(window.left)||!Number.isInteger(window.top)||window.left<0||window.top<0||window.left+width>fullWidth||window.top+height>fullHeight))throw Error('Invalid software picture window.');
  if(x<0||y<0||w<=0||h<=0||x+w>fullWidth+.0001||y+h>fullHeight+.0001)throw Error('The software color crop extends outside its picture.');
  if(outputSize!==null&&(!Array.isArray(outputSize)||outputSize.length!==2||outputSize.some(value=>!Number.isFinite(value)||value<=0)))throw Error('Invalid software color output size.');
  const outWidth=Math.ceil(outputSize?.[0]??w),outHeight=Math.ceil(outputSize?.[1]??h);dimensions(outWidth,outHeight);
  if(!tint||![0,1,2,3,5,6].includes(tint.mode)||!Array.isArray(tint.rgba)||tint.rgba.length!==4||tint.rgba.some(value=>!Number.isFinite(value)||!Number.isFinite(Math.fround(value)))||!Number.isFinite(blur)||!Number.isFinite(blurY)||!Number.isFinite(Math.fround(blur))||!Number.isFinite(Math.fround(blurY)))throw Error('Unsupported software color/blur settings.');
  if(!Array.isArray(colorRGB)||colorRGB.length!==3||colorRGB.some(value=>!Number.isFinite(value)||value<0||value>1))throw Error('Unsupported software vertex color.');
  if(vertexRGBA!==null&&(!Array.isArray(vertexRGBA)||vertexRGBA.length!==4||vertexRGBA.some(value=>!Number.isFinite(value)||value<0||value>1)))throw Error('Unsupported software vertex opacity or color.');
  if(nativeAddRGB!==null&&(!Array.isArray(nativeAddRGB)||nativeAddRGB.length!==3||nativeAddRGB.some(value=>!Number.isFinite(value)||!Number.isFinite(Math.fround(value)))))throw Error('Unsupported software additive bitmap color.');
  if(nativeSpriteFlags!==null&&(!nativeSpriteFlags||typeof nativeSpriteFlags.texturePremultiplied!=='boolean'||typeof nativeSpriteFlags.premultipliedProgram!=='boolean'))throw Error('Unsupported native bitmap texture flags.');
  if(!compiled)throw Error('The software color renderer is not prepared.');
  if(!instance)instance=new WebAssembly.Instance(compiled,{});
  const api=instance.exports,first=Number(api.__heap_base.value),output=(first+pixels.byteLength+15)&~15,outputBytes=outWidth*outHeight*4,needed=output+outputBytes;
  const growth=Math.ceil((needed-api.memory.buffer.byteLength)/65536);
  if(growth>0)api.memory.grow(growth);
  new Uint8Array(api.memory.buffer,first,pixels.byteLength).set(pixels);
  const additive=nativeAddRGB?.some(value=>value!==0),fullVertex=vertexRGBA!==null||additive||nativeSpriteFlags!==null,colored=colorRGB.some(value=>value!==1),windowed=window||colored||fullVertex;
  const args=[first,width,height,output,outWidth,outHeight,...(windowed?[fullWidth,fullHeight,window?.left??0,window?.top??0]:[]),x,y,w,h,additive?7:tint.mode,...tint.rgba,additive?0:blur,additive?0:blurY,raw?1:0,...(fullVertex?[...(vertexRGBA??[...colorRGB,1]),...(nativeAddRGB??[0,0,0])]:colored?colorRGB:[])];
  if(nativeSpriteFlags)args.push(nativeSpriteFlags.texturePremultiplied?1:0,nativeSpriteFlags.premultipliedProgram?1:0);
  const ok=(nativeSpriteFlags?api.shadeWindowSprite:fullVertex?api.shadeWindowVertex:colored?api.shadeWindowColor:window?api.shadeWindow:api.shade)(...args);
  if(ok!==1)throw Error('Software color rendering did not complete.');
  return{pixels:new Uint8ClampedArray(api.memory.buffer,output,outputBytes).slice(),width:outWidth,height:outHeight};
}
export function shadePixels(pixels,width,height,rect,tint,blur,options={}){
  return shadeData(pixels,width,height,rect,tint,blur,options);
}
export function processCPUColor(source,rect,tint,blur,output,{blurY=-blur,colorRGB=[1,1,1],extendedColor=true,vertexRGBA=null,nativeAddRGB=null,nativeSpriteFlags=null,sourceRGBA=null,outputSize=null}={}){
  const width=Number(source?.naturalWidth||source?.videoWidth||source?.width),height=Number(source?.naturalHeight||source?.videoHeight||source?.height);dimensions(width,height);
  if(!Array.isArray(rect)||rect.length!==4||rect.some(value=>!Number.isFinite(value)))throw Error('Invalid software color crop.');
  const[x,y,w,h]=rect;if(x<0||y<0||w<=0||h<=0||x+w>width+.0001||y+h>height+.0001)throw Error('The software color crop extends outside its picture.');
  // Shader coordinates remain normalized to the ORIGINAL atlas. Sampling is
  // clamped to this quad's UV vertices, so only its integer pixel window plus
  // bilinear/float32 guard pixels needs a canvas readback or WASM memory copy.
  const left=Math.max(0,Math.floor(x)-2),top=Math.max(0,Math.floor(y)-2),right=Math.min(width,Math.ceil(x+w)+2),bottom=Math.min(height,Math.ceil(y+h)+2),cw=right-left,ch=bottom-top;
  let pixels;
  if(sourceRGBA!==null){
    if(!(sourceRGBA instanceof Uint8Array||sourceRGBA instanceof Uint8ClampedArray)||sourceRGBA.byteLength!==width*height*4)throw Error('Invalid original bitmap pixels.');
    // Preserve raw straight pixels (including RGB under alpha0) and copy only
    // the sampled atlas window; Canvas readback would discard those colors.
    pixels=new Uint8ClampedArray(cw*ch*4);
    for(let row=0;row<ch;row++)pixels.set(sourceRGBA.subarray(((top+row)*width+left)*4,((top+row)*width+right)*4),row*cw*4);
  }else{
    if(!capture)capture=document.createElement('canvas');
    if(capture.width!==cw)capture.width=cw;if(capture.height!==ch)capture.height=ch;
    const context=capture.getContext('2d',{willReadFrequently:true});if(!context)throw Error('Software picture reading is unavailable.');
    context.clearRect(0,0,cw,ch);context.drawImage(source,left,top,cw,ch,0,0,cw,ch);
    pixels=context.getImageData(0,0,cw,ch).data;
  }
  const result=shadeData(pixels,cw,ch,rect,tint,blur,{raw:extendedColor,blurY,colorRGB,vertexRGBA,nativeAddRGB,nativeSpriteFlags,outputSize,window:{width,height,left,top}});
  if(output.width!==result.width)output.width=result.width;if(output.height!==result.height)output.height=result.height;
  const target=output.getContext('2d');if(!target)throw Error('Software picture drawing is unavailable.');
  let overflow=false;for(let i=0;i<result.pixels.length;i+=4)if(result.pixels[i]>result.pixels[i+3]||result.pixels[i+1]>result.pixels[i+3]||result.pixels[i+2]>result.pixels[i+3]){overflow=true;break;}
  if(extendedColor&&typeof Float16Array==='function'){
    // Standard byte ImageData clamps straight RGB to1 before premultiplying,
    // destroying native ADD/SCREEN's RGB>alpha. A capable software Canvas can
    // retain extended straight RGB and drawImage preserves its premultiplied
    // excess even when the destination is a normal byte Canvas.
    try{
      if(!floating)floating=document.createElement('canvas');
      if(floating.width!==result.width)floating.width=result.width;if(floating.height!==result.height)floating.height=result.height;
      const fc=floating.getContext('2d',{colorType:'float16'});
      if(fc?.getContextAttributes?.().colorType==='float16'){
        const values=new Float16Array(result.pixels.length);
        for(let i=0;i<values.length;i+=4){const a=result.pixels[i+3]/255,hasColor=result.pixels[i]||result.pixels[i+1]||result.pixels[i+2],effective=a||(hasColor?1/65504:0);for(let c=0;c<3;c++)values[i+c]=effective?Math.min(65504,result.pixels[i+c]/255/effective):0;values[i+3]=effective;}
        fc.putImageData(new ImageData(values,result.width,result.height,{pixelFormat:'rgba-float16',colorSpace:'srgb'}),0,0);
        target.clearRect(0,0,output.width,output.height);target.drawImage(floating,0,0);outputStatus.set(output,{extended:true,limited:false});return true;
      }
    }catch{/* Capability fallback below retains explicit overflow diagnostics. */}
  }
  if(extendedColor){for(let i=0;i<result.pixels.length;i+=4){const a=result.pixels[i+3];for(let c=0;c<3;c++)result.pixels[i+c]=a?Math.min(255,Math.round(result.pixels[i+c]*255/a)):0;}}
  target.putImageData(new ImageData(result.pixels,result.width,result.height),0,0);
  outputStatus.set(output,{extended:false,limited:extendedColor&&overflow});return true;
}
export function releaseCPUColor(){
  instance=null;if(floating){floating.width=0;floating.height=0;floating=null;}if(capture){capture.width=0;capture.height=0;capture=null;}
}
