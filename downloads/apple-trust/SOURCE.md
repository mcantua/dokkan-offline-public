# Apple public trust evidence

Public certificates only; no private keys or user credentials. Existing pinned dependency assets compared with official HTTPS Apple distribution. A root-descended user development certificate alone cannot authorize a provisioning profile; actual profile authority/expected live service response binding remains required.

[
  {
    "asset": "downloads/isideload/isideload-0.5.0/src/assets/apple_root.cer",
    "official_url": "https://www.apple.com/appleca/AppleIncRootCertificate.cer",
    "sha256": "b0b1730ecbc7ff4505142c49f1295e6eda6bcaed7e2c68c5be91b5a11001f024",
    "exact_match": true
  },
  {
    "asset": "downloads/isideload/isideload-0.5.0/src/assets/AppleWWDRCAG3.cer",
    "official_url": "https://www.apple.com/certificateauthority/AppleWWDRCAG3.cer",
    "sha256": "dcf21878c77f4198e4b4614f03d696d89c66c66008d4244e1b99161aac91601f",
    "exact_match": true
  }
]

Additional official public trust anchors retrieved 2026-10-28 UTC:
- AppleRootCA-G2.cer: https://www.apple.com/certificateauthority/AppleRootCA-G2.cer; SHA-256 `c2b9b042dd57830e7d117dac55ac8ae19407d38e41d88f3215bc3a890444a050`; 1430 bytes.
- AppleRootCA-G3.cer: https://www.apple.com/certificateauthority/AppleRootCA-G3.cer; SHA-256 `63343abfb89a6a03ebb57e9b3f5fa7be7c4f5c756f3017b3a8c488c3653e9179`; 583 bytes.
