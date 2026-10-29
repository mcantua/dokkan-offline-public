# Local App Installer security patches

Upstream isideload 0.5.0 (MIT); source archive/checksum recorded in SOURCE.md.

- auth/grandslam.rs: credential-bearing get/post/patch/put methods and URL-bag endpoint reads require HTTPS apple.com or a subdomain, default port 443, and no URL credentials. Redirects are disabled on the shared HTTP client. Invalid certificate acceptance and verbose transport logging remain disabled even if a caller passes the dangerous debug flag.
- dev/teams.rs: preserve optional memberships dictionaries from Apple responses, enabling explicit account-type checks rather than guessing from individual/company team names. Unknown metadata fails closed.
- anisette/remote_v3/mod.rs: disable redirects on anisette HTTP clients. App passes the explicit upstream-default endpoint https://ani.jkcoxson.com; no Apple account secrets are passed to anisette methods.

The original MIT notices are preserved. Runtime authentication has not been tested with an Apple account. These patches are not evidence of a complete protocol/dependency audit.

- dev/teams.rs: retain optional membership evidence for conservative free/paid classification; no assumption that an unknown team is paid.

## Profile-backed capability integration
- sideload/sign.rs adds sign_with_entitlements: application-provided, profile-reconciled exact main/extension dictionaries are signed, rather than implicitly copying every available profile permission. No special-app grant injection occurs in this new entry point.
- dev/app_groups.rs adds assign_app_groups with Apple's array of internal applicationGroup IDs, preserving multiple group bindings in one request. Exact group identifiers remain unchanged; no hardcoded source group is silently renamed.
- dev/app_ids.rs treats an absent APG3427HIY flag as disabled before requesting explicit enablement. Actual returned profile authorization remains the final capability gate.
Evidence for feature keys and array request schema is recorded in downloads/fastlane-capability-reference/SOURCE.md and downloads/alt-sign-reference/SOURCE.md. No reference implementation source was copied.

- AppIdsApi::configure_new_memory_capabilities generalizes the existing upstream memory capability JSON request for the exact documented increased-memory/debugging-memory/extended-VA enums, submits all requested values together, and is called ONLY for App IDs newly created in this operation. Existing REST capability relationships are never blindly replaced; their actual already-granted profile values remain supported. This route remains live-account unverified.
