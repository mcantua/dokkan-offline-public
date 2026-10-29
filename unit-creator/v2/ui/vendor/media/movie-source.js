/* Original Forge code (MIT). Fixed-origin game movie retrieval with bounded validation. */
const LIMIT=160*1024*1024;
function validPath(path){return typeof path==='string'&&path.length<=300&&/^movie\/[a-z0-9_./-]+\.usm$/i.test(path)&&!path.split('/').some(part=>!part||part==='.'||part==='..');}
function failure(message,code){return Object.assign(new Error(message),{code});}
function abort(signal){if(signal?.aborted)throw Object.assign(new Error('Movie loading cancelled.'),{name:'AbortError'});}
async function bytesFrom(response,limit,signal){
 if(!response.ok){await response.body?.cancel?.().catch(()=>{});throw failure('This movie resource is unavailable.','UNAVAILABLE');}
 const declared=Number(response.headers.get('content-length'));if(Number.isFinite(declared)&&declared>limit){await response.body?.cancel?.().catch(()=>{});throw failure('This movie exceeds the supported preview size.','TOO_LARGE');}
 let bytes;
 if(response.body?.getReader){const reader=response.body.getReader(),parts=[];let total=0,head=[];
  try{for(;;){abort(signal);const part=await reader.read();if(part.done)break;total+=part.value.byteLength;if(total>limit){await reader.cancel();throw failure('This movie exceeds the supported preview size.','TOO_LARGE');}
    for(let i=0;i<part.value.length&&head.length<4;i++)head.push(part.value[i]);
    if(head.length===4&&String.fromCharCode(...head)!=='CRID'){await reader.cancel();throw failure('This resource is not a complete game movie.','INVALID_MOVIE');}parts.push(part.value);
   }bytes=new Uint8Array(total);let at=0;for(const part of parts){bytes.set(part,at);at+=part.byteLength;}
  }finally{reader.releaseLock();}
 }else{bytes=new Uint8Array(await response.arrayBuffer());if(bytes.length>limit)throw failure('This movie exceeds the supported preview size.','TOO_LARGE');}
 abort(signal);if(bytes.length<32||String.fromCharCode(...bytes.subarray(0,4))!=='CRID')throw failure('This movie is an empty or invalid placeholder. Import a resource pack containing the complete movie.','INVALID_MOVIE');
 if(declared>0&&declared!==bytes.length)throw failure('This movie download is incomplete.','INCOMPLETE');return bytes;
}
export async function fetchMovieSource(path,{signal,fetcher=globalThis.fetch.bind(globalThis),maxBytes=LIMIT,onFallback}={}){
 if(!validPath(path))throw failure('Choose a valid game movie.','INVALID_PATH');if(!Number.isSafeInteger(maxBytes)||maxBytes<32||maxBytes>LIMIT)throw failure('Invalid movie loading limit.','INVALID_LIMIT');
 const relative=path.split('/').map(encodeURIComponent).join('/'),sources=['/assets/'+relative,'/cdn/uncompressed/'+relative];let last;
 for(let index=0;index<sources.length;index++){abort(signal);try{const bytes=await bytesFrom(await fetcher(sources[index],{signal}),maxBytes,signal);return{bytes,source:sources[index],fallback:index>0};}catch(error){if(error.name==='AbortError'||error.code==='TOO_LARGE')throw error;last=error;if(index===0)onFallback?.(error);}}
 throw last||failure('This movie resource is unavailable.','UNAVAILABLE');
}
