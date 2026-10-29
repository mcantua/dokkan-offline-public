/* Show saved artwork in collections without loading every complete project. */
'use strict';
window.ForgeCollectionArt=(()=>{
 const cache=new Map(),queue=[];let active=0;
 function url(meta){
  const signature=JSON.stringify([meta.key,meta.updatedAt||'',meta.resourceId||0]);
  if(cache.has(signature))return cache.get(signature);
  const result=(async()=>{const project=await Native.call('loadProject',{key:meta.key});const own=await projectPreviewUrl(project);return own||resourceThumb(project.artBinding?.sourceId||project.source?.resourceId||Forge.card(project).resource_id||meta.resourceId);})();
  cache.set(signature,result);result.catch(()=>{if(cache.get(signature)===result)cache.delete(signature);});
  while(cache.size>64)cache.delete(cache.keys().next().value);
  return result;
 }
 function drain(){
  while(active<2&&queue.length){const job=queue.shift();if(!job.img.isConnected)continue;active++;
   const current=()=>job.img.isConnected&&job.root.isConnected;
   url(job.meta).then(src=>{if(!current()||!src)return;const img=job.img;
    img.onload=()=>{if(current()){img.hidden=false;img.style.visibility='visible';}};
    img.onerror=()=>{if(current()){img.hidden=true;img.style.visibility='hidden';}};
    img.src=src;
   }).catch(()=>{if(current()){job.img.hidden=true;job.img.style.visibility='hidden';}}).finally(()=>{active--;drain();});
  }
 }
 function mount(root,projects){
  if(!root)return;const byKey=new Map(projects.map(p=>[p.key,p])),images=[...root.querySelectorAll('img[data-unit-art]')];
  const add=img=>{const meta=byKey.get(img.dataset.unitArt);if(meta){queue.push({root,img,meta});drain();}};
  if(typeof IntersectionObserver!=='function'){images.forEach(add);return;}
  let remaining=images.length;const observer=new IntersectionObserver(entries=>{if(!root.isConnected){observer.disconnect();return;}
   for(const entry of entries)if(entry.isIntersecting){observer.unobserve(entry.target);add(entry.target);remaining--;}
   if(!remaining)observer.disconnect();
  },{rootMargin:'240px'});images.forEach(img=>observer.observe(img));
 }
 return {mount};
})();
