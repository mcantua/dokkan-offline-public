/* Original Forge bounded PNG alpha metadata reader. MIT.
 * Cocos Image/libpng proof: tests/native-effect-png-flags.py. This describes
 * Texture.hasPremultipliedAlpha, not LWF's separate format1 shader override.
 * It never decodes/resamples pixels or treats a filename as image metadata. */
const LIMIT=262144,signature=[137,80,78,71,13,10,26,10],depths={0:[1,2,4,8,16],2:[8,16],3:[1,2,4,8],4:[8,16],6:[8,16]};
let table;
function crc(bytes,start,end){if(!table){table=new Uint32Array(256);for(let n=0;n<256;n++){let c=n;for(let bit=0;bit<8;bit++)c=c&1?0xedb88320^(c>>>1):c>>>1;table[n]=c>>>0;}}let c=0xffffffff;for(let at=start;at<end;at++)c=table[(c^bytes[at])&255]^(c>>>8);return(c^0xffffffff)>>>0;}
const unknown=reason=>Object.freeze({known:false,reason});
function parse(bytes,limit,checksum=crc){
 const incomplete=()=>({needMore:true});if(bytes.length<8)return incomplete();if(!signature.every((v,i)=>bytes[i]===v))return unknown('This artwork is not a PNG image.');
 const view=new DataView(bytes.buffer,bytes.byteOffset,bytes.byteLength);let at=8,header=null,palette=0,transparency=false,count=0;
 while(at+8<=bytes.length){
  if(++count>1024)return unknown('This PNG has too many metadata chunks.');
  const length=view.getUint32(at);if(length>0x7fffffff)return unknown('This PNG has an invalid chunk length.');const type=String.fromCharCode(...bytes.subarray(at+4,at+8));if(!/^[A-Za-z]{4}$/.test(type)||type[2]!==type[2].toUpperCase())return unknown('This PNG has an invalid chunk type.');
  if(!header&&type!=='IHDR')return unknown('This PNG is missing its first image header.');
  if(type==='IDAT'){
   if(!header||header.colorType===3&&!palette)return unknown('This indexed PNG is missing its color palette.');
   const channels=header.colorType===0?(transparency?2:1):header.colorType===4?2:header.colorType===6||transparency?4:3;return Object.freeze({known:true,premultiplied:channels===4,...header,channels,hasAlpha:channels===2||channels===4,hasTRNS:transparency,metadataBytes:at+8});
  }
  if(type==='IEND')return unknown('This PNG has no image data.');
  if(length>limit||at+length+12>limit)return unknown('This PNG exceeds the preview metadata limit.');
  if(at+length+12>bytes.length)return incomplete();
  if(checksum(bytes,at+4,at+8+length)!==view.getUint32(at+8+length))return unknown('This PNG has corrupt metadata.');
  if(type==='IHDR'){
   if(header||at!==8||length!==13)return unknown('This PNG has an invalid image header.');
   const width=view.getUint32(at+8),height=view.getUint32(at+12),bitDepth=bytes[at+16],colorType=bytes[at+17];
   if(!width||!height||width>0x7fffffff||height>0x7fffffff||!depths[colorType]?.includes(bitDepth)||bytes[at+18]!==0||bytes[at+19]!==0||bytes[at+20]>1)return unknown('This PNG uses an invalid image format.');
   header={width,height,bitDepth,colorType};
  }else if(type==='PLTE'){
   if(palette||transparency||header.colorType===0||header.colorType===4||!length||length%3!==0||length>768||header.colorType===3&&length/3>2**header.bitDepth)return unknown('This PNG has an invalid color palette.');palette=length/3;
  }else if(type==='tRNS'){
   if(transparency||header.colorType===4||header.colorType===6||header.colorType===0&&length!==2||header.colorType===2&&length!==6||header.colorType===3&&(!palette||!length||length>palette))return unknown('This PNG has invalid transparency metadata.');transparency=true;
  }else if(type[0]===type[0].toUpperCase())return unknown('This PNG has an unsupported critical metadata chunk.');
  at+=length+12;
 }
 return incomplete();
}
export function classifyNativePNG(input,{crc:checksum=crc}={}){
 if(!(input instanceof Uint8Array))return unknown('PNG metadata must be supplied as bytes.');const result=parse(input.subarray(0,LIMIT),LIMIT,checksum);return result.needMore?unknown(input.length>=LIMIT?'This PNG exceeds the preview metadata limit.':'The PNG metadata is incomplete.'):result;
}
function aborted(){const error=new Error('PNG metadata loading was canceled.');error.name='AbortError';return error;}
function dataPrefix(url,limit){
 const comma=url.indexOf(',');if(comma<0||comma>64)return null;const header=url.slice(0,comma).toLowerCase(),payload=url.slice(comma+1,comma+1+Math.ceil(limit/3)*4+4);
 if(header==='data:image/png;base64'){if(!/^[a-z0-9+/]*={0,2}$/i.test(payload))return null;const prefix=payload.slice(0,payload.length-payload.length%4);try{const text=atob(prefix),out=new Uint8Array(Math.min(limit,text.length));for(let i=0;i<out.length;i++)out[i]=text.charCodeAt(i);return out;}catch{return null;}}
 if(header==='data:image/png'){const encoded=url.slice(comma+1,comma+1+limit*3),out=[];for(let i=0;i<encoded.length&&out.length<limit;i++){if(encoded[i]==='%'){if(i+2>=encoded.length)break;if(!/^[0-9a-f]{2}$/i.test(encoded.slice(i+1,i+3)))return null;out.push(parseInt(encoded.slice(i+1,i+3),16));i+=2;}else{const code=encoded.charCodeAt(i);if(code>255)return null;out.push(code);}}return new Uint8Array(out);}return null;
}
export async function preloadNativePNG(source,{signal,fetch:fetcher=globalThis.fetch,baseURL=globalThis.location?.href,maxMetadataBytes=LIMIT,timeoutMs=15000}={}){
 if(signal?.aborted)throw aborted();const limit=Math.trunc(Number(maxMetadataBytes));if(!Number.isInteger(limit)||limit<64||limit>LIMIT)return unknown('Invalid PNG metadata limit.');
 if(typeof source!=='string'||!source)return unknown('The source image URL is unavailable.');
 if(source.slice(0,5).toLowerCase()==='data:'){const bytes=dataPrefix(source,limit);if(!bytes)return unknown('This embedded artwork is not a supported PNG.');const result=parse(bytes,limit);return result.needMore?unknown(bytes.length>=limit?'This PNG exceeds the preview metadata limit.':'The PNG metadata is incomplete.'):result;}
 let url,origin;try{url=new URL(source,baseURL);origin=new URL(baseURL).origin;}catch{return unknown('The source image URL is invalid.');}
 if(!['http:','https:','blob:'].includes(url.protocol)||url.origin!==origin||url.username||url.password)return unknown('PNG metadata can only load from this preview or its own image blobs.');
 if(typeof fetcher!=='function')return unknown('PNG metadata loading is unavailable.');
 const controller=new AbortController(),cancel=()=>controller.abort(),duration=Math.max(100,Math.min(30000,Number(timeoutMs)||15000)),timer=setTimeout(cancel,duration);signal?.addEventListener('abort',cancel,{once:true});let reader;
 try{
  const response=await fetcher(url.href,{signal:controller.signal,credentials:'same-origin',redirect:'error',...(url.protocol==='blob:'?{}:{headers:{Range:'bytes=0-'+(limit-1)}})});
  if(!response.ok)return unknown('The source PNG metadata could not be loaded.');
  if(!response.body?.getReader)return unknown('This browser cannot load PNG metadata within the preview limit.');reader=response.body.getReader();const bytes=new Uint8Array(limit);let used=0;
  while(used<limit){
   const {value,done}=await reader.read();if(done)break;if(!(value instanceof Uint8Array)||!value.length)continue;const take=Math.min(value.length,limit-used);bytes.set(value.subarray(0,take),used);used+=take;const result=parse(bytes.subarray(0,used),limit);if(!result.needMore)return result;
  }
  return unknown(used>=limit?'This PNG exceeds the preview metadata limit.':'The PNG metadata is incomplete.');
 }catch(error){if(signal?.aborted)throw aborted();return unknown(controller.signal.aborted?'PNG metadata loading timed out.':'The source PNG metadata could not be loaded.');}
 finally{clearTimeout(timer);signal?.removeEventListener('abort',cancel);try{await reader?.cancel();}catch{}controller.abort();}
}
