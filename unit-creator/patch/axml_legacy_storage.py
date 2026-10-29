"""Enable Android 8–10 public Downloads access in the existing binary manifest.

Resource ID verified against AOSP android-10.0.0_r47 core/res/res/values/public.xml.
Android 11+ ignores this legacy flag for target SDK 30+; it still needs managed all-files access.
"""
import pathlib
import struct
import subprocess
import sys

path = pathlib.Path(sys.argv[1])
ADD_PERMISSION = pathlib.Path(__file__).with_name("axml_add_permission.py")


def string_pool(data):
    typ, hsz, size, count, styles, flags, start, style_start = struct.unpack_from("<HHIIIIII", data, 8)
    if typ != 1 or styles or flags & 0x100: raise ValueError("Expected unstyled UTF-16 string pool")
    offsets = list(struct.unpack_from("<%dI" % count, data, 8 + hsz))
    strings = []
    for offset in offsets:
        p = 8 + start + offset
        n = struct.unpack_from("<H", data, p)[0]
        strings.append(data[p + 2:p + 2 + 2 * n].decode("utf-16le"))
    return hsz, size, flags, start, offsets, strings


for permission in ["android.permission.READ_EXTERNAL_STORAGE", "android.permission.WRITE_EXTERNAL_STORAGE"]:
    if permission not in string_pool(path.read_bytes())[-1]:
        subprocess.run([sys.executable, str(ADD_PERMISSION), str(path), str(path), permission], check=True)

b = path.read_bytes()
hsz, pool_size, flags, start, offsets, strings = string_pool(b)
name = "requestLegacyExternalStorage"
pool = b[8:8 + pool_size]
if name not in strings:
    raw = b[8 + start:8 + pool_size]
    offsets.append(len(raw))
    raw += struct.pack("<H", len(name)) + name.encode("utf-16le") + b"\0\0"
    raw += b"\0" * (-len(raw) % 4)
    strings.append(name)
    pool = struct.pack("<HHIIIIII", 1, hsz, hsz + 4 * len(offsets) + len(raw), len(offsets), 0, flags, hsz + 4 * len(offsets), 0)
    pool += struct.pack("<%dI" % len(offsets), *offsets) + raw
index, android = strings.index(name), strings.index("http://schemas.android.com/apk/res/android")
parts, pos, mapping, changed = [], 8, [], False
while pos < len(b):
    typ, header, size = struct.unpack_from("<HHI", b, pos)
    chunk = bytearray(b[pos:pos + size])
    if typ == 1:
        chunk = pool
    elif typ == 0x180:
        mapping = list(struct.unpack_from("<%dI" % ((size - header) // 4), b, pos + header))
        mapping += [0] * (index + 1 - len(mapping))
        if mapping[index] not in (0, 0x01010603): raise ValueError("Conflicting storage attribute ID")
        mapping[index] = 0x01010603
        chunk = struct.pack("<HHI", 0x180, header, header + 4 * len(mapping)) + struct.pack("<%dI" % len(mapping), *mapping)
    elif typ == 0x102 and strings[struct.unpack_from("<I", chunk, 20)[0]] == "application":
        first, width, count = struct.unpack_from("<HHH", chunk, 24)
        if width != 20: raise ValueError("Unsupported binary attribute width")
        entries = [16 + first + i * width for i in range(count)]
        existing = next((a for a in entries if struct.unpack_from("<I", chunk, a + 4)[0] == index), None)
        if existing is not None:
            if chunk[existing + 15] != 0x12: raise ValueError("Legacy flag is not a boolean")
            struct.pack_into("<I", chunk, existing + 16, 0xFFFFFFFF)
        else:
            insert = next((i for i, a in enumerate(entries) if mapping[struct.unpack_from("<I", chunk, a + 4)[0]] > 0x01010603), count)
            at = 16 + first + insert * width
            value = struct.pack("<IIIHBBI", android, index, 0xFFFFFFFF, 8, 0, 0x12, 0xFFFFFFFF)
            chunk[at:at] = value
            struct.pack_into("<I", chunk, 4, len(chunk))
            struct.pack_into("<H", chunk, 28, count + 1)
            for off in [30, 32, 34]:
                special = struct.unpack_from("<H", chunk, off)[0]
                if special and special >= insert + 1: struct.pack_into("<H", chunk, off, special + 1)
        changed = True
    parts.append(chunk)
    pos += size
if not changed: raise ValueError("No application element found")
out = bytearray(b[:8] + b"".join(parts))
struct.pack_into("<I", out, 4, len(out))
path.write_bytes(out)
print("Legacy public storage permissions/flag enabled; release version fields unchanged")
