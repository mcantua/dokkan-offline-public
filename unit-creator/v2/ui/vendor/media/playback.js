/* Original Forge prepared-movie transport. GPL-3.0-or-later.
 * A class-local WeakMap replaces only the upstream movie player's Blob URLs.
 * No global Blob, URL, or native editor bridge is modified or exposed. */
const prepared = new WeakMap();
const preparedByBytes=new WeakMap(),pendingByBytes=new WeakMap();
const LIMIT = 160 * 1024 * 1024;

export async function prepareMovieBlob(bytes) {
  const key=bytes!==null&&(typeof bytes==='object'||typeof bytes==='function')?bytes:null;
  if(key){const existing=preparedByBytes.get(key);if(existing&&prepared.has(existing))return existing;if(pendingByBytes.has(key))return await pendingByBytes.get(key);}
  const operation=storeMovieBlob(bytes);if(key)pendingByBytes.set(key,operation);
  try{const blob=await operation;if(key)preparedByBytes.set(key,blob);return blob;}
  finally{if(key)pendingByBytes.delete(key);}
}

const cacheKeys=new WeakMap();
/** media-pipeline: remember which kept-movie key belongs to freshly converted bytes. */
function sendKeep(key,href){const id=(String(href).match(/\/_forge\/prepared-movies\/([a-f0-9]{32})\.mp4$/)||[])[1];if(key&&id)fetch('/_forge/movie-cache/keep/'+key+'/'+id+'.mp4',{credentials:'same-origin',cache:'no-store'}).catch(()=>{});}
export function rememberMovieCacheKey(bytes,key){
 if(!bytes||typeof bytes!=='object'||!/^[a-f0-9]{64}-[a-z]{1,4}$/.test(String(key)))return;
 cacheKeys.set(bytes,String(key));
 // already handed to the player (checked AV1/VP9 paths): keep it now
 const blob=preparedByBytes.get(bytes),href=blob&&prepared.get(blob);if(href)sendKeep(String(key),href);
}

async function storeMovieBlob(bytes) {
  const key=bytes!==null&&typeof bytes==='object'?bytes:null;
  const blob = bytes instanceof Blob ? bytes : new Blob([bytes], {type:'video/mp4'});
  if (!blob.size || blob.size > LIMIT) throw new Error('This prepared movie exceeds the supported size.');
  const signature = new Uint8Array(await blob.slice(0,12).arrayBuffer());
  if (signature.length < 12 || String.fromCharCode(...signature.subarray(4,8)) !== 'ftyp') {
    throw new Error('The movie converter did not return a readable MP4.');
  }
  const controller = new AbortController();
  const cancel = () => controller.abort();
  window.addEventListener('pagehide',cancel,{once:true});
  const timer = setTimeout(cancel,120000);
  try {
    const response = await fetch('/_forge/prepared-movies', {
      method:'POST',credentials:'same-origin',headers:{'Content-Type':'video/mp4'},
      body:blob,signal:controller.signal,redirect:'error'
    });
    if (!response.ok) throw new Error('The prepared movie could not be saved for playback ('+response.status+').');
    const result = await response.json();
    const url = new URL(result.url,window.location.href);
    if (typeof result.url !== 'string' || url.origin !== window.location.origin ||
        !/^\/_forge\/prepared-movies\/[A-Za-z0-9_-]{16,128}\.mp4$/.test(url.pathname) ||
        url.search || url.hash || url.username || url.password) {
      throw new Error('The movie player returned an unsafe playback address.');
    }
    prepared.set(blob,url.href);
    // A movie converted on this phone is kept for next time (native MovieCache).
    const keepKey=key===null?null:cacheKeys.get(bytes);
    if(keepKey)sendKeep(keepKey,url.href);
    return blob;
  } finally {
    clearTimeout(timer);
    window.removeEventListener('pagehide',cancel);
  }
}

export function movieObjectUrl(blob) {
  const url = prepared.get(blob);
  if (!url) throw new Error('This movie has not been prepared for local playback.');
  return url;
}

export function releaseMovieUrl(url) {
  // Native movie files may be shared by preloaded sections; the preview server
  // owns their lifetime and removes them when the preview session closes.
  if (typeof url === 'string' && url.startsWith('blob:')) URL.revokeObjectURL(url);
}

export async function discardMovieBlob(blob) {
  const url=prepared.get(blob);if(!url)return false;
  prepared.delete(blob);
  const response=await fetch(url,{method:'DELETE',credentials:'same-origin',redirect:'error'});
  if(!response.ok&&response.status!==404)throw new Error('The failed movie probe could not be removed.');
  return true;
}

/** Require an actual decoded first frame before accepting a native codec. */
export async function probeMovieBlob(blob,{signal,timeoutMs=15000}={}) {
  if(signal?.aborted)throw new DOMException('Movie preparation cancelled.','AbortError');
  const url=movieObjectUrl(blob),video=document.createElement('video');
  video.muted=true;video.playsInline=true;video.preload='auto';
  video.style.cssText='position:fixed;width:1px;height:1px;left:0;top:0;opacity:0;pointer-events:none';
  return await new Promise((resolve,reject)=>{
    let done=false,timer;
    const clean=()=>{clearTimeout(timer);signal?.removeEventListener('abort',abort);video.pause();video.removeAttribute('src');video.load();video.remove();};
    const finish=(error)=>{if(done)return;done=true;const info={width:video.videoWidth,height:video.videoHeight,duration:video.duration};clean();error?reject(error):resolve(info);};
    const abort=()=>finish(new DOMException('Movie preparation cancelled.','AbortError'));
    const ready=()=>{if(video.readyState>=2&&video.videoWidth>0&&video.videoHeight>0)finish();};
    video.addEventListener('loadeddata',ready);video.addEventListener('error',()=>finish(new Error('This device could not decode the native movie.')));
    signal?.addEventListener('abort',abort,{once:true});timer=setTimeout(()=>finish(new Error('The native movie decoder did not return a frame.')),timeoutMs);
    document.body.append(video);video.src=url;video.load();
    const playing=video.play();if(playing?.catch)playing.catch(error=>finish(error));ready();
  });
}

// Pause events remain evidence when a script immediately resumes the video
// before the interrupted play promise's rejection microtask runs.
const playbackInterruptions=new WeakMap();
/** Pause/stop may interrupt an asynchronous play request. Consume only that race. */
export async function playMovieVideo(video) {
  let state=playbackInterruptions.get(video);
  if(!state){state={pauses:0,resets:0};playbackInterruptions.set(video,state);video.addEventListener?.('pause',()=>state.pauses++);video.addEventListener?.('emptied',()=>state.resets++);}
  const pauses=state.pauses,resets=state.resets;
  try { return await video.play(); }
  catch(error) {
    if(error?.name==='AbortError' && (video.paused || video.ended || !video.isConnected || state.pauses>pauses || state.resets>resets))return;
    throw error;
  }
}
