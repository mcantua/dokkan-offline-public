/* GPL-3.0-or-later Forge adapter. Existing LibAV AV1 decode -> lossless VP9.
 * Avoids a lossy intermediate generation before the editable frame pipeline.
 * Sources above 8-bit are explicitly normalized to the native 8-bit export path.
 */
self.prepareForgeAv1Edit=async function(video,progress,options={}){
 if(!(video instanceof Uint8Array)||video.length<44||video.length>160*1024*1024)throw Error('The AV1 source is incomplete.');const view=new DataView(video.buffer,video.byteOffset,video.byteLength);if(String.fromCharCode(...video.subarray(0,4))!=='DKIF'||String.fromCharCode(...video.subarray(8,12))!=='AV01'||view.getUint16(6,true)!==32)throw Error('Choose a supported AV1 game stream.');const width=view.getUint16(12,true),height=view.getUint16(14,true),n=view.getUint32(16,true),d=view.getUint32(20,true);if(!width||!height||width%2||height%2||width>4096||height>4096||width*height>16*1024*1024||!n||!d||n/d<1||n/d>120||n>2147483647||d>1000000)throw Error('The AV1 source dimensions or timing are unsupported.');const packets=[];let offset=32;while(offset<video.length){if(offset+12>video.length||packets.length>=10000)throw Error('The AV1 frame list is incomplete or oversized.');const size=view.getUint32(offset,true);if(!size||offset+12+size>video.length||view.getBigUint64(offset+4,true)!==BigInt(packets.length))throw Error('The AV1 movie has unreadable frame timing.');packets.push({offset:offset+12,size});offset+=12+size;}if(!packets.length||view.getUint32(24,true)&&view.getUint32(24,true)!==packets.length)throw Error('The AV1 frame count is inconsistent.');
 const end=options.endFrame;
 if(end!==undefined&&(!Number.isSafeInteger(end)||end<=0))throw Error('Choose a valid movie end time.');
 const wanted=end===undefined?packets.length:Math.min(packets.length,end);
 const base=new URL('./libav/',self.location.href).href.replace(/\/+$/,'');self.LibAV={base};importScripts('./libav/libav-6.10.9.0-av1-opus.js');
 const decoder=await self.LibAV.LibAV({noworker:true,nothreads:true,wasmurl:base+'/libav-6.10.9.0-av1-opus.wasm.wasm'});let state,sink,count=0;
 try{
  state=await decoder.ff_init_decoder('libaom-av1');sink=await self.createForgeVp9Sink({width,height,rate:{n,d},frames:wanted,lossless:true,quality:0});
  const accept=rows=>{for(const frame of rows){if(count>=wanted)break;sink.pushFrame(frame);count++;}};
  for(let index=0;index<packets.length&&count<wanted;index++){
   const packet=packets[index];accept(await decoder.ff_decode_multi(state[1],state[2],state[3],[{data:video.subarray(packet.offset,packet.offset+packet.size),pts:index,ptshi:0,dts:index,dtshi:0,flags:0}],false));
   progress({message:'Reading the selected AV1 movie section…',progress:count/wanted,decodedFrames:count,requiredFrames:wanted,sourceFrames:packets.length});
  }
  if(count<wanted)accept(await decoder.ff_decode_multi(state[1],state[2],state[3],[],true));
  return sink.finish();
 }finally{try{sink?.close();}finally{if(state)await decoder.ff_free_decoder(state[1],state[2],state[3]);decoder.terminate();}}
};
