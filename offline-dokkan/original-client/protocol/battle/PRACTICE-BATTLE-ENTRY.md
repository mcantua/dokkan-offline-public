# Original fixed-loadout practice entry

The native bridge is `duo/ODDuoPracticeBattle.mm`. A manually selected practice
battle reuses the current master's phase3 encounter, temporary player cards,
enemy stats, Ki tables and original combat Scene. It does not play the intro,
claim ordinary quest fidelity, charge ACT, grant rewards, or change Core-owned
cards/teams. Ordinary quests and Creator combat remain unfinished requirements.

The loader creates the bridge from its same verified image snapshot after
`dlopen`. Seventeen unique body-hash/function-size identities at actual
`LC_FUNCTION_STARTS` entries resolve its callables. Loaded bodies must still
match before entry. No private header, key, codec or original game data is added
to authored source. The host must bind a real manual native action and obtain
unchanged JSON from `ODOriginalPracticePhaseProvider` using its current selected
master/Core context. This is not a WebView/URL-controlled arbitrary scene API.

The bridge admits only the actual original Home Scene, with no pending
transition and no stopped/paused engine. It constructs the original192-byte
Json::Reader and40-byte Json::Value, uses the original byte-range parser, and
uses original constructors/destructors. The input bytes remain alive through
setup. The fixed-parameter method copies the phase data into original
InGameData; its own receiver is unused. Its original card setup has an explicit
same-ID fallback for the fixed borrowed loadout. These are temporary battle
objects, not permanent starter grants.

Before setup, the bridge also checks the already-existing native model class
and its actual collection getter, then calls the original owned-card lookup
for the fixed card IDs. A hit or unavailable cache rejects practice. Its
returned16-byte native shared ownership is released through the returned
control block using the matching Apple `std::__1` ABI; no deleter is invented.
The short getter is bound through the actual model vtable, rather than
assuming that an8-byte compiler-generated getter has a unique body hash.
The separate Core collision guard remains conservative evidence, not proof
that the live native collection is empty.

The original battle Scene factory creates the real InGameLayer. Its callback
setter copies the source's32-byte Apple libc++ `std::function<void(Node*)>`
contract; the bridge has a compile-time size gate. The original Director handles
Scene replacement/refcounts. The replacement completion returns through the
original Home factory with its non-login mode, following volatile puzzle/ability
cleanup. It deliberately omits the tutorial `FINISHED_BATTLE` event and original
checkpoint-unlink helper. It does not call the ordinary Core run/finish APIs.

Static completion is not runtime acceptance. The bridge, phase provider,
loader capability and manual action must be compiled together, then the actual
client must prove entry, playable Ki controls/attacks, victory/defeat callback,
return Home, and unchanged owned teams/progress. Resource availability, native
practice checkpoint behavior, return lifecycle and callback ABI still require
that device run. The first diagnostic IPA predates this bridge and proves none
of those behaviors. No in-app practice image exists yet.

Scope receipts and exact hashes are in `practice-entry-evidence.json`. The
8-byte callback setter follows a148-byte assignment body. The84-byte battle
initializer follows a952-byte base implementation. Reader cleanup outputs also
followed a76-byte allocation helper. These actual footprints are recorded;
requested wrapper sizes are not presented as the complete inspected scope.
