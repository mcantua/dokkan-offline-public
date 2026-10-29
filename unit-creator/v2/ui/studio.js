"use strict";
const studioState = { sourceDatabase: "", search: "", kind: "all", offset: 0, unitId: 0, files: [], stamp: "", items: [], more: false, tab: "characters", mode: "browse", selected: 0, loading: 0 };
async function studioBusy(title,work){
  let failure;
  const result=await busy(title,async()=>{try{return await work();}catch(e){failure=e;throw e;}});
  if(failure!==undefined)throw failure;
  return result;
}
function studioOwner(){return window.ForgeAnimationGallery?.current()||state.project;}
function studioPreviewRequest(owner=studioOwner()){return window.ForgeAnimationGallery?ForgeAnimationGallery.previewRequest(owner):ForgePreviewBindings.request(owner);}
function studioProject() {
  const independent=window.ForgeAnimationGallery?.current();if(independent)return independent.animationStudio;
  if (!state.project) return null;
  state.project.animationStudio = state.project.animationStudio || { clips: [], name: "My combined animation", purpose: "super", target: "", dirty: false };
  if (state.studioTarget) {
    const t = ForgeGuide.targets(state.project).find((t2) => t2.key === state.studioTarget);
    if (t) {
      state.project.animationStudio.purpose = t.kind;
      state.project.animationStudio.target = t.key;
    }
  }
  return state.project.animationStudio;
}
function studioButton(text, key, style = "ghost") {
  return '<button class="button ' + style + '" data-studio="' + esc(key) + '">' + esc(text) + "</button>";
}
function studioContext() {
  const p = studioProject();
  if (!p) return '<p class="notice">Browse first. Choose Edit animation to create a unit from that character and open its editable sequence.</p>';
  const owner = studioOwner();
  if (window.ForgeAnimationGallery?.current()) return '<p class="notice" id="studio-context"><strong>Editing animation:</strong> ' + esc(p.name || 'My animation') + '<br>This animation is separate from your units. Choose a unit when you assign it.</p>';
  const target = ForgeGuide.targets(owner).find(t => t.key === p.target);
  return '<p class="notice" id="studio-context"><strong>Editing unit:</strong> ' + esc(Forge.card(owner).name || owner.source?.name || 'Your unit') + '<br><strong>Selected move:</strong> ' + esc(target?.name || 'Choose a move when you assign') + '<br>' + (p.dirty ? 'Pending changes: this draft has not been assigned to the selected move.' : 'The editing draft is separate from move assignments. Assign again after editing to update the move.') + '</p>';
}
function studioRefreshContext() {
  const node = $('#studio-context');
  if (node) node.outerHTML = studioContext();
}
function studioChange() {
  const project = studioProject();
  if (project) {
    project.dirty = true;
    if(window.ForgeAnimationGallery?.current())ForgeAnimationGallery.changed();else scheduleSave();
    studioRefreshContext();
  }
}
async function renderStudio() {
  studioState.sourceDatabase = studioState.sourceDatabase || state.project?.source?.database || "eclipse";
  const p = studioProject(), stamp = String(state.info.meta.sha256 || state.info.meta.date) + ":" + studioState.sourceDatabase;
  if (studioState.stamp !== stamp) {
    studioState.stamp = stamp;
    studioState.files = [];
  }
  if (state.studioMode) {
    studioState.mode = state.studioMode;
    state.studioMode = null;
  }
  if (state.studioKind) {
    studioState.kind = state.studioKind;
    studioState.offset = 0;
    state.studioKind = null;
  }
  main('<div class="section-heading"><div><p class="eyebrow">1 FIND · 2 EDIT · 3 ASSIGN</p><h1>Animation editor (advanced)</h1><p>Find a character’s animation, edit its sections, then choose which move plays your result.</p></div>' + (state.project ? studioButton("Back to my unit", "back") : studioButton("Create a unit", "create")) + (window.ForgeOffline ? ForgeOffline.button("Offline") : "") + '</div><nav class="tabs studio-tabs studio-workflow" aria-label="Animation steps">' + studioButton("1 · Find an animation", "browse", studioState.mode === "browse" ? "" : "ghost") + (p ? studioButton("2 · Edit my sequence (" + p.clips.length + ")", "compose", studioState.mode === "compose" ? "" : "ghost") + studioButton("3 · Assign to a move", "assign", "teal") : "") + studioButton("AI animation help", "assistant", "ghost") + '</nav>' + studioContext() + '<section class="panel studio-browser"' + (studioState.mode === "compose" && p ? " hidden" : "") + '><h2>Find your animation</h2><p class="hint">Previews save the player and loaded resources on this device. Load and play a move online once, then use Offline preview to replay saved content. Unloaded resources and unsupported engine features remain unavailable. Game movies have a separate browser with automatic support for older formats.</p><div id="studio-offline" class="notice">Checking saved preview resources…</div><div class="source-controls"><label class="field">Game collection<select id="studio-database">' + selection([["eclipse", "Eclipse"], ["sparking", "Sparking"]], studioState.sourceDatabase) + '</select></label><input id="studio-search" aria-label="Find animations by character or move" placeholder="Character or move name…" value="' + esc(studioState.search) + '"><select id="studio-kind" aria-label="Animation type">' + selection(Object.entries(ForgeMotion.kinds).filter(([k]) => studioState.tab === "files" ? !["ultra", "ex", "fullpower", "dash", "launcher", "combo", "victory"].includes(k) : !["dodge", "dash", "launcher", "combo", "victory", "other", "revival"].includes(k)), studioState.kind) + '</select></div><div class="row">' + studioButton("Choose a character", "choose-character", "ghost") + (studioState.unitId ? studioButton("Show all characters", "all-characters", "subtle") : "") + studioButton("Character moves", "characters", studioState.tab === "characters" ? "" : "ghost") + studioButton("All game sequences", "files", studioState.tab === "files" ? "" : "ghost") + studioButton("Character poses & visuals", "visuals", "ghost") + (p ? studioButton("Build a character movement", "pose", "ghost") : "") + studioButton("Refresh animation list", "refresh", "subtle") + '</div><div id="studio-results"><p class="hint">Loading animation choices…</p></div><div id="studio-pages" class="row"></div></section>' + (p ? '<section class="panel studio-composer"' + (studioState.mode === "browse" ? " hidden" : "") + '><div class="section-heading"><div><h2>Your combined animation</h2><p>' + p.clips.length + " sections · " + p.clips.reduce((n, c) => n + c.to - c.from, 0).toFixed(1) + ' seconds</p></div><div class="row">' + studioButton("Add another section", "browse", "ghost") + studioButton("Edit and combine movies", "movie-editor", "ghost") + studioButton("Preview the whole sequence", "preview-composition", "") + studioButton("Undo", "undo", "subtle small") + studioButton("Redo", "redo", "subtle small") + '</div></div><p class="hint">Add animations above, then trim and arrange their sections below. Visual edits keep the original artwork and game resources. ' + (p.dirty ? "Changes have not been applied to a move yet." : "Saving keeps an editable draft. Assigning updates the game move for export.") + '</p><div class="field-grid"><label class="field">Sequence name<input id="studio-name" value="' + esc(p.name) + '"></label><label class="field">Describe this sequence as<select id="studio-purpose">' + selection(Object.entries(ForgeMotion.kinds).filter(([k]) => k !== "all"), p.purpose) + '</select></label></div><div id="studio-targets"></div><div id="studio-timeline"></div><div class="row">' + studioButton("Assign to a move", "assign", "teal") + studioButton("Save my editing draft", "save-draft", "ghost") + studioButton("Try in local combat workshop", "combat-bind", "ghost") + studioButton("Save an editable project backup", "backup", "subtle") + '</div><div id="studio-checks"></div></section>' : '<section class="panel"><h2>Want to combine or assign animations?</h2><p>Choose Edit animation on a character’s move to create your unit and start editing. You can also create or open a unit separately. Browsing and previews do not need a project.</p>' + studioButton("Create a unit", "create", "") + "</section>"));
  $("#studio-database").onchange = () => {
    studioState.sourceDatabase = $("#studio-database").value; studioState.unitId = 0; studioState.offset = 0; studioState.files = [];
    renderStudio().catch(error => toast(error.message, true));
  };
  $("#studio-search").oninput = () => {
    clearTimeout(studioState.timer);
    studioState.search = $("#studio-search").value;
    studioState.unitId = 0;
    studioState.offset = 0;
    studioState.timer = setTimeout(() => loadStudioResults().catch((e) => toast(e.message, true)), 300);
  };
  $("#studio-kind").onchange = () => {
    studioState.kind = $("#studio-kind").value;
    studioState.offset = 0;
    loadStudioResults().catch((e) => toast(e.message, true));
  };
  bindStudio($("#main"));
  if (p) {
    $("#studio-name").onchange = () => {
      p.name = $("#studio-name").value;
      studioChange();
    };
    $("#studio-purpose").onchange = () => {
      p.purpose = $("#studio-purpose").value;
      studioChange();
      renderStudioTargets();
    };
    renderStudioTargets();
    renderStudioTimeline();
  }
  await ForgePreviewStorage.mount($("#studio-offline"), { connected: () => state.view === "animations" });
  if (studioState.mode === "browse" || !p) await loadStudioResults();
}
async function studioFiles(refresh = false) {
  if (!studioState.files.length || refresh) studioState.files = await Native.call("animationFiles", { refresh, sourceDatabase: studioState.sourceDatabase });
  return studioState.files;
}
function studioSceneHint(entry) {
  var _a;
  const scriptPaths = { sp9000: "ab_script/attack_sp/sp9000.lua", no_attack: "ab_script/ab_sys/no_attack.lua", sys0001: "ab_script/ab_sys/sys0001.lua" }, hints = { "ab_script/attack_sp/sp9000.lua": ["No Super Attack message", "Shows the game’s “This character cannot perform a Super Attack.” notice while hiding the fighters. This is an intentionally still message scene."], "ab_script/ab_sys/no_attack.lua": ["No attack message", "Shows a short no-attack message. This is a message scene, so it may remain still."], "ab_script/ab_sys/sys0001.lua": ["Battle position reset", "Resets battle positions. Visible movement depends on the previous attack or dodge state in the game."] }, opponent = (_a = globalThis.ForgeOpponentScenes) == null ? void 0 : _a.get(entry.path || (/^sp\d+$/.test(entry.script || "") ? "ab_script/attack_sp/" + entry.script + ".lua" : "")), detail = hints[entry.path || scriptPaths[entry.script]] || (opponent ? [opponent.title, opponent.description] : null);
  if (!detail) return entry;
  const generic = entry.key === entry.path && entry.unitName === "Game sequence" && !entry.sourceTable, placeholder = !entry.moveName || ["none", "shared battle animation"].includes(String(entry.moveName).trim().toLowerCase());
  return { ...entry, moveName: generic || placeholder ? detail[0] : entry.moveName, description: detail[1] };
}
function studioFileMatches(path, search) {
  const known = studioSceneHint({ key: path, path, unitName: "Game sequence" });
  return (path + " " + (known.moveName || "")).toLowerCase().includes(String(search || "").toLowerCase());
}
async function loadStudioResults() {
  const token = ++studioState.loading;
  let items, more;
  if (studioState.tab === "files") {
    const files = await studioFiles();
    const filtered = files.filter((path) => path !== "ab_script/common/common.lua" && (studioState.kind === "all" || ForgeMotion.kindForPath(path) === studioState.kind) && studioFileMatches(path, studioState.search));
    items = filtered.slice(studioState.offset, studioState.offset + 12).map((path, i) => ({ key: path, path, kind: ForgeMotion.kindForPath(path), unitId: 0, resourceId: 0, unitName: "Game sequence", moveName: (ForgeMotion.kinds[ForgeMotion.kindForPath(path)] || "Other animation") + " · " + (studioState.offset + i + 1), description: "Extra sequences include generic combat, enemy actions, counters, transformations, and appearance effects. Some are not linked to a named character in the database." }));
    more = filtered.length > studioState.offset + 12;
  } else {
    const result = await Native.call("animationCatalog", { search: studioState.search, kind: studioState.kind, offset: studioState.offset, unitId: studioState.unitId, sourceDatabase: studioState.sourceDatabase });
    items = result.items;
    more = result.more;
  }
  if (token !== studioState.loading || state.view !== "animations" || !$("#studio-results")) return;
  items = items.map(entry => studioSceneHint({ ...entry, sourceDatabase: studioState.sourceDatabase }));
  studioState.items = items;
  studioState.more = more;
  $("#studio-results").innerHTML = items.length ? '<div class="animation-grid">' + items.map((entry, i) => '<article class="animation-tile">' + (entry.resourceId && entry.sourceDatabase !== "sparking" ? '<img loading="lazy" src="' + esc(resourceThumb(entry.resourceId)) + '" alt="' + esc(entry.unitName) + '">' : '<div class="animation-symbol" aria-hidden="true">▶</div>') + '<div><span class="chip">' + esc(ForgeMotion.kinds[entry.kind] || entry.kind) + "</span><h3>" + esc(entry.moveName) + "</h3><p>" + esc(entry.unitName) + (entry.rarity != null ? " · " + esc(Forge.rarities[entry.rarity]) : "") + '</p><p class="hint">' + esc(entry.description || "Preview to see what this sequence does.") + "</p>" + (ForgeAvailability.issue(entry.path, entry.script) ? '<p class="notice">' + esc(ForgeAvailability.message(entry.path, entry.script)) + "</p>" : "") + '<div class="row">' + studioButton("Edit animation", "edit:" + i, "small") + studioButton("Preview", "preview:" + i, "ghost small") + (entry.path === "ab_script/attack_sp/sp1237.lua" || entry.script === "sp1237" ? studioButton("Repair original dodge timing", "repair-source:" + i, "ghost small") : "") + ((state.project ? studioButton("Use original for a move", "use:" + i, "ghost small") + studioButton("Add a section", "add:" + i, "ghost small") + (entry.kind === "counter" && entry.sourceTable === "passive_skills" ? studioButton("Copy counter gameplay", "counter-profile:" + i, "ghost small") : "") : "") + (entry.unitId ? studioButton("Start from this character", "template:" + i, "subtle small") : "")) + "</div>" + (state.expert ? "<details><summary>Technical reference</summary><p>" + esc(entry.script || entry.path) + " · " + esc(entry.viewId || "") + "</p></details>" : "") + "</div></article>").join("") + "</div>" : '<div class="empty"><h3>No matching animations</h3><p>Try a shorter character name or All character animations. The All game sequences tab also includes unlinked combat sequences.</p></div>';
  $("#studio-pages").innerHTML = (studioState.offset ? studioButton("Previous", "prev") : "") + (more ? studioButton("Next 12", "next") : "");
  bindStudio($("#studio-results"));
  bindStudio($("#studio-pages"));
}
async function sourceForEntry(entry) {
  if (!entry) throw Error("Choose an animation from the list first.");
  let path = entry.path || ForgeAvailability.preferred(entry.script);
  if (!path) {
    let files = [];
    try { files = await studioFiles(); } catch (_) {}
    path = ForgeMotion.pathFor(entry.script, files);
  }
  if (!path) throw new Error(ForgeAvailability.message(null, entry.script) || "This sequence is not available in the public animation resources.");
  if (path === "ab_script/common/common.lua") throw new Error("This file is a shared animation helper. Choose a character move or game sequence to preview.");
  let source;
  try {
    const matching = studioOwner()?.assets?.find(asset => asset.path === "lua/" + path && asset.source === "sparking");
    source = await Native.call("animationSource", { path, sourceDatabase: entry.sourceDatabase, ...(matching ? {assetKey: matching.key} : {}) });
  } catch (error) {
    const missing = /HTTP 404\b/.test(error && error.message || "");
    throw new Error(ForgeAvailability.message(path, entry.script) || (missing ? "This clip is not in Eclipse's public animation files, so it can't be previewed or added. Choose another clip." : error.message));
  }
  return { ...source, label: entry.moveName + " · " + entry.unitName, catalog: entry };
}
function selectedTargets() {
  // A descriptive purpose must never hide another supported gameplay slot.
  if (window.ForgeAnimationGallery?.current()) return [];
  return state.project ? ForgeGuide.targets(state.project) : [];
}
async function studioEditEntry(entry, templateId) {
  if(window.ForgeAnimationGallery?.current()){const owner=studioOwner(),source=await sourceForEntry(entry);if(studioOwner()!==owner)throw Error("The open animation changed. Choose the clip again.");return studioAddSource(source,true);}
  if (!entry) throw Error("Choose an animation from the list first.");
  // Keep this entry across template creation, which replaces the main screen.
  if (!state.project) {
    const id = templateId || entry.unitId;
    if (!id) return ForgeGuideUI.pickUnit("Choose the unit you want to animate", card => studioEditEntry(entry, card.id), { sourceDatabase: entry.sourceDatabase });
    await flushSave();
    if (entry.sourceDatabase === "sparking") await ForgeSparkingContent.create(id);
    else await createUnit(id);
    if (!state.project || Number(state.project.source.cardId) !== Number(id) || state.view !== "editor" || (state.project.source.database || "eclipse") !== (entry.sourceDatabase || "eclipse")) return;
    // Both creation flows catch their own errors. Verify persistence before editing.
    await flushSave();
  }
  const unit = state.project;
  return studioBusy("Opening the animation editor", async () => {
    const source = await sourceForEntry(entry);
    if (state.project !== unit) throw Error("The selected unit changed. Choose its animation again.");
    return studioAddSource(source, true);
  });
}
async function studioAddSource(source, reuseExisting) {
  const unit = studioOwner(), p = studioProject();
  if (!unit || !p) throw Error("Start a new animation before adding clips.");
  await window.ForgeAnimationGallery?.prepareSource(unit,source);
  await ForgeSparkingContent.attachAnimation(unit, source);
  if (studioOwner() !== unit) throw Error("The selected unit changed. Choose its animation again.");
  await ForgeSparkingContent.checkEclipseAnimation(unit, source);
  if (studioOwner() !== unit) throw Error("The selected unit changed. Choose its animation again.");
  const existing = reuseExisting ? p.clips.findIndex(clip => clip.source.path === source.path && clip.source.text === source.text && (clip.source.catalog?.sourceDatabase || "eclipse") === (source.catalog?.sourceDatabase || "eclipse")) : -1;
  if (existing < 0) {
    p.clips.push(ForgeMotion.createClip(source));
    studioChange();
  }
  studioState.mode = "compose";
  studioState.selected = existing < 0 ? p.clips.length - 1 : existing;
  state.view = "animations";
  updateNav();
  await renderStudio();
  window.scrollTo(0, 0);
  toast(existing < 0 ? (window.ForgeBeginnerAnimations && !ForgeBeginnerAnimations.advanced() ? "Part added at the end. Play it and tap Start here and End here to keep just the part you want." : "Animation opened for editing. Trim, move or combine sections, then Assign to a move.") : "That move is already in your animation, so it wasn’t added twice.");
}
function studioAssignDialog() {
  const independent = window.ForgeAnimationGallery?.current();
  if (independent) {
    if (!independent.animationStudio?.clips?.length) throw Error("Add an animation section before choosing a unit.");
    return ForgeAnimationGallery.chooseUnit(independent);
  }
  const unit = state.project, p = studioProject(), targets = selectedTargets();
  if (!p?.clips.length) throw Error("Find an animation and choose Edit animation first.");
  if (!targets.length) throw Error("Add a supported move to this unit on the Moves tab first.");
  dialog("Assign your animation to a move", '<p>Unit: <strong>' + esc(Forge.card(unit).name || unit.source.name) + '</strong></p><p>Choose the real game move that will play this edited sequence. Its activation and gameplay rules stay in place.</p><label class="field">Move to update<select id="studio-assign-slot">' + selection(targets.map(t => [t.key, t.name]), p.target) + '</select></label><p class="hint">This applies your editing draft to the unit for export. Local combat workshop bindings are separate. Unsupported independent actions are not added by choosing a description.</p><button class="button teal" id="studio-assign-confirm">Assign and save this move</button>');
  $('#studio-assign-confirm').onclick = async () => {
    const button = $('#studio-assign-confirm');
    if (button.disabled) return;
    button.disabled = true;
    try {
      if (state.project !== unit) throw Error("The selected unit changed. Open Assign again.");
      const key = $('#studio-assign-slot').value;
      if (!ForgeGuide.targets(unit).some(t => t.key === key)) throw Error("This move changed. Open Assign again.");
      p.target = key;
      studioChange();
      await studioAction("apply");
      $('#dialog').close();
    } catch (error) { toast(error.message, true); }
    finally { if (button.isConnected) button.disabled = false; }
  };
}
function renderStudioTargets() {
  var _a, _b;
  const p = studioProject(), targets = selectedTargets();
  if (window.ForgeAnimationGallery?.current()) {
    $('#studio-targets').innerHTML = '<p class="notice">This animation is separate from your units. Assign it when you are ready to choose a unit and move.</p>';
    return;
  }
  if (state.studioTarget && targets.some((t) => t.key === state.studioTarget)) {
    p.target = state.studioTarget;
    state.studioTarget = null;
  }
  if (!targets.some((t) => t.key === p.target)) p.target = ((_a = targets[0]) == null ? void 0 : _a.key) || "";
  $("#studio-targets").innerHTML = targets.length ? '<label class="field">Assign this draft to<select id="studio-slot">' + selection(targets.map((t) => [t.key, t.name]), p.target) + "</select><small>The move keeps its existing gameplay trigger and damage rules. This changes its animation. Every supported move on this unit is listed; the description above does not restrict your choice.</small></label>" + (p.purpose === "transform" ? '<div class="notice">The existing transformation setup decides when the form changes. Choose its native animation slot when available, or an inherited Active Skill for its visuals.</div>' : "") : '<div class="notice">' + esc(["dash", "launcher", "combo", "dodge", "victory", "normal"].includes(p.purpose) ? "Dokkan does not expose a standalone per-unit " + ForgeMotion.kinds[p.purpose].toLowerCase() + " hook in this editor. You can design and preview the sequence, or use it visually in a supported move." : "Your unit has no " + ForgeMotion.kinds[p.purpose] + " slot. Add the matching move on the Moves tab, or start with a source character that already supports it.") + "</div>";
  if (p.target === "dodge:unit" && targets.length) $("#studio-targets").insertAdjacentHTML("beforeend", '<div class="notice">Experimental per-unit Dodge: the defender selects your sequence; other defenders keep their inherited animation. Export saves your unit and one Unit Creator Shared Actions file for this Library. Re-export and install each changed participating unit, replace Shared Actions, then restart Eclipse. Older unit patches or third-party patches owning the same Dodge animation may take priority. Actual Eclipse gameplay verification remains required.</div>');
  if (p.purpose === "dash") {
    $("#studio-targets").insertAdjacentHTML("beforeend", '<div class="notice">To change the independent Dash pose, customize this unit’s native battle poses. A combined animation sequence here still uses the actual move selected above. ' + studioButton("Customize battle poses", "battle-poses", "ghost small") + "</div>");
    bindStudio($("#studio-targets"));
  }
  if (["launcher", "combo", "victory"].includes(p.purpose) && targets.length) $("#studio-targets").insertAdjacentHTML("beforeend", '<div class="notice">This purpose describes the animation. Dokkan does not provide an independent ' + esc(ForgeMotion.kinds[p.purpose]) + " command here; choose the real move that will play it. It keeps that move’s trigger and gameplay.</div>");
  (_b = $("#studio-slot")) == null ? void 0 : _b.addEventListener("change", () => {
    p.target = $("#studio-slot").value;
    studioChange();
    renderStudioTargets();
  });
  document.querySelectorAll('#main [data-studio="assign"]').forEach(button => { button.disabled = !targets.length || !p.clips.length; });
  studioRefreshContext();
}
function timelineSourceNotice(clip) {
  const message = ForgeAvailability.message(clip.source.path);
  return message ? '<p class="notice">' + esc((clip.source.repair ? "Original source notice before this correction: " : "Original source notice: ") + message) + "</p>" : "";
}
function renderStudioTimeline() {
  const p = studioProject();
  $("#studio-timeline").innerHTML = p.clips.length ? '<ol class="studio-timeline">' + p.clips.map((c, i) => {
    var _a, _b, _c, _d, _e, _f, _g;
    return '<li class="studio-clip"><div class="effect-heading"><h3>' + esc(c.label) + '</h3><span class="chip">' + (c.to - c.from).toFixed(1) + ' sec</span></div><p class="hint">' + esc(((_a = c.source.catalog) == null ? void 0 : _a.unitName) || "Game sequence") + " · " + esc(((_b = c.source.catalog) == null ? void 0 : _b.moveName) || c.source.path.split("/")[1].replace(/_/g, " ")) + "</p>" + timelineSourceNotice(c) + '<div class="row">' + studioButton("Preview section", "clip-preview:" + i, "ghost small") + studioButton("Move earlier", "up:" + i, "subtle small") + studioButton("Move later", "down:" + i, "subtle small") + studioButton("Duplicate", "duplicate:" + i, "subtle small") + studioButton("Remove", "remove:" + i, "subtle small") + (c.source.repair ? studioButton("Restore original timing", "restore-source:" + i, "ghost small") : "") + "</div>" + (c.source.repair ? '<p class="notice">Authored corrected copy: ' + esc(c.source.repair.label) + ". The original source is retained for Restore. Normal-attack timing is unchanged; test the assigned move in Eclipse.</p>" : "") + "<details" + (i === studioState.selected ? " open" : "") + '><summary>Trim and edit this section</summary><div class="field-grid"><label class="field">Who performs this section?<select data-clip="' + i + ':actor">' + selection([["unit", "My unit"], ["opponent", "The other fighter"]], c.actor || "unit") + '</select><small>Changes character poses and attached effects. Baked videos keep their original characters.</small></label><label class="field">Section label<input data-clip="' + i + ':label" value="' + esc(c.label) + '"></label><label class="field">Keep from (seconds)<input type="number" step="0.1" min="0" max="600" data-clip="' + i + ':from" value="' + c.from + '"' + (((_c = c.report) == null ? void 0 : _c.video) ? " disabled" : "") + '></label><label class="field">Keep until (seconds)<input type="number" step="0.1" min="0.1" max="600" data-clip="' + i + ':to" value="' + c.to + '"></label></div><div class="field-grid">' + rangeHTML(i, "zoom", "Size (%)", c.zoom, 10, 400) + rangeHTML(i, "x", "Left / right", c.x, -800, 800) + rangeHTML(i, "y", "Up / down", c.y, -800, 800) + rangeHTML(i, "rotation", "Rotation (degrees)", c.rotation, -180, 180) + rangeHTML(i, "opacity", "Opacity (%)", c.opacity, 0, 100) + '</div><div class="row"><label class="check-item"><input type="checkbox" data-clip="' + i + ':mirror"' + (((_d = c.report) == null ? void 0 : _d.video) ? " disabled" : "") + (c.mirror ? " checked" : "") + '>Mirror left and right</label><label class="check-item"><input type="checkbox" data-clip="' + i + ':mute"' + (c.mute ? " checked" : "") + '>Mute this section</label></div><div class="field-grid"><label class="field">Split this section at (seconds)<input id="studio-split-' + i + '" type="number" step="0.1" value="' + ((c.from + c.to) / 2).toFixed(1) + '"></label></div>' + studioButton("Split into two sections", "split:" + i, "ghost small") + (((_e = c.report) == null ? void 0 : _e.markers.length) > 1 ? '<label class="field">Jump trim start to a detected scene<select data-marker="' + i + '">' + selection([["", "Choose a scene boundary"], ...c.report.markers.filter((f) => f / 60 < c.to).map((f, n) => [f / 60, "Scene " + (n + 1) + " · " + (f / 60).toFixed(1) + " seconds"])], "") + "</select><small>Detected from effect starts. Preview to check the cut.</small></label>" : "") + (((_f = c.report) == null ? void 0 : _f.video) ? '<p class="hint">This section contains a movie. Use Edit and combine movies above to cut inside it, change its picture, or combine it with another movie.</p>' : "") + (((_g = c.report) == null ? void 0 : _g.estimated) ? '<p class="hint">The original end time could not be fully determined. Adjust the cut using the live preview.</p>' : "") + "</details></li>";
  }).join("") + "</ol>" : '<div class="empty"><h3>Your timeline is empty</h3><p>Choose Find an animation, then Edit animation. Use Add a section to repeat a source intentionally. You can combine sections from different moves.</p></div>';
  bindStudio($("#studio-timeline"));
  $("#studio-timeline").querySelectorAll("[data-clip]").forEach((el) => {
    el.oninput = () => {
      if (el.type === "range") el.nextElementSibling.textContent = el.value;
    };
    el.onchange = () => {
      const [i, key] = el.dataset.clip.split(":"), clip = p.clips[Number(i)];
      clip[key] = el.type === "checkbox" ? el.checked : el.type === "number" || el.type === "range" ? Number(el.value) : el.value;
      studioState.selected = Number(i);
      studioChange();
      showStudioChecks();
    };
  });
  $("#studio-timeline").querySelectorAll("[data-marker]").forEach((el) => el.onchange = () => {
    if (el.value === "") return;
    p.clips[Number(el.dataset.marker)].from = Number(el.value);
    studioChange();
    renderStudioTimeline();
  });
  showStudioChecks();
}
function rangeHTML(i, key, label, value, min, max) {
  var _a, _b, _c;
  const disabled = ((_c = (_b = (_a = studioProject()) == null ? void 0 : _a.clips[i]) == null ? void 0 : _b.report) == null ? void 0 : _c.video) ? " disabled" : "";
  return '<label class="field">' + esc(label) + '<input type="range" min="' + min + '" max="' + max + '" value="' + value + '" data-clip="' + i + ":" + key + '"' + disabled + "><output>" + value + "</output></label>";
}
function showStudioChecks() {
  const p = studioProject(), errors = p.clips.length ? ForgeMotion.validate(p.clips) : [];
  $("#studio-checks").innerHTML = errors.length ? '<div class="notice error">' + errors.map(esc).join("<br>") + "<p>If this original scene cannot be combined safely, return to Find and choose Use original for a move. Original reuse still checks the selected move’s compatibility.</p></div>" : '<p class="hint">Generated sequences keep references to the original game resources. Test frame cuts and gameplay in Eclipse. To cut inside a movie or edit its picture and sound, choose Edit and combine movies. Scripts that jump between game phases still need their original engine context.</p>';
}
function bindStudio(root) {
  root.querySelectorAll("[data-studio]").forEach((b) => b.onclick = () => studioAction(b.dataset.studio).catch((e) => toast(e.message, true)));
}
async function studioAction(actionName) {
  var _a, _b, _c;
  const [name, indexText] = actionName.split(":"), index = Number(indexText), p = studioProject();
  if (name === "assistant") {
    if (!window.ForgeAssistant?.open) throw Error("AI animation help is not available in this build.");
    return window.ForgeAssistant.open({ task: "animation" });
  }
  if (name === "edit") return studioEditEntry(studioState.items[index]);
  if (name === "save-draft") {
    if (!p) throw Error("Choose an animation first.");
    await flushSave();
    toast(window.ForgeAnimationGallery?.current() ? "Animation draft saved to My animations. Choose a unit when you assign it." : "Editing draft saved to your unit. Assign it to a move when ready.");
    return;
  }
  if (name === "assign") return studioAssignDialog();
  if (name === "combat-bind") {
    if (!state.project || !p?.clips?.length) throw Error("Add an animation section before choosing a workshop action.");
    return ForgeCombatWorkshop.assignSequence({project:state.project,clips:p.clips,action:({ultra:"ultimate",fullpower:"ex",transformation:"transform"}[p.purpose]||p.purpose),name:p.name});
  }
  if (name === "movie-editor") return ForgeMovieEditor.open();
  if (name === "battle-poses") return ForgeBattlePoseEditor.open();
  if (name === "undo" || name === "redo") return window.ForgeAnimationGallery?.current() ? ForgeAnimationGallery.undo(name === "redo") : ForgeGuideUI.undo(name === "redo");
  if (name === "browse" || name === "compose") {
    studioState.mode = name;
    await renderStudio();
    window.scrollTo(0, 0);
    return;
  }
  if (name === "choose-character") return ForgeGuideUI.pickUnit("Browse a character’s animations", (card) => {
    studioState.unitId = card.id;
    studioState.search = card.name;
    studioState.offset = 0;
    studioState.tab = "characters";
    studioState.kind = "all";
    return renderStudio();
  }, {sourceDatabase: studioState.sourceDatabase});
  if (name === "all-characters") {
    studioState.unitId = 0;
    studioState.search = "";
    studioState.offset = 0;
    return renderStudio();
  }
  if (name === "pose") {
    if (!p) throw new Error("Start an animation first.");
    dialog("Build a character movement", '<p>Choose what your character does. These movements can be combined with any supported move.</p><label class="field">Movement<select id="pose-choice">' + selection(ForgePoses.definitions.map((item) => [item.key, item.label]), "dash") + '</select></label><label class="field">Duration (seconds)<input id="pose-seconds" type="number" min="0.1" max="30" step="0.1" value="1"></label><label class="field">Move left or right<input id="pose-x" type="range" min="-800" max="800" step="10" value="0"><small>Left moves toward the left edge; right moves toward the right edge.</small></label><label class="field">Move up or down<input id="pose-y" type="range" min="-800" max="800" step="10" value="0"></label><button class="button" id="pose-add">Add movement to my sequence</button>');
    $("#pose-add").onclick = () => {
      try {
        p.clips.push(ForgePoses.create($("#pose-choice").value, { seconds: Number($("#pose-seconds").value), travelX: Number($("#pose-x").value), travelY: Number($("#pose-y").value) }));
        studioState.mode = "compose";
        studioState.selected = p.clips.length - 1;
        studioChange();
        $("#dialog").close();
        renderStudio();
        toast("Character movement added. Choose who performs it and arrange it with your other sections.");
      } catch (error) {
        toast(error.message, true);
      }
    };
    return;
  }
  if (name === "back") {
    state.view = "editor";
    updateNav();
    renderEditor();
    return;
  }
  if (name === "create") return navigate("source");
  if (name === "characters" || name === "files") {
    studioState.tab = name;
    if (name === "files") {
      studioState.kind = "all";
      studioState.unitId = 0;
      studioState.search = "";
    }
    studioState.offset = 0;
    return renderStudio();
  }
  if (name === "refresh") {
    await studioFiles(true);
    toast("Animation list refreshed.");
    return loadStudioResults();
  }
  if (name === "next" || name === "prev") {
    studioState.offset = Math.max(0, studioState.offset + (name === "next" ? 12 : -12));
    return loadStudioResults();
  }
  if (name === "visuals") return ForgeGuideUI.pickUnit("Preview a character’s poses and visuals", async (card) => {
    const result = await Native.call("animationVisuals", { unitId: card.id });
    dialog(card.name + " · poses and visuals", result.items.length ? "<p>Preview a real character pack and select its individual poses. These clips are inspected separately from scripted move composition.</p>" + result.items.map((v, i) => '<p><button class="button ghost" data-visual-preview="' + i + '">' + esc(v.name) + "</button></p>").join("") : "<p>This character has no public visual pack available.</p>");
    document.querySelectorAll("[data-visual-preview]").forEach((b) => b.onclick = () => {
      const v = result.items[Number(b.dataset.visualPreview)];
      Native.call("previewAnimation", { mode: "pack", resourcePath: v.path, scene: v.scene, name: v.name }).catch((e) => toast(e.message, true));
    });
  });
  if (name === "counter-profile") {
    const entry = studioState.items[index], rows = await Native.call("query", { table: "passive_skills", ids: [entry.relationId], limit: 1 });
    if (!rows.length) throw new Error("This counter profile is no longer in the active data.");
    const fields = Forge.clone(rows[0]);
    delete fields.id;
    Forge.addPassive(state.project, fields);
    scheduleSave();
    state.view = "editor";
    state.step = 3;
    updateNav();
    renderEditor();
    toast("Copied " + entry.unitName + "’s counter with its original activation rule and animation.");
    return;
  }
  if (name === "template") {
    const entry = studioState.items[index];
    return entry.sourceDatabase === "sparking" ? ForgeSparkingContent.create(entry.unitId) : createUnit(entry.unitId);
  }
  if (name === "repair-source") {
    const entry = studioState.items[index], source = await studioBusy("Checking the original animation", () => sourceForEntry(entry));
    if (!source) return;
    return ForgeSourceRepairUI.open(source, { onPreview: (fixed) => Native.call("previewAnimation", { name: fixed.label + " · corrected dodge timing", text: fixed.text, ...state.project ? ForgePreviewBindings.request(state.project) : { attackerId: entry.unitId || 1000010 } }), ...p ? { onAdd: async (fixed) => {
      p.clips.push(ForgeMotion.createClip(fixed));
      studioState.mode = "compose";
      studioState.selected = p.clips.length - 1;
      studioChange();
      await renderStudio();
      window.scrollTo(0, 0);
      toast("Corrected section added. Its original source is retained for Restore.");
    } } : {} });
  }
  if (name === "restore-source") {
    if (!(p == null ? void 0 : p.clips[index])) throw new Error("Choose a section first.");
    const clip = p.clips[index], source = await ForgeSourceRepairs.restore(clip.source);
    clip.source = source;
    clip.report = ForgeMotion.analyze(source.text);
    studioChange();
    renderStudioTimeline();
    toast("Original animation timing restored. Your trim and visual settings were kept.");
    return;
  }
  if (name === "preview" || name === "add" || name === "use") {
    const entry = studioState.items[index];
    if (!entry) throw Error("Choose an animation from the list first.");
    // Assign existing database views without downloading Lua or the script inventory.
    if (name === "use" && entry.sourceDatabase !== "sparking" && state.project?.source?.database !== "sparking") return chooseAnimationTarget(entry, null);
    if (name === "preview" && entry.sourceDatabase !== "sparking" && ((_a = window.ForgeTrainingPicker) == null ? void 0 : _a.supports(entry.path))) {
      const source = await studioBusy("Preparing the training scene", () => sourceForEntry(entry));
      if (source) return ForgeTrainingPicker.preview(entry, source, { attackerId: entry.unitId || ((_b = state.project) == null ? void 0 : _b.source.cardId) || 1000010 });
      return;
    }
    return studioBusy(name === "preview" ? "Opening animation preview" : "Preparing animation", async () => {
      var _a2;
      const unit = studioOwner(), source = await sourceForEntry(entry);
      if (name !== "preview" && studioOwner() !== unit) throw Error("The selected unit changed. Choose its animation again.");
      if (name === "preview" && entry.sourceDatabase === "sparking") return Native.call("previewAnimation", await ForgeSparkingContent.preview(entry,source));
      if (name === "preview") return Native.call("previewAnimation", { name: source.label, path: source.path, text: source.text, sourceDatabase: entry.sourceDatabase, assetKey: source.assetKey, attackerId: entry.unitId || ((_a2 = state.project) == null ? void 0 : _a2.source.cardId) || 1000010 });
      if (name === "add") return studioAddSource(source, false);
      return chooseAnimationTarget(entry, source);
    });
  }
  if (!p) return;
  if (name === "up" || name === "down") {
    const other = index + (name === "up" ? -1 : 1);
    if (other >= 0 && other < p.clips.length) [p.clips[index], p.clips[other]] = [p.clips[other], p.clips[index]];
    studioChange();
    return renderStudioTimeline();
  }
  if (name === "duplicate") {
    const clip = Forge.clone(p.clips[index]);
    clip.key += "-copy-" + Date.now();
    p.clips.splice(index + 1, 0, clip);
    studioChange();
    return renderStudioTimeline();
  }
  if (name === "remove") {
    p.clips.splice(index, 1);
    studioChange();
    return renderStudioTimeline();
  }
  if (name === "split") {
    const clip = p.clips[index], at = Number($("#studio-split-" + index).value);
    if (at <= clip.from || at >= clip.to) throw new Error("Split between this section’s start and end.");
    const right = Forge.clone(clip);
    right.key += "-split-" + Date.now();
    right.from = at;
    clip.to = at;
    p.clips.splice(index + 1, 0, right);
    studioChange();
    return renderStudioTimeline();
  }
  if (name === "clip-preview") {
    const text = ForgeMotion.compile([p.clips[index]], { damage: false, music: p.music });
    return Native.call("previewAnimation", { name: p.clips[index].label, text, ...studioPreviewRequest() });
  }
  if (name === "preview-composition") {
    const text = ForgeMotion.compile(p.clips, { damage: false, music: p.music });
    return Native.call("previewAnimation", { name: p.name, text, ...studioPreviewRequest() });
  }
  if (name === "apply") {
    const unit = state.project, draft = JSON.stringify({clips:p.clips,target:p.target,name:p.name,music:p.music});
    const unchanged = () => { if (state.project !== unit || JSON.stringify({clips:p.clips,target:p.target,name:p.name,music:p.music}) !== draft) throw Error("The unit or draft changed. Review it and assign again."); };
    if (!p.target || !selectedTargets().some(target => target.key === p.target)) throw new Error("Choose a compatible game move first.");
    await ForgeSparkingContent.ensureAnimations(unit);
    unchanged();
    if (p.target === "dodge:unit") {
      const original = await Native.call("animationSource", { path: "ab_script/ab_sys/dg0001.lua" });
      unchanged();
      ForgeActionHooks.apply(unit, p.clips, original, p.name, {music:p.music});
    } else {
      if (((_c = ForgeGuide.targets(state.project).find((t) => t.key === p.target)) == null ? void 0 : _c.kind) === "counter") await ForgeCounterReservations.prepare(unit, { schema: state.info.schema });
      unchanged();
      ForgeGuide.applyComposition(unit, state.info.schema, p.clips, p.target, p.name, {music:p.music});
    }
    p.dirty = false;
    state.project.uiLabels = state.project.uiLabels || {};
    state.project.uiLabels.animations = state.project.uiLabels.animations || {};
    state.project.uiLabels.animations[p.target] = p.name + " (custom sequence)";
    scheduleSave();
    await flushSave();
    toast("Sequence applied. Its animation file will be included in ECLP and patch ZIP exports.");
    return renderStudio();
  }
  if (name === "backup") return exportProject("json");
}
// Plain-words compatibility for "use this animation for that move", shown before you confirm.
function animationFit(entry, source, target, unit) {
  if (!target) return ["bad", "Your unit needs a move of this kind first. Add one on the Moves step."];
  if (target.kind === "dodge") return ["bad", "Dodge animations are made in the animation editor: add this as a move there, then choose Dodge."];
  const row = (unit.tables[target.table] || []).find((r) => r.id === target.row), script = entry.script || (entry.path || "").split("/").pop().replace(/\.lua$/, "") || "";
  const directAllowed = entry.sourceDatabase !== "sparking" && unit.source?.database !== "sparking";
  const direct = directAllowed && (
    entry.sourceTable === "special_views" && Number(entry.viewId) > 0 && ["super", "ultra", "ex", "fullpower", "active", "standby", "finish"].includes(target.kind) ||
    target.kind === "counter" && /^c\d+$/.test(script) && Number(script.slice(1)) <= 16777215 ||
    target.kind === "normal" && row && new RegExp("^" + ({ 10001: "a", 10002: "ak", 10003: "b", 10004: "bk" }[target.category] || "never") + "\\d+$").test(script) ||
    target.kind === "intro" && entry.sourceTable === "passive_skill_effects" && Number(entry.viewId) > 0);
  if (direct) return ["good", "✓ Plays exactly like in the game. Your move keeps its own damage and effects."];
  if (source) {
    try { if (ForgeGuide.canReuseOriginal(source, target)) return ["good", "✓ The whole original animation is copied onto this move. Your move keeps its own damage and effects."]; } catch {}
    try {
      const report = ForgeMotion.analyze(source.text);
      if (report.training || report.awakening) return ["bad", "✕ Training and awakening scenes can't be used for a battle move. Pick a different animation."];
      const errors = ForgeMotion.validate([ForgeMotion.createClip(source)]);
      if (errors.length) return ["bad", "✕ Can't be used for this move: " + errors[0]];
    } catch (e) { return ["bad", "✕ Can't be used for this move: " + (e.message || e)]; }
  }
  if (target.kind === "counter") return ["ok", "Works after a small conversion: the app turns it into a counter sequence, so it can look slightly different from the original."];
  if (target.kind === "intro") return ["ok", "Works after a small conversion: the app turns it into an entrance sequence that plays at the start of battle."];
  return ["ok", "Works after a small conversion: the app makes a copy that fits this move. It plays the same animation; your move keeps its own damage and effects."];
}
function chooseAnimationTarget(entry, source) {
  var _a;
  const selectedUnit = state.project, targets = ForgeGuide.targets(selectedUnit);
  dialog("Use " + entry.moveName, "<p>" + esc(entry.unitName) + " · " + esc(ForgeMotion.kinds[entry.kind] || entry.kind) + '</p><label class="field">Use this animation for<select id="studio-use-slot">' + selection(targets.map((t) => [t.key, t.name]), targets.some((t) => t.key === (state.studioTarget || studioProject()?.target)) ? (state.studioTarget || studioProject()?.target) : (_a = targets[0]) == null ? void 0 : _a.key) + '</select></label><p id="studio-use-fit" class="notice" role="status" data-no-ai></p><button class="button" id="studio-use-confirm">Use this animation</button>');
  const showFit = () => { const key = $("#studio-use-slot").value, [level, text] = animationFit(entry, source, targets.find((t) => t.key === key), selectedUnit), box = $("#studio-use-fit"); box.textContent = text; box.className = "notice " + (level === "bad" ? "error" : level === "good" ? "success" : "warning"); $("#studio-use-confirm").disabled = level === "bad"; };
  $("#studio-use-slot").onchange = showFit;
  showFit();
  $("#studio-use-confirm").onclick = async () => {
    var _a2;
    const confirm=$("#studio-use-confirm");if(confirm.disabled)return;confirm.disabled=true;
    try {
      if(state.project!==selectedUnit)throw Error("The selected unit changed. Open the animation picker again.");
      const unit = selectedUnit, key = $("#studio-use-slot").value, target = targets.find((t) => t.key === key);
      if (!target) throw new Error("Your unit needs a compatible move first. Add one on the Moves tab.");
      if (target.kind === "dodge") throw new Error("Add this animation as a section, choose Dodge, and apply the sequence to create its fallback dispatcher.");
      const row = (unit.tables[target.table] || []).find((r) => r.id === target.row), script = entry.script || entry.path?.split("/").pop().replace(/\.lua$/, "") || "";
      const directAllowed=entry.sourceDatabase!=="sparking"&&unit.source?.database!=="sparking";
      const canReference=directAllowed&&(
        entry.sourceTable === "special_views" && Number(entry.viewId)>0 && ["super","ultra","ex","fullpower","active","standby","finish"].includes(target.kind) ||
        target.kind === "counter" && /^c\d+$/.test(script) && Number(script.slice(1)) <= 16777215 ||
        target.kind === "normal" && row && new RegExp("^"+({10001:"a",10002:"ak",10003:"b",10004:"bk"}[target.category]||"never")+"\\d+$").test(script) ||
        target.kind === "intro" && entry.sourceTable === "passive_skill_effects" && Number(entry.viewId)>0);
      if(!canReference){source=source||await sourceForEntry(entry);await ForgeSparkingContent.attachAnimation(unit,source);await ForgeSparkingContent.checkEclipseAnimation(unit,source);}
      if(state.project!==unit)throw new Error("The selected unit changed. Choose its animation again.");
      let direct = false;
      if (directAllowed && entry.sourceTable === "special_views" && Number(entry.viewId)>0 && ["super", "ultra", "ex", "fullpower", "active", "standby", "finish"].includes(target.kind)) {
        row[target.field] = entry.viewId;
        direct = true;
      } else if (directAllowed && target.kind === "counter" && /^c\d+$/.test(script) && Number(script.slice(1)) <= 16777215) {
        const number = Number(script.slice(1));
        let values;
        try {
          values = JSON.parse(row.efficacy_values || "{}");
        } catch {
        }
        if (Array.isArray(values)) {
          values[2] = number;
          row.efficacy_values = JSON.stringify(values);
        } else row.eff_value3 = number;
        direct = true;
      } else if (directAllowed && target.kind === "normal" && row && new RegExp("^" + ({ 10001: "a", 10002: "ak", 10003: "b", 10004: "bk" }[target.category] || "never") + "\\d+$").test(script)) {
        row.filename = script;
        direct = true;
      } else if (directAllowed && target.kind === "intro" && entry.sourceTable === "passive_skill_effects" && Number(entry.viewId)>0) {
        const set = Forge.primaryPassive(state.project), ids = new Set((state.project.tables.passive_skill_set_relations || []).filter((r) => r.passive_skill_set_id === (set == null ? void 0 : set.id)).map((r) => r.passive_skill_id));
        for (const r of state.project.tables.passive_skills || []) if (ids.has(r.id) && r.id !== target.row) r.passive_skill_effect_id = null;
        row.passive_skill_effect_id = entry.viewId;
        direct = true;
      }
      if (direct) {
        const previous = (_a2 = state.project.animationAssignments) == null ? void 0 : _a2[key];
        if (previous) {
          const table = target.kind === "intro" ? "passive_skill_effects" : !["counter", "normal"].includes(target.kind) ? "special_views" : null;
          if (table) state.project.tables[table] = (state.project.tables[table] || []).filter((r) => r.id !== previous.id);
          state.project.generatedFiles = (state.project.generatedFiles || []).filter((f) => f.owner !== key);
          delete state.project.animationAssignments[key];
        }
      } else {
        if (target.kind === "counter") await ForgeCounterReservations.prepare(unit, { schema: state.info.schema });
        if (state.project !== unit) throw new Error("The selected unit changed. Choose its animation again.");
        if(ForgeGuide.canReuseOriginal(source,target))ForgeGuide.applyOriginal(unit,state.info.schema,source,key,entry.moveName+" · "+entry.unitName);
        else ForgeGuide.applyComposition(unit, state.info.schema, [ForgeMotion.createClip(source)], key, entry.moveName + " · " + entry.unitName);
      }
      state.project.uiLabels = state.project.uiLabels || {};
      state.project.uiLabels.animations = state.project.uiLabels.animations || {};
      state.project.uiLabels.animations[key] = entry.moveName + " · " + entry.unitName;
      scheduleSave();
      $("#dialog").close();
      toast("Animation selected. Your move’s gameplay rules were preserved.");
      if (typeof window.forgeAfterAnimationUse === "function") window.forgeAfterAnimationUse(key);
    } catch (e) {
      toast(e.message, true);
    } finally { if(confirm.isConnected)confirm.disabled=false; }
  };
}
