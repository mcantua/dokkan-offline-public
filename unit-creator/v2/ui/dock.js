"use strict";
// In-app animation player. Previews play in a panel at the top of this screen (native side:
// PreviewDock). This keeps the page informed of the panel and lets Back shrink or close it.
window.ForgeDock = (() => {
  let state = "closed";
  function native(next) {
    // The player crashed or could not open: the panel shows a message; the page should stop
    // waiting for it (the editor's monitor resets and the next Play opens it again).
    if (next === "failed") { window.dispatchEvent(new CustomEvent("forge-dock-failed")); return; }
    state = next === "full" || next === "docked" ? next : "closed";
    document.documentElement.classList.toggle("dock-open", state !== "closed");
    window.dispatchEvent(new CustomEvent("forge-dock-state", { detail: { state } }));
  }
  // The player reports where it is (frames at 60 per second) so the editor's timeline can follow.
  function position(frame, last, status) {
    window.dispatchEvent(new CustomEvent("forge-dock-position", { detail: { frame: Number(frame) || 0, last: Number(last) || 0, status: String(status || "s") } }));
  }
  const seek = (frame, play = false) => Native.call("previewDock", { action: "seek", frame: Math.max(0, Math.round(frame)), play: Boolean(play) });
  const play = () => Native.call("previewDock", { action: "play" });
  const pause = () => Native.call("previewDock", { action: "pause" });
  const previous = window.forgeHandleBack;
  window.forgeHandleBack = () => {
    const busy = document.getElementById("busy");
    if (busy && !busy.hidden) return true;
    if (state === "full") {
      Native.call("previewDock", { action: "dock" }).catch(() => {});
      state = "docked";
      return true;
    }
    if (document.querySelector("dialog[open]")) return previous ? previous() : false;
    if (state === "docked") {
      Native.call("previewDock", { action: "close" }).catch(() => {});
      native("closed");
      return true;
    }
    return previous ? previous() : false;
  };
  async function separateWindow(value) {
    if (value !== undefined) dockableCache = null;
    return Native.call("previewDock", value === undefined ? {} : { action: "set", separateWindow: Boolean(value) });
  }
  // Steady 30 fps previews (the game's own frame rate). Older app builds simply ignore it.
  async function smooth(value) {
    return Native.call("previewDock", value === undefined ? {} : { action: "set", smooth: Boolean(value) });
  }
  // Preview quality: "auto" (recommended), "smooth" or "best"; and whether the player opens full screen.
  async function quality(value) {
    return Native.call("previewDock", value === undefined ? {} : { action: "set", quality: String(value) });
  }
  async function startFull(value) {
    return Native.call("previewDock", value === undefined ? {} : { action: "set", startFull: Boolean(value) });
  }
  // Whether previews open in the in-app panel (false with "separate window" or an old WebView).
  let dockableCache = null;
  async function dockable() {
    if (dockableCache !== null) return dockableCache;
    try { const r = await Native.call("previewDock", {}); dockableCache = r && r.dockable !== undefined ? Boolean(r.dockable) : !(r && r.separateWindow); } catch (e) { return true; }
    return dockableCache;
  }
  const forgetDockable = () => { dockableCache = null; };
  return { native, dockable, forgetDockable, position, seek, play, pause, state: () => state, separateWindow, smooth, quality, startFull, close: () => Native.call("previewDock", { action: "close" }) };
})();
