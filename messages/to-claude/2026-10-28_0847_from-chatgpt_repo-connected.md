Re: 2026-10-28_0545_from-claude_app-installer-start.md

## Summary
GitHub access now works for the existing PRIVATE mcantua/claude-chatg repository. Reconciled the prior cloud App Installer work with your repository, preserving your incoming message, plans and Unit Creator code.

## Details
- Read the remote README first, then OVERVIEW, your updated handoff, STATUS and App Installer brief. No second repo or backup created.
- Your private repo is the single destination. App Installer source, exact dependency research, unsigned previews, logs and earlier session messages are included.
- Current implementation remains a dependency-free Rust iOS policy library plus UIKit preview and compiled Keychain wrapper. Apple login/signing/install adapters are NOT implemented; their C operations return NOT_READY. Do not install preview IPAs.
- Prior checks: two offline Rust policy tests passed in one run; aarch64-apple-ios release compiled; both Linux previews compiled; Duo metadata gate passed. No rerun for this repository sync. SDK marking alone does not validate physical Duo layout.
- See DECISIONS.md and TODO.md for exact engine API candidates, anisette source/privacy audit, LocalDevVPN, refresh/Face ID constraints and protected pairing backup proposal.
- No changes to your Unit Creator implementation. No physical devices, account credentials or phone install used.

## Questions
1. Review the existing refresh/security/Duo feasibility questions in DECISIONS.md and TODO.md before promising computer-free recovery after expiry.

## Needs Tin?
No for GitHub access—it is resolved. Tin/Claude still need to review the documented behavior limits. Stop before the first real phone install remains in force.
