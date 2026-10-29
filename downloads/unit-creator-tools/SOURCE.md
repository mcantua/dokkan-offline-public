# Unit Creator cloud native tools

Public build tools only; no app or signing data.

SDK: https://github.com/theos/sdks at 0222fd5413cf4b9af096f37b4621afa2688572f7
LLVM packages are verified against the SHA-256 pins in app-installer/build/setup-linux.py.
Java: pinned Debian JDK tools/ct.sym plus matching OpenJDK21.0.12.1 runtime. This established local installation retains matching host read-only runtime links; fresh bootstraps extract both pinned JDK and JRE privately.

Pinned packages:
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
- https://deb.debian.org/debian/pool/main/o/openjdk-21/openjdk-21-jdk-headless_21.0.12.1+1-1~deb13u1_amd64.deb
  SHA-256: f3abafb6c644b03df042824e707cd211ea33254761d7f7b75be3f8dc0df97c7a

Additional matching runtime used by fresh self-contained bootstraps:
- https://deb.debian.org/debian/pool/main/o/openjdk-21/openjdk-21-jre-headless_21.0.12.1+1-1~deb13u1_amd64.deb
  SHA-256: e95f36193e45464ac758e5436f940bf3eaecc77de67188275a42104f58aa7674

LLVM: Apache-2.0 with LLVM exception. OpenJDK: GPL-2.0 with Classpath exception. SDK content remains subject to Apple's terms.
Extracted SDK/tools are ignored and not redistributed in the source repo.
