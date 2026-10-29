"""Signing-stable section identity for the exact retained genuine Duo app host."""
import hashlib
import struct


def section_identity(data):
    if len(data) < 32 or len(data) > 8*1024**2:
        raise ValueError('Invalid host bounds')
    magic,cpu,_,kind,count,amount,_,_=struct.unpack_from('<8I',data)
    if magic!=0xfeedfacf or cpu!=0x100000c or kind!=2 or count>1024 or 32+amount>len(data):
        raise ValueError('Invalid native host')
    digest=hashlib.sha256(b'ODNativeHostSections/v1\0');position=32;sections=0;build=None
    for _ in range(count):
        cmd,size=struct.unpack_from('<II',data,position)
        if size<8 or size%8 or position+size>32+amount:raise ValueError('Invalid host command')
        if cmd==0x32:
            if size<24 or build is not None:raise ValueError('Invalid host SDK metadata')
            platform,minimum,sdk,_=struct.unpack_from('<4I',data,position+8)
            build=(platform,minimum,sdk)
        if cmd==0x19:
            if size<72:raise ValueError('Invalid host segment')
            number=struct.unpack_from('<I',data,position+64)[0]
            if size!=72+number*80:raise ValueError('Invalid host sections')
            for index in range(number):
                at=position+72+index*80
                section,segment,address,length,offset=struct.unpack_from('<16s16sQQI',data,at)
                flags=struct.unpack_from('<I',data,at+64)[0]
                if flags&255 in (1,12,18):continue
                if offset<32+amount or offset+length>len(data):raise ValueError('Invalid host section bounds')
                digest.update(struct.pack('<16s16sQQI',segment,section,address,length,flags))
                digest.update(data[offset:offset+length]);sections+=1
        position+=size
    if position!=32+amount or not sections or build!=(2,0x100400,0x1b0100):
        raise ValueError('Expected genuine retained iOS27.1/min16.4 host')
    return {'schema':1,'algorithm':'ODNativeHostSections/v1','sections':sections,
            'sha256':digest.hexdigest(),'sdk':'27.1.0','minimum_os':'16.4.0',
            'scope':'File-backed code/data sections only; signed host/plugin manifest and load-command admission remain mandatory'}
