# Own-export resource-response schema

The user-provided `Sparking-saves-and-settings.tar` is12,932,096bytes, SHA256 `bd46997a0fcae532138baf1fd2b4456f7dc8ed7cf290449072337defed2bb32f`. The source export identifies Android6.6.0/code351; the cached response's producing client version is not independently embedded/verified. The original remains private in Drive. No source-player state, credentials or scalar response values are adopted.

## Metadata first, schema only

The initial TAR pass read headers only:107regular files/72directories. Credential/settings-class entries were excluded. One regular4,363,742byte JSON response candidate was identified. Root was notified before opening that payload. A strict bounded read parsed it in memory and produced field/type metadata through the existing schema redactor. No raw member was extracted to a file.

Its exact reviewed fixed basename is `resources_login_response.json`. The same literal and `/resources/login` each occur once in the actual Android patcher (`libbase.so`, hash pinned in the project input notes). This strongly grounds the resource-login role. It does not independently establish an HTTP method or iPhone runtime compatibility. Public historical client code uses GET, but that remains separate historical evidence.

## Retained evidence

- `research/cached-resource-response-schema.json` contains schema only, pinned archive/member hashes, the reviewed cache basename, provenance and limits.
- `cache_field_vocabulary.json` freezes96additional reviewed structural field labels. Each is an actual cache dictionary key, a nonopaque lowercase identifier, and an exact NUL-boundary literal in one or more pinned actual client/patcher binaries. All scalar values remain removed; dynamic ID/opaque map keys remain `[redacted-key]` with collision/type metadata.
- This exposes46named root fields. Five unproved root names remain redacted; their existence/types do not authorize inventing names/defaults. Unknown dynamic nested keys are likewise redacted.
- New reviewed root labels include `battle_status` (object), `card_skin_items` (array), `jukeboxes` (object), `kobetu_card_limitations` (object), `link_skill_lv_up_items` (array), `special_items` (array), and `support_memory_enhancement_items` (array).
- `tutorial` is an object with integer `progress`, integer `contents_lv` and boolean `is_finished`. Integer capacities/boost/gasha fields and boolean extended-capacity flag are observed types only. Played-cache numbers/flags are never fresh-player defaults; obtain rules from actual master/client behavior.

`extract_cached_response_schema.py` reproduces this from a caller-hash-pinned bounded TAR. It selects only that reviewed fixed response member, applies the explicit vocabulary and creates a new schema output exclusively. It never contacts an account/game service, extracts raw save members, copies scalar values or alters fresh-player/core state. Other archives receive unverified provenance, not the known source version.

## Current method/bootstrap limits

The small8KB possible cache DB was deserialized in memory and its schema inspected; no table row was read. No reviewed HTTP method/route/URL column was established. Other JSON headers do not identify an auth/nonce/sign-in response cache, and their credential/settings payloads remain unopened. No recognized fixed noncredential network-log/HTTP-metadata filename was found.

The current iPhone source response dispatcher compares parsed path strings; no method+route constant was established there. A bounded actual Android patcher literal/reference investigation established resource-login/cache-file references but did not establish GET/POST control flow. Do not turn historical GET evidence or this filename alone into an asserted current request-method observation.

This is observed server-response shape, not requiredness/default/config proof. Arrays are sampled to64items, objects to256members and depth to16 by the existing redactor. Do not serialize redaction placeholders into a game response. Missing game-wide configuration must come from permitted master/assets or independently verified structures, not the private played-account cache. Local projections must use the fresh own player/save and remain explicit about unresolved method/client/runtime requirements.
