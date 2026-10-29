# Original request decoder

`ios/ODOriginalRequestDecoder.mm` reuses the unchanged original encoder and
decoder. It adds no independent cryptography or separate key material. The
loader issues the capability from the same admitted image snapshot; issuance
leaves transport decoding disabled.

The two independent current-client callers establish a24-byte owned native
string returned through the arm64 indirect-result register, with no explicit
argument preparation. Both call the same opaque getter. Its target is resolved
from the pinned ordinary-response caller's actual BL and cross-checked against
the pinned outgoing start builder and function-start table. The provider body,
embedded constants and runtime key characters are neither inspected nor copied
into authored configuration. Each method passes the opaque object directly to
the original codec, then destroys it normally using the matching Apple
`std::__1` native-string ABI. No context survives in the capability.

Before routes can decode, a main-thread call in the initialized active original
engine must encode then decode one fixed own JSON probe through the original pair and
compare exact bytes. The probe contains no player data. A successful check is
reused for the same current engine; a failed actual attempt does not loop.
Source compilation, resolved pins and an unexecuted probe are not acceptance.
The guard requires the actual original AppController/image, active Director,
nonnull running Scene with an original-image vtable, and no pending Scene. The
codec has no source-proven Home dependency. No pending Scene does not establish
that an already-running Cocos transition finished; Host UIKit/context guards
remain separate. No timer, polling loop or invented Scene callback is installed.

Incoming POST bodies are bounded to1MiB. The gate requires the original
FastWriter envelope: `sign`, optionally followed by uint64 `timewarp`, with no
other/duplicate fields. Base64 must be canonical ASCII, without whitespace or
ignored characters. Its decoded framing must contain the eight-byte prefix
plus a nonempty payload. Only then does the original decoder run. Returned
plaintext must be a bounded JSON object. No plaintext/context is placed in logs,
reports, errors or files. The route independently validates its full DTO and
same Core/profile/master/request provenance before any mutation.

Limits remain material: original native transform wrappers ignore some failure
statuses. These guards do not prove safe arbitrary hostile ciphertext handling.
The capability is for actual original-client requests within the trusted native
route owner, not a public decryption service. Actual native roundtrip, encoded
POST, replay/error ownership and save integrity still require in-app evidence.
No native codec execution was performed during this source task.
