#!/usr/bin/env python3
"""Reuse a passed, byte-identical browser artifact for native-only source fixes.

Source subtree/blob identities and the committed input HTML must match. A changed
frontend/data input rebuilds normally. No previous check is relabeled as rerun.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import urllib.parse
import urllib.request

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / "unit-creator/cloud-ui/work/browser-reuse"
INPUTS = ["unit-creator/v2/ui", "unit-creator/web/src", "unit-creator/web/build.py", "unit-creator/web/standalone.py", "unit-creator/web/check-packed-page.py", "unit-creator/cloud-ui/build-browser.py"]
FILES = ["UnitCreator-test.html", "build-source.json", "verification.json", "preview.png"]
ARTIFACT_NAME = "unit-creator-browser-latest"
LABEL = "Browser"


def output(name, value):
    with open(os.environ["GITHUB_OUTPUT"], "a") as stream:
        stream.write(name + "=" + str(value) + "\n")


def api(path):
    request = urllib.request.Request("https://api.github.com/repos/mcantua/claude-chatg" + path,
        headers={"Authorization": "Bearer " + os.environ["GH_TOKEN"], "Accept": "application/vnd.github+json"})
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.load(response)


def head():
    return subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()


def identities():
    values = {}
    for path in INPUTS:
        entry = subprocess.check_output(["git", "ls-tree", "HEAD", "--", path], cwd=ROOT, text=True).strip()
        if not entry:
            raise RuntimeError("Browser source input is missing: " + path)
        values[path] = entry.split("\t")[0].split()[2]
    return values


def select():
    output("found", "false")
    if os.environ.get("GITHUB_REPOSITORY") != "mcantua/claude-chatg":
        return
    branch = os.environ["UC_SOURCE_BRANCH"]
    current = api("/actions/runs/" + os.environ["GITHUB_RUN_ID"])
    if current["path"] != ".github/workflows/unit-creator-cloud-native.yml":
        raise RuntimeError("Unexpected browser/native workflow")
    inputs = identities()
    artifacts = api("/actions/artifacts?" + urllib.parse.urlencode({"name": ARTIFACT_NAME, "per_page": 20}))["artifacts"]
    for artifact in artifacts:
        run = artifact.get("workflow_run", {})
        if artifact["expired"] or artifact["name"] != ARTIFACT_NAME or run.get("head_branch") != branch or run.get("id") == current["id"]:
            continue
        previous = api("/actions/runs/" + str(run["id"]))
        if previous["workflow_id"] != current["workflow_id"] or previous["path"] != current["path"]:
            continue
        baseline = run["head_sha"]
        tree = api("/git/trees/" + baseline + "?recursive=1")
        if tree.get("truncated"):
            continue
        saved = {entry["path"]: entry["sha"] for entry in tree["tree"]}
        if any(saved.get(path) != sha for path, sha in inputs.items()):
            continue
        WORK.mkdir(parents=True, exist_ok=True)
        (WORK / "candidate.json").write_text(json.dumps({"artifact_id": artifact["id"], "run_id": run["id"], "source_commit": baseline, "current_commit": head(), "source_inputs": inputs}, indent=2) + "\n")
        output("artifact_id", artifact["id"])
        output("run_id", run["id"])
        output("found", "true")
        print(LABEL + " source inputs match a previously passed artifact; verifying exact evidence before reuse.")
        return
    print(LABEL + " inputs changed or no passed artifact is available; build and check the current source.")


def verify():
    output("accepted", "false")
    candidate = json.loads((WORK / "candidate.json").read_text())
    downloaded = WORK / "artifact"
    if {p.name for p in downloaded.iterdir()} != set(FILES) or not all((downloaded / name).is_file() for name in FILES):
        raise RuntimeError("Unexpected browser evidence files")
    if candidate["current_commit"] != head() or candidate["source_inputs"] != identities():
        raise RuntimeError("Source changed during browser reuse")
    report = json.loads((downloaded / "build-source.json").read_text())
    check = json.loads((downloaded / "verification.json").read_text())
    digest = hashlib.sha256((downloaded / "UnitCreator-test.html").read_bytes()).hexdigest()
    previous_source = report.get("source_commit")
    if previous_source != candidate["source_commit"] or digest != report.get("html_sha256") or digest != check.get("html_sha256") or not check.get("checks") or not all(item.get("passed") is True for item in check["checks"]) or check.get("errors"):
        raise RuntimeError("Previous browser checks do not match the exact artifact")
    committed = hashlib.sha256((ROOT / "test-page/UnitCreator-test.html").read_bytes()).hexdigest()
    if committed not in (report.get("input_html_sha256"), digest):
        print("Committed game-data page changed; preserve it and rebuild rather than reuse.")
        return
    proof = {"run_id": candidate["run_id"], "artifact_id": candidate["artifact_id"], "verified_source_commit": previous_source, "source_inputs": candidate["source_inputs"], "html_sha256": digest, "checks_rerun": False}
    report["source_commit"] = head()
    report["reused_browser_verification"] = proof
    check["reused_browser_verification"] = proof
    destination = ROOT / "test-page"
    for name in FILES:
        part = (destination / name).with_suffix(Path(name).suffix + ".part")
        if name in ("build-source.json", "verification.json"):
            part.write_text(json.dumps(report if name == "build-source.json" else check, indent=2) + "\n")
        else:
            shutil.copyfile(downloaded / name, part)
        os.replace(part, destination / name)
    output("accepted", "true")
    print("Reused the exact passed HTML/checks: frontend code, packaging code and committed data input are unchanged. No browser tests repeated.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["select", "verify"])
    args = parser.parse_args()
    select() if args.action == "select" else verify()
