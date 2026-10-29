# Tin's standing rules (his own words in quotes)

## How to talk to him
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
- Every app gets **3 versions: Android, iPhone, and iPhone Duo. The iPhone Duo version is the PRIORITY**: build it first, test it first, and it gets the most polish. All three have the same features.
- (App Installer is the exception: iPhone + iPhone Duo only, no Android.)

## Dokkan Unit Creator
- **No new builds (APK/IPA) unless he says so** ("We are fixing the app first before we make the builds").
- Every release = 3 builds: Android APK, iPhone IPA, iPhone Duo version (check-duo gate + Duo display test + install on his iPhone Duo with run/device-install.command). Keep only the newest IPA in AI-Workspace/Dokkan-Unit-Creator/build.
- Always update the **web test page** (Claude artifact) after every change ("Make sure to always update it").
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
