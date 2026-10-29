`test-page/UnitCreator-test.html` is not stored in git. From `unit-creator/`, run `python3 web/build.py` to rebuild that self-contained page locally.

# Claude ↔ ChatGPT shared folder

This folder is how Claude (Anthropic) and ChatGPT (OpenAI) work together on Tin's projects. Tin is the owner. Both AIs read and write here. Tin can read everything.

## Tin's rules (both AIs must follow, always)
1. **Cloud first; ask before local use:** do everything possible in the cloud. Before using Tin's MacBook or his personal internet connection (home Wi-Fi, cellular data or hotspot) for project work, **both Claude and ChatGPT must explain the exact step and why it needs those resources, ask Tin, and wait for his explicit approval before proceeding**. A connected or online MacBook is not permission. Use his PC only when truly needed too. Record the reason and any local-use approval in STATUS.md.
2. **One folder:** all work, messages, downloads and builds live in this folder (private GitHub repo `claude-chatg`), well organized.
3. **One backup max**, for emergencies only. Never several backups or rollbacks.
4. **Delete old and unneeded files** right away. Keep only the newest working build.
5. **Tests: only what's needed**, usually 1–2 runs per task. Never 10. **App Installer:** use essential targeted checks, combine related fixes before testing/building, and repeat passing checks only when later changes could affect them. After development, run one focused final verification of IPA validation, signing, installation, updates, errors, stability and release requirements. Keep critical security/compatibility checks; keep developing until genuinely complete.
6. **Clean up after yourself** every session, here and in your own cloud workspace.
7. **Talk to Tin simply.** Times in 12-hour AM/PM. Progress reports as a table, pending items only, with % done.
8. **Planning means planning.** When Tin says "still planning", don't build.
9. **No secrets** in files: no passwords, Apple ID details, keys or tokens.

## Start here
Use Tin's [Tech & Game-Dev Knowledge Base](https://drive.google.com/drive/folders/1hmaKOZMIBVAVBLXuGcvkPANbGzM5Ye7t) as a reference: read **00 - README + Playbooks** first, then task-relevant sections. See [the reading record and access limits](context/TECH-GAMEDEV-KNOWLEDGE-BASE.md). Report exact documents read and access failures; verify changing technical facts against current official sources. Tin's latest instructions take priority over older notes. This repository records the reference; it does not automatically synchronize other chats.

0. **New to this repo or picking up Claude's work? Read HANDOFF.md.**
1. Read **projects/OVERVIEW.md**. It covers all of Tin's app projects, how they connect, and his standing rules.
2. Read the newest file in **messages/to-chatgpt/** (if you are ChatGPT) or **messages/to-claude/** (if you are Claude).
3. Check **STATUS.md** for who is doing what right now.

## How to talk to each other
- **One message = one new file** in the other side's inbox:
  - `messages/to-chatgpt/2026-10-28_0545_from-claude_app-installer-start.md`
  - `messages/to-claude/2026-10-29_1830_from-chatgpt_question-anisette.md`
  - File names: `YYYY-MM-DD_HHMM_from-<who>_<short-topic>.md`. Times in US Central (Tin's time).
- **Never edit or delete the other side's messages.** To answer, write a new file that starts with `Re: <file name>`.
- Each message has these headings: **Summary** (1–3 lines), **Details**, **Questions** (numbered, or "none"), **Needs Tin?** (yes/no + what).
- When you finish reading a message and act on it, add a line to **STATUS.md** under "Log".
- Decisions that only Tin can make go in **STATUS.md → "Waiting on Tin"**, written in simple words.

## Rules for both
- Talk to Tin simply. Short sentences, plain words.
- Don't change another project's code unless the plan says so. Example: ChatGPT does not edit the Dokkan Unit Creator; Claude owns it.
- No secrets in this folder: no passwords, Apple ID details, signing keys, API keys or tokens.
- Clean up: delete scratch files and old builds you made. Keep messages, they are the record.

## One folder for everything
This folder (the private GitHub repo **`claude-chatg`**) holds **all** work by both AIs: messages, plans, code, downloads and builds. Nothing goes anywhere else: no second repo, no loose files in other places.

```
claude-chatg/
  README.md            this file
  STATUS.md            who's doing what, "Waiting on Tin", log
  messages/
    to-chatgpt/        Claude -> ChatGPT
    to-claude/         ChatGPT -> Claude
  projects/            plans and briefs (read-only unless the plan changes)
    OVERVIEW.md  APP-INSTALLER-BRIEF.md  OFFLINE-DOKKAN-PLAN.md
    UNIT-CREATOR.md  IPHONE-DUO-DISPLAY.md
  app-installer/       the App Installer's code and its notes
    README.md  WORKLOG.md  DECISIONS.md  TODO.md  LICENSE
    ios/  core/  build/
  downloads/           everything downloaded from outside (libraries, reference code)
    <name>/SOURCE.md   where it came from, version, license, why we need it
  builds/              ONLY the latest working build of each app/variant
  unit-creator/        the Dokkan Unit Creator source (Claude owns it; read-only for ChatGPT)
```

## Keep it clean
- **Backups: at most ONE**, only for emergencies. Never several backups or rollbacks. When you make a new one, delete the old one.
- **Delete old and unneeded files** as soon as they're no longer needed for development.
- **Tests: only what's needed.** Test what you changed, usually 1–2 runs per task. Never 10 runs of the same thing.
- Every downloaded thing goes in `downloads/<name>/` with a SOURCE.md. Downloads that are no longer used get deleted (note it in the log).
- Big downloads (over about 50 MB) don't get committed. Record the exact URL + version in SOURCE.md so they can be fetched again.
- `builds/` keeps only the newest working build per app and variant. Older builds get deleted.
- No scratch files, temp folders or backups left behind. Clean up at the end of every session.
- Your own cloud workspace counts too: delete leftovers there once they're saved here.
