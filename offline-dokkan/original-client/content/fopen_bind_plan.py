#!/usr/bin/env python3
"""Decode only the pinned original client's standard fopen chained bindings."""
import argparse
import hashlib
import json
from pathlib import Path
import struct
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools"))
from objc_runtime_metadata import Image

ORIGINAL_SHA256 = "9d6bf0470c4b4ff7d914740ccf9f1622afa962b763e18bfcf1f6e051bfae0610"
ORIGINAL_BYTES = 55697728


def inspect_fopen_bindings(path):
    path = Path(path)
    if path.stat().st_size != ORIGINAL_BYTES:
        raise ValueError("Only the pinned original executable is admitted")
    data = path.read_bytes()
    if hashlib.sha256(data).hexdigest() != ORIGINAL_SHA256:
        raise ValueError("Original executable changed")
    image = Image(data)
    if image.chain_formats != {6}:
        raise ValueError("Only current non-PAC PTR_64_OFFSET chains are admitted")
    count = image.unpack("I", 16)[0]
    pos, fixups, libraries, segments = 32, None, [], []
    for _ in range(count):
        command, size = image.unpack("II", pos)
        if command == 0x80000034:
            if fixups is not None:
                raise ValueError("Duplicate fixups")
            fixups = image.unpack("II", pos + 8)
        elif command in (0xc, 0x80000018, 0x8000001f, 0x80000023):
            name = image.unpack("I", pos + 8)[0]
            if not 24 <= name < size:
                raise ValueError("Invalid library command")
            raw = data[pos + name:pos + size].split(b"\0", 1)
            if len(raw) != 2:
                raise ValueError("Unterminated library name")
            # Other library names are never emitted.
            libraries.append(raw[0] == b"/usr/lib/libSystem.B.dylib")
        elif command == 0x19:
            vm, amount, off, file_size = image.unpack("QQQQ", pos + 24)
            maximum, initial = image.unpack("II", pos + 56)
            segments.append((vm, amount, off, file_size, maximum, initial))
        pos += size
    if fixups is None:
        raise ValueError("Expected chained bindings")
    offset, size = fixups
    version, starts, imports, symbols, count, fmt, symbol_format = image.unpack("7I", offset)
    if (version != 0 or fmt != 3 or symbol_format != 0 or count > 65536 or
            not 28 <= imports <= size or imports + count * 16 > symbols or symbols >= size):
        raise ValueError("Unsupported import metadata")
    selected = {}
    for index in range(count):
        first, addend = image.unpack("Qq", offset + imports + index * 16)
        name_offset = first >> 32
        if ((first >> 17) & 0x7fff) or name_offset >= size - symbols:
            raise ValueError("Invalid import record")
        start = offset + symbols + name_offset
        if data[start:min(offset + size, start + 7)] != b"_fopen\0":
            continue
        ordinal, weak = first & 0xffff, (first >> 16) & 1
        if not 1 <= ordinal <= len(libraries) or not libraries[ordinal - 1] or weak or addend:
            raise ValueError("Expected strong addend-free libc fopen import")
        selected[index] = {"import_index": index, "library_ordinal": ordinal,
                           "name_offset": name_offset, "import_addend": addend,
                           "import_record_file_offset": offset + imports + index * 16}
    slots = []
    for address in sorted(image.binds):
        raw = image.at("Q", address)[0]
        ordinal = raw & 0xffffff
        if ordinal not in selected:
            continue
        if ((raw >> 24) & 255) or ((raw >> 32) & 0x7ffff):
            raise ValueError("Unsupported fopen pointer addend/reserved bits")
        matches = [x for x in segments if x[0] <= address and address + 8 <= x[0] + x[3]]
        if len(matches) != 1 or address % 8:
            raise ValueError("Unaligned or unmapped fopen slot")
        vm, amount, file_offset, file_bytes, maximum, initial = matches[0]
        slots.append({**selected[ordinal], "vm_address": address,
                      "image_relative_vm_offset": address - image.base,
                      "slot_file_offset": image.offset(address, 8),
                      "segment_vm_address": vm, "segment_vm_bytes": amount,
                      "segment_file_offset": file_offset, "segment_file_bytes": file_bytes,
                      "segment_max_protection": maximum, "segment_initial_protection": initial,
                      "pointer_format": 6})
    if not slots or len(slots) > 16 or set(selected) != {x["import_index"] for x in slots}:
        raise ValueError("Unexpected or unused fopen import selection")
    return {"schema": 1, "source_executable_sha256": ORIGINAL_SHA256,
            "source_executable_bytes": ORIGINAL_BYTES, "symbol": "_fopen",
            "source_image_base": image.base, "pointer_format": 6,
            "imports_format": 3, "symbols_format": 0,
            "fixups_file_offset": offset, "fixups_bytes": size,
            "slots": slots, "unknown_symbol_names_emitted": False,
            "original_modified": False, "runtime_slots_attached": False}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("original", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    if args.output.resolve() == args.original.resolve() or args.output.exists():
        raise SystemExit("Existing files preserved.")
    try:
        result = inspect_fopen_bindings(args.original)
        args.output.parent.mkdir(parents=True, exist_ok=True)
        with args.output.open("x") as output:
            output.write(json.dumps(result, indent=2) + "\n")
    except (ValueError, OSError, UnicodeError, struct.error):
        raise SystemExit("Binding inspection stopped; original preserved and no unknown symbols emitted.")
    print("Pinned fopen bind plan written. No runtime slot attachment was performed.")


if __name__ == "__main__":
    main()
