#!/usr/bin/env python3
"""Provision pinned local build tools without root or shell-profile changes.

Requires x86_64 Linux, Python 3, git, dpkg-deb, and the Debian 13 LLVM19 runtime
(libLLVM.so.19.1 plus its normal shared-library dependencies). Everything this
script downloads/extracts stays in downloads/ beneath the single repository.
"""
import argparse
import ctypes
from datetime import datetime
from zoneinfo import ZoneInfo
import hashlib
import json
import os
from pathlib import Path
import platform
import shutil
import subprocess
import tempfile
import urllib.request

ROOT = Path(__file__).resolve().parents[2]
DOWNLOADS = ROOT / 'downloads'
LLVM = DOWNLOADS / 'llvm'
RUST = DOWNLOADS / 'rust-toolchain'
SDK = DOWNLOADS / 'apple-sdk'
SNAPSHOT = 'https://snapshot.debian.org/archive/debian/20260925T181338Z/pool/main/l/llvm-toolchain-19/'
PACKAGES = {
    'clang-19': 'bbb74458d782b7792b61b0eed92746df5e6d033778c045cf8c2b3835b7c4efc4',
    'libclang-common-19-dev': '4018e40e2d4144fe38c45822e68cca63c1bf6c7872c3073ebb262ad4b2f9b8bc',
    'libclang-cpp19': 'a7d2b6df51050834f6ea5c0d5e34869c2298b0bcdaa91eff17ba3db2cd545c47',
    'lld-19': '756a805e8811d527dd2b5417f016c9342b8631fa9c1ddcd56265c13ae33bf3a4',
    'llvm-19': '0b1b7263f4f45e261099240fdbf00fc14b42b88410fd829e041bf83ea45866cb',
}
SDK_COMMIT = '0222fd5413cf4b9af096f37b4621afa2688572f7'
RUST_VERSION = '1.99.1'
RUSTUP_VERSION = '1.28.2'
HOST_PACKAGES = {
    'libllvm19':'1:19.1.7-3+b1', 'libc6':'2.41-12+deb13u4',
    'libstdc++6':'14.2.0-19', 'libgcc-s1':'14.2.0-19', 'libgcc-14-dev':'14.2.0-19',
    'gcc-14-base':'14.2.0-19', 'libffi8':'3.4.8-2', 'libedit2':'3.1-20250104-1',
    'libz3-4':'4.13.3-1', 'zlib1g':'1:1.3.dfsg+really1.3.1-1+b1',
    'libzstd1':'1.5.7+dfsg-1', 'libxml2':'2.12.7+dfsg+really2.9.14-2.1+deb13u3',
    'libtinfo6':'6.5+20250216-2', 'libbsd0':'0.12.2-2',
    'liblzma5':'5.8.1-1+deb13u1', 'libmd0':'1.1.0-2+b1', 'binutils':'2.44-3',
}
PROVENANCE = []


def configure_downloads(path):
    global DOWNLOADS, LLVM, RUST, SDK
    selected = Path(path).resolve()
    selected.relative_to((ROOT/'downloads').resolve())
    DOWNLOADS = selected
    LLVM, RUST, SDK = selected/'llvm', selected/'rust-toolchain', selected/'apple-sdk'


def record_provenance(status, error=None, phase='full'):
    DOWNLOADS.mkdir(parents=True, exist_ok=True)
    previous = (DOWNLOADS/'SOURCE.md').read_text() if phase == 'rust-only' and (DOWNLOADS/'SOURCE.md').exists() else ''
    timestamp = datetime.now(ZoneInfo('America/Chicago')).strftime('%Y-%m-%d %-I:%M %p US Central')
    text = '# Isolated Linux toolchain reproduction\n\n'
    text += f'Latest setup: {timestamp}\nResult: {status}\nPhase: {phase}\n'
    if error: text += 'Failure category: '+error+'\n'
    text += '\nCloud-only provisioning. No MacBook, personal internet, Apple account or phone was used. No backups created.\n'
    text += '\nPinned host runtime/CRT prerequisites (not downloaded or replaced by this script):\n'
    for name, version in HOST_PACKAGES.items(): text += f'- {name} {version}\n'
    text += '\nHost Python/git/dpkg-deb are setup utilities; all Rust/C compilers, archiver, linker, iOS SDK, Cargo registry cache and build output use the isolated prefix.\n'
    text += f'\nRust {RUST_VERSION}; rustup bootstrap {RUSTUP_VERSION}. SDK repository https://github.com/theos/sdks at {SDK_COMMIT}.\n'
    text += '\nDownloaded archives (SHA-256):\n'
    for item in PROVENANCE: text += f'- {item["url"]}\n  SHA-256: {item["sha256"]}\n'
    text += '\nObserved local tool identities:\n'
    env = environment()
    for tool in [RUST/'cargo/bin/rustup',RUST/'cargo/bin/rustc',LLVM/'root/usr/lib/llvm-19/bin/clang',LLVM/'root/usr/lib/llvm-19/bin/llvm-ar']:
        if tool.is_file():
            version = subprocess.check_output([str(tool),'--version'],env=env,text=True,stderr=subprocess.DEVNULL).splitlines()[0]
            text += '- '+version+'\n'
            if tool.name == 'rustup': text += '  Installed binary SHA-256: '+hashlib.sha256(tool.read_bytes()).hexdigest()+'\n'
    text += '\nLicense: Rust MIT/Apache-2.0; LLVM Apache-2.0 with LLVM exception. SDK content remains governed by Apple terms. Tool/SDK artifacts exceed50MB and are not committed.\n'
    if previous: text += '\n## Earlier complete-prefix attempt evidence\n\n'+previous
    (DOWNLOADS/'SOURCE.md').write_text(text)



def run(args, **kwargs):
    subprocess.run([str(a) for a in args], check=True, **kwargs)


def fetch(url, destination, expected=None):
    request = urllib.request.Request(url, headers={'User-Agent': 'AppInstaller-cloud-build'})
    with urllib.request.urlopen(request) as response, destination.open('wb') as stream:
        shutil.copyfileobj(response, stream)
    digest = hashlib.sha256(destination.read_bytes()).hexdigest()
    if expected and digest != expected:
        destination.unlink(missing_ok=True)
        raise ValueError('Download checksum mismatch: ' + url)
    PROVENANCE.append({'url':url,'sha256':digest})
    return digest


def environment():
    env = os.environ.copy()
    env['CARGO_HOME'] = str(RUST/'cargo')
    env['RUSTUP_HOME'] = str(RUST/'rustup')
    env['TMPDIR'] = str(RUST/'tmp')
    env['LD_LIBRARY_PATH'] = str(LLVM/'root/usr/lib/x86_64-linux-gnu')
    return env


def setup_llvm():
    if (LLVM/'root/usr/lib/llvm-19/bin/llvm-ar').is_file() and (LLVM/'root/usr/lib/llvm-19/bin/clang').is_file():
        return
    LLVM.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='setup-', dir=LLVM) as tmp:
        tmp = Path(tmp)
        for package, checksum in PACKAGES.items():
            name = package + '_19.1.7-3+b1_amd64.deb'
            deb = tmp/name
            fetch(SNAPSHOT + name, deb, checksum)
            if package != 'llvm-19':
                run(['dpkg-deb', '-x', deb, LLVM/'root'])
            else:
                stage = tmp/'llvm-extra'
                run(['dpkg-deb', '-x', deb, stage])
                dest = LLVM/'root/usr/lib/llvm-19/bin'
                dest.mkdir(parents=True, exist_ok=True)
                shutil.copy2(stage/'usr/lib/llvm-19/bin/llvm-ar', dest/'llvm-ar')
                (dest/'llvm-ranlib').unlink(missing_ok=True)
                (dest/'llvm-ranlib').symlink_to('llvm-ar')
                shutil.copytree(stage/'usr/share/doc/llvm-19', LLVM/'root/usr/share/doc/llvm-19', dirs_exist_ok=True)


def setup_rust():
    RUST.mkdir(parents=True, exist_ok=True)
    (RUST/'tmp').mkdir(exist_ok=True)
    try:
        env = environment()
        rustup = RUST/'cargo/bin/rustup'
        if not rustup.is_file():
            with tempfile.TemporaryDirectory(prefix='setup-', dir=RUST) as tmp:
                installer = Path(tmp)/'rustup-init'
                url = f'https://static.rust-lang.org/rustup/archive/{RUSTUP_VERSION}/x86_64-unknown-linux-gnu/rustup-init'
                checksum_file = Path(tmp)/'rustup-init.sha256'
                fetch(url + '.sha256', checksum_file)
                expected = checksum_file.read_text().split()[0]
                digest = fetch(url, installer, expected)
                installer.chmod(0o700)
                run([installer, '-y', '--profile', 'minimal', '--default-toolchain', RUST_VERSION,
                     '--no-modify-path'], env=env)
                # Record the bootstrap hash without replacing existing human-maintained provenance.
                note = RUST/'BOOTSTRAP.json'
                note.write_text(json.dumps({'url': url, 'sha256': digest}, indent=2) + '\n')
        run([rustup, 'set', 'auto-self-update', 'disable'], env=env)
        run([rustup, 'toolchain', 'install', RUST_VERSION, '--profile', 'minimal'], env=env)
        run([rustup, 'default', RUST_VERSION], env=env)
        run([rustup, 'target', 'add', '--toolchain', RUST_VERSION, 'aarch64-apple-ios'], env=env)
    finally:
        shutil.rmtree(RUST/'tmp', ignore_errors=True)


def setup_sdk():
    if (SDK/'source/iPhoneOS16.5.sdk/SDKSettings.plist').is_file():
        return
    SDK.mkdir(parents=True, exist_ok=True)
    # A transient sparse checkout fetches only this SDK. Git metadata is removed on success.
    with tempfile.TemporaryDirectory(prefix='setup-', dir=SDK) as tmp:
        source = Path(tmp)/'source'
        run(['git', 'clone', '--filter=blob:none', '--no-checkout', '--depth', '1',
             'https://github.com/theos/sdks.git', source])
        run(['git', '-C', source, 'sparse-checkout', 'set', 'iPhoneOS16.5.sdk'])
        run(['git', '-C', source, 'fetch', '--depth', '1', 'origin', SDK_COMMIT])
        run(['git', '-C', source, 'checkout', '--detach', SDK_COMMIT])
        actual = subprocess.check_output(['git', '-C', str(source), 'rev-parse', 'HEAD'], text=True).strip()
        if actual != SDK_COMMIT:
            raise ValueError('Unexpected SDK revision')
        shutil.rmtree(source/'.git')
        if (SDK/'source').exists():
            raise RuntimeError('Existing incomplete SDK directory; review before replacing it')
        shutil.move(str(source), SDK/'source')


def check():
    env = environment()
    tools = [RUST/'cargo/bin/rustup', RUST/'cargo/bin/rustc', LLVM/'root/usr/lib/llvm-19/bin/clang', LLVM/'root/usr/lib/llvm-19/bin/llvm-ar']
    for tool in tools:
        if not tool.is_file():
            raise FileNotFoundError('Missing local tool: ' + str(tool))
        run([tool, '--version'], env=env)
    if not (SDK/'source/iPhoneOS16.5.sdk/SDKSettings.plist').is_file():
        raise FileNotFoundError('Missing pinned iOS SDK')
    print('Local tools/SDK found. This check does not build or install an app.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true', help='check existing toolchain without downloading')
    parser.add_argument('--downloads-root', type=Path, help='isolated tools/cache prefix beneath this repo downloads/')
    parser.add_argument('--rust-only', action='store_true', help='repair/reprovision only Rust in an explicit isolated prefix; retain fresh LLVM/SDK')
    args = parser.parse_args()
    if args.rust_only and not args.downloads_root: parser.error('--rust-only requires an explicit --downloads-root')
    if args.downloads_root: configure_downloads(args.downloads_root)
    if platform.system() != 'Linux' or platform.machine() != 'x86_64':
        raise RuntimeError('This provisioning script supports x86_64 Linux only')
    for command in ('git', 'dpkg-deb', 'dpkg-query'):
        if not shutil.which(command):
            raise RuntimeError('Required host tool is missing: ' + command)
    # Explicitly validate the host runtime/CRT baseline; do not silently borrow unpinned compilers.
    for package, expected in HOST_PACKAGES.items():
        actual = subprocess.check_output(['dpkg-query','-W','-f=${Version}',package],text=True).strip()
        if actual != expected:
            raise RuntimeError(f'Pinned host prerequisite mismatch: {package} requires {expected}, observed {actual}')
    ctypes.CDLL('libLLVM.so.19.1')
    try:
        if not args.check:
            if not args.rust_only: setup_llvm()
            setup_rust()
            if not args.rust_only: setup_sdk()
        check()
        if args.downloads_root: record_provenance('PASSED' if not args.check else 'EXISTING-TOOLS CHECK ONLY',phase='rust-only' if args.rust_only else 'full')
    except Exception as error:
        if args.downloads_root: record_provenance('FAILED', type(error).__name__,phase='rust-only' if args.rust_only else 'full')
        raise


if __name__ == '__main__':
    main()
