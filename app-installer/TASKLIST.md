# Completion task list

**Current source-only state:** public-copy remote pairing/helper/phone transport is incomplete. Source authentication/fragmentation and asynchronous Files import repairs are uncompiled. Two Python migration-boundary checks passed; no app verification. No build until "make the builds". Historical rows below retain their original source scope; see device/PUBLIC-CONTINUATION.md.

This list tracks the actual completion goal. No overall100% claim while any required item is blocked or unverified. Builds and documents are evidence/milestones, not completion.

| Requirement | Current state | Required proof |
|---|---|---|
| Licensing six named cases | Six cases audited; 307 target packages have notices, zero gaps. Matching unsigned-candidate source delivery passed | New7059c85 package40777027792 passed matching source/IPA/kit checks; new7asset draft delivery40778539399 passed; all9 server hashes/sizes and2 fixture IDs verified |
| IPA capabilities | Required Installer/current Unit Creator source capabilities implemented; wider limits explicit in CAPABILITY-MATRIX.md | Live Apple profile grants, actual signed IPA and device behavior remain unverified |
| Signed bundle verification | Independent cryptographic verifier and real in-memory signing/tamper checks pass | Genuine Apple-issued profile/certificate plus physical installation still required |
| Apple authentication | Old8eaf reportedly crashes at sign-in after authorization. Missing Rust crypto-provider startup defect fixed in7059c85 | Fresh-process real HTTP constructor1passed/0fail/0.01seconds; actual corrected-build update/sign-in/2FA/team/session restore still required |
| Physical installation, update, launch and refresh | Tin reports4ad helper signing/export/install, then manual8eaf launch and sign-in crash | New7059 kit35,149,949bytes packaged; draft transfer40778539399 passed; corrected physical update/retest pending. No duplicate old-build action requested |
| Genuine SDK27.1/Duo simulator | Genuine Duo bare OS and production launch passed. Six earlier native methods retain passing evidence;2 new focused maximum-text/actual-keyboard methods passed40758076164 | Latest actual Duo/iOS27.1 run used no regular fallback or panel mutation; real software keyboard/guide geometry observed. Physical folds/touch/VoiceOver remain unverified |
| Physical Duo display/fold/touch | Unverified | Real outer/inner geometry, native pixels, safe areas, input, folds and retained state |
| Secure first-use/FaceID | Native biometric/Keychain review found no established separate crash cause; protection unchanged | Prior hosted checks retain original source scope; corrected-build physical passcode/biometric/session recovery still unverified |
| Existing eight and additional offline checks | Prior22 checks remain8eaf-scoped. New7059 executed startup1 and relevantTLS2, all0fail/0.01seconds per group | Fresh process starts with no provider and constructs the real account HTTP client without requests/credentials. No19core/response/native rerun claimed |
| Clean build / matching candidates | New7059c85/package40777027792 passed genuine-SDK compilation and candidate/source/kit gates | New7asset draft promotion40778539399 passed. Physical retest must establish whether the sign-in crash is resolved |
| Truthful install and interrupted self-update | Error+Complete, expected build Lookup and pending self-transition fixes committed in8eafc23; helper receipt checks2passed/0.024seconds | Cloud core/vendor/new-native checks passed40764445110; live install/update/relaunch evidence remains required |
| Final usable release | Not ready; release gate remains strict | Actual signing/install/refresh and physical acceptance, correct source delivery and no missing required functionality |

## Resource boundary
All source, downloads, builds and records live in the one repo under AI-Workspace. No personal MacBook or home/cellular/hotspot project use without explaining the exact action and waiting for Tin’s approval. Cloud-hosted macOS is permitted cloud infrastructure; OS-managed simulator state is ephemeral and separately documented. No Apple password/token/private key or pairing material in GitHub or logs.

Tin explicitly approved the specified MacBook, USB Duo, connection, kit/pairing and trusted dependencies on2026-10-28. Do not ask again for that scope. Tin resumed manual setup; direct computer control remains unavailable. Guide only the observed helper/UI flow, without asking again for the approved scope. Large Xcode installation and Apple-credential changes retain their separate approval boundary. User reports manual native signing/export/install and app launch before a sign-in crash. Those are reported bootstrap milestones, not verified in-app Apple/update/refresh acceptance.

Latest7059 verification ran only the fresh-process first-account constructor and relevantTLS2, then one matching package. Earlier22-check proof remains8eaf-only. Corrected delivery40778539399 passed; physical crash retest remains pending; release_ready=false.
