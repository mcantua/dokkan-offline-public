/* GPL-3.0-or-later. Local single-thread FFmpeg worker; no network service. */
'use strict';
self.onmessage = async ({ data }) => {
  const logs = [];
  try {
    const free=data.outputProfile==='vp9-opus';
    if (!data.copyVideo && data.video.byteLength >= 12 && String.fromCharCode(...data.video.subarray(0,4)) === 'DKIF' &&
        String.fromCharCode(...data.video.subarray(8,12)) === 'AV01') {
      if(free){
        importScripts('./vp9-stream-encoder.js','./av1-edit-source.js');
        data.video=await self.prepareForgeAv1Edit(data.video,event=>self.postMessage({type:'progress',event}));
        data.kind='vp9-ivf';data.copyVideo=true;
      }else{
        importScripts('./av1-fallback.js');
        data.video = await self.forgeDecodeAv1(data.video, event => self.postMessage({type:'progress',event}));
        data.kind = 'webm';
        data.copyVideo = false;
      }
    }
    if(data.audio&&data.audioKind==='adx'&&data.audio[4]===3&&[3,4].includes(data.audio[18])&&data.audio[7]<=2&&new DataView(data.audio.buffer,data.audio.byteOffset,data.audio.byteLength).getUint32(8)<=96000){
      importScripts('./native-adx.js');
      data.audio=ForgeNativeAdx.pcmToWav(ForgeNativeAdx.decodeADX(data.audio));
      data.audioKind='wav';
    }
    let hca;if(data.audio&&data.audioKind==='hca'){importScripts('./hca-metadata.js');const prepared=ForgeHcaMetadata.prepare(data.audio);data.audio=prepared.data;hca=prepared.info;}
    importScripts('./ffmpeg-core.js');
    const core = await createFFmpegCore({
      locateFile: path => new URL(path, self.location.href).href
    });
    core.setLogger(({ message }) => {
      logs.push(String(message));
      if (logs.length > 12) logs.shift();
    });
    core.setProgress(({ progress, time }) => {
      self.postMessage({ type: 'progress', event: { progress, time } });
    });
    self.postMessage({ type: 'progress', event: { message: 'Preparing this older game video on your device…' } });
    if(free&&!data.copyVideo){
      if(data.video.length>=12&&String.fromCharCode(...data.video.subarray(0,4))==='DKIF'&&String.fromCharCode(...data.video.subarray(8,12))==='VP90')data.copyVideo=true;
      else{
        importScripts('./free-codec.js');
        data.video=await self.forgePrepareVp9(core,data,event=>self.postMessage({type:'progress',event}));
        data.kind='vp9-ivf';data.copyVideo=true;
      }
    }
    core.FS.writeFile('input.video', data.video);
    const args = ['-hide_banner', '-loglevel', 'error', '-nostdin', '-threads', '1'];
    const formats = { 'mpeg2': 'mpegvideo', 'mpeg2-es': 'mpegvideo', 'mpeg-2': 'mpegvideo', 'mpeg2-video': 'mpegvideo', 'mpeg-ps': 'mpeg',
      'h264': 'h264', 'h264-annexb': 'h264', 'mpeg4': 'm4v', 'mpeg4-es': 'm4v', 'vp9': 'ivf', 'vp9-ivf': 'ivf' };
    const format = formats[data.kind];
    if (format) args.push('-f', format);
    // Raw H.264/MPEG4 streams often have no container clock. The USM header's
    // rate is authoritative when the caller has one; otherwise FFmpeg probes.
    if (Number.isFinite(data.framerate) && data.framerate >= 1 && data.framerate <= 120) {
      args.push('-r', String(data.framerate));
    }
    args.push('-i', 'input.video');
    if (data.audio) {
      core.FS.writeFile('input.audio', data.audio);
      const audioFormats = { wav: 'wav', adx: 'adx', hca: 'hca', ogg: 'ogg' };
      if (audioFormats[data.audioKind]) args.push('-f', audioFormats[data.audioKind]);
      args.push('-i', 'input.audio');
    }
    args.push('-map', '0:v:0');
    if (data.audio) {args.push('-map', '1:a:0');if(hca)args.push('-af',ForgeHcaMetadata.filters(hca));args.push('-c:a', free?'opus':'aac', '-b:a', '192k');if(free)args.push('-strict','-2');}
    else args.push('-an');
    args.push('-threads', '1');
    if (data.copyVideo) args.push('-c:v', 'copy');
    else args.push('-c:v', 'libx264', '-preset', 'ultrafast', '-crf', '20', '-pix_fmt', 'yuv420p',
      '-vf', 'scale=trunc(iw/2)*2:trunc(ih/2)*2');
    // Preserve exact 48 kHz audio edit durations and observed 30/60/NTSC clocks.
    args.push('-movie_timescale', '240000', '-movflags', '+faststart', '-y', 'output.mp4');
    const code = core.exec(...args);
    if (code !== 0) throw new Error('The older video stream could not be decoded. ' + logs.slice(-3).join(' '));
    const output = core.FS.readFile('output.mp4');
    if (!output.byteLength || output.byteLength > 160 * 1024 * 1024) {
      throw new Error('The prepared video exceeds the supported movie size.');
    }
    const bytes = output.slice();
    if(free&&data.audio){importScripts('./free-codec.js');self.forgeFixOpusPriming(bytes);}
    core.FS.unlink('input.video');
    core.FS.unlink('output.mp4');
    if (data.audio) core.FS.unlink('input.audio');
    self.postMessage({ type: 'result', data: bytes }, [bytes.buffer]);
  } catch (error) {
    self.postMessage({ type: 'error', message: String(error?.message || error) });
  }
};
