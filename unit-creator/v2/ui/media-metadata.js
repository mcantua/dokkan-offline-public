const MAX_SCAN = 2 * 1024 * 1024, MAX_CHUNKS = 512;
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
        return view.getUint8(off);
      case 1:
        return view.getInt8(off);
      case 2:
        return view.getUint16(off);
      case 3:
        return view.getInt16(off);
      case 4:
        return view.getUint32(off);
      case 5:
        return view.getInt32(off);
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
export function readUsmMetadata(input) {
  const bytes = input instanceof Uint8Array ? input : new Uint8Array(input), out = {};
  if (bytes.length < 4 || String.fromCharCode(...bytes.subarray(0, 4)) !== "CRID") return out;
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  let off = 0, seen = 0;
  while (off + 32 <= bytes.length && off < MAX_SCAN && seen++ < MAX_CHUNKS) {
    const size = view.getUint32(off + 4), end = off + 8 + size, header = view.getUint16(off + 8), padding = view.getUint16(off + 10), kind = bytes[off + 15], tag = String.fromCharCode(...bytes.subarray(off, off + 4));
    if (size < 24 || end > bytes.length || header < 24 || header + padding > size) damaged();
    if ((tag === "@SFV" || tag === "@SFA") && kind === 1) {
      const start = off + 8 + header, stop = end - padding;
      if (stop - start > MAX_SCAN) damaged();
      const table = utfHeader(bytes.subarray(start, stop));
      if (table) {
        const v = table.values;
        if (table.name === "VIDEO_HDRINFO") {
          if (v.framerate_n > 0 && v.framerate_d > 0) {
            const rate = v.framerate_n / v.framerate_d;
            if (rate > 0 && rate <= 240) out.framerate = rate;
          }
          if (Number.isInteger(v.total_frames) && v.total_frames >= 0 && v.total_frames <= 1e7) out.frames = v.total_frames;
          for (const key of ["width", "height"]) if (Number.isInteger(v[key]) && v[key] > 0 && v[key] <= 32768) out[key] = v[key];
        } else if (!out.audio) {
          const audio = {};
          if (v.total_samples >= 0) audio.samples = v.total_samples;
          if (v.sampling_rate > 0 && v.sampling_rate <= 384e3) audio.sampleRate = v.sampling_rate;
          if (v.num_channels > 0 && v.num_channels <= 32) audio.channels = v.num_channels;
          if (Object.keys(audio).length) out.audio = audio;
        }
      }
    }
    off = end;
    if (kind === 0 && (tag === "@SFV" || tag === "@SFA")) break;
  }
  if (off < bytes.length && off < MAX_SCAN && bytes.length - off < 32) damaged();
  return out;
}
