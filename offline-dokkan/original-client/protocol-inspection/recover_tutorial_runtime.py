#!/usr/bin/env python3
"""Restore exact original tutorial entry/PUT ownership spans, never execute them.

Uses the existing pinned Mach-O body recovery. Raw coordinates stay private;
public source contains only lengths/hashes of reviewed compiled functions.
"""
import argparse
import json
from pathlib import Path

from recover_tutorial_update import HERE, recover

PINS = {
    'title_finished_gate': (172, 'b87838acc47bcbbf8f73e78b523bfc09f51bed3e0a4e4a41914fa8e62cef685f'),
    'title_on_tutorial_progress': (512, '9728db44c9a1455664b83a9e4345b1f6ad86d7d81e2f39e9dab092a68234b065'),
    'tutorial_cache_owner': (608, 'c6f54e5ebf0d379205c2eb411ce3a49c8dce10ee6d039fa328276c2d9b8b1c6b'),
    'tutorial_progress_composer': (240, '819e4c38b7050fc076ff728550d1a8559d6db011931bf52949f2ceea457378a2'),
    'tutorial_process_selection': (172, '63ecffe1791720a49a50a75b0bede3ee4cb4f5c0bd0d6da722f9561b38155093'),
    'tutorial_ordered_process_models': (372, 'a370654d1ca32ae3bc606db5ce8fa5b2a6253d12853df1abf3404f72d43845bd'),
    'tutorial_next_process_progress': (44, '893740f6091c409547c568d7c5eff6f1f79b1b02466d05d512dba838401068ba'),
    'tutorial_checkpoint_issue_caller': (396, '31f79b16b13109248eacf34599a702df94ee6a1b4342603122b34524ca40b5e5'),
    'tutorial_update_request_factory': (80, '171f90c4c45111a06e7c5272e1f984ca79b7cdb6f50f384f5de1c9bb30471ebe'),
    'tutorial_model_put_progress': (808, '93af9ff8e8b2807f75a640c9ef879e4a1861649b91df6ac8e202148ab4bca56a'),
    'tutorial_update_success_completion': (32, '2db50733ec5810e3807303629062ffbf7d44bf6d89b7263be93783ae7ce7dfb9'),
    'tutorial_update_failure_completion': (156, 'd5f7298783e8492d42ada0019bb3d8b462458028fb9cf1f492fbd7200cd6a88f'),
    'game_api_task_factory': (164, 'e43723bc0d548772a8c4048f1adda0902513105012ae07a109a8379e9b7317a3'),
    'game_api_task_constructor': (464, '2b4406934c18de27d69c32b95527140db0972a045177879908217fc1ab600f4d'),
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('--private-output', type=Path, required=True)
    args = parser.parse_args()
    try:
        args.private_output.resolve().relative_to((HERE.parents[1] / 'private').resolve())
    except ValueError:
        raise SystemExit('Runtime spans must stay in the ignored project private directory.')
    try:
        result = recover(args.source, PINS)
        args.private_output.parent.mkdir(parents=True, exist_ok=True)
        args.private_output.write_text(json.dumps(result, indent=2) + '\n')
    except (OSError, ValueError):
        raise SystemExit('Tutorial runtime pin recovery stopped; no source values emitted.')
    print('Reviewed tutorial runtime body pins recovered; no policy, route or client execution admitted.')


if __name__ == '__main__':
    main()
