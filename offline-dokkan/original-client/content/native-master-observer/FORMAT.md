# Native observation and admission contract

`probe-format.h` is the exact internal memory layout. Header offsets are:

| Offset | Field |
|---:|---|
|0|8-byte `ODMOBS1\0` magic|
|8|version1|
|16|monotonic observation ticket counter|
|24|active original cached-open invocations|
|32|overlap observed; nonzero prevents admission|
|40|observation fault/collision; nonzero prevents admission|
|48|latest completed ticket|
|56|record size2048|
|64|16 records of2048 bytes|

At offset36864 is a separate2048-byte retained successful-schema witness. Its
published ticket is at40960. Empty-cache entry invalidates that ticket before
the original open. A successful new open copies its completed record there;
cached reuse never supplies a new schema proof or overwrites that witness. It
preserves the witness only while its manager/cache match the cached entry.

Record offsets: ticket0, manager8, entry cache16, preferred path/key result24,
fallback result32, final wrapper result40, last attempt48, path length56,
return cache64, path-valid flags72, resolved path80..1103 and completed ticket1104.
Results are signed64 values captured from the original low32-bit result.
Path length is at most1023 with a following NUL. Flags1 means a complete bounded
path copy. A consumer must reject an interior NUL rather than silently truncate
the declared length. No key argument/provider or database-handle contents are present.

This structure must never be serialized or returned to a page. A native reader
may expose fixed booleans/result codes and `preferred`/`fallback`/`unobserved`;
it may expose a logical same-cold-copy match, never raw paths or addresses.
The observation ticket identifies this probe invocation, not a native database
generation or an invented server/wire identifier.

Before reading, admit the exact derived file/recipe and actual mapped RX/RW
segments/code. Use bounded self-memory reads. Read the header and published
witness ticket twice around the witness copy; require active0, overlap0,
fault0, counter equal to latest completed ticket, stable nonzero witness ticket
and matching witness record/complete tickets. The retained witness ticket may
be older than the latest cached-reuse ticket. Then compare the
actual pinned manager/cache metadata with the captured manager/return cache
without dereferencing the SQLite handle. Require empty entry cache, final
wrapper result0, last successful attempted-path result0 and complete path.
Return1 supplies no new schema proof. Return16 supplies failure. A fallback
success cannot identify the preferred downloaded candidate.
The observer RW segment has image lifetime, unlike the SQLite handle. A reader
must use acquire ordering for its published counters/completion markers and
recheck them around bounded record copies; a pair of unrelated ordinary reads
is not a lifetime or publication barrier. No database-handle memory is read.
The successful original first/compatibility schema check is narrower than full
card-table usability or gameplay compatibility; report those separately.

For candidate admission, compare the captured filename privately with the
trusted cold-stage destination, and require last attempt `preferred`. Never
open a filename supplied by the observation. Reopen only the independently
trusted own destination with the existing no-follow directory policy and compare
its device/inode with the stage's retained working descriptor. Compare identity,
not the immutable ciphertext hash after the engine may legitimately write it.
Refuse deletion/replacement, changed current cache or unproved lifetime changes.
No raw filename, inode, address, account data or database row crosses the report
boundary. A callback or file-stage boolean cannot substitute for these checks.

The runtime reader/cold-copy identity capability and loader admission are not
implemented by this recipe. Until that path consumes actual native execution,
`nativeMasterAccepted` remains false. First-open evidence also does not establish
an unrestricted hot-reload/Creator generation boundary.

The native value-only report should expose observation availability/busy/fault,
the actual wrapper result, preferred/fallback attempt, whether that same call
observed schema success, and whether the chosen file matches the bound cold
copy. The raw struct is never the public API. A nonzero pointer, copied path or
successful instrumentation recipe alone cannot supply these values.

Original native unwind tables remain byte-identical. New island PCs have no
newly proved async-unwind coverage during their temporary96-byte SP decrease;
the leaf's lack of C++ calls is not an asynchronous-unwind guarantee.

Signing contract: this recipe emits an unsigned derived engine. The existing
strict signature-envelope normalizer must first remove only an allowed appended
signature and restore unsigned header/LINKEDIT sizes to the exact derived
recipe, before inverse normalization to the original snapshot. Simply raising
the11224-byte command cap or trusting a JSON hash is insufficient. Unchanged
origin/practice/decoder resolvers should receive the verified restored original
snapshot while checking their unchanged loaded functions. The current master
observer's full316-byte body hash intentionally changes and needs the separate
verified probe capability; it must not be silently disabled or treated as ready.
