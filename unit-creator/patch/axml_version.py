"""Set versionCode and (same-length) versionName in a binary AndroidManifest.xml."""
import struct, sys
src, dst, code, name = sys.argv[1], sys.argv[2], int(sys.argv[3]), sys.argv[4]
b = bytearray(open(src, "rb").read())
typ, hsz, size, count, scount, flags, sstart, _ = struct.unpack_from("<HHIIIIII", b, 8)
assert not flags & 0x100, "expects UTF-16 pool"
offs = struct.unpack_from("<%dI" % count, b, 8 + hsz)
strings = []
for o in offs:
    p = 8 + sstart + o; n = struct.unpack_from("<H", b, p)[0]; strings.append((p, b[p + 2:p + 2 + 2 * n].decode("utf-16le")))
pos = 8; resmap = []; done = {"code": 0, "name": 0}
while pos < len(b):
    t, h, sz = struct.unpack_from("<HHI", b, pos)
    if t == 0x0180: resmap = list(struct.unpack_from("<%dI" % ((sz - h) // 4), b, pos + h))
    if t == 0x0102:
        nm = struct.unpack_from("<I", b, pos + 20)[0]
        astart, asize, acount = struct.unpack_from("<HHH", b, pos + 24)
        if strings[nm][1] == "manifest":
            for i in range(acount):
                a = pos + 16 + astart + i * asize; n = struct.unpack_from("<I", b, a + 4)[0]
                rid = resmap[n] if n < len(resmap) else None
                if rid == 0x0101021B:  # versionCode
                    struct.pack_into("<I", b, a + 16, code); done["code"] += 1
                if rid == 0x0101021C:  # versionName
                    raw = struct.unpack_from("<I", b, a + 8)[0]; p, old = strings[raw]
                    assert len(old) == len(name), (old, name)
                    b[p + 2:p + 2 + 2 * len(name)] = name.encode("utf-16le"); done["name"] += 1
    pos += sz if t in (0x0001, 0x0180) or t >= 0x0100 else h
assert done == {"code": 1, "name": 1}, done
open(dst, "wb").write(b); print("versionCode", code, "versionName", name)
