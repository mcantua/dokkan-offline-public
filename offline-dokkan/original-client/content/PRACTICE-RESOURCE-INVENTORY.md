# Original practice resource availability

The phase-3 practice bridge enters the original battle directly. It does not
enter the ordinary sugoroku board. The previously missing ordinary TMX map pack
is therefore not an established dependency of this practice battle.

The restored original iPhone resource set already contains card and
battle-character packs matching the fixed loadout's metadata, a matching-number
background candidate, and a BGM wave bank matching the phase's source ID.
That wave bank is already among the 27 verified native
Documents aliases. These original iPhone packs remain preferable to Android
replacements: the corresponding Android character/background packs have
different hashes, including one background with the same size.

Availability is distinct from native lookup. The original resources retain
their `tutorial0/` bundle paths. The exact native search-path resolution and
background filename formatter still need source or runtime evidence; their
paths must not be flattened based on similar filenames. The master's battle
map row also has a separate background-image ID, so the phase map ID alone
does not establish a resource filename.

One precise small extraction candidate is `assets/bgm/bgm_149.acb`, 6,752 bytes,
SHA-256 `b8fdb8cdb5a942cbda5beafd85d5eb072eab63e14b7f2c599da9b1d4f86f8248`.
It exists in the supplied Android export metadata and is absent from the
restored iPhone set. The current evidence has not proved that the original
practice audio path requires this particular cue archive or that these Android
bytes are compatible. It is a conditional candidate, not an admitted download
or a reason to copy all Android assets.

The focused private inventory records source database relationships, exact
original/Android paths and pins, and existing alias membership at
`private/research-assets/phase3-practice-resource-inventory.private.json`.
This pass used retained metadata and readonly master rows. It performed no
downloads, extraction, resource publication, build, test, or key/save access.

The subsequent bounded native search review is recorded in
`practice-resource-search-source.json`. The actual FileUtils constructor and
platform initializer retain the native bundle and initially add an empty
search suffix. They do not themselves add `tutorial0/`. The existing full-path
resolver iterates native search/resolution vectors and checks real platform
existence before caching success. Later search changes still need their actual
caller; an empty initial suffix alone does not prove a missing resource alias.

The filesystem constant is now identified as
`FileUtilsCustom::TUTORIAL0_DIR`. Its two short native consumers construct
`<own-app-bundle>/tutorial0/` and the `tutorial0/<filename>` variant of the reviewed
Documents/assets prefix. The first getter's exact own-body selector chain is
`NSBundle.mainBundle.bundlePath`, append `/`, then `UTF8String`. Restored packs
already occupy that correct bundle location. Neither helper alone proves which
variant phase 3 selects or an automatic fallback. Localization keys
containing the same word were excluded from this conclusion.

The separate optional native observation in
`NATIVE-RESOURCE-LOOKUP-OBSERVATION.md` can check actual initialized-engine
resolution and expected own files without turning source research into a new
startup gate. No canonical alias has been added based on these partial facts.
