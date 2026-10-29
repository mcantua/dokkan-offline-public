/* One focused played-turn/restart/result scenario; authored data, no game assets. */
'use strict';
const assert = require('node:assert/strict');
const Battle = require('./battle.js');
const source = {
  battleId: 'local-run-1', contentId: 'sha256:' + 'a'.repeat(64), seed: 12345,
  policy: {id: Battle.policyId, minimumDamage: 1, advantagePpm: 1500000, disadvantagePpm: 500000, criticalPpm: 1900000, requireAnimations: false},
  roster: Array.from({length: 7}, (_, i) => ({
    instanceId: 'owned-' + (i + 1), masterId: i + 1, name: 'Authored fixture ' + (i + 1), element: 0,
    hp: 200, atk: 100, def: 10, baseKi: 11, maxKi: 12, kiMultipliersPpm: Array(13).fill(1000000),
    superAttacks: [{id: 'attack-' + (i + 1), name: 'Authored attack', threshold: 12, multiplierPpm: 2000000, animation: null}],
    effects: [{id: 'start-atk', kind: 'atk_percent', phase: 'start', value: 100}, {id: 'attack-atk', kind: 'atk_percent', phase: 'on_attack', value: 50}, {id: 'attack-def', kind: 'def_percent', phase: 'on_attack', value: 100}],
    finalExclusive: {atkPercent: 0, defPercent: 0, damageReductionPercent: 0},
    coverage: {sourceEffects: 3, translatedEffects: 3, requiredCapabilities: ['normal', 'super', 'atk_percent', 'def_percent'], unsupported: []}
  })),
  enemy: {id: 'authored-enemy', name: 'Authored enemy fixture', element: 0, hp: 2000, def: 0, attacks: [{id: 'before', slot: 0, atk: 120, kind: 'normal', animation: null}, {id: 'after', slot: 3, atk: 120, kind: 'normal', animation: null}]}
};
const inputBefore = JSON.stringify(source);
let state = Battle.create(source), commandNumber = 0;
function apply(kind, extra = {}) {
  const command = {id: 'intent-' + ++commandNumber, revision: state.revision, kind, ...extra};
  const result = Battle.transition(state, command); state = result.state; return {command, result};
}
for (let i = 0; i < 3; i++) apply('collect', {path: [[i, 4]]});
const first = apply('resolve');
assert.equal(state.turn, 2); assert.equal(state.enemyHp, 200); assert.equal(state.hp, 1190);
assert.deepEqual(state.order, ['owned-4', 'owned-5', 'owned-6']);
assert.deepEqual(first.result.events.filter(e => e.type === 'player-attack').map(e => e.damage), [600, 600, 600]);
const snapshot = Battle.serialize(state); state = Battle.restore(snapshot);
const retry = Battle.transition(state, first.command);
assert.equal(retry.replayed, true); assert.equal(Battle.serialize(retry.state), snapshot); assert.deepEqual(retry.events, []);
assert.throws(() => Battle.transition(state, {id: 'bad-path', revision: state.revision, kind: 'collect', path: [[0, 4], [1, 3]]}), /BATTLE_PATH_DISCONNECTED/);
assert.equal(Battle.serialize(state), snapshot);
for (let i = 0; i < 3; i++) apply('collect', {path: [[i, 4]]});
const finished = apply('resolve');
assert.equal(state.phase, 'victory'); assert.equal(state.enemyHp, 0);
assert.equal(finished.result.events.filter(e => e.type === 'battle-end').length, 1);
assert.equal(finished.result.events.filter(e => e.type === 'player-attack').length, 1);
assert.equal(Battle.transition(state, finished.command).replayed, true);
assert.equal(JSON.stringify(source), inputBefore);
const losing = JSON.parse(inputBefore); losing.enemy.attacks[0].atk = 100000;
state = Battle.create(losing); for (let i = 0; i < 3; i++) apply('collect', {path: [[i, 4]]});
const defeat = apply('resolve'); assert.equal(state.phase, 'defeat'); assert.equal(state.hp, 0);
assert.equal(defeat.result.events.some(e => e.type === 'player-attack'), false);
const unsupported = JSON.parse(inputBefore); unsupported.roster[0].coverage.requiredCapabilities.push('transformation');
assert.throws(() => Battle.create(unsupported), /BATTLE_CAPABILITY_UNSUPPORTED/);
console.log('One authored turn battle/restart/replay/outcome/capability scenario passed. No native gameplay, rewards or original-engine parity claimed.');
