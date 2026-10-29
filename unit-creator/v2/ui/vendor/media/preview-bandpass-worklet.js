/* Original Forge bounded persistent per-source sound filter. MIT. */
import {BandpassDSP} from './preview-bandpass-dsp.js';
class ForgeBandpassProcessor extends AudioWorkletProcessor{
  constructor(options){super();this.filter=new BandpassDSP(sampleRate);this.events=[];this.closed=false;this.tailEnd=Number.isFinite(options.processorOptions?.endTime)?Math.round(options.processorOptions.endTime*sampleRate)+256:Infinity;this.silence=new Float32Array(128);const initial=options.processorOptions?.events||[];for(const event of initial)this.add(event);this.port.onmessage=event=>{const value=event.data;if(value?.type==='close'){this.closed=true;this.events=[];}else if(value?.type==='end'&&Number.isFinite(value.time)&&value.time>=0)this.tailEnd=Math.min(this.tailEnd,Math.round(value.time*sampleRate)+256);else if(value?.type==='filter')this.add(value);};}
  add(value){if(!value||!Number.isFinite(value.time)||value.time<0||!Number.isFinite(value.low)||!Number.isFinite(value.high)||value.low<0||value.high<0||this.events.length>=4096)return;this.events.push({frame:Math.round(value.time*sampleRate),low:value.low,high:value.high});this.events.sort((a,b)=>a.frame-b.frame);}
  process(inputs,outputs){if(this.closed)return false;const input=inputs[0],output=outputs[0];if(!output?.length)return true;const length=output[0].length;let offset=0;
    while(offset<length){if(currentFrame+offset>=this.tailEnd){for(const channel of output)channel.fill(0,offset);this.closed=true;this.port.postMessage({type:'ended'});return false;}while(this.events[0]?.frame<=currentFrame+offset){const value=this.events.shift();this.filter.set(value.low,value.high);}const end=Math.min(length,this.tailEnd-currentFrame,Math.max(offset+1,(this.events[0]?.frame??Infinity)-currentFrame));for(let c=0;c<output.length;c++){const source=input[c]||input[0]||this.silence;this.filter.process(source.subarray(offset,end),output[c].subarray(offset,end),c);}offset=end;}
    return true;
  }
}
registerProcessor('forge-native-bandpass-v1',ForgeBandpassProcessor);
