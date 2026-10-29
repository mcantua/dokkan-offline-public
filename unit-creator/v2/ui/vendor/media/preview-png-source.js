/* Original Forge bounded same-preview PNG source loader. MIT.
 * Native pixel decoding is isolated from URL policy; no caller filesystem paths,
 * redirects, third-party origins or unbounded image/body allocations. */
import {decodeNativePNGAsync} from './preview-png-async.js';
import {classifyNativePNG} from './preview-png-metadata.js';
const LIMIT=32*1024*1024;
const abortError=()=>{const error=Error('Artwork decoding was canceled.');error.name='AbortError';return error;};
export async function loadNativePNGSource(source,{signal,fetch:fetcher=globalThis.fetch,baseURL=globalThis.location?.href,timeoutMs=15000,maxBytes=LIMIT,onMetadata=null,decode=decodeNativePNGAsync}={}){
 if(signal?.aborted)throw abortError();if(!Number.isInteger(maxBytes)||maxBytes<64||maxBytes>LIMIT)throw Error('Invalid artwork download limit.');if(typeof source!=='string'||!source)throw Error('The source artwork URL is unavailable.');
 let url,origin;try{url=new URL(source,baseURL);origin=new URL(baseURL).origin;}catch{throw Error('The source artwork URL is invalid.');}
 const embedded=url.protocol==='data:'&&/^data:image\/png(?:;base64)?,/i.test(source);
 if(!embedded&&(!['http:','https:','blob:'].includes(url.protocol)||url.origin!==origin||url.username||url.password))throw Error('Artwork can only load from this preview or its own PNG blobs.');
 if(embedded&&source.length>Math.ceil(maxBytes/3)*4+64)throw Error('The source artwork exceeds the download limit.');if(typeof fetcher!=='function'||typeof decode!=='function'||onMetadata!==null&&typeof onMetadata!=='function')throw Error('Artwork loading is unavailable.');
 const controller=new AbortController(),cancel=()=>controller.abort(),timer=setTimeout(cancel,Math.max(100,Math.min(30000,Number(timeoutMs)||15000)));signal?.addEventListener('abort',cancel,{once:true});let reader;
 try{
  const response=await fetcher(url.href,{signal:controller.signal,credentials:'same-origin',redirect:'error'});if(!response.ok)throw Error('The source artwork could not be loaded.');
  const declared=response.headers?.get?.('content-length');if(declared!==null&&declared!==undefined&&(!/^\d+$/.test(declared)||Number(declared)>maxBytes))throw Error('The source artwork exceeds the download limit.');if(!response.body?.getReader)throw Error('This browser cannot load artwork within the preview limit.');reader=response.body.getReader();let bytes=new Uint8Array(Math.min(65536,maxBytes)),used=0;
  let metadata=null;
  while(true){const{value,done}=await reader.read();if(done)break;if(!(value instanceof Uint8Array))throw Error('The source artwork returned invalid bytes.');if(value.length>maxBytes-used)throw Error('The source artwork exceeds the download limit.');if(used+value.length>bytes.length){let capacity=bytes.length;while(capacity<used+value.length)capacity=Math.min(maxBytes,capacity*2);const next=new Uint8Array(capacity);next.set(bytes.subarray(0,used));bytes=next;}bytes.set(value,used);used+=value.length;
   if(!metadata){const result=classifyNativePNG(bytes.subarray(0,used));if(result.known){metadata=result;const wanted=onMetadata?.(metadata);if(signal?.aborted)throw abortError();if(wanted===false)return{width:metadata.width,height:metadata.height,metadata,rgba:null,skipped:true};}else if(!/incomplete/.test(result.reason))throw Error(result.reason);}
  }
  if(signal?.aborted)throw abortError();if(controller.signal.aborted)throw Error('Artwork loading timed out.');if(declared!==null&&declared!==undefined&&Number(declared)!==used)throw Error('The source artwork download is incomplete.');if(!metadata)throw Error('The PNG metadata is incomplete.');clearTimeout(timer);const decoded=await decode(bytes.subarray(0,used),{signal});if(decoded.width!==metadata.width||decoded.height!==metadata.height)throw Error('The source artwork dimensions changed while decoding.');return decoded;
 }catch(error){if(signal?.aborted)throw abortError();if(controller.signal.aborted)throw Error('Artwork loading timed out.');throw error;}
 finally{clearTimeout(timer);signal?.removeEventListener('abort',cancel);try{await reader?.cancel();}catch{}controller.abort();}
}
