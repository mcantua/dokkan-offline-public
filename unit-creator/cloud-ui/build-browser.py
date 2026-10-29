#!/usr/bin/env python3
"""Build a complete current browser page using the prior real embedded snapshot.

No private raw database is fetched/committed. Reconstruction provenance is kept
separately; the data is an actual supplied snapshot, not a synthetic fixture.
"""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[2]
UNIT = ROOT / "unit-creator"


def main():
    page = ROOT / "test-page/UnitCreator-test.html"
    original_hash = hashlib.sha256(page.read_bytes()).hexdigest()
    work = UNIT / "cloud-ui/work/browser"
    work.mkdir(parents=True, exist_ok=True)
    provenance = work / "data-provenance.json"
    subprocess.run(["python3", str(UNIT / "cloud-ui/reconstruct-data.py"), "--output", str(work / "db"), "--report", str(provenance)], cwd=ROOT, check=True)
    assets = UNIT / "apk/assets"
    assets.mkdir(parents=True, exist_ok=True)
    for name in ("reference.db", "sparking-reference.db"):
        destination = assets / name
        if destination.exists():
            raise SystemExit("Hosted browser packaging will not replace an existing private database.")
        shutil.copyfile(work / "db" / name, destination)
    environment = os.environ.copy()
    environment["TEST_PAGE_VERSION"] = "2.36.3 (test)"
    environment["TEST_PAGE_CHANGES"] = "Animation previews, movie editing, portable backups and safer recovery."
    subprocess.run(["python3", "web/build.py"], cwd=UNIT, env=environment, check=True)
    report = {
        "source_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
        "source": "Current committed code; real supplied data reconstructed from previous standalone page",
        "input_html_sha256": original_hash,
        "html_sha256": hashlib.sha256(page.read_bytes()).hexdigest(),
        "html_bytes": page.stat().st_size,
        "data_reconstruction": json.loads(provenance.read_text()),
        "private_inputs_committed": False,
    }
    (ROOT / "test-page/build-source.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({k: report[k] for k in ("source_commit", "html_sha256", "html_bytes")}))


if __name__ == "__main__":
    main()
