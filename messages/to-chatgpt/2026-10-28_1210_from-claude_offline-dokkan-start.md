# From Claude → ChatGPT: you now own Offline Dokkan Battle too (Oct 28, 2026, 12:10 PM)

Tin's words: "let's start on the dokkan offline project and work on the unit creator at the same time. hand over this job to chat gpt".
So you run **both**: keep fixing the Unit Creator (his bug reports + test page), and start Offline Dokkan Battle in parallel.

## Read first
1. `projects/OFFLINE-DOKKAN-PLAN.md`: every rule Tin agreed to (banners, pity, 3×/6×/10× drops, EZA 500/700/300, weekend Elder Kai + World Tournament, sharing). Don't change his numbers.
2. The new section **"IPA findings"** in that file: I opened both IPAs today. Both are the official game + one injected tweak dylib. Eclipse already has an "Offline Mode". **Our app = official game + our own tweak with a full local server inside.**
3. `context/PROJECT-NOTES.md` and `context/TIN-RULES.md`.

## Where to work
- Code: new folder `offline-dokkan/` in this repo. (Tin's Mac folder `~/AI-Workspace/Offline Dokkan Battle/` is only for things that must run on the Mac.)
- Never put Bandai's app, its database, or the Sparking/Eclipse keys in GitHub. Users bring their own IPA.

## Suggested first stages (all cloud)
1. **Local server spec**: for each endpoint in the findings list, what the game sends and what it expects back. Use the game's own database tables (the Unit Creator already reads them, see `unit-creator/decomp/specs/`) and public docs. Write `offline-dokkan/docs/SERVER-SPEC.md`.
2. **Local server core** (runs inside our tweak, plain C/ObjC so it builds on Linux with theos like the Unit Creator IPA): login, user data, card box, items, teams and saves in a local SQLite file, with save export/import.
3. **Summons/banners module** with Tin's exact rates and pity, plus unit tests (only a few).
4. Stages/events with the drop multipliers, then the rest of the plan's §8 list.

## Needs Tin's Mac (ask him first, keep it short)
- Opening more of the IPAs (the game binary, `ios_current.json` addresses) and real-device tests. The IPAs are in `~/Downloads/` (1 GB each, too big to upload to you). Write a small `.command` script he can double-click that saves results to a small text file you can read.

## Reporting
- Progress reports to Tin: a table of **pending items only** with **% done**, 12-hour times.
- Keep the Unit Creator test page updated after every Unit Creator change, same as before.
