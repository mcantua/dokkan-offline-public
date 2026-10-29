#!/usr/bin/env python3
"""Add an authored-plugin dependency to the exact genuine SDK27.1 app shell.

Retains actual compiled code/SDK; no version-field substitution, signing or app
packaging. Existing outputs and the retained original are never overwritten.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import struct

from adapt_image import commands
from host_sections import section_identity

SOURCE_BYTES=332320
SOURCE_SHA256='18db225cd578fcfc724b1dbf6c0b89eb2213fb05d6113cd52fbc1a1ce006218a'
PLUGIN=b'@executable_path/Frameworks/OfflineDokkanHost.dylib\0'


def inject(source,output):
    source,output=Path(source),Path(output);stage=output.with_name(output.name+'.preparing')
    if source.resolve()==output.resolve() or output.exists() or output.is_symlink() or stage.exists() or stage.is_symlink():
        raise ValueError('Existing original/candidate preserved')
    fd=os.open(source,os.O_RDONLY|os.O_NOFOLLOW)
    with os.fdopen(fd,'rb') as stream:
        before=os.fstat(stream.fileno());data=stream.read(SOURCE_BYTES+1)
        if len(data)!=SOURCE_BYTES or hashlib.sha256(data).hexdigest()!=SOURCE_SHA256:
            raise ValueError('Wrong genuine host')
        expected=section_identity(data)
        kind,flags,old_amount,cmds=commands(data)
        if kind!=2 or not flags&0x200000:raise ValueError('Expected retained PIE main')
        first_section=len(data);kept=[]
        for cmd,p,n in cmds:
            if cmd==0x19:
                count=struct.unpack_from('<I',data,p+64)[0]
                if n!=72+count*80:raise ValueError('Invalid host segment')
                for i in range(count):
                    q=p+72+i*80;offset=struct.unpack_from('<I',data,q+48)[0]
                    length=struct.unpack_from('<Q',data,q+40)[0]
                    if length and offset:first_section=min(first_section,offset)
            if cmd==0xc:
                no=struct.unpack_from('<I',data,p+8)[0]
                if data[p+no:p+n].split(b'\0')[0]==PLUGIN.rstrip(b'\0'):
                    raise ValueError('Host plugin already present')
            if cmd!=0x1d:kept.append(data[p:p+n])
        amount=(24+len(PLUGIN)+7)//8*8
        kept.append((struct.pack('<6I',0xc,amount,24,0,0x10000,0x10000)+PLUGIN).ljust(amount,b'\0'))
        packed=b''.join(kept);end=32+len(packed)
        if end>first_section or any(data[32+old_amount:max(end,32+old_amount)]):
            raise ValueError('No verified unused header padding')
        image=bytearray(data);struct.pack_into('<II',image,16,len(kept),len(packed))
        image[32:max(end,32+old_amount)]=packed.ljust(max(len(packed),old_amount),b'\0')
        identity=section_identity(image)
        if identity!=expected:raise ValueError('Genuine host sections changed')
        after=os.fstat(stream.fileno())
        if (before.st_ino,before.st_size,before.st_mtime_ns)!=(after.st_ino,after.st_size,after.st_mtime_ns):
            raise ValueError('Host changed while reading')
        output.parent.mkdir(parents=True,exist_ok=True);created=False
        try:
            with stage.open('xb') as out:
                created=True;os.chmod(stage,0o600);out.write(image);out.flush();os.fsync(out.fileno())
            os.chmod(stage,0o400);os.link(stage,output,follow_symlinks=False);stage.unlink()
        except BaseException:
            if created and stage.exists():stage.unlink()
            raise
        return {'schema':1,'source_sha256':SOURCE_SHA256,'source_bytes':SOURCE_BYTES,
                'prepared_sha256':hashlib.sha256(image).hexdigest(),'prepared_bytes':len(image),
                'host_section_identity':identity,'compiled_sdk_unchanged':True,
                'plugin_dependency_added':True,'old_signature_command_removed':True,
                'signed':False,'executed':False,'original_game_launch_verified':False}


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('source',type=Path);p.add_argument('output',type=Path)
    a=p.parse_args()
    try:print(json.dumps(inject(a.source,a.output),indent=2))
    except (ValueError,OSError,struct.error):raise SystemExit('Host preparation failed; original/candidate preserved.')


if __name__=='__main__':main()
