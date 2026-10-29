#!/usr/bin/env python3
"""Bounded static bootstrap caller recovery; never executes a supplied client.

Locate previously reviewed bodies by exact length/hash, then retain private
caller summaries for manual dataflow review. Public output contains identities,
counts, allowlisted protocol field names and unresolved limits, never addresses,
code bytes, unknown literal strings, credentials or account values.
"""
import argparse
import bisect
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
FIELDS = frozenset(('data', 'response', 'result', 'body', 'error', 'errors',
    'auth_transaction_id', 'nonce', 'access_token', 'expires_in', 'token',
    'auth', 'status', 'status_code', 'code', 'message'))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, required=True)
    parser.add_argument('--capstone-runtime', type=Path, required=True)
    parser.add_argument('--private-output', type=Path, required=True)
    parser.add_argument('--report', type=Path, required=True)
    args = parser.parse_args()
    if not args.source.is_file() or args.source.stat().st_size > 512 * 1024 * 1024:
        raise ValueError('Invalid source')
    raw = args.source.read_bytes()
    if hashlib.sha256(raw).hexdigest() != PREPARED_SHA:
        raise ValueError('Prepared source hash mismatch')
    if 'private' not in args.private_output.parts:
        raise ValueError('Detailed output must stay private')
    sys.path.insert(0, str(args.capstone_runtime.resolve()))
    from capstone import Cs, CS_ARCH_ARM64, CS_MODE_ARM
    from capstone.arm64 import ARM64_OP_IMM, ARM64_OP_REG, ARM64_OP_MEM
    image = Image(raw)
    starts = function_starts(image)
    sections, _, _ = sections_and_symbols(image)
    text, size, _, _ = sections[b'__text']
    ends = starts[1:] + [text + size]
    spans = {s: e for s, e in zip(starts, ends) if text <= s < e <= text + size}
    contract = json.loads((HERE.parents[1] / 'research/bootstrap-auth-contract.json').read_text())
    pinned = {(x['bytes'], x['sha256']): x['role'] for x in contract['reviewed_bodies']}
    identities, roles, matches = {}, {}, {}
    for start, end in spans.items():
        length = end - start
        if length not in {n for n, _ in pinned}:
            continue
        digest = hashlib.sha256(raw[image.offset(start, length):image.offset(start, length) + length]).hexdigest()
        if (length, digest) in pinned:
            role = pinned[(length, digest)]
            matches.setdefault(role, []).append(start)
            roles[start] = role
    if any(len(v) != 1 for v in matches.values()) or not {'nonce_reader', 'token_response_consumer'} <= matches.keys():
        raise ValueError('Pinned bootstrap recovery is ambiguous or incomplete')

    def identity(start):
        if start not in spans:
            return 'unmapped-or-import'
        if start not in identities:
            length = spans[start] - start
            offset = image.offset(start, length)
            identities[start] = {'bytes': length, 'sha256': hashlib.sha256(raw[offset:offset + length]).hexdigest()}
            if start in roles:
                identities[start]['reviewed_role'] = roles[start]
        return identities[start]['sha256']

    # Integer decoding of B/BL provides a bounded inverse index including
    # reader alias tail thunks. It
    # does not interpret literal/string pools or execute any original code.
    callers = {}
    offset = image.offset(text, size)
    for rel in range(0, size - 3, 4):
        word = struct.unpack_from('<I', raw, offset + rel)[0]
        if word & 0x7c000000 != 0x14000000:
            continue
        signed = word & 0x3ffffff
        if signed & 0x2000000:
            signed -= 0x4000000
        target = text + rel + signed * 4
        if target not in spans:
            continue
        source_index = bisect.bisect_right(starts, text + rel) - 1
        if source_index >= 0:
            source = starts[source_index]
            if source in spans and text + rel < spans[source] and source != target:
                callers.setdefault(target, set()).add(source)
    selected = {matches['nonce_reader'][0], matches['token_response_consumer'][0]}
    frontier = set(selected)
    for _ in range(3):
        more = {s for target in frontier for s in callers.get(target, ()) if spans[s] - s <= 16384}
        if len(selected | more) > 32:
            raise ValueError('Bootstrap caller fanout exceeds bound')
        frontier = more - selected
        selected |= more

    pointers = []
    for location, target in image.rebases.items():
        if target not in selected:
            continue
        neighbors = []
        for displacement in range(-5, 7):
            try:
                candidate = image.pointer(location + displacement * 8)
            except ValueError:
                continue
            if candidate in spans and spans[candidate] - candidate <= 16384:
                neighbors.append(candidate)
        pointers.append({'location': location, 'target': target, 'neighbors': list(dict.fromkeys(neighbors))})
    nearby = {p for entry in pointers for p in entry['neighbors']}
    # Hard cap preserves the requested narrow caller review.
    if len(selected | nearby) <= 64:
        selected |= nearby

    decoder = Cs(CS_ARCH_ARM64, CS_MODE_ARM)
    decoder.detail = True
    summaries = []
    for start in sorted(selected):
        end = spans[start]
        offset = image.offset(start, end - start)
        instructions = list(decoder.disasm(raw[offset:offset + end - start], start))
        targets = {i.operands[-1].imm for i in instructions if i.mnemonic.startswith(('b.', 'cb', 'tb')) and i.operands and i.operands[-1].type == ARM64_OP_IMM}
        state = {f'x{i}': f'argument{i}' for i in range(9)}
        stack = {}
        events = []
        found = set()
        def reg_name(reg):
            name = decoder.reg_name(reg)
            return 'x' + name[1:] if name.startswith('w') and name[1:].isdigit() else name
        def render(value):
            if isinstance(value, int):
                try:
                    s = image.string(value, 64)
                except (ValueError, UnicodeError):
                    return 'opaque-address'
                if s in FIELDS:
                    found.add(s)
                    return 'field:' + s
                return 'opaque-address'
            return str(value)[:250] if value is not None else 'unknown'
        def operand(op):
            if op.type == ARM64_OP_REG:
                return state.get(reg_name(op.reg), 'unknown')
            if op.type == ARM64_OP_IMM:
                return op.imm
            if op.type == ARM64_OP_MEM:
                base = reg_name(op.mem.base)
                if base == 'sp':
                    return stack.get(op.mem.disp, 'unknown-stack')
                value = state.get(base)
                if isinstance(value, int):
                    try:
                        return image.pointer(value + op.mem.disp)
                    except ValueError:
                        return 'unknown-load'
                return f'load({render(value)},{op.mem.disp})'
            return 'unknown'
        for ins in instructions:
            if ins.address in targets:
                state = {key: value for key, value in state.items() if key.startswith('x') and key[1:].isdigit() and int(key[1:]) >= 19}
            ops = ins.operands
            if ins.mnemonic in ('adrp', 'adr') and len(ops) == 2:
                state[reg_name(ops[0].reg)] = ops[1].imm
            elif ins.mnemonic == 'mov' and len(ops) == 2:
                state[reg_name(ops[0].reg)] = operand(ops[1])
            elif ins.mnemonic in ('add', 'sub') and len(ops) == 3:
                left, right = operand(ops[1]), operand(ops[2])
                value = left + right * (1 if ins.mnemonic == 'add' else -1) if isinstance(left, int) and isinstance(right, int) else f'{ins.mnemonic}({render(left)},{render(right)})'
                state[reg_name(ops[0].reg)] = value
            elif ins.mnemonic.startswith('ldr') and len(ops) >= 2 and ops[0].type == ARM64_OP_REG:
                state[reg_name(ops[0].reg)] = operand(ops[1])
            elif ins.mnemonic in ('str', 'stur') and len(ops) == 2 and ops[1].type == ARM64_OP_MEM and reg_name(ops[1].mem.base) == 'sp':
                stack[ops[1].mem.disp] = operand(ops[0])
            elif ins.mnemonic in ('bl', 'blr') or (ins.mnemonic == 'b' and ops and ops[0].type == ARM64_OP_IMM and ops[0].imm in spans and not start <= ops[0].imm < end):
                target = ops[0].imm if ops[0].type == ARM64_OP_IMM else None
                target_id = identity(target) if target is not None else render(operand(ops[0]))
                event = {'ordinal': len(events), 'target': target_id,
                    'arguments': {f'x{i}': render(state.get(f'x{i}')) for i in (0, 1, 2, 3, 8)}}
                events.append(event)
                state = {key: value for key, value in state.items() if key.startswith('x') and key[1:].isdigit() and int(key[1:]) >= 19}
                state['x0'] = f'return{len(events)-1}'
            elif ops and ops[0].type == ARM64_OP_REG and ins.mnemonic not in ('cmp', 'cmn', 'tst', 'stp', 'cbz', 'cbnz', 'tbz', 'tbnz', 'br', 'ret'):
                state.pop(reg_name(ops[0].reg), None)
        summaries.append({**identities.get(start, {'sha256': identity(start), 'bytes': end-start}),
            'direct_callers': [identity(x) for x in sorted(callers.get(start, ()))],
            'allowlisted_fields': sorted(found), 'calls': events})
    private = {'kind': 'bounded-bootstrap-caller-summaries',
        'bodies': summaries,
        'private_body_spans': [{'identity': identity(start), 'start': start, 'end': spans[start]} for start in sorted(selected)],
        'private_pointer_locations': [{'location': p['location'], 'target': p['target']} for p in pointers],
        'pointer_neighborhoods': [{'target': identity(p['target']), 'neighbors': [identity(x) for x in p['neighbors']]} for p in pointers],
        'limits': ['symbolic summaries are linear and conservative at branch joins',
            'unknown strings omitted', 'indirect dynamic receivers unresolved',
            'no runtime, wire, account or secret data examined']}
    args.private_output.parent.mkdir(parents=True, exist_ok=True)
    args.private_output.write_text(json.dumps(private, indent=2) + '\n')
    report = {'kind': 'bounded-bootstrap-envelope-recovery', 'prepared_source_sha256': PREPARED_SHA,
        'original_source_sha256': contract['source_executable_sha256'],
        'recovered_bodies': [{'role': role, **identities.get(values[0], {'sha256': identity(values[0]), 'bytes': spans[values[0]] - values[0]})} for role, values in sorted(matches.items())],
        'reviewed_caller_body_count': len(selected),
        'wire_body_envelope_verified': False, 'runtime_execution_verified': False,
        'route_enablement_claimed': False,
        'limits': private['limits']}
    args.report.write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({'recovered_roles': sorted(matches), 'caller_bodies': len(selected),
        'envelope_verified': False, 'runtime_execution': False}))


if __name__ == '__main__':
    try:
        main()
    except Exception:
        print('Bounded bootstrap analysis failed; no client values emitted.', file=sys.stderr)
        raise SystemExit(1)
