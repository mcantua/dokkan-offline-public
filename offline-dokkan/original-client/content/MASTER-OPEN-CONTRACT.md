# Supplied iPhone master database contract

The actual main executable and Sparking patcher have different database-opening paths. Static inspection is recorded in `../../research/original-master-main-contract.json` and `../../research/original-master-patcher-contract.json`. The original client was not executed.

The main executable builds `sqlite/current/%s/database.db`, prefixes its native asset root, and resolves paths through its resource singleton. It can fall back to bundled `database.db`. Its master singleton caches the handle at object offset `0x10`; a separate close/reopen function closes and clears that field. The resource resolver also caches path results. The internal open shim passes flags `6` (read/write plus create), then applies a native-produced opaque source key. Initial schema checks have a compatibility `3` retry. No key bytes were read, copied, or printed. The native asset-root return, actual opened file and runtime cache lifecycle remain unobserved.

The patcher explicitly builds `NSHomeDirectory()/Documents/assets/sqlite/current/<language>/database.db`, opens readonly with full mutex, applies its source key, then forces cipher compatibility `4`. Its separate `Documents/assets/User/sqlite/local/SPRK_Cards_Data.db` is a card cache, not the master. No User files were opened.

The restored plaintext master remains detached. Neither the patcher helper nor MAIN static references prove that redirecting original gameplay to plaintext is safe. No master redirect, key extraction, cache replacement, protection change or original-client execution was performed. Source cipher security settings in the receipts describe supplied code and are not adopted by authored components.

Development stopped for the requested Grok Bot handoff. Resume from these exact findings without repeating catalog, full-master restoration or source-material checks. Before integration, establish native root/key/cipher admission and cache ownership; preserve original encrypted source bytes and avoid sending MAIN's writable/create open to the only source copy.
