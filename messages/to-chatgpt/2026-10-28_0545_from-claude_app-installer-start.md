# From Claude to ChatGPT: please start the App Installer

## Summary
Hi! Tin asked you to start the **App Installer** while I'm unavailable until Monday, Nov 2. I'll review everything on Monday and fix what needs fixing. Please read `projects/OVERVIEW.md`, then follow `projects/APP-INSTALLER-BRIEF.md`.

## Details
- **First step: GitHub.** Tin's ChatGPT is probably not connected to GitHub yet. Before anything else, ask Tin to connect his existing GitHub account to ChatGPT (sign in), and walk him through it in simple steps. The private repo **mcantua/claude-chatg** already exists and Claude already uploaded this folder to it. Work there. **All** work goes inside it: code in `app-installer/`, downloads in `downloads/`, builds in `builds/`, messages in `messages/`. No second repo. If he can't connect right now, start the work anyway and keep everything ready to upload once he does.
- **Cloud first:** Tin asks that you do everything possible in the cloud, without his MacBook, PC, Wi-Fi or hotspot data. Use those only for steps that truly need them (mainly the first install), and note each one in STATUS.md.
- **Keep it organized and clean:** follow README.md "One folder for everything" and "Keep it clean". Clean up after yourself every session, in this folder and in your own cloud workspace.
- **Tin's rules:** at most ONE backup (emergencies only), delete old/unneeded files right away, and only 1–2 test runs per task. No repeated testing.
- Scope for you: the App Installer only, sections 7 and 8 of the brief.
- **Stop before the first real install** on Tin's iPhone. That needs his Mac, and he and I will do it together.
- Don't touch the Dokkan Unit Creator. Don't build anything for Offline Dokkan Battle. It's planning only; read its plan so you know where things are heading.
- Write decisions down as you go (`app-installer/DECISIONS.md`). The review goes much faster when I can see why something was chosen, not just what.
- If something in the brief is impossible or outdated (library APIs change fast in this area), don't quietly work around it. Write it up for Tin and me in STATUS.md → "Waiting on Tin", plus a message here.
- Points I'd most like your notes on for Monday:
  1. Exact isideload / idevice versions and the functions used.
  2. Which anisette source you chose, and why.
  3. How on-device install reaches the iPhone (pairing file + which VPN app).
  4. How you handle the free-account limits (3 apps, 10 App IDs a week).
  5. Whether you built with the Linux/clang toolchain or needed Xcode.

## Questions
none

## Needs Tin?
Yes. He needs to put this folder somewhere we can both reach (see STATUS.md).
