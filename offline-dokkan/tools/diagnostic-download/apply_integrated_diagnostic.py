#!/usr/bin/env python3
"""Google Colab entry for the exact current integrated diagnostic delivery."""
from pathlib import Path
import hashlib
import tempfile
from ipa_delta import apply_delta, regular


def restore_integrated_diagnostic():
    from google.colab import drive
    drive.mount('/content/drive')
    folder = Path('/content/drive/MyDrive/AI-Workspace/Offline Dokkan + Unit Creator/Builds')
    if not folder.is_dir() or any(p.is_symlink() for p in (folder, *folder.parents)):
        raise RuntimeError('The exact existing private Builds folder is unavailable.')
    parts = (
        ('OfflineDokkan-Duo-Integrated-Diagnostic-2.36.3.delta.part-01', 100663296,
         'cc623ad8d264155fae68627efcad0fe10bb029c15424d2ddb8fefd4673ed60b3'),
        ('OfflineDokkan-Duo-Integrated-Diagnostic-2.36.3.delta.part-02', 35007816,
         '30d4ecb67a7bcfe4f1ef6f75c41328363d92e65b815059d341fbfeac736f769d'))
    # Provider upload limits require two parts. Join in ephemeral Google
    # runtime storage only; never create a duplicate full delta in Drive.
    with tempfile.TemporaryDirectory(dir='/content') as scratch:
        patch = Path(scratch) / 'delivery.delta'
        combined = hashlib.sha256()
        total = 0
        with patch.open('xb') as joined:
            for name, expected_size, expected_hash in parts:
                digest = hashlib.sha256()
                count = 0
                with regular(folder / name) as source:
                    while block := source.read(1024 * 1024):
                        count += len(block)
                        if count > expected_size:
                            raise ValueError('Delta part exceeds its pinned size')
                        joined.write(block)
                        digest.update(block)
                        combined.update(block)
                if count != expected_size or digest.hexdigest() != expected_hash:
                    raise ValueError('Delta part checksum mismatch')
                total += count
        if total != 135671112 or combined.hexdigest() != '377fe110b71fe2195b5648418489cd4c141ff488fde12f40df630d4363c8ed04':
            raise ValueError('Joined delta checksum mismatch')
        result = apply_delta(
            folder / 'OfflineDokkan-Duo-Diagnostic-2.36.3.ipa', patch,
            folder / 'OfflineDokkan-Duo-Integrated-Diagnostic-2.36.3.ipa',
            (795503162, '8299b3fc2f306d58a891e3baa5c1b0e64afb9b55269c5e91bdcb6a4086506008'),
            (135671112, '377fe110b71fe2195b5648418489cd4c141ff488fde12f40df630d4363c8ed04'),
            (929647581, '9c2dec628ad80a8e0c0f075d92c1ec4f3b64a91dbc108ed446a7d794bd12bbc2'))
    print('Current single IPA is in the private Builds folder:')
    print('OfflineDokkan-Duo-Integrated-Diagnostic-2.36.3.ipa')
    print(f"Verified {result['bytes']:,} bytes; SHA-256 {result['sha256']}")
    print('Baseline and both delta parts preserved. No Mac download was performed.')
    print('Unsigned integrated diagnostic; signing is required. Gameplay remains unverified.')


if __name__ == '__main__':
    restore_integrated_diagnostic()
