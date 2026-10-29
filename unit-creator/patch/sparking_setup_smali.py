#!/usr/bin/env python3
"""Replace only SprkCodec's two APK-key entry points in a baksmali directory.

Usage: python3 patch/sparking_setup_smali.py <baksmali-output-directory>
Idempotent; rejects missing/ambiguous methods before writing anything.
"""
import pathlib
import re
import sys


def patch(directory):
    path = pathlib.Path(directory) / "com/personal/aihub/SprkCodec.smali"
    source = path.read_text()
    changed = source
    for name, returns in [("keyFromApk", "[B"), ("databaseKeyFromApk", "Ljava/lang/String;")]:
        signature = name + "(Ljava/io/File;)" + returns
        pattern = re.compile(r"(?m)^\.method[^\n]*\b" + re.escape(signature) + r"\n.*?^\.end method", re.S)
        matches = list(pattern.finditer(changed))
        if len(matches) != 1:
            raise ValueError(signature + ": expected exactly one method")
        header = matches[0].group().splitlines()[0]
        if " static " not in header:
            raise ValueError(signature + ": expected a static method")
        replacement = header + "\n    .locals 1\n\n    invoke-static {p0}, Lcom/personal/aihub/SparkingSetup;->" + signature + "\n\n    move-result-object v0\n\n    return-object v0\n.end method"
        changed = changed[:matches[0].start()] + replacement + changed[matches[0].end():]
    if changed != source:
        path.write_text(changed)
    print("Sparking APK setup hooks ready (6.5.5 and 6.6; keys remain user supplied)")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    patch(sys.argv[1])
