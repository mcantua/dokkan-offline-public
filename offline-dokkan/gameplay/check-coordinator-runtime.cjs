/* One private-bootstrap/UTF8/native-callback boundary scenario; not a platform test. */
'use strict';
const assert = require('node:assert/strict'), vm = require('node:vm'), fs = require('node:fs'), path = require('node:path'), {createHash} = require('node:crypto');
let stored = null, writes = 0; const calls = [];
async function nativeBattleRPC(op, args) {
  calls.push(op);
  if (op === 'read') { assert.deepEqual(Object.keys(args), []); return stored; }
  if (op === 'cas') {
    if ((stored && stored.token) !== args.expectedToken) return false;
    stored = {token: 'native-' + ++writes, data: args.data}; return stored.token;
  }
  assert.equal(op, 'sha256'); assert.ok(args.bytes.length <= 4 * 1024 * 1024);
  return Array.from(createHash('sha256').update(Buffer.from(args.bytes)).digest());
}
const files = ['coordinator-runtime.js', 'battle.js', 'session.js'];
function context() {
  const ctx = vm.createContext({nativeBattleRPC});
  for (const file of files) vm.runInContext(fs.readFileSync(path.join(__dirname, file), 'utf8'), ctx, {filename: file});
  return ctx;
}
const request = (ctx, endpoint, message) => ctx.OfflineBattleCoordinator[endpoint](message);
(async () => {
  const ctx = context(), vector = 'A\u0000é中𠮷\ud800x\udc00'; ctx.vector = vector;
  const encoded = vm.runInContext('Array.from(new TextEncoder().encode(vector))', ctx);
  assert.deepEqual(Array.from(encoded), Array.from(Buffer.from(vector, 'utf8')));
  const hash = await vm.runInContext("crypto.subtle.digest('SHA-256',new Uint8Array([9,1,2,8]).subarray(1,3)).then(x=>Array.from(new Uint8Array(x)))", ctx);
  assert.deepEqual(Array.from(hash), Array.from(createHash('sha256').update(Buffer.from([1, 2])).digest()));
  const Battle = require('./battle.js'), plan = {battleId: 'native-bootstrap', contentId: 'sha256:' + 'c'.repeat(64), seed: 1,
    policy: {id: Battle.policyId, minimumDamage: 1, advantagePpm: 1500000, disadvantagePpm: 500000, criticalPpm: 1900000, requireAnimations: false},
    roster: Array.from({length: 7}, (_, i) => ({instanceId: 'owned-' + i, masterId: i + 1, name: 'Authored boundary fixture', element: 0, hp: 100, atk: 1, def: 0, baseKi: 0, maxKi: 12, kiMultipliersPpm: Array(13).fill(1000000), superAttacks: [], effects: [], finalExclusive: {atkPercent: 0, defPercent: 0, damageReductionPercent: 0}, coverage: {sourceEffects: 0, translatedEffects: 0, requiredCapabilities: [], unsupported: []}})),
    enemy: {id: 'enemy', name: 'Authored boundary fixture', element: 0, hp: 1, def: 0, attacks: []}};
  const forbidden = await request(ctx, 'handlePage', {id: 'page-start', op: 'startTrustedPlan', args: {plan}});
  assert.equal(forbidden.error.code, 'BATTLE_NATIVE_AUTHORITY_REQUIRED'); assert.equal(writes, 0);
  const started = await request(ctx, 'handle', {id: 'native-start', op: 'startTrustedPlan', args: {plan}});
  assert.equal(started.id, 'native-start'); assert.equal(started.result.state.battleId, plan.battleId);
  assert.match(started.result.reference.configurationSha256, /^[a-f0-9]{64}$/); assert.equal(writes, 1);
  const reopened = await request(context(), 'handle', {id: 'native-open', op: 'openTrustedPlan', args: {reference: started.result.reference}});
  assert.equal(reopened.result.state.battleId, plan.battleId); assert.equal(writes, 1);
  const loaded = await request(ctx, 'handlePage', {id: 12, op: 'load', args: {}});
  assert.equal(loaded.id, 12); assert.equal(loaded.result.battleId, plan.battleId);
  assert.equal((await request(ctx, 'handlePage', {id: 'sql', op: 'sql', args: {}})).error.code, 'BATTLE_COORDINATOR_OPERATION_UNSUPPORTED');
  assert.ok(calls.every(op => ['read', 'cas', 'sha256'].includes(op)));
  console.log('One private runtime/UTF8/native SHA/callback authority scenario passed in a bare cloud JS context. No iOS JavaScriptCore or Android runtime claim.');
})().catch(error => { console.error(error); process.exitCode = 1; });
