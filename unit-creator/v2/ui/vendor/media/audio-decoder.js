/* GPL-3.0-or-later. Bounded local Atom waveform preparation; see NOTICE.txt. */
const LIMIT=160*1024*1024,queue=[];let active=false;
/** Decode an already-decrypted ADX, HCA or WAV to a browser-readable PCM WAV.
 * Plain common ADX is decoded with native CRI arithmetic in the worker before
 * FFmpeg applies gain/resampling; its incompatible ADX arithmetic is bypassed.
 * HCA support depends on its cipher being supported by FFmpeg; never guess keys.
 * Normalises unsupported >stereo/>48kHz sources to bounded stereo/48kHz output.
 */
export async function decodeAudio(request){
 const data=request?.data instanceof Uint8Array?request.data:request?.data instanceof ArrayBuffer?new Uint8Array(request.data):null;
 if(!data?.length||data.length>LIMIT)throw Error('This sound is empty or exceeds160MiB.');
 if(!['adx','hca','wav'].includes(request.kind))throw Error('This game sound format is unsupported.');
 if(request.kind==='adx'){
  const d=new DataView(data.buffer,data.byteOffset,data.byteLength);if(data.length<24||d.getUint16(0)!==0x8000||data[4]!==3||data[5]!==18||data[6]!==4||data[19]!==0)throw Error('Prepare the encrypted ADX sound before decoding it.');
  const channels=data[7],rate=d.getUint32(8),samples=d.getUint32(12),offset=d.getUint16(2)+4;
  if(!channels||channels>8||rate<8000||rate>192000||!samples||samples*channels*2>LIMIT||samples/rate>600||offset<24||offset>data.length||Math.ceil(samples/32)*18*channels>data.length-offset)throw Error('This ADX sound has invalid or oversized sample data.');
 }
 if(request.gain!==undefined&&(!Number.isFinite(request.gain)||request.gain<0||request.gain>1))throw Error('This sound has an unsupported volume.');
 if(request.signal?.aborted)throw new DOMException('Sound preparation cancelled.','AbortError');
 if(typeof Worker!=='function'||typeof WebAssembly!=='object')throw Error('This device needs a newer browser to prepare game sounds.');
 if(queue.length+(active?1:0)>=24)throw Error('Too many game sounds are waiting.');
 return await new Promise((resolve,reject)=>{const e={request,data,resolve,reject};e.abort=()=>{const i=queue.indexOf(e);if(i>=0){queue.splice(i,1);request.signal?.removeEventListener('abort',e.abort);reject(new DOMException('Sound preparation cancelled.','AbortError'));}};request.signal?.addEventListener('abort',e.abort,{once:true});queue.push(e);pump();});
}
async function pump(){if(active||!queue.length)return;active=true;const e=queue.shift();e.request.signal?.removeEventListener('abort',e.abort);try{e.resolve(await run(e))}catch(error){e.reject(error)}finally{active=false;pump()}}
async function run({request,data}){
 if(request.signal?.aborted)throw new DOMException('Sound preparation cancelled.','AbortError');
 const worker=new Worker(new URL('./audio-worker.js',import.meta.url));
 try{return await new Promise((resolve,reject)=>{let done=false,timer;const end=(error,value)=>{if(done)return;done=true;clearTimeout(timer);request.signal?.removeEventListener('abort',abort);worker.terminate();error?reject(error):resolve(value)},abort=()=>end(new DOMException('Sound preparation cancelled.','AbortError'));request.signal?.addEventListener('abort',abort,{once:true});timer=setTimeout(()=>end(Error('This sound took too long to prepare.')),Math.max(1000,Math.min(300000,request.timeoutMs||60000)));worker.onerror=e=>end(Error(e.message||'The local sound decoder could not start.'));worker.onmessageerror=()=>end(Error('The sound decoder returned unreadable data.'));worker.onmessage=({data:r})=>{if(r.type==='result'){if(!(r.data instanceof Uint8Array)||!r.data.length||r.data.length>LIMIT)return end(Error('The sound decoder returned invalid data.'));end(null,{data:r.data,mime:'audio/wav'})}else if(r.type==='error')end(Error(r.message||'This sound could not be decoded.'));};try{const copy=data.slice();worker.postMessage({data:copy,kind:request.kind,sampleRate:request.sampleRate,channels:request.channels,gain:request.gain===undefined?1:request.gain},[copy.buffer])}catch(error){end(error)}})}finally{worker.terminate()}
}
