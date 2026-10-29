/* Browser game movies: original USM demuxing + lossless VP9/WebM remuxing.
 * Uses the phone browser's actual video decoder; no remote upload or WASM engine. */
(function () {
  'use strict';
  const W = window.__forgeWeb;
  if (!W || window.__forgeIOS || !W.preview) return;
  const H = W.handlers, R = W.resourceStore, originalPreview = H.previewAnimation;
  const LIMIT = 64 * 1048576, enc = new TextEncoder(); let current = null;
  function id(hex) { return Uint8Array.from(hex.match(/../g), h => parseInt(h, 16)); }
  function size(value) {
    if (!Number.isSafeInteger(value) || value < 0 || value > LIMIT + 1048576) throw Error('The converted movie exceeds the browser preview limit.');
    let n = 1; while (value >= 2 ** (7 * n) - 1) n++;
    const out = new Uint8Array(n); for (let i = n - 1; i >= 0; i--) { out[i] = value % 256; value = Math.floor(value / 256); } out[0] |= 1 << (8 - n); return out;
  }
  function element(hex, parts) { const data = new Blob(Array.isArray(parts) ? parts : [parts]); return new Blob([id(hex), size(data.size), data]); }
  function number(hex, value) { let n = 1; while (value >= 2 ** (8 * n)) n++; const out = new Uint8Array(n); for (let i = n - 1; i >= 0; i--) { out[i] = value % 256; value = Math.floor(value / 256); } return element(hex, out); }
  function text(hex, value) { return element(hex, enc.encode(value)); }
  function remux(input) {
    if (input.kind !== 'vp9-ivf') throw Error('This browser preview supports VP9 game movies. This movie uses ' + input.kind + '; use the phone app for its full decoder.');
    if (input.video.length > LIMIT || input.width > 4096 || input.height > 4096 || input.width * input.height > 16e6) throw Error('This movie exceeds the browser preview size limit.');
    const frames = [], v = new DataView(input.video.buffer, input.video.byteOffset, input.video.byteLength), ms = input.rate.d / input.rate.n * 1000;
    for (let at = 32, count = 0; at < input.video.length; count++) {
      if (at + 12 > input.video.length || count >= 10000) throw Error('The movie has an invalid IVF frame list.');
      const n = v.getUint32(at, true); if (!n || at + 12 + n > input.video.length || v.getBigUint64(at + 4, true) !== BigInt(count)) throw Error('The movie has a truncated or mistimed frame.');
      const frame = input.video.subarray(at + 12, at + 12 + n), b0 = frame[0];
      if (b0 >> 6 !== 2 || b0 & 0x30) throw Error('This movie needs a VP9 profile unsupported by the browser remuxer.');
      frames.push({ bytes: frame, time: Math.round(count * ms), key: !(b0 & 0x0c) }); at += 12 + n;
    }
    if (frames.length !== input.frames || !frames[0]?.key) throw Error('The movie must start with a complete keyframe.');
    const header = element('1a45dfa3', [number('4286', 1), number('42f7', 1), number('42f2', 4), number('42f3', 8), text('4282', 'webm'), number('4287', 4), number('4285', 2)]);
    const duration = new DataView(new ArrayBuffer(8)); duration.setFloat64(0, frames.length * ms);
    const info = element('1549a966', [number('2ad7b1', 1000000), text('4d80', 'Dokkan Unit Creator'), text('5741', 'Dokkan Unit Creator'), element('4489', duration.buffer)]);
    const track = element('1654ae6b', element('ae', [number('d7', 1), number('73c5', 1), number('83', 1), text('86', 'V_VP9'), number('23e383', Math.round(ms * 1000000)), element('e0', [number('b0', input.width), number('ba', input.height)])]));
    const clusters = []; let blocks = [], base = 0;
    const flush = () => { if (blocks.length) clusters.push(element('1f43b675', [number('e7', base), ...blocks])); blocks = []; };
    for (const frame of frames) {
      if (!blocks.length || frame.key || frame.time - base > 30000) { flush(); base = frame.time; }
      const head = new Uint8Array(4), view = new DataView(head.buffer); head[0] = 0x81; view.setInt16(1, frame.time - base); head[3] = frame.key ? 0x80 : 0;
      blocks.push(element('a3', [head, frame.bytes]));
    }
    flush(); const segment = element('18538067', [info, track, ...clusters]);
    return new Blob([header, segment], { type: 'video/webm' });
  }
  function close() {
    const old = current; current = null; if (!old) return;
    old.observer.disconnect(); old.video.pause(); old.video.removeAttribute('src'); old.video.load(); if (old.audio) { old.audio.pause(); old.audio.removeAttribute('src'); old.audio.load(); } old.urls.forEach(u => URL.revokeObjectURL(u));
  }
  H.previewAnimation = async function (a) {
    if (a.mode !== 'movie') { close(); return originalPreview(a); }
    const path = R.path(a.resourcePath);
    if (!/^movie\/[a-z0-9_./-]+\.usm$/i.test(path)) throw Error('Choose a game movie from the movie browser.');
    let row;
    try { row = await W.preview.resolve(path, a); }
    catch (error) {
      if (a.assetKey || a.assets || (await H.previewCache({})).offline || !navigator.onLine) throw error;
      const saved = await H.downloadAsset({ path }); row = await R.read(saved.key);
    }
    if (row.size > LIMIT) throw Error('Browser movie previews support game files up to 64 MiB.');
    let input = ForgeMovieInput.readMovie(new Uint8Array(await row.blob.arrayBuffer()));
    if ((input.kind !== 'vp9-ivf' || input.audioKind === 'hca') && W.movies?.prepareInput) input = await W.movies.prepareInput(input);
    const probe = document.createElement('video');
    if (!probe.canPlayType('video/webm; codecs="vp9"')) throw Error('This phone browser cannot decode VP9 WebM movies. Use a browser with VP9 support or the phone app.');
    const videoBlob = remux(input), duration = input.frames * input.rate.d / input.rate.n;
    let audioBlob = null;
    if (input.audio) {
      if (input.audioKind !== 'adx' || !window.ForgeNativeAdx) throw Error('This movie uses ' + input.audioKind + ' sound, which this lightweight browser player cannot decode. Use the phone app for matching sound.');
      const info = ForgeNativeAdx.inspect(input.audio);
      if (info.samples * info.channels * 2 > LIMIT) throw Error('This movie expands beyond the 64 MiB browser audio limit.');
      audioBlob = new Blob([ForgeNativeAdx.pcmToWav(ForgeNativeAdx.decodeADX(input.audio))], { type: 'audio/wav' });
    }
    let trim = null;
    if (a.trim != null) { const t = a.trim; if (!t || typeof t.from !== 'number' || typeof t.to !== 'number' || !Number.isFinite(t.from) || !Number.isFinite(t.to) || t.from < 0 || t.to <= t.from || t.to > duration + 0.01) throw Error('Choose valid movie trim bounds.'); trim = { from: t.from, to: Math.min(t.to, duration) }; }
    close(); W.preview.close();
    dialog(String(a.name || 'Game movie preview'), '<section class="browser-movie-preview"><p class="hint">' + (input.browserConvertedFrom ? input.browserConvertedFrom + ' picture locally converted to VP9' : 'Original VP9 picture') + (audioBlob ? ' and decoded ADX sound' : '') + '. This browser prepares the preview locally without changing the game file.</p><video id="browser-game-video" controls playsinline preload="metadata" aria-label="Game movie"></video><p id="browser-movie-status" role="status">Opening the local movie…</p><button type="button" class="button ghost" id="browser-save-video">Save preview video (.webm)</button><p class="hint">The WebM download contains the original video picture. The game export retains its original USM file and sound.</p></section>');
    const video = document.getElementById('browser-game-video'), urls = [URL.createObjectURL(videoBlob)], audio = audioBlob ? document.createElement('audio') : null;
    if (audio) { urls.push(URL.createObjectURL(audioBlob)); audio.src = urls[1]; audio.preload = 'auto'; }
    const shell = document.getElementById('dialog'), status = document.getElementById('browser-movie-status'), observer = new MutationObserver(() => { if (!video.isConnected || !shell.open) close(); });
    observer.observe(shell, { childList: true, subtree: true, attributes: true, attributeFilter: ['open'] }); current = { observer, video, audio, urls };
    const sync = () => { if (!audio) return; audio.volume = video.volume; audio.muted = video.muted; audio.playbackRate = video.playbackRate; if (audio.readyState >= 1 && Math.abs(audio.currentTime - video.currentTime) > 0.15) audio.currentTime = video.currentTime; };
    video.onplay = async () => { sync(); if (audio) try { await audio.play(); } catch (_) { video.pause(); status.textContent = 'Tap Play again to allow this browser to play the movie sound.'; } };
    video.onpause = video.onended = () => { if (audio) audio.pause(); };
    video.onseeked = () => { sync(); };
    video.onratechange = video.onvolumechange = sync;
    video.ontimeupdate = () => { sync(); if (trim && video.currentTime >= trim.to) { video.pause(); video.currentTime = trim.from; } };
    document.getElementById('browser-save-video').onclick = () => { const link = document.createElement('a'); link.href = urls[0]; link.download = 'UnitCreator-preview.webm'; document.body.append(link); link.click(); link.remove(); };
    video.src = urls[0];
    try {
      await new Promise((resolve, reject) => { const timer = setTimeout(() => reject(Error('This browser did not open the VP9 movie. Its original game file was kept.')), 15000); video.onloadedmetadata = () => { clearTimeout(timer); resolve(); }; video.onerror = () => { clearTimeout(timer); reject(Error('This browser could not decode the VP9 movie. Its original game file was kept.')); }; });
      if (!video.isConnected || !shell.open) throw Error('This movie preview was closed while loading.');
      if (trim) video.currentTime = trim.from;
      status.textContent = input.width + ' × ' + input.height + ' · ' + duration.toFixed(2) + ' seconds' + (audioBlob ? ' · Original sound ready' : ' · No sound track');
      return { opened: true, local: true, mode: 'movie', audio: !!audioBlob };
    } catch (error) { if (status.isConnected) status.textContent = error.message; close(); throw error; }
  };
  async function instantReady() {
    if (typeof Worker !== 'function' || !window.ForgeUsmWriter) throw Error('The local VP9 movie tools are unavailable in this browser. Your animation is kept.');
    const base = window.__forgeStandaloneBase || new URL('.', location.href).href;
    const response = await fetch(base + 'vendor/media/instant-worker.js');
    if (!response.ok) throw Error('The local instant movie worker is not bundled in this page. Your animation is kept.');
  }
  W.movies = { remux, close, instantReady, instantOnly: true };
  addEventListener('pagehide', close);
})();
