export function installNativeAudioBinders(mark, bank, nextId, num, str, isNil = () => false) {
  mark("playSeNotStoppable", (L) => {
    const id = nextId();
    bank.commands.push({ type: "playSeNotStoppable", frame: num(L, 1), cueId: num(L, 2), name: str(L, 3), vol: isNil(L) ? -1 : num(L, 4), workId: id, forgePhase: bank.phase || 0 });
    return id;
  });
  for (const type of ["stopAndCancelAllSe", "stopAndCancelAllVoice"]) mark(type, (L) => {
    bank.commands.push({ type, frame: num(L, 1), forgePhase: bank.phase || 0 });
  });
}
const states = /* @__PURE__ */ new WeakMap();
const captureTime = (bus) => (bus == null ? void 0 : bus._mixCapturing) && Number.isFinite(bus._forgeCaptureSeconds) ? bus._forgeCaptureSeconds : null;
function endCapture(event, bus) {
  var _a;
  const seconds = captureTime(bus);
  if (seconds != null) event.forgeEndSeconds = Math.min((_a = event.forgeEndSeconds) != null ? _a : Infinity, seconds);
}
const relative = (value, fallback) => value == null || value < 0 ? fallback : Math.max(0, value > 1.5 ? value / 100 : value);
function installBus(bus) {
  if (!bus || states.has(bus)) return states.get(bus);
  const state = { cancelled: /* @__PURE__ */ new Set(), protected: /* @__PURE__ */ new Set(), voiceCancelled: /* @__PURE__ */ new WeakSet(), voiceCommand: null, playing: null, pending: /* @__PURE__ */ new Map() };
  states.set(bus, state);
  bus._forgeAudioWorkCancelled = (id) => state.cancelled.has(id);
  bus._forgeHasAudioWork = (id) => {
    var _a, _b;
    return !state.cancelled.has(id) && (((_a = bus.voices) == null ? void 0 : _a.has(id)) || ((_b = state.pending.get(id)) == null ? void 0 : _b.gen) === bus.timelineGen);
  };
  const silence = bus.silence;
  if (silence) bus.silence = function(...args) {
    this.timelineGen++;
    return silence.apply(this, args);
  };
  const startNow = bus._startNow;
  if (startNow) bus._startNow = function(buffer, volume, key, options = {}) {
    var _a;
    const gen = this.timelineGen, voice = typeof key === "string" && key.startsWith("v:"), command = options.forgeVoiceCommand || state.voiceCommand;
    const cancelled = () => gen !== this.timelineGen || !voice && state.cancelled.has(key) || voice && command && state.voiceCancelled.has(command);
    if (cancelled()) return;
    if (((_a = this.ctx) == null ? void 0 : _a.state) !== "running") {
      const request = { gen };
      state.pending.set(key, request);
      void this._ensureRunning().then(() => {
        if (!cancelled()) startNow.call(this, buffer, volume, key, options);
      }).finally(() => {
        if (state.pending.get(key) === request) state.pending.delete(key);
      });
      return;
    }
    return startNow.call(this, buffer, volume, key, options);
  };
  const note = bus._noteMix;
  if (note) bus._noteMix = function(kind, id, options) {
    var _a, _b, _c, _d;
    const count = ((_a = this._mixEvents) == null ? void 0 : _a.length) || 0;
    note.call(this, kind, id, options);
    if (((_b = this._mixEvents) == null ? void 0 : _b.length) > count) Object.assign(this._mixEvents[this._mixEvents.length - 1], { forgeWorkId: (_c = state.playing) == null ? void 0 : _c.workId, forgeProtected: !!((_d = state.playing) == null ? void 0 : _d.protected), ...Number.isFinite(options == null ? void 0 : options.forgeCaptureSeconds) ? { forgeCaptureSeconds: options.forgeCaptureSeconds } : captureTime(this) != null ? { forgeCaptureSeconds: captureTime(this) } : {} });
  };
  const cueNow = bus.playCueNow;
  if (cueNow) bus.playCueNow = function(id, options = {}) {
    if (state.cancelled.has(options.workId)) return true;
    const previous = state.playing;
    state.playing = { workId: options.workId, protected: state.protected.has(options.workId) };
    try {
      return cueNow.call(this, id, options);
    } finally {
      state.playing = previous;
    }
  };
  bus.playCue = async function(id, options = {}) {
    var _a, _b, _c, _d;
    const gen = this.timelineGen, forgeCaptureSeconds = captureTime(this), request = { gen };
    if (state.cancelled.has(options.workId)) return;
    state.pending.set(options.workId, request);
    try {
      const buffer = await this.preloadSe(id);
      if (!buffer || gen !== this.timelineGen || state.cancelled.has(options.workId)) return;
      const volume = ((_a = this.volumeByWorkId) == null ? void 0 : _a.has(options.workId)) ? this.volumeByWorkId.get(options.workId) : relative(options.volume, 0.35);
      const previous = state.playing;
      state.playing = { workId: options.workId, protected: state.protected.has(options.workId) };
      try {
        (_c = this._noteMix) == null ? void 0 : _c.call(this, "se", id, { ...options, forgeCaptureSeconds, relVolume: volume, cacheKey: ((_b = [...this.cache || []].find(([key, value]) => value === buffer && key.startsWith("se:" + id + ":"))) == null ? void 0 : _b[0]) || "se:" + id });
        this._startNow(buffer, volume, options.workId, options);
      } finally {
        state.playing = previous;
      }
    } catch (error) {
      (_d = this.log) == null ? void 0 : _d.call(this, "SE " + id + " failed: " + (error.message || error));
    } finally {
      if (state.pending.get(options.workId) === request) state.pending.delete(options.workId);
    }
  };
  bus.playVoice = async function(id, options = {}) {
    var _a, _b, _c, _d;
    const gen = this.timelineGen, command = state.voiceCommand, forgeCaptureSeconds = captureTime(this);
    try {
      const buffer = await this.preloadVoice(id, options.packageHint || "");
      if (!buffer || gen !== this.timelineGen || command && state.voiceCancelled.has(command)) return;
      const volume = ((_a = this.volumeByVoiceCue) == null ? void 0 : _a.has(id)) ? this.volumeByVoiceCue.get(id) : relative(options.volume, 0.45);
      (_c = this._noteMix) == null ? void 0 : _c.call(this, "voice", id, { ...options, forgeCaptureSeconds, relVolume: volume, cacheKey: ((_b = [...this.cache || []].find(([key, value]) => value === buffer && key.startsWith("voice:" + id + ":"))) == null ? void 0 : _b[0]) || "voice:" + id + ":" + (options.packageHint || "") });
      this._startNow(buffer, volume, "v:" + id, { ...options, forgeVoiceCommand: command });
    } catch (error) {
      (_d = this.log) == null ? void 0 : _d.call(this, "Voice " + id + " failed: " + (error.message || error));
    }
  };
  return state;
}
export function resetNativeAudio(runner) {
  runner._forgeCancelledAudio = /* @__PURE__ */ new WeakSet();
  const state = installBus(runner.audio);
  if (state) {
    runner.audio.timelineGen++;
    state.cancelled.clear();
    state.pending.clear();
    state.protected.clear();
    state.voiceCancelled = /* @__PURE__ */ new WeakSet();
    state.voiceCommand = null;
  }
}
export function seekNativeAudio(runner, frame) {
  resetNativeAudio(runner);
  for (const command of runner.commands || []) if ((Number(command.frame) || 0) <= frame && (command.type === "stopAndCancelAllSe" || command.type === "stopAndCancelAllVoice")) executeNativeAudio(runner, command);
}
function stopVoice(bus, key) {
  var _a, _b;
  const live = (_a = bus == null ? void 0 : bus.voices) == null ? void 0 : _a.get(key);
  if (!live) return;
  try {
    live.src.onended = null;
    live.src.stop(0);
    live.src.disconnect();
  } catch {
  }
  (_b = bus._sources) == null ? void 0 : _b.delete(live.src);
  bus.voices.delete(key);
}
export function executeNativeAudio(runner, command) {
  var _a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, _r, _s;
  const type = command.type, state = installBus(runner.audio);
  if (!runner._forgeCancelledAudio) runner._forgeCancelledAudio = /* @__PURE__ */ new WeakSet();
  if (runner._forgeCancelledAudio.has(command)) return true;
  if (type === "setBandpassFilter") {
    if ((_b = (_a = runner.audio) == null ? void 0 : _a._forgeBandpass) == null ? void 0 : _b.execute(command)) return true;
    if (!runner._forgeBandpassWarning) {
      runner._forgeBandpassWarning = true;
      (_c = runner.log) == null ? void 0 : _c.call(runner, "Preview limitation: this move uses a game sound filter that is not reproduced yet. Its original command is preserved for game export.");
    }
    return true;
  }
  if (type === "playVoice" && state) state.voiceCommand = command;
  if (type === "playSeNotStoppable") {
    state == null ? void 0 : state.protected.add(command.workId);
    runner._playSe(command);
    (_d = runner.log) == null ? void 0 : _d.call(runner, "playSeNotStoppable cue=" + command.cueId + " @f" + (command.frame || 0));
    return true;
  }
  if (type === "stopSeIfDoubleSpeed") {
    const id = (_f = command.workId) != null ? _f : (_e = command.args) == null ? void 0 : _e[1], bus = runner.audio;
    if (runner.highSpeed && id != null && ((_g = bus == null ? void 0 : bus.voices) == null ? void 0 : _g.has(id))) {
      (_h = bus.stopWork) == null ? void 0 : _h.call(bus, id);
      for (const event of bus._mixEvents || []) if (event.kind === "se" && event.forgeWorkId === id) {
        event.endFrame = Math.min((_i = event.endFrame) != null ? _i : Infinity, command.frame || 0);
        endCapture(event, bus);
      }
      (_j = runner.log) == null ? void 0 : _j.call(runner, "stopSeIfDoubleSpeed work=" + id + " @f" + (command.frame || 0));
    }
    return true;
  }
  if (type !== "stopAndCancelAllSe" && type !== "stopAndCancelAllVoice") return false;
  const voice = type === "stopAndCancelAllVoice", phase = (_k = command.forgePhase) != null ? _k : 0, workIds = /* @__PURE__ */ new Set();
  let cancelledCount = 0;
  for (const queued of runner.commands || []) {
    if (((_l = queued.forgePhase) != null ? _l : 0) !== phase) continue;
    if (voice ? queued.type === "playVoice" : ["playSe", "playSeLife", "playSeVer2"].includes(queued.type)) {
      cancelledCount++;
      runner._forgeCancelledAudio.add(queued);
      if (voice) state == null ? void 0 : state.voiceCancelled.add(queued);
      if (queued.workId != null) {
        workIds.add(queued.workId);
        state == null ? void 0 : state.cancelled.add(queued.workId);
      }
    }
  }
  if (voice) {
    for (const key of [...((_n = (_m = runner.audio) == null ? void 0 : _m.voices) == null ? void 0 : _n.keys()) || []]) if (typeof key === "string" && key.startsWith("v:")) stopVoice(runner.audio, key);
  } else for (const id of workIds) (_p = (_o = runner.audio) == null ? void 0 : _o.stopWork) == null ? void 0 : _p.call(_o, id);
  const events = ((_q = runner.audio) == null ? void 0 : _q._mixEvents) || [];
  for (let index = events.length - 1; index >= 0; index--) {
    const event = events[index];
    if (voice ? event.kind === "voice" : event.kind === "se" && !event.forgeProtected && workIds.has(event.forgeWorkId)) {
      if (event.frame >= (command.frame || 0)) events.splice(index, 1);
      else {
        event.endFrame = Math.min((_r = event.endFrame) != null ? _r : Infinity, command.frame || 0);
        endCapture(event, runner.audio);
      }
    }
  }
  (_s = runner.log) == null ? void 0 : _s.call(runner, type + " @f" + (command.frame || 0) + " · phase " + phase + " · cancelled " + cancelledCount + " registered events");
  return true;
}
