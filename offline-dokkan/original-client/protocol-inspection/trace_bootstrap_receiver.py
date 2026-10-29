#!/usr/bin/env python3
"""Narrow the saved bootstrap-dispatch frontier to request callback holders.

Uses the retained prior dispatch report rather than repeating its whole-image
slot scan. Private output may contain source coordinates; printed/public output
contains only exact body identities and derived structural observations.
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct
import subprocess
import sys

from trace_bootstrap_envelope import Image, function_starts, sections_and_symbols, PREPARED_SHA, FIELDS


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--source', type=Path, required=True)
    ap.add_argument('--capstone-runtime', type=Path, required=True)
    ap.add_argument('--dispatch-report', type=Path, required=True)
    ap.add_argument('--accessor-report', type=Path,
        help='Continue only saved setter accessors; skip constructor recovery.')
    ap.add_argument('--focus-body-sha',action='append',default=[],
        help='Inspect only a saved body/direct-callee identity from dispatch evidence.')
    ap.add_argument('--focus-helper-depth',type=int,default=1)
    ap.add_argument('--classify-callable-types',action='store_true',
        help='Classify only the retained two callback RTTI records; no code rescan.')
    ap.add_argument('--private-output', type=Path, required=True)
    ap.add_argument('--report', type=Path, required=True)
    args = ap.parse_args()
    if 'private' not in args.private_output.parts:
        raise ValueError('Detailed output must remain private')
    raw = args.source.read_bytes()
    if len(raw)>512*1024*1024 or hashlib.sha256(raw).hexdigest()!=PREPARED_SHA:
        raise ValueError('Prepared source identity rejected')
    old=json.loads(args.dispatch_report.read_text())
    sys.path.insert(0,str(args.capstone_runtime.resolve()))
    from capstone import Cs,CS_ARCH_ARM64,CS_MODE_ARM
    from capstone.arm64 import ARM64_OP_REG,ARM64_OP_IMM,ARM64_OP_MEM
    image=Image(raw)
    starts=function_starts(image)
    sections,symbols,dynamic=sections_and_symbols(image)
    if args.classify_callable_types:
        private_types=[];facts=[]
        for point in old['address_points']:
            type_info=image.pointer(point['address_point']-8)
            name=image.string(image.pointer(type_info+8),16384)
            decoded=subprocess.run(['c++filt','-t',name],capture_output=True,text=True,timeout=10)
            if decoded.returncode or not decoded.stdout or len(decoded.stdout)>32768:
                raise ValueError('Bounded RTTI decoding failed')
            demangled=decoded.stdout.strip();prefix='std::__1::__function::__func<'
            parameters=[]
            if demangled.startswith(prefix) and demangled.endswith('>'):
                inner=demangled[len(prefix):-1];begin=0;angle=paren=0
                for i,char in enumerate(inner):
                    if char=='<':angle+=1
                    elif char=='>':angle-=1
                    elif char=='(':paren+=1
                    elif char==')':paren-=1
                    elif char==',' and angle==0 and paren==0:
                        parameters.append(inner[begin:i].strip());begin=i+1
                parameters.append(inner[begin:].strip())
            signature=parameters[-1] if len(parameters)==3 else ''
            private_types.append({'role':point['role'],'private_type_info':type_info,
                'private_mangled_name':name,'private_demangled_name':demangled,'private_signature':signature})
            facts.append({'role':point['role'],'callback':identity(point['callback']),
                'libcxx_function_wrapper_rtti':bool(signature),
                'signature_returns_void':signature.startswith('void ('),
                'signature_contains_cocos_http_response':'cocos2d::network::HttpResponse' in signature,
                'signature_contains_nlohmann_json':'nlohmann::' in signature and 'basic_json<' in signature,
                'signature_contains_jsoncpp_value':'Json::Value' in signature,
                'virtual_slot':point['slot']})
        args.private_output.parent.mkdir(parents=True,exist_ok=True)
        args.private_output.write_text(json.dumps({'types':private_types},indent=2)+'\n')
        report={'kind':'retained-bootstrap-callable-rtti','prepared_source_sha256':PREPARED_SHA,'facts':facts,
            'wire_body_envelope_verified':False,'runtime_execution_verified':False,'route_enablement_claimed':False,
            'limits':['RTTI describes the selected compiled callback type, not the HTTP JSON envelope.',
                'Unknown names and source coordinates stay private.']}
        args.report.write_text(json.dumps(report,indent=2)+'\n')
        print(json.dumps({'callback_types':len(facts),'libcxx_wrappers':sum(x['libcxx_function_wrapper_rtti'] for x in facts),'wire_envelope_verified':False}))
        return
    text,size,_,_=sections[b'__text']
    spans={s:e for s,e in zip(starts,starts[1:]+[text+size]) if text<=s<e<=text+size}
    def identity(start):
        if start not in spans:return None
        length=spans[start]-start;off=image.offset(start,length)
        return {'bytes':length,'sha256':hashlib.sha256(raw[off:off+length]).hexdigest()}
    contract=json.loads((Path(__file__).resolve().parents[2]/'research/bootstrap-auth-contract.json').read_text())
    pins={x['role']:x for x in contract['reviewed_bodies'] if x['role'] in ('common_request_constructor','auth_request_constructor','nonce_request_constructor')}
    previous_receiver=json.loads(args.accessor_report.read_text()) if args.accessor_report else None
    recovered={}
    if args.focus_body_sha:
        selected=set()
        for wanted in args.focus_body_sha:
            found=set(int(s) for s,item in old['summaries'].items() if item['sha256']==wanted)
            for item in old['summaries'].values():
                for call in item['calls']:
                    if isinstance(call['target'],dict) and call['target']['sha256']==wanted:
                        pc=call['private_pc'];word=image.at('I',pc)[0]
                        if word&0x7c000000!=0x14000000:continue
                        delta=word&0x3ffffff
                        if delta&0x2000000:delta-=0x4000000
                        target=pc+delta*4
                        if identity(target) and identity(target)['sha256']==wanted:found.add(target)
            if len(found)!=1:raise ValueError('Focus identity is missing or ambiguous')
            selected|=found
        previous_receiver=previous_receiver or {'request_tables':{}}
    elif previous_receiver:
        selected={fns[slot] for fns in previous_receiver['request_tables'].values() for slot in (8,10) if slot<len(fns) and fns[slot] in spans}
    else:
        selected=set(x for p in old['address_points'] for x in p['constructor_references'] if identity(x)['bytes']>100)
        for s,e in spans.items():
            for role,pin in pins.items():
                if e-s==pin['bytes'] and identity(s)['sha256']==pin['sha256']:
                    recovered[role]=s;selected.add(s)
        if len(recovered)!=3:raise ValueError('Required request constructors not recovered')
    decoder=Cs(CS_ARCH_ARM64,CS_MODE_ARM);decoder.detail=True
    def known_import(target):
        if target is None:return None
        address,length,index,stride=sections.get(b'__stubs',(0,0,0,0))
        if not stride or not address<=target<address+length or (target-address)%stride:return None
        indirect=index+(target-address)//stride
        if indirect>=dynamic[13]:return None
        symbol=image.unpack('I',dynamic[12]+indirect*4)[0]
        offset,count,strings,string_size=symbols
        if symbol>=count:return None
        at=image.unpack('I',offset+symbol*16)[0]
        if at>=string_size:return None
        name=raw[strings+at:min(strings+string_size,strings+at+96)].split(b'\0',1)[0]
        allow={b'___cxa_throw':'cxx_throw',b'___cxa_allocate_exception':'cxx_allocate_exception',
            b'___cxa_begin_catch':'cxx_begin_catch',b'___cxa_end_catch':'cxx_end_catch',
            b'_abort':'abort',b'___assert_rtn':'assertion_failure',b'___stack_chk_fail':'stack_guard_failure',
            b'_memcpy':'memory_copy',b'_memcmp':'memory_compare',b'_strlen':'string_length'}
        return allow.get(name)
    tables={}
    def table(address):
        if not isinstance(address,int):return None
        if address in tables:return address
        try:
            if image.at('q',address-16)[0]!=0:return None
            ti=image.pointer(address-8)
            # The request family may be built without RTTI or contain pure
            # virtual binds. Its previously proven inherited slots provide
            # a stronger independent identity than a guessed type name.
            materializer=identity(image.pointer(address+2*8))
            getter=identity(image.pointer(address+17*8))
            pinned_request=materializer and getter and materializer['sha256']=='829cd9c45cd0d3cae4d795b9ea842cae3e14d24310ddafb085a8c026cf6cbe37' and getter['sha256']=='a26061eb76af386891a60b091a9a312b796ec48c788d8f4d2246855d112fa845'
            if not pinned_request:
                image.offset(ti,16)
                if ti in spans:return None
            fns=[]
            for i in range(24):
                try:fn=image.pointer(address+i*8)
                except ValueError:
                    if pinned_request:fn=None
                    else:break
                if fn not in spans:
                    if pinned_request:fn=None
                    else:break
                fns.append(fn)
            if len(fns)<9:return None
            tables[address]=fns
            return address
        except ValueError:return None
    def inspect(start):
        off=image.offset(start,spans[start]-start)
        insns=list(decoder.disasm(raw[off:off+spans[start]-start],start))
        regs={f'x{i}':f'argument{i}' for i in range(9)}
        regs['sp']=0;stack_addresses={0}
        stack={};writes=[];calls=[];materialized=set()
        def rn(reg):
            name=decoder.reg_name(reg)
            if name=='fp':return 'x29'
            if name=='lr':return 'x30'
            return 'x'+name[1:] if name.startswith('w') and name[1:].isdigit() else name
        def expr(v):
            if isinstance(v,int):
                if v in stack_addresses:return f'local-stack[{v}]'
                try:
                    literal=image.string(v,64)
                    if literal in FIELDS:return 'field:'+literal
                except (ValueError,UnicodeError):pass
                cf,cf_size,_,_=sections.get(b'__cfstring',(0,0,0,0))
                if cf<=v<cf+cf_size and (v-cf)%32==0:
                    try:
                        ptr=image.pointer(v+16);length=image.at('Q',v+24)[0]
                        if 0<length<=64:
                            off=image.offset(ptr,length);literal=raw[off:off+length].decode('ascii')
                            if literal in FIELDS:return 'field:'+literal
                    except (ValueError,UnicodeError):pass
                return 'constant-or-address'
            return str(v)[:500]
        def location(base,disp):
            at=regs.get(base,'unknown')
            return ('stack',at+disp) if isinstance(at,int) and at in stack_addresses else (expr(at),disp)
        def value(op):
            if op.type==ARM64_OP_REG:return regs.get(rn(op.reg),'unknown')
            if op.type==ARM64_OP_IMM:return op.imm
            if op.type==ARM64_OP_MEM:
                base=rn(op.mem.base);v=regs.get(base,'unknown')
                key=location(base,op.mem.disp)
                if key in stack:return stack[key]
                if key[0]=='stack':return f'local-value[{key[1]}]'
                if isinstance(v,int):
                    try:return image.pointer(v+op.mem.disp)
                    except ValueError:return 'unknown-load'
                return f'load({expr(v)},{op.mem.disp})'
            return 'unknown'
        def store(op,base,disp):
            v=value(op);stack[location(base,disp)]=v
            t=table(v)
            if t:materialized.add(t)
            writes.append({'destination':expr(regs.get(base,'unknown')),'member_offset':disp,
                'value':expr(v),'private_value':v,'private_vtable':t})
        for ins in insns:
            op=ins.operands
            if ins.mnemonic in ('adr','adrp') and len(op)==2:regs[rn(op[0].reg)]=op[1].imm
            elif ins.mnemonic=='mov' and len(op)==2:regs[rn(op[0].reg)]=value(op[1])
            elif ins.mnemonic in ('add','sub') and len(op)==3:
                l,r=value(op[1]),value(op[2]);regs[rn(op[0].reg)]=l+(r if ins.mnemonic=='add' else -r) if isinstance(l,int) and isinstance(r,int) else f'{ins.mnemonic}({expr(l)},{r if isinstance(r,int) and abs(r)<1048576 else expr(r)})'
                if isinstance(l,int) and l in stack_addresses and isinstance(r,int):stack_addresses.add(regs[rn(op[0].reg)])
            elif ins.mnemonic in ('ldr','ldur') and len(op)>1:regs[rn(op[0].reg)]=value(op[1])
            elif ins.mnemonic=='ldp' and len(op)==3 and op[2].type==ARM64_OP_MEM:
                base,disp=rn(op[2].mem.base),op[2].mem.disp
                for i in (0,1):regs[rn(op[i].reg)]=stack.get(location(base,disp+i*8),f'load({expr(regs.get(base,"unknown"))},{disp+i*8})')
            elif ins.mnemonic in ('str','stur') and len(op)==2 and op[1].type==ARM64_OP_MEM:store(op[0],rn(op[1].mem.base),op[1].mem.disp)
            elif ins.mnemonic=='stp' and len(op)==3 and op[2].type==ARM64_OP_MEM:
                for i in (0,1):store(op[i],rn(op[2].mem.base),op[2].mem.disp+i*8)
            elif ins.mnemonic in ('bl','blr','br') or (ins.mnemonic=='b' and op and op[0].type==ARM64_OP_IMM and op[0].imm in spans and not start<=op[0].imm<spans[start]):
                target=op[0].imm if op[0].type==ARM64_OP_IMM else None
                calls.append({'target':identity(target) if target in spans else known_import(target) or expr(value(op[0])),
                    'arguments':{f'x{i}':expr(regs.get(f'x{i}','unknown')) for i in (0,1,2,3,8)},'private_pc':ins.address,'private_target':target})
                regs={k:v for k,v in regs.items() if k=='sp' or k.startswith('x') and k[1:].isdigit() and int(k[1:])>=19};regs['x0']=f'return{len(calls)-1}'
            elif op and op[0].type==ARM64_OP_REG and ins.mnemonic not in ('cmp','cmn','tst','cbz','cbnz','tbz','tbnz','ret','br'):regs.pop(rn(op[0].reg),None)
            if ins.writeback:
                mem=next((o for o in op if o.type==ARM64_OP_MEM),None)
                if mem is not None:
                    base=rn(mem.mem.base);before=regs.get(base)
                    delta=op[-1].imm if op[-1].type==ARM64_OP_IMM else mem.mem.disp
                    if isinstance(before,int) and before in stack_addresses:
                        regs[base]=before+delta;stack_addresses.add(before+delta)
        return {**identity(start),'writes':writes,'calls':calls,'private_materialized_vtables':sorted(materialized)}
    summaries={s:inspect(s) for s in selected}
    if previous_receiver:
        frontier=set(selected)
        depth=args.focus_helper_depth if args.focus_body_sha else 3
        if depth<0 or depth>3:raise ValueError('Invalid focus depth')
        for _ in range(depth):
            more={call['private_target'] for s in frontier for call in summaries[s]['calls'] if call['private_target'] in spans and spans[call['private_target']]-call['private_target']<=8192}
            more-=summaries.keys()
            if len(summaries)+len(more)>24:raise ValueError('Accessor helper fanout exceeded bound')
            for s in more:summaries[s]=inspect(s)
            frontier=more
    request_tables={t for s in recovered.values() for t in summaries[s]['private_materialized_vtables']}
    for t in request_tables:
        for slot in (6,8,10):
            fns=tables[t]
            if slot<len(fns) and fns[slot] in spans and spans[fns[slot]]-fns[slot]<=8192 and fns[slot] not in summaries:summaries[fns[slot]]=inspect(fns[slot])
    private={'kind':'bootstrap-callback-holder-frontier','request_constructors':recovered,'request_tables':{str(t):tables[t] for t in request_tables},'summaries':{str(s):v for s,v in summaries.items()}}
    args.private_output.parent.mkdir(parents=True,exist_ok=True);args.private_output.write_text(json.dumps(private,indent=2)+'\n')
    public={'kind':'bootstrap-callback-holder-frontier','prepared_source_sha256':PREPARED_SHA,
        'request_constructors':{r:identity(s) for r,s in recovered.items()},
        'request_vtables':[{'slot_count':len(tables[t]),'selected_slots':{str(slot):{**identity(tables[t][slot]),'writes':[{k:v for k,v in w.items() if not k.startswith('private_')} for w in summaries[tables[t][slot]]['writes']]} for slot in (6,8,10) if slot<len(tables[t]) and tables[t][slot] in summaries}} for t in request_tables],
        'accessor_followup':bool(previous_receiver),
        'accessor_summaries':[identity(s) for s in summaries] if previous_receiver else [],
        'wire_body_envelope_verified':False,'runtime_execution_verified':False,'route_enablement_claimed':False,
        'limits':['Candidate stores and dispatch slots require receiver-identity matching.','No complete HTTP-body root binding is established.','Unknown strings, addresses, code bytes and player values are omitted.']}
    args.report.write_text(json.dumps(public,indent=2)+'\n')
    print(json.dumps({'constructor_bodies':len(recovered),'request_vtables':len(request_tables),'reviewed_bodies':len(summaries),'wire_envelope_verified':False}))


if __name__=='__main__':
    try:main()
    except Exception:
        print('Bounded callback-holder analysis failed; no client values emitted.',file=sys.stderr)
        raise SystemExit(1)
