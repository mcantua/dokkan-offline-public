"""TEST-ONLY proof verifier checks. Does not execute Rust tests or contact a network."""
import copy
import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[3]
SPEC = importlib.util.spec_from_file_location('reuse', ROOT / 'app-installer/cloud-ui/reuse-core-proof.py')
reuse = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(reuse)
PROOF = ROOT / 'downloads/completion-verification/hosted-core'
CONTEXT = {**reuse.EXPECTED_CONTEXT, 'rustc_version': 'rustc 1.99.1 (TEST-ONLY context)'}


class ProofTests(unittest.TestCase):
    def test_actual_saved_proof_accepts_only_exact_input_and_context(self):
        manifest, files = reuse.verify(ROOT, PROOF, CONTEXT)
        self.assertEqual(len(manifest['files']), 198)
        self.assertEqual(set(files), {'manifest.json', 'source-report.json', 'coretests.log', 'tls-tests.log'})
        for key, value in (('os', 'Linux'), ('architecture', 'x86_64'),
                           ('rustc_version', 'rustc 1.98.0 (TEST-ONLY)'), ('xcode', 'Xcode other')):
            with self.subTest(context=key), self.assertRaises(ValueError):
                reuse.verify(ROOT, PROOF, {**CONTEXT, key: value})
        actual = reuse.current_files(ROOT)
        for kind in ('changed', 'new', 'missing'):
            changed = copy.deepcopy(actual)
            path = next(iter(changed))
            if kind == 'changed':
                changed[path] = '0' * 64
            elif kind == 'new':
                changed['app-installer/core/src/TEST-ONLY-new.rs'] = '0' * 64
            else:
                del changed[path]
            with self.subTest(inputs=kind), patch.object(reuse, 'current_files', return_value=changed), self.assertRaises(ValueError):
                reuse.verify(ROOT, PROOF, CONTEXT)

    def test_raw_log_tampering_or_success_summary_changes_reject(self):
        with tempfile.TemporaryDirectory(dir=Path(__file__).parent) as temporary:
            proof = Path(temporary)
            for name in ('manifest.json', 'source-report.json', 'coretests.log', 'tls-tests.log'):
                (proof / name).write_bytes((PROOF / name).read_bytes())
            original = (proof / 'coretests.log').read_bytes()
            (proof / 'coretests.log').write_bytes(original + b'TEST-ONLY tampered\n')
            with self.assertRaises(ValueError):
                reuse.verify(ROOT, proof, CONTEXT)
            changed = original.replace(b'18 passed; 0 failed', b'17 passed; 1 failed')
            (proof / 'coretests.log').write_bytes(changed)
            import json
            manifest = json.loads((proof / 'manifest.json').read_text())
            manifest['checks']['core']['sha256'] = reuse.sha(changed)
            (proof / 'manifest.json').write_text(json.dumps(manifest))
            with self.assertRaises(ValueError):
                reuse.verify(ROOT, proof, CONTEXT)


if __name__ == '__main__':
    unittest.main()
