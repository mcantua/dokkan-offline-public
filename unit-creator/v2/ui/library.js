"use strict";
function renderLibrary() {
  var _a;
  main('<div class="section-heading"><div><h1>Library</h1><p>Your units and game files. Tap a unit to keep editing it.</p></div><button class="button" data-action="import">Import file ↑</button></div><div class="tabs library-tabs">' + [["all", "Everything"], ["created", "Made by me (" + state.projects.filter((p) => p.origin !== "uploaded").length + ")"], ["uploaded", "Imported (" + state.projects.filter((p) => p.origin === "uploaded").length + ")"], ["patches", "Game files (" + state.patches.length + ")"], ["sparking", "Sparking characters"]].map(([key, label]) => '<button data-library-filter="' + key + '" aria-pressed="' + (state.libraryFilter === key ? "true" : "false") + '" class="' + (state.libraryFilter === key ? "active" : "") + '">' + label + "</button>").join("") + '</div><div class="source-controls"><input id="library-query" aria-label="Search library" placeholder="Search unit, author, ID, or patch…" value="' + esc(state.libraryQuery) + '"></div><div id="library-results"></div><section id="sparking-content"></section><details class="panel library-more"><summary><strong>More tools</strong> <span class="hint">Shared Dodge actions, Sparking builds, Eclipse</span></summary><section class="panel"><h2>Shared custom actions</h2><p>Update the shared Dodge file after changing, restoring, or removing saved custom Dodge designs. Your current saved Library is checked before any file is made.</p><button class="button ghost" id="update-library-shared-actions">Update shared actions</button></section><section id="library-extras"></section><section class="panel library-status"><h2>Build imports</h2><p class="hint">To open Sparking patches, first import the original Sparking 6.5.5 APK or its ZIP, then import a .sprk file. Portable game SQL and assets are converted to ECLP and shown in the Sparking category. Sparking-only local roster SQL and Areas are stopped with an explanation. The Sparking tab includes the downloaded source catalogue. Choose a character there to make an editable copy and prepare its matching resources. Original patches are also supported.</p><button class="button ghost small" data-action="assets">Import build resources</button></section></details>');
  $("#update-library-shared-actions").onclick = () => updateLibrarySharedActions().catch((error) => toast(error.message, true));
  (_a = window.ForgeSparking) == null ? void 0 : _a.mountLibraryEntry($("#library-extras"));
  $("#library-query").addEventListener("input", (e) => {
    state.libraryQuery = e.target.value;
    state.libraryPage = 0;
    renderLibraryResults();
  });
  $("#library-rarity")?.addEventListener("change", (e) => {
    state.libraryRarity = e.target.value;
    state.libraryPage = 0;
    renderLibraryResults();
  });
  document.querySelectorAll("[data-library-filter]").forEach((b) => b.addEventListener("click", () => {
    state.libraryFilter = b.dataset.libraryFilter;
    state.libraryPage = 0;
    document.querySelectorAll("[data-library-filter]").forEach((el) => {
      el.classList.toggle("active", el === b);
      el.setAttribute("aria-pressed", String(el === b));
    });
    renderLibraryResults();
    renderSparkingLibraryPanel();
  }));
  renderLibraryResults();
  renderSparkingLibraryPanel();
}
function renderSparkingLibraryPanel() {
  const target = $("#sparking-content");
  if (!target) return;
  if(!$("#library-open-eclipse")) {
    const launcher=document.createElement("section");launcher.className="panel";
    launcher.innerHTML='<h2>Play your unit in Dokkan Eclipse</h2><p>Open your unit, go to the last step (Save &amp; Play) and tap Save game file. Then load that .eclp file with Eclipse’s patch importer.</p><button class="button ghost" id="library-open-eclipse">Open Dokkan Eclipse</button>';
    ($("#library-results") ? $("#library-results").after(launcher) : target.before(launcher));
    launcher.querySelector("button").onclick=async()=>{try{const result=await Native.call("openEclipse");if(!result.installed)toast("Eclipse is not installed. Its official download page was requested.");}catch(error){toast(error.message,true);}};
  }
  target.hidden = state.libraryFilter !== "sparking";
  if (!target.hidden && !target.dataset.mounted && window.ForgeSparkingContent) {
    target.dataset.mounted = "true";
    window.ForgeSparkingContent.mount(target);
  }
}
function renderLibraryResults() {
  const q = state.libraryQuery.trim().toLocaleLowerCase(), filter = state.libraryFilter;
  const units = state.projects.filter((p) => filter !== "patches" && (filter === "all" || filter === "sparking" && (p.sourceDatabase === "sparking" || p.sparkingAnimations) || (p.origin === "uploaded" ? "uploaded" : "created") === filter) && (state.libraryRarity === "" || String(p.rarity) === state.libraryRarity) && [p.name, p.author, p.targetId, p.sourceFile].join(" ").toLocaleLowerCase().includes(q));
  const patches = state.patches.filter((p) => (filter === "all" || filter === "patches" || filter === "sparking" && String(p.metadata.sourceFormat || "").startsWith("sparking-")) && state.libraryRarity === "" && [p.metadata.name, p.metadata.author, p.metadata.uuid, p.filename].join(" ").toLocaleLowerCase().includes(q));
  const pageSize = 48, total = units.length + patches.length, pages = Math.max(1, Math.ceil(total / pageSize));
  state.libraryPage = Math.min(pages - 1, Math.max(0, Number(state.libraryPage) || 0));
  const start = state.libraryPage * pageSize, end = start + pageSize, shownUnits = units.slice(start, end), shownPatches = patches.slice(Math.max(0, start - units.length), Math.max(0, end - units.length));
  $("#library-results").innerHTML = '<p class="hint library-result-status" id="library-result-status" role="status" aria-live="polite" tabindex="-1">' + (total ? "Showing " + (start + 1) + "–" + Math.min(end, total) + " of " + number(total) + " matching items" : "No matching items") + "</p>" + (shownUnits.length ? '<div class="section-heading"><h2>Your units <span class="count">' + units.length + '</span></h2></div><div class="unit-grid">' + shownUnits.map((p) => '<button class="unit-tile" data-open="' + esc(p.key) + '"><div class="tile-art"><img class="art-pending" data-unit-art="' + esc(p.key) + '" loading="lazy" alt="' + esc(p.name) + '"></div><div class="tile-body"><span class="chip ' + (p.origin === "uploaded" ? "teal" : "orange") + '">' + (p.origin === "uploaded" ? "UPLOADED" : "CREATED") + '</span> ' + (window.ForgeRarityBadge && ForgeRarityBadge.iconFor(p) ? '<span class="chip has-rb">' + ForgeRarityBadge.html(ForgeRarityBadge.iconFor(p)) : '<span class="chip">' + esc(Forge.rarities[p.rarity] || "UNIT")) + "</span><h3>" + esc(p.name) + "</h3><p>" + esc(Forge.elements[p.element] || "") + " · " + esc(p.targetId) + "</p><p>" + esc(p.author || "No author set") + "</p></div></button>").join("") + "</div>" : "") + (shownPatches.length ? '<div class="section-heading"><h2>Game files (.eclp) <span class="count">' + patches.length + '</span></h2></div><div class="unit-grid">' + shownPatches.map((p) => '<button class="unit-tile patch-tile" data-patch="' + esc(p.key) + '"><div class="tile-body"><span class="chip teal">.ECLP</span>' + (String(p.metadata.sourceFormat || "").startsWith("sparking-") ? ' <span class="chip orange">SPARKING</span>' : "") + '<h3>' + esc(p.metadata.name) + "</h3><p>" + esc(p.metadata.author || "Unknown author") + " · v" + esc(p.metadata.version) + "</p><p>" + p.count + " files · " + number(p.bytes) + " bytes</p><p>" + esc(p.filename) + "</p></div></button>").join("") + "</div>" : "") + (!units.length && !patches.length ? '<section class="empty"><div class="empty-icon">▤</div><h2>No matching items</h2><p>Create a unit or import a unit backup (.json) or a game file (.eclp). Your creations will appear here automatically.</p><button class="button ghost" data-action="new">Create a unit</button></section>' : "") + (pages > 1 ? '<nav class="library-pages row" aria-label="Library pages"><button class="button ghost" data-library-page="' + (state.libraryPage - 1) + '"' + (state.libraryPage === 0 ? " disabled" : "") + ">Previous page</button><span>Page " + (state.libraryPage + 1) + " of " + pages + '</span><button class="button ghost" data-library-page="' + (state.libraryPage + 1) + '"' + (state.libraryPage === pages - 1 ? " disabled" : "") + ">Next page</button></nav>" : "");
  $("#library-results").querySelectorAll("[data-library-page]").forEach((button) => button.addEventListener("click", () => {
    state.libraryPage = Number(button.dataset.libraryPage);
    renderLibraryResults();
    const status = $("#library-result-status");
    status.focus();
    status.scrollIntoView({ block: "start" });
  }));
  window.ForgeCollectionArt?.mount($("#library-results"),shownUnits);
  bindDynamic($("#library-results"));
  $("#library-results").querySelectorAll("[data-patch]").forEach((b) => b.addEventListener("click", () => showPatch(b.dataset.patch)));
}
function showPatch(key) {
  const p = state.patches.find((p2) => p2.key === key);
  if (!p) return;
  dialog(p.metadata.name, "<p>" + esc(p.metadata.description || "No description supplied.") + "</p>" + (p.metadata.compatibility ? '<p class="notice warning">' + esc(p.metadata.compatibility) + "</p>" : "") + '<p class="hint">Author: ' + esc(p.metadata.author || "Unknown") + " · Version: " + esc(p.metadata.version) + "<br>UUID: " + esc(p.metadata.uuid) + '</p><div class="row"><button class="button" id="library-export-patch">Save ECLP</button>' + (p.projectKey ? '<button class="button ghost" id="library-edit-patch">Edit unit project</button>' : "") + "</div>" + (!p.projectKey ? '<p class="hint">This patch has no editable unit project. Its original SQL and resources are preserved for installation in Eclipse.</p>' : "") + "<h3>Patch files (" + p.count + ')</h3><div class="patch-files">' + p.entries.slice(0, 200).map((e) => "<p>" + esc(e.path) + " <small>" + number(e.size) + " B</small></p>").join("") + "</div>");
  $("#library-export-patch").addEventListener("click", () => busy("Saving your Eclipse patch", async () => {
    const name = String(p.metadata.name).replace(/[^a-zA-Z0-9_-]+/g, "-").slice(0, 80) || "unit-patch";
    const r = await Native.call("export", { name: name + ".eclp", kind: "eclp", patchKey: p.key });
    if (r == null ? void 0 : r.saved) toast("ECLP saved.");
  }));
  if (p.projectKey) $("#library-edit-patch").addEventListener("click", () => {
    $("#dialog").close();
    openUnit(p.projectKey);
  });
}
