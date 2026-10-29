/* Last line of defence before any patch file is written: every database row in the export must
   use a new ID. If a row would replace an existing card or record in the active game database,
   the export is stopped. The only exception is an EZA / Super EZA project, which is allowed to
   update the one official card it awakens (and nothing else). */
(function() {
  "use strict";
  if (!window.Native || typeof Native.call !== "function") return;
  const original = Native.call;
  const INSERT = /INSERT (?:OR REPLACE )?INTO "(\w+)" \("id"[^)]*\) VALUES \((-?\d+)/g;
  function sqlTexts(method, args) {
    if (!args || typeof args !== "object") return [];
    const out = [];
    if (typeof args.text === "string" && (args.kind === "sql" || /\.sql$/i.test(args.name || ""))) out.push(args.text);
    for (const e of Array.isArray(args.entries) ? args.entries : []) if (e && typeof e.text === "string" && /\.sql$/i.test(e.path || "")) out.push(e.text);
    if (method === "convert" && args.patch && Array.isArray(args.patch.entries)) for (const e of args.patch.entries) if (e && typeof e.text === "string" && /\.sql$/i.test(e.path || "")) out.push(e.text);
    return out;
  }
  async function check(method, args) {
    const texts = sqlTexts(method, args);
    if (!texts.length) return;
    const byTable = new Map();
    for (const text of texts) for (const m of text.matchAll(INSERT)) {
      if (!byTable.has(m[1])) byTable.set(m[1], new Set());
      byTable.get(m[1]).add(Number(m[2]));
    }
    const app = typeof state !== "undefined" ? state : null;
    const p = app && app.project, allowed = new Set(p && p.awaken ? [Number(p.awaken.cardId)] : []);
    const schema = app && app.info && app.info.schema || {};
    if (!Object.keys(schema).length) throw new Error("Game data is still loading. Try exporting again in a moment.");
    const hits = [];
    for (const [table, idSet] of byTable) {
      if (!schema[table]) continue;
      const ids = [...idSet].filter((id) => !(table === "cards" && allowed.has(id)));
      for (let i = 0; i < ids.length && hits.length < 5; i += 900) {
        const rows = await original.call(Native, "query", { table, ids: ids.slice(i, i + 900), limit: 5 });
        for (const r of rows) hits.push(table + " #" + r.id + (r.name ? " (" + r.name + ")" : ""));
      }
    }
    if (hits.length) throw new Error("Export stopped to protect the game: it would replace existing game data (" + hits.slice(0, 3).join(", ") + "). Nothing was saved. Export again and the app will move your unit to a free slot.");
  }
  Native.call = async function(method, args) {
    if (method === "export" || method === "convert") await check(method, args);
    const result = await original.apply(this, arguments);
    try {
      if (method === "export" && result && result.saved === true && args && args.kind !== "json" && typeof state !== "undefined" && state.project && sqlTexts(method, args).length) {
        state.project.lastExportAt = new Date().toISOString();
        if (typeof scheduleSave === "function") scheduleSave();
      }
    } catch {}
    return result;
  };
  window.ForgeIdGuard = { check };
})();
