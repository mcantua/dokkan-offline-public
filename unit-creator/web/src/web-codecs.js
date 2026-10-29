/* Local, bounded browser movie encoding through actual native WebCodecs.
 * Reuses the original USM writer and plain ADX codec; no WASM or external upload. */
(function () {
  'use strict';
  const W = window.__forgeWeb;
  if (!W?.movies || window.__forgeIOS) return;
  const LIMIT = 64 * 1048576, MAX_FRAMES = 10000, RATE = 48000, enc = new TextEncoder();
  const codec = 'vp09.00.10.08'; let supported = null;
  const aborted = signal => { if (signal?.aborted) throw new DOMException('Movie editing cancelled.', 'AbortError'); };
  const finite = (v, lo, hi) => typeof v === 'number' && Number.isFinite(v) && v >= lo && v <= hi;
  async function capability() {
    if (supported != null) return supported;
    if (!window.VideoEncoder || !window.VideoDecoder || !window.VideoFrame || !window.EncodedVideoChunk) return supported = false;
    try {
      const [encode, decode] = await Promise.all([VideoEncoder.isConfigSupported({ codec, width: 64, height: 64, bitrate: 500000, framerate: 30, latencyMode: 'realtime' }), VideoDecoder.isConfigSupported({ codec, codedWidth: 64, codedHeight: 64 })]);
      supported = !!(encode.supported && decode.supported);
    } catch (_) { supported = false; }
    return supported;
  }
  const beforeReady = W.movies.instantReady;
  W.movies.instantReady = async function () { await beforeReady(); W.movies.instantOnly = !await capability(); };
  function sourceInfo(clip) {
    if (clip.kind === 'vp9-ivf') return { ...ForgeUsmWriter.inspectIVF(clip.video), codec };
    if (clip.kind !== 'av1-ivf') throw Error('Native browser editing accepts VP9 and supported AV1 game movies. This scene uses ' + clip.kind + '; use the phone app for its full decoder.');
    const bytes = clip.video;
    if (!(bytes instanceof Uint8Array) || bytes.length < 44 || bytes.length > LIMIT) throw Error('Choose a complete AV1 IVF movie within 64 MiB.');
    const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength), text = (a, b) => String.fromCharCode(...bytes.subarray(a, b));
    if (text(0, 4) !== 'DKIF' || text(8, 12) !== 'AV01' || view.getUint16(4, true) !== 0 || view.getUint16(6, true) !== 32) throw Error('The AV1 IVF header is invalid.');
    const width = view.getUint16(12, true), height = view.getUint16(14, true), rate = view.getUint32(16, true), scale = view.getUint32(20, true), fps = rate / scale, declared = view.getUint32(24, true), frames = [];
    if (!width || !height || width > 4096 || height > 4096 || width * height > 16e6 || rate > 2147483647 || scale > 2147483647 || !finite(fps, 1, 120)) throw Error('This AV1 movie has unsupported dimensions or timing.');
    for (let at = 32; at < bytes.length;) {
      if (at + 12 > bytes.length || frames.length >= MAX_FRAMES) throw Error('The AV1 IVF frame list is truncated or too large.');
      const size = view.getUint32(at, true);
      if (!size || at + 12 + size > bytes.length || view.getBigUint64(at + 4, true) !== BigInt(frames.length)) throw Error('The AV1 movie has truncated frames or unsupported timestamps.');
      frames.push({ offset: at, size, key: frames.length === 0 }); at += 12 + size;
    }
    if (!frames.length || declared && declared !== frames.length || clip.frames && clip.frames !== frames.length) throw Error('AV1 frame timing does not match the game movie.');
    return { bytes, width, height, rate, scale, fps, frames, codec: 'av01.0.04M.08' };
  }
  function plan(request) {
    if (!request || !Array.isArray(request.clips) || !request.clips.length || request.clips.length > 12) throw Error('Choose 1–12 movie scenes.');
    if (!Number.isInteger(request.width) || !Number.isInteger(request.height) || request.width < 2 || request.height < 2 || request.width > 4096 || request.height > 4096 || request.width * request.height > 16e6) throw Error('Choose movie dimensions up to 4096 pixels and 16 million pixels total.');
    const rate = request.rate, fps = rate && rate.n / rate.d;
    if (!Number.isSafeInteger(rate?.n) || !Number.isSafeInteger(rate?.d) || rate.n < 1 || rate.d < 1 || rate.n > 2147483647 || rate.d > 2147483647 || !finite(fps, 1, 120)) throw Error('Choose a supported movie frame rate.');
    if (request.lossless || request.quality === 0) throw Error('Exact-pixel lossless encoding needs the full phone-app encoder. Choose Balanced, High, or Smallest file for native browser encoding.');
    if (!finite(request.quality, 1, 63) || !['auto', 'mute'].includes(request.audioMode)) throw Error('Choose a supported movie quality and sound setting.');
    let bytes = 0, frames = 0; const sourceVideo = new Set(), sourceAudio = new Set(); const clips = request.clips.map(clip => {
      if (!(clip.video instanceof Uint8Array) || !Number.isSafeInteger(clip.startFrame) || !Number.isSafeInteger(clip.endFrame)) throw Error('Choose complete movie scenes with valid trim bounds.');
      const info = sourceInfo(clip), sourceFps = info.fps;
      if (clip.startFrame < 0 || clip.endFrame > info.frames.length || clip.endFrame <= clip.startFrame) throw Error('A movie trim ends outside its source.');
      if (!sourceVideo.has(clip.video)) { sourceVideo.add(clip.video); bytes += clip.video.length; }
      if (clip.audio && !sourceAudio.has(clip.audio)) { sourceAudio.add(clip.audio); bytes += clip.audio.length; }
      if (bytes > LIMIT) throw Error('Use up to 64 MiB of source picture and sound for browser encoding.');
      const transform = { scale: 1, x: 0, y: 0, rotation: 0, opacity: 1, flipX: false, flipY: false, ...clip.transform };
      if (!finite(transform.scale, .05, 8) || !finite(transform.x, -request.width * 2, request.width * 2) || !finite(transform.y, -request.height * 2, request.height * 2) || !finite(transform.rotation, -180, 180) || !finite(transform.opacity, 0, 1) || typeof transform.flipX !== 'boolean' || typeof transform.flipY !== 'boolean') throw Error('Choose valid movie picture transforms.');
      if (clip.audio != null && !(clip.audio instanceof Uint8Array)) throw Error('This scene has unreadable sound bytes.');
      if (request.audioMode !== 'mute' && clip.audio && (clip.audioKind !== 'adx' || !window.ForgeNativeAdx)) throw Error('This scene uses ' + clip.audioKind + ' sound. Mute it or use the phone app for its full sound decoder.');
      if (request.audioMode !== 'mute' && clip.audio) { const info = ForgeNativeAdx.inspect(clip.audio); if (info.samples * info.channels * 2 > LIMIT) throw Error('A source sound track expands beyond the 64 MiB browser decode limit.'); }
      const count = Math.max(1, Math.round((clip.endFrame - clip.startFrame) / sourceFps * fps)); frames += count;
      if (frames > MAX_FRAMES || frames / fps > 180) throw Error('Keep the edited movie within three minutes and 10,000 frames.');
      return { ...clip, info, sourceFps, transform, count };
    });
    return { clips, frames, fps, rate, width: request.width, height: request.height };
  }
  function ivf(chunks, p) {
    chunks.sort((a, b) => a.timestamp - b.timestamp);
    if (chunks.length !== p.frames || !chunks[0]?.key) throw Error('The browser encoder did not return a complete movie.');
    let length = 32; for (const chunk of chunks) length += 12 + chunk.bytes.length;
    if (length > LIMIT) throw Error('The encoded picture exceeds 64 MiB. Choose fewer scenes or a smaller picture.');
    const out = new Uint8Array(length), view = new DataView(out.buffer); out.set(enc.encode('DKIF')); view.setUint16(6, 32, true); out.set(enc.encode('VP90'), 8); view.setUint16(12, p.width, true); view.setUint16(14, p.height, true); view.setUint32(16, p.rate.n, true); view.setUint32(20, p.rate.d, true); view.setUint32(24, p.frames, true);
    let at = 32;
    chunks.forEach((chunk, i) => { if (i && chunk.timestamp <= chunks[i - 1].timestamp) throw Error('The browser encoder returned conflicting frame times.'); view.setUint32(at, chunk.bytes.length, true); view.setBigUint64(at + 4, BigInt(i), true); out.set(chunk.bytes, at + 12); at += 12 + chunk.bytes.length; });
    return out;
  }
  async function audio(p, request, progress) {
    if (request.audioMode === 'mute' || !p.clips.some(c => c.audio)) return null;
    progress({ message: 'Rebuilding original scene sound', progress: .9 });
    const samples = Math.round(p.frames / p.fps * RATE); if (samples * 4 > LIMIT) throw Error('The edited sound exceeds the browser memory limit.');
    const writer = ForgeNativeAdx.createEncoder({ samples, sampleRate: RATE, channels: 2 }); let written = 0;
    for (let index = 0; index < p.clips.length; index++) {
      aborted(request.signal); const c = p.clips[index], decoded = c.audio ? ForgeNativeAdx.decodeADX(c.audio) : null;
      const count = index === p.clips.length - 1 ? samples - written : Math.round(c.count / p.fps * RATE), sourceStart = c.startFrame / c.sourceFps;
      for (let at = 0; at < count; at += 8192) {
        const n = Math.min(8192, count - at), pcm = new Uint8Array(n * 4), view = new DataView(pcm.buffer);
        if (decoded) for (let i = 0; i < n; i++) {
          const position = (sourceStart + (at + i) / RATE) * decoded.sampleRate, a = Math.floor(position), mix = position - a;
          for (let channel = 0; channel < 2; channel++) {
            const ch = Math.min(channel, decoded.channels - 1), x = a < decoded.samples ? decoded.pcm[a * decoded.channels + ch] : 0, y = a + 1 < decoded.samples ? decoded.pcm[(a + 1) * decoded.channels + ch] : x;
            view.setInt16(i * 4 + channel * 2, Math.max(-32768, Math.min(32767, Math.round(x + (y - x) * mix))), true);
          }
        }
        writer.write(pcm); if ((at / 8192) % 8 === 7) { await new Promise(resolve => setTimeout(resolve, 0)); aborted(request.signal); }
      }
      written += count;
    }
    return writer.finish();
  }
  W.movies.editMovie = async function (request, progress = () => {}) {
    aborted(request.signal); if (!await capability()) throw Error('This browser has no native VP9 movie encoder. Keyframe cuts and joins still work; use the phone app for picture changes.');
    const p = plan(request), signal = request.signal, chunks = [], canvas = document.createElement('canvas'); canvas.width = p.width; canvas.height = p.height;
    const ctx = canvas.getContext('2d', { alpha: false }); if (!ctx) throw Error('The browser could not create a movie drawing surface.');
    const qualityFactor = Math.max(.04, .3 - request.quality / 250), bitrate = Math.round(Math.max(100000, Math.min(50000000, p.width * p.height * p.fps * qualityFactor)));
    const config = { codec, width: p.width, height: p.height, bitrate, framerate: p.fps, latencyMode: 'realtime', bitrateMode: 'variable' };
    if (!(await VideoEncoder.isConfigSupported(config)).supported) throw Error('This browser cannot encode the chosen movie size or frame rate. Choose a smaller picture.');
    let encoder = null, decoder = null, failure = null, encodedBytes = 0, frameIndex = 0; const deadline = Date.now() + 600000;
    const stop = () => { try { decoder?.close(); } catch (_) {} try { encoder?.close(); } catch (_) {} };
    const check = () => { aborted(signal); if (failure) throw failure; if (Date.now() > deadline) throw Error('Movie encoding took too long. Choose fewer or smaller scenes.'); };
    const flush = async instance => {
      let timer; try { await Promise.race([instance.flush(), new Promise((_, reject) => { timer = setTimeout(() => reject(Error('The browser movie codec stopped responding. Your scene choices are kept.')), 60000); })]); } finally { clearTimeout(timer); } check();
    };
    signal?.addEventListener('abort', stop, { once: true });
    try {
      encoder = new VideoEncoder({ error: error => { failure = Error('The browser video encoder failed: ' + error.message); }, output: chunk => {
        try { if ((encodedBytes += chunk.byteLength) > LIMIT) throw Error('The encoded movie exceeds 64 MiB. Choose fewer scenes or a smaller picture.'); const bytes = new Uint8Array(chunk.byteLength); chunk.copyTo(bytes); chunks.push({ bytes, timestamp: chunk.timestamp, key: chunk.type === 'key' }); } catch (error) { failure = error; }
      } }); encoder.configure(config);
      for (let clipIndex = 0; clipIndex < p.clips.length; clipIndex++) {
        check(); const c = p.clips[clipIndex], decodeConfig = { codec: c.info.codec, codedWidth: c.info.width, codedHeight: c.info.height };
        if (!(await VideoDecoder.isConfigSupported(decodeConfig)).supported) throw Error('This browser cannot decode the selected ' + c.kind + ' movie. Your scenes and trim choices are kept.');
        let emitted = 0, pendingFrames = 0, outputQueue = Promise.resolve();
        decoder = new VideoDecoder({ error: error => { failure = Error('The browser could not decode this ' + c.kind + ' scene: ' + error.message); }, output: frame => {
          pendingFrames++;
          outputQueue = outputQueue.then(async () => {
          try {
            check(); if (frame.displayWidth > 4096 || frame.displayHeight > 4096 || frame.displayWidth * frame.displayHeight > 16e6) throw Error('A decoded picture exceeds the browser frame memory limit.'); const index = Math.round(frame.timestamp / 1e6 * c.sourceFps);
            if (index < c.startFrame || index >= c.endFrame) return;
            while (emitted < c.count && c.startFrame + Math.floor(emitted / p.fps * c.sourceFps) <= index) {
              while (encoder.encodeQueueSize > 2) { check(); await new Promise(resolve => setTimeout(resolve, 1)); }
              check(); ctx.globalAlpha = 1; ctx.fillStyle = '#000'; ctx.fillRect(0, 0, p.width, p.height); ctx.save();
              const t = c.transform, fit = Math.min(p.width / frame.displayWidth, p.height / frame.displayHeight);
              ctx.translate(p.width / 2 + t.x, p.height / 2 + t.y); ctx.rotate(t.rotation * Math.PI / 180); ctx.scale(t.scale * (t.flipX ? -1 : 1), t.scale * (t.flipY ? -1 : 1)); ctx.globalAlpha = t.opacity;
              ctx.drawImage(frame, -frame.displayWidth * fit / 2, -frame.displayHeight * fit / 2, frame.displayWidth * fit, frame.displayHeight * fit); ctx.restore();
              const output = new VideoFrame(canvas, { timestamp: Math.round(frameIndex / p.fps * 1e6), duration: Math.round(1e6 / p.fps) });
              try { encoder.encode(output, { keyFrame: emitted === 0 || frameIndex % Math.max(1, Math.round(p.fps * 2)) === 0 }); } finally { output.close(); }
              emitted++; frameIndex++;
              if (frameIndex % 8 === 0) progress({ message: 'Encoding movie picture', progress: .85 * frameIndex / p.frames });
            }
          } catch (error) { failure = error; } finally { frame.close(); pendingFrames--; }
          });
        } }); decoder.configure(decodeConfig);
        for (let i = 0; i < c.endFrame; i++) {
          while (decoder.decodeQueueSize > 2 || encoder.encodeQueueSize > 2 || pendingFrames > 2) { check(); await new Promise(resolve => setTimeout(resolve, 1)); }
          check(); const f = c.info.frames[i]; decoder.decode(new EncodedVideoChunk({ type: f.key ? 'key' : 'delta', timestamp: Math.round(i / c.sourceFps * 1e6), duration: Math.round(1e6 / c.sourceFps), data: c.video.subarray(f.offset + 12, f.offset + 12 + f.size) }));
          if (i % 2 === 1) await new Promise(resolve => setTimeout(resolve, 0));
        }
        await flush(decoder); await outputQueue; check(); decoder.close(); decoder = null; if (emitted !== c.count) throw Error('The browser decoder returned an incomplete trimmed scene.');
        await flush(encoder);
      }
      if (frameIndex !== p.frames) throw Error('The encoded frame count does not match the movie timeline.');
      const video = ivf(chunks, p), sound = await audio(p, request, progress); check(); progress({ message: 'Writing edited game movie', progress: .98 });
      const bytes = ForgeUsmWriter.encodeVP9(video, { name: request.name || 'forge-motion', audio: sound ? { kind: 'adx', data: sound } : null });
      if (bytes.length > LIMIT) throw Error('The complete edited movie exceeds 64 MiB. Choose fewer scenes or a smaller picture.');
      progress({ message: 'Edited movie is ready', progress: 1 }); return { data: bytes, mime: 'application/octet-stream', metadata: { width: p.width, height: p.height, frames: p.frames, rate: p.rate } };
    } finally { signal?.removeEventListener('abort', stop); stop(); canvas.width = canvas.height = 0; }
  };
  W.movies.prepareInput = async function (input) {
    if (input.kind !== 'av1-ivf') throw Error('This browser cannot prepare ' + input.kind + ' game movies. Use the phone app for its full decoder.');
    if (!await capability()) throw Error('This browser cannot convert AV1 game movies locally. Your original resource is kept; use a browser with native AV1 decoding and VP9 encoding or the phone app.');
    const request = { name: 'browser-preview', width: input.width, height: input.height, rate: input.rate, quality: 36, audioMode: 'auto', clips: [{ ...input, startFrame: 0, endFrame: input.frames, transform: { scale: 1, x: 0, y: 0, rotation: 0, opacity: 1, flipX: false, flipY: false } }] };
    const converted = await W.movies.editMovie(request);
    return { ...ForgeMovieInput.readMovie(converted.data), browserConvertedFrom: 'AV1' };
  };
  W.movies.codecs = { capability };
})();
