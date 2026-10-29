#!/usr/bin/env python3
"""Prepare a private loadable-image candidate from the exact supplied arm64 main.

This changes container metadata only; it does not sign, execute, decrypt, package
or claim dyld/runtime compatibility. The original file is never overwritten.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import stat
import struct

SOURCE_BYTES = 55697728
SOURCE_SHA256 = '9d6bf0470c4b4ff7d914740ccf9f1622afa962b763e18bfcf1f6e051bfae0610'
IDENTIFIER = b'@rpath/OriginalDokkanEngine.dylib\0'
VERSION = 1


def unpack(data, fmt, offset):
    length = struct.calcsize('<' + fmt)
    if offset < 0 or offset + length > len(data):
        raise ValueError('Invalid image bounds')
    return struct.unpack_from('<' + fmt, data, offset)


def commands(data):
    magic, cpu, _, kind, count, amount, flags, _ = unpack(data, '8I', 0)
    if magic != 0xfeedfacf or cpu != 0x100000c or count > 8192 or amount > 4*1024**2:
        raise ValueError('Unsupported image')
    position, result = 32, []
    for _ in range(count):
        cmd, size = unpack(data, 'II', position)
        if size < 8 or size % 8 or position + size > 32 + amount:
            raise ValueError('Malformed load command')
        result.append((cmd, position, size))
        position += size
    if position != 32 + amount:
        raise ValueError('Command bytes mismatch')
    return kind, flags, amount, result


def imports(data, start):
    offset, amount = unpack(data, 'II', start + 8)
    version, starts, entries, _, count, fmt, _ = unpack(data, '7I', offset)
    if (version != 0 or fmt != 3 or offset + amount > len(data) or
            not 28 <= starts < amount or count > 100000 or entries + count*16 > amount):
        raise ValueError('Unsupported chained imports')
    ordinals = []
    for index in range(count):
        raw = unpack(data, 'Q', offset + entries + index*16)[0] & 0xffff
        ordinals.append(raw - 65536 if raw >= 32768 else raw)
    return offset, amount, starts, ordinals


def adapt(source, output):
    source, output = Path(source), Path(output)
    temporary = output.with_name(output.name + '.preparing')
    if (source.resolve() == output.resolve() or output.exists() or output.is_symlink() or
            temporary.exists() or temporary.is_symlink()):
        raise ValueError('Existing inputs or outputs preserved')
    fd = os.open(source, os.O_RDONLY | os.O_NOFOLLOW)
    with os.fdopen(fd, 'rb') as stream:
        before = os.fstat(stream.fileno())
        if not stat.S_ISREG(before.st_mode) or before.st_size != SOURCE_BYTES:
            raise ValueError('Wrong source size/type')
        original = stream.read(SOURCE_BYTES + 1)
        if hashlib.sha256(original).hexdigest() != SOURCE_SHA256:
            raise ValueError('Wrong original client')
        kind, flags, old_amount, cmds = commands(original)
        if kind != 2 or not flags & 0x200000:
            raise ValueError('Expected original PIE executable')
        image = bytearray(original)
        segments = [(p,n) for c,p,n in cmds if c == 0x19]
        if len(segments) != 5:
            raise ValueError('Unexpected segment layout')
        first, first_size = segments[0]
        if (original[first+8:first+24].rstrip(b'\0') != b'__PAGEZERO' or first_size != 72 or
                unpack(original,'QQQQ',first+24) != (0,0x100000000,0,0) or
                unpack(original,'I',first+64)[0] != 0):
            raise ValueError('Unexpected page-zero segment')
        chains = [(p,n) for c,p,n in cmds if c == 0x80000034]
        if len(chains) != 1:
            raise ValueError('Expected one chained-fixup command')
        fixup_offset, fixup_size, starts, ordinals = imports(original,chains[0][0])
        table = fixup_offset + starts
        count = unpack(original,'I',table)[0]
        if count != len(segments) or table + 4 + count*4 > fixup_offset + fixup_size:
            raise ValueError('Wrong chained segment table')
        offsets = list(unpack(original,'I'*count,table+4))
        if offsets[0] != 0:
            raise ValueError('Unexpected page-zero fixups')
        # Relative segment-start offsets retain their original targets. The old
        # final table slot becomes harmless zero padding; payload sizes do not move.
        struct.pack_into('<I',image,table,count-1)
        struct.pack_into('<'+'I'*count,image,table+4,*(offsets[1:]+[0]))
        libraries = []
        for cmd,p,n in cmds:
            if cmd in (0xc,0x80000018,0x8000001f,0x80000023,0x20):
                name_offset = unpack(original,'I',p+8)[0]
                if not 24 <= name_offset < n:
                    raise ValueError('Malformed library command')
                libraries.append((p,original[p+name_offset:p+n].split(b'\0',1)[0]))
        if (len(libraries) != 63 or not libraries[-1][1].endswith(b'/DokkanSparkingPatcher.dylib') or
                len([x for x in libraries if x[1].endswith(b'/DokkanSparkingPatcher.dylib')]) != 1 or
                63 in ordinals):
            raise ValueError('Source patcher is not an unused final dependency')
        # Verify classic symbol ordinal metadata too, without reading names.
        sym = [(p,n) for c,p,n in cmds if c == 2]
        if len(sym) != 1:
            raise ValueError('Expected symbol metadata')
        symoff,nsyms,_,_ = unpack(original,'4I',sym[0][0]+8)
        if nsyms > 1000000 or symoff+nsyms*16 > len(original):
            raise ValueError('Malformed symbol metadata')
        for i in range(nsyms):
            _,ntype,_,desc,_ = unpack(original,'IBBHQ',symoff+i*16)
            if ntype & 0x0e == 0 and desc >> 8 == 63:
                raise ValueError('Classic symbol references source patcher')
        excluded = {first,libraries[-1][0]}
        kept, removed = [], []
        for cmd,p,n in cmds:
            if p in excluded or cmd in (0xe,0x80000028,0x1d):
                removed.append(cmd)
            else:
                if cmd in (0x22,0x80000022,0x4,0x5,0x27,0xd):
                    raise ValueError('Unsupported executable-only/binding command')
                kept.append(bytes(image[p:p+n]))
        name_size = (24+len(IDENTIFIER)+7)//8*8
        identity = struct.pack('<6I',0xd,name_size,24,0,0x10000,0x10000)+IDENTIFIER
        kept.append(identity.ljust(name_size,b'\0'))
        packed = b''.join(kept)
        if len(packed) > old_amount:
            raise ValueError('Insufficient header space')
        # Source SDK metadata remains unchanged. SDK27.1 belongs to the separately
        # compiled app host, never to a relabeled original engine.
        struct.pack_into('<IIII',image,12,6,len(kept),len(packed),flags & ~0x200000)
        image[32:32+old_amount] = packed.ljust(old_amount,b'\0')
        new_kind,new_flags,_,new_commands = commands(image)
        if new_kind != 6 or new_flags & 0x200000 or len([c for c,_,_ in new_commands if c==0xd]) != 1:
            raise ValueError('Invalid prepared image metadata')
        after = os.fstat(stream.fileno())
        if ((before.st_ino,before.st_size,before.st_mtime_ns) !=
                (after.st_ino,after.st_size,after.st_mtime_ns) or source.stat().st_ino != before.st_ino):
            raise ValueError('Source changed during preparation')
        output.parent.mkdir(parents=True,exist_ok=True)
        created = False
        try:
            with temporary.open('xb') as out:
                created = True
                os.chmod(temporary,0o600)
                out.write(image);out.flush();os.fsync(out.fileno())
            os.chmod(temporary,0o400)
            os.link(temporary,output,follow_symlinks=False)
            temporary.unlink()
        except BaseException:
            if created and temporary.exists():temporary.unlink()
            raise
        return {'schema':1,'adapter_version':VERSION,'source_sha256':SOURCE_SHA256,
                'source_bytes':len(original),'prepared_sha256':hashlib.sha256(image).hexdigest(),
                'prepared_bytes':len(image),'file_type':'MH_DYLIB','source_sdk_unchanged':True,
                'pagezero_removed':True,'chained_segment_indexes_adjusted':True,
                'unused_source_patcher_dependency_removed':True,'source_patcher_bind_count':0,
                'old_signature_command_removed':True,'signed':False,'executed':False,
                'dyld_runtime_verified':False,'initializer_containment_verified':False,
                'original_game_launch_verified':False}


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('source',type=Path);p.add_argument('output',type=Path)
    args=p.parse_args()
    try: print(json.dumps(adapt(args.source,args.output),indent=2))
    except (ValueError,OSError,struct.error):raise SystemExit('Image preparation failed; original and prior outputs preserved.')


if __name__ == '__main__':main()
