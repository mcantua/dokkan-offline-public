# Actual client inputs and reuse

Tin confirmed the full Android export finished and supplied the iPhone IPA. Duo is the first implementation/build/test target. Android inspection is shared reference work, not an Android-first release. No APK/IPA was built during this input-inspection batch.

## Android client verified in the cloud

- Drive source: `Sparking Full Data/Sparking/Sparking.apk`, file ID `1wIqMDoHqcLAy2tAl65ywi4uGL0Hw78Wl`.
- Original private file preserved;108,832,078bytes; SHA256 `10ba87c268961285f26269d2110d5af4e114b7853d1baabf775fa33411bb3049`.
- Actual manifest: `com.sparkingDokkan.GLB`, version6.6.0/code351, launcher `org.cocos2dx.cpp.AppActivity`, arm64-v8a only.
- The APK contains the real native engine, `libcocos2dcpp.so` (78,497,512bytes, SHA256 `dd403dcd850b32dfe3b77d555c7002e5b1b4aaaacc99bedf23a9ec501d7da82c`), and the existing source patcher `libbase.so` (4,621,104bytes, SHA256 `83c0b40f49ae0edb0c91650ff36eb97a528db2c14627333f7023c3a13e0018d4`). These user-supplied binaries remain private and are not our authored/runtime distribution.
- DEX035,7,072 classes. The actual Cocos Java HTTP bridge contains `createHttpURLConnection(String):HttpURLConnection`, `connect(HttpURLConnection):int`, `sendRequest(HttpURLConnection,byte[]):void`, response code/body/header readers and `disconnect(HttpURLConnection):void`. The factory opens a normal Java URL connection; response handling includes compressed/error streams. These are verified bytecode signatures/semantics, not a working offline adapter or a verified game-response schema.
- `DirectoryPath.getApplicationRoot/getResource` in this APK are empty-string stubs. Do not assume those Java methods alone supply a usable resource-root hook; actual native startup/path handling remains to verify. App startup also contains source SDK/notification hooks; offline startup must not depend on live accounts/telemetry.

## Completed export and content mapping

The source export's verification record identifies the Android package/version above and36,257 exported files/26,309,112,799bytes. `assets-manifest.json` supplies36,150 assets-root records; manifest SHA256 is `2196f85c0d09e41967d6b0c08a1860fe57037c1f172cd8c048e9cad70f0f5a33`. Original saves/settings, private User files and account state are preserved in Drive; they were not imported into a player profile or printed.

The expanded Drive tree lets us fetch available files without downloading the26.65GB full ZIP into the19GB free cloud disk. It is not proven complete: the observed `assets/sqlite/current/en` Drive folder is empty even though the exported manifest references its114.8MB master. The complete archive remains the input for selective extraction of missing files; do not claim the master was fetched or overwrite it with the small bundled seed database. `content/export_asset_catalog.py` produces36,087 immutable references compatible with the existing native content resolver, excluding63 private User records. Android/iPhone graphics, audio, scripts, archives and databases must be checked against the actual iPhone client before marking compatibility. Native Android ELF binaries cannot be repackaged as iOS Mach-O binaries.

## iPhone/Duo client verified in the cloud

Tin completed the private Colab transfer. All twelve parts, the source ID/length and the reconstructed read-only IPA passed the source manifest's SHA-256 checks. Original Drive IPA remains unchanged/private; no Mac project data was downloaded. The initial cloud-download staging-name collision was corrected and its affected parts retrieved again before whole-file assembly; all final bytes passed the pinned checks.

- Source: `Sparking 6.6.ipa`, Drive ID `12o01--OT-8r3QiXVD6mp-uMfv4b_qbms`,1,144,358,271bytes, SHA256 `0ea61911a09c4e7735f2d7b32b7b2c6c6977c1f4acf0a9db278049528b662816`.
- Actual bundle `GLB.Dkkn.Sparking.dev`, version6.6.0/build26093018. Main executable `BNGI0221` is55,697,728bytes; SHA256 `9d6bf0470c4b4ff7d914740ccf9f1622afa962b763e18bfcf1f6e051bfae0610`.
- Main executable: arm64, actual LC_BUILD_VERSION iOS minimum15.0/SDK26.0, cryptid0, chained fixups present. Its SDK26.0 metadata is not proof of the project's required SDK27.1/Duo presentation. Preserve the original binary and verify a genuine integration/display path rather than claiming an SDK-field edit equals rebuilding with27.1.
- Source patcher `DokkanSparkingPatcher.dylib`:5,657,724bytes; SHA256 `74e47aa75fdbd828fa3918a966b50457e8497143962d5be573cb60f332e055dc`; arm64, minimum14.0/SDK16.5, cryptid0, no chained fixups. Allowlisted labels include `HttpAsynConnection`, `startRequest:`, `responseData`, `responseCode`, `connectionDidFinishLoading:` and `LocalResponseHandler`. These are static labels only; method encodings, callback semantics and current request/response bodies still need verification.
- Bundle includes1,418 ZIP entries/1,144,047,808uncompressed bytes, substantial tutorial assets, source patcher/frameworks and launch resources. Plist allows iPhone/iPad, portrait, UIRequiresFullScreen=true and LaunchScreen storyboard. No arbitrary profile/key/account contents were printed or imported.

Sanitized reproducible metadata is in `supplied-iphone-metadata.json`; raw original/client extracts stay ignored/private. The original app icon was viewed as a static input image, not a game launch. No APK/IPA was built and no app UI changed, so no editor HTML rebuild was needed.

**Next:** inspect the actual iPhone ObjC/ABI and startup/resource/network contracts (including chained-pointer handling), then implement the local adapter around that engine, Duo first. Compare required Android/iPhone resource formats before reuse; obtain missing master files by selective cloud extraction. Runtime contracts and both Duo displays remain unverified. Keep original scenes/animations/mechanics and integrate Creator through shared local services; do not substitute the rejected authored game harness. No further Colab authorization/retry is required for this IPA.
