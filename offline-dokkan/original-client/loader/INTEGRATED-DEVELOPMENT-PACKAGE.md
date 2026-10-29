# Original-client integrated development package

This extends the successful diagnostic assembler with the existing genuine
shell, engine, original resources, framework, native seed, Duo scene policy,
FD-preserving copy and publication checks. It is **Diagnostic (integrated development)**, not playable.
No native master acceptance, original frame, login or gameplay is inferred.

The exact package identity is `org.offlinedokkan.duo`; the display name is
`Dokkan Duo Diagnostic`. Use its own app container. No existing player data,
Sparking identity, provisioning or signing material is included.

The component source inventory includes Objective-C++ `.mm` units. They use
actual Apple C++17/libc++, with ARC and the bridge's compile-time callback ABI
assertion; C and Objective-C flags are unchanged. Linking includes libc++ only
when a `.mm` source is present. The source receipt records that language/runtime
selection, and assembly includes `.mm` in the clean-source/freshness gate.

The component must come from the same frozen clean HEAD as assembly, with
`original_startup_entry_enabled: true` and the diagnostic flag false. The
concrete `ODUnifiedDuoNativeFactory.m` and original startup constructor must be
present in the component source manifest with matching hashes. The normal
factory/host native master gate remains in place; packaging cannot bypass it.

`integrated-development-package-source.json` adds only:

- Exact immutable canonical Core `OriginalClient/Core/reference.db`:
  114827264 bytes, SHA256
  `1a8f5a823a6efa7343ff463b92197a574898e03569e2067f3daf8a4f282be4f4`.
- Exact immutable opaque source candidate
  `OriginalClient/NativeCandidate/en/database.db`: 114827264 bytes, SHA256
  `f37296ef05e31000d9868741b18525a5d41311ccc152acb82c848b7b1c8ef14d`.
  Its `en` label comes from the Android export. It is not an observed original
  iPhone language selection or proof of compatible native opening.
- The native same-Core Creator frontend under `site/`, generated only with
  `python3 offline-dokkan/creator-ui/build.py --original-client`. The pinned
  `ui-manifest.json` must identify the same source HEAD and generator hash;
  every file is copied with SHA verification. The original-client flag must be
  true, gameplay harness false, and bundled game databases false. Files remain
  read-only; private data and generated database snapshots are excluded.
- The two exact authored protocol files at `OriginalClient/Protocol/` required
  by the factory. Their fixed source paths, sizes and hashes are in the contract.

The plaintext Core reference is not a compatible opaque native preferred
master. The original 535552-byte bundle `database.db` stays at its original
fallback location. The assembler publishes none of these inputs to
`sqlite/current`; it creates bundle resources only. The cold-start adapter may
create an exclusive own working copy of the opaque candidate on a fresh
installation. It must preserve existing working state. The original engine
selects its actual language and accepts or rejects that candidate. Native
language selection, compatibility and full-schema acceptance remain unverified.

The existing registered workflow entry ID `400826915` now accepts
`entry_mode=integrated-development` (default remains `diagnostic`). It invokes
`build-components.sh --original-startup-entry` with the genuine SDK27.1 cloud
runner. The build recipe rejects an unfinished native factory before compilation.
Only the authored library and source receipt enter the GitHub artifact.

```text
gh workflow run 400826915 --repo mcantua/dokkan-offline-public \
  --ref REVIEWED_TOPIC_REF -f approved_source_commit=FROZEN_FULL_SHA \
  -f entry_mode=integrated-development
```

Wait for the integration lead's frozen SHA before dispatch. Preserve the same
frozen worktree for assembly. Add these options to the existing diagnostic
assembler's exact pinned resource/component arguments:

```text
--profile integrated-development \
--core-reference /ABSOLUTE/IGNORED/PRIVATE/IMMUTABLE/reference.db \
--native-candidate /ABSOLUTE/IGNORED/PRIVATE/IMMUTABLE/Current-export-master.db \
--creator-site /ABSOLUTE/FROZEN/WORKTREE/offline-dokkan/creator-ui/site \
--creator-site-manifest-sha256 EXACT_UI_MANIFEST_SHA256
```

Use a new absent `.app` output below that worktree's ignored private folder.
The existing `package_diagnostic_ipa.py` admits both explicit receipt profiles
and retains the Diagnostic (integrated development) label in its output. Unsigned packaging does not
establish installation, rendering, login, battles, saves or Creator integration.

The practice/resume/opaque-source candidate batch compiled successfully in
run `40958701574` from `8be14517dd4bd00e3da747b07a87a26f4493d136`
(71 units) and produced the unsigned integrated diagnostic. The subsequent
original request codec, POST teams and retained Creator-site changes await
the next combined compilation and assembly. No integrated package is signed,
installed or executed. Reuse prior original-resource evidence; no repeat
original resource staging is needed.

Stage the native Creator UI after the integration lead freezes the next commit,
before its app assembly. This is a local source-only staging operation, with no
database download, game-byte transformation, compiler or separate IPA build.
Use the original-client output, **not** `unit-creator/web/site-ios` or the
browser test page: those standalone adapters expect their own database paths.
The retained native controller serves `site/index.html` at `app://local/`, and
`host-adapter.js`/`ios-tools-adapter.js` bind the selected game's same native
Core, scope and Creator services. `core.js`, `sparking-dependencies.js` and
`runtime-forge.js` also supply the existing trusted native validators.

Generated `site/` stays ignored. Its staging manifest, complete inventory and
all member hashes are admitted before publication. Unknown files, raw database
or game archive files, protected trees, harness resources and source symlinks
are rejected. The assembler holds the site directory FD and checks its identity
throughout the existing copy/publication sequence. Package receipts keep
`creator_ui_runtime_verified: false`; frontend inclusion alone does not prove
that a custom unit has worked in an actual original battle.
