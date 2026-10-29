# Original iPhone/Duo integration

This directory contains authored components for the supplied original iPhone client. It preserves the original engine and presentation as the production foundation. It is not a replacement game or a runnable release yet. The frozen mobile save-manager and authored battle harness elsewhere remain internal tools.

Tin's active target is the complete unified Duo app: actual offline gameplay plus the full integrated Unit Creator, saves, custom units and both displays. Ordinary iPhone and Android target work is on hold until Tin accepts Duo and explicitly authorizes starting another version. Shared Android source data may be examined when needed by Duo.

## Components and integration boundary

| Component | Implemented | Still required in the original client |
| --- | --- | --- |
| `../tools/objc_runtime_metadata.py` | Bounded static arm64/chained-pointer inspection and exact allowlisted ABI evidence. | Concrete argument classes, code paths, ownership/thread behavior and current game-response contracts. |
| `ios/` | Exact HTTP ABI preflight and in-process, bounded local URL transport with explicit origin/method/path admissions and no network fallback inside that transport. | Trusted original-client bootstrap/attachment; verified responses and all other network paths. No route or fake login response is supplied. |
| `duo/` | UIKit geometry/reserved-region capture, safe aspect/touch helpers and optional verified renderer-layout observation. | Genuine SDK27.1 scene integration and application of actual original renderer/camera/drawable/touch coordinates, followed by both-display acceptance. |
| `../content/iphone_asset_catalog.py` | Hash-pinned byte-identical resource admission into the native content resolver's catalog format. | Actual resource-path attachment, complete dependencies and format/codec/runtime verification. Most examined Android/iPhone resources are not byte-identical. |
| `master/` | Read-only source/schema admission and existing-column/type checks for strict settings definitions. | The pinned full current master, original-engine row lookup/ID/reference/owned-instance bindings, and custom-unit consumption in real battles. Column admission never grants runtime readiness. |

The original inputs stay read-only/private. `../research/SUPPLIED-CLIENTS.md`, `IOS-RUNTIME-CONTRACTS.md`, `IOS-ASSET-COMPATIBILITY.md` and their sanitized evidence record actual hashes and results. No original executable, patcher, database, source-account state or keys are included in this source directory. A host must independently pin its original executable/catalog/master; matching runtime ABI alone is insufficient.

## Continue integration

Connect only contracts established from this exact client. Preserve the existing durable core/strict Creator validation and original game behavior; authored internal policies are not verified Dokkan mechanics or wire responses. Reject unsupported operations explicitly rather than fabricating successful replies or silently ignoring custom settings.

The original executable is currently marked SDK26.0. Changing that number does not establish a genuine SDK27.1 build or full Duo layout. Geometry observation alone does not resize a Cocos framebuffer or prove touch mapping. Likewise static method encodings, byte-identical CPK/ACB/AWB containers and admitted SQLite columns do not prove gameplay.

Grok recorded the exact-growth hosted Finish fix in run40891656259 before this public snapshot. Reuse that limited evidence; the obsolete unresolved-precision wording in older diagnostics does not require another run. This integration draft adds full-bundle validation and late-binding source, but neither the combined native host nor full-unit gameplay has been compiled or exercised here. All stale/snapshot/scope guards remain required.

Reuse the component checks already recorded for this cohort. Run additional checks only for an actual integration change/failure. No original game launch, offline battle, finished custom-unit battle, genuine SDK27.1 attachment, physical installation or both-display acceptance has been demonstrated by these component results. Do not package/release the old save-manager as the game or automatically start another platform after a Duo checkpoint.
