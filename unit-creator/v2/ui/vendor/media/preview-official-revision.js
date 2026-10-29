/* Forge original opt-in coherent official revision preview. MIT.
 * Only this verified complete bundle is eligible; game exports are unchanged. */
export const REVISION = Object.freeze({
  "id": "b1-00243-e31c20b4",
  "path": "ab_script/attack_sp/sp2516.lua",
  "label": "Available official revision",
  "root": "ingame/battle/sp_effect/sp_effect_b1_00243/en/",
  "files": [
    {
      "path": "ingame/battle/sp_effect/sp_effect_b1_00243/en/sp_effect_b1_00243.lwf",
      "bytes": 93192,
      "sha256": "e31c20b4db4c504b019dc5b36f468f42c8e9b23cc87f8b73d04f3209821f3912",
      "mime": "application/octet-stream"
    },
    {
      "path": "ingame/battle/sp_effect/sp_effect_b1_00243/en/sp_effect_b1_00243_0.png",
      "bytes": 836848,
      "sha256": "805e25b7bcdc9713d1a9f9b746993eb46807c83117c1984637e3ff2b0411868e",
      "mime": "image/png"
    },
    {
      "path": "ingame/battle/sp_effect/sp_effect_b1_00243/en/Images_drawtxt_ggaha.png",
      "bytes": 4200,
      "sha256": "74f5e17c0ac6104a348bee5df71e9bf7e9b4e631da5afb58cb11c4cdc60201d4",
      "mime": "image/png"
    },
    {
      "path": "ingame/battle/sp_effect/sp_effect_b1_00243/en/sp_effect_b1_00243_1.png",
      "bytes": 496779,
      "sha256": "027d042ffb8d0abef1f50ad18e8e3731fc06ee2df6873996348960e1834ea634",
      "mime": "image/png"
    },
    {
      "path": "ingame/battle/sp_effect/sp_effect_b1_00243/en/Images_drawtext_zudododo.png",
      "bytes": 9827,
      "sha256": "31d13e2a40df11bf20641e3124db51e7a6198628a736777f88d640d6ffd71ed4",
      "mime": "image/png"
    },
    {
      "path": "ingame/battle/sp_effect/sp_effect_b1_00243/en/Images_drawtext_zuoot.png",
      "bytes": 8863,
      "sha256": "ff599a269f6c88b4ab83c13237b24688cbe8dddd78283e627fde38bd55f0f246",
      "mime": "image/png"
    },
    {
      "path": "ingame/battle/sp_effect/sp_effect_b1_00243/en/Images_text_goho1.png",
      "bytes": 1858,
      "sha256": "9e30655ae31e4bc0d08e3ba95b945d6df4bfe0ac66be0001a1ac80818f6ac118",
      "mime": "image/png"
    },
    {
      "path": "ingame/battle/sp_effect/sp_effect_b1_00243/en/Images_text_goho2.png",
      "bytes": 2313,
      "sha256": "209a4c2efdd8a876b6f4b822e7c70cae6b7c9f2bad99b504e16adaa107b5def0",
      "mime": "image/png"
    }
  ],
  "scenes": {
    "161631": "ef_001",
    "161632": "ef_001r",
    "161633": "ef_002",
    "161634": "ef_002r",
    "161635": "ef_003",
    "161636": "ef_003r",
    "161637": "ef_004",
    "161638": "ef_005",
    "161639": "ef_006"
  }
});
for(const row of REVISION.files)Object.freeze(row);Object.freeze(REVISION.files);Object.freeze(REVISION.scenes);
const aborted=()=>{const e=Error('The revision selection was canceled.');e.name='AbortError';return e;};
const check=signal=>{if(signal?.aborted)throw aborted();};
async function bounded(response,limit,signal){if(!response.ok)throw Error('A matching official resource is unavailable.');const declared=Number(response.headers.get('content-length'));if(declared>limit)throw Error('An official resource changed size.');if(!response.body?.getReader){const bytes=new Uint8Array(await response.arrayBuffer());if(bytes.length>limit)throw Error('An official resource changed size.');check(signal);return bytes;}const reader=response.body.getReader(),parts=[];let size=0;try{while(true){check(signal);const r=await reader.read();if(r.done)break;size+=r.value.length;if(size>limit)throw Error('An official resource changed size.');parts.push(r.value);}}finally{await reader.cancel().catch(()=>{});}const bytes=new Uint8Array(size);let at=0;for(const part of parts){bytes.set(part,at);at+=part.length;}return bytes;}
export function revisionMetadata(metadata,id){if(!metadata||metadata.found!==true||Number(metadata.id)!==Number(id)||Number(metadata.category)!==5||metadata.pack_name!=='sp_effect_b1_00243'||metadata.scene_name!==REVISION.scenes[id]||metadata.usm?.url)throw Error('The selected assets use a different move definition. Keep the selected assets or import the complete matching official revision.');const original=metadata.lwf?.rel;if(original!==REVISION.files[0].path)throw Error('The selected assets use a different visual pack.');return{...metadata,media:'lwf',lwf:{rel:REVISION.files[0].path,url:'/cdn/uncompressed/'+REVISION.files[0].path,bytes:REVISION.files[0].bytes,source:'verified-official-revision',stamp:'sha256:'+REVISION.files[0].sha256},forge_official_revision:REVISION.id};}
export async function downloadRevision(fetcher,{subtle=globalThis.crypto?.subtle,signal,timeoutMs=20000}={}){if(!subtle)throw Error('Verified official revisions require a secure browser context.');const controller=new AbortController(),abort=()=>controller.abort(),timer=setTimeout(abort,timeoutMs);signal?.addEventListener('abort',abort,{once:true});if(signal?.aborted)abort();const files=[];try{for(const row of REVISION.files){check(controller.signal);const response=await fetcher('/cdn/uncompressed/'+row.path,{signal:controller.signal}),bytes=await bounded(response,row.bytes,controller.signal);if(bytes.length!==row.bytes)throw Error('The available or imported official resource differs from the verified revision.');const hash=Array.from(new Uint8Array(await subtle.digest('SHA-256',bytes)),v=>v.toString(16).padStart(2,'0')).join('');if(hash!==row.sha256)throw Error('The available or imported official resource differs from the verified revision. No files were switched.');files.push(Object.freeze({file:row,blob:new Blob([bytes],{type:row.mime})}));}const metadata={};for(const id of Object.keys(REVISION.scenes)){check(controller.signal);const response=await fetcher('/api/effect-pack/'+id+'?enemy=0',{signal:controller.signal}),bytes=await bounded(response,65536,controller.signal);let value;try{value=JSON.parse(new TextDecoder().decode(bytes));}catch{throw Error('The move definition is unreadable.');}metadata[id]=Object.freeze(revisionMetadata(value,id));}check(controller.signal);return Object.freeze({files:Object.freeze(files),metadata:Object.freeze(metadata)});}catch(error){controller.abort();if(signal?.aborted)throw aborted();throw error;}finally{clearTimeout(timer);signal?.removeEventListener('abort',abort);}}
export function createRevisionResolver({fetcher,base,subtle=globalThis.crypto?.subtle}){let bundle=null,epoch=0,controller=null;const getURL=input=>{try{return new URL(typeof input==='string'?input:typeof input?.url==='string'?input.url:String(input),base);}catch{return null;}},origin=new URL(base),sameOrigin=url=>url.protocol===origin.protocol&&url.hostname===origin.hostname&&url.port===origin.port;
 const api={get active(){return!!bundle;},async enable(){const token=++epoch;controller?.abort();controller=new AbortController();const loaded=await downloadRevision(fetcher,{subtle,signal:controller.signal});if(token!==epoch)throw aborted();bundle=loaded;return REVISION.id;},restore(){epoch++;controller?.abort();controller=null;bundle=null;},async response(input,init){if(!bundle)return null;const url=getURL(input),method=String(init?.method||input?.method||'GET').toUpperCase();if(!url||!sameOrigin(url)||url.searchParams.has('patch')||!['GET','HEAD'].includes(method))return null;check(init?.signal||input?.signal);let relative=null;for(const prefix of['/cdn/uncompressed/'])if(url.pathname.startsWith(prefix))relative=url.pathname.slice(prefix.length);const row=bundle.files.find(item=>item.file.path===relative);if(row)return new Response(method==='HEAD'?null:row.blob,{headers:{'content-type':row.file.mime,'content-length':String(row.file.bytes),'cache-control':'no-store','X-Asset-Stamp':'sha256:'+row.file.sha256,'X-Forge-Official-Revision':REVISION.id}});const match=/^\/api\/effect-pack\/([1-9][0-9]*)$/.exec(url.pathname),metadata=match&&bundle.metadata[match[1]];if(metadata){const bytes=JSON.stringify({...metadata,enemy:url.searchParams.get('enemy')==='1'});return new Response(method==='HEAD'?null:bytes,{headers:{'content-type':'application/json','cache-control':'no-store','X-Forge-Official-Revision':REVISION.id}});}return null;}};return api;}
export function mountOfficialRevision(root=window){if(root.__forgeAnimation?.path!==REVISION.path||root.__forgeOfficialRevision)return null;const originalFetch=root.fetch,fetcher=originalFetch.bind(root),resolver=createRevisionResolver({fetcher,base:root.location.href,subtle:root.crypto?.subtle});root.__forgeOfficialRevision=resolver;const wrapper=async(input,init)=>await resolver.response(input,init)||fetcher(input,init);root.fetch=wrapper;let observer,disposed=false;
 const mount=()=>{if(disposed)return;const bar=root.document.getElementById('forge-animation-bar'),start=root.document.getElementById('forge-animation-start');if(!bar||!start)return;observer?.disconnect();if(root.document.getElementById('forge-official-revision'))return;const box=root.document.createElement('section');box.id='forge-official-revision';box.setAttribute('aria-label','Official visual revision');box.style.cssText='margin-top:12px;padding:12px;border:1px solid #82d7c5;border-radius:8px;max-width:50rem;overflow-wrap:anywhere';const title=root.document.createElement('strong');title.textContent='Available official revision';const explanation=root.document.createElement('p');explanation.textContent='If your selected version is missing artwork, you can preview a complete available official revision. Its artwork and timeline differ; this does not recover the selected version or change game exports.';const use=root.document.createElement('button');use.type='button';use.textContent='Use available official revision';const restore=root.document.createElement('button');restore.type='button';restore.textContent='Restore selected assets';restore.disabled=true;restore.style.marginLeft='8px';const status=root.document.createElement('p');status.setAttribute('role','status');status.setAttribute('aria-live','polite');status.textContent='Using selected assets.';box.append(title,explanation,use,restore,status);bar.append(box);
 const stop=()=>root.document.getElementById('btnStop')?.click();use.onclick=async()=>{if(start.disabled){status.textContent='Wait until the animation controls are ready, then choose this revision.';return;}use.disabled=true;restore.disabled=true;start.disabled=true;stop();status.textContent='Verifying the complete matching official visual bundle…';try{const {getActivePatchId}=await import('/tools/lua-player/js/patch-context.js');if(getActivePatchId())throw Error('This official revision cannot be mixed with an active patch preview. Keep the selected assets for that preview.');await resolver.enable();if(disposed)return;stop();status.textContent='Using the complete available official revision. Artwork and timeline may differ. Game exports remain unchanged.';restore.disabled=false;start.disabled=false;start.click();}catch(error){if(!disposed){status.textContent=error.name==='AbortError'?'Revision loading was canceled. Selected assets were preserved.':error.message+' The selected assets were preserved.';restore.disabled=!resolver.active;}}finally{if(!disposed){use.disabled=resolver.active;start.disabled=false;}}};restore.onclick=()=>{stop();resolver.restore();use.disabled=false;restore.disabled=true;status.textContent='Using selected assets. Their missing artwork may still prevent complete playback.';start.click();};};
 observer=new root.MutationObserver(mount);observer.observe(root.document.body||root.document.documentElement,{childList:true,subtree:true});mount();root.addEventListener('pagehide',()=>{disposed=true;observer.disconnect();resolver.restore();if(root.fetch===wrapper)root.fetch=originalFetch;if(root.__forgeOfficialRevision===resolver)delete root.__forgeOfficialRevision;},{once:true});return resolver;}
