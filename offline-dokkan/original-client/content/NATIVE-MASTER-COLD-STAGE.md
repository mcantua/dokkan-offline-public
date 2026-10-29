# Original native master: cold working-copy boundary

`ODNativeMasterColdStage` prepares a separate byte-identical opaque downloaded
master in the actual own-app default Documents/assets tree. It does not open a
database, obtain/apply a key, alter a cipher pragma or replace an engine handle.
No original client, app or staging call was executed for this source change.

The old `engine_master_attach` tool admits only detached plaintext read-only
copies under a host-selected state directory. That useful tool remains
available, but it cannot satisfy the original MAIN engine's flags6/native-key
contract. `ODUnifiedDuoHost` no longer treats that tool as integrated native
master admission.

The new native-only stage accepts a separately hash-pinned immutable opaque
source and an explicitly supplied actual native language. It does not select a
language or assume `en`. The caller must first prove the current engine's
language/settings contract. No currently admitted call site supplies that
observation. The default resource root is statically proven; a configured
prefix can change it and its runtime value remains unknown.

The actual app identity must be in the own `org.offlinedokkan.*` namespace;
the source game's installation identity is refused. Foundation supplies this
app's own Documents directory. Existing assets must
already have been prepared by the reviewed resource publisher. The stage checks
only for the existence of `User` and `sqlite/current`; either existing name
rejects without reading or replacing its contents. It creates an exclusive
pending tree, copies the exact source bytes and verifies length/hash/source
identity. It then atomically publishes the complete current tree with Darwin's
exclusive rename. Existing current trees cannot be replaced. The source stays
read-only; the independent working database is mode0600, because the original
MAIN engine opens read/write/create and may validate, update or remove it.

The exact bundled535,552-byte seed is rejected as a preferred downloaded master.
A SQLite-format plaintext header also rejects. Neither rejecting those cases
nor obtaining the expected opaque hash proves codec/schema compatibility. The
bundled seed remains the original fallback. No source APK, cache, signed key
material or source-game installation is modified.

The returned native stage object retains own-root/working-file descriptors and
rechecks root linkage, file identity/hash, mode and absence of User before the
original image can load. It reports staging separately from original-engine
acceptance. A publication followed by a durability/context failure remains in
place for explicit recovery; it is never silently deleted or retried over an
existing tree. No file path or database bytes appear in its public report.

The integrated host can retain this typed preparation object, only when its
assets root matches the host's actual resources root. Integrated startup still
refuses admission: no verified native key/open/schema outcome or observation
ABI is currently available. There is deliberately no caller-set boolean or
invented acceptance callback that can make a byte copy count as native success.
The separate fresh-container startup diagnostic continues to use the untouched
original bundle seed and no preferred downloaded master.

Remaining first-path proof is specific: establish the native language/prefix,
observe the actual selected file and original open/codec/schema result, then
reuse the original asynchronous initialization/cache owner. Do not invoke the
known close wrapper blindly: its underlying close can return5 for outstanding
statements, while the wrapper clears its cache regardless. Native acceptance,
first home, real battle and Creator units in that battle remain unverified.

This cohort used manual source review and whitespace checking only. No new
runtime test, C/Objective-C compilation, app build, game launch, real save,
User folder contents, signing material or private key was accessed. Source
inventory automatically includes the new Objective-C module; no build was run.
