# Dokkan Unit Creator — fixes in this build

Base: `Dokkan-Unit-Creation.apk` versionName 2.12.3-android (versionCode 29). Version numbers are unchanged.

## v2.36.2 (code 127)
- **iPhone: no more freezing while downloading.** Saving, moving and listing files now happens in the background instead of on the screen's thread. Storage use is added up on the phone instead of sending the page a list of every downloaded file.
- **Faster, smoother downloads:** 24 files at a time instead of 48, which the phone and Eclipse's server handle better.
- **Portraits & Sprites:** the template character's own portrait, battle sprite and battle motion always come first, marked "Original" and selected. They're added even if the search missed them. Pictures load 48 at a time with a "Show more" button.

## v2.36.1 (code 126)
- **iPhone: no more downloading what Sparking already has.** The Sparking app keeps its downloaded game files on the phone (Files › On My iPhone › Sparking). With its folder linked (Downloads › "Link Sparking's folder", or the first Import to Sparking), the app copies Sparking's files instead of downloading them. That covers Sparking's character database and game files, and Eclipse files with the same name and size. Every copy is checked first: the size and checksum must match. Because Sparking's files stay when the Unit Creator is deleted, a reinstall doesn't download them again. Downloads show how much was taken from Sparking.

## v2.36.0 (code 125)
- **New "Dragon Ball intensity" look across the whole app:** a dark battlefield backdrop with a golden aura, fiery main buttons, Goku-blue second choices, comic-style outlined titles and slashed fighting-game menu bars. Effects switch off in Lite mode, on slower phones and with Reduce motion. Every feature, setting, saved unit and the iPhone Duo full-screen layout are unchanged.
- **Home looks like Dokkan Battle's main screen:** your last unit big in the middle with an aura, banners on the right (Create a unit, EZA / Super EZA, Templates, Import, Sparking characters, Downloads), a big pulsing **Continue** button, and your units below. Works for Dokkan Eclipse and Dokkan Sparking.
- **Simpler card builder:**
  - The first tab, **Portraits & Sprites**, has just 3 big buttons (Portrait, Battle sprite, Battle motion), each showing what's chosen now.
  - **Artwork & Aura** is second.
  - **Super Attacks** shows each attack as a short card (name, Ki, damage) you tap to edit; normal attack and other move animations are at the bottom.
  - **Passive Skill** has the Add buttons at the top and the in-game preview folded away.
  - **Links & Categories** lists your picks first.
  - **Save & Play** shows one "ready" line and the 3 big buttons (Import to Eclipse, Import to Sparking, Export .SQL / .JSON), with other file types under "Other ways to save".
- **Easier ability editing:** each ability's settings are numbered steps (1 What it does, 2 Who gets it, 3 When & how often, 4 Requirements). "Chance to activate" has quick buttons (25%, 50%, 70%, 100%) next to the slider. Critical, dodge and every other ability keep all their options.
- **Card builder tabs** all show at once on wide screens (no sideways scrolling).
- **Import to Sparking on iPhone:** link Sparking's folder once (On My iPhone › Sparking). After that, every unit goes straight into it and Sparking opens, with no searching through folders. Sending the same unit again makes no second copy, a renamed unit replaces its old file, and a broken link (game reinstalled) is explained and fixed in one tap. "Save somewhere else" is still there. Eclipse works the same way.
- **Portraits & Sprites:** search a character (for example Goku) to see every portrait the game has for them (429 for Goku), every battle sprite (▶ pose preview in the phone app) and every battle motion style. "Undo all" goes back to the original look. Skills and stats don't change.
- **Import from .sql:** Update & import › "Import a .sql file". The app reads the file's game data (only its INSERT rows; nothing in the file is run) and turns it into an editable unit in your Library. Your own .SQL comes back exactly. Pictures and animations come from the game card it's based on, and transformations in the file need adding again. On iPhone and the web version, "Choose a file" takes .sql too.
- **Fix:** Sparking 6.6 needs a creator number in every patch, and patches without one were refused. The app now always adds it (iPhone and Android).
- Android: Import to Sparking/Eclipse no longer risks losing the old file if replacing it fails.

## v2.35.4 (code 124)
- **iPhone: no more freezing while downloading.** Downloads now run in the background instead of on the screen's thread (48 files at once used to freeze scrolling and taps). Screen-edge updates and the SLR/GR check also do much less work.
- **Downloads made simple:** one choice — ⭐ Everything or Just the basics — plus mobile data on/off. Game movies and player settings are under "More options".
- **Sparking is easy to find:** its own purple card with an on/off switch, showing "✓ Up to date" or "New Sparking characters". If Sparking isn't set up yet, an "Open Sparking" button takes you there.
- **Sparking stays updated like Eclipse:** every time the app opens it checks Sparking too, and "New game data" now covers both. Before any download the newest Sparking data comes first, and your downloaded Sparking files are brought up to date after an update.
- Home: "in the menu bar" (on iPhone Duo the bar is on the side).

## v2.35.3 (code 123)
- **SLR / GR Exclusive is permanent:** it can't be removed or changed (the × is gone, and if anything takes it out it comes straight back). It's applied after every other boost — leader, links, Ki, Super Attack, Active Skill and the rest of the passive come first.
- **New: damage reduction in the Exclusive.** SLR (Super Exclusive): ATK & DEF +10% and "Reduces damage received by 10%". GR (Godly Exclusive): ATK & DEF +20% and "Reduces damage received by 20%". In every passive the unit has (before EZA, EZA steps and forms).

## v2.35.2 (code 122)
- **iPhone Duo: true full screen on both displays.** The status bar/camera column no longer leaves an empty black strip: on the 27.1 layout the tab bar now stands in that column (like Apple's apps) and the bottom bar is gone, so screens get the full height. Content stays clear of cameras, the status bar and the home bar using the phone's own numbers (including iPhone Duo camera regions). Folding/unfolding keeps your place and edits.
- Inner display sideways: the upright tab bar replaces the left menu, so screens get that width too.
- Settings › This iPhone's screen now shows "Full screen: Yes/No" and the edges kept clear.
- Every future iPhone build is checked automatically and is refused if it would bring the black bars back.

## v2.35.1 (code 121)
- Removed the old "Special Skills" step — everything on it now has its own place (counters & revival in "＋ Add an ability", Intro on Passive Skill, Active Skill, Standby & Finish, Domain and Super Attacks steps). Help text updated.

## v2.35.0 (code 120)
- Revival and Transformation sections removed from the Passive Skill step: both are added from "＋ Add an ability" (Character exclusive) and show in the ability list. Revivals are normal ability cards (with "＋ Add a bonus after reviving" and "⟳ Transform when it revives"); transformations show as "Turns into …" cards; adding one opens "⟳ New transformation" at the top of the step.
- Active Skill, Standby Skill & Finish Skill and Domain removed from "＋ Add an ability". New steps: ⏳ Standby & Finish and 🌐 Domain (Active Skill already has its own step).
- Descriptions are rewritten automatically every time the builder is drawn, so they follow any change to the character (added, changed or removed skills, renamed forms).

## v2.34.0 (code 119)
- "＋ Add an ability" uses Dokkan Battle's own wording (e.g. "Chance of evading enemy's attack", "Damage reduction rate", "Attacks guaranteed to hit", "Foresees enemy's Super Attack", "Survives K.O. attacks", "Can nullify attacks that are guaranteed to hit").
- New group "Nullify & immunity": Nullifies enemy's attack, Nullifies enemy's Super Attack, Immune to negative effects, Immune to stun, Immune to Super Attack seal, Immune to ATK & DEF reduction, Immune to action disabling, Can nullify attacks that are guaranteed to hit.
- "Stop the enemy" split into: Stuns the attacked enemy, Seals the attacked enemy's Super Attack, Disables the enemy's action, Disables the enemy's guard.
- Character exclusive now lists: Transformation, Revival, Active Skill, Standby Skill & Finish Skill, Domain, Entrance Animation, Directs enemy's attack towards the character (new LR Super Saiyan Goku / Frieza (Final Form) mechanic; also an Active Skill effect), Giant form / Rage, Reversible Exchange, Deactivates transformation, Standby mode, Cancels a skill.

## v2.33.3 (code 118)
- "Stop the enemy": the choice is now "What happens to the enemy" with plain options (Stun — it can't attack / Seal — it can't use Super Attacks / Skip — it loses its next action / Break guard — it can't guard) and a one-line explanation of the chosen one.
- Stun, Seal and Skip now let you choose When: when its attack hits, when attacking, right before attacking, when receiving an attack, or after receiving an attack (was fixed to "when its attack hits").

## v2.33.2 (code 117)
- "Revive" removed from "＋ Add an ability" — revivals are added only in the ✚ Revival section.

## v2.33.1 (code 116)
- "Survive & revive" split: "Survive a K.O. attack" stays an ability; Revive has its own ✚ Revival section on the Passive Skill step (between Intro and Transformations) with "＋ Add a revival", the revival editor (HP, animation, "＋ Add a bonus after reviving") and "⟳ Transform when it revives".
- Transformations: new way "When it revives" — transforms right after its Revival Skill brings it back (adds a revival if there's none).

## v2.33.0 (code 115)
- Create a unit (character template): step 1 now uses the character finder — only fully awakened, EZA and Super EZA characters plus their transformed / exchange / revival / giant / standby versions, with filters. Your own units and Sparking characters are under "Or start from one of your own units". The new unit always gets its own new IDs.
- EZA / Super EZA: after choosing EZA or Super EZA you pick "A character from the game" or one of your own units. For your unit the EZA steps are added to it (or its existing EZA opens for editing).

## v2.32.7 (code 114)
- Fix: a transformation that happens by itself (not via Active Skill) didn't show in the description for characters with Extreme Z-Awakening — it went into the pre-EZA Passive Skill while the builder shows the EZA one. It now goes into the Passive Skill you're editing and the base one (so it transforms with or without EZA), and transformations added before are moved over automatically. The description then shows e.g. "Starting from the 4th turn from the start of battle — Transforms into Goku".

## v2.32.6 (code 113)
- Character finder: transformed / exchange / revival / giant / standby versions are only shown for fully awakened, EZA and Super EZA characters (forms of earlier, not-yet-awakened versions are hidden unless "Also show earlier versions" is ticked). Each one says whose form it is ("Transformed form · of Goku & Vegeta (Angel)").

## v2.32.5 (code 112)
- Character finder tiles: the "Transformed form" (etc.) and EZA tags now sit on their own line under the name and type instead of on top of the picture and name, so names are readable.

## v2.32.4 (code 111)
- Character finder: "All versions" is now the default and the Version row sits right under the search box, so transformed / exchange / revival / giant / standby versions appear in every search (tagged), without having to switch to them. "Normal cards" shows only the usual cards.

## v2.32.3 (code 110)
- Character finder (every "pick a character" window, including Create): new "Version" row — Normal cards, Transformed forms, Exchange forms, Revival / swap-in forms, Giant forms, Standby forms, Every version. Each special version is tagged on its card. Found from the game's own skills that point at those cards (transformations, Reversible Exchange, revive/swap-in, giant form, Standby Skill).

## v2.32.2 (code 109)
- Active Skill transformations: clearer notes. With an Active Skill already, the transformation joins it ("attack and effects happen together with the transformation"). With none, a "Transformation" Active Skill is made, and the Active Skill step says you can add an ultimate attack or a boost to it.

## v2.32.1 (code 108)
- Intro: "★ Make my own animation" and "★ One of my saved animations" at the top of "Choose an entrance scene" and beside the scene on the Intro section. If there's no intro yet, one is added first and your animation is used for it. The intro then shows "★ My own animation — name"; picking a game scene again switches back.

## v2.32.0 (code 107)
- Animation picker made simple: no more rows of category buttons. Step 1: "Make my own" / "My saved animations", or pick the character the animation belongs to (search box + A–Z list, plus "Shared transformation & finishing scenes" at the top). Step 2: that character's animations under plain headings (Super Attacks, Ultra, Active Skills, Counters, Transformations…), each listed once. "← All characters" goes back.

## v2.31.9 (code 106)
- Animation picker lists everything for every move: Everything, Super, Ultra, EX, Full Power, Ultimates, Active, Standby, Finish, Counters (all of them, by character), Transformations (transforming / turning back), Giant forms, Revivals, Intros, Nullify / absorb — plus shared and enemy animations that no card uses directly. "Everything" + search finds any animation of a character, each tagged with its kind.
- Fix: an animation picked from another move's list is kept when you later change other settings of that move.
- Web version: transformations, giant forms, nullify and shared animations are listed too.

## v2.31.8 (code 105)
- Passive "Who gets it" now also offers "Allies in certain Categories…" and "Certain characters (by name)…": pick as many as you like (chips with ×), plus "This character gets it too". Built with the game's own sub-target lists (Category = type 1, name group = type 4). The description says e.g. "\"Saiyan\" Category allies' ATK & DEF 30%▲" or "ATK & DEF 30%▲ for the character and allies whose names include \"Goku\"".
- Editing an ability no longer clears who it applies to.

## v2.31.7 (code 104)
- Every animation choice (counters, revivals, Super/Ultra/EX, Active, Standby, Finish, Look tab) now opens one organized "Choose an animation" window: Make my own / My saved animations at the top, a search box, category buttons (Counter animations, Super Attacks, Ultra, EX, Full Power, Ultimates, Active, Standby, Finish…), and every animation listed by character A–Z (repeated versions shown once; more load as you scroll).
- Web version: the game animation list now works there too.

## v2.31.6 (code 103)
- Counters: one simple "Damage reduction" choice — No damage reduction / all attacks / normal attacks only / Super Attacks only — then the %. The matching "when receiving …" condition is built automatically, and the description updates.

## v2.31.5 (code 102)
- Active Skill transformations are explained plainly: the wizard option "Active Skill (the player taps a button)" says whether it is added to your existing Active Skill or a new one is made; transformation cards say "This is an Active Skill transformation"; the Active Skill step shows "Tapping this Active Skill transforms the character into …".
- New passive conditions: "When activating the Active Skill" (the game's "When activating the Active Skill or when attacking with 24 Ki") and "When attacking with a certain Ki or more". Ki values follow the card's rarity (LR 24 Ki = 800, others 600).

## v2.31.4 (code 101)
- Passive Skill step order: abilities → Intro → Transformations → In-game description.
- The in-game description now updates when an intro or transformation is added, changed or removed (an intro with no bonuses shows "Activates the Entrance Animation…"; transformations show "Transforms into <your form's name>").

## v2.31.3 (code 100)
- Transformations simplified: one panel. Each transformation is one card: "Turns into NAME", "When: …", and Edit / Change when / Remove buttons; rarely used choices are under "More options". The add-a-transformation questions only show after tapping "＋ Add a transformation" (3 short questions, Cancel to close).

## v2.31.2 (code 99)
- Each transformed form under "Your transformations" now has a "🗑 Remove this transformation" button (asks first; Undo brings it back). It removes the transformation ability and deletes the form.

## v2.31.1 (code 98)
- The Intro is no longer a separate step. It is now a section of the Passive Skill step (between the description and Transformations). The builder has 9 steps.

## v2.31.0 (code 97)
- Transformations are no longer a separate step. They now sit at the bottom of the Passive Skill step (they work like a passive) and also at the bottom of the Intro step (for transforming right after the intro). The builder has 10 steps.
- All "Transform tab/step" wording now points to "Transformations on the Passive Skill step".

## Bugs fixed

1. **Battle-abilities editor could trap you on a step**  (`assets/ui/guided.js`)
   Many real game abilities store values outside the guided editor's fixed input ranges: flat DEF +3000 or −100000, ATK +1200%, or a −50% value with a percentage calculation. Such a value made the input field "invalid" before you touched it, so Back, Next, Done and the step buttons all failed with *"Value must be greater than or equal to -100"* (or similar). This happened on about 66 playable source cards, and on any unit after you used **Copy a character's passive** from cards such as Legendary Super Saiyan Broly.
   - The input range now always includes the stored value.
   - A flat DEF amount is no longer labelled "(%)" and gets a flat-amount range.

2. **Some source cards could never be exported**  (`assets/ui/core.js`)
   Fifteen Sparking player cards (for example Third Eye Gomah and Goku (DAIMA)) have a starting HP above their maximum HP. Every copy failed export with *"HP initial value must be between zero and its maximum"*. New copies now clamp the starting stat to the maximum.

3. **Lowering a max stat in Advanced mode blocked export**  (`assets/ui/simple-mode.js`)
   The automatic "lower the starting stat too" adjustment only ran in the simple editor. It now runs in every editor mode and ignores a temporarily empty field.

4. **Patch name stopped following the unit name in Advanced mode**  (`assets/ui/simple-mode.js`)
   The Eclipse patch name ("<name> — Custom Unit") now updates in every mode, as long as you haven't customized it.

5. **Saved-version review showed the wrong card**  (`assets/ui/project-versions.js`)
   Reviewing a saved version showed the original source card's name and stats instead of your design's. It now shows the design's own name and stats.

6. **Transformation picker listed identical choices**  (`assets/ui/forms-model.js`)
   EZA units list the same transformation several times (for example "Strongest Duo" three times), so you couldn't tell which one you were replacing. Each option now names its stage, for example "Strongest Duo · EZA stage 3".

7. **Bundled card database was never refreshed after an app update**  (native: `CreatorActivity.ensureDb` + new `ForgeFixes.refreshBundledDatabase`)
   `reference.db` was copied into app storage once and reused forever, so updating the APK with a newer database had no effect. The copy is now refreshed when the installed package changes. A database you imported from an Eclipse APK or downloaded is not touched.

## Round 2 — Eclipse compatibility (crash fix)

These changes are based on comparing the app's output with `Gohan_v8.eclp`, a custom unit that loads in Eclipse.

1. **Card and row IDs now follow the Eclipse layout.**  (`core.js`, `guide-model.js`, `guided.js`, `app.js`)
   - Units used to be placed at 10-digit IDs (1,950,000,001 and up), and every passive, leader, super attack and condition row was given IDs in the billions.
   - Units now get 8-digit card IDs ending in 1 (97000001, 97001001, …), like the working patch.
   - Each unit's rows stay in its own 1,000-ID block, and passive, leader and Active Skill sets use the matching 7-digit block (for example 9700000).
   - Units saved with the old IDs are moved to a new slot automatically the next time you export them, including in Expert mode.
2. **The patch can be imported again without breaking.**  (`core.js`)
   The SQL now uses `INSERT OR REPLACE`, as the working patch does. Plain `INSERT` failed with "UNIQUE constraint failed" whenever Eclipse applied the patch a second time (an update or re-import).
3. **Transformations returned to the official card.**  (`core.js`)
   Transformation and giant-form skills shared the official game's battle parameters, which name the official card as the one to return to. A custom unit could therefore turn into the official card mid-battle. Each unit now exports its own copy of those parameters, pointing back to your card (and to your custom forms).
4. **Transformation descriptions were missing.**  (`core.js`, `native-compat.js`)
   Every transformation in the game has one. The app never copied them, so custom transforming units had none. They are now added for every transformation.
5. **Extreme Z-Awakening could not be used.**  (`core.js`, `native-compat.js`)
   Units copied from EZA cards kept the EZA stages but not the routes that unlock them, so they were stuck on the pre-EZA kit. The routes are now exported.
6. **EX Super Attack options were dropped.**  (`core.js`, `native-compat.js`)
   They are now carried over with the unit.

Units saved by older versions are upgraded with items 3–6 automatically when you export.

## Added

- **Delete units and imported patches from the Library**  (`assets/ui/library-delete.js`, `style.css`, `index.html`; native `deleteProject` / `deletePatch` in `ForgeFixes`)
  Before this, nothing could be removed. Each unit tile now has a Delete button, and the patch dialog has "Delete this patch". Both ask for confirmation first. Deleting a unit removes its design and saved versions. Exported files and imported artwork are not touched.

## How the native changes are packaged

- `classes.dex` is the original code reassembled. Only two call sites were added: a call to `ForgeFixes.dispatch` at the top of `CreatorActivity.dispatch`, and a call to `ForgeFixes.refreshBundledDatabase` in `CreatorActivity.ensureDb`.
- `classes2.dex` is new and holds only `com.personal.aihub.ForgeFixes` (source in `ForgeFixes.java`).
- `ui-changes.diff` and `smali-changes.diff` show every change, so you can port them to your source project.

## Verified

- 727 units created from random Eclipse source cards (plus 160 from Sparking) through the app's own code, then exported.
  - All 887 SQL patches applied cleanly to a copy of the Eclipse database.
  - All 727 Eclipse units had zero dangling references: categories, skills, conditions, links and views.
- Every editor step rendered for 500 Eclipse and 250 Sparking source cards (all EZA stages), with zero invalid fields.
- ECLP files produced by the app's real Java code (`EclpCodec`, run on a desktop JVM) decrypt and match byte for byte.
- These flows ran end to end without errors: copy passive, leader and move; transformation form; saved versions; delete.
- Every screen and dialog button was clicked in a browser engine with no JavaScript errors.

## Not verifiable here

- Loading the ECLP inside Eclipse itself.
- Animation previews and artwork downloads, which need the live dokkan-eclipse.com site.

## Round 3 — Card Builder (new default editor)

Opening or creating a unit now goes straight to the **Card Builder**: one screen with step tabs and a live card preview that updates as you edit. The previous editor is still there — tap **Classic editor** at the top (and **✦ Card Builder** to come back). New files: `builder-model.js` (game-data logic), `builder.js` (screens), `builder.css`; loaded from `index.html`.

Every ability is built from plain-English choices. The builder writes the same kinds of game records that official cards use (matched against the most common official row layouts in the bundled database), and writes the in-game description for you. You can switch the automatic description off and type your own.

**Tabs**

1. **Basics** — name, rarity, Super/Extreme class and type (colour-coded), HP/ATK/DEF with presets, cost, levels.
2. **Leader Skill** — build leader skills from scratch in bonus tiers:
   - All Types, chosen Types, Super Class, Extreme Class, Super/Extreme + Type, or one or more Categories ("A" or "B" Category).
   - Optional "who also belong to …" tiers (e.g. *plus an additional Ki +1 and HP, ATK & DEF +30%*).
   - Ki and HP/ATK/DEF (equal or separate values).
   - Quick-start presets.
   - Category targeting reuses the game's own targeting records when an identical one exists, and creates the unit's own records otherwise. A unit counts once even if it is in several of the chosen Categories, the same way official leaders work.
3. **Passive Skill** — add abilities from a catalogue of 27:
   - **Stats:** ATK, DEF, ATK & DEF.
   - **Ki & Ki Spheres:** Ki; Ki per sphere; ATK/DEF per sphere; change sphere colours.
   - **Defense:** damage reduction, guard, evasion, heal, immunity to negative effects, foresee Super Attack.
   - **Offense:** critical hits, effective against all Types, additional attacks.
   - **Enemy effects:** lower ATK/DEF, stun, seal Super Attack, disable action.
   - **Team support:** Ki or ATK & DEF for allies of a Type.
   - **Growth:** stacking boosts per attack performed or received.

   Each ability has its own settings: when it happens, who it affects, how long it lasts, chance, once per battle, and conditions. **Conditions** come from a list of 20 rule types (HP %, from turn N, after N attacks/Super Attacks/evasions, Category allies on the team, facing a Category enemy, attack slot and more), combined with ALL or ANY. Rules a beginner can't express are kept exactly as they are; the existing advanced condition editor is one tap away. Abilities the builder doesn't recognise are kept unchanged and can still be retimed or removed.
4. **Super Attacks** — name, Ki needed, damage class, single or all enemies, and extra effects:
   - raise ATK/DEF (self, all allies, or a Class), critical hits, evasion, effective against all Types;
   - lower enemy ATK/DEF, stun, seal, disable action.

   You can add a Super Attack or an Ultra Super Attack (18 Ki) from scratch. Each attack's animation can be previewed, swapped for any character's, or edited in Animation Studio.
5. **Active Skill** — create one from scratch:
   - **Ultimate attack:** extra ATK boost, one or all enemies.
   - **Power-up:** Ki, ATK/DEF for self or team, heal, guard, crits, evasion, sphere change, stun/seal/disable.

   Set its activation conditions, duration and uses per battle. Use any official Active Skill's animation (cut-in and music).
6. **Transform** — add a transformation that happens automatically (with conditions such as "from turn 4" or "HP 50% or less") or by Active Skill. It can turn into **a new custom form you design** (a full unit you edit with the same builder; everything exports together) or into an existing game card. The builder uses the game's own transformation scene template and gives every unit a private copy, so a custom unit never turns back into the official card. You can also change or remove existing transformations.
7. **Links & Categories**, 8. **Look & Animations**, 9. **Save & Play** (checklist, validation and export).

**Live card preview** — rarity badge, class/type colour frame, art, HP/ATK/DEF/cost, and expandable details for the Leader Skill, every Super Attack, Passive (formatted like the game), Active Skill, transformations, Link Skills and Categories.

**Fixes made while building this**
- Typing a number and then tapping another button no longer swallows the tap: field edits update in place instead of redrawing the screen.
- Type colours use CSS classes. The app's Content-Security-Policy blocks inline styles, which would otherwise make every type look blue.

**Verification**
- Every catalogue entry round-trips through the game rows (294 combinations).
- The builder was driven through every tab and control in a headless browser, on desktop and phone sizes, on several source cards: EZA, active-transform, standby, no-leader, no-Super-Attack and Dokkan-field units. Each export was applied to a copy of the game database with no missing references. Transformations point at real cards and private battle parameters, and Category leader targeting records are complete.

## Round 4 — Connect your own AI (chat helper + card art)

**Connect any AI** (`ai-connect.js`, native `ForgeAi.java` in `classes2.dex`)
- Connect providers in **AI settings**, or use **Copy & paste mode**, which works with any AI app and needs no key:

  | Provider | What it can do here |
  | --- | --- |
  | ChatGPT / OpenAI | Chat and image generation |
  | Google Gemini | Chat and image generation |
  | Claude (Anthropic) | Chat |
  | Grok (xAI) | Chat and image generation |
  | OpenRouter | Chat, with access to hundreds of models |
  | Any OpenAI-compatible server | Chat and image generation |

- Paste an API key once. The app stores it in its private storage on the phone. The key is never shown to the web UI or put in exports, and it is only sent to that provider. **Save & test** checks the connection, and **Load model list** fills in the provider's available models.
- Requests run on their own background thread with polling, so a slow image generation never freezes saving or the rest of the app.
- Server addresses must be https://. Plain http:// is allowed only to 127.0.0.1, for an AI app running on the phone; this follows the app's existing network security policy.

**✦ AI helper** — in the Card Builder header, the Passive tab and the AI page.
- Chat about your unit. It already knows your current card: stats, leader, passive, supers, Active Skill, links and categories.
- Ask for changes ("make it an LR Super AGL Gogeta with a Fusion leader…"). The AI answers with structured builder actions covering:
  - basics;
  - multi-tier Category leaders;
  - passive abilities with conditions;
  - Super and Ultra Super Attacks with effects;
  - Active Skill;
  - Link Skills and Categories;
  - art ideas.
- The app checks every change and shows a review list. **Apply to my unit** makes all of them at once, and one **Undo** reverts them. Unknown names or abilities are rejected with the reason.

**◈ Create card art with AI** — in Look & Animations and on the AI page.
- Builds a Dokkan-style art prompt from your character, a pose, the unit's type colour and class.
- **Improve prompt with AI** rewrites it with your connected chat AI.
- Output options: a **transparent cut-out** of the character, full card art, or a background.
- Generates the picture with OpenAI, Gemini, Grok or a compatible server. The image is saved to your imported pictures; tap **Show on my card preview**, or **Put it in the in-game card art**, which opens the artwork editor to fit and export it.
- Without an image AI, copy the prompt into any image app and import the result.

**Animation Studio** (already in the app; now linked from the builder)
- Use any animation in the game.
- Combine several clips into one sequence: trim, reorder, split, move, zoom, mirror, mute.
- Assign the result to a Super Attack, Ultra, Active Skill, counterattack, transformation, normal attack or intro.
- The Look & Animations tab lists every animated move with Preview, Choose and Combine / edit. Counterattack abilities on the Passive tab have their own animation buttons.
- Verified end to end: two clips from different characters were combined, assigned to a Super Attack and to a counterattack, and exported. The patch contained both generated scripts and applied cleanly.

## Round 5 — Never overwrite game cards, EZA / Super EZA, Dragon Ball look, Quick Create

**Your units never replace anything in the game**
- **New, unused IDs.** Every new unit gets its own block of IDs. The block is now picked at random from 2,000 slots, so units made on different phones, or shared by other creators who use this app, almost never land on the same IDs. Each candidate block is also checked against:
  - every row the unit would write in the active game database;
  - your saved units, including their transformation forms and reserved blocks.

  (`guide-model.js`)
- **Free-slot check in every mode.** It now runs before every export, in Expert mode too. If the unit's slot has been taken (for example after a game data update), the unit moves to a free slot automatically. (`guided.js`)
- **Final safety check.** Just before any patch file is written, every database row in it is checked against the game database. If anything would replace an existing card or record, the export stops with a clear message and nothing is saved. The only exception is the one card you deliberately give an EZA or Super EZA. (`id-guard.js`, loaded right after `bridge.js`)
- **Verified:**
  - **Builder exports** (Quick Create, Card Builder, AI helper, Animation Studio): no rows that replace game data.
  - **Sparking units:** pass the final check.
  - **EZA / Super EZA exports:** the only existing row they touch is the awakened card itself, and only its EZA growth field (`optimal_awakening_grow_type`) changes.

**EZA / Super EZA of an existing card** (`core.js` `materializeAwaken`, `builder-model.js`, `builder.js`)
- From the home screen choose **EZA / Super EZA a card**, then pick the card.
  - **EZA:** creates 7 awakening steps using the official level pattern (125 → 140, Super Attack level 10 → 15). If the card already has an EZA, it is loaded so you can redo it.
  - **Super EZA:** adds step 8 to a card that already has an EZA.
- **Tabs:** EZA Overview (steps, level caps, awakening medals), Leader Skill and Passive Skill (choose which EZA step to edit), EZA Super Attack (upgraded attacks that unlock at Super Attack level 14), and Save & Play.
- **What the export contains:** only the records you create, all with new IDs: growth steps, skills, routes and upgraded attacks. The card's own record is re-exported unchanged apart from pointing at the new EZA steps. The card's original skills, attacks and existing awakening routes are never re-written. A Super EZA's 8th step uses the card's own EZA medals.
- The Card Builder can now also edit each EZA stage of normal units (stage picker on the Leader and Passive tabs).

**Easier to use**
- **New home screen** with four big choices: Quick Create, Build from a character, EZA / Super EZA, and AI helper & art. Your units appear as card-style tiles.
- **⚡ Quick Create** (`dbz-home.js`) takes three taps: pick a fighter → pick a fighting style → final touches (rarity, class, type, name).
  - **Fighting styles:** All-rounder, Heavy hitter, Tank, Speedster or Support.
  - **What you get:** a complete, balanced kit — Category leader skill, passive, Super Attack, and for LR an Ultra Super Attack and Active Skill. Edit anything afterwards.
- **Dragon Ball progress tracker:** collect all 7 Dragon Balls by finishing the name, leader, passive, Super Attacks, links & categories, card art and saving. It always shows what to do next.
- **Tips and glossary:** a tip on every builder step, and a plain-English glossary (Ki, Categories, Links, EZA…).
- **Simpler header:** extra tools moved into **⋯ More**.

**Dragon Ball style**
- Bundled fonts: Bangers for big titles and Russo One for interface text, under the SIL Open Font License (licenses included).
- Orange-and-blue energy colours, glowing Dragon Ball buttons, ki-burst hero, type-coloured cards and chunky orange action buttons, applied across the app (`dbz-theme.css`).

## Round 6 — Speed, and one version per character

**Why the app felt slow**
- The main screen ran with hardware acceleration switched off: `android:hardwareAccelerated="false"` on `CreatorActivity`, plus `WebView.setLayerType(LAYER_TYPE_SOFTWARE)`. So the phone's CPU drew every pixel. That made scrolling, taps, glows and the spinning hero background lag everywhere.

**Native fixes**
- **Manifest:** `CreatorActivity` now has `hardwareAccelerated="true"`. Patched in the binary manifest (`patch/axml_hwaccel.py`, applied by `build.sh`).
- **WebView setup:** `ForgeFixes.configureWebView` now replaces the forced software layer. It uses the GPU by default and software rendering only if the user picks **Compatibility**.
- **Safety net:** if the page renderer crashes twice within 10 minutes, the app switches itself to Compatibility graphics (`ForgeFixes.noteRendererCrash`, hooked into `onRenderProcessGone`) and turns on Lite effects.
- **New bridge method:** `renderMode` (get / `set: "gpu" | "software"`), which applies immediately.

**Interface fixes**
- **⚡ App speed** (home screen → More tools) offers two settings:
  - Visual effects: Full or Lite.
  - Graphics: Fast (GPU) or Compatibility.
- Lite mode removes blurred glows, shadows and animations (`perf.css`, `perf.js`).
- The spinning ki-burst is now static, and backdrop blurs are gone. `prefers-reduced-motion` is respected.
- **Typing:**
  - Undo snapshots are taken once per pause instead of on every keystroke (`guided.js`).
  - The crash-backup copy is written at most once a second, and immediately when the app goes to the background.
  - The preview redraws at most once per frame.
- **Live card:** it is only redrawn when its content changes, and the art image is kept, so it no longer reloads on each keystroke (`builder.js`).
- **Numbers:** they use one cached formatter instead of building a new one on every call (`app.js`). This was the biggest JS cost when opening a unit.
- **Quick actions:** they no longer flash the full-screen "Working…" overlay. It appears only if a job takes longer than about 0.3 s.

**One version per character** (`card-versions.js`)
- **Before:** game data lists every stage of a card (base, Z-awakened, each Dokkan awakening) plus enemy/story copies and transformation-only forms, so searches showed many copies of each character.
- **Now:** these screens show one entry per character, its fully awakened playable card:
  - Build from a character
  - Quick Create
  - every character picker (copy a skill, EZA picker, art, Animation Studio)
- **Badges:** cards that already have an Extreme Z-Awakening show **EZA**. Cards that already have a Super EZA (step 8, or the LR Super EZA route) show **SUPER EZA**.
- **Rules:**
  - Dokkan awakening chains (`CardAwakeningRoute::Dokkan`) are followed to their last card.
  - Cards outside the player ranges (3/5/7/9xxxxxx enemy, NPC and placeholder cards) and 4xxxxxx transformation forms are hidden.
  - Cards without a full kit are hidden.
- **Show every version** brings everything back when you need a specific card. Pickers for "which card does it transform into" show every version by default.
- The awakening index is built once from the game data and cached on the device. It is rebuilt automatically after a game data update.

**Verified**
- Builder, forms/undo, Quick Create, EZA / Super EZA, classic mode, Animation Studio, AI helper and the Sparking guard flows: no page errors.
- Exports: no rows replace game data.
- The rebuilt APK's manifest shows `hardwareAccelerated="true"` for `CreatorActivity`.

## Round 7 — Templates bring their transformations

**Before**
- Starting a unit from a game card copied only that card. Its transformations still pointed at the official game cards, so the custom unit turned into the original cards in battle.

**Now** (`template-forms.js`)
- **Build from a character** and **Quick Create** copy every transformation of the template into your unit as your own editable forms, each with its own private IDs. This covers:
  - automatic (passive) transformations
  - Active Skill transformations
  - Standby and Finish transformations
- **Chains are followed:** for example Frieza 1st → 2nd → 3rd → Final → Golden, or Super Saiyan Goku → SS2 → SS3 → God → Blue. Forms that turn back are included too, up to the limit of 4 custom forms per unit.
- **At export, every transformation inside the unit is moved onto your copies.** This includes:
  - form → form transformations
  - "turn back" transformations
  - the battle settings that name the card to return to
- **Transform tab:**
  - It lists forms reached through another form under **More forms in this unit**, each with an **Edit this form** button.
  - Inside a form, it shows what that form turns into.
- **Units made before this update:** they get a **Copy the transformations into my unit** button on the Transform tab.

**Supporting changes**
- **Form validation** (`core.js`) accepts forms reached through another form.
- **Removing or changing a transformation** keeps every form that is still reachable (`forms-model.js` `chained` / `prune`).

**Verified**
- **Templates tested:** Frieza (1st Form), Vegito, SS Gohan (Youth), Kefla, Gohan (Teen) and Super Saiyan Goku.
- **In every export:**
  - each transformation and return target points at the unit's own cards
  - no row replaces game data
  - the integrity check reports 0 problems
- **Also fixed:** editing an ability stage (for example a leader or passive edit) on a unit with a custom form could stop the next transformation with "A form points to another custom form…". Those stage copies are now accepted, and they follow their form if it moves to a new slot at export.

## Round 8 — Copying passives adds them, meta limits, live descriptions, bottom scrolling

**Bottom of screens could not be reached**
- **Cause:** on phones, the last buttons of a screen (for example the orange Next button on Basics) sat behind the bottom navigation bar. One stylesheet cut the bottom spacing to 36px, and the bar is taller on real phones.
- **Fix:**
  - The app now measures the bar's real height and keeps that much space plus a margin below every screen (`perf.js`, `perf.css`).
  - Focused fields and the toast also stay above the bar.

**Copying another character's passive now ADDS it** (`passive-merge.js`, `guided.js`)
- **Copy a character's passive** now offers **＋ Add to my passive** (the default) or **Replace my passive**. This works in the Card Builder (on any EZA stage) and in the classic editor.
- **Combining:** abilities that do the same thing at the same moment are combined into one, with their amounts added together. "Same" means the same effect, timing, target, duration, chance and conditions.
  - Example: "ATK & DEF +70%" and "ATK & DEF +250%" at the start of the turn become one "ATK & DEF +300%".
  - Effects without amounts (Guard, immune…) aren't duplicated.
- **Additional attacks are never combined**, because two additional attacks are two attacks. At most two can be triggered at the same moment.
- **Everything else is appended.** Transformations aren't copied with a passive; use the Transform tab for those.
- **Meta limits for one combined ability:**

  | Effect | Limit |
  |---|---|
  | ATK/DEF, self | 300% |
  | ATK/DEF, allies | 60% |
  | Enemy ATK/DEF down | 50% |
  | Ki, self | +7 |
  | Ki, allies | +3 |
  | Damage reduction | 60% |
  | Evade | 60% |
  | Critical hit | 70% |
  | Heal | 20% |
  | Per-Ki-Sphere bonus | 15% |
  | Ki per sphere | +2 |
  | Growth per attack | 50% |
  | Growth limit | 300% / Ki +7 |

  These match today's strongest LR/TUR units.
- **Description:** the combined passive's in-game description is rewritten to match, in the game's own wording and "*Heading* / - line" layout.
  - Matching lines under the same heading get their amounts added, within the same limits. New lines go under their heading.
- **After copying**, a short report lists what was combined, what was added, and anything that was kept within the meta.

**Descriptions now follow every passive change**
- **Line-by-line updates:** passives that keep the game's wording (or contain abilities the builder can't rewrite) are updated line by line whenever abilities are added (builder, classic presets, counters, AI helper), changed or removed.
  - When only the amounts change, the game's wording and icons are kept.
- **Auto-written descriptions** (builder-made passives) show abilities at the same moment as one line with their amounts added, as they stack in battle (two "Ki +3" → "Ki +6").
- **Fixed:** "checking conditions…" could be written into descriptions while conditions were loading. Texts now wait for the conditions and are finished afterwards.
- **Fixed:** the timing "when attacking" used by many game cards was shown as a basic effect.
- **Fixed:** headings like "When attacking when attacking as the 3rd attacker" no longer repeat the timing.
- **Fixed:** growth that resets every turn is now described "within the turn" and keeps that setting when edited.
- **Classic editor:** "Write a description from my effects" now writes the official layout.

**Balance check**
- **Card Builder:** the Passive Skill tab warns when abilities that stack go past today's meta, and offers **Fit to today's meta**.
- **AI helper:** abilities it adds that match an existing one are combined (within the limits), and it reports anything above the meta.

## Round 9 — Review of the "Beginner Test" build (ChatGPT changes)

**Starting point:** `Dokkan-Unit-Creation-Beginner-Test.apk` (com.dokkanunitcreation.dev, versionCode 55).

**What it adds (kept)**
- **Simple Animation editor** (`beginner-tools.js`, `sequence-*.js`): add clips, trim them, pick a song, preview, save a video, and use the result on a unit. The previous editor is still available as "Advanced editor".
- **My animations** (`animation-gallery.js`): animations kept independently of units.
- **Copy one Super Attack** from any character, including EX and Conditional attacks (`super-attacks.js`). New attack types: Conditional, EX and Full-power.
- **Transformation wizard with inheritance** (`form-inheritance.js`): forms follow the base unit's stats, leader, links, categories and other gameplay settings unless inheritance is turned off.
- **Saved-art thumbnails** in collections (`collection-art.js`).
- **Native code:** stricter project checks on save, and m4a/aac/flac audio support.

**Fixes made in this review**
- **Packaging:**
  - The test APK was signed with a different key and used a separate package name, so it could not update the real app.
  - The new build is the main app (com.dokkanunitcreation.app, "Dokkan Unit Creation", versionCode 56 / 2.13.0), signed with the release key, with GPU rendering kept.
  - **Units from the Test app:** units made in the separate Test app stay in that app. Save them there with Save editable backup and import them in the main app.
- **Removed a 10 MB leftover temp file** (`vendor/media/.ffmpeg-core.wasm.Dkw99Q`).
- **Animation editor:** after starting an independent animation, opening a unit and tapping Animate kept showing the independent animation instead of the unit's moves. Opening another unit now returns the editor to that unit (`animation-gallery.js`, `beginner-tools.js`).
- **Super Attack activation rules:**
  - Only Conditional Super Attacks use them in the game; none of the 19,000+ other Super Attacks do.
  - The condition editor is now shown only for Conditional attacks.
  - Changing an attack's type away from Conditional clears its rules and special asset id, matching the game data (`builder.js`, `super-attacks.js`).
- **Readability:** the description on a selected option card (e.g. "Automatically" in the transformation wizard) was orange on orange and unreadable.
- **One version per character in the Sparking catalog:**
  - Library → Sparking characters and the Sparking character pickers listed every card stage, often 10–20 copies of one character.
  - They now show one fully awakened playable card per character with EZA / Super EZA badges, like the Eclipse lists (`card-versions.js`, `sparking-content.js`, `guided.js`).

**Checked**
- Regression flows: Card Builder, forms/undo, Quick Create, EZA / Super EZA, classic editor, AI helper, transformations from templates, passive copy/merge/sync, full builder crawl.
- Simple and advanced Animation editor: clips, trim, use on a Super Attack, ECLP export round trip.
- Super Attack copying.
- Results: no page errors; every export has 0 integrity problems and replaces no game data.

## Round 10 — "Eclipse returned HTTP 404" when adding or previewing clips (v2.13.1, versionCode 57)

**Cause.** The app guessed the folder for each animation from its name. Every `tf…` scene (fusions,
transformations and transforming Active Skills, such as Goku & Vegeta (Angel)'s *Special Fusion*)
was looked up under `ab_script/transformation/`. Eclipse publishes those 65 files under
`ab_script/active_skill/`, so the request 404'd. Preview and Add clip both load the clip the same
way, so both failed.

**Fix.**
- `motion.js`: `tf` scenes now map to `active_skill`. The published file list is checked before
  any guess. When a name exists in several folders (e.g. `a0001`), the folder its prefix names wins.
- `studio.js`: clips are resolved against the published file list (bundled or refreshed) instead of
  the bare guess. A clip that really isn't on Eclipse (2 of 3,132 catalog entries) now says so in
  plain words instead of showing the raw HTTP 404.
- Verified: preview + add for all Goku & Vegeta (Angel) clips and other characters' clips, with a
  test double that 404s exactly like the CDN. The old build reproduces your toast; the new one
  passes. The simple-editor flow still exports with 0 problems and 0 overwrites.

## Round 11 — In-app animation player and Offline downloads (v2.14.0, versionCode 58)

### Previews play inside the app
- **Before:** every Preview opened a separate screen. It started its own browser, loaded the
  Eclipse player page, and then waited for you to tap “Load and play”.
- **Now:** previews play in a panel at the top of the same screen (`PreviewDock`, native). The
  editor stays visible and usable below it.
  - Tapping Preview on another clip replaces what's playing, in place.
  - The animation starts by itself.
  - The panel shows only the stage, with a slim control row: ⟲ replay, ❚❚ pause/resume, 2× speed,
    Crop (phone-screen view) and Tools.
  - Tools shows situations, recording and the full player. “Back to the simple player” returns.
  - Drag the bar under the panel to make it taller or shorter (remembered).
  - ⤢ fills the screen, ✕ closes. Back shrinks, then closes.
  - Save video uses the whole screen so the recording stays sharp.
- **Unchanged:** the isolated local player, its security checks and the request hand-off are the same
  ones PreviewActivity used. If the panel can't open (or the WebView is too old), the old
  separate screen opens instead.
- **Setting:** Offline downloads → Player and offline settings → “Where previews play”.

### Offline downloads (new)
- **Where:** an “Offline” button on the Animations page and in Animation Studio, plus “Download for
  offline…” in the preview storage section (Animations and Game movies).
- **Essentials:** the animation player, all 2,600+ animation scripts and every character picture.
- **My units:** artwork, effects and sound effects for the characters your saved units are based
  on, plus the shared battle scenes.
- **Everything:** artwork for every character and every animation effect. Game movies are optional.
- **How it runs:**
  - Wi-Fi only (default), with pause, resume and cancel.
  - A progress pill shows while a download runs.
  - The screen stays on during downloads.
  - Files you already have are skipped, so tapping Download again finishes or updates a set.
  - The preview storage limit is raised automatically as needed (up to 32 GB), and 400 MB of the
    phone's free space is always kept.
- **Storage format:** files go into the same preview cache the player already reads, with identical
  keys, so previews use them with no other change. Scripts go where Add clip looks for them.
- **Pictures:** character pictures on the main screen are now served from the phone when saved. Any
  picture you see is also saved in the background for next time.

### Native changes
- **classes.dex:** three small smali hooks in CreatorActivity (`patch/dock_smali.py`):
  - the preview launch → in-app player (falls back to PreviewActivity),
  - onActivityResult → forwarded for “Save video”,
  - main WebView image requests → saved pictures.
- **classes2.dex:** PreviewDock and OfflineLibrary, plus the existing ForgeFixes and ForgeAi.
- **Build:** `build3.sh`.
- **Manifest:** adds `ACCESS_NETWORK_STATE`, a normal permission granted automatically, so “Wi-Fi only”
  can tell Wi-Fi from mobile data (`patch/axml_add_permission.py`).
- **Independent review fixes:**
  - Attacking-side effect metadata is saved under every URL form the player uses.
  - A download still runs when Offline preview is on.
  - The panel resizes on rotation and when the keyboard opens.
  - Status checks never wait on the player's cache lock.
  - The storage reservation is returned when a download fails.
  - Cancelling waits for in-flight files.
  - Full screen after Save video doesn't stick.
  - The screen-on flag is cleared when downloads end.

## Round 12 — Clip editor and movie editor overhaul (v2.15.0, versionCode 59)

### New visual trim control (both editors)
- **Bar:** shows the whole scene; the part you keep is in colour.
- **Handles:** drag the green handle (Start) or the orange handle (End). Tapping the bar moves the
  nearest handle.
- **Times:** shown big at all times, with − / + buttons (0.1 s). Tap a time to type an exact
  value. Impossible times are refused with a message instead of being silently changed.
- **Marks:** small white marks show key moments. Handles snap to them when you get close.
- **Accessibility:** works with a keyboard and screen readers (each handle is a slider).

### Animations page (clip editor)
- **Clip cards:** one card per clip. Each shows its trim bar, when it plays in your animation, and
  big buttons: ▶ Play this part, ↑, ↓, ⧉ duplicate and ✕ remove.
- **Overview strip:** a coloured strip at the top shows every clip at its real length. Tap one to
  jump to it.
- **Undo / Redo:** now beside “Your clips”.
- **Adding clips:** “+ Add a clip” sits under the list.
- **Speed:**
  - Script analysis is cached, so trimming no longer re-scans every clip's script.
  - A trim change took about 107 ms in tests; it now takes about 10 ms.
  - The clip list renders about 7× faster.

### Movie editor (“Combine movie scenes”)
- **Three steps:** 1 Pick scenes, 2 Cut & arrange, 3 Make movie, with step buttons at the top.
- **Scene list:** appears instantly. Scenes from your imported game files are added when ready.
  Each scene has ▶ Watch and + Add.
- **Scene cards:** each scene gets the trim control. ▶ Play this part plays exactly the part you
  kept, looping, in the in-app player.
- **Instant movies:**
  - A scene can be joined without re-encoding when it is a VP9 movie that starts on a cut point
    (keyframe) and keeps its original picture.
  - Plain ADX sound is cut and joined in the same pass.
  - The plan box says whether your movie will be instant, and if not, why.
  - Scenes that start between cut points get “⚡ Move start to the nearest cut point”.
  - In tests, an instant movie took 0.6 s; the same kind of movie re-encoded took about 20 s on a
    desktop, and longer on a phone.
- **Re-encoding:**
  - Shows a progress bar, a percentage when available, and how long it has been working.
  - The default quality is Balanced (faster).
  - If the instant join fails, it falls back to re-encoding automatically.
- **Results:** ▶ Watch my movie, then “Add to my animation”, which adds the movie as a new clip.
- **Native:** movie previews receive the chosen part (`trim`) and loop just that part.

## Round 13 — Beginner-friendly redesign (v2.16.0, versionCode 60)

### Navigation
- **Bottom bar:** now five clear tabs: Home, Create, Animate, Library, More. It used to hold up to
  eight cramped buttons, and some screens couldn't be reached on phones.
- **More:** a sheet with everything else, grouped into Make, Files and App: Templates & presets,
  AI helpers, Game movies, Combat practice, Import a file, Offline downloads, Recover unsaved
  designs, Game data & files, Settings, Help and Welcome tour.
- **Every screen:** shows its name at the top (or the unit's name while editing), plus **?** (help
  for this screen) and **⚙** (Settings).
- **Sidebar (larger screens):** adds Templates & presets, Offline downloads, Settings and Help.

### Welcome tour (first launch; reopen from More or Help)
1. What the app does: Create, Customize, Play.
2. How much help you want: Beginner (recommended) or Advanced.
3. Comfort: text size (with a live sample) and look (Dokkan or Calm dark).
4. Start: ⚡ Make my first unit, ★ Browse templates, or Look around.

### Settings
- **Look & comfort:**
  - Style: Dokkan or Calm dark.
  - Text size: Small, Normal, Large or Extra large. This uses Android's own text zoom and is
    remembered from the next start.
  - High contrast and Reduce motion.
- **Help level:** Beginner or Advanced, Show tips, Take the tour, Open Help.
- **Animations:** where previews play, Offline preview, Offline downloads.
- **Speed:** Lite effects, and more graphics options.
- **Your data:** Saved versions of the open unit, Recover unsaved designs, Import, Library.
- **Restore defaults:** on every section, plus “Restore all defaults”. Units and files are never
  touched.

### Help center
- **Guides:** searchable, in plain language.
  - Getting started: first unit in 3 steps, templates, putting a unit in Eclipse.
  - Animations: making animations, cutting movies, instant previews.
  - Library, combat, game data, AI.
- **Dokkan words explained:** 20 terms.
- **Fix a problem:** slow app, preview not playing, lost changes, storage.
- **Per screen:** **?** opens the guide for the screen you're on.

### Templates & presets (new)
- **Seven whole-unit templates:** All-rounder, Heavy hitter, Tank, Speedster, Support, Critical
  striker and Healer.
- **Pieces:**
  - 12 Passive presets.
  - 5 Super Attack presets.
  - 4 Leader Skill presets, including “My Category +170%”.
  - 2 Active Skill presets.
- **Preview before applying:** see HP, ATK and DEF before → after and a list of exactly what will
  change. Then apply, and use ↶ Undo to take it back. The unit's name, rarity and look are kept.
- **Where to find them:** ★ Presets in the card builder toolbar, ★ Add a preset ability on the
  Passive step, a Home card, and More.

### Home and Library
- **Home:** a “New here? Start in 3 steps” card while you have fewer than three units.
- **Library:**
  - Plain names: Everything, Made by me, Imported units, Game files (.eclp), Sparking characters.
  - The very long Sparking catalogue only shows on its own tab.
  - Rarely used tools are folded into “More tools”.
  - A clear “Play your unit in Dokkan Eclipse” guide.
- **Bug fix:** unit pictures used blocked inline styles, which showed broken images before
  loading. Fixed.

### Native
- **textZoom:** new bridge action, applied to the main WebView at start-up.

### Compatibility
- **Saved data:** project format unchanged. Saved units, settings and files carry over.
- **Tests:** all existing UI and export tests pass with 0 problems and 0 overwrites.

## Round 14 — Smooth previews, Dragon Ball icon, “Dokkan Unit Creator” name (v2.17.0, versionCode 61)

### Animation previews: real-time speed and smooth playback
- **Previews no longer play in slow motion.**
  - The cause: the player treated any frame drawn later than 80 ms as a normal 33 ms frame. On a
    phone that could only draw 8–11 frames a second, the animation therefore ran at a quarter to a
    third of its real speed.
  - The fix: the player now catches up (up to 8 game frames per drawing). The animation keeps the
    game's real timing and only draws fewer in-between pictures on slow phones.
  - Measured in a timing simulation of the player loop:
    | Phone draws | Game frames per second before | Game frames per second now |
    |---|---|---|
    | 8 a second | 8.3 | 30.3 |
    | 11 a second | 11.0 | 29.5 |
- **Steady 30 fps drawing ("Smooth playback", on by default).**
  - The game logic runs at 30 frames a second, but the player redrew the whole scene on every
    screen refresh: 60, 90 or 120 times a second. Now it draws once per game frame.
  - On a 120 Hz screen this is 30 drawings a second instead of 120, which frees the phone to keep
    the timing even.
  - Recording ("Save video") still captures every frame.
  - To turn it off: Settings → Animations → Smooth playback.
- **Less work while an animation plays.**
  - The player's status line was rewritten 30–120 times a second. Each rewrite made the app re-scan
    the whole player log against 25 patterns. The status line now updates about 5 times a second,
    and the scan runs at most every 0.4 s.
  - The editor's decorative animations (glows, auras) pause while the in-app player is open.
    Loading spinners keep turning.
  - In full-screen mode the editor underneath stops drawing completely, and comes back when you
    shrink or close the player.

### New Dragon Ball app icon
- The orange “F” is replaced by a 4-star Dragon Ball with a golden ki aura and sparkles, on a
  deep-blue burst. The icon is a vector, so it stays sharp at every size.
- The sidebar logo is now a Dragon Ball in every theme, including Calm dark.

### The app is called “Dokkan Unit Creator” everywhere
- **App name** under the icon: “Dokkan Unit Creator” (was “Dokkan Unit Creation”).
- **Visible text with “Forge” is gone.** This covers:
  - error messages, for example “Update Forge”, which now asks you to update the app;
  - export credits: CPK/patch author is now “Dokkan Unit Creator”;
  - the shared-actions pack, now named “Unit Creator Shared Actions”;
  - comments in generated Lua scripts;
  - download user-agent names;
  - headings and help text.
- **Kept on purpose:** internal names that you never see but that saved units and exported
  patches rely on (the `dokkan-unit-forge` project format, internal function and file
  identifiers). Renaming them would break your existing units and patches.

### Build
- The build now stops if the native code fails to compile, so a broken build can't be packaged by
  mistake.

## Round 15 — Lag fixes and a simpler Animate screen (v2.18.0, versionCode 62)

### Previews lag less
- **Automatic quality (new default).**
  - Previews start with exact game colors. While a preview plays, the player measures how long
    each picture takes to draw.
  - If a third of the pictures in any 1.5-second stretch are late (over 26 ms of work, or more
    than 60 ms apart), it switches to **smooth mode**. In smooth mode, artwork colors and glows
    are no longer re-processed picture by picture on the graphics chip. A short note says so.
  - The phone remembers this, so later previews start in smooth mode right away.
  - Choose in **Settings → Animations → Preview quality**:
    - Automatic (recommended);
    - Smoothest: always smooth, and drawn at a lighter resolution on very sharp screens;
    - Best colors: always exact.
  - Saved videos always use exact colors.
- **Artwork stays on the graphics chip.**
  - Before, a whole artwork sheet (often 2048×2048) was copied to the graphics chip again for
    every single colored sprite in every picture.
  - Now each sheet is copied once and reused. The memory used is capped at about 64 MB, and the
    least recently used sheets are dropped first.
- **Full screen by default.** The editor underneath stops drawing while you watch.

### Player screen: simpler
- Opens **full screen**, with a big **✕ Close** button and a **Smaller** button (to see the editor
  below). The phone's Back button always closes the player.
- **Three big buttons with words:** ↺ Again, ❚❚ Pause / ▶ Play, ⋯ More.
  - More holds 2× speed, Phone frame and Player tools.
- **While loading:** a card says "Getting your animation ready…". If something goes wrong, the
  card explains what.
- **When it ends:** a big **↺ Watch again** button appears.

### Animate screen: four numbered steps
1. **Add moves:** one big ＋ Add a move button. Your moves show their start and end times, with
   the trim handles.
2. **Music.**
3. **Watch it:** a big ▶ Watch my animation button.
4. **Keep it:** Save to My animations, Use on my unit, or Save as a video file.

- Until you add your first move, steps 2–4 are greyed out and say "Add a move first".
- After that, **Watch my animation** becomes the big orange button.
- **Moved out of the way:**
  - The “Ask AI” banner and the second “Animations” heading are gone.
  - Create movement, Combine movie scenes, Switch unit, Offline downloads, the advanced editor
    and backups moved into **More tools**.
- **Move picker:**
  - Now titled “Pick a move”.
  - Each result has two big buttons, **▶ Watch** and **＋ Add**.
  - Empty “None” entries are hidden.
- **Plainer messages,** for example “Move added. Drag its handles to keep the part you want…”.

### Settings → Animations
- **How the player opens:** Full screen (recommended), Half screen, or Separate screen (the old
  player).
- **Preview quality:** Automatic, Smoothest or Best colors.
- **Restore defaults** resets both.

## Round 16 — Video-player style animation player (v2.18.1, versionCode 63)
- **Clean screen.** The animation fills the screen, with no button bars and no pop-up cards on
  top of it.
- **Tap to show the controls.** Tapping the animation shows:
  - ✕ (close) at top left;
  - ⤡/⤢ (smaller or full screen) and ⋯ at top right;
  - big ↺ (replay) and ❚❚/▶ (pause or play) in the middle;
  - a progress bar with the time, for example 0:04 / 0:10, at the bottom.

  While it plays, the controls fade after 3 seconds. Tap again to hide them sooner.
- **Jump to a moment** by tapping or dragging the progress bar.
- **⋯ menu:** 2× speed, Phone frame and Player tools, plus a one-line note on preview quality.
  It closes after you pick something.
- **When the animation ends,** the controls stay up with a big ↺ in the middle. There is no
  "Finished" box any more.
- **While loading,** only a small spinner shows. A message appears only if something goes wrong.
- **The app's own title bar is hidden.** It comes back only with Player tools and while saving
  a video, so you can always close.
- **No pop-up when smooth mode switches on.** Its status is in the ⋯ menu instead.

## Round 17 — Edit in a small window (v2.19.0, versionCode 64)
- **Choose where previews play.** The Animations screen now starts with a
  **Preview in: ▣ Small window / ⛶ Full screen** choice.
  - It applies to every preview started there: a single move, the whole animation, and scenes
    in Combine movie scenes.
  - Small window is the default for the editor.
  - The phone remembers your choice. Switching it also resizes an open player at once.
  - Settings → Animations still decides the size for previews started from other screens.
- **Small window:**
  - The player sits at the top, with ✕, ⤢ (full screen), replay, pause and the progress bar.
  - Your moves, trim handles, start and end times, ↑ ↓, music and save buttons stay usable
    underneath.
  - Drag the bar under the player to make it bigger or smaller.
- **Replay after a trim (on by default):** with the small window open, a move plays again by
  itself after you trim it, so you see the new cut straight away. Untick “Replay a move after I
  trim it” to stop this.
- **✂ Cut into two parts:**
  - A new button on every move splits it at the middle of the part you kept, giving two moves
    you can trim, reorder or remove separately.
  - Game movies are re-cut on the phone for each part.
  - Undo takes it back.
- “Play this part” is now “▶ Watch this part”.

## Round 18 — A real timeline editor (v2.20.0, versionCode 65)
The Animations screen is now a phone video editor, like CapCut.

### Layout
- **Preview always on screen.** The animation plays in the window at the top while you edit, and
  stays paused at the white line otherwise.
  - After every change (trim, split, move, delete, music, undo), the preview rebuilds itself
    paused at the same moment. This takes a few seconds while it reloads.
  - Leaving the Animations screen closes it.
- **Timeline:**
  - Your moves sit side by side as coloured blocks, sized by length, with a time ruler above
    and a music lane below.
  - It slides under a fixed **white line** (the playhead). Slide with your finger to jump to any
    moment; the preview pauses and follows.
  - While the preview plays, the timeline scrolls along with it.
  - **−/＋** zoom in and out, and the zoom is remembered.
- **Top:** the animation name, **?** help, **↶ Undo / ↷ Redo**, a big **▶/❚❚** button and the
  time (for example 0:04.2 / 0:09.8).
- **Bottom:**
  - **＋ Add move**;
  - **♪ Music**;
  - **💾 Save**: Save to My animations, Use on my unit, or Save as a video file;
  - **⋯ More**: My animations, Start a new animation, Combine movie scenes, Create movement,
    Switch unit, Offline downloads, Advanced editor, Save a backup.

### Editing a move
Tap a block to select it. A tool row appears:
- **✂ Split** cuts at the white line, into two moves.
- **⇤⇥ Trim** opens exact start and end times with handles, and **▶ Watch this move**.
- **▶ Watch** plays from that move's start.
- **← Earlier / Later →** move it; the selection follows.
- **⧉ Copy** duplicates it.
- **🗑 Delete** removes it.

You can also drag the **white handles** on a selected block's edges to trim it directly; a
bubble shows the new start or end time.

### Empty screen
One big **＋ Add your first move** button, with My animations, More tools and How it works.

### Under the hood
- The player reports its position about 4 times a second. The app relays it to the timeline,
  and the timeline sends seek, play and pause back.
- A refreshed preview opens paused at the playhead.
- The player's time label now counts in real seconds (60 game frames per second).

## Round 19 — Clearer screens everywhere (v2.21.0, versionCode 66)
Every screen was reviewed at phone size, and the confusing parts were changed.

### Everywhere
- **The “Need a hand getting started? Ask AI about this” banner is gone** from Library, Practice
  battle, Game data and the other screens. AI is in ☰ More.
- **“Back to my units” is gone** (the bottom bar already reaches every screen). When you came
  from editing a unit, it is replaced by **← Back to <your unit's name>**.
- **The old name “Animation Studio” is now “animation editor”** everywhere.

### Home
- One big **⚡ Create a unit** button inside the banner, with “1 Pick a fighter · 2 Change
  anything · 3 Play it in Eclipse”.
- **Your units** come right after the banner, so carrying on with a unit is one tap.
- **Other ways to start:**
  - Start from a template;
  - Build from a character;
  - EZA / Super EZA a card;
  - Describe it to AI.
- **Removed duplicates:** the separate “New here?” box, the second Quick Create card, and the
  “More tools” button grid. Those tools are all in the bar and ☰ More.

### Create a unit
- **Quicker ways to start** at the top: ⚡ Quick Create, ★ Use a template, ✦ Describe to AI.
- **Then “Or pick a character”,** with one short explanation instead of two intro boxes. The
  vague “Start from an idea instead” button is gone.

### Library
- **Shorter header.** The three counter boxes are gone; the tabs show the counts instead
  (Made by me (2), Imported (0), Game files (0)).
- **The tabs wrap** onto a second line instead of running off screen.
- **The Delete button on each unit is smaller and quieter** (🗑 Delete).

### Practice battle
- **Plainer wording:** it's now “Practice battle — try your unit in a quick practice fight on
  this phone. It's a rough test, not the real game.”
- **The technical rules note is folded** into “What this practice battle does and doesn't
  include”.
- **“Workshop training profile” is now “Practice opponent”.**

### Game data & files
- **A plain explanation of when you need this screen** and what Refresh and Import APK do.
- **Database details are folded away,** and the “Imported assets” chip and Expert-mode note
  are replaced by a “Files you imported” heading.

### Card builder
- **Super Attacks:** one main **＋ Add a Super Attack** (or Ultra, once a Super Attack exists)
  and **Copy an attack from the game**. Conditional, EX and Ultra are under **Other kinds of
  Super Attack** with a one-line explanation. Before, there were four orange buttons in a row.
- **Look & Animations:**
  - Each animated move now shows **▶ Watch** and **Change…** instead of 3–4 buttons.
  - Change… opens a short list in plain words: Use another character's animation, Edit it in
    the animation editor, Use one of my saved animations, Swap for a different game attack.
  - The long explanation is now one sentence.
- **EZA version picker:** now titled “Which version are you editing?”, explaining that “Before
  EZA” is what your unit starts with and most people only edit that one.
- **Save & Play:**
  - “Project checks passed / ID collisions…” is now **“✓ Your unit is ready to save — Nothing
    is missing.”**
  - “Compatibility notes” is now **“Things to double-check in the game”**.
  - Patch name, author and version are folded into an optional section that fills itself in.
  - The .sql/.zip formats are labelled “for experts”.

## Round 20 — Copy from a unit, any animation on any move, Dokkan-style passive text (v2.22.0, versionCode 67)

### ⧉ Copy from a unit (new, in the Card Builder toolbar)
1. **Choose where to copy from:** *A character from the game* (any card, including EZA versions)
   or *One of my units*.
2. **Tick what you want.** Each line shows what that unit actually has:
   - HP, ATK & DEF;
   - Rarity, Type & Class;
   - Leader Skill;
   - Passive Skill (**Add to my passive** or **Replace my passive**);
   - Transformation only;
   - Super Attacks & Ultra Super Attacks (**Replace mine** or **Add to mine**);
   - Active Skill;
   - Standby & Finish Skills;
   - Link Skills;
   - Categories;
   - Card artwork;
   - Aura;
   - **Animations only**: their Super Attack, Active Skill and normal attack animations on
     *your* moves, which keep their own damage and effects.

   Things the unit doesn't have are greyed out. **Pick the whole kit** ticks the gameplay set
   in one tap.
3. **See the changes:** every change is shown as before → after. Nothing changes until **Apply
   to my unit**, and **↶ Undo** takes the whole copy back in one step.

**Dependencies are handled for you**
- Abilities keep their activation conditions, targets, EX options, Ultimate Super Attacks and
  animations.
- Custom conditions from your own units are copied with them, and their condition formulas are
  re-pointed to the copies.
- Transformations copied from one of your own units that point at that unit's private forms are
  pointed at the original game forms instead (with a note).

**Checked:** full kits copied from 3 different game cards (Super Saiyan Goku, Majin Buu (Ultimate
Gohan), and the LR Super Saiyan Vegeta (Angel) + Super Saiyan Goku (Angel) fusion), a copy from
one of my own units, and a unit with its own forms. All passed the app's checks; the exported
SQL applied with 0 problems, overwrote nothing, and Undo restored the unit.

### Use any animation for any move
- On Look & Animations, **Change… → Use another character's animation** opens the animation
  library **for that move**. A banner names the move, and each result has **▶ Watch** and
  **✓ Use**.
- **The "Use" step now says in plain words whether the animation fits the move you pick:**
  - **✓ Plays exactly like in the game:** a direct reference to the game's animation.
  - **✓ The whole original animation is copied onto this move.**
  - **Works after a small conversion:** for example, it is turned into a counter or entrance
    sequence and may look slightly different.
  - **✕ Can't be used:** for example training/awakening scenes, or Dodge (which is made in the
    animation editor). The button is disabled.
- After **Use**, you're taken straight back to your unit's animations.
- **Every move keeps its own damage and effects;** only the visuals change.

### Passive descriptions in Dokkan Battle style
- **Same layout as the game:** "Basic effect(s)", then one heading per moment and condition.
- **ATK and DEF boosts with identical settings are merged:** ATK +100%, DEF +100%, ATK +50%
  and DEF +50% (all at the start of the turn) become **"ATK & DEF +150%"**. Different values
  become "ATK +X% and DEF +Y%".
- **Ki is written in front of the stat boost it shares every setting with:** "Ki +3 and ATK &
  DEF +150%", as on official cards. Team and enemy effects work the same way, for example
  "All allies' Ki +2 and ATK & DEF +20%" and "All enemies' ATK & DEF −20%".
- **Never combined:** different moments ("start of turn" vs "when attacking", which are
  separate calculation phases in battle), different conditions, targets, durations, chances,
  once-only effects, flat vs percentage vs lowering, and growth ("with each attack"). Each of
  these keeps its own line.
- **Fixed an older risk:** the moment an ability triggers is now part of the merge check, so
  two abilities under the same condition heading but at different moments are no longer added
  together.
- **Line order like official cards:** Ki and stats, then defence, critical hits/dodges,
  additional attacks and the rest; your own effects before team and enemy effects.
- **Which descriptions update:**
  - Descriptions the app writes for you update automatically whenever abilities change,
    including on units you already made the next time you open them.
  - Passives copied from game cards keep the game's own official wording.

## Round 21 — Combine every version of a character, organized and kept within the meta (v2.23.0, versionCode 68)

### New buttons on the Passive Skill step
- **⧉ Copy every version of a character:** pick a character and the app lists every playable
  version that has a different passive (all ticked; untick any you don't want). By default the
  EZA wording is used when a card has one. All of them are added to your passive in one go.
- **🧹 Organize & balance:** tidies a passive you already filled with copies.
- Both show the result first: what was combined, what was lowered, and the new in-game
  description. Nothing changes until you tap **Apply to my unit**, and ↶ Undo takes it all
  back in one step.
- **Add to my passive** (the passive copy and Copy from a unit) now organizes automatically too.

### What "organize" does
- **Exact copies become one** (same effect, moment, condition, target and settings).
- **Matching boosts are added together** only when the game calculates them the same way:
  same moment, same condition, same target, same duration and chance. For example three
  "ATK & DEF +100% at the start of the turn" become one "ATK & DEF +300%".
- **Defensive and special flags** (guard, damage-type immunity, foresee Super Attack, effective
  against all types…) that repeat under one condition keep only the strongest chance.
- **Weaker chances are dropped from the description** when the same effect is already guaranteed
  under that heading.
- **At most 2 additional attacks** at the same moment.
- **The description is rebuilt in game style:** headings with the same wording are merged,
  "Basic effect(s)" comes first, and the stat line reads like official cards
  ("Ki +7, ATK & DEF 300%↑ and ATK 7000↑").

### Kept within today's meta
- **For one moment:** ATK/DEF about +300%, Ki +7, damage reduction 60%, evade 60%, critical
  hit 70%, flat ATK/DEF 10000, 2 additional attacks.
- **For the whole passive, with every condition met at once:** self ATK and DEF about 1000% and
  Ki about 12. If a combined passive is over that, the conditional boosts are lowered evenly
  ("Basic effect(s)" are left alone). The game also caps Ki on its own (12, or 24 for LRs).
- The summary lists every value that was lowered, from → to.

### Checked
- Combining all 66 Super Saiyan Goku versions onto a unit: 232 → 223 abilities, description
  170 → 147 lines, no meta warnings left, a second "Organize & balance" changes nothing,
  export SQL applies with 0 problems, ↶ Undo restores the original passive.
- Regression runs: Copy from a unit, passive copy, passive text sync, Card Builder flow, shell.

## Round 22 — "Every version" now means every fully awakened card with that name (v2.23.1, versionCode 69)
- The button is now **⧉ Copy every fully awakened version**. Pick the character (any version of
  them) and the list shows every **fully awakened** card with **exactly the same name**.
- **Fully awakened** = the top of each awakening line: a card that doesn't Dokkan Awaken into
  another card. Cards that still awaken further (for example the TURs that become an LR, or a
  UR that becomes a TUR) are left out, as are the game's hidden helper cards.
- Cards that have an Extreme Z-Awakening are marked **EZA** in the list; with "Use the EZA
  version" on, their EZA passive is the one copied.
- Checked with Vegito: 5 cards listed (LR "Die!", the EZA TURs "Whole Other Level", "Know No
  Bounds", "Potara of Hope", and the SSR "Enter the Savior"), the earlier 13 included
  pre-awakened copies. Combined result: no meta warnings, export SQL 0 problems, Undo works.

## Round 23 — Copy all, or choose; mix several characters (v2.23.2, versionCode 70)
- The Passive step button is now **⧉ Copy passives from characters**. It builds a list:
  - Pick a character → all their fully awakened cards (same name) go in the list.
  - **＋ Add another character** adds more characters to the same list (Vegito + Super Gogeta,
    for example). **✕ Remove** takes a character out. "← Back to my list" in the character
    search returns without adding anything.
  - **Copy all passives** (default): every card in the list, one tap.
  - **Choose which cards**: a checklist grouped by character, with Tick all / Untick all per
    character. The button shows how many passives will be combined.
- Everything is then combined, organized and kept within the meta as before, with the result
  shown before applying. "← Back to my list" on the result screen lets you change your picks.
- The single-character **Copy a character's passive** button is still there.
- The duplicate "Close" button under these dialogs is gone.
- Checked: Vegito (5) + Super Gogeta (5), all mode: 10 combined, 90 → 87 abilities, no meta
  warnings, SQL 0 problems, Undo works. Choose mode: 4 of 10 picked and combined correctly.

## Round 24 — Error sweep (v2.23.3, versionCode 71)
An independent code review plus the full test sweep found these problems in the new passive
tools. All are fixed:
1. **Lowering effects read as boosts.** "DEF 50%↓" could be merged with "ATK 100%↑" into
   "ATK 100% and DEF 50%↑". Lines with a ↓ (or "lowers"/"reduces"/a minus sign) are now never
   combined with boosts, and a ↑ line and a ↓ line are never added together.
2. **Combining or capping changed when an effect happens.** Changing an amount went through the
   builder's form, which reset values it has no option for: timing 3 became "start of turn",
   "for 7 turns" became "this turn", and the sub-target, chance and extra data were reset too.
   Now only the amount (and the effect, e.g. ATK → ATK & DEF) changes.
3. **Unused passives piled up.** Adding a passive also brought every other passive of that card
   (all its EZA steps) along as unused rows; combining a whole character could leave 20+ unused
   passive sets and, with several characters, hit the game's 99-set limit and fail export. Only
   the chosen passive is copied now (also for "Add to my passive" and Copy from a unit).
4. **The buttons always edited the "before EZA" passive.** They now edit the version open in
   the Card Builder (e.g. "EZA step 7"), and on EZA projects they refuse the original passive
   with a clear message instead of silently changing something that never exports.
5. **An empty passive showed "0 abilities → 0".** Combining into a passive with no abilities now
   works normally; Organize & balance on an empty passive just says there's nothing to do.
6. **Different Ki Sphere colour changes were deleted.** "AGL → Rainbow" and "TEQ → Rainbow" at the
   same moment were treated as copies; now only true copies are merged.
7. **Description lowering didn't match the abilities.** "For every Ki Sphere obtained" and
   "per ally" lines are no longer lowered in the text (the abilities aren't either), and a
   value is never raised by the lowering.
8. **"This turn" and "rest of the battle" were merged for conditional or once-only boosts.**
   That's only the same thing for plain always-on boosts, which is now the only case merged.
9. If none of the chosen cards can be read, nothing is offered to apply.

Checked: a new test for each fix (porg_fixes.py), the combine/organize tests, Copy from a unit,
passive copy/sync/classic, Card Builder, EZA flow, transformation forms, Super Attack copy, smoke
and integrity tests — all pass, exports apply with 0 problems.

## Round 25 — Bug sweep: animation editor, player, Copy From Unit (v2.23.4, versionCode 72)
Two independent code reviews plus the full test set. Fixed:

### Animation editor and player
1. **Another preview took over the editor.** Tapping ▶ Watch in the move picker (or Save video)
   played in the editor's window, and the timeline then followed that other animation; Play and
   sliding afterwards controlled the wrong thing. The timeline now only follows its own preview,
   and ▶ reopens your sequence.
2. **Taps were lost while the preview was opening.** Play / Watch move right after an edit did
   nothing (the button showed ❚❚) and the white line jumped back. They now wait and run as soon
   as the preview is ready.
3. **A crashed player left the editor stuck** (spinner forever, Play did nothing). The app is now
   told when the player stops or can't open, and the next ▶ opens it again.
4. **With "separate window" on (or an old WebView), every edit opened a full-screen preview.**
   Edits now only refresh a preview window that is already open, never the full-screen one,
   and a window you closed with ✕ stays closed.
5. **Leaving the screen when saving failed** removed the editor layout and closed the preview
   even though you stayed on the screen. It now only happens after you really leave.
6. **A cancelled or failed Split could leave a video move cut short.** The move now goes back
   exactly as it was.
7. **"Try again" on the player lost the start position** (and a movie's chosen part). Kept now.
8. **"Choose an animation for move X" stayed on** after closing the picker with ×. Closing it
   now ends that mode.

### Copy From Unit
9. **Artwork links stayed behind after copying "Card artwork"** — the preview kept the old custom
   art and the export pointed at files that were gone. Removed fields are now really removed,
   and the preview refreshes.
10. **Copying art from one of your units with imported art** pointed at that unit's private
    files. It now uses that character's original game picture.
11. **Clearing one custom animation could delete another** (an intro and a Super/Active animation
    with the same private number). Each is now looked up in its own place.
12. **Custom animations from your other unit were copied as broken links** (Active, Standby,
    Finish, intro, counter and normal attacks could play the wrong animation or nothing). Those
    moves now use the game's original animation; a note says so.
13. **Replacing Super Attacks could leave them pointing at a deleted custom animation** or at
    nothing. They now fall back to a game animation.
14. **A unit that failed to load caused a second, hidden error**, and "Your unit changed" was
    never shown. Both now show a clear message.

### Home
15. **Quick Create showed "… is ready!" after it failed.** Only shown on success now.

Checked: new tests for every fix (tl_fixes.py, ucopy_fixes.py), plus timeline, player commands,
player page, clips, picker, studio, movies, Copy from a unit (game cards, my units, forms),
Super copy, passive tools, Card Builder, EZA, shell, smoke and integrity — all pass, exports apply
with 0 problems. Old test scripts for the pre-redesign guided editor were retired (that editor
was replaced by the Card Builder).

## Round 26 — Passive descriptions written like Dokkan Battle, clearer "Copy passives" (v2.24.0, versionCode 73)

### Descriptions use the game's own wording and icons
The description the app writes for you now follows the official cards (checked against thousands
of descriptions in the game data):
- **Icons:** green ↑ `{passiveImg:up_g}` for boosts, yellow ↓ `{passiveImg:down_y}` for lowering
  enemies, red ↓ `{passiveImg:down_r}`, `{passiveImg:once}` for once only and
  `{passiveImg:forever}` for effects that last the rest of the battle.
- **Wording:** "Ki +3 and ATK & DEF 200%↑", "Damage reduction rate 40%↑", "Chance of performing a
  critical hit 50%↑", "Evades enemy's attack", "Receives an additional Ki +1 per Rainbow Ki Sphere
  obtained", "ATK & DEF 15%↑ per Ki Sphere obtained", "Changes Ki Spheres: AGL to Rainbow",
  "All allies' Ki +2 and ATK & DEF 30%↑", "All enemies' ATK & DEF 20%↓ for 2 turns".
- **Chances in words**, like the game: rare / medium / high / great ("Launches an additional attack
  that has a high chance of becoming a Super Attack", "High chance of stunning the attacked enemy").
- **Growth** gets its own heading: "*For every attack performed*" with "∞ DEF 20%↑ (up to 200%)".
- **"How it looks in the game"** preview under the description box draws the icons, so you see
  exactly what the card shows. The card preview shows the icons too.
- Units whose description is written automatically update to the new wording on their own.

### "Copy passives" says exactly what it copies
- A box at the top explains it: for every **fully awakened** card with the same name, the app copies
  its **strongest passive** — **Super EZA** if it has one, otherwise **EZA**, otherwise the fully
  awakened passive. Weaker versions (before awakening or before EZA) are never copied.
- The cards are always listed, each marked **Super EZA passive**, **EZA passive** or **Fully
  awakened passive**.
- The two choices are now **Copy every card listed** and **Pick cards myself**.
- The "Use the EZA version" switch is gone: the strongest version is always used.

## Round 27 — "Copy passives" rebuilt from scratch (v2.24.1, versionCode 74)
The old window showed every version of every card (the general card search) and could list the
same passive twice. It's now three simple steps:
1. **Type a name** — e.g. "Vegito". Each name appears **once** ("Vegito", "Super Vegito",
   "Super Saiyan God SS Vegito"…), no card versions at all.
2. **One screen, one button** — "**5** passives from Vegito" and a big **Copy all 5 passives into
   mine** button. Only the strongest version of each fully awakened card is used (Super EZA › EZA
   › fully awakened); weaker versions are never shown.
   - The same passive is never listed twice (same passive, or the same card released again).
   - **＋ Add a character** adds another name as a chip; ✕ on a chip removes it.
   - **Choose which passives** (folded away) lists them, each marked Super EZA / EZA / Fully
     awakened, to untick any you don't want. The big number and button follow your choice.
3. **The result** before anything changes, as before.

## Round 28 — Combine leader skills like passives, random skill names (v2.25.0, versionCode 75)

### ⧉ Combine leader skills from characters (Leader Skill step)
Same three steps as Copy passives: type a name → one screen with one button → the result.
- Uses the strongest leader skill of every fully awakened card with that name (EZA/Super EZA
  when it has one), listed once each (same wording = same leader).
- Becomes **one modern leader skill**: all Category bonuses join into one "A, B or C Category"
  bonus at the strongest value, and "characters who also belong to …" bonuses join into one
  extra bonus.
- **Kept within today's top meta** (checked against 2026 cards): one Category: up to Ki +4 and
  +220%; several: Ki +3 and +220%; with the extra bonus: HP up to 250% and ATK & DEF up to 220%
  in total for any one ally. Up to 4 Categories (and 6 "also" Categories), like official cards.
- Old Type / Class / All Types bonuses are used only when no leader has Category bonuses.
  Leader effects with conditions can't be combined and are listed as left out.
- The description is written in official style, e.g. '"Wicked Bloodline", "Planet Namek Saga" or
  "Sworn Enemies" Category Ki +3, HP +200% and ATK & DEF +170%, plus an additional HP, ATK & DEF
  +50% for characters who also belong to the "Transformation Boost" … Category'.
- The result gets a fresh random name (🎲 to roll another) and stays editable on the Leader step.

### 🎲 Random skill names
- A 🎲 button next to every skill-name box (Leader, Passive, Active Skill).
- **🎲 New skill names** in the Card Builder toolbar renames the Leader, Passive, Active, Standby
  and Finish Skills at once (every EZA stage too). ↶ Undo takes it back.
- Combined passives also get a fresh name, with 🎲 on the result screen.

### Also
- Leader descriptions written by the app use the official "plus an additional … for characters
  who also belong to …" wording.
- Test tool fix: the test copy of the game database now pages like the app (5000 rows).

## Round 29 — The big overhaul (v2.26.0, versionCode 76)

### ✪ New Card Builder step: Special Skills
One place for every special mechanic, each with plain explanations and ↶ Undo:
- **Counters** — ＋ Add a counter: what it counters (normal attacks, Super Attacks, Ki-blast or
  unarmed Super Attacks, any attack), counter damage (Enormous ×2, Tremendous ×3, Ferocious ×4),
  damage blocked, chance, and the animation (any game counter, or your own). Also "Evade and
  counter". Counters are now editable on the Passive step too, and written in official wording
  ("Damage reduction rate 70%↑ temporarily and counters with tremendous power").
- **Revival** — HP recovered, who revives (the character or an ally), revival scene.
- **Intro (entrance scene)** — pick any of the 127 game entrance scenes by character, or make
  your own with 🎬.
- **Domain** — pick one of the game's Domains (name, effect and turns shown), appearing with
  your Active Skill or by itself from a chosen turn. **Customize** makes it your own: name, text,
  turns, numbers and background.
- **Standby & Finish Skill** — copy one from any character that has one, rename it (🎲), change
  its texts and how long it stands by; remove it cleanly (its transformation too).
- Shortcuts to Active Skills, EX / Ultra / Conditional Super Attacks and Transformations.

### Super Attacks
- **EX Super Attacks: choose when they can happen** — when the 1st attack is a Super Attack, as an
  additional Super Attack, or when the 1st Super Attack is a critical hit. The game's priority
  (20 / 30 / 40) and the in-game trigger text are set for you (fixes a wrong priority before).

### 🎨 Card artwork (Look & Animations)
- One big **Change card artwork** button: use any character's artwork, **create new art with AI**,
  or use your own picture.
- AI art is requested with the official Dokkan card-art rules (Toei anime style, cel shading,
  vertical portrait, head in the upper third, body to the knees, no text/frame); see or copy the
  exact instructions.
- Your picture is fitted automatically into the card art, round portrait, cut-ins and thumbnail at
  their exact sizes. **LR:** it goes into the character layer of the card's animated artwork, so
  it moves with the game's LR animation, aura and effects.

### 🎵 Your own music
- Animate → 🎵 Music → **Upload my own song** (MP3, M4A, WAV, OGG, AAC, FLAC from your phone or
  computer).

### Import, updates, downloads and your data
- **More → Import & update**: units (.json, Eclipse .eclp, Sparking .sprk, .zip), **check for new
  Eclipse data**, download the newest data, import the Eclipse app (APK), download artwork &
  animations, import resource packs, open the Eclipse website.
- **Settings → Your data**: download game files, AI tools, and **🗑 Delete my data** (your units,
  your files incl. My animations, downloads, AI connections, settings — you choose).

### Names instead of numbers
- "Custom ID 97000001" is gone from Home, the Library, the unit preview and the unit pickers;
  you see the character it's based on, its rarity and type instead. Counter animations are named
  after characters.

### Also
- Help: new guides for Special Skills, card artwork, your own songs, Import & update, deleting data.
- Fixes from two code reviews (12 issues), all covered by new tests: special_ui, special_crawl,
  art_studio_ui, data_ui.

## Round 30 — "Update & import" made simple (v2.26.1, versionCode 77)
- The screen is now two cards:
  - **🎮 Game data** — checks Dokkan Eclipse by itself when you open it and says, in one line,
    whether new characters are available. One big **Update now** button. When an update fails, the
    reason is shown right there with **Try again**, **Update from an Eclipse app file instead** and
    **Copy the error** (so it can be sent and fixed). Your current characters are always kept.
  - **📥 Import a unit** — one "Choose a file" button for .json, .eclp and .sprk units.
- Everything else (offline downloads, resource packs, the Eclipse app file, the website) is folded
  under **More options**.
- After an update the screen shows the new data date instead of the old built-in one.

## Round 31 — Character finder + one-tap game data in Settings (v2.26.2, versionCode 78)
- **🔎 New character finder** on Create and in every "pick a character" window (Copy from a unit,
  copy kits, activation rules, transformations…):
  - Type part of a name — every word counts ("ss4 gogeta" style searches work).
  - One-tap chips: **Rarity** (LR, UR/TUR, SSR, SR & lower), **Type** (AGL/TEQ/INT/STR/PHY in their
    colours), **Class** (Super/Extreme).
  - **More filters**: **Category** (pick from the list, e.g. Fusion, Pure Saiyans), **Extreme
    Z-Awakening** (has EZA, has Super EZA, no EZA yet), **Sort** (newest first, oldest, name, rarity,
    highest ATK, highest HP) and "Also show earlier versions".
  - Each character is shown once, as its fully awakened version, newest first. Exact name matches
    come first. Results update as you tap; "Clear filters" resets everything.
  - The whole list is searched at once (no more Next/Previous pages).
- **Settings → 🎮 Game data** is now the first section: the date of your characters, an automatic
  check with Dokkan Eclipse, and one big **⬇ Update now** button. After updating you land back in
  Settings with "✓ You have the newest characters". If it fails, the reason is shown with Try again
  / Copy the error.
- The finder has a "Can't find a brand-new character? Get the newest game data" link, and its list
  refreshes itself after an update.
- Tested (finder_ui test) (name, rarity, type, class, category, EZA, sort, clear, create from a tile,
  pick window, Settings update success and failure).

## Round 32 — Smoother Animate player, voices in sync, easier cutting (v2.27.0, versionCode 79)
### Sound and picture stay together
- The animation player now keeps **real time**: when the phone stutters (loading artwork, a busy
  moment), the picture catches up over the next few frames instead of falling behind for good.
  Before, every hitch pushed the picture further behind the sound — after a few hitches voices,
  music and movie sound were up to 2 seconds off. Simulated on a slow phone with hitches:
  before ≈1–2 s behind, now under 0.2 s at worst and back in sync right after.
- Frames now come out at an even pace (before, a 60/120 Hz screen made the player alternate
  between skipping and doubling frames — visible stutter).
- Movie scenes (like fusion scenes) no longer restart their sound every time the picture lags a
  little; the sound is only re-synced when it is clearly off.
### The timeline feels faster
- The white line glides with the picture instead of jumping 4 times a second.
- After an edit the preview waits until you've finished (and never reloads while the Trim window is
  open), so the phone isn't busy reloading while you're still cutting.
### Much easier cutting
- New **⇤ Start here** and **End here ⇥** buttons: put the white line where the move should begin
  (or end) and tap once. No dragging tiny handles.
- **Fit** button (and automatic fit when an animation is far wider than the screen) shows the whole
  animation. **Pinch with two fingers** to zoom. **Tap the time ruler** to jump the white line there.
- Bigger, easier-to-grab trim handles. All 9 tools are visible in two rows (nothing hidden).
- Help → "Make an animation" explains the new buttons.
- Checked by an independent code review (7 findings, all fixed) and new tests: tl_easy, plus
  timing simulations of the player clock.

## Round 33 — Smoother app (v2.27.1, versionCode 80)
Measured on a simulated phone-speed CPU (4× slower than a desktop):
- **Create screen, first open: about 9 seconds → under 0.5 seconds.** The character list used to
  download every column of every card (about 20 MB passed from the game data into the app); the app
  now asks only for the 12 details it needs (about 0.25 MB). It's also used again right after an
  update. Same list, same results (checked side by side).
- **Copy passives / leader skills name search** uses that same small list instead of fetching up to
  2,000 full cards on every keystroke.
- **Automatic Lite effects:** until you choose yourself, the app notices when scrolling and tapping
  stutter on your phone and switches Lite effects on by itself (once, with a message). Change it
  any time in Settings → Speed.
- **Long lists** (characters, units, animations) only draw the tiles you can see.
- **Animation player:** decides on fast colors after 1 second of lag instead of 1.5 seconds.
- Everything else (opening units, switching builder steps, typing, Settings, Animate) was measured
  and already stays well under a frame budget on a real phone; no background work runs while idle.

## Round 34 — Fewer, clearer options (v2.27.2, versionCode 81)
Every screen was listed button by button; duplicates, leftovers and technical extras were removed.
Nothing you need is gone — each removed button was a second copy of something that stays.
- **More menu** (12 → 8): removed "Game data & files" (same as Update & import), "Recover unsaved
  designs" and "Welcome tour" (both stay in Settings).
- **Settings**: one "Restore all defaults" instead of six restore buttons; removed "Open Help" (the ?
  is on every screen), the second "Offline downloads" button, the "Library" link (it's in the bottom
  bar). "Update & import" is now "Import a unit file" (updating is the Game data section at the top).
  "More speed options" is now "Screen flickers or stays blank?" so it's clear when you need it.
- **Pop-ups** no longer each get their own "✦ Help me with this" AI button (the AI helper stays in
  the card builder and under More).
- **Card builder toolbar**: "🎲 New skill names" moved into ⋯ More; removed "My units" (bottom bar has
  Home). "Classic editor" only shows with Help level → Advanced.
- **Update & import**: removed the repeated offline download button (it's More → Download game files).
- **Library**: removed the rarity filter (search covers it).
- **Animate → More**: removed the repeated offline downloads; the old "Advanced editor" only shows
  with Help level → Advanced.
- **Game movies**: shows only movies that can actually play; removed the technical filters (video
  format, missing files), the storage/tools panel (now in Download game files) and "Check imported
  movies" (it checks by itself).

## Round 35 — Animate rebuilt with sliders (v2.28.0, versionCode 82)
The timeline (scrolling track, white line, nine tools) is gone. Now:
- **One card per move with a two-handle slider** across the whole move. Drag the **green** handle
  to where the move should start and the **orange** handle to where it should end. While you
  drag, the preview at the top shows the move at **exactly the frame under your handle**, so you
  pick the precise moment by watching it. Tap anywhere on the bar and the nearest handle jumps
  there; **‹ ›** move a handle by 0.1 s; each card shows how much it keeps.
- **▶ on a move** plays just the part you kept and stops at your end handle.
- **One slider for the whole animation** at the top, with the big ▶: drag to watch any moment.
- **⋯ on a move**: play it earlier/later, make a copy (to use another part of the same move too —
  this replaces Split), keep the whole move again, remove it.
- Bottom row: ＋ Add move · 🎵 Music · 💾 Save · ⋯ More. Help → "Make an animation" rewritten.
- New test: sl_ui (drag, frame-exact preview, tap-to-jump, nudges, keyboard, play part and stop,
  whole slider, copy/earlier/later/whole/remove). Old timeline tests retired.

## Round 36 — Videos open fast, downloads include movies (v2.28.1, versionCode 83)
Why videos still felt like they were downloading:
1. Game movies (fusion scenes, cut-scenes) have to be **converted on the phone** into a video it can
   play. That work was thrown away when the preview closed, so the same movie was converted again
   every time — even when its file was downloaded.
2. **Downloads didn't include movies** unless you picked "Everything" + "Also download game movies"
   (several GB). "Essentials" and "My units" never saved the movies your animations use.
3. The **Download button could look dead**: with many saved units it spent a long time silently
   "finding the characters in your units" before anything happened, and a download waiting for
   Wi-Fi only showed Pause/Cancel.

Fixed:
- **Prepared movies are kept on the phone** (up to 3 GB, oldest removed first). The first time a
  movie plays it's prepared once; after that it opens straight away. Only the final, checked video
  is kept. "Delete my data → downloads" also clears them.
- **"My units & animations"** (now ticked by default with Essentials) also saves the game movies,
  moves, artwork and sounds used by **every animation you made** — your units' animations and My
  animations — plus movies started by the animation scripts (setupMovie).
- **Download button**: shows "Starting…" and a live "Finding … 3 of 24" count right away; looks up
  six units at a time and each character once (much faster with many units); if it can't start, the
  reason is shown in the dialog with **Try again**; a download waiting for Wi-Fi gets a **Use mobile
  data now** button.

## Round 37 — "Play and tap" animation editor, downloads that actually save (v2.29.0, versionCode 84)
Built for joining parts of several moves, marking each part by watching it (your choice).
- **No sliders, no timeline.** Your animation is a list of **parts, in order**. Each card says what it
  keeps ("0:02.9 → 0:09.0 · 6.1 s" or "The whole move") with two big buttons: **✂ Choose the part**
  and **▶ Watch**. ⋯ = play earlier / later, use another part of the same move, keep the whole
  move, remove.
- **＋ Add a part** → pick a move → **Choose the part to keep** opens by itself, with the move in the
  preview: **▶ Play**, then tap **Start here** (green) when it reaches the moment you want — it
  pauses on that exact picture — **▶ Play** again and tap **End here** (orange). **◀ 0.1 s / 0.1 s ▶**
  fine-tune, **⏮ From the start**, **▶ Watch my part** (stops at your end), **✓ Done**. A small bar
  shows the part you keep and where you are. Closing without Done changes nothing.
- **▶ Play my animation** plays all parts together.
- Less lag: the player now does one seek at a time and skips stale ones (fast taps used to start
  many overlapping seeks).
- **Downloads**: Eclipse often answers with a redirect, which the downloader treated as a failure —
  so most files never saved. It now follows Eclipse's redirects and sends the same request as the
  app's other downloads. If files still can't be saved, the window says so plainly ("Nothing could
  be downloaded. Reason: …" / "N files couldn't be saved") with **Copy the details** — instead of
  claiming everything finished.
- Tests: parts_ui (new), tl_fixes, offline_ui, data_ui, dock_cmd. Slider tests retired.

## Round 38 — Clean download result (v2.29.1, versionCode 85)
- Your report showed downloads now work: one file out of thousands failed — sp0111.lua, which
  Eclipse serves in a form the editor can't read either. Such scripts now count as "not on Eclipse"
  instead of a failed download, so the window finishes with "Finished" and nothing to retry.

## Round 39 — Animate lag on very sharp screens (Pixel 10) (v2.29.2, versionCode 86)
Profiling showed the editor itself uses about 5% of the processor while an animation plays; the lag
came from the animation player drawing at the screen's full sharpness. A Pixel 10 has about 3
pixels per point, so the player drew up to 9× the pixels it needed, plus the exact-color pass on
every one of them.
- Unless Settings → Animations → Preview quality is "Best colors", the player now draws at most
  1.25× in the small editing panel (about 6× fewer pixels on a Pixel 10), 2× full screen, 1.5× in
  smooth mode.
- Automatic quality uses fast colors in the small editing panel and switches back to exact game
  colors when you go full screen.
- Checked in a 3× test screen: small panel 1.25× + fast colors, full screen 2× + exact colors,
  Smoothest 1.5×, Best colors 3×.

## Round 40 — Optimized for every Pixel and Samsung phone from 2020 on (v2.30.0, versionCode 87)
Checked: Android 10–16, Android System WebView versions, screen widths from the Galaxy Z Fold
cover screen to the unfolded Fold / Pixel Fold, large system text, very sharp screens, and
lower-memory phones (Galaxy A series, Pixel "a" models).
- **Android versions**: the app supports Android 8 and newer (every 2020+ phone); edge-to-edge on
  Android 15/16 is handled, and all of the app's own code was checked for Android-version-only
  calls (none found).
- **Old Android System WebView**: the app's screens need WebView 111+ (shipped with every 2020+
  phone through Play Store updates). If a phone has an older one, the app now says so once, with an
  **Update in Play Store** button, instead of looking broken. A missing feature older WebViews
  lack (Array .at) is now filled in.
- **Galaxy Z Fold / Pixel Fold**: folding or unfolding (or resizing in split screen) no longer
  restarts the app.
- **Screen sizes**: every main screen and window checked at 280, 320, 360, 384, 412, 600 and 884 dp.
  Fixed: the card builder's ⋯ More menu ran off the left edge on most phones; Special Skills cards
  were wider than very narrow screens; the Animate play button and time squeezed on narrow screens.
- **Large system text** (Samsung "Huge", Android accessibility sizes): the app follows the phone's
  text size but keeps it at most 140% so screens stay usable (your own Settings text size still
  goes up to Extra large).
- **Lower-memory phones (4 GB or less)**: Lite effects from the start (until you choose in Settings),
  the small animation panel draws at 1×, and 2 GB phones use fast colors. Faster phones keep full
  effects and exact colors; the app still switches to lighter settings by itself if a phone lags.
- **Very sharp screens** (Pixel Pro models, Galaxy S Ultra): lighter drawing from v2.29.2 applies.
- Also: the "move added" message now matches the new Choose-the-part editor.

## Web version (iPhone) — first release
- New: the app runs in Safari/iPhone as a Home Screen web app (GitHub Pages). Find characters, build, save, export .eclp (same format, verified with the Android decoder), .json backup/import, AI helper copy & paste mode, works offline.
- Not on the web yet: animations, previews, game-file downloads, opening Android-made .eclp files.
- Shared code: sidebar shortcuts now carry a data-side-go attribute (no visible change on Android).

## Round 41 — Android update + iPhone app project (v2.30.1, versionCode 88)
- **Android**: a maintenance build so phones stay in step with the web/iPhone version. Shared code
  change only (sidebar shortcuts carry a data-side-go attribute); nothing looks different. Same
  signing key, so it installs over v2.30.0 and keeps all your units.
- **iPhone app (.ipa) — ready to build**: a real iPhone app that works fully offline. The whole app
  and the game data are inside it, units are saved on the phone, and **Save file** opens the
  iPhone's own Save / Share sheet (Files, AirDrop) and saves the **.eclp directly** (no zip).
  Web links open in Safari. It builds on GitHub's Mac computers (the repo has the build set up);
  installing uses Sideloadly with a free Apple ID (re-sign every 7 days).
  Files: `ios/` (Swift app, project.yml, build workflow), `web/build.py` (new `site-ios` build),
  `web/src/web-native.js` (native Save sheet), `web/src/sw.js` (web version now saves all game data
  for offline on the first visit, so a brand-new unit can be made offline too), `web/src/web-ui.js` (no home-screen tip or offline
  worker inside the app), `web/test_ios.py` (new test).

## iPhone app — first build (UnitCreator-2.30.1.ipa)
- **New: a real iPhone app (.ipa).** Built right here (no Mac needed) in Objective-C with Apple's
  public iPhone SDK. It works fully offline: the whole app and all game data are inside it, and your
  units are saved on the phone. **Save file** opens the iPhone's Save / Share sheet and saves the
  .eclp directly. Web links open in Safari. Works on iOS 16.4 and newer, iPhone and iPad/unfolded.
- Install with Sideloadly on your PC and a free Apple ID (re-sign every 7 days; units are kept).
- Same as the web version: no animations/previews yet, and Android-made .eclp files can't be opened yet.
- Files: `ios-objc/main.m` (the app), `ios-objc/build-ipa.sh` (build: `./ios-objc/build-ipa.sh`).
  The Swift/Xcode version in `ios/` stays as a backup for building on GitHub later.

## iPhone app — full version (UnitCreator-2.30.1.ipa, second build)
The iPhone app is now the Android app: same screens, same features, same answers and messages.
- **Animations**: the real Eclipse player runs inside the app, docked or full screen, exactly like
  Android (a private local server, the same player patches, the same hand-off). Moves, game movies
  (converted in the app) and visual packs all play. Play / pause / seek / resize / close, the startup
  screen and error notes, "Save video" frames and saving.
- **Game data**: the real game databases ship inside the app and are queried with the phone's own
  SQLite (same SQL as Android). One-tap newest database, undo (restore previous), integrity checks.
- **Units** are saved as files like on Android; **saved versions** (save, list, restore) work.
- **Import**: unit backups, .eclp from either app (a new zstd decoder opens Android-made files),
  game databases, ZIPs, patch ZIPs, game-file archives (CPK unpacking), the Eclipse APK, single
  pictures and game files. **Export**: .eclp (with attached art and packed CPK files), .zip, .json —
  saved with the iPhone's Save dialog.
- **Library / Studio**: imported files, Eclipse file browser and downloads, animation lists and
  scripts, move catalogue, card poses, artwork, decorations, custom LWF animations, movie uploads.
- **Offline downloads** (Wi-Fi only option, automatic storage budget) and offline previews.
- **Sparking**: built-in catalogue, update characters, resource downloads, audio banks, Sparking APK
  import and .sprk → .eclp conversion (keys kept in the iPhone Keychain, decryption done natively).
- **AI**: connect your own AI; keys stay in the iPhone Keychain and are added natively to requests.
- Tested in a browser that stands in for the iPhone, against the real Eclipse site: 46 feature
  checks, 3 player types, plus the web suites. An independent review of the iPhone-side code found
  13 problems (2 crashes, a player server that could stop after the phone sleeps, etc.); all fixed.
  Not yet run on a real iPhone.
- Character thumbnails come from saved copies (instant, and they work offline), like Android.
- Web version: can now also open Android-made .eclp files; saves all game data for offline at once.

## iPhone app — foldable / both screens (UnitCreator-2.30.1.ipa, third build)
- **Fold, unfold and rotate without reloading.** The app catches the size change before it happens, keeps your
  place in whatever list you were scrolling, pauses decorative animations for the instant the layout changes, then
  restores. The docked animation player resizes along with the screen. Anything you were editing stays open.
- **Every screen fits narrow and wide displays.** Checked by machine from 320 to 430 points wide (outer-screen sizes)
  and at 744 × 1133 and 1133 × 744 (inner-screen sizes): the character finder, every builder step, the "⋯ More"
  menu and Settings — nothing runs off the side.
- **Character finder is smooth.** Scrolling a fresh list used to stutter (slowest frames ~95 ms with the CPU slowed 4×);
  now ~20–30 ms. Thumbnails also decode off the main thread.
- **The phone is no longer treated as a slow device.** iOS hides its real memory and core count from web pages, so
  the app used to switch itself to its low-end mode. The app now reports the real values.
- **New: Settings → "This iPhone's screen".** Shows the window and screen size (points and pixels), refresh rate,
  measured frame rate, memory, cores and Low Power Mode. Fold or unfold, then tap *Check again*; *Copy report* copies it.
- Tested here in a browser stand-in at those sizes; it still needs checking on a real foldable iPhone (see HANDOFF).

## Round 42 — Android + iPhone together (v2.30.2, versionCode 89)
- **Smoother character finder (Android too).** The first scroll through a fresh list of characters stuttered;
  it's now smooth. File: `v2/ui/perf.css` (finder tiles no longer use `content-visibility:auto`).
- **"⋯ More" menu stays on screen on narrow phones (Android too).** File: `v2/ui/shell.css`.
- **iPhone app** rebuilt as the same version (2.30.2, build 89) with the foldable support from the previous build.
- Files: `Dokkan-Unit-Creator-v2.30.2-android.apk` (signed with your key, installs over 2.30.1), `UnitCreator-2.30.2.ipa`.

## iPhone Duo — native screens (not yet released; waiting for testing)
- **Full inner display, no black bars.** iPhone Duo letterboxes apps built for iOS versions before 27.1; the app is now
  built for iOS 27.1 and no longer asks for "full screen only".
- **Exact Duo sizes checked:** outer 466 × 678 and inner 626 × 890 points (1398 × 2034 and 1878 × 2670 pixels), upright and
  sideways — Home, Library, character finder, Animations, Card Builder and Settings all fit.
- **Clear of the clock, Dynamic Island and home bar** on every iPhone, in every orientation (this was missing before:
  the top of each screen sat under the status bar). Sideways, the sidebar scrolls and is more compact.

### Passive step: three ways to add abilities
- **＋ Add an ability** lists all 130 passive abilities found in the game, searchable and grouped; tap one and set it up.
- **★ Add a preset ability** is the same list, each already set to a balanced value taken from today's LR and UR cards.
- **⧉ Copy a character's passive** copies one character's whole passive, or combines abilities from several characters into yours.
- "Organize & balance" and "Ask AI to design my passive" were removed from this step.
- **SLR Super Exclusive:** level 180 units get a permanent ATK & DEF +10% at the top of every passive, applied after every other boost, the same way GR's Godly Exclusive gives +20%. It glows gold instead of red.
- **Leader Skill step:** new bonus tiers start empty instead of copying the first one; the copy/combine buttons and the description checkbox are gone (the description always updates); the name starts randomized (🎲 rerolls it); Quick starts are All Types Ki +3 +170%, Super Class and Extreme Class Ki +3 +200%.
- **Simpler passive list:** one plain entry per ability (64 instead of 130 near-duplicates); who it affects, % or fixed amount, timing and conditions are chosen in the ability's editor after you pick it.
- **Passive abilities rebuilt for beginners:** 20 simple abilities to pick from (Critical hit, Dodge, ATK & DEF, Ki…); each opens a guided editor — what it does (kind, how it grows, % or fixed), who, when & how often (chance slider, duration, once per battle), requirements & restrictions — with a live “How it works in battle” summary, Duplicate, Turn off/on, Add another effect at the same moment, and Advanced game settings for experts.
- **Every passive in the game:** all 56 passive effect types and their variants are now available, including character exclusives (Giant / Rage form and Exchange picked by name from every one in the game, End transformation, Standby mode, Cancel a skill, Transformation) plus Ignore enemy DEF and Block “attacks always hit”. No options are greyed out any more.
- **Name conditions:** a requirement can now be “a character named … is on the team”, “facing an enemy named …” or “a character named … attacks in the same turn” — pick from the game's list or type any name. Chance slider fixed on iPhone.
- **Dokkan wording everywhere:** conditions copied from other characters read like the game (no more “An inherited condition”), and the strongest EZA step is selected by default.
- **Intro step:** choose whether a unit has an Entrance Animation, which scene, when it plays and the bonuses it gives; the passive description shows it the game's way. Revivals now have their music and “bonus after reviving”.
- **Clearer “Who gets it”** wording, **use your own revival animation**, and revive-triggered transformations/boosts that work across two characters (the other one transforms when it rotates in, without replaying the revival).
- **Revival animation is one simple choice:** pick a character’s revival (e.g. “Goku (Ultra Instinct)”) or “★ My own animation” — only one ever plays.
- **One animation choice for every move:** counters, revivals, Super / Ultra / EX attacks, Active Skills and every move on Look & Animations show plain names (no “Like”) plus “★ Make my own”, “★ One of my saved animations” and “🔍 Any attack animation in the game”. Counters can now reduce damage from all attacks, normal attacks or Super Attacks.
- **Download everything up front:** the first time the app opens it asks whether to download Everything or the Essentials, so animations, pictures, sprites and battle motions open instantly instead of loading each time.
- **One downloads folder:** everything the app downloads goes into Download › Dokkan Unit Creator (iPhone: Files › On My iPhone › Dokkan Unit Creator), split into Game files, Game movies and Animation scripts. Nothing shows up in Photos or Gallery. Game movies now download last, so they can never stop the rest.

## Round 43 — v2.30.3 (Android 90 + iPhone)
- **Automatic clean-up before every download:** removes half-finished, outdated and duplicate downloads (also from earlier versions) and keeps everything still valid, so nothing downloads twice. Settings › Animations › “Clean up old files now”.
- **Earlier installs:** if your phone still has a Dokkan Unit Creator folder from before, the app asks for Android's “All files access” to reuse it and merge any “(2)” copies into it — no new folder. It only ever touches its own files.
- **Sparking: custom-made content only.** Sparking's own characters, transformations, moves, animations, effects and custom stages download from Sparking; original game files come from Eclipse and are never downloaded twice. New “Sparking custom content” download (about 5 GB).
- **v2.30.4:** simpler download question with a Wi-Fi only / Wi-Fi or mobile data choice.
- **v2.30.5:** the app checks for new game data every time it opens (“New game data · Download now”), and downloads always get the newest game data first.
- **v2.30.6:** downloads about 2–3× faster (10 at a time, connections reused).
- **v2.30.7:** downloads run 32 at a time (about 3× faster again).
- **v2.30.8:** downloads as many files at once as the server handles well (64 on Android, 48 on iPhone), with automatic retries.
- **v2.30.9:** downloads keep going with the screen off or in other apps (a “Downloading game files” notification shows progress) and continue by themselves if the app was closed.
