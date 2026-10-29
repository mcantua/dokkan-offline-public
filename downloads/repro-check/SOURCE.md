# Isolated Linux toolchain reproduction

Latest setup: 2026-10-28 10:09 AM US Central
Result: PASSED
Phase: rust-only

Cloud-only provisioning. No MacBook, personal internet, Apple account or phone was used. No backups created.

Pinned host runtime/CRT prerequisites (not downloaded or replaced by this script):
- libllvm19 1:19.1.7-3+b1
- libc6 2.41-12+deb13u4
- libstdc++6 14.2.0-19
- libgcc-s1 14.2.0-19
- libgcc-14-dev 14.2.0-19
- gcc-14-base 14.2.0-19
- libffi8 3.4.8-2
- libedit2 3.1-20250104-1
- libz3-4 4.13.3-1
- zlib1g 1:1.3.dfsg+really1.3.1-1+b1
- libzstd1 1.5.7+dfsg-1
- libxml2 2.12.7+dfsg+really2.9.14-2.1+deb13u3
- libtinfo6 6.5+20250216-2
- libbsd0 0.12.2-2
- liblzma5 5.8.1-1+deb13u1
- libmd0 1.1.0-2+b1
- binutils 2.44-3

Host Python/git/dpkg-deb are setup utilities; all Rust/C compilers, archiver, linker, iOS SDK, Cargo registry cache and build output use the isolated prefix.

Rust 1.99.1; rustup bootstrap 1.28.2. SDK repository https://github.com/theos/sdks at 0222fd5413cf4b9af096f37b4621afa2688572f7.

Downloaded archives (SHA-256):
- https://static.rust-lang.org/rustup/archive/1.28.2/x86_64-unknown-linux-gnu/rustup-init.sha256
  SHA-256: fda213f7e5b0860abe98f2500ccef7cefd7a4c358833388a0a3d9fba43865fd8
- https://static.rust-lang.org/rustup/archive/1.28.2/x86_64-unknown-linux-gnu/rustup-init
  SHA-256: 20a06e644b0d9bd2fbdbfd52d42540bdde820ea7df86e92e533c073da0cdd43c

Observed local tool identities:
- rustup 1.28.2 (e4f3ad6f8 2025-04-28)
  Installed binary SHA-256: 20a06e644b0d9bd2fbdbfd52d42540bdde820ea7df86e92e533c073da0cdd43c
- rustc 1.99.1 (58cf8f9c3 2026-10-13)
- Debian clang version 19.1.7 (3+b1)
- Debian LLVM version 19.1.7

License: Rust MIT/Apache-2.0; LLVM Apache-2.0 with LLVM exception. SDK content remains governed by Apple terms. Tool/SDK artifacts exceed50MB and are not committed.

## Earlier complete-prefix attempt evidence

# Isolated Linux toolchain reproduction

Latest setup: 2026-10-28 10:07 AM US Central
Result: PASSED

Cloud-only provisioning. No MacBook, personal internet, Apple account or phone was used. No backups created.

Pinned host runtime/CRT prerequisites (not downloaded or replaced by this script):
- libllvm19 1:19.1.7-3+b1
- libc6 2.41-12+deb13u4
- libstdc++6 14.2.0-19
- libgcc-s1 14.2.0-19
- libgcc-14-dev 14.2.0-19
- gcc-14-base 14.2.0-19
- libffi8 3.4.8-2
- libedit2 3.1-20250104-1
- libz3-4 4.13.3-1
- zlib1g 1:1.3.dfsg+really1.3.1-1+b1
- libzstd1 1.5.7+dfsg-1
- libxml2 2.12.7+dfsg+really2.9.14-2.1+deb13u3
- libtinfo6 6.5+20250216-2
- libbsd0 0.12.2-2
- liblzma5 5.8.1-1+deb13u1
- libmd0 1.1.0-2+b1
- binutils 2.44-3

Host Python/git/dpkg-deb are setup utilities; all Rust/C compilers, archiver, linker, iOS SDK, Cargo registry cache and build output use the isolated prefix.

Rust 1.99.1; rustup bootstrap 1.28.2. SDK repository https://github.com/theos/sdks at 0222fd5413cf4b9af096f37b4621afa2688572f7.

Downloaded archives (SHA-256):
- https://snapshot.debian.org/archive/debian/20260925T181338Z/pool/main/l/llvm-toolchain-19/clang-19_19.1.7-3+b1_amd64.deb
  SHA-256: bbb74458d782b7792b61b0eed92746df5e6d033778c045cf8c2b3835b7c4efc4
- https://snapshot.debian.org/archive/debian/20260925T181338Z/pool/main/l/llvm-toolchain-19/libclang-common-19-dev_19.1.7-3+b1_amd64.deb
  SHA-256: 4018e40e2d4144fe38c45822e68cca63c1bf6c7872c3073ebb262ad4b2f9b8bc
- https://snapshot.debian.org/archive/debian/20260925T181338Z/pool/main/l/llvm-toolchain-19/libclang-cpp19_19.1.7-3+b1_amd64.deb
  SHA-256: a7d2b6df51050834f6ea5c0d5e34869c2298b0bcdaa91eff17ba3db2cd545c47
- https://snapshot.debian.org/archive/debian/20260925T181338Z/pool/main/l/llvm-toolchain-19/lld-19_19.1.7-3+b1_amd64.deb
  SHA-256: 756a805e8811d527dd2b5417f016c9342b8631fa9c1ddcd56265c13ae33bf3a4
- https://snapshot.debian.org/archive/debian/20260925T181338Z/pool/main/l/llvm-toolchain-19/llvm-19_19.1.7-3+b1_amd64.deb
  SHA-256: 0b1b7263f4f45e261099240fdbf00fc14b42b88410fd829e041bf83ea45866cb
- https://static.rust-lang.org/rustup/archive/1.28.2/x86_64-unknown-linux-gnu/rustup-init.sha256
  SHA-256: fda213f7e5b0860abe98f2500ccef7cefd7a4c358833388a0a3d9fba43865fd8
- https://static.rust-lang.org/rustup/archive/1.28.2/x86_64-unknown-linux-gnu/rustup-init
  SHA-256: 20a06e644b0d9bd2fbdbfd52d42540bdde820ea7df86e92e533c073da0cdd43c

License: Rust MIT/Apache-2.0; LLVM Apache-2.0 with LLVM exception. SDK content remains governed by Apple terms. Tool/SDK artifacts exceed50MB and are not committed.

Observed setup finding and repair:
- One isolated-prefix full setup invocation passed with entirely newly downloaded Rust/LLVM/SDK.
- The initial recipe allowed rustup auto-self-update after bootstrap; Rust1.99.1 remained pinned. Recipe now disables auto-self-update before toolchain operations; the same setting was applied to this fresh prefix after setup. No second full setup was run.
- Observed active rustup 1.29.2 (d8c92c676 2026-10-21)
- Active rustup binary SHA-256: 5be191e8c70a5007074254cb74d78dbfdd25cd5a61c27de7b8e5410122ec24f4
- This proves fresh-prefix tool provisioning on the declared host runtime, not an untouched-bootstrap end-to-end run of the corrected self-update setting.

## Fresh registry and pre-build state

- Cargo fetch --locked --target aarch64-apple-ios completed into this prefix’s new registry/cache: 305 crate archives, 22745216 bytes.
- Registry source URL template: https://static.crates.io/crates/<name>/<name>-<version>.crate; exact versions/checksums are in the versioned app-installer/core/Cargo.lock.
- Cargo.lock SHA-256 at fetch: d81e742c9800538923f6c073a8be0d4e8e9fa4a6c7e7f664d09871d971a55646
- Fresh target directory exists before compilation: False (no prior native/Rust build output copied).

Pinned Rust component manifest SHA-256: dc137a3a5d74d4bb58e472d7470b7f3185d7315957aaaec5c0655aacd031e52a

- rustc x86_64-unknown-linux-gnu
  https://static.rust-lang.org/dist/2026-10-15/rustc-1.99.1-x86_64-unknown-linux-gnu.tar.xz
  SHA-256: 2ff05ff9c08a90861e7f6e4065b40a8b87463b4576186fd613871c3e37f2091f

- cargo x86_64-unknown-linux-gnu
  https://static.rust-lang.org/dist/2026-10-15/cargo-1.99.1-x86_64-unknown-linux-gnu.tar.xz
  SHA-256: 53f3521949404d595efb06a55c12c5658d4ed1c75566f33d3d514eaebe70bd8a

- rust-std x86_64-unknown-linux-gnu
  https://static.rust-lang.org/dist/2026-10-15/rust-std-1.99.1-x86_64-unknown-linux-gnu.tar.xz
  SHA-256: 109b074225bf5b9ea3820890876bfdf4ed161adbfaf94b2b4b5984c85ee5d958

- rust-std aarch64-apple-ios
  https://static.rust-lang.org/dist/2026-10-15/rust-std-1.99.1-aarch64-apple-ios.tar.xz
  SHA-256: d62c2e84717c6fa56ef0d8e5a11821850fb717c40879075a8e465a1e15af247c

## Final fresh-prefix compile/link/package proof

- Clean source commit: 5cc34908e754487e0035860a13205644cb7ea6d0
- Matching source-tree SHA-256: 46fa22b39bbcceb17718b67be0c58d5bbf446d72702b6eb99379ab9ed74b2c13
- Started: 2026-10-28 10:15:11 AM US Central
- Finished: 2026-10-28 10:16:44 AM US Central
- Complete iPhone+Duo pair elapsed: 92.69 seconds.
- Fresh target directory was absent before compilation. New Rust/host-build helpers, iOS C objects and all native sources were rebuilt with the fresh compiler/SDK and new Cargo registry. Original core/target or compiler/registry caches were not copied or linked. Host Linux runtime/CRT dependencies are the explicitly pinned prerequisites above.
- Both built-in artifact gates passed without warnings/errors. Both artifacts record clean source, identical source fingerprint and the isolated toolchain/target prefixes. No phone install, Apple login/device/VPN request, MacBook or personal internet was used.
- 307 locked Cargo dependency notice entries included; six genuine upstream notice gaps remain explicitly disclosed.
- Only after BOTH gates passed, the successful pair atomically replaced the two current builds/ review IPAs. No backups or duplicate release artifacts were retained.

- iphone: 5290509 bytes; SHA-256 7ead615b500c6d1d941c11317b3f028053fdcc2364dc74cb88ed103b3ae20cd7

- duo: 5290520 bytes; SHA-256 fd597f36825da885df4bd6f137195ce84453b26f14a1d102c2849cb475c08a4b

Evidence snapshot:

```json
{
  "source_commit": "5cc34908e754487e0035860a13205644cb7ea6d0",
  "source_tree_sha256": "46fa22b39bbcceb17718b67be0c58d5bbf446d72702b6eb99379ab9ed74b2c13",
  "started": "2026-10-28 10:15:11 AM US Central",
  "ended": "2026-10-28 10:16:44 AM US Central",
  "elapsed_seconds": 92.69,
  "target_was_absent_at_start": true,
  "artifacts": [
    {
      "variant": "iphone",
      "bytes": 5290509,
      "sha256": "7ead615b500c6d1d941c11317b3f028053fdcc2364dc74cb88ed103b3ae20cd7",
      "metadata": {
        "source_commit": "5cc34908e754487e0035860a13205644cb7ea6d0",
        "source_has_uncommitted_changes": false,
        "variant": "iphone",
        "unsigned": true,
        "compilation_sdk": "16.5",
        "requested_sdk_mark": "16.5",
        "duo_device_layout_verified": false,
        "phone_install_attempted": false,
        "toolchain_downloads_prefix": "downloads/repro-check",
        "cargo_target_prefix": "downloads/repro-check/target",
        "rustc_version": "rustc 1.99.1 (58cf8f9c3 2026-10-13)",
        "clang_version": "Debian clang version 19.1.7 (3+b1)",
        "source_tree_sha256": "46fa22b39bbcceb17718b67be0c58d5bbf446d72702b6eb99379ab9ed74b2c13"
      },
      "notice_count": 307,
      "notice_gaps": 6
    },
    {
      "variant": "duo",
      "bytes": 5290520,
      "sha256": "fd597f36825da885df4bd6f137195ce84453b26f14a1d102c2849cb475c08a4b",
      "metadata": {
        "source_commit": "5cc34908e754487e0035860a13205644cb7ea6d0",
        "source_has_uncommitted_changes": false,
        "variant": "duo",
        "unsigned": true,
        "compilation_sdk": "16.5",
        "requested_sdk_mark": "27.1",
        "duo_device_layout_verified": false,
        "phone_install_attempted": false,
        "toolchain_downloads_prefix": "downloads/repro-check",
        "cargo_target_prefix": "downloads/repro-check/target",
        "rustc_version": "rustc 1.99.1 (58cf8f9c3 2026-10-13)",
        "clang_version": "Debian clang version 19.1.7 (3+b1)",
        "source_tree_sha256": "46fa22b39bbcceb17718b67be0c58d5bbf446d72702b6eb99379ab9ed74b2c13"
      },
      "notice_count": 307,
      "notice_gaps": 6
    }
  ]
}
```

Cleanup: removed this isolated prefix’s downloaded Rust/LLVM/SDK, Cargo registry/index/cache, compiled target output and staging/metrics files after recording evidence. Only this SOURCE.md remains. The original required toolchain under downloads/{rust-toolchain,llvm,apple-sdk} remains available. The built artifact metadata deliberately retains the now-cleaned isolated tool paths as historical provenance; recreate them using the recipe to repeat the check.
