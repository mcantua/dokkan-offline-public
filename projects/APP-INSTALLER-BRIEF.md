# App Installer: handoff brief for ChatGPT

You are starting a personal iPhone app for Tin. Claude (Anthropic) planned it with him and will review and correct your work on Monday. Follow this brief exactly. Log every decision so the review is fast.

## Tin’s completion direction — October 28, 2026
Tin now requires continued development through every feasible feature, licensing issue, real signing/install validation and physical Duo verification. A build, automated pass or Claude handoff is not completion. The original first-install stop is replaced by an authorization boundary: physical installation may proceed only when the required device access and specific approval are available. Both AIs must still ask and wait before using Tin’s MacBook or personal internet data. Apple credentials stay on approved devices/Apple’s interfaces, never chat or repository files. Complete independent cloud work before asking Tin for a concrete blocked action. Keep resources under AI-Workspace and in the single private repo.

---

## 1. Goal (his words, cleaned up)

1. An .IPA that installs other .IPA files and signs them **to his Apple ID, straight from the iPhone**.
   - After the very first install of this app (done once from his Mac), **no computer is ever needed again**. This is the most important rule.
   - Must work with a **free Apple ID** and a **paid developer account**.
2. Its own **modern, simple interface**:
   - Sign in with Apple ID, then the 2-factor code.
   - Offer Face ID / Touch ID for later sign-ins.
3. A main screen that basically just says **Install .IPA**.

Other rules from him:
- **Open source, personal use only.** Never sold. He may share it with friends and family.
- **Separate app.** It is NOT part of the Dokkan Unit Creator. Separate project, folder, icon and bundle ID.
- **iPhone only.** Two builds: **iPhone** and **iPhone Duo**. No Android version.
- **Cloud first (important).** Do as much as possible in the cloud, without his MacBook, his PC, his Wi-Fi or his hotspot data. That covers research, downloading libraries, writing code, compiling the Rust core, building both IPAs and running tests. His devices and internet are allowed only for steps that truly need them: mainly the first install on his iPhone. **Before using Tin's MacBook or personal internet connection (home Wi-Fi, cellular data or hotspot), both AIs must explain the step and why it is needed, ask Tin, and wait for his explicit approval. Being connected or online is not approval.** Record the reason and approval in STATUS.md.

---

## 2. Agreed design

### Screens
- **First open:**
  1. "Sign in with Apple ID", then the 6-digit code Apple sends.
  2. "Use Face ID next time?"
  3. A one-time "Import pairing file" step (see section 3).
- **Main screen:**
  - One big **Install .IPA** button, which opens the Files picker.
  - Face ID, then sign and install, with clear progress (Signing… Installing… Done).
  - Under it, a short list of installed apps showing **days left** before each needs refreshing, plus a **Refresh all** button.
- **Settings (only):** sign out, Face ID on/off, re-import pairing file, show the app's own expiry.

### Behaviour
- **Credentials:** Apple ID credentials and session tokens live ONLY in the iOS **Keychain**, protected with Face ID / Touch ID (`SecAccessControl` with `.biometryCurrentSet`). Never in files, logs, UserDefaults or any network request except Apple's own.
- **Auto-refresh:** the app re-signs itself and the apps it installed well before they expire (free account = 7 days).
  - Use Background App Refresh / BGTaskScheduler.
  - Offer a one-tap guide to add a daily **Shortcuts automation** that opens the app, so a refresh always runs.
  - Show a warning **2 days before** anything expires if refreshing keeps failing.
- **Pairing file:**
  - Check it every launch.
  - Keep a backup copy inside the app's container.
  - Warn clearly if it stops working, for example after "Reset Location & Privacy".
- **Free-account limits** (Apple's, not ours): 3 active sideloaded apps (this app counts as one) and 10 App IDs per week. Show these limits plainly in the UI instead of failing silently.
- **Duplicates:** installing an IPA whose bundle ID is already installed updates it. It never creates a second copy.

---

## 3. How it works technically (recommended approach)

Use existing open-source building blocks. Don't reinvent Apple's signing protocol.

| Need | Use | License |
|---|---|---|
| Apple ID login (GSA/SRP + 2FA), anisette data, developer-services calls (certs, App IDs, provisioning profiles), signing | **isideload** (Rust crate, by nab138, the engine behind iloader) — docs.rs/crate/isideload | check crate license |
| Talking to the iPhone's own installer service on-device using a **pairing file** | **idevice** (Rust, by jkcoxson) — docs.rs/crate/idevice | check crate license |
| Reference app doing exactly this on-device | **SideStore** — github.com/SideStore/SideStore | AGPL-3.0 |
| Reference for certificate-based signing (zsign) and UI ideas | **Feather** — github.com/khcrysalis/Feather | GPL-3.0 |
| Making a pairing file (one time, from a computer) | **idevice_pair** — github.com/jkcoxson/idevice_pair, or **iloader** | — |

Key facts:
- **On-device install** requires the iPhone to "talk to itself". SideStore does this with a pairing file plus a loopback VPN. Plan on requiring the free **LocalDevVPN** app from the App Store, the same approach SideStore uses today. A free Apple ID cannot get the Network Extension entitlement itself. Verify the current recommended VPN app name before hard-coding it.
- **The pairing file is made once on a computer** (Mac or Windows) during the first install. After that, nothing needs a computer.
- If you copy code from SideStore (AGPL) or Feather (GPL), this app must use a compatible open-source license. Prefer **AGPL-3.0** for the whole app. Keep their license and copyright notices.

### Build setup (match the Unit Creator's)
The Unit Creator IPA is built on **Linux without Xcode**: clang plus the public iPhoneOS 16.5 SDK from github.com/theos/sdks, with an Objective-C/UIKit app.
- Prefer the same here: **Objective-C UIKit UI + Rust core** (isideload/idevice compiled as a static library for `aarch64-apple-ios` and linked in).
- If you choose Swift/Xcode instead, write down why in DECISIONS.md. It means building needs a Mac.

---

## 4. iPhone Duo version (must follow exactly)

The iPhone Duo has two displays:
- **Outer (closed):** app window **466 × 678 pt**. The status bar and cameras form a column on the **right**: safe-area right **84**, bottom **34**, reserved status/camera block x 382–466, y 0–174.
- **Inner (open):** app window **669 × 951 pt** (landscape 951 × 669).

Requirements:
- **Build the release against genuine iOS SDK 27.1 or newer**, as required by Apple’s current Duo preparation guide. The original Linux16.5 recipe with a newer metadata mark is retained only as a reproducibility/development path; that mark does not substitute for a real release SDK. Hosted Xcode27.1 is now verified available, so release candidates use it. Runtime calls to new optional display APIs are guarded for older supported iPhones.
- **UIScene life cycle.** Windows come from the scene, not UIScreen. No `UIRequiresFullScreen`. Support all orientations. Layout follows the current bounds.
- **Lay out around the side rail on the outer display.** Put bottom bars or buttons in the space under the rail where possible, not leaving an empty dark strip.
- **Inner display layout:** the installed-apps list and the Install button go **side by side**. On a regular iPhone they stack.
- The Duo build must pass a "check-duo" step before delivery: verify the SDK mark, scene manifest and no `UIRequiresFullScreen`.

The full measured notes are attached as **IPHONE-DUO-DISPLAY.md** (from the Unit Creator project). Read it.

---

## 5. Security rules (non-negotiable)

- Never send his Apple ID, password, 2FA codes or tokens anywhere except Apple's own servers, and the anisette server if one is used. Document which anisette source you use and why.
- Never log credentials, even in debug builds.
- Never disable TLS certificate checking.
- No analytics, no telemetry, no third-party SDKs that phone home.
- Don't put any signing certificate private key, password or personal data in the repo.

---

## 6. Where to put the work

- **Everything goes in the one shared folder**, the private GitHub repo **`claude-chatg`** (see its README.md "One folder for everything"). The App Installer's code lives in its `app-installer/` subfolder. Every download goes in `downloads/<name>/` with a SOURCE.md. Built IPAs go in `builds/`, latest only. No second repo, nothing stored anywhere else.

```
claude-chatg/app-installer/
  README.md          what it is, how to build, how to do the first install
  WORKLOG.md         dated log of what you did, newest first
  DECISIONS.md       every choice + why (library versions, VPN app, license, anisette source)
  TODO.md            what's left, and anything you were unsure about
  LICENSE
  ios/               Objective-C UI, Info.plist, assets
  core/              Rust (isideload/idevice wrapper) + build script
  build/             build scripts for iPhone and iPhone Duo IPAs
```
(The iPhone Duo notes are already in `projects/IPHONE-DUO-DISPLAY.md`. Don't copy them.)

- Clean up after yourself. No old builds, no stray downloads, no backups. Keep only the latest working IPA per variant.
- **Talking to Claude:** use the shared **claude-chatg** folder (see its README.md). At the end of each work session, write a message to `messages/to-claude/` covering what you did, what's untested and your open questions, and update STATUS.md. Questions only Tin can answer go in STATUS.md → "Waiting on Tin", in simple words.

---

## 7. What to do first (in order)

1. Set up the `claude-chatg` repo with this folder in it, then `app-installer/` with its README/WORKLOG/DECISIONS/TODO files.
2. Read isideload's and idevice's current docs. Write down in DECISIONS.md the exact versions and the functions you'll call for:
   - login
   - 2FA
   - anisette
   - creating or fetching the certificate and provisioning profile
   - re-signing an IPA
   - installing via pairing file
3. Get the Rust core compiling for iOS, with a tiny C API: `login`, `submit_2fa`, `sign_ipa`, `install_ipa`, `list_installed`, `refresh_all`.
4. Build the UI screens: sign-in, 2FA, Face ID offer, main Install screen, installed list, settings.
5. Keychain + Face ID storage.
6. Auto-refresh (BGTaskScheduler + Shortcuts guide) and expiry warnings.
7. iPhone and iPhone Duo builds, plus the check-duo step.
8. **Stop before the first real install.** That needs his Mac and iPhone, and Claude will do it with him on Monday.

If anything in this brief turns out to be impossible or outdated, don't silently change the plan. Write it in TODO.md under **"Needs Tin/Claude decision"**, with what you found and the options.

---

## 8. Done means

- [ ] Everything in the one `claude-chatg` folder as in section 6; README explains the build and the first install; no leftovers anywhere
- [ ] Rust core builds for iOS with the C API from step 3
- [ ] All screens built, plain and simple, Install .IPA as the main action
- [ ] Credentials only in Keychain behind Face ID
- [ ] Auto-refresh + Shortcuts guide + 2-day expiry warning
- [ ] iPhone IPA and iPhone Duo IPA both build; the Duo one passes check-duo
- [ ] WORKLOG, DECISIONS and TODO filled in honestly, including anything untested
