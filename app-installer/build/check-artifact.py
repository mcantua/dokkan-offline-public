#!/usr/bin/env python3
"""Inspect unsigned artifacts. Passing never proves installation, layout or OS compatibility."""
import argparse
import json
from pathlib import Path
import plistlib
import re
import stat
import struct
import zipfile
import unicodedata

ORIENTATIONS = {'UIInterfaceOrientationPortrait', 'UIInterfaceOrientationPortraitUpsideDown',
                'UIInterfaceOrientationLandscapeLeft', 'UIInterfaceOrientationLandscapeRight'}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def inspect_macho(data):
    require(len(data) >= 32, 'Truncated executable header')
    magic, cpu, _, filetype, count, command_bytes, _, _ = struct.unpack_from('<8I', data)
    require(magic == 0xFEEDFACF and cpu == 0x0100000C and filetype == 2,
            'Expected arm64 Mach-O executable')
    require(32 + command_bytes <= len(data), 'Truncated Mach-O load command region')
    offset, end = 32, 32 + command_bytes
    versions = []
    for _ in range(count):
        require(offset + 8 <= end, 'Truncated Mach-O load command')
        command, size = struct.unpack_from('<II', data, offset)
        require(size >= 8 and size % 8 == 0 and offset + size <= end, 'Invalid Mach-O load command size')
        if command == 0x32:
            require(size >= 24, 'Truncated LC_BUILD_VERSION')
            versions.append(struct.unpack_from('<III', data, offset + 8))
        offset += size
    require(offset == end and len(versions) == 1, 'Expected one LC_BUILD_VERSION')
    return versions[0]


def check(path, variant, source_root=None):
    app = 'Payload/AppInstaller.app/'
    with zipfile.ZipFile(path) as z:
        names = z.namelist()
        require(len(names)<=20000,'Too many IPA entries')
        canonical=[];total=0;regular_paths=set();directory_paths=set()
        for entry in z.infolist():
            require('\\' not in entry.filename and not entry.filename.startswith('/'),'Unsafe IPA path')
            parts=Path(entry.filename).parts
            require('..' not in parts,'Unsafe IPA parent path')
            key=unicodedata.normalize('NFC',str(Path(entry.filename))).casefold()
            kind=stat.S_IFMT(entry.external_attr >> 16)
            if entry.is_dir():require(kind in {0,stat.S_IFDIR},'ZIP directory type/name conflict')
            else:require(kind in {0,stat.S_IFREG},'ZIP file type/name conflict')
            for index in range(1,len(Path(key).parts)):
                ancestor='/'.join(Path(key).parts[:index])
                require(ancestor not in regular_paths,'ZIP file used as an ancestor directory')
                directory_paths.add(ancestor)
            if entry.is_dir():require(key not in regular_paths,'ZIP file/directory conflict');directory_paths.add(key)
            else:require(key not in directory_paths,'ZIP directory replaced by regular file');regular_paths.add(key)
            canonical.append(key)
            total+=entry.file_size
            require(entry.file_size<=128*1024*1024 and total<=512*1024*1024,'IPA uncompressed size limit exceeded')
            require(entry.file_size<=1024*1024 or entry.file_size<=max(entry.compress_size,1)*1000,'IPA compression ratio limit exceeded')
        require(len(set(canonical))==len(canonical),'Canonical/case-alias IPA paths are forbidden')
        require(len(names) == len(set(names)), 'Duplicate ZIP entries')
        require(all(n.startswith(app) and '..' not in Path(n).parts and '\\' not in n and '\x00' not in n for n in names), 'Unexpected archive paths')
        require(all(stat.S_IFMT(i.external_attr >> 16) in {0,stat.S_IFREG,stat.S_IFDIR} for i in z.infolist()),'Special file in review artifact')
        p = plistlib.loads(z.read(app + 'Info.plist'))
        executable = z.read(app + 'AppInstaller')
        mode = z.getinfo(app + 'AppInstaller').external_attr >> 16
        require(mode & stat.S_IXUSR, 'Executable bit missing in archive')
        metadata = json.loads(z.read(app + 'BuildMetadata.json'))
        notices=z.read(app + 'ThirdPartyNotices.txt')
        notice_report=json.loads(z.read(app + 'ThirdPartyNoticeReport.json'))
        require(bool(notices.strip()) and notice_report.get('target')=='aarch64-apple-ios',
                'Missing locked third-party notices/report')
        require(notice_report.get('notice_gap_count')==len(notice_report.get('missing_notices',[])),
                'Notice gap report is inconsistent')
        for size,scale in [(120,2),(180,3)]:
            icon=z.read(app + f'AppIcon60x60@{scale}x.png')
            require(len(icon)>=33 and icon[:8]==b'\x89PNG\r\n\x1a\n', 'Missing valid app icon PNG')
            width,height=struct.unpack_from('>II',icon,16)
            require((width,height)==(size,size) and icon[25]==2, 'Expected opaque RGB icon of correct size')
        require(not any(n.endswith(('.p12', '.p8', '.pem', '.key', '.mobiledevicepairing')) for n in names),
                'Private signing/pairing file included in artifact')
        require(app + 'embedded.mobileprovision' not in names, 'Review artifact must remain unsigned')
    platform, minimum, sdk = inspect_macho(executable)
    genuine = metadata.get('synthetic_sdk_marker') is False
    if genuine:
        marker=metadata.get('compilation_sdk','')
        parts=tuple(int(part) for part in marker.split('.'))
        require(parts >= (27,1),'Genuine device candidates require SDK27.1 or newer')
        expected_mark=(parts[0]<<16)|((parts[1] if len(parts)>1 else 0)<<8)|(parts[2] if len(parts)>2 else 0)
        require(metadata.get('requested_sdk_mark')==marker,'Candidate must use its actual SDK marker')
        require(metadata.get('designation')=='unsigned-candidate','Unsigned candidate cannot be designated final')
        toolchain=metadata.get('genuine_toolchain',{})
        require(toolchain.get('sdk_version')==marker and bool(re.fullmatch(r'[0-9a-f]{64}',toolchain.get('sdk_settings_sha256',''))),
                'Actual SDK provenance is missing')
        require(notice_report.get('notice_obligations_satisfied') is True and notice_report.get('notice_gap_count')==0,
                'Candidate contains unresolved license obligations')
        require(notice_report.get('distribution_requirements_satisfied') is True,'Matching source/relink delivery missing')
        receipt=notice_report.get('corresponding_source',{})
        require(receipt.get('sha256')==metadata.get('source_bundle_sha256') and receipt.get('source_tree_sha256')==metadata.get('source_tree_sha256')
                and receipt.get('locked_dependency_graph_hash')==metadata.get('locked_dependency_graph_hash'),
                'IPA/source/relink binding mismatch')
    else:
        expected_mark = (27 << 16 | 1 << 8) if variant == 'duo' else (16 << 16 | 5 << 8)
        marker = '27.1' if variant == 'duo' else '16.5'
    require(platform == 2 and minimum == (16 << 16 | 4 << 8), 'Incorrect iOS platform/minimum version')
    require(sdk == expected_mark, 'Incorrect requested/actual SDK marker')
    require(p.get('DTSDKName') == 'iphoneos' + marker and p.get('DTPlatformVersion') == marker,
            'SDK plist marker does not match executable')
    require(p.get('MinimumOSVersion') == '16.4', 'Incorrect minimum OS plist value')
    require(p.get('CFBundleIdentifier') == 'org.tin.appinstaller', 'Unexpected bundle identity')
    require(p.get('CFBundleExecutable') == 'AppInstaller', 'Unexpected executable identity')
    require(p.get('CFBundleIcons',{}).get('CFBundlePrimaryIcon',{}).get('CFBundleIconFiles') == ['AppIcon60x60'],
            'Missing primary icon manifest')
    require(p.get('UIDeviceFamily') == [1], 'Only iPhone is supported')
    require('UIRequiresFullScreen' not in p, 'UIRequiresFullScreen must be absent')
    require('UILaunchScreen' in p, 'Missing launch screen')
    require(set(p.get('UISupportedInterfaceOrientations', [])) == ORIENTATIONS, 'Missing orientations')
    configurations = p.get('UIApplicationSceneManifest', {}).get('UISceneConfigurations', {})
    scenes = configurations.get('UIWindowSceneSessionRoleApplication', [])
    require(any(s.get('UISceneDelegateClassName') == 'AIScene' for s in scenes), 'Missing scene delegate')
    require(p.get('BGTaskSchedulerPermittedIdentifiers') == ['org.tin.appinstaller.refresh'],
            'Missing refresh scheduler identifier')
    require('fetch' in p.get('UIBackgroundModes', []), 'Missing background refresh mode')
    require(bool(re.fullmatch(r'[0-9a-f]{64}',str(metadata.get('source_tree_sha256','')))),
            'Missing exact source-tree fingerprint')
    require(metadata.get('unsigned') is True and metadata.get('variant') == variant,
            'Missing honest review-artifact metadata')
    require((genuine or metadata.get('compilation_sdk') == '16.5') and metadata.get('requested_sdk_mark') == marker,
            'Incorrect SDK provenance metadata')
    require(metadata.get('phone_install_attempted') is False and metadata.get('duo_device_layout_verified') is False,
            'Artifact must not claim device installation/layout verification')
    if source_root:
        source = '\n'.join(p.read_text() for p in (Path(source_root)/'app-installer/ios').glob('*.m'))
        require('initWithWindowScene:' in source, 'UIWindows must be created from their scene')
        require(not re.search(r'UIScreen\s*(?:\.\s*)?mainScreen', source),
                'Screen-based window sizing is forbidden')
    print(f'{variant} artifact checks passed. Device install, rail layout, folding and OS compatibility remain UNVERIFIED.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('ipa')
    parser.add_argument('variant', choices=('iphone', 'duo'))
    parser.add_argument('--source-root', type=Path)
    args = parser.parse_args()
    check(args.ipa, args.variant, args.source_root)
