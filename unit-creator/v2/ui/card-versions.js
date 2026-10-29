/* One entry per character: game card lists contain every stage of a card (base, Z-awakened,
   each Dokkan awakening), enemy/story copies and transformation forms. Character pickers use
   this to show only the fully awakened, playable version of each card, and to tell whether that
   card already has an Extreme Z-Awakening (EZA) or Super EZA in the game data. */
(function() {
  "use strict";
  const CACHE_KEY = "forge-card-versions";
  // One awakening index per game database (the Eclipse database and the Sparking catalog).
  const dbs = {};
  const slot = (database) => dbs[database] || (dbs[database] = { loading: null, loadedFor: "", index: { next: new Map(), eza: new Set(), seza: new Set(), sezaGrow: new Set() } });
  let index = slot("eclipse").index;

  const playable = (id) => { id = Number(id); return Math.floor(id / 10) * 10 + 1; };
  function dataStamp(database) {
    const info = typeof state !== "undefined" && state.info || {};
    const stamp=[info.meta && (info.meta.date || info.meta.source), info.count, info.database && info.database.updatedAt];
    if(database === "sparking" && info.sparkingSnapshotId)stamp.push(info.sparkingSnapshotId);
    return database + "|" + JSON.stringify(stamp);
  }
  function build(raw) {
    const next = new Map();
    for (const [from, to] of raw.next) if (playable(from) !== playable(to)) next.set(playable(from), playable(to));
    return { next, eza: new Set(raw.eza), seza: new Set(raw.seza), sezaGrow: new Set(raw.sezaGrow) };
  }
  async function fetchAll(database, table, filters) {
    const out = [], method = database === "sparking" ? "querySparking" : "query";
    for (let offset = 0; offset < 50000; offset += 5000) {
      const rows = await Native.call(method, { table, filters, limit: 5000, offset });
      out.push(...rows);
      if (rows.length < 5000) break;
    }
    return out;
  }
  async function schemaOf(database) {
    if (database !== "sparking") return typeof state !== "undefined" && state.info && state.info.schema || {};
    try { return (await Native.call("sparkingInfo")).schema || {}; } catch { return {}; }
  }
  async function load(database = "eclipse") {
    const db = slot(database), stamp = dataStamp(database);
    if (db.loading && db.loadedFor === stamp) return db.loading;
    db.loadedFor = stamp;
    db.loading = (async () => {
      const key = CACHE_KEY + (database === "eclipse" ? "" : "-" + database);
      try {
        const cached = JSON.parse(localStorage.getItem(key) || "null");
        if (cached && cached.stamp === stamp && cached.v === 1) { db.index = build(cached); if (database === "eclipse") index = db.index; return db.index; }
      } catch {}
      const schema = await schemaOf(database);
      const raw = { v: 1, stamp, next: [], eza: [], seza: [], sezaGrow: [] };
      if (schema.card_awakening_routes) {
        for (const r of await fetchAll(database, "card_awakening_routes", { type: "CardAwakeningRoute::Dokkan" })) raw.next.push([Number(r.card_id), Number(r.awaked_card_id)]);
        const eza = new Set(), seza = new Set();
        const optimal = "CardAwakeningRoute::Optimal";
        for (const r of await fetchAll(database, "card_awakening_routes", { type: optimal, optimal_awakening_step: 1 })) eza.add(Number(r.card_id));
        for (const r of await fetchAll(database, "card_awakening_routes", { type: optimal, optimal_awakening_type: 2 })) { eza.add(Number(r.card_id)); seza.add(Number(r.card_id)); }
        for (const r of await fetchAll(database, "card_awakening_routes", { type: optimal, optimal_awakening_step: 8 })) { eza.add(Number(r.card_id)); seza.add(Number(r.card_id)); }
        raw.eza = [...eza]; raw.seza = [...seza];
      }
      if (schema.optimal_awakening_growths) raw.sezaGrow = [...new Set((await fetchAll(database, "optimal_awakening_growths", { step: 8 })).map((r) => Number(r.optimal_awakening_grow_type)))];
      try { localStorage.setItem(key, JSON.stringify(raw)); } catch {}
      db.index = build(raw);
      if (database === "eclipse") index = db.index;
      return db.index;
    })();
    db.loading.catch(() => { db.loading = null; });
    return db.loading;
  }
  const idx = (database) => database && database !== "eclipse" ? slot(database).index : index;
  function finalId(id, database) {
    const ix = idx(database);
    let current = playable(id);
    for (let i = 0; i < 12 && ix.next.has(current); i++) current = ix.next.get(current);
    return current;
  }
  function isAwakenedFurther(id, database) { return idx(database).next.has(playable(id)); }
  // Cards a player can own. Eclipse: 7-digit 1xxxxxx/2xxxxxx (4xxxxxx are transformation-only
  // forms) and 8-digit custom units; 3/5/7/9xxxxxx are enemies, story NPCs and placeholders.
  // The Sparking catalog also has 6-digit units of its own.
  function isPlayerCard(c, database) {
    const id = Number(c.id);
    if (id % 10 !== 1) return false;
    const sparkingOwn = database === "sparking" && id >= 1e5 && id < 1e6;
    if (!(sparkingOwn || id >= 1e6 && id < 3e6 || id >= 1e7)) return false;
    return Number(c.hp_max) > 300 && c.leader_skill_set_id != null && c.passive_skill_set_id != null;
  }
  function status(c, database) {
    if (!c) return "";
    const ix = idx(database), id = playable(c.id), grow = c.optimal_awakening_grow_type;
    if (ix.seza.has(id) || grow != null && ix.sezaGrow.has(Number(grow))) return "seza";
    if (ix.eza.has(id) || grow != null && grow !== "" && Number(grow) > 0) return "eza";
    return "";
  }
  function badge(c, database) {
    const s = typeof c === "string" ? c : status(c, database);
    return s === "seza" ? '<span class="cv-badge cv-seza" title="Already has a Super Extreme Z-Awakening">SUPER EZA</span>'
      : s === "eza" ? '<span class="cv-badge cv-eza" title="Already has an Extreme Z-Awakening">EZA</span>' : "";
  }
  function label(c, database) {
    const s = status(c, database);
    return s === "seza" ? "Already Super EZA'd" : s === "eza" ? "Already EZA'd" : "Not EZA'd yet";
  }

  /* rows: cards from a name search (any order). Returns one fully awakened, playable card per
     character, keeping the order of first appearance. With { rarity } only cards that are
     already fully awakened at that rarity are kept. { database: "sparking" } uses the Sparking
     catalog. */
  async function collapse(rows, options = {}) {
    const database = options.database || "eclipse";
    try { await load(database); } catch { return rows.filter((c) => Number(c.id) % 10 === 1); }
    const out = [], seen = new Set(), missing = [];
    for (const c of rows) {
      const id = Number(c.id), final = finalId(id, database);
      if (options.rarity != null && options.rarity !== "" && final !== id) continue;
      if (seen.has(final)) continue;
      if (final === id) {
        if (!isPlayerCard(c, database)) continue;
        seen.add(final);
        out.push(c);
      } else {
        seen.add(final);
        out.push(final);
        missing.push(final);
      }
    }
    const found = new Map(), method = database === "sparking" ? "querySparking" : "query";
    for (let i = 0; i < missing.length; i += 900) {
      for (const r of await Native.call(method, { table: "cards", ids: missing.slice(i, i + 900), limit: 1000 })) found.set(Number(r.id), r);
    }
    const unique = new Set(), result = [];
    for (const item of out) {
      const c = typeof item === "number" ? found.get(item) : item;
      if (!c || !isPlayerCard(c, database)) continue;
      const key = [c.name, c.element, c.rarity, c.passive_skill_set_id, c.leader_skill_set_id].join("|");
      if (unique.has(key)) continue;
      unique.add(key);
      result.push(c);
    }
    return result;
  }

  // Warm the index shortly after startup so the first character search is instant.
  (async () => {
    for (let i = 0; i < 300 && window.__forgeWorkspaceStartup !== "ready"; i++) await new Promise((r) => setTimeout(r, 100));
    if (window.__forgeWorkspaceStartup === "ready") setTimeout(() => load().catch(() => {}), 1500);
  })();

  window.ForgeCardVersions = { load, collapse, finalId, isAwakenedFurther, isPlayerCard, status, badge, label };
})();
