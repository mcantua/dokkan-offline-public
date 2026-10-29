/* Import a unit from a .sql file (v2.36). Reads the INSERT statements of a Dokkan SQL patch — the .SQL this app
   exports, or one from Dokkan Eclipse / Sparking creators — and rebuilds an editable unit from its rows.
   Nothing in the file is run: statements are only read as data. Only tables and columns the game database knows
   are kept; everything else is listed back to the user. */
(function () {
  "use strict";
  const MAX = 64 * 1024 * 1024;

  // ---- reading the SQL text (INSERT [OR REPLACE|IGNORE] INTO table [(cols)] VALUES (...),(...);) ----
  function parse(text) {
    const out = [], skipped = {};
    let i = 0;
    const n = text.length;
    const ws = () => { for (;;) { while (i < n && /\s/.test(text[i])) i++; if (text.startsWith("--", i)) { while (i < n && text[i] !== "\n") i++; continue; } if (text.startsWith("/*", i)) { const e = text.indexOf("*/", i + 2); i = e < 0 ? n : e + 2; continue; } break; } };
    const word = () => { ws(); const m = /^[A-Za-z_]+/.exec(text.slice(i, i + 32)); if (!m) return ""; i += m[0].length; return m[0].toUpperCase(); };
    const ident = () => {
      ws();
      const q = text[i];
      if (q === '"' || q === "`" || q === "[") {
        const close = q === "[" ? "]" : q; let s = ""; i++;
        while (i < n) { if (text[i] === close) { if (text[i + 1] === close && close !== "]") { s += close; i += 2; continue; } i++; break; } s += text[i++]; }
        return s;
      }
      const m = /^[A-Za-z_][A-Za-z0-9_.]*/.exec(text.slice(i, i + 200)); if (!m) throw new Error("Unreadable table or column name near character " + i + ".");
      i += m[0].length; return m[0].split(".").pop();
    };
    const value = () => {
      ws();
      const c = text[i];
      if (c === "'") {
        let s = ""; i++;
        while (i < n) { if (text[i] === "'") { if (text[i + 1] === "'") { s += "'"; i += 2; continue; } i++; break; } s += text[i++]; }
        return s;
      }
      if ((c === "X" || c === "x") && text[i + 1] === "'") { const e = text.indexOf("'", i + 2); const hex = text.slice(i + 2, e); i = e + 1; return hex; }
      const m = /^(-?\d+(\.\d+)?([eE][-+]?\d+)?|NULL|TRUE|FALSE|CURRENT_TIMESTAMP)/i.exec(text.slice(i, i + 64));
      if (!m) throw new Error("Unreadable value near character " + i + ".");
      i += m[0].length;
      const v = m[0].toUpperCase();
      if (v === "NULL") return null; if (v === "TRUE") return 1; if (v === "FALSE") return 0;
      if (v === "CURRENT_TIMESTAMP") return new Date().toISOString().slice(0, 19).replace("T", " ");
      return Number(m[0]);
    };
    const skipStatement = () => { // to the next ; that is not inside a 'string'
      let q = false;
      while (i < n) { const c = text[i]; if (q) { if (c === "'") { if (text[i + 1] === "'") { i += 2; continue; } q = false; } } else if (c === "'") q = true; else if (c === ";") { i++; return; } i++; }
    };
    while (i < n) {
      ws(); if (i >= n) break;
      const start = i, w = word();
      if (w !== "INSERT" && w !== "REPLACE") { if (w) skipped[w] = (skipped[w] || 0) + 1; else i++; i = Math.max(i, start + 1); skipStatement(); continue; }
      let k = word();
      if (k === "OR") { word(); k = word(); }
      if (k !== "INTO") { skipStatement(); continue; }
      const table = ident(); let cols = null;
      ws();
      if (text[i] === "(") { i++; cols = []; for (;;) { cols.push(ident()); ws(); if (text[i] === ",") { i++; continue; } if (text[i] === ")") { i++; break; } throw new Error("Unreadable column list for " + table + "."); } }
      if (word() !== "VALUES") { skipStatement(); skipped.SELECT = (skipped.SELECT || 0) + 1; continue; }
      for (;;) {
        ws(); if (text[i] !== "(") throw new Error("Unreadable row in " + table + ".");
        i++; const vals = [];
        for (;;) { vals.push(value()); ws(); if (text[i] === ",") { i++; continue; } if (text[i] === ")") { i++; break; } throw new Error("Unreadable row in " + table + "."); }
        out.push({ table, cols, vals });
        ws(); if (text[i] === ",") { i++; continue; }
        if (text[i] === ";") i++;
        break;
      }
    }
    return { rows: out, skipped };
  }

  // ---- rows -> an editable unit ----
  async function toProject(text, { schema, query, fileName }) {
    if (typeof text !== "string" || !text.trim()) throw new Error("This .sql file is empty.");
    if (text.length > MAX) throw new Error("This .sql file is too large (over 64 MB).");
    const { rows, skipped } = parse(text);
    if (!rows.length) throw new Error("This .sql file has no INSERT rows, so there is no unit in it.");
    const tables = {}, usedSchema = {}, unknownTables = new Set(), droppedCols = new Set();
    for (const r of rows) {
      const cols = schema[r.table];
      if (!cols) { unknownTables.add(r.table); continue; }
      const names = cols.map((c) => c.name), list = r.cols || names;
      if (list.length !== r.vals.length) throw new Error("A row in " + r.table + " has " + r.vals.length + " values for " + list.length + " columns.");
      const row = {};
      list.forEach((c, k) => { if (names.includes(c)) row[c] = r.vals[k]; else droppedCols.add(r.table + "." + c); });
      if (row.id === undefined && names.includes("id")) continue;
      const t = (tables[r.table] = tables[r.table] || []);
      const at = row.id !== undefined ? t.findIndex((x) => x.id === row.id) : -1;
      if (at >= 0) t[at] = row; else t.push(row);   // later rows replace earlier ones, like INSERT OR REPLACE
      usedSchema[r.table] = JSON.parse(JSON.stringify(cols));
    }
    const cards = tables.cards || [];
    if (!cards.length) throw new Error("This .sql file has no card (no rows for the cards table), so there is no unit to edit.");
    // the playable card: id ending in 1 with a leader and passive skill, else the first card
    const main = cards.find((c) => Number(c.id) % 10 === 1 && c.leader_skill_set_id && c.passive_skill_set_id) || cards.find((c) => Number(c.id) % 10 === 1) || cards[0];
    const targetId = Number(main.id), rootId = Math.floor(targetId / 10) * 10;
    // An exported unit also carries a copy of its card at the rounded "root" id (the game looks it up); the
    // builder makes that copy again on export, so it and its card settings are not kept twice.
    let dropped = 0;
    if (rootId !== targetId) for (const t of Object.keys(tables)) {
      const before = tables[t].length;
      tables[t] = t === "cards" ? tables[t].filter((r) => Number(r.id) !== rootId) : tables[t].filter((r) => !("card_id" in r) || Number(r.card_id) !== rootId);
      dropped += before - tables[t].length;
    }
    const otherCards = tables.cards.filter((c) => c !== main);
    for (const t of ["leader_skill_sets", "leader_skills", "passive_skill_sets", "passive_skill_set_relations", "passive_skills"]) {
      tables[t] = tables[t] || []; if (!usedSchema[t] && schema[t]) usedSchema[t] = JSON.parse(JSON.stringify(schema[t]));
    }
    // The builder keeps the unit's card under the game card it is based on (same picture/animation resource) and
    // writes it to your custom ID on export; the rest of the rows keep their ids and links.
    const resourceId = Number(main.resource_id) || rootId;
    let sourceId = resourceId + 1, sourceName = main.name;
    try {
      const hit = query && sourceId !== targetId ? await query({ table: "cards", ids: [sourceId], limit: 1 }) : [];
      if (hit && hit[0]) sourceName = hit[0].name; else sourceId = 0;
    } catch (e) { sourceId = 0; }
    if (!sourceId || sourceId === targetId) sourceId = targetId + 2;   // no game card behind it: any other id works
    tables.cards = [Object.assign({}, main, { id: sourceId })];
    const stamp = new Date().toISOString(), uid = () => (crypto && crypto.randomUUID ? crypto.randomUUID() : "u" + Date.now().toString(16) + Math.random().toString(16).slice(2));
    const project = {
      format: "dokkan-unit-forge", version: 1,
      key: "unit-" + main.id + "-" + Date.now(),
      createdAt: stamp, updatedAt: stamp,
      source: { cardId: sourceId, name: sourceName, resourceId },
      targetId,
      patch: { name: String(main.name || "Imported unit") + " — Custom Unit", author: "", version: "1.0.0", description: "", uuid: uid() },
      tables, schema: usedSchema, abilityAnimationSources: {}, assets: [], notes: "",
      cardOverrides: { name: main.name, resource_id: resourceId },
      libraryOrigin: "uploaded",
      provenance: { file: fileName || "unit.sql", importedAt: stamp, format: "sql" },
    };
    const notes = [];
    const count = Object.values(tables).reduce((a, t) => a + t.length, 0);
    notes.push(count + " game rows read from " + Object.keys(tables).filter((t) => tables[t].length).length + " tables.");
    if (otherCards.length) notes.push(otherCards.length + " other card(s) in the file (transformations or other units) were not rebuilt — add transformations again on the Passive Skill step.");
    if (unknownTables.size) notes.push("Left out, not in the game database: " + [...unknownTables].slice(0, 6).join(", ") + (unknownTables.size > 6 ? "…" : "") + ".");
    if (droppedCols.size) notes.push("Unknown columns left out: " + [...droppedCols].slice(0, 6).join(", ") + (droppedCols.size > 6 ? "…" : "") + ".");
    const other = Object.entries(skipped).map(([k, v]) => v + " " + k).join(", ");
    if (other) notes.push("Not imported (only INSERT rows are read): " + other + " statement(s).");
    return { project, notes };
  }

  window.ForgeSqlImport = { parse, toProject };
})();
