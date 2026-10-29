# One-file private Drive download

`Restore-Duo-Diagnostic-Download.ipynb` contains the exact standalone
`restore_diagnostic_ipa.py` source. It runs only in Google Colab and restores the
eight uploaded 2.36.3 diagnostic parts into one IPA in the existing private
`AI-Workspace/Offline Dokkan + Unit Creator/Builds` folder.

The exact original manifest must be uploaded as
`diagnostic-download-manifest.json`. Its SHA-256 is pinned in the script, along
with all eight part sizes and hashes and the final 795,503,162-byte IPA hash.
The script verifies every input while joining in temporary Google runtime
storage, then publishes the output with exclusive creation and verifies its
Drive readback. It never overwrites a different file. An identical existing
output is reused. Parts and manifest remain unchanged; runtime scratch is
automatically removed.

This uses the owner's interactive Drive authorization through Colab. No
credentials are written by this helper. It does not download data to the Mac,
change sharing, build, sign, install, or touch save folders. The IPA is an
**unsigned diagnostic**, with installation and gameplay still unverified.

Prepared for parent review; the notebook has not been executed by this worker.

## Current integrated diagnostic delta

`Update-Duo-Integrated-Diagnostic.ipynb` embeds the exact stdlib-only
`ipa_delta.py` and `apply_integrated_diagnostic.py` sources. It uses the already
restored integrated baseline IPA and a 16,641,867-byte private delta to produce
the current 944,841,989-byte integrated diagnostic in the same Drive folder.
The current output ends in `-20fd1d0.ipa`, preserving the previous baseline.
This avoids
uploading the unchanged original assets again.

The current delta is below the provider's secondary 100 MiB limit and needs no
parts. Its SHA-256 is
`a42a364f5dc8dbc0e9c64d339857ea791e3008464fa0038321539fffac30ebde`.
It reuses 928,255,512 compressed bytes through 2,211 operations.

The delta copies only exact unchanged compressed ZIP payload spans from the
hash-pinned baseline. Changed payloads, local headers, and central directory
bytes come from the hash-pinned literal stream. The bounded recipe permits only
baseline or literal copies, validates every offset/length and full coverage,
and requires the final target checksum. It never decompresses game content or
executes instructions from the delta. Publication uses exclusive creation and
verified readback; different existing output is preserved.

One earlier real delivery roundtrip using this unchanged algorithm reconstructed
the exact previous target SHA-256
`9c2dec628ad80a8e0c0f075d92c1ec4f3b64a91dbc108ed446a7d794bd12bbc2`.
The disposable roundtrip copy was removed after verification. That evidence is
reused; no second roundtrip was run for the current delta. The current complete
target hash is pinned and remains mandatory during restoration:
`f8d9deddddffb2c1571fa62905c325c37920c32d0b4e291cd907ad975f3b3c43`.
No additional application build,
native execution, signing, installation, or gameplay verification was performed.
The new Colab notebook itself has not been executed by this worker.
