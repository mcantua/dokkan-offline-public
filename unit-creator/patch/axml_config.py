"""Set android:configChanges on CreatorActivity (binary AndroidManifest.xml), in place.
Adds smallestScreenSize|screenLayout so folding/unfolding a Galaxy Z Fold or Pixel Fold (or
multi-window resizing) doesn't restart the app."""
import struct, sys
path, value = sys.argv[1], int(sys.argv[2], 0)
b = bytearray(open(path, "rb").read())
typ, hsz, size, count, scount, flags, sstart, _ = struct.unpack_from("<HHIIIIII", b, 8)
offs = struct.unpack_from("<%dI" % count, b, 8 + hsz); strings = []
for o in offs:
    p = 8 + sstart + o; n = struct.unpack_from("<H", b, p)[0]; strings.append(b[p + 2:p + 2 + 2 * n].decode("utf-16le"))
pos = 8; resmap = []; done = 0
while pos < len(b):
    t, h, sz = struct.unpack_from("<HHI", b, pos)
    if t == 0x0180: resmap = list(struct.unpack_from("<%dI" % ((sz - h) // 4), b, pos + h))
    if t == 0x0102 and strings[struct.unpack_from("<I", b, pos + 20)[0]] == "activity":
        astart, asize, acount = struct.unpack_from("<HHH", b, pos + 24)
        attrs = {}
        for i in range(acount):
            a = pos + 16 + astart + i * asize; n = struct.unpack_from("<I", b, a + 4)[0]
            rid = resmap[n] if n < len(resmap) else None; attrs[rid] = a
        name_a = attrs.get(0x01010003)
        if name_a is not None and strings[struct.unpack_from("<I", b, name_a + 8)[0]] == "com.personal.aihub.CreatorActivity":
            a = attrs.get(0x0101001f); assert a is not None, "CreatorActivity has no configChanges"
            old = struct.unpack_from("<I", b, a + 16)[0]
            struct.pack_into("<I", b, a + 16, value); done += 1
            print("configChanges", hex(old), "->", hex(value))
    pos += sz if t in (0x0001, 0x0180) or t >= 0x0100 else h
assert done == 1
open(path, "wb").write(b)
