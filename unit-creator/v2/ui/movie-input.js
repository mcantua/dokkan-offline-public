(function(root, factory) {
  if (typeof module === "object" && module.exports) module.exports = factory();
  else root.ForgeMovieInput = factory();
})(typeof globalThis === "object" ? globalThis : this, function() {
  "use strict";
  const MAX_BYTES = 160 * 1024 * 1024, MAX_HEADER = 2 * 1024 * 1024;
  function damaged() {
    throw new Error("This movie has damaged or unsupported timing metadata.");
  }
  function utfHeader(bytes) {
    const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength), len = bytes.byteLength;
    const need = (off, n) => {
      if (!Number.isSafeInteger(off) || off < 0 || n < 0 || off + n > len) damaged();
    };
    const u8 = (off) => {
      need(off, 1);
      return view.getUint8(off);
    }, u16 = (off) => {
      need(off, 2);
      return view.getUint16(off);
    }, u32 = (off) => {
      need(off, 4);
      return view.getUint32(off);
    };
    if (len < 32 || String.fromCharCode(...bytes.subarray(0, 4)) !== "@UTF") return null;
    const end = u32(4) + 8;
    if (end > len || end < 32) damaged();
    const rows = u32(8) + 8, strings = u32(12) + 8, data = u32(16) + 8, count = u16(24), rowWidth = u16(26), rowCount = u32(28);
    if (rows < 32 || rows > strings || strings > data || data > end) damaged();
    const stringAt = (relative) => {
      const off = strings + relative;
      if (!Number.isSafeInteger(relative) || relative < 0 || off < strings || off >= data) damaged();
      let at = off;
      while (at < data && at - off < 512 && bytes[at] !== 0) at++;
      if (at === data || at - off >= 512) damaged();
      return new TextDecoder().decode(bytes.subarray(off, at));
    };
    const name = stringAt(u32(20));
    if (name !== "VIDEO_HDRINFO" && name !== "AUDIO_HDRINFO") return null;
    if (count > 256 || rowCount > 64 || rowWidth > 8192 || rows + rowWidth * rowCount > strings) damaged();
    if (!rowCount) return { name, values: {} };
    const sizes = [1, 1, 2, 2, 4, 4, 8, 8, 4, 8, 4, 8];
    const value = (off, type) => {
      const n = sizes[type];
      if (n === void 0) damaged();
      need(off, n);
      switch (type) {
        case 0:
          return view.getInt8(off);
        case 1:
          return view.getUint8(off);
        case 2:
          return view.getInt16(off);
        case 3:
          return view.getUint16(off);
        case 4:
          return view.getInt32(off);
        case 5:
          return view.getUint32(off);
        case 6:
        case 7: {
          const high = view.getUint32(off), low = view.getUint32(off + 4), v = high * 4294967296 + low;
          return Number.isSafeInteger(v) ? v : null;
        }
        case 8:
          return view.getFloat32(off);
        case 9:
          return view.getFloat64(off);
        default:
          return null;
      }
    };
    let col = 32, row = rows;
    const values = {};
    for (let i = 0; i < count; i++) {
      if (col + 5 > rows) damaged();
      const flags = u8(col), type = flags & 15, storage = flags & 240, key = stringAt(u32(col + 1));
      col += 5;
      if (sizes[type] === void 0) damaged();
      let found;
      if (storage === 16) found = 0;
      else if (storage === 48) {
        if (col + sizes[type] > rows) damaged();
        found = value(col, type);
        col += sizes[type];
      } else if (storage === 80) {
        if (row + sizes[type] > rows + rowWidth) damaged();
        found = value(row, type);
        row += sizes[type];
      } else damaged();
      if (typeof found === "number" && Number.isFinite(found)) values[key] = found;
    }
    return { name, values };
  }
  function typeOf(video, codec) {
    const text = (a, b) => String.fromCharCode(...video.subarray(a, b));
    if (video.length >= 32 && text(0, 4) === "DKIF") {
      if (text(8, 12) === "VP90") return "vp9-ivf";
      if (text(8, 12) === "AV01") return "av1-ivf";
    }
    let mpeg = false, extension = false, h264 = false;
    for (let i = 0; i < Math.min(video.length - 5, 65536); i++) if (video[i] === 0 && video[i + 1] === 0 && video[i + 2] === 1) {
      const code = video[i + 3];
      if (code === 176 || code === 182) return "mpeg4";
      if (code === 179) mpeg = true;
      if (code === 181 && video[i + 4] >>> 4 === 1) extension = true;
      if ((code & 31) === 7 || (code & 31) === 8) h264 = true;
    }
    if (mpeg) return codec === 1 ? "mpeg1" : extension ? "mpeg2" : "mpeg1";
    if (h264) return "h264";
    throw Error("This movie uses a video format the local editor cannot read.");
  }
  function readMovie(input) {
    const bytes = input instanceof Uint8Array ? input : new Uint8Array(input);
    if (bytes.length < 32 || bytes.length > MAX_BYTES || String.fromCharCode(...bytes.subarray(0, 4)) !== "CRID") throw Error("Choose a complete CRI USM game movie up to 160 MB.");
    const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength), video = [], audio = [], videoTracks = /* @__PURE__ */ new Set(), audioTracks = /* @__PURE__ */ new Set();
    let offset = 0, chunks = 0, totalVideo = 0, totalAudio = 0, header, soundHeader;
    while (offset < bytes.length) {
      if (offset + 32 > bytes.length || ++chunks > 5e4) damaged();
      const size = view.getUint32(offset + 4), end = offset + 8 + size, payload = view.getUint16(offset + 8), padding = view.getUint16(offset + 10), tag = String.fromCharCode(...bytes.subarray(offset, offset + 4)), kind2 = bytes[offset + 15], channel = bytes[offset + 12], start = offset + 8 + payload, stop = end - padding;
      if (size < 24 || end > bytes.length || payload < 24 || start > stop || stop > end || end <= offset) damaged();
      if ((tag === "@SFV" || tag === "@SFA") && kind2 === 1 && channel === 0) {
        if (stop - start > MAX_HEADER) damaged();
        const table = utfHeader(bytes.subarray(start, stop));
        if ((table == null ? void 0 : table.name) === "VIDEO_HDRINFO") {
          if (header) damaged();
          header = table.values;
        } else if ((table == null ? void 0 : table.name) === "AUDIO_HDRINFO") {
          if (soundHeader) damaged();
          soundHeader = table.values;
        }
      }
      if (kind2 === 0 && tag === "@SFV") {
        videoTracks.add(channel);
        if (channel === 0) {
          video.push(bytes.subarray(start, stop));
          totalVideo += stop - start;
        }
      }
      if (kind2 === 0 && tag === "@SFA") {
        audioTracks.add(channel);
        if (channel === 0) {
          audio.push(bytes.subarray(start, stop));
          totalAudio += stop - start;
        }
      }
      offset = end;
    }
    if (!header || !totalVideo || totalVideo + totalAudio > MAX_BYTES) throw Error("The movie is missing its readable video stream or timing information.");
    const { width, height, total_frames: frames, framerate_n: n, framerate_d: d } = header;
    if (![width, height, frames, n, d].every(Number.isSafeInteger) || width < 2 || height < 2 || width > 4096 || height > 4096 || width * height > 16 * 1024 * 1024 || frames < 1 || frames > 1e4 || n < 1 || n > 2147483647 || d < 1 || d > 1e6 || n / d < 1 || n / d > 120) throw Error("The movie dimensions, duration or frame rate exceed the editor limits.");
    const join = (parts, size) => {
      const result = new Uint8Array(size);
      let at = 0;
      for (const part of parts) {
        result.set(part, at);
        at += part.length;
      }
      return result;
    }, picture = join(video, totalVideo), sound = totalAudio ? join(audio, totalAudio) : null, kind = typeOf(picture, header.mpeg_codec), warnings = [];
    if (videoTracks.size > 1 || audioTracks.size > 1) warnings.push("This movie contains several tracks. The editor selected the first video and sound tracks.");
    if (kind === "vp9-ivf" || kind === "av1-ivf") {
      if (picture.length < 44) damaged();
      const ivf = new DataView(picture.buffer), declared = ivf.getUint32(24, true);
      if (ivf.getUint16(4, true) !== 0 || ivf.getUint16(6, true) !== 32 || ivf.getUint16(12, true) !== width || ivf.getUint16(14, true) !== height || declared && declared !== frames) damaged();
      let at = 32, count = 0;
      while (at < picture.length) {
        if (at + 12 > picture.length) damaged();
        const size = ivf.getUint32(at, true);
        if (!size || at + 12 + size > picture.length || ivf.getBigUint64(at + 4, true) !== BigInt(count)) damaged();
        at += 12 + size;
        if (++count > 1e4) damaged();
      }
      if (count !== frames) damaged();
    }
    const soundKind = sound ? sound.length >= 20 && sound[0] === 128 && sound[1] === 0 ? "adx" : String.fromCharCode(...sound.subarray(0, 3)) === "HCA" ? "hca" : "unsupported" : null;
    return { video: picture, audio: sound, audioKind: soundKind, kind, rate: { n, d }, frames, width, height, audioInfo: soundHeader ? { samples: soundHeader.total_samples, sampleRate: soundHeader.sampling_rate, channels: soundHeader.num_channels } : null, warnings };
  }
  return { readMovie, MAX_BYTES };
});
