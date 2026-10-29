/* Recovery reconstruction, MIT. One cancellable bounded decoding worker.
 * This source is newly reconstructed, not the lost previously verified file. */
import {decodeNativePNG} from './preview-png-decode.js';
import {initializeNativePNGAccelerator} from './preview-png-wasm.js';
const MAX_INPUT=32*1024*1024,MAX_HELD=64*1024*1024,MAX_JOBS=64;
let queue=[],active=null,worker=null,sequence=0,held=0,idle=null,closing=false,unavailable=false,fallbackPreparation;
const counts={requested:0,workerStarts:0,workerCompleted:0,fallbackCompleted:0,workerErrors:0,canceled:0,timeouts:0,engine:null,lastError:null,acceleratorError:null};
const canceled=()=>new DOMException('Artwork decoding was canceled.','AbortError');
function stopWorker(){clearTimeout(idle);idle=null;const previous=worker;worker=null;previous?.terminate();}
function finish(job,error,result){
 if(job.done)return;job.done=true;clearTimeout(job.timer);job.signal?.removeEventListener('abort',job.abort);held-=job.bytes.length;queue=queue.filter(item=>item!==job);if(active===job)active=null;
 if(error){if(error.name==='AbortError')counts.canceled++;else counts.lastError=String(error.message||error).slice(0,400);job.reject(error);}else job.resolve(result);
 if(!closing)queueMicrotask(drain);
}
function valid(value){return value&&Number.isSafeInteger(value.width)&&Number.isSafeInteger(value.height)&&value.width>0&&value.height>0&&value.width*value.height<=16*1024*1024&&value.rgba instanceof Uint8Array&&value.rgba.length===value.width*value.height*4&&value.metadata?.known===true&&value.metadata.width===value.width&&value.metadata.height===value.height&&typeof value.metadata.premultiplied==='boolean';}
async function drain(){
 if(closing||active)return;clearTimeout(idle);idle=null;const job=queue.shift();if(!job){if(worker)idle=setTimeout(stopWorker,5000);return;}if(job.signal?.aborted){finish(job,canceled());return;}active=job;
 if(unavailable||typeof globalThis.Worker!=='function'){
  try{if(!fallbackPreparation)fallbackPreparation=initializeNativePNGAccelerator().catch(error=>{counts.acceleratorError=String(error?.message||error).slice(0,400);return null;});const accelerator=await fallbackPreparation;if(job.done)return;if(job.signal?.aborted){finish(job,canceled());return;}const decoded=decodeNativePNG(job.bytes,{accelerator});counts.fallbackCompleted++;counts.engine=accelerator?'wasm-main-thread':'javascript';finish(job,null,decoded);}catch(error){finish(job,error);}return;
 }
 try{
  if(!worker){
   let current;try{current=new Worker(new URL('./preview-png-worker.js',import.meta.url),{type:'module',name:'unit-creation-artwork'});}catch(error){unavailable=true;counts.lastError=String(error.message||error).slice(0,400);active=null;queue.unshift(job);drain();return;}
   worker=current;counts.workerStarts++;
   current.onmessage=({data})=>{if(worker!==current||!active||data?.id!==active.id)return;const pending=active;if(data.error){counts.workerErrors++;finish(pending,Error(String(data.error).slice(0,400)));return;}if(!valid(data.decoded)){counts.workerErrors++;stopWorker();finish(pending,Error('The artwork decoder returned invalid pixels.'));return;}counts.workerCompleted++;counts.engine=data.engine==='wasm'?'wasm':'javascript-worker';counts.acceleratorError=data.acceleratorError?String(data.acceleratorError).slice(0,400):null;finish(pending,null,data.decoded);};
   const fail=()=>{if(worker!==current)return;counts.workerErrors++;const pending=active;stopWorker();if(pending)finish(pending,Error('Background artwork decoding could not run. Reopen this preview and try again.'));};current.onerror=fail;current.onmessageerror=fail;
  }
  const bytes=job.bytes.slice();worker.postMessage({id:job.id,bytes},[bytes.buffer]);
 }catch(error){stopWorker();finish(job,error);}
}
export function decodeNativePNGAsync(bytes,{signal,timeoutMs=120000}={}){
 if(signal?.aborted)return Promise.reject(canceled());if(!(bytes instanceof Uint8Array)||!bytes.length||bytes.length>MAX_INPUT)return Promise.reject(Error('This PNG exceeds the artwork decoding limit.'));if(queue.length+(active?1:0)>=MAX_JOBS||held+bytes.length>MAX_HELD)return Promise.reject(Error('Too many pictures are being prepared. Wait for the current preview, then retry.'));
 return new Promise((resolve,reject)=>{const job={id:++sequence,bytes,signal,resolve,reject,done:false,timer:null,abort:null};counts.requested++;job.abort=()=>{if(active===job)stopWorker();finish(job,canceled());};job.timer=setTimeout(()=>{counts.timeouts++;if(active===job)stopWorker();finish(job,Error('Artwork decoding took too long. Try reopening this preview.'));},Math.max(100,Math.min(180000,Number(timeoutMs)||120000)));held+=bytes.length;queue.push(job);signal?.addEventListener('abort',job.abort,{once:true});if(signal?.aborted)job.abort();else drain();});
}
export function cancelPNGDecoding(){closing=true;stopWorker();const pending=[...(active?[active]:[]),...queue];active=null;queue=[];for(const job of pending)finish(job,canceled());closing=false;}
export function pngDecodingStatus(){return Object.freeze({...counts,workerAvailable:!unavailable&&typeof globalThis.Worker==='function',workerActive:!!worker,active:!!active,queued:queue.length,heldInputBytes:held});}
if(typeof globalThis.addEventListener==='function')globalThis.addEventListener('pagehide',cancelPNGDecoding);
