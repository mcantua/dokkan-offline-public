# Dokkan Unit Creator — Feature Inventory (before the v2.36 redesign)

Taken on 27 Oct 2026, before the new look. Use this list to check that nothing was lost.
- Files are in v2/ui unless marked web/src.
- Each line reads: feature — test hook (file).
- The automatic check is `web/test_redesign.py`.

## 0. Global shell
- Skip link `a.skip-link`; brand → Home `.sidebar .brand[data-nav="home"]`
- Breadcrumb `#breadcrumb`, `.mobile-brand`; save state `#save-state`; Import file `#import-top`
- Help for this screen `#shell-help`; Settings `#shell-settings`; Eclipse docs `#help`
- Toast `#toast`; busy overlay `#busy` (`#busy-title`, `#busy-detail`); generic dialog `dialog#dialog`
- Back handling `window.forgeHandleBack`; download pill `#offline-pill`; draft recovery `forge-draft`
- Save conflict dialog `#save-conflict-*`; recover designs `#recovery-backups`; saved versions `[data-action="project-versions"]`, `#save-named-version`, `#restore-named-version`

## 1. Navigation
- Sidebar `[data-nav]`: home, library, source (Create), animations, combat, movies, assets, ai; extras `.shell-side-extra [data-side-go="templates|offline|settings|help"]`
- Mobile/rail nav: Home, Create, Animate, Library + More `.shell-more-button` → `#shell-more` (`[data-shell-go="templates|ai|movies|combat|import|offline|settings|help"]`)
- Welcome tour `#shell-tour` (`[data-tour]`, experience/text/theme radios, `[data-tour-go]`)
- New data prompt `#new-data` (`[data-nd]`); first-run Downloads (`forge-offline-asked`)

## 2. Home
- Hero `.db-hero`; ⚡ Create a unit `#db-quick` → `#cc-new` (`#cc-template` Quick Create, `#cc-scratch`), `#cc-eza` → `#ez-eza` / `#ez-seza` → `#ezw-game` or `[data-ezw]`
- Your units `.db-tiles .db-tile[data-open]` with art and rarity badge; See all `#db-library`; start card `#shell-start`
- Quick Create `#qc-dialog`: fighter `#qc-finder`/`#qc-search`/`[data-qc-i]`; style `[data-qc-style]`; name/rarity (GR/SLR/LR/UR)/class/type

## 3. Unit picker rules
- Fully awakened only: `ForgeCardVersions.finalId` / `collapse()` (card-versions.js)
- Player cards only: `isPlayerCard` (card-versions.js, finder.js)
- No duplicates: collapse key name|element|rarity|passive|leader (+formKind in finder.js)
- SEZA > EZA > base: `status()` badges `.cv-seza`/`.cv-eza`; `RANK={seza:2,eza:1,"":0}` (dbz-home.js `transformations`)
- Earlier versions only on request: `[data-fd-every]`, `#source-all`, `#guide-unit-all`

## 4. Create (source)
- Finder `#fd-create .fd`: search `[data-fd-text]`, versions `[data-fd="ver"]`, rarity, type, class chips, `details.fd-more` (category, EZA, sort, earlier versions), clear, results `.fd-tile[data-fd-pick]`, show more, get newest data `[data-fd-update]`
- Quicker ways: Quick Create, Use a template, Describe to AI (`.creation-start-options`)

## 5. Card Builder (editor, `#bld`)
- Header: progress balls, AI helper `[data-b="ai-helper"]`, Undo/Redo, More menu (glossary, Classic editor, Saved versions, new skill names), Templates, Copy from a unit `.ucopy-button`, tips `.bld-tip`, form banner, live card `#bld-card`, tabs `.bld-tab[data-b="tab:*"]`, footer prev/next
- Tabs: basics, leader, passive, supers, active, standby, domain, links, look, save (EZA: eza, leader, passive, supers, save)
- Basics: name, rarity, class, type, stat presets, HP/ATK/DEF, cost/level/SA cap/level-1 stats
- SLR/GR exclusive perks (lv 180/200): Super/Godly Exclusive ATK & DEF +10/20% and 10/20% DR, permanent, applied last (`ForgeLevelPerks`)
- Leader: stages, name/description/auto, groups (who, types, class-types, categories, Ki, stats, split), tiers, presets, copy/combine
- Passive: stages, name, abilities (Edit/Done, delete); family editor: what it does, who gets it, when & how often (timing, turns, **chance slider `s.chance`**, once), requirements (condition editor `.bld-cond`: rules, ALL/ANY, add, custom, advanced, copy), advanced raw values; Add an ability `[data-b="pcat:add"]` (`dialog.pf-sheet`), preset ability, copy a character's passive, copy passives from characters, organize & balance, counter, Ki-sphere bonus, balance check, intro, transformations wizard `#bld-tf-new`, forms, revival, description preview, EZA notice
- Super Attacks: add Normal/Ultra(Hyper)/Condition/Extra, copy from game, name/type/Ki/damage/hits/conditions/EX trigger & chance/effects/auto text/remove/animation, EZA adds
- Active Skill: kind, name, create, lasts, uses, boost, hits, attacks, effects, conditions, texts, animation, delete
- Standby & Finish, Domain (special-skills.js)
- Links & Categories: `#lookup-query`, `[data-link]` (max 7), `[data-category]`
- Look & Animations: art studio `.art-studio-button`, more artwork options, AI art, normal attack style, per-move animations, animation editor, My animations
- Save & Play: checklist, validation, Put it in your game: `to-eclipse`, `to-sparking`, `send-files` (.SQL/.JSON); `eclp`, `json`, `sql`, `zip`, `eclp-online`; shared actions flow; export repair; patch details `[data-bind="patch:*"]`
- EZA project: growth table, Add Super EZA `[data-b="eza-seza"]`, medals
- Classic editor: `.stepper [data-step]`, advanced table, preview `#unit-preview`

## 6. Library
- Filters `[data-library-filter="all|created|uploaded|patches|sparking"]`, search `#library-query`, unit tiles, patch tiles + dialog (export/edit/delete/open Eclipse), Sparking characters `#sparking-content`, more tools (shared actions, Sparking builds, build resources)

## 7. Animations
- Beginner timeline `#tl` (play, parts, trim, checks, music, save, more), advanced studio (browse/compose/assign/assistant), My animations gallery, preview dock, trim

## 8. Game movies — browser `#movie-browser` + movie editor
## 9. Combat workshop — `#combat-workshop` setup/arena/bindings
## 10. Assets & data — APK import, sync, import, report, restore DB, imported assets, browse Eclipse
## 11. AI — hub `.aic-hub`, AI settings (keys stay in native storage), helper chat, card art, subscription studio, Ask-AI bar
## 12. Downloads — `#offline-root`: Eclipse/Sparking tiles, mobile-data switch `#offline-any`, start/pause/cancel, Download everything `#offline-all`, progress, more options, storage choice
## 13. Update & import hub — `#import-hub` `[data-imp=*]`
## 14. Settings — `dialog.settings-sheet`: jump nav, theme/text/contrast/motion, help level/tips/tour, player/quality/offline, Lite/speed, your data (versions, recover, import, wipe), restore defaults, iPhone screen report `#set-iphone`
## 15. Help — `dialog.help-sheet`, search, topics, glossary
## 16. Templates & presets — `dialog.presets-sheet`

## 17. Platform layers
- Web: `html.web-version`, web.css hides phone-only items
- iPhone: `html.ios-app`, ios.css (safe areas, Duo rail), `__forgeFold`, display geometry from main.m

## 18. CSS load order
style, guided, movies, movie-editor, art-editor, battle-pose-editor, combat-workshop, simple-mode, workbench, builder, dbz-theme, rarity-badges, perf, beginner-tools, offline, trim, shell, **premium (new, v2.36)**. The web build adds web.css after perf. The iPhone build adds ios.css last.
