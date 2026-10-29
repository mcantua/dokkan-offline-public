/* Own local turn-battle state machine. No network, source-game protocol or rewards. */
(function (root, factory) {
  if (typeof module === 'object' && module.exports) module.exports = factory();
  else root.OfflineDokkanBattle = factory();
})(typeof globalThis !== 'undefined' ? globalThis : this, function () {
  'use strict';
  const VERSION = 1, PPM = 1000000, MAX_TURNS = 128, MAX_COMMANDS = 2048;
  const LEGACY_POLICY = 'offline-turn-battle-v1', SOURCE_POLICY = 'offline-turn-battle-source-v2';
  const STAT_PHASE_POLICY = 'percent-then-flat-by-phase-v1';
  const COLORS = ['AGL', 'TEQ', 'INT', 'STR', 'PHY', 'Rainbow'];
  const CAPABILITIES = ['normal', 'super', 'ki_spheres', 'rotation', 'atk_percent', 'def_percent', 'ki', 'damage_reduction', 'dodge', 'critical', 'additional_normal', 'final_exclusive', 'atk_flat', 'def_flat', 'static_class'];
  const fail = code => { const e = new Error(code); e.code = code; throw e; };
  const record = x => x && typeof x === 'object' && !Array.isArray(x);
  const int = (x, low, high, code) => Number.isSafeInteger(x) && x >= low && x <= high ? x : fail(code);
  const id = x => typeof x === 'string' && /^[A-Za-z0-9_.:-]{1,127}$/.test(x) ? x : fail('BATTLE_ID_INVALID');
  const text = x => typeof x === 'string' && x.trim() && x.length <= 160 && !/[\x00-\x1f\x7f]/.test(x) ? x : fail('BATTLE_NAME_INVALID');
  const clone = x => JSON.parse(JSON.stringify(x));
  function stable(x) {
    if (Array.isArray(x)) return '[' + x.map(stable).join(',') + ']';
    if (record(x)) return '{' + Object.keys(x).sort().map(k => JSON.stringify(k) + ':' + stable(x[k])).join(',') + '}';
    return JSON.stringify(x);
  }
  function mul(a, b, divisor = PPM) {
    int(a, 0, Number.MAX_SAFE_INTEGER, 'BATTLE_STAT_OVERFLOW');
    int(b, 0, Number.MAX_SAFE_INTEGER, 'BATTLE_STAT_OVERFLOW');
    const n = BigInt(a) * BigInt(b) / BigInt(divisor);
    return n <= BigInt(Number.MAX_SAFE_INTEGER) ? Number(n) : fail('BATTLE_STAT_OVERFLOW');
  }
  function object(x, code) { if (!record(x)) fail(code); return x; }
  function exact(x, keys, code) { object(x, code); if (Object.keys(x).some(k => !keys.includes(k))) fail(code); }
  function policy(x) {
    exact(x, ['id', 'minimumDamage', 'advantagePpm', 'disadvantagePpm', 'criticalPpm', 'requireAnimations', 'statPhasePolicy', 'classPolicy'], 'BATTLE_POLICY_INVALID');
    if (![LEGACY_POLICY, SOURCE_POLICY].includes(x.id) || typeof x.requireAnimations !== 'boolean') fail('BATTLE_POLICY_REQUIRED');
    if (x.id === LEGACY_POLICY) {
      if (Object.prototype.hasOwnProperty.call(x, 'statPhasePolicy') || Object.prototype.hasOwnProperty.call(x, 'classPolicy')) fail('BATTLE_SOURCE_POLICY_REQUIRED');
    } else {
      if (x.statPhasePolicy !== STAT_PHASE_POLICY) fail('BATTLE_STAT_PHASE_POLICY_REQUIRED');
      exact(x.classPolicy, ['id', 'samePpm', 'opposingPpm', 'neutralPpm', 'critical'], 'BATTLE_CLASS_POLICY_REQUIRED');
      if (x.classPolicy.id !== 'static-class-v1' || !['apply', 'bypass'].includes(x.classPolicy.critical)) fail('BATTLE_CLASS_POLICY_REQUIRED');
      for (const field of ['samePpm', 'opposingPpm', 'neutralPpm']) int(x.classPolicy[field], 1, 4 * PPM, 'BATTLE_CLASS_POLICY_INVALID');
    }
    int(x.minimumDamage, 1, 1000, 'BATTLE_POLICY_INVALID');
    int(x.advantagePpm, PPM, 4 * PPM, 'BATTLE_POLICY_INVALID');
    int(x.disadvantagePpm, 1, PPM, 'BATTLE_POLICY_INVALID');
    int(x.criticalPpm, PPM, 4 * PPM, 'BATTLE_POLICY_INVALID');
  }
  function animation(x) {
    if (x === null) return;
    exact(x, ['path', 'sha256'], 'BATTLE_ANIMATION_INVALID');
    if (typeof x.path !== 'string' || x.path.length > 500 || !/^[A-Za-z0-9_./-]+$/.test(x.path) || x.path.split('/').some(k => !k || k === '.' || k === '..') || !/^[a-f0-9]{64}$/.test(x.sha256)) fail('BATTLE_ANIMATION_INVALID');
  }
  function effect(x, selectedPolicy) {
    exact(x, ['id', 'kind', 'phase', 'value'], 'BATTLE_EFFECT_UNSUPPORTED'); id(x.id);
    if (!CAPABILITIES.includes(x.kind) || !['leader', 'start', 'on_attack', 'per_sphere'].includes(x.phase)) fail('BATTLE_EFFECT_UNSUPPORTED');
    const flat = x.kind === 'atk_flat' || x.kind === 'def_flat';
    const stat = flat || x.kind === 'atk_percent' || x.kind === 'def_percent';
    if (flat && selectedPolicy.id !== SOURCE_POLICY) fail('BATTLE_STAT_PHASE_POLICY_REQUIRED');
    if (!stat && !['ki', 'damage_reduction', 'dodge', 'critical', 'additional_normal'].includes(x.kind)) fail('BATTLE_EFFECT_UNSUPPORTED');
    if (!stat && x.phase !== 'start') fail('BATTLE_EFFECT_PHASE_UNSUPPORTED');
    int(x.value, 0, x.kind === 'ki' ? 24 : flat ? 2147483647 : stat ? 10000 : 100, 'BATTLE_EFFECT_VALUE_INVALID');
  }
  function fighter(x, selectedPolicy) {
    exact(x, ['instanceId', 'masterId', 'name', 'element', 'classType', 'hp', 'atk', 'def', 'baseKi', 'maxKi', 'kiMultipliersPpm', 'superAttacks', 'effects', 'finalExclusive', 'coverage'], 'BATTLE_CARD_INVALID');
    id(x.instanceId); int(x.masterId, 1, Number.MAX_SAFE_INTEGER, 'BATTLE_MASTER_INVALID'); text(x.name);
    int(x.element, 0, 4, 'BATTLE_TYPE_INVALID');
    if (selectedPolicy.id === SOURCE_POLICY) {
      if (!['neutral', 'super', 'extreme'].includes(x.classType)) fail('BATTLE_CLASS_REQUIRED');
    } else if (Object.prototype.hasOwnProperty.call(x, 'classType')) fail('BATTLE_CLASS_POLICY_REQUIRED');
    for (const k of ['hp', 'atk', 'def']) int(x[k], k === 'hp' ? 1 : 0, 2147483647, 'BATTLE_STATS_INVALID');
    if (![12, 24].includes(x.maxKi)) fail('BATTLE_KI_INVALID'); int(x.baseKi, 0, x.maxKi, 'BATTLE_KI_INVALID');
    if (!Array.isArray(x.kiMultipliersPpm) || x.kiMultipliersPpm.length !== x.maxKi + 1) fail('BATTLE_KI_CURVE_REQUIRED');
    x.kiMultipliersPpm.forEach(v => int(v, 1, 10 * PPM, 'BATTLE_KI_CURVE_INVALID'));
    if (!Array.isArray(x.superAttacks) || x.superAttacks.length > 2) fail('BATTLE_SUPER_UNSUPPORTED');
    const thresholds = new Set();
    for (const sa of x.superAttacks) {
      exact(sa, ['id', 'name', 'threshold', 'multiplierPpm', 'animation'], 'BATTLE_SUPER_UNSUPPORTED'); id(sa.id); text(sa.name);
      int(sa.threshold, 1, x.maxKi, 'BATTLE_SUPER_INVALID'); int(sa.multiplierPpm, PPM, 30 * PPM, 'BATTLE_SUPER_INVALID');
      if (thresholds.has(sa.threshold)) fail('BATTLE_SUPER_AMBIGUOUS'); thresholds.add(sa.threshold); animation(sa.animation);
    }
    if (!Array.isArray(x.effects) || x.effects.length > 128) fail('BATTLE_EFFECT_UNSUPPORTED'); x.effects.forEach(row => effect(row, selectedPolicy));
    if (new Set(x.effects.map(e => e.id)).size !== x.effects.length) fail('BATTLE_EFFECT_DUPLICATE');
    exact(x.finalExclusive, ['atkPercent', 'defPercent', 'damageReductionPercent'], 'BATTLE_EXCLUSIVE_INVALID');
    for (const key of Object.keys(x.finalExclusive)) int(x.finalExclusive[key], 0, 20, 'BATTLE_EXCLUSIVE_INVALID');
    if (![0, 10, 20].includes(x.finalExclusive.atkPercent) || x.finalExclusive.atkPercent !== x.finalExclusive.defPercent || x.finalExclusive.atkPercent !== x.finalExclusive.damageReductionPercent) fail('BATTLE_EXCLUSIVE_INVALID');
    exact(x.coverage, ['sourceEffects', 'translatedEffects', 'requiredCapabilities', 'unsupported'], 'BATTLE_CAPABILITIES_REQUIRED');
    int(x.coverage.sourceEffects, 0, 10000, 'BATTLE_CAPABILITIES_REQUIRED');
    if (x.coverage.translatedEffects !== x.coverage.sourceEffects || !Array.isArray(x.coverage.unsupported) || x.coverage.unsupported.length || !Array.isArray(x.coverage.requiredCapabilities) || x.coverage.requiredCapabilities.some(c => !CAPABILITIES.includes(c))) fail('BATTLE_CAPABILITY_UNSUPPORTED');
    if (selectedPolicy.id === SOURCE_POLICY && (!x.coverage.requiredCapabilities.includes('static_class') || x.effects.some(row => !x.coverage.requiredCapabilities.includes(row.kind)))) fail('BATTLE_CAPABILITY_UNSUPPORTED');
  }
  function enemy(x, selectedPolicy) {
    exact(x, ['id', 'name', 'element', 'classType', 'hp', 'def', 'attacks'], 'BATTLE_ENEMY_INVALID'); id(x.id); text(x.name);
    int(x.element, 0, 4, 'BATTLE_TYPE_INVALID');
    if (selectedPolicy.id === SOURCE_POLICY) {
      if (!['neutral', 'super', 'extreme'].includes(x.classType)) fail('BATTLE_CLASS_REQUIRED');
    } else if (Object.prototype.hasOwnProperty.call(x, 'classType')) fail('BATTLE_CLASS_POLICY_REQUIRED');
    int(x.hp, 1, 2147483647, 'BATTLE_ENEMY_INVALID'); int(x.def, 0, 2147483647, 'BATTLE_ENEMY_INVALID');
    if (!Array.isArray(x.attacks) || x.attacks.length > 20) fail('BATTLE_ENEMY_PLAN_UNSUPPORTED');
    for (const a of x.attacks) {
      exact(a, ['id', 'slot', 'atk', 'kind', 'animation'], 'BATTLE_ENEMY_PLAN_UNSUPPORTED'); id(a.id);
      int(a.slot, 0, 3, 'BATTLE_ENEMY_PLAN_INVALID'); int(a.atk, 0, 2147483647, 'BATTLE_ENEMY_PLAN_INVALID');
      if (!['normal', 'super'].includes(a.kind)) fail('BATTLE_ENEMY_PLAN_UNSUPPORTED'); animation(a.animation);
    }
    if (new Set(x.attacks.map(a => a.id)).size !== x.attacks.length) fail('BATTLE_ENEMY_PLAN_INVALID');
  }
  function random(s) { let v = s.randomState; v ^= v << 13; v ^= v >>> 17; v ^= v << 5; s.randomState = v >>> 0; return s.randomState; }
  function board(s) { return Array.from({length: 5}, () => Array.from({length: 6}, () => random(s) % 6)); }
  function rotation(s) { return s.queue.slice(0, 3); }
  function beginTurn(s) { s.pending = []; s.order = rotation(s); }
  function validate(s) {
    if (!record(s) || s.format !== 'offline-dokkan-battle' || s.version !== VERSION) fail('BATTLE_SAVE_INVALID');
    id(s.battleId); id(s.contentId); policy(s.policy);
    if (!Array.isArray(s.roster) || s.roster.length !== 7) fail('BATTLE_TEAM_REQUIRES_SEVEN'); s.roster.forEach(unit => fighter(unit, s.policy)); enemy(s.enemy, s.policy);
    const ids = s.roster.map(c => c.instanceId);
    if (new Set(ids).size !== 7 || !Array.isArray(s.queue) || s.queue.length !== 7 || new Set(s.queue).size !== 7 || s.queue.some(x => !ids.includes(x))) fail('BATTLE_ROTATION_INVALID');
    int(s.turn, 1, MAX_TURNS, 'BATTLE_TURN_LIMIT'); int(s.revision, 0, MAX_COMMANDS, 'BATTLE_REVISION_INVALID'); int(s.randomState, 1, 4294967295, 'BATTLE_RANDOM_INVALID');
    int(s.maxHp, 1, Number.MAX_SAFE_INTEGER, 'BATTLE_HP_INVALID');
    if (s.maxHp !== s.roster.reduce((n, c) => n + c.hp, 0)) fail('BATTLE_HP_INVALID');
    int(s.hp, 0, s.maxHp, 'BATTLE_HP_INVALID'); int(s.enemyHp, 0, s.enemy.hp, 'BATTLE_HP_INVALID');
    if (!['playing', 'victory', 'defeat', 'limit'].includes(s.phase) || s.phase === 'playing' && (!s.hp || !s.enemyHp) || s.phase === 'victory' && (s.enemyHp || !s.hp) || s.phase === 'defeat' && (s.hp || !s.enemyHp) || s.phase === 'limit' && (s.turn !== MAX_TURNS || !s.hp || !s.enemyHp)) fail('BATTLE_PHASE_INVALID');
    if (!Array.isArray(s.board) || s.board.length !== 5 || s.board.some(r => !Array.isArray(r) || r.length !== 6 || r.some(v => !Number.isInteger(v) || v < 0 || v > 5))) fail('BATTLE_BOARD_INVALID');
    if (!Array.isArray(s.order) || s.order.length !== 3 || new Set(s.order).size !== 3 || s.order.some(x => !rotation(s).includes(x))) fail('BATTLE_ROTATION_INVALID');
    if (!Array.isArray(s.pending) || s.pending.length > 3) fail('BATTLE_SELECTION_INVALID');
    for (let i = 0; i < s.pending.length; i++) {
      const p = s.pending[i], unit = s.roster.find(c => c.instanceId === s.order[i]);
      exact(p, ['instanceId', 'ki', 'spheres', 'sameType'], 'BATTLE_SELECTION_INVALID');
      if (p.instanceId !== unit.instanceId) fail('BATTLE_SELECTION_INVALID');
      int(p.ki, 0, unit.maxKi, 'BATTLE_KI_INVALID'); int(p.spheres, 1, 30, 'BATTLE_SELECTION_INVALID'); int(p.sameType, 0, p.spheres, 'BATTLE_SELECTION_INVALID');
    }
    if (!Array.isArray(s.commands) || s.commands.length !== s.revision || s.commands.length > MAX_COMMANDS || new Set(s.commands.map(c => c.id)).size !== s.commands.length) fail('BATTLE_COMMAND_HISTORY_INVALID');
    for (const c of s.commands) { exact(c, ['id', 'input'], 'BATTLE_COMMAND_HISTORY_INVALID'); id(c.id); if (typeof c.input !== 'string' || c.input.length > 4096) fail('BATTLE_COMMAND_HISTORY_INVALID'); }
    return s;
  }
  function create(input) {
    exact(input, ['battleId', 'contentId', 'policy', 'roster', 'enemy', 'seed'], 'BATTLE_CONFIGURATION_INVALID');
    policy(input.policy); if (!Array.isArray(input.roster) || input.roster.length !== 7) fail('BATTLE_TEAM_REQUIRES_SEVEN');
    input.roster.forEach(unit => fighter(unit, input.policy)); enemy(input.enemy, input.policy); int(input.seed, 1, 4294967295, 'BATTLE_RANDOM_INVALID');
    if (input.policy.requireAnimations && (input.roster.some(c => c.superAttacks.some(a => !a.animation)) || input.enemy.attacks.some(a => a.kind === 'super' && !a.animation))) fail('BATTLE_ANIMATION_REQUIRED');
    const s = {format: 'offline-dokkan-battle', version: VERSION, battleId: id(input.battleId), contentId: id(input.contentId), policy: clone(input.policy), roster: clone(input.roster), enemy: clone(input.enemy), randomState: input.seed, revision: 0, turn: 1, phase: 'playing', maxHp: input.roster.reduce((n, c) => n + c.hp, 0), enemyHp: input.enemy.hp, queue: input.roster.map(c => c.instanceId), commands: []};
    s.hp = s.maxHp; s.board = board(s); beginTurn(s); return validate(s);
  }
  function effects(unit, kind, phase) { return unit.effects.filter(e => e.kind === kind && (!phase || e.phase === phase)).reduce((n, e) => n + e.value, 0); }
  function stat(unit, key, selection, hasAttacked = true, selectedPolicy) {
    let value = unit[key];
    const flat = (phase, count = 1) => selectedPolicy.id === SOURCE_POLICY ? effects(unit, key + '_flat', phase) * count : 0;
    for (const phase of hasAttacked ? ['leader', 'start', 'on_attack'] : ['leader', 'start']) {
      value = mul(value, 100 + effects(unit, key + '_percent', phase), 100) + flat(phase);
      int(value, 0, Number.MAX_SAFE_INTEGER, 'BATTLE_STAT_OVERFLOW');
    }
    value = mul(value, 100 + effects(unit, key + '_percent', 'per_sphere') * selection.spheres, 100) + flat('per_sphere', selection.spheres);
    int(value, 0, Number.MAX_SAFE_INTEGER, 'BATTLE_STAT_OVERFLOW');
    return mul(value, 100 + unit.finalExclusive[key + 'Percent'], 100);
  }
  function typeMultiplier(from, to, p) {
    // Source numeric order AGL, TEQ, INT, STR, PHY; TEQ beats AGL, AGL beats STR.
    const beats = [3, 0, 1, 4, 2];
    return beats[from] === to ? p.advantagePpm : beats[to] === from ? p.disadvantagePpm : PPM;
  }
  function classMultiplier(from, to, selectedPolicy, critical = false) {
    if (selectedPolicy.id === LEGACY_POLICY) return PPM;
    const rule = selectedPolicy.classPolicy;
    if (critical && rule.critical === 'bypass') return PPM;
    return from === 'neutral' || to === 'neutral' ? rule.neutralPpm : from === to ? rule.samePpm : rule.opposingPpm;
  }
  function chance(s, percentage) { return percentage >= 100 || percentage > 0 && random(s) % PPM < percentage * 10000; }
  function collect(s, path, events) {
    if (s.pending.length === 3 || !Array.isArray(path) || !path.length || path.length > 30) fail('BATTLE_PATH_INVALID');
    const seen = new Set(), cells = []; let color = null, previous = null;
    for (const point of path) {
      if (!Array.isArray(point) || point.length !== 2) fail('BATTLE_PATH_INVALID');
      const [x, y] = point; int(x, 0, 5, 'BATTLE_PATH_INVALID'); int(y, 0, 4, 'BATTLE_PATH_INVALID');
      if (!previous && y !== 4 || previous && Math.abs(x - previous[0]) + Math.abs(y - previous[1]) !== 1 || seen.has(x + ':' + y)) fail('BATTLE_PATH_DISCONNECTED');
      const sphere = s.board[y][x];
      if (sphere !== 5) { if (color !== null && color !== sphere) fail('BATTLE_PATH_COLOR_MISMATCH'); color = sphere; }
      seen.add(x + ':' + y); cells.push(sphere); previous = point;
    }
    const unit = s.roster.find(c => c.instanceId === s.order[s.pending.length]), sameType = cells.filter(v => v === unit.element).length;
    const ki = Math.min(unit.maxKi, unit.baseKi + effects(unit, 'ki') + cells.length + sameType);
    s.pending.push({instanceId: unit.instanceId, ki, spheres: cells.length, sameType});
    for (let x = 0; x < 6; x++) {
      const remaining = s.board.map(r => r[x]).filter((v, y) => !seen.has(x + ':' + y));
      while (remaining.length < 5) remaining.unshift(random(s) % 6);
      for (let y = 0; y < 5; y++) s.board[y][x] = remaining[y];
    }
    events.push({type: 'ki-collected', instanceId: unit.instanceId, ki, spheres: cells.length, sameType});
  }
  function incoming(s, attack, slot, events) {
    if (s.phase !== 'playing') return;
    const index = Math.min(slot, 2), choice = s.pending[index], unit = s.roster.find(c => c.instanceId === choice.instanceId);
    if (chance(s, Math.min(100, effects(unit, 'dodge')))) { events.push({type: 'dodge', instanceId: unit.instanceId, attackId: attack.id}); return; }
    let damage = mul(attack.atk, typeMultiplier(s.enemy.element, unit.element, s.policy));
    damage = mul(damage, classMultiplier(s.enemy.classType, unit.classType, s.policy));
    damage = Math.max(s.policy.minimumDamage, damage - stat(unit, 'def', choice, slot === 3, s.policy));
    damage = mul(damage, 100 - Math.min(100, effects(unit, 'damage_reduction')), 100);
    damage = mul(damage, 100 - unit.finalExclusive.damageReductionPercent, 100);
    damage = Math.min(s.hp, damage); s.hp -= damage;
    events.push({type: 'enemy-attack', attackId: attack.id, kind: attack.kind, instanceId: unit.instanceId, damage, hp: s.hp, animation: clone(attack.animation)});
    if (!s.hp) { s.phase = 'defeat'; events.push({type: 'battle-end', outcome: 'failed', battleId: s.battleId}); }
  }
  function outgoing(s, choice, additional, events) {
    if (s.phase !== 'playing') return;
    const unit = s.roster.find(c => c.instanceId === choice.instanceId);
    const sa = additional ? null : unit.superAttacks.filter(a => choice.ki >= a.threshold).sort((a, b) => b.threshold - a.threshold)[0];
    const critical = chance(s, Math.min(100, effects(unit, 'critical')));
    let attack = mul(stat(unit, 'atk', choice, true, s.policy), unit.kiMultipliersPpm[choice.ki]);
    if (sa) attack = mul(attack, sa.multiplierPpm);
    attack = mul(attack, critical ? s.policy.criticalPpm : typeMultiplier(unit.element, s.enemy.element, s.policy));
    attack = mul(attack, classMultiplier(unit.classType, s.enemy.classType, s.policy, critical));
    const damage = Math.min(s.enemyHp, Math.max(s.policy.minimumDamage, attack - (critical ? 0 : s.enemy.def)));
    s.enemyHp -= damage;
    events.push({type: 'player-attack', instanceId: unit.instanceId, kind: sa ? 'super' : 'normal', superId: sa ? sa.id : null, additional, critical, damage, enemyHp: s.enemyHp, animation: sa ? clone(sa.animation) : null});
    if (!s.enemyHp) { s.phase = 'victory'; events.push({type: 'battle-end', outcome: 'clear', battleId: s.battleId}); }
  }
  function resolve(s, events) {
    if (s.pending.length !== 3) fail('BATTLE_KI_SELECTION_REQUIRED');
    for (let slot = 0; slot < 4 && s.phase === 'playing'; slot++) {
      for (const attack of s.enemy.attacks.filter(a => a.slot === slot)) incoming(s, attack, slot, events);
      if (slot < 3 && s.phase === 'playing') {
        const choice = s.pending[slot], unit = s.roster.find(c => c.instanceId === choice.instanceId);
        outgoing(s, choice, false, events);
        if (s.phase === 'playing' && chance(s, Math.min(100, effects(unit, 'additional_normal')))) outgoing(s, choice, true, events);
      }
    }
    if (s.phase === 'playing') {
      if (s.turn === MAX_TURNS) { s.phase = 'limit'; events.push({type: 'battle-end', outcome: 'unsettled-limit', battleId: s.battleId}); }
      else { s.queue = s.queue.slice(3).concat(s.order); s.turn++; beginTurn(s); events.push({type: 'turn-start', turn: s.turn, order: clone(s.order)}); }
    }
  }
  function transition(input, command) {
    validate(input); exact(command, ['id', 'revision', 'kind', 'path', 'order'], 'BATTLE_COMMAND_INVALID'); id(command.id);
    if (!['collect', 'order', 'resolve'].includes(command.kind)) fail('BATTLE_COMMAND_UNSUPPORTED');
    if (command.kind !== 'collect' && command.path !== undefined || command.kind !== 'order' && command.order !== undefined) fail('BATTLE_COMMAND_INVALID');
    const encoded = stable(command); if (encoded.length > 4096) fail('BATTLE_COMMAND_INVALID');
    const existing = input.commands.find(c => c.id === command.id);
    if (existing) { if (existing.input !== encoded) fail('BATTLE_COMMAND_CONFLICT'); return {state: clone(input), events: [], replayed: true}; }
    if (command.revision !== input.revision) fail('BATTLE_REVISION_CONFLICT');
    if (input.phase !== 'playing') fail('BATTLE_ALREADY_FINISHED'); if (input.commands.length === MAX_COMMANDS) fail('BATTLE_COMMAND_LIMIT');
    const s = clone(input), events = [];
    if (command.kind === 'collect') collect(s, command.path, events);
    else if (command.kind === 'resolve') resolve(s, events);
    else {
      if (s.pending.length || !Array.isArray(command.order) || command.order.length !== 3 || new Set(command.order).size !== 3 || command.order.some(v => !s.order.includes(v))) fail('BATTLE_ROTATION_INVALID');
      s.order = command.order.slice(); events.push({type: 'rotation-changed', order: clone(s.order)});
    }
    s.revision++; s.commands.push({id: command.id, input: encoded}); validate(s); return {state: s, events, replayed: false};
  }
  function serialize(s) { validate(s); const json = JSON.stringify(s); if (json.length > 2 * 1024 * 1024) fail('BATTLE_SAVE_TOO_LARGE'); return json; }
  function restore(json) { if (typeof json !== 'string' || json.length > 2 * 1024 * 1024) fail('BATTLE_SAVE_INVALID'); let s; try { s = JSON.parse(json); } catch { fail('BATTLE_SAVE_INVALID'); } return validate(s); }
  return Object.freeze({create, transition, serialize, restore, validate, colors: Object.freeze(COLORS), capabilities: Object.freeze(CAPABILITIES), policyId: LEGACY_POLICY, sourcePolicyId: SOURCE_POLICY, statPhasePolicyId: STAT_PHASE_POLICY});
});
