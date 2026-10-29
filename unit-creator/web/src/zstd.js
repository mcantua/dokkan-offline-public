/* Zstandard decompressor (RFC 8878), written for the Unit Creator so the iPhone app can open .eclp
 * files made by the Android app (zstd level 3). Frames with raw, RLE and compressed blocks;
 * Huffman literals (1 and 4 streams); FSE sequences; repeat offsets. No dictionaries.
 *   ForgeZstd.decompress(bytes, expectedSize) → Uint8Array */
(function (root) {
  "use strict";
  const fail = (m) => { throw new Error("Unreadable file inside the .eclp (" + m + ")."); };
  const hb = (x) => 31 - Math.clz32(x);   // highest set bit

  // bits read forward (FSE table headers), little-endian
  function getBits(src, pos, n) {   // n ≤ 32, absolute bit position
    let v = 0, done = 0;
    while (done < n) {
      const byte = src[(pos + done) >>> 3] | 0, off = (pos + done) & 7, take = Math.min(8 - off, n - done);
      v += ((byte >>> off) & ((1 << take) - 1)) * 2 ** done;
      done += take;
    }
    return v;
  }
  // backward bit stream (Huffman streams, FSE weights, sequences)
  class Back {
    constructor(src, start, end) {
      if (end <= start) fail("empty bit stream");
      const last = src[end - 1];
      if (!last) fail("bad bit stream padding");
      this.src = src; this.start = start;
      this.off = (end - start) * 8 - (8 - hb(last));
    }
    read(n) {
      if (!n) return 0;
      this.off -= n;
      if (this.off >= 0) return getBits(this.src.subarray(this.start), this.off, n);
      const have = this.off + n;
      if (have <= 0) return 0;
      return getBits(this.src.subarray(this.start), 0, have) * 2 ** (-this.off);
    }
  }

  // ---------------------------------------------------------------- FSE
  function readFseHeader(src, pos, maxAcc, maxSym) {
    let bit = pos * 8;
    const acc = getBits(src, bit, 4) + 5; bit += 4;
    if (acc > maxAcc) fail("FSE accuracy");
    let remaining = (1 << acc) + 1, sym = 0;
    const freq = [];
    while (remaining > 1 && sym <= maxSym) {
      const bits = hb(remaining) + 1;
      let val = getBits(src, bit, bits);
      const lowerMask = (1 << (bits - 1)) - 1, threshold = (1 << bits) - 1 - remaining;
      if ((val & lowerMask) < threshold) { val &= lowerMask; bit += bits - 1; }
      else { if (val > lowerMask) val -= threshold; bit += bits; }
      const proba = val - 1;
      remaining -= proba < 0 ? -proba : proba;
      freq[sym++] = proba;
      if (proba === 0) {
        let repeat = getBits(src, bit, 2); bit += 2;
        for (;;) {
          for (let i = 0; i < repeat && sym <= maxSym; i++) freq[sym++] = 0;
          if (repeat === 3) { repeat = getBits(src, bit, 2); bit += 2; } else break;
        }
      }
    }
    if (remaining !== 1) fail("FSE header");
    while (freq.length <= maxSym) freq.push(0);
    return { table: fseTable(freq, acc), next: (bit + 7) >>> 3 };
  }
  function fseTable(freq, acc) {
    const size = 1 << acc, sym = new Uint8Array(size), bits = new Uint8Array(size), base = new Uint16Array(size);
    let high = size;
    const next = new Array(freq.length).fill(0);
    for (let s = 0; s < freq.length; s++) if (freq[s] === -1) { sym[--high] = s; next[s] = 1; }
    const step = (size >>> 1) + (size >>> 3) + 3, mask = size - 1;
    let pos = 0;
    for (let s = 0; s < freq.length; s++) {
      if (freq[s] <= 0) continue;
      next[s] = freq[s];
      for (let i = 0; i < freq[s]; i++) { sym[pos] = s; do pos = (pos + step) & mask; while (pos >= high); }
    }
    if (pos !== 0) fail("FSE table");
    for (let i = 0; i < size; i++) {
      const s = sym[i], d = next[s]++;
      bits[i] = acc - hb(d);
      base[i] = (d << bits[i]) - size;
    }
    return { acc, sym, bits, base };
  }
  function rleTable(s) { return { acc: 0, sym: new Uint8Array([s]), bits: new Uint8Array([0]), base: new Uint16Array([0]) }; }

  // ---------------------------------------------------------------- Huffman
  function huffTable(weights) {   // weights for all but the last symbol
    let sum = 0;
    for (const w of weights) if (w) sum += 1 << (w - 1);
    if (!sum) fail("Huffman weights");
    const maxBits = hb(sum) + 1, left = (1 << maxBits) - sum;
    if (left & (left - 1)) fail("Huffman weights");
    const all = weights.concat([hb(left) + 1]);
    if (maxBits > 11) fail("Huffman depth");
    const size = 1 << maxBits, nb = new Uint8Array(size), sy = new Uint8Array(size);
    const bits = all.map((w) => (w ? maxBits + 1 - w : 0));
    const count = new Array(maxBits + 2).fill(0);
    for (const b of bits) if (b) count[b]++;
    const idx = new Array(maxBits + 2).fill(0);
    idx[maxBits] = 0;
    for (let i = maxBits; i >= 1; i--) { idx[i - 1] = idx[i] + count[i] * (1 << (maxBits - i)); nb.fill(i, idx[i], idx[i - 1]); }
    for (let s = 0; s < bits.length; s++) {
      if (!bits[s]) continue;
      const len = 1 << (maxBits - bits[s]);
      sy.fill(s, idx[bits[s]], idx[bits[s]] + len);
      idx[bits[s]] += len;
    }
    return { maxBits, nb, sy };
  }
  function readHuffTree(src, pos) {
    const head = src[pos];
    let weights = [], next;
    if (head >= 128) {
      const n = head - 127;
      for (let i = 0; i < n; i++) { const b = src[pos + 1 + (i >> 1)]; weights.push(i & 1 ? b & 15 : b >> 4); }
      next = pos + 1 + ((n + 1) >> 1);
    } else {
      const end = pos + 1 + head;
      const { table, next: start } = readFseHeader(src, pos + 1, 6, 255);
      const br = new Back(src, start, end);
      let s1 = br.read(table.acc), s2 = br.read(table.acc);
      const dec = (s) => { const sym = table.sym[s]; return [sym, table.base[s] + br.read(table.bits[s])]; };
      for (;;) {
        let r = dec(s1); weights.push(r[0]); s1 = r[1];
        if (br.off < 0) { weights.push(table.sym[s2]); break; }
        r = dec(s2); weights.push(r[0]); s2 = r[1];
        if (br.off < 0) { weights.push(table.sym[s1]); break; }
        if (weights.length > 255) fail("Huffman weights");
      }
      next = end;
    }
    return { table: huffTable(weights), next };
  }
  function huffStream(src, start, end, t, out, o, n) {
    const br = new Back(src, start, end), mask = (1 << t.maxBits) - 1;
    let state = br.read(t.maxBits);
    for (let i = 0; i < n; i++) {
      out[o + i] = t.sy[state];
      const b = t.nb[state];
      state = ((state << b) + br.read(b)) & mask;
    }
  }

  // ---------------------------------------------------------------- sequences
  const LL_BASE = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 18, 20, 22, 24, 28, 32, 40, 48, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536];
  const LL_BITS = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 3, 3, 4, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];
  const ML_BASE = [], ML_BITS = [];
  for (let i = 0; i < 32; i++) { ML_BASE.push(i + 3); ML_BITS.push(0); }
  [[35, 1], [37, 1], [39, 1], [41, 1], [43, 2], [47, 2], [51, 3], [59, 3], [67, 4], [83, 4], [99, 5], [131, 7], [259, 8], [515, 9], [1027, 10], [2051, 11], [4099, 12], [8195, 13], [16387, 14], [32771, 15], [65539, 16]].forEach(([b, n]) => { ML_BASE.push(b); ML_BITS.push(n); });
  const LL_DEF = fseTable([4, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 2, 1, 1, 1, 1, 1, -1, -1, -1, -1], 6);
  const ML_DEF = fseTable([1, 4, 3, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, -1, -1, -1, -1, -1, -1, -1], 6);
  const OF_DEF = fseTable([1, 1, 1, 1, 1, 1, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, -1, -1, -1, -1, -1], 5);

  function decompress(src, expected) {
    src = src instanceof Uint8Array ? src : new Uint8Array(src);
    let out = new Uint8Array(expected != null ? expected : Math.max(1024, src.length * 4)), o = 0;
    const grow = (n) => { if (o + n <= out.length) return; if (expected != null) fail("size"); let s = out.length * 2; while (s < o + n) s *= 2; const b = new Uint8Array(s); b.set(out.subarray(0, o)); out = b; };
    let i = 0;
    while (i < src.length) {
      const magic = (src[i] | (src[i + 1] << 8) | (src[i + 2] << 16) | (src[i + 3] << 24)) >>> 0;
      if (magic >= 0x184d2a50 && magic <= 0x184d2a5f) { i += 8 + ((src[i + 4] | (src[i + 5] << 8) | (src[i + 6] << 16) | (src[i + 7] << 24)) >>> 0); continue; }
      if (magic !== 0xfd2fb528) fail("frame");
      i += 4;
      const fhd = src[i++], single = (fhd >> 5) & 1, dictFlag = fhd & 3, fcsFlag = fhd >> 6, checksum = (fhd >> 2) & 1;
      if (dictFlag) {
        let id = 0; for (let k = 0; k < [0, 1, 2, 4][dictFlag]; k++) id += src[i + 1 - single + k] * 2 ** (8 * k);
        if (id) fail("dictionary");
      }
      if (!single) i++;
      i += [0, 1, 2, 4][dictFlag];
      i += [single ? 1 : 0, 2, 4, 8][fcsFlag];
      const frameStart = o;
      const rep = [1, 4, 8];
      let huff = null, tLL = null, tOF = null, tML = null;
      for (;;) {
        const h = src[i] | (src[i + 1] << 8) | (src[i + 2] << 16); i += 3;
        const last = h & 1, type = (h >> 1) & 3, size = h >>> 3;
        if (type === 0) { grow(size); out.set(src.subarray(i, i + size), o); o += size; i += size; }
        else if (type === 1) { grow(size); out.fill(src[i], o, o + size); o += size; i += 1; }
        else if (type === 2) {
          const end = i + size;
          // literals
          const b0 = src[i], lt = b0 & 3, sf = (b0 >> 2) & 3;
          let regen, comp = 0, streams = 1, p;
          if (lt < 2) {
            if (sf === 0 || sf === 2) { regen = b0 >> 3; p = i + 1; }
            else if (sf === 1) { regen = (b0 >> 4) + (src[i + 1] << 4); p = i + 2; }
            else { regen = (b0 >> 4) + (src[i + 1] << 4) + (src[i + 2] << 12); p = i + 3; }
          } else {
            const b1 = src[i + 1], b2 = src[i + 2], b3 = src[i + 3], b4 = src[i + 4];
            if (sf < 2) { streams = sf === 0 ? 1 : 4; regen = (b0 >> 4) + ((b1 & 0x3f) << 4); comp = (b1 >> 6) + (b2 << 2); p = i + 3; }
            else if (sf === 2) { streams = 4; regen = (b0 >> 4) + (b1 << 4) + ((b2 & 3) << 12); comp = (b2 >> 2) + (b3 << 6); p = i + 4; }
            else { streams = 4; regen = (b0 >> 4) + (b1 << 4) + ((b2 & 0x3f) << 12); comp = (b2 >> 6) + (b3 << 2) + (b4 << 10); p = i + 5; }
          }
          let lits;
          if (lt === 0) { lits = src.subarray(p, p + regen); p += regen; }
          else if (lt === 1) { lits = new Uint8Array(regen).fill(src[p]); p += 1; }
          else {
            const cend = p + comp;
            let q = p;
            if (lt === 2) { const t = readHuffTree(src, p); huff = t.table; q = t.next; }
            else if (!huff) fail("Huffman table");
            lits = new Uint8Array(regen);
            if (streams === 1) huffStream(src, q, cend, huff, lits, 0, regen);
            else {
              const s1 = src[q] | (src[q + 1] << 8), s2 = src[q + 2] | (src[q + 3] << 8), s3 = src[q + 4] | (src[q + 5] << 8);
              const seg = (regen + 3) >> 2;
              let a = q + 6;
              const ends = [a + s1, a + s1 + s2, a + s1 + s2 + s3, cend];
              let starts = [a, ends[0], ends[1], ends[2]];
              for (let k = 0; k < 4; k++) huffStream(src, starts[k], ends[k], huff, lits, seg * k, k < 3 ? seg : regen - 3 * seg);
            }
            p = cend;
          }
          // sequences
          let nSeq = src[p++];
          if (nSeq >= 128) { if (nSeq < 255) nSeq = ((nSeq - 128) << 8) + src[p++]; else { nSeq = src[p] + (src[p + 1] << 8) + 0x7f00; p += 2; } }
          let litPos = 0;
          if (nSeq > 0) {
            const modes = src[p++];
            const pick = (mode, def, maxAcc, maxSym, prev) => {
              if (mode === 0) return def;
              if (mode === 1) return rleTable(src[p++]);
              if (mode === 2) { const r = readFseHeader(src, p, maxAcc, maxSym); p = r.next; return r.table; }
              if (!prev) fail("repeat table");
              return prev;
            };
            tLL = pick((modes >> 6) & 3, LL_DEF, 9, 35, tLL);
            tOF = pick((modes >> 4) & 3, OF_DEF, 8, 31, tOF);
            tML = pick((modes >> 2) & 3, ML_DEF, 9, 52, tML);
            const br = new Back(src, p, end);
            let sLL = br.read(tLL.acc), sOF = br.read(tOF.acc), sML = br.read(tML.acc);
            for (let n = 0; n < nSeq; n++) {
              const ofCode = tOF.sym[sOF], llCode = tLL.sym[sLL], mlCode = tML.sym[sML];
              if (llCode > 35 || mlCode > 52 || ofCode > 31) fail("sequence code");
              const ofVal = 2 ** ofCode + br.read(ofCode);
              const ml = ML_BASE[mlCode] + br.read(ML_BITS[mlCode]);
              const ll = LL_BASE[llCode] + br.read(LL_BITS[llCode]);
              let off;
              if (ofVal > 3) { off = ofVal - 3; rep[2] = rep[1]; rep[1] = rep[0]; rep[0] = off; }
              else {
                const idx = ll === 0 ? ofVal : ofVal - 1;
                if (idx === 0) off = rep[0];
                else if (idx === 3) { off = rep[0] - 1; if (off <= 0) fail("offset"); rep[2] = rep[1]; rep[1] = rep[0]; rep[0] = off; }
                else { off = rep[idx]; if (idx === 2) rep[2] = rep[1]; rep[1] = rep[0]; rep[0] = off; }
              }
              if (n !== nSeq - 1) {
                sLL = tLL.base[sLL] + br.read(tLL.bits[sLL]);
                sML = tML.base[sML] + br.read(tML.bits[sML]);
                sOF = tOF.base[sOF] + br.read(tOF.bits[sOF]);
              }
              grow(ll + ml);
              if (litPos + ll > lits.length) fail("literals");
              out.set(lits.subarray(litPos, litPos + ll), o); o += ll; litPos += ll;
              if (off > o - frameStart) fail("offset");
              let from = o - off;
              if (off >= ml) { out.copyWithin(o, from, from + ml); o += ml; }
              else for (let k = 0; k < ml; k++) out[o++] = out[from++];
            }
          }
          const rest = lits.length - litPos;
          grow(rest); out.set(lits.subarray(litPos), o); o += rest;
          i = end;
        } else fail("block type");
        if (last) break;
      }
      if (checksum) i += 4;
    }
    if (expected != null && o !== expected) fail("size");
    return expected != null ? out : out.slice(0, o);
  }
  const api = { decompress };
  if (typeof module === "object" && module.exports) module.exports = api;
  else root.ForgeZstd = api;
})(typeof self !== "undefined" ? self : this);
