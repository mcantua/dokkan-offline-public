/* Original Forge immutable native bitmap geometry. MIT.
 * Original LWFBitmapImpl::initWithFileEx406abe8; actual51fragment×3size oracle.
 * Read original Data before the Canvas context rounds/clips its source rect.
 * No Data, live matrix, bitmap renderer or image is mutated. */
const f=Math.fround,unknown=reason=>Object.freeze({known:false,reason}),freezeArray=values=>Object.freeze(values),finite=values=>values.every(Number.isFinite);
export function nativeBitmapGeometry(lwf,descriptor,physical){
 const data=lwf?.data??lwf,kind=descriptor?.kind,id=descriptor?.id;if(!['bitmap','bitmapEx'].includes(kind)||!Number.isInteger(id)||id<0)return unknown('The original bitmap identity is unavailable.');
 const bitmap=(kind==='bitmap'?data?.bitmaps:data?.bitmapExs)?.[id],fragment=data?.textureFragments?.[bitmap?.z$4],texture=data?.textures?.[fragment?.z$oe];if(!bitmap||!fragment||!texture)return unknown('The original bitmap texture definition is unavailable.');
 if(kind==='bitmapEx'&&((Number(bitmap.z$Tb)||0)&3)!==0)return unknown('Repeating bitmap geometry is not supported by this preview.');
 const width=physical?.width,height=physical?.height,nominalW=texture.width,nominalH=texture.height,scale=f(texture.scale),[x,y,u,v,w,h]=[fragment.x,fragment.y,fragment.z$R,fragment.z$S,fragment.z$q,fragment.z$k].map(f),clip=(kind==='bitmap'?[0,0,1,1]:[bitmap.z$R,bitmap.z$S,bitmap.z$q,bitmap.z$k]).map(f);
 if(!finite([width,height,nominalW,nominalH,scale,x,y,u,v,w,h,...clip])||width<=0||height<=0||nominalW<=0||nominalH<=0||scale<=0)return unknown('The original bitmap dimensions are invalid.');
 const offsetX=f(clip[0]*w),offsetY=f(clip[1]*h),spanX=f(clip[2]*w),spanY=f(clip[3]*h),left=f(f(x+offsetX)/scale),top=f(f(y+offsetY)/scale),right=f(f(f(x+offsetX)+spanX)/scale),bottom=f(f(f(y+offsetY)+spanY)/scale),baseU=f(u+offsetX),baseV=f(v+offsetY),rotated=!!fragment.z$fb,u0=f(baseU/f(nominalW)),v0=f(baseV/f(nominalH)),u1=f(f(baseU+(rotated?spanY:spanX))/f(nominalW)),v1=f(f(baseV+(rotated?spanX:spanY))/f(nominalH));
 const localCorners=freezeArray([[right,top],[right,bottom],[left,top],[left,bottom]].map(freezeArray)),nativeUV=freezeArray((rotated?[[u1,v1],[u0,v1],[u1,v0],[u0,v0]]:[[u1,v0],[u1,v1],[u0,v0],[u0,v1]]).map(freezeArray)),minU=Math.min(u0,u1),minV=Math.min(v0,v1),du=Math.abs(u1-u0),dv=Math.abs(v1-v0),sourceRect=freezeArray([minU*width,minV*height,du*width,dv*height]),empty=du===0||dv===0||left===right||top===bottom;
 let affine={a:0,b:0,c:0,d:0,tx:left,ty:top};
 if(!empty){
  // Fit the native source→local correspondence, rather than reverse-engineer
  // rounded Canvas dimensions. This also retains signed BitmapEx clips.
  const p=localCorners[2],s=nativeUV[2],uA=nativeUV[0][0]-s[0],vA=nativeUV[0][1]-s[1],uB=nativeUV[3][0]-s[0],vB=nativeUV[3][1]-s[1],pxA=localCorners[0][0]-p[0],pyA=localCorners[0][1]-p[1],pxB=localCorners[3][0]-p[0],pyB=localCorners[3][1]-p[1],det=uA*vB-vA*uB;
  if(!Number.isFinite(det)||det===0)return unknown('The original bitmap has a degenerate texture mapping.');
  const ax=(pxA*vB-pxB*vA)/det,ay=(pyA*vB-pyB*vA)/det,cx=(pxB*uA-pxA*uB)/det,cy=(pyB*uA-pyA*uB)/det;affine={a:ax*du,b:ay*du,c:cx*dv,d:cy*dv,tx:p[0]+ax*(minU-s[0])+cx*(minV-s[1]),ty:p[1]+ay*(minU-s[0])+cy*(minV-s[1])};
 }
 const outputSize=freezeArray([Math.max(1,Math.ceil(Math.abs(rotated?bottom-top:right-left))),Math.max(1,Math.ceil(Math.abs(rotated?right-left:bottom-top)))]),geometry={known:true,kind,id,textureIndex:fragment.z$oe,textureName:texture.filename,rotated,sourceRect,localCorners,nativeUV,localAffine:Object.freeze(affine),outputSize,empty};geometry.drawMatrix=(world,size=outputSize)=>nativeCanvasCommandGeometry(geometry,world,size).matrix;return Object.freeze(geometry);
}
export function nativeCanvasCommandGeometry(geometry,world,outputSize=geometry?.outputSize){
 if(!geometry?.known)return unknown(geometry?.reason||'The original bitmap geometry is unavailable.');if(geometry.empty)return Object.freeze({known:true,empty:true,matrix:null,sourceRect:geometry.sourceRect,outputSize});
 const m=[world?.scaleX,world?.skew1,world?.skew0,world?.scaleY,world?.translateX,world?.translateY],size=Array.isArray(outputSize)?outputSize:[];if(!finite(m)||size.length!==2||!size.every(value=>Number.isFinite(value)&&value>0))return unknown('The original bitmap world matrix or output size is unavailable.');
 const[a,b,c,d,tx,ty]=m,n=geometry.localAffine,[w,h]=size,matrix=Object.freeze({scaleX:(a*n.a+c*n.b)/w,skew1:(b*n.a+d*n.b)/w,skew0:(a*n.c+c*n.d)/h,scaleY:(b*n.c+d*n.d)/h,translateX:a*n.tx+c*n.ty+tx,translateY:b*n.tx+d*n.ty+ty});return Object.freeze({known:true,empty:false,matrix,sourceRect:geometry.sourceRect,outputSize:freezeArray(size.slice())});
}
