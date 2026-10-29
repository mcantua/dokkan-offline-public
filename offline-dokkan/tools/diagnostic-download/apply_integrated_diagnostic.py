#!/usr/bin/env python3
"""Google Colab entry for the exact current integrated diagnostic delivery."""
from pathlib import Path
from ipa_delta import apply_delta


def restore_integrated_diagnostic():
    from google.colab import drive
    drive.mount('/content/drive')
    folder = Path('/content/drive/MyDrive/AI-Workspace/Offline Dokkan + Unit Creator/Builds')
    if not folder.is_dir() or any(p.is_symlink() for p in (folder, *folder.parents)):
        raise RuntimeError('The exact existing private Builds folder is unavailable.')
    result = apply_delta(
        folder / 'OfflineDokkan-Duo-Integrated-Diagnostic-2.36.3.ipa',
        folder / 'OfflineDokkan-Duo-Integrated-Diagnostic-2.36.3-20fd1d0.delta',
        folder / 'OfflineDokkan-Duo-Integrated-Diagnostic-2.36.3-20fd1d0.ipa',
        (929647581, '9c2dec628ad80a8e0c0f075d92c1ec4f3b64a91dbc108ed446a7d794bd12bbc2'),
        (16641867, 'a42a364f5dc8dbc0e9c64d339857ea791e3008464fa0038321539fffac30ebde'),
        (944841989, 'f8d9deddddffb2c1571fa62905c325c37920c32d0b4e291cd907ad975f3b3c43'))
    print('Current single IPA is in the private Builds folder:')
    print('OfflineDokkan-Duo-Integrated-Diagnostic-2.36.3-20fd1d0.ipa')
    print(f"Verified {result['bytes']:,} bytes; SHA-256 {result['sha256']}")
    print('Previous integrated IPA and delta preserved. No Mac download was performed.')
    print('Unsigned integrated diagnostic; signing is required. Gameplay remains unverified.')


if __name__ == '__main__':
    restore_integrated_diagnostic()
