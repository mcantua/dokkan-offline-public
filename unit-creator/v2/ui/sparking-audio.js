(function(root) {
  "use strict";
  const MAX_FILES = 128, MAX_FILE = 192 * 1024 * 1024, MAX_TOTAL = 512 * 1024 * 1024;
  const escape = value => String(value == null ? "" : value).replace(/[&<>"']/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
  const app = () => typeof state !== "undefined" ? state : root.state;
  const call = (method, args) => (typeof Native !== "undefined" ? Native : root.Native).call(method, args || {});
  const megabytes = bytes => (bytes / 1000000).toLocaleString(undefined, { minimumFractionDigits: 1, maximumFractionDigits: 1 }) + " MB";
  let active = null;

  function version(value) {
    if (!Number.isSafeInteger(value) || value < 1) throw Error("This unit has an invalid recorded Sparking content version. Its design was kept.");
    return value;
  }
  function sourceVersion(project) {
    const versions = [], add = value => { if (value != null) versions.push(version(value)); };
    if (project.source && project.source.database === "sparking" || /^sparking$/i.test(project.provenance && project.provenance.sourceDatabase || "")) add(project.provenance && project.provenance.sourceVersion);
    const dependencies = project.sourceDependencies;
    if (dependencies != null && (typeof dependencies !== "object" || Array.isArray(dependencies))) throw Error("This unit has invalid original resource metadata.");
    if (dependencies) {
      add(dependencies.sourceVersion);
      if (dependencies.animations != null && !Array.isArray(dependencies.animations)) throw Error("This unit has invalid original animation versions.");
      for (const animation of dependencies.animations || []) {
        if (!animation || typeof animation !== "object") throw Error("This unit has invalid original animation versions.");
        versions.push(version(animation.version));
      }
    }
    const unique = [...new Set(versions)];
    if (unique.length !== 1) throw Error(unique.length ? "This unit refers to different Sparking content versions. Use matching original resources before attaching audio." : "This unit has no unambiguous original Sparking content version. Reopen a Sparking copy or prepare its original animation sources first.");
    return unique[0];
  }
  function audioKind(path) {
    if (typeof path !== "string") throw Error("The audio catalogue contains an invalid bank path.");
    if (/^se\/[A-Za-z0-9_-]{1,80}\.(?:acb|awb)$/.test(path)) return "se";
    const voice = /^voice\/(?:(en|ja)\/)?([A-Za-z0-9_-]{1,80})\/([A-Za-z0-9_-]{1,80})\.(?:acb|awb)$/.exec(path);
    if (voice && voice[2] === voice[3]) return "voice";
    throw Error("The audio catalogue contains an unsupported game bank path.");
  }
  function safeKey(key) {
    return typeof key === "string" && key.length > 0 && key.length <= 500 && /^[A-Za-z0-9_./-]+$/.test(key) && key.split("/").every(part => part && part !== "." && part !== "..");
  }
  function size(value) {
    if (!Number.isSafeInteger(value) || value < 1 || value > MAX_FILE) throw Error("An audio bank exceeds the native 192 MiB file limit or has an invalid size.");
    return value;
  }
  function catalogue(result, expected) {
    if (!result || typeof result !== "object" || result.version !== expected || !Array.isArray(result.files) || !result.files.length || result.files.length > MAX_FILES) throw Error("The matching audio catalogue is missing, empty, or invalid. Your unit was kept.");
    const seen = new Set();
    return result.files.map(file => {
      if (!file || typeof file !== "object" || Array.isArray(file)) throw Error("The audio catalogue contains an invalid record.");
      const kind = audioKind(file.path), identity = file.path.toLowerCase();
      if (file.kind !== kind || seen.has(identity)) throw Error("The audio catalogue has conflicting bank paths or kinds.");
      seen.add(identity);
      return { path: file.path, bytes: size(file.bytes), kind };
    });
  }
  function plan(session, files) {
    if (!files.length) throw Error("Select sound effects, available voices, or both.");
    const bytes = files.reduce((sum, file) => sum + file.bytes, 0);
    if (bytes > MAX_TOTAL) throw Error("This selection exceeds the 512 MiB attachment limit. Choose a smaller audio group.");
    const assets = session.project.assets == null ? [] : session.project.assets;
    if (!Array.isArray(assets)) throw Error("This unit has an invalid attached-file list. Its original design was kept.");
    const owned = new Map();
    for (const asset of assets) {
      if (!asset || typeof asset !== "object" || typeof asset.path !== "string") throw Error("An existing attached file has invalid metadata. Its original design was kept.");
      const identity = asset.path.normalize("NFC").toLowerCase();
      if (owned.has(identity)) throw Error("Existing attached files have conflicting game paths. Resolve them before adding audio.");
      owned.set(identity, asset);
      if (asset.source === "sparking" && asset.sourceVersion != null && version(asset.sourceVersion) !== session.version) throw Error("An attached original file uses another Sparking version. Its files and your design were kept.");
    }
    const needed = [], reused = [];
    for (const file of files) {
      const prior = owned.get(file.path.toLowerCase());
      if (!prior) { needed.push(file); continue; }
      if (prior.path !== file.path || prior.source !== "sparking" || prior.sourceVersion !== session.version || prior.sourcePath != null && prior.sourcePath !== file.path || prior.size !== file.bytes || !safeKey(prior.key) || typeof prior.sha256 !== "string" || !/^[a-f0-9]{64}$/i.test(prior.sha256)) throw Error("A selected audio path already has a custom replacement or conflicting original metadata. Existing files were kept; resolve that bank before attaching originals.");
      reused.push(file);
    }
    return { files, bytes, needed, reused, downloadBytes: needed.reduce((sum, file) => sum + file.bytes, 0) };
  }
  function batchAssets(result, records, expected) {
    if (!result || typeof result !== "object" || result.sourceVersion !== expected || !Array.isArray(result.assets) || !result.assets.length || result.assets.length !== records.length || result.missing != null && (!Array.isArray(result.missing) || result.missing.length)) throw Error("An audio download returned incomplete or mismatched source files. No banks were attached.");
    const wanted = new Map(records.map(file => [file.path, file])), seen = new Set();
    return result.assets.map(asset => {
      if (!asset || typeof asset !== "object" || Array.isArray(asset)) throw Error("An audio download returned an invalid file reference.");
      audioKind(asset.path);
      const file = wanted.get(asset.path);
      if (!file || seen.has(asset.path.toLowerCase()) || asset.source !== "sparking" || asset.sourcePath != null && asset.sourcePath !== asset.path || asset.sourceVersion != null && asset.sourceVersion !== expected || asset.size !== file.bytes || !safeKey(asset.key) || typeof asset.sha256 !== "string" || !/^[a-f0-9]{64}$/i.test(asset.sha256)) throw Error("An audio download has conflicting paths, sizes, fingerprints, or source versions. No banks were attached.");
      seen.add(asset.path.toLowerCase());
      return { ...asset, source: "sparking", sourceVersion: expected };
    });
  }
  function unchanged(session) {
    if (session.cancelled || active !== session || !session.panel.isConnected || !session.modal.open) throw Error("Audio attachment cancelled. Finished downloads may remain cached; the unit was not changed.");
    if (!app() || app().project !== session.project || JSON.stringify(session.project) !== session.original) throw Error("Your unit changed while audio was being prepared. Downloaded files may remain cached; the unit was not changed.");
  }
  function cleanup(session) {
    session.modal.removeEventListener("close", session.close);
    session.modal.removeEventListener("cancel", session.cancel);
    if (session.observer) session.observer.disconnect();
  }
  function cancel(session) {
    if (session.committing) return;
    session.cancelled = true;
    cleanup(session);
    if (active === session) active = null;
  }
  function status(session, text, error) {
    if (active !== session || !session.panel.isConnected) return;
    const target = session.panel.querySelector("#sparking-audio-status");
    target.textContent = text;
    target.className = "hint" + (error ? " error" : "");
  }
  function selected(session) {
    const se = session.panel.querySelector("#sparking-audio-se").checked, voice = session.panel.querySelector("#sparking-audio-voice").checked;
    return session.files.filter(file => file.kind === "se" ? se : voice);
  }
  function update(session) {
    const button = session.panel.querySelector("#sparking-audio-download"), summary = session.panel.querySelector("#sparking-audio-total");
    try {
      unchanged(session);
      const selection = plan(session, selected(session));
      summary.textContent = selection.files.length + " selected files · " + megabytes(selection.bytes) + " total. " + selection.needed.length + " new files · " + megabytes(selection.downloadBytes) + " to download" + (selection.reused.length ? "; " + selection.reused.length + " matching files already attached." : ".");
      button.disabled = !selection.needed.length;
      button.textContent = selection.needed.length ? "Download and attach audio" : "Selected banks already attached";
      status(session, "All existing files and custom replacements will be kept.");
    } catch (error) { summary.textContent = ""; button.disabled = true; status(session, error.message, true); }
  }
  async function download(session) {
    if (session.working || session.done) return;
    const button = session.panel.querySelector("#sparking-audio-download"), cancelButton = session.panel.querySelector("#sparking-audio-cancel");
    let stagedProject = null, stagedText = null;
    try {
      unchanged(session);
      const selection = plan(session, selected(session));
      if (!selection.needed.length) return;
      session.working = true;
      button.disabled = true;
      session.panel.querySelectorAll("input").forEach(input => input.disabled = true);
      const staged = [];
      let completedBytes = 0;
      // Original game banks come from Eclipse (saved once for previews, not attached: Eclipse already has
      // them). Only Sparking's own custom banks are downloaded from Sparking.
      const custom = [], originals = [], SC = root.ForgeSparkingCustom;
      for (const file of selection.needed) {
        let original = false;
        try { original = SC ? await SC.isOriginal(file.path) : false; } catch (e) { original = false; }
        (original ? originals : custom).push(file);
      }
      for (let index = 0; index < originals.length; index++) {
        unchanged(session);
        status(session, "Saving original bank " + (index + 1) + " of " + originals.length + " from Eclipse…");
        await call("downloadAsset", { path: originals[index].path });
      }
      session.originals = originals.length;
      for (let index = 0; index < custom.length; index += 8) {
        unchanged(session);
        const records = custom.slice(index, index + 8);
        status(session, "Downloading Sparking's files " + (index + 1) + "–" + (index + records.length) + " of " + custom.length + ". Completed " + megabytes(completedBytes) + ". Nothing has been attached yet.");
        button.textContent = "Downloading " + (index + 1) + "–" + (index + records.length);
        const result = await call("downloadSparkingAssets", { version: session.version, paths: records.map(file => file.path) });
        unchanged(session);
        staged.push(...batchAssets(result, records, session.version));
        completedBytes += records.reduce((sum, file) => sum + file.bytes, 0);
      }
      unchanged(session);
      plan(session, selection.files);
      if (new Set(staged.map(asset => asset.key)).size !== staged.length) throw Error("Downloaded bank references conflict. No banks were attached.");
      const existingKeys = new Set((session.project.assets || []).map(asset => asset.key));
      if (staged.some(asset => existingKeys.has(asset.key))) throw Error("A downloaded bank reuses an existing file reference. No banks were attached.");
      stagedProject = JSON.parse(session.original);
      stagedProject.assets = [...(stagedProject.assets || []), ...staged];
      session.committing = true;
      cancelButton.disabled = true;
      status(session, "All audio files are ready. Saving their attachments to this unit…");
      button.textContent = "Saving attachments…";
      app().project = stagedProject;
      scheduleSave();
      stagedText = JSON.stringify(stagedProject);
      await flushSave(); // The shared writer requires saved:true and rejects superseded saves.
      session.done = true;
      if (active === session && session.panel.isConnected) {
        status(session, staged.length + " of Sparking's own audio files attached and saved locally" + (session.originals ? "; " + session.originals + " original banks saved from Eclipse (not attached — Eclipse already has them)" : "") + ". " + megabytes(selection.bytes) + " of selected banks are now included. Source-listed banks do not guarantee that every animation cue has matching audio.");
        button.textContent = "Audio attached";
        cancelButton.textContent = "Close";
      }
      if (typeof toast === "function") toast("Sparking audio banks attached and saved locally.");
    } catch (error) {
      // Restore only our unchanged staged editor copy; never overwrite subsequent edits.
      if (stagedProject && app() && app().project === stagedProject && (!stagedText || JSON.stringify(stagedProject) === stagedText)) {
        app().project = session.project;
        if (typeof stashDraft === "function") stashDraft();
      }
      status(session, error.message + " The original design and previous files were kept. Completed downloads may remain cached.", true);
      if (active === session && session.panel.isConnected) {
        button.textContent = "Download and attach audio";
        session.panel.querySelectorAll("input").forEach(input => input.disabled = input.dataset.empty === "true");
        button.disabled = session.cancelled;
      }
    } finally {
      session.working = false;
      session.committing = false;
      if (cancelButton.isConnected) cancelButton.disabled = false;
      if (!session.modal.open || !session.panel.isConnected || active !== session) { cancel(session); cleanup(session); }
    }
  }

  async function open(project) {
    if (active) cancel(active);
    if (!project || !app() || app().project !== project) throw Error("Open the current unit before attaching its Sparking audio.");
    if (typeof flushSave === "function") await flushSave();
    if (!app() || app().project !== project) throw Error("The selected unit changed. Open audio again from its current design.");
    const expected = sourceVersion(project), original = JSON.stringify(project);
    dialog("Sparking audio banks", '<section id="sparking-audio-picker"><p>Attach original sound effects and available voice banks listed by this unit’s exact Sparking source version. Banks may be shared across characters; this does not guarantee every animation cue has matching audio.</p><p class="hint">Checking the source-listed files before any audio download…</p><div id="sparking-audio-options"></div><p id="sparking-audio-total" class="hint"></p><p id="sparking-audio-status" class="hint" role="status">Loading the matching audio catalogue…</p><div class="row"><button type="button" class="button" id="sparking-audio-download" disabled>Download and attach audio</button><button type="button" class="button ghost" id="sparking-audio-cancel">Cancel</button></div></section>');
    const panel = document.querySelector("#sparking-audio-picker"), modal = panel.closest("dialog");
    const session = { project, original, version: expected, panel, modal, files: [], cancelled: false, working: false, committing: false, done: false };
    active = session;
    // A queued close from the previous dialog must not cancel a newly reopened picker.
    session.close = () => { if (!modal.open) cancel(session); };
    session.cancel = event => { if (session.committing) event.preventDefault(); else cancel(session); };
    modal.addEventListener("close", session.close);
    modal.addEventListener("cancel", session.cancel);
    session.observer = new MutationObserver(() => { if (!panel.isConnected) cancel(session); });
    session.observer.observe(panel.parentNode, { childList: true });
    panel.querySelector("#sparking-audio-cancel").onclick = () => { if (!session.committing) { cancel(session); modal.close(); } };
    panel.querySelector("#sparking-audio-download").onclick = () => download(session);
    try {
      const result = await call("sparkingAudioCatalog", { version: expected });
      unchanged(session);
      session.files = catalogue(result, expected);
      const groups = ["se", "voice"].map(kind => {
        const rows = session.files.filter(file => file.kind === kind), bytes = rows.reduce((sum, file) => sum + file.bytes, 0);
        return '<label class="check-item"><input type="checkbox" id="sparking-audio-' + kind + '"' + (kind === "se" && rows.length ? " checked" : "") + (!rows.length ? ' disabled data-empty="true"' : '') + '><span>' + (kind === "se" ? "Include sound effects" : "Include available voices") + ' · ' + rows.length + ' files · ' + escape(megabytes(bytes)) + '</span></label>';
      });
      panel.querySelector("#sparking-audio-options").innerHTML = '<fieldset><legend>Original content version ' + expected + '</legend>' + groups.join("") + '</fieldset>';
      panel.querySelectorAll("input").forEach(input => input.onchange = () => update(session));
      update(session);
    } catch (error) { status(session, error.message + " Your unit and its previous files were kept.", true); }
  }
  root.ForgeSparkingAudio = { open };
})(typeof globalThis !== "undefined" ? globalThis : this);
