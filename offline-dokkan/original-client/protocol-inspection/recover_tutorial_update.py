#!/usr/bin/env python3
"""Recover the exact reviewed tutorial-update bodies for bounded continuation.

This is static pin recovery. It does not enable a route, invoke the client,
assert a complete HTTP envelope, or emit instructions/addresses publicly.
"""
import argparse
import hashlib
import json
from pathlib import Path
import sys

HERE=Path(__file__).resolve().parent
sys.path[:0]=[str(HERE),str(HERE.parents[1]/'tools')]
from objc_runtime_metadata import Image
from inspect_handler_fields import function_starts,sections_and_symbols
SOURCE_SHA='efaabfc9b3cdb0e2eeb550b6ea616f5eeb565c6584ad838b765f34539648d222'
PINS={
    'tutorial_update_constructor':(264,'66cc64dc0f5a6e6aebac1be862333c95390af9a2d7f271fead11c924cdc75f9b'),
    'game_api_constructor':(712,'0179754c18025710cf1672a8ec5f131523c81832475d593f8c1952e0c0e2da05'),
    'request_ancestor_constructor':(352,'a0eba4837b88cc8ec757d5d3bb467a73b86b0d8ff6753c672cb21db8f7307e0b'),
    'common_request_constructor':(420,'9d8e134af30873e345b61ff3542d2e85399c549c0b1f1331843c9807c5865910'),
    'request_materializer':(1284,'829cd9c45cd0d3cae4d795b9ea842cae3e14d24310ddafb085a8c026cf6cbe37'),
    'request_method_getter':(8,'a26061eb76af386891a60b091a9a312b796ec48c788d8f4d2246855d112fa845'),
    'request_body_setter':(240,'fcc67747f8c0a63511d413f51a0acaca1aa7cd95c76b841711ba6aa056cfc6d9'),
    'progress_json_numeric_constructor':(36,'1ef574139ccdd31f39eb0b9cb40860d91bb786224b249ee52e9883e3f0521726'),
    'timewarp_json_numeric_constructor':(32,'323596a073066664c12710422f1f39c1dbb50966d4bbb75e07e9ac3179d80438'),
    'url_builder':(664,'4192af9cd1485f8a3402f6497c6f92669b60a55d006ff99e0ebfb5e2112df663'),
    'relative_suffix_builder':(248,'3d0d976939e884fea40c87de204fba3db90f3956b8043df15133898ca8202a11'),
}


def recover(source):
    if source.stat().st_size!=55697728:raise ValueError('Source size mismatch')
    data=source.read_bytes()
    if hashlib.sha256(data).hexdigest()!=SOURCE_SHA:raise ValueError('Source identity mismatch')
    image=Image(data);starts=function_starts(image);sections,_,_=sections_and_symbols(image)
    text,size,_,_=sections[b'__text'];ends=starts[1:]+[text+size]
    by_identity={(size,sha):role for role,(size,sha) in PINS.items()}
    sizes={size for size,_ in PINS.values()};found={}
    for start,end in zip(starts,ends):
        size=end-start
        if size not in sizes or not text<=start<end<=text+sections[b'__text'][1]:continue
        offset=image.offset(start,size);sha=hashlib.sha256(data[offset:offset+size]).hexdigest()
        role=by_identity.get((size,sha))
        if role:
            if role in found:raise ValueError('Ambiguous body identity')
            found[role]={'role':role,'start':start,'end':end,'bytes':size,'sha256':sha}
    if set(found)!=set(PINS):raise ValueError('Required tutorial request bodies unavailable')
    return {'source_sha256':SOURCE_SHA,'body_spans':[found[k] for k in sorted(found)]}


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('source',type=Path);p.add_argument('--private-output',type=Path,required=True)
    args=p.parse_args()
    private_root=(HERE.parents[1]/'private').resolve()
    try:args.private_output.resolve().relative_to(private_root)
    except ValueError:raise SystemExit('Detailed spans must stay in the ignored project private directory.')
    try:
        result=recover(args.source)
        args.private_output.parent.mkdir(parents=True,exist_ok=True)
        args.private_output.write_text(json.dumps(result,indent=2)+'\n')
    except (ValueError,OSError):raise SystemExit('Tutorial request pin recovery failed; no source values emitted.')
    print('Reviewed tutorial request body pins recovered; no route or runtime acceptance granted.')


if __name__=='__main__':main()
