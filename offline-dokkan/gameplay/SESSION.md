# Durable native battle session

`session.js` wraps the real turn engine with immutable configuration identities, serialized intents, native compare-and-swap persistence and trusted result handoff. It is usable by the existing battle view without changing its API. It does not invent a roster, provide rewards, start a fake native battle, or substitute browser storage for native save durability.

## Native storage boundary

The native host creates one coordinator for its fixed app-private current-battle slot:

```js
const session = OfflineDokkanBattleSession.create({
  storage: nativePrivateBattleStore,
  verifySettlement: nativeVerifyCommittedRunReceipt
});
const state = await session.startTrustedPlan(actualImmutablePlan);
const pinned = await session.trustedIdentity();
```

The storage adapter has two methods:

| Method | Contract |
|---|---|
| `read()` | Resolve `null` or `{token, data}` for the complete committed slot. `data` is canonical JSON. |
| `compareAndSwap(expectedToken, data)` | Under one native cross-process lock, compare the current token (`null` means absent), durably commit the complete replacement, and return a **new opaque string token**. Return `false` on mismatch without writing. |

Tokens must not be reused for different data. Writes must stage/fsync/publish atomically and preserve the last committed state on failure. The native adapter owns all file paths, permissions, size limits, locks and crash cleanup. No path, storage root, token or arbitrary save contents should be accepted from a game-page command. The envelope is limited to4MiB and its immutable configuration to512KiB. These are fresh single-slot files, not a collection of save backups.

`startTrustedPlan` is **native-only authority**: its actual source-backed roster, stage plan, policy and seed come from the trusted run coordinator. A page may not choose enemy HP, stats, rewards, skill-coverage assertions or content hashes. The coordinator pins a SHA256 of the exact canonical configuration, including its initial seed. A same-plan retry resumes current state; it never resets the board or battle. A different plan cannot replace an active or unsettled battle. A terminal battle may be replaced only after an actual trusted settlement receipt is verified.

On restart, the native run record supplies its pinned `{battleId, contentId, configurationSha256}`:

```js
await session.openTrustedPlan(pinnedRunReference);
```

The coordinator validates the stored hashes/version and replays its legal intent journal from the immutable configuration before accepting the saved state. Edited HP, fake victory, inconsistent RNG/board state, added fields, changed command IDs, or a rehashed but invalid result fail. It does not trust a merely well-formed JSON save or its self-reported checksum. Exact validated storage tokens are cached so normal in-session reads do not repeatedly replay unchanged state. Reopening is data-integrity validation, not a repeated development test. Native integration should perform this work on the dedicated battle worker/JS context rather than block rendering with a worst-case journal replay.

## Page-facing API

Expose only these methods through the scoped native game bridge:

```js
await session.load();                // Current state only
await session.dispatch(command);     // Same {state,events,replayed} as engine
```

`load` is serialized behind `dispatch`. Dispatch commits the complete authoritative state before returning visual events. Two coordinators racing on one storage revision cannot both apply a choice. A compare-and-swap conflict reloads once: a same-intent winner returns as a replay; a different winning command makes the stale intent fail. Uncertain storage errors propagate so the existing view reloads/retries the exact original ID. No new animation, damage or reward event is emitted by a duplicate retry.

The battle view can use it directly:

```js
OfflineDokkanBattleView.mount(container, {
  load: session.load,
  dispatch: session.dispatch,
  onEvents: playVerifiedAnimationsAfterCommit,
  onExit: returnToGame
});
```

Do not expose `startTrustedPlan`, `openTrustedPlan`, the raw storage adapter or settlement confirmation through a normal WebView message handler. The module itself is not an access-control boundary; it runs in a native-owned scoped coordinator. Hashing requires actual SHA256 via Web Crypto (or Node's public Web Crypto implementation for cloud development), with no weak fallback.

## Result handoff

`pendingSettlement()` returns a native-only terminal descriptor with battle/content/configuration/state hashes, revision and `clear`/`failed`. It does **not** grant a reward or treat a page-provided win as a run result. `playing` and the unresolved turn-limit state do not produce a settleable result.

The trusted native run coordinator must validate the battle's actual source/run bindings and commit the corresponding result once through the existing core. Only afterward may it call `confirmSettlementTrusted(receiptId)`. The supplied `verifySettlement(receiptId, pending)` callback must query its actual durable ledger and return `{committed:true, receiptId, battleId, contentId, configurationSha256, stateSha256, outcome}` matching that exact terminal descriptor. A boolean, user JSON or a receipt from a different state is not accepted. The confirmation only records that an existing commit happened; it cannot create currency or characters. Repeating the same receipt is idempotent. A reopened confirmation is rechecked with the trusted ledger before the old battle can be replaced.

No actual core settlement adapter or native atomic-file implementation is claimed by this module. Those remain integration requirements. Without a verifier, results remain pending and a completed battle cannot silently disappear into a new one.

One focused `node offline-dokkan/gameplay/check-session.cjs` scenario passed: new coordinator reopening, a durable-write reply lost after commit, same-ID recovery, concurrent compare-and-swap winner/stale rejection, completed battle handoff, refusal of an uncommitted receipt, idempotent recorded settlement, rehashed forged-result rejection by journal replay, and permitted replacement only after trusted confirmation. The adapter faults were simulated to exercise these mechanisms; physical storage durability, native launch, source-character battle compatibility and real core rewards are **not** claimed. The previous unchanged turn-engine scenario was not rerun.
