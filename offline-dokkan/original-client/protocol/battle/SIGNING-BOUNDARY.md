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

Keep the original native codec as the integration candidate. The next justified
step is to establish a compatible original semantic/codec boundary without
extracting private material. No native hook signature, decoder, replacement
crypto, decoded request payload or successful offline request is claimed here.
