#!/usr/bin/env python3
"""Continue the pinned bootstrap trace at its indirect-dispatch boundary.

Original instructions/addresses are retained only in an ignored private report.
Public evidence is restricted to body hashes, structural slot observations,
allowlisted field names, counts and explicit unresolved limits. This tool never
executes, patches, recompiles or contacts the original application or service.
"""
import argparse
import bisect
import hashlib
import json
from pathlib import Path
import struct
import sys

from trace_bootstrap_envelope import Image, function_starts, sections_and_symbols, PREPARED_SHA, FIELDS

CALLBACKS = {
    'nonce_callback': (200, '34cf3d5c78c7bae97efb781db82c8b72f67b04bddd16d8d62865771a440aaac2'),
    'token_callback': (396, '9be612c7e314e64f136a9999e82ffae68fa9de644525650733aa997d6b4821a4'),
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, required=True)
    parser.add_argument('--capstone-runtime', type=Path, required=True)
    parser.add_argument('--prior-private-report', type=Path, required=True)
    parser.add_argument('--private-output', type=Path, required=True)
    parser.add_argument('--report', type=Path, required=True)
    args = parser.parse_args()
    if 'private' not in args.private_output.parts:
        raise ValueError('Detailed output must remain private')
    if not args.source.is_file() or args.source.stat().st_size > 512 * 1024 * 1024:
        raise ValueError('Source size rejected')
    raw = args.source.read_bytes()
    if hashlib.sha256(raw).hexdigest() != PREPARED_SHA:
        raise ValueError('Prepared source identity rejected')
    sys.path.insert(0, str(args.capstone_runtime.resolve()))
    from capstone import Cs, CS_ARCH_ARM64, CS_MODE_ARM
    from capstone.arm64 import ARM64_OP_REG, ARM64_OP_IMM, ARM64_OP_MEM
    image = Image(raw)
    starts = function_starts(image)
    sections, _, _ = sections_and_symbols(image)
    text, text_size, _, _ = sections[b'__text']
    spans = {s: e for s, e in zip(starts, starts[1:] + [text + text_size]) if text <= s < e <= text + text_size}
    identities = {}
    def body(start):
        if start not in spans:
            return None
        if start not in identities:
            length = spans[start] - start
            off = image.offset(start, length)
            identities[start] = {'bytes': length, 'sha256': hashlib.sha256(raw[off:off+length]).hexdigest()}
        return identities[start]
    def containing(pc):
        i = bisect.bisect_right(starts, pc) - 1
        return starts[i] if i >= 0 and starts[i] in spans and pc < spans[starts[i]] else None
    prior = json.loads(args.prior_private_report.read_text())
    recovered = {}
    # Reuse retained exact spans when present. Older summaries lack them, so
    # recover only the two newly targeted callback bodies, not the old cohort.
    for item in prior.get('private_body_spans', []):
        for role, (_, digest) in CALLBACKS.items():
            if item['identity'] == digest and body(item['start'])['sha256'] == digest:
                recovered[role] = item['start']
    if len(recovered) != 2:
        for start, end in spans.items():
            for role, (length, digest) in CALLBACKS.items():
                if role not in recovered and end-start == length and body(start)['sha256'] == digest:
                    recovered[role] = start
    if len(recovered) != 2:
        raise ValueError('Callback recovery incomplete')
    address_points = []
    for role, target in recovered.items():
        for location, value in image.rebases.items():
            if value != target:
                continue
            first = location
            for _ in range(32):
                try:
                    previous = image.pointer(first-8)
                except ValueError:
                    break
                if previous not in spans:
                    break
                first -= 8
            try:
                offset_top = image.at('q', first-16)[0]
                type_info = image.pointer(first-8)
                image.offset(type_info, 16)
                header = -1024*1024 <= offset_top <= 0 and offset_top % 8 == 0 and type_info not in spans
            except ValueError:
                header = False
            if not header:
                continue
            functions = []
            for i in range(40):
                try:
                    fn = image.pointer(first + i*8)
                except ValueError:
                    break
                if fn not in spans:
                    break
                functions.append(fn)
            address_points.append({'role': role, 'callback': target, 'address_point': first,
                'slot': (location-first)//8, 'offset_to_top': offset_top, 'functions': functions,
                'constructor_references': [], 'rebased_references': [p for p, v in image.rebases.items() if v == first]})
    if len(address_points) != 2:
        raise ValueError('Unique structural callback address points not established')
    slots = {p['slot']*8 for p in address_points}
    code_offset = image.offset(text, text_size)
    code = memoryview(raw)[code_offset:code_offset+text_size]
    words = struct.unpack('<' + 'I'*(len(code)//4), code)
    indirect_sites = {}
    for index, word in enumerate(words):
        pc = text + index*4
        # Constructors normally materialize the exact C++ address point using
        # ADRP+ADD. Record references first; assignment is reviewed separately.
        if word & 0x9f000000 == 0x90000000:
            immediate = ((word>>5)&0x7ffff)*4 + ((word>>29)&3)
            if immediate & 0x100000:
                immediate -= 0x200000
            page, register = (pc & ~4095) + immediate*4096, word & 31
            for next_word in words[index+1:index+7]:
                if next_word & 0xff000000 != 0x91000000 or (next_word>>5)&31 != register:
                    continue
                address = page + (((next_word>>10)&0xfff) << (12 if next_word & (1<<22) else 0))
                for point in address_points:
                    if address == point['address_point']:
                        fn = containing(pc)
                        if fn and spans[fn]-fn <= 32768:
                            point['constructor_references'].append(fn)
        if word & 0xfffffc1f != 0xd63f0000:
            continue
        register = (word>>5)&31
        for previous in words[max(0,index-4):index]:
            if previous & 0xffc00000 == 0xf9400000 and previous&31 == register:
                displacement = ((previous>>10)&0xfff)*8
                if displacement in slots:
                    fn = containing(pc)
                    if fn and spans[fn]-fn <= 32768:
                        indirect_sites.setdefault(fn, []).append((pc, displacement))
    if len(indirect_sites) > 3000:
        raise ValueError('Virtual-dispatch frontier exceeded bound')
    decoder = Cs(CS_ARCH_ARM64, CS_MODE_ARM)
    decoder.detail = True
    def inspect(start):
        off, length = image.offset(start, spans[start]-start), spans[start]-start
        instructions = list(decoder.disasm(raw[off:off+length], start))
        regs = {f'x{i}': ('argument', i) for i in range(9)}
        slots_state = {}
        calls, fields, assignments = [], set(), []
        def rn(register):
            name = decoder.reg_name(register)
            return 'x'+name[1:] if name.startswith('w') and name[1:].isdigit() else name
        def visible(value):
            if isinstance(value, int):
                try:
                    text_value = image.string(value, 64)
                    if text_value in FIELDS:
                        fields.add(text_value)
                        return 'field:'+text_value
                except (ValueError, UnicodeError):
                    pass
                return 'opaque-address-or-integer'
            if isinstance(value, tuple):
                return '('+','.join(visible(v) if isinstance(v, tuple) else str(v) for v in value)+')'
            return str(value)[:250]
        def val(operand):
            if operand.type == ARM64_OP_REG:
                return regs.get(rn(operand.reg), 'unknown')
            if operand.type == ARM64_OP_IMM:
                return operand.imm
            if operand.type == ARM64_OP_MEM:
                base = rn(operand.mem.base)
                if base in ('sp', 'fp', 'x29'):
                    return slots_state.get((base, operand.mem.disp), ('stack', base, operand.mem.disp))
                value = regs.get(base, 'unknown')
                if isinstance(value, int):
                    try:
                        return image.pointer(value + operand.mem.disp)
                    except ValueError:
                        return 'unknown-load'
                return ('load', value, operand.mem.disp)
            return 'unknown'
        for ins in instructions:
            ops = ins.operands
            if ins.mnemonic in ('adrp', 'adr') and len(ops) == 2:
                regs[rn(ops[0].reg)] = ops[1].imm
            elif ins.mnemonic == 'mov' and len(ops) == 2:
                regs[rn(ops[0].reg)] = val(ops[1])
            elif ins.mnemonic in ('add', 'sub') and len(ops) == 3:
                left, right = val(ops[1]), val(ops[2])
                regs[rn(ops[0].reg)] = left+(right if ins.mnemonic=='add' else -right) if isinstance(left,int) and isinstance(right,int) else (ins.mnemonic, left, right)
            elif ins.mnemonic.startswith(('ldr', 'ldur')) and len(ops)>1 and ops[0].type == ARM64_OP_REG:
                regs[rn(ops[0].reg)] = val(ops[1])
            elif ins.mnemonic in ('ldp',) and len(ops)==3 and ops[2].type==ARM64_OP_MEM:
                base, disp = rn(ops[2].mem.base), ops[2].mem.disp
                for j in (0,1):
                    regs[rn(ops[j].reg)] = slots_state.get((base, disp+j*8), ('load', regs.get(base, 'unknown'),disp+j*8))
            elif ins.mnemonic in ('str','stur') and len(ops)==2 and ops[1].type==ARM64_OP_MEM:
                base, disp, value = rn(ops[1].mem.base), ops[1].mem.disp, val(ops[0])
                slots_state[(base,disp)] = value
                for point in address_points:
                    if value == point['address_point']:
                        assignments.append({'role':point['role'],'destination':visible(regs.get(base,'unknown')),'member_offset':disp})
            elif ins.mnemonic in ('stp',) and len(ops)==3 and ops[2].type==ARM64_OP_MEM:
                for j in (0,1):
                    slots_state[(rn(ops[2].mem.base), ops[2].mem.disp+j*8)] = val(ops[j])
            elif ins.mnemonic in ('bl','blr'):
                target = ops[0].imm if ops[0].type==ARM64_OP_IMM else None
                target_body = body(target) if target in spans else None
                call = {'ordinal':len(calls),'target':target_body or visible(val(ops[0])),
                    'arguments':{f'x{i}':visible(regs.get(f'x{i}','unknown')) for i in (0,1,2,3,8)},
                    'indirect':ins.mnemonic=='blr','private_pc':ins.address}
                calls.append(call)
                regs={k:v for k,v in regs.items() if k.startswith('x') and k[1:].isdigit() and int(k[1:])>=19}
                regs['x0']=('return',len(calls)-1)
            elif ops and ops[0].type==ARM64_OP_REG and ins.mnemonic not in ('cmp','cmn','tst','cbz','cbnz','tbz','tbnz','ret','br'):
                regs.pop(rn(ops[0].reg),None)
        return {**body(start),'fields':sorted(fields),'calls':calls,'address_point_assignments':assignments}
    constructors={fn for point in address_points for fn in point['constructor_references']}
    # Parsing may be in a direct helper, so retain summaries for immediate
    # helper callees of the small candidate set with allowlisted JSON fields.
    summaries={start:inspect(start) for start in set(indirect_sites)|constructors}
    interesting={start for start,s in summaries.items() if s['fields'] or start in constructors}
    for start in list(interesting):
        for call in summaries[start]['calls']:
            if isinstance(call['target'],dict) and call['target']['bytes']<=32768:
                # Identity-to-start lookup is bounded to the parent function's
                # actual direct call, not a general whole-image helper survey.
                off=image.offset(call['private_pc'],4)
                word=struct.unpack_from('<I',raw,off)[0]
                signed=word&0x3ffffff
                if signed&0x2000000:
                    signed-=0x4000000
                target=call['private_pc']+signed*4
                if target in spans and target not in summaries and len(summaries)<3500:
                    summaries[target]=inspect(target)
    private={'kind':'bounded-bootstrap-virtual-dispatch-frontier',
        'address_points':address_points,
        'candidate_sites':{str(start):sites for start,sites in indirect_sites.items()},
        'summaries':{str(start):summary for start,summary in summaries.items()},
        'private_body_spans':[{'identity':body(start),'start':start,'end':spans[start]} for start in summaries]}
    args.private_output.parent.mkdir(parents=True,exist_ok=True)
    args.private_output.write_text(json.dumps(private,indent=2)+'\n')
    public={'kind':'bounded-bootstrap-dispatch-frontier',
        'prepared_source_sha256':PREPARED_SHA,
        'callback_address_points':[{'role':point['role'],'callback':body(point['callback']),
            'virtual_slot':point['slot'],'offset_to_top':point['offset_to_top'],
            'consecutive_function_slots':len(point['functions']),
            'constructor_reference_bodies':[body(fn) for fn in sorted(set(point['constructor_references']))],
            'rebased_address_point_reference_count':len(point['rebased_references'])} for point in address_points],
        'candidate_dispatcher_body_count':len(indirect_sites),
        'candidate_bodies_with_allowlisted_fields':[{**body(start),'fields':summary['fields']} for start,summary in summaries.items() if summary['fields']],
        'wire_body_envelope_verified':False,'runtime_execution_verified':False,'route_enablement_claimed':False,
        'limits':['Same virtual-slot offset is not proof of callback receiver identity.',
            'Linear symbolic summaries do not prove all conditional paths.',
            'Unknown strings, addresses, code bytes and player values are omitted.']}
    args.report.write_text(json.dumps(public,indent=2)+'\n')
    print(json.dumps({'address_points':[(p['role'],p['slot']) for p in address_points],
        'candidate_dispatcher_bodies':len(indirect_sites),
        'bodies_with_allowlisted_fields':sum(bool(s['fields']) for s in summaries.values()),
        'wire_envelope_verified':False}))


if __name__=='__main__':
    try:
        main()
    except Exception:
        print('Bounded bootstrap dispatch analysis failed; no client values emitted.',file=sys.stderr)
        raise SystemExit(1)
