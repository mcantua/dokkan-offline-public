# idevice

Version: 0.1.68
License: MIT (see upstream source).
Source: https://crates.io/api/v1/crates/idevice/0.1.68/download
Purpose: audit the exact signing and on-device installation APIs.
Crates.io archive SHA-256: f5d7799c8497cef60ddfd38f7d92e267b9fa5d0b18e7691d31041453007400ca
Fetched October 28, 2026; the reviewed patched local source is linked into the current core.
Upstream license retrieved separately (crate did not include a license file): https://raw.githubusercontent.com/jkcoxson/idevice/d32c8189c51c2789496b0768039419c3705498c3/LICENSE.txt

App Installer patches now also require strict version2 Remote Pairing exports with authenticated peer identifier/key pins, trusted setup M6 and subsequent pair-verify signatures, nonce/session invalidation, bounded RP/CDTunnel framing, and an audited vendored OpenSSL TLS1.2 PSK-only production tunnel. The handwritten TLS implementation remains inactive in production. Existing Lockdown certificate pinning stays on rustls/ring even with OpenSSL enabled. Ordinary verification is not disabled. Exact diff/source and corresponding-source/license receipts must accompany each build. Focused proof is under downloads/completion-verification/remote-pairing-working; physical RP/RSD service behavior remains unverified.

October 29 cloud audit adds two narrow validation fixes: a present `alt_irk` must be exactly 16 bytes of plist Data (absent remains permitted), matching the native protected-backup validator; and RSD check-in/StartService replies containing an orphan `ErrorDescription` fail with fixed messages. Ordinary `Error` fields were already rejected by `read_plist` and that behavior is preserved. Two focused `rp_connectivity_` methods passed using synthetic records and an in-memory framed stream; exact proof and the initial corrected test expectation are retained in the same verification folder. Neither establishes the cause of Tin's physical USB export failure.

Later October 29 actual helper output reached authenticated-pairing-pending, then failed. A deeper wire audit found noncanonical254-byte M3/M5 splits and a serializer that truncated logical lengths to u8. Serialization now emits canonical255-byte continuation fragments for all long fields; M3/M5 provide single logical fields, removing fixed slices. M2/M4 require the expected state and unambiguous salt/proof; truncated trailing TLV headers are rejected. Minimal fixed progress callbacks expose no protocol payload. Two `rp_setup_wire_` methods passed, including the real production pairing method against an independent strict-fragment synthetic SRP/Ed25519/AEAD peer with tamper cases. Reference: https://github.com/doronz88/pymobiledevice3/blob/91269aef1570966aa740eebc7dc64ec16ef1cb4c/pymobiledevice3/remote/tunnel_service.py#L948 . Exact logs/pre-post source receipts are in the same proof folder. This reproduces a real interoperability defect, not yet the phone's verified root cause; M6 identity and later peer pinning remain mandatory.
