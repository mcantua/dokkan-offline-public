(function(root, factory) {
  if (typeof module === "object" && module.exports) module.exports = factory();
  else root.ForgeMovies = factory();
})(typeof globalThis !== "undefined" ? globalThis : this, function() {
  "use strict";
  const groups = { battle: "Battle scenes", events: "Story & event movies", tutorial: "Tutorial scenes", imported: "Imported movies" };
  const safePath = (value) => typeof value === "string" && /^movie\/[a-z0-9_./-]+\.usm$/i.test(value) && value.length < 300 && !value.split("/").some((x) => !x || x === "." || x === "..");
  const escape = (value) => String(value != null ? value : "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
  function localPath(value) {
    const parts = String(value || "").replace(/\\/g, "/").split("/"), i = parts.findIndex((p) => p.toLowerCase() === "movie");
    if (parts.some((p) => p === "." || p === "..")) return null;
    if (i < 0) return null;
    const result = parts.slice(i).join("/");
    return safePath(result) ? result : null;
  }
  function merge(publicItems, localItems = []) {
    const rows = new Map((publicItems || []).filter((x) => safePath(x.path)).map((x) => [x.path, { ...x, imported: false }]));
    for (const asset of localItems) {
      const p = localPath(asset.path || asset.name);
      if (!p || Number(asset.size) < 32) continue;
      const previous = rows.get(p), name = String(asset.name || p.split("/").pop());
      rows.set(p, { ...previous || { path: p, title: name.replace(/\.usm$/i, "") || "Imported game movie", variation: 0, format: "Imported", group: "imported" }, status: "available", format: "Imported", size: Number(asset.size) || 0, imported: true, importedName: name, assetKey: asset.key });
    }
    return [...rows.values()];
  }
  function filter(items, { search = "", group = "all", format = "all", available = "all" } = {}) {
    const words = String(search).trim().toLocaleLowerCase().split(/\s+/).filter(Boolean);
    return items.filter((x) => (group === "all" || (group === "imported" ? x.imported : x.group === group)) && (format === "all" || x.format === format) && (available === "all" || (available === "available" ? x.status === "available" : x.status !== "available")) && words.every((w) => [x.title, groups[x.group], x.format, x.importedName, x.path, x.imported ? "imported" : ""].join(" ").toLocaleLowerCase().includes(w)));
  }
  async function mount(container) {
    if (!container) throw Error("Movie browser container is missing.");
    const catalog = typeof ForgeMovieCatalog !== "undefined" ? ForgeMovieCatalog : { items: [] };
    let items = merge(catalog.items), query = { search: "", group: "all", format: "all", available: "available" }, offset = 0, loading = false;
    const pageSize = 12;
    container.innerHTML = '<div class="panel movie-intro"><h2>Choose a movie and watch it</h2><p>Browse battle scenes, story movies, and older game videos. Movies are prepared on this device. Played resources are saved for offline replay.</p><p class="hint">Choose character moves in the animation editor when you want to build or assign a gameplay animation.</p><div class="source-controls"><label class="field">Find a movie<input id="movie-search" type="search" placeholder="Character, move, or story…" autocomplete="off"></label><label class="field">Where it appears<select id="movie-group"><option value="all">All game movies</option>' + Object.entries(groups).map(([k, v]) => '<option value="' + k + '">' + v + "</option>").join("") + '</select></label><label class="field" hidden>Show<select id="movie-available"><option value="all">All, including missing files</option><option value="available">Available to load</option><option value="unavailable">Missing from public resources</option></select></label></div><details class="movie-extra" hidden><summary>More movie filters</summary><label class="field">Video format<select id="movie-format"><option value="all">All formats</option><option>AV1</option><option>VP9</option><option>MPEG-1</option><option>Imported</option><option>Unknown</option></select></label><p class="hint">The app chooses the decoder automatically.</p></details><div id="movie-offline" class="notice" hidden>Checking saved resources…</div><div class="row"><button type="button" class="button ghost small" id="movie-local-refresh" hidden>Check imported movies</button><button type="button" class="button subtle small" id="movie-reset">Clear filters</button></div><p id="movie-summary" class="hint" role="status" aria-live="polite"></p></div><div id="movie-results"></div><nav class="row movie-pages" aria-label="Movie pages"><button type="button" class="button ghost" id="movie-previous">Previous movies</button><button type="button" class="button ghost" id="movie-next">Next movies</button></nav>';
    const find = (selector) => container.querySelector(selector);
    const connected = () => container.isConnected;
    function render() {
      if (!connected()) return;
      const matches = filter(items, query);
      offset = Math.min(offset, Math.max(0, Math.floor((matches.length - 1) / pageSize) * pageSize));
      const shown = matches.slice(offset, offset + pageSize);
      find("#movie-summary").textContent = matches.length ? "Showing " + (offset + 1) + "–" + (offset + shown.length) + " of " + matches.length + " movies. " + items.filter((x) => x.status !== "available").length + " public files are placeholders." : "No movies match these choices. Try a shorter character name or clear the filters.";
      find("#movie-results").innerHTML = shown.length ? '<div class="movie-grid">' + shown.map((x, i) => '<article class="panel movie-card"><div class="movie-symbol" aria-hidden="true">▶</div><span class="chip">' + escape(groups[x.group] || "Game movie") + "</span><h3>" + escape(x.title) + '</h3><p class="hint">' + (x.variation ? "Visual variation " + x.variation + " · " : "") + (x.size / 1048576).toFixed(1) + " MB" + (x.imported ? " · Imported on this device" : "") + "</p>" + (x.status === "available" ? '<button type="button" class="button" data-movie-preview="' + i + '">Preview movie</button><button type="button" class="button ghost" data-movie-edit="' + i + '">Edit and combine</button>' : '<p class="notice movie-unavailable">This public file is a placeholder. Import a resource pack containing this movie to preview it.</p><button type="button" class="button ghost" disabled aria-disabled="true">Movie unavailable</button>') + '<details class="movie-extra"><summary>Movie details</summary><p>' + escape(x.format) + ' video</p><p class="movie-reference">' + escape(x.path) + "</p></details></article>").join("") + "</div>" : '<div class="empty"><h3>No matching movies</h3><p>Clear the filters to browse the catalog.</p></div>';
      find("#movie-previous").disabled = offset === 0;
      find("#movie-next").disabled = offset + pageSize >= matches.length;
      for (const button of container.querySelectorAll("[data-movie-edit]")) button.onclick = () => ForgeMovieEditor.open(shown[Number(button.dataset.movieEdit)]).catch((error) => {
        find("#movie-summary").textContent = error.message;
      });
      for (const button of container.querySelectorAll("[data-movie-preview]")) button.onclick = async () => {
        const movie = shown[Number(button.dataset.moviePreview)];
        if (!movie || movie.status !== "available") return;
        button.disabled = true;
        const previous = button.textContent;
        button.textContent = "Opening movie…";
        try {
          await Native.call("previewAnimation", { mode: "movie", resourcePath: movie.path, assetKey: movie.assetKey, name: movie.title + (movie.variation ? " · visual " + movie.variation : "") });
        } catch (error) {
          find("#movie-summary").textContent = error.message || "The movie could not be opened.";
        } finally {
          if (button.isConnected) {
            button.disabled = false;
            button.textContent = previous;
          }
        }
      };
    }
    for (const [id, key] of [["movie-search", "search"], ["movie-group", "group"], ["movie-format", "format"], ["movie-available", "available"]]) {
      const element = find("#" + id);
      element.oninput = () => {
        query[key] = element.value;
        offset = 0;
        render();
      };
    }
    find("#movie-previous").onclick = () => {
      offset = Math.max(0, offset - pageSize);
      render();
      find("#movie-summary").scrollIntoView({ block: "nearest" });
    };
    find("#movie-next").onclick = () => {
      offset += pageSize;
      render();
      find("#movie-summary").scrollIntoView({ block: "nearest" });
    };
    find("#movie-reset").onclick = () => {
      query = { search: "", group: "all", format: "all", available: "available" };
      for (const [id, key] of [["movie-search", "search"], ["movie-group", "group"], ["movie-format", "format"], ["movie-available", "available"]]) find("#" + id).value = query[key];
      offset = 0;
      render();
    };
    async function imported() {
      if (loading) return;
      loading = true;
      const button = find("#movie-local-refresh");
      button.disabled = true;
      try {
        const local = [];
        let page = 0;
        for (; page < 200; page++) {
          const rows = await Native.call("assets", { query: ".usm", offset: page * 100, limit: 100 });
          if (!connected()) return;
          local.push(...rows);
          if (rows.length < 100) break;
        }
        items = merge(catalog.items, local);
        render();
        if (page === 200) find("#movie-summary").textContent += " Imported movie scan reached 20,000 files; refine your Library if more are needed.";
      } catch (error) {
        if (connected()) find("#movie-summary").textContent = "The public catalog is ready. Imported movies could not be checked: " + error.message;
      } finally {
        loading = false;
        if (button.isConnected) button.disabled = false;
      }
    }
    find("#movie-local-refresh").onclick = imported;
    render();
    await ForgePreviewStorage.mount(find("#movie-offline"), { connected });
    await imported();
  }
  return { mount, merge, filter, safePath, localPath, groups };
});
