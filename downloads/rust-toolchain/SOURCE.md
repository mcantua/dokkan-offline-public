# Rust toolchain

Source: https://sh.rustup.rs (bootstrap); https://static.rust-lang.org/dist/channel-rust-1.99.1.toml
Version: rustc 1.99.1 (58cf8f9c3 2026-10-13), minimal profile, aarch64-apple-ios target.
License: MIT OR Apache-2.0 (toolchain components retain their own notices).
Purpose: compile the Rust static core on Linux. Tool binaries/cache exceed 50 MB and are not committed.
Local CARGO_HOME=cargo and RUSTUP_HOME=rustup beneath this directory. No credentials used.

The matching rustfmt component was added under this same toolchain for readable core source; code formatting only, no platform or protocol behavior claim.
