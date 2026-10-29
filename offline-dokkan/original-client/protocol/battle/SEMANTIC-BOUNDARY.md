# Original plaintext battle data: exact observation frontier

The existing shared body setter is **after encoding**. It receives the outer
`sign` object, optionally adds `timewarp`, serializes it and stores the encoded
body on the request. It does not expose the original options/statistics JSON.

The actual plaintext seam is the original `Json::FastWriter::write` call inside
each start/finish builder. The writer's exact native RTTI and virtual slot 2
identify its 136-byte method; both selected callers invoke that same method
directly. The observed ARM64 register contract at each pinned call site is:

| Register | Meaning at these exact call sites |
|---|---|
| X0 | Local `Json::FastWriter` object address |
| X1 | Local plaintext `Json::Value` address |
| X8 | Caller-owned storage for the returned 24-byte libc++ string |
| X21 | Live original request object, saved from the builder's entry X0 |
| X20 / X19 | The builder's original continuation arguments X1 / X2 |

X21 is caller context, **not** another serializer argument. Treating it as a
request pointer for arbitrary uses of this shared serializer would be invalid.
The two exact body identities and private call-site coordinates are retained;
a generic hook signature has not been admitted from this observation.

The plaintext string goes to the original native codec. Its long-string
allocation is then deleted before the encoded-body setter runs. Saving that
pointer for a later network callback would therefore create a dangling pointer.
The local JSON/writer objects also belong to the original builder's stack.
A justified observer must copy the existing serialized bytes while they are
valid and own the copy independently; it must leave the original codec and
original gameplay untouched.

The shared 1240-byte send path can dispatch immediately or defer a request.
Thus merely keeping a thread-local pointer during the builder cannot establish
the later Foundation request's identity, retry generation or cancellation
lifetime. The existing materializer and completion installer provide the next
source identities to bind, but no binding is claimed yet.

`semantic-boundary-evidence.json` records the exact function hashes, register
facts and remaining requirements. This is a source-proven observation seam,
not an existing plaintext getter, implemented native hook, working transport,
playable battle or persistent save. No key provider or private key material was
inspected, and no original code or codec was modified.
