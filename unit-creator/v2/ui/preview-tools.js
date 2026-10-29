(function(root, factory) {
  const api = factory();
  if (typeof module === "object" && module.exports) module.exports = api;
  else root.ForgePreviewTools = api;
})(typeof window === "object" ? window : globalThis, function() {
  "use strict";
  function count(value) {
    return Number.isSafeInteger(value) && value >= 0 ? value : 0;
  }
  function state(value) {
    const s = value && typeof value === "object" ? value : {};
    return { ready: s.ready === true, preparing: s.preparing === true, offline: s.offline === true, preparedFiles: count(s.preparedFiles), totalFiles: count(s.totalFiles), preparedBytes: count(s.preparedBytes), totalBytes: count(s.totalBytes), missingFiles: count(s.missingFiles), invalidFiles: count(s.invalidFiles), failures: Array.isArray(s.failures) ? s.failures.slice(0, 20) : [], currentLabel: typeof s.currentLabel === "string" ? s.currentLabel.slice(0, 160) : "", version: typeof s.version === "string" ? s.version : "" };
  }
  function description(value) {
    const s = state(value);
    if (s.ready) return "Preview tools are saved on this device. Each scene still needs its game assets.";
    if (s.preparing) return "Saving preview tools: " + s.preparedFiles + " of " + s.totalFiles + " files.";
    if (s.offline) return "To prepare the player for offline use, switch off “Offline preview” and connect once.";
    if (s.preparedFiles) return "Saved " + s.preparedFiles + " of " + s.totalFiles + " tool files. Prepare again to download the rest.";
    return "Connect once to save the animation and movie players. Then use imported game resources or scenes you have saved.";
  }
  async function mount(container, { connected = () => (container == null ? void 0 : container.isConnected) !== false } = {}) {
    if (!container) return;
    container.innerHTML = '<section class="notice preview-tools" aria-label="Offline preview tools"><h3>Prepare offline preview tools</h3><p class="hint">Save the player itself separately from character and movie files. This downloads public player tools to your device.</p><p data-tools-status role="status" aria-live="polite">Checking saved tools…</p><progress data-tools-progress max="1" value="0" aria-label="Preview tool files saved" hidden></progress><div class="row"><button type="button" class="button ghost small" data-tools-prepare disabled>Prepare preview tools</button><button type="button" class="button subtle small" data-tools-refresh disabled>Check tools</button></div><details data-tools-details hidden><summary>Download details</summary><p class="hint" data-tools-errors></p></details></section>';
    const find = (selector) => container.querySelector(selector), status = find("[data-tools-status]"), progress = find("[data-tools-progress]"), prepare = find("[data-tools-prepare]"), refresh = find("[data-tools-refresh]"), details = find("[data-tools-details]"), errors = find("[data-tools-errors]");
    let active = false, timer = null, polling = false, last = {};
    const stop = () => {
      if (timer) {
        clearInterval(timer);
        timer = null;
      }
    };
    function draw(value) {
      if (!connected()) {
        stop();
        return;
      }
      last = state(value);
      status.textContent = description(last);
      progress.hidden = !last.preparing;
      progress.max = Math.max(1, last.totalFiles);
      progress.value = Math.min(last.preparedFiles, progress.max);
      prepare.disabled = active || last.preparing || last.offline;
      prepare.textContent = last.ready ? "Check and repair tools" : last.preparing ? "Saving preview tools…" : last.preparedFiles ? "Finish preparing tools" : "Prepare preview tools";
      refresh.disabled = active;
      details.hidden = !last.failures.length;
      errors.textContent = last.failures.map((f) => String(f.path || "Tool file") + ": " + String(f.message || "Download could not finish.")).join("\n");
      errors.style.whiteSpace = "pre-wrap";
      if (last.preparing && !timer) timer = setInterval(() => {
        void check();
      }, 1e3);
      else if (!last.preparing) stop();
    }
    async function check() {
      if (!connected()) {
        stop();
        return;
      }
      if (polling) return;
      polling = true;
      try {
        draw(await Native.call("previewTools", {}));
      } catch (error) {
        if (connected()) {
          status.textContent = "Saved preview tools could not be checked. Try again when the app is ready.";
          details.hidden = false;
          errors.textContent = error.message || String(error);
          refresh.disabled = active;
        }
      } finally {
        polling = false;
      }
    }
    refresh.onclick = () => {
      void check();
    };
    prepare.onclick = async () => {
      if (active || last.offline) return;
      active = true;
      draw({ ...last, preparing: true });
      try {
        draw(await Native.call("previewTools", { prepare: true }));
      } catch (error) {
        if (connected()) {
          status.textContent = "The tools could not finish downloading. Check your connection and try again.";
          details.hidden = false;
          errors.textContent = error.message || String(error);
        }
      } finally {
        active = false;
        if (connected()) {
          prepare.disabled = last.offline || last.preparing;
          refresh.disabled = false;
        }
        void check();
      }
    };
    await check();
    return { refresh: check, dispose: stop };
  }
  return { mount, state, description };
});
