# Tin's recent requests, in order, and what happened (Oct 26–28, 2026)

Latest storage directive: Google Drive is the central workspace for everything related to Offline Dokkan + Unit Creator, including all future meaningful changes. Use `AI-Workspace/Offline Dokkan + Unit Creator`, reuse existing IDs, verify transfers before disposable-copy cleanup, minimize Mac storage and preserve active tools/only working copies. No direct Mac access or background sync exists. See `DRIVE-WORKSPACE.md` and its registry for actual transfer state.

| # | Tin asked | Result |
|---|---|---|
| 1 | Portraits & Sprites too confusing: only portrait, battle motion and sprite pickers | Done (3 big buttons, v2.36.0) |
| 2 | Simplify the other builder tabs | Done (Super Attack cards, folded passive text, simple Save & Play) |
| 3 | Home should look like the Dokkan Battle start screen, mixed with the current UI | Done (`v2/ui/dbz-home.js`) |
| 4 | App that signs and installs IPAs from the iPhone, computerless after the first install | Handed to ChatGPT (`app-installer/`). Claude reviews later |
| 5 | Offline Dokkan Battle (attached spec) and all banner/drop/EZA/pity/tournament rules | Planning only: `projects/OFFLINE-DOKKAN-PLAN.md` + Claude doc |
| 6 | Shared folder for Claude and ChatGPT, keep it clean, one backup max, few tests | This repo |
| 7 | "Never download the same files over" after reinstall | v2.36.1: iPhone reuses Sparking's files. Android and Eclipse DB still pending |
| 8 | Freezing, slow downloads, template's sprite/battle motion not selected | v2.36.2: fixed (see unit-creator/deliver/CHANGES.md) |
| 9 | Make builds + install on iPhone | v2.36.2 built. APK sent. iPhone install waiting (run `run/device-install.command`) |
| 10 | Full handoff with EVERYTHING for ChatGPT and the second Claude account | This repo: HANDOFF.md, context/, unit-creator/, mac-workspace/ |

| 11 | Continue Unit Creator here; App Installer stays with the other chat | Ownership recorded; historical Claude-only restriction superseded |
| 12 | One self-contained browser HTML after each change | `test-page/UnitCreator-test.html`, overwritten each batch; current2.36.3 test with both databases |
| 13 | Restore only game databases; do not commit raw APK/ZIP/DB | Two supplied ZIP entries extracted and checked in ignored storage; original APK transfer too large |
| 14 | Start Offline Dokkan stage1 in cloud, alongside Unit Creator | Spec and working portable domain/save/summon core implemented; game adapter remains unverified |
| 15 | Three versions, iPhone Duo first, same features | Applies to both apps; both display sizes checked in mock browser, physical acceptance pending |
| 16 | Autonomous completion, minimal targeted testing, native development packages | Development IPA2.36.3/128 compiled; Android blocked by full base/private signing inputs; no completed-release claim |
| 17 | Approve both steps: read-only IPA metadata + Unit Creator development Mac/Duo install/check | Explicit approval received repeatedly; same limited approval, no execution from cloud possible; reviewed helper prepared |

| 18 | Latest directive: do not stop at milestones; complete every achievable Unit Creator/Offline requirement using agents/tools, isolate device-only dependencies, minimize usage/testing | Six implementation tracks resumed; genuine hosted Duo native check, real browser resources/LWF, Android database/media fixes, persisted Creator/EXP/calendar systems and native adapters underway. No final completion claim. |

### Latest correction — Oct 28, 2026
Tin asked why Offline Dokkan showed Eclipse/Sparking choices. He clarified: **Offline Dokkan is our own original version**; Eclipse/Sparking help development and supply databases/assets/website downloads only. The mode selector/parallel save architecture was a misunderstanding. Current work removes it, uses one canonical player and moves provider details into data setup. Existing data must be preserved. Original-client wire compatibility is no longer an acceptance dependency. Unit Creator's both-game support remains required.

### Latest unified-game master directive — Oct 28, 2026
The full attached directive requires one integrated Offline Dokkan application, shared editor/characters/assets/databases/saves/progression, direct collection/team access after finishing a custom unit, actual battles including custom abilities/resources, and continued authorized implementation. Browser HTML remains a compatibility/development tool. Batch related changes/builds, reuse evidence, avoid repeated tests/progress interruptions. Completion requires playable integrated gameplay and essential native/save/install/security verification, not isolated checks or unsupported percentages. All agents follow this rule.

### Latest screenshot correction — 1-to-1 Dokkan, Oct 28
Tin rejected the simplified battle-harness screenshot: the offline game must be a 1-to-1 copy of the Dokkan experience shown in Eclipse/Sparking. Root acknowledged the wrong replacement-game direction and stopped all agents extending it. Actual production must retain Dokkan's real client/engine presentation and mechanics, with agreed offline changes and integrated Creator. Pure-JS/own-policy/native-save-manager work is preserved as internal backend/tooling only, not claimed gameplay or the intended product. No new permission is required to stop that approach or correct cloud source; no personal Mac was accessed.

## October 29 resumed source integration

Tin resumed ChatGPT with “take over” in `mcantua/dokkan-offline-public`, then
reconfirmed that the supplied Sparking/original client must be the actual game
foundation. The previous simplified screenshot was an internal harness, not
the finished product. Preserve the original presentation/mechanics plus the
agreed offline changes and full embedded Creator. A playable test build link
is requested when available; no such build exists yet. Tin can install it
himself. No builds were requested with “make the builds”.

His latest pasted directive renews maximum useful parallel agents, cloud-first
work, advance personal-bandwidth notice, minimal targeted checks, meaningful
completion estimates and reports with actual visual evidence about every ten
minutes while active. Unknown overall/remaining percentages must be stated
honestly. Continue development between reports/checkpoints and reassign useful
work. No background or other-chat synchronization is implied.

Tin then clarified that progress images are for the actual app. New in-app screenshots are unavailable while no native build/run is authorized; use text status, never a browser/diagram stand-in.
