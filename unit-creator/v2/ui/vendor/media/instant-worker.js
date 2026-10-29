/* Forge instant movie join. MIT.
 * Joins VP9 scene sections without re-encoding: every section starts on a keyframe, so its
 * frames can be copied as they are. Plain ADX sound is cut and joined in PCM and encoded once.
 * Input: {name, width, height, rate:{n,d}, sections:[{video, from, to, audio, audioKind, mute}], mute}
 */
'use strict';
importScripts('./usm-writer.js', './native-adx.js');
self.onmessage = ({ data }) => {
  try {
    const progress = (message) => self.postMessage({ type: 'progress', event: { message } });
    progress('Joining your scenes');
    const parts = [];
    let frameCount = 0, bytes = 32;
    for (const section of data.sections) {
      const info = ForgeUsmWriter.inspectIVF(section.video);
      if (!info.frames[section.from] || !info.frames[section.from].key) throw Error('A section no longer starts on a cut point. Snap its start again.');
      if (section.to > info.frames.length || section.to <= section.from) throw Error('A section ends outside its scene.');
      for (let i = section.from; i < section.to; i++) {
        const f = info.frames[i];
        parts.push(section.video.subarray(f.offset + 12, f.offset + 12 + f.size));
        bytes += 12 + f.size;
        frameCount++;
      }
    }
    const ivf = new Uint8Array(bytes), view = new DataView(ivf.buffer);
    ivf.set([68, 75, 73, 70], 0);
    view.setUint16(4, 0, true);
    view.setUint16(6, 32, true);
    ivf.set([86, 80, 57, 48], 8);
    view.setUint16(12, data.width, true);
    view.setUint16(14, data.height, true);
    view.setUint32(16, data.rate.n, true);
    view.setUint32(20, data.rate.d, true);
    view.setUint32(24, frameCount, true);
    let at = 32, pts = 0;
    for (const part of parts) {
      view.setUint32(at, part.length, true);
      view.setBigUint64(at + 4, BigInt(pts++), true);
      ivf.set(part, at + 12);
      at += 12 + part.length;
    }
    let audio = null;
    if (!data.mute && data.sections.some((s) => s.audio && !s.mute)) {
      progress('Joining the sound');
      const fps = data.rate.n / data.rate.d;
      let format = null;
      const decoded = data.sections.map((s) => {
        if (!s.audio || s.mute) return null;
        const pcm = ForgeNativeAdx.decodeADX(s.audio);
        if (!format) format = { sampleRate: pcm.sampleRate, channels: pcm.channels };
        else if (format.sampleRate !== pcm.sampleRate || format.channels !== pcm.channels) throw Error('These scenes use different sound formats.');
        return pcm;
      });
      const ranges = data.sections.map((s) => [Math.round(s.from / fps * format.sampleRate), Math.round(s.to / fps * format.sampleRate)]);
      const samples = ranges.reduce((n, [a, b]) => n + (b - a), 0);
      const encoder = ForgeNativeAdx.createEncoder({ samples, sampleRate: format.sampleRate, channels: format.channels });
      const ch = format.channels;
      decoded.forEach((pcm, i) => {
        const [a, b] = ranges[i], length = (b - a) * ch, chunk = new Int16Array(length);
        if (pcm) {
          const available = Math.max(0, Math.min(b, pcm.samples) - a);
          if (available > 0) chunk.set(pcm.pcm.subarray(a * ch, (a + available) * ch));
        }
        const raw = new Uint8Array(chunk.buffer);
        for (let o = 0; o < raw.length; o += 65536) encoder.write(raw, o, Math.min(65536, raw.length - o));
      });
      audio = encoder.finish();
    }
    progress('Writing your movie');
    const usm = ForgeUsmWriter.encodeVP9(ivf, { name: data.name || 'forge-motion', audio: audio ? { kind: 'adx', data: audio } : null });
    self.postMessage({ type: 'result', data: usm, frames: frameCount }, [usm.buffer]);
  } catch (error) {
    self.postMessage({ type: 'error', message: String(error && error.message || error) });
  }
};
