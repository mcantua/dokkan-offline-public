/* Original GPL-3.0-or-later bounded adapter. Existing LibAV/libvpx retains
 * LGPL/BSD licensing. No external service or additional codec binary is used. */
'use strict';
self.forgePrepareVp9=async function(core,data,progress=()=>{}){
 const {width,height,frames,rate}=data.metadata||{};
 if(!Number.isInteger(width)||!Number.isInteger(height)||width<2||height<2||width%2||height%2||width>4096||height>4096||width*height>16*1024*1024||!Number.isInteger(frames)||frames<1||frames>10000||!Number.isInteger(rate?.n)||!Number.isInteger(rate?.d)||rate.n<1||rate.n>1000000||rate.d<1||rate.d>10000||rate.n/rate.d<1||rate.n/rate.d>120)throw Error('This movie needs valid bounded frame dimensions and timing for the compatible decoder.');
 const formats={'mpeg1':'mpegvideo','mpeg2':'mpegvideo','mpeg2-es':'mpegvideo','mpeg-2':'mpegvideo','mpeg2-video':'mpegvideo','mpeg-ps':'mpeg',h264:'h264','h264-annexb':'h264',mpeg4:'m4v','mpeg4-es':'m4v',vp9:'ivf','vp9-ivf':'ivf',webm:'matroska'};
 let sink;
 try{
  importScripts('./vp9-stream-encoder.js');
  sink=await self.createForgeVp9Sink({width,height,frames,rate,quality:20,lossless:false});
  const device=core.FS.makedev(73,1);core.FS.registerDevice(device,{open(stream){stream.seekable=false;},write(_stream,buffer,offset,length){return sink.write(buffer,offset,length);}});core.FS.mkdev('/forge-compatible.raw',384,device);core.FS.writeFile('forge-source.video',data.video);
  const args=['-hide_banner','-loglevel','error','-nostdin','-threads','1','-r',rate.n+'/'+rate.d];if(formats[data.kind])args.push('-f',formats[data.kind]);args.push('-i','forge-source.video','-map','0:v:0','-an','-threads','1','-c:v','rawvideo','-vf','scale='+width+':'+height,'-pix_fmt','yuv420p','-f','rawvideo','-y','/forge-compatible.raw');
  progress({message:'Preparing a compatible video codec on your device…'});
  const code=core.exec(...args);if(code!==0)throw Error('The movie could not be prepared with the compatible video decoder.');return sink.finish();
 }finally{
  sink?.close();core.reset();for(const path of ['forge-source.video','/forge-compatible.raw'])try{core.FS.unlink(path);}catch(_){/* Worker owns all remaining resources. */}
 }
};

// MOV edits already remove the encoder's initial delay. Opus' decoder pre-skip
// must not remove that same delay again. Retain the exact container edit/clock;
// only the newly encoded owned Opus sample-description header is normalized.
self.forgeFixOpusPriming=function(bytes){
 if(!(bytes instanceof Uint8Array)||bytes.length<12||bytes.length>160*1024*1024)throw Error('Invalid compatible movie output.');
 const view=new DataView(bytes.buffer,bytes.byteOffset,bytes.byteLength),text=at=>String.fromCharCode(...bytes.subarray(at,at+4));
 function boxes(start,end){const rows=[];for(let at=start;at<end;){if(at+8>end||rows.length>4096)throw Error('Incomplete compatible MP4 box.');let size=view.getUint32(at),header=8;if(size===1){if(at+16>end)throw Error('Incomplete compatible MP4 box.');const wide=view.getBigUint64(at+8);if(wide>BigInt(Number.MAX_SAFE_INTEGER))throw Error('Oversized compatible MP4 box.');size=Number(wide);header=16;}else if(size===0)size=end-at;if(size<header||at+size>end)throw Error('Invalid compatible MP4 box.');rows.push({type:text(at+4),start:at,data:at+header,end:at+size});at+=size;}return rows;}
 const one=(rows,type)=>{const found=rows.filter(b=>b.type===type);if(found.length!==1)throw Error('Missing or ambiguous compatible MP4 '+type+'.');return found[0];};
 const moov=one(boxes(0,bytes.length),'moov');let changed=0,preSkip=0;
 for(const track of boxes(moov.data,moov.end).filter(b=>b.type==='trak')){
  const children=boxes(track.data,track.end),mdia=one(children,'mdia'),md=boxes(mdia.data,mdia.end),hdlr=one(md,'hdlr');if(hdlr.data+12>hdlr.end)throw Error('Incomplete compatible MP4 handler.');if(text(hdlr.data+8)!=='soun')continue;
  const minf=one(md,'minf'),stbl=one(boxes(minf.data,minf.end),'stbl'),stsd=one(boxes(stbl.data,stbl.end),'stsd');if(stsd.data+8>stsd.end||view.getUint32(stsd.data+4)!==1)throw Error('Unsupported compatible audio description.');const entry=one(boxes(stsd.data+8,stsd.end),'Opus');if(entry.data+28>entry.end)throw Error('Incomplete Opus sample description.');const ops=one(boxes(entry.data+28,entry.end),'dOps');if(ops.end-ops.data<11||bytes[ops.data]!==0)throw Error('Unsupported Opus sample header.');const skip=view.getUint16(ops.data+2);if(!skip)continue;
  const edts=one(children,'edts'),elst=one(boxes(edts.data,edts.end),'elst'),p=elst.data,version=bytes[p];if(p+8>elst.end||view.getUint32(p+4)!==1||![0,1].includes(version))throw Error('Unsupported Opus timing edit.');const entryBytes=version===1?20:12;if(p+8+entryBytes!==elst.end)throw Error('Incomplete Opus timing edit.');const time=version===1?view.getBigInt64(p+16):BigInt(view.getInt32(p+12)),rateAt=p+(version===1?24:16);if(time!==BigInt(skip)||view.getInt32(rateAt)!==65536)throw Error('The Opus delay differs from its container edit.');
  view.setUint16(ops.data+2,0);preSkip=skip;changed++;
 }
 if(changed!==1)throw Error('The compatible movie needs exactly one fresh Opus timing edit.');return{containerTrimmedSamples:preSkip,decoderPreSkip:0};
};
