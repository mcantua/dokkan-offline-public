"use strict";
// ⬆ Update & import — kept to two things:
//   1. Game data: checks Eclipse by itself when opened; one button updates it; any problem is
//      explained right there (with "Try again" and other ways to update).
//   2. Import a unit file.
// Everything else is folded under "More options".
window.ForgeImport = (() => {
  const h = (s) => esc(String(s == null ? "" : s));
  const KEY = "forge-data-date";
  const stored = () => { try { return localStorage.getItem(KEY) || ""; } catch (e) { return ""; } };
  const remember = (d) => { try { if (d) localStorage.setItem(KEY, d); } catch (e) {} };
  function dataDate() {
    const m = state.info && state.info.meta || {};
    const own = m.date || ((String(m.source || "").match(/\d{4}-\d{2}-\d{2}/) || [])[0]) || "";
    const saved = stored();
    return saved && (!own || saved > own) ? saved : own;
  }
  const pretty = (iso) => { if (!iso) return ""; try { return new Date(iso + "T12:00:00").toLocaleDateString(undefined, { day: "numeric", month: "long", year: "numeric" }); } catch (e) { return iso; } };
  let sheet = null, online = "", host = null;
  function open(opts = {}) {
    if (!sheet) { sheet = document.createElement("dialog"); sheet.id = "import-hub"; sheet.className = "shell-sheet"; sheet.setAttribute("aria-labelledby", "import-hub-title"); document.body.append(sheet); }
    sheet.innerHTML = '<div class="sheet-head"><h2 id="import-hub-title">Update & import</h2><button type="button" class="icon-button" data-sheet-close aria-label="Close">×</button></div>' +
      '<section class="imp-card"><h3>🎮 Game data</h3><p class="imp-now">Your characters are from <strong>' + h(pretty(dataDate()) || "the version built into the app") + '</strong>.</p><div id="imp-status" data-imp-status class="imp-status" role="status">Checking Dokkan Eclipse for new characters…</div><div id="imp-actions" data-imp-actions></div></section>' +
      '<section class="imp-card"><h3>📥 Import a unit</h3><p>A unit file from this app (.json), from Dokkan Eclipse (.eclp) or from Dokkan Sparking (.sprk).</p><button type="button" class="button imp-big" data-imp="file">Choose a file</button><button type="button" class="button ghost imp-sql" data-imp="sql">📄 Import a .sql file</button><p class="hint">A .sql file (game data only) becomes an editable unit. Its pictures and animations come from the game card it is based on.</p></section>' +
      '<details class="imp-more"><summary>More options</summary><div class="imp-list">' +
      '<button type="button" class="button ghost" data-imp="resources">🗂 Import a game resource pack (.zip)</button>' +
      '<button type="button" class="button ghost" data-imp="apk">📦 Update from a Dokkan Eclipse app file (.apk)</button>' +
      '<button type="button" class="button ghost" data-imp="eclipse">🌐 Open the Dokkan Eclipse website</button></div></details>';
    sheet.querySelector("[data-sheet-close]").onclick = () => sheet.close();
    sheet.querySelectorAll("[data-imp]").forEach((b) => b.onclick = () => run(b.dataset.imp).catch((e) => toast(e.message || String(e), true)));
    if (!sheet.open) sheet.showModal();
    host = sheet;
    if (opts.noCheck) return;
    if (opts.update) return run("update");
    check();
  }
  // The same "Game data" box inside Settings (or anywhere): date, automatic check, one button.
  function card(el, onLeave) {
    el.innerHTML = '<p class="imp-now">Your characters are from <strong>' + h(pretty(dataDate()) || "the version built into the app") + '</strong>.</p><div data-imp-status class="imp-status" role="status">Checking Dokkan Eclipse for new characters…</div><div data-imp-actions class="imp-actions"></div>';
    host = el; leave = onLeave || null;
    return check();
  }
  let leave = null;
  function status(html, actions = "") {
    const root = host && host.isConnected ? host : sheet;
    const s = root && root.querySelector("[data-imp-status]"), a = root && root.querySelector("[data-imp-actions]");
    if (s) s.innerHTML = html;
    if (a) { a.innerHTML = actions; a.querySelectorAll("[data-imp]").forEach((b) => b.onclick = () => run(b.dataset.imp).catch((e) => toast(e.message || String(e), true))); }
  }
  async function check() {
    let r;
    try { r = await Native.call("checkUpdates"); } catch (e) { r = { ok: false, error: e.message }; }
    if (!r || !r.ok) {
      status('<span class="imp-warn">Couldn\'t reach Dokkan Eclipse right now.</span> ' + h((r && r.error) || "Check your internet connection."), '<button type="button" class="button ghost" data-imp="check">Check again</button>');
      return r;
    }
    online = r.lastModified ? new Date(Number(r.lastModified)).toISOString().slice(0, 10) : "";
    const mine = dataDate();
    if (online && mine && online <= mine) status('<span class="imp-ok">✓ You have the newest characters.</span>', '<button type="button" class="button ghost small" data-imp="update">Download again anyway</button>');
    else status('<span class="imp-new">New characters are available' + (online ? " (" + h(pretty(online)) + ")" : "") + ".</span>", '<button type="button" class="button imp-big" data-imp="update">⬇ Update now · about ' + Math.max(1, Math.round((Number(r.size) || 100 * 1048576) / 1048576)) + " MB</button>");
    return r;
  }
  // quiet check used on app start and before downloads: { newer, online, size } (never throws)
  async function newer() {
    let r;
    try { r = await Native.call("checkUpdates"); } catch (e) { return { newer: false }; }
    if (!r || !r.ok || r.web) return { newer: false };
    online = r.lastModified ? new Date(Number(r.lastModified)).toISOString().slice(0, 10) : "";
    const mine = dataDate();
    return { newer: Boolean(online && (!mine || online > mine)), online, label: pretty(online), size: Number(r.size) || 0 };
  }
  async function update(opts = {}) {
    let failure = null;
    const result = await databaseTask("Updating the game data", async () => {
      try { return await Native.call("sync"); } catch (e) { failure = e; throw e; }
    });
    if (result) {
      state.info = result;
      remember(online || new Date().toISOString().slice(0, 10));
      try { localStorage.removeItem("forge-finder-index"); } catch (e) {}
      window.ForgeFinder?.reset?.();
      await loadLookups();
      const back = leave; leave = null;
      if (back) back(); else if (!opts.quiet) open();
      toast("Updated! The newest characters are ready. Your units were kept.");
      return true;
    }
    leave = null;
    if (opts.quiet) { toast("The game data update didn't finish. Your current characters were kept.", true); return false; }
    open({ noCheck: true });
    const why = String((failure && failure.message) || "The download didn't finish.");
    status('<span class="imp-warn">The update didn\'t work.</span> ' + h(why) + "<br><small>Your current characters were kept.</small>",
      '<button type="button" class="button" data-imp="update">Try again</button><button type="button" class="button ghost" data-imp="apk">Update from an Eclipse app file instead</button><button type="button" class="button ghost small" data-imp="copyerr" data-err="' + h(why) + '">Copy the error</button>');
    const c = sheet.querySelector('#imp-actions [data-imp="copyerr"]');
    if (c) c.onclick = () => Native.call("copy", { text: "Update error: " + why }).then(() => toast("Error copied — paste it to me so I can fix it.")).catch(() => {});
  }
  async function run(what) {
    if (what === "check") { status("Checking…"); return check(); }
    if (what === "update") { if (sheet && sheet.open) sheet.close(); if (leave && host && host.isConnected) { const d = host.closest("dialog"); if (d && d.open) d.close(); } return update(); }
    if (sheet && sheet.open) sheet.close();
    const d = host && host.isConnected && host.closest("dialog"); if (d && d.open) d.close();
    if (what === "sql") { if (host && host.close) host.close(); return window.importSqlFile(); }
    if (what === "file" || what === "resources") return importFile();
    if (what === "apk") return importFile("importApk");
    if (what === "offline") return ForgeOffline.open();
    if (what === "eclipse") return Native.call("openEclipse").catch(() => Native.call("external", { url: "https://dokkan-eclipse.com" }));
  }
  return { open, card, check, update, newer };
})();
