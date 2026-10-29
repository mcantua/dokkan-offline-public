// Exercises ForgeBuilder end to end: build a unit from scratch abilities, export SQL, apply it.
process.removeAllListeners("warning");
const UI = "/home/claude/work/apk/assets/ui/";
const Forge = require(UI + "core.js");
global.Forge = Forge;
const G = require(UI + "guide-model.js");
const B = require(UI + "builder-model.js");
const fs = require("fs");
const { open } = require("./node_db");
const assert = (c, m) => { if (!c) throw new Error("ASSERT: " + m); };
const profiles = JSON.parse(fs.readFileSync(UI + "data/damage-profiles.json", "utf8"));

(async () => {
  const { schema, query, db } = open();
  const cats = new Map(db.prepare("select id,name from card_categories").all().map((r) => [r.id, r.name]));
  const names = { category: (id) => cats.get(Number(id)) };
  const official = db.prepare("select * from sub_target_types").all().map((r) => ({ ...r }));
  const sourceId = Number(process.argv[2] || 1018721);
  const p = await Forge.loadTemplate(query, schema, sourceId, 97000001);
  await Forge.hydrateAbilityAnimations(p, query, schema);

  // Leader: decode official, then build a multi-tier category leader from scratch.
  const card = Forge.card(p);
  const lrows = p.tables.leader_skills.filter((r) => r.leader_skill_set_id === card.leader_skill_set_id);
  const subIds = [...new Set(lrows.map((r) => r.sub_target_type_set_id).filter(Boolean))];
  const subRows = official.filter((r) => subIds.includes(r.sub_target_type_set_id));
  console.log("decoded source leader:", JSON.stringify(B.decodeLeader(lrows, subRows)));
  const groups = [
    { who: "categories", categories: [16, 7], ki: 3, hp: 170, atk: 170, def: 170 },
    { who: "categories", categories: [16, 7], also: [77, 23], ki: 1, hp: 30, atk: 30, def: 30 },
    { who: "types", types: [2], ki: 2, hp: 50, atk: 50, def: 50 },
    { who: "categories", categories: [1, 2, 3], also: [5], ki: 1, hp: 10, atk: 20, def: 10 },
    { who: "classTypes", classTypes: [4096, 262144], ki: 1, hp: 10, atk: 10, def: 10 },
    { who: "all", ki: 0, hp: 100, atk: 120, def: 100 }
  ];
  const set = B.buildLeader(p, schema, groups, { official, names, name: "" });
  console.log("leader:", set.name, "|", set.description);
  const mine = p.tables.leader_skills.filter((r) => r.leader_skill_set_id === set.id);
  const back = B.decodeLeader(mine, [...official, ...(p.tables.sub_target_types || [])]);
  assert(back && back.length === 6, "leader round trip " + JSON.stringify(back));
  console.log("leader rows", mine.length, "local sub sets", (p.tables.sub_target_type_sets || []).length);

  // Passive from scratch.
  const passiveSet = Forge.primaryPassive(p);
  p.tables.passive_skill_set_relations = p.tables.passive_skill_set_relations.filter((r) => r.passive_skill_set_id !== passiveSet.id);
  const a = B.addPassiveAbility(p, "atkdef", { atk: 150, def: 120 });
  const b = B.addPassiveAbility(p, "ki", { amount: 3 });
  const c = B.addPassiveAbility(p, "dr", { amount: 40 }, { timing: 1, target: 1, turn: 1, chance: 100 });
  B.applyCondition(p, schema, c, { mode: "all", items: [{ key: "hpBelow", values: { hp: 50 } }] });
  const d = B.addPassiveAbility(p, "stack", { stat: 0, step: 20, max: 100, trigger: 5 });
  const e = B.addPassiveAbility(p, "stun", {}, { timing: 5, target: 3, chance: 30, turn: 1 });
  const f = B.addPassiveAbility(p, "additional", { super: 50 });
  B.applyCondition(p, schema, f, { mode: "any", items: [{ key: "turn", values: { turn: 4 } }, { key: "allies", values: { category: 16, count: 3 } }] });
  const g = B.addPassiveAbility(p, "typeKi", { type: 3, amount: 2 }, { target: 2 });
  for (const row of [a, b, c, d, e, f, g]) assert(B.decodePassive(row), "decode " + row.efficacy_type);
  const lookup = (id) => (p.tables.skill_causalities || []).find((r) => r.id === id);
  const describe = (row) => B.conditionText(B.decodeCondition(row.causality_conditions, lookup), names);
  const rows = p.tables.passive_skills.filter((r) => p.tables.passive_skill_set_relations.some((x) => x.passive_skill_id === r.id && x.passive_skill_set_id === passiveSet.id));
  console.log(B.passiveText(rows, describe));
  const cond = B.decodeCondition(f.causality_conditions, lookup);
  assert(cond && cond.mode === "any" && cond.items.length === 2, "condition round trip " + JSON.stringify(cond));

  // Super attacks.
  for (const rel of p.tables.card_specials) {
    const s = p.tables.special_sets.find((x) => x.id === rel.special_set_id);
    console.log("source SA", rel.style, s.name, "|", B.superText(s, p.tables.specials.filter((x) => x.special_set_id === s.id), profiles), "| official:", s.description.replace(/\n/g, " "));
  }
  const hasHyper = p.tables.card_specials.some((r) => r.style === "Hyper");
  const ultra = B.createSuper(p, schema, { name: "Test Ultra", style: "Hyper", ki: 18, profile: profiles.find((x) => x.key === "mega-colossal"), profiles, effects: [{ key: "atk", values: { amount: 100 }, settings: { target: 1, turn: 99 } }, { key: "defDown", values: { amount: 50 }, settings: { turn: 3 } }, { key: "stun", settings: { chance: 30 } }, { key: "atkdef", values: { atk: 20, def: 20 }, settings: { target: 16, turn: 2 } }] });
  console.log("new ultra:", ultra.set.description, hasHyper ? "(source already had Hyper)" : "");

  // Active skill (attack + effects) and a passive transformation into an official card.
  const view = db.prepare("select special_view_id, bgm_id from active_skill_sets where id=388").get();
  if (!(p.tables.card_active_skills || []).length) {
    const act = B.createActive(p, schema, { name: "Test Burst", viewId: view.special_view_id, bgmId: view.bgm_id, attack: { boost: 300, allEnemies: false }, effects: [{ key: "atkdef", values: { atk: 50, def: 50 }, target: 2 }, { key: "ki", values: { amount: 6 }, target: 1 }] });
    B.applyCondition(p, schema, act, { mode: "all", items: [{ key: "entryTurn", values: { turn: 3 } }] });
    act.effect_description = B.activeText(p, act, profiles);
    act.condition_description = B.activeConditionText(describe(act), act);
    console.log("active:", act.effect_description, "|", act.condition_description);
  }
  const exRow = (await query({ table: "passive_skills", ids: [1998] }))[0];
  const exParams = await query({ table: "battle_params", filters: { param_no: exRow.eff_value3 }, limit: 50 });
  const tr = B.addPassiveTransformation(p, schema, { exemplar: { row: exRow, params: exParams }, targetId: 4018730, name: "Power Unleashed", condition: { mode: "all", items: [{ key: "turn", values: { turn: 4 } }] }, description: "Transforms starting from the 4th turn from the start of battle" });
  console.log("transform row", tr.id, "desc rows", (p.tables.transformation_descriptions || []).length);

  const check = Forge.validate(p);
  console.log("validate errors:", check.errors, "warnings:", check.warnings.length);
  assert(!check.errors.length, "validation");
  const sql = Forge.sql(p);
  fs.writeFileSync(process.argv[3] || "/tmp/claude-0/builder_test.sql", sql);
  const tables = Forge.materialize(p);
  console.log("materialized tables:", Object.entries(tables).map(([t, r]) => t + ":" + r.length).join(" "));
  console.log("OK");
})().catch((e) => { console.error(e.stack || e); process.exit(1); });
