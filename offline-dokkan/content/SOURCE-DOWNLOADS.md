# Data sources for our original Offline Dokkan

Eclipse and Sparking are database/asset providers used to develop and populate **one original Offline Dokkan game**. They are not selectable game modes or separate player accounts. Source labels on imported files identify their origin and format; they do not decide the game's name, player save or progression.

`source_downloads.py` is an explicit cloud/development utility. Nothing downloads at launch or while playing. It never creates or changes a player, chooses active game content, decrypts a database, extracts keys or contacts a login/account endpoint. The normal native setup and canonical-content migration remain separate work.

Show the fixed provider registry without any network request:

```sh
python3 offline-dokkan/content/source_downloads.py registry
```

Import the public plaintext Eclipse database into the ignored private development content library:

```sh
python3 offline-dokkan/content/source_downloads.py database \
  --source eclipse --library offline-dokkan/data/content
```

An optional `--sha256` pins an independently verified **download-byte** SHA256. The importer then creates and hashes a consistent, integrity/schema-checked SQLite snapshot; its normalized snapshot hash may differ from the source bytes. The source registry's older `game` column is provider provenance only in this utility. No `active` row is written.

The Sparking database endpoint is registered too. If its response is encrypted, the utility rejects it with `PLAINTEXT_MASTER_REQUIRED_NO_DECRYPTION`, deletes the temporary download and preserves existing content. It does not guess keys or silently treat ciphertext as a database. Use a legitimately obtained plaintext snapshot with the existing importer instead.

Download the public Sparking asset manifest explicitly:

```sh
python3 offline-dokkan/content/source_downloads.py manifest \
  --source sparking --library offline-dokkan/data/content
```

Its JSON result identifies the single content-addressed manifest file. To download a selected game resource, call `asset --source sparking --path RESOURCE_PATH --manifest MANIFEST_FILE --library offline-dokkan/data/content`. Only an exact manifest entry with a supported logical game path, URL, size and decimal xxHash64 is accepted. The public upstream `libxxhash` runtime must be installed for its streaming checksum; a missing runtime fails explicitly. No proprietary cryptography is involved. Both the manifest checksum and an independent SHA256 are calculated while streaming the resource.

For a resource whose size/SHA256 are already known from a verified local content manifest, use `asset --source eclipse --path RESOURCE_PATH --bytes EXACT_SIZE --sha256 SHA256 --library offline-dokkan/data/content`. The same form is supported for Sparking. The CLI derives the URL from the provider registry; it does not accept arbitrary download addresses. A checksum detects corruption, not licensing, authenticity or the correctness of an untrusted manifest.

The registered public URLs are the existing Unit Creator's URLs:

- Eclipse database: `https://dokkan-eclipse.com/cdn/uncompressed/sqlite/current/en/database_decrypted.db`.
- Eclipse assets: `https://dokkan-eclipse.com/cdn/uncompressed/` and the matching-resource mirror `https://cdn.dokkan-eclipse.com/uncompressed/`.
- Sparking database: `https://ddl.dokkan-sparking.com/dokkan/assets/global/en/sqlite/current/en/database.db`.
- Sparking manifest: `https://dokkan-sparking.com/client_assets`.
- Sparking assets: `https://ddl.dokkan-sparking.com/dokkan/assets/global/en/`.

TLS verification and configured proxy trust remain enabled. Requests send only our generic user agent, identity encoding and the existing public manifest-version headers. No cookies, login tokens, account details or private keys are supplied. A refused request fails; this tool does not bypass access restrictions. Server availability and terms can change.

Downloads stream in 64KiB chunks to fresh private temporary files. Bounds are 2GiB for a database, 20MiB for a manifest and 192MiB for one asset. Exact declared/expected lengths and required hashes must match. Redirects are limited to three and must remain the exact approved resource on an approved HTTPS provider/mirror. Redirects to another path, HTTP, credentials, query strings, fragments or unrelated hosts fail before the next request. Game-resource paths reject traversal, encodings, account paths and ambiguous separators.

Files are synced before content-addressed publication; an existing different/corrupt cache file is never overwritten. Failed downloads remove only their own temporary file. No game data is part of source control or a shipped app. The returned `cache_path`/SHA256 can be used by the trusted host's existing verified local-content resolver. The CLI does not yet wire downloads into the native setup screens, determine complete stage dependencies, build a merged canonical catalog, or make battles playable.

One focused check is available:

```sh
python3 offline-dokkan/content/check_source_downloads.py
```

It uses fake HTTPS responses and synthetic SQLite/content to check allowed redirects, path/size/encoding/hash rejection, the public xxHash vector, manifest-backed transfer, plaintext master import, preservation of existing files and complete temporary cleanup. It passed once for this change. It is not a live-site, phone, native-app or gameplay check; no large database was downloaded again.
