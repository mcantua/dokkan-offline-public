/* Original Forge bounded movie sound extraction. GPL-3.0-or-later.
 * Scheduling, mute, gain and native movie ownership belong to the AudioBus.
 */
import {readUsmMetadata} from '/tools/usm-player/js/forge-metadata.js';
const INPUT_LIMIT=160*1024*1024,PCM_LIMIT=64*1024*1024,decodeDetails=new WeakMap();
export function movieAudioDecodeInfo(buffer){return decodeDetails.get(buffer)||null;}
function abortError(){return new DOMException('Movie sound preparation cancelled.','AbortError');}
function bytesOf(input){if(input instanceof Uint8Array)return input;if(input instanceof ArrayBuffer)return new Uint8Array(input);throw Error('Movie sound needs bounded movie bytes.');}
function checkedMetadata(value){
 if(!value||!Number.isSafeInteger(value.samples)||value.samples<1||!Number.isInteger(value.sampleRate)||value.sampleRate<8000||value.sampleRate>192000||!Number.isInteger(value.channels)||value.channels<1||value.channels>8||!Number.isSafeInteger(value.samples*value.channels*4))throw Error('This movie has missing or unsupported sound timing.');
 return{samples:value.samples,sampleRate:value.sampleRate,channels:value.channels};
}
/** Read only owned USM structure. No elementary stream copy or decode occurs. */
export function sourceMovieAudioMetadata(input){
 const bytes=bytesOf(input);if(bytes.length<32||bytes.length>INPUT_LIMIT||String.fromCharCode(...bytes.subarray(0,4))!=='CRID')throw Error('This movie has an invalid or oversized USM source.');
 const container=readUsmMetadata(bytes),view=new DataView(bytes.buffer,bytes.byteOffset,bytes.byteLength);let at=0,chunks=0,foundAudio=false,selectedAudioChannel=null,adx=null,audioBytes=0;
 while(at<bytes.length){
  if(++chunks>65536)throw Error('This movie has too many sound containers.');
  if(bytes.length-at<32){if(bytes.length-at<=2048&&bytes.subarray(at).every(x=>x===0))break;throw Error('This movie has an incomplete sound container.');}
  const tag=String.fromCharCode(...bytes.subarray(at,at+4));
  if(tag!=='CRID'&&!/^@[A-Z0-9]{3}$/.test(tag)){if(bytes.length-at<=2048&&bytes.subarray(at).every(x=>x===0))break;throw Error('This movie has an invalid sound container.');}
  const size=view.getUint32(at+4),header=view.getUint16(at+8),padding=view.getUint16(at+10),end=at+8+size;
  if(size<24||header<24||header+padding>size||end>bytes.length)throw Error('This movie has a damaged sound container.');
  if(tag==='@SFA'&&selectedAudioChannel===null)selectedAudioChannel=bytes[at+12];
  if(tag==='@SFA'&&bytes[at+12]===selectedAudioChannel){
   foundAudio=true;
   if(bytes[at+15]===0){const start=at+8+header,stop=end-padding;audioBytes+=stop-start;
    if(!adx&&stop-start>=24&&view.getUint16(start)===0x8000){
     if(![2,3,4].includes(bytes[start+4])||bytes[start+5]!==18||bytes[start+6]!==4)throw Error('This movie uses an unsupported ADX sound header.');
     const offset=view.getUint16(start+2)+4;if(offset<20||offset>1024*1024)throw Error('This movie has invalid ADX sound timing.');
     adx={...checkedMetadata({samples:view.getUint32(start+12),sampleRate:view.getUint32(start+8),channels:bytes[start+7]}),offset};
    }
   }
  }
  at=end;
 }
 if(!foundAudio){if(container.audio)throw Error('This movie declares sound without its audio stream.');return null;}
 const declared=container.audio?checkedMetadata(container.audio):null;
 if(adx){
  if(adx.offset+Math.ceil(adx.samples/32)*18*adx.channels>audioBytes)throw Error('The movie sound ends before its declared samples.');
  if(declared&&['samples','sampleRate','channels'].some(k=>declared[k]!==adx[k]))throw Error('The movie sound headers disagree about their timing.');
  return Object.freeze({samples:adx.samples,sampleRate:adx.sampleRate,channels:adx.channels});
 }
 if(declared&&audioBytes>0)return Object.freeze(declared);
 throw Error('This movie audio stream has no verified sample timing.');
}

/** Cache only decoded PCM, keyed by exact compressed SHA-256 and output rate.
 * Cancelled native decodeAudioData calls cannot be interrupted by browsers;
 * their memory reservations remain until they actually settle.
 */
export function createMovieAudioCache({maxBytes=PCM_LIMIT,maxEntries=8,timeoutMs=30000}={}){
 if(!Number.isSafeInteger(maxBytes)||maxBytes<4||maxBytes>PCM_LIMIT||!Number.isInteger(maxEntries)||maxEntries<1||maxEntries>32||!Number.isInteger(timeoutMs)||timeoutMs<1000||timeoutMs>300000)throw Error('Invalid movie sound cache limits.');
 const cached=new Map(),pending=new Set();let cachedBytes=0,reservedBytes=0,inputBytes=0,generation=0,closed=false;
 function drop(id){const item=cached.get(id);if(item){cached.delete(id);cachedBytes-=item.bytes;}}
 function evict(required){while(cached.size&&(cached.size>=maxEntries||cachedBytes+reservedBytes+required>maxBytes))drop(cached.keys().next().value);}
 function clear(){generation++;for(const entry of pending)entry.cancel(abortError());cached.clear();cachedBytes=0;}
 async function decode({key,bytes,metadata,context,signal}={}){
  if(closed)throw Error('The movie sound cache is closed.');
  if(signal?.aborted)throw abortError();
  if(metadata===null)return null;
  const info=checkedMetadata(metadata),source=bytesOf(bytes),rate=context?.sampleRate;
  if(typeof key!=='string'||!key||key.length>1024||typeof context?.decodeAudioData!=='function'||context.state==='closed'||!Number.isInteger(rate)||rate<8000||rate>192000)throw Error('Movie sound needs a valid owner and audio context.');
  if(!source.length||source.length>INPUT_LIMIT)throw Error('The prepared movie exceeds the sound read limit.');
  const exactFrames=info.samples*rate/info.sampleRate,expectedFrames=Math.ceil(exactFrames),reservation=expectedFrames*info.channels*4;
  if(!Number.isSafeInteger(expectedFrames)||!Number.isSafeInteger(reservation)||reservation>maxBytes)throw Error('The movie sound exceeds the 64 MiB decoded-audio limit.');
  if(pending.size>=8||inputBytes+source.length>INPUT_LIMIT)throw Error('Too many movie sounds are being prepared.');
  const inputSize=source.length;inputBytes+=inputSize;let ownedReservation=0;
  const current=generation;let cancelled=false,rejectCancelled,timer;
  const cancellation=new Promise((_,reject)=>rejectCancelled=reject);
  const entry={key,cancel(error){if(cancelled)return;cancelled=true;rejectCancelled(error);}};pending.add(entry);
  const abort=()=>entry.cancel(abortError());signal?.addEventListener('abort',abort,{once:true});
  const alive=()=>{if(cancelled||current!==generation||closed)throw abortError();};
  timer=setTimeout(()=>entry.cancel(Error('This movie sound took too long to decode.')),timeoutMs);
  const work=(async()=>{
   let snapshot;
   try{
    alive();snapshot=new Uint8Array(source.length);snapshot.set(source);
    if(!globalThis.crypto?.subtle)throw Error('This device cannot safely identify movie sound data.');
    const digest=new Uint8Array(await crypto.subtle.digest('SHA-256',snapshot));alive();
    const hash=Array.from(digest,x=>x.toString(16).padStart(2,'0')).join(''),id=[key,hash,info.samples,info.sampleRate,info.channels,rate].join('\0');
    const previous=cached.get(id);if(previous){cached.delete(id);cached.set(id,previous);return previous.buffer;}
    evict(reservation);if(cachedBytes+reservedBytes+reservation>maxBytes)throw Error('Other movie sounds are still using the decoded-audio budget.');
    reservedBytes+=reservation;ownedReservation=reservation;
    // The copied ArrayBuffer may be detached by decodeAudioData. Never pass the
    // caller's prepared bytes, which are also used for video and export.
    let buffer=await context.decodeAudioData(snapshot.buffer);snapshot=null;alive();
    if(!buffer||buffer.sampleRate!==rate||buffer.numberOfChannels!==info.channels||!Number.isInteger(buffer.length)||buffer.length<1||buffer.length<Math.floor(exactFrames)||buffer.length>expectedFrames+1)throw Error('The decoded movie sound has incorrect channel or sample timing.');
    const decodedFrames=buffer.length,trailingSamples=[],boundarySamples=[];
    if(buffer.length===expectedFrames+1){
     // WebKit/GStreamer measurably rounds this AAC track's final duration up
     // by one sample. The original USM sample count is authoritative. Correct
     // only that one trailing frame; never conceal larger priming/tail errors.
     if(typeof buffer.getChannelData!=='function'||typeof context.createBuffer!=='function')throw Error('The decoded movie sound has incorrect channel or sample timing.');
     const exact=context.createBuffer(info.channels,expectedFrames,rate);
     for(let channel=0;channel<info.channels;channel++){const data=buffer.getChannelData(channel);if(!(data instanceof Float32Array)||data.length!==decodedFrames)throw Error('The decoded movie sound has incorrect channel or sample timing.');trailingSamples.push(data[expectedFrames]);boundarySamples.push(data[expectedFrames-1]);exact.getChannelData(channel).set(data.subarray(0,expectedFrames));}
     buffer=exact;
    }
    decodeDetails.set(buffer,Object.freeze({sourceSamples:info.samples,sourceSampleRate:info.sampleRate,contextSampleRate:rate,decodedFrames,preparedFrames:buffer.length,trimmedTrailingFrames:decodedFrames-buffer.length,trailingSamples:Object.freeze(trailingSamples),boundarySamples:Object.freeze(boundarySamples)}));
    const size=buffer.length*buffer.numberOfChannels*4;if(!Number.isSafeInteger(size)||size>reservation)throw Error('The decoded movie sound exceeds its reserved budget.');
    while(cached.size>=maxEntries)drop(cached.keys().next().value);
    cached.set(id,{key,buffer,bytes:size});cachedBytes+=size;return buffer;
   }finally{snapshot=null;reservedBytes-=ownedReservation;inputBytes-=inputSize;pending.delete(entry);clearTimeout(timer);signal?.removeEventListener('abort',abort);}
  })();
  return await Promise.race([work,cancellation]);
 }
 return Object.freeze({decode,clear,release(key){for(const[id,item]of cached)if(item.key===key)drop(id);for(const entry of pending)if(entry.key===key)entry.cancel(abortError());},close(){closed=true;clear();},stats(){return Object.freeze({entries:cached.size,cachedBytes,reservedBytes,inputBytes,pending:pending.size,closed});}});
}
