#!/usr/bin/env python3
"""Retain matched candidate/source + native-kit artifacts, scoped to this workflow.

--pair: CANDIDATE_ARTIFACT_ID and KIT_ARTIFACT_ID; a partial new pair is
removed without touching the previous pair. Default: DIAGNOSTIC_ARTIFACT_ID.
All modes require GITHUB_REPOSITORY, GITHUB_RUN_ID and GH_TOKEN. API requests
use only https://api.github.com; no configurable endpoint can receive the token.
"""
import argparse
import json
import os
import re
import sys
import urllib.request

CANDIDATE = 'app-installer-cloud-ui-latest'
KIT = 'app-installer-native-kit-latest'
DIAGNOSTIC = 'app-installer-cloud-tests-latest'
OWNED_NAMES = frozenset((CANDIDATE, KIT, DIAGNOSTIC))


def number(value):
    if isinstance(value, bool) or not re.fullmatch(r'[1-9][0-9]*', str(value)):
        raise ValueError('Invalid GitHub numeric identifier')
    return int(value)


class GitHub:
    def __init__(self, repository, token):
        if not re.fullmatch(r'[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+', repository):
            raise ValueError('Invalid GitHub repository')
        self.base = f'https://api.github.com/repos/{repository}/actions'
        self.headers = {'Authorization': f'Bearer {token}',
                        'Accept': 'application/vnd.github+json',
                        'X-GitHub-Api-Version': '2022-11-28'}

    def get(self, path):
        request = urllib.request.Request(self.base + path, headers=self.headers)
        with urllib.request.urlopen(request, timeout=30) as response:
            return json.load(response)

    def delete(self, artifact_id):
        request = urllib.request.Request(self.base + f'/artifacts/{number(artifact_id)}',
                                         headers=self.headers, method='DELETE')
        with urllib.request.urlopen(request, timeout=30):
            pass


def prune(api, run_id, supplied):
    """Validate all ownership before any deletion; api is injectable for offline tests."""
    run_id = number(run_id)
    if set(supplied) not in ({CANDIDATE, KIT}, {DIAGNOSTIC}):
        raise ValueError('Artifact names are outside the retention contract')
    current = api.get(f'/runs/{run_id}')
    if number(current['id']) != run_id:
        raise ValueError('Current workflow run mismatch')
    workflow_id = number(current['workflow_id'])
    run_number = number(current['run_number'])
    run_cache = {run_id: current}
    provided = {}
    for name, artifact_id in supplied.items():
        if not artifact_id:
            continue
        artifact_id = number(artifact_id)
        item = api.get(f'/artifacts/{artifact_id}')
        if (number(item['id']) != artifact_id or item['name'] != name
                or number(item['workflow_run']['id']) != run_id
                or item.get('expired') is not False):
            raise ValueError('Current artifact ownership or availability mismatch')
        provided[name] = artifact_id
    if not provided:
        return 0
    if len(provided) != len(supplied):
        # A new source without a matching kit (or vice versa) cannot supersede
        # the previous complete license/source pair.
        for artifact_id in provided.values():
            api.delete(artifact_id)
        return len(provided)

    pending = {}
    page = 1
    while True:
        batch = api.get(f'/artifacts?per_page=100&page={page}')['artifacts']
        if not isinstance(batch, list) or len(batch) > 100:
            raise ValueError('Malformed artifact listing')
        for item in batch:
            if item.get('name') not in supplied:
                continue
            artifact_id = number(item['id'])
            if artifact_id in provided.values():
                continue
            old_id = number(item['workflow_run']['id'])
            if old_id == run_id:
                continue
            if old_id not in run_cache:
                run_cache[old_id] = api.get(f'/runs/{old_id}')
            old = run_cache[old_id]
            if number(old['id']) != old_id:
                raise ValueError('Historical workflow run mismatch')
            # Run number, unlike upload completion time, preserves a newer
            # concurrent run when an older run finishes late.
            if (number(old['workflow_id']) == workflow_id
                    and number(old['run_number']) < run_number):
                pending[artifact_id] = item['name']
        if len(batch) < 100:
            break
        page += 1
    # Delete old binaries first. If any API deletion fails, their source
    # companions remain available for every retained old native kit.
    for artifact_id in sorted(pending, key=lambda identity: (pending[identity] != KIT, identity)):
        api.delete(artifact_id)
    return len(pending)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--pair', action='store_true')
    args = parser.parse_args()
    names = ({CANDIDATE: os.environ.get('CANDIDATE_ARTIFACT_ID', ''),
              KIT: os.environ.get('KIT_ARTIFACT_ID', '')} if args.pair else
             {DIAGNOSTIC: os.environ.get('DIAGNOSTIC_ARTIFACT_ID', '')})
    try:
        api = GitHub(os.environ['GITHUB_REPOSITORY'], os.environ['GH_TOKEN'])
        removed = prune(api, os.environ['GITHUB_RUN_ID'], names)
    except Exception:
        # Never print headers, bearer tokens or response bodies on CI failure.
        print('Artifact retention failed safely; ownership could not be verified.', file=sys.stderr)
        return 1
    print(f'Artifact retention completed; removed {removed} owned artifacts.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
