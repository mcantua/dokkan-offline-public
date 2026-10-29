"""Add a <uses-permission android:name="..."/> to a binary AndroidManifest.xml (UTF-16 pool),
copying the existing INTERNET permission element."""
import struct, sys
src, dst, perm = sys.argv[1], sys.argv[2], sys.argv[3]
b = bytearray(open(src, "rb").read())
SP = 8
typ, hsz, size, count, scount, flags, sstart, stylestart = struct.unpack_from("<HHIIIIII", b, SP)
assert typ == 0x0001 and not flags & 0x100 and scount == 0, "expects UTF-16 pool without styles"
offs = list(struct.unpack_from("<%dI" % count, b, SP + hsz))
def s_at(i):
    p = SP + sstart + offs[i]; n = struct.unpack_from("<H", b, p)[0]; return b[p + 2:p + 2 + 2 * n].decode("utf-16le")
strings = [s_at(i) for i in range(count)]
assert perm not in strings, "already present"
# new string pool: append the string
data = bytes(b[SP + sstart:SP + size])
end = max(SP + sstart + o + 2 + 2 * struct.unpack_from("<H", b, SP + sstart + o)[0] + 2 for o in offs) - (SP + sstart)
data = data[:end]
new_off = len(data)
data += struct.pack("<H", len(perm)) + perm.encode("utf-16le") + b"\0\0"
while len(data) % 4: data += b"\0"
new_hsz = hsz; offs_new = offs + [new_off]
pool = struct.pack("<HHIIIIII", 0x0001, hsz, 0, count + 1, 0, flags, hsz + 4 * (count + 1), 0)
pool += struct.pack("<%dI" % (count + 1), *offs_new) + data
pool = pool[:4] + struct.pack("<I", len(pool)) + pool[8:]
rest = bytearray(b[SP + size:])
new_index = count
# find INTERNET uses-permission start/end tags in rest
pos = 0; start = None
while pos < len(rest):
    t, h, sz = struct.unpack_from("<HHI", rest, pos)
    if t == 0x0102 and strings[struct.unpack_from("<I", rest, pos + 20)[0]] == "uses-permission":
        astart, asize, acount = struct.unpack_from("<HHH", rest, pos + 24)
        for i in range(acount):
            a = pos + 16 + astart + i * asize
            raw = struct.unpack_from("<i", rest, a + 8)[0]
            if raw >= 0 and strings[raw] == "android.permission.INTERNET": start = (pos, sz, a)
    if start and t == 0x0103 and pos > start[0]:
        endtag = (pos, sz); break
    pos += sz
assert start, "INTERNET permission not found"
sp, ssz, a = start
el = bytearray(rest[sp:sp + ssz]); ai = a - sp
struct.pack_into("<i", el, ai + 8, new_index)           # raw value
struct.pack_into("<I", el, ai + 16, new_index)          # typed value data (TYPE_STRING)
assert el[ai + 15] == 0x03, "expected string-typed attribute"
et = bytes(rest[endtag[0]:endtag[0] + endtag[1]])
insert_at = endtag[0] + endtag[1]
rest = rest[:insert_at] + el + et + rest[insert_at:]
out = bytearray(b[:SP]) + pool + rest
struct.pack_into("<I", out, 4, len(out))
open(dst, "wb").write(out)
print("added", perm, "string index", new_index)
