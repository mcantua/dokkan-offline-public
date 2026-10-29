# Embedded Creator Finish boundary

The genuine hosted WK run `40780018874` failed with “This unit changed while preparing. Save it and finish again.” The JSON wire normalization already present did not resolve that failure. It must not be called fixed.

The old error combined four independent checks. `ui-adapter.js` now returns distinct, value-free error codes while keeping the exact same acceptance conditions:

| Code | Failed boundary |
| --- | --- |
| `CREATOR_PREPARE_DRAFT_REPLACED` | A different project object became the open draft while native preparation awaited. |
| `CREATOR_PREPARE_DRAFT_CHANGED` | The same live draft's JSON content changed during preparation. |
| `CREATOR_PREPARE_KEY_MISMATCH` | Native returned a project with a different key. |
| `CREATOR_PREPARE_SAVED_MISMATCH` | The returned saved JSON differs from the pinned live draft. |
| `CREATOR_IMPORT_DRAFT_REPLACED` | The open project switched while strict projection awaited. |
| `CREATOR_IMPORT_DRAFT_CHANGED` | The live draft changed while strict projection awaited. |

The visible editor maps these codes to plain-language messages. A caller of `OfflineCreatorUI.finish()` receives the code in `error.message`, so one necessary future genuine WK scenario can identify the exact failed boundary. No draft values, names, paths, keys, payloads or numeric samples are logged. The native saved-project hash, snapshot intent, strict projection comparison, stale checks and idempotent collection authority remain intact.

Static tracing confirms shared `flushSave()` clones the project before the asynchronous save; native `saveProject` freezes and persists the received JSON, and `offlineCreatorPrepare` returns that durable project. Static tracing alone does not establish which check failed in the genuine run. No speculative snapshot coercion, automatic overwrite, discarded field or relaxed guard was introduced.

One focused cloud Node check executed the actual Finish/normalization/error-mapping functions with a controlled async host boundary. A JSON-normalized unchanged snapshot reached import; each of the six distinct draft/snapshot boundary failures rejected before native import. An initial check fixture lacked `state.info.schema`; correcting that fixture allowed the focused check to run. This establishes guard preservation and value-free failure identification only, not a successful WK run or the native bug's root cause.

A browser-only attempt did not reach Finish: the default Playwright browser was absent, and the existing hosted artifact subsequently timed out during startup using the installed cloud Chromium. These are setup/startup failures, not native Finish evidence. No further browser startup loop, native build or full suite was run. Root should use the distinct code in the next justified, focused native cohort and keep the runtime bug pending until the actual discrepancy is corrected and verified.

## Focused genuine WK execution path

On the authorized ephemeral hosted `xcode-27` runner, run:

```sh
bash unit-creator/cloud-ui/finish-only-run.sh
```

This requires actual Xcode27.1, simulator SDK27.1 and the genuine iPhone Duo/iOS27.1 runtime. It never substitutes an ordinary simulator, edits an SDK mark or accesses Tin's Mac/phone. The isolated neutral simulator host runs the existing `ODCreatorController`, `ODCreatorSession`, strict projector and native C/SQLite services; it is an internal component check, not the original game or a production Offline Dokkan build.

Only Eclipse table rows are reconstructed from the existing committed HTML with the established checked reconstructor. No full web build, standalone/codec suite, ordinary iPhone target, Android work, device package or game-client launch is included. The single XCTest reproduces the prior save/prepare/edit/stale/forged/Finish/retry sequence, records the exact error code, and compares root fields/table columns and JSON types without scalar contents. It checks the selected master hash remains unchanged and captures the actual WK component state even on a diagnosed failure.

Upload only `unit-creator/cloud-ui/finish-work/evidence/`: `finish-only-result.json`, `finish-only-wk.png`, toolchain/provenance metadata and build log (optionally XCResult). Never upload the reconstructed `db`, simulator `.app`, private data container or `DerivedData`. Only the newly created simulator is shut down/deleted. The helper preserves any existing `finish-work` and requires a fresh ephemeral checkout.

Shell, embedded Python and the XCTest's embedded JavaScript passed syntax checks. Genuine hosted compilation/execution remains pending until the scoped root-owned workflow runs. A passing static check or generated source does not resolve the native Finish bug.

### First genuine focused run

Hosted run `40860320010`, source `3badaa020e7becc4ce52cf0889643f521a5e86e3`, compiled the isolated host/test with actual Xcode27.1 build27A9275, simulator SDK27.1, arm64 and the required Duo runtime. Artifact `12891736436` contains toolchain/provenance metadata and the build log. It failed before WK startup: the diagnostic waited30seconds for `profile.create`'s main-queue callback while its own main dispatch block spun a nested run loop. It produced no Finish JSON or WK image and supplies no evidence about the original snapshot discrepancy.

The diagnostic was corrected to use asynchronous core, WK startup, JavaScript and snapshot callbacks, each with a bounded deadline. No main-dispatch block spins while waiting for another main-queue reply. Early setup failures now also write a value-free JSON result. This specific harness failure justifies one focused retry; it does not justify a product guard change or rerunning the older unrelated native suites. The original Finish discrepancy remains pending the corrected genuine run.

### Actual saved-boundary failure identified

Run `40868354886` at `a5478ec9cd2046def164e951f8fe3f886d4e069f` reached the real hosted Duo WK editor. Startup passed; the selected reconstructed master was unchanged. Finish rejected with **`CREATOR_PREPARE_SAVED_MISMATCH`**. The live project matched the last submitted save; the earlier prepared snapshot differed only at `sourceStatGrowth`, with both sides objects. The sanitized result and actual WK image are in private evidence for this run. This is component evidence, not original-game or physical-device gameplay evidence.

The prior diagnostic retained the external prepare performed before `finish()`; Finish may hydrate growth before its own save/prepare. The guard now attaches value-free evidence from its **actual final prepare**: known growth fields, row-count agreement, first known `lv`/`coef` difference, JSON types, thousandth equality and one-ULP comparison. Its acceptance remains exactly unchanged. A synthetic native JSON probe in the same existing XCTest counts first/repeated Foundation numeric roundtrip changes across public `n/1000` examples and tests decimal-string stability. No game/user scalar is emitted. These changed-risk observations remain unexecuted until the next scoped hosted cohort; do not claim a numeric cause or a fix before that evidence.

The separate device-library component objects compiled with the actual27.1 SDK, but linking failed because its command lacked CoreGraphics/QuartzCore frameworks. Parent owns that narrow linker correction. This did not prevent the independent actual WK diagnostic from exposing the saved-boundary failure.
