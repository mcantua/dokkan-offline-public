# What Tin has said about each app

## Dokkan Unit Creator
- He plays Dokkan Eclipse, a fan-run Dokkan Battle private server that accepts custom .eclp patches, and Dokkan Sparking (.sprk patches).
- Earlier custom card: "Gohan Black" (base and Beast forms). He was unhappy with its sprites, animations and battle motion. He only has the built .eclp, not the source.
- The app started as an Android APK. He wanted a full iOS version, an exact replica, animations included. Done: iPhone and iPhone Duo builds now exist.
- All testing happens in the browser test page first, before any build.
- Sequence he chose: **perfect the Unit Creator first**, then the Offline Dokkan game and the merge.

## Offline Dokkan Battle (planning only)
Full plan: ../projects/OFFLINE-DOKKAN-PLAN.md. Key points:
- Personal use and fun, never sold. Can be shared free with friends and family: the shared app has no Bandai Namco content, and each person uses their own Apple ID and imports their own Eclipse/Sparking.
- A 1-to-1 offline copy of Dokkan Battle, set up like Eclipse/Sparking. An in-game Creator runs the Unit Creator, and finished units go straight into the game.
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
- Updates: import a newer Eclipse/Sparking APK/IPA. The Eclipse website should also have data. Internet only for optional updates.

## App Installer (ChatGPT building)
- His own iPhone app that signs and installs IPAs with his Apple ID **from the phone**. **Completely computerless after the first install**, for free and paid accounts.
- Simple modern UI: Apple ID sign-in + 2FA, Face ID / Touch ID, main screen is basically "Install .IPA".
- Open source, only for him (may share). iPhone + iPhone Duo builds, no Android. Separate app from the Unit Creator.
- Built in the cloud as much as possible.
