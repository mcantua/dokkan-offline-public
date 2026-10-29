#!/usr/bin/env python3
"""Read-only direct-call frontier for the original master's startup lifetime.

Decodes only ARM64 B/BL immediates, never strings, data or key-provider bodies.
The graph is syntactic: indirect calls, reachability and thread lifetime remain
unproven. Raw addresses are retained only in ignored private research output.
"""
import argparse
from bisect import bisect_right
from collections import defaultdict, deque
import hashlib
import json
from pathlib import Path
import struct

from inspect_master_root import ROOT, SOURCE_BYTES, SOURCE_HASH, Image, function_starts


def sections(image):
    result = {}
    position = 32
    for _ in range(image.unpack("I", 16)[0]):
        command, size = image.unpack("II", position)
        if command == 0x19:
            for index in range(image.unpack("I", position + 64)[0]):
                at = position + 72 + index * 80
                name = image.data[at:at + 16].split(b"\0", 1)[0]
                if name in (b"__text", b"__init_offsets"):
                    if name in result:
                        raise ValueError("Duplicate selected section")
                    address, count, offset = image.unpack("QQI", at + 32)
                    if count % 4 or image.offset(address, count) != offset:
                        raise ValueError("Invalid selected section")
                    result[name] = (address, count, offset)
        position += size
    if set(result) != {b"__text", b"__init_offsets"}:
        raise ValueError("Selected sections missing")
    return result


def inspect(source):
    if source.stat().st_size != SOURCE_BYTES:
        raise ValueError("Changed source size")
    data = source.read_bytes()
    if hashlib.sha256(data).hexdigest() != SOURCE_HASH:
        raise ValueError("Changed prepared engine")
    image = Image(data)
    starts = function_starts(image)
    contract = json.loads((ROOT / "offline-dokkan/research/original-master-main-contract.json").read_text())
    scope = json.loads((ROOT / "offline-dokkan/private/ghidra/native-master-callable.private.json").read_text())
    key_start, key_end = contract["open_and_key"]["key_string_provider_vm_range"]
    targets = {entry["label"]: int(entry["address"], 16)
               for entry in scope["functions"][:5]}
    targets["master_selected_entry"] = contract["path"]["selected_entry_vm_range"][0]
    if scope["expected_source_sha256"] != SOURCE_HASH:
        raise ValueError("Changed scope")
    selected = sections(image)
    text, text_bytes, text_offset = selected[b"__text"]
    init, init_bytes, init_offset = selected[b"__init_offsets"]
    initializers = {image.base + value[0] for value in
                    struct.iter_unpack("<I", data[init_offset:init_offset + init_bytes])}
    if len(initializers) > 16384 or not all(text <= value < text + text_bytes for value in initializers):
        raise ValueError("Invalid initializer frontier")
    incoming = defaultdict(list)
    excluded_words = 0
    for offset, (word,) in enumerate(struct.iter_unpack("<I", data[text_offset:text_offset + text_bytes])):
        address = text + offset * 4
        if key_start <= address < key_end:
            excluded_words += 1
            continue
        # ARM64 immediate B and BL. Do not interpret other instructions/data.
        if word & 0x7c000000 != 0x14000000:
            continue
        displacement = word & 0x3ffffff
        if displacement & 0x2000000:
            displacement -= 0x4000000
        target = address + displacement * 4
        if not text <= target < text + text_bytes:
            continue
        owner_index = bisect_right(starts, address) - 1
        if owner_index < 0:
            continue
        owner = starts[owner_index]
        # Internal branches are CFG edges, not inter-function call edges.
        if owner == target or (owner_index + 1 < len(starts) and owner <= target < starts[owner_index + 1]):
            continue
        incoming[target].append({"owner": owner, "site": address,
                                 "kind": "BL" if word & 0x80000000 else "B"})

    private = {"source_sha256": SOURCE_HASH, "targets": {}}
    public = {}
    for label, target in targets.items():
        if target not in starts:
            raise ValueError("Reviewed target is not a function start")
        index = starts.index(target)
        end = starts[index + 1]
        body_sha = hashlib.sha256(data[image.offset(target):image.offset(end)]).hexdigest()
        frontier = deque([(target, [])])
        seen = {target}
        initializer_paths = []
        # Bound exploration; no inference through indirect or unresolved calls.
        while frontier and len(seen) <= 50000:
            current, chain = frontier.popleft()
            if current in initializers:
                initializer_paths.append([current] + chain)
            if len(chain) == 8:
                continue
            for call in incoming.get(current, []):
                owner = call["owner"]
                if owner not in seen:
                    seen.add(owner)
                    frontier.append((owner, [current] + chain))
        direct = incoming.get(target, [])
        private["targets"][label] = {"target": target, "body_sha256": body_sha,
            "direct_incoming": direct, "initializer_paths": initializer_paths}
        public[label] = {"body_sha256": body_sha, "direct_incoming_branch_sites": len(direct),
            "direct_caller_function_count": len({call["owner"] for call in direct}),
            "direct_initializer_callers": sum(call["owner"] in initializers for call in direct),
            "initializer_syntactic_paths_within_eight_edges": len(initializer_paths),
            "shortest_initializer_syntactic_path_edges": min((len(path) - 1 for path in initializer_paths), default=None),
            "reverse_functions_considered": len(seen), "reverse_frontier_capped": bool(frontier),
            "call_graph_is_syntactic_only": True}
    destination = ROOT / "offline-dokkan/private/research-master/lifecycle-frontier.private.json"
    destination.write_text(json.dumps(private, indent=2) + "\n")
    return {"schema": "original-master-lifecycle-frontier-v1", "source_sha256": SOURCE_HASH,
        "method": "Fixed ARM64 B/BL immediate decoding and LC_FUNCTION_STARTS ownership; no function-body semantics",
        "initializer_count": len(initializers), "max_reverse_edges": 8,
        "key_provider_words_excluded": excluded_words, "targets": public,
        "limits": {"client_executed": False, "key_provider_body_followed": False,
            "source_key_data_read": False, "indirect_call_graph_complete": False,
            "initializer_path_runtime_reachable_proven": False, "no_initializer_path_means_safe": False,
            "seed_copied_to_downloaded_path_proven": False, "native_master_attached": False,
            "safe_close_reopen_abi_admitted": False, "public_raw_addresses_or_disassembly": False}}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    if args.output.resolve() == args.source.resolve():
        raise SystemExit("Input engine preserved")
    try:
        result = inspect(args.source)
        args.output.write_text(json.dumps(result, indent=2) + "\n")
    except (OSError, ValueError, KeyError, IndexError):
        raise SystemExit("Master lifecycle inspection stopped; source preserved")
    print("Master lifecycle branch frontier recorded; no engine execution or key-provider inspection")


if __name__ == "__main__":
    main()
