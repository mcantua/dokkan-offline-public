// Round-trip checks for every builder catalog entry.
process.removeAllListeners("warning");
const UI = "/home/claude/work/apk/assets/ui/";
global.Forge = require(UI + "core.js");
const B = require(UI + "builder-model.js");
const { open } = require("./node_db");
const assert = (c, m) => { if (!c) throw new Error(m); };
(async () => {
  const { schema, query } = open();
  const p = await Forge.loadTemplate(query, schema, 1002841, 97000001);
  let n = 0;
  for (const def of B.PASSIVE) for (const target of B.allowedTargets(def)) for (const timing of [1, 4, 7]) {
    const values = {};
    for (const f of def.fields) values[f.name] = f.kind === "choice" ? f.options[f.options.length - 1][0] : Math.min(f.max, Math.max(f.min, 37));
    if (def.key === "sphereChange") values.from = 1;
    const row = B.addPassiveAbility(p, def.key, values, { target, timing, turn: 3, chance: 60, once: true });
    const d = B.decodePassive(row);
    assert(d && d.key === def.key, "decode " + def.key + " got " + JSON.stringify(d));
    const back = B.normalizeValues(def.fields, d.values), want = B.normalizeValues(def.fields, values);
    if (def.key !== "stack") assert(JSON.stringify(back) === JSON.stringify(want), "values " + def.key + JSON.stringify([back, want]));
    assert(B.passiveLine(row).length > 3, "line");
    n++;
  }
  for (const c of B.CONDITIONS) {
    const values = B.conditionDefaults(c.key);
    if (c.fields.some((f) => f.kind === "category")) values.category = 16;
    const rule = B.conditionRule({ key: c.key, values });
    const m = B.matchCondition({ causality_type: rule.type, cau_val1: rule.values[0], cau_val2: rule.values[1], cau_val3: rule.values[2] });
    assert(m && m.key === c.key, "condition " + c.key + " -> " + JSON.stringify(m));
    n++;
  }
  B.createSuper(p, schema, { name: "x", style: "Normal", ki: 12, viewId: 6165, effects: [] });
  const set = p.tables.special_sets[p.tables.special_sets.length - 1];
  for (const def of B.SA_EFFECTS) for (const target of B.SA_TARGETS[def.targets]) {
    const row = B.addSpecialEffect(p, set.id, def.key, {}, { target, turn: 2 });
    const d = B.decodeSpecial(row);
    assert(d && d.key === def.key, "special " + def.key + JSON.stringify(d));
    assert(B.specialPhrase(row).text, "phrase " + def.key);
    n++;
  }
  const act = B.createActive(p, schema, { name: "a", viewId: 20425, attack: { boost: 50 } });
  for (const def of B.ACTIVE_EFFECTS) for (const t of B.ACTIVE_TARGETS[def.targets]) {
    const values = {}; if (def.key === "sphereChange") values.from = 1;
    const row = B.addActiveEffect(p, act.id, def.key, values, t);
    const d = B.decodeActive(row);
    assert(d && d.key === def.key, "active " + def.key + JSON.stringify(d));
    n++;
  }
  console.log("activeText:", B.activeText(p, act));
  console.log("superText:", B.superText(set, p.tables.specials.filter((r) => r.special_set_id === set.id), []));
  const check = Forge.validate(p);
  assert(!check.errors.length, check.errors.join(";"));
  require("fs").writeFileSync("/tmp/claude-0/fuzz.sql", Forge.sql(p));
  console.log("round trips OK:", n);
})().catch((e) => { console.error(e.stack || e); process.exit(1); });
