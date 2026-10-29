# Native accepted Creator resource reader

`ODAcceptedCreatorResources` opens the actual immutable captured bytes named
by one accepted full-unit packet. This is a native resource capability for the
original-client integration, not a new WebView operation, exported filesystem,
resource installer or replacement game.

The native owner supplies Session's exact six-key accepted packet, that same
issuer's workspace URL, and a current-context callback. Construction checks the
accepted-project binding, all thirteen full receipt fields, the full descriptor,
content/save/profile/definition/version/instance identities, and the exact
project, definition and full-packet hashes. It parses those copied bytes on a
private serial IO queue. The receipt remains snapshot evidence; it is not
permanent current-generation or gameplay authority.

The reader independently admits only actual `resources` records in the packet:

- `captured-asset`, `captured-generated-text` and
  `captured-shared-action-installation-pending` map an exact declared logical
  path to its captured hash and size.
- `captured-cpk-inputs-build-pending` exposes only its explicit container/input
  path tuples. It cannot open that container as if a CPK had been built.

Unknown kinds, extra record fields, duplicate case/normalization aliases,
conflicting sizes for one hash, invalid paths and excessive indexes reject.
There is no arbitrary hash/source-path lookup, resident-game fallback, guessed
alias, network access, CPK build or resource publication. Captured files are at
most96MiB each; a packet admits at most50,000 resource/container/input records.
Unsupported records remain preserved in their accepted packet, not omitted.

The trusted native workspace URL is canonicalized off main, then every path
component is traversed through readonly directory descriptors with `NOFOLLOW`.
The workspace and `full-bundle-captures` directory are pinned by inode/device
identity and app ownership. The actual `.original-creator-binding.json` must
name the packet's content and save scope; its bounded bytes and file identity
remain pinned. A changed workspace/root/owner rejects later opens.

Opening uses only a previously admitted descriptor's lowercase hash basename
under that captured-directory FD. `O_RDONLY|O_NOFOLLOW|O_CLOEXEC|O_NONBLOCK`
prevents symlink traversal and a malicious FIFO blocking the queue. The file
must be regular, app-owned, single-link, non-writable and the declared size.
The existing `od_content_verify_readonly_fd` verifies complete bytes with
`pread`; before/after inode, size, mode, modification/change times and the
directory entry are also checked. The fresh returned FD remains at offsetzero.
The native caller owns and must close it.

Owner authorization runs on main immediately before queued IO and again before
delivery. The main-only callback is never called from the IO queue, and no
queue synchronously waits for main. `invalidate` revokes queued deliveries;
stale results close their FD rather than returning it. Use a weak native owner
capture when appropriate, and make the callback reflect the actual issuer's
admission lifetime. Directory/file IO and all large byte hashing remain off
main. Final original-engine activation still needs its own current projection,
resource-path, format and reload proof.

`attestDeclaredResource:completion:` performs the same verified direct-resource
open, closes its FD, then returns exactly
`{path,sha256,size,content_id,save_scope,full_bundle_sha256,project_sha256}`.
A trusted native JavaScriptCore adapter may wrap this as
`attestAcceptedResource(path)` for a MovieModel candidate planner. It exposes
neither a descriptor nor a filesystem path to JavaScript and does not attest
any rewritten movie, new destination, CPK or installed resource. Actual
`MovieModel.rebase` integration must retain the accepted logical-path binding;
no generic string/path rewrite is authorized by this reader.

This source cohort was not compiled or executed. One source-only API/whitespace
check is recorded by the parent. Missing/stale/writable/corrupt blobs,
normalization collisions, explicit CPK inputs and asynchronous revocation still
need focused native verification when builds are authorized. No app, HTML,
gameplay, signing or device result is claimed.
