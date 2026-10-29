/* Original Forge per-sound bandpass mathematics. MIT.
 * Supplied native software-voice class: ctor421e3a4, coefficients421ec7c,
 * update421e464, PCM421e0e8/421f47c. This is a numerical reproduction;
 * SIMD reassociation can differ slightly from sequential browser arithmetic.
 */
const f=Math.fround;
export function bandpassFrequency(hz){
  if(!Number.isFinite(hz)||hz<=0)throw Error('Invalid game sound-filter frequency.');
  const normalized=f(Math.max(0,Math.min(1,f(Math.log(f(f(hz)/24)))/f(6.907755374908447))));
  if(normalized<=1/65536)return 24;if(normalized>=65535/65536)return 24000;
  // Native41f1ea8: three separate single-precision operations then exp2f.
  return Math.min(24000,Math.max(24,f(2**f(f(f(normalized*f(2.1735804080963135))+1)*f(4.584962368011475)))));
}
export function bandpassCoefficients(sampleRate,lowHz,highHz){
  if(!Number.isInteger(sampleRate)||sampleRate<8000||sampleRate>192000||!Number.isFinite(lowHz)||!Number.isFinite(highHz))throw Error('Invalid game sound-filter settings.');
  const low=Math.max(10,f(lowHz)),high=Math.min(f(sampleRate*.5-100),f(highHz));
  if(low>high-1)return{feedback:[1,0,0],feedforward:[0,0,0]};
  const a=Math.tan(Math.PI*low/sampleRate),b=Math.tan(Math.PI*high/sampleRate),denominator=1+b-a+a*b;
  return{feedback:[1,f(2*(a*b-1)/denominator),f((1-b+a+a*b)/denominator)],feedforward:[f((b-a)/denominator),0,f(-(b-a)/denominator)]};
}
export class BandpassDSP{
  constructor(sampleRate){if(!Number.isInteger(sampleRate)||sampleRate<8000||sampleRate>192000)throw Error('Invalid game sound-filter rate.');this.sampleRate=sampleRate;this.enabled=false;this.history=[];this.coefficients=null;}
  set(low,high,{normalized=true}={}){
    if(low===0||high===0)return false; // The original callback skips zero cutoffs.
    const pair=normalized?[bandpassFrequency(low),bandpassFrequency(high)]:[low,high];
    this.coefficients=bandpassCoefficients(this.sampleRate,...pair);this.enabled=true;return true;
  }
  reset(){this.history=[];this.enabled=false;this.coefficients=null;}
  process(input,output,channel=0){
    if(!Number.isInteger(channel)||channel<0||channel>=8||input.length!==output.length)throw Error('Invalid game sound-filter channel.');
    if(!this.enabled){output.set(input);return;}
    const state=this.history[channel]||(this.history[channel]=[0,0,0,0]),a=this.coefficients.feedback,b=this.coefficients.feedforward;let[x1,x2,y1,y2]=state;
    for(let i=0;i<input.length;i++){
      const x=input[i],y=b[0]*x+b[1]*x1+b[2]*x2-a[1]*y1-a[2]*y2;
      output[i]=y;x2=x1;x1=x;y2=y1;y1=y;
    }
    state[0]=x1;state[1]=x2;state[2]=y1;state[3]=y2;
  }
}
