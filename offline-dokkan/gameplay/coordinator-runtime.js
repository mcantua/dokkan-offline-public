/* Load FIRST in a private native JS context, never the public game WebView. */
(function (root) {
  'use strict';
  if (root.OfflineBattleCoordinator) throw Error('BATTLE_COORDINATOR_ALREADY_BOOTSTRAPPED');
  const MAX_BYTES = 4 * 1024 * 1024;
  const rpc = root.nativeBattleRPC;
  if (typeof rpc !== 'function') throw Error('BATTLE_NATIVE_RPC_REQUIRED');
  const fail = code => { const error = new Error(code); error.code = code; throw error; };
  const record = value => value && typeof value === 'object' && !Array.isArray(value);
  function exact(value, keys) { if (!record(value) || Object.keys(value).some(key => !keys.includes(key))) fail('BATTLE_REQUEST_INVALID'); }
  // JavaScriptCore has typed arrays but may not expose the browser TextEncoder.
  // Web-standard USVString handling replaces isolated surrogates with U+FFFD.
  if (typeof root.TextEncoder !== 'function') {
    class UTF8Encoder {
      get encoding() { return 'utf-8'; }
      encode(input) {
        const text = input === undefined ? '' : String(input), output = [];
        for (let i = 0; i < text.length; i++) {
          let code = text.charCodeAt(i);
          if (code >= 0xd800 && code <= 0xdbff) {
            const low = text.charCodeAt(i + 1);
            if (low >= 0xdc00 && low <= 0xdfff) { code = 0x10000 + (code - 0xd800) * 0x400 + low - 0xdc00; i++; }
            else code = 0xfffd;
          } else if (code >= 0xdc00 && code <= 0xdfff) code = 0xfffd;
          if (code <= 0x7f) output.push(code);
          else if (code <= 0x7ff) output.push(0xc0 | code >> 6, 0x80 | code & 63);
          else if (code <= 0xffff) output.push(0xe0 | code >> 12, 0x80 | code >> 6 & 63, 0x80 | code & 63);
          else output.push(0xf0 | code >> 18, 0x80 | code >> 12 & 63, 0x80 | code >> 6 & 63, 0x80 | code & 63);
        }
        return new Uint8Array(output);
      }
    }
    Object.defineProperty(root, 'TextEncoder', {value: UTF8Encoder, writable: false, configurable: false});
  }
  const nativeCrypto = Object.freeze({subtle: Object.freeze({
    async digest(algorithm, input) {
      if (!(algorithm === 'SHA-256' || record(algorithm) && algorithm.name === 'SHA-256' && Object.keys(algorithm).length === 1)) fail('BATTLE_HASH_ALGORITHM_UNSUPPORTED');
      let data;
      if (input instanceof ArrayBuffer) data = new Uint8Array(input);
      else if (ArrayBuffer.isView(input)) data = new Uint8Array(input.buffer, input.byteOffset, input.byteLength);
      else fail('BATTLE_HASH_INPUT_INVALID');
      if (data.byteLength > MAX_BYTES) fail('BATTLE_HASH_INPUT_TOO_LARGE');
      // Always the native platform's SHA256. No private keys, JS digest fallback,
      // original-game service, fetch or network access is used here.
      const result = await rpc('sha256', {bytes: Array.from(data)});
      if (!Array.isArray(result) || result.length !== 32 || result.some(byte => !Number.isInteger(byte) || byte < 0 || byte > 255)) fail('BATTLE_NATIVE_HASH_INVALID');
      return new Uint8Array(result).buffer;
    }
  })});
  try { Object.defineProperty(root, 'crypto', {value: nativeCrypto, writable: false, configurable: false}); }
  catch { fail('BATTLE_PRIVATE_CRYPTO_CONTEXT_REQUIRED'); }
  let session = null;
  function coordinator() {
    if (!session) {
      if (!root.OfflineDokkanBattleSession || typeof root.OfflineDokkanBattleSession.create !== 'function') fail('BATTLE_ENGINE_NOT_READY');
      session = root.OfflineDokkanBattleSession.create({storage: Object.freeze({
        read: () => rpc('read', {}),
        compareAndSwap: (expectedToken, data) => rpc('cas', {expectedToken, data})
      })});
    }
    return session;
  }
  function requestId(value) { return typeof value === 'string' && /^[A-Za-z0-9_.:-]{1,127}$/.test(value) || Number.isSafeInteger(value) && value >= 0 ? value : fail('BATTLE_REQUEST_ID_INVALID'); }
  function errorReply(id, error) {
    const candidate = error && (error.code || error.message), code = typeof candidate === 'string' && /^[A-Z][A-Z0-9_]{0,95}$/.test(candidate) ? candidate : 'BATTLE_COORDINATOR_FAILED';
    return {id, error: {code, message: code}};
  }
  async function handle(request, pageOnly) {
    let id = null;
    try {
      exact(request, ['id', 'op', 'args']); id = requestId(request.id);
      let encoded;
      try { encoded = JSON.stringify(request); } catch { fail('BATTLE_REQUEST_INVALID'); }
      if (new root.TextEncoder().encode(encoded).byteLength > MAX_BYTES) fail('BATTLE_REQUEST_TOO_LARGE');
      let snapshot;
      try { snapshot = JSON.parse(encoded); } catch { fail('BATTLE_REQUEST_INVALID'); }
      exact(snapshot, ['id', 'op', 'args']); id = requestId(snapshot.id);
      const operation = snapshot.op, args = snapshot.args;
      if (!['startTrustedPlan', 'openTrustedPlan', 'load', 'dispatch'].includes(operation)) fail('BATTLE_COORDINATOR_OPERATION_UNSUPPORTED');
      if (pageOnly && !['load', 'dispatch'].includes(operation)) fail('BATTLE_NATIVE_AUTHORITY_REQUIRED');
      const engine = coordinator(); let result;
      if (operation === 'startTrustedPlan') {
        exact(args, ['plan']); if (!record(args.plan)) fail('BATTLE_REQUEST_INVALID');
        const state = await engine.startTrustedPlan(args.plan), reference = await engine.trustedIdentity(); result = {state, reference};
      } else if (operation === 'openTrustedPlan') {
        exact(args, ['reference']); if (!record(args.reference)) fail('BATTLE_REQUEST_INVALID');
        const state = await engine.openTrustedPlan(args.reference), reference = await engine.trustedIdentity(); result = {state, reference};
      } else if (operation === 'load') {
        exact(args, []); result = await engine.load();
      } else {
        exact(args, ['command']); if (!record(args.command)) fail('BATTLE_REQUEST_INVALID'); result = await engine.dispatch(args.command);
      }
      return {id, result};
    } catch (error) { return errorReply(id, error); }
  }
  Object.defineProperty(root, 'OfflineBattleCoordinator', {value: Object.freeze({
    handle: request => handle(request, false),
    handlePage: request => handle(request, true)
  }), writable: false, configurable: false});
})(typeof globalThis !== 'undefined' ? globalThis : this);
