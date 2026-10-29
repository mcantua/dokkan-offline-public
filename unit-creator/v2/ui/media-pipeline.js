import { readUsmMetadata } from "/tools/usm-player/js/forge-metadata.js";
import { sourceMovieAudioMetadata } from "/_forge/media/movie-audio.js";
import { demuxUsm } from "/tools/usm-player/js/usm-demux.js";
import { extractIvfFrames, getFramerate, isIvf } from "/tools/usm-player/js/ivf.js";
import { muxVp9ToMp4 } from "/tools/usm-player/js/mp4-muxer.js";
import { decryptAdx, parseAdxHeader, DEFAULT_ADX_KEY_ID } from "/tools/usm-player/js/adx-decoder.js";
import { probeVideoPayload } from "/tools/usm-player/js/probe.js";
const LIMIT = 160 * 1024 * 1024;
function progress(detail) {
  if (typeof window === "object") window.dispatchEvent(new CustomEvent("forge-media-progress", { detail }));
}
function pcmWave(decoded) {
  const { pcm, channels, sampleRate } = decoded;
  const integerPcm = pcm instanceof Int16Array;
  if (!integerPcm && !(pcm instanceof Float32Array) || !Number.isInteger(channels) || channels < 1 || channels > 8 || !Number.isInteger(sampleRate) || sampleRate < 8e3 || sampleRate > 192e3) throw new Error("This movie has an unsupported sound track.");
  if (pcm.length % channels !== 0) throw new Error("The movie sound track has an incomplete audio frame.");
  if (pcm.length * 2 > LIMIT) throw new Error("This sound track exceeds the movie preparation limit.");
  const data = new Uint8Array(44 + pcm.length * 2), view = new DataView(data.buffer);
  const text = (offset, value) => {
    for (let i = 0; i < value.length; i++) data[offset + i] = value.charCodeAt(i);
  };
  text(0, "RIFF");
  view.setUint32(4, data.length - 8, true);
  text(8, "WAVE");
  text(12, "fmt ");
  view.setUint32(16, 16, true);
  view.setUint16(20, 1, true);
  view.setUint16(22, channels, true);
  view.setUint32(24, sampleRate, true);
  view.setUint32(28, sampleRate * channels * 2, true);
  view.setUint16(32, channels * 2, true);
  view.setUint16(34, 16, true);
  text(36, "data");
  view.setUint32(40, data.length - 44, true);
  for (let i = 0; i < pcm.length; i++) {
    if (integerPcm) view.setInt16(44 + i * 2, pcm[i], true);
    else {
      const value = Math.max(-1, Math.min(1, Number.isFinite(pcm[i]) ? pcm[i] : 0));
      view.setInt16(44 + i * 2, Math.round(value * (value < 0 ? 32768 : 32767)), true);
    }
  }
  return data;
}
function prepareAdx(audio, opts) {
  var _a;
  if (!(audio instanceof Uint8Array) || audio.length < 24) throw new Error("The movie sound track has an incomplete ADX header.");
  const header = parseAdxHeader(audio);
  if (audio[5] !== 18 || audio[6] !== 4 || !Number.isInteger(header.channels) || header.channels < 1 || header.channels > 8 || !Number.isInteger(header.sampleRate) || header.sampleRate < 8e3 || header.sampleRate > 192e3 || !Number.isInteger(header.sampleCount) || header.sampleCount < 1 || header.sampleCount * header.channels * 2 > LIMIT || header.dataOffset < 20 || header.dataOffset > audio.length || ![2, 3, 4].includes(header.encoding)) {
    throw new Error("The movie sound track has an unsupported or oversized ADX header.");
  }
  const frames = Math.ceil(header.sampleCount / 32), required = header.dataOffset + frames * 18 * header.channels;
  if (!Number.isSafeInteger(required) || required > audio.length) throw new Error("The movie sound track ends inside an ADX frame.");
  return decryptAdx(audio.subarray(0, required), (_a = opts.adxKey) != null ? _a : DEFAULT_ADX_KEY_ID, { force: Boolean(opts.forceAdx) }).data;
}
function frameClock(fps, frameCount) {
  if (!Number.isFinite(fps) || fps < 1 || fps > 240 || !Number.isSafeInteger(frameCount) || frameCount < 1) return null;
  let x = fps, n0 = 0, n1 = 1, d0 = 1, d1 = 0;
  for (let i = 0; i < 24; i++) {
    const a = Math.floor(x), n = a * n1 + n0, d = a * d1 + d0;
    if (!Number.isSafeInteger(n) || !Number.isSafeInteger(d) || n > 1e6 || d > 1e4 || frameCount * d > 4294967295) break;
    if (Math.abs(n / d - fps) < 1e-8) return { timescale: n, framerateN: n, framerateD: d };
    n0 = n1;
    n1 = n;
    d0 = d1;
    d1 = d;
    const fraction = x - a;
    if (fraction < Number.EPSILON) break;
    x = 1 / fraction;
  }
  return null;
}
export async function openUsm(file, log = () => {
}, opts = {}) {
  var _a, _b, _c, _d, _e, _f;
  if (!file || file.size > LIMIT) throw new Error("This movie exceeds the 160 MB preview limit.");
  const buffer = await file.arrayBuffer(), container = readUsmMetadata(new Uint8Array(buffer));
  const demuxed = demuxUsm(buffer);
  // A movie that was prepared before is kept on the phone (native MovieCache): reuse it instead of
  // converting the same movie again. Its key is the movie file's SHA-256 plus the output kind.
  const cacheKind = (opts.outputProfile === "vp9-opus" ? "v" : opts.outputProfile ? "h" : "a") + (opts.forceFfmpeg ? "f" : "");
  let cacheKey = "";
  try {
    if (globalThis.crypto && crypto.subtle) cacheKey = Array.from(new Uint8Array(await crypto.subtle.digest("SHA-256", buffer)), (b) => b.toString(16).padStart(2, "0")).join("") + "-" + cacheKind;
  } catch (e) {}
  if (cacheKey && typeof fetch === "function") {
    try {
      const kept = await fetch("/_forge/movie-cache/" + cacheKey + ".mp4", { credentials: "same-origin", cache: "no-store" });
      if (kept.ok) {
        const mp4 = new Uint8Array(await kept.arrayBuffer());
        if (mp4.length > 12 && String.fromCharCode(...mp4.subarray(4, 8)) === "ftyp") {
          log("This movie was prepared before on this phone. It opens straight away.");
          const cachedMeta = { width: container.width || 0, height: container.height || 0, fps: container.framerate || 0, frames: container.frames || 0, audioKind: demuxed.audioKind, audio: sourceMovieAudioMetadata(new Uint8Array(buffer)), durationSec: container.frames && container.framerate ? container.frames / container.framerate : 0, path: "kept", probe: "kept" };
          return { mp4, audio: null, meta: cachedMeta };
        }
      }
    } catch (e) {}
  }
  const keep = async (bytes) => {
    if (!cacheKey || !bytes) return bytes;
    try { (await import("/_forge/media/playback.js")).rememberMovieCacheKey?.(bytes, cacheKey); } catch (e) {}
    return bytes;
  };
  if (!((_a = demuxed.video) == null ? void 0 : _a.byteLength)) throw new Error("This file has no readable game-video stream.");
  const probe = probeVideoPayload(demuxed.video);
  if (demuxed.video[0] === 0 && demuxed.video[1] === 0 && demuxed.video[2] === 1 && demuxed.video[3] === 176) probe.kind = "mpeg4";
  log("Preparing game movie on this device · " + probe.kind);
  let audio, audioKind, metadata = { width: container.width || 0, height: container.height || 0, fps: container.framerate || 0, frames: container.frames || 0, audioKind: demuxed.audioKind, audio: sourceMovieAudioMetadata(new Uint8Array(buffer)), durationSec: container.frames && container.framerate ? container.frames / container.framerate : 0 };
  if ((_b = demuxed.audio) == null ? void 0 : _b.byteLength) {
    if (demuxed.audioKind === "adx") {
      audio = prepareAdx(demuxed.audio, opts);
      audioKind = "adx";
      log("Prepared the movie sound track on this device.");
    } else {
      audio = demuxed.audio;
      audioKind = demuxed.audioKind || "";
    }
  }
  const capabilities = typeof document === "object" ? document.createElement("video") : null;
  const freeProfile = opts.outputProfile === "vp9-opus" || !opts.outputProfile && capabilities && (capabilities.canPlayType('video/mp4; codecs="avc1.42E01E"') === "" || audio && capabilities.canPlayType('audio/mp4; codecs="mp4a.40.2"') === "") && capabilities.canPlayType('video/mp4; codecs="vp09.00.10.08"') !== "";
  const nativeVp9 = isIvf(demuxed.video) && probe.kind === "vp9-ivf";
  let remuxed;
  if (nativeVp9) {
    const parsed = extractIvfFrames(demuxed.video), header = parsed.header, frames = parsed.frames, fps = container.framerate || getFramerate(header) || 30;
    if (!frames.length) throw new Error("This game movie contains no frames.");
    metadata = { ...metadata, width: header.width, height: header.height, fps, frames: frames.length, durationSec: frames.length / fps };
    const clock = frameClock(fps, frames.length);
    if (clock) remuxed = muxVp9ToMp4({ width: header.width, height: header.height, ...clock, profile: (_d = (_c = frames[0]) == null ? void 0 : _c.profile) != null ? _d : 0, level: 10, bitDepth: (_f = (_e = frames[0]) == null ? void 0 : _e.bitDepth) != null ? _f : 8, frames });
    const supported = typeof document !== "object" || document.createElement("video").canPlayType('video/mp4; codecs="vp09.00.10.08"') !== "";
    if (remuxed && supported && !audio && !opts.forceFfmpeg) return { mp4: remuxed, audio: null, meta: { ...metadata, path: "vp9-native", probe: probe.kind } };
  }
  const controller = new AbortController();
  const cancel = () => controller.abort();
  if (typeof window === "object") {
    window.addEventListener("forge-media-cancel", cancel);
    window.addEventListener("pagehide", cancel, { once: true });
  }
  progress({ active: true, message: "Preparing this movie on your device…" });
  try {
    const { convert } = await import("/_forge/media/converter.js");
    const report = (event) => {
      if (event.message) log(event.message);
      const amount = Number.isFinite(event.progress) ? Math.max(0, Math.min(100, Math.round(event.progress * 100))) : null;
      progress({ active: true, message: "Preparing this movie on your device" + (amount == null ? "…" : " · " + amount + "%") });
    };
    const clock = frameClock(metadata.fps, metadata.frames), videoInfo = clock ? { width: metadata.width, height: metadata.height, frames: metadata.frames, rate: { n: clock.framerateN, d: clock.framerateD } } : void 0;
    const convertMovie = (copyVideo) => convert({ video: demuxed.video, kind: probe.kind, audio, audioKind, framerate: metadata.fps || void 0, signal: controller.signal, copyVideo, outputProfile: freeProfile ? "vp9-opus" : void 0, metadata: videoInfo }, report);
    const av1 = isIvf(demuxed.video) && demuxed.video.length >= 12 && String.fromCharCode(...demuxed.video.subarray(8, 12)) === "AV01";
    const nativeAv1 = av1 && !opts.forceFfmpeg && typeof document === "object" && document.createElement("video").canPlayType('video/mp4; codecs="av01.0.08M.08"') !== "";
    let result, nativeVerified = false;
    if (nativeAv1) {
      const playback = await import("/_forge/media/playback.js");
      let candidate;
      try {
        result = await convertMovie(true);
        candidate = await playback.prepareMovieBlob(result.data);
        await playback.probeMovieBlob(candidate, { signal: controller.signal });
        nativeVerified = true;
        log("Your device decoded the original AV1 movie. Its original video quality is preserved.");
      } catch (error) {
        if (candidate) try {
          await playback.discardMovieBlob(candidate);
        } catch (cleanup) {
          log(cleanup.message);
        }
        if (controller.signal.aborted) throw error;
        log("Native AV1 playback is unavailable. Preparing a compatible movie instead…");
      }
    }
    if (!nativeVerified) {
      result = await convertMovie(Boolean(freeProfile && nativeVp9));
      if (freeProfile) {
        const playback = await import("/_forge/media/playback.js");
        let candidate;
        try {
          candidate = await playback.prepareMovieBlob(result.data);
          await playback.probeMovieBlob(candidate, { signal: controller.signal });
        } catch (error) {
          if (candidate) try {
            await playback.discardMovieBlob(candidate);
          } catch (cleanup) {
            log(cleanup.message);
          }
          throw error;
        }
        log("Your device decoded the compatible VP9 movie.");
      }
    }
    log("Movie and sound are ready. No online conversion was used.");
    await keep(result.data); // only the finished, checked video is kept for next time
    return { mp4: result.data, audio: null, meta: { ...metadata, path: nativeVerified ? "av1-native" : freeProfile ? "forge-free" : "forge-local", probe: probe.kind, outputProfile: freeProfile ? "vp9-opus" : "h264-aac" } };
  } finally {
    if (typeof window === "object") {
      window.removeEventListener("forge-media-cancel", cancel);
      window.removeEventListener("pagehide", cancel);
    }
    progress({ active: false });
  }
}
