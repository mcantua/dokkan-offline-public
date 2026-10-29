# Linux build tooling — October 28, 2026

## Build contract
Run from the repository root:

```
python3 app-installer/build/setup-linux.py --check
source app-installer/build/env.sh
cargo build --manifest-path app-installer/core/Cargo.toml --locked --release --target aarch64-apple-ios
bash app-installer/build/build-ipa.sh iphone
bash app-installer/build/build-ipa.sh duo
```

`setup-linux.py` without `--check` provisions missing tools locally. It requires x86_64 Linux, Python/git/dpkg-deb as setup utilities, and an explicitly pinned Debian13 LLVM/glibc/CRT runtime baseline listed in the script. Package-version mismatches fail clearly instead of silently using another runtime. The script does not install system packages or modify shell profiles. Exact package hashes and sources are recorded in `downloads/llvm/SOURCE.md`; Rust is1.99.1; the SDK revision is pinned in `downloads/apple-sdk/SOURCE.md`.

For an isolated cloud reproduction inside the same repository:

```
python3 app-installer/build/setup-linux.py --downloads-root downloads/repro-check
export AI_DOWNLOADS_ROOT="$PWD/downloads/repro-check"
export CARGO_TARGET_DIR="$AI_DOWNLOADS_ROOT/target"
export AI_BUILD_OUTPUT_DIR="$AI_DOWNLOADS_ROOT/artifacts"
bash app-installer/build/build-ipa.sh iphone
bash app-installer/build/build-ipa.sh duo
```

All override paths are constrained inside this repository; downloads prefixes must remain beneath downloads/. The isolated prefix has its own downloaded clang/lld/archiver, SDK, Rust toolchain, Cargo registry and Rust target output. Host Rust build scripts use the newly downloaded clang/lld linker too. Old Rust compiler wrappers/caches and inherited LLVM library paths are excluded. System runtime/CRT files remain declared pinned prerequisites; this is a fresh-prefix cloud proof, not a claim of building in a completely empty operating-system image. Original working IPAs are untouched when AI_BUILD_OUTPUT_DIR is isolated. The setup records URLs/hashes and outcome in the prefix’s SOURCE.md; after metrics are recorded, isolated tools/cache/artifacts are deleted and only that provenance remains.

The isolated setup completed on the pinned cloud host. Its first full invocation exposed rustup auto-self-update; a second Rust-only corrective invocation reprovisioned only the fresh prefix’s Rust tools, disabled self-update, and verified rustup 1.28.2/Rust 1.99.1. Freshly downloaded LLVM/SDK were retained from the first invocation; no original toolchain was borrowed. Exact attempt evidence, bootstrap/package hashes and host prerequisites are recorded in downloads/repro-check/SOURCE.md. The isolated final Rust/native build passed from clean source 5cc34908e754487e0035860a13205644cb7ea6d0; the fresh iPhone+Duo pair compiled/linked/packaged in 92.69 seconds, both artifact gates passed, and only then replaced the current review IPAs. This is not claimed as one untouched full invocation of the corrected recipe.

`env.sh` supplies local Cargo/Rustup locations, SDKROOT, deployment target 16.4 and native C/archive wrappers. `clang-ios.sh` targets arm64 iOS with the pinned SDK and lld. LLVM's archiver is required for ring's Mach-O C objects; GNU ar is not selected. The downloaded llvm-19 package was used only for llvm-ar/llvm-ranlib and copyright notices; package/extraction scratch was removed.

The build script compiles all production `ios/*.m`, links UIKit/Foundation/Security/LocalAuthentication/UniformTypeIdentifiers/BackgroundTasks/UserNotifications/CoreFoundation/SystemConfiguration and the real Rust static library. No Cargo feature can silently select the old policy-only stub. No build step contacts Apple's account/device services or installs on a phone. No signing identity is included.

`third-party-notices.py` uses offline locked Cargo metadata for the iOS dependency graph and collects available root/declared/license-directory LICENSE/LICENCE/COPYING/NOTICE/COPYRIGHT files verbatim. Every package includes its declared SPDX metadata, version and source. Missing complete texts or undeclared licenses are explicitly listed in bundled ThirdPartyNoticeReport.json; their absence is never silently treated as license compliance. The generator does not download or invent notices. Versioned supplements under downloads/license-notices preserve exact upstream commit URLs, content hashes, and declarations where published crates omitted notice files. A supplement closes a gap only when complete applicable upstream files are verified; a generic license text alone never closes an absent copyright/notice gap. Rust standard-library/toolchain notice scope remains outside Cargo metadata and must be audited before public distribution.

The output remains `builds/AppInstaller-iphone-preview.ipa` and `builds/AppInstaller-duo-preview.ipa`: unsigned review artifacts until the integrated behavior has been reviewed and validated. The same bundle ID is used for both variants. The artifacts include honest build metadata identifying the source commit, whether build-source paths were dirty (generated IPAs are excluded), and a SHA-256 fingerprint of native/Rust/build/assets plus vendored isideload/idevice source. The source fingerprint is checked again after compilation; a source change aborts packaging. This fingerprint does not cover the SDK/tool binaries, which have separate pinned provenance. Build metadata also records compiler versions and repository-relative toolchain/target prefixes. It is not a claim that that exact source state was already pushed.

The artifact is gated in its staging directory before atomically replacing the current variant's IPA. A failure retains the previous working artifact. Intermediate native objects/modules and the staged package are cleaned on exit. Only the current successful review artifact per variant belongs in builds; Rust's reusable library/cache and required toolchain remain under their designated folders.

## Artifact checks
`check-artifact.py` validates ZIP identity/duplicate entries/executable mode, arm64 Mach-O command bounds, exact requested SDK/minimum markers, scene delegate, all orientations, iPhone-only family, no UIRequiresFullScreen, refresh manifest, no embedded signing/pairing secrets, and honest unsigned/device-verification metadata. With `--source-root` it rejects screen-bound window sizing and requires scene window creation. `check-duo.py` delegates to the same gate for the Duo variant.

The Duo SDK27.1 marker is a requested synthetic compatibility mark on code compiled with SDK 16.5. Neither the marker nor these checks proves rail/fold layout, a true SDK27.1 build, or device/OS compatibility. Those remain physical-device review work; first installation is a stop point.

## Verification status
Final integrated iPhone and Duo release/link/package builds both passed from clean source commit `8666ccbf3497f1893c02408cd93f4739bd2db798`. Both artifacts record `source_has_uncommitted_changes=false` and the same source-tree fingerprint. All Objective-C files and the mandatory patched isideload/idevice Rust engine linked successfully. Each artifact gate passed, including icon, metadata, manifest, source and notice checks. Only the latest review IPA per variant is retained; staging/lock/module scratch was removed.

One earlier full native syntax compilation passed. Two artifact-gate regression tests passed in each of two invocations (the second followed the icon/notice gate additions); no repeated runtime/device tests were performed. Shell/Python source syntax checks passed. A fresh-prefix cloud reproduction was subsequently completed as documented below; no claim is made of a completely blank operating-system image.

Each IPA contains available notices for 307 locked iOS Cargo packages and explicitly reports six genuine missing complete upstream notice/copyright gaps: apple-codesign-quick 0.1.0 (LGPL-2.1-or-later), cms 0.2.3, isideload-p12-keystore 0.3.0-rc4, isideload-vfs 0.0.1, plist-macro 0.1.6 and unicode-casefold 0.2.0. Exact published-source declarations/READMEs and official GNU LGPL2.1 text are included where retrievable; these do not invent missing copyright notices or close static relinking obligations. The asn1-rs-impl gap was closed with exact-revision upstream MIT/Apache files. Review licensing and Rust standard-library/toolchain notice scope before public distribution.

No live Apple account request, VPN/device installer request, Keychain/Face ID runtime, background-scheduler or physical Duo layout test was performed by these build commands. The artifacts remain unsigned review previews; no phone install was attempted. The first installation remains a stop point.

## Fresh-prefix build result — October 28, 2026

Source commit `5cc34908e754487e0035860a13205644cb7ea6d0` built successfully with a newly provisioned prefix and an initially absent Cargo target directory. The complete iPhone+Duo pair took 92.69 seconds, from 10:15:11 AM to 10:16:44 AM US Central. Both used fresh Rust 1.99.1, clang/lld 19.1.7, the pinned SDK 16.5 checkout, new Cargo registry/cache and fresh native/Rust outputs. Explicit pinned Linux runtime/CRT prerequisites remained host-supplied. The first full setup exposed rustup auto-self-update; the corrected second Rust-only setup verified rustup 1.28.2 with self-update disabled while retaining the first run’s newly downloaded LLVM/SDK. This is not claimed as one untouched full run of the corrected recipe.

Both artifacts recorded source clean, matched source fingerprint `46fa22b39bbcceb17718b67be0c58d5bbf446d72702b6eb99379ab9ed74b2c13`, and passed all package gates without warnings/errors. Both include 307 Cargo notice entries and the same six explicit gaps. Each remains unsigned, no phone install was attempted, and physical Duo/Face ID/VPN/background behavior remains unverified.

- iPhone: 5,290,509 bytes, SHA-256 `7ead615b500c6d1d941c11317b3f028053fdcc2364dc74cb88ed103b3ae20cd7`.
- Duo: 5,290,520 bytes, SHA-256 `fd597f36825da885df4bd6f137195ce84453b26f14a1d102c2849cb475c08a4b`.

The successful pair replaced builds/ only after both gates passed. Fresh tools/SDK/registry/targets/outputs were removed; only `downloads/repro-check/SOURCE.md` remains as setup and build evidence. Original required tools were preserved. No MacBook, personal connection, Apple account or phone resources were used.
