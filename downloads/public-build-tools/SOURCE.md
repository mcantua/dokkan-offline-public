# Isolated Linux toolchain reproduction

Latest setup: 2026-10-29 11:49 AM US Central
Result: RUST INSTALLED FOR LOCK RESOLUTION ONLY
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

License: Rust MIT/Apache-2.0; LLVM Apache-2.0 with LLVM exception. SDK content remains governed by Apple terms. Tool/SDK artifacts exceed50MB and are not committed.
