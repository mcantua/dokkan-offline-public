#!/usr/bin/env python3
"""Read the SDK mark from a thin arm64 iOS Mach-O without a host LLVM dependency."""
import pathlib
import struct
import sys


def sdk_version(data):
    if len(data) < 32:
        raise ValueError("truncated Mach-O header")
    magic, cpu, subtype, kind, count, size, flags, reserved = struct.unpack_from("<IiiIIIII", data)
    if magic != 0xFEEDFACF or cpu != 0x0100000C or kind != 2:
        raise ValueError("expected a thin arm64 Mach-O executable")
    if count > 4096 or size > len(data) - 32:
        raise ValueError("invalid Mach-O command table")
    end, pos, found = 32 + size, 32, []
    for _ in range(count):
        if pos + 8 > end:
            raise ValueError("truncated load command")
        cmd, length = struct.unpack_from("<II", data, pos)
        if length < 8 or length % 8 or pos + length > end:
            raise ValueError("invalid load command length")
        if cmd == 0x32:
            if length < 24:
                raise ValueError("truncated LC_BUILD_VERSION")
            platform, minimum, sdk, tools = struct.unpack_from("<IIII", data, pos + 8)
            if platform != 2 or length < 24 + tools * 8:
                raise ValueError("not an iOS build-version command")
            found.append(sdk)
        pos += length
    if pos != end or len(found) != 1:
        raise ValueError("expected exactly one complete iOS build-version command")
    value = found[0]
    return f"{value >> 16}.{(value >> 8) & 255}.{value & 255}"


if __name__ == "__main__":
    try:
        print(sdk_version(pathlib.Path(sys.argv[1]).read_bytes()))
    except (ValueError, OSError, IndexError) as error:
        raise SystemExit(str(error))
