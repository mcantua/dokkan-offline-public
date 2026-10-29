# One original Offline Dokkan game

The main screen has one player and no Eclipse/Sparking mode selector. Those names appear only in the data-source setup action and internal provenance. The immediate implementation uses one validated active source database; merging sources needs ID/relationship validation and is not performed by concatenating their tables.

`active-master.plist` records the exact active source and content identity. The single `player.db` and `creator/workspace` belong to Offline Dokkan. Importing incompatible source data never creates another player or overwrites progress: it reports that a compatibility update is needed. The native core also checks the content identity when reopening.

An unambiguous earlier development player is adopted only when its recorded content matches. SQLite backup includes a consistent source WAL and publishes a fresh canonical copy without replacing any existing player. The earlier save is preserved as the one recovery copy. If both earlier players exist, or the source does not match, recovery is required; neither earlier file is merged or deleted. An earlier selected-source Creator workspace moves intact into the canonical workspace only if no canonical workspace exists; other source workspaces remain untouched.

One focused actual SDK16.5 syntax check covers these Objective-C changes; genuine hosted Duo execution is pending. The prepared native scenario now checks no source-mode selector, canonical player reopening, incompatible-source rejection preserving that player, the real master importer, and the shared Creator Finish/reopen flow. This is a native foundation, not a claim that playable battles are finished.
