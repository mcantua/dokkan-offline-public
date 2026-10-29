# Original-client Duo diagnostic package source contract

`diagnostic-package-source.json` describes one eventual original-client
diagnostic app. `assemble_diagnostic_app.py` implements its unsigned Linux
cloud assembler source. It has not been executed or tested; no app, IPA,
native compile, signing or device run was made for this contract. Tin's
**“make the builds”** instruction is required before using the compile/package
steps. This target has no offline auth success routes and cannot be offered
as a playable build.

The existing `build-components.sh` produces an authored library only;
`inject_shell.py` prepares an active shell only. Neither creates a complete
app. `unit-creator/cloud-ui/package-device.sh` builds older, separate products
and must not be used as an original-client package or modified into one by
substituting its version/SDK metadata. The cohesive assembler reuses the
existing resource admission, FD-relative staging/publication and shell
injection APIs. It takes an explicit `--make-the-builds` operator flag; that
flag does not itself grant authorization.

The future assembler must take the verified private resource staging output,
its exact extraction manifest and reviewed SHA receipts. Reverify every
member, and copy `bundle/` into an absent, own diagnostic app bundle without
flattening paths. This preserves all 1,067 selected original resource
candidates, root/tutorial distinctions, exact framework `Info.plist` and
binary, opaque app-root seed, and authored catalog/cache payload. The sibling
staged `documents/` tree is a preparation artifact and must not enter the app
bundle or an existing device container. Native cold publication makes working
copies through the existing admitted catalog instead.

Add the unchanged genuine shell baseline at
`OriginalClient/OriginalGenuineDuoShell`, the reviewed injected active shell at
`OfflineDokkanStartupDiagnostic`, the prepared original engine at
`Frameworks/OriginalDokkanEngine.dylib`, and the authored library at
`Frameworks/OfflineDokkanHost.dylib`. Require the component-build receipt to
prove the diagnostic entry was enabled and production entry disabled; merely
linking the default inert component library cannot install the startup host.
Verify exact pre-signing hashes before copying. Preserve the immutable input
trees, and refuse overwrite, symlink, unlisted payload or collision with a
resource member.

The component receipt's `source_commit` must equal the current reviewed
repository HEAD. Relevant authored compilation units, headers and build recipe
must be committed and clean, including untracked source refusal. A fixed
literal allowlist of critical diagnostic/loader/transport/scene/resource source
hashes must also match that component's source manifest. The assembler never
opens a path supplied by the receipt's source list. This refuses an older
diagnostic library whose entry flags still happen to match; freshness alone
does not establish successful compilation or runtime behavior.

The original Adjust binary and its original framework metadata must remain
together at `Frameworks/AdjustSigSdk.framework`. The extraction manifest owns
the metadata hash; do not invent a replacement `Info.plist`. Static inspection
of the exact retained shell establishes its `@executable_path/Frameworks`
rpath, while the prepared original engine names
`@rpath/AdjustSigSdk.framework/AdjustSigSdk`. The package locations match those
actual load commands. This does not establish successful dyld loading or SDK
startup behavior.

Generate the own app `Info.plist` from the explicit authored fields in the
contract. Require an approved version/build as explicit package inputs.
Never copy original app identity, provisioning, entitlements or signatures.
The own identity is exactly `org.offlinedokkan.startupdiagnostic.duo`, and the
app must use its own fresh container. The shell's actual scene-configuration
method is replaced by the reviewed bootstrap, so changing plist text alone
is insufficient: the diagnostic-enabled library must load before main and
select `ODDuoOriginalSceneDelegate` with the retained real AppController
provider. The original window/renderer lifecycle stays under that bridge.

Keep the baseline and opaque seed unchanged as resource data. Final signing
must later use normal Apple policy on embedded executables/frameworks and
then the own app, without exposing or reading signing material here. The
native bootstrap validates active shell code identity while admitting its
reviewed injected command and signing changes; the prepared-engine loader
likewise admits only its documented signing normalization. Do not rewrite SDK
fields to imply a different native compile or use an ad-hoc signature bypass.

The exact compatible catalog/cache is cold-staged on one preparation queue
into actual own Documents before original `dlopen` and its initializers.
Existing native `assets/User` or `assets/sqlite/current` is refused without
reading it. The bundle seed remains the original fallback; never install it
as the preferred downloaded master. No plaintext master, player data,
signing file, full IPA/APK, resource part archive or internal harness belongs
in this diagnostic payload.

When builds are explicitly authorized, first obtain the genuine diagnostic
component library through the existing component recipe. Then provide these
assembler arguments, all as private cloud paths and reviewed exact hashes:

```text
--staged                  verified original-resource staging root
--manifest                original resource extraction manifest
--manifest-sha256         reviewed exact extraction manifest SHA-256
--staging-receipt-sha256   reviewed exact staging-receipt.json SHA-256
--shell                   unchanged pinned genuine SDK27.1 baseline
--engine                  pinned prepared original engine
--component               freshly authorized diagnostic authored library
--component-receipt       that library's component-build.json
--component-receipt-sha256 reviewed exact component build receipt SHA-256
--version                 explicitly approved three-part version
--build                   explicitly approved positive build number
--output                  absent own diagnostic .app below ignored private/
--make-the-builds          record the current explicit build authorization
```

The assembler re-hashes the full admitted original resource layer and checks
its exact file inventory before copying, uses source descriptors with
currentness checks, prepares the active shell through the existing reviewed
`inject_shell.inject` API, then publishes an absent `.app` with FD-relative
`RENAME_NOREPLACE`. The injection paths use retained Linux `/proc/self/fd`
directory anchors. If an ancestor changes, success is refused; an unrelated
tree is never overwritten. Only an owned unpublished stage may be removed.
Executable images gain execute permission; the unchanged baseline and opaque
seed remain read-only data. The receipt identifies an unsigned diagnostic,
with device/startup/login/gameplay flags false. No IPA ZIP or signing operation
is performed by this assembler.

Actual complete scene dependencies, normal signing, original dyld/startup,
first render, offline login, gameplay, save behavior and both Duo displays
remain runtime acceptance work. The selected resource candidate set is a
preserved source inventory, not proof that every startup dependency is present.
