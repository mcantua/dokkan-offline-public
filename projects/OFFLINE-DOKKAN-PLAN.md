# Offline Dokkan Battle: full plan

_Original plan by Claude, October28,2026. A separate ChatGPT conversation has implemented development work in open PR#1. Tin’s latest original-game clarification below supersedes the earlier fan-client/patcher proposal. This document records scope, not completion or physical verification._

## Latest scope clarification from Tin — October 28, 2026

Offline Dokkan is **our own original offline game/version**. Eclipse and Sparking are research, database, asset and website-download sources. They are not game modes, separate playable editions or required live services for our game.

- One Offline Dokkan identity and game flow, with its own saves, progression, agreed rules and integrated Creator.
- No Eclipse/Sparking mode picker on Offline Dokkan’s home screen. Source labels belong only where needed to import, validate or update data.
- No requirement to sign into, connect to, or reproduce the live server protocol of Eclipse/Sparking. Remove “verify the original game connection” from mandatory release blockers. Any compatibility research must serve a specifically chosen import/runtime component, not redefine the product as a fan-server client.
- Unit Creator remains compatible with **both** Eclipse and Sparking. Its genuine export/import destination choices are a separate requirement and must be preserved.
- Imported data/art/animations retain their actual provenance; “our original version” does not mean third-party assets were authored by us. Preserve the existing bring-your-own-data and distribution rules.
- The old IPA findings below remain historical research. Their speculative patcher architecture does not override this clarification. Real offline gameplay and device acceptance still require implementation/verification; removing an unnecessary server dependency does not make them complete.

## 1. The goal
- Our own **original offline Dokkan version**, targeting the agreed Dokkan experience and rules on iPhone Duo first, then iPhone and Android. Eclipse/Sparking supply research and permitted/user-imported data/assets, with **no external game server or internet** required to play.
- **The difference:** a **Creator section inside the game** opens the Dokkan Unit Creator. A finished character lands in the game automatically on your own summon banner. No exporting, no moving files.
- Internet is only used when you choose to check for updates.
- **Personal use and fun only. Never sold.** Can be shared free with friends and family (section 6).
- Shared source/project folder: `~/AI-Workspace/claude-chatg/offline-dokkan/`. Don't modify Eclipse, Sparking or the Unit Creator without Tin's OK. Never alter his original IPA files.

## 2. Current product architecture and data sources
- Build our standalone Offline Dokkan app and its own local game logic/data services. Import compatible databases/assets from the user’s permitted sources. Runtime/renderer reuse remains a technical choice to verify; the app must not become an Eclipse/Sparking mode or depend on their online clients/services.
- Our local game core holds:
  - player saves (box, items, stones, progress)
  - **summon banners**
  - pity counters
  - drop rules
  - the event schedule
- Add a **Creator button** that opens the Unit Creator.
- Sign/install our iPhone/Duo app through the separately approved App Installer workflow. Actual Apple signing and physical acceptance remain separate verification requirements.

### Already verified (from the game data the Unit Creator reads; Sparking has 233 tables)
| Part | Table | Rows |
|---|---|---|
| Story/event areas | areas | 751 |
| Quests | quests | 3,490 |
| Stage boards | sugoroku_maps | 5,914 |
| Enemies on boards | sugoroku_map_enemy_informations | 5,567 |
| Enemy skills | enemy_skills | 11,124 |
| Enemy AI rules | enemy_ai_conditions | 7,457 |
| Boss drops | sugoroku_map_boss_drop_items | 15,795 |
| Missions / rewards | missions / mission_rewards | 27,677 / 49,210 |
| EZA battles | z_battle_stages | 241 |
| Hidden Potential | potential_boards / potential_squares | 45 / 15,030 |
| World Tournament | budokais / budokai_ranks | 64 / 768 |
| Dokkan Fields | dokkan_fields | 19 |

**Not in the data:** summon banners, player data and the event schedule. Our built-in server makes these.
- Banners are built from the characters in the data.
- Lineups and rotation dates come from **DokkanDB** (dokkandb.com) and **DokkanInfo** (dokkaninfo.com).
- Both sites block automated reading from the cloud and need a check in a real browser.

### IPA findings (Claude, Oct 28, 2026 12:05 PM, quick look on Tin's Mac)
Files: `~/Downloads/Sparking 6.6.ipa` (1.1 GB) and `~/Downloads/Eclipse Patcher v3.0.0.ipa` (1.0 GB). Originals left untouched.
- **Both are the official Dokkan app** (`BNGI0221.app`, Bandai's C++ cocos2d-x engine) **plus one injected tweak dylib** (theos + CydiaSubstrate `MSHookMessageEx`):
  - Sparking: `Frameworks/DokkanSparkingPatcher.dylib` (5.7 MB). Server `https://dokkan-sparking.com`, Discord login, its own asset downloader. Source files named in it include `HttpAsynConnectionClass.x` and **`LocalResponseHandler.x`** (it answers some requests inside the app). Ships `ios_current.json` / `ios_6.4.0.json` = function addresses in the game binary (InGameLayer, AbilityManager, DPuzzleGameLayer, MasterClock…).
  - Eclipse: `Frameworks/EclipsePatcher.dylib` (1.3 MB). Servers `mod.dokkan-eclipse.com`, `cdn.dokkan-eclipse.com`, original `ishin-global.aktsk.com`, and `http://127.0.0.1`. Has **`EclipseOfflineMode`, `EclipseOfflineProtocol`, `OfflineCache`, `_buildOfflineLoginResponse`, "Offline Mode"**: Eclipse already fakes login and caches responses locally.
- **Answers:**
  - Q1 (how the app reaches its server): the tweak hooks the game's HTTP class (`HttpAsynConnection`) and redirects or answers requests. This supports a historical runtime-reuse proposal; it is not the current product definition and does not make fan-server wire compatibility a mandatory release requirement.
  - Q2: battle runs in the app (InGameLayer, DPuzzle, AbilityManager). The server receives results (`/user_areas`, `/sugoroku_maps/finish`, `/missions/...`).
  - Q3: yes. Eclipse already has an Offline Mode.
  - Q5: the examined fan patchers ship as "game app + injected dylib, re-signed". That describes those sources; it does not impose dylib injection as a requirement for our standalone Offline app.
- **Historical endpoint strings observed in the tweaks** (not a current required endpoint contract for our standalone game): `/auth/nonce`, `/auth/sign_in`, `/resources/login`, `/resources/home`, `/user/mydata`, `/user_areas`, `/user_cards/`, `/cards`, `/teams`, `/events`, `/quests`, `/sugoroku_maps/start`, `/sugoroku_maps/finish`, `/missions`, `/missions/put_forward`, `/potentials`, `/potentials/release`, `/equip`, `/dragonball_sets`, `/db_stories`, `/genkai_battles`, `/joint_campaigns`, `/cooperation_campaigns`, `/announcements`, `/briefing`, `/support_leaders`, `/client_assets`, `/ondemand_assets`, `/assets/database`, `/sd/battle`, `/sd/characters`, `/sd/packs`, `/unrelease`, `/item_reverse_resolutions`, `/iap_rails` (stub).
- Still open: Q4 (Creator button: Sparking already has an in-game overlay panel `MainUIHandler …InGameTogglePanel`, a good model), Q6, Q7.
- **Rules:** never put Bandai's app, database or the Sparking/Eclipse keys in the repo. Each user brings their own IPA; our tweak is the only thing we ship.

### Remaining implementation questions
1. Select and implement the game runtime/renderer and actual offline battle flow; saved-state management alone is not a playable game.
2. Validate imported database/assets against our own domain rules and preserve each source’s provenance. Cloud-supplied files can be researched without using the Mac.
3. Finish the integrated Creator route, data migration and all agreed progression/reward features.
4. Verify optional website data downloads and banner schedules with supported access; data import/update choices belong in setup.
5. Verify iPhone Duo first, then iPhone and Android: real signing, installation, persistence, displays, touch and final gameplay. An adapter to Eclipse/Sparking’s live servers is not a prerequisite.

## 3. Progression (like a fresh official account)
- Start with nothing unlocked. Play Story, Events and missions to unlock more.
- **Everything is farmable.** No event is ever gone for good. Rewards can be earned again and again (Sparking-style).
- Drop multipliers:

| Drop | Multiplier |
|---|---|
| Items (missions, events, story, everything) | 3× |
| Awakening Medals | 6× |
| Dragon Stones | 10× |

## 4. Summon banners
| Banner | What's in it | When it changes |
|---|---|---|
| **Live official banners** | Same banners as the real game right now | Whenever the real game rotates them |
| **2 random rotators** | Random official banners from **the last 9 months only** | Every week |
| **Elder Kai banner** | Only Elder Kais. Each raises a character's Super Attack level by 1 | Every weekend |
| **Unit Creator banner** | Every official character that is **not** a Carnival, Dokkan Fest or Rising exclusive, **plus every character the player created or imported** | Featured lineup changes as new creations arrive |

- Summon prices: official, 5 Dragon Stones single, 50 multi.
- **Unit Creator banner details:**
  - **Featured: 5 characters.** A new creation pushes the oldest featured one out of the featured spot into the banner's normal rate. It never leaves the banner.
  - The **newest creation is the main featured character** and gets the **pity system**.
  - Rates: GR far rarer than SLR, SLR far rarer than LR; everything below LR at normal rates. Starting rates: **LR 1%, SLR 0.1%, GR 0.01%** (changeable).
  - **Pity**, for the main featured only. The counter shows on the banner ("Guaranteed in 7 more multis").

| Main featured rarity | Guaranteed copy on multi # |
|---|---|
| GR | 50th |
| SLR | 25th |
| LR | 10th |
| UR | 5th |

  The counter restarts after a natural or guaranteed pull, and when a new main featured arrives.

## 5. Created characters in the game
- Drop **fully awakened**, at **level 1**, Hidden Potential locked, Super Attack level 1, **no add-ons**.
- Train them, pull dupes and open Hidden Potential exactly like official cards.
- Stats grow with level up to the max stats set in the Creator.
- **SLR / GR:** their Super / Godly Exclusive bonus is **always on, at every level**.

### EZA / Super EZA on official characters
| Action | Who | Dragon Stones | Animated banner on the card |
|---|---|---|---|
| Custom EZA | Official characters with **no** EZA | 500 | "Custom EZA" (not official) |
| Custom Super EZA | Official characters with **no** Super EZA | 700 | "Custom Super EZA" (not official) |
| Enhance to current meta | Official characters that **already have** an EZA/Super EZA. They can't be hand-edited; this auto-upgrades them to today's meta | 300 | "Enhanced" |

### World Tournament
- **Weekend-only** event, built on the game's own World Tournament data.
- Our own **World Tournament exclusive characters**, earned only from ranking rewards.
- **Simulated AI rankings:** AI players climb all weekend as if real players were grinding. If Tin doesn't play much that weekend, he falls behind. Reaching #1 takes real play.
- Final rank sets the rewards when the weekend ends.

## 6. Sharing with friends and family
- Free to share, never sold.
- The shared app holds **only our own work**, with **no Bandai Namco files**.
- Each person installs our app with their **own Apple ID** and imports their own permitted databases/assets. Eclipse/Sparking packages or website downloads may be sources; their online services and game-mode identities are not part of our game.
- **Sharing created characters:**
  - Share sends a small unit file (Messages, AirDrop, anything).
  - The friend imports it, and it lands on **their** Unit Creator banner as their newest main featured, credited "Created by Tin".
  - Only created characters can be shared. Custom EZAs, Custom Super EZAs and Enhanced cards cannot.
  - No duplicates: the same character imported twice is added once, and a newer version replaces the old.
  - Unit files hold only the character's settings. Art and animations come from each person's own game data.

## 7. Updates
- **Never needed to play.**
- Optional updates:
  - Import a newer Eclipse or Sparking APK/IPA to add new characters, events and data.
  - Read banner schedules from DokkanDB / DokkanInfo.
- Download only what's new, validate it, keep progress, and never break already-downloaded events.
- Save export/import for backups.

## 8. Build stages (when Tin says go)
1. Finish the Unit Creator, then its builds when Tin says so.
2. Validate the chosen runtime/data imports and standalone game architecture. Use Mac-only inputs only within specific approval; do available research in the cloud.
3. Built-in server v1: login, box, items, saves, all offline.
4. Story and events (with the drop multipliers, always farmable) plus the weekend World Tournament.
5. Summons: live official banners, 2 weekly rotators, weekend Elder Kai banner.
6. Training and upgrades: levels, Super Attack levels, Hidden Potential, dupes.
7. Unit Creator inside the game: Creator button, Unit Creator banner with featured 5 and pity.
8. EZA features: Custom EZA / Super EZA / Enhance with stone prices and animated banners.
9. Sharing: unit files and bring-your-own-data setup, with source choices confined to import/update screens.
10. Updates: import newer game versions, banner schedules.
11. **3 versions: iPhone Duo (PRIORITY: build, test and polish it first), iPhone, and Android** (Tin, Oct 28, 12:23 PM). All three have the same features. See IPHONE-DUO-DISPLAY.md. Android provides the same original game/features, using supported imports of the user’s permitted data/assets.
