> **Scrubbed copy, prepared Thursday, October 29, 2026, 10:44 AM CT.** This is a single-commit snapshot with personal details removed, for `mcantua/dokkan-offline-public`. `mcantua/claude-chatg` stays the private backup. Nothing secret, no signing material, no `save/` data, no Sparking keys, and no personal details may be committed. The device UDID and private network address come from `config/private.local` or the `DUO_UDID` and `OFFLINE_DEVICE_HOST` environment variables. As of Thursday, October 29, 2026, 11:02 AM CT, https://github.com/mcantua/dokkan-offline-public is the active repo for Offline Dokkan work. `mcantua/claude-chatg` is the private backup. No personal data may be committed. Personal details include the real name, a personal email, the device UDID, and private network addresses.

# FULL HANDOFF: everything Claude (cloud chat) was doing

_Written Wed Oct 28, 2026, 11:15 AM US Central by Claude, before running out of usage._
_For: ChatGPT, and Tin's second Claude account. Read README.md ("Tin's rules") first, then this file._

---

## 0. Where everything is

| What | Where |
|---|---|
| This shared repo (all AI work + messages) | GitHub **mcantua/dokkan-offline-public** (active). Private backup: **mcantua/claude-chatg** |
| Dokkan Unit Creator source, newest (v2.36.2) | `unit-creator/` in this repo |
| Unit Creator detailed engineering notes | `unit-creator/HANDOFF.md` (long; read §0, §5, §6 and the bottom "v2.36" notes) |
| Change log (what each version added) | `unit-creator/deliver/CHANGES.md` |
| Feature checklist (nothing may be lost) | `unit-creator/docs/FEATURE-INVENTORY.md` |
| iPhone Duo screen rules | `unit-creator/docs/IPHONE-DUO-DISPLAY.md` (also `projects/`) |
| Import to Eclipse / Sparking format | `unit-creator/docs/SEND-TO-GAME.md` |
| App Installer (ChatGPT's) | `app-installer/` + `projects/APP-INSTALLER-BRIEF.md` |
| Offline Dokkan plan (planning only) | `projects/OFFLINE-DOKKAN-PLAN.md` + Tin's Claude doc "Offline Dokkan Battle — Plan" |
| Tin's Mac project folder | `~/AI-Workspace/Dokkan-Unit-Creator/` (build/, run/*.command, tools/, evidence/, research/, source/) |
| **PRIVATE** Android signing key + base APK | Mac only: `~/AI-Workspace/Dokkan-Unit-Creator/private-build/`. **Never upload to GitHub, never print the key password.** |
| Web test page (Tin's Claude sidebar) | Claude artifact "Dokkan Unit Creator", Version 94 (only Claude can update it) |
| Claude↔Claude chats (separate!) | GitHub **mcantua/claude-sessions**. Never mix with this repo |

---

## 1. Tin's rules (summary; README has the full list)
- Talk simply. Times in 12-hour AM/PM. Progress reports = a table of **pending items only** with **% done**.
- **No Unit Creator builds unless Tin says "make the builds".** When he does: 3 builds (Android APK, iPhone IPA, iPhone Duo check) and install on his iPhone Duo.
- Use **official Dokkan Battle wording** in the app.
- The Unit Creator works for **both Dokkan Eclipse AND Dokkan Sparking**.
- **Cloud first.** Ask before using his MacBook or personal internet data (ChatGPT added this to README).
- At most **one** backup. Delete old/unneeded files. Only **1–2 test runs per task**.
- Unit rules: start characters must be **fully awakened only**, best version first (**Super EZA > EZA > base**), **no duplicates**.
- Keep the web test page updated after every change (Claude-only artifact. If you can't update it, say so).

---

## 2. Dokkan Unit Creator: current state

**Version:** v2.36.2 (Android versionCode 127). Built today.
- The IPA is on the Mac in `build/`.
- The APK was sent to Tin in chat.
- The iPhone install of 2.36.2 was **pending** when this was written (another Claude session held the Mac). Check `~/AI-Workspace/Dokkan-Unit-Creator/evidence/status.txt`: if it doesn't say a 2.36.2 DONE from today, run the install (section 4).

**What was done in the last two days** (all in `deliver/CHANGES.md`):
- New dark "Dragon Ball intensity" look.
- Home looks like Dokkan's main screen: big last unit, banners on the right, Continue button.
- Simpler builder tabs:
  - **Portraits & Sprites** first, with just 3 big buttons.
  - **Artwork & Aura** second.
  - Super Attacks as tap-to-open cards; the normal attack and other move animations moved to the bottom of the Super Attacks tab.
  - Save & Play with 3 big buttons.
- Import to Sparking on iPhone via a linked Sparking folder.
- Sparking 6.6 `creator_id` fix.
- .sql import.
- **v2.36.1:** reuse files the Sparking app already has, instead of downloading them (iPhone).
- **v2.36.2:**
  - Freezing fixed: native file work moved off the main thread.
  - Storage counted natively.
  - 24 parallel downloads instead of 48.
  - Portraits & Sprites shows the template's own portrait/sprite/motion first, marked "Original".
  - Grids load 48 at a time.

**Pending (Tin's latest asks):**

| Item | % | Notes |
|---|---|---|
| Tin tests 2.36.2 on the phone (freezing, download speed, Original sprite/motion) | 0% | Ask him what he sees |
| Android: no re-downloading after a reinstall | 0% | Android can't read Sparking's files. Plan: a folder Tin picks once (SAF) that survives reinstall |
| iPhone: Eclipse database (99 MB) re-downloads after a reinstall | 0% | Plan: a "Dokkan Files" folder picked once, outside the app |
| Real-phone check of Import to Sparking (folder link, no duplicates) | 0% | Ask Tin to try it |

**Key facts discovered:**
- Sparking keeps **25.7 GB** of game files in its Files folder: `Sparking/assets/...` (cpk/png/acb/awb/usm/lua/lwf), plus `assets/sqlite/current/en/database.db` (109.5 MB). The Unit Creator reuses them through the linked folder (`gameFolderCopyIn` in `ios-objc/Player.m`, `IOS.fromGameFolder` in `web/src/ios-sparking.js`), always checking size + xxhash64 or the Eclipse size first.
- iPhone app is UIScene, marked SDK 27.1, built on **Linux** with clang + theos iPhoneOS16.5 SDK (`ios-objc/build-ipa.sh`, which runs the `check-duo.sh` gate). No Xcode needed for the IPA.

---

## 3. How to build (only when Tin says so)

Cloud (Linux):
```
cd unit-creator
python3 web/build.py                               # web/site, site-artifact, site-ios
VERSION=2.36.3 BUILD=128 bash ios-objc/build-ipa.sh  # → out/UnitCreator-2.36.3.ipa (+ Duo gate)
./build-from-release.sh 128 2.36.3-android         # → out/...-android.apk
python3 web/test_ios_duo.py                        # must say 0 failed
```
- `build-ipa.sh` clones the SDK automatically (sparse git clone of github.com/theos/sdks).
- The APK build needs `base/Dokkan-Unit-Creator-v2.30.0.apk` and `signing/dokkan-unit-creation-release.jks` + `signing/.pw`. Those come from the **private** Mac folder `private-build/` (signing-key.zip contains the .jks and the password). The APK certificate SHA-256 must be `9d274247…fafa`.
- Tests: `web/test_redesign.py` (36 feature checks) and `web/test_ios_duo.py` (91 Duo checks). They need Playwright + Chromium. Run each once; don't repeat.
- Next numbers: **2.36.3 / code 128**. Keep APK and IPA on the same version.

---

## 4. How to install on Tin's iPhone Duo (needs his Mac + phone; ask first)
1. Put the IPA in `~/AI-Workspace/Dokkan-Unit-Creator/build/`. Keep only the newest IPA there.
2. The iPhone must be **plugged in, unlocked and trusted**. **NordVPN must be disconnected** and **iloader closed**, because both break the connection.
3. Double-click `run/device-install.command` (Finder: Go › Go to Folder… › that path › ⌘O). It signs with the Mac's Apple Development identity (team P4NRE7Q8ZT), installs, launches and saves evidence in `evidence/<time>/`.
4. Check `evidence/status.txt` = "DONE …". Delete old evidence folders.
- Troubleshooting: run `run/phone-check.command`. It writes `evidence/phone-check.txt` showing whether the phone is "connected" or "unavailable".
- Device UDID: 00000000-0000000000000000 (iPhone Duo, iOS 27.1).

---

## 5. Other projects
- **App Installer:** ChatGPT's. See `STATUS.md`, `app-installer/WORKLOG.md`, `DECISIONS.md` and `TODO.md`. Claude hasn't reviewed it yet.
  - Open questions for Tin are in STATUS → "Waiting on Tin".
  - Notes: Face ID can't approve unattended background refresh. Recovering after the installer itself expires may need a computer.
- **Offline Dokkan Battle:** **STARTED Oct 28, 12:00 PM, owned by ChatGPT** (in parallel with Unit Creator). See `messages/to-chatgpt/2026-10-28_1210_from-claude_offline-dokkan-start.md` and the "IPA findings" in the plan. All agreed rules are in `projects/OFFLINE-DOKKAN-PLAN.md`:
  - banners, pity, drops 3×/6×/10×
  - EZA prices 500/700/300
  - weekend World Tournament with simulated rankings
  - weekend Elder Kai banner
  - sharing with friends: no Bandai Namco files in the app, each person imports their own Eclipse/Sparking

  Next step when Tin says go: open Sparking.ipa and eclipse.ipa on the Mac and answer the 7 "still unknown" items.
- **Claude↔Claude chats:**
  - Tin set up **mcantua/claude-sessions** for his Claude chats on different devices. THE BREAKING chats on the Mac and PC join it through a local synced folder (GitHub Desktop).
  - Keep it separate from this repo.

---

## 6. Things to know about working with Tin
- He tests on the phone and reports issues in short messages (often with typos). Restate what you understood in one or two lines, then fix it.
- He wants progress, not questions. Ask only when a choice is truly his.
- He's on the go a lot (work). Keep updates short. Push notifications for progress reports when available.
- If the Mac is "offline", say so plainly and keep working in the cloud.

---

## 7. Set up a fresh cloud workspace (new Claude account / ChatGPT)
Everything needed is in this repo except 2 private files.
1. `git clone https://github.com/mcantua/claude-chatg` (sign in to Tin's GitHub when asked).
2. `cp -r claude-chatg/unit-creator /home/claude/work && cd /home/claude/work` (any folder works; scripts use their own folder).
3. Get the 2 **private** files from Tin's Mac `~/AI-Workspace/Dokkan-Unit-Creator/private-build/` (ask Tin first):
   - `Dokkan-Unit-Creator-v2.30.0.apk` → put in `base/`
   - `signing-key.zip` → unzip into `signing/` (gives the .jks and `.pw`). Never print or commit it.
4. `bash setup.sh`: restores the game databases from the base APK and installs the tools. Then `python3 web/build.py`.
5. iOS SDK: `ios-objc/build-ipa.sh` downloads it by itself (theos/sdks).
6. Tests need Playwright + Chromium (`pip install playwright --break-system-packages`).

**Not in GitHub on purpose:** builds (APK/IPA), game databases (setup.sh restores them), the signing key and base APK (Mac only), Tin's personal info.

## 8. What else is in this repo
| Folder | What |
|---|---|
| `context/` | Tin's standing rules, what he said about each app, and his recent requests in order |
| `unit-creator/` | Full source + tools: `setup.sh`, `build3.sh`, `harness/` (test harness), `ios/` (Xcode project for the Mac), `decomp/` (decompiled game research + specs), `patch/` |
| `mac-workspace/` | Copy of Tin's Mac folder scripts: `run/*.command` (install, phone-check, sparking-files), `tools/` (duo-device-test.sh, phone-apps.sh, axml.py), `signing/` (Xcode signing helper), `research/NOTES.md` (Sparking file measurements) |
| `projects/` | Briefs: overview, App Installer, Offline Dokkan plan, iPhone Duo rules |
| `app-installer/` | ChatGPT's App Installer work |
| `messages/` | Claude↔ChatGPT messages |
