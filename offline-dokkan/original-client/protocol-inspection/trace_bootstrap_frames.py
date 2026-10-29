#!/usr/bin/env python3
"""Affine stack aliases for the two already-recovered bootstrap frontier bodies.

This is a small control-flow continuation, not another caller/vtable scan. No
original app execution, source modification, unknown strings or code output.
Stack aliases alone never establish a C++ ABI, JSON type, body root or wrapper.
"""
import argparse
import hashlib
import json
from pathlib import Path
import sys

from trace_bootstrap_envelope import Image, PREPARED_SHA

PINNED = frozenset(('a7d135a3e5f611e4fe73e1a97e0a848ad8bbe91b276b69c3c67597f7e3b6ea57',
    'e551358ed7c7b5690cabc23114060313f24420be48d62967fcc1c270f366d10a'))


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--source',type=Path,required=True)
    ap.add_argument('--capstone-runtime',type=Path,required=True)
    ap.add_argument('--private-input',type=Path,required=True)
    ap.add_argument('--report',type=Path,required=True)
    args=ap.parse_args()
    source=args.source.read_bytes()
    if len(source)>512*1024*1024 or hashlib.sha256(source).hexdigest()!=PREPARED_SHA:
        raise ValueError('Prepared identity rejected')
    sys.path.insert(0,str(args.capstone_runtime.resolve()))
    from capstone import Cs,CS_ARCH_ARM64,CS_MODE_ARM
    from capstone.arm64 import ARM64_OP_REG,ARM64_OP_IMM,ARM64_OP_MEM
    image=Image(source);prior=json.loads(args.private_input.read_text())
    decoder=Cs(CS_ARCH_ARM64,CS_MODE_ARM);decoder.detail=True
    results=[]
    for address,summary in prior['summaries'].items():
        if summary['sha256'] not in PINNED:continue
        start=int(address);length=summary['bytes'];off=image.offset(start,length)
        if hashlib.sha256(source[off:off+length]).hexdigest()!=summary['sha256']:
            raise ValueError('Body identity rejected')
        insns=list(decoder.disasm(source[off:off+length],start));by_pc={i.address:i for i in insns}
        call_ord={c['private_pc']:i for i,c in enumerate(summary['calls'])}
        def rn(register):
            name=decoder.reg_name(register)
            if name=='fp':return 29
            if name=='lr':return 30
            if name in ('sp','wsp'):return 31
            if name.startswith(('x','w')) and name[1:].isdigit():return int(name[1:])
            return None
        states={start:tuple([None]*31+[0])};queue=[start];steps=0
        while queue:
            pc=queue.pop();old=list(states[pc]);state=old.copy();ins=by_pc[pc];ops=ins.operands;steps+=1
            if steps>=100000:raise ValueError('Control-flow bound exceeded')
            def write(register,value):
                index=rn(register)
                if index is not None:state[index]=value
            def read(register):
                index=rn(register)
                return old[index] if index is not None else None
            if ins.mnemonic=='mov' and len(ops)==2:
                write(ops[0].reg,read(ops[1].reg) if ops[1].type==ARM64_OP_REG else None)
            elif ins.mnemonic in ('add','sub') and len(ops)==3 and ops[1].type==ARM64_OP_REG and ops[2].type==ARM64_OP_IMM:
                value=read(ops[1].reg);write(ops[0].reg,None if value is None else value+(ops[2].imm if ins.mnemonic=='add' else -ops[2].imm))
            elif ins.mnemonic in ('bl','blr'):
                for register in range(19):state[register]=None
            elif ins.mnemonic=='ldp' and len(ops)>=3:
                write(ops[0].reg,None);write(ops[1].reg,None)
            elif ops and ops[0].type==ARM64_OP_REG and ins.mnemonic not in ('cmp','cmn','tst','cbz','cbnz','tbz','tbnz','ret','br','str','stur','stp'):
                write(ops[0].reg,None)
            if ins.writeback:
                memory=next((operand for operand in ops if operand.type==ARM64_OP_MEM),None)
                if memory is not None:
                    base=rn(memory.mem.base);delta=ops[-1].imm if ops[-1].type==ARM64_OP_IMM else memory.mem.disp
                    if base is not None:state[base]=None if old[base] is None else old[base]+delta
            successors=[]
            if ins.mnemonic not in ('ret','br'):
                if ins.mnemonic=='b':successors=[ops[0].imm]
                elif ins.mnemonic.startswith('b.') or ins.mnemonic in ('cbz','cbnz','tbz','tbnz'):
                    successors=[pc+4,ops[-1].imm]
                else:successors=[pc+4]
            for successor in successors:
                if successor not in by_pc:continue
                after=tuple(state)
                if successor in states:
                    after=tuple(a if a==b else None for a,b in zip(states[successor],after))
                if states.get(successor)!=after:states[successor]=after;queue.append(successor)
        relevant={16,17,28,29,39} if length==1432 else {10,18,25}
        observations=[{'call_ordinal':ordinal,'stack_aliases':{f'x{i}':states[pc][i] for i in (0,1,2,3,8,29,31) if states[pc][i] is not None}} for pc,ordinal in call_ord.items() if pc in states and ordinal in relevant]
        results.append({'bytes':length,'sha256':summary['sha256'],'instructions':len(insns),
            'reachable_instructions':len(states),'cfg_transfer_steps':steps,'call_stack_aliases':observations})
    if len(results)!=2:raise ValueError('Pinned frontier incomplete')
    report={'kind':'focused-bootstrap-frame-control-flow','bodies':results,
        'wire_body_envelope_verified':False,'runtime_execution_verified':False,'route_enablement_claimed':False,
        'limits':['Only affine stack-pointer aliases are analyzed.',
            'Conditional branches are joined conservatively; no branch condition is guessed.',
            'This does not identify JSON types, callable receivers or member selection.']}
    args.report.write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps({'focused_bodies':len(results),'wire_envelope_verified':False,'runtime_execution':False}))


if __name__=='__main__':
    try:main()
    except Exception:
        print('Focused bootstrap frame analysis failed; no client values emitted.',file=sys.stderr)
        raise SystemExit(1)
