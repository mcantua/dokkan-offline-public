/* One coordinator boundary scenario, with fault-injected atomic-storage adapter. */
'use strict';
const assert = require('node:assert/strict'), {createHash} = require('node:crypto');
const Session = require('./session.js'), Battle = require('./battle.js');
const stable = x => Array.isArray(x) ? '[' + x.map(stable).join(',') + ']' : x && typeof x === 'object' ? '{' + Object.keys(x).sort().map(k => JSON.stringify(k) + ':' + stable(x[k])).join(',') + '}' : JSON.stringify(x);
const copy = x => JSON.parse(JSON.stringify(x));
function storage() {
  let current = null, writes = 0;
  return {
    afterCommitFailure: false, beforeCAS: null,
    async read() { return copy(current); },
    async compareAndSwap(expected, data) {
      if (this.beforeCAS) { const callback = this.beforeCAS; this.beforeCAS = null; await callback(); }
      if ((current && current.token) !== expected) return false;
      current = {token: 'revision-' + ++writes, data};
      if (this.afterCommitFailure) { this.afterCommitFailure = false; throw Error('Injected lost durable-write reply'); }
      return current.token;
    },
    inspect() { return copy(current); }, inject(row) { current = copy(row); }
  };
}
const plan = {
  battleId: 'run-1', contentId: 'sha256:' + 'b'.repeat(64), seed: 5,
  policy: {id: Battle.policyId, minimumDamage: 1, advantagePpm: 1500000, disadvantagePpm: 500000, criticalPpm: 1900000, requireAnimations: false},
  roster: Array.from({length: 7}, (_, i) => ({instanceId: 'owned-' + i, masterId: i + 1, name: 'Authored coordinator fixture', element: 0, hp: 100, atk: 100, def: 0, baseKi: 0, maxKi: 12, kiMultipliersPpm: Array(13).fill(1000000), superAttacks: [], effects: [], finalExclusive: {atkPercent: 0, defPercent: 0, damageReductionPercent: 0}, coverage: {sourceEffects: 0, translatedEffects: 0, unsupported: [], requiredCapabilities: ['normal']}})),
  enemy: {id: 'fixture-enemy', name: 'Authored coordinator fixture', element: 0, hp: 500, def: 0, attacks: [{id: 'first', slot: 0, atk: 1, kind: 'normal', animation: null}]}
};
(async () => {
  const store = storage(), ledger = new Map(), verifier = async id => ledger.get(id) || null;
  let session = Session.create({storage: store, verifySettlement: verifier});
  await session.startTrustedPlan(plan); const reference = await session.trustedIdentity();
  const first = {id: 'collect-1', revision: 0, kind: 'collect', path: [[0, 4]]};
  store.afterCommitFailure = true;
  await assert.rejects(session.dispatch(first), /Injected lost durable-write reply/);
  assert.equal((await session.load()).revision, 1);
  const recovered = await session.dispatch(first);
  assert.equal(recovered.replayed, true); assert.deepEqual(recovered.events, []);
  session = Session.create({storage: store, verifySettlement: verifier});
  await session.openTrustedPlan(reference);
  const other = Session.create({storage: store, verifySettlement: verifier}); await other.openTrustedPlan(reference);
  const second = {id: 'collect-2-winner', revision: 1, kind: 'collect', path: [[1, 4]]};
  store.beforeCAS = () => other.dispatch(second);
  await assert.rejects(session.dispatch({id: 'collect-2-loser', revision: 1, kind: 'collect', path: [[2, 4]]}), /BATTLE_REVISION_CONFLICT/);
  let state = await session.load(); assert.equal(state.pending.length, 2); assert.equal(state.revision, 2);
  let number = 3;
  async function dispatch(kind, extra = {}) { const result = await session.dispatch({id: 'intent-' + number++, revision: state.revision, kind, ...extra}); state = result.state; return result; }
  await dispatch('collect', {path: [[2, 4]]}); await dispatch('resolve');
  assert.equal(state.turn, 2); assert.equal(state.enemyHp, 200);
  for (let i = 0; i < 3; i++) await dispatch('collect', {path: [[i, 4]]});
  await dispatch('resolve'); assert.equal(state.phase, 'victory');
  const pending = await session.pendingSettlement(); assert.equal(pending.outcome, 'clear');
  await assert.rejects(session.confirmSettlementTrusted('not-a-core-receipt'), /BATTLE_SETTLEMENT_NOT_COMMITTED/);
  assert.ok(await session.pendingSettlement());
  ledger.set('core-receipt-1', {...pending, receiptId: 'core-receipt-1', committed: true});
  assert.equal((await session.confirmSettlementTrusted('core-receipt-1')).replayed, false);
  assert.equal((await session.confirmSettlementTrusted('core-receipt-1')).replayed, true);
  assert.equal(await session.pendingSettlement(), null);
  const saved = store.inspect(), corrupt = copy(saved), envelope = JSON.parse(corrupt.data);
  envelope.state.hp--; envelope.stateSha256 = createHash('sha256').update(stable(envelope.state)).digest('hex'); corrupt.data = stable(envelope);
  const brokenStore = storage(); brokenStore.inject(corrupt);
  const broken = Session.create({storage: brokenStore, verifySettlement: verifier});
  await assert.rejects(broken.openTrustedPlan(reference), /BATTLE_JOURNAL_RESULT_MISMATCH/);
  assert.deepEqual(store.inspect(), saved);
  const replacement = Session.create({storage: store, verifySettlement: verifier});
  await replacement.startTrustedPlan({...plan, battleId: 'run-2', seed: 6});
  assert.equal((await replacement.load()).battleId, 'run-2');
  console.log('One session restart/CAS/lost-reply/journal/settlement boundary scenario passed. Storage adapter faults were simulated; native durability and reward settlement are not claimed.');
})().catch(error => { console.error(error); process.exitCode = 1; });
