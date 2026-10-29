(function() {
  "use strict";
  const request = window.__forgeAnimation;
  if (!request || request.mode !== "movie") return;
  const path = request.resourcePath;
  if (typeof path !== "string" || !/^movie\/[a-z0-9_./-]+\.usm$/i.test(path) || path.length > 300 || path.split("/").some((x) => !x || x === "." || x === "..")) return;
  const bar = document.createElement("section");
  bar.id = "forge-movie-bar";
  bar.setAttribute("aria-label", "Movie preview controls");
  bar.style.cssText = "padding:18px 22px;background:#112832;color:#edf5f8;font-family:system-ui,sans-serif;border-bottom:1px solid #3c5962";
  const title = document.createElement("h1");
  title.textContent = request.name || "Game movie";
  title.style.cssText = "font-size:1.35rem;margin:0 0 8px";
  bar.append(title);
  const detail = document.createElement("p");
  detail.setAttribute("role", "status");
  detail.setAttribute("aria-live", "polite");
  detail.textContent = request.offline ? "Ready to load saved movie resources from this device." : "Ready. Load this movie once to save its resources for offline replay.";
  bar.append(detail);
  const controls = document.createElement("div");
  controls.style.cssText = "display:flex;flex-wrap:wrap;gap:10px";
  bar.append(controls);
  const button = (label) => {
    const b = document.createElement("button");
    b.type = "button";
    b.textContent = label;
    b.style.cssText = "padding:11px 15px;border:1px solid #55757c;border-radius:8px;background:#26454f;color:white;font-size:15px;cursor:pointer";
    controls.append(b);
    return b;
  };
  const load = button("Load and play movie"), sound = button("Movie sound: Off"), cancel = button("Cancel preparation"), previous = button("Previous frame"), next = button("Next frame"), tools = button("Show player tools");
  cancel.disabled = true;
  previous.disabled = true;
  next.disabled = true;
  document.body.prepend(bar);
  document.body.classList.add("forge-movie-simple");
  const style = document.createElement("style");
  style.textContent = ".nav-container,#drop,#frameSeek,.actions{display:none!important}body.forge-movie-simple .hdr,body.forge-movie-simple #drop,body.forge-movie-simple .opt,body.forge-movie-simple #status,body.forge-movie-simple #meta,body.forge-movie-simple .log-wrap,body.forge-movie-simple .actions{display:none!important}#video{max-height:72vh!important;width:100%;object-fit:contain}#forge-movie-bar button:disabled{opacity:.5;cursor:default}@media(max-width:600px){#forge-movie-bar{padding:14px!important}#forge-movie-bar button{flex:1;min-width:130px}.shell{padding:12px!important}}";
  document.head.append(style);
  tools.onclick = () => {
    const simple = document.body.classList.toggle("forge-movie-simple");
    tools.textContent = simple ? "Show player tools" : "Hide player tools";
  };
  let controller = null, watch = null, active = false, video = null, generation = 0, fps = 30, lastPrepared = null;
  function connectVideo() {
    const target = document.getElementById("video");
    if (video && video === target) return true;
    video = target;
    if (!video) return false;
    video.dataset.forgeMovie = "1";
    video.muted = true;
    video.defaultMuted = true;
    video.setAttribute("playsinline", "");
    video.addEventListener("volumechange", () => {
      sound.textContent = "Movie sound: " + (video.muted ? "Off" : "On");
    });
    video.addEventListener("play", () => {
      detail.textContent = "Playing your movie. Use pause, the timeline, or frame controls below.";
    });
    video.addEventListener("ended", () => {
      detail.textContent = "Movie finished. Press play below to watch it again.";
    });
    return true;
  }
  function step(direction) {
    if (!video || !video.src) return;
    video.pause();
    video.currentTime = Math.max(0, Math.min(Number.isFinite(video.duration) ? video.duration : Infinity, video.currentTime + direction / fps));
  }
  previous.onclick = () => step(-1);
  next.onclick = () => step(1);
  document.addEventListener("keydown", (event) => {
    var _a;
    if ((event.key === "ArrowLeft" || event.key === "ArrowRight") && (video == null ? void 0 : video.src) && !["INPUT", "SELECT", "TEXTAREA"].includes((_a = document.activeElement) == null ? void 0 : _a.tagName)) {
      event.preventDefault();
      event.stopImmediatePropagation();
      step(event.key === "ArrowLeft" ? -1 : 1);
    }
  }, { capture: true });
  sound.onclick = () => {
    if (!video && !connectVideo()) return;
    video.muted = !video.muted;
    sound.textContent = "Movie sound: " + (video.muted ? "Off" : "On");
    if (!video.muted && video.src) void video.play().catch(() => {
    });
  };
  window.addEventListener("forge-media-progress", (event) => {
    var _a;
    if (active && ((_a = event.detail) == null ? void 0 : _a.active)) detail.textContent = String(event.detail.message || "Preparing this movie on your device…");
  });
  cancel.onclick = () => {
    generation++;
    controller == null ? void 0 : controller.abort();
    window.dispatchEvent(new Event("forge-media-cancel"));
    clearInterval(watch);
    active = false;
    load.disabled = false;
    cancel.disabled = true;
    detail.textContent = "Movie preparation cancelled. Choose Load and play movie to try again.";
  };
  load.onclick = async () => {
    var _a, _b, _c, _d, _e, _f, _g;
    if (active) return;
    if (!video && !connectVideo()) {
      detail.textContent = "The saved movie player is still loading. Try again in a moment.";
      return;
    }
    active = true;
    load.disabled = true;
    cancel.disabled = false;
    previous.disabled = true;
    next.disabled = true;
    const token = ++generation, runController = new AbortController();
    controller = runController;
    detail.textContent = "Loading this movie and preparing it on your device…";
    try {
      const { fetchMovieSource } = await import(new URL("/_forge/media/movie-source.js", location.href).href);
      const { bytes } = await fetchMovieSource(path, { signal: runController.signal, onFallback: () => {
        if (token === generation) detail.textContent = "Checking the complete public movie resource…";
      } });
      if (runController.signal.aborted || token !== generation) return;
      const logElement = document.getElementById("log");
      if (logElement) logElement.textContent = "";
      const log = (text) => {
        if (logElement) {
          const line = document.createElement("div");
          line.textContent = String(text);
          logElement.append(line);
        }
      };
      const [{ openUsm }, { prepareMovieBlob, movieObjectUrl, discardMovieBlob }] = await Promise.all([import(new URL("/tools/usm-player/js/pipeline.js", location.href).href), import(new URL("/_forge/media/playback.js", location.href).href)]);
      const selectedKey = (_a = document.getElementById("adx-key")) == null ? void 0 : _a.value;
      const result = await openUsm(new File([bytes], path.split("/").pop(), { type: "application/octet-stream" }), log, { forceFfmpeg: Boolean((_b = document.getElementById("force-ffmpeg")) == null ? void 0 : _b.checked), adxKey: selectedKey ? Number(selectedKey) : void 0, forceAdx: Boolean((_c = document.getElementById("force-adx")) == null ? void 0 : _c.checked) });
      if (runController.signal.aborted || token !== generation) return;
      const prepared = await prepareMovieBlob(result.mp4);
      if (runController.signal.aborted || token !== generation) {
        await discardMovieBlob(prepared).catch(() => {
        });
        return;
      }
      const previousPrepared = lastPrepared;
      video.pause();
      video.removeAttribute("src");
      video.load();
      lastPrepared = prepared;
      if (previousPrepared && previousPrepared !== prepared) await discardMovieBlob(previousPrepared).catch(() => {
      });
      if (runController.signal.aborted || token !== generation) {
        if (lastPrepared === prepared) lastPrepared = null;
        await discardMovieBlob(prepared).catch(() => {
        });
        return;
      }
      video.src = movieObjectUrl(prepared);
      video.load();
      fps = Number((_d = result.meta) == null ? void 0 : _d.fps) > 0 ? Number(result.meta.fps) : 30;
      const status = document.getElementById("status");
      if (status) {
        status.dataset.state = "ok";
        status.textContent = "Movie prepared on this device.";
      }
      const meta = document.getElementById("meta");
      if (meta) meta.textContent = [((_e = result.meta) == null ? void 0 : _e.width) && ((_f = result.meta) == null ? void 0 : _f.height) ? result.meta.width + "×" + result.meta.height : "", fps + " fps", ((_g = result.meta) == null ? void 0 : _g.path) || ""].filter(Boolean).join(" · ");
      let ticks = 0;
      watch = setInterval(() => {
        const status2 = document.getElementById("status");
        if ((status2 == null ? void 0 : status2.dataset.state) === "err") {
          clearInterval(watch);
          active = false;
          load.disabled = false;
          cancel.disabled = true;
          detail.textContent = "The movie could not be prepared on this device. Open player tools for details or import a complete replacement resource.";
          return;
        }
        if (video.src && video.readyState >= 2 && video.videoWidth > 0) {
          clearInterval(watch);
          active = false;
          load.disabled = false;
          cancel.disabled = true;
          previous.disabled = false;
          next.disabled = false;
          detail.textContent = "Ready. Press play below to watch the movie.";
          void video.play().catch(() => {
            detail.textContent = "Ready. Tap play on the movie below.";
          });
        } else if (++ticks > 1800) {
          clearInterval(watch);
          active = false;
          load.disabled = false;
          cancel.disabled = true;
          detail.textContent = "Movie preparation is taking too long. Try another movie or open player tools for details.";
        }
      }, 250);
    } catch (error) {
      if (token !== generation) return;
      if (error.name !== "AbortError") detail.textContent = error.message;
      active = false;
      load.disabled = false;
      cancel.disabled = true;
    }
  };
  const timer = setInterval(() => {
    if (connectVideo()) {
      clearInterval(timer);
    }
  }, 100);
  setTimeout(() => clearInterval(timer), 3e4);
  window.addEventListener("pagehide", () => {
    controller == null ? void 0 : controller.abort();
    window.dispatchEvent(new Event("forge-media-cancel"));
    clearInterval(watch);
    clearInterval(timer);
  }, { once: true });

  // In-app player: start by itself, and when a part was chosen ("Play this part") play only
  // that part, over and over, until another preview replaces it.
  if (request.dock) {
    const compact = document.createElement("style");
    compact.textContent = "#forge-movie-bar{padding:10px 12px!important}#forge-movie-bar h1{font-size:1rem!important;margin:0 0 4px!important}#forge-movie-bar button{min-width:0!important;padding:8px 10px!important;font-size:13px!important}#video{max-height:calc(100vh - 150px)!important}";
    document.head.append(compact);
    if (request.autoplay) {
      let tries = 0;
      const auto = setInterval(() => {
        if (++tries > 200) return clearInterval(auto);
        if (connectVideo() && !load.disabled) { clearInterval(auto); load.click(); }
      }, 150);
    }
  }
  const trim = request.trim && Number.isFinite(Number(request.trim.from)) && Number.isFinite(Number(request.trim.to)) && Number(request.trim.to) > Number(request.trim.from) ? { from: Math.max(0, Number(request.trim.from)), to: Number(request.trim.to) } : null;
  if (trim) {
    const clockText = (v) => Math.floor(v / 60) + ":" + String(Math.floor(v % 60)).padStart(2, "0") + "." + String(Math.round((v % 1) * 100)).padStart(2, "0").slice(0, 2);
    title.textContent = (request.name || "Movie") + " · your cut " + clockText(trim.from) + "–" + clockText(trim.to);
    let hooked = null;
    const hook = setInterval(() => {
      if (!video || hooked === video) return;
      hooked = video;
      const seekStart = () => { try { video.currentTime = trim.from; } catch {} };
      video.addEventListener("loadedmetadata", seekStart);
      video.addEventListener("play", () => { if (video.currentTime < trim.from - 0.05 || video.currentTime >= trim.to) seekStart(); });
      video.addEventListener("timeupdate", () => {
        if (video.currentTime >= trim.to - 0.02) { seekStart(); if (video.paused) void video.play().catch(() => {}); }
      });
      video.addEventListener("ended", () => { seekStart(); void video.play().catch(() => {}); });
      if (video.readyState >= 1) seekStart();
    }, 200);
    window.addEventListener("pagehide", () => clearInterval(hook), { once: true });
  }
})();
