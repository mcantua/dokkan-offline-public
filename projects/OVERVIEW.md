# Tin's app projects: overview

_Written by Claude, Oct 28, 2026. Read this first._

He builds these apps for fun and **personal use**. Nothing here is ever sold. Some of it may be shared free with friends and family.

His devices:
- **iPhone Duo** (foldable, two displays)
- a **MacBook** (dev work lives in `~/AI-Workspace/`)
- a Windows PC with an RTX 5090 (used for his separate game project, THE BREAKING)
- Android devices: Pixel, Odin 3 Max, Retroid Pocket 5

## The three projects and how they connect

| # | Project | What it is | Owner now | State |
|---|---|---|---|---|
| 1 | **Dokkan Unit Creator** | App to make custom Dragon Ball Z Dokkan Battle characters and import them into Dokkan Eclipse and Dokkan Sparking | Claude | Polishing; builds wait for Tin |
| 2 | **App Installer** | iPhone app that signs and installs IPAs with your Apple ID, straight from the phone, no computer after the first install | **ChatGPT (starting now)** | Brief ready |
| 3 | **Offline Dokkan Battle** | Our own original offline game with integrated Creator; Eclipse/Sparking are data/research sources | Separate ChatGPT conversation, open PR#1 | Development underway; actual gameplay and final acceptance remain unverified |

How they connect:
- The **App Installer** is also how the **Offline Dokkan** game gets onto phones. Each friend imports permitted data into our own game; Apple signing and refresh constraints must remain accurately documented.
- In the end, the **Unit Creator merges into the Offline Dokkan** game. You make a character in the in-game Creator, and it lands on your own summon banner.
- Order Tin chose:
  1. Perfect the Unit Creator.
  2. Then the Offline Dokkan game and the merge.
  3. The App Installer is being started by ChatGPT now, while Claude is unavailable until Monday.

## Standing rules from Tin (apply to everyone)

**Talking to Tin**
- Talk simply. Short sentences, plain words, no jargon.
- Times in 12-hour AM/PM, never 24-hour.
- Progress reports: a table ("sheet style"), only what's **pending or in progress** (not finished items), with a **% complete** per item.
- When Tin says something is "still planning", don't build. Plan only.
- When a message starts with "reword", he only wants his text reworded.

**Working**
- **One folder for everything:** all work by Claude and ChatGPT (messages, plans, code, downloads, builds) lives in the shared `claude-chatg` folder / private GitHub repo, organized as its README.md says. Nothing scattered elsewhere.
- **Cloud first; ask before local use.** Do everything you can in the cloud (your own cloud workspace, GitHub). Both Claude and ChatGPT must ask Tin **before using his MacBook or personal internet connection (home Wi-Fi, cellular data or hotspot) for project work**. Explain the exact step and why cloud work cannot handle it, then wait for Tin's explicit approval. A connected or online MacBook is not permission. Use his PC only when truly needed too. First installation and opening Mac-only files still require this approval. Record the reason and approval in STATUS.md.
- Keep work organized in `~/AI-Workspace/<Project>/` on his Mac.
- Clean up after yourself: delete scratch files, old builds and backups. Keep only the latest working build. Never delete tools needed to make the apps.
- **Tests:** only what's needed. Test what changed, usually 1–2 runs per task. 10 tests per task is way too many.
- **Backups:** at most ONE, for emergencies. Never several backups or rollbacks.
- **Delete old and unneeded files** as soon as they're not needed for development.
- Log and fix every bug you find.
- Don't make new builds of the **Unit Creator** unless Tin says so.
- When builds are made, there are three Unit Creator builds: **APK (Android), iPhone IPA, iPhone Duo IPA**. The Duo build must pass a "check-duo" step and be installed on the phone.

**Security**
- Never send Tin's email address or account details anywhere.
- AI API keys live only in the phone's secure storage (Android Keystore / iOS Keychain). Never in files or the web version.
- Never disable TLS verification.
- Never publish signing keys or Tin's private data. Never print the signing-key password.
- Never ship game decryption keys inside an app. They come from the user's own copy of the game.

## Project 1: Dokkan Unit Creator (Claude owns it, don't edit)
Details: **UNIT-CREATOR.md**. In short:
- Android APK and iPhone/iPhone Duo IPA, plus a web test page in Tin's Claude sidebar.
- Works for **both Dokkan Eclipse and Dokkan Sparking**, not only Eclipse.
- Uses Dokkan Battle's **official in-game wording** for every ability and text.
- The Android version has exactly the same features as the iPhone versions.

## Project 2: App Installer (ChatGPT starts now)
Full instructions: **APP-INSTALLER-BRIEF.md**. Follow it exactly. Stop before the first real install on the phone.

## Project 3: Offline Dokkan Battle
Full plan: **OFFLINE-DOKKAN-PLAN.md**. Separate development is underway in open PR#1. Tin clarified that this is our own original offline game; Eclipse/Sparking supply research/data/assets/download sources, not selectable game modes or required live-service integrations. Coordinate ownership before taking over the other conversation’s code.
