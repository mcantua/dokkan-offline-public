#!/usr/bin/env python3
"""Build the browser test from committed source while independent edits continue.

Uses one disposable source staging directory, never another working backup.
Only the two ignored database inputs are linked in. No Mac/network/signing work.
"""
import hashlib
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import tarfile
import tempfile

ROOT = Path(__file__).resolve().parents[2]
UNIT = ROOT / "unit-creator"


def main():
    source = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    out = UNIT / "out"
    out.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=".web-checkpoint-", dir=out) as temporary:
        stage = Path(temporary)
        archive = subprocess.check_output(["git", "archive", source, "unit-creator"], cwd=ROOT)
        with tarfile.open(fileobj=io.BytesIO(archive)) as files:
            files.extractall(stage, filter="data")
        work = stage / "unit-creator"
        assets = work / "apk/assets"
        assets.mkdir(parents=True, exist_ok=True)
        for name in ("reference.db", "sparking-reference.db"):
            original = UNIT / "apk/assets" / name
            if not original.is_file():
                raise SystemExit("Restore both private game databases before building the test page.")
            (assets / name).symlink_to(original.resolve())
        environment = os.environ.copy()
        environment["W"] = str(work)
        subprocess.run(["python3", "web/build.py"], cwd=work, env=environment, check=True)
        generated = stage / "test-page/UnitCreator-test.html"
        # Promote only after the complete requested build/bundle succeeds.
        for source_file, destination in [
            (generated, ROOT / "test-page/UnitCreator-test.html"),
            (work / "web/artifact-files.json", UNIT / "web/artifact-files.json"),
        ]:
            part = destination.with_suffix(destination.suffix + ".part")
            try:
                shutil.copyfile(source_file, part)
                os.replace(part, destination)
            finally:
                part.unlink(missing_ok=True)
        for name in ("site", "site-artifact", "site-ios", "ios-db"):
            destination = UNIT / "web" / name
            if destination.exists():
                shutil.rmtree(destination)
            shutil.move(str(work / "web" / name), destination)
        report = {
            "source_commit": source,
            "source": "Committed source only; concurrent uncommitted edits were excluded",
            "html_sha256": hashlib.sha256(generated.read_bytes()).hexdigest(),
            "html_bytes": generated.stat().st_size,
            "private_inputs_committed": False,
        }
        (ROOT / "test-page/build-source.json").write_text(json.dumps(report, indent=2) + "\n")
        print(json.dumps(report))


if __name__ == "__main__":
    main()
