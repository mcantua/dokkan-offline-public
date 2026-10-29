#!/usr/bin/env python3
"""Recover exact tutorial/profile readers and emit bounded symbolic facts only.

Private addresses stay under the required ignored private output path. Unknown
strings and machine instructions are never included in the public evidence.
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parents[1] / 'tools'))
from objc_runtime_metadata import Image
from inspect_handler_fields import function_starts, sections_and_symbols

PREPARED_SHA = 'efaabfc9b3cdb0e2eeb550b6ea616f5eeb565c6584ad838b765f34539648d222'
FIELDS = frozenset(('user', 'tutorial', 'progress', 'contents_lv', 'is_finished',
    'card_capacity', 'total_card_capacity', 'support_item_capacity',
    'is_support_item_capacity_extended', 'timewarp'))
URL_LITERALS=frozenset(('/', '?', '&', '='))
ROLES = frozenset(('profile_decoder', 'lookup_with_prior_value_fallback',
                   'nullable_member_lookup', 'user_constructor'))


def analyze(args):
    raw = args.source.read_bytes()
    if hashlib.sha256(raw).hexdigest() != PREPARED_SHA:
        raise ValueError('Source pin mismatch')
    if 'private' not in args.private_output.parts:
        raise ValueError('Detailed output must remain private')
    image = Image(raw)
    starts = function_starts(image)
    sections, _, _ = sections_and_symbols(image)
    text, size, _, _ = sections[b'__text']
    ends = starts[1:] + [text + size]
    spans = {s:e for s,e in zip(starts, ends) if text <= s < e <= text+size}
    contract = json.loads((HERE.parents[1] / 'research/original-profile-initializer-contract.json').read_text())
    pins = {(x['bytes'],x['sha256']):x['role'] for x in contract['reviewed_bodies'] if x['role'] in ROLES}
    found = {}
    known = {}
    if args.frontier_from:
        prior=json.loads(args.frontier_from.read_text())
        if prior.get('source_sha256')!=PREPARED_SHA:raise ValueError('Explicit continuation identity mismatch')
        selected=[x for x in prior['body_spans'] if x.get('sha256')!='4b634d9dbf00a7af014407d8efa876cde23e4975916ff9c98aa2662d94496e3e']
        if not 1<=len(selected)<=32:raise ValueError('Explicit frontier exceeds bound')
        for i,item in enumerate(selected,1):
            start=item['start'];end=item['end']
            if spans.get(start)!=end or end-start>32768:raise ValueError('Explicit span mismatch')
            pos=image.offset(start,end-start)
            if hashlib.sha256(raw[pos:pos+end-start]).hexdigest()!=item['sha256']:raise ValueError('Explicit hash mismatch')
            role='tutorial_field_frontier_'+str(i)
            found[role]=start;known[start]=role
    elif args.loaders_from:
        prior=json.loads(args.loaders_from.read_text())
        if prior.get('source_sha256')!=PREPARED_SHA:raise ValueError('Loader continuation identity mismatch')
        selected={}
        for entry in prior['loader_targets']:
            loader=entry['loader'];known[loader['start']]='tutorial_master_loader'
            for item in entry['direct_callers']:selected[item['start']]=item
        if not 1<=len(selected)<=12:raise ValueError('Loader owner frontier exceeds bound')
        for i,item in enumerate(selected.values(),1):
            start=item['start'];end=item['end']
            if spans.get(start)!=end or end-start>16384:raise ValueError('Loader owner span mismatch')
            pos=image.offset(start,end-start)
            if hashlib.sha256(raw[pos:pos+end-start]).hexdigest()!=item['sha256']:raise ValueError('Loader owner hash mismatch')
            role='tutorial_loader_owner_'+str(i)
            found[role]=start;known[start]=role
    elif args.continue_from:
        prior=json.loads(args.continue_from.read_text())
        if prior.get('source_sha256')!=PREPARED_SHA:raise ValueError('Continuation identity mismatch')
        selected=[x for x in prior['callers'] if x['role']=='profile_decoder']
        if not 1<=len(selected)<=12:raise ValueError('Continuation frontier exceeds bound')
        for item in prior['reader_spans']:known[item['start']]=item['role']
        for i,item in enumerate(selected,1):
            start=item['start'];end=item['end']
            if spans.get(start)!=end or end-start>16384:raise ValueError('Caller span mismatch')
            pos=image.offset(start,end-start)
            digest=hashlib.sha256(raw[pos:pos+end-start]).hexdigest()
            if digest!=item['identity']:raise ValueError('Caller hash mismatch')
            role='profile_direct_caller_'+str(i)
            found[role]=start;known[start]=role
    else:
        lengths = {x[0] for x in pins}
        for start, end in spans.items():
            if end-start not in lengths:
                continue
            pos = image.offset(start,end-start)
            digest = hashlib.sha256(raw[pos:pos+end-start]).hexdigest()
            role = pins.get((end-start,digest))
            if role:
                if role in found: raise ValueError('Ambiguous reader pin')
                found[role] = start
        if set(found) != ROLES:
            raise ValueError('Missing exact reader pin')
        known = {start:role for role,start in found.items()}
    sys.path.insert(0,str(args.capstone_runtime.resolve()))
    from capstone import Cs, CS_ARCH_ARM64, CS_MODE_ARM
    from capstone.arm64 import ARM64_OP_IMM, ARM64_OP_REG, ARM64_OP_MEM
    cs = Cs(CS_ARCH_ARM64,CS_MODE_ARM);cs.detail=True
    identities = {}
    # Resolve only standard-library imports needed to understand URL assembly.
    # Never emit arbitrary symbol names or original strings.
    sys.path.insert(0,str(HERE.parent/'content'))
    from inspect_master_root import imports
    bindings=imports(image)
    def imported_role(target):
        if not isinstance(target,int):return 'unmapped-or-import'
        try:position=image.offset(target,24)
        except ValueError:return 'unmapped-or-import'
        registers={};symbol=None
        for ins in cs.disasm(raw[position:position+24],target):
            o=ins.operands
            if ins.mnemonic=='adrp' and len(o)==2:registers[cs.reg_name(o[0].reg)]=o[1].imm
            elif ins.mnemonic=='ldr' and len(o)==2 and o[1].type==ARM64_OP_MEM:
                b=registers.get(cs.reg_name(o[1].mem.base))
                if isinstance(b,int) and b+o[1].mem.disp in bindings:symbol=bindings[b+o[1].mem.disp]
            if ins.mnemonic in ('br','ret','b'):break
        if symbol in ('_strlen','_memcpy','_memmove','_memcmp'):return symbol[1:]
        if symbol and 'basic_string' in symbol and 'append' in symbol:return 'std.basic_string.append'
        if symbol and 'basic_string' in symbol and 'plI' in symbol:return 'std.basic_string.operator_plus'
        if symbol and 'put_character_sequence' in symbol:return 'std.stream.insert_character_sequence'
        if symbol and 'basic_ostream' in symbol:return 'std.basic_ostream.operation'
        if symbol and 'basic_stringbuf' in symbol:return 'std.basic_stringbuf.operation'
        return 'unmapped-or-import'
    def identity(start):
        if start not in spans:return imported_role(start)
        if start not in identities:
            length=spans[start]-start; pos=image.offset(start,length)
            identities[start]={'bytes':length,'sha256':hashlib.sha256(raw[pos:pos+length]).hexdigest()}
            if start in known:identities[start]['role']=known[start]
        return known.get(start,identities[start]['sha256'])
    def reg(value):
        s=cs.reg_name(value)
        return 'x'+s[1:] if s.startswith('w') and s[1:].isdigit() else s
    def read_string(address):
        try:s=image.string(address,128)
        except (ValueError,UnicodeError):return None
        return s if s in FIELDS else None
    summaries=[]
    private=[]
    for role in sorted(found):
        start=found[role];end=spans[start];pos=image.offset(start,end-start)
        instructions=list(cs.disasm(raw[pos:pos+end-start],start))
        state={f'x{i}':f'input{i}' for i in range(9)};stack={};events=[];fields=set()
        def val(op):
            if op.type==ARM64_OP_REG:return state.get(reg(op.reg),'unknown')
            if op.type==ARM64_OP_IMM:return op.imm
            if op.type==ARM64_OP_MEM:
                base=reg(op.mem.base);b=state.get(base,'unknown')
                if base in ('sp','fp','x29'):return stack.get((base,op.mem.disp),'unknown-stack')
                if isinstance(b,int):
                    try:return image.pointer(b+op.mem.disp)
                    except ValueError:return 'unknown-load'
                return f'load({render(b)},{op.mem.disp})'
            return 'unknown'
        def render(v):
            if isinstance(v,int):
                try:literal=image.string(v,16)
                except (ValueError,UnicodeError):literal=None
                if literal in URL_LITERALS:return 'literal:'+literal
                field=read_string(v)
                if field:fields.add(field);return 'field:'+field
                return 'opaque-address' if v>4096 else 'constant:'+str(v)
            return str(v)[:500]
        for ins in instructions:
            ops=ins.operands
            if ins.mnemonic in ('adr','adrp') and len(ops)==2:state[reg(ops[0].reg)]=ops[1].imm
            elif ins.mnemonic=='mov' and len(ops)==2:state[reg(ops[0].reg)]=val(ops[1])
            elif ins.mnemonic in ('add','sub') and len(ops)==3:
                a,b=val(ops[1]),val(ops[2]);sign=1 if ins.mnemonic=='add' else -1
                state[reg(ops[0].reg)]=a+sign*b if isinstance(a,int) and isinstance(b,int) else f'{ins.mnemonic}({render(a)},{render(b)})'
            elif ins.mnemonic.startswith('ldr') and len(ops)>=2 and ops[0].type==ARM64_OP_REG:state[reg(ops[0].reg)]=val(ops[1])
            elif ins.mnemonic in ('ldp',) and len(ops)==3 and ops[2].type==ARM64_OP_MEM:
                base=reg(ops[2].mem.base)
                for j in (0,1):
                    displacement=ops[2].mem.disp+j*8
                    if base in ('sp','fp','x29'):item=stack.get((base,displacement),'unknown-pair-load')
                    else:
                        address=state.get(base)
                        if isinstance(address,int):
                            try:item=image.pointer(address+displacement)
                            except ValueError:item='unknown-pair-load'
                        else:item=f'load({render(address)},{displacement})'
                    state[reg(ops[j].reg)]=item
            elif ins.mnemonic=='csel' and len(ops)>=3:
                state[reg(ops[0].reg)]=f'select({render(val(ops[1]))},{render(val(ops[2]))})'
            elif ins.mnemonic in ('str','strb','stur') and len(ops)==2 and ops[1].type==ARM64_OP_MEM:
                mem=ops[1].mem;base=reg(mem.base)
                if base in ('sp','fp','x29'):stack[(base,mem.disp)]=val(ops[0])
                elif base in state:
                    events.append({'event':'store','width':'byte' if ins.mnemonic=='strb' else ('32-bit' if cs.reg_name(ops[0].reg).startswith('w') else '64-bit'),
                                   'base':render(state[base]),'offset':mem.disp,'value':render(val(ops[0]))})
            elif ins.mnemonic=='stp' and len(ops)==3 and ops[2].type==ARM64_OP_MEM:
                base=reg(ops[2].mem.base)
                if base in ('sp','fp','x29'):
                    for j in (0,1):stack[(base,ops[2].mem.disp+j*8)]=val(ops[j])
            elif ins.mnemonic in ('bl','blr'):
                target=ops[0].imm if ops and ops[0].type==ARM64_OP_IMM else None
                e={'event':'call','callee':identity(target),'args':{f'x{i}':render(state.get(f'x{i}','unknown')) for i in range(9)}}
                events.append(e);state={k:v for k,v in state.items() if k[1:].isdigit() and int(k[1:])>=19}
                state['x0']='result'+str(len(events)-1)
            elif ins.mnemonic in ('b','br') and ops:
                target=ops[0].imm if ops[0].type==ARM64_OP_IMM else None
                if target in spans and target!=start:events.append({'event':'tail','callee':identity(target),'args':{f'x{i}':render(state.get(f'x{i}','unknown')) for i in range(9)}})
            elif ops and ops[0].type==ARM64_OP_REG and ins.mnemonic not in ('cmp','cmn','tst','cbz','cbnz','tbz','tbnz','ret'):
                state.pop(reg(ops[0].reg),None)
        identity(start)
        summaries.append({'role':role,**identities[start],'allowlisted_fields':sorted(fields),'events':events})
        private.append({'role':role,'start':start,'end':end})
    # Find immediate direct reader callers only, not a broad recursive caller walk.
    targets={found["profile_decoder"]} if not (args.continue_from or args.loaders_from or args.frontier_from) else set();callers={x:set() for x in targets}
    text_pos=image.offset(text,size)
    import bisect
    for rel in range(0,size-3,4) if targets else ():
        word=struct.unpack_from('<I',raw,text_pos+rel)[0]
        if word&0x7c000000!=0x14000000:continue
        delta=word&0x3ffffff
        if delta&0x2000000:delta-=0x4000000
        target=text+rel+delta*4
        if target not in targets:continue
        n=bisect.bisect_right(starts,text+rel)-1
        if n>=0 and starts[n] in spans and starts[n]!=target:callers[target].add(starts[n])
    pointers=[{'location':loc,'target':target} for loc,target in image.rebases.items() if target in targets]
    args.private_output.parent.mkdir(parents=True,exist_ok=True)
    args.private_output.write_text(json.dumps({'source_sha256':PREPARED_SHA,'reader_spans':private,'pointer_locations':pointers,'callee_spans':[{'start':key,'end':spans[key],**value} for key,value in identities.items() if key in spans],
       'callers':[{'role':known[target],'start':s,'end':spans[s],'identity':identity(s)} for target,values in callers.items() for s in sorted(values)],
       'symbolic_summaries':summaries,'limits':['Linear symbolic summaries are partial across branches.','No source strings outside allowlisted fields emitted.']},indent=2)+'\n')
    args.report.write_text(json.dumps({'kind':'actual-current-tutorial-reader-recovery','prepared_source_sha256':PREPARED_SHA,
        'original_source_sha256':contract['source_executable_sha256'],'recovered_readers':[{k:v for k,v in s.items() if k!='events'} for s in summaries],
        'direct_reader_callers':[{'role':known[t],'count':len(v),'identities':[identities[s] for s in sorted(v)]} for t,v in callers.items()],
        'reader_relative_shape_verified':False,'tutorial_start_state_verified':False,'capacity_start_values_verified':False,
        'runtime_execution_verified':False,'http_route_admitted':False,
        'limits':['Pinned reader recovery only; symbolic events are private for manual flow review.','No played-account values, credentials or source keys read.']},indent=2)+'\n')
    print('Recovered selected tutorial/profile frontier; no default policy or route admitted.')


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--source',type=Path,required=True);p.add_argument('--capstone-runtime',type=Path,required=True)
    p.add_argument('--private-output',type=Path,required=True);p.add_argument('--report',type=Path,required=True)
    mode=p.add_mutually_exclusive_group()
    mode.add_argument('--continue-from',type=Path,help='Reuse the exact private reader/caller frontier; do not rescan previous pins or callers')
    mode.add_argument('--loaders-from',type=Path,help='Inspect only an already-recovered private tutorial loader-owner frontier')
    mode.add_argument('--frontier-from',type=Path,help='Inspect only an already-recovered private tutorial field frontier')
    analyze(p.parse_args())


if __name__=='__main__':
    try:main()
    except Exception:
        raise SystemExit('Tutorial reader recovery failed; no client values emitted.')
