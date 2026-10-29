# Restore two original iPhone startup inputs

The retained original-client working images contain the engine and genuine
shell, but omit its required `AdjustSigSdk` binary and bundled `database.db`
seed. The retained resource cache has 27 content-addressed audio/archive blobs,
with neither missing file. The retained client-analysis archive contains only
metadata and Android analysis files.

`extract_startup_inputs.py` reads the existing private IPA through authenticated
Google Drive byte ranges inside Colab. It selects only the original app-root
`database.db` and `Frameworks/AdjustSigSdk.framework/AdjustSigSdk`, checking the
exact previously recorded sizes and SHA-256 hashes. It does not reconstruct or
download the full IPA, inspect signing/provisioning files, read saves, launch
the game, or compile anything. It caps source reads at 16 MiB and rejects a
server that ignores Range. The original IPA remains unchanged.

The source and destination Drive IDs are runtime configuration in a private,
self-contained notebook, outside Git. Use standard managed Colab authorization
instead of the older `drive.mount` helper that failed credential propagation.
Google manages that authorization; this extractor does not serialize, print,
or upload credentials. It creates one small `Private-iPhone-startup-inputs.zip`
in the existing project Game Data folder, or overwrites only an existing output
owned by this extractor. It verifies the uploaded archive by SHA-256 readback.

The chat cannot run Colab under the owner's Google sign-in. After the reviewed
notebook has been uploaded and verified, the owner must open it in regular
Chrome, choose **Run all**, and authorize Google access if requested. Game data
processing runs in Google's cloud; the browser displays the notebook and
authorization UI. No full game transfer through the Mac is required.

One combined synthetic check passed for exact-only ZIP extraction, rejected
ignored Range responses, and rejected member hash mismatch. No actual Google
authorization, real IPA extraction, upload, app build, or launch has been
performed by this helper yet. Those remain pending; this tool is not gameplay.

Official references retrieved on October 29, 2026: Google Drive's
[download guide](https://developers.google.com/workspace/drive/api/guides/manage-downloads)
documents partial blob downloads using `Range`, and the official Python client
documents [MediaIoBaseUpload](https://googleapis.github.io/google-api-python-client/docs/epy/googleapiclient.http.MediaIoBaseUpload-class.html).
