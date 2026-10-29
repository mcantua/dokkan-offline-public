# Native verified resource preloading (source integration)

The actual original client uses a Foundation `fileExistsAtPath:` probe in its
resource resolver. A virtual `fopen` result alone therefore does not establish
resource availability. This module composes the existing exact-IPA admission
with physical publication before original-engine loading. It does not replace
the game engine, create an asset format converter, guess its runtime root or
claim that the current full scene dependency set is known.

## Trusted native configuration

`resource_preload.h/.c` owns a callable native preloader. Its constructor takes:

- An `O_RDONLY` regular catalog FD, its exact expected byte count/SHA-256, and
  expected manifest/IPA/bundle identities.
- Native-selected imported resource and private content-cache directories.
- Readonly directory FDs for the attested actual assets root and the own-app
  working boundary that contains it. The publisher's bounded ancestry guard
  stays inside this namespace and protects import/cache directories.
- A nonempty, unique set of canonical asset-root-relative required paths and
  a trusted native scope-currentness callback/context.

Paths and FDs come from native-owned configuration, not WebView messages,
client booleans, guesses based on `.app` paths or downloaded account caches.
The constructor copies the requirement strings, sorts them and uses binary
lookup when matching aliases. Counts are bounded at20,000. An empty/unknown
requirement set cannot become a success or boot-readiness claim.

## The admitted catalog is the exact captured FD data

The new `od_iphone_resources_open_catalog_fd` captures at most128MiB with
`pread`, preserving the caller's file offset. Before/after regular-file
identity, size and modification time must match. The existing SHA implementation
checks the exact captured bytes against the expected catalog hash. An ordinary
SQLite header and rollback-format read/write versions are required; WAL images
are refused, not edited.

Those same bytes become a `SQLITE_DESERIALIZE_READONLY` private memory database.
`query_only=ON` and `trusted_schema=OFF` remain in force; extension loading is
still omitted by the existing pinned component build. Expected metadata checks
match the legacy resource constructor. Assets and aliases are read from this
one immutable snapshot, without reopening a pathname or relying on `/dev/fd`.
Rename/replacement of an external catalog path cannot switch the admitted data.
The legacy path-based API remains unchanged.

The pinned dependency is the existing SQLite3.50.4 in
`downloads/sqlite-amalgamation/SOURCE.md`; no SQLite download/build was needed
for this source task. The existing build flags do not omit deserialize.
Ownership follows [official sqlite3_deserialize documentation](https://www.sqlite.org/c3ref/deserialize.html):
`FREEONCLOSE` owns the allocated buffer after success and frees it before
returning on deserialize failure. The code does not free it twice. The source
image is unchanged and32 zero padding bytes beyond its hashed length satisfy
the documented malformed-image padding precaution.

## Before any resource publication

`od_iphone_resources_visit_aliases` enumerates exact catalog aliases, with a
20,000-row cap. Each row passes the existing alias-to-canonical path/reference
validation. Unknown catalog aliases, malformed metadata and visitor aborts have
distinct fixed errors; no alias is silently skipped. The preloader matches
canonical references to the trusted required path set and checks conflicting
aliases. If any configured path is absent, it reports incomplete and publishes
nothing from that run.

Only after all configured requirements match does the preloader call
`od_iphone_resources_publish_asset` for each required path. That publisher
rechecks canonical preferred-entry/alias admission, scope-safe roots,
readonly/hash-verified bytes, no-overwrite and durability. Before each
publication and before returning, the preloader checks native currentness.

Earlier successful files remain intact if a later publication fails. The
receipt distinguishes configured/matched/missing counts, verified aliases,
new files, idempotently verified existing files, and a failed original
configuration index. A file linked before a subsequent directory-sync failure
is still counted as newly published, with the run failed for a safe same-name
retry. No mismatch or unadmitted Android resource is copied over an existing
file.

`configured_paths_complete` means only that this explicit configured set was
durably published. `original_engine_attached` and `gameplay_verified` always
remain false. The module does not discover every native scene dependency,
attach a master/codec, install file hooks, create an auth response, run a game
or grant overall bootstrap readiness.

## Integration point and evidence limit

The trusted native bootstrap composition should open the preloader and run it
on its serial preparation/content queue before loading the original image and
before that image can execute resource existence checks. Do not run bulk
hash/copy work on the renderer/main queue. The final dispatcher/factory and
complete dependency configuration are separate unfinished work; no fabricated
attachment is supplied here.

One focused source/export-inventory and whitespace check is the only check for
this cohort. Native C/SQLite execution, compilation, game loading, real probe
consumption, platform sandbox behavior and decoders remain unverified. When
builds are explicitly authorized, one focused native cohort should cover:
exact-FD snapshot admission after source-path replacement, source offset
preservation, readonly/wrong-identity/WAL rejection, exact alias enumeration,
missing requirements with no target writes, scope invalidation, and physical
publication/idempotent retry. Reuse prior unchanged source-identity evidence;
do not rerun unrelated suites.
