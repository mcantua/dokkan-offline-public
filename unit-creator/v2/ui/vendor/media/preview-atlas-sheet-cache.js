/* Original Forge instance-owned atlas preparation leases. MIT.
 * Only the exact-source loader adapter calls this module. URLs are never
 * intercepted globally; the original producer owns decoding and disposal. */
const MAX_DIMENSION=16384;
export class AtlasSheetCache {
 constructor({maxPixels=64*1024*1024,maxEntries=512,concurrency=4}={}) {
  if(!Number.isSafeInteger(maxPixels)||maxPixels<1||!Number.isSafeInteger(maxEntries)||maxEntries<1||!Number.isSafeInteger(concurrency)||concurrency<1||concurrency>32)throw new Error('Invalid atlas preparation cache limits.');
  this.maxPixels=maxPixels;this.maxEntries=maxEntries;this.concurrency=concurrency;this.entries=new Map();this.pixels=0;this.active=0;this.waiting=[];this.counts={requests:0,hits:0,producers:0,failures:0,uncached:0,releases:0};
 }
 _run(produce){return new Promise((resolve,reject)=>{this.waiting.push({produce,resolve,reject});this._drain();});}
 _drain(){while(this.active<this.concurrency&&this.waiting.length){const task=this.waiting.shift();this.active++;Promise.resolve().then(task.produce).then(task.resolve,task.reject).finally(()=>{this.active--;this._drain();});}}
 async acquire(sourceURL,width,height,produce){
  if(typeof sourceURL!=='string'||!sourceURL||sourceURL.length>16384||!Number.isInteger(width)||!Number.isInteger(height)||width<1||height<1||width>MAX_DIMENSION||height>MAX_DIMENSION||typeof produce!=='function')throw new Error('Invalid atlas preparation request.');
  this.counts.requests++;const key=JSON.stringify([sourceURL,width,height,'original-fit-v1']),pixels=width*height;let entry=this.entries.get(key);
  if(entry){this.counts.hits++;entry.owners++;}
  else{
   const shared=this.entries.size<this.maxEntries&&pixels<=this.maxPixels-this.pixels;entry={key,pixels,owners:1,shared,result:null};if(shared){this.entries.set(key,entry);this.pixels+=pixels;}else this.counts.uncached++;
   entry.promise=this._run(async()=>{this.counts.producers++;try{const result=await produce();if(!result||typeof result.url!=='string'||!result.url||typeof result.dispose!=='function')throw new Error('Atlas preparation did not return an owned resource.');entry.result=result;return result;}catch(error){this.counts.failures++;this._remove(entry);throw error;}});
  }
  let resource;try{resource=await entry.promise;}catch(error){entry.owners--;throw error;}
  let released=false;return Object.freeze({url:resource.url,release:()=>{if(released)return;released=true;this.counts.releases++;entry.owners--;if(entry.owners===0){this._remove(entry);const owned=entry.result;entry.result=null;try{owned?.dispose();}catch{/* A producer cleanup failure must not retain cache ownership. */}}}});
 }
 _remove(entry){if(entry.shared&&this.entries.get(entry.key)===entry){this.entries.delete(entry.key);this.pixels-=entry.pixels;}}
 snapshot(){return Object.freeze({...this.counts,entries:this.entries.size,pixels:this.pixels,owners:[...this.entries.values()].reduce((n,e)=>n+e.owners,0),active:this.active,queued:this.waiting.length,maxPixels:this.maxPixels});}
}
const shared=new AtlasSheetCache();
export function acquireAtlasSheet(sourceURL,width,height,produce){return shared.acquire(sourceURL,width,height,produce);}
export function atlasSheetCacheSnapshot(){return shared.snapshot();}
