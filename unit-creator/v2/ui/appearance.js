/* 🖼 Portraits & Sprites (builder tab, v2.36): change the unit's
   - portrait  — the card art / thumbnail / cut-ins (cards.resource_id + bg_effect_id), picked from every portrait
                 the game has for a character,
   - battle sprite — the fighter that appears in battle (cards.character_id),
   - battle motion — its attack motion style (cards.special_motion).
   Choices are written as card overrides, the same way "Use another character's artwork" always has, so export,
   forms and the other art tools keep working. Custom in-game artwork / custom battle poses are respected. */
window.ForgeAppearance = (() => {
  "use strict";
  const h = (s) => esc(String(s == null ? "" : s));
  const ui = { q: null, part: "portrait", rows: [], chars: new Map(), loading: false, error: "", lastQ: "" };
  const P = () => state.project;
  const card = () => Forge.card(P());
  const call = (o) => Native.call(P() && P().source && P().source.database === "sparking" ? "querySparking" : "query", o);
  const portraitOf = (c) => Number(c.resource_id) || Math.floor(Number(c.id) / 10) * 10;
  const current = () => {
    const p = P(), c = card(), o = p.cardOverrides || {};
    return { portrait: Number(o.resource_id != null ? o.resource_id : portraitOf(c)), character: Number(o.character_id != null ? o.character_id : c.character_id), motion: Number(o.special_motion != null ? o.special_motion : c.special_motion) || 0 };
  };
  const MOTIONS = { 0: "Standard", 1: "Style 1", 2: "Style 2", 3: "Style 3", 4: "Style 4", 5: "Style 5" };

  async function load(q) {
    ui.loading = true; ui.error = ""; ui.lastQ = q;
    try {
      const CV = window.ForgeCardVersions, raw = [];
      for (let off = 0; off < 2400; off += 600) {
        const page = await call({ table: "cards", search: { column: "name", text: q }, limit: 600, offset: off });
        raw.push(...page); if (page.length < 600) break;
      }
      const db = P().source && P().source.database === "sparking" ? "sparking" : "";
      ui.rows = raw.filter((c) => (CV && CV.isPlayerCard ? CV.isPlayerCard(c, db) : Number(c.id) % 10 === 1)).sort((a, b) => Number(b.rarity) - Number(a.rarity) || Number(b.id) - Number(a.id));
      const ids = [...new Set(ui.rows.map((c) => Number(c.character_id)).filter(Boolean))].filter((id) => !ui.chars.has(id));
      for (let i = 0; i < ids.length; i += 300) for (const r of await call({ table: "characters", ids: ids.slice(i, i + 300), limit: 300 }).catch(() => [])) ui.chars.set(Number(r.id), r.name);
    } catch (e) { ui.error = e.message || String(e); ui.rows = []; }
    ui.loading = false;
    if (state.view === "editor") renderEditor();
  }
  const dedupe = (key) => { const seen = new Map(); for (const c of ui.rows) { const k = key(c); if (!seen.has(k)) seen.set(k, { key: k, cards: [] }); seen.get(k).cards.push(c); } return [...seen.values()]; };
  const charName = (id, c) => { const n = ui.chars.get(Number(id)); return n && !/[぀-ヿ一-鿿]/.test(n) ? n : (c && c.name) || "Fighter " + id; };

  // the template's own portrait / sprite / motion always comes first, marked "Original" (added when the search missed it)
  const originalFirst = (list, key, card) => {
    const i = list.findIndex((g) => g.key === key);
    const g = i >= 0 ? list.splice(i, 1)[0] : { key, cards: [card] };
    g.cards = [Object.assign({}, g.cards[0], { name: (P().source && P().source.name) || card.name })].concat(g.cards.slice(1));
    g.original = true; list.unshift(g); return list;
  };
  const PAGE = 48;
  const page = (list) => list.slice(0, ui.shown || PAGE);
  const more = (list) => list.length > (ui.shown || PAGE) ? '<p class="ap-foot"><button type="button" class="button ghost" data-ap-more>Show ' + Math.min(PAGE, list.length - (ui.shown || PAGE)) + " more (" + (list.length - (ui.shown || PAGE)) + " left)</button></p>" : "";
  function html() {
    const p = P(); if (!p) return "";
    if (ui.key !== p.key) { ui.key = p.key; ui.q = null; ui.rows = []; ui.lastQ = ""; ui.part = "portrait"; ui.shown = 0; }
    const c = card(), cur = current();
    if (ui.q === null) ui.q = String((p.uiLabels && p.uiLabels.appearanceSearch) || p.source.name || c.name || "").replace(/\s*\(.*$/, "").split(" ").slice(-1)[0] || "";
    if (!ui.loading && ui.lastQ !== ui.q && ui.q.trim().length >= 2) setTimeout(() => load(ui.q.trim()), 0);
    const locked = p.artBinding ? '<p class="notice warning">This unit uses custom in-game artwork (Artwork &amp; Aura). Picking a portrait here replaces it with the game portrait you choose.</p>' : "";
    const poseLock = p.battlePoseBinding ? '<p class="notice warning">This unit uses custom battle poses. Restore the original poses in Artwork &amp; Aura › Customize battle poses before choosing another battle sprite.</p>' : "";
    const spriteNow = (p.uiLabels && p.uiLabels.sprite) || (cur.character === Number(c.character_id) ? "Original" : charName(cur.character));
    const tabs = [["portrait", "1", "Portrait", (p.uiLabels && p.uiLabels.art) || "Original", '<img src="' + h(resourceThumb(cur.portrait)) + '" alt="">'],
      ["sprite", "2", "Battle sprite", spriteNow, ""], ["motion", "3", "Battle motion", MOTIONS[cur.motion] || "Style " + cur.motion, ""]]
      .map(([k, n, l, v, img]) => '<button type="button" class="ap-step' + (ui.part === k ? " on" : "") + '" data-ap-part="' + k + '">' + img + '<span class="ap-step-n">' + n + "</span><strong>" + l + "</strong><small>" + h(v) + "</small></button>").join("");
    let grid = "";
    if (ui.loading) grid = '<p class="hint">Finding every ' + h(ui.q) + " portrait, sprite and motion…</p>";
    else if (ui.error) grid = '<p class="notice error">' + h(ui.error) + "</p>";
    else if (!ui.rows.length) grid = '<p class="hint">No characters match “' + h(ui.q) + '”. Try a shorter name, e.g. Goku, Vegeta, Broly.</p>';
    else if (ui.part === "portrait") {
      const list = originalFirst(dedupe(portraitOf), portraitOf(c), c);
      grid = '<p class="hint">' + list.length + " portraits. Tap one to use it.</p>" + '<div class="ap-grid">' +
        page(list).map((g) => { const c0 = g.cards[0]; return '<button type="button" class="ap-tile t' + (Number(c0.element) % 10) + (g.key === cur.portrait ? " on" : "") + '" data-ap-portrait="' + g.key + '" data-ap-card="' + c0.id + '"><img src="' + h(resourceThumb(g.key)) + '" alt="" loading="lazy"><span>' + h((g.original ? "Original · " : "") + c0.name) + "</span><small>" + h(Forge.rarities[c0.rarity] || "") + (g.cards.length > 1 ? " · " + g.cards.length + " cards" : "") + "</small></button>"; }).join("") + "</div>" + more(list);
    } else if (ui.part === "sprite") {
      const list = originalFirst(dedupe((x) => Number(x.character_id)).filter((g) => g.key), Number(c.character_id), c);
      grid = '<p class="hint">' + list.length + ' fighters. Tap one to use it. ▶ = watch it.</p><div class="ap-grid">' +
        page(list).map((g) => { const c0 = g.cards[0]; return '<div class="ap-tile t' + (Number(c0.element) % 10) + (g.key === cur.character ? " on" : "") + '"><button type="button" class="ap-pick" data-ap-sprite="' + g.key + '" data-ap-card="' + c0.id + '"' + (p.battlePoseBinding ? " disabled" : "") + '><img src="' + h(thumb(c0)) + '" alt="" loading="lazy"><span>' + h(g.original ? "Original · " + c0.name : charName(g.key, c0)) + "</span><small>Used by " + g.cards.length + " card" + (g.cards.length === 1 ? "" : "s") + '</small></button><button type="button" class="ap-play" data-ap-preview="' + c0.id + '" aria-label="Preview poses">▶</button></div>'; }).join("") + "</div>" + more(list);
    } else {
      const list = originalFirst(dedupe((x) => Number(x.special_motion) || 0).sort((a, b) => a.key - b.key), Number(c.special_motion) || 0, c);
      grid = '<p class="hint">Tap a style to use it. ▶ = watch it.</p><div class="ap-motions">' +
        list.map((g) => '<button type="button" class="ap-motion' + (g.key === cur.motion ? " on" : "") + '" data-ap-motion="' + g.key + '"><strong>' + h(MOTIONS[g.key] || "Style " + g.key) + (g.original ? " (original)" : "") + "</strong><small>" + h(g.cards.slice(0, 3).map((x) => x.name).join(", ")) + (g.cards.length > 3 ? " +" + (g.cards.length - 3) : "") + '</small><span class="ap-motion-play" data-ap-preview="' + g.cards[0].id + '" role="button" aria-label="Preview">▶</span></button>').join("") + "</div>";
    }
    return '<section class="panel ap"><h2>Portraits &amp; Sprites</h2><div class="ap-steps">' + tabs + "</div>" + locked + (ui.part === "sprite" ? poseLock : "") +
      '<label class="field ap-search">Search a character<input type="search" data-ap-q value="' + h(ui.q) + '" placeholder="e.g. Goku, Vegeta, Broly" enterkeyhint="search"></label>' + grid +
      '<p class="ap-foot"><button type="button" class="button subtle small" data-ap-reset>Undo all — back to the original look</button></p></section>';
  }

  function done(msg) { scheduleSave(); state.previewUrl = ""; if (state.view === "editor") renderEditor(); if (msg) toast(msg); }
  function findCard(id) { return ui.rows.find((c) => Number(c.id) === Number(id)); }
  document.addEventListener("click", (e) => {
    const t = e.target.closest && e.target.closest("[data-ap-part],[data-ap-portrait],[data-ap-sprite],[data-ap-motion],[data-ap-preview],[data-ap-reset],[data-ap-more]");
    if (!t || !P()) return;
    const p = P(); p.uiLabels = p.uiLabels || {};
    if (t.dataset.apPreview) {
      e.preventDefault(); e.stopPropagation();
      return Native.call("animationVisuals", { unitId: Number(t.dataset.apPreview) }).then((r) => {
        const v = (r.items || []).find((x) => / · (Battle|Idle) poses$/.test(x.name)) || (r.items || [])[0];
        if (!v) return toast("No pose preview for this fighter.", true);
        return Native.call("previewAnimation", { mode: "pack", resourcePath: v.path, scene: v.scene, name: v.name });
      }).catch((err) => toast(/web|phone app|unsupported/i.test(err.message || "") ? "Pose previews play in the phone app." : err.message, true));
    }
    if (t.dataset.apPart) { ui.part = t.dataset.apPart; ui.shown = 0; return renderEditor(); }
    if (t.hasAttribute("data-ap-more")) { ui.shown = (ui.shown || PAGE) + PAGE; const y = window.scrollY; renderEditor(); window.scrollTo(0, y); return; }
    if (t.hasAttribute("data-ap-reset")) {
      if (p.artBinding) ForgeArt.restore(p);
      for (const k of ["resource_id", "bg_effect_id", "special_motion"]) delete p.cardOverrides[k];
      if (!p.battlePoseBinding) delete p.cardOverrides.character_id;
      delete p.uiLabels.art; delete p.uiLabels.artCardId; delete p.uiLabels.sprite; delete p.previewKey;
      return done("Back to the original portrait, sprite and motion.");
    }
    const c = findCard(t.dataset.apCard);
    if (t.dataset.apPortrait) {
      if (p.artBinding) ForgeArt.restore(p);
      p.cardOverrides.resource_id = Number(t.dataset.apPortrait);
      if (c) p.cardOverrides.bg_effect_id = c.bg_effect_id != null ? c.bg_effect_id : null;
      p.uiLabels.art = c ? c.name : "Portrait " + t.dataset.apPortrait; p.uiLabels.artCardId = c ? c.id : null;
      delete p.previewKey;
      return done("Portrait changed to " + p.uiLabels.art + ".");
    }
    if (t.dataset.apSprite) {
      if (p.battlePoseBinding) return toast("Restore the original battle poses first (Artwork & Aura › Customize battle poses).", true);
      p.cardOverrides.character_id = Number(t.dataset.apSprite);
      p.uiLabels.sprite = charName(t.dataset.apSprite, c);
      return done("Battle sprite changed to " + p.uiLabels.sprite + ".");
    }
    if (t.dataset.apMotion !== undefined) {
      p.cardOverrides.special_motion = Number(t.dataset.apMotion);
      return done("Battle motion set to " + (MOTIONS[t.dataset.apMotion] || "style " + t.dataset.apMotion) + ".");
    }
  }, true);
  let timer = null;
  document.addEventListener("input", (e) => {
    if (!e.target.matches || !e.target.matches("[data-ap-q]")) return;
    ui.q = e.target.value; ui.shown = 0; clearTimeout(timer);
    if (P()) { P().uiLabels = P().uiLabels || {}; P().uiLabels.appearanceSearch = ui.q; }
    timer = setTimeout(() => { if (ui.q.trim().length >= 2) { ui.loading = true; load(ui.q.trim()).then(() => { const f = document.querySelector("[data-ap-q]"); if (f) { f.focus(); f.setSelectionRange(f.value.length, f.value.length); } }); } }, 450);
  });
  return { html };
})();
