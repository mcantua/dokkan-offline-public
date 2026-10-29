# Unified Duo source integration draft

Tin resumed ChatGPT with “take over” on October 29 and reconfirmed the
foundation: his supplied Sparking/original Dokkan client, offline, with agreed
edits and the full Unit Creator built in. Preserve the original screens,
combat, artwork, sounds and animations. The account launcher and authored
battle harness are not the production game or gameplay evidence.

## Source boundary

Repository: `mcantua/dokkan-offline-public` only.
Topic: `chatgpt/duo-source-integration`.
Base pin: `220d7bbc7ebd535692b3dfc7f980c928cf04f267`.
Nothing was merged into the base or pushed into another workstream.

This topic combines the relevant authored source from the following draft
snapshots. It does not import their workflow changes, App Installer changes,
old handoff replacements, native test-run scripts or original game bytes.

| Draft | Source pin | Included source |
|---|---|---|
| #1 | `bc10bf122fdbb93ec74cf7aa410c605bcb7c552c` | Auth reader-relative candidate, closed HTTP routes and fresh-state policy |
| #2 | `2969c2debbd48d25af798bcaa368e2b9ba4d56fd` | Native full-bundle validator and same-account Finish |
| #3 | `616a40475f57c0161f4c98df4f3377dbaa1ee3f6` | Existing launcher/account components and Creator UI changes |
| #4 | `480ebdc6f87b54895fc0665c01fcd765b3ae8594` | Master staging, late services, Creator menu and scoped Player control |

The source was applied with three-way conflict resolution. The combined
`ODUnifiedDuoHost` retains both auth/fresh-state APIs and deferred Creator
binding; unverified `/auth/nonce` and `/auth/sign_in` success routes stay
closed. The controller retains the launcher close-label property and gives
original-game Menu return semantics priority while in the real engine.

## Corrections in this topic

- Native full validation now agrees with Session preparation for optional
  `awaken:false`, `awaken:null` and numeric zero. Actual awakening requests
  still reject this new-unit Finish flow. Default Forge projects omit the
  property, so this was not a failure of every default unit.
- Required late scene attachment happens before lifecycle installation or
  committing services. A failed attachment returns its error and leaves
  pending admission available for the same trusted service to retry. No scope,
  content or scene admission was relaxed.
- Auth rejection uses its own host error code. Master-stage errors no longer
  receive the auth-envelope message after the two drafts are combined.
- Replaced the obsolete unresolved growth-precision statement in the original
  client README with the exact scope of Grok's recorded Finish evidence.

## Verification and limits

One focused source check passed: changed JavaScript syntax, patch whitespace
and absence of conflict markers. Staged privacy verification is required by
the commit hook. No compiler, native check, simulator, runtime test, HTML build,
APK/IPA, dependency installation, Mac, PC or personal connection was used.
Nothing under a `save/` folder, the signing key or private configuration was
opened or changed. Native fixes are source-reviewed, not runtime-verified.

Grok's earlier run40891656259 is retained only for its original hosted Finish
scope. It does not validate this combined branch or a full unit.

## Pending production work

- The engine's real master open/resource root remains unverified. Published
  plaintext and readonly receipts are staging evidence. MAIN's own keyed
  open/cached handle is not redirected; no Sparking key is included.
- `prepareNativeEnvironment:` records an asset-root mismatch but does not make
  an observed match an integrated startup requirement. Resolve this using the
  actual native resource-path contract; do not guess a root or claim an
  original-engine database attachment from the staging flag alone.
- The true auth success envelope and fresh-account tutorial/capacity contract
  are still unresolved. Never install a fabricated success response.
- The PR #3 account launcher is a component/internal host. Its account summary
  is not the original game's home screen, battle or completed production
  entrypoint. Bind the trusted original-engine composition before delivery.
- When builds are explicitly authorized, verify the combined native cohort
  once. Include full Finish false/null handling and a failed service attachment
  followed by successful retry; existing C admission checks do not exercise
  the Objective-C side-effect ordering.
- Real offline battles, full custom abilities/resources/forms, progression,
  installation and both physical Duo displays remain unverified. Ordinary
  iPhone and Android stay paused.

## Preservation

STATUS is mirrored to the existing Drive file
`1eJk2p1RvCmrt8QZOK65ITgW5VZZowf--`. Update the existing Source file
`1HpVONnER2Mh8-3ywtLc01h5kXEjYybo0` in place with the committed public-source
archive after publishing. Do not create another backup or overwrite the
separate game-data, tools, signing or recovery objects. The frozen private
GitHub repository remains untouched. Record completed transfers in STATUS.
