#!/usr/bin/env python3
"""One combined inverse/control-flow check; synthetic memory only, no game run."""
import argparse
import json
import os
from pathlib import Path
import struct
import sys

from recipe import (ROOT, SOURCE_SHA, Image, build, verify, normalize, commands,
                    segments, segment_values, name, CODE_NAME, DATA_NAME, sha)
from probes import (BASE, TEXT_BYTES, DATA_BYTES, SITES, MAGIC, PATH_OFFSET,
                    COMPLETE_OFFSET, RECORD_BASE, RECORD_BYTES, RECORDS,
                    WITNESS_RECORD_OFFSET,WITNESS_TICKET_OFFSET)
from capstone import Cs,CS_ARCH_ARM64,CS_MODE_LITTLE_ENDIAN
from unicorn import Uc,UC_ARCH_ARM64,UC_MODE_ARM,UC_HOOK_CODE,UC_PROT_READ,UC_PROT_WRITE,UC_PROT_EXEC
from unicorn import arm64_const as a64

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source",type=Path);parser.add_argument("receipt",type=Path)
    parser.add_argument("--derived-output",type=Path)
    parser.add_argument("--recipe-receipt",type=Path)
    parser.add_argument("--witness-only",action="store_true")
    args=parser.parse_args();source=args.source.read_bytes()
    derived,recipe=build(source);verify(derived)
    assert normalize(derived)==source and sha(source)==SOURCE_SHA
    image=Image(derived);cmds=commands(derived)
    code=next(c for c in segments(cmds) if name(c)==CODE_NAME)
    data=next(c for c in segments(cmds) if name(c)==DATA_NAME)
    code_vm,_,code_off,_=segment_values(code);data_vm,_,data_off,_=segment_values(data)
    assert struct.unpack_from("<ii",code,56)==(5,5)
    assert struct.unpack_from("<ii",data,56)==(3,3)
    for where in (() if args.witness_only else (code_off,data_off,image.offset(SITES['entry'][0]),image.offset(0x10044fa50)+12)):
        altered=bytearray(derived);altered[where]^=1
        try:verify(bytes(altered))
        except ValueError:pass
        else:raise AssertionError("Altered derived engine admitted")
    dis=Cs(CS_ARCH_ARM64,CS_MODE_LITTLE_ENDIAN)
    for f in recipe['functions'].values():
        body=derived[image.offset(f['vm']):image.offset(f['vm'])+f['bytes']]
        assert not any(i.mnemonic in ('bl','blr','svc','hvc') for i in dis.disasm(body,f['vm']))
    scenarios=[]
    slides=(0x40000000,) if args.witness_only else (0,0x40000000)
    for slide in slides:
        uc=Uc(UC_ARCH_ARM64,UC_MODE_ARM)
        uc.mem_map(code_vm+slide,TEXT_BYTES,UC_PROT_READ|UC_PROT_WRITE|UC_PROT_EXEC)
        uc.mem_write(code_vm+slide,derived[code_off:code_off+TEXT_BYTES])
        uc.mem_protect(code_vm+slide,TEXT_BYTES,UC_PROT_READ|UC_PROT_EXEC)
        uc.mem_map(data_vm+slide,DATA_BYTES,UC_PROT_READ|UC_PROT_WRITE)
        uc.mem_write(data_vm+slide,derived[data_off:data_off+DATA_BYTES])
        for page in {site&~4095 for site,_ in SITES.values()}:
            uc.mem_map(page+slide,4096,UC_PROT_READ|UC_PROT_WRITE|UC_PROT_EXEC)
            for site,_ in SITES.values():
                if site&~4095==page:uc.mem_write(site+slide,derived[image.offset(site):image.offset(site)+4])
            uc.mem_protect(page+slide,4096,UC_PROT_READ|UC_PROT_EXEC)
        stack=0x200000000+slide;manager=0x210000000+slide;pathmem=0x220000000+slide
        uc.mem_map(stack,65536);uc.mem_map(manager,4096);uc.mem_map(pathmem,4096)
        native_sp=stack+32768;handle=0x777770000  # deliberately NEVER mapped/followed
        qregs=[getattr(a64,f'UC_ARM64_REG_Q{i}') for i in range(32)]
        xregs=[getattr(a64,f'UC_ARM64_REG_X{i}') for i in range(31)]
        wanted_stop=[None]
        def stop(u,address,size,user):
            if address==wanted_stop[0]:u.emu_stop()
        uc.hook_add(UC_HOOK_CODE,stop)
        def run(role,sp,changes):
            before={i:0xA100000000000000+i*0x10101 for i in range(31)}
            before.update(changes)
            # Poison the key-bearing callee-saved register, never dereferenced.
            if role=='filename':before[19]=0xDEADC0DE000
            for i,v in before.items():uc.reg_write(xregs[i],v)
            for i,r in enumerate(qregs):uc.reg_write(r,(i+1)*(1<<96)+(i+17))
            uc.reg_write(a64.UC_ARM64_REG_SP,sp);uc.reg_write(a64.UC_ARM64_REG_NZCV,0xA0000000)
            site=SITES[role][0]+slide;wanted_stop[0]=site+4
            frame=bytes(uc.mem_read(sp,96))
            uc.emu_start(site,site+4,count=20000)
            assert uc.reg_read(a64.UC_ARM64_REG_PC)==site+4
            assert uc.reg_read(a64.UC_ARM64_REG_SP)==sp
            assert uc.reg_read(a64.UC_ARM64_REG_NZCV)==0xA0000000
            expected=before.copy()
            dest,origin={'entry':(22,0),'preferred':(20,0),'fallback':(20,0),
                         'finish':(0,20),'filename':(1,20)}[role]
            expected[dest]=before[origin]
            for i,v in expected.items():assert uc.reg_read(xregs[i])==v,(role,i)
            for i,r in enumerate(qregs):assert uc.reg_read(r)==(i+1)*(1<<96)+(i+17)
            after=bytes(uc.mem_read(sp,96))
            assert after[8:]==frame[8:] if role=='entry' else after==frame
        def write64(address,value):uc.mem_write(address,struct.pack('<Q',value))
        def read64(address):return struct.unpack('<Q',uc.mem_read(address,8))[0]
        def begin(cache=0,sp=native_sp):
            write64(manager+16,cache);run('entry',sp,{0:manager})
            return read64(sp)
        def row(ticket):
            address=data_vm+slide+RECORD_BASE+((ticket-1)&15)*RECORD_BYTES
            fields=struct.unpack('<10Q',uc.mem_read(address,80))
            n=fields[7];return address,fields,bytes(uc.mem_read(address+PATH_OFFSET,min(n,1023)))
        def filename(value,attempt=1,sp=native_sp,too_long=False,short=False):
            psp=sp-96
            return_pc=SITES['preferred' if attempt==1 else 'fallback'][0]+slide
            write64(psp+88,return_pc)
            if short:
                assert len(value)<=22
                raw=value+b'\0'*(23-len(value))+bytes([len(value)])
                uc.mem_write(psp+24,raw);pointer=psp+24
            else:
                n=1024 if too_long else len(value)
                pointer=0xDDDDD0000 if too_long else pathmem
                if not too_long:uc.mem_write(pointer,value+b'\0')
                uc.mem_write(psp+24,struct.pack('<QQQ',pointer,n,(1<<63)|(n+1)))
            run('filename',psp,{0:pointer,20:manager+16})
        def returned(role,result,sp=native_sp):run(role,sp,{0:result,22:manager+16})
        def finish(result,sp=native_sp):
            write64(manager+16,handle);run('finish',sp,{20:result,22:manager+16})
        candidate=b'/synthetic-own/Documents/assets/sqlite/current/en/database.db'
        t=begin();filename(candidate);returned('preferred',0);finish(0)
        a,f,p=row(t)
        assert f[0]==t and f[2]==0 and f[3]==0 and f[5]==0 and f[6]==1 and f[9]==1 and p==candidate
        assert read64(a+COMPLETE_OFFSET)==t and read64(data_vm+slide+24)==0
        scenarios.append('preferred source path + native success tuple captured; slide='+str(slide))
        if args.witness_only:
            published=data_vm+slide+WITNESS_TICKET_OFFSET
            witness=data_vm+slide+WITNESS_RECORD_OFFSET
            snapshot=bytes(uc.mem_read(witness,1112))
            assert read64(published)==t and snapshot==bytes(uc.mem_read(a,1112))
            for _ in range(18):begin(handle);finish(1)
            assert read64(published)==t and bytes(uc.mem_read(witness,1112))==snapshot
            assert read64(data_vm+slide+48)>t+16
            scenarios.append('retained schema witness survives cached reuse beyond ring capacity')
            begin();assert read64(published)==0
            filename(candidate);returned('preferred',0);finish(16)
            assert read64(published)==0
            scenarios.append('empty-cache entry invalidates before open; schema failure cannot restore witness')
            fresh=begin();filename(candidate);returned('preferred',0);finish(0)
            assert read64(published)==fresh and read64(witness)==fresh
            scenarios.append('new successful open publishes its own completed witness')
            begin(handle+16);assert read64(published)==0
            run('finish',native_sp,{20:1,22:manager+16})
            assert read64(published)==0 and read64(data_vm+slide+24)==0
            scenarios.append('changed cache identity invalidates witness; reuse cannot manufacture one')
            continue
        t=begin();filename(candidate);returned('preferred',26)
        fallback=b'/synthetic-own/Bundle/database.db'
        filename(fallback,2);returned('fallback',0);finish(0)
        a,f,p=row(t);assert f[3]==26 and f[4]==0 and f[5]==0 and f[6]==2 and p==fallback and p!=candidate
        scenarios.append('fallback success cannot claim chosen candidate')
        t=begin();filename(candidate);returned('preferred',0);finish(16)
        assert row(t)[1][5]==16;scenarios.append('schema failure16 retained')
        t=begin(handle);finish(1)
        f=row(t)[1];assert f[2]==handle and f[5]==1 and f[7]==0
        scenarios.append('cached reuse1 supplies no fresh acceptance')
        t=begin();filename(b'',too_long=True);returned('preferred',0);finish(0)
        f=row(t)[1];assert f[7]==0 and f[9]==0
        scenarios.append('oversized path never read and cannot supply identity')
        t=begin();filename(b'database.db',short=True);returned('preferred',0);finish(0)
        assert row(t)[2]==b'database.db';scenarios.append('actual inline-string representation handled')
        t=begin();address=row(t)[0];write64(address,t+16);finish(0)
        assert read64(data_vm+slide+40)==1 and read64(data_vm+slide+24)==0
        scenarios.append('collision drops observation without changing native return')
        uc.mem_write(data_vm+slide+40,b'\0'*8)
        t=begin(sp=native_sp);u=begin(sp=native_sp+4096)
        finish(0,sp=native_sp);finish(0,sp=native_sp+4096)
        assert read64(data_vm+slide+24)==0 and read64(data_vm+slide+32)==1
        scenarios.append('overlapping native invocations marked unsuitable for admission')
    result={'schema':1,'kind':'optional-observer-inverse-and-synthetic-controlflow-check',
        'result':'passed','targeted_runs':1,'exact_inverse_and_regeneration':True,
        'tampered_derived_bytes_rejected':not args.witness_only,'rx_probe_rw_data_no_wx_segment':True,
        'registers_including_live_lr_vectors_nzcv_sp_and_native_frame_preserved':True,
        'key_pointer_provider_and_cached_sqlite_handle_unmapped_in_emulator':True,
        'aslr_slides_checked':len(slides),'scenarios':scenarios,'derived_sha256':sha(derived),
        'original_source_unchanged':args.source.read_bytes()==source,
        'original_game_executed':False,'ios_dyld_signing_device_verified':False,
        'native_master_accepted':False}
    if args.witness_only:
        result['kind']='retained-schema-witness-targeted-check'
        result['prior_inverse_tamper_and_full_matrix_evidence_reused']='check-evidence.json'
        result['tampered_derived_bytes_rejected']='prior unchanged recipe evidence; not repeated'
    if args.derived_output:
        if args.derived_output.resolve()==args.source.resolve():raise ValueError('Separate output required')
        fd=os.open(args.derived_output,os.O_WRONLY|os.O_CREAT|os.O_EXCL|os.O_NOFOLLOW,0o400)
        with os.fdopen(fd,'wb') as f:f.write(derived);f.flush();os.fsync(f.fileno())
    if args.recipe_receipt:args.recipe_receipt.write_text(json.dumps(recipe,indent=2)+'\n')
    args.receipt.write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps({'result':'passed','targeted_runs':1,'source_or_device_game_execution':False}))
if __name__=='__main__':main()
