# Hayate (Grok Bot) handoff: Offline Dokkan / embedded Unit Creator

> **Scrubbed copy, prepared Thursday, October 29, 2026, 10:44 AM CT.** This is a single-commit snapshot with personal details removed, for `mcantua/dokkan-offline-public`. `mcantua/claude-chatg` stays the private backup. Nothing secret, no signing material, no `save/` data, no Sparking keys, and no personal details may be committed. The device UDID and private network address come from `config/private.local` or the `DUO_UDID` and `OFFLINE_DEVICE_HOST` environment variables. As of Thursday, October 29, 2026, 11:11 AM CT, https://github.com/mcantua/dokkan-offline-public is public and is the active repo for Offline Dokkan work. `mcantua/claude-chatg` is the frozen private backup. No personal data may be committed. Personal details include the real name, a personal email, the device UDID, and private network addresses.

Updated: Thu Oct 29, 2026, 11:11 AM CT

Repo: https://github.com/mcantua/dokkan-offline-public. Read context/TIN-RULES.md first.
Base branch: chatgpt/ios-eclipse-database-reuse (draft PR #1, DO NOT MERGE)
Previous handoff: Drive GROK-TAKEOVER.md (1QY2d_MlEJ5UZlWlmS441gqW1_Yhz8Yag)
Linked from the top of STATUS.md and HANDOFF.md.
Tin's go-ahead: "continue everything" (9:14 AM). No release builds until he says "make the builds".

## Latest repository transition

2026-10-29 11:13 AM US Central: Tin confirmed this public repository as the only active destination and the old private repo as untouched backup. Read all five required startup files and confirmed draft PRs #1 auth, #2 validation, #3 launcher, #4 engine/menu against the specified base. Documentation updates are isolated on `chatgpt/public-repo-transition-log`; no base push/merge, code review, build, app test, save access, key access or personal-machine action occurred. Current no-build/local-config/privacy instructions are at the top of README and context/TIN-RULES. Work is logged in STATUS and the existing private Drive Documentation folder; check the transition log for the exact sync receipt. Older CI/native results and acceptance gaps below remain scoped historical evidence.

## Done
- 1a24cfc and earlier: guarded the omitted sqlite3_enable_load_extension call. Extension loading stays OFF.
- Selected-master read now denies SQL printf/format.
- Derived growth coefficients are stored as exact thousandth strings.
- CI runs: 40886179478 FAIL (selected-master-read), 40890254683 PASS, 40891656259 PASS.
- Saved app screenshots: creator_welcome_sheet_run_40891656259.png (also identical in 40890254683) and creator_card_builder_run_40886179478.png. The finish-only workflow now always uploads every simulator PNG it reaches as duo-creator-simulator-screenshots. No new CI run for that workflow edit.

## Cloud agents (Cursor) running in parallel
| Agent | Task | Branch |
|---|---|---|
| bc-8aae2896-bc68-5071-b4e3-59e5cc5ad65e | Finish precision (done) | base branch |
| bc-65e17f79-5714-5e98-9535-2d3ec2a03bda | Full custom-unit validation + WIP compile | own branch, draft PR to base |
| bc-82741d46-7f6b-5d49-b4b8-8c7e73bd14f6 | Bootstrap auth envelope + fresh-state policy | own branch, draft PR to base |
| bc-40e91828-53e4-5e6c-a4df-9b86c14d641c | Engine master attach, late service binding, in-game Creator menu | own branch, draft PR to base |
Each agent writes its own log under messages/ in the repo.

## Pending (% done)
| Item | % |
|---|---|
| Finish saves numbers exactly | 100% (diagnostic) |
| Full custom-unit validation before save | 0% |
| Bootstrap auth envelope + fresh-state policy | 0% |
| Original-engine master attachment | 0% |
| Late service binding in ODUnifiedDuoHost | 0% |
| In-game Creator menu | 0% |
| Real battles/saves/summons with custom units | 0% |
| Duo two-screen test on phone | 0% |

## Blockers needing Tin's data (don't guess)
- The real auth success response body
- Fresh-account starting stats and items
- How the original engine keys or opens its master database (the key must never ship in the app)

## Rules recap
Cloud-only (ask before using Tin's Mac, PC or data). 1-2 test runs per task. At most one backup.
No secrets in files. Never touch save/ or the signing key. Never enable TLS bypass, never ship Sparking keys, never enable SQLite extensions.
Times in 12-hour AM/PM CT. Progress reports are % tables of pending items only.
