"use strict";
// Copy from a unit: pick any character in the game (or one of your own units), tick what you want
// (stats, Leader Skill, Passive Skill, Super Attacks, Active Skill, transformations, links,
// categories, artwork, aura, animations…), see exactly what will change, then apply it in one step.
// Everything is prepared on a copy of your unit first, so nothing changes until you tap Apply, and
// ↶ Undo takes the whole copy back. Abilities keep their activation conditions and targets.
window.ForgeUnitCopy = (() => {
  const G = () => window.ForgeGuide, B = () => window.ForgeBuilder;
  const FEATURES = [
    ["stats", "HP, ATK & DEF", "Base stats (starting and maximum)."],
    ["identity", "Rarity, Type & Class", "For example LR, Super, STR."],
    ["leader", "Leader Skill", "Replaces your Leader Skill."],
    ["passive", "Passive Skill", "Add it to yours or replace yours. Transformations, counters and additional attacks inside it come along."],
    ["transform", "Transformation only", "Just the “transforms into …” part of their passive, added to yours."],
    ["supers", "Super Attacks & Ultra Super Attacks", "With their damage, effects, conditions and animations."],
    ["active", "Active Skill", "With its conditions, effects and animation."],
    ["standby", "Standby & Finish Skills", "Charge-up moves and finishers, if they have any."],
    ["links", "Link Skills", "All 7 links."],
    ["categories", "Categories", "Replaces your categories."],
    ["art", "Card artwork", "Their in-game picture."],
    ["aura", "Aura", "Aura colour, size and position."],
    ["animations", "Animations only", "Their Super Attack, Active Skill and normal attack animations on YOUR moves. Your moves' damage and effects stay yours."]
  ];
  const STYLE_ORDER = { Normal: 0, Hyper: 1, Condition: 2, Extra: 3, FullPower: 4 };
  const STYLE_NAME = { Normal: "Super Attack", Hyper: "Ultra Super Attack", Condition: "Conditional Super Attack", Extra: "EX Super Attack", FullPower: "Full-power attack" };
  const STATS = ["hp_init", "hp_max", "atk_init", "atk_max", "def_init", "def_max"];
  const AURA = ["aura_id", "aura_scale", "aura_offset_x", "aura_offset_y", "is_aura_front"];
  const ACTIVE_TABLES = ["ultimate_specials", "active_skill_sets", "active_skills", "card_active_skills", "dokkan_field_active_skill_set_relations"];
  const STANDBY_TABLES = ["finish_specials", "standby_skill_sets", "standby_skills", "card_standby_skill_set_relations", "finish_skill_sets", "finish_skills", "card_finish_skill_set_relations", "standby_skill_set_finish_skill_set_relations"];
  const CONDITION_TABLES = ["skill_causalities", "sub_target_type_sets", "sub_target_types"];
  const html = (s) => esc(String(s == null ? "" : s));
  const fmt = (n) => (typeof number === "function" ? number(n) : String(n));

  // ------------------------------------------------------------------ donors
  const dbOf = (p) => (p && p.source && p.source.database === "sparking" ? "sparking" : "eclipse");
  async function schemaOf(db) { return db === "sparking" ? (await Native.call("sparkingInfo")).schema : state.info.schema; }
  async function gameDonor(card) {
    const p = state.project, db = dbOf(p), schema = await schemaOf(db), query = (o) => Native.call(db === "sparking" ? "querySparking" : "query", o);
    const donor = await Forge.loadTemplate(query, schema, card.id, p.targetId);
    donor.schema = donor.schema || schema;
    // Ultimate Super Attacks behind Active Skills are read separately, like the passive/leader copy does.
    for (const r of donor.tables.active_skill_sets || []) if (r.ultimate_special_id) {
      G().ensure(donor, schema, "ultimate_specials");
      const rows = await query({ table: "ultimate_specials", ids: [r.ultimate_special_id], limit: 1 });
      if (rows.length && !donor.tables.ultimate_specials.some((x) => x.id === rows[0].id)) donor.tables.ultimate_specials.push(rows[0]);
    }
    return { project: donor, name: card.name, kind: "game", cardId: Number(card.id) };
  }
  async function myDonor(key) {
    const donor = await Native.call("loadProject", { key });
    if (!donor || donor.format !== "dokkan-unit-forge" || !donor.tables || !donor.cardOverrides) throw Error("That saved unit could not be read.");
    donor.schema = donor.schema || state.info.schema;
    const reverted = await revertCustomAnimations(donor);
    return { project: donor, name: Forge.card(donor).name || "Your unit", kind: "mine", cardId: Number(donor.source && donor.source.cardId), reverted };
  }
  // Custom animations you made live inside that unit (its own scripts and private ids), so they
  // can't travel. On the copy we read from, every move with a custom animation goes back to the
  // game's original animation (or, for a move you created, the first game animation of its kind).
  async function revertCustomAnimations(donor) {
    const assigned = donor.animationAssignments || {};
    if (!Object.keys(assigned).length) return 0;
    const db = dbOf(donor), query = (o) => Native.call(db === "sparking" ? "querySparking" : "query", o);
    let count = 0;
    for (const t of G().targets(donor)) {
      if (!assigned[t.key] || !t.table || t.row == null) continue;
      const rows = donor.tables[t.table] || [], row = rows.find((r) => r.id === t.row);
      if (!row) continue;
      const field = t.kind === "intro" ? "passive_skill_effect_id" : t.field;
      if (!field) continue;
      let original = null;
      if (Number(t.row) > 0) { try { original = (await query({ table: t.table, ids: [t.row], limit: 1 }))[0] || null; } catch (e) { original = null; } }
      if (original) {
        row[field] = original[field];
        if (t.kind === "counter" && "efficacy_values" in original) row.efficacy_values = original.efficacy_values;
      } else if (t.table === "card_motions") {
        donor.tables.card_motions = rows.filter((r) => r !== row);
      } else if (t.kind === "intro" || t.kind === "counter") {
        row[field] = t.kind === "intro" ? null : 0;
      } else {
        const other = rows.find((r) => r !== row && Number(r[field]) > 0);
        row[field] = other ? other[field] : null;
      }
      count++;
    }
    donor.animationAssignments = {};
    donor.generatedFiles = [];
    return count;
  }

  // ------------------------------------------------------------------ helpers on the working copy
  // Imports donor rows (new private ids) together with any custom conditions/targets they use,
  // and points their condition formulas at the imported condition copies.
  function importWithConditions(work, donor, tables) {
    const conditionTables = CONDITION_TABLES.filter((t) => (donor.tables[t] || []).length);
    const maps = G().importOwned(work, donor, conditionTables.concat(tables));
    const causes = maps.skill_causalities;
    if (causes && causes.size) {
      const rewrite = (n) => typeof n === "number" ? (causes.get(n) ?? n) : Array.isArray(n) ? n.map((v, i) => i ? rewrite(v) : v) : n;
      for (const t of tables) for (const row of work.tables[t] || []) {
        if (!maps[t] || ![...maps[t].values()].includes(row.id) || !row.causality_conditions) continue;
        try {
          const c = JSON.parse(row.causality_conditions);
          c.compiled = rewrite(c.compiled);
          if (c.source) c.source = String(c.source).replace(/-?\d+/g, (n) => String(causes.get(Number(n)) ?? n));
          row.causality_conditions = JSON.stringify(c);
        } catch {}
      }
    }
    return maps;
  }
  // Only tables that exist in the game data and actually have rows are handed on.
  function subset(donor, tables) {
    const keep = (t) => donor.schema && donor.schema[t];
    return { schema: donor.schema, tables: Object.fromEntries(tables.filter(keep).map((t) => [t, donor.tables[t] || []]).concat(CONDITION_TABLES.filter((t) => keep(t) && (donor.tables[t] || []).length).map((t) => [t, donor.tables[t]]))) };
  }
  function setName(p, table, id) { const s = (p.tables[table] || []).find((r) => r.id === id); return s ? s.name || "" : ""; }
  function supersOf(p) { return (p.tables.card_specials || []).slice().sort((a, b) => (STYLE_ORDER[a.style] ?? 9) - (STYLE_ORDER[b.style] ?? 9) || (a.lv_start || 0) - (b.lv_start || 0) || a.id - b.id); }
  function superLabel(p, rel) { return (setName(p, "special_sets", rel.special_set_id) || STYLE_NAME[rel.style] || "Super Attack") + (rel.style && rel.style !== "Normal" ? " (" + (STYLE_NAME[rel.style] || rel.style) + ")" : ""); }
  function linkNames(c) { return Array.from({ length: 7 }, (_, i) => c["link_skill" + (i + 1) + "_id"]).filter(Boolean).map((id) => ((state.links || []).find((l) => l.id === id) || {}).name || ("Link " + id)); }
  function categoryNames(p) { return (p.tables.card_card_categories || []).map((r) => ((state.categories || []).find((c) => c.id === r.card_category_id) || {}).name).filter(Boolean); }
  function passiveSetRows(p, setId) { const ids = new Set((p.tables.passive_skill_set_relations || []).filter((r) => r.passive_skill_set_id === setId).map((r) => r.passive_skill_id)); return (p.tables.passive_skills || []).filter((r) => ids.has(r.id)); }
  function primaryPassiveRows(p) { const set = Forge.primaryPassive(p); return set ? passiveSetRows(p, set.id) : []; }
  const isTransform = (r) => [103, 79].includes(Number(r.efficacy_type));
  function describeSet(set) { return set ? String(set.itemized_description || set.description || "").replace(/\{passiveImg:[^}]*\}/g, "").replace(/\*/g, "").trim() : ""; }
  // Removes the current unit's rows of one family before the donor's are copied in.
  function dropOwned(work, relationTable, setTable, setField, childTables) {
    const rels = work.tables[relationTable] || [], ids = new Set(rels.map((r) => r[setField]));
    work.tables[relationTable] = [];
    if (setTable) work.tables[setTable] = (work.tables[setTable] || []).filter((r) => !ids.has(r.id));
    for (const [table, field] of childTables || []) work.tables[table] = (work.tables[table] || []).filter((r) => !ids.has(r[field]));
  }
  function clearAnimation(work, key) {
    const a = work.animationAssignments && work.animationAssignments[key];
    if (!a) return;
    // the id belongs to one table only: intro animations → passive_skill_effects, normal attacks and
    // counters → none (script files only), everything else → special_views
    const kind = String(key).split(":")[0], table = kind === "intro" ? "passive_skill_effects" : ["normal", "counter", "dodge"].includes(kind) ? null : "special_views";
    if (table && work.tables[table]) work.tables[table] = work.tables[table].filter((r) => r.id !== a.id || r.id > 0);
    work.generatedFiles = (work.generatedFiles || []).filter((f) => f.owner !== key);
    delete work.animationAssignments[key];
  }

  // ------------------------------------------------------------------ what the donor has
  function inventory(d) {
    const p = d.project, c = Forge.card(p), passive = Forge.primaryPassive(p), rows = primaryPassiveRows(p), leader = (p.tables.leader_skill_sets || []).find((s) => s.id === c.leader_skill_set_id);
    const supers = supersOf(p), actives = p.tables.card_active_skills || [], standby = (p.tables.card_standby_skill_set_relations || []).length + (p.tables.card_finish_skill_set_relations || []).length;
    const own = state.project, sameDb = dbOf(p) === dbOf(own);
    const customView = (v) => d.kind === "mine" && Number(v) < 0;
    return {
      stats: { ok: STATS.some((k) => c[k]), detail: "HP " + fmt(c.hp_max) + " · ATK " + fmt(c.atk_max) + " · DEF " + fmt(c.def_max) },
      identity: { ok: true, detail: (Forge.rarities[c.rarity] || "") + " " + (Forge.elements[c.element] || "") },
      leader: { ok: !!leader, detail: leader ? leader.name || "Leader Skill" : "No Leader Skill" },
      passive: { ok: !!passive && rows.length > 0, detail: passive ? (passive.name || "Passive Skill") + " · " + rows.length + " abilit" + (rows.length === 1 ? "y" : "ies") : "No Passive Skill" },
      transform: { ok: rows.some(isTransform), detail: rows.some(isTransform) ? "Transforms (passive)" : "Doesn't transform through its passive" },
      supers: { ok: sameDb && supers.length > 0, detail: sameDb ? supers.map((r) => superLabel(p, r)).join(" · ") || "No Super Attacks" : "From the other game collection (Eclipse/Sparking)", warn: supers.some((r) => customView(r.view_id)) ? "Its custom animations stay behind; the attacks use your current Super Attack animation." : "" },
      active: { ok: sameDb && actives.length > 0, detail: actives.length ? actives.map((r) => setName(p, "active_skill_sets", r.active_skill_set_id) || "Active Skill").join(" · ") : "No Active Skill" },
      standby: { ok: sameDb && standby > 0, detail: standby ? standby + " skill" + (standby === 1 ? "" : "s") : "None" },
      links: { ok: linkNames(c).length > 0, detail: linkNames(c).join(", ") || "None" },
      categories: { ok: (p.tables.card_card_categories || []).length > 0, detail: categoryNames(p).slice(0, 6).join(", ") + (categoryNames(p).length > 6 ? "…" : "") || "None" },
      art: { ok: !!(c.resource_id || d.cardId), detail: d.kind === "mine" && p.artBinding ? "Their in-game picture (custom artwork you imported stays with that unit)" : "Their card picture" },
      aura: { ok: true, detail: c.aura_id ? "Special aura" : "No special aura" },
      animations: { ok: sameDb && ((supers.some((r) => Number(r.view_id) > 0) && (own.tables.card_specials || []).length > 0) || ((p.tables.active_skill_sets || []).some((s) => Number(s.special_view_id) > 0) && (own.tables.card_active_skills || []).length > 0) || (p.tables.card_motions || []).some((r) => r.filename)), detail: "Super Attack, Active Skill and normal attack animations" }
    };
  }

  // ------------------------------------------------------------------ build the result
  function build(d, picked, options, base = state.project) {
    const before = base, work = Forge.clone(before), donor = d.project, dc = Forge.card(donor), changes = [], notes = [];
    const schemaFix = (tables) => { for (const t of tables) if (donor.schema && donor.schema[t]) G().ensure(work, donor.schema, t); };
    if (picked.has("stats")) {
      const b = Forge.card(work);
      for (const k of STATS) if (dc[k] != null) work.cardOverrides[k] = dc[k];
      changes.push(["HP, ATK & DEF", "HP " + fmt(b.hp_max) + " · ATK " + fmt(b.atk_max) + " · DEF " + fmt(b.def_max), "HP " + fmt(dc.hp_max) + " · ATK " + fmt(dc.atk_max) + " · DEF " + fmt(dc.def_max)]);
    }
    if (picked.has("identity")) {
      const b = Forge.card(work);
      work.cardOverrides.rarity = dc.rarity;
      work.cardOverrides.element = dc.element;
      changes.push(["Rarity, Type & Class", (Forge.rarities[b.rarity] || "") + " " + (Forge.elements[b.element] || ""), (Forge.rarities[dc.rarity] || "") + " " + (Forge.elements[dc.element] || "")]);
    }
    if (picked.has("leader")) {
      const was = (work.tables.leader_skill_sets || []).find((s) => s.id === Forge.card(work).leader_skill_set_id);
      schemaFix(["leader_skill_sets", "leader_skills"]);
      const maps = importWithConditions(work, donor, ["leader_skill_sets", "leader_skills"]);
      const id = maps.leader_skill_sets.get(G().stageAbilityId(donor, "base", "leader"));
      if (id == null) throw Error(d.name + " has no Leader Skill to copy.");
      G().setStageAbility(work, "base", "leader", id);
      const now = work.tables.leader_skill_sets.find((s) => s.id === id);
      changes.push(["Leader Skill", (was && was.name) || "—", (now.name || "Leader Skill") + (now.description ? " — " + now.description : "")]);
    }
    if (picked.has("passive")) {
      // options.targetSet: add into this passive set (e.g. the EZA step open in the Card Builder)
      const fixed = options.targetSet != null && (work.tables.passive_skill_sets || []).some((s) => s.id === options.targetSet);
      const was = fixed ? work.tables.passive_skill_sets.find((s) => s.id === options.targetSet) : Forge.primaryPassive(work), wasName = was ? was.name || "Passive Skill" : "—";
      schemaFix(["passive_skill_sets", "passive_skills", "passive_skill_set_relations"]);
      const donorSetOld = G().stageAbilityId(donor, options.passiveStage && G().stageSet(donor, options.passiveStage, "passive") ? options.passiveStage : "base", "passive");
      const adding = !!(options.passive === "add" && was && (fixed || passiveSetRows(work, was.id).length) && window.ForgePassiveMerge);
      // adding: bring only the chosen passive, not the donor's other (EZA stage) passives
      const src = adding ? ForgePassiveMerge.onlySet(donor, donorSetOld) : donor;
      const maps = importWithConditions(work, src, ["passive_skill_sets", "passive_skills", "passive_skill_set_relations", "passive_skill_set_additions", "dokkan_field_passive_skill_relations"].filter((t) => src.tables[t]));
      const donorSet = maps.passive_skill_sets.get(donorSetOld);
      if (donorSet == null) throw Error(d.name + " has no Passive Skill to copy.");
      if (adding) {
        if (!fixed) G().isolateAbilityStage(work, "base", "passive");
        const target = fixed ? options.targetSet : G().stageAbilityId(work, "base", "passive");
        const merged = ForgePassiveMerge.copyPassive(work, target, donorSet);
        // tidy straight away: exact copies become one, matching boosts combined, kept within today's meta
        const tf = merged.skipped.filter((t) => /under Transformations/.test(t)).length;
        if (tf) notes.push(tf + " transformation" + (tf === 1 ? " was" : "s were") + " left out of the passive — add them under Transformations on the Passive Skill step.");
        const tidy = options.organize === false ? null : ForgePassiveMerge.organize(work, target);
        if (tidy) for (const line of ForgePassiveMerge.organizeSummary(tidy).slice(1)) notes.push(line);
        work.builderAuto = work.builderAuto || {};
        work.builderAuto["passive:" + target] = false;
        if (work.builderLines) delete work.builderLines[target];
        const now = (work.tables.passive_skill_sets || []).find((s) => s.id === target);
        changes.push(["Passive Skill (added to yours)", wasName, describeSet(now) || ForgePassiveMerge.summary(merged) || "Combined"]);
      } else {
        G().setStageAbility(work, "base", "passive", donorSet);
        if ((work.formProjects || []).length) notes.push("Your unit's own transformed forms are kept. Whether it still transforms now depends on the new passive — check Transformations on the Passive Skill step.");
        const now = work.tables.passive_skill_sets.find((s) => s.id === donorSet);
        changes.push(["Passive Skill (replaces yours)", wasName, (now.name || "Passive Skill") + (describeSet(now) ? " — " + describeSet(now) : "")]);
      }
    } else if (picked.has("transform")) {
      const rows = primaryPassiveRows(donor).filter(isTransform);
      if (!rows.length) throw Error(d.name + " doesn't transform through its passive.");
      schemaFix(["passive_skills", "passive_skill_set_relations"]);
      if (!Forge.primaryPassive(work)) throw Error("Your unit needs a Passive Skill first (add any ability on the Passive Skill step).");
      G().isolateAbilityStage(work, "base", "passive");
      const target = G().stageAbilityId(work, "base", "passive"), part = subset(donor, []);
      part.tables.passive_skills = rows;
      const maps = importWithConditions(work, part, ["passive_skills"]);
      for (const id of maps.passive_skills.values()) work.tables.passive_skill_set_relations.push(Object.assign(Forge.rowDefault(work.schema.passive_skill_set_relations || donor.schema.passive_skill_set_relations), { id: Forge.localId(work, "passive_skill_set_relations"), passive_skill_set_id: target, passive_skill_id: id }));
      changes.push(["Transformation", "—", "Transforms like " + d.name + " (into the same forms). Make the forms your own later under Transformations on the Passive Skill step."]);
    }
    if (picked.has("supers")) {
      const old = supersOf(work).map((r) => r.id), wasNames = supersOf(work).map((r) => superLabel(work, r)), added = [];
      // a game animation (never one of your custom ones, whose script goes away with a replaced attack)
      const positive = (v) => (Number(v) > 0 ? Number(v) : null);
      const fallbackView = supersOf(work).map((r) => positive(r.view_id)).find(Boolean) || supersOf(donor).map((r) => positive(r.view_id)).find(Boolean) || null;
      for (const rel of supersOf(donor)) {
        const part = subset(donor, ["card_specials", "special_sets", "specials", "extra_special_options"]);
        part.tables.card_specials = [rel];
        part.tables.special_sets = (donor.tables.special_sets || []).filter((s) => s.id === rel.special_set_id);
        part.tables.specials = (donor.tables.specials || []).filter((s) => s.special_set_id === rel.special_set_id);
        part.tables.extra_special_options = (donor.tables.extra_special_options || []).filter((o) => o.card_special_id === rel.id);
        const row = ForgeSuperAttacks.copy(work, part);
        if (Number(row.view_id) < 0 && fallbackView) row.view_id = fallbackView;
        added.push(superLabel(work, row));
      }
      if (options.supers !== "add") for (const id of old) B().removeSuper(work, id);
      if (d.kind === "mine" && d.reverted) notes.push("Custom animations you made on that unit stay with it; copied moves use the game's original animations. Change them on Portraits & Sprites.");
      changes.push([options.supers === "add" ? "Super Attacks (added)" : "Super Attacks (replace yours)", wasNames.join(" · ") || "—", added.join(" · ")]);
    }
    if (picked.has("active")) {
      const wasNames = (work.tables.card_active_skills || []).map((r) => setName(work, "active_skill_sets", r.active_skill_set_id)).filter(Boolean);
      schemaFix(ACTIVE_TABLES);
      for (const key of Object.keys(work.animationAssignments || {})) if (key.startsWith("active:")) clearAnimation(work, key);
      dropOwned(work, "card_active_skills", "active_skill_sets", "active_skill_set_id", [["active_skills", "active_skill_set_id"], ["dokkan_field_active_skill_set_relations", "active_skill_set_id"]]);
      importWithConditions(work, donor, ACTIVE_TABLES.filter((t) => donor.tables[t]));
      const nowNames = (work.tables.card_active_skills || []).map((r) => setName(work, "active_skill_sets", r.active_skill_set_id)).filter(Boolean);
      changes.push(["Active Skill", wasNames.join(" · ") || "—", nowNames.join(" · ") || "—"]);
    }
    if (picked.has("standby")) {
      schemaFix(STANDBY_TABLES);
      for (const key of Object.keys(work.animationAssignments || {})) if (key.startsWith("standby:") || key.startsWith("finish:")) clearAnimation(work, key);
      dropOwned(work, "card_standby_skill_set_relations", "standby_skill_sets", "standby_skill_set_id", [["standby_skills", "standby_skill_set_id"]]);
      dropOwned(work, "card_finish_skill_set_relations", "finish_skill_sets", "finish_skill_set_id", [["finish_skills", "finish_skill_set_id"]]);
      importWithConditions(work, donor, STANDBY_TABLES.filter((t) => donor.tables[t]));
      changes.push(["Standby & Finish Skills", "—", (work.tables.standby_skill_sets || []).map((s) => s.name).concat((work.tables.finish_skill_sets || []).map((s) => s.name)).filter(Boolean).join(" · ") || "Copied"]);
    }
    if (picked.has("links")) {
      const b = linkNames(Forge.card(work));
      for (let i = 1; i <= 7; i++) work.cardOverrides["link_skill" + i + "_id"] = dc["link_skill" + i + "_id"] || null;
      changes.push(["Link Skills", b.join(", ") || "—", linkNames(dc).join(", ")]);
    }
    if (picked.has("categories")) {
      const b = categoryNames(work);
      work.schema.card_card_categories = work.schema.card_card_categories || state.info.schema.card_card_categories;
      work.tables.card_card_categories = [];
      (donor.tables.card_card_categories || []).forEach((r, i) => work.tables.card_card_categories.push(Object.assign(Forge.rowDefault(work.schema.card_card_categories), { id: Forge.localId(work, "card_card_categories"), card_id: work.source.cardId, card_category_id: r.card_category_id, num: i + 1 })));
      changes.push(["Categories", b.join(", ") || "—", categoryNames(work).join(", ")]);
    }
    if (picked.has("art")) {
      const b = (work.uiLabels && work.uiLabels.art) || "Current artwork";
      if (work.artBinding && window.ForgeArt) ForgeArt.restore(work);
      // your other unit's imported art lives in its own private namespace: use its original game picture
      const art = donor.artBinding && window.ForgeArt ? Forge.card(ForgeArt.restore(Forge.clone(donor))) : dc;
      work.cardOverrides.resource_id = art.resource_id || Math.floor(Number(d.cardId) / 10) * 10;
      work.cardOverrides.bg_effect_id = art.bg_effect_id != null ? art.bg_effect_id : null;
      work.uiLabels = work.uiLabels || {};
      work.uiLabels.art = d.name;
      work.uiLabels.artCardId = d.cardId;
      delete work.previewKey;
      changes.push(["Card artwork", b, d.name + "’s artwork"]);
    }
    if (picked.has("aura")) {
      const b = (work.uiLabels && work.uiLabels.aura) || "Current aura";
      for (const k of AURA) work.cardOverrides[k] = dc[k];
      work.uiLabels = work.uiLabels || {};
      work.uiLabels.aura = dc.aura_id ? d.name + "’s aura" : "No special aura (from " + d.name + ")";
      changes.push(["Aura", b, work.uiLabels.aura]);
    }
    if (picked.has("animations")) {
      const done = [];
      if (!picked.has("supers")) {
        const mine = supersOf(work), theirs = supersOf(donor).filter((r) => Number(r.view_id) > 0);
        mine.forEach((rel) => {
          const match = theirs.find((t) => t.style === rel.style && !t.used) || theirs.find((t) => t.style === "Normal" && !t.used) || theirs.find((t) => !t.used);
          if (!match) return;
          match.used = true;
          clearAnimation(work, "super:" + rel.id);
          rel.view_id = match.view_id;
          done.push(superLabel(work, rel) + " ← " + superLabel(donor, match));
        });
        theirs.forEach((t) => delete t.used);
      }
      if (!picked.has("active")) {
        const mySet = (work.tables.active_skill_sets || []).find((s) => (work.tables.card_active_skills || []).some((r) => r.active_skill_set_id === s.id));
        const their = (donor.tables.active_skill_sets || []).find((s) => Number(s.special_view_id) > 0);
        if (mySet && their) { clearAnimation(work, "active:" + mySet.id); mySet.special_view_id = their.special_view_id; done.push("Active Skill"); }
      }
      const motions = (donor.tables.card_motions || []).filter((r) => r.filename);
      if (motions.length) {
        schemaFix(["card_motions"]);
        for (const key of Object.keys(work.animationAssignments || {})) if (key.startsWith("normal:")) clearAnimation(work, key);
        work.tables.card_motions = [];
        for (const r of motions) work.tables.card_motions.push(Object.assign(Forge.clone(r), { id: Forge.localId(work, "card_motions"), card_id: work.source.cardId }));
        done.push("Normal attacks");
      }
      if (!done.length && !picked.has("supers") && !picked.has("active")) throw Error(d.name + " has no animations that can be copied onto your moves.");
      work.uiLabels = work.uiLabels || {};
      if (done.length) changes.push(["Animations", "Your current animations", done.join(" · ")]);
      notes.push("Only the animations changed; your moves keep their own damage and effects.");
    }
    // Your other unit's transformations may point at its own private forms (made with "Make these
    // transformations your own"). Those forms live inside that unit, so copied transformations are
    // pointed at the original game forms instead.
    if (d.kind === "mine" && (donor.formProjects || []).length) {
      const privateForms = new Map(donor.formProjects.map((f) => [Number(f.targetId), f]));
      let moved = 0;
      for (const table of ["passive_skills", "active_skills", "standby_skills", "finish_skills"]) for (const row of work.tables[table] || []) {
        if (Number(row.efficacy_type) !== 103 || !window.ForgeForms) continue;
        const t = ForgeForms.target(row, table), form = privateForms.get(t.targetId);
        if (!form || (work.formProjects || []).some((f) => Number(f.targetId) === t.targetId)) continue;
        const original = Number(form.source && form.source.cardId);
        if (!original) continue;
        if (t.values) { t.values[0] = original; row.efficacy_values = JSON.stringify(t.values); } else row[t.field] = original;
        moved += 1;
      }
      if (moved) notes.push("The copied transformation turns into the original game form" + (moved === 1 ? "" : "s") + ". To use your own versions, open Transformations on the Passive Skill step and choose “Make these transformations your own”.");
    }
    return { work, changes, notes };
  }

  // ------------------------------------------------------------------ screens
  function closeDialog() { const d = document.getElementById("dialog"); if (d && d.open) d.close(); }
  function open() {
    const p = state.project;
    if (!p) return toast("Open one of your units first.", true);
    if (p.awaken) return toast("EZA projects change an existing card; copy abilities on each step instead.", true);
    dialog("Copy from a unit", '<div class="ucopy-dialog" data-no-ai></div><p>Take anything from another unit — a character in the game or one of your own — and put it on <strong>' + html(Forge.card(p).name || "your unit") + '</strong>. You\'ll see every change before anything happens.</p>' +
      '<div class="ucopy-sources"><button type="button" class="button ucopy-source" id="ucopy-game"><strong>🎮 A character from the game</strong><small>Any card in the game, including EZA versions.</small></button><button type="button" class="button ghost ucopy-source" id="ucopy-mine"><strong>📁 One of my units</strong><small>Something you made earlier.</small></button></div><div class="row"><button type="button" class="button ghost" id="ucopy-cancel0">Cancel</button></div>');
    document.getElementById("ucopy-cancel0").onclick = closeDialog;
    document.getElementById("ucopy-game").onclick = () => { closeDialog(); ForgeGuideUI.pickUnit("Copy from which character?", (card) => load(() => gameDonor(card)), { sourceDatabase: dbOf(p), allVersions: true }); };
    document.getElementById("ucopy-mine").onclick = () => pickMine().catch((e) => toast(e.message, true));
  }
  async function pickMine() {
    const rows = (await Native.call("projects")).filter((r) => r.key !== state.project.key);
    if (!rows.length) return toast("You don't have another unit yet.", true);
    dialog("Copy from which of your units?", '<div class="ucopy-dialog" data-no-ai></div><label class="field">Find your unit<input id="ucopy-search" type="search" placeholder="Unit name…"></label><div class="guide-picks" id="ucopy-list"></div><div class="row"><button type="button" class="button ghost" id="ucopy-back0">← Back</button></div>');
    document.getElementById("ucopy-back0").onclick = () => open();
    const draw = () => {
      const q = document.getElementById("ucopy-search").value.trim().toLowerCase();
      const list = rows.filter((r) => !q || String(r.name).toLowerCase().includes(q));
      document.getElementById("ucopy-list").innerHTML = list.map((r) => '<button type="button" class="guide-pick" data-ucopy-key="' + html(r.key) + '"><span><strong>' + html(r.name) + "</strong><small>" + html(r.sourceName || "") + "</small></span></button>").join("") || "<p>No units match.</p>";
      document.querySelectorAll("[data-ucopy-key]").forEach((b) => b.onclick = () => load(() => myDonor(b.dataset.ucopyKey)));
    };
    document.getElementById("ucopy-search").oninput = draw;
    draw();
  }
  async function load(fetch) {
    const p = state.project;
    let d = null;
    await busy("Reading that unit", async () => { d = await fetch(); });
    if (!d) return;   // busy already showed what went wrong
    if (state.project !== p) return toast("Your unit changed. Start the copy again.", true);
    choose(d);
  }
  function choose(d, picked = new Set(), options = { passive: "add", supers: "replace" }) {
    const inv = inventory(d);
    dialog("Copy from " + d.name, '<div class="ucopy-dialog" data-no-ai></div><p>Tick what you want to copy onto your unit.</p><div class="ucopy-list">' + FEATURES.map(([key, label, help]) => {
      const it = inv[key], disabled = !it.ok;
      return '<label class="ucopy-item' + (disabled ? " off" : "") + '"><input type="checkbox" data-ucopy="' + key + '"' + (picked.has(key) && !disabled ? " checked" : "") + (disabled ? " disabled" : "") + '><span><strong>' + html(label) + '</strong><small>' + html(it.detail || help) + "</small>" + (it.warn ? '<small class="ucopy-warn">' + html(it.warn) + "</small>" : "") + "</span></label>" +
        (key === "passive" ? '<div class="ucopy-mode" data-ucopy-mode="passive"><label><input type="radio" name="ucopy-passive" value="add"' + (options.passive !== "replace" ? " checked" : "") + '> Add to my passive</label><label><input type="radio" name="ucopy-passive" value="replace"' + (options.passive === "replace" ? " checked" : "") + "> Replace my passive</label></div>" : "") +
        (key === "supers" ? '<div class="ucopy-mode" data-ucopy-mode="supers"><label><input type="radio" name="ucopy-supers" value="replace"' + (options.supers !== "add" ? " checked" : "") + '> Replace mine</label><label><input type="radio" name="ucopy-supers" value="add"' + (options.supers === "add" ? " checked" : "") + "> Add to mine</label></div>" : "");
    }).join("") + '</div><div class="row ucopy-quick"><button type="button" class="button ghost small" id="ucopy-kit">Pick the whole kit</button><button type="button" class="button ghost small" id="ucopy-none">Clear</button></div><div class="row"><button type="button" class="button" id="ucopy-preview">See the changes →</button><button type="button" class="button ghost" id="ucopy-cancel">Cancel</button></div>');
    const boxes = () => [...document.querySelectorAll("[data-ucopy]")];
    const sync = () => {
      const on = new Set(boxes().filter((b) => b.checked).map((b) => b.dataset.ucopy));
      document.querySelectorAll("[data-ucopy-mode]").forEach((m) => m.hidden = !on.has(m.dataset.ucopyMode));
      // a copied passive already contains the transformation; supers bring their own animations
      const t = document.querySelector('[data-ucopy="transform"]');
      if (t && inv.transform.ok) { t.disabled = on.has("passive"); if (on.has("passive")) t.checked = false; t.closest(".ucopy-item").classList.toggle("off", on.has("passive")); }
      document.getElementById("ucopy-preview").disabled = !on.size;
    };
    boxes().forEach((b) => b.onchange = sync);
    document.getElementById("ucopy-kit").onclick = () => { boxes().forEach((b) => { if (!b.disabled) b.checked = ["stats", "identity", "leader", "passive", "supers", "active", "standby", "links", "categories"].includes(b.dataset.ucopy); }); const r = document.querySelector('input[name="ucopy-passive"][value="replace"]'); if (r) r.checked = true; sync(); };
    document.getElementById("ucopy-none").onclick = () => { boxes().forEach((b) => { b.checked = false; }); sync(); };
    document.getElementById("ucopy-cancel").onclick = closeDialog;
    document.getElementById("ucopy-preview").onclick = () => {
      const on = new Set(boxes().filter((b) => b.checked && !b.disabled).map((b) => b.dataset.ucopy));
      const opts = { passive: (document.querySelector('input[name="ucopy-passive"]:checked') || {}).value || "add", supers: (document.querySelector('input[name="ucopy-supers"]:checked') || {}).value || "replace" };
      try { preview(d, on, opts); } catch (e) { toast(e.message || String(e), true); }
    };
    sync();
  }
  function preview(d, picked, options) {
    const p = state.project, result = build(d, picked, options);
    dialog("What will change", '<div class="ucopy-dialog" data-no-ai></div><p>From <strong>' + html(d.name) + "</strong> to <strong>" + html(Forge.card(p).name || "your unit") + '</strong>:</p><div class="ucopy-changes">' + result.changes.map(([what, from, to]) => '<div class="ucopy-change"><strong>' + html(what) + '</strong><span class="ucopy-from">' + html(from) + '</span><span class="ucopy-arrow" aria-hidden="true">↓</span><span class="ucopy-to">' + html(to) + "</span></div>").join("") + "</div>" +
      result.notes.map((n) => '<p class="hint">' + html(n) + "</p>").join("") + '<p class="hint">Nothing has changed yet. After applying, ↶ Undo takes it all back in one step.</p><div class="row"><button type="button" class="button" id="ucopy-apply">Apply to my unit</button><button type="button" class="button ghost" id="ucopy-back">← Back</button></div>');
    document.getElementById("ucopy-back").onclick = () => choose(d, picked, options);
    document.getElementById("ucopy-apply").onclick = async () => {
      if (state.project !== p) return toast("Your unit changed. Start the copy again.", true);
      // fields the copy removed (e.g. custom artwork links) must go from your unit too
      for (const k of Object.keys(p)) if (!(k in result.work)) delete p[k];
      Object.assign(p, result.work);
      if (picked.has("art")) { state.previewUrl = ""; if (typeof projectPreviewUrl === "function") projectPreviewUrl(p).then((u) => { if (state.project === p) { state.previewUrl = u; if (typeof renderPreview === "function") renderPreview(); } }).catch(() => {}); }
      closeDialog();
      if (window.ForgeBuilderUI && ForgeBuilderUI.refreshTexts && state.builder) ForgeBuilderUI.refreshTexts();
      scheduleSave();
      await flushSave();
      renderEditor();
      toast("Copied " + result.changes.length + " thing" + (result.changes.length === 1 ? "" : "s") + " from " + d.name + ". ↶ Undo takes it back.");
    };
  }
  // Toolbar button in the card builder, next to Presets.
  let queued = false;
  function inject() {
    queued = false;
    const tools = document.querySelector(".bld-tools");
    if (tools && !tools.querySelector(".ucopy-button") && !(state.project && state.project.awaken)) {
      const b = document.createElement("button");
      b.type = "button";
      b.className = "button ghost small ucopy-button";
      b.textContent = "⧉ Copy from a unit";
      b.onclick = () => open();
      (tools.querySelector(".shell-presets-button") || tools.querySelector('[data-b="ai-helper"]') || tools.firstChild)?.after(b);
    }
  }
  new MutationObserver(() => { if (!queued) { queued = true; requestAnimationFrame(inject); } }).observe(document.body, { childList: true, subtree: true });
  return { open, build, inventory, gameDonor, myDonor, FEATURES };
})();
