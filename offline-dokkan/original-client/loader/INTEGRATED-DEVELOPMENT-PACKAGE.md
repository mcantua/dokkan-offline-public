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
--native-candidate /ABSOLUTE/IGNORED/PRIVATE/IMMUTABLE/Current-export-master.db
```

Use a new absent `.app` output below that worktree's ignored private folder.
The existing `package_diagnostic_ipa.py` admits both explicit receipt profiles
and retains the Diagnostic (integrated development) label in its output. Unsigned packaging does not
establish installation, rendering, login, battles, saves or Creator integration.

The earlier integrated factory compiled successfully in run `40956206387`
from `e625d787fad552597f3502692fe94e4149e82ed0` (68 units). The current
combined practice/resume/opaque-source candidate batch has not been compiled
or assembled. No integrated package is signed, installed or executed. Reuse
the prior original-resource evidence; no repeat resource staging is needed.
