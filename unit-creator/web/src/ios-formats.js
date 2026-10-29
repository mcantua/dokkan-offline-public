/* iPhone app: the Android app's file checks and readers (ImageAssets.inspect, LwfStorage.inspect,
 * CpkArchive @UTF/CPK/CRILAYLA, MovieStorage.inspect), same rules and messages. */
(function () {
  "use strict";
  const IOS = window.__forgeIOS || window.__forgeWeb;
  if (!IOS) return;
  const fail = (m) => new Error(m);
  const MiB = 1048576;
  const u16be = (b, o) => (b[o] << 8) | b[o + 1], u32be = (b, o) => ((b[o] << 24) >>> 0) + (b[o + 1] << 16) + (b[o + 2] << 8) + b[o + 3];
  const u16le = (b, o) => b[o] | (b[o + 1] << 8), u32le = (b, o) => (b[o] | (b[o + 1] << 8) | (b[o + 2] << 16)) + b[o + 3] * 16777216;
  const ascii = (b, o, n) => String.fromCharCode.apply(null, b.subarray(o, o + n));
  const F = (IOS.formats = { u16be, u32be, u16le, u32le, ascii });

  // ---------------------------------------------------------------- images
  const IMG_ERR = "Choose a complete supported image (up to 12 MB,4096px per side).";
  F.IMG_ERR = IMG_ERR;
  let crcTable = null;
  function crc32(b, start, end) {
    if (!crcTable) { crcTable = new Uint32Array(256); for (let n = 0; n < 256; n++) { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; crcTable[n] = c >>> 0; } }
    let c = 0xffffffff;
    for (let i = start; i < end; i++) c = crcTable[(c ^ b[i]) & 255] ^ (c >>> 8);
    return (c ^ 0xffffffff) >>> 0;
  }
  function dims(w, h, mime) {
    if (!(w >= 1 && h >= 1 && w <= 4096 && h <= 4096 && w * h <= 16000000)) throw fail(IMG_ERR);
    return { width: w, height: h, mime };
  }
  async function inflateZlib(data) {
    const ds = new DecompressionStream("deflate");
    const out = await new Response(new Blob([data]).stream().pipeThrough(ds)).arrayBuffer();
    return new Uint8Array(out);
  }
  F.inspectImage = async function (b, strict) {
    const len = b.length;
    if (len < 12 || len > 12582912) throw fail(IMG_ERR);
    if (b[0] === 0x89 && ascii(b, 1, 3) === "PNG" && b[4] === 13 && b[5] === 10 && b[6] === 26 && b[7] === 10) {
      let pos = 8, w = 0, h = 0, bpp = 3, first = true, ended = false, idat = [], idatLen = 0;
      while (pos + 12 <= len) {
        const n = u32be(b, pos);
        if (n > 12582912 || pos + 12 + n > len) throw fail(IMG_ERR);
        const type = ascii(b, pos + 4, 4);
        if (!/^[A-Za-z]{2}[A-Z][A-Za-z]$/.test(type)) throw fail(IMG_ERR);
        if (strict && type[0] === type[0].toUpperCase() && !["IHDR", "IDAT", "IEND"].includes(type)) throw fail(IMG_ERR);
        if (crc32(b, pos + 4, pos + 8 + n) !== u32be(b, pos + 8 + n)) throw fail(IMG_ERR);
        if (first) {
          if (type !== "IHDR" || n !== 13) throw fail(IMG_ERR);
          w = u32be(b, pos + 8); h = u32be(b, pos + 12);
          if (b[pos + 18] !== 0 || b[pos + 19] !== 0 || b[pos + 20] > 1) throw fail(IMG_ERR);
          if (strict && (b[pos + 16] !== 8 || !(b[pos + 17] === 2 || b[pos + 17] === 6) || b[pos + 20] !== 0)) throw fail(IMG_ERR);
          bpp = b[pos + 17] === 6 ? 4 : 3;
          first = false;
        } else if (type === "IHDR") throw fail(IMG_ERR);
        if (type === "IDAT") { idat.push(b.subarray(pos + 8, pos + 8 + n)); idatLen += n; }
        if (strict && (type === "acTL" || type === "fcTL" || type === "fdAT")) throw fail(IMG_ERR);
        if (type === "IEND") { if (n !== 0 || pos + 12 !== len || !idatLen) throw fail(IMG_ERR); ended = true; break; }
        pos += 12 + n;
      }
      if (!ended) throw fail(IMG_ERR);
      const r = dims(w, h, "image/png");
      if (strict) {
        let raw;
        try { raw = await inflateZlib(new Blob(idat)); } catch (e) { throw fail(IMG_ERR); }
        const stride = w * bpp + 1;
        if (raw.length !== h * stride) throw fail(IMG_ERR);
        for (let y = 0; y < h; y++) if (raw[y * stride] > 4) throw fail(IMG_ERR);
      }
      return r;
    }
    if (strict) throw fail("Artwork edits must be PNG images.");
    if (b[0] === 0xff && b[1] === 0xd8) {
      let pos = 2;
      while (pos + 4 <= len) {
        if (b[pos] !== 0xff) break;
        while (pos < len && b[pos] === 0xff) pos++;
        const mpos = pos, m = b[pos++];
        if (m === 0xd9 || m === 0xda) break;
        if (m === 0x01 || (m >= 0xd0 && m <= 0xd7)) continue;
        if (pos + 2 > len) break;
        const seg = u16be(b, pos);
        if (seg < 2) break;
        if ([0xc0, 0xc1, 0xc2, 0xc3, 0xc5, 0xc6, 0xc7, 0xc9, 0xca, 0xcb, 0xcd, 0xce, 0xcf].includes(m)) {
          if (seg < 8 || mpos + 8 > len) break;
          return dims(u16be(b, mpos + 6), u16be(b, mpos + 4), "image/jpeg");
        }
        pos += seg;
        if (pos > len) break;
      }
      throw fail(IMG_ERR);
    }
    if ((ascii(b, 0, 6) === "GIF87a" || ascii(b, 0, 6) === "GIF89a") && len >= 13) return dims(u16le(b, 6), u16le(b, 8), "image/gif");
    if (ascii(b, 0, 4) === "RIFF" && ascii(b, 8, 4) === "WEBP" && u32le(b, 4) + 8 === len) {
      let pos = 12;
      while (pos + 8 <= len) {
        const id = ascii(b, pos, 4), size = u32le(b, pos + 4);
        if (pos + 8 + size > len) break;
        if (id === "VP8X" && size >= 10) return dims((b[pos + 12] | (b[pos + 13] << 8) | (b[pos + 14] << 16)) + 1, (b[pos + 15] | (b[pos + 16] << 8) | (b[pos + 17] << 16)) + 1, "image/webp");
        if (id === "VP8L" && size >= 5 && b[pos + 8] === 0x2f) { const v = u32le(b, pos + 9); return dims((v & 0x3fff) + 1, ((v >>> 14) & 0x3fff) + 1, "image/webp"); }
        if (id === "VP8 " && size >= 10 && b[pos + 11] === 0x9d && b[pos + 12] === 0x01 && b[pos + 13] === 0x2a) return dims(u16le(b, pos + 14) & 0x3fff, u16le(b, pos + 16) & 0x3fff, "image/webp");
        pos = pos + 8 + size + (size & 1);
      }
      throw fail(IMG_ERR);
    }
    if (b[0] === 0x42 && b[1] === 0x4d && len >= 26) {
      const hdr = u32le(b, 14);
      if (hdr === 12) return dims(u16le(b, 18), u16le(b, 20), "image/bmp");
      if (hdr >= 40 && len >= 54) { const dv = new DataView(b.buffer, b.byteOffset); return dims(dv.getInt32(18, true), Math.abs(dv.getInt32(22, true)), "image/bmp"); }
    }
    throw fail(IMG_ERR);
  };

  // ---------------------------------------------------------------- LWF
  const LWF_ERR = "Choose a complete, uncompressed supported LWF animation up to 12 MB.";
  F.LWF_ERR = LWF_ERR;
  F.inspectLwf = function (b) {
    const len = b.length;
    if (len < 324 || len > 12582912 || !(b[0] === 0x4c && b[1] === 0x57 && b[2] === 0x46 && b[3] === 0)) throw fail(LWF_ERR);
    const ver = (b[4] << 16) | (b[5] << 8) | b[6];
    if (![0x121010, 0x131211, 0x141211].includes(ver)) throw fail(LWF_ERR);
    const H = ver === 0x141211 ? 332 : 324;
    const word = (o) => u32le(b, o);
    if (len < H || (b[7] & 4) !== 0 || word(H - 4) !== len) throw fail(LWF_ERR);
    const w = word(8), h = word(12), fps = word(16);
    if (!(w >= 1 && w <= 16384 && h >= 1 && h <= 16384 && fps >= 1 && fps <= 240)) throw fail(LWF_ERR);
    let prev = H;
    for (let o = 32; o < H - 4; o += 8) {
      const off = word(o), cnt = word(o + 4);
      if (off || cnt) { if (off < prev || off > len || cnt > len - off) throw fail(LWF_ERR); prev = off; }
    }
    if (!(word(20) < word(H - 24) && word(24) < word(H - 8))) throw fail(LWF_ERR);
    return { mime: "application/octet-stream", width: w, height: h };
  };

  // ---------------------------------------------------------------- CRI @UTF table
  const WIDTH = [1, 1, 2, 2, 4, 4, 8, 8, 4, 8, 4, 8];
  const sjis = (() => { try { return new TextDecoder("shift_jis", { fatal: true }); } catch (e) { return null; } })();
  F.utf = function (input, maxRows) {
    let b = input;
    if (!(b.length >= 4 && ascii(b, 0, 4) === "@UTF")) {
      b = new Uint8Array(input);
      let k = 0x5f;
      for (let i = 0; i < b.length; i++) { b[i] ^= k; k = (k * 0x4115) & 0xff; }
    }
    if (b.length < 32 || ascii(b, 0, 4) !== "@UTF") throw fail("CPK: Unsupported table signature");
    const length = u32be(b, 4) + 8;
    if (length > b.length) throw fail("CPK: Truncated or invalid table");
    const rows = u32be(b, 8) + 8, strings = u32be(b, 12) + 8, data = u32be(b, 16) + 8;
    const ncols = u16be(b, 24), rowWidth = u16be(b, 26), nrows = u32be(b, 28);
    if (ncols > 512 || nrows > (maxRows || 10000)) throw fail("CPK: Truncated or invalid table size");
    if (!(rows >= 32 && strings >= rows && data >= strings && data <= length)) throw fail("CPK: Invalid table layout");
    if (rows + rowWidth * nrows > strings) throw fail("CPK: Truncated or invalid UTF rows");
    const dv = new DataView(b.buffer, b.byteOffset, b.byteLength);
    const str = (off) => {
      const s = strings + off;
      if (off < 0 || s >= data) throw fail("CPK: Truncated or invalid UTF string");
      let e = s; while (e < data && b[e] !== 0) e++;
      if (e >= data) throw fail("CPK: Unterminated UTF string");
      const bytes = b.subarray(s, e);
      try { return new TextDecoder("utf-8", { fatal: true }).decode(bytes); }
      catch (x) { if (sjis) try { return sjis.decode(bytes); } catch (y) {} throw fail("CPK: Unsupported filename encoding"); }
    };
    const read = (type, o) => {
      if (o + WIDTH[type] > length) throw fail("CPK: Truncated or invalid UTF value");
      switch (type) {
        case 0: return b[o]; case 1: return dv.getInt8(o); case 2: return dv.getUint16(o); case 3: return dv.getInt16(o);
        case 4: return dv.getUint32(o); case 5: return dv.getInt32(o);
        case 6: { const v = dv.getBigUint64(o); if (v > 9007199254740991n) throw fail("CPK: 64-bit value exceeds safe range"); return Number(v); }
        case 7: { const v = dv.getBigInt64(o); if (v > 9007199254740991n || v < -9007199254740991n) throw fail("CPK: 64-bit value exceeds safe range"); return Number(v); }
        case 8: return dv.getFloat32(o); case 9: return dv.getFloat64(o);
        case 10: return str(dv.getUint32(o));
        case 11: { const off = dv.getUint32(o), size = dv.getUint32(o + 4); if (data + off + size > length) throw fail("CPK: Truncated or invalid UTF bytes"); return b.subarray(data + off, data + off + size); }
      }
    };
    const cols = []; let pos = 32, perRow = 0;
    for (let c = 0; c < ncols; c++) {
      if (pos + 5 > rows) throw fail("CPK: Truncated or invalid UTF columns");
      const flags = b[pos], type = flags & 0x0f, storage = flags & 0xf0, name = str(u32be(b, pos + 1));
      pos += 5;
      if (type >= 12 || ![0x10, 0x30, 0x50].includes(storage)) throw fail("CPK: Unsupported UTF storage");
      if (cols.some((x) => x.name === name)) throw fail("CPK: Duplicate UTF column");
      const col = { name, type, storage };
      if (storage === 0x30) { col.value = read(type, pos); pos += WIDTH[type]; }
      if (storage === 0x50) perRow += WIDTH[type];
      cols.push(col);
    }
    if (perRow > rowWidth) throw fail("CPK: Truncated or invalid UTF rows");
    const out = [];
    for (let r = 0; r < nrows; r++) {
      let o = rows + r * rowWidth; const row = {};
      for (const c of cols) {
        if (c.storage === 0x10) row[c.name] = 0;
        else if (c.storage === 0x30) row[c.name] = c.value;
        else { row[c.name] = read(c.type, o); o += WIDTH[c.type]; }
      }
      out.push(row);
    }
    return out;
  };

  // ---------------------------------------------------------------- CPK archive (reads from a Blob/File)
  F.cpkEntries = async function (blob) {
    const size = blob.size;
    const slice = async (o, n) => new Uint8Array(await blob.slice(o, o + n).arrayBuffer());
    async function packet(o, tag) {
      const h = await slice(o, 16);
      if (h.length < 16 || ascii(h, 0, 4) !== tag) throw fail("CPK: Invalid " + tag.trim() + " packet");
      const n = Number(new DataView(h.buffer).getBigUint64(8, true));
      if (n > 32 * MiB) throw fail("CPK: Metadata exceeds limit");
      if (o + 16 + n > size) throw fail("CPK: Truncated or invalid metadata");
      return F.utf(await slice(o + 16, n));
    }
    const head = await packet(0, "CPK ");
    if (head.length !== 1) throw fail("CPK: Invalid archive header");
    const num = (k) => { const v = head[0][k]; if (typeof v !== "number" || v < 0) throw fail("CPK: Invalid " + k); return v; };
    const toc = num("TocOffset"), content = num("ContentOffset"), files = num("Files");
    if (toc === 0) throw fail("CPK: Archive has no named TOC; an external name map is required");
    const rows = await packet(toc, "TOC ");
    if (rows.length !== files) throw fail("CPK: Archive file count does not match TOC");
    const base = Math.min(content, toc), seen = new Set(), out = []; let total = 0;
    for (const r of rows) {
      if (typeof r.FileName !== "string" || !(typeof r.DirName === "string" || r.DirName === 0)) throw fail("CPK: Invalid file name");
      const dir = r.DirName === 0 || r.DirName === "" || r.DirName === "<NULL>" ? "" : r.DirName;
      const path = dir ? dir + "/" + r.FileName : r.FileName;
      if (!cpkSafe(path)) throw fail("CPK: Unsafe entry path");
      const key = path.normalize("NFC").toLowerCase();
      if (seen.has(key)) throw fail("CPK: Duplicate entry path");
      seen.add(key);
      if (r.FileSize > 160 * MiB || r.ExtractSize > 160 * MiB || (total += r.ExtractSize) > 2147483648) throw fail("CPK: Extracted data exceeds limit");
      const offset = r.FileOffset + base;
      if (!Number.isSafeInteger(offset)) throw fail("CPK: Invalid file offset");
      if (offset + r.FileSize > size) throw fail("CPK: Truncated or invalid file contents");
      if (offset < content) throw fail("CPK: File overlaps archive metadata");
      out.push({ path, offset, storedSize: r.FileSize, size: r.ExtractSize });
    }
    return out;
  };
  function cpkSafe(s) {
    if (!s || s.length > 500 || s.startsWith("/") || /[\\:\x00-\x1f\x7f]/.test(s)) return false;
    return s.split("/").every((x) => x && x !== "." && x !== "..");
  }
  F.cpkRead = async function (blob, e) {
    const bytes = new Uint8Array(await blob.slice(e.offset, e.offset + e.storedSize).arrayBuffer());
    if (bytes.length >= 8 && ascii(bytes, 0, 8) === "CRILAYLA") return F.crilayla(bytes, e.size);
    if (e.size !== e.storedSize) throw fail("CPK: Unsupported compression format");
    return bytes;
  };
  F.crilayla = function (bytes, expected) {
    const len = bytes.length;
    if (len < 272 || ascii(bytes, 0, 8) !== "CRILAYLA") throw fail("CPK: Unsupported compressed entry");
    const uncompressed = u32le(bytes, 8), hdrOff = u32le(bytes, 12), total = uncompressed + 256;
    if (total > 160 * MiB || total !== expected) throw fail("CPK: Compressed output size does not match file table");
    if (!(16 + hdrOff + 256 <= len && 272 + hdrOff === len)) throw fail("CPK: Unexpected trailing CRILAYLA data");
    const out = new Uint8Array(total);
    out.set(bytes.subarray(16 + hdrOff, 16 + hdrOff + 256), 0);
    let src = hdrOff + 15, pool = 0, cache = 0;
    const take = (n) => {
      let v = 0;
      while (n > 0) {
        if (pool === 0) { if (src < 16) throw fail("CPK: Truncated CRILAYLA bit stream"); cache = bytes[src--]; pool = 8; }
        const k = Math.min(n, pool);
        v = (v << k) | ((cache >> (pool - k)) & ((1 << k) - 1));
        pool -= k; n -= k;
      }
      return v;
    };
    let i = total - 1;
    while (i >= 256) {
      if (take(1) === 0) { out[i--] = take(8); continue; }
      const offset = take(13) + 3;
      let length = 3, all = true;
      for (const lvl of [2, 3, 5, 8]) { const b = take(lvl); length += b; if (b !== (1 << lvl) - 1) { all = false; break; } }
      if (all) { let b; do { b = take(8); length += b; if (length > i - 255) throw fail("CPK: CRILAYLA match exceeds output"); } while (b === 255); }
      if (length > i - 255 || i + offset >= total) throw fail("CPK: Invalid CRILAYLA back-reference");
      while (length-- > 0) { out[i] = out[i + offset]; i--; }
    }
    return out;
  };

  // ---------------------------------------------------------------- authored USM (MovieStorage.inspect)
  F.inspectUsm = async function (blob) {
    const M = (m) => fail("Movie: " + m);
    const size = blob.size;
    if (size < 2048 || size > 100663296) throw M("Choose a complete authored movie up to 96 MB.");
    const all = new Uint8Array(await blob.arrayBuffer());
    const HEADER_END = "#HEADER END     ===============\0", META_END = "#METADATA END   ===============\0", CONTENTS_END = "#CONTENTS END   ===============\0";
    let pos = 0, packets = 0, dir = null, video = null, audio = null, seek = null;
    const v = { marked: false, metaEnd: false, ended: false, frames: 0, bytes: 0, keys: [] };
    const a = { marked: false, ended: false, endBlock: false, header: null, blocks: 0, bytes: 0, hlen: 0 };
    while (pos < size) {
      if (++packets > 70000) throw M("The movie contains too many packets.");
      if (pos + 32 > size) throw M("The movie contains a truncated or oversized packet.");
      const sig = ascii(all, pos, 4), csize = u32be(all, pos + 4) + 8, hdr = u16be(all, pos + 8) + 8, pad = u16be(all, pos + 10), type = all[pos + 15];
      if (hdr !== 32 || all[pos + 12] || all[pos + 13] || all[pos + 14] || type > 3 || csize < 32 || csize % 32 || csize - 32 - pad < 0) throw M("Invalid authored movie packet.");
      if (pos + csize > size) throw M("Invalid authored movie packet.");
      const payloadLen = csize - 32 - pad;
      if (payloadLen > MiB + 64) throw M("The movie contains a truncated or oversized packet.");
      const p = all.subarray(pos + 32, pos + 32 + payloadLen);
      if (pos === 0) {
        if (sig !== "CRID" || type !== 1 || csize !== 2048) throw M("The movie directory is missing.");
        let rows; try { rows = F.utf(p, 3); } catch (e) { throw M("Invalid authored movie metadata."); }
        if (!(rows.length === 2 || rows.length === 3) || rows[0].filesize !== size || rows[0].stmid !== 0 || rows[1].stmid !== 0x40534656 || (rows[2] && rows[2].stmid !== 0x40534641)) throw M("Invalid authored movie directory.");
        dir = rows;
      } else {
        if (sig !== "@SFV" && sig !== "@SFA") throw M("Unsupported movie stream.");
        const isV = sig === "@SFV";
        if (!isV && dir.length !== 3) throw M("Unsupported movie stream.");
        if (type === 1) {
          if (payloadLen > 65536) throw M("Movie metadata is too large.");
          let rows; try { rows = F.utf(p, 1); } catch (e) { throw M("Invalid stream metadata."); }
          if (rows.length !== 1) throw M("Invalid stream metadata.");
          const r = rows[0];
          if (isV) {
            if (video || v.frames) throw M("Unsupported VP9 movie metadata.");
            const ok = r.mpeg_codec === 9 && r.metadata_count === 1 && r.metadata_size >= 32 && r.metadata_size <= MiB && r.width >= 1 && r.height >= 1 && r.width <= 4096 && r.height <= 4096 &&
              r.width * r.height <= 16777216 && r.total_frames >= 1 && r.total_frames <= 10000 && r.framerate_d >= 1 && r.framerate_n / r.framerate_d >= 1 && r.framerate_n / r.framerate_d <= 120;
            if (!ok) throw M("Unsupported VP9 movie metadata.");
            video = r;
          } else {
            if (audio || a.bytes) throw M("Unsupported ADX movie metadata.");
            if (!(r.audio_codec === 2 && r.metadata_count === 0 && r.metadata_size === 0 && r.sampling_rate === 48000 && r.num_channels === 2 && r.total_samples >= 1)) throw M("Unsupported ADX movie metadata.");
            audio = r;
          }
        } else if (type === 3) {
          if (!isV || !video || v.frames || seek || video.metadata_size !== csize || payloadLen > MiB) throw M("Invalid movie seek metadata.");
          try { seek = F.utf(p, 10000); } catch (e) { throw M("Invalid movie seek metadata."); }
        } else if (type === 2) {
          if (payloadLen > 64) throw M("Invalid movie marker.");
          const t = ascii(p, 0, p.length);
          if (![HEADER_END, META_END, CONTENTS_END].includes(t)) throw M("Unsupported movie marker.");
          if (t === HEADER_END) {
            if (isV) { if (!video || v.marked || v.frames) throw M("Invalid video header marker."); v.marked = true; }
            else { if (!audio || a.marked || a.bytes) throw M("Invalid audio header marker."); a.marked = true; }
          } else if (t === META_END) {
            if (!isV || !seek || !seek.length || v.metaEnd || v.frames) throw M("Invalid seek marker."); v.metaEnd = true;
          } else if (isV) { if (!v.frames || v.ended) throw M("Invalid video end marker."); v.ended = true; }
          else { if (!a.endBlock || a.ended) throw M("Invalid audio end marker."); a.ended = true; }
        } else {
          if (isV) {
            if (!video || !v.marked || !v.metaEnd || v.ended || payloadLen < 13) throw M("Incomplete VP9 packet.");
            let fo = 0;
            if (v.frames === 0) {
              if (payloadLen < 45) throw M("Incomplete VP9 packet.");
              if (ascii(p, 0, 4) !== "DKIF" || u16le(p, 4) !== 0 || u16le(p, 6) !== 32 || ascii(p, 8, 4) !== "VP90" || u16le(p, 12) !== video.width || u16le(p, 14) !== video.height) throw M("Unsupported IVF movie header.");
              if (u32le(p, 16) !== video.framerate_n || u32le(p, 20) !== video.framerate_d || u32le(p, 24) !== video.total_frames) throw M("Movie frame timing differs from its metadata.");
              fo = 32;
            }
            const fsz = u32le(p, fo), pts = u32le(p, fo + 4) + u32le(p, fo + 8) * 4294967296;
            const b0 = p[fo + 12];
            if (fsz < 1 || pts !== v.frames || fsz + 12 + fo !== payloadLen || (b0 >> 6) !== 2 || (b0 & 0x30) !== 0 || (v.frames === 0 && (b0 & 0x0c) !== 0)) throw M("Invalid authored VP9 frame.");
            v.keys.push({ offset: pos, key: (b0 & 0x0c) === 0 });
            v.bytes += payloadLen; v.frames++;
          } else {
            if (!audio || !a.marked || a.ended || a.endBlock || payloadLen < 1) throw M("Incomplete ADX packet.");
            if (!a.header) {
              if (payloadLen < 24 || u16be(p, 0) !== 0x8000) throw M("Invalid ADX header.");
              const hlen = u16be(p, 2) + 4;
              const ok = hlen === payloadLen && hlen <= 4096 && p[4] === 3 && p[5] === 0x12 && p[6] === 4 && p[7] === 2 && u32be(p, 8) === 48000 && u32be(p, 12) === audio.total_samples &&
                (p[18] === 3 || p[18] === 4) && p[19] === 0 && ascii(p, hlen - 6, 6) === "(c)CRI";
              if (!ok) throw M("Unsupported plain stereo ADX header.");
              a.header = true; a.hlen = hlen;
            } else if (payloadLen === 18 && u16be(p, 0) === 0x8001 && u16be(p, 2) === 14) a.endBlock = true;
            else { if (payloadLen % 36) throw M("ADX audio ends inside a sample block."); a.blocks += payloadLen / 36; }
            a.bytes += payloadLen;
          }
        }
      }
      pos += csize;
    }
    if (!video || !v.ended || v.frames !== video.total_frames || v.bytes !== dir[1].filesize || !seek || !seek.length) throw M("The movie ends before its declared video content.");
    if (seek[0].ofs_frmid !== 0) throw M("The first movie seek must point to its first frame.");
    for (const s of seek) {
      const k = v.keys[s.ofs_frmid];
      if (!(s.ofs_frmid >= 0 && s.ofs_frmid < v.frames) || !k || !k.key || k.offset !== s.ofs_byte) throw M("Movie seek positions do not match its frames.");
    }
    if (dir.length === 3) {
      const n = video.framerate_n, d = video.framerate_d;
      const ok = audio && a.header && a.ended && a.endBlock && a.blocks === Math.ceil(audio.total_samples / 32) && a.bytes === a.hlen + a.blocks * 36 + 18 && a.bytes === dir[2].filesize &&
        Math.abs(audio.total_samples / 48000 - (v.frames * d) / n) <= d / n + 1 / 48000;
      if (!ok) throw M("The movie ends before its declared audio content.");
    }
    return { width: video.width, height: video.height, frames: v.frames, rate: { n: video.framerate_n, d: video.framerate_d }, preservedAudio: dir.length === 3 };
  };
})();
