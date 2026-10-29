"use strict";
window.ForgePreviewStorage = (() => {
  const sizes = [["512 MB", 512 * 1024 ** 2], ...[1, 2, 4, 8, 16, 32].map((n) => [n + " GB", n * 1024 ** 3])];
  let sequence = 0;
  async function mount(container, options = {}) {
    if (!container) return;
    const id = "preview-storage-" + ++sequence, alive = () => container.isConnected && (!options.connected || options.connected());
    container.innerHTML = '<p class="hint" role="status">Checking downloaded previews…</p>';
    let busy = false, tools = null;
    async function render(cache, message = "") {
      var _a, _b;
      tools == null ? void 0 : tools.dispose();
      tools = null;
      if (!alive()) return;
      const expanded = ((_a = container.querySelector("details")) == null ? void 0 : _a.open) || false;
      const bytes = Number(cache.bytes) || 0, max = Number(cache.maxBytes) || 2 * 1024 ** 3, count = Number(cache.count) || 0;
      container.innerHTML = '<div class="preview-storage">' + (window.ForgeOffline ? '<div class="offline-callout"><p><strong>Skip the waiting.</strong> Download animations and pictures to this phone once, then everything opens instantly, even offline.</p>' + ForgeOffline.button("Download for offline…", "") + "</div>" : "") + '<label class="check-item"><input type="checkbox" id="' + id + '-offline"' + (cache.offline ? " checked" : "") + '>Offline preview · use downloaded files only</label><p class="hint">Play an animation or prepare a movie online once to save its resources. Missing files still need a connection.</p><details><summary>Downloaded preview storage</summary><p class="hint" role="status" data-preview-usage>' + count + " saved resources · " + (bytes / 1048576).toFixed(1) + " MB used of " + (((_b = sizes.find((x) => x[1] === max)) == null ? void 0 : _b[0]) || "2 GB") + '</p><label class="field">Space allowed for downloaded previews<select id="' + id + '-budget">' + sizes.map(([label, value]) => '<option value="' + value + '"' + (value === max ? " selected" : "") + ">" + label + "</option>").join("") + '</select></label><p class="hint">Changing this limit keeps existing files. If storage is full, increase the limit or clear downloaded previews.</p>' + (bytes > max ? '<p class="notice">Existing downloads exceed this limit. Increase it or clear downloaded previews before downloading more.</p>' : "") + '<div class="row"><button type="button" class="button ghost small" data-preview-refresh>Refresh usage</button><button type="button" class="button subtle small" data-preview-clear>Clear downloaded previews</button></div></details><p class="hint" role="status" aria-live="polite" data-preview-message>' + esc(message) + "</p><div data-preview-tools></div></div>";
      const find = (selector) => container.querySelector(selector);
      find("details").open = expanded;
      find("#" + id + "-offline").onchange = (event) => update({ offline: event.target.checked }, "Preview mode saved. Reopen previews to use this setting.").catch(() => {
      });
      find("#" + id + "-budget").onchange = (event) => update({ maxBytes: Number(event.target.value) }, "Preview storage size saved. Existing downloads were kept.").catch(() => {
      });
      find("[data-preview-refresh]").onclick = () => update({}, "Preview storage usage updated.").catch(() => {
      });
      find("[data-preview-clear]").onclick = () => {
        dialog("Clear downloaded previews?", '<p>Downloaded animation players, movies, and preview resources will be removed from this device. You will need to download them again before offline playback.</p><p>Your created units, Library patches, project backups, and imported assets will stay on this device.</p><p>Close any open previews before continuing. Your storage limit and offline setting will be kept.</p><p id="preview-clear-error" role="alert"></p><div class="row"><button type="button" class="button ghost" id="preview-clear-cancel">Keep downloaded previews</button><button type="button" class="button" id="preview-clear-confirm">Clear downloaded previews</button></div>');
        document.querySelector("#preview-clear-cancel").onclick = () => document.querySelector("#dialog").close();
        document.querySelector("#preview-clear-confirm").onclick = async (event) => {
          event.target.disabled = true;
          try {
            await update({ clear: true }, "Downloaded previews cleared. Your units and imported assets were kept.");
            document.querySelector("#dialog").close();
            if (alive()) find("[data-preview-clear]").focus();
          } catch (error) {
            event.target.disabled = false;
            document.querySelector("#preview-clear-error").textContent = error.message || "Downloaded previews could not be cleared.";
          }
        };
      };
      if (window.ForgePreviewTools) tools = await ForgePreviewTools.mount(find("[data-preview-tools]"), { connected: alive });
    }
    async function update(args, message) {
      var _a;
      if (busy) return;
      const active = document.activeElement, focus = container.contains(active) ? active.id ? "#" + active.id : active.hasAttribute("data-preview-refresh") ? "[data-preview-refresh]" : null : null;
      busy = true;
      container.querySelectorAll("input,select,button").forEach((e) => e.disabled = true);
      try {
        const cache = await Native.call("previewCache", args);
        await render(cache, message);
        if (alive() && focus) (_a = container.querySelector(focus)) == null ? void 0 : _a.focus();
        return cache;
      } catch (error) {
        if (alive()) {
          container.querySelectorAll("input,select,button").forEach((e) => e.disabled = false);
          container.querySelector("[data-preview-message]").textContent = error.message || "Preview storage could not be updated.";
        }
        throw error;
      } finally {
        busy = false;
      }
    }
    try {
      await render(await Native.call("previewCache"));
    } catch (error) {
      if (alive()) container.textContent = error.message || "Preview storage is unavailable.";
    }
  }
  return { mount };
})();
