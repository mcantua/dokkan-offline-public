/* Source-bound normalizer for our original local battle engine. No rows/assets embedded. */
(function (root, factory) {
  if (typeof module === 'object' && module.exports) module.exports = factory();
  else root.OfflineDokkanSourceRoster = factory();
})(typeof globalThis !== 'undefined' ? globalThis : this, function () {
  'use strict';
  const POLICY = 'source-anchors-and-sa-linear-floor-v1', PPM = 1000000;
  const BATTLE_POLICY = 'offline-turn-battle-source-v2', STAT_PHASE_POLICY = 'percent-then-flat-by-phase-v1';
  const record = x => x && typeof x === 'object' && !Array.isArray(x);
  const integer = (v, low = 0, high = Number.MAX_SAFE_INTEGER) => Number.isSafeInteger(v) && v >= low && v <= high;
  const emptyCondition = x => x === null || x === undefined || x === '';
  const zero = x => x === null || x === undefined || x === 0;
  const copied = x => JSON.parse(JSON.stringify(x));
  const allowed = {
    cards: ['id'], passive_skill_sets: ['id'], passive_skill_set_relations: ['passive_skill_set_id'],
    passive_skills: ['id'], leader_skill_sets: ['id'], leader_skills: ['leader_skill_set_id'], card_specials: ['card_id'],
    special_sets: ['id'], specials: ['special_set_id'], card_active_skills: ['card_id'],
    card_standby_skill_set_relations: ['card_id'], card_finish_skill_set_relations: ['card_id'],
    passive_skill_set_additions: ['card_id'], origin_battle_passive_skill_set_relations: ['card_id'], special_bonuses: ['id']
  };
  function error(code) { const e = new Error(code); e.code = code; throw e; }
  function sourceBattlePolicy(policy) {
    if (!record(policy) || policy.id !== BATTLE_POLICY || policy.statPhasePolicy !== STAT_PHASE_POLICY || !record(policy.classPolicy) || typeof policy.requireAnimations !== 'boolean') return false;
    if (!integer(policy.minimumDamage, 1, 1000) || !integer(policy.advantagePpm, PPM, 4 * PPM) || !integer(policy.disadvantagePpm, 1, PPM) || !integer(policy.criticalPpm, PPM, 4 * PPM)) return false;
    if (Object.keys(policy).some(key => !['id', 'minimumDamage', 'advantagePpm', 'disadvantagePpm', 'criticalPpm', 'requireAnimations', 'statPhasePolicy', 'classPolicy'].includes(key))) return false;
    const rule = policy.classPolicy;
    return Object.keys(rule).length === 5 && rule.id === 'static-class-v1' && ['apply', 'bypass'].includes(rule.critical) && ['samePpm', 'opposingPpm', 'neutralPpm'].every(key => integer(rule[key], 1, 4 * PPM));
  }
  function sourceClass(element) {
    if (!integer(element, 0, 24) || ![0, 1, 2, 3, 4, 10, 11, 12, 13, 14, 20, 21, 22, 23, 24].includes(element)) return null;
    return element < 10 ? 'neutral' : element < 20 ? 'super' : 'extreme';
  }
  function makeReport() {
    const unsupported = [], ledger = [], notes = [];
    function issue(field, code, value) {
      const item = {field, code}; if (value !== undefined) item.value = copied(value);
      unsupported.push(item);
    }
    function cover(field, translated) { ledger.push({field, translated}); }
    return {unsupported, ledger, notes, issue, cover};
  }
  function identity(source, contentId) {
    if (!record(source) || !['eclipse', 'sparking'].includes(source.provider) || source.contentId !== contentId || typeof source.query !== 'function' || typeof contentId !== 'string' || !/^[A-Za-z0-9_.:-]{1,127}$/.test(contentId)) error('SOURCE_CONTEXT_INVALID');
  }
  function reader(source, contentId, definition, report) {
    return async function rows(table, key, value) {
      identity(source, contentId);
      if (!allowed[table]?.includes(key) || !integer(value, -Number.MAX_SAFE_INTEGER)) error('SOURCE_QUERY_INVALID');
      let result;
      // A supplied definition table is its complete effective graph, not a
      // patch to which deleted master effects may be silently reintroduced.
      if (definition && Object.prototype.hasOwnProperty.call(definition.tables, table)) {
        const local = definition.tables[table];
        if (!Array.isArray(local) || local.length > 10000 || local.some(r => !record(r))) error('EFFECTIVE_TABLE_INVALID');
        result = local.filter(row => row[key] === value);
      } else {
        try { result = await source.query('SELECT * FROM "' + table + '" WHERE "' + key + '" = ? ORDER BY "id" LIMIT 1001', [value]); }
        catch (_) { report.issue(table, 'SOURCE_QUERY_UNAVAILABLE'); return []; }
        identity(source, contentId);
      }
      if (!Array.isArray(result) || result.length > 1000 || result.some(row => !record(row) || row[key] !== value || !integer(row.id, -Number.MAX_SAFE_INTEGER))) error('SOURCE_QUERY_RESULT_INVALID');
      if (new Set(result.map(row => row.id)).size !== result.length) error('SOURCE_QUERY_RESULT_DUPLICATE');
      return copied(result);
    };
  }
  function bindDefinition(definition, owned, contentId, report) {
    if (!definition) {
      if (owned.created_definition || owned.official_upgrade || owned.tournament_definition) report.issue('owned.effective_definition', 'EFFECTIVE_DEFINITION_REQUIRED');
      return null;
    }
    if (!record(definition) || !['offline-dokkan-definition', 'offline-dokkan-official-upgrade'].includes(definition.format) || definition.schema_version !== 1 || !record(definition.source) || definition.source.content_id !== contentId || definition.source.master_id !== owned.master_id || !record(definition.card) || definition.card.id !== owned.master_id || !record(definition.tables)) error('EFFECTIVE_DEFINITION_SOURCE_MISMATCH');
    if (owned.created_definition && (definition.definition_id !== owned.created_definition.definition_id || definition.version !== owned.created_definition.version)) error('EFFECTIVE_DEFINITION_VERSION_MISMATCH');
    if (owned.official_upgrade && definition.version !== owned.official_upgrade.version) error('EFFECTIVE_DEFINITION_VERSION_MISMATCH');
    return copied(definition);
  }
  async function loadBinding(source, contentId, binding, report) {
    if (!record(binding) || !record(binding.owned) || !integer(binding.owned.instance_id, 1) || !integer(binding.owned.master_id, 1)) error('OWNED_SOURCE_BINDING_REQUIRED');
    const owned = copied(binding.owned), definition = bindDefinition(binding.definition, owned, contentId, report);
    const read = reader(source, contentId, definition, report);
    // Root card always exists in the selected immutable master; a definition
    // may override its fields but cannot replace its origin identity.
    const roots = await reader(source, contentId, null, report)('cards', 'id', owned.master_id);
    if (roots.length !== 1) error('SOURCE_CARD_MISSING');
    const card = Object.assign({}, roots[0], definition ? definition.card : {});
    return {owned, definition, card, read};
  }
  function kiCurve(card, policy, report) {
    const fields = ['eball_mod_min', 'eball_mod_num100', 'eball_mod_mid', 'eball_mod_mid_num', 'eball_mod_max', 'eball_mod_max_num'];
    const raw = Object.fromEntries(fields.map(key => [key, card[key]]));
    if (policy !== POLICY) { report.issue('cards.eball_mod_*', 'KI_CURVE_POLICY_REQUIRED', raw); return {raw, policy: null, curve: null}; }
    if (fields.some(key => !integer(card[key], 0, 1000)) || ![12, 24].includes(card.eball_mod_max_num) || !integer(card.eball_mod_num100, 1, card.eball_mod_max_num) || card.eball_mod_min < 1 || card.eball_mod_max < 1) {
      report.issue('cards.eball_mod_*', 'KI_ANCHORS_UNSUPPORTED', raw); return {raw, policy, curve: null};
    }
    const anchors = [[0, card.eball_mod_min], [card.eball_mod_num100, 100], [card.eball_mod_max_num, card.eball_mod_max]];
    if (card.eball_mod_mid || card.eball_mod_mid_num) {
      if (!integer(card.eball_mod_mid_num, 1, card.eball_mod_max_num) || !integer(card.eball_mod_mid, 1, 1000)) { report.issue('cards.eball_mod_mid', 'KI_ANCHORS_UNSUPPORTED', raw); return {raw, policy, curve: null}; }
      anchors.push([card.eball_mod_mid_num, card.eball_mod_mid]);
    }
    anchors.sort((a, b) => a[0] - b[0]);
    const unique = [];
    for (const pair of anchors) {
      if (unique.length && unique.at(-1)[0] === pair[0]) {
        if (unique.at(-1)[1] !== pair[1]) { report.issue('cards.eball_mod_*', 'KI_ANCHORS_AMBIGUOUS', raw); return {raw, policy, curve: null}; }
      } else unique.push(pair);
    }
    if (unique.some((pair, index) => index && pair[1] < unique[index - 1][1])) { report.issue('cards.eball_mod_*', 'KI_ANCHORS_NONMONOTONIC', raw); return {raw, policy, curve: null}; }
    const curve = [];
    for (let ki = 0; ki <= card.eball_mod_max_num; ki++) {
      const high = unique.findIndex(pair => pair[0] >= ki), b = unique[high], a = unique[Math.max(0, high - 1)];
      const value = a[0] === b[0] ? BigInt(a[1]) * 10000n : BigInt(a[1]) * 10000n + BigInt(b[1] - a[1]) * BigInt(ki - a[0]) * 10000n / BigInt(b[0] - a[0]);
      curve.push(Number(value));
    }
    return {raw, anchors: unique, policy, curve, original_rounding_verified: false};
  }
  function exclusive(rows, stats, report) {
    const final = stats.final_exclusive;
    if (!record(final) || final.included_in_base !== false || final.apply_once_after_other_boosts !== true || ![0, 10, 20].includes(final.atk_percent) || final.atk_percent !== final.def_percent || final.atk_percent !== final.damage_reduction_percent || final.atk_percent > 0 && final.always_on !== true) {
      report.issue('stats.final_exclusive', 'EXCLUSIVE_BINDING_INVALID'); return {skip: new Set(), value: null};
    }
    const value = {atkPercent: final.atk_percent, defPercent: final.def_percent, damageReductionPercent: final.damage_reduction_percent};
    const named = rows.filter(row => ['Super Exclusive', 'Godly Exclusive', 'Level 200 Exclusive'].includes(row.name));
    if (!final.atk_percent) {
      if (named.length) report.issue('passive_skills.Exclusive', 'EXCLUSIVE_ROWS_WITHOUT_CORE_DESCRIPTOR', named.map(row => row.id));
      return {skip: new Set(), value};
    }
    const title = final.atk_percent === 10 ? 'Super Exclusive' : 'Godly Exclusive';
    const expected = [[1, 4, final.atk_percent], [2, 6, final.def_percent], [13, 6, 100 - final.damage_reduction_percent]];
    const valid = named.length === 3 && expected.every(([eff, timing, amount]) => named.filter(row => row.name === title && row.efficacy_type === eff && row.exec_timing_type === timing && row.eff_value1 === amount && row.eff_value2 === 0 && row.eff_value3 === 0 && row.calc_option === 2 && row.target_type === 1 && zero(row.sub_target_type_set_id) && row.probability === 100 && row.is_once === 0 && row.turn === 1 && emptyCondition(row.causality_conditions) && zero(row.exec_game_type) && zero(row.passive_skill_effect_id) && row.efficacy_values === '{}').length === 1);
    if (!valid) report.issue('passive_skills.Exclusive', 'EXCLUSIVE_ROWS_MISMATCH', named.map(row => row.id));
    return {skip: new Set(valid ? named.map(row => row.id) : []), value};
  }
  function passive(row, field, report, battlePolicy) {
    const issues = report.unsupported.length;
    const check = (condition, key, code) => { if (!condition) report.issue(field + '.' + key, code, row[key]); };
    check(emptyCondition(row.causality_conditions), 'causality_conditions', 'PASSIVE_CONDITION_UNSUPPORTED');
    check(row.target_type === 1, 'target_type', 'PASSIVE_TARGET_UNSUPPORTED');
    check(zero(row.sub_target_type_set_id), 'sub_target_type_set_id', 'PASSIVE_SUBTARGET_UNSUPPORTED');
    check(zero(row.exec_game_type), 'exec_game_type', 'PASSIVE_GAME_TYPE_UNSUPPORTED');
    check(zero(row.passive_skill_effect_id), 'passive_skill_effect_id', 'PASSIVE_SCRIPT_UNSUPPORTED');
    check(row.turn === 1 && row.is_once === 0, 'turn', 'PASSIVE_DURATION_UNSUPPORTED');
    check(row.probability === 100, 'probability', 'PASSIVE_ACTIVATION_CHANCE_UNSUPPORTED');
    check(row.efficacy_values === '{}' || row.efficacy_values === null, 'efficacy_values', 'PASSIVE_PARAMETERS_UNSUPPORTED');
    const stat = [1, 2, 3, 59, 60, 61].includes(row.efficacy_type);
    const flat = [1, 2, 3].includes(row.efficacy_type) && row.calc_option === 0;
    if (flat && !sourceBattlePolicy(battlePolicy)) report.issue(field + '.calc_option', 'FLAT_STAT_PHASE_POLICY_REQUIRED', row.calc_option);
    const supported = stat || [5, 13, 90, 91, 81].includes(row.efficacy_type);
    check(supported, 'efficacy_type', 'PASSIVE_EFFECT_UNSUPPORTED');
    const calc = flat || row.efficacy_type === 5 || row.efficacy_type === 81 ? 0 : 2;
    check(row.calc_option === calc, 'calc_option', 'PASSIVE_CALCULATION_UNSUPPORTED');
    const perSphere = [59, 60, 61].includes(row.efficacy_type);
    const phase = perSphere ? 'per_sphere' : row.exec_timing_type === 1 ? 'start' : stat && [4, 11].includes(row.exec_timing_type) ? 'on_attack' : null;
    check(phase !== null && (!perSphere || row.exec_timing_type === 1), 'exec_timing_type', 'PASSIVE_PHASE_UNSUPPORTED');
    check(integer(row.eff_value1, 0, flat ? 2147483647 : stat ? 10000 : row.efficacy_type === 5 ? 24 : 100), 'eff_value1', 'PASSIVE_VALUE_UNSUPPORTED');
    check(integer(row.eff_value2, 0, flat ? 2147483647 : 10000) && ([3, 61].includes(row.efficacy_type) || row.eff_value2 === 0), 'eff_value2', 'PASSIVE_VALUE_UNSUPPORTED');
    check(row.eff_value3 === 0, 'eff_value3', row.efficacy_type === 81 ? 'ADDITIONAL_SUPER_UNSUPPORTED' : 'PASSIVE_VALUE_UNSUPPORTED');
    if (report.unsupported.length !== issues) { report.cover(field, false); return []; }
    const base = {phase, id: field.replace(/[\[\]]/g, '.')};
    let effects;
    if (stat) {
      effects = [];
      if ([1, 3, 59, 61].includes(row.efficacy_type)) effects.push({...base, id: base.id + '.atk', kind: flat ? 'atk_flat' : 'atk_percent', value: row.eff_value1});
      if ([2, 3, 60, 61].includes(row.efficacy_type)) effects.push({...base, id: base.id + '.def', kind: flat ? 'def_flat' : 'def_percent', value: [3, 61].includes(row.efficacy_type) ? row.eff_value2 : row.eff_value1});
    } else {
      const kind = {5: 'ki', 13: 'damage_reduction', 90: 'critical', 91: 'dodge', 81: 'additional_normal'}[row.efficacy_type];
      effects = [{...base, kind, value: row.efficacy_type === 13 ? 100 - row.eff_value1 : row.efficacy_type === 81 ? 100 : row.eff_value1}];
    }
    report.cover(field, true); return effects;
  }
  async function leaderEffects(binding, card, source, contentId, report) {
    const loaded = await loadBinding(source, contentId, binding, report);
    if (zero(loaded.card.leader_skill_set_id)) return {effects: [], ki: 0};
    const sets = await loaded.read('leader_skill_sets', 'id', loaded.card.leader_skill_set_id);
    if (sets.length !== 1) report.issue('leader[' + loaded.owned.instance_id + '].leader_skill_set_id', 'LEADER_SET_MISSING');
    const rows = await loaded.read('leader_skills', 'leader_skill_set_id', loaded.card.leader_skill_set_id);
    const effects = []; let ki = 0;
    for (const row of rows) {
      const field = 'leader[' + loaded.owned.instance_id + '].leader_skills[' + row.id + ']', before = report.unsupported.length;
      let values; try { values = JSON.parse(row.efficacy_values); } catch (_) { values = null; }
      if (!Array.isArray(values) || values.length !== 3 || values.some(v => !integer(v, 0, 10000))) report.issue(field + '.efficacy_values', 'LEADER_VALUES_UNSUPPORTED', row.efficacy_values);
      if (!emptyCondition(row.causality_conditions) || !zero(row.sub_target_type_set_id)) report.issue(field + '.causality_conditions', 'LEADER_CONDITION_UNSUPPORTED');
      if (row.exec_timing_type !== 1 || row.target_type !== 2) report.issue(field + '.target_type', 'LEADER_SCOPE_UNSUPPORTED', {target_type: row.target_type, exec_timing_type: row.exec_timing_type});
      const supported = row.efficacy_type === 0 && row.calc_option === 0 && values?.every(v => v === 0) || [5, 83].includes(row.efficacy_type) && row.calc_option === 0 || row.efficacy_type === 104 && row.calc_option === 2;
      if (!supported) report.issue(field + '.efficacy_type', 'LEADER_EFFECT_UNSUPPORTED', row.efficacy_type);
      if (row.efficacy_type === 104 && values && values[0]) report.issue(field + '.efficacy_values[0]', 'LEADER_HP_PHASE_UNSUPPORTED', values[0]);
      if (row.efficacy_type === 83 && values && (!integer(values[0], 1, 31) || values[1] > 24 || values[2] !== 0)) report.issue(field + '.efficacy_values', 'LEADER_TYPE_MASK_UNSUPPORTED', values);
      if (row.efficacy_type === 5 && values && (values[0] > 24 || values[1] !== 0 || values[2] !== 0)) report.issue(field + '.efficacy_values', 'LEADER_KI_UNSUPPORTED', values);
      if (before !== report.unsupported.length) { report.cover(field, false); continue; }
      if (row.efficacy_type === 5) ki += values[0];
      if (row.efficacy_type === 83 && values[0] & (1 << (card.element % 10))) ki += values[1];
      if (row.efficacy_type === 104) {
        effects.push({id: 'leader.' + loaded.owned.instance_id + '.' + row.id + '.atk', kind: 'atk_percent', phase: 'leader', value: values[1]});
        effects.push({id: 'leader.' + loaded.owned.instance_id + '.' + row.id + '.def', kind: 'def_percent', phase: 'leader', value: values[2]});
      }
      report.cover(field, true);
    }
    return {effects, ki};
  }
  async function supers(binding, policy, report, animations) {
    const {owned, card, read} = binding, relations = await read('card_specials', 'card_id', card.id), available = [];
    for (const relation of relations) {
      if (!integer(relation.lv_start, 0, 99)) { report.issue('card_specials[' + relation.id + '].lv_start', 'SUPER_LEVEL_GATE_UNSUPPORTED'); continue; }
      if (relation.lv_start > owned.sa_level) continue;
      available.push(relation);
    }
    const selected = [];
    for (const style of new Set(available.map(row => row.style))) {
      const rows = available.filter(row => row.style === style), max = Math.max(...rows.map(row => row.lv_start));
      const active = rows.filter(row => row.lv_start === max);
      if (active.length !== 1 || !['Normal', 'Hyper'].includes(style)) report.issue('card_specials.style.' + style, 'SUPER_STYLE_UNSUPPORTED', active.map(row => row.id));
      else selected.push(active[0]);
    }
    const result = [];
    for (const relation of selected) {
      const field = 'card_specials[' + relation.id + ']', before = report.unsupported.length;
      if (!emptyCondition(relation.causality_conditions) || !zero(relation.card_costume_condition_id) || !zero(relation.special_asset_id) || !zero(relation.priority)) report.issue(field + '.conditions', 'SUPER_CONDITION_UNSUPPORTED');
      if (!integer(relation.eball_num_start, 1, card.eball_mod_max_num)) report.issue(field + '.eball_num_start', 'SUPER_KI_THRESHOLD_UNSUPPORTED', relation.eball_num_start);
      for (const index of [1, 2]) if (!zero(relation['special_bonus_id' + index]) && (!integer(relation['special_bonus_lv' + index], 1) || owned.sa_level >= relation['special_bonus_lv' + index])) report.issue(field + '.special_bonus_id' + index, 'SUPER_LEVEL_BONUS_UNSUPPORTED', relation['special_bonus_id' + index]);
      const sets = await read('special_sets', 'id', relation.special_set_id);
      if (sets.length !== 1) { report.issue(field + '.special_set_id', 'SUPER_SET_MISSING'); continue; }
      const set = sets[0], effects = await read('specials', 'special_set_id', set.id);
      if (typeof set.name !== 'string' || !set.name.trim() || set.name.length > 160 || /[\x00-\x1f\x7f]/.test(set.name)) report.issue('special_sets[' + set.id + '].name', 'SUPER_NAME_UNSUPPORTED');
      if (set.aim_target !== 0 || set.is_inactive !== 0 || !emptyCondition(set.causality_description)) report.issue('special_sets[' + set.id + ']', 'SUPER_SCOPE_UNSUPPORTED');
      for (const row of effects) { report.issue('specials[' + row.id + ']', 'SUPER_EFFECT_PHASE_UNSUPPORTED', {efficacy_type: row.efficacy_type, calc_option: row.calc_option, turn: row.turn, causality_conditions: row.causality_conditions}); report.cover('specials[' + row.id + ']', false); }
      let multiplier = null;
      if (policy !== POLICY) report.issue('special_sets[' + set.id + '].increase_rate', 'SUPER_MULTIPLIER_POLICY_REQUIRED');
      else if (!integer(set.increase_rate, 0, 2800) || !integer(set.lv_bonus, 0, 1000)) report.issue('special_sets[' + set.id + ']', 'SUPER_MULTIPLIER_SOURCE_INVALID');
      else {
        const percent = 100n + BigInt(set.increase_rate) + BigInt(set.lv_bonus) * BigInt(owned.sa_level - 1);
        if (percent < 100n || percent > 3000n) report.issue('special_sets[' + set.id + ']', 'SUPER_MULTIPLIER_RANGE_UNSUPPORTED');
        else multiplier = Number(percent * 10000n);
      }
      const animation = animations?.[String(relation.id)] || null;
      if (animation && (!record(animation) || typeof animation.path !== 'string' || !/^[A-Za-z0-9_./-]{1,500}$/.test(animation.path) || animation.path.split('/').some(p => !p || p === '.' || p === '..') || !/^[a-f0-9]{64}$/.test(animation.sha256))) report.issue(field + '.animation', 'VERIFIED_ANIMATION_REFERENCE_REQUIRED');
      result.push({id: 'source-super.' + relation.id, name: set.name, threshold: relation.eball_num_start, multiplierPpm: multiplier, animation: animation ? {path: animation.path, sha256: animation.sha256} : null, source: {relation: copied(relation), set: copied(set)}, supported: before === report.unsupported.length});
    }
    if (new Set(result.map(row => row.threshold)).size !== result.length || result.length > 2) report.issue('card_specials', 'SUPER_THRESHOLDS_AMBIGUOUS');
    return result;
  }
  async function normalizeOwnedCard(input) {
    if (!record(input)) error('ROSTER_INPUT_INVALID');
    const sourceHandle = input.source;
    input = {...copied(Object.fromEntries(Object.entries(input).filter(([key]) => key !== 'source'))), source: sourceHandle};
    const {source, contentId, policy} = input; identity(source, contentId);
    const report = makeReport(), binding = await loadBinding(source, contentId, input, report), {owned, card, read} = binding;
    const stats = input.stats;
    if (!record(stats) || stats.master_id !== owned.master_id || stats.level !== owned.level || stats.level_cap !== card.lv_max || stats.source_grow_type !== card.grow_type || binding.definition?.stat_policy && binding.definition.stat_policy !== stats.policy || stats.base_excludes_bonuses !== true || !['master-coefficient-linear-floor-v1', 'creator-cap-normalized-v1'].includes(stats.policy) || ['hp', 'atk', 'def'].some(k => !integer(stats[k], k === 'hp' ? 1 : 0, 2147483647))) report.issue('stats', 'CORE_OWNED_STATS_BINDING_REQUIRED');
    if (!integer(owned.level, 1, card.lv_max) || !integer(owned.sa_level, 1, card.skill_lv_max)) report.issue('owned.level', 'OWNED_LEVEL_BINDING_INVALID');
    if (!record(owned.potential) || Object.keys(owned.potential).length) report.issue('owned.potential', 'POTENTIAL_COMBAT_EFFECTS_UNSUPPORTED');
    if (owned.created_definition?.addons?.length || owned.tournament_definition?.addons?.length || input.equipment?.length) report.issue('owned.addons', 'EQUIPMENT_COMBAT_EFFECTS_UNSUPPORTED');
    if (![0, 1, 2, 3, 4, 10, 11, 12, 13, 14, 20, 21, 22, 23, 24].includes(card.element)) report.issue('cards.element', 'SOURCE_TYPE_UNSUPPORTED', card.element);
    const classType = sourceClass(card.element), explicitBattlePolicy = sourceBattlePolicy(input.battlePolicy);
    if (input.battlePolicy !== undefined && !explicitBattlePolicy) report.issue('battlePolicy', 'SOURCE_BATTLE_POLICY_INVALID');
    if (classType && classType !== 'neutral' && !explicitBattlePolicy) report.issue('cards.element', 'STATIC_CLASS_POLICY_REQUIRED', card.element);
    const ki = kiCurve(card, policy, report);
    if (!zero(card.passive_skill_set_id) && (await read('passive_skill_sets', 'id', card.passive_skill_set_id)).length !== 1) report.issue('cards.passive_skill_set_id', 'PASSIVE_SET_MISSING');
    const relations = zero(card.passive_skill_set_id) ? [] : await read('passive_skill_set_relations', 'passive_skill_set_id', card.passive_skill_set_id), passives = [];
    for (const relation of relations) {
      const rows = await read('passive_skills', 'id', relation.passive_skill_id);
      if (rows.length !== 1) report.issue('passive_skill_set_relations[' + relation.id + ']', 'PASSIVE_REFERENCE_MISSING');
      else passives.push(rows[0]);
    }
    if (new Set(passives.map(row => row.id)).size !== passives.length) report.issue('passive_skill_set_relations', 'PASSIVE_REFERENCE_DUPLICATE');
    const final = exclusive(passives, record(stats) ? stats : {}, report), effects = [];
    const rarityBoost = binding.definition?.rarity === 'GR' ? 20 : binding.definition?.rarity === 'SLR' ? 10 : 0;
    if (final.value && final.value.atkPercent !== rarityBoost) report.issue('stats.final_exclusive', 'EXCLUSIVE_RARITY_BINDING_INVALID');
    for (const row of passives) {
      const field = 'passive_skills[' + row.id + ']';
      if (final.skip.has(row.id)) { report.cover(field, true); continue; }
      effects.push(...passive(row, field, report, input.battlePolicy));
    }
    let baseKi = 0;
    if (!Array.isArray(input.leaders) || input.leaders.length !== 2 || input.leaders.some(leader => !record(leader?.owned)) || new Set(input.leaders?.map(leader => leader.owned.instance_id)).size !== 2) report.issue('team.leaders', 'TWO_OWNED_LEADER_BINDINGS_REQUIRED');
    else for (const leader of input.leaders) {
      const leaderResult = await leaderEffects(leader, card, source, contentId, report); baseKi += leaderResult.ki; effects.push(...leaderResult.effects);
    }
    if (!integer(baseKi, 0, ki.raw.eball_mod_max_num)) report.issue('team.leaders.ki', 'LEADER_KI_SUM_UNSUPPORTED', baseKi);
    for (let i = 1; i <= 7; i++) if (!zero(card['link_skill' + i + '_id'])) { report.issue('cards.link_skill' + i + '_id', 'LINK_LEVEL_AND_ROTATION_TRANSLATION_REQUIRED', card['link_skill' + i + '_id']); report.cover('cards.link_skill' + i + '_id', false); }
    for (const [table, code] of [['card_active_skills', 'ACTIVE_SKILL_UNSUPPORTED'], ['card_standby_skill_set_relations', 'STANDBY_UNSUPPORTED'], ['card_finish_skill_set_relations', 'FINISH_SKILL_UNSUPPORTED'], ['passive_skill_set_additions', 'PASSIVE_ADDITION_SCHEDULE_UNSUPPORTED'], ['origin_battle_passive_skill_set_relations', 'ORIGIN_BATTLE_PASSIVE_CONTEXT_REQUIRED']]) {
      const rows = await read(table, 'card_id', card.id);
      for (const row of rows) { report.issue(table + '[' + row.id + ']', code); report.cover(table + '[' + row.id + ']', false); }
    }
    const attacks = integer(owned.sa_level, 1, card.skill_lv_max) ? await supers(binding, policy, report, input.animations) : [];
    if (typeof card.name !== 'string' || !card.name.trim() || card.name.length > 160 || /[\x00-\x1f\x7f]/.test(card.name)) report.issue('cards.name', 'BATTLE_NAME_UNSUPPORTED');
    if (effects.length > 128 || report.ledger.length > 10000) report.issue('effects', 'BATTLE_EFFECT_LIMIT_UNSUPPORTED');
    const capabilities = ['normal', 'ki_spheres', 'rotation', ...new Set(effects.map(row => row.kind))];
    if (explicitBattlePolicy) capabilities.push('static_class');
    if (attacks.length) capabilities.push('super'); if (final.value?.atkPercent) capabilities.push('final_exclusive');
    const coverage = {sourceEffects: report.ledger.length, translatedEffects: report.ledger.filter(row => row.translated).length, requiredCapabilities: capabilities, unsupported: report.unsupported.map(item => item.code)};
    const resolved = {baseStats: record(stats) ? copied(stats) : null, type: card.element % 10, classType, baseKi, ki, superAttacks: attacks, effects, finalExclusive: final.value, coverage};
    const fighter = report.unsupported.length ? null : {instanceId: String(owned.instance_id), masterId: owned.master_id, name: card.name, element: resolved.type, ...(explicitBattlePolicy ? {classType} : {}), hp: stats.hp, atk: stats.atk, def: stats.def, baseKi, maxKi: card.eball_mod_max_num, kiMultipliersPpm: ki.curve, superAttacks: attacks.map(({source, supported, ...row}) => row), effects, finalExclusive: final.value, coverage};
    identity(source, contentId);
    return {supported: fighter !== null, fighter, unsupported: report.unsupported, resolved, provenance: {contentId, provider: source.provider, masterId: owned.master_id, instanceId: owned.instance_id, ownedLevel: owned.level, superAttackLevel: owned.sa_level, definition: binding.definition ? {id: binding.definition.definition_id || null, version: binding.definition.version} : null, policy: policy === POLICY ? POLICY : null, battlePolicy: explicitBattlePolicy ? copied(input.battlePolicy) : null, sourceClass: {element: card.element, classType, awakeningElementType: card.awakening_element_type}, originalGameRoundingVerified: false, sourceEffectAccounting: report.ledger}};
  }
  return Object.freeze({normalizeOwnedCard, policyId: POLICY, battlePolicyId: BATTLE_POLICY, statPhasePolicyId: STAT_PHASE_POLICY});
});
