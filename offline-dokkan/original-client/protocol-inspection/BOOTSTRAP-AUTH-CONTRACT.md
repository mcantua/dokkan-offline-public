# Established bootstrap facts for takeover

Development has resumed on the supplied iPhone6.6.0/build26093018 client. The original method/field facts below are retained, and the ordinary JSON response-root chain has now been recovered. `research/bootstrap-auth-contract.json` and `bootstrap-plain-json-root.json` record the exact source/body identities and limits without raw code, addresses, keys or account values. No original game was executed or built.

## Actual HTTP methods

Current `GET /auth/nonce` and `POST /auth/sign_in` are statically proved end to end. The nonce request constructor chooses kind0; sign-in's auth constructor chooses kind1. Their common request constructor stores that kind at member offset188. Both actual subclass vtables inherit the same slot17 method-kind getter and slot2 request materializer. The materializer copies the getter's result into the Cocos request method member at offset12. The original Foundation bridge indexes its actual four-entry table:0GET,1POST,2PUT,3DELETE, then calls `setHTTPMethod:`. This is current supplied-code evidence, separate from historical public client guesses. Native request execution remains unverified.

## Reader-relative response fields

- The120byte nonce DTO reader consumes `auth_transaction_id` and `nonce` through string conversion into two24byte string fields. The first field was verified by its exact source JSON lookup key; it is not the historical `captcha_session_key`.
- The396byte auth-token consumer reads `access_token` via string conversion and `expires_in` via the actual numeric-to-signed32 conversion helper. It stores expiry as native `time(NULL)` plus that signed duration. A string `expires_in` enters the unsupported/error conversion path; use integer duration as the canonical candidate shape.
- No actual auth secret/captcha success field was admitted. A generic `secret` literal reference resolved to unrelated option-handling code and was expressly rejected as auth evidence.

**Ordinary JSON envelope recovered:** the current request materializer calls the completion installer, which copies its success/failure holders into the exact HTTP-completion callable. That completion parses the response-data string into one JsonCpp document and passes that same value to the consumers. It selects no `data` or other child wrapper. Its response content-type predicate distinguishes `application/x-zstd`; the new candidate uses `application/json`. Field-requiredness, nonce/transaction value encoding, complete sign-in success fields and actual runtime acceptance remain unverified. This root-shape proof does not admit a route or establish successful login.

The nonce reader's only discovered direct caller was an alias thunk; the next caller was bounded to200bytes but was not inspected before stopping. The token consumer has a single vtable pointer reference. These existing private references are in `private/source-response-cache/auth-reader-callers.private.json` and `auth-reader-next-callers.private.json` for a future authorized session; no private payload is involved.

## Initializer and privacy boundaries

Actual profile initializer facts are separately retained in `research/original-profile-initializer-contract.json` and `PROFILE-INITIALIZER-CONTRACT.md`. Tutorial0/0/finished=true and zero capacities are pre-server native sentinels, not proved playable new-account defaults. Resource-cache schema evidence is separate and removes every scalar player/account value. No credentials were extracted, no played-state values adopted, no account/game service contacted, and no app was executed or package built for this analysis.

`protocol/bootstrap-auth.js` now exposes `issuePlainJSON`; native `ODOfflineBootstrapAuth` exposes `issuePlainJSONWithNativeTime:expiresIn:error:`. Both encode the two root-shaped body candidates from one in-memory local issue. These are ready for the next transport integration, while full-success, route and runtime flags remain closed. The legacy base issuer keeps its previous reader-relative behavior. Do not log or persist the candidate token strings. Next recover complete auth success/request state and bind the actual native transport; confirm the path during a future authorized original-client run. Original source/server account keys must never be shipped.

The native class also has `candidateRoutesWithExpiresIn:contextIsCurrent:error:`.
It creates the two local handler objects without installing them. A nonce request
rotates the local in-memory issue; sign-in returns that issue's token candidate
and supports a same-issue retry. Missing/expired nonce state and a stale owner
predicate fail closed. Only local randomness is used; source credential headers
and request bodies are neither read nor forwarded by these handlers. The host
still rejects auth routes. Native compilation, delivery/invalidation behavior,
pre-auth commands and actual login remain unverified.

The continuation is in `research/bootstrap-upstream-success-frontier.json`.
The actual transaction's typed factory reaches the current sign-in constructor,
but its run queue also contains pre-auth and intermediate authentication stages.
The 64-byte success callable preserves the JSON reference in x2 through its
virtual call; an earlier pseudoC-only reading incorrectly omitted that argument
and was corrected by exact instruction review. The default model success event
does not itself read extra JSON fields. That fact alone is not full startup proof.
