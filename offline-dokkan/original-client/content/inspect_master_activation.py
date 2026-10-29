#!/usr/bin/env python3
"""Recover reviewed original master activation identities, never keys or rows.

The private scoped-analysis manifests supply addresses. Public output contains
only exact hashes, reviewed source labels/signatures and fixed file/event names.
This does not execute a client, database, callback or source-owned close API.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

from inspect_master_root import ROOT, SOURCE_BYTES, SOURCE_HASH, Image, function_starts

SCOPES = (
    "native-master-lifecycle-callers.private.json",
    "native-master-open-upstream.private.json",
    "native-master-listener-producer.private.json",
    "native-master-resource-cleanup.private.json",
    "native-master-open-outer.private.json",
    "native-master-thread-producer.private.json",
)


def inspect(source):
    if source.stat().st_size != SOURCE_BYTES:
        raise ValueError("Changed source size")
    data = source.read_bytes()
    if hashlib.sha256(data).hexdigest() != SOURCE_HASH:
        raise ValueError("Changed source")
    image = Image(data)
    starts = function_starts(image)
    bodies = {}
    for filename in SCOPES:
        scope = json.loads((ROOT / "offline-dokkan/private/ghidra" / filename).read_text())
        if scope["expected_source_sha256"] != SOURCE_HASH:
            raise ValueError("Changed scope")
        for entry in scope["functions"]:
            address = int(entry["address"], 16)
            if address not in starts or not 0 < entry["bytes"] <= 4096:
                raise ValueError("Invalid reviewed body")
            end = starts[starts.index(address) + 1]
            body = data[image.offset(address):image.offset(end)]
            if len(body) != entry["bytes"] or hashlib.sha256(body).hexdigest() != entry["sha256"]:
                raise ValueError("Changed reviewed body")
            bodies[entry["label"]] = {"bytes": len(body), "sha256": entry["sha256"]}

    callback_scope = json.loads((ROOT / "offline-dokkan/private/ghidra" / SCOPES[0]).read_text())
    target = next(int(entry["address"], 16) for entry in callback_scope["functions"]
                  if entry["label"] == "master_reopen_callback")
    matches = []
    for location, value in image.rebases.items():
        if value != target:
            continue
        address_point = location - 6 * 8
        try:
            if image.at("q", address_point - 16)[0] != 0:
                continue
            type_info = image.pointer(address_point - 8)
            name = image.string(image.pointer(type_info + 8), 16384)
        except (ValueError, UnicodeError):
            continue
        if not name.startswith("NSt3__110__function6__funcI"):
            continue
        result = subprocess.run(["c++filt", "-t", "--", name], capture_output=True,
                                text=True, timeout=10)
        if result.returncode or len(result.stdout) > 32768:
            raise ValueError("RTTI decoding failed")
        demangled = result.stdout.strip()
        expected_origin = "DialogDatabaseDownloadLayer::setFetchAssetEventListeners()::$_2"
        if (expected_origin not in demangled or not demangled.endswith("void (cocos2d::EventCustom*)>")):
            raise ValueError("Unexpected callback identity")
        matches.append({"private_address_point": address_point,
                        "private_type_info": type_info, "private_demangled": demangled})
    if len(matches) != 1:
        raise ValueError("Ambiguous native activation callback")
    (ROOT / "offline-dokkan/private/research-master/activation-callable.private.json").write_text(
        json.dumps(matches, indent=2) + "\n")
    return {"schema": "original-master-native-activation-v1", "source_sha256": SOURCE_HASH,
        "method": "Pinned source body identity and selected libc++ RTTI metadata; bounded assembly/Ghidra semantic review",
        "bodies": bodies,
        "reviewed_callback": {"origin": "DialogDatabaseDownloadLayer::setFetchAssetEventListeners()::$_2",
            "signature": "void(cocos2d::EventCustom*)", "virtual_slot": 6,
            "registered_event": "EVENT_NET_FILE_DOWNLOAD_SUCCESS", "path_filter": "/database.db$"},
        "reviewed_first_open_thread": {"producer_bytes": 364, "entry_bytes": 276,
            "entry_passed_to_pthread_create": True, "thread_detached": True,
            "entry_initializes_libcxx_thread_local_data": True,
            "calls_master_initialization_before_scheduling_completion": True,
            "host_may_invoke_worker_or_callback_directly": False},
        "native_preferred_master_validation": {"source_role": "DatabaseManager::removeOldPragmaKeyDatabase",
            "uses_original_opaque_key": True, "key_provider_body_followed": False,
            "open_or_schema_failure_cleanup": True,
            "cleanup_removes_candidate_file": True,
            "cleanup_recursively_removes_native_relative_tree": "sqlite/current/",
            "candidate_file_remove_import": "remove", "tree_cleanup_import": "nftw",
            "cached_handle_closed_and_cleared_after_check": True},
        "limits": {"client_executed": False, "keys_or_database_rows_read": False,
            "host_callable_abi_admitted": False, "runtime_quiescence_proven": False,
            "current_android_cipher_accepted_by_iphone": False, "seed_to_downloaded_master_copy_proven": False,
            "original_master_attached": False, "raw_addresses_or_code_emitted_publicly": False}}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    if args.source.resolve() == args.output.resolve():
        raise SystemExit("Input engine preserved")
    try:
        output = inspect(args.source)
        args.output.write_text(json.dumps(output, indent=2) + "\n")
    except (OSError, ValueError, KeyError, IndexError, StopIteration, subprocess.TimeoutExpired):
        raise SystemExit("Master activation inspection stopped; source preserved")
    print("Original master activation identity recorded; no client, key or database execution")


if __name__ == "__main__":
    main()
