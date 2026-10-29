/* Original Forge bounded PNG CPU acceleration, MIT. No browser image decode.
 * Compiled raster/CRC code and pinned miniz tinfl MIT source/rebuild recipe are
 * in scripts/media/png-decoder; complete license is in preview-png-NOTICE.txt.
 * No eager fetch or instantiation: callers explicitly initialize once. */
const MAX_INPUT=32*1024*1024,MAX_PIXELS=16*1024*1024,MAX_INFLATED=128*1024*1024+65536,MAX_MEMORY=256*1024*1024;
let initialized;
export function initializeNativePNGAccelerator({wasmBytes,fetch:fetcher=globalThis.fetch,timeoutMs=10000}={}){
 if(!initialized)initialized=initialize(wasmBytes,fetcher,timeoutMs).catch(error=>{initialized=null;throw error;});return initialized;
}
async function initialize(wasmBytes,fetcher,timeoutMs){
 if(typeof WebAssembly!=='object')throw Error('WebAssembly artwork decoding is unavailable.');
 let bytes=wasmBytes;
 if(bytes===undefined){
  if(typeof fetcher!=='function')throw Error('The local artwork decoder cannot be loaded.');
  const controller=new AbortController();let reader,timer;
  try{bytes=await Promise.race([(async()=>{
   const response=await fetcher(new URL('./preview-png.wasm',import.meta.url),{credentials:'same-origin',redirect:'error',cache:'force-cache',signal:controller.signal});
   if(!response.ok)throw Error('The local artwork decoder could not be loaded.');
   const declared=response.headers.get('content-length');if(declared!==null&&(!/^\d+$/.test(declared)||Number(declared)>1024*1024))throw Error('The local artwork decoder has an invalid size.');
   if(!response.body?.getReader)throw Error('The local artwork decoder cannot be loaded within its size limit.');reader=response.body.getReader();const parts=[];let used=0;
   while(true){const{value,done}=await reader.read();if(done)break;if(!(value instanceof Uint8Array)||value.length>1024*1024-used)throw Error('The local artwork decoder exceeds its size limit.');parts.push(value);used+=value.length;}
   if(declared!==null&&Number(declared)!==used)throw Error('The local artwork decoder download is incomplete.');const result=new Uint8Array(used);let offset=0;for(const part of parts){result.set(part,offset);offset+=part.length;}return result;
  })(),new Promise((_,reject)=>{timer=setTimeout(()=>{controller.abort();reject(Error('The local artwork decoder loading timed out.'));},Math.max(100,Math.min(15000,Number(timeoutMs)||10000)));})]);}
  finally{clearTimeout(timer);controller.abort();try{const cancelled=reader?.cancel();cancelled?.catch(()=>{});}catch{}}
 }
 if(!(bytes instanceof Uint8Array)||!bytes.length||bytes.length>1024*1024)throw Error('The local artwork decoder has an invalid size.');
 const {instance}=await WebAssembly.instantiate(bytes,{}),api=instance.exports,memory=api.memory,base=Math.ceil(Number(api.__heap_base?.value)/16)*16;
 if(!(memory instanceof WebAssembly.Memory)||!Number.isSafeInteger(base)||base<1||typeof api.png_crc!=='function'||typeof api.png_decode!=='function')throw Error('The local artwork decoder is incompatible.');
 function reserve(size){if(!Number.isSafeInteger(size)||size<0||base+size>MAX_MEMORY)throw Error('The artwork decoder workspace exceeds its limit.');const need=base+size;if(need>memory.buffer.byteLength)memory.grow(Math.ceil((need-memory.buffer.byteLength)/65536));return new Uint8Array(memory.buffer);}
 const errors={1:'This PNG has invalid or incomplete zlib compression.',2:'PNG pixels exceed their declared dimensions or are incomplete.',3:'This PNG uses an invalid row filter.',4:'The PNG pixel references a missing palette color.',5:'This PNG has invalid raster parameters.',6:'The PNG pixel checksum is invalid.'};
 return Object.freeze({engine:'wasm',
  crc(input,start,end){if(!(input instanceof Uint8Array)||!Number.isSafeInteger(start)||!Number.isSafeInteger(end)||start<0||end<start||end>input.length||end-start>MAX_INPUT)throw Error('Invalid bounded PNG checksum request.');const size=end-start,heap=reserve(size);heap.set(input.subarray(start,end),base);return api.png_crc(base,size)>>>0;},
  decode({compressed,parts,compressedLength,expected,width,height,depth,type,interlaced,palette=null,trns=null}){
   if(compressed!==undefined){if(!(compressed instanceof Uint8Array))throw Error('Invalid bounded PNG compression request.');parts=[compressed];compressedLength=compressed.length;}
   if(!Array.isArray(parts)||!parts.length||parts.length>1000000||!Number.isSafeInteger(compressedLength)||compressedLength<6||compressedLength>MAX_INPUT||!Number.isSafeInteger(expected)||expected<1||expected>MAX_INFLATED||!Number.isSafeInteger(width)||!Number.isSafeInteger(height)||width<1||height<1||width>32768||height>32768||width*height>MAX_PIXELS||!Number.isInteger(depth)||![1,2,4,8,16].includes(depth)||![0,2,3,4,6].includes(type)||typeof interlaced!=='boolean'||palette!==null&&(!(palette instanceof Uint8Array)||palette.length>768)||trns!==null&&(!(trns instanceof Uint8Array)||trns.length>256))throw Error('Invalid bounded PNG raster request.');
   let sum=0;for(const part of parts){if(!(part instanceof Uint8Array)||part.length>compressedLength-sum)throw Error('Invalid bounded PNG compression request.');sum+=part.length;}if(sum!==compressedLength)throw Error('The PNG compressed pixels are incomplete.');
   const align=value=>Math.ceil(value/16)*16,raw=base+align(compressedLength),rgba=raw+align(expected),paletteAt=rgba+width*height*4,trnsAt=paletteAt+align(palette?.length||0),end=trnsAt+(trns?.length||0),heap=reserve(end-base);
   let at=base;for(const part of parts){heap.set(part,at);at+=part.length;}if(palette)heap.set(palette,paletteAt);if(trns)heap.set(trns,trnsAt);
   const result=api.png_decode(base,compressedLength,raw,expected,rgba,width,height,depth,type,interlaced?1:0,paletteAt,palette?.length||0,trnsAt,trns?.length||0);
   if(result!==0)throw Error(errors[-result]||'The local artwork decoder failed.');
   return new Uint8Array(memory.buffer,rgba,width*height*4).slice();
  },
  stats(){return{engine:'wasm',workspaceBytes:memory.buffer.byteLength,maxWorkspaceBytes:MAX_MEMORY};}
 });
}
