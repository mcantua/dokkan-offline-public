# App Installer — active signing/recovery batch

Public repository only: `mcantua/dokkan-offline-public`, branch `chatgpt/app-installer-pairing-repair`, draft PR#7. Tin resumed all App Installer work and cloud builds remain authorized. Other projects belong to their own conversations. Never merge base/main or publish without approval.

## Implemented and checked

App production8e9b43ce adds bounded64KiB resource hashes; controlled resource/executable/page/verifier cancellation and whole-operation deadline; native continuous-monotonic5minute expiry with stale-generation guards, direct no-UI Rust/C lease checks and independent100ms install monitor; source-directory fsync before installed metadata/journal cleanup; and a declared128MiB file-rewrite/4MiB signature budget with fallible bounded reads plus cancellable sequential file lease. Oversized/changed inputs have useful fixed errors; resources are not capped at128MiB. Executable file-backed support above that ceiling remains a genuine backend limit, not an Apple entitlement restriction. Individual syscall/crypto/check-write races remain cooperative, not atomic rollback.

Fresh hosted41310143960 at8e9b43ce SUCCESS: transport2/0=.37s, recovery2/0=.04s, native4/0=5.952s. Xcode27.1/SDK27.1, regular iPhone18ProMax runtime27.0; NOT physical/Duo/auth success. Original vendor8/helper2 reused. Three individually justified focused signer2/0 invocations addressed newly found resource, executable-cancel and memory gaps; final memory methods=.25s with27unchanged source hashes. Earlier Linux synthetic signer/verifier2/0=9.34s has its own prior source scope. The supersededc40 hosted41308375871 was cancelled after discovery of the memory gap; historicalcore4/nativecompile only, no native pass claim.

Matching package-only **41311226478**, source **b45c705e5fde11a5c07bed590cc4a4643a24f1e4** (documentation-only descendant of8e9) is in progress. It reuses matching existing proofs and runs no new tests. Preserve existing verified7-file draft430349496/current distribution until final artifact/source/kit/actualMacsignature/server-pin checks pass. Do not substitute another stale kit or claim final signing/phone acceptance. Package results/pins will be appended below when known.

Full proof at `downloads/completion-verification/public-pairing/resume-20261101/`; current run413101 includes raw logs/preposthashes, toolchain/source report, one original compressed native artifact and3untouched UIKit fixture PNGs with8attachment refs/hashes. Older compressed native archive removed only after replacement verified; historical compact evidence retained.

Dependency graph073cbb40839821536762df4491e1a5807a290c9fd9f8fce0776f579a40777fd7;408 packages/0notice gaps; unchanged versions/features. Modified LGPL signer source/grants/lineage and complete source/relink delivery remain mandatory. Recipient Cargo instructions now name the actual core manifest. Do not repeat unchanged suites or builds for minor docs.

## Read-only path incident — do not repeat

One supplementary reviewer used the wrong inherited frozen checkout for capability/setup source inspection and Git file history. This violated Tin's no-access instruction. No writes/builds/tests/config/key/pairing/save-file access were reported; root did NOT reopen it to audit. The agent was stopped, findings excluded, and relevant source independently checked in the actual public HEAD. No app change/test/build derives from those reads. Root disclosed this to Tin and corrected current STATUS/continuation/shared Drive. The b45 package memo predates discovery and its absolute no-frozen-read sentence is incorrect; current records are the erratum. Ledger: `review-boundary-incident.json` in the proof folder. Every future tool command must pin `/workspace/AI-Workspace/dokkan-offline-public` before any read; do not rely on inherited cwd or audit the frozen repo.

## Real completion boundary

No personal Mac/USB capability, VPN or device endpoint is configured in this cloud environment. Scoped Mac/USB/network setup approval persists but does not create control. Announce exact step/resources/connection known or unknown/bytes before personal use; do not ask again for already approved routine work. Major Xcode or account/certificate changes need separate approval. Keep account/password/2FA/signing/pairing data local to authorized Apple/device UI, never chat/GitHub/Drive.

Use verified minimal public-folder overlay, same installed bundle/team identity and compatible importer. Pair only skips account/build/install/launch; raw credentials stay local, allowed progress streams live. No uninstall/trust reset/data clearing/private-backup copy. Real Apple auth/profile signing, session/install/update/refresh/security/recovery and both-display/touch/fold acceptance remain unverified. No100%/final-release claim. Continue independent actionable work; documentation is not completion. Verify explicit Drive writes/readback; no automatic cross-chat sync.

## Matching package result

41311226478 SUCCESS fromb45c705;0fresh tests,18prior matching methods reused. Source/IPA full verifier passed in10.152s and independent portable kit review in0.615s:38payloads/24required source bindings; all notices/graphs/helper/universal Mach-O receipts agree. SourceFPf66a5e7923e4501e8ced127e8aa580b9cca16b2ed1d536ab64994ec12e46e918, graph073cbb40839821536762df4491e1a5807a290c9fd9f8fce0776f579a40777fd7. Kit44,228,257bytes SHA88e1aab0ca98a5e2187471d42dba7d047c2438703588898d201e01dd62483391. Full7-file +2outer pins are in the reviewed public-delivery contract. Actual separate hostedMac signature/draft delivery is next, not yet claimed.

## Backend delivery and continued actual UI work

Mac signature/delivery41313262648 SUCCESS at7416eee; independent server/receipt verification matches all7pins in the sole430349496 draft. Root retired obsolete local files only after new data verified, retaining exactly7b45outputs and no backup/outer ZIP duplicates. Do NOT recommend the intermediate download: actual max-AX PNG has a sliced status line although controls tests passed. Root continued with an actual fix:2lineellipsispreview + native full scrolling Task details/Done + pinnedCancel + separate compact indeterminate spinner. Existing method02 is expanded; ONE fresh responsive UI method is next, with unchanged backend proofs reused by reviewed COMMON-only migration. Two minimal integrity methods passed0.028s against actual retained public proof/Git bytes, rejecting production drift and false relabelling. New UI/source-matched package remains pending.

## Actual responsive result and next correction

Hosted run **41316177182**, source **99368915**, built and launched successfully. Exactly one existing method, `test02ResponsiveMainUsesLabelledTestOnlyFixture`, ran and failed in **40.539 seconds**: **four assertion failures, zero passing methods**. The full-details font remained 17 points, content height 216 did not exceed viewport 786, vertical offset stayed 0, and the compact spinner was hidden. Retained original fixture images and logs are failure evidence, not passing accessibility or physical-phone proof.

Window-level accessibility trait inheritance/restoration, explicit spinner visibility, a 22-point details symbol and bounded scrolling are now source-ready. A genuine SDK API check followed by ONE targeted retry remains pending. Unchanged backend proofs are reused; the verified b45 backend assets stay held and no intermediate download is recommended. No corrected UI pass, matching UI package or new device result is claimed.

Tin's Mac is currently unavailable. Continue actionable cloud work without requesting routine approved access again. Existing scoped approval persists, while actual account/device/fold acceptance remains unverified. Keep the frozen backup boundary; the disclosed read-only incident remains the existing ledger, with no new backup audit.


Follow-up responsive run41319375823/sourcef26de5bc built successfully, then its one method failed with one unexpected exception in5.102s: UIKit forbids reading a trait override that does not exist. The later enlarged-font/details/spinner assertions were not reached. Commitac87396 guards that getter with containsTrait; no production code or assertions changed. The same single method is now running in41320431373. The SDK syntax pass establishes declarations/compilation, not that getter runtime precondition. No new UI pass is claimed.
