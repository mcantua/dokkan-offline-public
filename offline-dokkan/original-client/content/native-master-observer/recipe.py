#!/usr/bin/env python3
"""OPTIONAL offline derivation of the pinned original engine, never in-place.

Adds RX leaf probes / RW telemetry before LINKEDIT, updates only relocation
metadata file offsets and five exact MOVs. Normalization is an exact inverse;
verification additionally regenerates and compares EVERY derived byte.
No original game code is executed and no key/provider body is inspected.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import struct
import sys

from probes import (ROOT, BASE, TEXT_BYTES, DATA_BYTES, RECORD_BYTES, RECORDS,
                    RECORD_BASE, MAGIC, SITES, assemble,
                    WITNESS_RECORD_OFFSET,WITNESS_TICKET_OFFSET)
sys.path[:0]=[str(ROOT/"offline-dokkan/tools"),str(ROOT/"downloads/capstone/runtime")]
from objc_runtime_metadata import Image
from capstone import Cs,CS_ARCH_ARM64,CS_MODE_LITTLE_ENDIAN

SOURCE_BYTES=55697728
SOURCE_SHA="efaabfc9b3cdb0e2eeb550b6ea616f5eeb565c6584ad838b765f34539648d222"
CODE_NAME=b"__ODOBS_TEXT"
DATA_NAME=b"__ODOBS_DATA"
LINKEDIT_DATA={0x1d,0x1e,0x26,0x29,0x2b,0x2e,0x80000033,0x80000034}
PREFIX=TEXT_BYTES+DATA_BYTES

def u32(b,p):return struct.unpack_from("<I",b,p)[0]
def p32(b,p,v):struct.pack_into("<I",b,p,v)
def align(n):return (n+16383)&~16383
def sha(b):return hashlib.sha256(b).hexdigest()

def commands(b):
    if len(b)<32 or u32(b,0)!=0xfeedfacf or u32(b,4)!=0x100000c:raise ValueError("Pinned thin arm64 only")
    n,size=struct.unpack_from("<II",b,16);pos=32;out=[]
    if n>128 or size>16384:raise ValueError("Unbounded command header")
    for _ in range(n):
        cmd,length=struct.unpack_from("<II",b,pos)
        if length<8 or length%8 or pos+length>32+size:raise ValueError("Invalid command")
        out.append(bytearray(b[pos:pos+length]));pos+=length
    if pos!=32+size:raise ValueError("Invalid header size")
    return out

def segments(cmds):
    return [c for c in cmds if u32(c,0)==0x19]
def name(c):return bytes(c[8:24]).split(b"\0",1)[0]
def segment_values(c):return struct.unpack_from("<QQQQ",c,24)
def selected(cmds,kind):
    rows=[c for c in cmds if u32(c,0)==kind]
    if len(rows)!=1:raise ValueError("Missing/duplicate selected command")
    return rows[0]

def chain_change(blob,index,adding):
    b=bytearray(blob)
    version,start,imports,symbols,count,fmt,symfmt=struct.unpack_from("<7I",b)
    if version or start<28 or start+4>len(b):raise ValueError("Unexpected chains")
    n=u32(b,start);entries=list(struct.unpack_from(f"<{n}I",b,start+4))
    if adding:
        if index>=n or entries[index]:raise ValueError("LINKEDIT must have no pointer fixups")
        at=start+4+4*index;entries[index:index]=[0,0];delta=8
        b[at:at]=b"\0"*8
    else:
        if index+2>=n or any(entries[index:index+3]):raise ValueError("Unexpected observer/linkedit fixups")
        at=start+4+4*index;del entries[index:index+2];delta=-8
        del b[at:at+8]
    for i,v in enumerate(entries):
        if v:entries[i]=v+delta
    p32(b,start,len(entries));struct.pack_into(f"<{len(entries)}I",b,start+4,*entries)
    for field,value in ((8,imports),(12,symbols)):
        if value>=at:p32(b,field,value+delta)
    return bytes(b),at

def section_segment(segname,sectname,vm,off,amount,prot,flags):
    c=bytearray(152);struct.pack_into("<II",c,0,0x19,152);c[8:8+len(segname)]=segname
    struct.pack_into("<QQQQiiII",c,24,vm,amount,off,amount,prot,prot,1,0)
    c[72:72+len(sectname)]=sectname;c[88:88+len(segname)]=segname
    struct.pack_into("<QQIIIIIIII",c,104,vm,amount,off,2 if prot==5 else 3,0,0,flags,0,0,0)
    return c

def rewrite_offsets(cmds,map_offset,chain_delta,vm_delta):
    for c in cmds:
        cmd=u32(c,0)
        if cmd==0x19:
            if name(c)==b"__LINKEDIT":
                vm,vs,off,size=segment_values(c)
                size+=chain_delta
                struct.pack_into("<QQQQ",c,24,vm+vm_delta,align(size),map_offset(off),size)
            else:
                n=u32(c,64)
                for i in range(n):
                    p=72+i*80
                    for field in (48,56):
                        value=u32(c,p+field)
                        if value:p32(c,p+field,map_offset(value))
        elif cmd==2:
            for field in (8,16):p32(c,field,map_offset(u32(c,field)))
        elif cmd==0xb:
            for field in (32,40,48,56,64,72):
                value=u32(c,field)
                if value:p32(c,field,map_offset(value))
        elif cmd in LINKEDIT_DATA:
            value=u32(c,8)
            if value:p32(c,8,map_offset(value))
            if cmd==0x80000034:p32(c,12,u32(c,12)+chain_delta)
        elif cmd in (0x22,0x80000022):
            for field in (8,16,24,32,40):
                value=u32(c,field)
                if value:p32(c,field,map_offset(value))
        elif cmd==0x16:
            if u32(c,8):p32(c,8,map_offset(u32(c,8)))
        elif cmd in (0x1d,0x3,0x31,0x80000035):
            raise ValueError("Unsupported optional metadata command")

def replace_header(data,cmds):
    b=bytearray(data);old=u32(b,20);payload=b"".join(cmds)
    if len(payload)+32>16384:raise ValueError("Header room exceeded")
    if len(payload)>old and any(b[32+old:32+len(payload)]):raise ValueError("Header padding is not empty")
    b[32:32+max(old,len(payload))]=payload.ljust(max(old,len(payload)),b"\0")
    struct.pack_into("<II",b,16,len(cmds),len(payload))
    return b

def stack_slot_proof(raw,image):
    body=raw[image.offset(0x10044fa50):image.offset(0x10044fa50)+316]
    if sha(body)!="ac277142cbeb5788e5b5983ce1dd621e49a3d359803f87a2e95c41fce277e46b":raise ValueError("Cached wrapper changed")
    cs=Cs(CS_ARCH_ARM64,CS_MODE_LITTLE_ENDIAN);cs.detail=True;accesses=[]
    for i in cs.disasm(body,0x10044fa50):
        for op in i.operands:
            if op.type==3 and cs.reg_name(op.mem.base)=="sp":
                width=16 if i.mnemonic.startswith(("stp","ldp")) else (1 if "sb" in i.mnemonic or i.mnemonic.endswith("b") else 8)
                if op.mem.disp<8:raise ValueError("Native code accesses reserved ticket slot")
                accesses.append({"offset":op.mem.disp,"width":width})
        if i.mnemonic in ("add","mov") and len(i.operands)>1 and i.operands[1].type==1 and cs.reg_name(i.operands[1].reg)=="sp":
            if len(i.operands)<3 or i.operands[2].type!=2 or i.operands[2].imm<8:raise ValueError("Native SP+0 alias escapes")
    return {"whole_exact_body_bytes":316,"reserved_slot":[0,8],"observed_native_stack_ranges":accesses,
            "provider_body_inspected":False,"indirect_key_result_starts_at_sp_plus":8}

def build(raw):
    if len(raw)!=SOURCE_BYTES or sha(raw)!=SOURCE_SHA:raise ValueError("Pinned immutable input required")
    image=Image(raw);cmds=commands(raw);segs=segments(cmds)
    link=next(c for c in segs if name(c)==b"__LINKEDIT");li=segs.index(link)
    vm,vs,off,size=segment_values(link)
    if li!=len(segs)-1 or off+size!=len(raw) or off%16384 or vm%16384:raise ValueError("Unexpected LINKEDIT layout")
    if any(vm<=p<vm+vs for p in image.rebases.values()):raise ValueError("LINKEDIT rebase target cannot move")
    if any(u32(c,0)==0x1d for c in cmds):raise ValueError("Unsigned prepared source required")
    proof=stack_slot_proof(raw,image)
    code,functions=assemble(vm);data=bytearray(DATA_BYTES)
    data[:8]=MAGIC;struct.pack_into("<Q",data,8,1);struct.pack_into("<Q",data,56,RECORD_BYTES)
    chain=selected(cmds,0x80000034);co,cz=struct.unpack_from("<II",chain,8)
    fixed,chain_at=chain_change(raw[co:co+cz],li,True)
    inserts=[(off,code+data),(co+chain_at,b"\0"*8)]
    # Replace the entire chained blob so its internal offsets/count change.
    b=bytearray(raw);b[co:co+cz]=fixed
    b[off:off]=code+data
    def mapped(value):return value+sum(len(payload) for pos,payload in inserts if value>=pos)
    rewrite_offsets(cmds,mapped,8,PREFIX)
    idx=cmds.index(link)
    cmds[idx:idx]=[section_segment(CODE_NAME,b"__odobs_code",vm,off,TEXT_BYTES,5,0x80000400),
                   section_segment(DATA_NAME,b"__odobs_data",vm+TEXT_BYTES,off+TEXT_BYTES,DATA_BYTES,3,0)]
    b=replace_header(b,cmds)
    patched=[]
    for role,(site,word) in SITES.items():
        position=image.offset(site)
        if u32(raw,position)!=word:raise ValueError("Displaced instruction changed")
        target=functions[role]["vm"];delta=target-site
        if delta%4 or not -(1<<27)<=delta<(1<<27):raise ValueError("Probe branch out of range")
        p32(b,position,0x14000000|((delta>>2)&0x3ffffff))
        patched.append({"role":role,"source_rva":site-BASE,"probe_rva":target-BASE,
                        "displaced_word":word,"patched_word":u32(b,position)})
    Image(bytes(b))
    return bytes(b),{"schema":1,"kind":"optional-passive-native-master-probe-recipe",
        "original_sha256":SOURCE_SHA,"derived_sha256":sha(b),"derived_bytes":len(b),
        "code_rva":vm-BASE,"data_rva":vm+TEXT_BYTES-BASE,"code_bytes":TEXT_BYTES,"data_bytes":DATA_BYTES,
        "code_sha256":sha(code),"initial_data_sha256":sha(data),"patched_sites":patched,
        "retained_witness_record_offset":WITNESS_RECORD_OFFSET,
        "retained_witness_ticket_offset":WITNESS_TICKET_OFFSET,
        "functions":{k:{x:v for x,v in f.items() if x!="assembly"} for k,f in functions.items()},
        "stack_slot_proof":proof,"original_key_or_provider_inspected":False,
        "original_function_start_and_unwind_payloads_unchanged":True,
        "direct_branch_islands_preserve_live_lr":True,
        "native_runtime_executed":False,"master_accepted":False}

def normalize(derived):
    cmds=commands(derived);segs=segments(cmds)
    code=next(c for c in segs if name(c)==CODE_NAME);data=next(c for c in segs if name(c)==DATA_NAME)
    link=next(c for c in segs if name(c)==b"__LINKEDIT")
    vm,_,off,_=segment_values(code);dvm,_,doff,_=segment_values(data);lvm,_,loff,_=segment_values(link)
    if segment_values(code)[1:]!=(TEXT_BYTES,off,TEXT_BYTES) or dvm!=vm+TEXT_BYTES or doff!=off+TEXT_BYTES or lvm!=vm+PREFIX or loff!=off+PREFIX:raise ValueError("Observer segment layout changed")
    original_li=segs.index(code)
    chain=selected(cmds,0x80000034);co,cz=struct.unpack_from("<II",chain,8)
    fixed,chain_at=chain_change(derived[co:co+cz],original_li,False)
    deletions=[(off,PREFIX),(co+chain_at,8)]
    def inverse(value):
        if any(a<=value<a+n for a,n in deletions):raise ValueError("Metadata points inside observer insertion")
        return value-sum(n for a,n in deletions if value>=a+n)
    b=bytearray(derived);b[co:co+cz]=fixed
    del b[off:off+PREFIX]
    cmds=[c for c in cmds if not(u32(c,0)==0x19 and name(c) in (CODE_NAME,DATA_NAME))]
    rewrite_offsets(cmds,inverse,-8,-PREFIX)
    b=replace_header(b,cmds)
    original_image=Image(bytes(b))
    for role,(site,word) in SITES.items():p32(b,original_image.offset(site),word)
    if len(b)!=SOURCE_BYTES or sha(b)!=SOURCE_SHA:raise ValueError("Exact inverse did not recover pinned source")
    return bytes(b)

def verify(derived):
    original=normalize(derived);expected,receipt=build(original)
    if derived!=expected:raise ValueError("Derived bytes differ from exact allowed recipe")
    receipt["exact_inverse_verified"]=True;receipt["deterministic_regeneration_verified"]=True
    return receipt

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source",type=Path);parser.add_argument("--output",type=Path)
    parser.add_argument("--verify",type=Path);parser.add_argument("--receipt",type=Path,required=True)
    args=parser.parse_args()
    if args.verify:
        result=verify(args.verify.read_bytes())
    else:
        if not args.source or not args.output or args.source.resolve()==args.output.resolve():parser.error("Separate source/output required")
        raw=args.source.read_bytes();derived,result=build(raw);result=verify(derived)
        fd=os.open(args.output,os.O_WRONLY|os.O_CREAT|os.O_EXCL|os.O_NOFOLLOW,0o400)
        with os.fdopen(fd,"wb") as f:f.write(derived);f.flush();os.fsync(f.fileno())
    args.receipt.write_text(json.dumps(result,indent=2)+"\n")
    print(json.dumps({"optional_derived_recipe_verified":True,"native_runtime":False,"master_accepted":False}))
if __name__=="__main__":main()
