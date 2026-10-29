#!/usr/bin/env python3
"""Package the assembled own diagnostic for normal external signing/install.

This does not sign the app or establish launch/playability. Original game bytes
and the resulting IPA stay in the ignored private cloud workspace.
"""
import argparse
import hashlib
import json
from pathlib import Path
import plistlib
import stat
import zipfile


def package(app, output):
    app, output = Path(app), Path(output)
    private = Path(__file__).resolve().parents[2] / "private"
    # Refuse external trees, symlinks, replacement and unrelated applications.
    for path in (app, output):
        path.relative_to(private)
        if any(parent.is_symlink() for parent in (path, *path.parents)):
            raise ValueError("A regular private diagnostic path is required")
    if app.suffix != ".app" or output.suffix != ".ipa" or output.exists():
        raise ValueError("An assembled diagnostic and absent IPA output are required")
    info = plistlib.loads((app / "Info.plist").read_bytes())
    receipt = json.loads((app / "package-receipt.json").read_bytes())
    if info.get("CFBundleIdentifier") != "org.offlinedokkan.startupdiagnostic.duo":
        raise ValueError("Only the own original-client diagnostic can be packaged")
    # The assembler receipt is retained in the archive, including its source
    # hashes and explicit unsigned/unverified status.
    if receipt.get("playable_build") is not False or receipt.get("code_signed") is not False:
        raise ValueError("An explicit unsigned diagnostic receipt is required")
    members = []
    for item in sorted(app.rglob("*")):
        mode = item.lstat().st_mode
        if stat.S_ISLNK(mode) or not (stat.S_ISDIR(mode) or stat.S_ISREG(mode)):
            raise ValueError("Unexpected special file in the assembled diagnostic")
        if stat.S_ISREG(mode):
            members.append(item)
    with zipfile.ZipFile(output, "x", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for item in members:
            archive.write(item, str(Path("Payload") / app.name / item.relative_to(app)))
    with output.open("rb") as source:
        digest = hashlib.file_digest(source, "sha256").hexdigest()
    return {"label": "Diagnostic", "signed": False, "installation_verified": False,
            "playable": False, "bytes": output.stat().st_size, "sha256": digest,
            "version": info.get("CFBundleShortVersionString"),
            "build": info.get("CFBundleVersion"), "files": len(members)}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--app", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    print(json.dumps(package(args.app, args.output), indent=2))
