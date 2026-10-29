/* Lazy browser compatibility codecs. Original resources stay untouched; the
 * isolated worker is terminated on completion, cancellation or timeout. */
(function () {
  'use strict';
  const W = window.__forgeWeb;
  if (!W?.movies || window.__forgeIOS) return;
  const movies = W.movies, nativeEdit = movies.editMovie, nativePrepare = movies.prepareInput, beforeReady = movies.instantReady, LIMIT = 64 * 1048576;
  let active = false;
  const base = () => window.__forgeStandaloneBase || new URL('.', location.href).href;
  function abort(signal) { if (signal?.aborted) throw new DOMException('Movie editing cancelled.', 'AbortError'); }
  function run(request, progress = () => {}, check = false) {
    const signal = request?.signal; abort(signal);
    if (active) return Promise.reject(Error('Finish or cancel the current compatibility movie before starting another.'));
    if (typeof Worker !== 'function' || typeof WebAssembly !== 'object') return Promise.reject(Error('This browser cannot run the local compatibility decoder. Your original movie is kept.'));
    const transfer = [], copies = new Map(); let total = 0;
    const clone = bytes => { if (bytes == null) return null; if (!(bytes instanceof Uint8Array)) throw Error('Choose complete picture and sound bytes.'); if (!copies.has(bytes)) { total += bytes.length; if (total > LIMIT) throw Error('Choose up to 64 MiB of source picture and sound.'); const copy = bytes.slice(); copies.set(bytes, copy); transfer.push(copy.buffer); } return copies.get(bytes); };
    let payload;
    if (!check) { if (!Array.isArray(request?.clips) || request.clips.length > 12) return Promise.reject(Error('Choose 1–12 movie scenes.')); payload = { ...request, signal: undefined, clips: request.clips.map(c => ({ ...c, video: clone(c.video), audio: clone(c.audio) })) }; }
    return new Promise((resolve, reject) => {
      let worker = null, pendingVerification = null; const controller = new AbortController(); active = true; let done = false, loading = false;
      const finish = (error, result) => { if (done) return; done = true; active = false; clearTimeout(timer); signal?.removeEventListener('abort', cancel); controller.abort(); worker?.terminate(); error ? reject(error) : resolve(result); };
      const cancel = () => finish(new DOMException('Movie editing cancelled.', 'AbortError'));
      const timer = setTimeout(() => finish(Error('Compatibility editing took too long. Choose fewer or smaller scenes; your choices are kept.')), 600000);
      signal?.addEventListener('abort', cancel, { once: true });
      const onerror = e => finish(Error('The local compatibility decoder could not start. ' + (e.message || 'Your original movie is kept.')));
      const onmessage = async ({ data }) => {
        if (done) return;
        if (data.type === 'progress') { try { progress(data.event); } catch (e) { finish(e); } return; }
        if (data.type === 'error') { finish(Error(data.message)); return; }
        if (data.type === 'result') {
          try {
            if (data.result.verification) {
              pendingVerification = data.result;
              // This pinned core needs an independent decoder instance. Release
              // the complete encoder worker/heap before creating its verifier.
              worker.terminate(); worker = null; loading = false; startWorker();
              worker.postMessage({ type: 'verify', video: pendingVerification.video, hashes: pendingVerification.verification.hashes }, [pendingVerification.video.buffer]);
              return;
            }
            if (pendingVerification) {
              if (data.result.verifiedLossless !== true) throw Error('The lossless verification did not complete.');
              worker.terminate(); worker = null;
              const bytes = ForgeUsmWriter.encodeVP9(data.result.video, { name: request.name || 'browser-movie', audio: pendingVerification.audio ? { kind: 'adx', data: pendingVerification.audio } : null });
              if (bytes.length > LIMIT) throw Error('The complete edited movie exceeds 64 MiB. Choose fewer scenes or a smaller picture.');
              const result = { data: bytes, mime: 'application/octet-stream', metadata: { ...pendingVerification.metadata, verifiedLossless: true } }; pendingVerification = null; finish(null, result); return;
            }
            finish(null, data.result);
          } catch (error) { finish(error); }
          return;
        }
        if (data.type !== 'runtime' || loading) return; loading = true;
        try {
          const response = await fetch(new URL('vendor/media/ffmpeg-core.wasm', base()), { signal: controller.signal });
          if (!response.ok) throw Error('The compatibility decoder is not bundled in this page.');
          const advertised = Number(response.headers.get('content-length'));
          if (advertised > 40 * 1048576) throw Error('The bundled compatibility decoder exceeds its size limit.');
          // The standalone page serves its embedded Blob. A streaming hosted
          // response is also bounded before it is assembled or transferred.
          let bytes;
          if (response.body?.getReader) {
            const reader = response.body.getReader(), chunks = []; let length = 0;
            try { for (;;) { const r = await reader.read(); if (r.done) break; length += r.value.length; if (length > 40 * 1048576) throw Error('The bundled compatibility decoder exceeds its size limit.'); chunks.push(r.value); } } catch (e) { await reader.cancel().catch(() => {}); throw e; }
            bytes = new Uint8Array(length); let at = 0; for (const c of chunks) { bytes.set(c, at); at += c.length; }
          } else bytes = new Uint8Array(await response.arrayBuffer());
          if (bytes.length < 1048576 || bytes.length > 40 * 1048576) throw Error('The compatibility decoder is incomplete.');
          if (!done) worker.postMessage({ type: 'wasm', bytes: bytes.buffer }, [bytes.buffer]);
        } catch (e) { finish(e); }
      };
      function startWorker() { worker = new Worker(new URL('web/web-compat-worker.js', base())); worker.onerror = onerror; worker.onmessage = onmessage; }
      try { startWorker(); } catch (error) { finish(error); return; }
      worker.postMessage(check ? { type: 'check' } : { type: 'edit', request: payload }, transfer);
      if (signal?.aborted) cancel();
    });
  }
  const needsCompatibility = request => request.lossless || request.quality === 0 || request.clips?.some(c => !['vp9-ivf', 'av1-ivf'].includes(c.kind) || request.audioMode !== 'mute' && c.audio && c.audioKind !== 'adx');
  movies.editMovie = async function (request, progress) {
    abort(request?.signal);
    if (!needsCompatibility(request) && await movies.codecs?.capability()) {
      try { return await nativeEdit(request, progress); } catch (e) {
        if (e.name === 'AbortError' || !/browser.*(?:cannot|could not|failed)|codec stopped responding|no native VP9/i.test(e.message)) throw e;
      }
    }
    return run(request, progress);
  };
  movies.prepareInput = async function (input) {
    if (input.kind === 'vp9-ivf' && input.audioKind !== 'hca') return input;
    if (input.kind === 'av1-ivf' && input.audioKind !== 'hca' && await movies.codecs?.capability()) {
      try { return await nativePrepare(input); } catch (e) { if (!/browser.*(?:cannot|could not|failed)|codec stopped responding/i.test(e.message)) throw e; }
    }
    const request = { name: 'browser-preview', width: input.width, height: input.height, rate: input.rate, quality: 24, audioMode: 'auto', clips: [{ ...input, startFrame: 0, endFrame: input.frames }] };
    const converted = await run(request);
    return { ...ForgeMovieInput.readMovie(converted.data), browserConvertedFrom: input.kind + (input.audioKind === 'hca' ? ' + HCA' : '') };
  };
  movies.instantReady = async function () { await beforeReady(); movies.instantOnly = false; };
  movies.compatibility = { check: () => run(null, () => {}, true) };
})();
