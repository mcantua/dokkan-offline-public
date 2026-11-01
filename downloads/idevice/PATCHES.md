# Local security patch: idevice 0.1.68

Applied October 28, 2026 for Tin's App Installer. Upstream source origin/version/checksum remain in SOURCE.md. This directory intentionally differs from the original crates.io archive. Keep upstream MIT license/copyright notices.

## sni.rs — authenticated pairing certificate pin

The upstream `NoServerNameVerification` accepted **any** server certificate and returned unconditional acceptance for both TLS 1.2 and TLS 1.3 handshake signatures. That permits an unauthenticated endpoint and violates Tin's rule that TLS verification must never be disabled.

The local `PairingCertificateVerifier`:

- Requires the server's complete end-entity DER certificate to equal `PairingFile.device_certificate` exactly. A mismatch fails with `InvalidCertificate(ApplicationVerificationFailure)`.
- Checks the same pin again in each handshake-signature method.
- Delegates TLS 1.2 and TLS 1.3 handshake-signature verification to rustls's `WebPkiServerVerifier`. A pinned certificate without the corresponding private-key proof is insufficient.
- Uses the inner verifier's supported signature schemes; it does not add weak/unsupported algorithms or accept-all signatures.
- Uses direct pairing trust rather than DNS name/OCSP/public-CA path validation. The phone's pairing-issued identity does not have a meaningful DNS hostname. The imported, validated pairing record is the explicit trust anchor; a certificate rotation requires a fresh trusted pairing record. Certificate validity dates and revocation are not separately evaluated by this direct-pin policy.
- Propagates client-auth configuration errors instead of panicking with `.unwrap()`.

The rustls API for installing any custom verifier is named `dangerous()`. Here it installs an enforcing verifier; it is not an option to skip certificate or signature authentication.

## Dependency selection

The app must use this exact local idevice path for its direct dependency **and** patch the crates.io `idevice` source so isideload's transitive use resolves to the same patched library. The Rust-engine agent owns Cargo.toml/lock changes. Do not build from an unpatched registry copy.

## Compatibility and verification limits

No network/device TLS handshake, real pairing record, account or phone-install test has been performed. The engine/build agents have typechecked/cross-compiled the patched source. The offline in-memory cryptographic tests below passed; a physical-device test is still required before claiming working device transport.

Real signature verification may reject historical iPhone TLS identities/handshakes that rely on obsolete algorithms unsupported by the selected rustls provider. Fail closed and report pairing/transport failure. Do not reintroduce unconditional signature acceptance, permit an arbitrary new server identity, or downgrade TLS to make an old device work. Tin and Claude need to review any such compatibility failure.

## Remaining upstream skip-verification paths — excluded from this app configuration

- `src/lib.rs`, the `openssl`-only `Idevice::start_session` branch, sets `SslVerifyMode::empty()` and permits legacy SSL/TLS algorithms. The app uses `ring`/`rustls`, not the openssl feature. This branch is not fixed by this patch and must not be enabled for App Installer.
- `src/remote_pairing/tunnel.rs::connect_tls_psk_tunnel`, gated on the `openssl` feature, uses `SslVerifyMode::NONE` and disables hostname checks in its TLS-PSK configuration. The selected engine does not enable/use this path. A PSK design needs its own authentication audit before use; this patch makes no claim about it.
- `src/lib.rs` still contains unrelated upstream socket/server-name `.unwrap()` calls outside sni.rs. They are not certificate-verification bypasses but remain robustness concerns; the app must surface transport failures safely.

Any future feature expansion or dependency upgrade must re-audit these paths. Ordinary Apple HTTPS login/anisette TLS belongs to the separate isideload patch/audit and is outside this file's scope.

## Offline cryptographic verification — October 28, 2026

Two Rust test functions in `src/sni.rs` generate fresh certificate/private-key identities with **rcgen 0.14.10** entirely in process memory. No fixture key, certificate or pairing identity is written to a file or log. They open no socket and contact no Apple, anisette, VPN or device endpoint.

1. `trusted_pairing_and_real_signature_complete_tls12_and_tls13`: the production `create_client_config` completes real TLS 1.2 and TLS 1.3 client/server handshakes using the pinned device certificate and valid private-key proof. Encrypted application data is then authenticated/decrypted. The synthetic DNS name deliberately differs from the certificate SAN, verifying the intended direct pairing-trust behavior.
2. `substituted_identity_and_tampered_signature_fail_tls12_and_tls13`: each protocol rejects a different, otherwise valid generated certificate with `ApplicationVerificationFailure`; it also rejects the correctly pinned certificate when the server signer corrupts its real handshake signature, with `BadSignature`. A counter confirms the tampered signature was actually emitted.

Result: **2 passed, 0 failed**, 5 unrelated upstream tests filtered out, completed in 0.01 seconds after compilation. Tested with rustls **0.23.46**, rustls-webpki **0.103.16**, ring provider, Linux cloud executor. One initial invocation stopped at a test-only import visibility error; corrected to rustls's public `sign` module. The second and final invocation passed both tests. No additional test runs were made for this subtask.

Reproduce from the shared repository root with CARGO_HOME and RUSTUP_HOME pointing to the existing `downloads/rust-toolchain/cargo` and `downloads/rust-toolchain/rustup` directories:

```sh
cargo test --manifest-path downloads/idevice/idevice-0.1.68/Cargo.toml --locked --no-default-features --features ring --lib sni::tests::
```

Keep `CARGO_TARGET_DIR` under `app-installer/core/target/` (the actual run used its `tls-verification` child). Disposable test build outputs were removed after recording the result. The vendor lock records the test graph; the app's Cargo.toml/lock were not edited by this subtask.

Test-only certificate generation dependency: https://crates.io/crates/rcgen/0.14.10 (MIT OR Apache-2.0); source/archive retained in the existing Cargo cache under downloads, with exact registry checksums in the vendor lock. It is a dev-dependency and is not linked into the app release.

These tests establish the selected verifier's actual cryptographic accept/reject behavior. They do not establish legacy-iPhone algorithm compatibility, validity of a real pairing file, VPN routing, Apple login, provisioning, install/update, Keychain/Face ID behavior, refresh scheduling or phone reliability.

## installation_proxy.rs — truthful install and lookup responses

The local patch rejects any Error or ErrorDescription key before reading completion or LookupResult, including empty or wrong-typed errors. A valid status and bounded progress percentage are required. Device failures cannot be presented as Complete, and an error-bearing empty lookup cannot authorize deletion of retained source records. get_apps_with_attributes adds the protocol's ReturnAttributes option without changing the original get_apps default API.

The Installer requests actual build/release metadata and requires the requested build/version after trusted successful completion before committing retained source/expiry. Self-relaunch keeps an unresolved latest-IPA journal unless an observed running build/team/profile transition confirms the intended update; identical visible metadata remains unresolved. One grouped vendor response regression and one grouped core install/self-transition regression were added. These are offline checks; real device acceptance is still pending. Current results are recorded in app-installer/VERIFICATION.md after execution.

The new response regression passed once in combined hosted40764445110 at8eafc23:1passed/0failed/7filtered/0.00seconds with --no-default-features --features ring,tcp,installation_proxy --lib services::installation_proxy::response_tests::. The affected core confirmation/self-transition test also passed in its19-check suite. TLS2 passed separately in0.01seconds. No live installation/lookup operation was performed.

## October29 public-source remote authentication repair — uncompiled

The public-copy source now uses canonical255 TLV continuation, strict message/field sizes and states, authenticated M6 accessory signatures and pinned M2 pair-verify identity. Strict version2 records require consistent host keys and a previously authenticated peer signing pin; legacy/unpinned/mixed exports reject. New Unix exports are create_new0600 with synchronization; partial new-file failure may leave that private incomplete file for review. Responder persistence is not supported without a verified peer pin. See app-installer/device/PUBLIC-CONTINUATION.md. Eight source regression methods are added, not executed. This does not change the old TLS proof's source scope or enable remote_pairing in the app. No upstream license/dependency version changed. Complete public transport/helper/source packaging and actual device acceptance remain pending.
