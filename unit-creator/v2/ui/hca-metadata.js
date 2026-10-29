(function(root, factory) {
  const api = factory();
  if (typeof module === "object" && module.exports) module.exports = api;
  else root.ForgeHcaMetadata = api;
})(typeof globalThis !== "undefined" ? globalThis : this, function() {
  "use strict";
  const MAX_BYTES = 160 * 1024 * 1024;
  function fail(text) {
    throw Error(text);
  }
  function tag(bytes, at) {
    return String.fromCharCode(...bytes.subarray(at, at + 4).map((x) => x & 127));
  }
  function crc(bytes) {
    let value = 0;
    for (const b of bytes) {
      value ^= b << 8;
      for (let bit = 0; bit < 8; bit++) value = (value << 1 ^ (value & 32768 ? 32773 : 0)) & 65535;
    }
    return value;
  }
  function inspect(bytes) {
    if (!(bytes instanceof Uint8Array) || bytes.length < 40 || bytes.length > MAX_BYTES) fail("The HCA sound is empty, truncated or too large.");
    const v = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength), version = v.getUint16(4), offset = v.getUint16(6);
    if (tag(bytes, 0) !== "HCA\0" || tag(bytes, 8) !== "fmt\0" || version < 256 || version > 768 || offset < 40 || offset > 65535 || offset > bytes.length) fail("This HCA sound has an invalid header.");
    const channels = bytes[12], sampleRate = bytes[13] << 16 | bytes[14] << 8 | bytes[15], frameCount = v.getUint32(16), delay = v.getUint16(20), padding = v.getUint16(22), encodedSamples = frameCount * 1024, samples = encodedSamples - delay - padding;
    if (!channels || channels > 8 || sampleRate < 8e3 || sampleRate > 192e3 || !frameCount || !Number.isSafeInteger(encodedSamples) || encodedSamples * channels * 4 > MAX_BYTES || samples < 1 || delay + padding >= encodedSamples || samples / sampleRate > 600) fail("This HCA sound has invalid or oversized sample data.");
    const format = tag(bytes, 24), frameBytes = v.getUint16(28);
    if (!["comp", "dec\0"].includes(format) || frameBytes < 8 || offset + frameCount * frameBytes > bytes.length) fail("The HCA sound ends inside a coded frame.");
    if (crc(bytes.subarray(0, offset)) !== 0) fail("The HCA header checksum is damaged.");
    let at = format === "comp" ? 40 : 36, cipherType = 0, loop = null, seen = /* @__PURE__ */ new Set();
    while (at < offset - 2) {
      if (at + 4 > offset - 2) fail("The HCA header ends inside a metadata field.");
      const name = tag(bytes, at);
      if (name === "pad\0" || name === "comm") break;
      if (seen.has(name)) fail("The HCA header repeats a metadata field.");
      seen.add(name);
      const size = { "ath\0": 6, "loop": 16, "ciph": 6, "rva\0": 8, "vbr\0": 8 }[name];
      if (!size || at + size > offset - 2) fail("This HCA sound has unsupported or truncated metadata.");
      if (name === "ciph") cipherType = v.getUint16(at + 4);
      if (name === "loop") {
        const first = v.getUint32(at + 4), last = v.getUint32(at + 8), pre = v.getUint16(at + 12), post = v.getUint16(at + 14), start = first * 1024 + pre - delay, end = (last + 1) * 1024 - post - delay;
        if (first > last || last >= frameCount || pre > 1023 || post > 1023 || start < 0 || end <= start || end > samples) fail("This HCA sound has invalid loop points.");
        loop = { startSample: start, endSample: end, sampleRate };
      }
      at += size;
    }
    if (![0, 1].includes(cipherType)) fail("This encrypted HCA sound needs an authorized, supported decoder key.");
    for (let frame = 0; frame < frameCount; frame++) {
      const start = offset + frame * frameBytes;
      if (bytes[start] !== 255 || bytes[start + 1] !== 255 || crc(bytes.subarray(start, start + frameBytes)) !== 0) fail("The HCA sound contains a damaged coded frame.");
    }
    return { version, offset, channels, sampleRate, frameCount, frameBytes, encodedSamples, delay, padding, samples: loop ? Math.min(samples, loop.endSample) : samples, declaredSamples: samples, cipherType, loop };
  }
  function prepare(bytes) {
    const info = inspect(bytes);
    if (info.cipherType !== 1) return { data: bytes, info };
    const output = new Uint8Array(bytes), v = new DataView(output.buffer, output.byteOffset, output.byteLength), decrypt = new Uint8Array(256);
    let x = 0, index = 1;
    for (let i = 0; i < 256; i++) {
      x = x * 13 + 11 & 255;
      if (x !== 0 && x !== 255) decrypt[index++] = x;
    }
    decrypt[255] = 255;
    for (let frame = 0; frame < info.frameCount; frame++) {
      const at2 = info.offset + frame * info.frameBytes, end = at2 + info.frameBytes - 2;
      for (let p = at2; p < end; p++) output[p] = decrypt[output[p]];
      v.setUint16(end, crc(output.subarray(at2, end)));
    }
    let at = tag(bytes, 24) === "comp" ? 40 : 36, found = false;
    while (at < info.offset - 2) {
      const name = tag(bytes, at);
      if (name === "ciph") {
        v.setUint16(at + 4, 0);
        found = true;
        break;
      }
      const size = { "ath\0": 6, loop: 16, "rva\0": 8, "vbr\0": 8 }[name];
      if (!size) fail("The HCA cipher metadata is unavailable.");
      at += size;
    }
    if (!found) fail("The HCA cipher metadata is missing.");
    v.setUint16(info.offset - 2, crc(output.subarray(0, info.offset - 2)));
    return { data: output, info };
  }
  function filters(info) {
    if (!info || !Number.isSafeInteger(info.delay) || !Number.isSafeInteger(info.samples) || info.delay < 0 || info.samples < 1 || info.delay + info.samples > MAX_BYTES) fail("Invalid HCA sample trim.");
    return "atrim=start_sample=" + info.delay + ":end_sample=" + (info.delay + info.samples) + ",asetpts=PTS-STARTPTS,volume=-1:precision=float";
  }
  return { inspect, prepare, filters, crc, MAX_BYTES };
});
