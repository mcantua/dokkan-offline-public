"""Two grouped TEST-ONLY regressions; these fixtures are not device/release evidence."""
import contextlib
import hashlib
import copy
import importlib.util
import io
from pathlib import Path
import stat
import sys
import tempfile
import unittest
import zipfile

sys.dont_write_bytecode = True
BUILD = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BUILD))


def load(name, filename):
    spec = importlib.util.spec_from_file_location(name, BUILD / filename)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


artifact_fixture = load('candidate_security_artifact_fixture', 'test-artifact.py')
artifact_check = load('candidate_security_artifact_check', 'check-artifact.py')
candidate = load('candidate_security_candidate_gate', 'verify-candidate.py')
packager = load('candidate_security_packager', 'package-device-cloud.py')


class CandidateSecurityTests(unittest.TestCase):
    def test_zip_aliases_special_files_and_expansion_bounds_are_rejected(self):
        work = BUILD / 'work'
        work.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='candidate-security-test-', dir=work) as temporary:
            path = Path(temporary) / 'TEST-ONLY-fixture.ipa'
            artifact_fixture.fixture(path)
            with contextlib.redirect_stdout(io.StringIO()):
                artifact_check.check(path, 'duo')
            for alias in [
                'Payload/AppInstaller.app/./AppInstaller',
                'Payload/AppInstaller.app/APPINSTALLER',
                'Payload/AppInstaller.app//AppInstaller',
                'Payload/AppInstaller.app/AppInstaller/child',
            ]:
                artifact_fixture.fixture(path)
                with zipfile.ZipFile(path, 'a') as archive:
                    archive.writestr(alias, b'TEST-ONLY conflicting executable path')
                with self.assertRaises(ValueError, msg=alias):
                    artifact_check.check(path, 'duo')
            artifact_fixture.fixture(path)
            with zipfile.ZipFile(path, 'a') as archive:
                archive.writestr('Payload/AppInstaller.app/café.txt', b'one')
                archive.writestr('Payload/AppInstaller.app/café.txt', b'two')
            with self.assertRaises(ValueError):
                artifact_check.check(path, 'duo')
            artifact_fixture.fixture(path)
            fifo = zipfile.ZipInfo('Payload/AppInstaller.app/TEST-ONLY-special-file')
            fifo.create_system = 3
            fifo.external_attr = (stat.S_IFIFO | 0o600) << 16
            with zipfile.ZipFile(path, 'a') as archive:
                archive.writestr(fifo, b'')
            with self.assertRaises(ValueError):
                artifact_check.check(path, 'duo')
            artifact_fixture.fixture(path)
            # A tiny compressed entry claims/expands to >2 MiB; the gate must reject
            # it before extraction even though none of its named metadata is read.
            with zipfile.ZipFile(path, 'a', compression=zipfile.ZIP_DEFLATED) as archive:
                archive.writestr('Payload/AppInstaller.app/TEST-ONLY-expansion.bin', b'\x00' * (2 * 1024 * 1024))
            with self.assertRaises(ValueError):
                artifact_check.check(path, 'duo')
        try:
            work.rmdir()
        except OSError:
            pass

    def test_candidate_designation_requires_genuine_matching_toolchain(self):
        # TEST-ONLY metadata shape; never passed off as a compiled SDK receipt.
        toolchain = {
            'sdk_version': '27.1', 'sdk_settings_sha256': 'a' * 64,
            'sdk_path': '/TEST-ONLY/iPhoneOS27.1.sdk', 'xcode': 'TEST-ONLY Xcode 27.1',
            'clang': 'TEST-ONLY Apple clang', 'rustc': 'rustc 1.99.1 (TEST-ONLY fixture)',
        }
        good = {
            'synthetic_sdk_marker': False, 'designation': 'unsigned-candidate',
            'compilation_sdk': '27.1', 'requested_sdk_mark': '27.1',
            'genuine_toolchain': copy.deepcopy(toolchain), 'unsigned': True,
        }
        candidate.require_genuine(good, toolchain)
        for changes in [
            {'synthetic_sdk_marker': True},
            {'designation': 'unsigned-preview'},
            {'compilation_sdk': '16.5', 'requested_sdk_mark': '16.5'},
            {'compilation_sdk': '27.1', 'requested_sdk_mark': '16.5'},
            {'genuine_toolchain': {**toolchain, 'sdk_settings_sha256': 'b' * 64}},
            {'genuine_toolchain': {**toolchain, 'sdk_version': '27.2'}},
            {'genuine_toolchain': {**toolchain, 'clang': 'TEST-ONLY another clang'}},
        ]:
            metadata = copy.deepcopy(good)
            metadata.update(changes)
            with self.assertRaises(ValueError, msg=str(changes)):
                candidate.require_genuine(metadata, toolchain)
        for missing in ['synthetic_sdk_marker', 'designation', 'compilation_sdk', 'genuine_toolchain']:
            metadata = copy.deepcopy(good)
            del metadata[missing]
            with self.assertRaises(ValueError, msg=missing):
                candidate.require_genuine(metadata, toolchain)


        # A completed Rust build receipt must bind the actual archive bytes to this
        # source/graph/SDK. Mechanical fixture receipts can never be production evidence.
        work = BUILD / 'work'
        work.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='candidate-receipt-test-', dir=work) as temporary:
            library = Path(temporary) / 'libapp_installer_core.a'
            library.write_bytes(b'TEST-ONLY archive, not device Rust machine code')
            expected = {'source_commit': '1'*40, 'source_tree_sha256': '2'*64,
                        'locked_dependency_graph_hash': '3'*64,
                        'sdk_version': '27.1', 'sdk_settings_sha256': 'a'*64,
                        'rustc_version': 'rustc 1.99.1 (TEST-ONLY fixture)'}
            receipt = {'schema_version': 1, 'test_fixture': True, 'build_succeeded': True,
                       'target': 'aarch64-apple-ios', 'file': library.name,
                       'bytes': library.stat().st_size,
                       'sha256': hashlib.sha256(library.read_bytes()).hexdigest(), **expected}
            packager.verify_core_receipt(receipt, library, expected, allow_test_fixture=True)
            with self.assertRaises(ValueError):
                packager.verify_core_receipt(receipt, library, expected)
            for field, value in [('source_tree_sha256', '4'*64),
                                 ('locked_dependency_graph_hash', '5'*64),
                                 ('sdk_version', '16.5'), ('sdk_settings_sha256', '6'*64),
                                 ('source_commit', '7'*40), ('sha256', '8'*64),
                                 ('rustc_version', 'rustc 1.98.0 (TEST-ONLY wrong runtime)'),
                                 ('build_succeeded', False)]:
                changed = {**receipt, field: value}
                with self.assertRaises(ValueError, msg=field):
                    packager.verify_core_receipt(changed, library, expected, allow_test_fixture=True)
            library.write_bytes(b'TEST-ONLY replacement foreign library')
            with self.assertRaises(ValueError):
                packager.verify_core_receipt(receipt, library, expected, allow_test_fixture=True)
        try:
            work.rmdir()
        except OSError:
            pass


if __name__ == '__main__':
    unittest.main()
