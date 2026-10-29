(function(root, factory) {
  if (typeof module === "object" && module.exports) module.exports = factory();
  else root.ForgeMovieEditPlan = factory();
})(typeof globalThis === "object" ? globalThis : this, function() {
  "use strict";
  const MAX_BYTES = 160 * 1024 * 1024;
  function fail(message) {
    throw Error("Movie edit: " + message);
  }
  function integer(value, min, max, label) {
    if (!Number.isInteger(value) || value < min || value > max) fail("Choose a supported " + label + ".");
    return value;
  }
  function number(value, min, max, label) {
    if (typeof value !== "number" || !Number.isFinite(value) || value < min || value > max) fail("Choose a supported " + label + ".");
    return value;
  }
  function clock(value = { n: 30, d: 1 }) {
    const n = integer(value.n, 1, 2147483647, "frame rate"), d = integer(value.d, 1, 1e6, "frame rate");
    if (n / d < 1 || n / d > 120) fail("Frame rate must be between 1 and 120.");
    return { n, d, fps: n / d };
  }
  function plan(request) {
    var _a, _b, _c;
    if (!request || !Array.isArray(request.clips) || request.clips.length < 1 || request.clips.length > 12) fail("Choose between one and twelve movie sections.");
    const width = integer(request.width, 2, 4096, "canvas width"), height = integer(request.height, 2, 4096, "canvas height");
    if (width % 2 || height % 2 || width * height > 16 * 1024 * 1024) fail("Choose an even canvas size up to 16 million pixels.");
    const rate = clock(request.rate), audioMode = (_a = request.audioMode) != null ? _a : "auto";
    if (!["auto", "mute"].includes(audioMode)) fail("Choose whether to keep or mute the sound.");
    let bytes = 0, frames = 0, samples = 0;
    const clips = request.clips.map((clip, index) => {
      var _a2, _b2, _c2, _d, _e, _f, _g, _h;
      if (!clip || !(clip.video instanceof Uint8Array) || !clip.video.length || !["vp9-ivf", "av1-ivf", "mpeg1", "mpeg2", "mpeg4", "h264"].includes(clip.kind)) fail("Section " + (index + 1) + " needs a supported game-video stream.");
      bytes += clip.video.length;
      if (clip.audio != null && (!(clip.audio instanceof Uint8Array) || !clip.audio.length)) fail("Section " + (index + 1) + " has unreadable sound.");
      bytes += ((_a2 = clip.audio) == null ? void 0 : _a2.length) || 0;
      const sourceRate = clock(clip.rate || request.rate), sourceFrames = integer(clip.frames, 1, 1e4, "source frame count"), start = integer((_b2 = clip.startFrame) != null ? _b2 : 0, 0, sourceFrames - 1, "first frame"), end = integer((_c2 = clip.endFrame) != null ? _c2 : sourceFrames, start + 1, sourceFrames, "last frame"), count = Math.max(1, Math.round((end - start) * sourceRate.d / sourceRate.n * rate.fps)), soundSamples = Math.round(count / rate.fps * 48e3), t = clip.transform || {}, transform = { scale: number((_d = t.scale) != null ? _d : 1, 0.05, 8, "zoom"), x: number((_e = t.x) != null ? _e : 0, -8192, 8192, "horizontal position"), y: number((_f = t.y) != null ? _f : 0, -8192, 8192, "vertical position"), rotation: number((_g = t.rotation) != null ? _g : 0, -180, 180, "rotation"), opacity: number((_h = t.opacity) != null ? _h : 1, 0, 1, "opacity"), flipX: t.flipX === true, flipY: t.flipY === true };
      const angle = transform.rotation * Math.PI / 180, w = width * transform.scale, h = height * transform.scale, workW = Math.abs(Math.cos(angle)) * w + Math.abs(Math.sin(angle)) * h, workH = Math.abs(Math.sin(angle)) * w + Math.abs(Math.cos(angle)) * h;
      if (workW > 8192 || workH > 8192 || workW * workH > 32 * 1024 * 1024) fail("This zoom needs a smaller canvas to fit device memory.");
      frames += count;
      samples += soundSamples;
      const audioKind = clip.audio ? clip.audioKind || ((clip.audio[0] & 127) === 72 && (clip.audio[1] & 127) === 67 && (clip.audio[2] & 127) === 65 ? "hca" : "adx") : null;
      if (clip.audio && !["adx", "hca"].includes(audioKind)) fail("Section " + (index + 1) + " has an unsupported sound format. Mute this section or choose another scene.");
      return { index, video: clip.video, audio: clip.audio || null, audioKind, kind: clip.kind, sourceRate, sourceFrames, start, end, count, soundSamples, transform };
    });
    if (bytes > MAX_BYTES || frames > 1e4 || audioMode === "auto" && clips.some((c) => c.audio) && Math.ceil(samples / 32) * 36 + 4096 > MAX_BYTES) fail("This sequence exceeds the supported movie size or duration.");
    const color = (_b = request.background) != null ? _b : "000000";
    if (typeof color !== "string" || !/^[A-Fa-f0-9]{6}$/.test(color)) fail("Choose a plain background color.");
    const preserveAudio = request.preserveAudio === true;
    if (preserveAudio && (clips.length !== 1 || clips[0].start !== 0 || clips[0].end !== clips[0].sourceFrames || !clips[0].audio || clips[0].audioKind !== "adx" || audioMode !== "auto")) fail("Preserving original sound requires one complete plain ADX movie section.");
    return { clips, width, height, rate, frames, samples, audio: audioMode === "auto" && clips.some((c) => c.audio), preserveAudio, color, lossless: request.lossless === true, quality: integer((_c = request.quality) != null ? _c : 24, 0, 63, "picture quality") };
  }
  function filters(plan2, inputMap) {
    const filters2 = [], videos = [], audios = [], fps = plan2.rate.n + "/" + plan2.rate.d;
    for (const clip of plan2.clips) {
      const t = clip.transform, i = clip.index, v = "v" + i, bg = "bg" + i, out = "out" + i, duration = (clip.count / plan2.rate.fps).toFixed(9), fit = "min(" + plan2.width + "/iw\\," + plan2.height + "/ih)";
      let chain = "[" + inputMap[i].video + ":v]trim=start_frame=" + clip.start + ":end_frame=" + clip.end + ",setpts=PTS-STARTPTS,fps=fps=" + fps + ":round=near,scale=w=max(2\\,trunc(iw*" + fit + "*" + t.scale + "/2)*2):h=max(2\\,trunc(ih*" + fit + "*" + t.scale + "/2)*2):flags=neighbor";
      if (t.flipX) chain += ",hflip";
      if (t.flipY) chain += ",vflip";
      if (t.rotation || t.opacity !== 1) {
        chain += ",format=rgba";
        if (t.rotation) chain += ",rotate=" + t.rotation + "*PI/180:ow=rotw(" + t.rotation + "*PI/180):oh=roth(" + t.rotation + "*PI/180):c=none";
        if (t.opacity !== 1) chain += ",colorchannelmixer=aa=" + t.opacity;
      }
      chain += "[" + v + "]";
      filters2.push(chain, "color=c=0x" + plan2.color + ":s=" + plan2.width + "x" + plan2.height + ":r=" + fps + ":d=" + duration + "[" + bg + "]", "[" + bg + "][" + v + "]overlay=x=(W-w)/2+" + t.x + ":y=(H-h)/2+" + t.y + ":shortest=1:eof_action=endall,format=yuv420p,trim=end_frame=" + clip.count + ",setpts=PTS-STARTPTS[" + out + "]");
      videos.push("[" + out + "]");
      if (plan2.audio && !plan2.preserveAudio) {
        const a = "a" + i;
        if (clip.audio) {
          const first = Math.round(clip.start / clip.sourceRate.fps * 48e3), last = Math.round(clip.end / clip.sourceRate.fps * 48e3);
          filters2.push("[" + inputMap[i].audio + ":a]aresample=48000,aformat=sample_fmts=s16:channel_layouts=stereo,atrim=start_sample=" + first + ":end_sample=" + last + ",asetpts=PTS-STARTPTS,apad=whole_len=" + clip.soundSamples + ",atrim=end_sample=" + clip.soundSamples + "[" + a + "]");
        } else filters2.push("anullsrc=r=48000:cl=stereo,atrim=end_sample=" + clip.soundSamples + ",asetpts=PTS-STARTPTS[" + a + "]");
        audios.push("[" + a + "]");
      }
    }
    filters2.push(videos.join("") + "concat=n=" + videos.length + ":v=1:a=0[vout]");
    if (audios.length) filters2.push(audios.join("") + "concat=n=" + audios.length + ":v=0:a=1[aout]");
    return filters2.join(";");
  }
  return { plan, filters, MAX_BYTES };
});
