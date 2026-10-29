"""Flip android:hardwareAccelerated to true on CreatorActivity inside a binary AndroidManifest.xml."""
import struct, sys
src, dst = sys.argv[1], sys.argv[2]
b = bytearray(open(src, "rb").read())
assert struct.unpack_from("<H", b, 0)[0] == 0x0003
pos = 8; strings = []; resmap = []
def read_pool(off):
    _, hsz, size, count, scount, flags, sstart, _ = struct.unpack_from("<HHIIIIII", b, off)
    utf8 = flags & 0x100; offs = struct.unpack_from("<%dI" % count, b, off + hsz); out = []
    for o in offs:
        p = off + sstart + o
        if utf8:
            n = b[p]; p += 2 if n & 0x80 else 1
            n = b[p]; 
            if n & 0x80: n = ((n & 0x7f) << 8) | b[p+1]; p += 2
            else: p += 1
            out.append(b[p:p+n].decode("utf8", "replace"))
        else:
            n = struct.unpack_from("<H", b, p)[0]; p += 2
            out.append(b[p:p+2*n].decode("utf-16le", "replace"))
    return out
patched = 0
while pos < len(b):
    typ, hsz, size = struct.unpack_from("<HHI", b, pos)
    if typ == 0x0001: strings = read_pool(pos)
    elif typ == 0x0180: resmap = list(struct.unpack_from("<%dI" % ((size - hsz) // 4), b, pos + hsz))
    elif typ == 0x0102:
        name = struct.unpack_from("<I", b, pos + 20)[0]
        astart, asize, acount = struct.unpack_from("<HHH", b, pos + 24)
        if strings[name] == "activity":
            attrs = [pos + 16 + astart + i * asize for i in range(acount)]
            def rid(a): n = struct.unpack_from("<I", b, a + 4)[0]; return resmap[n] if n < len(resmap) else None
            nm = None
            for a in attrs:
                if rid(a) == 0x01010003:  # android:name
                    raw = struct.unpack_from("<I", b, a + 8)[0]; dtype = b[a + 15]; data = struct.unpack_from("<I", b, a + 16)[0]
                    nm = strings[raw] if raw != 0xFFFFFFFF else (strings[data] if dtype == 3 else None)
            if nm == "com.personal.aihub.CreatorActivity":
                for a in attrs:
                    if rid(a) == 0x010102D3:  # android:hardwareAccelerated
                        assert b[a + 15] == 0x12, "not a boolean"
                        print("hardwareAccelerated was", struct.unpack_from("<I", b, a + 16)[0])
                        struct.pack_into("<I", b, a + 16, 0xFFFFFFFF); patched += 1
    pos += size if typ in (0x0001, 0x0180) or typ >= 0x0100 else hsz
assert patched == 1, patched
open(dst, "wb").write(b); print("patched", dst)
