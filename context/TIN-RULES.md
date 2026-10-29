# Tin's standing rules (his own words in quotes)

## Latest active repository instruction (October 29)
- Offline Dokkan + embedded Unit Creator now uses `mcantua/dokkan-offline-public`. The previous private repository is an untouched backup: no edits, pushes, builds or development there.
- Base: `chatgpt/ios-eclipse-database-reuse`. Use topic branches and draft PRs; never merge into the base without Tin's OK. Preserve the existing draft workstreams and coordinate through `STATUS.md`.
- No builds until Tin says "make the builds"; historical development-package authorization does not override this. Keep verification to one or two meaningful runs per task.
- Never touch `save/` folders or the signing key. Personal details, including email/device/network identifiers, come only from ignored local configuration or environment selectors; do not read, print or commit their values. No secrets in files.
- Read README, HANDOFF, HAYATE-HANDOFF, STATUS and these rules on takeover. Log actions and actual verification limits in `STATUS.md` and the existing shared Drive folder. This repository move supersedes conflicting old repository/pause directions; other project/platform limits persist.

## Latest resumption and foundation confirmation (October 29)
- Tin's "take over" resumes ChatGPT development in the public repository. The older stop below is historical. No-build, protected-base, Duo-only and privacy limits still apply.
- Tin reconfirmed that Offline Dokkan is the supplied Sparking/original Dokkan client adapted for offline play with the agreed changes and built-in Unit Creator. Preserve its real presentation and mechanics. The account launcher and authored battle harness are internal components, never a replacement game or completion evidence.

## Latest parallel-development and reporting directive (October 29)
- Tin explicitly renewed maximum practical productive cloud-agent use. Six workers plus the integration lead are the current seven available slots; keep independent ownership and reassign finished workers while useful work remains. Do not duplicate tests or create agents only to fill slots.
- Continue original-client development between checkpoints. Report about every ten minutes during active execution: overall/remaining estimates only when reliable, current phase, completed milestones in prose, pending task table with owners/progress/remaining work, active/blocked agents, resource use, build/check status and actual visual evidence. If no meaningful screenshot exists, use a clearly labeled source diagram/technical summary; no fabricated images or harness-as-game claims.
- Tin wants a download link for a genuinely playable original-client Duo test build and will install it himself. There is no playable build yet. Do not label old demos or an unverified package playable. The standing explicit "make the builds" gate remains in force; this link request does not direct a new build now.
- Tin also authorized installation when an eligible playable build exists; the cloud currently has no direct iPhone/Mac/VPN capability. Being connected alone grants no new device access. Announce any concrete personal-connection step with known connection type/estimated bytes, or state uncertainty. No current cloud research uses Tin’s personal connection.

## Latest progress-image clarification (October 29)
- Tin clarified that progress images must be taken inside the actual app. Do not use browser captures, system diagrams, concept art or internal battle-harness screens as in-app evidence. If the actual app cannot be run under current authorization/environment limits, give text updates and explicitly say new in-app screenshots are unavailable. This overrides the broader diagram/browser examples in earlier reporting notes.

## Latest stop / takeover instruction (October 29)
- Tin asked ChatGPT to stop development to conserve usage and save/upload everything Grok Bot needs. All development agents stopped; perform only preservation/documentation/uploads for the handoff. Do not automatically resume ChatGPT development based on older sustained-work directions. Grok takeover state and exact WIP/blockers: [../GROK-TAKEOVER.md](../GROK-TAKEOVER.md). Duo-only and all privacy/storage/testing/platform gates remain in force.

## How to talk to him
- Use Tin's [Tech & Game-Dev Knowledge Base](https://drive.google.com/drive/folders/1hmaKOZMIBVAVBLXuGcvkPANbGzM5Ye7t) as reference. Read **00 - README + Playbooks** first, then task-relevant sections; report exact documents read and access failures. Persist the reference in project notes where supported, without claiming automatic synchronization with other chats. Verify changing technical facts against current official sources. Latest instructions override older reference notes. Reading log: [TECH-GAMEDEV-REFERENCE.md](TECH-GAMEDEV-REFERENCE.md).
- Keep it simple ("How you talk to me is simple"). Short sentences, plain words.
- Times in 12-hour AM/PM, never 24-hour ("not in military time").
- Progress reports: a sheet/table, **only pending / in-progress items**, each with a **% complete**. Send them automatically, with a phone push notification when the tool allows. (For THE BREAKING on his PC: also include how many watts the PC is drawing.)
- A message starting with "reword" = only reword his text and give it back, with no intro and without doing the task in it.

## All app projects (Unit Creator, App Installer, Offline Dokkan)
- **Cloud first**: do everything possible in the cloud, without his MacBook, PC, Wi-Fi or hotspot data. Use those only when truly needed (and ask first; ChatGPT made that stricter in README).
- **One shared folder** for all Claude↔ChatGPT work: GitHub mcantua/claude-chatg. Claude↔Claude chats use a **separate** repo, mcantua/claude-sessions. Never mix them.
- At most **ONE backup/rollback**, for emergencies only ("One is okay … but do not have multiple").
- Delete old and unnecessary files as soon as they're not needed. Clean up after yourself (and never delete tools needed to build).
- **No unnecessary tests**: "10 tests per task is way too much"; "I don't need 20 test runs of everything!"
- When he says "still planning", plan only and don't build.

## Builds for Unit Creator AND Offline Dokkan (Tin, Oct 28, 12:23 PM)
- Eventual targets are Android, iPhone and iPhone Duo with the same features. Tin's October 29 instruction puts ordinary iPhone and Android target development/builds/testing on hold: finish and verify the entire unified Offline Dokkan + integrated Unit Creator on Duo first, including both displays. Even after Duo is complete, wait for Tin's explicit approval before starting either other version. Shared data/asset work needed for Duo may continue. App Installer remains iPhone/iPhone Duo only and belongs to the other ChatGPT chat.
- Tin explicitly requests as many available cloud agents as possible for this project (October 29). Use the available slots for independent useful Duo implementation, coordinate file ownership, and combine integration/verification. All agents follow the same minimum-testing, private-input, cloud-storage, platform-gate and personal-connection rules. Do not duplicate work or tests merely to occupy slots.

## Permanent development rule (Tin, Oct 28)
- Continue authorized implementation autonomously; a spec, browser preview, test pass or unsigned package is not overall completion. Never claim 100% while implementation, critical checks, installation or physical-device requirements remain incomplete.
- Tin's latest directive: do not voluntarily stop after an agent batch, commit, Drive sync, check or IPA. Integrate completed work, update the checklist, then immediately take the next actionable unified-Duo requirement. Reassign available agents when independent useful work exists. A genuine execution/input limit requires saved code, results, blockers and exact continuation; never imply inactive background work.
- Prioritize implementation speed. Batch related changes; use the smallest meaningful targeted verification. Do not rerun unchanged features or create tests that merely mirror the code. Expand checks only for a specific failure, regression or unresolved integrity/security/platform concern.
- Run one focused final verification per integrated batch. Preserve essential security, data-integrity, installation and platform checks. No repeated APK/IPA rebuilds for minor edits.
- Development agents and available cloud tools are authorized. Keep active progress reports concise, pending items only with percentages; continue working after reports. Mac/PC/personal connection use still requires a concrete explanation and Tin's approval first.
- Native package work was explicitly requested in Tin's completion instructions; never present unprovisioned or device-untested output as a final release. Follow Duo-first order and align release versions.

## Dokkan Unit Creator
- **No new builds (APK/IPA) unless he says so** ("We are fixing the app first before we make the builds").
- Every release = 3 builds: Android APK, iPhone IPA, iPhone Duo version (check-duo gate + Duo display test + install on his iPhone Duo with run/device-install.command). Keep only the newest IPA in AI-Workspace/Dokkan-Unit-Creator/build.
- ChatGPT in this Unit Creator chat handles all three when Tin requests builds. Keep the version numbers the same (next: 2.36.3 / code 128); request Mac/device access only when needed, before using it.
- Always update the **web test page** after every change. Tin's latest instruction for ChatGPT: run `python3 web/build.py`, package `web/site-artifact` as one self-contained `test-page/UnitCreator-test.html`, overwrite the same file locally and attach it in chat. Do not commit `test-page/UnitCreator-test.html`. Embed JS/CSS/fonts/data; show version + a short change line at the top. Preview when possible. Match the real app's screens/features; only true phone operations may be labeled "iPhone only". Claude's artifact cannot be updated by ChatGPT. See `test-page/README.md` for current missing assets and parity gaps.
- Use **official Dokkan Battle in-game wording** for abilities and texts.
- It's for **Dokkan Eclipse AND Dokkan Sparking**, not Eclipse only.
- Character lists: **fully awakened only**, most advanced version (**SEZA > EZA > base**), never duplicates or earlier versions.
- Android has exactly the same features as the iPhone and iPhone Duo versions.
- Fully optimized for his iPhone Duo (outer and inner displays).
- Work lives in AI-Workspace/Dokkan-Unit-Creator on his Mac.

## Offline Dokkan — original game scope (Tin, October 28, 2026)
- Offline Dokkan is our own original offline game/version. Eclipse and Sparking are research, database, asset and website-download sources, not gameplay modes.
- Keep data-source choices in import/update setup; remove the Eclipse/Sparking mode picker from Offline’s main game flow.
- Live Eclipse/Sparking client/server integration is not a required completion gate. Implement and verify our own actual offline gameplay.
- Preserve Unit Creator’s compatibility/export choices for both games; this correction applies to Offline’s product identity.
- Preserve data provenance, bring-your-own-data distribution, Duo-first and all existing progression/summon/Creator rules.


## Security
- Never send his account email anywhere.
- AI API keys live only in Android Keystore / iOS Keychain. Never in files or the web version.
- Never disable TLS verification.
- Never publish the signing key or his private data. Never print the signing-key password.
- Never ship the Sparking SPRK/DB keys inside an app. They come from his own APK.

## THE BREAKING / Battle World (his IKEMEN GO fighting game. Separate project, listed for completeness)
- Don't ask permission, just do the work. Don't wait on his decisions.
- Log AND fix every bug (Docs/BUG-BACKLOG.md). Log everything discussed in brainstorming.
- New builds install right away on every connected device (Odin 3 Max, Retroid Pocket 5, Pixel, iPhone). Desktop and phones stay identical.
- Heavy research and correctness for everything (moves, sprites, voice lines). Never approve obviously wrong work.
- Use his RTX 5090 for heavy computing. Run as many workers in parallel as possible. As lead, keep other AI workers busy and post instructions in their chats.
- Clean up on Mac and PC. Never delete tools needed to make the game.

## Sustained completion directive (Tin, Oct 28, latest pasted request)
- Continue actual implementation across both Unit Creator and Offline Dokkan; a build, test page, successful check, commit or handoff is an intermediate checkpoint.
- A physical-device or missing-wire dependency blocks only dependent work. Immediately continue independent browser, Android, core/gameplay and native integration work.
- Use available agents for independent implementation. Obtain trusted cloud tools/dependencies as needed; preserve credentials, originals and working packages. Never bypass access restrictions or pretend a device/game check passed.
- Investigate supported authorized computer access once. This session currently exposes cloud execution/GitHub tools, no personal Mac connection and no configured VPN/device capability. Keep the already-approved Mac workflow ready without repeatedly asking the same permission or stopping unrelated development.
- Minimize usage and testing: code first, batch related changes, target changed risks and retry only actual failures. State genuine verification limits. Do not call either whole project complete using percentages or mock results.

## Offline Dokkan identity correction (Tin, Oct 28)
- Offline Dokkan is our own original game. Eclipse/Sparking are data/reference providers, including databases/assets and website downloads, not selectable game modes.
- One own-game player/save/Creator workspace. Source selection appears only in data setup and source provenance. Never split player progression by source or silently merge incompatible source IDs.
- Original-client patch/wire research does not define the product or block our own local gameplay implementation. Unit Creator itself still supports exporting to both source games.

## Unified application and usage limits (Tin's latest master directive, Oct 28)
- Final product is ONE Offline Dokkan game with the complete Unit Creator built inside it: shared characters/assets/data/saves/progression. Standalone HTML is a development/compatibility tool, not a separate required app.
- Completed local creations appear in the player's collection and teams without file transfers; later edits retain legitimate progress. Actual custom attacks/animations/passives/forms must work in real battles before completion is claimed.
- Continue actual playable gameplay, Ki collection, skills, progression, summons/events/missions/tournament, downloads and native integration. A save manager, menu, codec demo or passing check is not a finished game.
- Batch related edits before HTML/native builds and verification; this supersedes rebuilding after every minor edit. Reuse exact unchanged evidence; targeted checks only, extra checks only for specific failures or essential security/save/install concerns. All agents follow these limits.
- Progress updates only after meaningful milestones, concise pending-item tables. Do not invent reliable aggregate completion percentages while major gameplay scope is unverified.
- Do not claim background development if no supported execution is active. Preserve exact continuation notes if an actual limit interrupts work. All routine reversible development remains authorized.

- Include actual images/screenshots with every progress report; label older captures and unverified UI accurately (Tin, latest request).
- During active development, give a pending-only progress table with percentages and actual app images every10minutes (Tin, October29). Label historical/component/browser captures and state when no unified-game screenshot exists. Do not generate extra screenshots or imply inactive background progress just to satisfy a timer.

## 1-to-1 Dokkan requirement (Tin's latest correction)
- The final offline game must be a 1-to-1 Dokkan Battle experience like Eclipse/Sparking: actual game screens, layouts, artwork, sounds, animations, Ki presentation and battle mechanics, with only Tin's agreed modifications and integrated Creator.
- “Our own version” means our offline/customized variant, not permission to substitute a simplified engine/UI or invent balance/phase/AI rules.
- Preserve/reuse the actual user-supplied Dokkan client/engine as the production foundation. Source providers remain data setup only, never game modes; no live fan-server/account dependency is required for play.
- The authored JavaScript battle view, native save manager and own-policy simulations are INTERNAL DEVELOPMENT HARNESSES only. They do not count as implemented production gameplay or visual fidelity. Stop extending/releasing them as the game.
- Current-client local request/response/runtime contracts require verification for the selected actual client. Static strings/databases alone are not working integration. Do not fabricate hook signatures, addresses, success responses or proprietary assets.
- Progress images must show actual work with accurate scope; do not show internal harnesses as the intended game design. Preserve useful backend/editor work, original files, keys and saves.

## Primary Google Drive workspace (Tin, latest instruction)
- Store all project source, downloads/game assets, tools/dependencies, documentation, current builds and the one permitted backup under the existing `AI-Workspace/Offline Dokkan + Unit Creator` Google Drive folder. Reuse existing folders/file IDs; do not create duplicate or dated copies. Keep GitHub as the source collaboration repository and continue its existing commit/handoff rules.
- Drive workspace: `https://drive.google.com/drive/folders/1vCYgjgNagsEZ-yNsfRI97qrJkiBdsIbV`. Root AI-Workspace: `1zDzwfrU8MOQItyhNX1jc1HP7erl0vM-H`. Folder/file registry and exact verification limits belong in `context/DRIVE-WORKSPACE.json` and `context/DRIVE-WORKSPACE.md`.
- Synchronize after meaningful changes during active work. The connector does not mount Drive as a compiler filesystem or run unattended sync; use cloud working files only where development/build/runtime requires them. Never claim continuous/background sync.
- Minimize Mac storage. No direct Mac access exists in this chat. Do not claim Mac files were moved/deleted. Mac use still requires the existing scoped authorization; do not delete an only working copy. Explain Google Drive for desktop streaming/Free up space when relevant, rather than mirroring the entire workspace locally.
- Verify successful uploads/readback before deleting disposable local/cloud copies. Keep necessary active tools, originals and candidates until safely recoverable. Exclude signing keys/passwords/provisioning/account credentials/AI API keys; private game content belongs only in private Drive, never GitHub. Do not recreate obsolete Offline builds that Tin requested removed.
