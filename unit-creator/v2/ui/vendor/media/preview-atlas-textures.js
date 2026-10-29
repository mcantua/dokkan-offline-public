/* Original Forge bounded WebGL atlas-upload cache. MIT.
 * Only immutable decoded PNG arrays belong here. Dynamic canvases/video and
 * browser image uploads keep their ordinary per-draw upload path. */
const MAX_PIXELS=16*1024*1024;
export class PreviewAtlasTextures{
 constructor(gl,{maxPixels=MAX_PIXELS}={}){
  if(!gl||!Number.isSafeInteger(maxPixels)||maxPixels<1||maxPixels>MAX_PIXELS)throw Error('Invalid preview texture cache.');
  this.gl=gl;this.maxPixels=maxPixels;this.pixels=0;this.sources=new WeakMap();this.entries=new Map();
 }
 _remove(entry){
  this.gl.deleteTexture(entry.texture);this.entries.delete(entry.texture);this.pixels-=entry.width*entry.height;
  const variants=this.sources.get(entry.source);variants?.delete(entry.key);if(variants?.size===0)this.sources.delete(entry.source);
 }
 bind(source,width,height,premultiplied,prepare){
  if(!(source instanceof Uint8Array||source instanceof Uint8ClampedArray)||!Number.isSafeInteger(width)||!Number.isSafeInteger(height)||width<1||height<1||width*height>this.maxPixels||source.byteLength!==width*height*4||typeof premultiplied!=='boolean')throw Error('Invalid original atlas texture.');
  const gl=this.gl,key=width+':'+height+':'+Number(premultiplied);let entry=this.sources.get(source)?.get(key);
  gl.activeTexture(gl.TEXTURE0);
  if(entry){gl.bindTexture(gl.TEXTURE_2D,entry.texture);this.entries.delete(entry.texture);this.entries.set(entry.texture,entry);return entry.texture;}
  if(typeof prepare!=='function')throw Error('Original atlas preparation is unavailable.');
  // Retire old GPU buffers/source references before allocating the new upload,
  // keeping peak memory bounded when switching between two large atlases.
  while(this.pixels+width*height>this.maxPixels)this._remove(this.entries.values().next().value);
  const prepared=prepare(source,width,height,premultiplied);
  if(!(prepared instanceof Uint8Array||prepared instanceof Uint8ClampedArray)||prepared.byteLength!==source.byteLength)throw Error('The original atlas has invalid prepared pixels.');
  const texture=gl.createTexture();if(!texture)throw Error('The preview could not allocate its atlas.');
  try{
   gl.bindTexture(gl.TEXTURE_2D,texture);
   for(const p of[gl.TEXTURE_WRAP_S,gl.TEXTURE_WRAP_T])gl.texParameteri(gl.TEXTURE_2D,p,gl.CLAMP_TO_EDGE);
   for(const p of[gl.TEXTURE_MIN_FILTER,gl.TEXTURE_MAG_FILTER])gl.texParameteri(gl.TEXTURE_2D,p,gl.LINEAR);
   // The prepared bytes already have the native PNG integer conversion and
   // explicit row orientation. WebGL's browser-image conversions stay off.
   gl.pixelStorei(gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL,false);gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL,false);
   gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA,width,height,0,gl.RGBA,gl.UNSIGNED_BYTE,prepared);
   const error=gl.getError();if(error!==gl.NO_ERROR)throw Error('Preview atlas upload failed ('+error+').');
  }catch(error){gl.deleteTexture(texture);throw error;}
  entry={source,key,texture,width,height};let variants=this.sources.get(source);if(!variants)this.sources.set(source,variants=new Map());variants.set(key,entry);this.entries.set(texture,entry);this.pixels+=width*height;return texture;
 }
 clear(){for(const entry of this.entries.values())this._remove(entry);}
}
