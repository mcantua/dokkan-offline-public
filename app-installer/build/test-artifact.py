#!/usr/bin/env python3
"""Two offline regression tests for the review-artifact gate; no SDK/device needed."""
import contextlib
import sys
sys.dont_write_bytecode = True
import importlib.util
import io
import json
from pathlib import Path
import plistlib
import struct
import tempfile
import unittest
import zipfile
import zlib

spec = importlib.util.spec_from_file_location('artifact_check', Path(__file__).with_name('check-artifact.py'))
check = importlib.util.module_from_spec(spec)
spec.loader.exec_module(check)
ROOT = Path(__file__).resolve().parents[2]


def fixture(path, mutate=None, macho=None):
    p = plistlib.loads((ROOT/'app-installer/ios/Info.plist').read_bytes())
    p.update(DTSDKName='iphoneos27.1', DTPlatformVersion='27.1')
    if mutate: mutate(p)
    # Minimal arm64 executable/load-command fixture, not an executable app.
    command = struct.pack('<6I', 0x32, 24, 2, 16 << 16 | 4 << 8, 27 << 16 | 1 << 8, 0)
    data = struct.pack('<8I', 0xFEEDFACF, 0x0100000C, 0, 2, 1, 24, 0, 0) + command
    metadata = dict(unsigned=True, variant='duo', compilation_sdk='16.5', requested_sdk_mark='27.1',
                    phone_install_attempted=False, duo_device_layout_verified=False, source_tree_sha256='0'*64)
    with zipfile.ZipFile(path, 'w') as z:
        z.writestr('Payload/AppInstaller.app/Info.plist', plistlib.dumps(p))
        info = zipfile.ZipInfo('Payload/AppInstaller.app/AppInstaller')
        info.external_attr = 0o100755 << 16
        z.writestr(info, macho if macho is not None else data)
        z.writestr('Payload/AppInstaller.app/BuildMetadata.json', json.dumps(metadata))
        z.writestr('Payload/AppInstaller.app/ThirdPartyNotices.txt','Synthetic gate fixture; not third-party source.')
        z.writestr('Payload/AppInstaller.app/ThirdPartyNoticeReport.json',json.dumps({'target':'aarch64-apple-ios','notice_gap_count':0,'missing_notices':[]}))
        for size,scale in [(120,2),(180,3)]:
            def chunk(kind,payload):
                return struct.pack('>I',len(payload))+kind+payload+struct.pack('>I',zlib.crc32(kind+payload)&0xffffffff)
            png=b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',size,size,8,2,0,0,0))
            png+=chunk(b'IDAT',zlib.compress((b'\x00'+b'\x00'*size*3)*size))+chunk(b'IEND',b'')
            z.writestr(f'Payload/AppInstaller.app/AppIcon60x60@{scale}x.png',png)


class ArtifactTests(unittest.TestCase):
    def test_structural_corruption_and_sdk_manifest_mismatch_rejected(self):
        work = ROOT/'app-installer/build/work'
        work.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='artifact-test-', dir=work) as tmp:
            path = Path(tmp)/'fixture.ipa'
            fixture(path)
            with contextlib.redirect_stdout(io.StringIO()): check.check(path, 'duo')
            for mutate in [lambda p: p.update(DTSDKName='iphoneos16.5'),
                           lambda p: p.update(UIRequiresFullScreen=False),
                           lambda p: p.pop('UIApplicationSceneManifest')]:
                fixture(path, mutate=mutate)
                with self.assertRaises(ValueError): check.check(path, 'duo')
            fixture(path, macho=struct.pack('<8I',0xFEEDFACF,0x0100000C,0,2,1,24,0,0))
            with self.assertRaises(ValueError): check.check(path,'duo')

    def test_scene_window_source_gate_rejects_screen_sizing(self):
        work = ROOT/'app-installer/build/work'
        work.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='artifact-test-', dir=work) as tmp:
            tmp = Path(tmp)
            path = tmp/'fixture.ipa';fixture(path)
            ios = tmp/'app-installer/ios';ios.mkdir(parents=True)
            source = ios/'main.m';source.write_text('window = [[UIWindow alloc] initWithWindowScene:scene];')
            with contextlib.redirect_stdout(io.StringIO()): check.check(path,'duo',tmp)
            for expression in ['UIScreen.mainScreen.bounds', '[[UIScreen mainScreen] bounds]']:
                source.write_text('initWithWindowScene:scene; window = '+expression+';')
                with self.assertRaises(ValueError): check.check(path,'duo',tmp)


if __name__ == '__main__': unittest.main()
