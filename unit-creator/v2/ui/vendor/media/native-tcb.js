/* Original Forge implementation of the supplied native 3D TCB curve.
 * Native arithmetic proof: tests/native-preview-effect-tracks.py executes
 * original interpolation0x1f863ac and tangents0x1f864f4. MIT.
 * Each endpoint owns its own T/C/B; missing neighbors use one-sided tangents.
 * This module does not infer missing prior battle state or phase context. */
const f=Math.fround;
const finite=(value,fallback=0)=>Number.isFinite(Number(value))?Number(value):fallback;
const add=(a,b)=>f(a+b),sub=(a,b)=>f(a-b),mul=(a,b)=>f(a*b),madd=(a,b,c)=>f(a*b+c);
export const DEFAULT_TCB=Object.freeze({t:.5,c:-1,b:0});
function tcb(key){return{t:f(finite(key.t,.5)),c:f(finite(key.c,-1)),b:f(finite(key.b,0))};}
export function nativeSegment(previous,left,right,next,fraction,get){
 const p0=f(finite(get(left))),p1=f(finite(get(right))),a=tcb(left),b=tcb(right),delta=sub(p1,p0);
 let m0=mul(delta,mul(mul(sub(1,a.t),sub(1,a.c)),sub(1,a.b)));
 if(previous){const prior=f(finite(get(previous))),coefficient=mul(mul(sub(1,a.t),add(1,a.c)),add(1,a.b)),scale=a.c===-1?.5:f(f(right.frame-left.frame)/f(right.frame-previous.frame));m0=mul(add(m0,mul(sub(p0,prior),coefficient)),scale);}
 let m1=mul(delta,mul(mul(sub(1,b.t),sub(1,b.c)),add(1,b.b)));
 if(next){const following=f(finite(get(next))),coefficient=mul(mul(sub(1,b.t),add(1,b.c)),sub(1,b.b)),scale=b.c===-1?.5:f(f(right.frame-left.frame)/f(next.frame-left.frame));m1=mul(add(m1,mul(sub(following,p1),coefficient)),scale);}
 const u=f(fraction),u2=mul(u,u),u3=mul(u2,u);
 let quadratic=madd(-3,p0,mul(3,p1));quadratic=madd(-2,m0,quadratic);quadratic=sub(quadratic,m1);
 let cubic=madd(2,p0,mul(-2,p1));cubic=add(m0,cubic);cubic=add(m1,cubic);
 let result=mul(quadratic,u2);result=madd(cubic,u3,result);result=madd(m0,u,result);return add(p0,result);
}
function ordered(keys){const seen=new Set();return keys.filter(key=>{const frame=finite(key?.frame,NaN);if(!Number.isFinite(frame)||seen.has(frame))return false;seen.add(frame);return true;}).slice().sort((a,b)=>a.frame-b.frame);}
export function interpolateComponent(keys,frame,get){
 if(!keys?.length)return null;const list=ordered(keys);if(!list.length)return null;const at=finite(frame);
 if(at<=list[0].frame)return f(finite(get(list[0])));if(at>=list[list.length-1].frame)return f(finite(get(list[list.length-1])));
 let index=0;while(index<list.length-1&&list[index+1].frame<=at)index++;
 const left=list[index],right=list[index+1],span=right.frame-left.frame;if(span<1)return f(finite(get(right)));
 // Original native next-neighbor selector0x1f83c18 omits the final
 // stored key as a forward tangent neighbor (it remains a real endpoint).
 const next=index+2<list.length-1?list[index+2]:null;
 return nativeSegment(list[index-1]||null,left,right,next,f(f(at-left.frame)/f(span)),get);
}
export function evalVec3Track(keys,frame,kind){
 if(!keys?.length){if(kind==='scale')return{x:1,y:1,z:0};if(kind==='pos')return{x:-5000,y:0,z:0};return{x:0,y:0,z:0};}
 if(kind==='scale')return{x:interpolateComponent(keys,frame,key=>finite(key.sx,1))??1,y:interpolateComponent(keys,frame,key=>finite(key.sy,1))??1,z:interpolateComponent(keys,frame,key=>finite(key.sz))??0};
 if(kind==='rot')return{x:interpolateComponent(keys,frame,key=>finite(key.rot))??0,y:0,z:0};
 return{x:interpolateComponent(keys,frame,key=>finite(key.x))??0,y:interpolateComponent(keys,frame,key=>finite(key.y))??0,z:interpolateComponent(keys,frame,key=>finite(key.z))??0};
}
