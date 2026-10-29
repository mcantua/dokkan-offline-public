(function(root, factory) {
  const api = factory();
  if (typeof module === "object" && module.exports) module.exports = api;
  else root.ForgeAudioBank = api;
})(typeof globalThis === "object" ? globalThis : this, () => {
  "use strict";
  const MAX = 160 * 1024 * 1024, MAX_ROWS = 2e4;
  function fail(s) {
    throw Error("Audio bank: " + s);
  }
  function bytes(v) {
    if (v instanceof Uint8Array) return v;
    if (v instanceof ArrayBuffer) return new Uint8Array(v);
    fail("expected bytes");
  }
  function range(o, n, total) {
    if (!Number.isSafeInteger(o) || !Number.isSafeInteger(n) || o < 0 || n < 0 || o > total || n > total - o) fail("truncated or invalid range");
  }
  function view(b) {
    return new DataView(b.buffer, b.byteOffset, b.byteLength);
  }
  function uint(n, label) {
    if (!Number.isSafeInteger(n) || n < 0) fail("invalid " + label);
    return n;
  }
  function utf(input) {
    const b = bytes(input);
    if (b.length > 32 * 1024 * 1024 || b.length < 32 || String.fromCharCode(...b.subarray(0, 4)) !== "@UTF") fail("invalid UTF signature or size");
    const d = view(b), length = d.getUint32(4) + 8;
    range(0, length, b.length);
    const version = d.getUint16(8), rows = d.getUint16(10) + 8, strings = d.getUint32(12) + 8, data = d.getUint32(16) + 8, columns = d.getUint16(24), width = d.getUint16(26), count = d.getUint32(28);
    if (version > 1 || columns > 512 || count > MAX_ROWS || rows < 32 || strings < rows || data < strings || data > length) fail("invalid UTF layout");
    range(rows, width * count, strings);
    const sizes = [1, 1, 2, 2, 4, 4, 8, 8, 4, 8, 4, 8];
    function str(o) {
      const p2 = strings + uint(o, "string");
      range(p2, 1, data);
      let e = p2;
      while (e < data && b[e]) e++;
      if (e === data) fail("unterminated string");
      if (e - p2 > 4096) fail("string too long");
      try {
        return new TextDecoder("utf-8", { fatal: true }).decode(b.subarray(p2, e));
      } catch {
        fail("invalid UTF8 string");
      }
    }
    function value(t, p2, end) {
      range(p2, sizes[t] || 0, end);
      switch (t) {
        case 0:
          return d.getUint8(p2);
        case 1:
          return d.getInt8(p2);
        case 2:
          return d.getUint16(p2);
        case 3:
          return d.getInt16(p2);
        case 4:
          return d.getUint32(p2);
        case 5:
          return d.getInt32(p2);
        case 6: {
          const n = d.getBigUint64(p2);
          if (n > BigInt(Number.MAX_SAFE_INTEGER)) fail("64bit value too large");
          return Number(n);
        }
        case 7: {
          const n = d.getBigInt64(p2);
          if (n < BigInt(Number.MIN_SAFE_INTEGER) || n > BigInt(Number.MAX_SAFE_INTEGER)) fail("64bit value too large");
          return Number(n);
        }
        case 8:
          return d.getFloat32(p2);
        case 9:
          return d.getFloat64(p2);
        case 10:
          return str(d.getUint32(p2));
        case 11: {
          const o = data + d.getUint32(p2), n = d.getUint32(p2 + 4);
          range(o, n, length);
          return b.subarray(o, o + n);
        }
        default:
          fail("unknown column type");
      }
    }
    str(d.getUint32(20));
    let p = 32, rowBytes = 0;
    const defs = [], seen = /* @__PURE__ */ new Set();
    for (let i = 0; i < columns; i++) {
      range(p, 5, rows);
      const flag = b[p], type = flag & 15, storage = flag & 240, name = str(d.getUint32(p + 1));
      p += 5;
      if (!sizes[type] || ![16, 48, 80].includes(storage) || seen.has(name)) fail("invalid column");
      seen.add(name);
      let constant = 0;
      if (storage === 48) {
        constant = value(type, p, rows);
        p += sizes[type];
      }
      if (storage === 80) rowBytes += sizes[type];
      defs.push({ name, type, storage, constant });
    }
    if (rowBytes > width) fail("invalid row width");
    const out = [];
    for (let i = 0; i < count; i++) {
      let q = rows + i * width;
      const r = /* @__PURE__ */ Object.create(null);
      for (const c of defs) {
        r[c.name] = c.storage === 80 ? value(c.type, q, rows + (i + 1) * width) : c.constant;
        if (c.storage === 80) q += sizes[c.type];
      }
      out.push(r);
    }
    return out;
  }
  function awb(input) {
    const b = bytes(input), d = view(b);
    if (b.length < 16 || b.length > MAX || String.fromCharCode(...b.subarray(0, 4)) !== "AFS2") fail("invalid AFS2 bank");
    const offSize = b[5], idSize = b[6], count = d.getUint32(8, true), align = d.getUint16(12, true), subkey = d.getUint16(14, true);
    if (![1, 2, 4, 8].includes(offSize) || ![1, 2, 4].includes(idSize) || count > MAX_ROWS || !align || align > 32768) fail("invalid AFS2 layout");
    range(16, count * idSize + (count + 1) * offSize, b.length);
    function num(p, n) {
      if (n === 1) return b[p];
      if (n === 2) return d.getUint16(p, true);
      if (n === 4) return d.getUint32(p, true);
      const v = d.getBigUint64(p, true);
      if (v > BigInt(Number.MAX_SAFE_INTEGER)) fail("AFS2 offset too large");
      return Number(v);
    }
    const base = 16 + count * idSize, entries = /* @__PURE__ */ new Map();
    let prev = base + (count + 1) * offSize;
    for (let i = 0; i < count; i++) {
      const id = num(16 + i * idSize, idSize), raw = num(base + i * offSize, offSize), end = num(base + (i + 1) * offSize, offSize), start = Math.ceil(raw / align) * align;
      if (raw < prev || end < start || entries.has(id)) fail("invalid AFS2 entry");
      range(start, end - start, b.length);
      entries.set(id, { id, offset: start, size: end - start });
      prev = end;
    }
    return { entries, subkey, extract(id) {
      const e = entries.get(id);
      if (!e) fail("waveform missing from AFS2");
      return b.subarray(e.offset, e.offset + e.size);
    } };
  }
  function commands(value) {
    const b = bytes(value);
    if (b.length > 65536) fail("command list too long");
    const d = view(b), out = [];
    let p = 0;
    while (p < b.length) {
      range(p, 3, b.length);
      const code = d.getUint16(p), size = b[p + 2];
      p += 3;
      range(p, size, b.length);
      out.push({ code, data: b.subarray(p, p + size) });
      p += size;
    }
    return out;
  }
  function inspect(input) {
    const b = bytes(input);
    if (b.length > MAX) fail("ACB exceeds160MiB");
    const heads = utf(b);
    if (heads.length !== 1) fail("expected one ACB header");
    const h = heads[0], cache = /* @__PURE__ */ new Map();
    function table(name) {
      if (!cache.has(name)) cache.set(name, h[name] instanceof Uint8Array && h[name].length ? utf(h[name]) : []);
      return cache.get(name);
    }
    const cues = table("CueTable"), names = /* @__PURE__ */ new Map();
    for (const row2 of table("CueNameTable")) {
      if (typeof row2.CueName === "string") names.set(row2.CueIndex, row2.CueName);
    }
    const ids = /* @__PURE__ */ new Set();
    for (const c of cues) {
      if (ids.has(c.CueId)) fail("duplicate cue ID");
      ids.add(c.CueId);
    }
    function row(name, index) {
      uint(index, "reference index");
      const r = table(name)[index];
      if (!r) fail("missing " + name + " row");
      return r;
    }
    function configuration(r) {
      var _a;
      if (((_a = r.LocalAisacs) == null ? void 0 : _a.length) || r.GlobalAisacNumRefs || r.NumActionTracks || r.ParameterPallet != null && r.ParameterPallet !== 65535) fail("custom AISAC, action tracks or parameter effects need Atom playback");
    }
    function references(type, index, depth, visited) {
      if (depth > 12) fail("cue reference nesting exceeds limit");
      const key = type + ":" + index;
      if (visited.has(key)) fail("cyclic cue reference");
      const next = new Set(visited);
      next.add(key);
      if (type === 1) {
        const w = row("WaveformTable", index);
        return [{ waveform: index, bank: w.Streaming ? "stream" : "memory", id: w.Streaming ? w.StreamAwbId : w.MemoryAwbId, encoding: w.EncodeType, sampleRate: w.SamplingRate, channels: w.NumChannels, samples: w.NumSamples, loop: !!w.LoopFlag }];
      }
      if (type === 2) {
        const s = row("SynthTable", index);
        configuration(s);
        const a = bytes(s.ReferenceItems), v = view(a);
        if (a.length % 4 || a.length > 1024) fail("invalid synth references");
        const result = [];
        const local = atCommands(s.CommandIndex, "SynthCommandTable");
        for (let p = 0; p < a.length; p += 4) {
          const t = v.getUint16(p);
          if (t) result.push(...references(t, v.getUint16(p + 2), depth + 1, next));
        }
        if (s.Type !== 0) fail("random/sequential synth needs Atom playback");
        return result.map((w) => ({ ...w, routingCommands: [...w.routingCommands || [], ...local.map((c) => ({ ...c, scope: "synth", owner: index }))] }));
      }
      if (type === 3) {
        const s = row("SequenceTable", index);
        configuration(s);
        const a = bytes(s.TrackIndex);
        if (s.NumTracks > 128 || s.NumTracks * 2 > a.length) fail("invalid sequence tracks");
        if (s.Type !== 0) fail("random/sequential sequence needs Atom playback");
        if (s.PlaybackRatio !== 100) fail("altered playback ratio needs Atom playback");
        const local = atCommands(s.CommandIndex, "SeqCommandTable");
        const result = [];
        for (let n = 0; n < s.NumTracks; n++) {
          const track = row("TrackTable", view(a).getUint16(n * 2));
          configuration(track);
          const event = row(table("TrackEventTable").length ? "TrackEventTable" : "TrackCommandTable", track.EventIndex);
          for (const c of commands(event.Command)) {
            if (c.code === 2e3 || c.code === 2003) {
              if (c.code === 2e3 && c.data.length !== 4 || c.code === 2003 && (c.data.length !== 6 || c.data[4] || c.data[5])) fail("unsupported noteOn command");
              const v = view(c.data);
              const found = references(v.getUint16(0), v.getUint16(2), depth + 1, next);
              for (const w of found) result.push({ ...w, track: n, routingCommands: [...w.routingCommands || [], ...local.map((c2) => ({ ...c2, scope: "sequence", owner: index }))], trackCommands: track.CommandIndex === 65535 || track.CommandIndex == null ? [] : commands(row("TrackCommandTable", track.CommandIndex).Command), eventCommands: commands(event.Command).filter((c2) => ![0, 2e3, 2003].includes(c2.code)) });
            } else if (c.code !== 0) fail("timed note commands need Atom playback");
          }
        }
        return result;
      }
      fail("unsupported cue reference type " + type);
    }
    function atCommands(index, name) {
      return index === 65535 || index == null ? [] : commands(row(name, index).Command);
    }
    function muted(w) {
      return (w.trackCommands || []).some((c) => c.code === 33 && c.data.length === 1 && c.data[0] === 1);
    }
    function defaults(w) {
      return [...w.routingCommands || [], ...w.trackCommands || []].every((c) => {
        var _a;
        if (c.code === 0) return true;
        if (c.code === 87) return c.data.length === 2 && view(c.data).getUint16(0) <= 100;
        if (c.code === 33) return c.data.length === 1 && c.data[0] === 0;
        if (c.code !== 111 || c.data.length !== 4) return false;
        const d = view(c.data), index = d.getUint16(0), value = d.getUint16(2), name = (_a = table("StringValueTable")[index]) == null ? void 0 : _a.StringValue;
        return index === 0 ? name === "MasterOut" && value === 1e4 : index < 8 && name === "BUS" + index && value === (c.scope === "sequence" ? 0 : 1e4);
      });
    }
    function volumeGain(w) {
      var _a;
      const levels = /* @__PURE__ */ new Map();
      for (const c of [...w.routingCommands || [], ...w.trackCommands || []]) if (c.code === 87) levels.set((c.scope || "track") + ":" + ((_a = c.owner) != null ? _a : 0), Math.fround(view(c.data).getUint16(0) / 100));
      let gain = 1;
      for (const value of levels.values()) gain = Math.fround(gain * value);
      return gain;
    }
    const out = cues.map((c, i) => {
      var _a;
      const item = { id: c.CueId, name: names.get(i) || "", lengthMs: c.Length };
      try {
        item.waves = references(c.ReferenceType, c.ReferenceIndex, 0, /* @__PURE__ */ new Set());
        item.activeWaves = item.waves.filter((w) => !muted(w));
        item.simple = item.activeWaves.length === 1 && defaults(item.activeWaves[0]) && !((_a = item.activeWaves[0].eventCommands) == null ? void 0 : _a.length);
        if (item.simple) item.gain = volumeGain(item.activeWaves[0]);
      } catch (e) {
        item.error = e.message;
        item.waves = [];
        item.simple = false;
      }
      return item;
    });
    return { name: h.Name || "", cues: out, memory: h.AwbFile instanceof Uint8Array && h.AwbFile.length ? awb(h.AwbFile) : null, table, extract(cueId, streamBank) {
      const cue = out.find((c) => c.id === cueId);
      if (!cue) fail("cue not found");
      if (!cue.simple) fail("cue requires Atom timing, mixing or effects: " + (cue.error || cue.name));
      const w = cue.activeWaves[0], bank = w.bank === "stream" ? awb(streamBank) : this.memory;
      if (!bank) fail("missing waveform bank");
      return { ...w, gain: cue.gain, name: cue.name, data: bank.extract(w.id), subkey: bank.subkey };
    } };
  }
  function prepareAdx(input) {
    const b = bytes(input), d = view(b);
    if (b.length < 24 || b.length > MAX || d.getUint16(0) !== 32768) fail("invalid ADX");
    const offset = d.getUint16(2) + 4, channels = b[7], rate = d.getUint32(8), samples = d.getUint32(12), flag = b[19];
    if (b[4] !== 3 || b[5] !== 18 || b[6] !== 4 || channels < 1 || channels > 8 || rate < 8e3 || rate > 192e3 || !samples || samples * channels * 2 > MAX || offset < 24 || offset > b.length || ![0, 9].includes(flag)) fail("unsupported or oversized ADX");
    range(offset, Math.ceil(samples / 32) * 18 * channels, b.length);
    const out = new Uint8Array(b);
    if (flag === 9) {
      let key = 3;
      const end = offset + Math.ceil(samples / 32) * 18 * channels;
      for (let p = offset; p < end; p += 18) {
        const val = ((out[p] << 8 | out[p + 1]) ^ key) & 8191;
        out[p] = val >> 8;
        out[p + 1] = val & 255;
        key = key * 3353 + 1083 & 32767;
      }
      out[19] = 0;
    }
    let loop;
    const loopBase = b[18] === 4 ? 24 + Math.max(8, channels * 4) : b[18] === 3 ? 20 : null;
    if (loopBase !== null && offset >= loopBase + 24 + 6) {
      const loopType = d.getUint32(loopBase + 4);
      if (loopType) {
        if (loopType !== 1) fail("unsupported ADX loop type");
        const start = d.getUint32(loopBase + 8), end = d.getUint32(loopBase + 16), startByte = d.getUint32(loopBase + 12), endByte = d.getUint32(loopBase + 20), required = offset + Math.ceil(samples / 32) * 18 * channels;
        if (start >= end || end > samples || startByte < offset || startByte >= required || endByte < startByte || endByte > required) fail("invalid ADX loop points");
        loop = { startSample: start, endSample: end, sampleRate: rate };
      }
    }
    return { data: out, channels, sampleRate: rate, samples, encrypted: flag !== 0, loop };
  }
  return { utf, awb, inspect, commands, prepareAdx, MAX_BYTES: MAX };
});
