# "Import to Eclipse" / "Import to Sparking"

This is the last step of a unit (Save & Play → **Put it in your game**). Research date: 27 Oct 2026.

The research used the user's downloaded apps:
- Eclipse Patcher v3.0.0 (iOS IPA, plus Android APK v1.0.0.4)
- Sparking 6.6 (iOS IPA, plus Android APK Patcher 3.62)

The extracted manifests, Info.plists and string dumps are in `AI-Workspace/Dokkan-Unit-Creator/research/`.

## What the two games accept

| | Eclipse | Sparking |
|---|---|---|
| App id | `com.anthen.eclipse` (iOS + Android) | Android `com.sparkingDokkan.GLB`, iOS `GLB.Dkkn.Sparking.dev` |
| Patch file | `.eclp`: "ECLP" + AES-256-GCM, our app already writes it | `.sprk`: "SPRK" 01 + IV[16] + AES-256-CTR(ZIP) |
| Open-with / share target | none (no document types, no file intent filters) | none |
| URL scheme | `dbzdokkanww` (Android host `jp.co.bandainamcogames.BNGI0221`) | the **same** `dbzdokkanww` |
| How it imports | iOS: Patches › ＋ (document picker), then "Patch Added!". Android: built-in file browser starting at `/storage/emulated/0` | **SPRK File Manager** lists `Internal storage/Download/Sparking/` and has an Import button. iOS: Import SPRK (document picker) |
| Files visible in Files app (iOS) | yes (UIFileSharingEnabled, open in place) | yes |

Neither game can be handed a file by another app, so fully automatic importing isn't possible. The app does the closest thing:

- **Android**
  - It saves the file where the game looks: `Download/Eclipse/<unit>.eclp` or `Download/Sparking/<unit>.sprk`. Sparking's own folder is exactly what its SPRK File Manager shows.
  - It then opens the game (launcher intent for the package).
  - The user taps Import once inside the game.
- **iPhone (v2.36)**
  - The first time, the app asks to link the game's folder once (*On My iPhone › Sparking* / *Eclipse*). This uses the iPhone folder picker plus a security-scoped bookmark, which is the supported way for one app to write into a folder another app shares in Files. Nothing is read from the game's private storage.
  - After that, each unit is saved straight into that folder and the game opens with `dbzdokkanww://`. "Save somewhere else this time" keeps the old save sheet.
  - **No duplicates:** the same unit gives the same `.sprk` (zip with fixed times; IV = first 16 bytes of the zip's SHA-256). The app also remembers what it last sent for each unit, ignoring export timestamps, so the same unit sent again keeps the file that's already there. A renamed unit replaces its old file, but only a file with the same unit ID.
  - If the link breaks (game reinstalled), the app explains it and links again in one tap.
  - Because Eclipse and Sparking share that scheme, iOS opens whichever one it picks when both are installed.
  - In the game: Patches › ＋ (Eclipse) or Import Patch (Sparking).

## The Sparking patch the app writes

ZIP contents (the same layout the app's SPRK→ECLP importer reads):
- `patch_info.json`: `name`, `version`, `description`, `creator_id` (whole number, 0; **Sparking 6.6 refuses a patch without it**: "patch_info.json must contain a nonnegative whole-number creator_id"), `creator_name`, `created_with`
- `patches/sql/<unit>.sql`: the unit's game data (the same SQL as the ECLP's `files/<unit>.sql`)
- `patches/assets/<path>`: every attached file (art, animations…), from the ECLP's `files/<path>`

Encryption: AES-256-CTR (big-endian counter) with a random 16-byte IV. The file is `"SPRK" 0x01 IV ciphertext`.

The key is the 16-byte format key from the user's own Sparking APK, zero-padded to 32 bytes. It is saved when Sparking is set up:
- Android: `files/forge/sprk-format-key.bin`
- iPhone: Keychain `sparking.sprk`

Never ship the key in the app.

Where the keys sit inside the Sparking APK (`lib/arm64-v8a/libbase.so`):

| Version | libbase.so SHA-256 | SPRK key (16 bytes) | DB key (64 hex) |
|---|---|---|---|
| 6.5.5 | 9d3f2749…dca0 | offset 648423 | offset 487092 |
| 6.6 | 83c0b40f…18d4 | offset 665339 | offset 495950 |

- The same 16-character password also appears in the iOS Sparking patcher right before `Running SPRK Patch`, so iOS and Android Sparking use the same key.
- The iPhone app accepts both versions when you set up Sparking.
- The Android app's set-up is still the original 6.5.5-only code. If Sparking was set up on Android before, the key is already there; a fresh Android set-up with only 6.6 needs one more fix.

## Code

- `v2/ui/builder.js`: Save tab, **Put it in your game** buttons (`data-export="to-eclipse" | "to-sparking"`).
- `v2/ui/app.js`:
  - `exportProject("to-eclipse"|"to-sparking")` runs the same checks as Save game file, then `Native.call("sendToGame", {target, request})`.
  - `showSendOutcome()` shows where the file is and the one step left in the game.
- **Android:** `dock/src/.../SendToGame.java`, reached through `ForgeFixes.dispatch "sendToGame"`.
  - It builds the patch with the app's own `writeExport` (ECLP, or ZIP for Sparking), converts it to the Sparking layout and encrypts it.
  - It writes into `Download/<Game>/` and launches the game.
- **iPhone:**
  - `web/src/ios-io.js` `H.sendToGame` builds the ECLP, or the Sparking ZIP plus native `sprkEncode` (Host.m).
  - Then it opens the save sheet and `dbzdokkanww://`.
- **Web test page:** says it works in the phone app.

## Status

- **Built and compiled:** Android and iPhone code, plus the Save-tab UI in the web test page.
- **Not yet tested inside the real games.** Sparking isn't installed on the iPhone Duo (free Apple ID limit of 3 apps), and no Android phone was connected.
- **First real test:**
  1. Make a unit.
  2. Tap Import to Sparking on an Android phone that has Sparking.
  3. In Sparking, open SPRK File Manager › Import.
  4. If Sparking refuses the file, check its `Download/Sparking/sandbox_diagnostics.txt`.

## Status (27 Oct 2026, v2.36.0)
- Tested in the cloud with the iPhone mock (web/test_redesign.py):
  - the one-time link
  - the file landing in the folder
  - a valid SPRK v1 file (decrypted and checked: header, `patches/sql`, `creator_id`)
  - no second copy on re-send
  - a rename replacing the old file
  - lost-link recovery
- The iPhone Duo now has Sparking 6.6 (`GLB.Dkkn.Sparking.dev.P4NRE7Q8ZT`, signed with his Apple ID) and The Breaking. Unit Creator is not installed right now, so there is a free slot.
- Still to do on the phone:
  1. Install v2.36.0 (`run/device-install.command`).
  2. Import to Sparking: link the folder, then use Import Patch in Sparking.
