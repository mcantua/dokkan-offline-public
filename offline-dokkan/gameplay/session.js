/* Native-owned durable battle coordinator. Export only load/dispatch to game pages. */
(function (root, factory) {
  if (typeof module === 'object' && module.exports) module.exports = factory(require('./battle.js'), require('node:crypto').webcrypto);
  else root.OfflineDokkanBattleSession = factory(root.OfflineDokkanBattle, root.crypto);
})(typeof globalThis !== 'undefined' ? globalThis : this, function (Battle, crypto) {
  'use strict';
  const FORMAT = 'offline-dokkan-battle-session', MAX_BYTES = 4 * 1024 * 1024;
  const fail = code => { const e = new Error(code); e.code = code; throw e; };
  const record = x => x && typeof x === 'object' && !Array.isArray(x);
  const copy = x => JSON.parse(JSON.stringify(x));
  const identity = x => typeof x === 'string' && /^[A-Za-z0-9_.:-]{1,127}$/.test(x) ? x : fail('BATTLE_SESSION_ID_INVALID');
  const token = x => typeof x === 'string' && x.length > 0 && x.length <= 256 && !/[\x00-\x1f\x7f]/.test(x) ? x : fail('BATTLE_STORAGE_TOKEN_INVALID');
  function stable(x) {
    if (Array.isArray(x)) return '[' + x.map(stable).join(',') + ']';
    if (record(x)) return '{' + Object.keys(x).sort().map(k => JSON.stringify(k) + ':' + stable(x[k])).join(',') + '}';
    return JSON.stringify(x);
  }
  function bytes(text) { return new TextEncoder().encode(text); }
  async function digest(text) {
    if (!crypto || !crypto.subtle) fail('BATTLE_HASH_UNAVAILABLE');
    return Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256', bytes(text))), b => b.toString(16).padStart(2, '0')).join('');
  }
  function serialize(envelope) {
    const text = stable(envelope);
    if (bytes(text).length > MAX_BYTES) fail('BATTLE_SESSION_TOO_LARGE');
    return text;
  }
  function pending(envelope) {
    const s = envelope.state;
    if (s.phase !== 'victory' && s.phase !== 'defeat') return null;
    return {battleId: s.battleId, contentId: s.contentId, configurationSha256: envelope.configurationSha256, stateSha256: envelope.stateSha256, revision: s.revision, outcome: s.phase === 'victory' ? 'clear' : 'failed', requiresTrustedSettlement: true};
  }
  function create({storage, verifySettlement} = {}) {
    if (!Battle || !storage || typeof storage.read !== 'function' || typeof storage.compareAndSwap !== 'function' || verifySettlement !== undefined && typeof verifySettlement !== 'function') fail('BATTLE_SESSION_HOST_REQUIRED');
    let tail = Promise.resolve(), expected = null, cache = null;
    function serial(work) { const task = tail.then(work, work); tail = task.catch(() => {}); return task; }
    async function checkReceipt(receiptId, envelope) {
      identity(receiptId); const result = pending(envelope);
      if (!result || !verifySettlement) fail('BATTLE_TRUSTED_SETTLEMENT_REQUIRED');
      const proof = await verifySettlement(receiptId, copy(result));
      if (!record(proof) || proof.committed !== true || proof.receiptId !== receiptId || ['battleId', 'contentId', 'configurationSha256', 'stateSha256', 'outcome'].some(k => proof[k] !== result[k])) fail('BATTLE_SETTLEMENT_NOT_COMMITTED');
    }
    async function checkRow(row) {
      if (row === null) return null;
      if (!record(row) || typeof row.data !== 'string' || bytes(row.data).length > MAX_BYTES) fail('BATTLE_STORAGE_RECORD_INVALID');
      token(row.token);
      if (cache && cache.token === row.token) {
        if (cache.data !== row.data) fail('BATTLE_STORAGE_TOKEN_REUSED');
        return cache;
      }
      let envelope;
      try { envelope = JSON.parse(row.data); } catch { fail('BATTLE_STORAGE_RECORD_INVALID'); }
      const keys = ['format', 'version', 'configuration', 'configurationSha256', 'state', 'stateSha256', 'settlement'];
      if (!record(envelope) || Object.keys(envelope).some(k => !keys.includes(k)) || Object.keys(envelope).length !== keys.length || envelope.format !== FORMAT || envelope.version !== 1 || serialize(envelope) !== row.data) fail('BATTLE_STORAGE_RECORD_INVALID');
      if (!/^[a-f0-9]{64}$/.test(envelope.configurationSha256) || !/^[a-f0-9]{64}$/.test(envelope.stateSha256)) fail('BATTLE_SESSION_HASH_INVALID');
      if (await digest(stable(envelope.configuration)) !== envelope.configurationSha256 || await digest(stable(envelope.state)) !== envelope.stateSha256) fail('BATTLE_SESSION_HASH_INVALID');
      Battle.validate(envelope.state);
      let replay = Battle.create(envelope.configuration);
      // Structural validation alone cannot establish a legitimate clear. Replay
      // legal intents from the immutable plan before accepting a reopened state.
      for (const command of envelope.state.commands) {
        let intent; try { intent = JSON.parse(command.input); } catch { fail('BATTLE_JOURNAL_INVALID'); }
        if (!record(intent) || intent.id !== command.id || stable(intent) !== command.input) fail('BATTLE_JOURNAL_INVALID');
        replay = Battle.transition(replay, intent).state;
      }
      if (stable(replay) !== stable(envelope.state)) fail('BATTLE_JOURNAL_RESULT_MISMATCH');
      if (envelope.settlement !== null) {
        if (!record(envelope.settlement) || Object.keys(envelope.settlement).length !== 1) fail('BATTLE_SETTLEMENT_INVALID');
        await checkReceipt(envelope.settlement.receiptId, envelope);
      }
      cache = {token: row.token, data: row.data, envelope}; return cache;
    }
    function requireExpected(row) {
      if (!expected) fail('BATTLE_TRUSTED_PLAN_REQUIRED');
      if (!row) fail('BATTLE_SESSION_MISSING');
      const e = row.envelope;
      if (e.configurationSha256 !== expected.configurationSha256 || e.state.battleId !== expected.battleId || e.state.contentId !== expected.contentId) fail('BATTLE_TRUSTED_PLAN_MISMATCH');
      return e;
    }
    async function read() { return checkRow(await storage.read()); }
    async function write(previous, envelope) {
      const data = serialize(envelope), old = previous ? previous.token : null;
      const next = await storage.compareAndSwap(old, data);
      if (next === false) return false;
      token(next); if (next === old) fail('BATTLE_STORAGE_TOKEN_REUSED');
      cache = {token: next, data, envelope}; return true;
    }
    function planIdentity(plan, configurationSha256) { return {battleId: plan.battleId, contentId: plan.contentId, configurationSha256}; }
    async function makeEnvelope(plan) {
      const configuration = copy(plan), state = Battle.create(configuration);
      if (bytes(stable(configuration)).length > 512 * 1024) fail('BATTLE_CONFIGURATION_TOO_LARGE');
      return {format: FORMAT, version: 1, configuration, configurationSha256: await digest(stable(configuration)), state, stateSha256: await digest(stable(state)), settlement: null};
    }
    return Object.freeze({
      startTrustedPlan(plan) {
        // Take a bounded validated copy before queueing, so a caller cannot
        // mutate queued trusted inputs between an await and durable commit.
        const original = copy(plan); Battle.create(original);
        return serial(async () => {
          const envelope = await makeEnvelope(original), nextExpected = planIdentity(original, envelope.configurationSha256);
          for (let attempt = 0; attempt < 2; attempt++) {
            const previous = await read();
            if (previous) {
              if (previous.envelope.configurationSha256 === envelope.configurationSha256) { expected = nextExpected; return copy(previous.envelope.state); }
              if (!previous.envelope.settlement) fail('BATTLE_ACTIVE_OR_UNSETTLED');
              // A new plan may replace only a terminal battle whose receipt has
              // already been verified against the trusted core ledger above.
              await checkReceipt(previous.envelope.settlement.receiptId, previous.envelope);
            }
            if (await write(previous, envelope)) { expected = nextExpected; return copy(envelope.state); }
          }
          fail('BATTLE_STORAGE_CONFLICT');
        });
      },
      openTrustedPlan(reference) {
        const trusted = copy(reference);
        if (!record(trusted) || Object.keys(trusted).length !== 3 || !/^[a-f0-9]{64}$/.test(trusted.configurationSha256)) fail('BATTLE_TRUSTED_PLAN_INVALID');
        identity(trusted.battleId); identity(trusted.contentId);
        return serial(async () => {
          const row = await read();
          if (!row || row.envelope.configurationSha256 !== trusted.configurationSha256 || row.envelope.state.battleId !== trusted.battleId || row.envelope.state.contentId !== trusted.contentId) fail('BATTLE_TRUSTED_PLAN_MISMATCH');
          expected = trusted; return copy(row.envelope.state);
        });
      },
      load() { return serial(async () => copy(requireExpected(await read()).state)); },
      dispatch(command) {
        const intent = copy(command);
        return serial(async () => {
          for (let attempt = 0; attempt < 2; attempt++) {
            const previous = await read(), envelope = requireExpected(previous);
            const result = Battle.transition(envelope.state, intent);
            if (result.replayed) return result;
            if (envelope.settlement) fail('BATTLE_ALREADY_SETTLED');
            const next = {...envelope, state: result.state, stateSha256: await digest(stable(result.state))};
            if (await write(previous, next)) return result;
          }
          fail('BATTLE_STORAGE_CONFLICT');
        });
      },
      trustedIdentity() { return serial(() => expected ? copy(expected) : fail('BATTLE_TRUSTED_PLAN_REQUIRED')); },
      pendingSettlement() { return serial(async () => { const e = requireExpected(await read()); return e.settlement ? null : pending(e); }); },
      confirmSettlementTrusted(receiptId) {
        identity(receiptId);
        return serial(async () => {
          for (let attempt = 0; attempt < 2; attempt++) {
            const previous = await read(), envelope = requireExpected(previous);
            await checkReceipt(receiptId, envelope);
            if (envelope.settlement) {
              if (envelope.settlement.receiptId !== receiptId) fail('BATTLE_SETTLEMENT_CONFLICT');
              return {recorded: true, replayed: true};
            }
            if (await write(previous, {...envelope, settlement: {receiptId}})) return {recorded: true, replayed: false};
          }
          fail('BATTLE_STORAGE_CONFLICT');
        });
      }
    });
  }
  return Object.freeze({create});
});
