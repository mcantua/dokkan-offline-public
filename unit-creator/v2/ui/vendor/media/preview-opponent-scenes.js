/* Original Forge source-backed opponent-scene choices. MIT.
 * Exact original source SHA256s from actual Fengari execution changing only
 * _IS_PLAYER_SIDE_ to0. This metadata does not establish visual/gameplay fidelity. */
(function(root,factory){const api=factory(root);if(typeof window==='undefined'&&typeof module==='object'&&module.exports)module.exports=api;root.ForgeOpponentScenes=api;})(typeof globalThis!=='undefined'?globalThis:this,function(root){
 'use strict';
 const hashes=Object.freeze({
  "ab_script/attack_sp/sp2529.lua": "42bfc248d0f49c9d24ff19b0aac575897362e72ae3f789e60e09b6bc4bab05fe",
  "ab_script/attack_sp/sp2530.lua": "342789666fed37d292f8d1c8ccac46e8069072aeb4f7079a0b96cd2f3d478cac",
  "ab_script/attack_sp/sp2700.lua": "7383be906b3c932eaa18b8f7dc4d763b15c7c4dce316f2d18e53f3fdbe90b803",
  "ab_script/attack_sp/sp2704.lua": "5b26aec4b2484ef3c4fd069430dd32316003aea44edc23e68653a93ea5dbd641",
  "ab_script/attack_sp/sp2720.lua": "37951cf7227e13a5e6aa1e47599010ffe44124b8623340541dd38cecbce7c0e3",
  "ab_script/attack_sp/sp2725.lua": "c3331f345e8a76b6ffdb8da23a0e62e00287283de086a1801b4fca9dbba55c47",
  "ab_script/attack_sp/sp2741.lua": "ce8385c78364eef269945aeced9adcf865acad10f865cf47b2dd3ef469db73fd",
  "ab_script/attack_sp/sp2761.lua": "0c4abc5f0bcecfe6ff4e3c1baab2ad577e6397289fb96267602df2a0a79d3865",
  "ab_script/attack_sp/sp2782.lua": "4bc63735103b7a601d2b8a6714f066220d60227eee2b34075cd4b31227ffaa44",
  "ab_script/attack_sp/sp2819.lua": "7a6a524112efe62cc49eb4c15ecd9f4e1e0283ad1c1ff4ffa4b3f7634007afaa",
  "ab_script/attack_sp/sp2842.lua": "dc81091164a4f92175b4c73fdf4670ac25517e18c8febd3be7777e9968579e93",
  "ab_script/attack_sp/sp2843.lua": "fa2a62bcaf3e9ee6ace24caf06e13087ffcf2182ff89d706c7f929b25e4e54f0",
  "ab_script/attack_sp/sp2846.lua": "a31c02974f1b98ef026c96fa092233db7f25a96f1f071373d00f12e1830008f8",
  "ab_script/attack_sp/sp2879.lua": "e1c8e947cb8d5368a1e584eb44b17bf6da9e083dc4615d90de4015e0da4abbd8",
  "ab_script/attack_sp/sp2880.lua": "a3fe308fa50394a2fa581a9e04f9c4dce27a3b244758a00f0d509f20febdb4f4",
  "ab_script/attack_sp/sp2882.lua": "f6ac6c22898bc0628aa1f7cb1ebf59f68960fa1ce515e0ace89b89089bf3acbc",
  "ab_script/attack_sp/sp2896.lua": "467e255bf7f63d0661dc1d760690da0bc17b3ab3c019ef97a76e9fd0e1ff7041",
  "ab_script/attack_sp/sp2897.lua": "dee8f660a29e4ad5069dad33485e1ae77c1ada5bdc300199dfe9b034a5fa3b72",
  "ab_script/attack_sp/sp2898.lua": "672b774fcdf6c757a4e2a309813b99d713b03277abbd58cf27a3ba5b35f68a8f",
  "ab_script/attack_sp/sp2899.lua": "d58113d2c99a89bed502f056305570b34b45c9587aa2832bae961d2965f78f11",
  "ab_script/attack_sp/sp2900.lua": "1916f9573c4f21486e7ddf1ccf9cbdec1ba5b6cf645a70d233aa05157748331e",
  "ab_script/attack_sp/sp2901.lua": "f29e06112f6350ddb3a18f856bed50d302cd23df53006a34a5788071dbed2f07",
  "ab_script/attack_sp/sp2915.lua": "b3ed4e470205970ff5777a7abce088282e4580cb22533d145855321afcebd926",
  "ab_script/attack_sp/sp2962.lua": "16966d54747c48b7b8d0e84ebe8575a726e39e00dda79b0e10f9e1edf3a5d7f5",
  "ab_script/attack_sp/sp2990.lua": "1bbed5bad1cfacefdb9a60f8acb51f492c827b1c465e7f842cf126dd734e1a47",
  "ab_script/attack_sp/sp2991.lua": "42661a8b73476ea4d8fb00c110cfb7a6cd1f932cefed3dfa7228952c1f5deea8",
  "ab_script/attack_sp/sp2992.lua": "12a658288238b42eb6f321163939f39133e2942e09b462d7bf8d17d08e1bbfdf",
  "ab_script/attack_sp/sp2998.lua": "010719d487f3b877a5c0675453920cc614395016c5e0f282cd3f77a9c2dcea29",
  "ab_script/attack_sp/sp3063.lua": "ba7f5b7aba7a341a5c0546b23470c4e593e72d986e2c1801e6a0c63f13073fe4",
  "ab_script/attack_sp/sp3064.lua": "ac8ad8538964902b538f280ed50e0e1d01f6ac4177d01e28e9676dc7f2df3077",
  "ab_script/attack_sp/sp3068.lua": "728387368059aebe150b7f619882512708d4276ea8f813902ab2d6e2a255ef28",
  "ab_script/attack_sp/sp3118.lua": "d4ea75257bee8960172ab6b18760a35a274b4a42ab63db00543b49ab1cea29fa"
});
 const paths=Object.freeze(Object.keys(hashes));
 const description='This original scene is written for the opponent’s side. Choose Preview opponent-side scene in the preview to inspect that branch. Its playback still needs game testing.';
 const get=path=>Object.prototype.hasOwnProperty.call(hashes,path)?Object.freeze({path,sourceSHA256:hashes[path],title:'Opponent-side Super Attack scene · variation '+(paths.indexOf(path)+1),description}):null;
 async function inspect(path,text){const entry=get(path);if(!entry||typeof text!=='string'||text.length>2*1024*1024||!root.crypto?.subtle||typeof TextEncoder==='undefined')return null;const bytes=new TextEncoder().encode(text);if(bytes.length>2*1024*1024)return null;const digest=new Uint8Array(await root.crypto.subtle.digest('SHA-256',bytes));let actual='';for(const value of digest)actual+=value.toString(16).padStart(2,'0');return actual===entry.sourceSHA256?entry:null;}
 async function readSource(request){if(typeof request.text==='string')return request.text;const entry=get(request.path);if(!entry)return null;const controller=new AbortController(),timer=setTimeout(()=>controller.abort(),15000);let reader;try{const response=await fetch('/cdn/uncompressed/lua/'+entry.path,{signal:controller.signal,credentials:'same-origin',redirect:'error'});if(!response.ok||Number(response.headers.get('content-length')||0)>2*1024*1024)return null;if(!response.body?.getReader)return null;reader=response.body.getReader();const parts=[];let length=0;while(true){const item=await reader.read();if(item.done)break;length+=item.value.length;if(length>2*1024*1024)return null;parts.push(item.value);}const bytes=new Uint8Array(length);let offset=0;for(const part of parts){bytes.set(part,offset);offset+=part.length;}return new TextDecoder('utf-8',{fatal:true}).decode(bytes);}finally{clearTimeout(timer);try{await reader?.cancel();}catch{}}}
 function applyCondition(input){if(!input||input.disabled||input.dataset?.key!=='_IS_PLAYER_SIDE_')return false;if(input.tagName==='INPUT'&&input.type==='checkbox')input.checked=false;else if(input.tagName==='SELECT'&&Array.from(input.options).some(option=>option.value==='0'))input.value='0';else return false;const EventType=input.ownerDocument?.defaultView?.Event||root.Event;input.dispatchEvent(new EventType('input',{bubbles:true}));input.dispatchEvent(new EventType('change',{bubbles:true}));return true;}
 async function mount({request,bar,start,onOpponent}){if(!get(request?.path)||!bar||!start||typeof onOpponent!=='function')return null;let entry;try{entry=await inspect(request.path,await readSource(request));}catch{return null;}if(!entry||!bar.isConnected)return null;const box=document.createElement('section');box.dataset.forgeOpponentScene='true';box.setAttribute('aria-label','Opponent-side scene');const note=document.createElement('p');note.textContent=entry.description;const button=document.createElement('button');button.type='button';button.textContent='Preview opponent-side scene';button.disabled=start.disabled;button.onclick=onOpponent;box.append(note,button);bar.append(box);const observer=new MutationObserver(()=>{button.disabled=start.disabled;});observer.observe(start,{attributes:true,attributeFilter:['disabled']});root.addEventListener('pagehide',()=>observer.disconnect(),{once:true});return{button,entry};}
 return Object.freeze({get,inspect,applyCondition,mount,paths});
});
