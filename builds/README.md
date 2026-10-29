# Current App Installer cloud distribution

Only the latest verified cloud distribution is kept here. Source `2a31f6eed1256daacb5d0bed844f5839bce63f20`; successful package `40884961768`; verified private draft transfer `40887996440`. Both IPAs remain unsigned candidates, not final signed releases.

Native setup kit: 43,111,535 bytes, SHA-256 `1cda0defbcf540ffd68d8eb743be9f9e618da01e4ed2e4f9f359aa81779cfe93`. Complete source: 92,848,016 bytes, SHA-256 `13a43fb6c8f412f97bafb11f397dd979cb4d5df5753470d35b73a80c96709e4e`. Source fingerprint: `cf2a945cbafac3cf9871301813c13aecd69be0fb7186704922012fd6b47388c4`.

This kit includes the universal Mac trusted-USB pairing helper, fresh verification before publishing a new peer-pinned record, coordinated pairing-file import, and the reviewed pairing-only launcher/diagnostics. The app and helper have zero unresolved notice gaps. The complete source archive is the corresponding-source/relink companion; it is not needed for the small Mac setup transfer.

Use the private draft and [the existing-kit update instructions](../app-installer/device/UPDATE-EXISTING-KIT.md). Preserve the existing private setup files and app/Keychain identity. Actual server verification confirmed exactly nine current assets and their hashes; the two original InstallationCheck fixture asset IDs remain unchanged. Local assets were replaced only after that verification.

The new native import check passed once (0.101 seconds); the two vendor and one helper Linux results were reused with their recorded source limitations. No unrelated passing suite was repeated. Actual phone pairing, signing, install/update/refresh and physical Duo acceptance remain unverified. Never add Apple credentials, profiles, private signing keys or pairing exports here.
