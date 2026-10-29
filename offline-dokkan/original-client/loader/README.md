# Original engine image preparation

`adapt_image.py` prepares an unsigned private image candidate from the exact supplied unencrypted arm64 main. It preserves the original file, engine code, file offsets, image base, ObjC metadata, data and SDK26.0 build metadata. It never decrypts content, handles signing credentials, executes the image or packages an app.

The pinned main has an executable-only page-zero segment, dyld launcher/entry commands and an obsolete source signature. The tool removes those load commands, marks the candidate MH_DYLIB, supplies its own install name and clears MH_PIE. It adjusts the chained-fixup segment index table when removing the segment without moving any fixup targets/imports or other file bytes. The last source patcher dependency is removed only after confirming it is ordinal63, last, and unused by both chained imports and classic symbol metadata. This does not establish that the patcher's behavior is unnecessary: any required modifications/resource decoding must still be implemented from verified contracts rather than loading its live-service startup implicitly.

All original inputs remain private. Source pin:55,697,728bytes/SHA256 `9d6bf0470c4b4ff7d914740ccf9f1622afa962b763e18bfcf1f6e051bfae0610`. The first prepared image is the same length/SHA256 `efaabfc9b3cdb0e2eeb550b6ea616f5eeb565c6584ad838b765f34539648d222`. Neither binary belongs in GitHub or general distribution. Regenerate from the user's retained original:

```sh
python3 offline-dokkan/original-client/loader/adapt_image.py \
  offline-dokkan/private/iphone-client/BNGI0221 \
  offline-dokkan/private/iphone-client/OriginalDokkanEngine.dylib
```

One actual-image static check is in `adaptation-evidence.json`: independently decoded selected ObjC ABI and chained rebase/bind counts remain identical, prepared Mach-O metadata parses, SDK remains26.0, original hash stays unchanged, and the unused source-patcher dependency is absent. Existing candidates/staging files reject rather than being overwritten. No loader/runtime/device claim follows from this check.

**Still required:** executable-to-library dyld validation, concrete native startup preparation, code signing and actual device loading, and the original scene/render/protocol/resource/Creator connections. The retained main was genuinely compiled with SDK27.1; current changed authored components still need their matching native compile. The original AppController's UIApplicationMain entry is separately established by bounded method inspection; calling dlopen on the original MH_EXECUTE or merely changing its SDK field is not a valid integration.

`ODPreparedEngineEnvironment` establishes actual pre-load configuration, rather than demanding an exhaustive static audit of all original initializers before an authorized startup diagnostic. The local Foundation transport must already be installed, native state paths validated and the source patcher excluded. The native host selects diagnostic versus integrated startup and reports actual coverage. Diagnostic permission does not attest raw-socket/WebKit/kernel containment or successful gameplay; complete offline behavior remains an essential runtime check. No page boolean can grant loading authority. Preparation is an intermediate implementation step, not a finished game.

## Production plugin entry

Adding the plugin dependency with `inject_shell.py` only asks dyld to load the
authored library. The library must also call the reviewed native host before
the preserved shell reaches main. Without that edge, loading component code
alone does not replace the shell's earlier standalone UI.

`ODUnifiedDuoStartup` supplies this edge only when compiled with
`OD_UNIFIED_DUO_STARTUP_ENTRY=1`. Its constructor calls the native compiled
`ODCreateUnifiedDuoStartupHost` factory and admits only an
`ODUnifiedDuoIntegratedTarget`. It calls `installBeforeApplicationMain:` and
retains the installed composition. Missing factory, an exception, wrong host
purpose or failed installation stops the process before shell main. No
account/launcher/battle-harness fallback runs, and only a fixed failure label
is printed. No native error, file path or credential is logged.

The factory is deliberately still unimplemented: the actual local response
contracts, original master/resource connection and same-player services must
be composed from their admitted native capabilities. A guessed factory that
returns a diagnostic or fake success is not a replacement for that work.
`startup-source.json` records this exact boundary. It does not configure an
auth route, supply a database key, or attest gameplay.

The component source inventory includes the new file but leaves its process
constructor disabled by default. Existing hosted Finish/component diagnostics
therefore do not change startup just because they reuse these sources. When
Tin explicitly authorizes builds, `build-components.sh
--original-startup-entry` selects the production entry and validates its source
manifest. While its factory remains explicitly unfinished, this option stops
before dependency setup or compilation; it cannot silently produce a
constructor-enabled library presented as ready. Once the actual factory is
implemented, that library still requires the genuine shell
composition before use. No new workflow was added or dispatched for this
change. One source-only shell/manifest check was performed; Objective-C
compilation, constructor ordering, signing and actual original-game startup
remain unverified.

## Separate original-client startup diagnostic

`ODOriginalDuoStartupDiagnostic` now supplies a concrete native diagnostic
factory. It is deliberately separate from `ODCreateUnifiedDuoStartupHost`:
the integrated production factory remains unfinished, and its entry still
rejects diagnostics. Both entry defines together are a compile error.
Component libraries retain inert startup by default. When builds are explicitly
authorized, `--original-startup-diagnostic-entry` selects only this diagnostic
constructor; it is not a playable/release target or an app-packaging command.

The native factory selects these actual app-owned inputs:

- The existing hash-pinned genuine SDK27.1 shell baseline at
  `OriginalClient/OriginalGenuineDuoShell` and prepared original engine at
  `Frameworks/OriginalDokkanEngine.dylib`.
- The real `Frameworks/AdjustSigSdk.framework/AdjustSigSdk` dependency. Its
  original649,088-byte source SHA is recorded in
  `startup-diagnostic-source.json`; package preparation must check it before
  normal signing. Runtime loading uses ordinary dyld/OS signing policy.
- The opaque535,552-byte original app-root `database.db` seed, read-only hashed
  against its recovered source pin. It is not decoded, replaced with an Android
  database, or assigned a guessed encryption key.
- The real first `NSDocumentDirectory` result plus `assets`, matching the
  recovered native path getter. It must already exist and contain entries.
  No `_resources` path, empty fallback tree or guessed master-language path is
  created. Presence of entries alone does not attest complete resource staging.
- A separate own Application Support `OriginalClientStartupDiagnostic`
  directory, created with descriptor-relative/no-symlink checks. No existing
  `save/` directory is read, copied, changed or deleted.

Existing `ODInstallPreparedDuoShellBootstrap` supplies the concrete shell edge:
it verifies the shell's exact launch and scene method encodings, installs the
local Foundation transport before original image initialization, allocates and
retains the real `AppController` separately, launches it once, and supplies that
same object through the original-scene provider. The diagnostic factory reuses
this path without copying source ivars/IMPs onto the shell or calling a guessed
C++ entry. Scene lifecycle forwarding remains owned by the existing scene
bridge. Installation failure stops before the shell's old WebView UI.

The diagnostic installs **zero success routes**, no Creator services, no
plaintext derived master, and no native cached-handle close/reopen. Its latest
native host report can be read on main with
`ODCopyOriginalDuoStartupDiagnosticReport`; no diagnostic files, account data or
raw network requests are written. Foundation rejection is not kernel/raw-socket
isolation, and loaded dependencies/SDK network behavior still needs observation.

The real dependency binary and seed were absent from both retained resource and
client-analysis caches, then restored through the targeted cloud-only IPA
extractor with their exact pins. The framework's original bundle metadata has
not been restored; the two binaries do not establish a complete framework or
complete startup resources. A complete compatible pre-staged asset
tree, source pin verification before signing, native compile, original dyld
loading, actual AppController rendering and offline login/battle/save remain
unverified. This factory is source progress toward startup, not evidence that
the original game launched. No app/library build was run for this change.

Only Foundation-selected native directory prefixes are canonicalized, after
rejecting a symlink at that root and confirming the same directory inode. This
admits iOS's OS-owned `/var` alias while all resource/framework/state descendants
still use descriptor-relative `O_NOFOLLOW` traversal. Native database failure
cleanup may remove its working `sqlite/current` tree, so working resources must
be copies inside the own-app namespace; immutable originals/cache remain
separate. No startup code redirects the engine to the only source copy.
The native factory admits only the authored diagnostic identity
`org.offlinedokkan.startupdiagnostic.duo`, without logging an actual account or
provisioning identity. The package recipe must
use a fresh own diagnostic app/container, preserving any installed original
game and existing application data; the diagnostic Application Support folder
alone does not isolate the original engine's actual Documents accesses.
An existing native `assets/User` or `assets/sqlite/current` tree is refused
without reading or deleting its contents. No reviewed copied-working-tree
receipt has been implemented, so an existing tree cannot be admitted by a
boolean or an invented receipt. The package's reviewed resource-copy staging
still needs to establish the exact required first-start resource set.
