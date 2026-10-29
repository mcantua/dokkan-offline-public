# Offline Dokkan Battle: full plan

_Latest requirement: a 1-to-1 Dokkan client experience, with our agreed offline/custom changes and integrated Creator. The simplified replacement battle UI/engine was rejected. Source providers are not selectable game modes._

## Binding 1-to-1 requirement
Use the actual Dokkan game client/engine and its real screens, artwork, sounds, animations, Ki layout and battle behavior as the production foundation. Our own offline/custom version changes the agreed systems, not the underlying game into a simplified imitation. Keep original client files user-supplied, private and unchanged; ship only our authored code and permitted dependencies.

The JavaScript battle harness/native save-manager screens are internal development tools. They do not satisfy playable-game, fidelity or integrated-character acceptance. Own-policy damage/class/AI/ACT choices are not recovered Dokkan mechanics or an approved replacement. Do not extend them as the final game.

No live Eclipse/Sparking login/server is needed for offline play. The chosen actual game client's local runtime/API contracts still need real verification. This distinction preserves the source-only rule without discarding the real game engine.

## Latest scope clarification from Tin — October 28, 2026

Offline Dokkan is **our own original offline game/version**. Eclipse and Sparking are research, database, asset and website-download sources. They are not game modes, separate playable editions or required live services for our game.

- One Offline Dokkan identity and game flow, with its own saves, progression, agreed rules and integrated Creator.
- No Eclipse/Sparking mode picker on Offline Dokkan’s home screen. Source labels belong only where needed to import, validate or update data.
- No requirement to sign into, connect to, or reproduce the live server protocol of Eclipse/Sparking. Remove “verify the original game connection” from mandatory release blockers. Any compatibility research must serve a specifically chosen import/runtime component, not redefine the product as a fan-server client.
- Unit Creator remains compatible with **both** Eclipse and Sparking. Its genuine export/import destination choices are a separate requirement and must be preserved.
- Imported data/art/animations retain their actual provenance; “our original version” does not mean third-party assets were authored by us. Preserve the existing bring-your-own-data and distribution rules.
- The old IPA findings below remain historical research. Their speculative patcher architecture does not override this clarification. Real offline gameplay and device acceptance still require implementation/verification; removing an unnecessary server dependency does not make them complete.


## 1. The goal
- **Our own original Offline Dokkan Battle game**, with one app identity and one continuous local player save. Eclipse and Sparking are **development/data sources**, never selectable game versions or separate player modes.
- Use their databases, locally supplied files and permitted website/CDN downloads for the data/assets our game needs. Preserve source provenance internally; do not confuse the source provider with the player's game identity.
- Dokkan Battle look, sound, gameplay and the progression rules below remain the intended experience. A working save manager alone is not the completed game.
- A **Creator section inside our game** opens the Unit Creator. A finished character appears directly in our own collection and team system, remains editable and registers in the Creator library/banner system, without exporting/moving files. Actual battle abilities and resources must work before completion.
- After data setup, playing requires **no server and no internet**. Internet is only for explicit setup/downloads and optional updates.
- Personal use and fun only; never sold. Shared code/packages contain our work, not databases/assets/private keys.
- Duo first (both displays), then iPhone and Android, with equal features. Unit Creator is fully embedded in the final Offline Dokkan application, with shared character/assets/save systems. Its standalone HTML remains a development tool; earlier standalone code/builds are preserved as working development resources.

## 2. Current implementation direction
- Preserve actual Dokkan client screens and battle execution. A verified in-process local adapter connects that client to our local player/save/summon/progression core; the embedded Creator uses the same characters/assets/data. Do not guess current-client responses/hooks.
- Imported source data is read-only and identified by its actual hash. Setup may identify Eclipse/Sparking as the **data source**; the main game never asks which one to play.
- Start with one active validated master snapshot and one canonical player save/Creator workspace. Do not blindly merge source IDs: cross-source catalog composition and updates need explicit validated mappings so existing progress remains valid. Changing a content provider never creates a second game/profile or discards progress.
- Preserve existing development saves during the correction. Adopt an unambiguous compatible legacy save safely; ambiguous legacy data requires explicit recovery instead of silently choosing/merging/deleting it.
- Use bounded, verified local imports and explicit HTTPS website downloads. Source downloads are not remote gameplay/logins; no source account or proprietary key ships in the app.
- Implement and verify the selected actual client’s offline adapter. Keep its engine/UI/assets intact; account for exact current method signatures, payloads, callbacks and resource dependencies. Static strings/historical samples are research only.

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

### IPA findings (historical Claude research, Oct 28, 2026 12:05 PM)

**Historical proposed approach:** the patching statements in this subsection describe Claude's earlier idea. Tin has clarified that the product is our own game, not an Eclipse/Sparking mode selector. These findings do not define the current architecture or require source-client wire compatibility.
Files: `~/Downloads/Sparking 6.6.ipa` (1.1 GB) and `~/Downloads/Eclipse Patcher v3.0.0.ipa` (1.0 GB). Originals left untouched.
- **Both are the official Dokkan app** (`BNGI0221.app`, Bandai's C++ cocos2d-x engine) **plus one injected tweak dylib** (theos + CydiaSubstrate `MSHookMessageEx`):
  - Sparking: `Frameworks/DokkanSparkingPatcher.dylib` (5.7 MB). Server `https://dokkan-sparking.com`, Discord login, its own asset downloader. Source files named in it include `HttpAsynConnectionClass.x` and **`LocalResponseHandler.x`** (it answers some requests inside the app). Ships `ios_current.json` / `ios_6.4.0.json` = function addresses in the game binary (InGameLayer, AbilityManager, DPuzzleGameLayer, MasterClock…).
  - Eclipse: `Frameworks/EclipsePatcher.dylib` (1.3 MB). Servers `mod.dokkan-eclipse.com`, `cdn.dokkan-eclipse.com`, original `ishin-global.aktsk.com`, and `http://127.0.0.1`. Has **`EclipseOfflineMode`, `EclipseOfflineProtocol`, `OfflineCache`, `_buildOfflineLoginResponse`, "Offline Mode"**: Eclipse already fakes login and caches responses locally.
- **Answers:**
  - Q1 (how the app reaches its server): the tweak hooks the game's HTTP class (`HttpAsynConnection`) and redirects or answers requests. **Our offline app = the same game app + our own tweak with a full local server inside it.** Proven approach.
  - Q2: battle runs in the app (InGameLayer, DPuzzle, AbilityManager). The server receives results (`/user_areas`, `/sugoroku_maps/finish`, `/missions/...`).
  - Q3: yes. Eclipse already has an Offline Mode.
  - Q5: the patchers ship as "game app + injected dylib, re-signed", so the App Installer must support injecting a dylib + re-signing (same as these IPAs).
- **Server endpoints our local server must answer** (seen in the tweaks): `/auth/nonce`, `/auth/sign_in`, `/resources/login`, `/resources/home`, `/user/mydata`, `/user_areas`, `/user_cards/`, `/cards`, `/teams`, `/events`, `/quests`, `/sugoroku_maps/start`, `/sugoroku_maps/finish`, `/missions`, `/missions/put_forward`, `/potentials`, `/potentials/release`, `/equip`, `/dragonball_sets`, `/db_stories`, `/genkai_battles`, `/joint_campaigns`, `/cooperation_campaigns`, `/announcements`, `/briefing`, `/support_leaders`, `/client_assets`, `/ondemand_assets`, `/assets/database`, `/sd/battle`, `/sd/characters`, `/sd/packs`, `/unrelease`, `/item_reverse_resolutions`, `/iap_rails` (stub).
- Still open: Q4 (Creator button: Sparking already has an in-game overlay panel `MainUIHandler …InGameTogglePanel`, a good model), Q6, Q7.
- **Rules:** never put Bandai's app, database or the Sparking/Eclipse keys in the repo. Each user brings their own IPA; our tweak is the only thing we ship.

### Current unresolved implementation work
1. Actual client/engine integration preserving 1-to-1 boards, battles, presentation and animation-script execution.
2. Complete source-data/asset dependency mapping and verified website download installation.
3. Safe content updates/cross-source mappings that preserve one player save.
4. Finish training, Hidden Potential, equipment, missions and first-run progression.
5. Full original-game UI and in-game Creator/banner integration on all three targets.
6. Optional banner metadata from DokkanDB/DokkanInfo with source/date provenance.
7. Apple signing/install and physical Duo/iPhone/Android acceptance. Cloud checks remain distinct from these steps.

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
- Each person installs our own app with their **own Apple ID** where required and imports/downloads their own permitted source content during data setup. They play our Offline Dokkan game with one save.
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
2. Own-game identity and one canonical player save; source adapters only in data setup. Continue source-backed development in the cloud.
3. Local game core v1: player, box, items and saves, all offline; own screens call it directly.
4. Story and events (with the drop multipliers, always farmable) plus the weekend World Tournament.
5. Summons: live official banners, 2 weekly rotators, weekend Elder Kai banner.
6. Training and upgrades: levels, Super Attack levels, Hidden Potential, dupes.
7. Unit Creator inside the game: Creator button, Unit Creator banner with featured 5 and pity.
8. EZA features: Custom EZA / Super EZA / Enhance with stone prices and animated banners.
9. Sharing: unit files, and "bring your own Eclipse/Sparking" setup.
10. Updates: import newer game versions, banner schedules.
11. **3 versions: iPhone Duo (PRIORITY: build, test and polish it first), iPhone, and Android** (Tin, Oct 28, 12:23 PM). All three have the same features. See IPHONE-DUO-DISPLAY.md. All three run our own game and use source files/downloads only for data setup.
