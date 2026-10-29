Revised completion-pass offline regression evidence, October 28, 2026.

Commands (source app-installer/build/env.sh first):

- cargo test --manifest-path app-installer/core/Cargo.toml --locked --offline --lib:16passed,0failed.
- cargo test --manifest-path downloads/idevice/idevice-0.1.68/Cargo.toml --locked --offline --no-default-features --features ring --lib sni::tests:::2passed,0failed.

All eight original targeted checks are included:TLS2,identity2,cleanup2,capabilities2. Additional core checks cover archive2,engine2,preflight/expiry2,entitlementpolicy2,actualsigning/CMS/tamper2. Original logs and exact tested-source hashes are beside this file. Synthetic certs/keys exist only in memory during test; none are Apple-issued or saved. No personal Mac/data or phone access. This proves offline behavior only, not live account acceptance, revocation, installation or physical Duo compatibility.
