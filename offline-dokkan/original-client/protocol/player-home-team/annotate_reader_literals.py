#!/usr/bin/env python3
"""Annotate allowlisted literal references in already pinned player reader spans.

This is a static input for scoped decompilation, not proof of field ownership,
HTTP routing, requiredness, defaults or playable game behavior. Addresses stay
in the mandatory private output. The original source is opened readonly.
"""
import argparse
import hashlib
import json
from pathlib import Path
import sys

HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE.parents[2]/'tools'))
from objc_runtime_metadata import Image
sys.path.insert(0,str(HERE.parents[1]/'protocol-inspection'))
from trace_tutorial_state import PREPARED_SHA


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--source',type=Path,required=True)
    ap.add_argument('--frontier',type=Path,required=True)
    ap.add_argument('--capstone-runtime',type=Path,required=True)
    ap.add_argument('--private-output',type=Path,required=True)
    ap.add_argument('--report',type=Path,required=True)
    args=ap.parse_args()
    if 'private' not in args.private_output.parts:raise ValueError('Address annotations must stay private')
    raw=args.source.read_bytes()
    if hashlib.sha256(raw).hexdigest()!=PREPARED_SHA:raise ValueError('Source pin changed')
    frontier=json.loads(args.frontier.read_text())
    if frontier.get('source_sha256')!=PREPARED_SHA:raise ValueError('Frontier pin changed')
    spans=frontier['body_spans']
    if not 1<=len(spans)<=8:raise ValueError('Reader scope exceeds bound')
    schema=json.loads((HERE.parents[2]/'research/cached-resource-response-schema.json').read_text())
    fields=set()
    def names(node):
        if not isinstance(node,dict):return
        for k,v in node.get('properties',{}).items():
            if k!='[redacted-key]':fields.add(k)
            names(v)
        for item in node.get('items',[]):names(item)
    names(schema['structure'])
    fields.update(('user','cards','teams','user_card_teams','selected_team_num','selected_kobetu_team_num','user_card_ids','num','team_bgm_filename'))
    image=Image(raw)
    sys.path.insert(0,str(args.capstone_runtime.resolve()))
    from capstone import Cs,CS_ARCH_ARM64,CS_MODE_ARM
    from capstone.arm64 import ARM64_OP_IMM,ARM64_OP_REG
    cs=Cs(CS_ARCH_ARM64,CS_MODE_ARM);cs.detail=True
    detailed=[];public=[]
    for span in spans:
        start,end=span['start'],span['end'];size=end-start
        if not 0<size<=32768:raise ValueError('Reader span invalid')
        off=image.offset(start,size);body=raw[off:off+size]
        if hashlib.sha256(body).hexdigest()!=span['sha256']:raise ValueError('Reader body changed')
        registers={};refs=[]
        for ins in cs.disasm(body,start):
            ops=ins.operands;address=None
            if ins.mnemonic in ('adrp','adr') and len(ops)==2:
                registers[ops[0].reg]=ops[1].imm;address=ops[1].imm
            elif ins.mnemonic=='add' and len(ops)==3 and ops[1].type==ARM64_OP_REG and ops[2].type==ARM64_OP_IMM:
                base=registers.get(ops[1].reg)
                if isinstance(base,int):
                    address=base+(ops[2].imm << ops[2].shift.value);registers[ops[0].reg]=address
                else:registers.pop(ops[0].reg,None)
            elif ins.mnemonic=='mov' and len(ops)==2 and ops[1].type==ARM64_OP_REG:
                if ops[1].reg in registers:registers[ops[0].reg]=registers[ops[1].reg]
                else:registers.pop(ops[0].reg,None)
            elif ops and ops[0].type==ARM64_OP_REG and ins.mnemonic not in ('str','strb','strh','stur','stp','cmp','cmn','tst','cbz','cbnz','tbz','tbnz','ret'):
                registers.pop(ops[0].reg,None)
            if ins.mnemonic in ('bl','blr'):
                registers={reg:value for reg,value in registers.items() if cs.reg_name(reg) not in {f'x{n}' for n in range(19)}}
            if address is not None:
                try:value=image.string(address,128)
                except (ValueError,UnicodeError):continue
                if value in fields:refs.append({'instruction':ins.address,'literal_address':address,'field':value})
        detailed.append({'role':span['role'],'bytes':size,'sha256':span['sha256'],'allowlisted_literal_references':refs})
        public.append({'role':span['role'],'bytes':size,'sha256':span['sha256'],'allowlisted_fields':sorted({r['field'] for r in refs})})
    args.private_output.parent.mkdir(parents=True,exist_ok=True)
    args.private_output.write_text(json.dumps({'source_sha256':PREPARED_SHA,'reader_annotations':detailed},indent=2)+'\n')
    args.report.write_text(json.dumps({'kind':'pinned-player-reader-literal-annotations','source_sha256':PREPARED_SHA,'readers':public,'reader_field_ownership_verified':False,'http_route_admitted':False,'native_runtime_execution_verified':False,'limits':['Exact previously retained reader spans only; no new whole-image xref scan.','Literal references alone do not prove field ownership, type, requiredness, HTTP route or response root.','No scalar player data, source keys or unknown strings emitted.']},indent=2)+'\n')
    print('Pinned player reader literal annotations saved; no route or payload admitted.')

if __name__=='__main__':main()
