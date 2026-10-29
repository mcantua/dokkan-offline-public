#!/usr/bin/env python3
"""Provision pinned public LLVM/iOS SDK into ignored repo storage; no app build or signing."""
import argparse
import hashlib
import importlib.util
import os
import pathlib
import platform
import shutil
import subprocess
import tempfile
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[2]
PREFIX = pathlib.Path(os.environ.get("UC_NATIVE_TOOLS", ROOT / "downloads/unit-creator-tools"))
JDK_URL = "https://deb.debian.org/debian/pool/main/o/openjdk-21/openjdk-21-jdk-headless_21.0.12.1+1-1~deb13u1_amd64.deb"
JDK_SHA256 = "f3abafb6c644b03df042824e707cd211ea33254761d7f7b75be3f8dc0df97c7a"
JRE_URL = "https://deb.debian.org/debian/pool/main/o/openjdk-21/openjdk-21-jre-headless_21.0.12.1+1-1~deb13u1_amd64.deb"
JRE_SHA256 = "e95f36193e45464ac758e5436f940bf3eaecc77de67188275a42104f58aa7674"


def setup_jdk():
    home = PREFIX / "jdk/usr/lib/jvm/java-21-openjdk-amd64"
    if (home / "lib/ct.sym").is_file() and (home / "lib/modules").is_file(): return home
    PREFIX.mkdir(parents=True, exist_ok=True)
    if (PREFIX / "jdk").exists(): raise ValueError("Incomplete existing JDK preserved; choose a fresh ignored UC_NATIVE_TOOLS directory")
    with tempfile.TemporaryDirectory(prefix="jdk-", dir=PREFIX) as tmp:
        stage = pathlib.Path(tmp) / "root"
        for name,url,digest in [("jdk",JDK_URL,JDK_SHA256),("jre",JRE_URL,JRE_SHA256)]:
            package=pathlib.Path(tmp)/(name+".deb")
            with urllib.request.urlopen(url) as response,package.open("wb") as out: shutil.copyfileobj(response,out)
            if hashlib.sha256(package.read_bytes()).hexdigest()!=digest: raise ValueError("Pinned Java package checksum mismatch")
            subprocess.run(["dpkg-deb","-x",str(package),str(stage)],check=True)
        # Debian configuration links refer to /etc; keep supplied config inside our private tool prefix.
        for link in stage.rglob("*"):
            if link.is_symlink():
                target=os.readlink(link)
                if target.startswith("/") and (stage/target.lstrip("/")).exists():
                    link.unlink();link.symlink_to(os.path.relpath(stage/target.lstrip("/"),link.parent))
        stage.replace(PREFIX / "jdk")
    return home


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="check current tools without downloads")
    parser.add_argument("--java-only", action="store_true", help="prepare matching pinned Java only, without LLVM/iOS SDK")
    args = parser.parse_args()
    if platform.system() != "Linux" or platform.machine() != "x86_64":
        raise SystemExit("This pinned tool bootstrap supports x86_64 Linux cloud environments only.")
    if args.java_only:
        if not args.check: setup_jdk()
        subprocess.run([str(ROOT / "unit-creator/tools/javac"),"-version"],check=True)
        print("Pinned matching Java compiler/runtime ready; no native app was built.")
        return
    # Reuse the existing pinned SHA-256 package/SDK bootstrap without editing App Installer source.
    spec = importlib.util.spec_from_file_location("native_bootstrap", ROOT / "app-installer/build/setup-linux.py")
    bootstrap = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(bootstrap)
    bootstrap.configure_downloads(PREFIX)
    if not args.check:
        bootstrap.setup_llvm()
        bootstrap.setup_sdk()
        setup_jdk()
    env = bootstrap.environment()
    for tool in [PREFIX / "llvm/root/usr/lib/llvm-19/bin/clang", PREFIX / "llvm/root/usr/lib/llvm-19/bin/ld64.lld"]:
        subprocess.run([str(tool), "--version"], env=env, check=True)
    subprocess.run([str(ROOT / "unit-creator/tools/javac"), "-version"], check=True)
    subprocess.run([str(ROOT / "unit-creator/tools/jar"), "--version"], check=True)
    sdk = PREFIX / "apple-sdk/source/iPhoneOS16.5.sdk"
    if not (sdk / "SDKSettings.plist").is_file():
        raise FileNotFoundError("Pinned iPhoneOS SDK is missing")
    if not args.check:
        lines = ["# Unit Creator cloud native tools", "", "Public build tools only; no app or signing data.",
                 "", "SDK: https://github.com/theos/sdks at " + bootstrap.SDK_COMMIT,
                 "LLVM packages are verified against the SHA-256 pins in app-installer/build/setup-linux.py.",
                 "Java: pinned Debian JDK tools/ct.sym and matching OpenJDK21.0.12.1 JRE. Existing complete installations may retain verified matching host runtime read-only links.", "", "Pinned packages:"]
        for package, digest in bootstrap.PACKAGES.items():
            lines.extend(["- " + bootstrap.SNAPSHOT + package + "_19.1.7-3+b1_amd64.deb", "  SHA-256: " + digest])
        lines.extend(["- " + JDK_URL, "  SHA-256: " + JDK_SHA256])
        lines.extend(["- " + JRE_URL, "  SHA-256: " + JRE_SHA256])
        lines.extend(["", "LLVM: Apache-2.0 with LLVM exception. OpenJDK: GPL-2.0 with Classpath exception. SDK content remains subject to Apple's terms.",
                      "Extracted SDK/tools are ignored and not redistributed in the source repo."])
        (PREFIX / "SOURCE.md").write_text("\n".join(lines) + "\n")
    print("Native compiler/SDK ready. Android release still requires the original base APK and private release key.")


if __name__ == "__main__":
    main()
