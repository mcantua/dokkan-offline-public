# App Installer decisions — October 28, 2026


## October 28, 2026 — completion verification changes

- Final candidates now use genuine hosted Xcode/iOS SDK27.1+, verified through actual runner inventory. The older Linux16.5 build with a27.1 metadata mark remains a development/reproducibility recipe; it cannot establish native Duo release compatibility.
- Keep the Objective-C/UIKit and Rust architecture. Hosted Apple tools compile the same application source; no personal Mac is used for cloud checks.
- Preserve requested capabilities only when the selected team's real Apple profile grants them. Never copy all profile privileges, silently strip a required feature, rename hardcoded shared resources, or substitute a development push environment for production.
- Verify the actual signed output independently before installation staging, including exact authenticated profile bytes, code/CMS/resource hashes, identity and device/team/expiry bindings. Offline verification explicitly does not establish revocation, installation or physical behavior.
- Deliver a complete corresponding-source/relink archive beside each candidate. Six published notice cases were audited; static/LTO LGPL distribution needs actual application/library/transitive source and replacement/relink instructions, not a private-repo link alone.
- A cloud or simulator pass is a development result. Final release classification requires live account/device functionality and actual outer/inner/fold/touch tests. The release gate refuses unsigned candidates, simulated hardware evidence, missing required features and unverified acceptance fields.
- Tin's latest instruction permits first-install work after concrete resource/device approval. Both AIs still explain the exact Mac/personal-network step, ask and wait. Passwords, signing keys and pairing material remain local/protected and never enter GitHub/chat.

## Scope and evidence
The real Rust engine is integrated, not an inactive stub. Objective-C screens and secure storage/refresh coordination are implemented. The core has passed iOS compilation and targeted offline tests; final package checks are recorded in WORKLOG. No live Apple authentication, certificate issuance, VPN connection, Keychain device execution or phone installation has occurred. Unsigned cloud artifacts are for review. Stop before first real install.

Six cloud agents were explicitly requested by Tin and worked on engine, UI, storage, refresh, validation and builds. Root integrated their work. One existing private repo mcantua/claude-chatg; no second repo or backup.

## Exact engine APIs and storage
Pinned isideload **0.5.0** and idevice **0.1.68**, both MIT, are mandatory local path dependencies with documented security patches. Cargo.lock pins the transitive graph. apple-codesign-quick **0.1.0** provides profile parsing and Rust signing primitives. No dependency defaults enabling filesystem credential storage are used.

| Purpose | API used |
|---|---|
| Apple account/login | AppleAccount::builder → danger_debug(false) → explicit RemoteV3AnisetteProvider → build; AppleAccount::login |
| 2FA | TwoFactorCallback with bounded waiting; SubmitCode/ResendCode/SendToDevices/SendSms; only safe last-two-digit phone choices enter UI |
| Session restore | Keychain serialized account SPD + email; DeveloperSession::from_account; no stored account password |
| Developer team | TeamsApi::list_teams; explicit callback selection if multiple teams |
| Certificate | CertificateIdentity::retrieve with custom SideloadingStorage and MaxCertsBehavior::Error; never silently revoke a certificate |
| App IDs/profiles | AppIdsApi::list_app_ids/add_app_id/download_team_provisioning_profile and DevicesApi::ensure_device_registered |
| Sign | Validated extracted directory → Application::new → sideload::sign::sign; validate original identities, then apply deterministic per-team main/extension mappings; preserve verified existing and own-installer identities |
| Device access | PairingFile::from_bytes → TcpProvider → InstallationProxyClient::connect/get_apps; MisagentClient::copy_all for conservative development-app accounting |
| Install | sideload::install::install_app followed by installed-app lookup; unique AppInstaller-owned PublicStaging name plus durable cleanup intent/retry on the next authorized connection |
| Refresh | Latest retained original per confirmed app; self source packaged from actual installed bundle/profile; refresh self last |

C API supports initialize, login, 2FA choices, team selection, session restore, pairing, sign/install/list/refresh, cancel/lock/sign-out and allocated safe JSON events/snapshots. Native InstallerService authenticates explicitly, stages Files input under protected imports, correlates operation IDs, and never emits invented installation success. Cancellation invalidates delayed native and Rust operation callbacks.

## Security patches
- downloads/isideload/PATCHES.md: require HTTPS Apple-controlled destinations for account requests; disable redirects; prohibit invalid certificate acceptance/verbose transport logging even if a caller passes a debug flag. Explicit anisette endpoint https://ani.jkcoxson.com, upstream default. No Apple ID/password/2FA/session tokens intentionally pass to anisette. Runtime protocol privacy still requires review.
- downloads/idevice/PATCHES.md: upstream rustls device transport accepted all certificates AND handshake signatures. The selected transport now pins the exact device certificate from the trusted pairing record and verifies TLS1.2/1.3 handshake signatures. DNS matching is replaced by pairing identity, not an accept-all policy. Legacy unsupported signature algorithms fail closed. Excluded OpenSSL paths still have upstream bypass code but are not enabled/used by this app.
- Tracing compiled off for dependency logs. Raw upstream errors and plist attachments never reach UI/log output. Only fixed safe categories/messages are exposed.

Persistent account/session/certificate secrets use native SideloadingStorage through device-only Keychain. Default ACL is biometryCurrentSet. An explicit setting change can disable biometric ACLs after authentication, while device-unlocked protection and explicit native authorization remain. Initial setup requires enrolled Face ID/Touch ID; a first-run passcode-only path is not implemented. Authenticated contexts expire after five minutes; Rust reads cannot prompt. Device lock invalidates context and clears in-memory engine authentication without deleting saved records.

Pairing primary is engine.pairing in Keychain. Exactly one ECIES-X963-SHA256-AESGCM container backup uses a nonexported device-only Keychain EC private key. File/directory are Complete-protected and excluded from cloud backup. No plaintext pairing backup. Keychain and file replacement cannot be atomic across stores: backup failure is reported and native install/refresh gates stay closed until backup succeeds. Read paths reject unsafe file types/links. Biometric migration keeps old records until update and attempts rollback; device verification remains necessary.

## Free/paid account behavior
Determine membership from actual team evidence, or existing provisioning-profile metadata. Unknown status fails closed before mutation. Paid accounts do not inherit the free weekly quota. For free accounts, preflight current App ID availability including extensions and conservatively count active development app profiles matched to installed apps, including the installer/other tools. Show explicit fixed limit errors for three-app/weekly-ID limits. Unknown usage fails closed. Server/device accounting behavior remains untested live.

The original source identity and installed signing identity are stored separately. New third-party apps get deterministic bounded per-team IDs; repeat original or already-signed imports reuse the mapping. The actual installer identity is preserved for self-refresh. Existing external copies are adopted only with installed/selected-team ownership evidence; ambiguous or cross-team copies fail before creating a duplicate. Capabilities that cannot be safely reconciled with profiles are rejected rather than silently stripped. See TODO and engine notes for exact current limits.

## VPN evidence
LocalDevVPN's source README links App Store ID6755608044. Constants.swift gives default interfaceconfigured-address/32 and peerconfigured-address/32; minimuxer/src/device.rs explicitly usesconfigured-address:62078. The engine accepts only the verified fixed peerconfigured-address. See downloads/localdevvpn-reference/SOURCE.md. Physical VPN/loopback behavior and patched legacy TLS compatibility are unverified.

## Scheduling and expiry
BGTaskScheduler is opportunistic. Five-minute authorized in-memory session + unlocked protected data + signed-in pairing are required for unattended work; background code never triggers Face ID. Expiry notifications use real provisioning dates and explicit notification permission. Shortcuts offers an opening guide but cannot guarantee the app opens/unlocks daily. Self-install can terminate the app before final confirmation. An expired installer may need a computer to recover; never promise otherwise.

## Build and Duo
Linux first: Rust1.99.1, clang/lld19.1.7, iPhoneOS16.5 SDK mirror at theos/sdks commit0222fd5413cf4b9af096f37b4621afa2688572f7. No Xcode or Tin device used. All tools/caches stay under downloads; large tools/SDK are excluded from git with provenance recorded.

Duo has scene lifecycle, live bounds/width columns, all orientations, safe-area fallback and runtime-gated rail controls based on actual reported regions. The requested LC_BUILD_VERSION SDK27.1 mark is synthetic on16.5 compilation. Artifact/source guards do not establish physical folding, rail, OS27.1 or measured-device support. No APIs requiring newer compile-time headers are linked directly.

AGPL-3.0-only for our source; no commercial-use restriction added. MIT notices and patched source retained. Generated package notices include available locked-graph licenses plus an explicit gaps report; this is not a completed licensing audit.

Notice audit: 307 locked iOS packages, six upstream full-notice gaps recorded explicitly (apple-codesign-quick, cms, isideload-p12-keystore, isideload-vfs, plist-macro, unicode-casefold). Official LGPL2.1 and exact source declarations/evidence are included where available. Static LGPL linking/source/relink obligations and remaining copyright evidence require review before distribution.

## Further cloud verification after the initial build pass
The initial 80% report was an estimate, not evidence of live functionality. The resumed cloud pass adds actual in-memory TLS1.2/1.3 acceptance/rejection tests, durable-cleanup retry tests, source-to-installed identity/plist-rewrite tests and adversarial multi-slice/DER/XML entitlement tests. UI/native fixes cover timed-out auth, stale messages/events, pipeline busy windows and installed-plist BG task identifiers. See VERIFICATION.md and downloads/repro-check/SOURCE.md for measured results and setup limitations.
