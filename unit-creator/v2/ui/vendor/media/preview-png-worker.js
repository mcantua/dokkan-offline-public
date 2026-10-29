/* Recovery reconstruction: exact pixel decoder in a dedicated module worker.
 * New source after environment replacement; not the lost tested worker hash. */
import {decodeNativePNG} from './preview-png-decode.js';
import {initializeNativePNGAccelerator} from './preview-png-wasm.js';
let prepared;
self.onmessage=async({data})=>{
 const id=data?.id;
 try{
  if(!Number.isSafeInteger(id)||!(data.bytes instanceof Uint8Array)||!data.bytes.length||data.bytes.length>32*1024*1024)throw Error('Invalid artwork decoding request.');
  if(!prepared)prepared=initializeNativePNGAccelerator().then(accelerator=>({accelerator,error:null}),error=>({accelerator:null,error:String(error?.message||error).slice(0,400)}));
  const {accelerator,error}=await prepared,decoded=decodeNativePNG(data.bytes,{accelerator});
  self.postMessage({id,decoded,engine:accelerator?'wasm':'javascript-worker',acceleratorError:error},[decoded.rgba.buffer]);
 }catch(error){self.postMessage({id,error:String(error?.message||error).slice(0,400)});}
};
