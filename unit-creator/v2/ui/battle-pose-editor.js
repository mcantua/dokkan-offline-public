"use strict";
window.ForgeBattlePoseEditor = (() => {
  const LIMIT = 12 * 1024 * 1024;
  function decode(value) {
    if (typeof value !== "string" || value.length > Math.ceil(LIMIT / 3) * 4) throw Error("Choose a fighter animation of 12 MB or less.");
    const text = atob(value);
    if (text.length > LIMIT) throw Error("Choose a fighter animation of 12 MB or less.");
    const bytes = new Uint8Array(text.length);
    for (let i = 0; i < text.length; i++) bytes[i] = text.charCodeAt(i);
    return bytes;
  }
  function encode(bytes) {
    if (!(bytes instanceof Uint8Array) || bytes.length > LIMIT) throw Error("The fighter animation exceeds the editor limit.");
    const chunks = [];
    for (let i = 0; i < bytes.length; i += 32768) chunks.push(String.fromCharCode(...bytes.subarray(i, i + 32768)));
    return btoa(chunks.join(""));
  }
  async function open() {
    var _a;
    if (!state.project) throw Error("Create or open a unit first.");
    const project = state.project, key = project.key, M = ForgeBattlePoses;
    let catalog = [], info, original = null, available = [], draft = Forge.clone(((_a = project.battlePoseBinding) == null ? void 0 : _a.bindings) || []), working = false, request = 0, identityAudit = null, sourceCharacter = null, loadError = "";
    const connected = () => {
      var _a2, _b;
      return state.project === project && ((_a2 = document.querySelector("#battle-pose-body")) == null ? void 0 : _a2.isConnected) && ((_b = document.querySelector("#dialog")) == null ? void 0 : _b.open);
    };
    dialog("Customize battle poses", '<div id="battle-pose-body"><p role="status">Finding this fighter’s original poses…</p></div>');
    const body = () => document.querySelector("#battle-pose-body");
    const read = async (assetKey) => decode((await Native.call("readAsset", { key: assetKey, maxBytes: LIMIT })).base64), store = async (bytes, options = {}) => Native.call("storeLwf", { name: options.name || "Custom battle poses", data: encode(bytes) });
    function status(text, error = false) {
      if (!connected()) return;
      const node = body().querySelector("#battle-pose-status");
      if (node) {
        node.textContent = text;
        node.setAttribute("role", error ? "alert" : "status");
      }
    }
    async function files() {
      const result = [], root = M.inspect(project, []).root;
      for (let offset = 0; offset < 1e5; offset += 500) {
        const rows = await Native.call("assets", { query: root, offset, limit: 500 });
        if (!connected()) return [];
        result.push(...rows);
        if (rows.length < 500) return result;
      }
      throw Error("This resource collection has too many matching files. Choose a smaller complete fighter pack.");
    }
    function poseName(key2) {
      var _a2;
      return ((_a2 = available.find((pose) => pose.key === key2)) == null ? void 0 : _a2.label) || "Unavailable source pose";
    }
    function canApply() {
      return !!original && !!(identityAudit == null ? void 0 : identityAudit.checked) && identityAudit.legacyRawCharacterConditions === 0 && draft.length > 0 && draft.every((item) => available.some((pose) => pose.key === item.target) && available.some((pose) => pose.key === item.source));
    }
    function updateButtons() {
      var _a2, _b, _c;
      if (!connected()) return;
      const apply2 = body().querySelector("#battle-pose-apply"), target = (_a2 = body().querySelector("#battle-pose-target")) == null ? void 0 : _a2.value, source = (_b = body().querySelector("#battle-pose-source")) == null ? void 0 : _b.value, choice = source === "original" || source === target ? null : source, pending = !!target && choice !== (((_c = draft.find((item) => item.target === target)) == null ? void 0 : _c.source) || null);
      if (apply2) apply2.disabled = working || !canApply() || pending;
    }
    async function run(work) {
      if (working) return;
      working = true;
      body().querySelectorAll("button,select,input").forEach((node) => node.disabled = true);
      try {
        await work();
      } catch (error) {
        status(error.message || "The battle poses could not be updated.", true);
      } finally {
        working = false;
        if (connected()) {
          body().querySelectorAll("button,select,input").forEach((node) => node.disabled = false);
          const group = body().querySelector("#battle-pose-group");
          if (group && !info.groups.length) group.disabled = true;
          updateButtons();
        }
      }
    }
    function render() {
      var _a2, _b, _c, _d;
      if (!connected()) return;
      const ready = !!original && !info.missing.length;
      body().innerHTML = '<p>Change the pose your fighter uses for an existing battle action. For example, make Dash use a punch pose. The action keeps its gameplay rules; its visual pose changes for this custom unit.</p><p class="hint">Choose from this fighter’s compatible built-in poses. The editor updates both your unit’s and the opponent’s view. New launcher or victory game events are not added. Exported poses still need actual Eclipse gameplay verification.</p><label class="field">Original fighter resources<select id="battle-pose-group">' + (info.groups.length > 1 ? '<option value="">Choose an imported build</option>' : "") + info.groups.map((group2, index) => '<option value="' + esc(group2) + '"' + (group2 === info.group ? " selected" : "") + ">" + esc(group2 === "saved-custom-fighter" ? "Saved unit fighter resources" : "Imported fighter pack " + (index + 1)) + "</option>").join("") + "</select></label>" + (!ready ? '<div class="notice"><strong>Complete original fighter resources are needed</strong><p>' + esc(loadError || (!info.group && info.groups.length ? "Choose one imported build above." : "Import this fighter’s battle, idle and matching Super Attack packs, including their texture pictures.")) + '</p><div class="row"><button class="button ghost" id="battle-pose-import">Import fighter resources</button><button class="button ghost" id="battle-pose-download">Get original fighter online</button></div></div>' : "") + ((identityAudit == null ? void 0 : identityAudit.legacyRawCharacterConditions) ? '<p class="notice warning">This database contains older character-identity rules. A private fighter could change who those rules recognize. Keep the original fighter, or import a compatible database before applying pose replacements.</p>' : "") + '<p id="battle-pose-status" role="status" aria-live="polite"></p>' + (ready ? '<div class="field-grid"><label class="field">Battle action to change<select id="battle-pose-target">' + selection(available.map((pose) => [pose.key, pose.label]), available.some((pose) => pose.key === "dash") ? "dash" : (_a2 = available[0]) == null ? void 0 : _a2.key) + '</select></label><label class="field">Pose it should use<select id="battle-pose-source"><option value="original">Keep the original pose</option>' + available.map((pose) => '<option value="' + esc(pose.key) + '">' + esc(pose.label) + "</option>").join("") + '</select></label><label class="field">Preview side<select id="battle-pose-side"><option value="player">Your unit</option><option value="enemy">Opponent</option></select></label></div><div class="row"><button class="button ghost" id="battle-pose-preview-original">Preview original action</button><button class="button ghost" id="battle-pose-preview-choice">Preview chosen replacement</button><button class="button" id="battle-pose-add">Update this pose choice</button></div><h3>Your pose replacements</h3><div id="battle-pose-bindings"></div><button class="button" id="battle-pose-apply">Use these poses in the game</button>' : "") + (project.battlePoseBinding ? '<p class="hint">Restoring removes only this unit’s private fighter resources and pose choices. Imported resources and your other customizations are kept.</p><button class="button subtle" id="battle-pose-restore">Restore original battle poses</button>' : "");
      const group = body().querySelector("#battle-pose-group");
      group.disabled = !info.groups.length;
      group.onchange = () => run(async () => {
        info = M.inspect(project, catalog, { group: group.value || void 0 });
        await loadOriginal();
        render();
      });
      (_b = body().querySelector("#battle-pose-import")) == null ? void 0 : _b.addEventListener("click", () => run(async () => {
        var _a3;
        const result = await Native.call("import");
        if (!(result == null ? void 0 : result.kind)) return;
        state.info = result.info || await Native.call("info");
        await loadLookups();
        rememberImportResult(result);
        catalog = await files();
        if (!connected()) return;
        info = M.inspect(project, catalog, { group: info.group || void 0 });
        await audit();
        await loadOriginal();
        render();
        if ((_a3 = result.warnings) == null ? void 0 : _a3.length) status("Some resource archives could not be opened. Review Last import results in Game content.", true);
      }));
      (_c = body().querySelector("#battle-pose-download")) == null ? void 0 : _c.addEventListener("click", () => run(download));
      (_d = body().querySelector("#battle-pose-restore")) == null ? void 0 : _d.addEventListener("click", () => run(async () => {
        M.restore(project);
        scheduleSave();
        await flushSave();
        renderEditor();
        document.querySelector("#dialog").close();
        toast("Original battle poses restored. Your imported resources were kept.");
      }));
      if (!ready) return;
      const target = body().querySelector("#battle-pose-target"), source = body().querySelector("#battle-pose-source");
      const selectTarget = () => {
        var _a3;
        source.value = ((_a3 = draft.find((item) => item.target === target.value)) == null ? void 0 : _a3.source) || "original";
        updateButtons();
      };
      target.onchange = selectTarget;
      source.onchange = () => {
        updateButtons();
        status("Preview the choice, then press Update this pose choice to add it to your draft.");
      };
      selectTarget();
      body().querySelector("#battle-pose-add").onclick = () => {
        draft = draft.filter((item) => item.target !== target.value);
        if (source.value !== "original" && source.value !== target.value) draft.push({ target: target.value, source: source.value });
        renderBindings();
        status("Pose choice updated in this draft. Apply the choices to save them to your unit.");
      };
      body().querySelector("#battle-pose-preview-original").onclick = () => run(() => preview(false));
      body().querySelector("#battle-pose-preview-choice").onclick = () => run(() => preview(true));
      body().querySelector("#battle-pose-apply").onclick = () => run(apply);
      renderBindings();
      updateButtons();
    }
    function renderBindings() {
      const node = body().querySelector("#battle-pose-bindings");
      if (!node) return;
      node.innerHTML = draft.length ? draft.map((item, index) => '<p class="battle-pose-binding"><span>' + esc(poseName(item.target)) + " → " + esc(poseName(item.source)) + '</span><button class="icon-button" data-remove-pose="' + index + '" aria-label="Remove replacement for ' + esc(poseName(item.target)) + '">×</button></p>').join("") : '<p class="hint">No replacements yet. Choose an action and a pose, then update the choice.</p>';
      node.querySelectorAll("[data-remove-pose]").forEach((button) => button.onclick = () => {
        var _a2;
        draft.splice(Number(button.dataset.removePose), 1);
        renderBindings();
        const target = body().querySelector("#battle-pose-target");
        body().querySelector("#battle-pose-source").value = ((_a2 = draft.find((item) => item.target === target.value)) == null ? void 0 : _a2.source) || "original";
        updateButtons();
      });
      updateButtons();
    }
    async function audit() {
      var _a2;
      if (!state.info.schema.skill_causalities || !state.info.schema.characters) throw Error("This database does not include the fighter identity records needed for safe pose editing.");
      const legacy = await Promise.all([22, 29].map((type) => Native.call("query", { table: "skill_causalities", filters: { causality_type: type }, limit: 1 })));
      identityAudit = { checked: true, legacyRawCharacterConditions: legacy.reduce((count, rows) => count + rows.length, 0) + (project.tables.skill_causalities || []).filter((row) => [22, 29].includes(Number(row.causality_type))).length };
      sourceCharacter = ((_a2 = project.battlePoseBinding) == null ? void 0 : _a2.sourceCharacter) || (await Native.call("query", { table: "characters", filters: { id: info.sourceId }, limit: 1 }))[0];
      if (!sourceCharacter) throw Error("This source fighter is missing from the current database. Import its complete game build first.");
    }
    async function loadOriginal() {
      const token = ++request;
      original = null;
      available = [];
      loadError = "";
      if (!info.group || info.missing.length) return;
      const asset = info.sourceAssets.find((item) => item.path === info.battlePath);
      try {
        const bytes = await read(asset.key), parsed = M.inspectLwf(bytes);
        if (!connected() || token !== request) return;
        if (!parsed.available.length) throw Error("This fighter has no compatible named battle poses in its source pack.");
        original = bytes;
        available = parsed.available;
      } catch (error) {
        if (token === request) loadError = error.message;
      }
    }
    async function preview(chosen) {
      const target = body().querySelector("#battle-pose-target").value, source = body().querySelector("#battle-pose-source").value, side = body().querySelector("#battle-pose-side").value, pose = available.find((item) => item.key === target);
      let assets = info.sourceAssets.map((item) => ({ path: item.path, key: item.key }));
      if (chosen && source !== "original" && source !== target) {
        const assignments = [...draft.filter((item) => item.target !== target), { target, source }], patched = M.remap(original, assignments), stored = await store(patched.bytes, { name: "Pose preview" });
        if (!connected()) return;
        assets = assets.map((item) => item.path === info.battlePath ? { ...item, key: stored.key } : item);
      }
      await Native.call("previewAnimation", { mode: "pack", resourcePath: info.battlePath, scene: pose[side + "Scene"], name: pose.label + (chosen ? " · chosen pose" : " · original"), assets });
    }
    async function apply() {
      var _a2;
      if (!canApply()) throw Error("Choose compatible pose replacements and a database with safe fighter identity rules first.");
      const occupied = (await Native.call("query", { table: "characters", filters: { id: info.privateId }, limit: 1 })).map((row) => row.id);
      for (const other of await Native.call("projects")) if (other.key !== key && Number(other.targetId) === info.privateId) occupied.push(info.privateId);
      const plan = await M.plan(project, catalog, { group: info.group, assignments: draft, sourceCharacter, characterSchema: ((_a2 = project.battlePoseBinding) == null ? void 0 : _a2.characterSchema) || state.info.schema.characters, identityAudit, occupiedCharacterIds: occupied, readAsset: read, storeLwf: store });
      if (!connected()) throw Error("The selected creation changed. Open its pose editor again.");
      M.apply(project, plan);
      scheduleSave();
      await flushSave();
      renderEditor();
      document.querySelector("#dialog").close();
      toast("Private battle poses saved. Export the Eclipse patch and test actual gameplay.");
    }
    async function download() {
      var _a2;
      const motion = String(Number(project.tables.cards[0].special_motion) || 0).padStart(2, "0"), roots = [info.root + "battle", info.root + "idle", info.root + "sp" + motion], found = /* @__PURE__ */ new Map();
      let dirs = 0, total = 0;
      for (const root of roots) {
        const queue = [root];
        while (queue.length) {
          const folder = queue.shift();
          if (++dirs > 32) throw Error("This fighter pack has too many folders. Import a verified resource build instead.");
          status("Finding original fighter resources…");
          const listing = await Native.call("browseAssets", { path: folder });
          if (!connected()) return;
          if (listing.error || !Array.isArray(listing.items) || !listing.items.length) throw Error("The original fighter pack is unavailable online. Import a complete authorized resource build instead.");
          for (const item of listing.items) {
            if (!Forge.safePath(item.path) || !item.path.startsWith(root + "/")) throw Error("The fighter listing contains an unexpected file location.");
            if (item.type === "directory") {
              queue.push(item.path);
              continue;
            }
            if (!/\.(?:png|lwf|json|fnt|txt|plist|bin|fsh|vsh)$/i.test(item.path)) continue;
            const size = Number(item.size);
            if (!Number.isSafeInteger(size) || size < 1 || size > LIMIT) throw Error("A fighter resource exceeds the 12 MB editor limit. Import a verified compatible resource build.");
            if (!found.has(item.path)) {
              total += size;
              found.set(item.path, item);
              if (found.size > 200 || total > 128 * 1024 * 1024) throw Error("This fighter pack exceeds the download limit. Import a verified resource build instead.");
            }
          }
        }
      }
      if (!found.size) throw Error("No compatible fighter files were found. Import a complete resource build instead.");
      const group = "art-download-" + Date.now() + "-" + Math.random().toString(36).slice(2, 14).padEnd(8, "0");
      let count = 0;
      for (const item of found.values()) {
        if (!connected()) return;
        status("Downloading original fighter resources: " + ++count + " of " + found.size + ".");
        const saved = await Native.call("downloadAsset", { path: item.path, group });
        if (!((_a2 = saved.key) == null ? void 0 : _a2.startsWith(group + "/"))) throw Error("Update this app to store original fighter resources in a protected collection.");
        if (Number(saved.size) !== Number(item.size)) throw Error("A fighter resource changed while downloading. Try again.");
      }
      catalog = await files();
      if (!connected()) return;
      info = M.inspect(project, catalog, { group });
      await loadOriginal();
      render();
      status("Original fighter resources downloaded. Choose an action and its replacement pose.");
    }
    try {
      catalog = await files();
      if (!connected()) return;
      info = M.inspect(project, catalog);
      await audit();
      await loadOriginal();
      render();
    } catch (error) {
      if (connected()) body().innerHTML = '<p class="notice" role="alert">' + esc(error.message) + "</p>";
    }
  }
  return { open, decode, encode };
})();
