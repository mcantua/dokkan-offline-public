#!/usr/bin/env python3
"""Publish only the verified HTML/check metadata using the scoped Actions token.

Git transport supports the complete self-contained media runtime without the
connector's per-request body limit. No token is written to a file or printed.
"""
import base64
import json
import os
from pathlib import Path
import subprocess
import urllib.request

ROOT = Path(__file__).resolve().parents[2]
FILES = ["test-page/UnitCreator-test.html", "test-page/build-source.json", "test-page/verification.json", "test-page/preview.png"]


def main():
    repository = os.environ["GITHUB_REPOSITORY"]
    if repository != "mcantua/claude-chatg":
        raise SystemExit("Unexpected publication repository")
    branch, expected = os.environ["UC_SOURCE_BRANCH"], os.environ["UC_SOURCE_HEAD"]
    if not branch.startswith("chatgpt/"):
        print("Verified browser artifact is available; automatic commits are restricted to this chat's source branches.")
        return
    subprocess.run(["git", "check-ref-format", "--branch", branch], cwd=ROOT, check=True, stdout=subprocess.DEVNULL)
    report = json.loads((ROOT / "test-page/build-source.json").read_text())
    if report["source_commit"] != expected:
        raise SystemExit("Generated browser page does not match the requested source commit")
    if not all((ROOT / name).is_file() for name in FILES):
        raise SystemExit("Verified page, preview or report is missing")
    environment = os.environ.copy()
    token = os.environ["GH_TOKEN"]
    credential = base64.b64encode(("x-access-token:" + token).encode()).decode()
    environment.update(GIT_CONFIG_COUNT="1", GIT_CONFIG_KEY_0="http.https://github.com/.extraheader", GIT_CONFIG_VALUE_0="AUTHORIZATION: basic " + credential,
                       GIT_TRACE="0", GIT_TRACE_CURL="0", GIT_CURL_VERBOSE="0")
    def git(*args, capture=False):
        result = subprocess.run(["git", *args], cwd=ROOT, env=environment, check=True, text=True,
                                stdout=subprocess.PIPE if capture else None)
        return result.stdout.strip() if capture else None
    git("fetch", "--no-tags", "origin", branch)
    if git("rev-parse", "FETCH_HEAD", capture=True) != expected:
        print("Source branch advanced; verified HTML stays downloadable as an artifact. No source was overwritten.")
        return
    if git("rev-parse", "HEAD", capture=True) != expected:
        raise SystemExit("Publication checkout differs from the requested source")
    git("add", "--", *FILES)
    unchanged = subprocess.run(["git", "diff", "--cached", "--quiet"], cwd=ROOT).returncode == 0
    if unchanged:
        print("Browser page already matches the current source.")
        return
    git("-c", "user.name=github-actions[bot]", "-c", "user.email=41898282+github-actions[bot]@users.noreply.github.com",
        "commit", "-m", "Overwrite current self-contained Unit Creator test page from verified source")
    git("push", "--force-with-lease=refs/heads/" + branch + ":" + expected, "origin", "HEAD:refs/heads/" + branch)
    print("Updated only the current test HTML and its measured check files.")
    # Prune only older browser artifacts belonging to this workflow after successful promotion.
    artifact_id = int(os.environ["UC_BROWSER_ARTIFACT_ID"])
    run_id = int(os.environ["GITHUB_RUN_ID"])
    headers = {"Authorization": "Bearer " + token, "Accept": "application/vnd.github+json"}
    api = "https://api.github.com/repos/" + repository
    def request(path, method="GET"):
        with urllib.request.urlopen(urllib.request.Request(api + path, headers=headers, method=method), timeout=30) as response:
            return json.loads(response.read()) if method == "GET" else None
    current = request("/actions/runs/" + str(run_id))
    if current["path"] != ".github/workflows/unit-creator-cloud-native.yml":
        raise SystemExit("Unexpected workflow; no evidence was removed")
    page = 1
    remove = []
    while True:
        artifacts = request("/actions/artifacts?name=unit-creator-browser-latest&per_page=100&page=" + str(page))["artifacts"]
        for artifact in artifacts:
            if artifact["id"] == artifact_id or artifact["name"] != "unit-creator-browser-latest":
                continue
            previous = request("/actions/runs/" + str(artifact["workflow_run"]["id"]))
            if previous["workflow_id"] == current["workflow_id"] and previous["path"] == current["path"]:
                remove.append(artifact["id"])
        if len(artifacts) < 100:
            break
        page += 1
    for identifier in remove:
        request("/actions/artifacts/" + str(identifier), "DELETE")


if __name__ == "__main__":
    main()
