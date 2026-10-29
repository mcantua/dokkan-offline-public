#!/usr/bin/env python3
"""Fetch SHA-pinned public smali2.5.2 tools into ignored cloud storage; never builds an APK."""
import argparse
import hashlib
import pathlib
import shutil
import tempfile
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[2]
PREFIX = ROOT / "downloads/unit-creator-smali"
PACKAGES = [
    ('org/smali', 'smali', '2.5.2', '136c5c4653d6531bd7b6f10f35f8691cb96432e727d30b4d5579826ee01e9419'),
    ('org/smali', 'baksmali', '2.5.2', '1ed236266d7dc4907aade0b19a34f77efac25342b63c8ace52e579039941b389'),
    ('org/smali', 'dexlib2', '2.5.2', '5a5c8982d8bd7d6e3bb1a0713049e3c78b719ec32b20f6b619885cec30a0dd61'),
    ('org/smali', 'util', '2.5.2', '4f580a9cff3ebb83cb3fd20bec88e37e4f183796ca652732992611620282daea'),
    ('org/antlr', 'antlr', '3.5.2', '5ac36c2acfb0a0f3d37dafe20b5b570f2643e2d000c648d44503c2738be643df'),
    ('org/antlr', 'antlr-runtime', '3.5.2', 'ce3fc8ecb10f39e9a3cddcbb2ce350d272d9cd3d0b1e18e6fe73c3b9389c8734'),
    ('org/antlr', 'stringtemplate', '3.2.1', 'f66ce72e965e5301cb0f020e54d2ba6ad76feb91b3cbfc30dbbf00c06a6df6d7'),
    ('antlr', 'antlr', '2.7.7', '88fbda4b912596b9f56e8e12e580cc954bacfb51776ecfddd3e18fc1cf56dc4c'),
    ('com/beust', 'jcommander', '1.64', '156be736199c990321d9ff77090b199629cfc9865e2d6c13f7cd291bb1641817'),
    ('com/google/guava', 'guava', '27.1-android', '686404f2d1d4d221911f96bd627ff60dac2226a5dfa6fb8ba517073eb97ec0ef'),
    ('com/google/guava', 'failureaccess', '1.0.1', 'a171ee4c734dd2da837e4b16be9df4661afab72a41adaf31eb84dfdaf936ca26'),
    ('com/google/guava', 'listenablefuture', '9999.0-empty-to-avoid-conflict-with-guava', 'b372a037d4230aa57fbeffdef30fd6123f9c0c2db85d0aced00c91b974f33f99'),
    ('com/google/code/findbugs', 'jsr305', '3.0.2', '766ad2a0783f2687962c8ad74ceecc38a28b9f72a2d085ee438b7813e928d0c7'),
    ('org/checkerframework', 'checker-compat-qual', '2.5.2', 'd7291cebf5e158d169807ae49d4b16ff672986f0c6d803e5f207c40cb61ef982'),
    ('com/google/errorprone', 'error_prone_annotations', '2.2.0', '6ebd22ca1b9d8ec06d41de8d64e0596981d9607b42035f9ed374f9de271a481a'),
    ('com/google/j2objc', 'j2objc-annotations', '1.1', '2994a7eb78f2710bd3d3bfb639b2c94e219cedac0d4d084d516e78c16dddecf6'),
]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    PREFIX.mkdir(parents=True, exist_ok=True)
    source = ["# Pinned Android smali tools", "", "Public Maven Central artifacts, fetched over HTTPS and SHA256 verified. No app, database or signing data.", "", "Versions/hashes below are pinned in unit-creator/tools/setup-smali.py. smali/dexlib2/util: BSD-3-Clause; ANTLR2: public domain; ANTLR3/StringTemplate: BSD; Guava/error-prone/J2ObjC: Apache-2.0; JCommander: Apache-2.0; jsr305: BSD-3-Clause; checker annotations: MIT.", ""]
    for group, artifact, version, digest in PACKAGES:
        name = artifact + "-" + version + ".jar"
        url = "https://repo.maven.apache.org/maven2/" + group + "/" + artifact + "/" + version + "/" + name
        destination = PREFIX / name
        if not destination.is_file() or hashlib.sha256(destination.read_bytes()).hexdigest() != digest:
            if args.check: raise ValueError("Missing or changed pinned public tool: " + name)
            with tempfile.TemporaryDirectory(prefix=".download-", dir=PREFIX) as tmp:
                candidate = pathlib.Path(tmp) / name
                with urllib.request.urlopen(url) as response, candidate.open("wb") as out: shutil.copyfileobj(response, out)
                if hashlib.sha256(candidate.read_bytes()).hexdigest() != digest: raise ValueError("Pinned public tool hash mismatch: " + name)
                candidate.replace(destination)
        source.extend(["- " + url, "  SHA256: " + digest])
    if not args.check: (PREFIX / "SOURCE.md").write_text("\n".join(source) + "\n")
    print("Pinned smali/baksmali tool set verified; no APK was built.")


if __name__ == "__main__": main()
