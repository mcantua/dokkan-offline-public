/* Combining passive skills.
   - Copying another character's passive ADDS it to the current passive: abilities that do the same
     thing at the same moment (same effect, timing, target, duration, chance and conditions) are
     merged by adding their values together; everything else is appended.
   - Merged values are kept inside today's (late-2026) power-creep limits so a unit doesn't break
     the game, and the in-game description is rewritten to match, in the official
     "*Heading*\n- effect" layout.
   - The same rules are used by the AI helper and by the balance check in the Card Builder. */
(function(root, factory) {
  if (typeof module === "object" && module.exports) module.exports = factory(require("./core"), require("./builder-model"));
  else root.ForgePassiveMerge = factory(root.Forge, root.ForgeBuilder);
})(typeof globalThis !== "undefined" ? globalThis : this, function(Forge, B) {
  "use strict";

  // ------------------------------------------------------------ meta limits
  // Highest values seen on current top-tier LR / TUR units for ONE ability line (all copies of the
  // same ability at the same moment added together). Team buffs are much smaller than self buffs.
  const META = {
    stat: { self: 300, team: 60, enemy: 50 },      // ATK / DEF % (start of turn, when attacking, …)
    ki: { self: 7, team: 3 },                       // Ki +
    dr: 60,                                         // damage reduction %
    dodge: 60,                                      // evade chance %
    crit: 70,                                       // critical hit chance %
    heal: 20,                                       // HP recovered %
    perSphere: 15,                                  // ATK / DEF +% per Ki Sphere
    kiPerSphere: 2,                                 // Ki + per Ki Sphere
    stackStep: { pct: 50, ki: 2 },                  // growth per attack
    stackMax: { pct: 300, ki: 7 },                  // growth limit
    additionalPerMoment: 2,                         // additional attacks triggered at one moment
    // Worst case for the whole passive when every condition is met at once (the character's own
    // ATK / DEF % and Ki, not counting growth or per-Ki-Sphere boosts). Today's strongest LR/TUR
    // units reach about this much; past it a unit is "broken".
    total: { stat: 1000, ki: 12 },
    flat: 10000                                     // old flat ATK / DEF boosts ("ATK 5000") at one moment
  };
  const TEAM = new Set([2, 16, 12, 13]), ENEMY = new Set([3, 4]);
  const scope = (target) => ENEMY.has(Number(target)) ? "enemy" : TEAM.has(Number(target)) ? "team" : "self";

  // cap for one decoded field of a catalog ability; null = not additive / no cap
  function capOf(key, field, settings, values) {
    const who = scope(settings.target);
    switch (key) {
      case "atkdef": case "atk": case "def": return META.stat[who] || META.stat.self;
      case "atkDown": case "defDown": case "atkdefDown": return META.stat.enemy;
      case "typeStats": return field === "type" ? null : META.stat.team;
      case "ki": return who === "self" ? META.ki.self : META.ki.team;
      case "typeKi": return field === "type" ? null : META.ki.team;
      case "dr": return META.dr;
      case "dodge": return META.dodge;
      case "crit": return META.crit;
      case "heal": return META.heal;
      case "atkPerSphere": case "defPerSphere": case "atkdefPerSphere": return META.perSphere;
      case "kiPerSphere": return field === "sphere" ? null : META.kiPerSphere;
      case "stack": {
        if (field === "stat" || field === "trigger") return null;
        const ki = Number(values && values.stat) === 5;
        return field === "step" ? (ki ? META.stackStep.ki : META.stackStep.pct) : (ki ? META.stackMax.ki : META.stackMax.pct);
      }
      default: return null;
    }
  }
  // fields that are identity (must match to merge) rather than amounts
  const IDENTITY = { typeStats: ["type"], typeKi: ["type"], kiPerSphere: ["sphere"], stack: ["stat", "trigger"], sphereChange: ["from", "to"], counter: ["what", "power", "dr", "anim"], dodgeCounter: ["what", "power", "anim"], revive: ["hp", "view"] };
  const NEVER_MERGE = new Set(["additional"]);           // two additional attacks are two attacks
  const FLAGS = new Set(["guard", "immune", "foresee", "effective", "stun", "seal", "disable", "sphereChange", "counter", "dodgeCounter", "revive"]); // same effect twice = once

  // ------------------------------------------------------------ rows
  const norm = (v) => v == null || v === "" ? "" : String(v);
  const cond = (row) => { const c = norm(row.causality_conditions); if (!c) return ""; try { const o = JSON.parse(c); return JSON.stringify(o && o.compiled !== undefined ? o.compiled : o); } catch { return c; } };
  const values = (row) => { try { const v = JSON.parse(row.efficacy_values || "{}"); return Array.isArray(v) || (v && Object.keys(v).length) ? JSON.stringify(v) : ""; } catch { return norm(row.efficacy_values); } };
  function settingsKey(row) {
    return [row.efficacy_type, row.calc_option, row.target_type, row.exec_timing_type, Number(row.sub_target_type_set_id) || 0, row.turn, row.probability, Number(row.is_once) || 0, cond(row), values(row)].join("|");
  }
  function decoded(row) { const d = B.decodePassive(row); return d ? { key: d.key, def: B.passiveDef(d.key), values: B.normalizeValues(B.passiveDef(d.key).fields, d.values) } : null; }
  // "same" = identical settings, and (for catalog abilities) identical identity fields
  function sameAbility(a, b) {
    if (settingsKey(a) !== settingsKey(b)) return false;
    const da = decoded(a), db = decoded(b);
    if (!da || !db) return ["eff_value1", "eff_value2", "eff_value3"].every((f) => norm(a[f]) === norm(b[f])) ? "duplicate" : false;
    if (da.key !== db.key) return false;
    if ((IDENTITY[da.key] || []).some((f) => da.values[f] !== db.values[f])) return false;
    if (NEVER_MERGE.has(da.key)) return false;
    if (FLAGS.has(da.key) || !da.def.fields.some((f) => f.kind !== "choice")) return "duplicate";
    return "sum";
  }
  // Changes only what an ability does and how much. Its moment, duration, target, sub-target,
  // chance, once-only flag and extra data stay exactly as they were (the builder's form would
  // otherwise reset values it has no option for, e.g. "for 7 turns" or timing 3).
  const KEEP = ["exec_timing_type", "turn", "target_type", "sub_target_type_set_id", "probability", "is_once", "efficacy_values"];
  function rewrite(row, key, values, settings) {
    const kept = {};
    for (const k of KEEP) if (row[k] !== undefined) kept[k] = row[k];
    B.updatePassiveAbility(row, key, values, settings || B.settingsOf(row));
    return Object.assign(row, kept);
  }
  // Adds b's amounts into a (a is changed). Returns notes about limits applied.
  function addInto(a, b) {
    const da = decoded(a), db = decoded(b), s = B.settingsOf(a), out = Object.assign({}, da.values), notes = [];
    for (const f of da.def.fields) {
      if (f.kind === "choice") continue;
      const cap = capOf(da.key, f.name, s, da.values), raw = Number(da.values[f.name]) + Number(db.values[f.name]);
      let next = Math.min(raw, f.max);
      if (cap != null && next > cap) next = Math.max(cap, Number(da.values[f.name]), Number(db.values[f.name]));
      if (next < raw) notes.push({ field: f.label.replace(/\s*[+−-]?\s*%?$/, "").replace(/\s*\+$/, ""), wanted: raw, kept: next });
      out[f.name] = next;
    }
    rewrite(a, da.key, out, s);
    return notes;
  }
  function setRows(p, setId) {
    const ids = (p.tables.passive_skill_set_relations || []).filter((r) => r.passive_skill_set_id === setId).map((r) => r.passive_skill_id);
    // the level perks (Godly / Super Exclusive) are never combined, capped or replaced
    return ids.map((id) => (p.tables.passive_skills || []).find((r) => r.id === id)).filter((r) => r && !/Exclusive$/.test(r.name || ""));
  }
  // A row used by another passive (for example a different EZA step) is copied before it changes.
  function ownRow(p, setId, row) {
    const users = (p.tables.passive_skill_set_relations || []).filter((r) => r.passive_skill_id === row.id);
    if (users.every((r) => r.passive_skill_set_id === setId)) return row;
    const copy = Object.assign(Forge.clone(row), { id: Forge.localId(p, "passive_skills") });
    p.tables.passive_skills.push(copy);
    for (const rel of users) if (rel.passive_skill_set_id === setId) rel.passive_skill_id = copy.id;
    return copy;
  }
  function relate(p, setId, rowId) {
    const rel = Object.assign(p.schema && p.schema.passive_skill_set_relations ? Forge.rowDefault(p.schema.passive_skill_set_relations) : {}, { id: Forge.localId(p, "passive_skill_set_relations"), passive_skill_set_id: setId, passive_skill_id: rowId });
    p.tables.passive_skill_set_relations.push(rel);
  }
  const isTransformation = (row) => [103, 79].includes(Number(row.efficacy_type));
  const isAdditional = (row) => { const d = decoded(row); return Number(row.efficacy_type) === 81 && (!d || d.key === "additional"); };
  function describe(row) { try { return B.passiveLine(row); } catch { return "Special effect"; } }

  /* Adds the passive set donorSetId (already inside p) into targetSetId.
     Returns { merged: [{text, notes}], added: [text], skipped: [text] }. The donor set and its
     unused rows are removed afterwards. */
  function mergeSets(p, targetSetId, donorSetId, options = {}) {
    const report = { merged: [], added: [], skipped: [], duplicates: 0 };
    const donorRows = setRows(p, donorSetId), keepDonor = new Set();
    for (const donor of donorRows) {
      if (isTransformation(donor) && !options.keepTransformations) { report.skipped.push(describe(donor) + " (add transformations under Transformations on the Passive Skill step)"); continue; }
      const current = setRows(p, targetSetId);
      let done = false;
      for (const row of current) {
        const how = sameAbility(row, donor);
        if (!how) continue;
        if (how === "duplicate") { report.duplicates++; done = true; break; }
        const mine = ownRow(p, targetSetId, row), before = describe(mine), notes = addInto(mine, donor);
        report.merged.push({ before, donor: describe(donor), text: describe(mine), notes });
        done = true;
        break;
      }
      if (done) continue;
      if (isAdditional(donor)) {
        const sameMoment = current.filter((r) => isAdditional(r) && Number(r.exec_timing_type) === Number(donor.exec_timing_type) && cond(r) === cond(donor));
        if (sameMoment.length >= META.additionalPerMoment) { report.skipped.push(describe(donor) + " (already " + sameMoment.length + " additional attacks at that moment)"); continue; }
      }
      relate(p, targetSetId, donor.id);
      keepDonor.add(donor.id);
      report.added.push(describe(donor));
    }
    // remove the donor set, and donor rows that were merged or skipped
    for (const row of donorRows) if (!keepDonor.has(row.id) && !(p.tables.passive_skill_set_relations || []).some((r) => r.passive_skill_id === row.id && r.passive_skill_set_id !== donorSetId)) Forge.removePassive(p, row.id);
    p.tables.passive_skill_set_relations = (p.tables.passive_skill_set_relations || []).filter((r) => r.passive_skill_set_id !== donorSetId);
    p.tables.passive_skill_sets = (p.tables.passive_skill_sets || []).filter((s) => s.id !== donorSetId);
    if (p.tables.passive_skill_set_additions) p.tables.passive_skill_set_additions = p.tables.passive_skill_set_additions.filter((r) => r.target_passive_skill_set_id !== donorSetId && r.additional_passive_skill_set_id !== donorSetId);
    if (p.tables.dokkan_field_passive_skill_relations) {
      const alive = new Set((p.tables.passive_skills || []).map((r) => r.id));
      p.tables.dokkan_field_passive_skill_relations = p.tables.dokkan_field_passive_skill_relations.filter((r) => alive.has(r.passive_skill_id));
    }
    return report;
  }

  // Adds one freshly created row into a matching ability of the same passive, if there is one
  // (used when abilities are added automatically, e.g. by the AI helper). Returns the kept row.
  function absorb(p, setId, row) {
    for (const other of setRows(p, setId)) {
      if (other.id === row.id) continue;
      const how = sameAbility(other, row);
      if (!how) continue;
      if (how === "sum") addInto(ownRow(p, setId, other), row);
      Forge.removePassive(p, row.id);
      return { row: setRows(p, setId).find((r) => r.id === other.id) || other, merged: true };
    }
    return { row, merged: false };
  }

  // ------------------------------------------------------------ balance check
  // Totals of the same ability at the same moment that go past the meta limits.
  function balanceIssues(rows) {
    const groups = new Map();
    for (const row of rows) {
      const d = decoded(row);
      if (!d || NEVER_MERGE.has(d.key) || FLAGS.has(d.key)) continue;
      const key = d.key + "|" + [row.target_type, row.exec_timing_type, cond(row), (IDENTITY[d.key] || []).map((f) => d.values[f]).join(",")].join("|");
      if (!groups.has(key)) groups.set(key, []);
      groups.get(key).push({ row, d });
    }
    const issues = [];
    for (const list of groups.values()) {
      const { d, row } = list[0], s = B.settingsOf(row);
      for (const f of d.def.fields) {
        if (f.kind === "choice") continue;
        const cap = capOf(d.key, f.name, s, d.values);
        if (cap == null) continue;
        const total = list.reduce((n, x) => n + Number(x.d.values[f.name]), 0);
        if (total > cap) issues.push({ rows: list.map((x) => x.row), key: d.key, field: f.name, label: f.label, total, cap, text: describe(row) });
      }
    }
    return issues;
  }
  // Lowers the amounts so every issue fits its limit (the last abilities give way first).
  function fitToMeta(p, setId) {
    const fixed = [];
    for (const issue of balanceIssues(setRows(p, setId))) {
      let over = issue.total - issue.cap;
      for (const row of issue.rows.slice().reverse()) {
        if (over <= 0) break;
        const mine = ownRow(p, setId, row), d = decoded(mine), now = Number(d.values[issue.field]);
        const min = (d.def.fields.find((f) => f.name === issue.field) || {}).min || 1, cut = Math.min(over, now - min);
        if (cut <= 0) continue;
        d.values[issue.field] = now - cut;
        over -= cut;
        rewrite(mine, d.key, d.values);
      }
      const pct = /%/.test(issue.label) ? "%" : "";
      fixed.push(issue.label.replace(/\s*[+−-]?\s*%?$/, "").replace(/\s*\+$/, "") + " " + issue.total + pct + " → " + (issue.cap + Math.max(0, over)) + pct);
    }
    return fixed;
  }

  // ------------------------------------------------------------ descriptions
  // Official text: headings in *stars* (may wrap over lines), bullets "- " (may wrap too).
  function parse(text) {
    const groups = [];
    let group = null, heading = null, bullet = null;
    const lines = String(text || "").replace(/\r/g, "").split("\n");
    for (const raw of lines) {
      const line = raw.trim();
      if (heading !== null) { heading += " " + line; if (line.endsWith("*")) { group = { heading: heading.replace(/^\*|\*$/g, "").trim(), lines: [] }; groups.push(group); heading = null; bullet = null; } continue; }
      if (!line) continue;
      if (line.startsWith("*")) {
        if (line.length > 1 && line.endsWith("*")) { group = { heading: line.replace(/^\*|\*$/g, "").trim(), lines: [] }; groups.push(group); bullet = null; }
        else heading = line;
        continue;
      }
      if (!group) { group = { heading: "", lines: [] }; groups.push(group); }
      if (line.startsWith("- ") || line === "-") { bullet = line.replace(/^-\s?/, ""); group.lines.push(bullet); continue; }
      if (group.lines.length) group.lines[group.lines.length - 1] += " " + line;
      else group.lines.push(line);
    }
    return groups.filter((g) => g.heading || g.lines.length);
  }
  function serialize(groups) {
    return groups.filter((g) => g.lines.length).map((g) => (g.heading ? "*" + g.heading + "*\n" : "") + g.lines.map((l) => "- " + l).join("\n")).join("\n");
  }
  // {passiveImg:up_g}/{passiveImg:down_r} are just arrows; {passiveImg:once}/{passiveImg:forever} mean something
  const clean = (s) => String(s).replace(/\{passiveImg:(up|down)_[a-z]+\}/gi, "").replace(/\s+/g, " ").trim().toLowerCase();
  const headingKey = (h) => clean(h).replace(/[^a-z0-9%#]+/g, " ").trim();
  // Numbers that are amounts: "+3", "250%", "Ki +3". Not "when Ki is 24", "50% or less", "4th".
  const AMOUNT = /([+＋]?)(\d+)(%?)(?!\d)/g;
  function amounts(line) {
    const out = [], text = String(line);
    for (const m of text.matchAll(AMOUNT)) {
      const before = text.slice(Math.max(0, m.index - 16), m.index).toLowerCase().replace(/\{passiveimg:(up|down)_[a-z]+\}/g, "").trimEnd(), after = text.slice(m.index + m[0].length, m.index + m[0].length + 12).toLowerCase();
      const context = /\b(is|at|of|hp|from|than|every|turn|turns|attacker|within)\s*$/.test(before) || /^\s*(or (more|less|above|below|higher|lower)|st\b|nd\b|rd\b|th\b|turn|attack|time|ki sphere)/.test(after);
      out.push({ index: m.index, length: m[0].length, sign: m[1], value: Number(m[2]), pct: m[3], amount: !!(m[1] || m[3]) && !context });
    }
    return out;
  }
  // wording of a line without its amounts (other numbers, e.g. "for 5 turns", stay part of it)
  function shape(line) {
    const text = String(line), list = amounts(text);
    let out = "", last = 0;
    for (const x of list) { out += text.slice(last, x.index) + (x.amount ? "#" + x.pct : text.substr(x.index, x.length)); last = x.index + x.length; }
    return clean((out + text.slice(last)).replace(/\{passiveImg:down_[a-z]+\}/gi, " ⇩ ")).replace(/[+＋]/g, "");
  }
  function textCap(line, index, length) {
    const l = clean(line), before = clean(String(line).slice(0, index)).slice(-48), after = clean(String(line).slice(index + length)).slice(0, 48);
    const team = /all allies|allies'|allies’/.test(l), enemy = /enem/.test(l) && /[−-]$|lower|reduc(e|es) (the )?(attacked )?enem/.test(before + l);
    if (/per ki sphere/.test(l)) return /\bki\s*[+＋]?\s*$/.test(before) ? META.kiPerSphere : META.perSphere;
    const pick = (ctx) => {
      if (/up to\s*[+＋]?$/.test(ctx)) return /\bki\b/.test(l) ? META.stackMax.ki : META.stackMax.pct;
      if (/damage reduction|reduces damage|damage received/.test(ctx)) return META.dr;
      if (/evad|dodge/.test(ctx)) return META.dodge;
      if (/critical/.test(ctx)) return META.crit;
      if (/recover/.test(ctx)) return META.heal;
      if (/per ki sphere/.test(ctx)) return /ki\s*[+＋]?\s*$/.test(before) ? META.kiPerSphere : META.perSphere;
      if (/\bki\s*[+＋]?\s*$/.test(ctx)) return team ? META.ki.team : META.ki.self;
      if (/atk|def/.test(ctx)) return enemy ? META.stat.enemy : team ? META.stat.team : META.stat.self;
      return null;
    };
    const near = pick(before);
    return near != null ? near : pick(after.replace(/^[^a-z]*/, ""));
  }
  // a + b for two lines of the same shape, keeping a's wording and format
  function sumLine(a, b, notes) {
    const na = amounts(a), nb = amounts(b);
    if (na.length !== nb.length) return a;
    let out = "", last = 0;
    na.forEach((x, i) => {
      out += a.slice(last, x.index);
      let v = x.value;
      if (x.amount && nb[i].amount) {
        const raw = x.value + nb[i].value, cap = textCap(a, x.index, x.length);
        v = cap != null && raw > cap ? Math.max(cap, x.value, nb[i].value) : raw;
        if (v < raw && notes) notes.push({ line: a, wanted: raw, kept: v });
      }
      out += x.sign + v + x.pct;
      last = x.index + x.length;
    });
    return out + a.slice(last);
  }
  const transformLine = (l) => /^transforms\b|giant form/i.test(clean(l));
  const additionalLine = (l) => /additional (super )?attack|additional super attack/.test(clean(l));
  /* Adds donor's description into current's. Lines with the same wording (apart from the amounts)
     under the same heading are combined by adding the amounts (within meta limits). */
  function mergeText(current, donor, options = {}) {
    const groups = parse(current), notes = [];
    for (const dg of parse(donor)) {
      let g = groups.find((x) => headingKey(x.heading) === headingKey(dg.heading));
      for (const line of dg.lines) {
        if (!options.keepTransformations && transformLine(line)) continue;
        if (!g) { g = { heading: dg.heading, lines: [] }; groups.push(g); }
        // additional attacks are separate attacks: never added together, at most two per moment
        if (additionalLine(line)) { if (g.lines.filter(additionalLine).length < META.additionalPerMoment) g.lines.push(line); continue; }
        const match = g.lines.findIndex((l) => !additionalLine(l) && shape(l) === shape(line));
        if (match >= 0) {
          // same wording: amounts are added together; a repeated effect without amounts appears once
          if (amounts(line).some((x) => x.amount)) g.lines[match] = sumLine(g.lines[match], line, notes);
          continue;
        }
        g.lines.push(line);
      }
    }
    // keep "Basic effect(s)" first like the game does
    groups.sort((a, b) => (headingKey(b.heading) === "basic effect s") - (headingKey(a.heading) === "basic effect s"));
    return { text: serialize(groups), notes };
  }
  // Puts one generated line under its heading (creating the heading if needed).
  function insertLine(text, heading, line) {
    const groups = parse(text);
    let g = groups.find((x) => headingKey(x.heading) === headingKey(heading));
    if (!g) { g = { heading, lines: [] }; if (headingKey(heading) === "basic effect s") groups.unshift(g); else groups.push(g); }
    if (!g.lines.some((l) => clean(l) === clean(line))) g.lines.push(line);
    return serialize(groups);
  }
  // Finds a line written for `line` (same words, or the official wording of the same amounts).
  function locate(groups, heading, line) {
    const order = groups.slice().sort((a, b) => (headingKey(b.heading) === headingKey(heading)) - (headingKey(a.heading) === headingKey(heading)));
    for (const g of order) {
      let i = g.lines.findIndex((l) => clean(l) === clean(line));
      if (i < 0) i = g.lines.findIndex((l) => shape(l) === shape(line) && amounts(l).map((x) => x.value).join() === amounts(line).map((x) => x.value).join());
      if (i >= 0) return { g, i };
    }
    return null;
  }
  function replaceLine(text, oldHeading, oldLine, heading, line) {
    const groups = parse(text), at = locate(groups, oldHeading, oldLine);
    if (!at) return null;
    if (headingKey(oldHeading) === headingKey(heading)) {
      const old = at.g.lines[at.i];
      // keep the official wording/format when only the amounts changed
      if (shape(old) === shape(line) && clean(old) !== clean(line) && amounts(old).length === amounts(line).length) {
        const na = amounts(old), nb = amounts(line);
        let out = "", last = 0;
        na.forEach((x, k) => { out += old.slice(last, x.index) + x.sign + nb[k].value + x.pct; last = x.index + x.length; });
        at.g.lines[at.i] = out + old.slice(last);
      } else at.g.lines[at.i] = /\{passiveImg:up_g\}/i.test(old) && !/\{passiveImg:/i.test(line) ? String(line).replace(/(\d+%)(?![\s\S]*\d+%)/, "$1{passiveImg:up_g}") : line;
      return serialize(groups);
    }
    at.g.lines.splice(at.i, 1);
    return insertLine(serialize(groups), heading, line);
  }
  function removeLine(text, heading, line) {
    const groups = parse(text), at = locate(groups, heading, line);
    if (!at) return null;
    at.g.lines.splice(at.i, 1);
    return serialize(groups);
  }

  /* Copies the passive set donorSetId (already inside p) into targetSetId: abilities and the
     in-game description are both combined. */
  function copyPassive(p, targetSetId, donorSetId, options = {}) {
    const sets = p.tables.passive_skill_sets || [], target = sets.find((s) => s.id === targetSetId), donor = sets.find((s) => s.id === donorSetId);
    if (!target || !donor) throw new Error("This passive could not be found. Choose the character again.");
    const donorText = donor.itemized_description || "", report = mergeSets(p, targetSetId, donorSetId, options);
    const text = mergeText(target.itemized_description || "", donorText, options);
    target.itemized_description = text.text;
    report.textNotes = text.notes;
    report.setId = targetSetId;
    return report;
  }
  // Short summary for the person, e.g. after copying.
  function summary(report) {
    const out = [];
    if (report.merged.length) out.push("Combined " + report.merged.length + (report.merged.length === 1 ? " matching ability" : " matching abilities") + ": " + report.merged.map((m) => m.text).join("; ") + ".");
    if (report.added.length) out.push("Added " + report.added.length + (report.added.length === 1 ? " new ability" : " new abilities") + ".");
    const capped = [...report.merged.flatMap((m) => m.notes)];
    if (capped.length) out.push("Kept within today's meta: " + capped.map((n) => n.field + " " + n.wanted + " → " + n.kept).join(", ") + ".");
    if (report.duplicates) out.push(report.duplicates + (report.duplicates === 1 ? " ability was" : " abilities were") + " already on your passive.");
    if (report.skipped.length) out.push("Not copied: " + report.skipped.join("; ") + ".");
    return out.join(" ");
  }

  /* Keeps a passive's written description in step with its abilities without rewriting it:
     lines for added abilities are inserted under their heading, changed ones are updated in place
     (keeping the game's wording when only the amounts changed) and removed ones are taken out.
     lineOf(row) → [heading, line], or null while something (conditions) is still loading.
     The last known lines are kept in p.builderLines[setId]. Returns true when the text changed. */
  function syncText(p, set, rows, lineOf) {
    const now = {};
    for (const row of rows) { const pair = lineOf(row); if (!pair) return false; now[row.id] = pair; }
    p.builderLines = p.builderLines || {};
    const before = set.itemized_description || "";
    let prev = p.builderLines[set.id];
    if (!prev) {
      // A passive copied for one awakening stage (same text) inherits what its original knew, so
      // an ability added right after the copy is still recognised as new.
      const sets = p.tables.passive_skill_sets || [];
      const sibling = Object.entries(p.builderLines).find(([id]) => id !== String(set.id) && (sets.find((x) => String(x.id) === id) || {}).itemized_description === before);
      if (sibling) {
        const pool = Object.values(sibling[1]).map((pair) => pair.join("\u0000"));
        prev = {};
        for (const [id, pair] of Object.entries(now)) { const at = pool.indexOf(pair.join("\u0000")); if (at >= 0) { prev[id] = pair; pool.splice(at, 1); } }
      }
    }
    if (prev) {
      let text = before;
      for (const id of Object.keys(prev)) if (!now[id]) { const t = removeLine(text, prev[id][0], prev[id][1]); if (t != null) text = t; }
      for (const id of Object.keys(now)) {
        if (!prev[id]) text = insertLine(text, now[id][0], now[id][1]);
        else if (prev[id][0] !== now[id][0] || prev[id][1] !== now[id][1]) {
          const t = replaceLine(text, prev[id][0], prev[id][1], now[id][0], now[id][1]);
          text = t != null ? t : insertLine(text, now[id][0], now[id][1]);
        }
      }
      if (text !== before) set.itemized_description = text;
    }
    p.builderLines[set.id] = now;
    return (set.itemized_description || "") !== before;
  }

  // ------------------------------------------------------------ organize & balance
  /* Cleans up a passive that was built from many copies (for example every version of a character):
     1. exact copies become one; the same ability at the same moment (same timing, condition,
        target, duration, chance, once-only) is added together;
     2. ATK, DEF and ATK & DEF boosts at the same moment become one "ATK & DEF" ability, and the
        Ki boosts at that moment become one;
     3. a guaranteed effect (e.g. "Guards all attacks") replaces weaker chances of the same effect
        at the same moment;
     4. every combined amount stays within META (one moment) and the whole passive within
        META.total (every condition at once): conditional boosts are lowered evenly if needed,
        the Basic effect(s) are kept.
     The in-game description is organized the same way, keeping the game's own wording for
     everything else. Returns a report (what was combined, capped and lowered). */
  // At the start of each turn, "this turn" (1) and "rest of the battle" (99) both mean "always on".
  // Only for plain always-on boosts: with a condition or once-only, 1 turn and the rest of the battle differ.
  const turnOf = (row) => Number(row.exec_timing_type) === 1 && !cond(row) && !Number(row.is_once) && [1, 99].includes(Number(row.turn)) ? "always" : row.turn;
  const momentSig = (row) => [row.exec_timing_type, row.target_type, Number(row.sub_target_type_set_id) || 0, turnOf(row), row.probability, Number(row.is_once) || 0, cond(row)].join("|");
  const flagSig = (row) => [row.efficacy_type, row.exec_timing_type, row.target_type, Number(row.sub_target_type_set_id) || 0, row.turn, Number(row.is_once) || 0, cond(row), values(row), row.eff_value1, row.eff_value2, row.eff_value3].join("|");
  function detach(p, setId, row) {
    p.tables.passive_skill_set_relations = (p.tables.passive_skill_set_relations || []).filter((r) => !(r.passive_skill_set_id === setId && r.passive_skill_id === row.id));
    if (!(p.tables.passive_skill_set_relations || []).some((r) => r.passive_skill_id === row.id)) Forge.removePassive(p, row.id);
  }
  const isBasic = (row) => Number(row.exec_timing_type) === 1 && !cond(row);
  function organizeRows(p, setId) {
    const report = { before: setRows(p, setId).length, combined: [], duplicates: 0, capped: [], dropped: [], lowered: [] };
    // 1. exact copies and same-ability sums
    let changed = true;
    while (changed) {
      changed = false;
      const rows = setRows(p, setId);
      outer: for (let i = 0; i < rows.length; i++) for (let j = i + 1; j < rows.length; j++) {
        const how = sameAbility(rows[i], rows[j]);
        if (!how) continue;
        if (how === "duplicate") report.duplicates++;
        else { const notes = addInto(ownRow(p, setId, rows[i]), rows[j]); report.combined.push(describe(setRows(p, setId).find((r) => r.id === rows[i].id) || rows[i])); report.capped.push(...notes); }
        detach(p, setId, rows[j]);
        changed = true;
        break outer;
      }
    }
    // 2. ATK / DEF / ATK & DEF and Ki at the same moment
    const buckets = new Map();
    for (const row of setRows(p, setId)) {
      const d = decoded(row);
      if (!d || !["atk", "def", "atkdef", "ki"].includes(d.key)) continue;
      const k = momentSig(row) + "|" + (d.key === "ki" ? "ki" : "stat") + "|" + row.calc_option;
      if (!buckets.has(k)) buckets.set(k, []);
      buckets.get(k).push({ row, d });
    }
    for (const list of buckets.values()) {
      if (list.length < 2) continue;
      const first = list[0], s = B.settingsOf(first.row), who = scope(s.target);
      let key, vals;
      if (first.d.key === "ki") {
        const raw = list.reduce((n, x) => n + Number(x.d.values.amount), 0), cap = who === "self" ? META.ki.self : META.ki.team;
        key = "ki"; vals = { amount: Math.min(raw, cap) };
        if (raw > cap) report.capped.push({ field: "Ki", wanted: raw, kept: cap });
      } else {
        let atk = 0, def = 0;
        for (const x of list) { if (x.d.key === "atkdef") { atk += Number(x.d.values.atk); def += Number(x.d.values.def); } else if (x.d.key === "atk") atk += Number(x.d.values.amount); else def += Number(x.d.values.amount); }
        const cap = META.stat[who] || META.stat.self, A = Math.min(atk, cap), D = Math.min(def, cap);
        if (A < atk) report.capped.push({ field: "ATK", wanted: atk, kept: A });
        if (D < def) report.capped.push({ field: "DEF", wanted: def, kept: D });
        key = A && D ? "atkdef" : A ? "atk" : "def"; vals = key === "atkdef" ? { atk: A, def: D } : { amount: A || D };
      }
      const keep = ownRow(p, setId, first.row);
      rewrite(keep, key, vals, s);
      for (const x of list.slice(1)) detach(p, setId, x.row);
      report.combined.push(describe(keep));
    }
    // 2b. flat ATK / DEF boosts from older cards (no %) at the same moment become one
    const flat = new Map();
    for (const row of setRows(p, setId)) {
      if (![1, 2, 3].includes(Number(row.efficacy_type)) || Number(row.calc_option) !== 0 || scope(row.target_type) !== "self" || values(row)) continue;
      const k = momentSig(row);
      if (!flat.has(k)) flat.set(k, []);
      flat.get(k).push(row);
    }
    for (const list of flat.values()) {
      if (list.length < 2) continue;
      let atk = 0, def = 0;
      for (const r of list) { const t = Number(r.efficacy_type); if (t === 1) atk += Number(r.eff_value1) || 0; else if (t === 2) def += Number(r.eff_value1) || 0; else { atk += Number(r.eff_value1) || 0; def += Number(r.eff_value2) || 0; } }
      const cap = META.flat, A = Math.min(atk, cap), D = Math.min(def, cap), keep = ownRow(p, setId, list[0]);
      if (A < atk || D < def) report.capped.push({ field: "flat ATK/DEF", wanted: Math.max(atk, def), kept: Math.max(A, D) });
      Object.assign(keep, A && D ? { efficacy_type: 3, eff_value1: A, eff_value2: D, eff_value3: 0 } : A ? { efficacy_type: 1, eff_value1: A, eff_value2: 0, eff_value3: 0 } : { efficacy_type: 2, eff_value1: D, eff_value2: 0, eff_value3: 0 });
      for (const r of list.slice(1)) detach(p, setId, r);
      report.combined.push("flat ATK/DEF");
    }
    // the same ability at one moment never goes past the meta, even split over several rows
    report.fitted = fitToMeta(p, setId);
    // 3. a guaranteed effect makes weaker chances of the same effect at the same moment pointless
    const flags = new Map();
    for (const row of setRows(p, setId)) {
      const d = decoded(row);
      if (!d || !FLAGS.has(d.key) || Number(row.probability) <= 0) continue;
      const k = flagSig(row);
      if (!flags.has(k)) flags.set(k, []);
      flags.get(k).push(row);
    }
    for (const list of flags.values()) {
      if (list.length < 2) continue;
      list.sort((a, b) => Number(b.probability) - Number(a.probability));
      for (const row of list.slice(1)) { report.dropped.push(describe(row) + " (" + describe(list[0]) + " already covers it)"); detach(p, setId, row); }
    }
    // 4. whole-passive budget: lower conditional ATK / DEF / Ki evenly
    for (const [field, keys, limit] of [["atk", ["atk", "atkdef"], META.total.stat], ["def", ["def", "atkdef"], META.total.stat], ["ki", ["ki"], META.total.ki]]) {
      const items = [];
      for (const row of setRows(p, setId)) {
        const d = decoded(row);
        if (!d || !keys.includes(d.key) || scope(row.target_type) !== "self" || Number(row.calc_option) !== Number(d.def.calc)) continue;
        const name = d.key === "atkdef" ? field : "amount";
        items.push({ row, d, name, value: Number(d.values[name]), basic: isBasic(row) });
      }
      const total = items.reduce((n, x) => n + x.value, 0), base = items.filter((x) => x.basic).reduce((n, x) => n + x.value, 0), extra = total - base;
      if (total <= limit || extra <= 0) continue;
      const factor = Math.max(0, (limit - base) / extra);
      let now = total;
      for (const x of items.filter((x) => !x.basic)) {
        const step = field === "ki" ? 1 : 5, min = field === "ki" ? 1 : 5;
        const next = Math.max(min, Math.floor(x.value * factor / step) * step);
        if (next >= x.value) continue;
        const mine = ownRow(p, setId, x.row), d = decoded(mine);
        d.values[x.name] = next;
        rewrite(mine, d.key, d.values);
        now -= x.value - next;
      }
      // already as low as each boost can go (the smallest step): nothing more to do without removing abilities
      if (now < total) report.lowered.push({ field: field === "ki" ? "Ki" : field.toUpperCase(), total, now, limit, factor });
    }
    report.after = setRows(p, setId).length;
    return report;
  }
  // ---- the description, in the game's own wording
  const STAT_PART = /^(ki) \+?(\d+)$|^(atk & def|atk|def) \+?(\d+)(%?)$/;
  // "Ki +3 and ATK & DEF 200%" → {ki:3, atk:200, def:200}; null for anything with other words
  function statAtoms(line) {
    const raw = String(line);
    if (/\{passiveImg:(once|forever|down_[a-z]+)\}/i.test(raw) || /[−-]\s*\d|\b(lowers?|reduc)/i.test(raw)) return null;
    const text = clean(raw);
    if (!text) return null;
    const out = { ki: 0, atk: 0, def: 0, fatk: 0, fdef: 0 };
    for (const part of text.split(/\s+and\s+|,\s*/)) {
      const m = part.trim().match(STAT_PART);
      if (!m) return null;
      if (m[1]) out.ki += Number(m[2]);
      else { const v = Number(m[4]), flat = !m[5]; if (m[3] !== "def") out[flat ? "fatk" : "atk"] += v; if (m[3] !== "atk") out[flat ? "fdef" : "def"] += v; }
    }
    return out;
  }
  // "Ki +3 and ATK & DEF 200%", "Ki +3, ATK 120% and DEF 80%" (official wording, with arrows)
  function statLine(t, official) {
    const pct = (n) => official ? n + "%{passiveImg:up_g}" : "+" + n + "%", flat = (n) => official ? n + "{passiveImg:up_g}" : "+" + n;
    const parts = [];
    if (t.ki) parts.push("Ki +" + t.ki);
    if (t.atk && t.atk === t.def) parts.push("ATK & DEF " + pct(t.atk));
    else { if (t.atk) parts.push("ATK " + pct(t.atk)); if (t.def) parts.push("DEF " + pct(t.def)); }
    if (t.fatk && t.fatk === t.fdef) parts.push("ATK & DEF " + flat(t.fatk));
    else { if (t.fatk) parts.push("ATK " + flat(t.fatk)); if (t.fdef) parts.push("DEF " + flat(t.fdef)); }
    return parts.length > 2 ? parts.slice(0, -1).join(", ") + " and " + parts[parts.length - 1] : parts.join(" and ");
  }
  const CHANCE = { rare: 1, medium: 2, high: 3, great: 4 };
  const CERTAIN = [[/^guards all attacks$/, /chance of guarding all attacks$/], [/^evades enemy's attack( \(including super attack\))?$/, /chance of evading enemy's attack/], [/^performs a critical hit$/, /chance of performing a critical hit$/]];
  function organizeText(text, report = {}) {
    const groups = [], notes = report.textNotes = [];
    for (const g of parse(text)) { const m = groups.find((x) => headingKey(x.heading) === headingKey(g.heading)); if (m) m.lines.push(...g.lines); else groups.push({ heading: g.heading, lines: g.lines.slice() }); }
    const basicKey = "basic effect s";
    for (const g of groups) {
      // exact copies once; same wording → amounts added (within limits); at most 2 additional attacks
      const out = [];
      for (const line of g.lines) {
        if (additionalLine(line)) { if (out.filter(additionalLine).length < META.additionalPerMoment) out.push(line); continue; }
        if (out.some((l) => clean(l) === clean(line)) && !amounts(line).some((x) => x.amount)) continue;
        const i = out.findIndex((l) => !additionalLine(l) && shape(l) === shape(line));
        if (i >= 0) { if (amounts(line).some((x) => x.amount)) out[i] = sumLine(out[i], line, notes); continue; }
        out.push(line);
      }
      // plain Ki / ATK / DEF lines become one line at the top of the heading
      const stats = out.map(statAtoms), count = stats.filter(Boolean).length;
      let lines = out;
      if (count > 1) {
        const t = stats.reduce((a, x) => x ? { ki: a.ki + x.ki, atk: a.atk + x.atk, def: a.def + x.def, fatk: a.fatk + x.fatk, fdef: a.fdef + x.fdef } : a, { ki: 0, atk: 0, def: 0, fatk: 0, fdef: 0 });
        const capped = { ki: Math.min(t.ki, META.ki.self), atk: Math.min(t.atk, META.stat.self), def: Math.min(t.def, META.stat.self), fatk: Math.min(t.fatk, META.flat), fdef: Math.min(t.fdef, META.flat) };
        for (const f of ["ki", "atk", "def"]) if (capped[f] < t[f]) notes.push({ field: f === "ki" ? "Ki" : f.toUpperCase(), wanted: t[f], kept: capped[f] });
        lines = [statLine(capped, out.some((l) => /\{passiveImg:/i.test(l)))].concat(out.filter((l, i) => !stats[i]));
      }
      // a guaranteed effect makes weaker chances of it pointless; otherwise the best chance stays
      const low = lines.map((l) => clean(l).replace(/^\{passiveimg:[a-z_]+\}/, ""));
      g.lines = lines.filter((l, i) => {
        for (const [sure, maybe] of CERTAIN) {
          if (!maybe.test(low[i])) continue;
          if (low.some((x) => sure.test(x))) return false;
          const word = (low[i].match(/^(rare|medium|high|great) chance/) || [])[1];
          if (word && low.some((x, k) => k !== i && maybe.test(x) && CHANCE[(x.match(/^(rare|medium|high|great) chance/) || [])[1]] > CHANCE[word])) return false;
        }
        return true;
      });
      g.basic = headingKey(g.heading) === basicKey;
    }
    // the same even lowering as the abilities: conditional plain ATK / DEF lines
    for (const low of report.lowered || []) {
      for (const g of groups) {
        // growth headings ("for every Ki Sphere obtained", "per ally…") are not lowered as abilities either
        if (g.basic || /\b(per|for every|each|every time)\b/i.test(g.heading || "")) continue;
        g.lines = g.lines.map((l) => {
          const a = statAtoms(l);
          if (!a) return l;
          const f = low.factor, cut = (n) => n ? Math.min(n, Math.max(5, Math.floor(n * f / 5) * 5)) : 0, cutKi = (n) => n ? Math.min(n, Math.max(1, Math.floor(n * f))) : 0;
          const next = Object.assign({}, a, { ki: low.field === "Ki" ? cutKi(a.ki) : a.ki, atk: low.field === "ATK" ? cut(a.atk) : a.atk, def: low.field === "DEF" ? cut(a.def) : a.def });
          return statLine(next, /\{passiveImg:/i.test(l));
        });
      }
    }
    groups.sort((a, b) => (b.basic ? 1 : 0) - (a.basic ? 1 : 0));
    return serialize(groups);
  }
  function organize(p, setId) {
    const set = (p.tables.passive_skill_sets || []).find((s) => s.id === setId);
    if (!set) throw new Error("This passive could not be found.");
    const beforeText = set.itemized_description || "", report = organizeRows(p, setId);
    // combining can line up new matches (amounts and durations become equal), so repeat until settled
    for (let pass = 0; pass < 4; pass++) {
      const more = organizeRows(p, setId);
      if (more.after === more.before && !more.combined.length && !more.dropped.length && !more.duplicates) break;
      report.after = more.after; report.duplicates += more.duplicates; report.combined.push(...more.combined); report.dropped.push(...more.dropped); report.capped.push(...more.capped); report.fitted = (report.fitted || []).concat(more.fitted || []); report.lowered.push(...more.lowered);
    }
    if (beforeText.trim()) set.itemized_description = organizeText(beforeText, report);
    report.linesBefore = beforeText ? parse(beforeText).reduce((n, g) => n + g.lines.length, 0) : 0;
    report.linesAfter = set.itemized_description ? parse(set.itemized_description).reduce((n, g) => n + g.lines.length, 0) : 0;
    report.text = set.itemized_description || "";
    return report;
  }
  function organizeSummary(r) {
    const out = [r.before + " abilities → " + r.after + (r.linesBefore ? "; description " + r.linesBefore + " lines → " + r.linesAfter : "") + "."];
    if (r.duplicates) out.push(r.duplicates + " exact cop" + (r.duplicates === 1 ? "y" : "ies") + " merged into one.");
    if (r.combined.length) out.push(r.combined.length + " group" + (r.combined.length === 1 ? "" : "s") + " of matching boosts combined.");
    if (r.dropped.length) out.push(r.dropped.length + " weaker chance" + (r.dropped.length === 1 ? "" : "s") + " removed because a guaranteed version already exists.");
    const caps = r.capped.concat(r.textNotes || []).filter((n) => n.field);
    if ((r.fitted || []).length) out.push("Kept within today's meta: " + r.fitted.slice(0, 8).join(", ") + ".");
    if (caps.length) out.push("Capped at today's meta for one moment: " + [...new Set(caps.map((n) => (n.field || "") + " " + n.wanted + " → " + n.kept))].slice(0, 8).join(", ") + ".");
    const first = {}, last = {};
    for (const l of r.lowered) { if (!(l.field in first)) first[l.field] = l; last[l.field] = l; }
    for (const f of Object.keys(first)) {
      const u = f === "Ki" ? "" : "%", a = first[f], b = last[f], now = b.now == null ? b.limit : b.now;
      out.push("Whole passive " + f + " was " + a.total + u + " with every condition met (today's meta: about " + a.limit + u + "), so conditional " + f + " boosts were lowered evenly to " + now + u + "." + (now > a.limit ? " Each is now at its smallest step" + (f === "Ki" ? "; the game also caps Ki at 12 (24 for LRs) on its own." : ".") : ""));
    }
    return out;
  }

  // A copy of a donor unit that holds only one of its passives (e.g. the EZA one), so adding it
  // to yours doesn't also bring the donor's other passives along as unused rows.
  function onlySet(donor, setId) {
    const t = donor.tables || {}, rel = (t.passive_skill_set_relations || []).filter((r) => r.passive_skill_set_id === setId), ids = new Set(rel.map((r) => r.passive_skill_id));
    const tables = Object.assign({}, t, { passive_skill_sets: (t.passive_skill_sets || []).filter((x) => x.id === setId), passive_skill_set_relations: rel, passive_skills: (t.passive_skills || []).filter((r) => ids.has(r.id)) });
    if (t.passive_skill_set_additions) tables.passive_skill_set_additions = [];
    if (t.dokkan_field_passive_skill_relations) tables.dokkan_field_passive_skill_relations = t.dokkan_field_passive_skill_relations.filter((r) => ids.has(r.passive_skill_id));
    return Object.assign({}, donor, { tables });
  }

  return { META, onlySet, capOf, copyPassive, organize, organizeRows, organizeText, organizeSummary, summary, syncText, sameAbility, mergeSets, absorb, balanceIssues, fitToMeta, setRows, parse, serialize, mergeText, insertLine, replaceLine, removeLine, shape, amounts };
});
