#!/usr/bin/env python3
"""Pinned early-initializer and allowlisted network-binding admission inventory.

No code is executed, modified or disassembled. Unknown symbols/classes/paths and
raw source strings are never emitted. A plan is not initializer containment.
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / "tools"))
from objc_runtime_metadata import Image

SOURCE_SHA = "9d6bf0470c4b4ff7d914740ccf9f1622afa962b763e18bfcf1f6e051bfae0610"
SOURCE_BYTES = 55697728
ALIASES = {"_connect": "_od_cnct", "_connectx": "_od_cncxx",
           "_getaddrinfo": "_od_dns_fail", "_send": "_od_s",
           "_sendto": "_od_snd", "_socket": "_od_skt",
           "_socketpair": "_od_spairxx"}
EXTRA_NETWORK = frozenset(("_connect_nocancel", "_connect$NOCANCEL", "_sendmsg",
    "_sendto_nocancel", "_CFStreamCreatePairWithSocketToHost", "_CFSocketConnectToAddress",
    "_nw_connection_create", "_nw_connection_start", "_nw_browser_start",
    "_curl_easy_perform", "_curl_multi_perform", "_curl_multi_socket_action",
    "_DNSServiceQueryRecord", "_DNSServiceGetAddrInfo", "_DNSServiceBrowse"))
ESCAPES = frozenset(("_dlopen", "_dlsym", "_syscall", "_NSClassFromString",
                    "_NSSelectorFromString"))


def inspect(path):
    path = Path(path)
    if path.stat().st_size != SOURCE_BYTES:
        raise ValueError("Wrong source")
    data = path.read_bytes()
    if hashlib.sha256(data).hexdigest() != SOURCE_SHA:
        raise ValueError("Changed source")
    image = Image(data)
    libraries, sections, segments, fixups = [], [], [], None
    position = 32
    routines = 0
    for _ in range(image.unpack("I", 16)[0]):
        command, size = image.unpack("II", position)
        if command == 0x19:
            vm, amount, offset, file_bytes = image.unpack("QQQQ", position + 24)
            initial = image.unpack("I", position + 60)[0]
            segment_name = data[position + 8:position + 24].split(b"\0", 1)[0]
            segments.append((vm, amount, offset, file_bytes, initial, segment_name))
            for index in range(image.unpack("I", position + 64)[0]):
                p = position + 72 + index * 80
                name = data[p:p + 16].split(b"\0", 1)[0]
                address, length, file_offset = image.unpack("QQI", p + 32)
                flags = image.unpack("I", p + 64)[0]
                if file_offset + length > len(data) and flags & 0xff not in (1, 0x12):
                    raise ValueError("Section outside image")
                sections.append((name, address, length, file_offset, flags))
        elif command in (0xc, 0x80000018, 0x8000001f, 0x80000023, 0x20):
            p = image.unpack("I", position + 8)[0]
            if not 24 <= p < size:
                raise ValueError("Bad dependency")
            name = data[position + p:position + size].split(b"\0", 1)
            if len(name) != 2:
                raise ValueError("Bad dependency")
            libraries.append(name[0])
        elif command == 0x80000034:
            if fixups is not None:
                raise ValueError("Duplicate fixups")
            fixups = image.unpack("II", position + 8)
        elif command in (0x11, 0x1a):
            routines += 1
        position += size
    if image.chain_formats != {6} or fixups is None:
        raise ValueError("Unsupported pointer format")
    text = [(vm, length) for name, vm, length, _, _ in sections if name == b"__text"]
    if len(text) != 1:
        raise ValueError("Missing unique text section")
    initializers = []
    for name, vm, length, offset, flags in sections:
        if name not in (b"__init_offsets", b"__mod_init_func", b"__mod_term_func",
                        b"__objc_nlclslist", b"__objc_nlcatlist", b"__thread_init"):
            continue
        width = 4 if name == b"__init_offsets" else 8
        if length % width or length > 1024 * 1024:
            raise ValueError("Invalid startup section")
        targets_in_text = None
        if name == b"__init_offsets":
            targets = [image.base + x[0] for x in struct.iter_unpack("<I", data[offset:offset + length])]
            targets_in_text = all(x % 4 == 0 and text[0][0] <= x < text[0][0] + text[0][1]
                                  for x in targets)
        initializers.append({"section": name.decode(), "entries": length // width,
            "section_type": flags & 0xff,
            "table_sha256": hashlib.sha256(data[offset:offset + length]).hexdigest(),
            "targets_in_text": targets_in_text, "bodies_audited": False})
    offset, size = fixups
    version, _, imports, symbols, count, fmt, symbol_format = image.unpack("7I", offset)
    if (version != 0 or fmt != 3 or symbol_format != 0 or count > 65536 or
            not 28 <= imports <= size or imports + count * 16 > symbols or symbols >= size):
        raise ValueError("Unsupported imports")
    records, selected, extra, escapes = [], {}, [], []
    for index in range(count):
        raw, addend = image.unpack("Qq", offset + imports + index * 16)
        name_offset = raw >> 32
        if name_offset >= size - symbols or (raw >> 17) & 0x7fff:
            raise ValueError("Invalid import")
        start = offset + symbols + name_offset
        end = data.find(b"\0", start, min(offset + size, start + 2048))
        if end < 0:
            raise ValueError("Unterminated import")
        name = data[start:end]
        records.append((start, end + 1, name))
        # Compare exact reviewed names before decoding/emitting anything.
        known = next((s for s in ALIASES if name == s.encode()), None)
        if known:
            ordinal = raw & 0xffff
            if (not 1 <= ordinal <= len(libraries) or
                    libraries[ordinal - 1] != b"/usr/lib/libSystem.B.dylib" or
                    (raw >> 16) & 1 or addend or len(known) != len(ALIASES[known])):
                raise ValueError("Unsupported native import contract")
            selected[index] = {"symbol": known, "alias": ALIASES[known],
                "import_index": index, "source_library_ordinal": ordinal,
                "import_record_file_offset": offset + imports + index * 16,
                "name_file_offset": start, "name_bytes_including_nul": end + 1 - start,
                "same_length_alias": True, "foreign_name_overlap": False}
        for collection, allowlist in ((extra, EXTRA_NETWORK), (escapes, ESCAPES)):
            match = next((s for s in allowlist if name == s.encode()), None)
            if match:
                collection.append(match)
    for record in selected.values():
        begin = record["name_file_offset"]
        end = begin + record["name_bytes_including_nul"]
        for left, right, name in records:
            if left < end and begin < right and name != record["symbol"].encode():
                record["foreign_name_overlap"] = True
    slots = []
    for address in sorted(image.binds):
        raw = image.at("Q", address)[0]
        record = selected.get(raw & 0xffffff)
        if record is None:
            continue
        if ((raw >> 24) & 255) or ((raw >> 32) & 0x7ffff):
            raise ValueError("Nonzero selected pointer addend/reserved bits")
        mapped = [s for s in segments if s[0] <= address and address + 8 <= s[0] + s[3]]
        if len(mapped) != 1 or address % 8:
            raise ValueError("Bad selected slot")
        segment = mapped[0]
        slots.append({"symbol": record["symbol"], "import_index": record["import_index"],
            "image_relative_vm_offset": address - image.base,
            "slot_file_offset": image.offset(address, 8),
            "segment_initial_protection": segment[4],
            "data_const": segment[5] == b"__DATA_CONST",
            "runtime_rewrite_authorized": False})
    return {"schema": 1, "source_sha256": SOURCE_SHA, "source_bytes": SOURCE_BYTES,
        "scope": "bounded static startup/import inventory; no initializer execution or containment proof",
        "startup_sections": initializers, "routine_commands": routines,
        "dependency_count": len(libraries),
        "system_dependency_count": sum(x.startswith((b"/System/", b"/usr/lib/")) for x in libraries),
        "private_rpath_dependency_ordinals": [i for i, x in enumerate(libraries, 1) if x.startswith(b"@rpath/")],
        "source_patcher_ordinal": next((i for i, x in enumerate(libraries, 1)
            if x == b"@executable_path/Frameworks/DokkanSparkingPatcher.dylib"), None),
        "network_imports": list(selected.values()), "network_bind_slots": slots,
        "additional_reviewed_network_imports": sorted(set(extra)),
        "dynamic_resolution_or_syscall_imports": sorted(set(escapes)),
        "static_redirect_is_admitted": False,
        "required_redirect_policy": "Explicit authored-plugin dependency ordinal and same-length alias changes before signing; preserve original initializer order and other names. No VM protection weakening.",
        "remaining_boundaries": ["Unreviewed initializer/class/category bodies", "Private dependency startup",
            "Foundation sessions outside the installed protocol", "CFNetwork/system-library internal calls",
            "WKWebView/network subprocesses", "Dynamic resolution/syscalls", "Local IPC compatibility"],
        "initializer_containment_verified": False, "original_modified": False,
        "unknown_names_or_strings_emitted": False}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("original", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    if args.output.exists() or args.output.resolve() == args.original.resolve():
        raise SystemExit("Existing files preserved.")
    try:
        result = inspect(args.original)
        args.output.parent.mkdir(parents=True, exist_ok=True)
        with args.output.open("x") as stream:
            stream.write(json.dumps(result, indent=2) + "\n")
    except (ValueError, OSError, struct.error, UnicodeError):
        raise SystemExit("Startup inspection stopped; original preserved, no unknown names emitted.")
    print("Pinned startup inventory written; no runtime load/containment was claimed.")


if __name__ == "__main__":
    main()
