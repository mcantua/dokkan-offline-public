"""Bounded static Mach-O metadata. Never executes code or emits arbitrary strings."""
import struct

MAX_COMMAND_BYTES = 4 * 1024 * 1024
ARCHES = {7: "i386", 12: "arm", 0x1000007: "x86_64", 0x100000c: "arm64"}
PLATFORMS = {1: "macOS", 2: "iOS", 3: "tvOS", 4: "watchOS", 6: "Mac Catalyst",
             7: "iOS Simulator", 8: "tvOS Simulator", 9: "watchOS Simulator",
             11: "visionOS", 12: "visionOS Simulator"}
# Only these library basenames can be reported; user paths/install names are omitted.
LIBRARIES = frozenset(("UIKit", "Foundation", "CoreFoundation", "Security", "WebKit",
    "JavaScriptCore", "OpenGLES", "Metal", "QuartzCore", "AVFoundation", "AudioToolbox",
    "CFNetwork", "SystemConfiguration", "libSystem.B.dylib", "libobjc.A.dylib",
    "libc++.1.dylib", "libsqlite3.dylib", "libz.1.dylib", "libcurl.4.dylib",
    "EclipsePatcher.dylib", "DokkanSparkingPatcher.dylib"))


def _version(value):
    return f"{value >> 16}.{(value >> 8) & 255}.{value & 255}"


def _read(stream, offset, size, total):
    if offset < 0 or size < 0 or offset + size > total:
        raise ValueError("Invalid Mach-O bounds")
    stream.seek(offset)
    data = stream.read(size)
    if len(data) != size:
        raise ValueError("Truncated Mach-O")
    return data


def _thin(stream, offset, size, total):
    magic = _read(stream, offset, 4, total)
    formats = {b"\xce\xfa\xed\xfe": ("<", 28), b"\xcf\xfa\xed\xfe": ("<", 32),
               b"\xfe\xed\xfa\xce": (">", 28), b"\xfe\xed\xfa\xcf": (">", 32)}
    if magic not in formats:
        raise ValueError("Unsupported Mach-O header")
    endian, header_size = formats[magic]
    if size < header_size:
        raise ValueError("Truncated Mach-O slice")
    header = _read(stream, offset, header_size, total)
    cpu, subtype, kind, count, command_bytes = struct.unpack_from(endian + "IIIII", header, 4)
    if count > 8192 or command_bytes > MAX_COMMAND_BYTES or header_size + command_bytes > size:
        raise ValueError("Invalid Mach-O commands")
    data = _read(stream, offset + header_size, command_bytes, total)
    out = {"architecture": ARCHES.get(cpu, "other"), "cpu_type": cpu,
           "cpu_subtype": subtype, "file_type": kind, "header_bits": 64 if header_size == 32 else 32,
           "build_versions": [], "encryption": [], "chained_fixups_present": False,
           "allowlisted_libraries": [], "unreported_library_count": 0}
    pos = 0
    for _ in range(count):
        if pos + 8 > len(data):
            raise ValueError("Truncated load command")
        cmd, length = struct.unpack_from(endian + "II", data, pos)
        if length < 8 or length % 4 or pos + length > len(data):
            raise ValueError("Invalid load command")
        payload = data[pos:pos + length]
        if cmd == 0x32:  # LC_BUILD_VERSION
            if length < 24:
                raise ValueError("Invalid build version")
            platform, minimum, sdk, tools = struct.unpack_from(endian + "IIII", payload, 8)
            if 24 + tools * 8 != length:
                raise ValueError("Invalid build tools")
            out["build_versions"].append({"command": "LC_BUILD_VERSION",
                "platform": PLATFORMS.get(platform, "other"), "platform_id": platform,
                "minimum_os": _version(minimum), "sdk": _version(sdk)})
        elif cmd in (0x24, 0x25, 0x2f, 0x30):
            if length != 16:
                raise ValueError("Invalid minimum OS version")
            minimum, sdk = struct.unpack_from(endian + "II", payload, 8)
            out["build_versions"].append({"command": "LC_VERSION_MIN",
                "platform": {0x24: "macOS", 0x25: "iOS", 0x2f: "tvOS", 0x30: "watchOS"}[cmd],
                "minimum_os": _version(minimum), "sdk": _version(sdk)})
        elif cmd in (0x21, 0x2c):
            if length != (24 if cmd == 0x2c else 20):
                raise ValueError("Invalid encryption command")
            start, amount, cryptid = struct.unpack_from(endian + "III", payload, 8)
            if start + amount > size:
                raise ValueError("Invalid encrypted range")
            out["encryption"].append({"cryptid": cryptid, "encrypted": cryptid != 0,
                                      "encrypted_bytes": amount})
        elif cmd == 0x80000034:
            if length != 16:
                raise ValueError("Invalid chained fixups")
            start, amount = struct.unpack_from(endian + "II", payload, 8)
            if start + amount > size:
                raise ValueError("Invalid fixup range")
            out["chained_fixups_present"] = True
        elif cmd in (0xc, 0x80000018, 0x8000001f, 0x80000023, 0x20):
            if length < 24:
                raise ValueError("Invalid library command")
            start = struct.unpack_from(endian + "I", payload, 8)[0]
            if not 24 <= start < length or b"\0" not in payload[start:]:
                raise ValueError("Invalid library name")
            basename = payload[start:].split(b"\0", 1)[0].rsplit(b"/", 1)[-1]
            name = basename.decode("ascii", errors="replace")
            if name in LIBRARIES:
                out["allowlisted_libraries"].append(name)
            else:
                out["unreported_library_count"] += 1
        pos += length
    if pos != len(data):
        raise ValueError("Mismatched load command size")
    out["allowlisted_libraries"] = sorted(set(out["allowlisted_libraries"]))
    return out


def macho_metadata(stream, size):
    """Read at most 16 bounded load-command regions, without extracting a binary."""
    magic = _read(stream, 0, 4, size)
    formats = {b"\xca\xfe\xba\xbe": (">", 20), b"\xbe\xba\xfe\xca": ("<", 20),
               b"\xca\xfe\xba\xbf": (">", 32), b"\xbf\xba\xfe\xca": ("<", 32)}
    if magic not in formats:
        return {"format": "Mach-O", "slices": [_thin(stream, 0, size, size)]}
    endian, entry_size = formats[magic]
    count = struct.unpack(endian + "I", _read(stream, 4, 4, size))[0]
    if not 1 <= count <= 16:
        raise ValueError("Invalid universal architecture count")
    table_end = 8 + count * entry_size
    table = _read(stream, 8, count * entry_size, size)
    ranges, result = [], []
    for index in range(count):
        start = index * entry_size
        cpu, subtype = struct.unpack_from(endian + "II", table, start)
        offset, amount = struct.unpack_from(endian + ("QQ" if entry_size == 32 else "II"), table, start + 8)
        if offset < table_end or amount < 28 or offset + amount > size or any(offset < b and a < offset + amount for a, b in ranges):
            raise ValueError("Invalid universal slice")
        ranges.append((offset, offset + amount))
        item = _thin(stream, offset, amount, size)
        if (item["cpu_type"], item["cpu_subtype"]) != (cpu, subtype):
            raise ValueError("Mismatched universal architecture")
        result.append(item)
    return {"format": "universal Mach-O", "slices": result}
