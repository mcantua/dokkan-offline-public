# Reused native Creator tools in the unified app

`ODScopedCreatorTools` reuses the existing `unit-creator/ios-objc/Host.m` and
`Player.m` implementations. It does not replace their gallery/files/downloads,
actual LWF preview/player, recording, export or native AI behavior with stubs.
The public constructor takes only native-issued workspace/site/scope/current
and network authorization capabilities. Pages cannot choose a storage root.

The complete editor's selected master, queries, project documents, saves,
versions, settings, core and Finish remain with the existing trusted Session.
General native SQL and `installDatabases` are deliberately absent from tools.
Session owns its readonly master and any separately reviewed temporary database
or projection authority; this module never opens arbitrary authoritative files.

### Readonly staged-source database inspection

The inspected iPhone export builders package textual SQL inside ECLP/ZIP/SPRK;
they do not execute imported patch SQL or require a writable export database.
The actual missing native DB operation was verification of a picked/decrypted
temporary candidate. `ODCreatorSourceDatabases` restores that narrow requirement
with `sourceDatabaseOpen`, `sourceDatabaseRead` and `sourceDatabaseClose`.

Open accepts only a relative regular plaintext SQLite file inside the bound
tools namespace, then returns an opaque UUID handle, never an authoritative
master path. Up to8 handles pin an open descriptor and path identity, length,
mtime/ctime. Reads reject replaced/changed files and revoked scopes before/after
execution. Close/invalidation releases the descriptor.

Only four typed read kinds exist: `quickCheck`, `tableType`, `tableInfo` and
`cardCount`. The table arguments are the existing verifier's eight required game
tables. Fixed native queries reuse Host's existing SQL parameter binding/result
conversion, with result/field/instruction limits. Each inspection opens a fresh
readonly/no-follow SQLite connection, disables extension loading/virtual-table
modules and untrusted schema, and installs a native authorizer. Card counting
requires an ordinary main-schema table. No page SQL, attach, extension, writable
flag, arbitrary absolute path or master replacement capability is supplied.

The frontend owner adapts `IOS.verifyDb` to these typed calls while keeping
`IOS.sql(native:selected-master,...)` with Session. Existing source activation
still requires the explicit native close/rebind path; a successful candidate
inspection does not change selected game data. This capability was added after
the last compile boundary and awaits root's combined native check; no additional
test run or package was made for it.

## Scoped storage and lifecycle

The narrow Host/Player refactor adds an explicit `ForgeStorageContext` initializer
and passes that context through every existing storage resolver, site lookup,
temporary media path, folder bookmark and Keychain query. Scoped tools use only
`workspace/native-tools`, with downloads and temporary outputs underneath it.
The legacy standalone constructors/class methods retain their existing default
paths; no process-global or thread-local root override is used.

Scoped paths reject traversal, malformed encodings, URL syntax/control characters
and symlink components. Root destinations are allowed for listing/mkdir/explicit
clear, not file replacement. External linked-folder imports are restricted to
regular resource files inside the granted folder. Source/private User/settings
paths are not game-resource import candidates. The source/mirror/preview services
do not gain a path to the Session master, save, owner file or projects store.

Construct and attach on main. A native current-scope callback is evaluated on
main, then revocation is latched atomically for background IO and transport
tickets. The owner must invalidate tools before releasing/changing its lease.
Invalidation cancels scoped sessions, stops the preview server/panel and revokes
further file/key/network access. Existing source requests get no fallback root.
Player cookies use a private nonpersistent store, not the game/global store.

## Native optional networking

Scope sessions are ephemeral with no cookie/credential/cache store. Every
network request and redirect passes the native URL authorizer and the private
`ODNativeCreatorAuthorizedRequest` ticket decorator after final body/auth headers
are set. There is no JS bypass header or global transport override. Original
game/SDK traffic stays untagged and handled by the local-only transport. AI
redirects remain disabled. Fixed AI providers must match their real provider
host; a custom provider also requires native URL authorization. A missing
native authorization/decorator refuses the request, rather than faking output.

The authorizer must be thread-safe and must not touch UIKit. Existing transfers
are canceled on close; ticket revocation is not represented as undoing a request
that already began. This development batch executed no network requests.

## Personal source codec capability

The generic Keychain bridge accepts only `ai.openai`, `ai.gemini`,
`ai.anthropic`, `ai.xai`, `ai.openrouter` and `ai.custom`, without raw-key reads.
Source keys use a distinct native-only scope service. The explicit
`sourceCodecStatus`/`sourceCodecImportAPK` capability replaces browser source-key
derivation/setters. Source status returns booleans and public version/hash only.

`ODCreatorSourceCodec` opens only the staged relative APK selected by the person,
requires the admitted6.6 APK's108,832,078byte length/SHA-256, and extracts only
`lib/arm64-v8a/libbase.so` using the bounded CRC-checked ZIP reader. It delegates
material admission to the existing public-map native helper in
`original-client/master/source_material.c`, checks source stability/current
binding, and writes the resulting material directly to native Keychain. Native
material/library buffers are wiped and freed. No raw source keys are returned to
JS, logged, included in files or compiled into the plugin.

After admission, the existing `sqlcipherDecrypt`, `sprkEncode` and `sprkDecode`
implementations read those native Keychain source slots internally. Before
admission they fail honestly. Generic source `secretSet/Get/Hint/Delete` remains
unavailable. The root/master/core identity does not change when source codec
setup or a temporary file conversion succeeds.

## User content archive

The native binding configures `configureArchiveWithSnapshotProvider:
documentsRestorer:` using the SAME issued Session callbacks. The archive helper
uses the native player's scoped `dokkan-files` folder bookmark, not a JSON path
or an app-private directory advertised as surviving uninstall. A missing bookmark
returns truthful unavailable status and the existing UI invokes the folder picker.

Archive mutation freezes new tool/scheme mutations, rejects active native
downloads, and drains prior scoped file writes before the resource transaction.
`archiveOperationInProgress` is the main-actor gate the controller uses to reject
ordinary Session edits/Finish/close during that transaction. Native snapshot and
restorer callbacks retain Session authority. The archive component owns ZIP
integrity/staging/restore semantics; this module only supplies the scoped native
dispatch and real bookmark.

## Build and verification

`build-source.json` lists the two extra reused Objective-C sources, all class/
global rename macros and exact frameworks/libraries. Compile Host/Player once
with those defines to avoid collisions with the genuine app shell's existing
ForgeHost/ForgePlayer/internal classes. The wrapper supplies the sole renamed
display-geometry global. It does not fabricate reserved-region measurements.

The prior checked inventory found47 scoped low-level operations:44 existing native
handler operations and3 explicit capabilities. The readonly source inspector adds
3 typed operations, bringing the current source set to50; its combined native
check is pending. This is registration/source reuse,
not proof of full editor runtime parity. The actual admitted APK's bounded native
ZIP reader produced exactly the pinned4,621,104byte library; the original stayed
unchanged and the buffer was cleared/freed. No key values were read by that check
or emitted. All four changed Objective-C components passed an arm64 syntax check
with real iPhoneOS16.5 headers, not SDK metadata relabeling.

`source-reuse-evidence.json` records the limits. Actual scoped filesystem/Keychain,
media/download/player/archive/source-codec UI behavior and final complete Creator
integration still need the coherent genuine SDK27.1/Duo runtime check. No APK,
IPA, HTML package, broad old UI suite or personal-device connection was made by
this task. The frontend owner integrates these services into the existing editor
and owns the next combined HTML/staging update.
