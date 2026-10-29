# Preserve the native battle request codec

Both original start/finish builders serialize their actual options/statistics,
call the existing native wrapper, and send its returned string under `sign`.
The wrapper is 100 bytes and takes two original caller-supplied input pointers,
using X8 for caller-owned result storage. It invokes a 288-byte first-stage
wrapper into a local three-pointer temporary, then a 228-byte encoder into the
final libc++-layout string. Input runtime data values were not extracted.

The second stage is a base64 BIO chain. This is established from the actual
standard method metadata (`base64 encoding`, type 0x20b; `memory buffer`,
type 0x401) and its no-newline flag 0x100, flush control 11 and buffer-pointer
control 115. These were checked against the official OpenSSL header and
base64 BIO documentation linked in `signing-wrapper-evidence.json`.
The cited reference release does not identify the binary's library version.

The first-stage bytes remain opaque. Base64 does **not** prove that they are
unencrypted JSON, payload-plus-MAC, ciphertext, or any particular cipher.
The key provider, private key constants and underlying key-handling bodies
were not inspected. No key values were read, stored, printed or shipped.

The client also contains an existing 200-byte decoder wrapper. The ordinary
WebAPI response callback reads `sign` into a native string, obtains its opaque
argument from the same getter used by the outgoing battle builders, and calls
that wrapper. The exact ARM64 call supplies the encoded-string address in X0,
the opaque-argument address in X1 and caller-owned result storage in X8.
These are observed native object addresses, not C strings or an exported C API.

The decoder first produces a temporary byte range, passes it with the opaque
argument into another original stage, then constructs the output string from
the resulting range. It releases both temporary allocations before returning.
The caller later releases the opaque argument and output as native strings.
The decoder's own observed high-pcode footprint is wholly inside its declared
200-byte body. Calling the same getter establishes its identity; equality of the
runtime argument values across requests has not been verified. The opaque getter
and the cipher/derivation implementations remain excluded from inspection.

Bounded instruction review of the paired stage wrappers establishes more than
their names. Outgoing data gets an eight-byte prefix; incoming data separates
that prefix before its transform. Both initialization wrappers use the same
algorithm-selector, derivation-selector and derivation-function identities,
the opaque argument's bytes and length, the prefix and iteration count one.
Both expect a derivation return of 32. Their context initialization reaches the
same original routine with mode one outgoing and mode zero incoming, and both
transforms call the same native update/final routines. No referenced key data,
private constants or opaque runtime values were dereferenced. Standard crypto
API names were unavailable in the selected symbol metadata, so no cipher name
is inferred from these identities.

The original decoder is not established as a safe arbitrary-input API. Its
outer wrapper rejects an empty first-stage range, while the next stage reads
an eight-byte prefix without its own short-input guard. The transform does not
check the native update/final status returns. Initialization failure produces
an empty range, but a derivation-length mismatch only logs and continues.
There are also native allocation/unwind paths. These observations require a
narrow source-pinned adapter and real acceptance evidence; an empty output is
not a proven complete error contract. The prefix/payload temporary lengths
must also be checked in the original runtime before assuming exact inversion.

The source-pinned native adapter is now implemented in
`ios/ODOriginalRequestDecoder.mm`; see [NATIVE-REQUEST-DECODER.md](NATIVE-REQUEST-DECODER.md).
It preserves owned native strings and original codec/context lifetime, validates
the bounded outer encoding, and keeps routes closed until an actual own-JSON
encode/decode roundtrip succeeds after original initialization. It adds no
separate keys, cryptography or exported context. Route ownership/DTO checks and
native runtime acceptance remain required. No native codec execution or working
request decoding is claimed by source implementation alone.

Ordinary response handling is a separate issue: the actual native predicate
accepts a JSON object without `sign` through its plain-response branch. Its
common root processors must still be satisfied before a battle or tutorial
response is admitted. This does not decode encoded request bodies.
