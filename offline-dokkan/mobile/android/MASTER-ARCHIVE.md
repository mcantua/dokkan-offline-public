# Native picker master staging

`OfflineMasterArchive` is a package-private native-host utility. It is not registered on the Creator WebView bridge and accepts no filesystem paths from a page. The existing master importer calls it on its worker after Android's explicit user file picker returns a `content://` URI:

```java
try (OfflineMasterArchive.Stage input = OfflineMasterArchive.stage(context, pickerUri, selectedGame)) {
    File database = input.database();
    // Existing read-only SQLite integrity/schema checks, SHA-256, native probe,
    // pinned-save migration guard, then atomic master publication/selection.
}
```

`selectedGame` is exactly `eclipse` or `sparking`. The URI's path and provider display name never become a filesystem path. All input is copied into a fresh random directory inside the app's private cache. A raw `SQLite format 3` file passes through as a private copy, bounded to 2 GiB. A ZIP/APK-style input is bounded to 4 GiB minus one byte and passed to the portable `content/master_archive.c` reader. Only the selected game's fixed plaintext database entry is extracted. An original encrypted game IPA/database is unsupported; this utility has no keys or decryption path. The host's existing importer must still validate the extracted database before making it active.

`Stage.close()` removes only its fixed temporary input/database/SQLite-sidecar files and its own random directory, both after success and failure. A database already moved out by the trusted importer is not deleted. Symlinked staging roots and non-picker URIs fail. No source file is modified, and no network or broad-storage permission is added.

`master_archive_jni.c` is a narrow private JNI method. Public `ParcelFileDescriptor.dup/getFd` supplies its descriptors; it does not inspect hidden Android/libcore fields. The portable reader requires a read-only seekable source FD and a fresh empty private output FD. Native success syncs/rewinds output; failure clears accepted output before Java removes the staging files. CMake and `build-native.sh` compile both archive C sources and link public/system `z`; native fingerprints and symbol gates cover the new source/export.

Run the focused new-source check with locally available inputs:

```sh
python3 offline-dokkan/mobile/android/check-master-archive.py /path/eclipse-db.zip /path/reference.db
```

The combined scenario passed against the actual supplied Eclipse ZIP and restored master: unchanged Java utility → actual JNI → portable C extraction produced the expected SHA. It also verified standalone SQLite/private path confinement, original-source preservation, complete temporary cleanup on success and corruption/wrong-game/provider failure, picker-only input and symlink-root rejection. The helper compiled against the actual Android SDK35 jar and its C/JNI sources compiled against public Android API26 ARM64 headers. Tiny JVM Context/provider/descriptor facades are test inputs only, never app runtime classes. This check does not claim Android SAF/device execution, master activation, an APK build or original-game compatibility; the host importer and device flow have their separate checks.
