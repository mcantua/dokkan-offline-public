#!/usr/bin/env python3
"""Remove only this build's known staging directory/lock inside app-installer/build/work."""
import argparse
from pathlib import Path
import shutil

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('variant', choices=('iphone', 'duo'))
parser.add_argument('--stage-only', action='store_true')
args = parser.parse_args()
base = Path(__file__).resolve().parent/'work'
paths = [base/args.variant]
if not args.stage_only: paths.append(base/(args.variant + '.lock'))
for path in paths:
    if path.is_symlink(): path.unlink()
    elif path.is_dir(): shutil.rmtree(path)
    elif path.exists(): path.unlink()

try:
    base.rmdir()
except OSError:
    pass  # Another variant may still own staging/lock files.
