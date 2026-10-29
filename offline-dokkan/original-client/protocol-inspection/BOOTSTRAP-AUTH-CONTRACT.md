# Established bootstrap facts for takeover

Development stopped at Tin's request for Grok takeover. The following facts were already established against the supplied iPhone6.6.0/build26093018 main; no new research, disassembly or tests were performed after the stop. `research/bootstrap-auth-contract.json` records the original executable hash and ten bounded body hashes, without raw code, addresses, keys or account values.

## Actual HTTP methods

Current `GET /auth/nonce` and `POST /auth/sign_in` are statically proved end to end. The nonce request constructor chooses kind0; sign-in's auth constructor chooses kind1. Their common request constructor stores that kind at member offset188. Both actual subclass vtables inherit the same slot17 method-kind getter and slot2 request materializer. The materializer copies the getter's result into the Cocos request method member at offset12. The original Foundation bridge indexes its actual four-entry table:0GET,1POST,2PUT,3DELETE, then calls `setHTTPMethod:`. This is current supplied-code evidence, separate from historical public client guesses. Native request execution remains unverified.

## Reader-relative response fields

- The120byte nonce DTO reader consumes `auth_transaction_id` and `nonce` through string conversion into two24byte string fields. The first field was verified by its exact source JSON lookup key; it is not the historical `captcha_session_key`.
- The396byte auth-token consumer reads `access_token` via string conversion and `expires_in` via the actual numeric-to-signed32 conversion helper. It stores expiry as native `time(NULL)` plus that signed duration. A string `expires_in` enters the unsupported/error conversion path; use integer duration as the canonical candidate shape.
- No actual auth secret/captcha success field was admitted. A generic `secret` literal reference resolved to unrelated option-handling code and was expressly rejected as auth evidence.

**Unresolved envelope gap:** these are fields relative to the JSON value delivered to each reader. The complete HTTP-body root versus a `data`/other wrapper was not yet traced through generic response processing. Field-requiredness, nonce/transaction value encoding, complete sign-in success fields and actual runtime acceptance remain unverified. Do not label a complete server response or enable a route factory based on these facts alone.

The nonce reader's only discovered direct caller was an alias thunk; the next caller was bounded to200bytes but was not inspected before stopping. The token consumer has a single vtable pointer reference. These existing private references are in `private/source-response-cache/auth-reader-callers.private.json` and `auth-reader-next-callers.private.json` for a future authorized session; no private payload is involved.

## Initializer and privacy boundaries

Actual profile initializer facts are separately retained in `research/original-profile-initializer-contract.json` and `PROFILE-INITIALIZER-CONTRACT.md`. Tutorial0/0/finished=true and zero capacities are pre-server native sentinels, not proved playable new-account defaults. Resource-cache schema evidence is separate and removes every scalar player/account value. No credentials were extracted, no played-state values adopted, no account/game service contacted, and no app was executed or package built for this analysis.

The next useful authorized step is the narrow caller/generic-response envelope trace, followed by a local bootstrap candidate using only its own random transaction/nonce/token and signed32TTL policy after the actual response contract is complete. Original source/server account keys must never be shipped. Root's native diagnostic observer can confirm current method/path at actual startup when native execution becomes available.
