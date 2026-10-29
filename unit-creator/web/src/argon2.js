/* Argon2id (RFC 9106, version 0x13) and BLAKE2b in plain JavaScript, for the web version's
 * .eclp export/import. Same parameters as the Android app (EclpCodec.derive): t=3, m=64 MiB, p=4,
 * 32-byte output. Runs in a worker (argon2-worker.js) so the page stays responsive.
 * Works in browsers, workers and Node (module.exports for tests). */
(function (root) {
  "use strict";
  // ---------------------------------------------------------------- BLAKE2b (64-bit words as 32-bit pairs)
  const IV = new Uint32Array([0xf3bcc908, 0x6a09e667, 0x84caa73b, 0xbb67ae85, 0xfe94f82b, 0x3c6ef372, 0x5f1d36f1, 0xa54ff53a, 0xade682d1, 0x510e527f, 0x2b3e6c1f, 0x9b05688c, 0xfb41bd6b, 0x1f83d9ab, 0x137e2179, 0x5be0cd19]);
  const SIGMA = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3, 11, 8, 12, 0, 5, 2, 15, 13, 10, 14, 3, 6, 7, 1, 9, 4, 7, 9, 3, 1, 13, 12, 11, 14, 2, 6, 5, 10, 4, 0, 15, 8, 9, 0, 5, 7, 2, 4, 10, 15, 14, 1, 11, 12, 6, 8, 3, 13, 2, 12, 6, 10, 0, 11, 8, 3, 4, 13, 7, 5, 15, 14, 1, 9, 12, 5, 1, 15, 14, 13, 4, 10, 0, 7, 6, 3, 9, 2, 8, 11, 13, 11, 7, 14, 12, 1, 3, 9, 5, 0, 15, 4, 8, 6, 2, 10, 6, 15, 14, 9, 11, 3, 0, 8, 12, 2, 13, 7, 1, 4, 10, 5, 10, 2, 8, 4, 7, 6, 1, 5, 15, 11, 9, 14, 3, 12, 13, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3];
  const v = new Uint32Array(32), m = new Uint32Array(32);
  function add64(a, b) { const lo = v[a] + v[b]; let hi = v[a + 1] + v[b + 1]; if (lo >= 0x100000000) hi++; v[a] = lo; v[a + 1] = hi; }
  function add64c(a, lo0, hi0) { const lo = v[a] + lo0; let hi = v[a + 1] + hi0; if (lo >= 0x100000000) hi++; v[a] = lo; v[a + 1] = hi; }
  function g(a, b, c, d, ix, iy) {
    add64(a, b); add64c(a, m[ix], m[ix + 1]);
    let xl = v[d] ^ v[a], xh = v[d + 1] ^ v[a + 1]; v[d] = xh; v[d + 1] = xl; // rotr 32
    add64(c, d);
    xl = v[b] ^ v[c]; xh = v[b + 1] ^ v[c + 1]; v[b] = (xl >>> 24) ^ (xh << 8); v[b + 1] = (xh >>> 24) ^ (xl << 8); // rotr 24
    add64(a, b); add64c(a, m[iy], m[iy + 1]);
    xl = v[d] ^ v[a]; xh = v[d + 1] ^ v[a + 1]; v[d] = (xl >>> 16) ^ (xh << 16); v[d + 1] = (xh >>> 16) ^ (xl << 16); // rotr 16
    add64(c, d);
    xl = v[b] ^ v[c]; xh = v[b + 1] ^ v[c + 1]; v[b] = (xh >>> 31) ^ (xl << 1); v[b + 1] = (xl >>> 31) ^ (xh << 1); // rotr 63
  }
  function compress(h, block, t, last) {
    for (let i = 0; i < 16; i++) { v[i] = h[i]; v[i + 16] = IV[i]; }
    v[24] ^= t; v[25] ^= Math.floor(t / 0x100000000);
    if (last) { v[28] = ~v[28]; v[29] = ~v[29]; }
    for (let i = 0; i < 32; i++) m[i] = block[i * 4] | (block[i * 4 + 1] << 8) | (block[i * 4 + 2] << 16) | (block[i * 4 + 3] << 24);
    for (let r = 0; r < 12; r++) {
      const s = r * 16;
      g(0, 8, 16, 24, SIGMA[s] * 2, SIGMA[s + 1] * 2); g(2, 10, 18, 26, SIGMA[s + 2] * 2, SIGMA[s + 3] * 2);
      g(4, 12, 20, 28, SIGMA[s + 4] * 2, SIGMA[s + 5] * 2); g(6, 14, 22, 30, SIGMA[s + 6] * 2, SIGMA[s + 7] * 2);
      g(0, 10, 20, 30, SIGMA[s + 8] * 2, SIGMA[s + 9] * 2); g(2, 12, 22, 24, SIGMA[s + 10] * 2, SIGMA[s + 11] * 2);
      g(4, 14, 16, 26, SIGMA[s + 12] * 2, SIGMA[s + 13] * 2); g(6, 8, 18, 28, SIGMA[s + 14] * 2, SIGMA[s + 15] * 2);
    }
    for (let i = 0; i < 16; i++) h[i] ^= v[i] ^ v[i + 16];
  }
  /** BLAKE2b with an output of `outLen` bytes (1–64), no key. */
  function blake2b(input, outLen) {
    const h = new Uint32Array(IV);
    h[0] ^= 0x01010000 ^ outLen;
    const block = new Uint8Array(128);
    let t = 0, pos = 0;
    const n = input.length;
    // all full blocks except the last one
    while (n - pos > 128) { block.set(input.subarray(pos, pos + 128)); t += 128; compress(h, block, t, false); pos += 128; }
    block.fill(0); block.set(input.subarray(pos)); t += n - pos; compress(h, block, t, true);
    const out = new Uint8Array(outLen);
    for (let i = 0; i < outLen; i++) out[i] = h[i >> 2] >>> (8 * (i & 3));
    return out;
  }
  const le32 = (x) => new Uint8Array([x & 255, (x >>> 8) & 255, (x >>> 16) & 255, (x >>> 24) & 255]);
  function concat(parts) { let n = 0; for (const p of parts) n += p.length; const out = new Uint8Array(n); let o = 0; for (const p of parts) { out.set(p, o); o += p.length; } return out; }
  /** H' (variable-length hash) from RFC 9106 section 3.3. */
  function hprime(x, outLen) {
    const input = concat([le32(outLen), x]);
    if (outLen <= 64) return blake2b(input, outLen);
    const r = Math.ceil(outLen / 32) - 2, out = new Uint8Array(outLen);
    let vv = blake2b(input, 64); out.set(vv.subarray(0, 32), 0);
    for (let i = 1; i < r; i++) { vv = blake2b(vv, 64); out.set(vv.subarray(0, 32), i * 32); }
    out.set(blake2b(vv, outLen - 32 * r), r * 32);
    return out;
  }

  // ---------------------------------------------------------------- Argon2 block compression (BlaMka)
  // A block is 128 64-bit words = 256 Uint32 (lo, hi).
  const R = new Uint32Array(256), Z = new Uint32Array(256);
  // a = a + b + 2·lo32(a)·lo32(b) on 64-bit (lo, hi) words at Uint32 offsets a and b
  function fma(w, a, b) {
    const al = w[a], bl = w[b];
    const a0 = al & 0xffff, a1 = al >>> 16, b0 = bl & 0xffff, b1 = bl >>> 16;
    const t1 = a1 * b0 + a0 * b1; // < 2^33
    let lo = a0 * b0 + (t1 % 65536) * 65536; // < 2^33
    let hi = a1 * b1 + ((t1 / 65536) | 0) + ((lo / 4294967296) | 0);
    lo = lo % 4294967296;
    // ×2, then add a and b
    lo = lo * 2 + al + bl; // < 2^35
    hi = hi * 2 + w[a + 1] + w[b + 1] + ((lo / 4294967296) | 0);
    w[a] = lo; w[a + 1] = hi; // Uint32Array keeps the low 32 bits
  }
  function gb(w, a, b, c, d) {
    fma(w, a, b);
    let xl = w[d] ^ w[a], xh = w[d + 1] ^ w[a + 1]; w[d] = xh; w[d + 1] = xl;
    fma(w, c, d);
    xl = w[b] ^ w[c]; xh = w[b + 1] ^ w[c + 1]; w[b] = (xl >>> 24) ^ (xh << 8); w[b + 1] = (xh >>> 24) ^ (xl << 8);
    fma(w, a, b);
    xl = w[d] ^ w[a]; xh = w[d + 1] ^ w[a + 1]; w[d] = (xl >>> 16) ^ (xh << 16); w[d + 1] = (xh >>> 16) ^ (xl << 16);
    fma(w, c, d);
    xl = w[b] ^ w[c]; xh = w[b + 1] ^ w[c + 1]; w[b] = (xh >>> 31) ^ (xl << 1); w[b + 1] = (xl >>> 31) ^ (xh << 1);
  }
  // indices are 64-bit word numbers; the Uint32 offset is 2× that
  function perm(w, i0, i1, i2, i3, i4, i5, i6, i7, i8, i9, i10, i11, i12, i13, i14, i15) {
    gb(w, 2 * i0, 2 * i4, 2 * i8, 2 * i12); gb(w, 2 * i1, 2 * i5, 2 * i9, 2 * i13);
    gb(w, 2 * i2, 2 * i6, 2 * i10, 2 * i14); gb(w, 2 * i3, 2 * i7, 2 * i11, 2 * i15);
    gb(w, 2 * i0, 2 * i5, 2 * i10, 2 * i15); gb(w, 2 * i1, 2 * i6, 2 * i11, 2 * i12);
    gb(w, 2 * i2, 2 * i7, 2 * i8, 2 * i13); gb(w, 2 * i3, 2 * i4, 2 * i9, 2 * i14);
  }
  /** out = G(X, Y) (xor-ed into out when `xor`). X, Y, out are offsets (in Uint32) into `mem`. */
  function G(mem, x, y, out, xor) {
    for (let i = 0; i < 256; i++) R[i] = mem[x + i] ^ mem[y + i];
    Z.set(R);
    for (let i = 0; i < 8; i++) { const b = 16 * i; perm(Z, b, b + 1, b + 2, b + 3, b + 4, b + 5, b + 6, b + 7, b + 8, b + 9, b + 10, b + 11, b + 12, b + 13, b + 14, b + 15); }
    for (let i = 0; i < 8; i++) { const b = 2 * i; perm(Z, b, b + 1, b + 16, b + 17, b + 32, b + 33, b + 48, b + 49, b + 64, b + 65, b + 80, b + 81, b + 96, b + 97, b + 112, b + 113); }
    if (xor) for (let i = 0; i < 256; i++) mem[out + i] ^= Z[i] ^ R[i];
    else for (let i = 0; i < 256; i++) mem[out + i] = Z[i] ^ R[i];
  }

  /**
   * Argon2id. password, salt: Uint8Array. Returns a Uint8Array of `tagLength` bytes.
   * progress(fraction) is called now and then.
   */
  function argon2id(password, salt, { iterations = 3, memoryKiB = 65536, parallelism = 4, tagLength = 32, progress = null } = {}) {
    const p = parallelism, t = iterations;
    const mBlocks = 4 * p * Math.floor(memoryKiB / (4 * p));
    const laneLen = mBlocks / p, segLen = laneLen / 4;
    const h0 = blake2b(concat([le32(p), le32(tagLength), le32(memoryKiB), le32(t), le32(0x13), le32(2), le32(password.length), password, le32(salt.length), salt, le32(0), le32(0)]), 64);
    const mem = new Uint32Array(mBlocks * 256);
    const at = (lane, idx) => (lane * laneLen + idx) * 256;
    const put = (bytes, off) => { for (let i = 0; i < 256; i++) mem[off + i] = bytes[i * 4] | (bytes[i * 4 + 1] << 8) | (bytes[i * 4 + 2] << 16) | (bytes[i * 4 + 3] << 24); };
    for (let l = 0; l < p; l++) {
      put(hprime(concat([h0, le32(0), le32(l)]), 1024), at(l, 0));
      put(hprime(concat([h0, le32(1), le32(l)]), 1024), at(l, 1));
    }
    // scratch blocks for data-independent addressing, placed after the memory
    const zero = new Uint32Array(256), input = new Uint32Array(256), addr = new Uint32Array(256), tmp = new Uint32Array(768);
    let done = 0;
    const total = t * mBlocks;
    for (let r = 0; r < t; r++) {
      for (let s = 0; s < 4; s++) {
        for (let l = 0; l < p; l++) {
          const independent = r === 0 && s < 2;
          let counter = 0;
          if (independent) {
            input.fill(0);
            input[0] = r; input[2] = l; input[4] = s; input[6] = mBlocks; input[8] = t; input[10] = 2;
          }
          const nextAddresses = () => {
            counter++; input[12] = counter;
            // addr = G(0, G(0, input))
            tmp.set(zero, 0); tmp.set(input, 256); tmp.fill(0, 512);
            G(tmp, 0, 256, 512, false); // tmp[512..] = G(0, input)
            G(tmp, 0, 512, 256, false); // tmp[256..] = G(0, that)
            addr.set(tmp.subarray(256, 512));
          };
          let start = 0;
          if (r === 0 && s === 0) { start = 2; if (independent) nextAddresses(); }
          for (let i = start; i < segLen; i++) {
            const idx = s * segLen + i, cur = at(l, idx);
            const prev = idx === 0 ? at(l, laneLen - 1) : cur - 256;
            let j1, j2;
            if (independent) {
              if (i % 128 === 0) nextAddresses();
              const k = (i % 128) * 2; j1 = addr[k]; j2 = addr[k + 1];
            } else { j1 = mem[prev]; j2 = mem[prev + 1]; }
            const refLane = r === 0 && s === 0 ? l : j2 % p;
            let w;
            if (r === 0) w = refLane === l ? s * segLen + i - 1 : s * segLen - (i === 0 ? 1 : 0);
            else w = refLane === l ? laneLen - segLen + i - 1 : laneLen - segLen - (i === 0 ? 1 : 0);
            // x = j1² >> 32 and y = (w·x) >> 32, exactly, without BigInt
            const jh = j1 >>> 16, jl = j1 & 0xffff;
            const x = jh * jh + Math.floor((2 * jh * jl * 65536 + jl * jl) / 4294967296);
            const xh = Math.floor(x / 65536), xl = x % 65536;
            const y = Math.floor((w * xh + Math.floor(w * xl / 65536)) / 65536);
            const zz = w - 1 - y;
            const startPos = r === 0 || s === 3 ? 0 : (s + 1) * segLen;
            const ref = at(refLane, (startPos + zz) % laneLen);
            G(mem, prev, ref, cur, r > 0);
            if (progress && (++done & 4095) === 0) progress(done / total);
          }
        }
      }
    }
    // final block: xor of the last block of each lane
    const last = new Uint32Array(256);
    for (let l = 0; l < p; l++) { const o = at(l, laneLen - 1); for (let i = 0; i < 256; i++) last[i] ^= mem[o + i]; }
    const bytes = new Uint8Array(1024);
    for (let i = 0; i < 256; i++) { bytes[i * 4] = last[i] & 255; bytes[i * 4 + 1] = (last[i] >>> 8) & 255; bytes[i * 4 + 2] = (last[i] >>> 16) & 255; bytes[i * 4 + 3] = (last[i] >>> 24) & 255; }
    return hprime(bytes, tagLength);
  }
  const api = { blake2b, argon2id };
  if (typeof module === "object" && module.exports) module.exports = api;
  else root.ForgeArgon2 = api;
})(typeof self !== "undefined" ? self : this);
