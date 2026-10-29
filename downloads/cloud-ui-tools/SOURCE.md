# Hosted macOS simulator tools

Cloud-only tools, downloaded beneath this directory by app-installer/cloud-ui/run.sh. No Tin Mac, personal network, Apple ID or physical phone is used.

- XcodeGen 2.46.0: https://github.com/yonaskolb/XcodeGen/releases/download/2.46.0/xcodegen.zip
  SHA-256: 4d9e34b62172d645eed6457cac13fc222569974098ef4ee9c3368bedf0196806 (published GitHub release asset digest).
  License: MIT; upstream notices retained in extracted archive.
- rustup-init 1.28.2: https://static.rust-lang.org/rustup/archive/1.28.2/aarch64-apple-darwin/rustup-init
  SHA-256: 20ef5516c31b1ac2290084199ba77dbbcaa1406c45c1d978ca68558ef5964ef5 (published .sha256).
- rustup-init 1.28.2 Intel alternate: https://static.rust-lang.org/rustup/archive/1.28.2/x86_64-apple-darwin/rustup-init
  SHA-256: 9c331076f62b4d0edeae63d9d1c9442d5fe39b37b05025ec8d41c5ed35486496 (published .sha256).
- Rust 1.99.1, minimal profile and matching iOS simulator target. Manifest: https://static.rust-lang.org/dist/channel-rust-1.99.1.toml
  License: MIT OR Apache-2.0. rustup verifies signed distribution metadata/component checksums using its normal verified transport.
- Xcode/iOS simulator: installed on GitHub's official xcode-27 hosted runner (genuine SDK27.1+ and actual Duo runtime required); actual Xcode/SDK/runner architecture captured in evidence/source-report.json. No SDK mirror downloaded.

Cargo/Rustup caches, tool downloads and project temporary files stay in this one repo folder. OS-managed CoreSimulator runtime/container data exist on the disposable hosted runner outside the checkout; the one simulator created by this job is shut down/deleted on exit. No repository secret or account credential is written here.

Official runner catalog pinned for evidence: https://github.com/actions/runner-images/blob/09456acd2718d935451373231c236286f861fd9c/images/macos/xcode-27-arm64-Readme.md
Actual allocated image/Xcode/SDK/runtime versions are discovered and recorded at run time. No synthetic SDK mark is used by the native hosted build.
