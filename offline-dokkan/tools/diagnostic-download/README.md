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
