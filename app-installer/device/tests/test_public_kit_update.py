"""Two offline synthetic filesystem checks; never verify a real Mac signature.

The internal seal seam accepts a deliberately non-cryptographic tiny Mach-O
fixture. Production CLI cannot select that seam and requires real codesign.
"""
import contextlib
import copy
import importlib.util
import io
import json
import os
from pathlib import Path
import stat
import struct
import sys
import tempfile
import unittest
from unittest import mock
import zipfile

sys.dont_write_bytecode = True
SCRIPT = Path(__file__).resolve().parents[1] / 'update-public-kit.py'
spec = importlib.util.spec_from_file_location('public_kit_update', SCRIPT)
updater = importlib.util.module_from_spec(spec)
spec.loader.exec_module(updater)
SOURCE = '1' * 40
TREE = '2' * 64


def encoded(value):
    return (json.dumps(value, sort_keys=True, indent=2) + '\n').encode()


def fixture_helper():
    def thin(cpu, subtype):
        return (struct.pack('<8I', 0xFEEDFACF, cpu, subtype, 2, 2, 40, 0, 0)
                + struct.pack('<6I', 0x32, 24, 1, 12 << 16, (27 << 16) | (1 << 8), 0)
                + struct.pack('<4I', 0x1D, 16, 72, 16) + bytes(16))
    arm, intel = thin(0x100000C, 0), thin(0x1000007, 3)
    table = (struct.pack('>II', 0xCAFEBABE, 2)
             + struct.pack('>5I', 0x100000C, 0, 64, len(arm), 6)
             + struct.pack('>5I', 0x1000007, 3, 192, len(intel), 6))
    return table + bytes(64 - len(table)) + arm + bytes(192 - 64 - len(arm)) + intel


def fixture_payload(revision, obsolete=False):
    files = {name: ('SYNTHETIC ' + name + '\n').encode() for name in updater.PUBLIC_FILES | updater.REQUIRED_NATIVE}
    files['app-installer/ios/InstallerService.h'] = ('SYNTHETIC HEADER ' + str(revision)).encode()
    files['app-installer/ios/main.m'] = ('SYNTHETIC MAIN ' + str(revision)).encode()
    if obsolete:
        files['app-installer/ios/RetiredSynthetic.h'] = b'SYNTHETIC RETIRED HEADER'
    library_name = updater.INPUT + 'libapp_installer_core.a'
    files[library_name] = b'!<arch>\nSYNTHETIC LIBRARY ' + str(revision).encode()
    files[updater.INPUT + 'review-resources/ThirdPartyNotices.txt'] = b'SYNTHETIC CORE NOTICES'
    files[updater.HELPER['binary']] = fixture_helper()
    files[updater.HELPER['notices']] = b'SYNTHETIC HELPER NOTICES'
    source = {'file': 'AppInstaller-corresponding-source.tar.xz', 'bytes': 1234, 'sha256': '3' * 64}
    rows = [{'manifest': 'app-installer/core/Cargo.toml', 'target': 'aarch64-apple-ios',
             'no_default_features': False, 'features': [], 'lock_path': 'app-installer/core/Cargo.lock',
             'lock_sha256': '4' * 64, 'packages': []}]
    for target in updater.TARGETS:
        rows.append({'manifest': 'downloads/idevice/idevice-0.1.68/Cargo.toml', 'target': target,
                     'no_default_features': True, 'features': ['app-installer-rp-bootstrap'],
                     'lock_path': 'downloads/idevice/idevice-0.1.68/Cargo.lock', 'lock_sha256': '5' * 64,
                     'packages': [{'name': 'idevice', 'version': '0.1.68', 'features': []},
                                  {'name': 'tracing', 'version': '0.1.0',
                                   'features': ['max_level_off', 'release_max_level_off']}]})
    graph = updater.canonical(rows)
    graphs = {row['target']: updater.canonical(row) for row in rows[1:]}
    common = {'source_commit': SOURCE, 'source_tree_sha256': TREE, 'locked_dependency_graph_hash': graph}
    library = dict(common, target='aarch64-apple-ios', unsigned=True,
                   bytes=len(files[library_name]), sha256=updater.sha(files[library_name]),
                   source_bundle_sha256=source['sha256'], source_bundle_bytes=source['bytes'])
    build = dict(common, unsigned=True, designation='unsigned-candidate', synthetic_sdk_marker=False,
                 source_bundle_sha256=source['sha256'], phone_install_attempted=False)
    report = dict(notice_obligations_satisfied=True, notice_gap_count=0, release_license_ready=True,
                  locked_dependency_graph_hash=graph, target_graph_hashes=graphs, distribution_graphs=rows)
    for name, value in ((updater.INPUT + 'cloud-device-library-manifest.json', library),
                        (updater.INPUT + 'review-resources/BuildMetadata.json', build),
                        (updater.INPUT + 'review-resources/ThirdPartyNoticeReport.json', report),
                        (updater.HELPER['notice_report'], report)):
        files[name] = encoded(value)
    receipt = dict(common, schema_version=1, project='dokkan-offline-public', test_fixture=False,
                   tool='app-installer-rp-bootstrap', version='0.1.68', targets=updater.TARGETS,
                   architectures=['arm64', 'x86_64'], minimum_macos='12.0', ad_hoc_signed=True,
                   notarized=False, build_succeeded=True, version_output='app-installer-rp-bootstrap 0.1.68',
                   version_only_executed=True, usb_or_pairing_executed=False, personal_resources_used=False,
                   notice_delivery_pending=False, corresponding_source_delivery_pending=False,
                   corresponding_source=source, target_graph_hashes=graphs, distribution_graphs=rows[1:],
                   genuine_toolchain={'rustc': 'rustc 1.99.1 SYNTHETIC', 'xcode': 'Xcode 27.1',
                                     'clang': 'SYNTHETIC clang', 'macos_sdk': '27.1', 'sdk_settings_sha256': '6' * 64})
    for key in ('binary', 'notices', 'notice_report'):
        name = updater.HELPER[key]
        receipt[key] = {'file': Path(name).name, 'bytes': len(files[name]), 'sha256': updater.sha(files[name])}
    receipt['binary']['mode'] = 0o755
    files[updater.HELPER['manifest']] = encoded(receipt)
    manifest = dict(schema_version=1, test_fixture=False, project='dokkan-offline-public',
                    source_repository='mcantua/dokkan-offline-public', source_commit=SOURCE,
                    bootstrap_tool_commit=SOURCE, source_tree_sha256=TREE, corresponding_source=source,
                    personal_resources_used=False, device_install_attempted=False, release_ready=False,
                    rust_library=library_name, library_manifest=updater.INPUT + 'cloud-device-library-manifest.json',
                    review_resources=updater.INPUT + 'review-resources',
                    native_sources=sorted(name for name in files if name.startswith('app-installer/ios/') and name.endswith(('.m', '.h'))),
                    secure_rp_tool=dict(updater.HELPER, source_commit=SOURCE, source_tree_sha256=TREE,
                                        version='0.1.68', format_key='format_version', protocol_record_version=2,
                                        peer_pin_required=True))
    manifest['files'] = [{'path': name, 'bytes': len(data), 'sha256': updater.sha(data),
                          **({'mode': 0o755} if name == updater.HELPER['binary'] else {})}
                         for name, data in sorted(files.items())]
    files[updater.MANIFEST] = encoded(manifest)
    return files


def write_kit(path, files, extra=()):
    with zipfile.ZipFile(path, 'w', zipfile.ZIP_DEFLATED) as archive:
        for name, data in files.items():
            mode = 0o755 if name == updater.HELPER['binary'] or name.endswith('.command') else 0o600
            info = zipfile.ZipInfo(updater.PREFIX + name)
            info.external_attr = (stat.S_IFREG | mode) << 16
            archive.writestr(info, data)
        for name, data, mode in extra:
            info = zipfile.ZipInfo(name); info.external_attr = mode << 16
            archive.writestr(info, data)
    return updater.sha(path.read_bytes()), path.stat().st_size


def tree_files(path):
    return {str(item.relative_to(path)): item.read_bytes() for item in path.rglob('*') if item.is_file()}


class PublicKitUpdateTests(unittest.TestCase):
    def setUp(self):
        work = SCRIPT.parents[1] / 'cloud-ui/work'
        work.mkdir(parents=True, exist_ok=True)
        self.temporary = tempfile.TemporaryDirectory(prefix='public-kit-tests-', dir=work)
        self.addCleanup(self.temporary.cleanup)
        self.base = Path(self.temporary.name)
        self.destination = self.base / 'AI-Workspace/dokkan-offline-public'
        self.seals = []

    def update(self, revision, obsolete=False):
        kit = self.base / ('kit-' + str(revision) + '.zip')
        pins = write_kit(kit, fixture_payload(revision, obsolete))
        return updater.apply_update(kit, self.destination, *pins, SOURCE,
                                    _seal_verifier=lambda path, receipt: self.seals.append(path.read_bytes()))

    def test_update_preserves_unlisted_private_and_rejects_changed_managed(self):
        # Observe real fsync/replace calls, without faking filesystem success:
        # payload directory entries must be durable before manifest publication.
        events = []
        original_sync, original_replace = updater.os.fsync, updater.os.replace
        def sync(fd):
            events.append(('sync', stat.S_ISDIR(os.fstat(fd).st_mode)))
            return original_sync(fd)
        def replace(source, destination, **kwargs):
            events.append(('replace', destination))
            return original_replace(source, destination, **kwargs)
        with mock.patch.object(updater.os, 'fsync', side_effect=sync), mock.patch.object(updater.os, 'replace', side_effect=replace):
            self.update(1, obsolete=True)
        replacements = [index for index, event in enumerate(events) if event[0] == 'replace']
        for index in replacements:
            self.assertEqual(events[index + 1], ('sync', True))
        publication = next(index for index, event in enumerate(events) if event == ('replace', updater.MANIFEST))
        self.assertEqual(events[publication - 1], ('sync', True))
        self.assertEqual(publication, replacements[-1])
        private = self.destination / 'app-installer/device/private/local-user-output'
        private.write_bytes(b'SYNTHETIC LOCAL USER OUTPUT')
        note = self.destination / 'local-user-note.txt'; note.write_bytes(b'SYNTHETIC USER NOTE')
        self.update(2)
        self.assertFalse((self.destination / 'app-installer/ios/RetiredSynthetic.h').exists())
        self.assertEqual(private.read_bytes(), b'SYNTHETIC LOCAL USER OUTPUT')
        self.assertEqual(note.read_bytes(), b'SYNTHETIC USER NOTE')
        self.assertEqual(stat.S_IMODE((self.destination / updater.HELPER['binary']).stat().st_mode), 0o755)
        # An interrupted overlay can contain a new pinned header beside the old
        # manifest; rerun accepts exact OLD or NEW hashes, never arbitrary edits.
        header = 'app-installer/ios/InstallerService.h'
        (self.destination / header).write_bytes(fixture_payload(3)[header])
        self.update(3)
        self.assertEqual((self.destination / header).read_bytes(), fixture_payload(3)[header])
        (self.destination / 'app-installer/ios/main.m').write_bytes(b'SYNTHETIC USER EDIT')
        before = tree_files(self.destination)
        with self.assertRaises(updater.UpdateError): self.update(4)
        self.assertEqual(tree_files(self.destination), before)
        self.assertEqual(len(self.seals), 3)
        self.assertFalse(list(self.destination.glob('.public-kit-update-*')))
        # Real codesign failure must stop before touching managed payloads too;
        # this deliberately failing seam does not simulate a successful seal.
        (self.destination / 'app-installer/ios/main.m').write_bytes(fixture_payload(3)['app-installer/ios/main.m'])
        before = tree_files(self.destination)
        kit = self.base / 'unsealed.zip'; pins = write_kit(kit, fixture_payload(4))
        def reject_seal(*_):
            raise updater.UpdateError('SYNTHETIC seal rejection')
        with self.assertRaises(updater.UpdateError):
            updater.apply_update(kit, self.destination, *pins, SOURCE, _seal_verifier=reject_seal)
        self.assertEqual(tree_files(self.destination), before)

    def test_bad_archives_and_symlinks_are_rejected_before_project_writes(self):
        with mock.patch.object(updater.subprocess, 'run', side_effect=AssertionError('No tool in default plan')):
            with contextlib.redirect_stdout(io.StringIO()): self.assertEqual(updater.main([]), 0)
        # macOS commonly resolves folder names case-insensitively. Reject every
        # spelling of the frozen folder BEFORE even attempting a filesystem open.
        with mock.patch.object(updater, 'open_directory', side_effect=AssertionError('Frozen source must not be opened')):
            for frozen in ('claude-chatg', 'CLAUDE-CHATG', 'Claude-ChatGPT'):
                with self.subTest(frozen=frozen), self.assertRaises(updater.UpdateError):
                    updater.apply_update(self.base / frozen / 'kit.zip', self.destination, '0' * 64, 1, SOURCE,
                                         _seal_verifier=lambda *_: None)
        base = fixture_payload(1)
        bad = [
            [(updater.PREFIX + '../escape', b'escape', stat.S_IFREG | 0o600)],
            [(updater.PREFIX + 'app-installer/ios/Link.h', b'target', stat.S_IFLNK | 0o777)],
            [(updater.PREFIX + 'readme.md', b'alias', stat.S_IFREG | 0o600)],
            [(updater.PREFIX + 'app-installer/device/private/pairing.plist', b'SYNTHETIC UNAPPROVED PAYLOAD', stat.S_IFREG | 0o600)],
        ]
        # Even a manifest-endorsed private injection must fail before creating
        # the destination. Whole-ZIP pins alone do not authorize private files.
        injected = copy.deepcopy(base)
        name = 'app-installer/device/private/pairing.plist'; injected[name] = b'SYNTHETIC'
        manifest = json.loads(injected[updater.MANIFEST])
        manifest['files'].append({'path': name, 'bytes': len(injected[name]), 'sha256': updater.sha(injected[name])})
        injected[updater.MANIFEST] = encoded(manifest)
        cases = [(base, entries) for entries in bad] + [(injected, [])]
        for index, (files, extra) in enumerate(cases):
            with self.subTest(archive=index):
                kit = self.base / ('bad-' + str(index) + '.zip'); pins = write_kit(kit, files, extra)
                with self.assertRaises(updater.UpdateError):
                    updater.apply_update(kit, self.destination, *pins, SOURCE, _seal_verifier=lambda *_: None)
                self.assertFalse(self.destination.exists())
        kit = self.base / 'valid.zip'; digest, size = write_kit(kit, base)
        with self.assertRaises(updater.UpdateError):
            updater.apply_update(kit, self.destination, '0' * 64, size, SOURCE, _seal_verifier=lambda *_: None)
        self.assertFalse(self.destination.exists())
        # Even if the source ZIP changes after verification, all staged bytes
        # must come from the immutable, externally pinned snapshot.
        original_reader = updater.read_archive
        replacement = fixture_payload(9)
        def replace_download_after_verification(stream, source):
            result = original_reader(stream, source)
            write_kit(kit, replacement)
            return result
        with mock.patch.object(updater, 'read_archive', side_effect=replace_download_after_verification):
            updater.apply_update(kit, self.destination, digest, size, SOURCE, _seal_verifier=lambda *_: None)
        self.assertEqual((self.destination / 'app-installer/ios/main.m').read_bytes(), base['app-installer/ios/main.m'])
        # A symlink in a managed target is also rejected without touching its
        # unlisted referent or any other managed file.
        referent = self.base / 'user-file'; referent.write_bytes(b'SYNTHETIC USER FILE')
        managed = self.destination / 'app-installer/ios/main.m'; managed.unlink(); managed.symlink_to(referent)
        kit = self.base / 'valid-again.zip'; digest, size = write_kit(kit, base)
        before_manifest = (self.destination / updater.MANIFEST).read_bytes()
        with self.assertRaises((updater.UpdateError, OSError)):
            updater.apply_update(kit, self.destination, digest, size, SOURCE, _seal_verifier=lambda *_: None)
        self.assertEqual(referent.read_bytes(), b'SYNTHETIC USER FILE')
        self.assertEqual((self.destination / updater.MANIFEST).read_bytes(), before_manifest)
        # Reject a symlink ancestor rather than following it to another folder.
        real = self.base / 'real'; real.mkdir()
        alias_base = self.base / 'alias'; alias_base.mkdir()
        (alias_base / 'AI-Workspace').symlink_to(real, target_is_directory=True)
        with self.assertRaises((updater.UpdateError, OSError)):
            updater.apply_update(kit, alias_base / 'AI-Workspace/dokkan-offline-public', digest, size, SOURCE, _seal_verifier=lambda *_: None)
        self.assertEqual(list(real.iterdir()), [])


if __name__ == '__main__':
    unittest.main()
