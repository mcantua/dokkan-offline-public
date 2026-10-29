#!/usr/bin/env python3
"""Bounded exact-table xrefs for the supplied client's tutorial master readers.

Never executes the client or emits strings beyond the reviewed tutorial schema.
This inspection follows original table references, not inferred gameplay rules.
"""
import argparse
import bisect
import hashlib
import json
import re
from pathlib import Path
import struct
import sys

HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE.parents[1]/'tools'))
from objc_runtime_metadata import Image
from inspect_handler_fields import function_starts,sections_and_symbols
PREPARED_SHA='efaabfc9b3cdb0e2eeb550b6ea616f5eeb565c6584ad838b765f34539648d222'
TABLES=frozenset(('tutorial_phases','tutorial_steps','tutorial_processes'))
FIELDS=TABLES|frozenset(('id','number','phase_id','step_id','process_type','parameters',
                       'is_resume_point','tutorial_scene_url','tutorial','contents_lv','progress','is_finished'))


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--source',type=Path,required=True);p.add_argument('--capstone-runtime',type=Path,required=True)
    p.add_argument('--private-output',type=Path,required=True);p.add_argument('--report',type=Path,required=True)
    args=p.parse_args();raw=args.source.read_bytes()
    if hashlib.sha256(raw).hexdigest()!=PREPARED_SHA or 'private' not in args.private_output.parts:raise ValueError('Invalid source/output identity')
    image=Image(raw);starts=function_starts(image);sections,_,_=sections_and_symbols(image)
    text,size,_,_=sections[b'__text'];ends=starts[1:]+[text+size]
    spans={s:e for s,e in zip(starts,ends) if text<=s<e<=text+size}
    cs_addr,cs_size,_,_=sections[b'__cstring'];cs_pos=image.offset(cs_addr,cs_size)
    strings={};literal_counts={name:0 for name in TABLES};sql_shapes={}
    for name in TABLES:
        needle=name.encode();offset=0
        while True:
            where=raw.find(needle,cs_pos+offset,cs_pos+cs_size)
            if where<0:break
            offset=where-cs_pos+len(needle)
            begin=raw.rfind(b'\0',cs_pos,where)+1
            if begin==0:begin=cs_pos
            end=raw.find(b'\0',where,cs_pos+cs_size)
            if end<begin or end-begin>4096:continue
            value=raw[begin:end].decode('utf-8','strict')
            if value==name or value.lstrip().lower().startswith('select'):
                strings[cs_addr+begin-cs_pos]=name;literal_counts[name]+=1
                where_clause=re.split(r'\bwhere\b',value,flags=re.I)
                allowed=[field for field in FIELDS-TABLES if len(where_clause)>1 and re.search(r'\b'+re.escape(field)+r'\b',where_clause[1])]
                sql_shapes[name]={'sql_select':value.lstrip().lower().startswith('select'),
                    'where_clause_present':len(where_clause)>1,'allowlisted_where_fields':sorted(allowed),
                    'bound_parameter_count':value.count('?'),'literal_values_exported':False}
    codepos=image.offset(text,size);refs=[]
    for rel in range(0,size-32,4):
        word=struct.unpack_from('<I',raw,codepos+rel)[0]
        if word&0x9f000000!=0x90000000:continue
        immediate=((word>>5)&0x7ffff)<<2|((word>>29)&3)
        if immediate&0x100000:immediate-=0x200000
        register=word&31;page=((text+rel)&~4095)+(immediate<<12)
        for distance in range(4,32,4):
            op=struct.unpack_from('<I',raw,codepos+rel+distance)[0]
            rn=(op>>5)&31;rd=op&31
            address=None;target=None
            if op&0xff000000==0x91000000 and rn==register:
                address=page+(((op>>10)&4095)<<(12 if op&(1<<22) else 0));target=address
            elif op&0xffc00000==0xf9400000 and rn==register:
                address=page+(((op>>10)&4095)<<3)
                try:target=image.pointer(address)
                except ValueError:pass
            if target in strings:
                at=text+rel+distance;n=bisect.bisect_right(starts,at)-1
                if n>=0 and starts[n] in spans:
                    refs.append({'start':starts[n],'instruction':at,'table':strings[target]})
            if rd==register and op&0xff000000 not in (0x91000000,):break
            if op&0xfc000000==0x94000000 and register<=18:break
    selected=sorted({x['start'] for x in refs})
    if len(selected)>32 or any(spans[x]-x>32768 for x in selected):raise ValueError('Tutorial table frontier exceeds bound')
    sys.path.insert(0,str(args.capstone_runtime.resolve()))
    from capstone import Cs,CS_ARCH_ARM64,CS_MODE_ARM
    from capstone.arm64 import ARM64_OP_REG,ARM64_OP_IMM,ARM64_OP_MEM
    decoder=Cs(CS_ARCH_ARM64,CS_MODE_ARM);decoder.detail=True
    def ident(start):
        if start not in spans:return {'bytes':0,'sha256':'unmapped-or-import'}
        n=spans[start]-start;off=image.offset(start,n)
        return {'bytes':n,'sha256':hashlib.sha256(raw[off:off+n]).hexdigest()}
    summaries=[];private=[]
    for start in selected:
        end=spans[start];off=image.offset(start,end-start)
        state={f'x{i}':f'input{i}' for i in range(9)};events=[];fields=set()
        def reg(n):
            s=decoder.reg_name(n)
            return 'x'+s[1:] if s.startswith('w') and s[1:].isdigit() else s
        def render(v):
            if isinstance(v,int):
                if v in strings:
                    fields.add(strings[v]);return 'table-sql:'+strings[v]
                try:s=image.string(v,128)
                except (ValueError,UnicodeError):s=None
                if s in FIELDS:fields.add(s);return 'field:'+s
                return 'opaque-address' if v>4096 else 'constant:'+str(v)
            return str(v)[:300]
        def value(op):
            if op.type==ARM64_OP_REG:return state.get(reg(op.reg),'unknown')
            if op.type==ARM64_OP_IMM:return op.imm
            if op.type==ARM64_OP_MEM:
                b=state.get(reg(op.mem.base),'unknown')
                if isinstance(b,int):
                    try:return image.pointer(b+op.mem.disp)
                    except ValueError:return 'unknown-load'
                return f'load({render(b)},{op.mem.disp})'
            return 'unknown'
        for ins in decoder.disasm(raw[off:off+end-start],start):
            ops=ins.operands
            if ins.mnemonic in ('adr','adrp') and len(ops)==2:state[reg(ops[0].reg)]=ops[1].imm
            elif ins.mnemonic=='mov' and len(ops)==2:state[reg(ops[0].reg)]=value(ops[1])
            elif ins.mnemonic in ('add','sub') and len(ops)==3:
                a,b=value(ops[1]),value(ops[2]);sign=1 if ins.mnemonic=='add' else -1
                state[reg(ops[0].reg)]=a+sign*b if isinstance(a,int) and isinstance(b,int) else f'{ins.mnemonic}({render(a)},{render(b)})'
            elif ins.mnemonic.startswith('ldr') and len(ops)>1:state[reg(ops[0].reg)]=value(ops[1])
            elif ins.mnemonic in ('bl','blr'):
                target=ops[0].imm if ops and ops[0].type==ARM64_OP_IMM else None
                events.append({'callee':ident(target),'args':{f'x{i}':render(state.get(f'x{i}','unknown')) for i in (0,1,2,3,4,8)}})
                state={k:v for k,v in state.items() if k[1:].isdigit() and int(k[1:])>=19};state['x0']='call_result'+str(len(events)-1)
            elif ops and ops[0].type==ARM64_OP_REG and ins.mnemonic not in ('cmp','cmn','tst','cbz','cbnz','tbz','tbnz','str','strb','stur','stp','ret'):
                state.pop(reg(ops[0].reg),None)
        summaries.append({**ident(start),'table_references':sorted({x['table'] for x in refs if x['start']==start}),
                          'allowlisted_fields':sorted(fields),'calls':events})
        private.append({'start':start,'end':end,**ident(start)})
    args.private_output.parent.mkdir(parents=True,exist_ok=True)
    args.private_output.write_text(json.dumps({'source_sha256':PREPARED_SHA,'bodies':private,'table_xrefs':refs,'symbolic_summaries':summaries},indent=2)+'\n')
    args.report.write_text(json.dumps({'kind':'actual-current-tutorial-table-frontier','prepared_source_sha256':PREPARED_SHA,
        'literal_counts':literal_counts,'sql_shapes':sql_shapes,'referenced_bodies':[{k:v for k,v in s.items() if k!='calls'} for s in summaries],
        'user_progress_to_master_phase_mapping_verified':False,'native_tutorial_execution_verified':False,
        'starting_state_admitted':False,'http_route_admitted':False,
        'limits':['Exact reviewed master table names only.','ADRP with immediate ADD/LDR lookahead is a partial static reference recovery.','No source strings outside the reviewed schema emitted.']},indent=2)+'\n')
    print('Bounded tutorial master-table SQL references recovered; no phase policy admitted.')


if __name__=='__main__':
    try:main()
    except Exception:raise SystemExit('Tutorial table reference analysis failed; no client values emitted.')
