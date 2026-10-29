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
