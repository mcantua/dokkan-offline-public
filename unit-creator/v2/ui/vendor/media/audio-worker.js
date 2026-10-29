/* GPL-3.0-or-later. Original bounded audio-only worker for bundled FFmpeg. */
'use strict';
self.onmessage=async({data:r})=>{try{
 if(!r||!['adx','hca','wav'].includes(r.kind)||!(r.data instanceof Uint8Array)||!r.data.length||r.data.length>160*1024*1024)throw Error('Invalid or oversized game sound.');
 if(r.kind==='adx'&&(r.data.length<24||r.data[19]!==0))throw Error('Prepare the ADX sound before decoding it.');
 let hca;if(r.kind==='hca'){importScripts('./hca-metadata.js');const prepared=ForgeHcaMetadata.prepare(r.data);r.data=prepared.data;hca=prepared.info;}
 if(!Number.isFinite(r.gain)||r.gain<0||r.gain>1)throw Error('Invalid game sound volume.');
 if(r.kind==='adx'&&[3,4].includes(r.data[18])&&r.data[7]<=2&&new DataView(r.data.buffer,r.data.byteOffset,r.data.byteLength).getUint32(8)<=96000){importScripts('./native-adx.js');r.data=ForgeNativeAdx.pcmToWav(ForgeNativeAdx.decodeADX(r.data));r.kind='wav';}
 importScripts('./ffmpeg-core.js');const core=await createFFmpegCore({locateFile:p=>new URL(p,self.location.href).href}),logs=[];
 core.setLogger(({message})=>{logs.push(String(message));if(logs.length>4)logs.shift()});
 core.FS.writeFile('input.'+r.kind,r.data);
 const rate=Number.isInteger(r.sampleRate)&&r.sampleRate>=8000&&r.sampleRate<=48000?r.sampleRate:48000,channels=r.channels===1?1:2;
 const filters=[];if(hca)filters.push(ForgeHcaMetadata.filters(hca));if(r.kind==='adx')filters.push('atrim=end_sample='+new DataView(r.data.buffer,r.data.byteOffset,r.data.byteLength).getUint32(12));if(r.gain!==1)filters.push('volume='+r.gain+':precision=float');const trim=filters.length?['-af',filters.join(',')]:[];
 const code=core.exec('-hide_banner','-loglevel','error','-nostdin','-threads','1','-f',r.kind,'-i','input.'+r.kind,'-map','0:a:0','-vn',...trim,'-t','600','-ar',String(rate),'-ac',String(channels),'-c:a','pcm_s16le','-fs',String(160*1024*1024),'-y','output.wav');
 if(code!==0)throw Error('This game sound could not be decoded. '+logs.join(' '));
 const output=core.FS.readFile('output.wav');if(output.length<44||output.length>160*1024*1024)throw Error('The prepared sound exceeds the supported size.');
 const data=output.slice();self.postMessage({type:'result',data},[data.buffer]);
}catch(e){self.postMessage({type:'error',message:String(e?.message||e)})}};
