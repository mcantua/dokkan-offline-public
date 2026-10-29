/* Original Forge bounded PNG→straight RGBA decoder. MIT.
 * Retains original RGB under alpha0, which a Canvas readback can destroy.
 * Includes PNG filters/packed samples/16-bit stripping and seven Adam7 passes.
 * Original native Image byte oracles are tested independently. */
import { classifyNativePNG } from './preview-png-metadata.js';
import { Unzlib } from './preview-png-inflate.js';
const MAX_INPUT=32*1024*1024,MAX_PIXELS=16*1024*1024,MAX_INFLATED=128*1024*1024+65536,channels={0:1,2:3,3:1,4:2,6:4};
let crcTable;
function crc(bytes,start,end){if(!crcTable){crcTable=new Uint32Array(256);for(let i=0;i<256;i++){let c=i;for(let n=0;n<8;n++)c=c&1?0xedb88320^(c>>>1):c>>>1;crcTable[i]=c>>>0;}}let c=0xffffffff;for(let i=start;i<end;i++)c=crcTable[(c^bytes[i])&255]^(c>>>8);return(c^0xffffffff)>>>0;}
function adler(bytes){let a=1,b=0;for(let start=0;start<bytes.length;start+=5552){const end=Math.min(bytes.length,start+5552);for(let i=start;i<end;i++){a+=bytes[i];b+=a;}a%=65521;b%=65521;}return((b<<16)|a)>>>0;}
export function inflateNativePNG(bytes,expected){
 if(!(bytes instanceof Uint8Array)||bytes.length<6||bytes.length>MAX_INPUT||!Number.isInteger(expected)||expected<1||expected>MAX_INFLATED)throw Error('Invalid bounded PNG compression request.');
 if((bytes[0]&15)!==8||bytes[0]>>>4>7||((bytes[0]<<8)|bytes[1])%31||bytes[1]&32)throw Error('This PNG has invalid zlib compression.');
 const out=new Uint8Array(expected);let used=0,finished=false;const inflater=new Unzlib((chunk,final)=>{if(used+chunk.length>expected)throw Error('PNG pixels exceed their declared dimensions.');out.set(chunk,used);used+=chunk.length;finished=!!final;});
 // A compressed1KiB step has a bounded DEFLATE expansion. Never feed an entire
 // attacker-controlled stream to an allocation-growing synchronous inflater.
 for(let at=0;at<bytes.length;at+=1024)inflater.push(bytes.subarray(at,Math.min(at+1024,bytes.length)),at+1024>=bytes.length);
 if(!finished||used!==expected)throw Error('The PNG pixel data is incomplete.');const n=bytes.length,checksum=((bytes[n-4]*0x1000000)+(bytes[n-3]<<16)+(bytes[n-2]<<8)+bytes[n-1])>>>0;if(adler(out)!==checksum)throw Error('The PNG pixel checksum is invalid.');return out;
}
function paeth(a,b,c){const p=a+b-c,pa=Math.abs(p-a),pb=Math.abs(p-b),pc=Math.abs(p-c);return pa<=pb&&pa<=pc?a:pb<=pc?b:c;}
export function decodeNativePNG(input,{inflate=inflateNativePNG,accelerator=null}={}){
 if(accelerator!==null&&(typeof accelerator.crc!=='function'||typeof accelerator.decode!=='function'))throw Error('Invalid PNG decoder accelerator.');const checksum=accelerator?accelerator.crc:crc;
 if(!(input instanceof Uint8Array)||input.length>MAX_INPUT)throw Error('This PNG exceeds the preview file-size limit.');const metadata=classifyNativePNG(input,{crc:checksum});if(!metadata.known)throw Error(metadata.reason);const{width,height,bitDepth:depth,colorType:type}=metadata;if(width>32768||height>32768||width*height>MAX_PIXELS)throw Error('This PNG exceeds the preview pixel limit.');
 const view=new DataView(input.buffer,input.byteOffset,input.byteLength),interlaced=input[28]===1,sourceChannels=channels[type],bits=sourceChannels*depth,bpp=Math.max(1,Math.ceil(bits/8)),idats=[];let palette=null,trns=null,totalCompressed=0,at=8,ended=false,sawData=false,dataEnded=false,sawHeader=false;
 while(at+12<=input.length){const length=view.getUint32(at),name=String.fromCharCode(...input.subarray(at+4,at+8));if(!/^[A-Za-z]{4}$/.test(name)||name[2]!==name[2].toUpperCase())throw Error('The PNG has an invalid chunk type.');if(length>0x7fffffff||at+length+12>input.length)throw Error('The PNG contains a truncated chunk.');if(checksum(input,at+4,at+8+length)!==view.getUint32(at+8+length))throw Error('The PNG contains a corrupt chunk.');
  if(name==='IDAT'){if(dataEnded)throw Error('The PNG image-data chunks are out of order.');sawData=true;totalCompressed+=length;if(totalCompressed>MAX_INPUT)throw Error('The PNG compressed pixels exceed the preview limit.');idats.push(input.subarray(at+8,at+8+length));}
  else{if(sawData)dataEnded=true;if(name==='IHDR'){if(sawHeader||at!==8||length!==13)throw Error('The PNG image headers are out of order.');sawHeader=true;}else if(name==='PLTE'){if(sawData||palette)throw Error('The PNG palette is out of order.');palette=input.subarray(at+8,at+8+length);}else if(name==='tRNS'){if(sawData||trns)throw Error('The PNG transparency metadata is out of order.');trns=input.subarray(at+8,at+8+length);}else if(name==='IEND'){if(length!==0||!sawData||at+12!==input.length)throw Error('The PNG has an invalid ending.');ended=true;break;}else if(name!=='IHDR'&&name[0]===name[0].toUpperCase())throw Error('This PNG uses an unsupported critical chunk.');}
  at+=length+12;
 }
 if(!ended||!totalCompressed)throw Error('The PNG image data is incomplete.');const passes=interlaced?[[0,0,8,8],[4,0,8,8],[0,4,4,8],[2,0,4,4],[0,2,2,4],[1,0,2,2],[0,1,1,2]]:[[0,0,1,1]],plans=passes.map(([x,y,dx,dy])=>({x,y,dx,dy,w:Math.max(0,Math.ceil((width-x)/dx)),h:Math.max(0,Math.ceil((height-y)/dy))}));let expected=0;for(const p of plans)if(p.w&&p.h){p.stride=Math.ceil(p.w*bits/8);expected+=(p.stride+1)*p.h;}if(expected>MAX_INFLATED)throw Error('The PNG inflated pixels exceed the preview limit.');
 if(accelerator&&inflate===inflateNativePNG){const rgba=accelerator.decode({parts:idats,compressedLength:totalCompressed,expected,width,height,depth,type,interlaced,palette,trns});if(!(rgba instanceof Uint8Array)||rgba.length!==width*height*4)throw Error('The PNG accelerator returned the wrong pixel size.');return{width,height,rgba,metadata};}
 const compressed=new Uint8Array(totalCompressed);let pos=0;for(const part of idats){compressed.set(part,pos);pos+=part.length;}const raw=inflate(compressed,expected);if(!(raw instanceof Uint8Array)||raw.length!==expected)throw Error('The PNG inflater returned the wrong pixel size.');const rgba=new Uint8Array(width*height*4);pos=0;
 for(const p of plans){if(!p.w||!p.h)continue;let previous=new Uint8Array(p.stride),row=new Uint8Array(p.stride);for(let py=0;py<p.h;py++){const filter=raw[pos++];if(filter>4)throw Error('This PNG uses an invalid row filter.');for(let i=0;i<p.stride;i++){const a=i>=bpp?row[i-bpp]:0,b=previous[i],c=i>=bpp?previous[i-bpp]:0,predict=filter===0?0:filter===1?a:filter===2?b:filter===3?(a+b)>>>1:paeth(a,b,c);row[i]=(raw[pos++]+predict)&255;}
   const sample=index=>depth===16?(row[index*2]<<8)|row[index*2+1]:depth===8?row[index]:(row[(index*depth)>>>3]>>>(8-depth-(index*depth&7)))&((1<<depth)-1),toByte=value=>depth===16?value>>>8:depth===8?value:Math.floor(value*255/((1<<depth)-1));
   for(let px=0;px<p.w;px++){const out=((p.y+py*p.dy)*width+p.x+px*p.dx)*4,index=px*sourceChannels;let r,g,b,a=255;
    if(type===3){const color=sample(index);if(color*3+2>=palette.length)throw Error('The PNG pixel references a missing palette color.');r=palette[color*3];g=palette[color*3+1];b=palette[color*3+2];if(trns&&color<trns.length)a=trns[color];}
    else if(type===0||type===4){const gray=sample(index);r=g=b=toByte(gray);if(type===4)a=toByte(sample(index+1));else if(trns&&gray===((trns[0]<<8)|trns[1]))a=0;}
    else{const rs=sample(index),gs=sample(index+1),bs=sample(index+2);r=toByte(rs);g=toByte(gs);b=toByte(bs);if(type===6)a=toByte(sample(index+3));else if(trns&&rs===((trns[0]<<8)|trns[1])&&gs===((trns[2]<<8)|trns[3])&&bs===((trns[4]<<8)|trns[5]))a=0;}
    rgba[out]=r;rgba[out+1]=g;rgba[out+2]=b;rgba[out+3]=a;
   }const swap=previous;previous=row;row=swap;
  }}
 return{width,height,rgba,metadata};
}
export function nativePNGTexturePixels(decoded){
 if(!decoded||!(decoded.rgba instanceof Uint8Array)||!Number.isInteger(decoded.width)||!Number.isInteger(decoded.height)||decoded.width<1||decoded.height<1||decoded.width*decoded.height>MAX_PIXELS||decoded.rgba.length!==decoded.width*decoded.height*4||typeof decoded.metadata?.premultiplied!=='boolean')throw Error('Invalid decoded PNG texture.');
 const out=decoded.rgba.slice();if(decoded.metadata.premultiplied)for(let at=0;at<out.length;at+=4){const factor=out[at+3]+1;for(let color=0;color<3;color++)out[at+color]=(out[at+color]*factor)>>>8;}return out;
}
