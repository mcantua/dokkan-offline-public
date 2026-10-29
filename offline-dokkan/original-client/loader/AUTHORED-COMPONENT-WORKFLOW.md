# Manual cloud original-client component build

`.github/workflows/original-client-diagnostic-components.yml` is prepared source
for one authored-library build. The diagnostic entry compiled successfully on
October 29 from source `5b695bd18613e7cafaea5588ce8bf324eb2c3d5e` in
[run 40953446345](https://github.com/mcantua/dokkan-offline-public/actions/runs/40953446345)
(67 native translation units). Earlier compiler failures were corrected before
that successful run. The new integrated-development selector has not run. Tin's latest standing instruction authorizes ongoing
Duo builds and removes the old repeated **“make the builds”** permission gate.
No additional build permission question is required. Diagnostic artifacts
still must never be labeled playable without actual original-game acceptance.

The recipe has `workflow_dispatch` and a local reusable `workflow_call` entry.
The registered `.github/workflows/unit-creator-finish-only.yml` path is now a
manual-only thin wrapper for the new recipe; it no longer runs the old WK test
or responds to intent-file pushes on this topic. The callee still requires the
outer event to be manual. Source pushes, pull requests, other workflow
completions and schedules cannot start it. It requires the full reviewed
source commit matching the selected workflow ref. A small request gate
completes before the Apple runner is used.
The checkout uses that exact commit with no persisted GitHub credentials, and
must be clean. The workflow has read-only repository permission.

The requested Apple runner is the official GitHub-hosted `xcode-27` arm64
preview label. This was checked through the GitHub connector against the
official [runner image index](https://github.com/actions/runner-images/blob/9329c776c4a38d3dcb31fc78b8180005041c07fb/README.md)
and [exact image inventory](https://github.com/actions/runner-images/blob/9329c776c4a38d3dcb31fc78b8180005041c07fb/images/macos/xcode-27-arm64-Readme.md)
on October 29. Image `20261026.0314.1` lists Xcode27.1 build27A9275 at
`/Applications/Xcode_27.1.app` and device SDK `iphoneos27.1`. The normalized
source receipt is `authored-component-runner-reference.json`. No other
reference document was used for this selector decision, and none of these
three requested official documents was inaccessible.

Recheck those official sources before a future dispatch. A label copied from
an old local workflow is insufficient cloud evidence; an unknown/self-hosted
selector must remain blocked until separately reviewed. The published listing
does not guarantee a runner is currently allocatable. The future job must
also report actual Xcode27.1 and device SDK27.1 or stop, without downloading
Xcode, changing SDK fields or substituting a simulator SDK. A runtime
`RUNNER_ENVIRONMENT` assertion would occur after code had already started and
cannot authorize using Tin's Mac. This recipe selects the verified official
cloud label instead, and does not use his Mac, phone, Wi-Fi or hotspot.

The default `entry_mode=diagnostic` compile invokes the existing
`build-components.sh --original-startup-diagnostic-entry`.
`entry_mode=integrated-development` selects `--original-startup-entry`; the
factory must be source-complete and the integrated constructor enabled. The
native master gate remains intact. Both profiles are explicitly unverified;
see [INTEGRATED-DEVELOPMENT-PACKAGE.md](INTEGRATED-DEVELOPMENT-PACKAGE.md). That recipe fetches
the pinned public SQLite dependency if needed and compiles authored source to
an arm64 library. The workflow does not retrieve Drive, original game data,
APKs/IPAs, extraction parts, resource caches, account configuration, saves,
provisioning or signing keys. It does not create a simulator, execute a test,
run original code, assemble an app, sign an image, install anything or build
another platform.

The exact output allowlist is:

- `OfflineDokkanHost.dylib`
- `component-build.json`

The build receipt must identify the reviewed commit, genuine device SDK27.1,
arm64/16.4 target and the selected mutually exclusive entry flags. The
library's size/SHA must match that receipt before upload. No failed/partial
build is uploaded. No compiler log, database, original executable, app, IPA,
directory wildcard or private environment/config file enters the artifact.
The uniquely named authored-only artifact has one-day retention. It is an
unsigned component, not an installable or playable game. Ordinary public
repository artifact visibility must therefore remain limited to these authored
bytes and public source hashes; private original game content stays in Drive
and the ignored cloud workspace.

After the integration lead freezes the reviewed source SHA, choose that topic
ref and supply its full SHA. Do not merge the protected base branch or dispatch
an unrelated workflow.
Before the first dispatch, confirm that GitHub has registered this workflow
and allows that topic ref. The official
[workflow_dispatch reference](https://github.com/github/docs/blob/2251b1ed734802304c8df15fc529742fae4d762a/data/reusables/actions/workflow-dispatch.md)
was also read: it requires the workflow file on the default branch before the
trigger receives events. This source task did not establish default-branch
registration for the new recipe, change repository settings or authorize a
protected-branch merge. Read-only repository/API checks confirmed default
branch `main` and existing active workflow ID `400826915` for the registered
wrapper path. The concrete intended dispatch uses that existing workflow ID
with the reviewed topic ref, loading the wrapper and its local reusable recipe
from the same frozen source. No base/default-branch merge is needed for that
route. The successful diagnostic run above confirmed this registered wrapper
and exact frozen source dispatch without a base/default-branch merge.

The integration lead will use the existing authenticated cloud GitHub CLI;
no credential value, signing file, Mac or private original input is involved:

```text
gh workflow run 400826915 --repo mcantua/dokkan-offline-public \
  --ref REVIEWED_TOPIC_REF -f approved_source_commit=FROZEN_FULL_SHA
```

Dispatch must wait until the lead supplies that frozen SHA. Verify the returned
run's `head_sha` equals it. A rejected dispatch is a workflow metadata/input
problem, not permission to merge a protected branch, run an old test or select
another runner.
Download the resulting two files into ignored private cloud inputs, verify the
library against its receipt, and record the exact receipt SHA before using the
reviewed `assemble_diagnostic_app.py` source. Its exact profile, component freshness and input/resource checks still apply.

Keep compilation and assembly on the same frozen reviewed HEAD. The assembler
intentionally rejects a component from a different commit, even if intervening
commits changed documentation only. Commit source changes before building;
record later build notes after assembly rather than triggering an unnecessary
repeat compile. An old artifact can be removed only after its replacement is
downloaded and verified. This workflow does not delete prior artifacts or
publish releases, and no automatic synchronization is claimed.

Diagnostic native compilation/linking is verified by the run above. Actual
original-client dyld startup, the original first frame, offline login,
game/save/Creator behavior and both Duo displays remain unverified.
Compilation establishes source/toolchain compatibility only.
