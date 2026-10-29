/* GPL-3.0-or-later. Lazy browser compatibility editor, using the bundled
 * FFmpeg 0.12.10 core and original bounded Forge planners/codecs. No keys. */
'use strict';
importScripts('../vendor/media/movie-edit-plan.js', '../vendor/media/native-adx.js', '../vendor/media/hca-metadata.js', '../vendor/media/usm-writer.js');
const LIMIT = 64 * 1048576, formats = { 'vp9-ivf': 'ivf', 'av1-ivf': 'ivf', mpeg1: 'mpegvideo', mpeg2: 'mpegvideo', mpeg4: 'm4v', h264: 'h264' };
let waiting = null, busy = false;
const progress = (message, value) => self.postMessage({ type: 'progress', event: { message, progress: value } });
function validate(request) {
  const p = ForgeMovieEditPlan.plan(request);
  p.lossless = p.lossless || p.quality === 0;
  if (p.preserveAudio) throw Error('Choose Auto sound when using compatibility encoding. Original files are kept.');
  if (p.width * p.height > 4 * 1048576 || p.frames / p.rate.fps > 180 || p.samples * 4 > LIMIT) throw Error('For phone memory, compatibility movies support up to 4 million pixels, three minutes and 64 MiB of decoded sound.');
  let total = 0; const seen = new Set();
  for (const c of p.clips) {
    for (const b of [c.video, c.audio]) if (b && !seen.has(b)) { total += b.length; seen.add(b); }
    if (total > LIMIT) throw Error('Choose up to 64 MiB of source picture and sound.');
    const t = c.transform, angle = t.rotation * Math.PI / 180, w = p.width * t.scale, h = p.height * t.scale;
    if ((Math.abs(Math.cos(angle)) * w + Math.abs(Math.sin(angle)) * h) * (Math.abs(Math.sin(angle)) * w + Math.abs(Math.cos(angle)) * h) > 8 * 1048576) throw Error('This zoom or rotation needs a smaller picture for phone memory.');
    if (p.audio && c.audio) {
      const info = c.audioKind === 'hca' ? ForgeHcaMetadata.inspect(c.audio) : ForgeNativeAdx.inspect(c.audio);
      if ((info.encodedSamples || info.samples) * info.channels * 2 + 4096 > LIMIT) throw Error('A source sound expands beyond the 64 MiB compatibility limit.');
    }
  }
  return p;
}
async function runtime(heapLimit) {
  const bytes = await new Promise(resolve => { waiting = resolve; self.postMessage({ type: 'runtime' }); });
  if (!(bytes instanceof ArrayBuffer) || bytes.byteLength < 1048576 || bytes.byteLength > 40 * 1048576) throw Error('The bundled compatibility decoder is incomplete.');
  importScripts('../vendor/media/ffmpeg-core.js');
  const core = await createFFmpegCore({ wasmBinary: new Uint8Array(bytes) });
  // This pinned Emscripten runtime grows its heap through memory.grow in its
  // JS resize import. Keep that allocator within 512 MiB, including decoder
  // frames and MEMFS. Lossless decoding runs in a fresh worker after this
  // encoder worker has terminated, keeping only one compatibility heap alive.
  const memory = Object.values(core.asm).find(value => value instanceof WebAssembly.Memory);
  if (!memory || memory.buffer.byteLength > heapLimit) throw Error('The compatibility decoder exceeds the phone memory budget.');
  const grow = memory.grow.bind(memory);
  memory.grow = pages => {
    if (!Number.isSafeInteger(pages) || pages < 0 || memory.buffer.byteLength + pages * 65536 > heapLimit) throw RangeError('Compatibility decoder heap limit exceeded.');
    return grow(pages);
  };
  return core;
}
function frameHashes(core, file, count) {
  const bytes = core.FS.readFile(file);
  if (bytes.length > 2 * 1048576) throw Error('Lossless verification exceeds its memory limit.');
  const hashes = new TextDecoder().decode(bytes).split(/\r?\n/).filter(line => line && !line.startsWith('#')).map(line => {
    const fields = line.split(',').map(value => value.trim());
    if (fields.length !== 6 || !/^[0-9]+$/.test(fields[4]) || !/^[a-f0-9]{32}$/.test(fields[5])) throw Error('The encoder returned incomplete lossless verification.');
    return fields[4] + ':' + fields[5];
  });
  if (hashes.length !== count) throw Error('Lossless verification did not cover every edited frame.');
  return hashes;
}
function join(parts, p) {
  let length = 32, count = 0;
  const infos = parts.map(bytes => { const info = ForgeUsmWriter.inspectIVF(bytes); length += bytes.length - 32; count += info.frames.length; return info; });
  if (length > LIMIT || count !== p.frames) throw Error('The compatibility encoder returned an incomplete or oversized movie.');
  const out = new Uint8Array(length), view = new DataView(out.buffer); out.set(parts[0].subarray(0, 32)); view.setUint32(16, p.rate.n, true); view.setUint32(20, p.rate.d, true); view.setUint32(24, count, true);
  let at = 32, frame = 0;
  for (const info of infos) for (const f of info.frames) { out.set(info.bytes.subarray(f.offset, f.offset + 12 + f.size), at); view.setBigUint64(at + 4, BigInt(frame++), true); at += 12 + f.size; }
  return out;
}
self.onmessage = async ({ data }) => {
  if (data.type === 'wasm') { const resolve = waiting; waiting = null; resolve?.(data.bytes); return; }
  if (busy) return; busy = true;
  let core; const logs = [];
  try {
    const verifying = data.type === 'verify';
    let verifiedInfo = null;
    if (verifying) {
      if (!(data.video instanceof Uint8Array) || data.video.length > LIMIT) throw Error('Lossless verification requires a bounded encoded movie.');
      verifiedInfo = ForgeUsmWriter.inspectIVF(data.video);
      if (verifiedInfo.width * verifiedInfo.height > 4 * 1048576 || verifiedInfo.frames.length / verifiedInfo.fps > 180 || !Array.isArray(data.hashes) || data.hashes.length !== verifiedInfo.frames.length || data.hashes.some(hash => typeof hash !== 'string' || !/^[0-9]{1,9}:[a-f0-9]{32}$/.test(hash))) throw Error('Lossless verification metadata is incomplete or too large.');
    }
    const p = data.type === 'check' || verifying ? null : validate(data.request);
    progress(verifying ? 'Verifying every lossless edited frame' : 'Loading the local compatibility decoder', verifying ? .94 : 0); core = await runtime(512 * 1048576);
    core.setLogger(({ message }) => { logs.push(String(message)); if (logs.length > 1000) logs.shift(); });
    if (verifying) {
      core.FS.writeFile('verify.ivf', data.video);
      core.setTimeout(120000); const code = core.exec('-hide_banner', '-loglevel', 'error', '-nostdin', '-max_alloc', String(LIMIT), '-threads', '1', '-max_pixels', String(4 * 1048576), '-f', 'ivf', '-c:v', 'libvpx-vp9', '-i', 'verify.ivf', '-map', '0:v', '-an', '-threads', '1', '-c:v', 'rawvideo', '-pix_fmt', 'yuv420p', '-f', 'framemd5', '-y', 'actual.hash'); core.reset();
      if (code !== 0 || JSON.stringify(frameHashes(core, 'actual.hash', verifiedInfo.frames.length)) !== JSON.stringify(data.hashes)) throw Error('Exact edited-frame verification failed. No movie was saved; your scenes are kept.');
      self.postMessage({ type: 'result', result: { video: data.video, verifiedLossless: true } }, [data.video.buffer]); return;
    }
    if (!p) {
      core.exec('-version'); core.reset(); const version = logs.find(s => /^ffmpeg version /.test(s)) || '';
      logs.length = 0; core.exec('-hide_banner', '-encoders'); core.reset(); const vp9 = logs.some(s => /\blibvpx-vp9\b/.test(s));
      logs.length = 0; core.exec('-hide_banner', '-decoders'); core.reset(); const hca = logs.some(s => /\bhca\b/.test(s));
      if (!version || !vp9 || !hca) throw Error('The compatibility runtime is missing a required local codec.');
      self.postMessage({ type: 'result', result: { ready: true, version, vp9, hca } }); return;
    }
    // Sequential scenes bound decoder/filter state. Device outputs enforce actual
    // byte limits while FFmpeg is writing, rather than silently truncating files.
    const parts = [], hashes = [], audio = p.audio ? ForgeNativeAdx.createEncoder({ samples: p.samples, channels: 2, sampleRate: 48000 }) : null;
    let bytesWritten = 0, picture = [], pictureBytes = 0;
    const videoDevice = core.FS.makedev(81, 1), audioDevice = core.FS.makedev(81, 2);
    core.FS.registerDevice(videoDevice, { open(s) { s.seekable = false; }, write(_s, b, offset, length) {
      if ((pictureBytes += length) > LIMIT || (bytesWritten += length) > LIMIT) throw Error('The encoded picture exceeds 64 MiB. Choose fewer scenes or a smaller picture.');
      picture.push(b.slice(offset, offset + length)); return length;
    } }); core.FS.mkdev('/edited.ivf', 384, videoDevice);
    if (audio) { core.FS.registerDevice(audioDevice, { open(s) { s.seekable = false; }, write(_s, b, offset, length) { return audio.write(b, offset, length); } }); core.FS.mkdev('/edited.pcm', 384, audioDevice); }
    for (let i = 0; i < p.clips.length; i++) {
      const c = p.clips[i], files = ['source.input', 'source.hca', 'sound.wav', 'expected.hash']; picture = []; pictureBytes = 0; logs.length = 0;
      const single = { ...p, clips: [{ ...c, index: 0 }], frames: c.count, samples: c.soundSamples, audio: !!audio, preserveAudio: false };
      try {
        core.FS.writeFile('source.input', c.video);
        const args = ['-hide_banner', '-loglevel', 'error', '-nostdin', '-max_alloc', String(LIMIT), '-threads', '1', '-max_pixels', String(4 * 1048576), '-r', c.sourceRate.n + '/' + c.sourceRate.d, '-f', formats[c.kind], '-i', 'source.input'], inputs = [{ video: 0 }];
        if (audio && c.audio) {
          if (c.audioKind === 'hca') {
            const prepared = ForgeHcaMetadata.prepare(c.audio); core.FS.writeFile('source.hca', prepared.data);
            core.setTimeout(120000); const code = core.exec('-hide_banner', '-loglevel', 'error', '-nostdin', '-max_alloc', String(LIMIT), '-threads', '1', '-f', 'hca', '-i', 'source.hca', '-af', ForgeHcaMetadata.filters(prepared.info), '-c:a', 'pcm_s16le', '-f', 'wav', '-fs', String(LIMIT), '-y', 'sound.wav'); core.reset();
            if (code !== 0) throw Error('The HCA sound could not be decoded. ' + logs.slice(-3).join(' '));
          } else core.FS.writeFile('sound.wav', ForgeNativeAdx.pcmToWav(ForgeNativeAdx.decodeADX(c.audio)));
          args.push('-f', 'wav', '-i', 'sound.wav'); inputs[0].audio = 1;
        }
        let filters = ForgeMovieEditPlan.filters(single, inputs);
        if (p.lossless) filters = filters.replace('[vout]', '[vraw]') + ';[vraw]split=2[vout][vverify]';
        args.push('-filter_complex_threads', '1', '-filter_complex', filters, '-map', '[vout]', '-an', '-frames:v', String(c.count), '-threads', '1', '-c:v', 'libvpx-vp9', '-deadline', 'realtime', '-cpu-used', '8', '-lag-in-frames', '0', '-auto-alt-ref', '0', '-lossless', p.lossless ? '1' : '0', '-crf', String(p.lossless ? 0 : p.quality), '-b:v', '0', '-pix_fmt', 'yuv420p', '-r', p.rate.n + '/' + p.rate.d, '-f', 'ivf', '-y', '/edited.ivf');
        if (audio) args.push('-map', '[aout]', '-vn', '-threads', '1', '-c:a', 'pcm_s16le', '-ar', '48000', '-ac', '2', '-f', 's16le', '-y', '/edited.pcm');
        if (p.lossless) args.push('-map', '[vverify]', '-an', '-frames:v', String(c.count), '-threads', '1', '-c:v', 'rawvideo', '-pix_fmt', 'yuv420p', '-f', 'framemd5', '-y', 'expected.hash');
        progress('Editing movie section ' + (i + 1) + ' of ' + p.clips.length, .1 + .8 * i / p.clips.length);
        core.setTimeout(120000); const code = core.exec(...args); core.reset();
        if (code !== 0) throw Error('The movie section could not be edited. ' + logs.slice(-4).join(' '));
        const output = new Uint8Array(pictureBytes); let at = 0; for (const chunk of picture) { output.set(chunk, at); at += chunk.length; } picture = [];
        if (output.length < 44) throw Error('The compatibility encoder returned no video.');
        new DataView(output.buffer).setUint32(24, c.count, true);
        const info = ForgeUsmWriter.inspectIVF(output);
        if (info.frames.length !== c.count || info.width !== p.width || info.height !== p.height) throw Error('The source movie ended before its selected frames were available.');
        if (p.lossless) hashes.push(...frameHashes(core, 'expected.hash', c.count));
        parts.push(output);
      } finally { for (const file of files) try { core.FS.unlink(file); } catch (_) {} }
    }
    progress('Writing the edited game movie', .95);
    const video = join(parts, p), sound = audio?.finish() || null;
    if (p.lossless) {
      const transfers = [video.buffer]; if (sound) transfers.push(sound.buffer);
      self.postMessage({ type: 'result', result: { video, audio: sound, verification: { hashes }, metadata: { width: p.width, height: p.height, frames: p.frames, rate: { n: p.rate.n, d: p.rate.d }, compatibility: true } } }, transfers); return;
    }
    const output = ForgeUsmWriter.encodeVP9(video, { name: data.request.name || 'browser-movie', audio: sound ? { kind: 'adx', data: sound } : null });
    if (output.length > LIMIT) throw Error('The complete edited movie exceeds 64 MiB. Choose fewer scenes or a smaller picture.');
    self.postMessage({ type: 'result', result: { data: output, mime: 'application/octet-stream', metadata: { width: p.width, height: p.height, frames: p.frames, rate: { n: p.rate.n, d: p.rate.d }, compatibility: true, verifiedLossless: p.lossless } } }, [output.buffer]);
  } catch (error) { self.postMessage({ type: 'error', message: String(error?.message || error) + (logs.length ? ' ' + logs.slice(-4).join(' ') : '') }); }
};
