"""Replace a string in a binary AndroidManifest.xml string pool (UTF-16, no styles), e.g. the app label."""
import struct, sys
src, dst, old, new = sys.argv[1:5]
b = bytearray(open(src, "rb").read())
SP = 8
typ, hsz, size, count, scount, flags, sstart, _ = struct.unpack_from("<HHIIIIII", b, SP)
assert typ == 1 and not flags & 0x100 and scount == 0
offs = struct.unpack_from("<%dI" % count, b, SP + hsz)
strings = []
for o in offs:
    p = SP + sstart + o; n = struct.unpack_from("<H", b, p)[0]; strings.append(b[p + 2:p + 2 + 2 * n].decode("utf-16le"))
hits = [i for i, s in enumerate(strings) if s == old]
assert hits, "string not found"
for i in hits: strings[i] = new
data = bytearray(); new_offs = []
for s in strings:
    new_offs.append(len(data)); assert len(s) < 0x8000
    data += struct.pack("<H", len(s)) + s.encode("utf-16le") + b"\0\0"
while len(data) % 4: data += b"\0"
pool = struct.pack("<HHIIIIII", 1, hsz, 0, count, 0, flags, hsz + 4 * count, 0) + struct.pack("<%dI" % count, *new_offs) + bytes(data)
pool = pool[:4] + struct.pack("<I", len(pool)) + pool[8:]
out = bytearray(b[:SP]) + pool + b[SP + size:]
struct.pack_into("<I", out, 4, len(out))
open(dst, "wb").write(out); print("replaced", len(hits), "string(s):", old, "->", new)
