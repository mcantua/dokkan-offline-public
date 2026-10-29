The integrated entry now calls `ODCreateUnifiedDuoStartupHost` in
`ODUnifiedDuoNativeFactory.m`. It uses only the actual `org.offlinedokkan.duo`
bundle and the typed shared native startup preparation. The diagnostic identity
and entry remain separate.

The factory verifies the exact bundled plaintext Core reference, retains its
readonly file identity, and creates one canonical Core and one deferred player
capability. Preparation runs on native IO through that same Core's owner queue;
the real profile/content/save scope returns on main after the ordinary main loop
starts. The factory then creates same-Core scoped Creator services and the
hash-pinned resource projector on IO and binds them to the actual Host on main.
No source account, starting collection, guessed save scope or second Core is used.

The Host initially installs deny-all Foundation transport before loading the
admitted original engine. Its source-bound native configuration can arm the
reviewed routes once before actual AppDelegate requests. Local ping/nonce/sign-in
handlers remain Host-owned and obtain current same-Core snapshots. The local
one-hour token lifetime is explicit offline policy, not a recovered server value.

Original engine/auth/UI initialization is allowed before observing native master
acceptance. The minimal persisted new-profile User DTO is independent of the
original engine's encrypted master. Full game data, teams/cards and Creator
mutations keep a separate native-master gate. The plaintext Core reference is
never staged as the original preferred MAIN database. A separately pinned opaque
source-export candidate has a distinct fresh-only path described below; no
native language selection, key or schema-acceptance result is invented.

Required integrated bundle additions are pinned in
`integrated-native-factory-source.json`. Existing original shell, engine, opaque
seed, dependency and compatible resource inputs use the same shared preparation
as diagnostic. The package must select `OD_UNIFIED_DUO_STARTUP_ENTRY=1` and leave
the diagnostic constructor disabled.

This is concrete composition source, not a playable acceptance report. Shared
original preparation now preserves own native User/current only when its exact
previously published native provenance receipt admits that same resource/root.
Unknown prior trees remain refused. Real resume, login/Home, battles, persistent
gameplay and both Duo displays still need actual original-client evidence.

On fresh own integrated startup only, the factory calls the native cold stager
with the separate fixed `OriginalClient/NativeCandidate/en/database.db` input:
114,827,264 bytes, SHA256
`f37296ef05e31000d9868741b18525a5d41311ccc152acb82c848b7b1c8ef14d`.
The stager independently publishes an exclusive working copy under the actual
own assets root. The label `en` comes from the supplied export asset path; it is
a compatibility candidate, not observation of the iPhone engine's selected
language or schema/codec acceptance. The engine retains its actual native
selection/open behavior and bundle fallback. The typed `knownIntegratedRelaunch`
capability skips all candidate staging/adoption on admitted relaunch, preserving
existing native User/current without opening or replacing their contents.

The first frozen factory cohort compiled and linked with the actual iPhoneOS
27.1 arm64 SDK in run `40956206387` (commit `e625d787`, 68 authored translation
units). Later failure-diagnostic changes retain the factory report even when
native inputs or Core/routes are unavailable, preserve specific Host failure
stages, and print fixed source stage names for early and asynchronous failures.
They never print arbitrary native error descriptions, paths, account values,
request bodies or origins. Compilation does not establish native launch/login.

The next source cohort connects the manual Practice Battle action to the real
engine. The existing loader resolves an optional practice capability from its
same admitted image snapshot after loading; missing pins keep practice closed
without preventing original auth/User startup. After real Core scope admission,
the factory creates the readonly phase provider from that same selected reference.
Only an explicit user action loads its unchanged phase JSON. The Host rechecks
owner/scope, real renderer/window, active scene and absence of an editor, then
passes this bootstrap's actual successfully launched AppController to the native
bridge. The bridge additionally admits only the real original Home scene with
no pending scene or paused/stopped engine. Creator and practice entries exclude
each other.

This uses the original fixed practice encounter and temporary native loadout.
It does not grant units, edit saved teams, award quest rewards, complete a
tutorial sequence or unlink the original ordinary-battle checkpoint. The
bridge's native finish callback requests the original Home scene. Actual battle
entry, combat completion and return still require device evidence; ordinary
quests and persistent gameplay remain separate unfinished requirements.

Original POST decoding is now connected through another optional capability
from that same verified loaded image snapshot. Finding source-matched functions
does not enable it. The Host supplies the actual original AppController to the
decoder's fixed own-JSON roundtrip; its actual initialized/current, active
original-engine guard with no pending scene runs before any opaque context
getter or codec invocation. An early/inactive/pending-scene attempt waits, one actual fixed
probe may run, and failure remains closed. The shared original request codec
has no Home-only contract, so opening the ordinary team editor first does not
create a hidden Practice Battle prerequisite. The opaque context is passed
only inside the original native codec and never inspected, stored or logged.

The resources adapter's decoder provider returns only the Host's currently
verified capability. POST `/teams` still requires its independent actual master,
Core/scope, clean projection, normalized payload and revision/commit guards.
There is no plaintext fallback, and the native own probe never uses request
bytes. A manual practice action may also attempt the independent fixed probe;
codec absence/failure does not block that action or original auth/User startup.
Actual self-check success, POST team mutation/response and relaunch persistence
remain runtime requirements. The report can refresh the existing bounded
native master observation on demand; cache presence does not open acceptance.

The subsequent cohort compiled 72 native units in run `40963117227` from
`20fd1d0`, including the original request decoder, POST teams and embedded
Creator files. The following changes are newer source and are not covered by
that compilation:

- Compact in-app actions reuse the existing original-scene readiness/invocation
  owners. Creator and practice still exclude each other. Actual practice state
  updates refresh the controls; a retained failed finish save exposes Retry Save.
- Read-only diagnostic sharing is configured separately from Core readiness, so
  a real active original window can export the allowlisted fixed failure state
  even when Core preparation failed. No file, upload or raw error is produced.
- Resources may wait once for actual initial same-Core service binding instead
  of failing because the asynchronous projector was not issued yet. This uses
  the existing bounded pending queue and the request's own timeout/cancellation,
  with no polling. Terminal preparation failure drains those requests. This
  covers a resources request independently of whether native auth ran first.
- A native practice session recomputes the unchanged phase bytes' hash, verifies
  their scoped source receipt, and durably records `prepared` before entry. The
  original finish callback alone invokes its same-Core saver. Native cleanup and
  Home return wait for `native-finish-observed` to commit. No win, reward, ACT,
  normal quest or tutorial completion is inferred. A failed/abandoned entry keeps
  its honest prepared record.

Unknown-commit practice retries retain their exact command, payload and first
revision. Core checks retained command/tombstone replay before checking revision.
Only its explicit `ORIGINAL_PLAYER_REVISION_CHANGED` rejection permits a new
intent on the next user retry after scope/revision revalidation. A pruned receipt
is a different error and never silently replays the operation. The one focused
Core ledger scenario covered migration, replay/lost response, stale revision,
scope, unchanged projection/gameplay data and reopen persistence. That verifies
the canonical ledger, not actual native combat or finish-callback delivery.

The retained 568-byte authentication transaction run unconditionally queues
nonce retrieval; only pre-auth ping is conditional. Local token expiry or a new
process therefore has a fresh-nonce path through that native transaction. The
authored issuer keeps tokens only in memory and never rejects canonical resources
because an old local issue expired. Actual foreground/client renewal ordering,
long-session login, native combat/finish save and device relaunch remain runtime
requirements; no new token persistence or invented renewal endpoint is added.
