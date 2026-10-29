"use strict";
const $ = (selector, root = document) => root.querySelector(selector);
const esc = (value) => String(value != null ? value : "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
const state = { view: "home", patches: [], libraryQuery: "", libraryFilter: "all", libraryRarity: "", info: null, projects: [], project: null, step: 0, categories: [], links: [], mechanics: window.FORGE_MECHANICS || {}, sourceQuery: "", sourceRarity: "", sourceOffset: 0, sourceRows: [], assetTab: "local", assetQuery: "", assetOffset: 0, lastImportReport: null, assetPath: "", assetListing: null, advancedTable: "cards", previewUrl: "" };
const steps = ["Identity", "Stats", "Leader", "Passive", "Attacks", "Links & categories", "Visuals", "Advanced (optional)", "Export"];
let saveTimer, saveQueue = Promise.resolve(), toastTimer, searchTimer, sourceRequest = 0, assetRequest = 0;
function toast(message, error = false) {
  const el = $("#toast");
  el.textContent = message;
  el.className = "show" + (error ? " error" : "");
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => el.className = "", error ? 7e3 : 4e3);
}
async function busy(title, work) {
  const overlay = $("#busy"), previous = document.activeElement;
  $("#busy-title").textContent = title;
  // Block taps straight away, but only show the dimmed "working" card if the job takes a while,
  // so quick actions no longer flash a full-screen overlay.
  overlay.classList.add("quiet");
  overlay.hidden = false;
  overlay.focus({ preventScroll: true });
  const reveal = setTimeout(() => overlay.classList.remove("quiet"), 280);
  try {
    return await work();
  } catch (error) {
    toast(error.message, true);
    return null;
  } finally {
    clearTimeout(reveal);
    overlay.classList.remove("quiet");
    overlay.hidden = true;
    if (previous?.isConnected && !previous.disabled && !previous.closest('[hidden],dialog:not([open])')) previous.focus({ preventScroll: true });
    else $("#main").focus({ preventScroll: true });
  }
}
function dialog(title, html) {
  $("#dialog-content").innerHTML = '<h2 id="dialog-title">' + esc(title) + "</h2>" + html;
  const d = $("#dialog");
  if (d.showModal) {
    if (!d.open) d.showModal();
  } else d.setAttribute("open", "");
}
function bindTop() {
  document.addEventListener("keydown", (event) => {
    if (!$("#busy").hidden && ["Tab", "Escape"].includes(event.key)) event.preventDefault();
  });
  document.querySelectorAll("[data-nav]").forEach((button) => button.addEventListener("click", (e) => {
    e.preventDefault();
    navigate(button.dataset.nav).catch((error) => toast(error.message, true));
  }));
  $("#import-top").addEventListener("click", () => importFile().catch((error) => toast(error.message, true)));
  $("#help").addEventListener("click", () => Native.call("external", { target: "documentation" }).catch((e) => toast(e.message, true)));
  $("#dialog-close").addEventListener("click", () => $("#dialog").close());
  document.addEventListener("error", (e) => {
    if (e.target.tagName === "IMG") e.target.hidden = true;
  }, true);
}
function selection(items, value) {
  return items.map(([id, name]) => '<option value="' + esc(id) + '"' + (String(id) === String(value) ? " selected" : "") + ">" + esc(name) + "</option>").join("");
}
function field(label, bind, value, kind = "text", hint = "", extra = "") {
  return '<label class="field">' + esc(label) + '<input type="' + kind + '" data-bind="' + esc(bind) + '" value="' + esc(value) + '" ' + extra + ">" + (hint ? "<small>" + esc(hint) + "</small>" : "") + "</label>";
}
function area(label, bind, value, hint = "") {
  return '<label class="field full">' + esc(label) + '<textarea data-bind="' + esc(bind) + '">' + esc(value) + "</textarea>" + (hint ? "<small>" + esc(hint) + "</small>" : "") + "</label>";
}
function select(label, bind, value, items, hint = "") {
  const list = items.slice();
  if (value != null && !list.some((x) => String(x[0]) === String(value))) list.unshift([value, "Inherited value " + value]);
  return '<label class="field">' + esc(label) + '<select data-bind="' + esc(bind) + '">' + selection(list, value) + "</select>" + (hint ? "<small>" + esc(hint) + "</small>" : "") + "</label>";
}
function thumb(c) {
  return resourceThumb(c.resource_id || c.id);
}
function resourceThumb(id) {
  id = Math.floor(Number(id) / 10) * 10;
  return "https://dokkan-eclipse.com/cdn/uncompressed/character/thumb/card_" + id + "_thumb/card_" + id + "_thumb.png";
}
let numberFormat = null;
function number(value) {
  // toLocaleString() builds a new ICU formatter on every call; reuse one (much faster on phones).
  try { numberFormat = numberFormat || new Intl.NumberFormat(); return numberFormat.format(Number(value || 0)); }
  catch { return Number(value || 0).toLocaleString(); }
}
function main(html) {
  if (state.view !== "combat") window.ForgeCombatWorkshop?.leave();
  $("#main").innerHTML = html;
  bindContent();
}
function updateNav() {
  document.querySelectorAll("[data-nav]").forEach((button) => {
    const active = button.dataset.nav === state.view || state.view === "editor" && button.dataset.nav === "source";
    button.classList.toggle("active", active);
    if (active) button.setAttribute("aria-current", "page");
    else button.removeAttribute("aria-current");
  });
  $("#breadcrumb").textContent = "Creator workspace / " + ({ home: "My units", library: "Library", source: "Create a unit", editor: "Unit editor", assets: "Assets & data", ai: "AI assistants", movies: "Game movies", combat: "Combat workshop" }[state.view] || "My units");
}
function stashDraft() {
  if (!state.project) return;
  try {
    localStorage.setItem("forge-draft", JSON.stringify(state.project));
  } catch {
  }
}
window.forgePersist = () => {
  stashDraft();
  flushSave().catch(() => {
  });
};
document.addEventListener("visibilitychange", () => {
  if (document.hidden) window.forgePersist();
});
function scheduleSave() {
  if (!state.project) return;
  state.project.updatedAt = new Date(Math.max(Date.now(), Number.isFinite(Date.parse(state.project.updatedAt)) ? Date.parse(state.project.updatedAt) + 1 : 0)).toISOString();
  stashDraft();
  $("#save-state").textContent = "Saving…";
  clearTimeout(saveTimer);
  saveTimer = setTimeout(() => flushSave().catch((e) => toast(e.message, true)), 650);
  renderPreview();
}
async function flushSave() {
  clearTimeout(saveTimer);
  if (!state.project) return;
  const project = Forge.clone(state.project);
  saveQueue = saveQueue.catch(() => {
  }).then(() => Native.call("saveProject", { project }));
  const saved = await saveQueue;
  if (saved?.superseded) throw new Error('A newer copy of this unit is already saved. Reopen it before continuing; your unsaved draft has not been cleared.');
  if (saved?.saved !== true) throw new Error('Saving this unit could not be confirmed. Your unsaved draft has not been cleared.');
  try {
    if (localStorage.getItem("forge-draft") === JSON.stringify(project)) localStorage.removeItem("forge-draft");
  } catch {
  }
  $("#save-state").textContent = "Saved locally";
}
async function navigate(view) {
  // Keep the current design open if saving failed; switching units can replace
  // the one local draft before its last changes have reached native storage.
  await flushSave();
  state.view = view;
  updateNav();
  if (view === "home") {
    state.projects = await Native.call("projects");
    renderHome();
  } else if (view === "library") {
    [state.projects, state.patches] = await Promise.all([Native.call("projects"), Native.call("patches")]);
    renderLibrary();
  } else if (view === "source") {
    renderSource();
    await searchSources();
  } else if (view === "editor") renderEditor();
  else if (view === "combat") await ForgeCombatWorkshop.open();
  else if (view === "assets") await renderAssets();
  else if (view === "ai") await renderAI();
  else if (view === "movies") {
    main('<div class="section-heading"><div><p class="eyebrow">WATCH BEFORE YOU CHOOSE</p><h1>Game movies</h1><p>Browse movie scenes by character, appearance, and format.</p></div></div><section id="movie-browser"></section>');
    await ForgeMovies.mount($("#movie-browser"));
  }
  window.scrollTo(0, 0);
}
window.forgeHandleBack = () => {
  if (!$("#busy").hidden) return true;
  const dialogs = document.querySelectorAll("dialog[open]"), top = dialogs[dialogs.length - 1];
  if (top) {
    if (typeof top.requestClose === "function") top.requestClose();
    else if (top.dispatchEvent(new Event("cancel", { cancelable: true }))) top.close();
    return true;
  }
  if (state.view !== "home") {
    navigate("home").catch((error) => toast(error.message, true));
    return true;
  }
  return false;
};
function renderHome() {
  main('<section class="hero"><div><p class="eyebrow">YOUR NEXT UNIT STARTS HERE</p><h1>Build your<br><span>next legend.</span></h1><p>Create custom Dokkan Battle units with a guided editor, real game data, and a clear path to Eclipse.</p></div><button class="button" data-action="new">Create a unit <span>＋</span></button></section><div class="summary-grid"><div class="summary-card"><span class="summary-icon">▦</span><div><strong class="summary-number">' + state.projects.length + '</strong><p>Saved units</p></div></div><div class="summary-card"><span class="summary-icon">◈</span><div><strong class="summary-number">' + number(state.info.count) + '</strong><p>Source cards</p></div></div><div class="summary-card"><span class="summary-icon">↓</span><div><strong class="summary-number">SQL · JSON · ECLP</strong><p>Built-in offline ECLP export</p></div></div></div><div class="section-heading"><div><h2>Your collection <span class="count">' + state.projects.length + '</span></h2><p>Your designs are saved on this device. Use ECLP to move a unit with its attached files. JSON backs up the editable design only.</p></div><button class="button ghost small" data-action="import">Import project</button></div>' + (state.projects.length ? '<div class="unit-grid">' + state.projects.map((p) => '<button class="unit-tile" data-open="' + esc(p.key) + '"><div class="tile-art"><span class="brand-mark" aria-hidden="true">★</span></div><div class="tile-body"><span class="chip orange">' + esc(Forge.rarities[p.rarity] || "UNIT") + '</span> <span class="chip">' + esc(Forge.elements[p.element] || "") + "</span><h3>" + esc(p.name) + "</h3><p>" + esc(p.sourceName ? "Based on " + p.sourceName : "Your unit") + "</p></div></button>").join("") + "</div>" : '<section class="empty"><div class="empty-icon">＋</div><h2>Your first custom unit is waiting.</h2><p>Choose a source card to inherit working animations and game references. Then shape its stats, skills, links, and identity into your own design.</p><button class="button" data-action="new">Start creating</button></section>') + '<div class="notice">ECLP export now runs on this device. Open Library to browse your created units and imported projects or patches.</div>');
}
function renderSource() {
  main('<div class="section-heading"><div><p class="eyebrow">STEP ONE · CHOOSE YOUR FOUNDATION</p><h1>Start with a source unit</h1><p>Inherit its attacks, animations, and mechanics. Your source stays unchanged.</p></div></div><div class="source-controls"><input id="source-query" aria-label="Search source units" placeholder="Search Goku, Gogeta, Broly…" value="' + esc(state.sourceQuery) + '"><select id="source-rarity" aria-label="Filter rarity">' + selection([["", "All rarities"], ...Forge.rarities.map((x, i) => [i, x])], state.sourceRarity) + '</select></div><div id="source-results"><p class="hint">Loading source cards…</p></div><div class="row row-end" id="source-pages"></div>');
}
const SOURCE_PAGE = 160;
async function searchSources() {
  const request = ++sourceRequest, offset = state.sourceOffset, query = state.sourceQuery, rarity = state.sourceRarity, all = !!state.sourceAll;
  const filters = {};
  if (rarity !== "") filters.rarity = Number(rarity);
  // Game data holds every stage of a card plus enemy and story copies. Search a wide page and
  // show one entry per character: its fully awakened, playable version (unless "every version").
  const options = { table: "cards", filters, search: { column: "name", text: query }, limit: all ? 40 : SOURCE_PAGE, offset };
  const raw = await Native.call("query", options);
  const CV = window.ForgeCardVersions;
  const rows = !CV ? raw : all ? (await CV.load().catch(() => null), raw) : await CV.collapse(raw, { rarity });
  if (state.view !== "source" || request !== sourceRequest || query !== state.sourceQuery || rarity !== state.sourceRarity || offset !== state.sourceOffset || all !== !!state.sourceAll) return;
  state.sourceRows = rows;
  const badge = (c) => CV ? CV.badge(c) : "";
  $("#source-results").innerHTML = rows.length ? '<div class="source-grid">' + rows.map((c) => '<button class="source-tile" data-source="' + c.id + '"><div class="tile-art"><img src="' + esc(thumb(c)) + '" alt="' + esc(c.name) + '" loading="lazy">' + badge(c) + '</div><div class="tile-body"><span class="chip orange">' + esc(Forge.rarities[c.rarity] || "?") + '</span> <span class="chip">' + esc(Forge.elements[c.element] || "Neutral") + "</span><h2>" + esc(c.name) + "</h2><p>" + (CV && !all ? esc(CV.label(c)) : "Source ID " + c.id) + "</p></div></button>").join("") + "</div>" : '<div class="empty"><h2>No matching characters' + (raw.length ? " on this page" : "") + "</h2><p>" + (raw.length ? "Tap Next to keep looking, or turn on “Show every version”." : "Try a shorter name or another rarity. You can refresh game data under Assets & data.") + "</p></div>";
  const size = all ? 40 : SOURCE_PAGE, more = raw.length === size;
  $("#source-pages").innerHTML = '<label class="cv-all"><input type="checkbox" id="source-all"' + (all ? " checked" : "") + '> Show every version (pre-awakened, enemy and transformation cards)</label><span class="hint" role="status">' + (rows.length ? number(rows.length) + (all ? " cards" : rows.length === 1 ? " character" : " characters") : "No characters") + "</span>" + (state.sourceOffset ? '<button class="button ghost small" data-action="source-prev">Previous</button>' : "") + (more ? '<button class="button ghost small" data-action="source-next">Next</button>' : "");
  $("#source-all").onchange = (e) => { state.sourceAll = e.target.checked; state.sourceOffset = 0; searchSources().catch((error) => toast(error.message, true)); };
  bindDynamic($("#source-results"));
  bindDynamic($("#source-pages"));
}
async function createUnit(id) {
  const result = await busy("Preparing the source unit and its skills", async () => {
    state.projects = await Native.call("projects");
    const next = Forge.nextUnitId(state.projects, null, Forge.SLOT_FLOOR);
    const p = await Forge.loadTemplate((options) => Native.call("query", options), state.info.schema, id, next);
    state.project = p;
    state.step = 0;
    state.previewUrl = "";
    await flushSave();
    return true;
  });
  if (result) {
    state.view = "editor";
    updateNav();
    renderEditor();
    window.scrollTo(0, 0);
  }
}
async function projectPreviewUrl(project) {
  var _a;
  const key = project.previewKey || (project.artBinding ? (_a = (project.assets || []).find((asset) => asset.owner === "forge-card-art" && asset.path === "character/thumb/card_" + project.artBinding.resourceId + "_thumb.png")) == null ? void 0 : _a.key : null);
  return key ? Native.call("assetUrl", { key }) : "";
}
async function migrateCounterBindings(project) {
  if (!Object.keys(project.animationAssignments || {}).some((key) => key.startsWith("counter:"))) return project;
  const before = JSON.stringify(project), staged = Forge.clone(project);
  await ForgeCounterReservations.prepare(staged, { schema: state.info.schema });
  for (const [key, assignment] of Object.entries(staged.animationAssignments)) if (key.startsWith("counter:")) (assignment.mode === "original" ? ForgeGuide.applyOriginal(staged, state.info.schema, assignment.originalSource || assignment.clips?.[0]?.source, key, assignment.name) : ForgeGuide.applyComposition(staged, state.info.schema, assignment.clips, key, assignment.name, { music: assignment.music }));
  const check = Forge.validate(staged);
  if (check.errors.length) throw new Error(check.errors[0]);
  if (JSON.stringify(project) !== before) throw new Error("The unit changed while its counter animation was prepared. Open or export it again.");
  return JSON.stringify(staged) === before ? project : staged;
}
async function openUnit(key) {
  await busy("Opening your saved unit", async () => {
    var _a, _b;
    let p = await Native.call("loadProject", { key });
    if ((p == null ? void 0 : p.format) !== "dokkan-unit-forge" || p.version !== 1 || ((_b = (_a = p.tables) == null ? void 0 : _a.cards) == null ? void 0 : _b.length) !== 1) throw new Error("Unsupported saved project.");
    await Forge.hydrateAbilityAnimations(p, (o) => Native.call(p.source?.database === "sparking" ? "querySparking" : "query", o), state.info.schema);
    const migrated = await migrateCounterBindings(p);
    if (migrated !== p) {
      await Native.call("saveProject", { project: migrated });
      p = migrated;
    }
    state.project = p;
    state.previewUrl = await projectPreviewUrl(p);
    state.step = 0;
    state.view = "editor";
    updateNav();
    renderEditor();
    window.scrollTo(0, 0);
  });
}
function previewHTML() {
  var _a;
  const c = Forge.card(state.project);
  return '<div class="preview-art"><span class="preview-label">' + esc(Forge.rarities[c.rarity]) + '</span><img src="' + esc(state.previewUrl || resourceThumb(((_a = state.project.artBinding) == null ? void 0 : _a.sourceId) || c.resource_id || state.project.source.resourceId)) + '" alt="Unit preview"></div><div class="preview-body"><span class="chip teal">' + esc(Forge.elements[c.element]) + "</span><h2>" + esc(c.name) + '</h2><div class="preview-stats">' + ["hp", "atk", "def"].map((s) => "<div><span>" + s.toUpperCase() + "</span><strong>" + number(c[s + "_max"]) + "</strong></div>").join("") + "</div><p>" + esc(Forge.rarities[c.rarity] || "") + " · " + esc(Forge.elements[c.element] || "") + "</p></div>";
}
function renderPreview() {
  const el = $("#unit-preview");
  if (el && state.project) el.innerHTML = previewHTML();
}
function renderEditor() {
  if (!state.project) return navigate("home");
  const c = Forge.card(state.project);
  main('<div class="section-heading"><div><p class="eyebrow">UNIT EDITOR</p><h1>' + esc(c.name) + '</h1><p>Changes save locally. Use Export when you are ready to build a patch.</p></div><div class="row"><button class="button ghost small" data-action="project-versions">Saved versions</button><button class="button ghost small" data-action="home">My units</button></div></div><div class="stepper">' + steps.map((name, i) => '<button data-step="' + i + '" class="' + (state.step === i ? "active" : "") + '"><span>' + (i + 1) + "</span>" + esc(name) + "</button>").join("") + '</div>' + (window.ForgeSparkingContent?.projectPanel(state.project) || "") + '<div class="editor-layout"><div><div id="editor-form">' + stepHTML() + '</div><div class="step-footer"><button class="button ghost" data-action="step-prev">' + (state.step ? "Previous" : "My units") + "</button><span>" + (state.step + 1) + " / " + steps.length + "</span>" + (state.step < steps.length - 1 ? '<button class="button" data-action="step-next">' + (state.step === 7 ? "Review & export" : "Continue") + "</button>" : '<button class="button ghost" data-action="copy-prompt">Copy AI design prompt</button>') + '</div></div><aside class="preview" id="unit-preview" aria-label="Unit appearance and stats">' + previewHTML() + "</aside></div>");
  window.ForgeSparkingContent?.bindProject($("#main"));
}
function primaryLeader() {
  const p = state.project, c = Forge.card(p);
  return (p.tables.leader_skill_sets || []).find((r) => r.id === c.leader_skill_set_id);
}
function mechanics(name) {
  return (state.mechanics[name] || []).map((row) => [row.id, row.name]);
}
function tableBind(table, row, fieldName) {
  return "table:" + table + ":" + row.id + ":" + fieldName;
}
function stepHTML() {
  const p = state.project, c = Forge.card(p);
  if (state.step === 0) return '<section class="panel"><h2>Give your unit an identity</h2><p class="hint">The source supplies working references. These settings describe your custom card.</p><div class="field-grid">' + field("Unit name", "card:name", c.name, "text", "This is the name stored in the game card record.") + field("Custom card ID", "targetId", p.targetId, "number", "For player characters, use a slot ending in 1 in a supported range; automatic slots follow this rule. Keep at least 1,000 between units. Other IDs remain available for technical/NPC projects.", 'min="1000000" max="1999999000"') + area("Design notes", "notes", p.notes, "What should make this unit special? These notes can become an AI design prompt.") + '</div></section><div class="notice">Source: ' + esc(p.source.name) + " · " + p.source.cardId + ". Character identity and inherited transformation targets remain linked to the source unless you edit their references in Advanced.</div>";
  if (state.step === 1) return '<section class="panel"><h2>Core stats & progression</h2><p class="hint">Set the starting and maximum values before Hidden Potential, equipment, and in-battle buffs.</p><div class="field-grid three">' + select("Rarity", "card:rarity", c.rarity, Forge.rarities.map((x, i) => [i, x])) + select("Class & type", "card:element", c.element, Object.entries(Forge.elements)) + field("Team cost", "card:cost", c.cost, "number") + field("Maximum level", "card:lv_max", c.lv_max, "number") + field("Super Attack level cap", "card:skill_lv_max", c.skill_lv_max, "number") + field("Ki maximum bonus", "card:eball_mod_max", c.eball_mod_max, "number", "Inherited engine value; use Advanced for the full Ki curve.") + '</div><div class="divider"></div><div class="field-grid">' + ["hp", "atk", "def"].map((s) => field(s.toUpperCase() + " at level 1", "card:" + s + "_init", c[s + "_init"], "number") + field(s.toUpperCase() + " at maximum level", "card:" + s + "_max", c[s + "_max"], "number", s === "hp" ? "Eclipse’s normal player-character list requires maximum HP above 300. Lower values remain valid for NPC/technical projects." : "")).join("") + '</div></section><div class="notice">EZA progression is inherited from your source. If it has alternate passive or leader stages, review those records in Advanced.</div>';
  if (state.step === 2) {
    const set = primaryLeader();
    return '<section class="panel"><h2>Leader skill</h2><p class="hint">Text and mechanics are separate. Changing the description alone does not change the effect in battle.</p>' + (set ? '<div class="field-grid">' + field("Leader skill name", tableBind("leader_skill_sets", set, "name"), set.name) + area("Displayed description", tableBind("leader_skill_sets", set, "description"), set.description) + "</div>" : '<p class="hint">No leader set on this source. Apply the preset below to add one.</p>') + '<div class="divider"></div><h3>Beginner preset · all types</h3><p class="hint">Creates real Ki and HP/ATK/DEF effects for all five types. It replaces only this unit’s base leader effects.</p><div class="row"><label class="field">Ki bonus<input id="leader-ki" type="number" value="3" min="0" max="24"></label><label class="field">HP, ATK & DEF bonus (%)<input id="leader-stats" type="number" value="170" min="0"></label><button class="button" data-action="leader-preset">Apply preset</button></div></section><div class="notice">For category leaders, mixed bonuses, or conditional skills, edit the inherited leader_skills records in Advanced. No category restrictions are added by the all-types preset.</div>';
  }
  if (state.step === 3) {
    const set = Forge.primaryPassive(p);
    const ids = (p.tables.passive_skill_set_relations || []).filter((r) => r.passive_skill_set_id === (set == null ? void 0 : set.id)).map((r) => r.passive_skill_id);
    const skills = (p.tables.passive_skills || []).filter((r) => ids.includes(r.id));
    return '<section class="panel"><h2>Build your passive</h2><p class="hint">Edit the base passive’s real effects below. EZA and alternate-stage passives remain available in Advanced.</p>' + (set ? '<div class="field-grid">' + field("Passive name", tableBind("passive_skill_sets", set, "name"), set.name) + area("Displayed passive description", tableBind("passive_skill_sets", set, "itemized_description"), set.itemized_description, "Keep this text in sync with the actual effect rows.") + "</div>" : "") + '<div class="divider"></div><div class="section-heading"><div><h3>Gameplay effects <span class="count">' + skills.length + '</span></h3></div><button class="button ghost small" data-action="add-effect">Add effect</button></div><div class="row preset-row">' + [["stats", "ATK & DEF +100%"], ["ki", "Ki +3"], ["crit", "50% critical"], ["dodge", "50% dodge"], ["guard", "Guard"], ["reduction", "40% damage reduction"]].map(([key, label]) => '<button class="button subtle small" data-action="preset-' + key + '">' + label + "</button>").join("") + "</div>" + skills.map(effectHTML).join("") + (skills.length ? "" : '<p class="hint">Add your first effect. You can start with ATK & DEF, Ki, guard, critical hits, or dodge.</p>') + "</section>";
  }
  if (state.step === 4) {
    const specials = p.tables.card_specials || [];
    return '<section class="panel"><h2>Super attacks & inherited mechanics</h2><p class="hint">Keep a working animation from your source, or change its view ID when you have the matching assets. Text edits do not generate animation scripts.</p>' + specials.map((rel) => {
      const set = (p.tables.special_sets || []).find((s) => s.id === rel.special_set_id);
      if (!set) return "";
      return '<div class="effect-card"><h3>' + esc(rel.style || "Normal") + ' Super Attack</h3><div class="field-grid">' + field("Attack name", tableBind("special_sets", set, "name"), set.name) + select("Attack style", tableBind("card_specials", rel, "style"), rel.style, [["Normal", "Super Attack"], ["Hyper", "Ultra Super Attack"], ["Extra", "Extra"], ["Condition", "Conditional"]]) + area("Displayed attack description", tableBind("special_sets", set, "description"), set.description) + field("Required Ki", tableBind("card_specials", rel, "eball_num_start"), rel.eball_num_start, "number") + field("Unlock at SA level", tableBind("card_specials", rel, "lv_start"), rel.lv_start, "number") + field("Damage increase rate", tableBind("special_sets", set, "increase_rate"), set.increase_rate, "number", "Raw engine multiplier. Preserve the source value unless you understand the damage formula.") + field("SA level bonus", tableBind("special_sets", set, "lv_bonus"), set.lv_bonus, "number") + field("Animation view ID", tableBind("card_specials", rel, "view_id"), rel.view_id, "number") + '</div><button class="button subtle small" data-duplicate-attack="' + rel.id + '">Duplicate as another attack</button></div>';
    }).join("") + '<div class="notice">Inherited active skill sets: ' + (p.tables.active_skill_sets || []).length + " · Standby sets: " + (p.tables.standby_skill_sets || []).length + " · Finish sets: " + (p.tables.finish_skill_sets || []).length + ". Their complete records can be edited in Advanced.</div></section>";
  }
  if (state.step === 5) return '<section class="panel"><h2>Links & categories</h2><p class="hint">Pick up to seven different Link Skills and any valid categories from your active data pack.</p><label class="field">Find a link or category<input id="lookup-query" placeholder="Search names…"></label><div class="divider"></div><h3>Link Skills <span id="link-count"></span></h3><div class="check-grid" id="link-options">' + linkOptions("") + '</div><div class="divider"></div><h3>Categories</h3><div class="check-grid" id="category-options">' + categoryOptions("") + "</div></section>";
  if (state.step === 6) return '<section class="panel"><h2>Visuals & patch resources</h2><p class="hint">Reuse a source resource ID, or supply a complete custom resource pack. Preview art is for this editor; it does not create the game’s card or animation files.</p><div class="field-grid">' + field("Game art resource ID", "card:resource_id", c.resource_id, "number", "Keep the inherited ID to reuse its assets. A new ID requires matching resource files.") + field("Aura ID", "card:aura_id", c.aura_id, "number", "Leave inherited values for the source aura.") + '</div><div class="divider"></div><div class="row"><button class="button ghost" data-action="import">Import image / asset pack</button><button class="button ghost" data-action="assets">Browse assets & data</button></div><div class="divider"></div><h3>Attached patch files <span class="count">' + p.assets.length + "</span></h3>" + (p.assets.length ? p.assets.map((a, i) => '<div class="effect-card"><div class="row">' + field("Destination path inside files/", "asset:" + i + ":path", a.path, "text", "Use Eclipse’s resource path, for example character/thumb/card_97000000_thumb.png.") + '<button class="icon-button" data-remove-asset="' + i + '" aria-label="Remove attached file">×</button></div></div>').join("") : '<p class="hint">No extra files attached. Your unit currently reuses the source’s existing assets.</p>') + "</section>";
  if (state.step === 7) {
    const table = state.advancedTable in p.tables ? state.advancedTable : "cards";
    state.advancedTable = table;
    return '<section class="panel"><h2>Advanced table editor</h2><p class="hint">Every inherited column stays available here. Rows use their source or negative local IDs while editing; export assigns your custom ID block and updates known foreign keys.</p><div class="notice warning">Editing descriptions does not implement mechanics. Review skill efficacy values, timing, targets, conditions, and any references to shared game data.</div><div class="row"><label class="field">Project table<select id="advanced-table">' + selection(Object.keys(p.tables).map((t) => [t, t + " (" + p.tables[t].length + ")"]), table) + '</select></label><button class="button ghost small" data-action="add-table">Add reference table</button></div><label class="field">Rows (JSON array)<textarea id="advanced-json" class="code-editor" spellcheck="false">' + esc(JSON.stringify(table === "cards" ? [Forge.card(p)] : p.tables[table], null, 2)) + '</textarea></label><div class="row"><button class="button" data-action="apply-advanced">Apply table changes</button><button class="button ghost" data-action="add-row">Add blank row</button><button class="button subtle" data-action="load-reference-row">Load a reference row</button></div><p class="hint">For the cards table, guided edits are stored as overrides. Applying it here also updates those visible fields. Use negative IDs for new related rows. Unknown columns and duplicate row IDs are rejected.</p></section>';
  }
  return exportHTML();
}
function effectHTML(row) {
  var _a;
  const def = (state.mechanics.efficacies || []).find((e) => e.id === row.efficacy_type), bind = (f) => tableBind("passive_skills", row, f);
  let source = "";
  try {
    source = ((_a = JSON.parse(row.causality_conditions || "null")) == null ? void 0 : _a.source) || "";
  } catch {
  }
  return '<article class="effect-card"><div class="effect-heading"><h3>' + esc((def == null ? void 0 : def.name) || "Inherited effect " + row.efficacy_type) + '</h3><button class="icon-button" data-remove-effect="' + row.id + '" aria-label="Remove effect">×</button></div><div class="field-grid">' + select("Effect", bind("efficacy_type"), row.efficacy_type, mechanics("efficacies")) + select("Target", bind("target_type"), row.target_type, mechanics("target-types")) + field((def == null ? void 0 : def.values[0]) || "Effect value 1", bind("eff_value1"), row.eff_value1, "number") + field((def == null ? void 0 : def.values[1]) || "Effect value 2", bind("eff_value2"), row.eff_value2, "number") + "</div>" + ((def == null ? void 0 : def.description) ? '<p class="hint">' + esc(def.description) + "</p>" : "") + '<details><summary>Timing, probability & advanced values</summary><div class="field-grid">' + select("When it activates", bind("exec_timing_type"), row.exec_timing_type, mechanics("exec-types")) + select("Calculation", bind("calc_option"), row.calc_option, mechanics("calc-op")) + field("Effect probability (%)", bind("probability"), row.probability, "number") + field("Duration (engine turns)", bind("turn"), row.turn, "number") + field((def == null ? void 0 : def.values[2]) || "Effect value 3", bind("eff_value3"), row.eff_value3, "number") + select("Activate only once", bind("is_once"), row.is_once, [[0, "No"], [1, "Yes"]]) + field("Condition ID expression", "condition:" + row.id, source, "text", "Examples: 5 or 3205 & 5. Empty means unconditional. Use Eclipse documentation for valid IDs.") + field("Extra efficacy JSON", bind("efficacy_values"), row.efficacy_values || "{}", "text") + "</div></details></article>";
}
function linkOptions(query) {
  const c = Forge.card(state.project), selected = Array.from({ length: 7 }, (_, i) => c["link_skill" + (i + 1) + "_id"]);
  return state.links.filter((r) => r.name.toLowerCase().includes(query.toLowerCase())).sort((a, b) => selected.includes(b.id) - selected.includes(a.id)).map((r) => '<label class="check-item"><input type="checkbox" data-link="' + r.id + '"' + (selected.includes(r.id) ? " checked" : "") + "><span>" + esc(r.name) + "</span><small>" + r.id + "</small></label>").join("");
}
function categoryOptions(query) {
  const selected = (state.project.tables.card_card_categories || []).map((r) => r.card_category_id);
  return state.categories.filter((r) => r.name.toLowerCase().includes(query.toLowerCase())).sort((a, b) => selected.includes(b.id) - selected.includes(a.id)).map((r) => '<label class="check-item"><input type="checkbox" data-category="' + r.id + '"' + (selected.includes(r.id) ? " checked" : "") + "><span>" + esc(r.name) + "</span><small>" + r.id + "</small></label>").join("");
}
function exportHTML() {
  var _a;
  const p = state.project, check = Forge.validate(p);
  return '<section class="panel"><h2>Package your creation</h2><p class="hint">Review your unit, name the patch, and choose the format for your next step.</p>' + sharedActionsNotice(p) + '<div class="field-grid">' + field("Patch name", "patch:name", p.patch.name) + field("Author", "patch:author", p.patch.author) + field("Patch version", "patch:version", p.patch.version) + field("Patch UUID", "patch:uuid", p.patch.uuid) + area("Patch description", "patch:description", p.patch.description) + '</div><div id="export-validation">' + validationHTML(check) + '</div><div class="export-grid"><div class="export-option"><h3>.SQL</h3><p>Game database changes with remapped custom IDs. Asset files are exported separately in the patch ZIP.</p><button class="button ghost" data-export="sql">Export SQL</button></div><div class="export-option"><h3>.JSON</h3><p>An editable project backup. Attached images and other resource bytes need separate transfer; use ECLP to include them when moving to another device.</p><button class="button ghost" data-export="json">Export project JSON</button></div><div class="export-option"><h3>Eclipse patch ZIP</h3><p>Metadata, game SQL, attached resource files, and your editable unit project in one archive.</p><button class="button" data-export="zip">Export patch ZIP</button></div><div class="export-option"><h3>.ECLP</h3><p>Build an encrypted Eclipse patch directly on this device, including your SQL, resources, and editable unit project.</p><button class="button teal" data-export="eclp">' + (((_a = p.actionHooks) == null ? void 0 : _a.dodge) ? "Export Eclipse files" : "Export ECLP offline") + '</button><p class="hint">Optional official conversion:</p>' + (Native.canConvertOnline() ? '<button class="button ghost small" data-export="eclp-online">Use Eclipse online</button>' : "") + '<button class="button ghost small" data-action="converter">Open converter in browser</button></div></div><div class="notice warning">Local ECLP export works without an account or Internet. It targets the reader in your supplied Eclipse build. Test new units in Eclipse; gameplay depends on the kit, referenced forms, and assets.</div></section>';
}
function validationHTML(check) {
  return '<div class="notice ' + (check.errors.length ? "error" : "success") + '"><strong>' + (check.errors.length ? "Fix these first" : "✓ Your unit is ready to save") + "</strong>" + (check.errors.length ? "<ul>" + check.errors.map((e) => "<li>" + esc(e) + "</li>").join("") + "</ul>" : "<br>Nothing is missing. Tap Save game file below.") + "</div>" + (check.warnings.length ? '<details class="notice warning"><summary>Things to double-check in the game (' + check.warnings.length + ")</summary><ul>" + check.warnings.map((e) => "<li>" + esc(e) + "</li>").join("") + "</ul></details>" : "");
}
function bindContent() {
  bindDynamic($("#main"));
  const source = $("#source-query");
  if (source) source.addEventListener("input", () => {
    state.sourceQuery = source.value;
    state.sourceOffset = 0;
    clearTimeout(searchTimer);
    searchTimer = setTimeout(() => searchSources().catch((e) => toast(e.message, true)), 300);
  });
  const rarity = $("#source-rarity");
  if (rarity) rarity.addEventListener("change", () => {
    state.sourceRarity = rarity.value;
    state.sourceOffset = 0;
    searchSources().catch((e) => toast(e.message, true));
  });
  const look = $("#lookup-query");
  if (look) look.addEventListener("input", () => {
    $("#link-options").innerHTML = linkOptions(look.value);
    $("#category-options").innerHTML = categoryOptions(look.value);
    bindDynamic($("#link-options"));
    bindDynamic($("#category-options"));
  });
  const advanced = $("#advanced-table");
  if (advanced) advanced.addEventListener("change", () => {
    state.advancedTable = advanced.value;
    renderEditor();
  });
}
function bindDynamic(root) {
  root.querySelectorAll("[data-action]").forEach((b) => b.addEventListener("click", () => action(b.dataset.action).catch((e) => toast(e.message, true))));
  root.querySelectorAll("[data-open]").forEach((b) => b.addEventListener("click", () => openUnit(b.dataset.open)));
  root.querySelectorAll("[data-source]").forEach((b) => b.addEventListener("click", () => createUnit(Number(b.dataset.source))));
  root.querySelectorAll("[data-step]").forEach((b) => b.addEventListener("click", async () => {
    await flushSave();
    state.step = Number(b.dataset.step);
    renderEditor();
  }));
  root.querySelectorAll("[data-bind]").forEach((el) => {
    const handler = (e) => updateBinding(el, e.type);
    if (el.tagName === "SELECT" || el.dataset.bind.startsWith("condition:")) el.addEventListener("change", handler);
    else el.addEventListener("input", handler);
  });
  root.querySelectorAll("[data-remove-effect]").forEach((b) => b.addEventListener("click", () => {
    Forge.removePassive(state.project, Number(b.dataset.removeEffect));
    scheduleSave();
    renderEditor();
  }));
  root.querySelectorAll("[data-duplicate-attack]").forEach((b) => b.addEventListener("click", () => duplicateAttack(Number(b.dataset.duplicateAttack))));
  root.querySelectorAll("[data-link]").forEach((el) => el.addEventListener("change", () => changeLink(el)));
  root.querySelectorAll("[data-category]").forEach((el) => el.addEventListener("change", () => changeCategory(el)));
  root.querySelectorAll("[data-export]").forEach((el) => el.addEventListener("click", () => exportProject(el.dataset.export)));
  root.querySelectorAll("[data-remove-asset]").forEach((el) => el.addEventListener("click", () => {
    state.project.assets.splice(Number(el.dataset.removeAsset), 1);
    scheduleSave();
    renderEditor();
  }));
  root.querySelectorAll("[data-ai]").forEach((el) => el.addEventListener("click", () => busy("Opening your AI assistant", () => Native.call("ai", { provider: el.dataset.ai }))));
  root.querySelectorAll("[data-asset-folder]").forEach((el) => el.addEventListener("click", () => {
    state.assetPath = el.dataset.assetFolder;
    state.assetOnlinePage = 0;
    renderAssets().catch((e) => toast(e.message, true));
  }));
  root.querySelectorAll("[data-download-asset]").forEach((el) => el.addEventListener("click", () => busy("Downloading the selected Eclipse resource", async () => {
    await Native.call("downloadAsset", { path: el.dataset.downloadAsset });
    toast("Resource saved locally. Find it under Imported assets.");
  })));
  root.querySelectorAll("[data-attach-asset]").forEach((el) => el.addEventListener("click", () => attachAsset(el.dataset.attachAsset, el.dataset.gamePath)));
  root.querySelectorAll("[data-preview-asset]").forEach((el) => el.addEventListener("click", () => previewImportedAsset(el.dataset.previewAsset).catch((error) => toast(error.message, true))));
}
function updateBinding(el, eventType) {
  if (!state.project) return;
  const bits = el.dataset.bind.split(":"), p = state.project;
  try {
    let value = el.value;
    if (el.type === "number") value = value === "" ? null : Number(value);
    if (el.tagName === "SELECT" && bits[bits.length - 1] !== "style") value = Number(value);
    if (bits[0] === "condition") {
      if (eventType !== "change") return;
      const row = p.tables.passive_skills.find((r) => r.id === Number(bits[1]));
      row.causality_conditions = Forge.compileCondition(value);
    } else if (bits[0] === "card") p.cardOverrides[bits[1]] = value;
    else if (bits[0] === "table") {
      const row = p.tables[bits[1]].find((r) => r.id === Number(bits[2]));
      row[bits[3]] = value;
    } else if (bits[0] === "patch") p.patch[bits[1]] = value;
    else if (bits[0] === "asset") p.assets[Number(bits[1])][bits[2]] = value;
    else if (bits[0] === "targetId") p.targetId = Number(value);
    else p[bits[0]] = value;
    scheduleSave();
    if ($("#export-validation")) $("#export-validation").innerHTML = validationHTML(Forge.validate(p));
    if (el.tagName === "SELECT" && bits[3] === "efficacy_type") renderEditor();
  } catch (e) {
    toast(e.message, true);
  }
}
function changeLink(el) {
  const c = Forge.card(state.project), id = Number(el.dataset.link);
  let selected = Array.from({ length: 7 }, (_, i) => c["link_skill" + (i + 1) + "_id"]).filter(Boolean);
  if (el.checked) {
    if (selected.length >= 7) {
      el.checked = false;
      return toast("A unit can have up to seven Link Skills.", true);
    }
    selected.push(id);
  } else selected = selected.filter((v) => v !== id);
  for (let i = 0; i < 7; i++) state.project.cardOverrides["link_skill" + (i + 1) + "_id"] = selected[i] || null;
  scheduleSave();
}
function changeCategory(el) {
  const p = state.project, id = Number(el.dataset.category);
  p.tables.card_card_categories = p.tables.card_card_categories || [];
  p.schema.card_card_categories = state.info.schema.card_card_categories;
  if (el.checked) p.tables.card_card_categories.push(Object.assign(Forge.rowDefault(p.schema.card_card_categories), { id: Forge.localId(p, "card_card_categories"), card_id: p.source.cardId, card_category_id: id, num: p.tables.card_card_categories.length + 1 }));
  else p.tables.card_card_categories = p.tables.card_card_categories.filter((r) => r.card_category_id !== id);
  scheduleSave();
}
function duplicateAttack(id) {
  const p = state.project, source = p.tables.card_specials.find((r) => r.id === id), set = p.tables.special_sets.find((r) => r.id === source.special_set_id);
  if (!set) return;
  const copy = Forge.clone(set);
  copy.id = Forge.localId(p, "special_sets");
  copy.name += " (Custom)";
  p.tables.special_sets.push(copy);
  const rel = Forge.clone(source);
  rel.id = Forge.localId(p, "card_specials");
  rel.special_set_id = copy.id;
  rel.priority = Number(rel.priority || 0) + 1;
  p.tables.card_specials.push(rel);
  for (const effect of [...p.tables.specials || []].filter((r) => r.special_set_id === set.id)) {
    const row = Forge.clone(effect);
    row.id = Forge.localId(p, "specials");
    row.special_set_id = copy.id;
    p.tables.specials.push(row);
  }
  scheduleSave();
  renderEditor();
}
async function openProjectVersions() {
  if (!state.project) return;
  await flushSave();
  const key = state.project.key;
  return ForgeProjectVersions.open({
    key, call: (method, args) => Native.call(method, args), dialog,
    getCurrentKey: () => state.project?.key,
    onRestore: async project => {
      state.project = project;
      try {
        const draft = JSON.parse(localStorage.getItem('forge-draft') || 'null');
        if (draft?.key === key) localStorage.removeItem('forge-draft');
      } catch {}
      window.ForgeGuideUI?.resetHistory?.(key);
      state.abilityStage = 'base'; state.studioTarget = null;
      state.step = 0; state.view = 'editor'; state.previewUrl = '';
      updateNav(); renderEditor();
      try { state.previewUrl = await projectPreviewUrl(project); renderPreview(); }
      catch (error) { toast('Design restored. Its preview could not be opened: ' + error.message, true); }
    }
  });
}
async function action(name) {
  if (name === 'project-versions') return openProjectVersions();
  if (["home", "source", "assets", "ai"].includes(name)) return navigate(name);
  if (name === "new") return navigate("source");
  if (name === "import") return importFile();
  if (name === "source-next") {
    state.sourceOffset += state.sourceAll ? 40 : SOURCE_PAGE;
    await searchSources();
    return;
  }
  if (name === "source-prev") {
    state.sourceOffset = Math.max(0, state.sourceOffset - (state.sourceAll ? 40 : SOURCE_PAGE));
    await searchSources();
    return;
  }
  if (name === "step-prev") {
    if (!state.step) return navigate("home");
    await flushSave();
    state.step--;
    renderEditor();
    window.scrollTo(0, 0);
    return;
  }
  if (name === "step-next") {
    await flushSave();
    state.step = Math.min(8, state.step + 1);
    renderEditor();
    window.scrollTo(0, 0);
    return;
  }
  if (name === "leader-preset") {
    Forge.allTypesLeader(state.project, Number($("#leader-ki").value), Number($("#leader-stats").value));
    scheduleSave();
    renderEditor();
    return;
  }
  if (name.startsWith("preset-")) {
    const presets = { stats: { efficacy_type: 3, eff_value1: 100, eff_value2: 100, calc_option: 2 }, ki: { efficacy_type: 5, eff_value1: 3, eff_value2: 0, calc_option: 0 }, crit: { efficacy_type: 90, eff_value1: 50, eff_value2: 0, calc_option: 0 }, dodge: { efficacy_type: 91, eff_value1: 50, eff_value2: 0, calc_option: 0 }, guard: { efficacy_type: 78, eff_value1: 0, eff_value2: 0, calc_option: 0 }, reduction: { efficacy_type: 13, eff_value1: 60, eff_value2: 0, calc_option: 2 } };
    const preset = presets[name.slice(7)];
    if (preset) {
      Forge.addPassive(state.project, preset);
      scheduleSave();
      renderEditor();
    }
    return;
  }
  if (name === "add-effect") {
    Forge.addPassive(state.project, {});
    scheduleSave();
    renderEditor();
    return;
  }
  if (name === "apply-advanced") {
    const table = state.advancedTable, rows = JSON.parse($("#advanced-json").value);
    if (!Array.isArray(rows)) throw new Error("Enter a JSON array of rows.");
    const candidate = Forge.clone(state.project);
    candidate.tables[table] = rows;
    if (table === "cards") {
      if (rows.length !== 1) throw new Error("Keep exactly one source card row.");
      candidate.cardOverrides = {};
    }
    const result = Forge.validate(candidate);
    if (result.errors.length) throw new Error(result.errors.join("\n"));
    state.project = candidate;
    scheduleSave();
    renderEditor();
    toast("Table changes applied.");
    return;
  }
  if (name === "add-row") {
    const table = state.advancedTable, rows = JSON.parse($("#advanced-json").value);
    const row = Forge.rowDefault(state.project.schema[table]);
    row.id = Math.min(0, ...rows.map((r) => Number(r.id) || 0)) - 1;
    rows.push(row);
    $("#advanced-json").value = JSON.stringify(rows, null, 2);
    toast("Blank row added to the editor. Set its references, then Apply.");
    return;
  }
  if (name === "add-table") {
    dialog("Add a game data table", '<p>Advanced authoring only. New rows are exported with custom IDs. You must set the required fields and references.</p><label class="field">Table<select id="new-table">' + selection(Object.keys(state.info.schema).filter((t) => !state.project.tables[t] && state.info.schema[t].some((c) => c.name === "id")).map((t) => [t, t]), "") + '</select></label><button class="button" id="confirm-add-table">Add empty table</button>');
    $("#confirm-add-table").addEventListener("click", () => {
      const table = $("#new-table").value;
      if (!table) return;
      state.project.tables[table] = [];
      state.project.schema[table] = state.info.schema[table];
      state.advancedTable = table;
      $("#dialog").close();
      scheduleSave();
      renderEditor();
    });
    return;
  }
  if (name === "load-reference-row") {
    dialog("Load a reference row", '<p>Copy a row from your active game database into the selected table. Its ID will be remapped on export. Add its related records separately when needed.</p><label class="field">Reference row ID<input id="reference-row-id" type="number"></label><button class="button" id="confirm-reference-row">Load row</button>');
    $("#confirm-reference-row").addEventListener("click", async () => {
      try {
        const rows = await Native.call("query", { table: state.advancedTable, filters: { id: Number($("#reference-row-id").value) }, limit: 1 });
        if (!rows.length) throw new Error("No row found.");
        const current = JSON.parse($("#advanced-json").value);
        if (current.some((r) => r.id === rows[0].id)) throw new Error("That row is already in this table.");
        current.push(rows[0]);
        $("#advanced-json").value = JSON.stringify(current, null, 2);
        $("#dialog").close();
        toast("Row loaded. Review it, then Apply table changes.");
      } catch (e) {
        toast(e.message, true);
      }
    });
    return;
  }
  if (name === "converter") return Native.call("external", { target: "converter" });
  if (name === "copy-prompt") {
    if (!state.project) return toast("Open a unit to create a design prompt.");
    await Native.call("copy", { text: Forge.prompt(state.project) });
    toast("Design prompt copied. Paste it into your preferred AI.");
    return;
  }
  if (name === "import-apk") return importFile("importApk");
  if (name === "restore-database") {
    const result = await databaseTask("Restoring your previous game database", () => Native.call("restoreDatabase"));
    if (result) {
      state.info = result;
      await loadLookups();
      toast("Previous database restored. Your saved units were kept.");
      await renderAssets();
    }
    return;
  }
  if (name === "sync") {
    const result = await databaseTask("Refreshing Eclipse game data (about 100 MB)", () => Native.call("sync"));
    if (result) {
      state.info = result;
      await loadLookups();
      toast("Game data updated. Saved unit projects were kept.");
      await renderAssets();
    }
    return;
  }
  if (name === "asset-local") {
    state.assetTab = "local";
    return renderAssets();
  }
  if (name === "asset-online") {
    state.assetTab = "online";
    return renderAssets();
  }
  if (name === "asset-search") {
    state.assetQuery = $("#asset-query").value;
    state.assetOffset = 0;
    return renderImportedAssets(true);
  }
  if (name === "asset-prev" || name === "asset-next") {
    state.assetOffset = Math.max(0, state.assetOffset + (name === "asset-next" ? 40 : -40));
    return renderImportedAssets(true);
  }
  if (name === "import-report") return showImportSummary();
  if (name === "asset-open-path") {
    state.assetPath = $("#online-path").value.trim().replace(/^\/+|\/+$/g, "");
    state.assetOnlinePage = 0;
    return renderAssets();
  }
  if (name === "external-files") return Native.call("external", { target: "files" });
  if (name === "native-ai") return Native.call("ai");
}
function rememberImportResult(result) {
  var _a;
  state.lastImportReport = { kind: result.kind, sourceFormat: result.sourceFormat || "", formatKeyConfigured: result.formatKeyConfigured === true, count: result.count, bytes: result.bytes, expanded: result.expanded, note: result.note || "", apk: result.apk || null, sourceCards: (_a = state.info) == null ? void 0 : _a.count, warnings: Array.isArray(result.warnings) ? result.warnings.map(String) : [] };
}
function showImportSummary() {
  const report = state.lastImportReport;
  if (!report) return;
  const warnings = report.warnings || [], count = Number(report.count) || 0, expanded = Number(report.expanded) || 0;
  dialog(warnings.length ? "Import completed with files to review" : "Import results", '<p class="notice ' + (warnings.length ? "warning" : "success") + '" role="' + (warnings.length ? "alert" : "status") + '">' + (warnings.length ? "Some archive contents could not be opened. The files that could be read are available, and the original archives were kept." : "Your imported files are saved on this device.") + "</p>" + (report.note ? "<p>" + esc(report.note) + "</p>" : "") + (count ? "<p><strong>" + number(count) + " resource files imported</strong>" + (expanded ? "<br>" + number(expanded) + " " + (expanded === 1 ? "file" : "files") + " opened from resource archives. Original archives were kept." : "") + (report.bytes ? "<br>" + number(report.bytes) + " bytes stored." : "") + "</p>" : "") + (report.apk ? "<p><strong>" + number(report.sourceCards) + " source cards</strong><br>APK: " + esc(report.apk.versionName || "Eclipse") + "<br>Game version: " + esc(report.apk.gameVersion || "Not provided") + '</p><p class="hint">Your created units remain in Library. Restore the previous database under Game content if needed.</p>' : "") + (warnings.length ? '<details class="notice warning"><summary>Files to review (' + warnings.length + ")</summary><ul>" + warnings.slice(0, 100).map((w) => "<li>" + esc(w) + "</li>").join("") + "</ul>" + (warnings.length > 100 ? "<p>" + number(warnings.length - 100) + " more messages are included in the full report.</p>" : "") + '</details><p class="hint">You can keep using readable files. For the remaining files, try a newer build or a supported unpacked resource archive. These warnings do not mean that a downloaded custom-unit database was found.</p>' : "") + '<button class="button ghost" id="copy-import-report">Copy full import report</button>');
  $("#copy-import-report").addEventListener("click", () => Native.call("copy", { text: JSON.stringify(report, null, 2) }).then(() => toast("Import report copied.")).catch((error) => toast(error.message, true)));
}
// .sql -> an editable unit (sql-import.js reads only the INSERT rows; nothing in the file is run)
async function importSqlFile(given) {
  const file = given || await Native.call("pickTextFile", { accept: ".sql" });
  if (!file || typeof file.text !== "string") return;
  if (!/\.sql$/i.test(file.name || "") && !/insert\s+(or\s+\w+\s+)?into/i.test(file.text.slice(0, 200000))) return toast("Choose a .sql file with INSERT rows.", true);
  let made;
  await busy("Reading the .sql file", async () => {
    made = await window.ForgeSqlImport.toProject(file.text, { schema: state.info.schema, query: (o) => Native.call("query", o), fileName: file.name });
  });
  if (!made) return;
  const p = made.project, check = Forge.validate(p);
  if (check.errors.length) return dialog("This .sql can't become a unit yet", "<p>The file was read, but the unit it makes has problems:</p><ul>" + check.errors.slice(0, 8).map((e) => "<li>" + esc(e) + "</li>").join("") + '</ul><p class="hint">' + made.notes.map(esc).join("<br>") + "</p>");
  await Forge.hydrateAbilityAnimations(p, (o) => Native.call("query", o), state.info.schema).catch(() => {});
  await Native.call("saveProject", { project: p });
  state.project = p; state.step = 0; state.previewUrl = ""; state.view = "editor";
  updateNav(); renderEditor();
  dialog("Unit imported from .sql", "<p><strong>" + esc(p.cardOverrides.name || p.source.name) + "</strong> is now in your Library and open to edit.</p><ul>" + made.notes.map((n) => "<li>" + esc(n) + "</li>").join("") + '</ul><p class="hint">A .sql file has game data only: pictures and animations come from the game card it is based on. Save it again as .eclp or send it to Eclipse or Sparking when you are done.</p><div class="row"><button class="button" id="sql-ok">Start editing</button></div>');
  const ok = document.getElementById("sql-ok"); if (ok) ok.onclick = () => document.getElementById("dialog").close();
}
window.importSqlFile = importSqlFile;
async function importFile(mode = "import") {
  if (typeof mode !== "string") mode = "import";
  const result = await databaseTask(mode === "importApk" ? "Importing Eclipse APK and updating game data" : "Importing the selected file or resource archive", () => Native.call(mode));
  if (!result || !result.kind) return;
  if (result.kind === "sql") return importSqlFile(result);
  if (result.kind === "project") {
    const check = Forge.validate(result.project);
    if (check.errors.length) return toast(check.errors.join("\n"), true);
    await Forge.hydrateAbilityAnimations(result.project, (o) => Native.call(result.project.source?.database === "sparking" ? "querySparking" : "query", o), state.info.schema);
    state.project = result.project;
    state.step = 0;
    state.previewUrl = "";
    state.view = "editor";
    updateNav();
    renderEditor();
    toast(result.patch ? "Unit and attached resources imported. Find them in Library." : "Project imported to Library. Transfer any referenced resource files separately.");
  } else if (result.kind === "patch") {
    state.libraryFilter = result.sourceFormat === "sparking-sprk" || result.patch?.metadata?.sourceFormat === "sparking-sprk" ? "sparking" : "patches";
    state.libraryQuery = "";
    state.libraryRarity = "";
    state.libraryPage = 0;
    toast(result.note || "Patch added to Library.");
    await navigate("library");
  } else {
    state.info = result.info || await Native.call("info");
    await loadLookups();
    rememberImportResult(result);
    state.assetOffset = 0;
    state.assetQuery = "";
    state.view = "assets";
    state.assetTab = "local";
    updateNav();
    await renderAssets();
    if (result.kind === "apk" || result.sourceFormat || state.lastImportReport.warnings.length) showImportSummary();
    else toast(result.note || (result.count ? number(result.count) + " files imported" + (result.expanded ? " · " + number(result.expanded) + " opened from resource archives" : "") + "." : "Imported successfully."));
  }
}
async function loadLookups() {
  state.lookupRevision = (state.lookupRevision || 0) + 1;
  state.conditionRows = [];
  state.conditionLoaded = false;
  state.conditionLoading = null;
  [state.categories, state.links] = await Promise.all([Native.call("query", { table: "card_categories", limit: 5e3 }), Native.call("query", { table: "link_skills", limit: 5e3 })]);
}
function sharedActionsNotice(p) {
  var _a;
  if (!((_a = p == null ? void 0 : p.actionHooks) == null ? void 0 : _a.dodge)) return (p == null ? void 0 : p.sharedActionsUpdateRequired) ? '<div class="notice warning"><strong>Update shared actions after restoring Dodge</strong><p>Saving this unit does not remove its old animation from an installed shared patch. Use Library → Update shared actions. If no custom Dodge units remain, disable or remove Unit Creator Shared Actions in Eclipse, then restart Eclipse.</p></div>' : "";
  return '<div class="notice warning"><strong>Save two Eclipse files for custom Dodge</strong><p>Your unit file and <strong>Unit Creator Shared Actions</strong> work together. The shared file includes custom Dodge designs from this device’s Library. Install both files in Eclipse. Re-export and install every other participating unit whose design changed; the shared file does not contain those unit resources.</p><p>Replace the existing Unit Creator Shared Actions patch when you export another Dodge unit, then restart Eclipse before testing.</p><details><summary>Updating older Dodge patches</summary><p>Older custom unit patches each contain a shared Dodge animation. Remove those older unit patches from Eclipse, export them again here, and install the new unit files with one current Unit Creator Shared Actions patch. An older or third-party patch that replaces the same Dodge animation can take priority.</p></details></div>';
}
function showSharedActionsOutcome(outcome, support) {
  var _a;
  if (!outcome.unitSaved) {
    toast(outcome.error ? "The unit file was not saved: " + outcome.error : "Export canceled. Your project remains saved.", Boolean(outcome.error));
    return;
  }
  const zip = /\.zip$/i.test(outcome.unitName), complete = outcome.supportSaved, body = '<div class="notice ' + (complete ? "success" : "warning") + '" role="status">' + (complete ? zip ? "Your unit ZIP archive and Shared Actions file were saved." : "Both Eclipse files were saved." : zip ? "Your unit ZIP archive was saved. Unit Creator Shared Actions still needs to be saved." : "Your unit file was saved. Unit Creator Shared Actions still needs to be saved.") + "</div><p><strong>Unit:</strong> " + esc(outcome.unitName) + "<br><strong>Shared actions:</strong> " + esc(outcome.supportName) + "</p>" + (outcome.error ? "<p>" + esc(outcome.error) + "</p>" : "") + "<p>Re-export and install the current patch for each participating unit whose design changed; Shared Actions does not include those units or their resources.</p>" + (((_a = support.units) == null ? void 0 : _a.length) ? "<p><strong>Participating units:</strong> " + support.units.map((unit) => esc(unit.name)).join(", ") + "</p>" : "") + (zip ? "<p><strong>Convert the unit ZIP archive to ECLP before installation.</strong> The ZIP archive cannot be installed directly in Eclipse. Keep the Shared Actions file as ECLP.</p>" : "") + "<p>Install your " + (zip ? "converted unit ECLP" : "unit file") + ' and the current Unit Creator Shared Actions file in Eclipse. Replace the previous Shared Actions patch, then restart Eclipse before testing.</p><details><summary>Older Dodge patches</summary><p>Remove older custom unit patches that contained their own shared Dodge animation, then replace them with freshly exported unit files. Keep one current Unit Creator Shared Actions patch. Other patches replacing that same animation may conflict.</p></details><p class="hint">Your editable unit remains saved in your Library. The shared file covers the Library snapshot used for this export.</p><div class="row">' + (!complete ? '<button class="button teal" id="save-shared-actions-again">Save Shared Actions file</button>' : "") + '<button class="button ghost" id="close-shared-actions-result">' + (complete ? "Done" : "Close for now") + "</button></div>";
  dialog(complete ? zip ? "Patch archive and shared file saved" : "Eclipse files saved" : zip ? "Finish saving your patch archive files" : "Finish saving your Eclipse files", body);
  $("#close-shared-actions-result").onclick = () => $("#dialog").close();
  const retry = $("#save-shared-actions-again");
  if (retry) retry.onclick = async () => {
    $("#dialog").close();
    let next = { ...outcome };
    await busy("Saving Unit Creator Shared Actions", async () => {
      try {
        const result = await Native.call("export", ForgeExportFlow.supportRequest(support));
        next = { ...outcome, supportSaved: (result == null ? void 0 : result.saved) === true, error: void 0 };
      } catch (error) {
        next = { ...outcome, supportSaved: false, error: error.message || String(error) };
      }
    });
    showSharedActionsOutcome(next, support);
  };
}
function showSharedActionsRemoval() {
  dialog("Remove unused shared actions", '<p>No saved units in this Library need custom Dodge. No replacement file was created.</p><p>In Eclipse, disable or remove <strong>Unit Creator Shared Actions</strong>, then restart Eclipse. This removes the old dispatcher and restores the game’s inherited Dodge animation.</p><p class="hint">Older custom unit patches that contained their own shared Dodge animation must also be replaced with freshly exported unit files. Your editable projects remain saved here.</p><button class="button ghost" id="shared-actions-removal-done">Done</button>');
  $("#shared-actions-removal-done").onclick = () => $("#dialog").close();
}
async function updateLibrarySharedActions() {
  await flushSave();
  let support;
  await busy("Checking your saved custom actions", async () => {
    support = await ForgeExportFlow.refresh({ listProjects: () => Native.call("projects"), loadProject: (key) => Native.call("loadProject", { key }) });
  });
  if (!support) return;
  if (support.removeRequired) return showSharedActionsRemoval();
  dialog("Update shared actions", "<p>The shared file contains custom Dodge animations for " + support.unitIds.length + ' saved units. Re-export and install each changed unit patch before updating the shared file; it contains no unit resources. Install or replace <strong>Unit Creator Shared Actions</strong> in Eclipse, then restart Eclipse.</p><p class="hint">Install each unit’s current exported patch as well. Older unit patches with their own shared Dodge animation can take priority and must be replaced.</p><button class="button teal" id="save-library-shared-actions">Save Shared Actions file</button>');
  $("#save-library-shared-actions").onclick = async () => {
    $("#dialog").close();
    let saved = false;
    await busy("Saving Unit Creator Shared Actions", async () => {
      const result = await Native.call("export", ForgeExportFlow.supportRequest(support));
      saved = (result == null ? void 0 : result.saved) === true;
      if (saved) toast("Shared Actions saved. Replace it in Eclipse, then restart Eclipse.");
      else toast("Save canceled. Your existing files and projects were kept.");
    });
  };
}
async function exportProject(kind) {
  // A portable draft backup must remain possible when native saving conflicts
  // or an unfinished gameplay field fails validation. It never clears a draft.
  if (kind === "json") {
    if (!state.project) return toast("Open a unit before saving its backup.", true);
    const snapshot = Forge.clone(state.project);
    return busy("Saving your editable project backup", async () => {
      const result = await Native.call("export", { name: Forge.filename(snapshot) + ".json", kind: "json", text: JSON.stringify(snapshot, null, 2) });
      toast(result?.saved === true ? "Project backup saved. Attached files remain on this device; use ECLP to include them." : "Backup canceled. Your current design and draft are unchanged.");
    });
  }
  // "Import to Eclipse / Sparking": the same patch, saved where the game looks for it, then the game opens
  let sendTarget = null;
  const sendKind = kind, useSheet = !!exportProject.useSheet;
  exportProject.useSheet = false;
  if (kind === "to-eclipse" || kind === "to-sparking") { sendTarget = kind.slice(3); kind = "eclp"; }
  // iPhone: the game's own Files folder is linked once; ask for it before doing any work (Android saves into
  // Download/<Game> and the web version has no folder, so the check is skipped there).
  if (sendTarget && !useSheet) {
    const folder = await Native.call("gameFolderStatus", { target: sendTarget }).catch(() => null);
    if (folder && !folder.web && (!folder.linked || !folder.ok)) return showFolderSetup(sendTarget, sendKind, !!folder.linked);
  }
  const online = kind === "eclp-online";
  if (online && !Native.canConvertOnline()) return toast("Automatic online upload is unavailable on this device. Save an Eclipse patch offline, or open the converter in your browser.", true);
  if (online) kind = "eclp";
  const p = state.project;
  await window.ForgeSparkingContent.ensureAnimations(p);
  if (kind !== "json" && p.source?.database === "sparking" && !p.sparkingResources) await window.ForgeSparkingContent.resources(p);
  const check = Forge.validate(p.source?.database === "sparking" || p.sourceDependencies?.animations?.length ? { ...p, sourceDependencies: undefined } : p);
  if (check.errors.length) return toast(check.errors[0], true);
  await flushSave();
  let sharedOutcome = null, sharedSupport = null, sharedRemoval = false, onlineFailure = null, sendOutcome = null;
  await busy("Checking references and preparing your export", async () => {
    var _a;
    if (kind !== "json" && (p.source?.database === "sparking" || p.sourceDependencies?.animations?.length)) {
      const dependencies = await window.ForgeSparkingContent.prepare(p);
      const problem = [...dependencies.issues, ...ForgeSparkingDependencies.validate(dependencies, state.info.schema)].find(issue => issue.severity === "error");
      if (problem) throw new Error(problem.message);
      stashDraft(); await flushSave();
    }
    const checkedSnapshot = JSON.stringify(p);
    const requireUnchanged = () => {
      if (state.project !== p || JSON.stringify(p) !== checkedSnapshot) throw new Error("Your design changed while its files were checked. Export again.");
    };
    const integrity = await ForgeExportAudit.check(p, {
      schema: state.info.schema,
      query: options => Native.call("query", options),
      assetStatus: keys => Native.call("assetStatus", { keys }),
      readDecoration: async key => new TextDecoder("utf-8", { fatal: true }).decode(ForgeBattlePoseEditor.decode((await Native.call("readAsset", { key, maxBytes: 131072 })).base64))
    });
    requireUnchanged();
    state.lastExportAudit = { key: p.key, ...integrity };
    if (integrity.errors.length) {
      dialog("This unit needs a repair before export", '<p>Your design is still saved. Fix the following items, then export again.</p><ul>' + integrity.errors.slice(0, 10).map(message => '<li>' + esc(message) + '</li>').join('') + '</ul><details><summary>Technical details for troubleshooting</summary><pre>' + esc(JSON.stringify(integrity.issues, null, 2)) + '</pre></details><button class="button" id="close-export-repair">Back to my unit</button>');
      document.getElementById("close-export-repair").onclick = () => document.getElementById("dialog").close();
      return;
    }
    if (kind !== "json") {
      const saved = await Native.call("projects");
      if (saved.some(other => other.key !== p.key && [other.targetId,...(other.reservedIds||[])].some(id => ForgeForms.all(p).some(form => Math.abs(Number(id)-Number(form.targetId))<1e3)))) throw new Error("This ID block overlaps another saved unit. Choose a custom ID at least 1,000 away from your other units.");
    }
    if (kind !== "json") for (const [table, rows] of Object.entries(Forge.materializeAll(p))) {
      if (!rows.length) continue;
      const columns = new Set((state.info.schema[table] || []).map((c) => c.name));
      if (!columns.size || rows.some((row) => Object.keys(row).some((key) => !columns.has(key)))) throw new Error("This project table differs from the active database: " + table + ". Review it in Advanced or recreate it from the updated source.");
      const checked = p.awaken && table === "cards" ? rows.filter((r) => Number(r.id) !== Number(p.awaken.cardId)) : rows;
      if (!checked.length) continue;
      const conflicts = await Native.call("query", { table, ids: checked.map((r) => r.id), limit: 1e3 });
      if (conflicts.length) throw new Error("ID collision in " + table + ". Choose a different custom card ID before exporting.");
    }
    let roster = Forge.playerRosterEligibility(p);
    if (kind !== "json") {
      const costumeTable = Boolean(state.info.schema.card_costumes), itemTable = Boolean(state.info.schema.item_card_properties), [costumes, items] = await Promise.all([costumeTable ? Native.call("query", { table: "card_costumes", filters: { card_id: Number(p.targetId) - 1 }, limit: 1 }) : [], itemTable ? Native.call("query", { table: "item_card_properties", filters: { card_id: Number(p.targetId) }, limit: 1 }) : []]);
      roster = Forge.playerRosterEligibility(p, { costumeCardIds: costumes.map((row) => row.card_id), itemCardIds: items.map((row) => row.card_id), catalogExclusionsChecked: costumeTable && itemTable });
      state.playerRosterCheck = { key: p.key, targetId: p.targetId, catalogIssues: roster.catalogIssues };
      if (state.view === "editor" && state.step === 8) renderEditor();
    }
    if (["eclp", "zip"].includes(kind) && sendTarget !== "sparking" && (((_a = p.actionHooks) == null ? void 0 : _a.dodge) || p.sharedActionsUpdateRequired)) {
      sharedSupport = await ForgeExportFlow.prepare(p, { listProjects: () => Native.call("projects"), loadProject: (key) => Native.call("loadProject", { key }) });
      if (sharedSupport == null ? void 0 : sharedSupport.removeRequired) {
        sharedRemoval = true;
        sharedSupport = null;
      }
    }
    let request = { name: Forge.filename(p) + "." + (kind === "json" ? "json" : kind === "sql" ? "sql" : kind === "eclp" && !online ? "eclp" : "zip"), kind };
    requireUnchanged();
    if (kind === "json") request.text = JSON.stringify(p, null, 2);
    else if (kind === "sql") request.text = Forge.sql(p);
    else request.entries = Forge.exportEntries(p);
    if (kind === "eclp" && online) {
      if (sharedSupport) {
        requireUnchanged();
        const shared = await Native.call("export", ForgeExportFlow.supportRequest(sharedSupport));
        if ((shared == null ? void 0 : shared.saved) !== true) {
          toast("Shared Actions save canceled. The converter was not opened; your project remains saved.");
          return;
        }
      }
      request.patch = p.patch;
      try {
        requireUnchanged();
        await Native.call("convert", request);
        toast(sharedSupport ? "Shared Actions saved. Convert and save your unit, install both files, then restart Eclipse." : "Converter opened. Sign in, convert, then save the ECLP download.");
      } catch (error) {
        onlineFailure = { sharedSaved: Boolean(sharedSupport), message: error.message || String(error) };
      }
    } else if (sharedSupport) {
      sharedOutcome = await ForgeExportFlow.savePair(request, sharedSupport, (entry) => { requireUnchanged(); return Native.call("export", entry); });
    } else if (sendTarget) {
      requireUnchanged();
      sendOutcome = await Native.call("sendToGame", { target: sendTarget, request, useSheet, unitKey: p.key });
    } else {
      requireUnchanged();
      const result = await Native.call("export", request);
      sharedRemoval = sharedRemoval && (result == null ? void 0 : result.saved) === true;
      if (result == null ? void 0 : result.saved) toast("Export saved: " + request.name + (kind === "sql" && ForgeForms.all(p).some(member => member.artBinding || member.assets?.length) ? ". SQL does not include your attached artwork or animations; export an Eclipse patch to transfer them." : "") + (kind !== "json" && roster.issues.length ? ". Player-roster warning: " + roster.issues[0] : ""));
      else toast("Export canceled. Your unit is still saved on this device.");
    }
  });
  if (sendOutcome && sendOutcome.needsFolder) { showFolderSetup(sendTarget, sendKind, !!sendOutcome.lost); return sendOutcome; }
  if (sendOutcome) { showSendOutcome(sendTarget, sendOutcome, p, sendKind); return sendOutcome; }
  if (onlineFailure) {
    dialog("Unit conversion did not finish", '<div class="notice warning" role="status">' + (onlineFailure.sharedSaved ? "<strong>Unit Creator Shared Actions was already saved.</strong> " : "") + "Your unit conversion did not complete.</div><p>Your editable project remains saved in your Library. You can build an Eclipse patch offline without using the online converter.</p><p><strong>Converter error:</strong> " + esc(onlineFailure.message) + '</p><div class="row"><button class="button teal" id="retry-conversion-offline">' + (onlineFailure.sharedSaved ? "Export Eclipse files offline" : "Save Eclipse patch offline") + '</button><button class="button ghost" id="close-converter-failure">Close for now</button></div>');
    $("#retry-conversion-offline").onclick = () => {
      $("#dialog").close();
      exportProject("eclp");
    };
    $("#close-converter-failure").onclick = () => $("#dialog").close();
  } else if (sharedOutcome) showSharedActionsOutcome(sharedOutcome, sharedSupport);
  else if (sharedRemoval) showSharedActionsRemoval();
  return sharedOutcome;
}
// iPhone, first "Import to Sparking/Eclipse": link the game's own folder (On My iPhone › Sparking) once. Neither
// game can be handed a file by another app, but both import from their own folder; once it's linked every unit
// goes straight there. "Save somewhere else" keeps the old save sheet.
function showFolderSetup(target, sendKind, lost) {
  const game = target === "eclipse" ? "Eclipse" : "Sparking";
  dialog((lost ? "Link " + game + "'s folder again" : "One-time setup: link " + game),
    (lost ? '<div class="notice warning">The link to ' + game + "'s folder stopped working (the game may have been reinstalled or updated). Link it again — it only takes a moment.</div>" : "") +
    "<p>" + game + " can't receive files straight from another app, but it has its own folder on your iPhone. Link that folder once and every unit you send lands right in it — no searching through folders.</p>" +
    '<ol class="help-steps"><li>Tap <strong>Choose ' + game + "'s folder</strong>.</li><li>Go to <strong>Browse › On My iPhone › " + game + "</strong>.</li><li>Tap <strong>Open</strong>.</li></ol>" +
    '<div class="row"><button class="button" id="gf-link">📁 Choose ' + game + "'s folder</button>" + '<button class="button ghost" id="gf-sheet">Save somewhere else this time</button></div>' +
    '<p class="hint">Only that one folder is used, and only to save your units. Nothing inside ' + game + " is read or changed.</p>");
  const close = () => document.getElementById("dialog").close();
  $("#gf-sheet").onclick = () => { close(); exportProject.useSheet = true; exportProject(sendKind).catch((e) => toast(e.message, true)); };
  $("#gf-link").onclick = async () => {
    let r;
    try { r = await Native.call("linkGameFolder", { target }); } catch (e) { return toast(e.message || String(e), true); }
    if (!r || !r.linked) return toast("No folder chosen. Nothing was sent.");
    if (r.looksRight === false) {
      dialog("Is this " + game + "'s folder?", "<p>You picked <strong>" + esc(r.name) + "</strong>. " + game + "'s folder is normally <strong>On My iPhone › " + game + "</strong>. Files saved anywhere else won't show up in the game's importer.</p>" +
        '<div class="row"><button class="button ghost" id="gf-again">Pick again</button><button class="button subtle" id="gf-anyway">Use it anyway</button></div>');
      $("#gf-again").onclick = async () => { await Native.call("unlinkGameFolder", { target }).catch(() => {}); showFolderSetup(target, sendKind, false); };
      $("#gf-anyway").onclick = () => { close(); exportProject(sendKind).catch((e) => toast(e.message, true)); };
      return;
    }
    close(); toast(game + "'s folder is linked. Sending your unit…");
    exportProject(sendKind).catch((e) => toast(e.message, true));
  };
}
// after "Import to Eclipse / Sparking": where the file is and the one step left inside the game
function showSendOutcome(target, r, p, sendKind) {
  if (!r || !r.saved) return toast("Not sent. Your unit is still saved on this device.");
  const game = target === "eclipse" ? "Eclipse" : "Sparking", file = esc(r.file || "");
  const where = r.folder ? "<strong>" + esc(r.folder) + "</strong>" : "the folder you chose";
  const ios = document.documentElement.classList.contains("ios-app");
  const steps = target === "eclipse"
    ? "<li>In Eclipse, open <strong>Patches</strong> and tap <strong>＋</strong>.</li><li>Pick <strong>" + file + "</strong> in " + where + ".</li><li>Restart Eclipse when it asks.</li>"
    : ios ? "<li>In Sparking, tap <strong>Import Patch</strong>.</li><li>Pick <strong>" + file + "</strong> in " + where + ".</li><li>Turn the patch on and restart Sparking when it asks.</li>"
    : "<li>In Sparking, open the <strong>SPRK File Manager</strong>.</li><li>Tap <strong>Import</strong> on <strong>" + file + "</strong> (in " + where + ").</li><li>Restart Sparking when it asks.</li>";
  const status = r.same ? '<div class="notice success">✓ This exact unit is already in ' + game + "'s folder, so no second copy was made. If you imported it before, there's nothing more to do.</div>"
    : r.replaced ? '<div class="notice success">✓ Updated the older copy of this unit in ' + game + "'s folder (no duplicate). Import it again in " + game + " to get the changes.</div>"
    : r.direct ? '<div class="notice success">✓ Saved straight into ' + game + "'s folder.</div>" : "";
  const eclipseMade = target === "sparking" && p && p.source?.database !== "sparking";
  dialog((r.opened ? "Opening " : "Saved for ") + game, status + '<p>' + (r.opened ? game + " is opening. " : "Open " + game + " now. ") + "Your unit was saved as <strong>" + file + "</strong> in " + where + ".</p><ol class=\"help-steps\">" + steps + "</ol>" +
    (eclipseMade ? '<p class="hint">This unit was made from Eclipse characters. If Sparking doesn\'t have one of its moves or pictures, make it from a Sparking character instead (Library › Sparking).</p>' : "") +
    '<div class="row"><button class="button" id="send-done">Done</button>' + (r.direct && ios ? '<button class="button subtle" id="send-relink">Use a different folder</button>' : "") + "</div>");
  const b = document.getElementById("send-done"); if (b) b.onclick = () => document.getElementById("dialog").close();
  const rl = document.getElementById("send-relink");
  if (rl) rl.onclick = async () => { await Native.call("unlinkGameFolder", { target }).catch(() => {}); showFolderSetup(target, sendKind || "to-" + target, false); };
}
async function attachAsset(key, gamePath) {
  if (!state.project) return toast("Open or create a unit before attaching resources.");
  if (state.project.assets.some((a) => a.key === key)) return toast("This file is already attached.");
  state.project.assets.push({ key, path: gamePath });
  scheduleSave();
  toast("Attached to your current unit. Review its destination under Visuals.");
}
async function databaseTask(title, work) {
  let active = true;
  const detail = $("#busy-detail");
  const poll = async () => {
    try {
      const p = await Native.call("importStatus");
      if (!active || !detail || !(p == null ? void 0 : p.label)) return;
      detail.textContent = p.label + (p.bytes ? " · " + (p.bytes / 1024 / 1024).toFixed(1) + (p.total ? " / " + (p.total / 1024 / 1024).toFixed(1) : "") + " MB" : "");
    } catch {
    }
  };
  const timer = setInterval(poll, 750);
  try {
    if (detail) detail.textContent = "Keep the app open while this finishes.";
    return await busy(title, work);
  } finally {
    active = false;
    clearInterval(timer);
  }
}
function databaseDetails() {
  const meta = state.info.meta || {}, apk = meta.apk;
  const date = (value) => {
    if (!value) return "";
    const d = new Date(value);
    return Number.isNaN(d.getTime()) ? String(value) : d.toLocaleString();
  };
  return '<div class="database-details"><p><strong>Database source:</strong> ' + esc(meta.sourceType === "apk-embedded" ? "Inside the imported APK" : meta.sourceType === "eclipse-current" ? "Eclipse current full English database" : meta.source) + "</p>" + (apk ? "<p><strong>Imported APK:</strong> " + esc(apk.filename) + "<br>" + esc(apk.versionName || "Eclipse") + " · Game " + esc(apk.gameVersion || "version not provided") + "</p>" : "") + "<p><strong>Last updated:</strong> " + esc(date(meta.date)) + (meta.publishedAt ? "<br><strong>Published by Eclipse:</strong> " + esc(date(meta.publishedAt)) : "") + "</p>" + (meta.sha256 ? '<details><summary>Database details</summary><p class="hint">SHA-256: ' + esc(meta.sha256) + (apk ? "<br>APK SHA-256: " + esc(apk.sha256) : "") + "</p></details>" : "") + "</div>";
}
function assetKind(name) {
  const extension = String(name).split(".").pop().toLowerCase();
  return ["png", "jpg", "jpeg", "webp", "gif", "bmp"].includes(extension) ? "Image" : extension === "lua" ? "Animation instructions" : extension === "lwf" ? "Animated artwork" : extension === "usm" ? "Game movie" : extension === "cpk" ? "Resource archive" : ["db", "sqlite", "sqlite3"].includes(extension) ? "Game database" : "Game resource";
}
async function renderImportedAssets(focus = false) {
  const request = ++assetRequest, query = state.assetQuery, offset = state.assetOffset || 0, pageSize = 40;
  const rows = await Native.call("assets", { query, offset, limit: pageSize + 1 });
  if (state.view !== "assets" || state.assetTab !== "local" || request !== assetRequest || query !== state.assetQuery || offset !== (state.assetOffset || 0) || !$("#asset-results")) return;
  const items = rows.slice(0, pageSize), hasMore = rows.length > pageSize;
  $("#asset-results").innerHTML = '<form id="asset-search-form" class="source-controls"><input id="asset-query" aria-label="Search imported assets" placeholder="Search imported file names…" value="' + esc(query) + '"><button class="button ghost" type="submit">Search files</button></form><p class="hint" id="asset-result-status" role="status" aria-live="polite" tabindex="-1">' + (items.length ? "Showing " + number(offset + 1) + "–" + number(offset + items.length) + (hasMore ? " · More files available" : "") : query ? "No files match your search." : "No resources imported yet.") + "</p>" + (items.length ? '<div class="asset-list">' + items.map((a) => '<article class="asset-item"><div><span class="chip">' + assetKind(a.name) + "</span><h3>" + esc(a.name) + "</h3><p>" + esc(a.path) + " · " + number(a.size) + ' bytes</p></div><button class="button ghost small" data-attach-asset="' + esc(a.key) + '" data-game-path="' + esc(a.path) + '">Attach to unit</button>' + (a.image ? '<button class="button subtle small" data-preview-asset="' + esc(a.key) + '">Preview image</button>' : "") + "</article>").join("") + "</div>" : '<div class="empty"><h2>' + (query ? "No matching resources" : "No resources imported yet") + "</h2><p>" + (query ? "Try a shorter file name or clear the search to browse all imported resources." : "Import a build/archive or your own images. Existing source resources do not need to be bundled again.") + "</p>" + (query ? '<button class="button ghost" id="clear-asset-search">Show all imported files</button>' : '<button class="button ghost" data-action="import">Import resources</button>') + "</div>") + (offset || hasMore ? '<nav class="row library-pages" aria-label="Imported resource pages"><button class="button ghost" data-action="asset-prev"' + (!offset ? " disabled" : "") + '>Previous files</button><button class="button ghost" data-action="asset-next"' + (!hasMore ? " disabled" : "") + ">Next files</button></nav>" : "");
  bindDynamic($("#asset-results"));
  $("#asset-search-form").addEventListener("submit", (event) => {
    event.preventDefault();
    action("asset-search").catch((error) => toast(error.message, true));
  });
  if ($("#clear-asset-search")) $("#clear-asset-search").addEventListener("click", () => {
    state.assetQuery = "";
    state.assetOffset = 0;
    renderImportedAssets(true).catch((error) => toast(error.message, true));
  });
  if (!state.expert) $("#asset-results").querySelectorAll(".asset-item p").forEach((el) => {
    el.textContent = el.textContent.slice(el.textContent.lastIndexOf(" · ") + 3);
  });
  if (focus) {
    const status = $("#asset-result-status");
    status.focus();
    status.scrollIntoView({ block: "start" });
  }
}
async function previewImportedAsset(key) {
  const url = await busy("Opening the imported image", () => Native.call("assetUrl", { key }));
  if (!url) return;
  dialog("Imported image preview", '<img class="imported-image-preview" src="' + esc(url) + '" alt="Imported artwork">' + (state.project ? '<p class="hint">This image can be used in the editor. Game artwork requires a complete compatible resource pack.</p><button class="button" id="use-imported-preview">Use as editor preview</button>' : '<p class="hint">Open or create a unit to use this image as its editor preview. Game artwork is configured separately.</p>'));
  if ($("#use-imported-preview")) $("#use-imported-preview").addEventListener("click", () => {
    state.project.previewKey = key;
    state.previewUrl = url;
    scheduleSave();
    $("#dialog").close();
    toast("Editor preview updated.");
  });
}
const onlineAssetCategories = [["", "All game resource folders"], ["character/card", "Card artwork"], ["character/card_bg", "Animated card backgrounds"], ["character/thumb", "Card portraits"], ["ingame/battle/character", "Fighter artwork and poses"], ["lua/ab_script", "Battle animation instructions"], ["movie", "Game movie files"], ["layout", "Game interface resources"]];
function renderOnlineAssetListing(data, path, { loading = false, error = "", focus = false } = {}) {
  var _a, _b;
  const node = $("#asset-results");
  if (!node) return;
  const category = onlineAssetCategories.filter(([prefix]) => prefix && (path === prefix || path.startsWith(prefix + "/"))).sort((a, b) => b[0].length - a[0].length)[0] || (!path ? onlineAssetCategories[0] : null), title = category ? category[1] : "Current game resource folder", nested = category && path !== category[0] ? path.slice(category[0].length + 1) : "", current = (_a = category == null ? void 0 : category[0]) != null ? _a : "__current__", choices = category ? onlineAssetCategories : [["__current__", "Current folder"], ...onlineAssetCategories], items = Array.isArray(data == null ? void 0 : data.items) ? data.items : [], pageSize = 40, pages = Math.max(1, Math.ceil(items.length / pageSize));
  state.assetOnlinePage = Math.min(pages - 1, Math.max(0, Number(state.assetOnlinePage) || 0));
  const start = state.assetOnlinePage * pageSize, shown = items.slice(start, start + pageSize);
  node.innerHTML = '<label class="field">What would you like to browse?<select id="online-asset-category">' + selection(choices, current) + "</select><small>Choose by purpose. You can open folders below without typing game file locations.</small></label>" + (state.expert ? '<details><summary>Open a specific resource folder</summary><form id="online-path-form" class="source-controls"><input id="online-path" aria-label="Eclipse resource folder" value="' + esc(path) + '" placeholder="character, lua, layout…"><button class="button ghost" type="submit">Go to folder</button></form><p class="hint">Current location: /' + esc(path) + "</p></details>" : "") + '<div class="section-heading"><h2 id="online-asset-folder-title">' + esc(title) + "</h2>" + (path ? '<button class="button subtle small" data-asset-folder="' + esc((_b = data == null ? void 0 : data.parentPath) != null ? _b : path.split("/").slice(0, -1).join("/")) + '">Parent folder</button>' : "") + "</div>" + (nested ? '<p class="hint">Subfolder: ' + esc(nested.split("/").pop()) + "</p>" : "") + '<p class="hint" id="online-asset-folder-status" tabindex="-1" role="status" aria-live="polite">' + (loading ? "Loading this resource folder…" : error ? "This folder could not be loaded." : items.length ? "Showing " + (start + 1) + "–" + Math.min(start + pageSize, items.length) + " of " + number(items.length) + " entries" : "No public entries are available in this folder.") + "</p>" + (error ? '<div class="notice error" role="alert">' + esc(error) + '</div><button class="button ghost" data-action="external-files">Open the official file browser</button>' : loading ? "" : shown.length ? '<table class="asset-table"><thead><tr><th scope="col">NAME</th><th scope="col">SIZE</th><th scope="col">ACTION</th></tr></thead><tbody>' + shown.map((a) => "<tr><td>" + esc(a.name) + "</td><td>" + (a.type === "directory" ? "Folder" : number(a.size || 0) + " B") + "</td><td>" + (a.type === "directory" ? '<button class="button ghost small" data-asset-folder="' + esc(a.path) + '">Open folder</button>' : '<button class="button ghost small" data-download-asset="' + esc(a.path) + '">Download</button>') + "</td></tr>").join("") + "</tbody></table>" : "") + (!loading && !error && pages > 1 ? '<nav class="row library-pages" aria-label="Public resource pages"><button class="button ghost" data-online-page="' + (state.assetOnlinePage - 1) + '"' + (!state.assetOnlinePage ? " disabled" : "") + ">Previous files</button><span>Page " + (state.assetOnlinePage + 1) + " of " + pages + '</span><button class="button ghost" data-online-page="' + (state.assetOnlinePage + 1) + '"' + (state.assetOnlinePage === pages - 1 ? " disabled" : "") + ">Next files</button></nav>" : "") + '<p class="hint">For choosing character moves with previews, use the animation editor. These optional resource folders contain individual game files.</p>';
  bindDynamic(node);
  $("#online-asset-category").onchange = () => {
    const value = $("#online-asset-category").value;
    if (value === "__current__") return;
    state.assetPath = value;
    state.assetOnlinePage = 0;
    renderAssets().catch((error2) => toast(error2.message, true));
  };
  node.querySelectorAll("[data-online-page]").forEach((button) => button.onclick = () => {
    state.assetOnlinePage = Number(button.dataset.onlinePage);
    renderOnlineAssetListing(data, path, { focus: true });
  });
  const form = $("#online-path-form");
  if (form) form.onsubmit = (event) => {
    event.preventDefault();
    action("asset-open-path").catch((error2) => toast(error2.message, true));
  };
  if (focus) {
    $("#online-asset-folder-status").focus();
    $("#online-asset-folder-status").scrollIntoView({ block: "start" });
  }
}
async function loadOnlineAssetListing() {
  const request = ++assetRequest, path = state.assetPath;
  state.assetListing = null;
  renderOnlineAssetListing(null, path, { loading: true });
  try {
    const data = await Native.call("browseAssets", { path });
    if (state.view !== "assets" || state.assetTab !== "online" || request !== assetRequest || path !== state.assetPath) return;
    if (data == null ? void 0 : data.error) throw Error(data.error);
    if (!Array.isArray(data == null ? void 0 : data.items)) throw Error("This resource folder returned an unreadable listing. Choose another category or try again.");
    state.assetListing = data;
    renderOnlineAssetListing(data, path);
  } catch (error) {
    if (state.view === "assets" && state.assetTab === "online" && request === assetRequest && path === state.assetPath) renderOnlineAssetListing(null, path, { error: error.message || String(error) });
  }
}
async function renderAssets() {
  var _a;
  let html = '<div class="section-heading"><div><h1>Game data & files</h1><p>The character list and game files the app uses. You only need this to update to a newer Eclipse version or add extra game files.</p></div></div><section class="panel"><div class="section-heading"><div><h2>' + number(state.info.count) + " source cards</h2><p>" + esc(state.info.meta.source) + '</p></div></div><div class="row"><button class="button" data-action="import-apk">Import Eclipse APK</button><button class="button ghost" data-action="sync">Refresh Eclipse data</button><button class="button ghost" data-action="import">Import other files</button>' + (state.lastImportReport ? '<button class="button subtle" data-action="import-report">Last import results</button>' : "") + (((_a = state.info.database) == null ? void 0 : _a.canRestore) ? '<button class="button subtle" data-action="restore-database">Restore previous database</button>' : "") + '</div><p class="hint"><strong>Refresh Eclipse data</strong> downloads the newest character list. <strong>Import Eclipse APK</strong> reads it from an Eclipse install file on this phone instead. Your units are never changed.</p><details class="beginner-details"><summary>Details</summary>' + databaseDetails() + '<p class="hint">The app reads the APK’s resources and database. If the APK only has starter or encrypted data, the app downloads Eclipse’s full English database (~100 MB, needs Internet). New data is used only after it checks out. Keep several hundred MB free; large resource archives may need several GB.</p></details></section><div class="tabs"><button data-action="asset-local" class="' + (state.assetTab === "local" ? "active" : "") + '">Imported assets</button><button data-action="asset-online" class="' + (state.assetTab === "online" ? "active" : "") + '">Browse Eclipse</button></div><div id="asset-results"><p class="hint">Loading resources…</p></div>';
  main(html);
  if (state.assetTab === "local") await renderImportedAssets();
  else await loadOnlineAssetListing();
}
async function renderAI() {
  main('<div class="section-heading"><div><p class="eyebrow">YOUR EXISTING SUBSCRIPTIONS</p><h1>Design with your AI assistants</h1><p>Ask for kit ideas, balance feedback, and explanations. Apply their suggestions in the unit editor.</p></div></div><section class="panel"><h2>Bring your unit context</h2><p class="hint">Copy a design prompt for your current unit, then paste it into the AI app. Your subscriptions stay in the official apps; the creator does not read their chats.</p><button class="button" data-action="copy-prompt">Copy current unit prompt</button></section><div id="ai-results"><p class="hint">Opening assistant options…</p></div>');
  const result = await Native.call("ai");
  if (state.view !== "ai") return;
  if (Array.isArray(result)) {
    $("#ai-results").innerHTML = '<div class="ai-grid">' + result.map((p) => '<article class="ai-card"><h2>' + esc(p.name) + '</h2><span class="chip teal">' + (p.installed ? "APP INSTALLED" : "WEBSITE FALLBACK") + "</span><p>Use your own " + esc(p.name) + ' account. Open its installed app when available, otherwise its official website.</p><button class="button ghost" data-ai="' + esc(p.id) + '">Open ' + esc(p.name) + "</button></article>").join("") + "</div>";
    bindDynamic($("#ai-results"));
  } else {
    $("#ai-results").innerHTML = '<section class="panel"><h2>AI launcher</h2><p class="hint">The assistant launcher opens the installed Android apps, with their websites as the fallback.</p><button class="button ghost" data-action="native-ai">Open AI launcher</button></section>';
    bindDynamic($("#ai-results"));
  }
}
async function boot() {
  window.__forgeWorkspaceStartup = "loading";
  var _a, _b;
  bindTop();
  try {
    state.info = await Native.call("info");
    await loadLookups();
    let recovered = false, retainedDraft = false;
    try {
      const draft = JSON.parse(localStorage.getItem("forge-draft") || "null");
      if ((draft == null ? void 0 : draft.format) === "dokkan-unit-forge" && draft.version === 1 && ((_b = (_a = draft.tables) == null ? void 0 : _a.cards) == null ? void 0 : _b.length) === 1) {
        let saved;
        try {
          saved = await Native.call("loadProject", { key: draft.key });
        } catch {
        }
        if (!saved || String(draft.updatedAt) > String(saved.updatedAt)) {
          const recovery = await Native.call("saveProject", { project: draft });
          if (recovery?.saved === true && recovery.superseded !== true) recovered = true;
          else retainedDraft = true;
        }
        if (!retainedDraft) localStorage.removeItem("forge-draft");
      }
    } catch {
    }
    state.projects = await Native.call("projects");
    updateNav();
    renderHome();
    if (recovered) toast("Your latest edits were recovered after the app closed.");
    if (retainedDraft) toast("An unsaved backup is still on this device because recovery was not confirmed. Keep this app installed while resolving the save conflict.", true);
    window.__forgeWorkspaceStartup = "ready";
  } catch (error) {
    window.__forgeWorkspaceStartup = "failed";
    main('<section class="panel"><h1>Could not open the creator</h1><div class="notice error">' + esc(error.message) + '</div><p class="hint">Close and reopen the app. The bundled database must finish preparing on first launch.</p></section>');
  }
}
// All deferred feature controllers must register before even a synchronous bridge can boot.
window.__forgeWorkspaceStartup = "loading";
if(document.readyState === "complete") boot();
else document.addEventListener("DOMContentLoaded", () => boot(), {once:true});
