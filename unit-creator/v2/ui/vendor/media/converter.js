/* Dokkan Unit Forge local legacy-video adapter. GPL-3.0-or-later.
 * See NOTICE.txt and corresponding-source-manifest.json in this directory. */
const MAX_BYTES = 160 * 1024 * 1024;
const queue = [];
let running = false;

/** Convert one demuxed video elementary stream entirely on this device.
 * @param {{video:Uint8Array|ArrayBuffer,kind?:string,framerate?:number,audio?:Uint8Array|ArrayBuffer,audioKind?:string,copyVideo?:boolean,outputProfile?:'h264-aac'|'vp9-opus',metadata?:{width:number,height:number,frames:number,rate:{n:number,d:number}},signal?:AbortSignal,timeoutMs?:number}} request
 * @param {(event:{progress?:number,time?:number,message?:string})=>void} onProgress
 * @returns {Promise<{data:Uint8Array,mime:string}>}
 */
export async function convert(request, onProgress = () => {}) {
  if(request.outputProfile!==undefined&&!['h264-aac','vp9-opus'].includes(request.outputProfile))throw new Error('This movie output format is unsupported.');
  const bytes = request.video instanceof Uint8Array ? request.video :
    request.video instanceof ArrayBuffer ? new Uint8Array(request.video) : null;
  if (!bytes || bytes.byteLength === 0) throw new Error('The video stream is empty.');
  if (bytes.byteLength > MAX_BYTES) throw new Error('This video is larger than the 160 MB preparation limit.');
  const audio = request.audio instanceof Uint8Array ? request.audio :
    request.audio instanceof ArrayBuffer ? new Uint8Array(request.audio) : null;
  if (request.audio != null && (!audio || !audio.byteLength)) throw new Error('The audio stream is empty.');
  if (bytes.byteLength + (audio?.byteLength || 0) > MAX_BYTES) throw new Error('This movie is larger than the 160 MB preparation limit.');
  if (request.signal?.aborted) throw new DOMException('Video preparation cancelled.', 'AbortError');
  if (typeof Worker !== 'function' || typeof WebAssembly !== 'object') {
    throw new Error('This device needs a newer browser or WebView to prepare older game videos.');
  }
  if (queue.length + (running ? 1 : 0) >= 24) throw new Error('Too many movies are waiting to be prepared. Try a shorter sequence.');
  return await new Promise((resolve, reject) => {
    const entry = { request, onProgress, bytes, audio, resolve, reject };
    entry.abort = () => {
      const index = queue.indexOf(entry);
      if (index < 0) return;
      queue.splice(index, 1);
      request.signal?.removeEventListener('abort', entry.abort);
      reject(new DOMException('Video preparation cancelled.', 'AbortError'));
    };
    request.signal?.addEventListener('abort', entry.abort, { once: true });
    queue.push(entry);
    pump();
  });
}

async function pump() {
  if (running || !queue.length) return;
  running = true;
  const entry = queue.shift();
  entry.request.signal?.removeEventListener('abort', entry.abort);
  try { entry.resolve(await run(entry)); }
  catch (error) { entry.reject(error); }
  finally { running = false; pump(); }
}

async function run({request, onProgress, bytes, audio}) {
  if (request.signal?.aborted) throw new DOMException('Video preparation cancelled.', 'AbortError');
  let worker;
  try {
    worker = new Worker(new URL('./converter-worker.js', import.meta.url));
    return await new Promise((resolve, reject) => {
      let settled = false;
      let timer;
      const cleanup = () => {
        clearTimeout(timer);
        request.signal?.removeEventListener('abort', abort);
        worker.terminate();
      };
      const finish = (error, value) => {
        if (settled) return;
        settled = true;
        cleanup();
        error ? reject(error) : resolve(value);
      };
      const abort = () => finish(new DOMException('Video preparation cancelled.', 'AbortError'));
      request.signal?.addEventListener('abort', abort, { once: true });
      const timeoutMs = Number.isFinite(request.timeoutMs) ? Math.max(1000, Math.min(600000, request.timeoutMs)) : 300000;
      timer = setTimeout(() => finish(new Error('Video preparation took too long. Try a shorter section or a faster device.')), timeoutMs);
      worker.onerror = event => finish(new Error(event.message || 'The local video converter could not start.'));
      worker.onmessageerror = () => finish(new Error('The local video converter returned unreadable data.'));
      worker.onmessage = ({ data }) => {
        if (data.type === 'progress') {
          try { onProgress(data.event); } catch (_) { /* UI callbacks cannot interrupt cleanup. */ }
        } else if (data.type === 'result') {
          if (!(data.data instanceof Uint8Array) || !data.data.byteLength) {
            finish(new Error('The video converter produced an empty movie.'));
          } else finish(null, { data: data.data, mime: 'video/mp4' });
        } else if (data.type === 'error') finish(new Error(data.message || 'This video could not be prepared.'));
      };
      // Copy only this view; transferring an entire demuxer's shared backing buffer
      // could detach other streams that the caller still needs for ADX decoding.
      try {
        const copy = bytes.slice();
        const audioCopy = audio?.slice();
        const transfers = [copy.buffer];
        if (audioCopy) transfers.push(audioCopy.buffer);
        worker.postMessage({ video: copy, audio: audioCopy, audioKind: request.audioKind || '',
          copyVideo: request.copyVideo === true, kind: request.kind || '', framerate: request.framerate, outputProfile:request.outputProfile, metadata:request.metadata }, transfers);
      } catch (error) { finish(error); }
    });
  } finally {
    worker?.terminate();
  }
}
