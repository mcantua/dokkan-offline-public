#!/usr/bin/env python3
"""Keep only current evidence from this workflow; never touch other projects or package artifacts."""
import json
import os
import sys
import urllib.request

REPOSITORY = os.environ["GITHUB_REPOSITORY"]
BASE = "https://api.github.com/repos/" + REPOSITORY
HEADERS = {"Authorization": "Bearer " + os.environ["GH_TOKEN"], "Accept": "application/vnd.github+json", "X-GitHub-Api-Version": "2022-11-28"}


def request(path, method="GET"):
    with urllib.request.urlopen(urllib.request.Request(BASE + path, headers=HEADERS, method=method)) as response:
        return json.loads(response.read()) if method == "GET" else None


def main():
    if sys.argv[1:] not in ([],["--android"]): raise ValueError("Unsupported artifact retention scope")
    name="unit-creator-android-native-latest" if sys.argv[1:] else "unit-creator-native-latest"
    keep = int(os.environ["UC_ARTIFACT_ID"])
    run = request("/actions/runs/" + str(int(os.environ["GITHUB_RUN_ID"])))
    if run["path"] != ".github/workflows/unit-creator-cloud-native.yml":
        raise ValueError("Unexpected source workflow; no artifact removed")
    current = request("/actions/artifacts/" + str(keep))
    if current["name"] != name or current["workflow_run"]["id"] != run["id"]:
        raise ValueError("Current uploaded artifact identity differs; no artifact removed")
    remove = []
    page = 1
    while True:
        artifacts = request("/actions/artifacts?name="+name+"&per_page=100&page=" + str(page))["artifacts"]
        for artifact in artifacts:
            if artifact["id"] == keep or artifact["name"] != current["name"]: continue
            previous = request("/actions/runs/" + str(artifact["workflow_run"]["id"]))
            if previous["workflow_id"] == run["workflow_id"] and previous["path"] == run["path"]:
                remove.append(artifact["id"])
        if len(artifacts) < 100: break
        page += 1
    for artifact in remove: request("/actions/artifacts/" + str(artifact), "DELETE")
    print("Kept current Unit Creator native evidence; removed " + str(len(remove)) + " older matching artifacts.")


if __name__ == "__main__": main()
