import "/_forge/audio-bank.js";
import "/_forge/media/hca-metadata.js";
import { decodeAudio } from "/_forge/media/audio-decoder.js";
const LIMIT = 160 * 1024 * 1024, MAX_METADATA = 32 * 1024 * 1024, MAX_CATALOG = 4 * 1024 * 1024;
const responseLoops = /* @__PURE__ */ new WeakMap(), bufferLoops = /* @__PURE__ */ new WeakMap();
let catalogPromise;
const parsed = /* @__PURE__ */ new Map(), pending = /* @__PURE__ */ new Map();
let cachedBytes = 0;
function route(value) {
  const u = new URL(value, location.href);
  if (u.origin !== location.origin || !["/api/se", "/api/voice"].includes(u.pathname) || !/^\d{1,10}$/.test(u.searchParams.get("cue") || "")) return null;
  const hint = u.searchParams.get("package") || "";
  if (hint.length > 200 || /[\x00-\x1f\x7f]/.test(hint)) return null;
  return { kind: u.pathname.endsWith("/se") ? "se" : "voice", cue: Number(u.searchParams.get("cue")), hint };
}
function address(file, extension) {
  if (!file || !Number.isSafeInteger(file.size) || file.size < 1 || file.size > LIMIT) throw Error("Invalid imported sound file size.");
  const u = new URL(file.url, location.href);
  if (u.origin !== location.origin || u.search || u.hash || u.username || u.password || !new RegExp("^/_forge/audio-bank-assets/[A-Za-z0-9_-]{16,128}\\." + extension + "$").test(u.pathname)) throw Error("Invalid imported sound address.");
  return u.href;
}
async function bounded(url, limit, signal) {
  var _a, _b, _c;
  const res = await fetch(url, { signal, credentials: "same-origin", redirect: "error" });
  if (!res.ok) throw Error("Imported sound source is unavailable (" + res.status + ").");
  const declared = res.headers.get("content-length");
  if (declared != null && (!/^\d+$/.test(declared) || Number(declared) > limit)) {
    await ((_b = (_a = res.body) == null ? void 0 : _a.cancel) == null ? void 0 : _b.call(_a));
    throw Error("Imported sound exceeds its read limit.");
  }
  const reader = (_c = res.body) == null ? void 0 : _c.getReader();
  if (!reader) {
    const bytes2 = new Uint8Array(await res.arrayBuffer());
    if (bytes2.length > limit) throw Error("Imported sound exceeds its read limit.");
    return bytes2;
  }
  const chunks = [];
  let size = 0;
  try {
    for (; ; ) {
      const r = await reader.read();
      if (r.done) break;
      size += r.value.length;
      if (size > limit) {
        await reader.cancel();
        throw Error("Imported sound exceeds its read limit.");
      }
      chunks.push(r.value);
    }
  } finally {
    reader.releaseLock();
  }
  if (declared != null && size !== Number(declared)) throw Error("Imported sound download is incomplete.");
  const bytes = new Uint8Array(size);
  let at = 0;
  for (const chunk of chunks) {
    bytes.set(chunk, at);
    at += chunk.length;
  }
  return bytes;
}
async function catalog() {
  if (!catalogPromise) catalogPromise = (async () => {
    const bytes = await bounded("/_forge/audio-banks", MAX_CATALOG), data = JSON.parse(new TextDecoder().decode(bytes));
    if (data.version !== 1 || !Array.isArray(data.banks) || data.banks.length > 1e4) throw Error("Invalid imported sound catalog.");
    const ids = /* @__PURE__ */ new Set();
    for (const bank of data.banks) {
      if (typeof bank.id !== "string" || ids.has(bank.id) || !["se", "voice"].includes(bank.kind) || typeof bank.package !== "string" || bank.package.length > 200 || !["en", "ja", ""].includes(bank.locale || "")) throw Error("Invalid imported sound bank.");
      ids.add(bank.id);
      address(bank.acb, "acb");
      if (bank.awb) address(bank.awb, "awb");
    }
    return data.banks;
  })();
  return await catalogPromise;
}
async function loadBank(bank, signal) {
  if (parsed.has(bank.id)) {
    const item = parsed.get(bank.id);
    parsed.delete(bank.id);
    parsed.set(bank.id, item);
    return item.bank;
  }
  const source = await bounded(address(bank.acb, "acb"), MAX_METADATA, signal);
  if (source.length !== bank.acb.size) throw Error("Imported cue sheet changed.");
  const result = globalThis.ForgeAudioBank.inspect(source);
  while (parsed.size && cachedBytes + source.length > MAX_METADATA) {
    const [id, item] = parsed.entries().next().value;
    parsed.delete(id);
    cachedBytes -= item.bytes;
  }
  if (source.length <= MAX_METADATA) {
    parsed.set(bank.id, { bank: result, bytes: source.length });
    cachedBytes += source.length;
  }
  return result;
}
async function localSound(request, signal) {
  const all = await catalog();
  let candidates = all.filter((b) => b.kind === request.kind);
  if (request.kind === "voice") {
    const exact = request.hint ? candidates.filter((b) => b.package === request.hint) : [];
    if (exact.length) candidates = exact;
    const english = candidates.filter((b) => b.locale === "en");
    if (english.length) candidates = english;
  }
  let selected;
  for (const candidate2 of candidates) {
    if (signal == null ? void 0 : signal.aborted) throw new DOMException("Sound preparation cancelled.", "AbortError");
    const bank2 = await loadBank(candidate2, signal), cue2 = bank2.cues.find((c) => c.id === request.cue && (!request.hint || candidate2.package === request.hint || c.name === request.hint));
    if (!cue2) continue;
    if (selected) throw Error("This sound cue occurs in multiple imported banks. Choose a complete, unambiguous resource collection.");
    if (!cue2.simple) throw Error("This imported cue uses unsupported Atom timing or effects.");
    selected = { candidate: candidate2, bank: bank2, cue: cue2 };
  }
  if (!selected) return null;
  const { candidate, bank, cue } = selected, external = cue.activeWaves[0].bank === "stream";
  let awb;
  if (external) {
    if (!candidate.awb) throw Error("The imported voice bank is missing its paired waveform file.");
    awb = await bounded(address(candidate.awb, "awb"), LIMIT, signal);
    if (awb.length !== candidate.awb.size) throw Error("Imported waveform bank changed.");
  }
  const wave = bank.extract(request.cue, awb);
  const hca = wave.data.length >= 4 && String.fromCharCode(...wave.data.subarray(0, 4).map((x) => x & 127)) === "HCA\0";
  if (!hca && wave.encoding !== 0) throw Error("This imported waveform codec has not been verified.");
  const prepared = hca ? { ...globalThis.ForgeHcaMetadata.inspect(wave.data), data: wave.data } : globalThis.ForgeAudioBank.prepareAdx(wave.data);
  const decoded = await decodeAudio({ data: prepared.data, kind: hca ? "hca" : "adx", sampleRate: prepared.sampleRate, channels: prepared.channels, gain: wave.gain, signal });
  return { ...decoded, loop: prepared.loop };
}
export async function fetchImportedAudio(url, init = {}, log = () => {
}) {
  const request = route(url);
  if (!request) return await fetch(url, init);
  try {
    const key = request.kind + ":" + request.cue + ":" + request.hint;
    let result;
    if (init.signal) result = await localSound(request, init.signal);
    else {
      let p = pending.get(key);
      if (!p) {
        p = localSound(request);
        pending.set(key, p);
      }
      try {
        result = await p;
      } finally {
        pending.delete(key);
      }
    }
    if (result) {
      log("Prepared " + request.kind + " " + request.cue + " from imported game sound banks on this device.");
      const response = new Response(result.data, { status: 200, headers: { "Content-Type": "audio/wav", "Content-Length": String(result.data.length) } });
      if (result.loop) responseLoops.set(response, result.loop);
      return response;
    }
  } catch (error) {
    if (error.name === "AbortError") throw error;
    log("Imported " + request.kind + " " + request.cue + ": " + error.message + " Using the existing public sound source when available.");
  }
  return await fetch(url, init);
}
export function rememberImportedAudioLoop(response, buffer) {
  const loop = responseLoops.get(response);
  if (!loop) return;
  const start = loop.startSample / loop.sampleRate, end = loop.endSample / loop.sampleRate;
  if (!Number.isFinite(start) || !Number.isFinite(end) || start < 0 || end <= start || end > buffer.duration + 1e-3) throw Error("The imported sound has invalid loop timing.");
  bufferLoops.set(buffer, { start, end: Math.min(end, buffer.duration) });
}
export function hasImportedAudioLoop(buffer) {
  return bufferLoops.has(buffer);
}
export function configureImportedAudioLoop(source, buffer) {
  const loop = bufferLoops.get(buffer);
  if (!loop) return false;
  source.loop = true;
  source.loopStart = loop.start;
  source.loopEnd = loop.end;
  return true;
}
export function importedAudioDuration(buffer, requested, remaining) {
  return bufferLoops.has(buffer) ? requested : Math.min(requested, remaining);
}
