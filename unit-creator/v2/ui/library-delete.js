/* Library housekeeping: delete saved unit designs and imported patches from this device. */
(function() {
  "use strict";
  if (typeof renderLibraryResults !== "function" || typeof showPatch !== "function") return;
  const priorResults = renderLibraryResults, priorPatch = showPatch;
  let working = false;

  function forgetDrafts(key) {
    try {
      const draft = JSON.parse(localStorage.getItem("forge-draft") || "null");
      if (draft && draft.key === key) localStorage.removeItem("forge-draft");
      localStorage.removeItem("forge-conflict-backup-" + key);
    } catch {}
  }

  function confirmDelete(title, body, label, work) {
    dialog(title, body + '<div class="row"><button class="button" id="library-delete-confirm">' + esc(label) + '</button><button class="button ghost" id="library-delete-cancel">Cancel</button></div>');
    const modal = $("#dialog");
    $("#library-delete-cancel").onclick = () => modal.close();
    $("#library-delete-confirm").onclick = async () => {
      if (working) return;
      working = true;
      modal.close();
      try {
        await busy("Deleting from this device", work);
      } finally {
        working = false;
      }
    };
  }

  async function refreshLibrary() {
    [state.projects, state.patches] = await Promise.all([Native.call("projects"), Native.call("patches")]);
    if (state.view === "library") (typeof renderLibrary === "function" ? renderLibrary : renderLibraryResults)();
  }

  function deleteUnit(meta) {
    confirmDelete("Delete this unit?", "<p><strong>" + esc(meta.name || "Saved unit") + "</strong> and its saved versions will be removed from this device. Eclipse files you already exported and imported artwork are not affected.</p><p>This cannot be undone. Save an editable backup first if you may need it again.</p>", "Delete unit", async () => {
      await flushSave();
      const open = state.project && (state.project.key === meta.key || (window.ForgeFormsUI && typeof ForgeFormsUI.root === "function" && ForgeFormsUI.root() && ForgeFormsUI.root().key === meta.key));
      const result = await Native.call("deleteProject", { key: meta.key });
      if (!result || result.deleted !== true) throw new Error("Deleting this unit could not be confirmed.");
      if (open) {
        clearTimeout(saveTimer);
        state.project = null;
        state.previewUrl = "";
      }
      forgetDrafts(meta.key);
      await refreshLibrary();
      toast("Unit deleted from this device.");
    });
  }

  function deletePatch(patch) {
    const name = patch.metadata && patch.metadata.name || patch.filename || "Eclipse patch";
    confirmDelete("Delete this patch?", "<p><strong>" + esc(name) + "</strong> will be removed from this Library. Copies you saved elsewhere are not affected" + (patch.projectKey ? ", and its editable unit stays in your Library" : "") + ".</p>", "Delete patch", async () => {
      const result = await Native.call("deletePatch", { key: patch.key });
      if (!result || result.deleted !== true) throw new Error("Deleting this patch could not be confirmed.");
      await refreshLibrary();
      toast("Patch deleted from this device.");
    });
  }

  renderLibraryResults = function(...args) {
    const result = priorResults.apply(this, args);
    const container = $("#library-results");
    if (!container) return result;
    container.querySelectorAll(".unit-tile[data-open]").forEach((tile) => {
      if (tile.parentElement && tile.parentElement.classList.contains("unit-tile-wrap")) return;
      const key = tile.dataset.open, meta = (state.projects || []).find((p) => p.key === key);
      if (!meta) return;
      const wrap = document.createElement("div");
      wrap.className = "unit-tile-wrap";
      tile.replaceWith(wrap);
      wrap.appendChild(tile);
      const remove = document.createElement("button");
      remove.type = "button";
      remove.className = "button subtle small tile-delete";
      remove.textContent = "🗑 Delete";
      remove.setAttribute("aria-label", "Delete " + (meta.name || "unit"));
      remove.addEventListener("click", (event) => {
        event.preventDefault();
        event.stopPropagation();
        deleteUnit(meta);
      });
      wrap.appendChild(remove);
    });
    return result;
  };

  showPatch = function(key, ...rest) {
    const result = priorPatch.call(this, key, ...rest);
    const patch = (state.patches || []).find((p) => p.key === key), content = $("#dialog-content");
    if (patch && content && $("#dialog").open && !$("#library-delete-patch")) {
      const row = document.createElement("div");
      row.className = "row";
      row.innerHTML = '<button class="button ghost" id="library-delete-patch">Delete this patch</button>';
      content.appendChild(row);
      $("#library-delete-patch").onclick = () => deletePatch(patch);
    }
    return result;
  };
})();
