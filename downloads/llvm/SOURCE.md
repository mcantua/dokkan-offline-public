# Linux LLVM tools

Debian snapshot: https://snapshot.debian.org/archive/debian/20260925T181338Z/
Version: 1:19.1.7-3+b1 (amd64), clang-19, lld-19, libclang-cpp19, libclang-common-19-dev.
License: Apache-2.0 with LLVM exception; retain package copyright notices in extracted usr/share/doc.
Purpose: compile/link Objective-C/UIKit Mach-O on Linux. Packages extracted locally with dpkg-deb -x into root/. Host libllvm19 19.1.7 is already installed. No system packages changed.
Reproduce using apt-get download against this Debian snapshot, then extract all four packages with dpkg-deb -x. Large binary tools are not committed.

Downloaded package checksums (SHA-256):
- clang-19_1%3a19.1.7-3+b1_amd64.deb: bbb74458d782b7792b61b0eed92746df5e6d033778c045cf8c2b3835b7c4efc4
- libclang-common-19-dev_1%3a19.1.7-3+b1_amd64.deb: 4018e40e2d4144fe38c45822e68cca63c1bf6c7872c3073ebb262ad4b2f9b8bc
- libclang-cpp19_1%3a19.1.7-3+b1_amd64.deb: a7d2b6df51050834f6ea5c0d5e34869c2298b0bcdaa91eff17ba3db2cd545c47
- lld-19_1%3a19.1.7-3+b1_amd64.deb: 756a805e8811d527dd2b5417f016c9342b8631fa9c1ddcd56265c13ae33bf3a4

Added llvm-ar/llvm-ranlib from llvm-19 1:19.1.7-3+b1 for Darwin static archives.
Exact URL: https://snapshot.debian.org/archive/debian/20260925T181338Z/pool/main/l/llvm-toolchain-19/llvm-19_19.1.7-3+b1_amd64.deb
SHA-256: 0b1b7263f4f45e261099240fdbf00fc14b42b88410fd829e041bf83ea45866cb
Only archiver and package copyright notices retained; package/extraction scratch deleted.
