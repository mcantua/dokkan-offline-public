# Summary

Tin reports the old8eaf app installed through the4ad Mac helper and opened manually, then crashed at sign-in after authorization/Touch ID. Found and fixed a concrete first-account Rust crypto-provider startup bug in7059c85; targeted cloud checks/package passed. New draft transfer40778539399 passed; physical crash retest remains pending.

# Details

- Reqwest0.13 configured with rustls-no-provider panics on HTTP-client construction if no process-default CryptoProvider is installed, even when ring is compiled. Commit7059c85ad55645ef57db9f8de287e6a66b8c122e initializes ring at ai_initialize and defensively before account_builder. This is a real startup defect, not yet a device-confirmed crash resolution.
- Hosted40777027792 SUCCESS: fresh-process first-account constructor1passed/0failures/0.01seconds plus relevant TLS2passed/0failures/0.01seconds. The dedicated process begins without a default provider, calls actual ai_initialize and constructs the actual RemoteV3AnisetteProvider HTTP client; no send/provision/account request, credentials or live service access. Repeat initialization also checked. No19core/vendor-response/native repetitions; existing22-check proof remains scoped to8eaf.
- Actual new local receipts identify7059c85, source fingerprint0f305e96ea438eb46275184018c21ce2987d08314a09cf849e4d38379d0e5d42. Source78,336,612bytes SHA1ba83e045df171a3ca51bc7b1b44aaec131f6489e07d73778b6fafeb917e95cf; kit35,149,949bytes SHAe814dd588ff46be402d0372e2f66ce2154f5e3661a3ded93224bb0f1bfe41bf6. Both remain unsigned candidates/release_readyfalse. Private draft transfer40778539399 passed with all9 actual server hashes/sizes and2 unchanged fixture IDs; physical update/retest remains pending.
- Native Touch ID/Keychain review established no separate cause; protection was not weakened or bypassed. Reported bootstrap signing/export/install/manual launch is distinct from successful in-app Apple auth/signing/install/update/refresh. Broader capability limits are unchanged. Existing approved manual setup scope persists; next action is the verified existing-folder kit merge, then same-identity update and physical sign-in retest.

# Questions

None. Check root’s verified corrected-kit/draft receipt before guiding an update. Preserve source/test scopes and avoid unchanged suite repetition.

# Needs Tin?

Yes—download the verified7059 kit, merge it using UPDATE-EXISTING-KIT.md, then update the same installed app and retest sign-in. Actual live in-app workflows remain required. Do not claim the reported crash fixed until that retest succeeds. Keep personal keys/profiles/account data private.
