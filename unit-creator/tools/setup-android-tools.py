#!/usr/bin/env python3
"""Provision pinned official Android SDK35/build tools/optional NDKr28b inside ignored cloud storage."""
import argparse
import hashlib
import os
import pathlib
import platform
import shutil
import stat
import tempfile
import urllib.request
import zipfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
PREFIX = ROOT / "downloads/android-sdk"
PACKAGES = [
    ("platform-35_r02.zip", "0988cacad01b38a18a47bac14a0695f246bc76c1b06c0eeb8eb0dc825ab0c8e0", "platforms", "android-35/android.jar"),
    ("build-tools_r35_linux.zip", "bd3a4966912eb8b30ed0d00b0cda6b6543b949d5ffe00bea54c04c81e1561d88", "build-tools", "android-15/aapt2"),
    ("platform-tools_r37.0.1-linux.zip", "d230f13842f60f782a8645f9c813f8f845bf36089ea7289f28c48f17979313f1", "", "platform-tools/adb"),
]
NDK = ("android-ndk-r28b-linux.zip", "e9f2759862cecfd48c20bbb7d8cfedbb020f4d91b5f78d9a2fc106f7db3c27ed", "ndk", "android-ndk-r28b/toolchains/llvm/prebuilt/linux-x86_64/bin/clang")
EMULATOR = [
    ("emulator-linux_x64-16696583.zip", "2c234e5d38a9ac2f962acd80d5b724e87373e9fc7b632b3f39f7c01f4ff81ea5", "", "emulator/emulator"),
    ("sys-img/google_apis/x86_64-35_r09.zip", "c67b9ba0ff5bc0eb6d046871bfa228af14d4d47b02f0cdae94f048e511b7566e", "system-images/android-35/google_apis", "x86_64/system.img"),
]


def digest(path):
    with path.open("rb") as f: return hashlib.file_digest(f,"sha256").hexdigest()


def install(package, check):
    name, expected, folder, probe = package
    archive = PREFIX / pathlib.PurePosixPath(name).name
    if not archive.is_file() or digest(archive) != expected:
        if check: raise ValueError("Missing/changed official Android tool archive: " + name)
        with tempfile.TemporaryDirectory(prefix=".android-download-", dir=PREFIX) as tmp:
            # Repository URLs may have directories; the private staging file
            # uses the same basename as the verified persistent archive.
            candidate=pathlib.Path(tmp)/archive.name
            with urllib.request.urlopen("https://dl.google.com/android/repository/"+name) as source, candidate.open("wb") as dest: shutil.copyfileobj(source,dest)
            if digest(candidate) != expected: raise ValueError("Pinned official Android tool hash mismatch")
            candidate.replace(archive)
    target = PREFIX / folder
    if (target/probe).is_file(): return
    if check: raise ValueError("Pinned Android tools not extracted: " + probe)
    with zipfile.ZipFile(archive) as source:
        # Google's NDK archive contains relative aliases. Reject every absolute/escaping path or link.
        for entry in source.infolist():
            path=pathlib.PurePosixPath(entry.filename)
            if path.is_absolute() or ".." in path.parts: raise ValueError("Unsafe public SDK archive path")
            mode=entry.external_attr>>16
            if stat.S_ISLNK(mode):
                link=source.read(entry).decode()
                resolved=(target/path.parent/link).resolve()
                if not resolved.is_relative_to(target.resolve()): raise ValueError("Escaping public SDK archive alias")
        target.mkdir(parents=True,exist_ok=True)
        for entry in source.infolist():
            path=target/entry.filename;mode=entry.external_attr>>16
            if entry.is_dir(): path.mkdir(parents=True,exist_ok=True)
            elif stat.S_ISLNK(mode):
                path.parent.mkdir(parents=True,exist_ok=True)
                if not path.exists() and not path.is_symlink(): path.symlink_to(source.read(entry).decode())
            else:
                path.parent.mkdir(parents=True,exist_ok=True)
                with source.open(entry) as src,path.open('wb') as dst: shutil.copyfileobj(src,dst)
                os.chmod(path,mode&0o777 or 0o644)
    if not (target/probe).is_file(): raise ValueError("Official tool archive did not contain expected tool")


def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--check',action='store_true');parser.add_argument('--ndk',action='store_true');parser.add_argument('--emulator',action='store_true');args=parser.parse_args()
    if platform.system()!='Linux' or platform.machine()!='x86_64': raise SystemExit('This public Android tool bootstrap requires x86_64 Linux cloud')
    PREFIX.mkdir(parents=True,exist_ok=True)
    for package in PACKAGES+([NDK] if args.ndk else [])+(EMULATOR if args.emulator else []):install(package,args.check)
    if not args.check:
        lines=['# Official Android cloud build tools','','Pinned official Google HTTPS artifacts. First download verified against published SDK repository SHA1; SHA256 below is the committed reproducibility pin. No game data, APK, signing key or account file.','','SDK archive terms/notices remain in each extracted package; tools stay ignored in this repo.','']
        for name,digest,_,_ in PACKAGES+[NDK]+EMULATOR: lines.extend(['- https://dl.google.com/android/repository/'+name,'  SHA256: '+digest])
        (PREFIX/'SOURCE.md').write_text('\n'.join(lines)+'\n')
    print('Pinned official Android SDK35/build-tools35/platform-tools verified'+(' with NDKr28b' if args.ndk else '')+'.')


if __name__=='__main__':main()
