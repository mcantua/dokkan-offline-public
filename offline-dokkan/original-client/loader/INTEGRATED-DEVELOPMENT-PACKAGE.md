# Original-client integrated development package

This extends the successful diagnostic assembler with the existing genuine
shell, engine, original resources, framework, native seed, Duo scene policy,
FD-preserving copy and publication checks. It is **Diagnostic (integrated development)**, not playable.
No native master acceptance, original frame, login or gameplay is inferred.

The exact package identity is `org.offlinedokkan.duo`; the display name is
`Dokkan Duo Diagnostic`. Use its own app container. No existing player data,
Sparking identity, provisioning or signing material is included.

The component must come from the same frozen clean HEAD as assembly, with
`original_startup_entry_enabled: true` and the diagnostic flag false. The
concrete `ODUnifiedDuoNativeFactory.m` and original startup constructor must be
present in the component source manifest with matching hashes. The normal
factory/host native master gate remains in place; packaging cannot bypass it.

`integrated-development-package-source.json` adds only:

- Exact immutable canonical Core `OriginalClient/Core/reference.db`:
  114827264 bytes, SHA256
  `1a8f5a823a6efa7343ff463b92197a574898e03569e2067f3daf8a4f282be4f4`.
- The two exact authored protocol files at `OriginalClient/Protocol/` required
  by the factory. Their fixed source paths, sizes and hashes are in the contract.

The plaintext Core reference is not a compatible opaque native preferred
master. The original 535552-byte bundle `database.db` stays at its original
fallback location. Neither database is published to `sqlite/current`. Native
acceptance and a compatible opaque preferred-master input remain separate
unresolved work.

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
--core-reference /ABSOLUTE/IGNORED/PRIVATE/IMMUTABLE/reference.db
```

Use a new absent `.app` output below that worktree's ignored private folder.
The existing `package_diagnostic_ipa.py` admits both explicit receipt profiles
and retains the Diagnostic (integrated development) label in its output. Unsigned packaging does not
establish installation, rendering, login, battles, saves or Creator integration.

This integrated profile has not been dispatched, assembled, signed, installed
or executed. Reuse the already successful diagnostic build/resource evidence;
no new app test or repeat resource staging is required for this source change.
