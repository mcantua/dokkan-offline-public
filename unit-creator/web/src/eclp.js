/* .eclp files in the browser — the same format the Android app writes (EclpCodec):
 *   "ECLP" | u16 version 1 | u32 metadata length | metadata JSON | 32-byte salt | 12-byte nonce |
 *   AES-256-GCM( u32 count | per file: u16 path length, path, u64 stored length, u64 size, zstd frame )
 * The key is Argon2id(SHA-256("uuid|name|version") ‖ fixed 32 bytes, salt), t=3, m=64 MiB, p=4.
 * Files are stored as zstd frames made of raw blocks (valid zstd, readable by every decoder).
 * Reading supports raw/RLE zstd blocks (files made here); Android-made files use compressed
 * blocks and are imported through their editable .json backup. */
(function (root) {
  "use strict";
  const FIXED = "ef16bc5f9378dc3fef16bc5f937ed622f910b35a9e76b8478b15d32be96dbf4c";
  const enc = new TextEncoder(), dec = new TextDecoder();
  const subtle = () => (root.crypto && root.crypto.subtle) || (typeof require === "function" ? require("crypto").webcrypto.subtle : null);
  const randomBytes = (n) => { const b = new Uint8Array(n); (root.crypto || require("crypto").webcrypto).getRandomValues(b); return b; };

  function safePath(p) {
    if (!p || p.length > 4096 || p.startsWith("/") || p.includes("\\") || /[:\x00-\x1f]/.test(p)) return false;
    return p.split("/").every((part) => part && part !== "." && part !== "..");
  }
  // ---------------------------------------------------------------- zstd frames with raw blocks
  function zstdRaw(bytes) {
    const BLOCK = 131072, blocks = Math.max(1, Math.ceil(bytes.length / BLOCK));
    const out = new Uint8Array(4 + 2 + blocks * 3 + bytes.length);
    out.set([0x28, 0xb5, 0x2f, 0xfd, 0x00, 0x38], 0); // magic, header (no size field), window 128 KiB
    let o = 6;
    for (let i = 0; i < blocks; i++) {
      const part = bytes.subarray(i * BLOCK, Math.min(bytes.length, (i + 1) * BLOCK));
      const header = (part.length << 3) | (0 << 1) | (i === blocks - 1 ? 1 : 0);
      out[o] = header & 255; out[o + 1] = (header >>> 8) & 255; out[o + 2] = (header >>> 16) & 255; o += 3;
      out.set(part, o); o += part.length;
    }
    return out;
  }
  function zstdRead(bytes, expected) {
    if (root.ForgeZstd) return root.ForgeZstd.decompress(bytes, expected);   // full decoder: files made by the Android app
    const out = new Uint8Array(expected);
    let i = 0, o = 0;
    while (i < bytes.length) {
      const magic = bytes[i] | (bytes[i + 1] << 8) | (bytes[i + 2] << 16) | (bytes[i + 3] << 24);
      if ((magic >>> 0) === 0xfd2fb528) {
        i += 4;
        const fhd = bytes[i++], single = (fhd >> 5) & 1, dictFlag = fhd & 3, fcsFlag = fhd >> 6, checksum = (fhd >> 2) & 1;
        if (!single) i++;
        i += [0, 1, 2, 4][dictFlag];
        i += [single ? 1 : 0, 2, 4, 8][fcsFlag];
        for (;;) {
          const h = bytes[i] | (bytes[i + 1] << 8) | (bytes[i + 2] << 16); i += 3;
          const last = h & 1, type = (h >> 1) & 3, size = h >>> 3;
          if (type === 0) { out.set(bytes.subarray(i, i + size), o); o += size; i += size; }
          else if (type === 1) { out.fill(bytes[i], o, o + size); o += size; i += 1; }
          else throw new Error("This .eclp file was made with compression only the Android app can read. On Android, use Save & Play → Save editable backup and import that .json file here.");
          if (last) break;
        }
        if (checksum) i += 4;
      } else if ((magic >>> 0) >= 0x184d2a50 && (magic >>> 0) <= 0x184d2a5f) { // skippable frame
        const n = bytes[i + 4] | (bytes[i + 5] << 8) | (bytes[i + 6] << 16) | (bytes[i + 7] << 24); i += 8 + n;
      } else throw new Error("Unreadable file inside the .eclp.");
    }
    if (o !== expected) throw new Error("A file inside the .eclp has the wrong size.");
    return out;
  }
  // ---------------------------------------------------------------- helpers
  function concat(parts) { let n = 0; for (const p of parts) n += p.length; const out = new Uint8Array(n); let o = 0; for (const p of parts) { out.set(p, o); o += p.length; } return out; }
  const le = (value, size) => { const b = new Uint8Array(size); let v = value; for (let i = 0; i < size; i++) { b[i] = v % 256; v = Math.floor(v / 256); } return b; };
  const readLe = (b, at, size) => { let v = 0; for (let i = size - 1; i >= 0; i--) v = v * 256 + b[at + i]; return v; };
  async function password(uuid, name, version) {
    for (const value of [uuid, name, version]) if (!value || !String(value).trim() || String(value).length > 1000) throw new Error("Patch UUID, name, and version are required (maximum 1,000 characters).");
    const digest = new Uint8Array(await subtle().digest("SHA-256", enc.encode(uuid + "|" + name + "|" + version)));
    const pw = new Uint8Array(64); pw.set(digest, 0);
    for (let i = 0; i < 32; i++) pw[32 + i] = parseInt(FIXED.substr(i * 2, 2), 16);
    return pw;
  }
  /** derive(pw, salt) → 32-byte key. Uses a worker when one is supplied (keeps the page smooth). */
  async function derive(pw, salt, deriveKey) {
    if (deriveKey) return deriveKey(pw, salt);
    const A = root.ForgeArgon2 || (typeof require === "function" ? require("./argon2.js") : null);
    return A.argon2id(pw, salt, { iterations: 3, memoryKiB: 65536, parallelism: 4, tagLength: 32 });
  }
  /**
   * write(entries, { deriveKey }) → Uint8Array. entries: [{path, bytes}] including "metadata.json"
   * (its uuid, name and version lock the file, exactly like the Android app).
   */
  async function write(entries, { deriveKey = null } = {}) {
    const seen = new Set();
    let meta = null;
    const files = [];
    for (const e of entries) {
      if (!safePath(e.path) || seen.has(e.path)) throw new Error("Unsafe or duplicate ECLP path.");
      seen.add(e.path);
      const bytes = typeof e.bytes === "string" ? enc.encode(e.bytes) : e.bytes;
      if (e.path === "metadata.json") meta = JSON.parse(dec.decode(bytes));
      files.push({ path: e.path, bytes });
    }
    if (!meta) throw new Error("Missing ECLP metadata");
    const parts = [le(files.length, 4)];
    for (const f of files) {
      const path = enc.encode(f.path), packed = zstdRaw(f.bytes);
      parts.push(le(path.length, 2), path, le(packed.length, 8), le(f.bytes.length, 8), packed);
    }
    const payload = concat(parts);
    const salt = randomBytes(32), nonce = randomBytes(12);
    const key = await derive(await password(meta.uuid, meta.name, meta.version), salt, deriveKey);
    const aes = await subtle().importKey("raw", key, { name: "AES-GCM" }, false, ["encrypt"]);
    key.fill(0);
    const sealed = new Uint8Array(await subtle().encrypt({ name: "AES-GCM", iv: nonce, tagLength: 128 }, aes, payload));
    const metaBytes = enc.encode(JSON.stringify(meta));
    return concat([enc.encode("ECLP"), le(1, 2), le(metaBytes.length, 4), metaBytes, salt, nonce, sealed]);
  }
  /** read(bytes) → { metadata, entries: [{path, bytes}] } */
  async function read(bytes, { deriveKey = null } = {}) {
    if (dec.decode(bytes.subarray(0, 4)) !== "ECLP" || readLe(bytes, 4, 2) !== 1) throw new Error("This isn't an .eclp file (or it's a newer version).");
    const metaLen = readLe(bytes, 6, 4);
    if (metaLen < 1 || metaLen > 4194304 || bytes.length < 70 + metaLen) throw new Error("Invalid ECLP length");
    const metadata = JSON.parse(dec.decode(bytes.subarray(10, 10 + metaLen)));
    const salt = bytes.slice(10 + metaLen, 42 + metaLen), nonce = bytes.slice(42 + metaLen, 54 + metaLen);
    const key = await derive(await password(metadata.uuid, metadata.name, metadata.version), salt, deriveKey);
    const aes = await subtle().importKey("raw", key, { name: "AES-GCM" }, false, ["decrypt"]);
    let payload;
    try { payload = new Uint8Array(await subtle().decrypt({ name: "AES-GCM", iv: nonce, tagLength: 128 }, aes, bytes.subarray(54 + metaLen))); }
    catch (e) { throw new Error("This .eclp file is damaged or was changed."); }
    const count = readLe(payload, 0, 4), entries = [];
    if (count > 100000) throw new Error("Too many ECLP files");
    let i = 4;
    for (let n = 0; n < count; n++) {
      const pl = readLe(payload, i, 2); i += 2;
      const path = dec.decode(payload.subarray(i, i + pl)); i += pl;
      if (!safePath(path)) throw new Error("Unsafe ECLP path");
      const stored = readLe(payload, i, 8), size = readLe(payload, i + 8, 8); i += 16;
      entries.push({ path, bytes: zstdRead(payload.subarray(i, i + stored), size) }); i += stored;
    }
    return { metadata, entries };
  }
  const api = { write, read, zstdRaw, zstdRead, safePath };
  if (typeof module === "object" && module.exports) module.exports = api;
  else root.ForgeEclp = api;
})(typeof self !== "undefined" ? self : this);
