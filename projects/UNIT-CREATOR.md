# Dokkan Unit Creator: summary for ChatGPT

_Claude owns this project. ChatGPT: read for context only, don't edit its code._

## What it does
Make custom Dokkan Battle characters (and EZA / Super EZA upgrades of existing ones) without coding, then put them into **Dokkan Eclipse** (.eclp patch) or **Dokkan Sparking** (.sprk patch).
- Platforms: Android APK, iPhone IPA, iPhone Duo IPA, and a web test page.
- Version in progress: v2.36.0 (build 125). Not built yet; waiting for Tin.

## Rules the app follows
- Characters you can start from: **fully awakened only**, showing the best version (**Super EZA > EZA > base**), **no duplicates**.
- Official Dokkan wording for every ability, condition and description.
- Rarities include LR, UR and the custom **SLR** (an LR at level 180 with a "Super Exclusive": ATK & DEF +10% and 10% damage reduction, always on) and **GR** (level 200, "Godly Exclusive": +20% / 20%).

## Main screens (after the Oct 2026 redesign)
- **Home:** Dokkan-style main screen.
  - Your last unit big in the middle.
  - Banners on the right: Create a unit, EZA / Super EZA, Templates, Import, Sparking characters, Downloads.
  - A big **Continue** button.
  - Your units below.
- **Card builder tabs:**
  1. **Portraits & Sprites:** only 3 pickers (portrait, battle sprite, battle motion)
  2. **Artwork & Aura:** card art, AI art, custom in-game art, battle poses, aura
  3. Basics
  4. Leader Skill
  5. Passive Skill
  6. **Super Attacks:** each attack is a tap-to-open card; normal attacks and other animations at the bottom
  7. Active Skill
  8. Standby & Finish
  9. Domain
  10. Links & Categories
  11. **Save & Play:** Import to Eclipse, Import to Sparking, Export .SQL / .JSON
- **Import:** unit files, .eclp/.sprk patches and **.sql files**.
- **Sending to Sparking on iPhone:** you link the Sparking folder once. After that units are written straight into it, and the same unit is never copied twice.
- Look: dark, fiery "Dragon Ball intensity" theme, comic-style titles, slashed menu bars.

## Why it matters for the other projects
- The **Offline Dokkan** game will contain this Creator. Finished characters go straight onto the player's custom summon banner.
- The **App Installer**'s iPhone Duo screen handling should copy what this app does: see IPHONE-DUO-DISPLAY.md.
