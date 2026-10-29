/* GPL-3.0-or-later Forge adapter; libav.js/runtime dependencies retain LGPL/BSD.
 * Software-decode AV1 one IVF packet at a time and encode a bounded VP8 movie.
 */
self.forgeDecodeAv1 = async function(video, progress) {
  if (video.byteLength < 32) throw new Error('The AV1 movie header is incomplete.');
  const header = new DataView(video.buffer, video.byteOffset, video.byteLength);
  const rate = header.getUint32(16,true), scale = header.getUint32(20,true);
  if (!rate || !scale) throw new Error('The AV1 movie has no valid frame timing.');
  progress({message:'Preparing AV1 game video on your device…'});
  const av1Base = new URL('./libav/', self.location.href).href.replace(/\/+$/, '');
  self.LibAV = { base: av1Base };
  importScripts('./libav/libav-6.10.9.0-av1-opus.js');
  let decoder = await self.LibAV.LibAV({noworker:true,nothreads:true,wasmurl:av1Base+'/libav-6.10.9.0-av1-opus.wasm.wasm'});
  self.LibAV = { base: av1Base };
  importScripts('./libav/libav-6.10.9.0-webm-vp9-cli.js');
  let encoder = await self.LibAV.LibAV({noworker:true,nothreads:true,wasmurl:av1Base+'/libav-6.10.9.0-webm-vp9-cli.wasm.wasm'});
  const [, dc, dpkt, dframe] = await decoder.ff_init_decoder('libaom-av1');
  let ec, eframe, epkt, oc, pb, graph, filterSource, filterSink, filterFrame;
  let frameCount = 0;
  let offset = 32;
  async function encodeFrames(frames, fin) {
    if (frames.length && !ec) {
      const first = frames[0];
      if (first.format !== encoder.AV_PIX_FMT_YUV420P) {
        [graph,filterSource,filterSink] = await encoder.ff_init_filter_graph('format=pix_fmts=yuv420p', {
          type:encoder.AVMEDIA_TYPE_VIDEO,time_base:[scale,rate],frame_rate:rate/scale,
          width:first.width,height:first.height,pix_fmt:first.format
        }, {type:encoder.AVMEDIA_TYPE_VIDEO,time_base:[scale,rate],pix_fmt:encoder.AV_PIX_FMT_YUV420P});
        filterFrame=await encoder.av_frame_alloc();
      }
      [, ec, eframe, epkt] = await encoder.ff_init_encoder('libvpx', {
        ctx: {bit_rate:4000000,pix_fmt:encoder.AV_PIX_FMT_YUV420P,width:first.width,height:first.height,
          time_base:[scale,rate],framerate:[rate,scale]},
        options:{deadline:'realtime','cpu-used':'8','lag-in-frames':'0'}
      });
      let fmt, st;
      [oc,fmt,pb,st] = await encoder.ff_init_muxer({filename:'av1.webm',open:true},[[ec,scale,rate]]);
      await encoder.avformat_write_header(oc,0);
    }
    if (!ec) return;
    // Native AV1 timestamps are frame indices in IVF's timebase.
    for (const frame of frames) {
      if (!Number.isFinite(frame.pts)) {frame.pts=frameCount;frame.ptshi=0;}
      frameCount++;frame.time_base_num=scale;frame.time_base_den=rate;
    }
    if(graph) frames=await encoder.ff_filter_multi(filterSource,filterSink,filterFrame,frames,fin);
    const packets = await encoder.ff_encode_multi(ec,eframe,epkt,frames,fin);
    await encoder.ff_write_multi(oc,epkt,packets);
  }
  while (offset < video.byteLength) {
    if (video.byteLength-offset < 12) throw new Error('The AV1 movie ends inside a frame header.');
    const size = header.getUint32(offset,true);
    const pts = header.getUint32(offset+4,true), ptshi=header.getUint32(offset+8,true);
    offset += 12;
    if (size > video.byteLength-offset) throw new Error('The AV1 movie ends inside a frame.');
    const frames = await decoder.ff_decode_multi(dc,dpkt,dframe,[{data:video.slice(offset,offset+size),pts,ptshi,dts:pts,dtshi:ptshi,flags:0}],false);
    await encodeFrames(frames,false);
    offset+=size;
    progress({progress:offset/video.byteLength});
  }
  await encodeFrames(await decoder.ff_decode_multi(dc,dpkt,dframe,[],true),true);
  if (!frameCount) throw new Error('The AV1 movie contains no decoded frames.');
  await encoder.av_write_trailer(oc);
  const output=await encoder.readFile('av1.webm');
  await encoder.ff_free_muxer(oc,pb);
  await encoder.ff_free_encoder(ec,eframe,epkt);
  await decoder.ff_free_decoder(dc,dpkt,dframe);
  await encoder.unlink('av1.webm');
  if(graph){await encoder.avfilter_graph_free_js(graph);await encoder.av_frame_free_js(filterFrame);}
  decoder.terminate();encoder.terminate();decoder=null;encoder=null;
  return output;
};
