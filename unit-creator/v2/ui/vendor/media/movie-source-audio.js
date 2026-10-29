/* Original Forge bounded primary USM sound extraction. GPL-3.0-or-later.
 * The original container and video remain untouched. Only owned first-stream
 * elementary audio is sent to the existing local CRI audio decoder.
 */
import {decodeAudio} from './audio-decoder.js';
import {createMovieAudioCache} from './movie-audio.js';
export function extractMovieSound(input,{metadata,maximum=32*1024*1024,signal}={}){
 if(signal?.aborted)throw new DOMException('Movie sound preparation cancelled.','AbortError');
 if(!(input instanceof Uint8Array)||input.length<32||input.length>160*1024*1024||String.fromCharCode(...input.subarray(0,4))!=='CRID'||!Number.isSafeInteger(maximum)||maximum<32||maximum>32*1024*1024)throw Error('Invalid or oversized movie sound source.');
 if(metadata===null)return null;
 if(!metadata||!Number.isSafeInteger(metadata.samples)||metadata.samples<1||!Number.isInteger(metadata.sampleRate)||metadata.sampleRate<8000||metadata.sampleRate>192000||!Number.isInteger(metadata.channels)||metadata.channels<1||metadata.channels>8||metadata.samples*metadata.channels*4>64*1024*1024)throw Error('The movie sound exceeds its supported PCM budget.');
 const view=new DataView(input.buffer,input.byteOffset,input.byteLength),parts=[];let at=0,count=0,total=0,channel=null;
 while(at<input.length){
  if(++count>65536)throw Error('This movie has too many sound chunks.');if(signal?.aborted)throw new DOMException('Movie sound preparation cancelled.','AbortError');
  if(input.length-at<32){if(input.length-at<=2048&&input.subarray(at).every(x=>x===0))break;throw Error('Incomplete movie sound chunk.');}
  const tag=String.fromCharCode(...input.subarray(at,at+4));if(tag!=='CRID'&&!/^@[A-Z0-9]{3}$/.test(tag)){if(input.length-at<=2048&&input.subarray(at).every(x=>x===0))break;throw Error('Invalid movie sound chunk.');}
  const size=view.getUint32(at+4),header=view.getUint16(at+8),padding=view.getUint16(at+10),end=at+size+8;
  if(size<24||header<24||header+padding>size||end>input.length)throw Error('Damaged movie sound chunk.');
  if(tag==='@SFA'){if(channel===null)channel=input[at+12];if(input[at+12]===channel&&input[at+15]===0){const from=at+8+header,to=end-padding;total+=to-from;if(total>maximum)throw Error('The elementary movie sound exceeds32MiB.');parts.push(input.subarray(from,to));}}
  at=end;
 }
 if(!total)throw Error('The movie declares sound but has no elementary sound data.');const data=new Uint8Array(total);let write=0;for(const part of parts){data.set(part,write);write+=part.length;}
 const prefix=String.fromCharCode(...data.subarray(0,4).map(x=>x&127)),kind=data[0]===0x80&&data[1]===0?'adx':prefix==='HCA\0'?'hca':null;
 if(!kind)throw Error('This movie uses an unsupported elementary sound codec.');
 return{kind,data,metadata:{samples:metadata.samples,sampleRate:metadata.sampleRate,channels:metadata.channels},channel};
}

/** Read only the local worker's bounded PCM16 RIFF result. Construct floats
 * explicitly: browser WAV decoders can normalize positive PCM by32767 rather
 * than the original integer codec's32768, introducing a measurable one-LSB
 * asymmetry. No codec or arbitrary native endpoint is replaced here.
 */
export function pcmMovieWav(bytes,context){
 if(!(bytes instanceof Uint8Array)||bytes.length<44||bytes.length>32*1024*1024+4096||typeof context?.createBuffer!=='function')throw Error('Invalid or oversized decoded movie WAV.');
 const v=new DataView(bytes.buffer,bytes.byteOffset,bytes.byteLength),tag=at=>String.fromCharCode(...bytes.subarray(at,at+4));
 if(tag(0)!=='RIFF'||tag(8)!=='WAVE'||v.getUint32(4,true)+8!==bytes.length)throw Error('Invalid decoded movie WAV container.');
 let at=12,count=0,format=null,data=null;
 while(at<bytes.length){if(++count>1024||at+8>bytes.length)throw Error('Damaged decoded movie WAV.');const length=v.getUint32(at+4,true),end=at+8+length;if(end>bytes.length)throw Error('Truncated decoded movie WAV.');
  if(tag(at)==='fmt '){if(format||length<16||v.getUint16(at+8,true)!==1)throw Error('The movie decoder did not return plain PCM16.');format={channels:v.getUint16(at+10,true),rate:v.getUint32(at+12,true),byteRate:v.getUint32(at+16,true),align:v.getUint16(at+20,true),bits:v.getUint16(at+22,true)};}
  if(tag(at)==='data'){if(data)throw Error('Duplicate decoded movie PCM.');data={at:at+8,length};}at=end+(length&1);
 }
 if(at!==bytes.length||!format||!data||![1,2].includes(format.channels)||format.rate!==context.sampleRate||format.bits!==16||format.align!==format.channels*2||format.byteRate!==format.rate*format.align||data.length%format.align||!data.length||data.length*2>64*1024*1024)throw Error('Invalid decoded movie PCM timing or budget.');
 const frames=data.length/format.align,buffer=context.createBuffer(format.channels,frames,format.rate);
 for(let c=0;c<format.channels;c++){const plane=buffer.getChannelData(c);for(let i=0;i<frames;i++)plane[i]=v.getInt16(data.at+(i*format.channels+c)*2,true)/32768;}
 return buffer;
}
const SOURCE_LIMIT=32*1024*1024;
function abort(){return new DOMException('Movie sound preparation cancelled.','AbortError');}
async function hash(data){if(!globalThis.crypto?.subtle)throw Error('This device cannot safely identify original movie sound.');return Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',data)),x=>x.toString(16).padStart(2,'0')).join('');}
function sourcePath(value){return typeof value==='string'&&value.length<=1024&&/^movie\/[A-Za-z0-9_./-]+\.usm$/.test(value)&&!value.split('/').some(p=>!p||p==='.'||p==='..')?value:null;}
async function readSource(path,signal){
 const response=await fetch('/assets/'+path.split('/').map(encodeURIComponent).join('/'),{signal,cache:'no-store'});
 if(!response.ok)throw Error('The original movie sound is unavailable ('+response.status+').');
 const declared=Number(response.headers.get('content-length'));if(declared>160*1024*1024)throw Error('The original movie exceeds160MiB.');
 if(!response.body?.getReader)throw Error('This browser cannot safely reload bounded movie sound.');
 const reader=response.body.getReader(),parts=[];let size=0;
 try{for(;;){if(signal.aborted)throw abort();const{done,value}=await reader.read();if(done)break;size+=value.length;if(size>160*1024*1024||parts.length>=65536)throw Error('The original movie exceeds its bounded read limit.');parts.push(value);}const data=new Uint8Array(size);let at=0;for(const part of parts){data.set(part,at);at+=part.length;}return data;}finally{try{await reader.cancel();}catch{}reader.releaseLock();}
}
/** Per-preview compressed source ledger. No whole movie or external audio key is
 * retained. Source fetch/decode is serialized so in-flight memory stays bounded.
 * A source evicted from the 32 MiB LRU is reloaded only at its original fixed
 * movie path, and must have exactly the original elementary SHA and timing.
 */
export function createMovieSourceAudio({decoder=decodeAudio}={}){
 const known=new WeakMap(),lru=new Set(),cache=createMovieAudioCache();let held=0,tail=Promise.resolve(),pending=0,generation=0,closed=false,controller=new AbortController();
 function remove(item){if(item.data){held-=item.data.length;item.data=null;}lru.delete(item);}
 function retain(item,data){
  if(data.length>SOURCE_LIMIT)throw Error('The original movie sound exceeds32MiB.');
  if(item.data===data){lru.delete(item);lru.add(item);return;}
  for(const old of lru){if(held+data.length<=SOURCE_LIMIT&&lru.size<8)break;if(!old.busy)remove(old);}
  if(held+data.length>SOURCE_LIMIT||lru.size>=8)throw Error('Other original movie sounds are still using the32MiB source budget.');
  item.data=data;held+=data.length;lru.add(item);
 }
 function remember(blob,source,metadata,path){
  if(closed)throw Error('The original movie sound store is closed.');
  if(metadata===null){known.set(blob,null);return;}
  const sound=extractMovieSound(source,{metadata}),item={kind:sound.kind,metadata:sound.metadata,channel:sound.channel,path:sourcePath(path),data:null,busy:false,signature:null,generation};
  retain(item,sound.data);item.signature=hash(sound.data);item.signature.catch(()=>{});known.set(blob,item);
 }
 async function decode(blob,{context,signal}={}){
  if(closed)throw Error('The original movie sound store is closed.');
  if(!known.has(blob))return undefined;const item=known.get(blob);if(item===null)return null;
  if(item.metadata.channels>2||context?.sampleRate!==48000||Math.ceil(item.metadata.samples*48000/item.metadata.sampleRate)*item.metadata.channels*4>64*1024*1024)throw Error('The original movie sound exceeds its stereo48kHz PCM budget.');
  if(pending>=8)throw Error('Too many original movie sounds are waiting.');
  pending++;const current=generation,ownSignal=controller.signal;
  const work=tail.then(async()=>{
   const stop=new AbortController(),cancel=()=>stop.abort();ownSignal.addEventListener('abort',cancel,{once:true});signal?.addEventListener('abort',cancel,{once:true});
   let key;
   try{
    if(signal?.aborted||ownSignal.aborted||current!==generation||item.generation!==current)throw abort();
    item.busy=true;const signature=await item.signature;if(stop.signal.aborted)throw abort();
    if(!item.data){
     if(!item.path)throw Error('This evicted movie sound has no verified reload path.');
     const source=await readSource(item.path,stop.signal),fresh=extractMovieSound(source,{metadata:item.metadata,signal:stop.signal});
     if(fresh.kind!==item.kind||fresh.channel!==item.channel||await hash(fresh.data)!==signature)throw Error('The original movie sound changed after it was selected. Reload this move before playing it.');
     retain(item,fresh.data);
    }else{lru.delete(item);lru.add(item);}
    const result=await decoder({data:item.data,kind:item.kind,sampleRate:48000,channels:item.metadata.channels,signal:stop.signal});
    if(stop.signal.aborted||current!==generation)throw abort();
    if(!(result?.data instanceof Uint8Array))throw Error('The original movie decoder returned unreadable sound.');
    key='source:'+signature;const buffer=await cache.decode({key,bytes:result.data,metadata:item.metadata,context:{sampleRate:context.sampleRate,state:context.state,createBuffer:(...args)=>context.createBuffer(...args),decodeAudioData:async raw=>pcmMovieWav(new Uint8Array(raw),context)},signal:stop.signal});return buffer;
   }finally{item.busy=false;if(key)cache.release(key);signal?.removeEventListener('abort',cancel);ownSignal.removeEventListener('abort',cancel);}
  });
  tail=work.catch(()=>{});try{return await work;}finally{pending--;}
 }
 function clear(){generation++;controller.abort();controller=new AbortController();cache.clear();for(const item of lru)remove(item);}
 return Object.freeze({remember,has:blob=>known.has(blob),decode,clear,close(){closed=true;clear();cache.close();},stats(){return Object.freeze({sourceBytes:held,sourceEntries:lru.size,pending,closed,decoded:cache.stats()});}});
}
