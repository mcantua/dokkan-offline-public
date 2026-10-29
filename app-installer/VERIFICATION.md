# Executed verification and remaining evidence

**Current public revision (October29,2:03 PM Central):** Public Rust pairing/recovery14 plus first-account/TLS3 and native3 have actual passing proof. Native compilerSDK27.1/componentruntime27.0; physical Duo remains unverified. Package-only40934237282 succeeded with both unsigned candidates, full source and sealed minimal kit; actual artifact hashes match. Independent artifact review and hosted Mac-signature/public draft delivery are active; Apple/device acceptance remains pending. See [current source/evidence](device/PUBLIC-CONTINUATION.md). Historical entries retain their original scope.


These are measured checks, not an overall readiness percentage. Cloud compilation is not proof of Apple-account or iPhone behavior. Tin now reports manual Mac signing/export/install and physical launch of the old app; its sign-in crash and pending corrected-build retest are recorded separately below.

## Latest first-account startup fix — 2026-10-28, 5:10 PM US Central

Tin reports that the4ad helper signed/exported/installed compiled8eaf and the app opened manually on the physical phone, then crashed during sign-in after the reported authorization/Touch ID step. This is a reported bootstrap/launch milestone, not successful in-app authentication or the crash's exact device backtrace.

Reqwest0.13 configured with rustls-no-provider panics on HTTP-client construction if no process-default CryptoProvider is installed, even when ring is compiled. Commit7059c85ad55645ef57db9f8de287e6a66b8c122e initializes ring at ai_initialize and defensively before account_builder. This is a real startup defect, not yet a device-confirmed crash resolution. **Physical crash resolution remains unconfirmed until the corrected build is installed and retested.** Native biometric/Keychain review found no separate cause; biometric/session protection was not weakened.

Run https://github.com/mcantua/claude-chatg/actions/runs/40777027792 succeeded with only the affected checks:

| Check | Actual result and scope |
|---|---|
| Fresh-process first-account HTTP constructor | 1 passed,0 failed,0.01seconds; starts without a global provider, uses actual ai_initialize and actual RemoteV3 client |
| Relevant pairing TLS | 2 passed,0 failed,0.01seconds |
| Earlier core/vendor/native tests | Not repeated; prior22-check proof remains8eaf-scoped |

The dedicated integration-test process prevents unrelated TLS/unit tests from masking the first-client bug by preinstalling the global provider. It constructs the actual client against example.invalid without sending requests or using credentials, then checks idempotent initialization. Logs and source context are in downloads/completion-verification/login-startup. This proves constructor/TLS behavior, not real Apple-service communication.

Actual new local receipts identify7059c85, source fingerprint0f305e96ea438eb46275184018c21ce2987d08314a09cf849e4d38379d0e5d42. Source78,336,612bytes SHA1ba83e045df171a3ca51bc7b1b44aaec131f6489e07d73778b6fafeb917e95cf; kit35,149,949bytes SHAe814dd588ff46be402d0372e2f66ce2154f5e3661a3ded93224bb0f1bfe41bf6. Both remain unsigned candidates/release_readyfalse. Private draft transfer40778539399 passed with all9 actual server hashes/sizes and2 unchanged fixture IDs; physical update/retest remains pending.

No final release or corrected-device success is claimed. Broader capability adapters/limits are unchanged. Existing approved manual setup scope persists; next action is the verified existing-folder kit merge, then same-identity update and physical sign-in retest.

## Earlier review checks and matching package — 2026-10-28, 3:46 PM US Central

Run https://github.com/mcantua/claude-chatg/actions/runs/40764445110 succeeded at source `8eafc2379d875d702a704a524a28982ccf66d598`. The changed Rust/vendor closure actually executed: **22 offline checks passed** (19 core,2 TLS,1 vendor response). Older unchanged-input proof was not reused.

| Selected check | Actual result |
|---|---|
| Production core, including install-version/self-transition regression | 19 passed, 0 failed, 9.14 seconds |
| Pairing TLS | 2 passed, 0 failed, 0.01 seconds |
| Vendor install/lookup error-response regression | 1 passed, 0 failed, 0.00 seconds |
| New native pending-authorization cancellation method | 1 passed, 0 failed, 0.133 seconds |
| Prior targeted helper receipt checks | 2 passed, 0.024 seconds; not repeated in this run |

The native method is `testCancellingOrdinaryPendingAuthenticationRejectsDelayedSyntheticSuccess`, using delayed synthetic authorization success to exercise production cancellation/generation guards. It proves the selected hosted cancellation behavior, not physical FaceID. Other eight native methods were not repeated. The8eaf core/TLS/response logs are in downloads/completion-verification/hosted-core; native result excerpt is downloads/native-ci-evidence/run-40764445110-test-excerpt.log.

The run also passed genuine Xcode27.1/device SDK27.1 Rust/native compilation, both actual unsigned-candidate gates, complete corresponding-source/relink checks and bootstrap project/kit assembly. Production fingerprint: `8d7ddcc0250145a1694808922a2a17e2cae9a0a8b3a3a1d4146c2ed5c892df45`. Locked dependency graph remains `28d6828268adaa9378e9da51b14fd26c0825befaf256a25d79ba12268d802430`.

| New packaged asset | Bytes | SHA-256 from visible8eafc23 receipt |
|---|---:|---|
| iPhone unsigned candidate | 5,537,316 | 6bade2bf7847ffa746b5485d03cd3ac4c52a7004c3e8c767ecee7958a5c7ad77 |
| Duo unsigned candidate | 5,537,320 | bcb7071e576d849fa848d1bf81757107857b5a93b4bf777c6d1cf005c65220fb |
| Complete source/relink | 78,328,952 | fd1797027192b6c7fa205cb512acf351bac6960e90654294e0e4f16a4339b9d4 |
| Native setup kit | 35,147,765 | 16b1d190a2fb4773d2e197992044dc7fe9456f1021c2b8b79a6e5bd9b559d5b4 |

Root verified and replaced all seven current local assets from this passing commit. Private draft transfer40766402789 passed; all9 server asset hashes/sizes,2 unchanged fixture IDs, source target and explicit draft tag verified. candidate-promotion-report.json and draft-release-state.json retain actual receipt/state. No final release: `release_ready=false`. Broader capability adapters and their documented limits are unchanged. Live Apple/free+paid/signing/install/update/refresh, real biometric/recovery behavior and physical Duo acceptance remain0%. Tin postponed Mac attempts; respect that pause and keep existing approval scope without repeated power/attachment requests.

## Earlier focused UI and matching package — 2026-10-28, 3:06 PM US Central

Run https://github.com/mcantua/claude-chatg/actions/runs/40758076164 at source `eeae1484059827148fda8f240e1c480f96bbcdf2` passed exactly the two new affected native methods: `test03AccessibilityTextKeepsControlsReadable` (7.552 seconds) and `test04KeyboardKeepsFocusedFieldsReachable` (4.020 seconds). Result: **2 passed, 0 failures, 11.573 seconds**. Genuine hosted arm64/Xcode27.1/iOS27.1/iPhone Duo, no ordinary-iPhone fallback or panel mutation. Six earlier passing native methods were not repeated.

The production UI now accommodates maximum accessibility text and actual public UIKit first-responder keyboard notifications/guides. Original narrow/wide main AX images and email/password/code keyboard geometry are retained under downloads/native-ci-evidence. The blank narrow AX Settings image was discarded; its layout assertions passed but it supplies no appearance proof. Keyboard attachments contain field names/geometry only; TEST-ONLY form metadata caused no account request. This is simulator layout/keyboard evidence, not physical VoiceOver, typing, folding or phone proof. The source report's native-pass flag predates XCTest; the raw result excerpt supplies the actual two-method result.

One matching genuine-SDK package run https://github.com/mcantua/claude-chatg/actions/runs/40759202354 then succeeded at the same source. Mandatory device/native compilation, both actual candidate gates, matching complete source/relink and bootstrap project/kit checks passed. Source fingerprint: `d70f9f95d0d33df5d8fe6ebad4935312a6b630eb7a109f2114747475cc502704`; locked graph remains `28d6828268adaa9378e9da51b14fd26c0825befaf256a25d79ba12268d802430`. Original18 core +2 TLS successes were reused only after all198 Rust inputs and raw logs matched; no new core/TLS execution is claimed.

| New packaged asset | Bytes | SHA-256 from actual receipt |
|---|---:|---|
| iPhone unsigned candidate | 5,531,205 | e8cab831947d7607337d1326f1358a1527123fd1e4029934db4a3e177767b1ad |
| Duo unsigned candidate | 5,531,209 | 083973b1dc6ab9866774735bd29a56a845014dae91aa1617a1fb39eb9ea62fc9 |
| Complete source/relink | 78,319,664 | d4bb15730d1071a2d0f2cc3ab601a85740ff82c7750b2fd6ebac27ac483110a0 |
| Native setup kit | 35,118,739 | 1c96294072b291063a6508133ae8db1a812562c1f00db4dfab8a2081cf418525 |

Root verified the downloaded artifact/member bindings and replaced the seven current local assets in builds. Promotion40760869486 passed with9 exact server asset hashes/sizes and2 unchanged fixture IDs in the same existing private unpublished draft. candidate-promotion-report.json and draft-release-state.json retain the actual receipt/state. Initial transfer40760625996 replaced the assets but stopped after GitHub reset an omitted draft tag; restoring and explicitly preserving tag_name corrected this metadata issue. Recovery repeated no app build/test. Both candidates retain `release_ready=false`. Apple auth/signing/install/update/refresh and physical Duo acceptance remain0%. MacBook is off; prior approved routine setup scope persists, while significantly larger Xcode installation and Apple-credential changes retain their separate approval boundary.

## Approved physical setup continuation — 2026-10-28

User approved personal MacBook/USB Duo/network/kit/pairing/trusted dependencies, reserving significantly larger Xcode and Apple-credential changes. After an earlier pause, Tin resumed manual setup and reports native signing/export/install and physical launch of the old app before its sign-in crash. Direct Mac execution remains unavailable in this conversation. Corrected7059 update/retest is pending verified delivery; no new old-build action is requested.

Two targeted mocked local-preflight tests passed for genuine full-Xcode selection/SDK ordering, Python3.9 acceptance/older rejection, CLI-only/oldSDK and first-launch/license errors. These are setup-logic checks, not observations of Tin’s Mac. Helper-only run40754015680 passed on ubuntu with no Rust/native test/compiler action: proved protected production inputs unchanged from0e48c9e, verified old complete kit payload, replaced only four committed helpers/docs, reused exact compiled library/source binding and verified the new draft pair before removing old kit assets/artifact. Historical helper-only proof is in downloads/completion-verification/candidate/kit-refresh-report.json; the current kit receipt is builds/AppInstaller-native-bootstrap-kit.json and now identifies the7059 package above. All existing20core/TLS and6native proof remains unchanged; none repeated for this fix.

## Current completion pass — 2026-10-28, 2:00 PM US Central

- Hosted run40735921274 at c5d1e4ef89c8dee95b4fc622af6180d1d5f2b4cb passed **18 production core + 2 pairing TLS tests**. That older proof was reused only while its entire closure matched. The current hosted-core records are superseded by the freshly executed8eafc23 results above; changed inputs cannot reuse the earlier proof.
- All six previously named notice cases have package-bound grant/attribution evidence. Actual target notices cover307 packages with0 gaps. Earlier offline source/relink extraction compiled with an empty Cargo cache; matching current candidate/source delivery subsequently passed40759202354 and private draft promotion40760869486.
- Genuine hosted Xcode27.1/build27A9275, device/simulator SDK27.1, iOS27.1 runtime and iPhone Duo type are verified. Device Rust compilation passed in run40744990057. No source is relabelled as a newer SDK.
- Earlier in this completion pass, native XCTest methods had not yet passed. A compile-only macro error was fixed. Later Duo SpringBoard aborted in its display transformer before the application was installed. Subsequent preflight fixes handle unregistered or absent Simulator.app by using supported headless simctl. A fallback, if necessary, is explicitly ordinary iPhone proof only.
- Candidate packaging found Cargo vendor omitted112 Git metadata files. Only missing .gitignore/.gitattributes are restored from checksum-matched original crates; changed metadata and any source omission still fail. The affected source-delivery check passed after correction; full matching packaging is running separately from native checks.
- Package40747677006 from clean0e48c9e succeeded: both genuine-SDK candidates, matching source/relink and minimal native bootstrap project/kit passed. All transferred file hashes and the full inner kit file manifest matched. Draft transfer40749506524 then preserved nine exact assets in the existing private unpublished draft, checking server-side digests without recompilation.
- Native40747684017 actually launched on a healthy genuine Duo, with no ordinary-iPhone fallback and no display-power mutation. Five of six XCTest methods passed, including real disposable-simulator Keychain metadata/add/delete guards and both refresh lifecycle methods. One responsive fixture failed four rail assertions because its manually reparented navigation controller did not adopt the requested safe-area inset synchronously. Harness-only3378826 now models the labelled geometry directly, preserves rail/touch/no-overlap/state assertions and adds explicit input-geometry assertions. Responsive-only follow-up40749191964 passed exactly1method/0failures in3.366seconds; five unchanged passing methods were not repeated. All6 native methods now have passing evidence across these focused runs. Root inspected settled production login/settings plus original responsive wide/side-rail captures in downloads/native-ci-evidence/images; geometry fixtures remain explicitly TEST-ONLY. The pre-test source report is retained unchanged, so its conservative duo_native_tests_verified=false is superseded only for the actual native methods by the raw result excerpt, not by a hardware claim.
- The optional screen-power driver described in ios/display-evidence.md is not invoked in the current baseline. Live panel transitions and physical folding remain unverified. That historical implementation description is not a current execution claim.
- All live Apple auth/signing/install/update/refresh, real Keychain/biometrics, and physical Duo dual-display/touch/fold checks remain unverified. Earlier historical results below describe earlier source only.

## Resumed cloud pass
| Area | Executed evidence | Result / limit |
|---|---|---|
| Pairing TLS | Two tests use production client config, generated RAM-only keys, actual TLS1.2/1.3 handshakes and encrypted application data | PASS: correct pin/signatures accepted; substituted certificate and genuinely tampered server signatures rejected. No sockets or live phone. |
| Durable cleanup | Two grouped tests exercise production retry loop through fake AFC | PASS: cancellation/failure retains intent; success/absence clears; foreign paths never deleted; duplicate requests delete once and bounds enforced. |
| App identity/update | Two grouped tests include actual upstream Application and written main/extension plists | PASS: stable raw/resigned imports, team namespace, self/external identity preservation with ownership evidence, cross-team conflicts and long IDs. No Apple registration. |
| Entitlement gate | Two grouped adversarial tests | PASS: every FAT slice, overlap/duplicate signature slots, XML/DER consistency and strict typed basic entitlements. Noncanonical/unsupported encodings fail closed. |
| Native flow corrections | Read-only cross-component review found actual timeout/error/progress/task-ID issues; code corrected | PASS: integrated native compilation/link succeeded in the fresh-prefix build. Actual UIKit execution also passed on the hosted simulator; see the result below. |
| Clean-prefix reproduction | One full fresh setup found rustup auto-update flaw; corrected Rust-only second setup passed with pinned rustup1.28.2/Rust1.99.1 and auto-update disabled | PASS: fresh LLVM/SDK and305 newly downloaded registry crates produced both gated packages from an initially absent target in92.69seconds. Declared pinned host-runtime dependencies were reused explicitly; first-setup and corrected Rust-only phases are recorded in downloads/repro-check/SOURCE.md. |

Task test execution stayed targeted: TLS two invocations (first compile-only error fixed); cleanup one; capability two (first compile-only error fixed); identity two completed runs with one intervening compile-only interruption from another owned module edit. No blanket repeated suite or live account calls.

## Behavior still unverified
- Real Apple SRP/2FA/team/provisioning/certificate responses and free/paid device quota accounting.
- Actual device TLS legacy-algorithm compatibility and LocalDevVPN loopback installation.
- iOS Keychain/Face ID/enrollment/backup migration and locked-device/background timing.
- In-app installation/update/self-refresh, including app termination during self replacement. Reported bootstrap installation/manual launch does not prove those workflows.
- Physical Duo folding/rail/VoiceOver/large text and actual hardware behavior. Hosted accessibility-layout proof does not establish physical acceptance.
- Final signed usable release acceptance remains pending. Latest unsigned package/source/relink integrity passed40764445110; current private draft promotion40766402789 passed. The six historical notice gaps are resolved.

The latest completion instruction permits real installation with the recorded setup approval and actual authorized access. Tin has granted that routine scope; do not ask again. Tin postponed Mac connection attempts; leave them paused without current action requests. Ask only if later resumed work encounters a significantly larger Xcode installation or Apple-credential change reserved by Tin.

## Hosted simulator result
Latest successful run: https://github.com/mcantua/claude-chatg/actions/runs/40719541467 at source1bdb7260b9c2a39667b44a71db10a0971002404d. GitHub-hosted arm64, Xcode16.4/iOS18.5; both actual XCTest methods PASS,0 failures,1.208seconds. Initial production login/Settings ran with empty fields and no account operation. Main controller uses a clearly labelled test-only metadata fixture at390/466/669/951point widths; it is not account/install or physical Duo proof. Original captures/provenance are in downloads/cloud-ui-evidence/. Root inspected login, settled Settings and wide fixture captures.

Two earlier infrastructure attempts executed zero XCTest methods: first an unsupported XcodeGen dependency key, then a missing static-library search path. Both were corrected from observed errors. The next run passed both methods; screenshot review found a mid-transition Settings capture, so a second runtime pass added transition completion/full-width assertions. That final run passed both methods and the settled screenshot was inspected. No repeated blind suite. Xcode emitted a benign UIDeviceFamily-overwritten warning because its target build setting controls that value; the Linux release pair remained warning-free.

## Real manual setup observation and device-selection correction
User screenshot, October28 approximately4:26PM Central: approved Mac launcher ran and reached local iPhone selection, then stopped with “The physical iPhone hardware UDID was not reported.” No account discovery, signing, provisioning or installation was reached by this path. This does not establish a physical device acceptance pass.

Corrected4ad510a: device list alias is used only to query selected device details; actual model/UDID validated before account discovery. Two targeted mocked regressions passed/0failures/0.003seconds, covering omitted-list-ID success through details and refusal of missing/alias/wrong-model details. New tool still needs real Mac retry. Helper-only40772688085 passed without app compilation/core/TLS/native-test repetition; source8eaf/fingerprint/library/source/IPAs unchanged, seven non-kit assets preserved. Current kit receipt/source and kit-refresh-report.json are authoritative for the newer tool revision.
