# What Tin has said about each app

## Tech & Game-Dev reference (October 29)
- Tin's reference is the existing [Tech & Game-Dev Knowledge Base](https://drive.google.com/drive/folders/1hmaKOZMIBVAVBLXuGcvkPANbGzM5Ye7t). Read **00 - README + Playbooks** first, then relevant sections. Exact reading/access log and official-source checks: [TECH-GAMEDEV-REFERENCE.md](TECH-GAMEDEV-REFERENCE.md). Latest instructions override older notes; do not claim automatic synchronization with other chats.
- Current supplied original iPhone client and complete current master are now available privately in the cloud. Historical statements below that the executable is unavailable predate that transfer. Actual unified original-engine launch and gameplay remain unverified.

## Google Drive storage preference (latest)
- Google Drive is primary for all project files/tools/downloads/assets/current builds and documentation, under `AI-Workspace/Offline Dokkan + Unit Creator`. Registry: `context/DRIVE-WORKSPACE.json`. Keep GitHub source collaboration and necessary cloud compile/runtime files; minimize Mac storage. Reuse folder/file IDs, verify uploads before removing disposable copies, preserve the only working copy, protect credentials, and keep at most one backup. No direct Mac access or unattended synchronization exists in this chat.

## Dokkan Unit Creator
- He plays Dokkan Eclipse, a fan-run Dokkan Battle private server that accepts custom .eclp patches, and Dokkan Sparking (.sprk patches).
- Earlier custom card: "Gohan Black" (base and Beast forms). He was unhappy with its sprites, animations and battle motion. He only has the built .eclp, not the source.
- The app started as an Android APK. He wanted a full iOS version, an exact replica, animations included. Done: iPhone and iPhone Duo builds now exist.
- All testing happens in the browser test page first, before any build.
- Latest master directive: final product is ONE Offline Dokkan game with Unit Creator fully embedded, sharing characters/assets/data/saves/progression. Standalone HTML remains a development/compatibility tool; it is not an external dependency for the finished game. Duo first, equal iPhone/Android features.

## Latest visual/gameplay requirement — 1-to-1 Dokkan
Tin explicitly rejected the simplified Ki-circle/test-card screenshot. It is an internal mechanics harness, not the game design. The final app must preserve the real Dokkan UI/art/sound/animations/layout/battle behavior using the actual game client/engine, with our agreed offline/custom changes and embedded Creator. No invented replacement battle balance or simplified interface is an approved final design. Eclipse/Sparking remain content/reference sources, not modes. The actual client/engine has not yet been integrated in this cloud workspace; supplied databases do not provide that executable. Existing read-only IPA metadata approval persists, without direct Mac access.

## Offline Dokkan Battle (stage 1 started; this ChatGPT chat owns it alongside Unit Creator)
Full plan: ../projects/OFFLINE-DOKKAN-PLAN.md. Key points:
- Tin clarified on Oct 28: **our own original game**, one identity/save. Eclipse/Sparking are sources for databases/assets and website downloads only. No main-game mode selector or separate source-game players. Original-client wire research is historical, not a completion gate. Spec: ../offline-dokkan/docs/SERVER-SPEC.md.
- Personal use and fun, never sold. Can be shared free with friends and family: the shared app has no Bandai Namco content, and each person uses their own Apple ID and imports their own Eclipse/Sparking.
- Our own original offline Dokkan experience with the agreed gameplay/progression. An in-game Creator runs the shared Unit Creator and finished units register directly in our game. The save-manager host is an early implementation, not completed playable gameplay.
- Folder when building starts: AI-Workspace/Offline Dokkan Battle/. Don't modify existing apps without his OK. Preserve the original IPAs.
- Progression like a fresh official account, Sparking-style: everything farmable and rewards re-earnable. Drops: items 3×, Awakening Medals 6×, Dragon Stones 10×.
- Banners:
  - live official (rotate when the real game rotates; DokkanDB / DokkanInfo)
  - 2 weekly random rotators from the last 9 months
  - weekend Elder Kai banner (Elder Kais only, +1 SA level)
  - Unit Creator banner: all non-Carnival/Fest/Rising-exclusive officials plus all created characters; GR ≪ SLR ≪ LR (1% / 0.1% / 0.01% starting), 5 featured slots
- Pity (Unit Creator banner, newest creation): guaranteed by multi #50 GR / #25 SLR / #10 LR / #5 UR.
- Created characters drop fully awakened, level 1, Hidden Potential locked, SA level 1, no add-ons. Stats grow with level. The SLR/GR exclusive bonus is always on.
- EZA on officials: Custom EZA 500 stones and Custom Super EZA 700 (cards without one, animated "Custom" banner). Enhance to current meta 300 (cards that have one, no hand edits, animated "Enhanced" banner).
- Weekend World Tournament with our own exclusive characters and simulated AI rankings that climb all weekend.
- Share created characters (not EZAs) as unit files. They land on the friend's banner as their newest featured, credited to Tin, with no duplicates.
- Data setup/updates: import permitted source databases/assets or explicitly download needed data from Eclipse/Sparking websites. Preserve one player save and validate source IDs/dependencies; internet is not required for ordinary play.

## App Installer (the other ChatGPT chat owns it)
- His own iPhone app that signs and installs IPAs with his Apple ID **from the phone**. **Completely computerless after the first install**, for free and paid accounts.
- Simple modern UI: Apple ID sign-in + 2FA, Face ID / Touch ID, main screen is basically "Install .IPA".
- Open source, only for him (may share). iPhone + iPhone Duo builds, no Android. Separate app from the Unit Creator.
- Built in the cloud as much as possible.

## Latest continuation
- Source/test delivery, measured limits and pending work: root HANDOFF.md §10.
- Tin approved read-only IPA metadata and the Unit Creator2.36.3 development signing/install/display check on Mac+Duo; no direct Mac tool exists here, and execution remains pending. Do not repeat the permission request for these same steps.
