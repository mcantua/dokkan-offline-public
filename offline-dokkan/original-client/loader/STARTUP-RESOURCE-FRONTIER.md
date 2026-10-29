# Original-client startup resource frontier

This follows the supplied client's real startup code. It does not define a
replacement startup screen or infer a minimum asset set from the Android
export.

The pinned 504-byte original `AppController` launch body was analyzed in one
bounded cohort. Its high-pcode footprint stays inside that exact body. Six
direct native callees were then analyzed together; the52-byte dispatch body
(`c8a74253d4c55fd64ab243e9b177f2e9fd9313b983277100371d68eedfae11b8`)
calls its receiver's virtual slot at byte offset 16 with that same receiver.
This is source control flow, not permission to invoke a guessed C++ ABI.

The application's already-pinned native vtable has exact RTTI `11AppDelegate`.
Its slot 2 body is 2,624 bytes / SHA-256
`e2dce5edd370d1f3daf7b155a51a5efda1c3645d4cdc20b251b2dfd3fd76abf2`.
The decompiler recorded 366 high-pcode instruction sites, all inside that body;
no tail-followed body is counted as part of this function. It reaches the
already-recovered original master singleton and constructs the literal
`download_caches.db` path through the original file-system provider. Neither
the literal nor this observation supplies a new host-selected path or a
download-cache/player-data fixture.

A literal `Launch` is passed to a native helper, followed by four more native
calls near the initial presentation path. Their exact source pins are retained
privately for the next bounded cohort (60, 48, 460, 136 and 68 bytes). `Launch` has
not yet been established as an asset filename, script entry or scene identity.
No mandatory resource path has been proven by this call chain so far.

That five-function cohort is now available. The 136-byte factory allocates a
`0x2d0`-byte object and installs a vtable whose exact original RTTI is
`11NoticeScene`. It invokes a 212-byte initializer with SHA-256
`ac47f236d4cf124c10e358ede942843503ad3c3d8dcbd9c19bdf1f096da85ad4`.
The failure path dispatches virtual cleanup at byte offset 8; the success path
calls a 48-byte native helper before returning the object. That helper's exact
ownership behavior is not yet independently established. This identifies the
actual native NoticeScene construction on the startup path. It does not prove
that the scene rendered or that its dependency set is known. That initializer
has now been analyzed: all its observed instruction sites are inside the
declared 212-byte source body. Its direct 144-byte factory creates an object
with exact RTTI `20LayoutQuestQuestTips`. The source records that factory's
124-byte initializer as SHA-256
`dc72c232a7c9b910b6e4aace0c5f1106621ca26688a6dec4e535432764b85aca`.
This is the next resource-loading frontier; a direct literal scan has not
established any filename or complete dependency set. Common scene constructor
and ownership helpers remain private pins rather than additional analysis
targets without a specific need.

The existing iPhone/Android compatibility catalog admits 29 original aliases
for 27 unique resources: audio and three tutorial UI CPKs. That is a verified
subset, not the complete 1,067-candidate iPhone bundle resource inventory and
not a proven boot dependency set. The restored Adjust framework binary and
original opaque app-root seed therefore do not establish a complete startup
resource package. The framework's original bundle metadata remains missing.

Continue from `notice_layer_factory_callee_2` in
`private/ghidra/startup-notice-layer.private.json`, then follow the actual
LayoutQuestQuestTips resource-consuming path. Reuse the existing FD catalog/preloader once
the required paths and original bundle aliases are established. Do not create
a generic manifest containing guessed filenames, mark a nonempty directory
complete, copy an unproven Android database into the preferred iPhone path,
or run a native close/reopen as a substitute for correct cold startup.

All raw code, addresses, pcode and detailed source spans stay in the ignored
private analysis workspace. No original game, new native component or app
package was compiled or executed for this analysis. Actual startup, login,
home, gameplay and save acceptance remain unverified.
