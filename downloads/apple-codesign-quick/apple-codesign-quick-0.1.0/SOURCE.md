# apple-codesign-quick 0.1.0: locally modified source

The published package is LGPL-2.1-or-later. This distribution selects LGPL3 as permitted by that grant; the original declaration is retained unchanged. Full LGPL2.1, LGPL3, incorporated GPL3, existing attribution and Sideloader lineage notice are included. No copyright owner or date is invented. App Installer remains AGPL-3.0-only; recipients retain the rights to modify/relink this library described in app-installer/licensing-signing.md.

## Provenance

- Published archive: https://static.crates.io/crates/apple-codesign-quick/apple-codesign-quick-0.1.0.crate
- Archive SHA-256: `519defc726db80b8a43836bbd6f69eb606a42783db799716a103436042593f0b` (the previously locked crates.io checksum).
- Repository: https://github.com/Dadoum/apple-crates
- Published VCS commit: `91fad87099663252dec23e4b5332a8ca979986f4`, path `apple-codesign-quick` (original `.cargo_vcs_info.json` retained).
- On November 1, 2026, copied the existing public-project Cargo cache only: verified its cached archive against the lock checksum, then compared every one of the 15 published regular files against that archive before copying. No network download or private-repository source was used.
- `PUBLISHED-CHECKSUMS.json` records the original published file hashes, before the local changes below. Additional license/attribution text was copied from this public project's existing verified notice collection. The published crate itself omitted license text; its original LGPL grant is in both manifests.

## Local changes

- `src/bundle.rs`: resources now stream through one 64 KiB buffer per active worker, updating SHA1 and SHA256 in the same pass. Resource hashing never uses mmap or its whole-file allocation fallback. Resource hashes and CodeResources semantics stay the same.
- Added `sign_bundle_controlled` and `Bundle::sign_controlled` accepting a shared `Fn() -> bool + Send + Sync` stop/deadline predicate. Existing APIs use a never-stop predicate. Checks occur at resource chunks, directory entries, bundles, library/executable boundaries and before metadata writes. Scoped Rayon work joins before returning; no detached signer worker is created.
- `src/control.rs`, `src/macho.rs`, `src/signature.rs`: controlled executable signing checks after reading, between thin/FAT phases, at each code page and code-directory slot, around CMS signing and immediately before replacing the executable. Existing never-stop file/data/signature APIs retain their behavior. A cancelled CMS callback regression confirms that the original executable is preserved before replacement. An in-progress syscall/crypto operation and the final check/write race cannot be atomically interrupted; this is cooperative cancellation, not hard realtime or rollback.
- `src/error.rs`: typed `CodeSignError::Cancelled`, with a fixed message and no account/device detail.
- `src/lib.rs`: exports the controlled bundle/executable entry points and stop-predicate type, and stops compiling the now-unused private file-bytes mapper. Its original source remains present as published provenance. Executable signing still uses its existing whole-file memory model; this patch does not claim memory bounds for executable rewriting.
- Two focused `resource_signing_` checks exercise the actual resource hashing helper (partial/Interrupted reads, matching hashes, I/O failure, logical 4 GiB cancellation), a successful synthetic executable signature, cancellation inside its actual CMS callback before file replacement, and an already-cancelled bundle that does not open/rewrite metadata. Execution evidence is recorded separately; adding tests is not a passing-test claim.

The patched Cargo manifest adds no dependency or feature. The root path patch selects this same library for direct and isideload consumers. Matching corresponding source and relink instructions remain required with every distributed binary.
