#!/usr/bin/env python3
"""Duo metadata/source gate; never establishes physical layout or true SDK compatibility."""
import argparse
import sys
sys.dont_write_bytecode = True
import importlib.util
from pathlib import Path

module_path = Path(__file__).with_name('check-artifact.py')
spec = importlib.util.spec_from_file_location('artifact_check', module_path)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('ipa')
    parser.add_argument('--source-root', type=Path)
    args = parser.parse_args()
    module.check(args.ipa, 'duo', args.source_root)
