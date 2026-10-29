#!/usr/bin/env python3
"""Bounded original-client existence-probe evidence; never executes the game.

Only reviewed call/selector names and body hashes are emitted. Detailed spans
and instruction text stay in ignored private/research-assets. No source values,
keys, account data, guessed hook locations or fabricated existence results.
"""
import argparse
import bisect
import hashlib
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[3]
sys.path[:0] = [str(ROOT / 'downloads/capstone/runtime'),
                str(ROOT / 'offline-dokkan/tools')]
from capstone import Cs, CS_ARCH_ARM64, CS_MODE_LITTLE_ENDIAN
from objc_runtime_metadata import Image
from inspect_master_root import SOURCE_HASH, SOURCE_BYTES, BODY_HASHES, imports, stub, function_starts

PROBE_SLOT = 488
PROBE_SHA = 'c42ea134c3e1e6e7d6e0a01caa727ddbf9ae8c615538af8b3b995d57cdfe10c9'
SELECTORS = frozenset(('fileExistsAtPath:', 'stringWithUTF8String:',
                       'fileExistsAtPath:isDirectory:', 'defaultManager'))
FILE_IMPORTS = frozenset(('_stat', '_stat$INODE64', '_lstat', '_lstat$INODE64',
                          '_access', '_open', '_fopen', '_fstat', '_fstat$INODE64'))


def import_selector(image, decoder, bindings, target):
    symbol, _ = stub(image, decoder, bindings, target)
    registers, selector = {}, None
    try:
        at = image.offset(target, 32)
        instructions = decoder.disasm(image.data[at:at + 32], target)
        for instruction in instructions:
            ops = instruction.operands
            if instruction.mnemonic == 'adrp' and len(ops) == 2:
                registers[decoder.reg_name(ops[0].reg)] = ops[1].imm
            elif instruction.mnemonic == 'ldr' and len(ops) == 2 and ops[1].type == 3:
                base = registers.get(decoder.reg_name(ops[1].mem.base))
                if base is not None and decoder.reg_name(ops[0].reg) == 'x1':
                    try:
                        candidate = image.string(image.pointer(base + ops[1].mem.disp))
                        if candidate in SELECTORS:
                            selector = candidate
                    except (ValueError, UnicodeError):
                        pass
            if instruction.mnemonic in {'br', 'b', 'ret'}:
                break
    except ValueError:
        pass
    return symbol, selector


def inspect(source):
    raw = source.read_bytes()
    if len(raw) != SOURCE_BYTES or hashlib.sha256(raw).hexdigest() != SOURCE_HASH:
        raise ValueError('Prepared source identity changed')
    image = Image(raw)
    starts = function_starts(image)
    spans = dict(zip(starts, starts[1:]))
    recovered = {}
    for address, end in spans.items():
        length = end - address
        if length > 16384:
            continue
        body = raw[image.offset(address, length):image.offset(address, length) + length]
        digest = hashlib.sha256(body).hexdigest()
        if digest in {PROBE_SHA, BODY_HASHES['full_path_resolver']}:
            if digest in recovered:
                raise ValueError('Ambiguous reviewed body')
            recovered[digest] = (address, body)
    if len(recovered) != 2:
        raise ValueError('Missing reviewed resource body')
    probe, body = recovered[PROBE_SHA]
    resolver, resolver_body = recovered[BODY_HASHES['full_path_resolver']]
    tables = [at - PROBE_SLOT for at, target in image.rebases.items()
              if target == probe and image.pointer(at - PROBE_SLOT + 72) == resolver]
    if len(tables) != 1:
        raise ValueError('Ambiguous resource vtable relationship')
    decoder = Cs(CS_ARCH_ARM64, CS_MODE_LITTLE_ENDIAN)
    decoder.detail = True
    bindings = imports(image)
    calls, direct_file_calls = [], []
    for instruction in decoder.disasm(body, probe):
        if instruction.mnemonic not in {'bl', 'b'}:
            continue
        symbol, selector = import_selector(image, decoder, bindings, instruction.operands[0].imm)
        if symbol in FILE_IMPORTS:
            direct_file_calls.append(symbol)
        if symbol == '_objc_msgSend' and selector:
            calls.append(selector)
    if 'fileExistsAtPath:' not in calls or 'stringWithUTF8String:' not in calls:
        raise ValueError('Reviewed Foundation existence calls changed')
    loads_probe_slot = any(
        i.mnemonic == 'ldr' and len(i.operands) == 2 and i.operands[1].type == 3
        and i.operands[1].mem.disp == PROBE_SLOT
        for i in decoder.disasm(resolver_body, resolver))
    if not loads_probe_slot:
        raise ValueError('Resolver no longer loads the reviewed slot')
    private = ROOT / 'offline-dokkan/private/research-assets'
    private.mkdir(exist_ok=True)
    (private / 'foundation-existence-probe.asm').write_text('\n'.join(
        f'{i.address:x} {i.mnemonic} {i.op_str}'
        for i in decoder.disasm(body, probe)) + '\n')
    (private / 'foundation-probe-index.json').write_text(json.dumps({
        'probe_address': probe, 'probe_bytes': len(body), 'resource_vtable': tables[0],
        'resolver_address': resolver,
    }, indent=2) + '\n')
    return {
        'schema': 'original-resource-existence-static-v1',
        'prepared_engine_sha256': SOURCE_HASH,
        'reviewed_bodies': [
            {'role': 'resource_full_path_resolver', 'sha256': BODY_HASHES['full_path_resolver'],
             'bytes': len(resolver_body)},
            {'role': 'foundation_existence_probe', 'sha256': PROBE_SHA, 'bytes': len(body)},
        ],
        'same_resource_vtable_probe_slot_bytes': PROBE_SLOT,
        'full_path_resolver_loads_probe_slot': loads_probe_slot,
        'probe_direct_selectors': calls,
        'probe_direct_libc_file_calls': direct_file_calls,
        'conclusion': 'The native resolver has a Foundation fileExistsAtPath: probe; fopen-only resource virtualization is not established as sufficient.',
        'limits': {
            'original_executed': False, 'complete_probe_control_flow_verified': False,
            'all_stat_access_open_paths_traced': False, 'runtime_root_observed': False,
            'existence_results_fabricated': False, 'hook_installed': False,
            'source_modified': False, 'keys_or_player_values_read_or_emitted': False,
            'public_addresses_or_code_emitted': False,
        },
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    if args.source.resolve() == args.output.resolve():
        raise SystemExit('Receipt cannot replace the original input')
    try:
        result = inspect(args.source)
        args.output.write_text(json.dumps(result, indent=2) + '\n')
    except (ValueError, OSError, UnicodeError):
        raise SystemExit('Bounded probe inspection stopped; no arbitrary source data emitted')
    print('Reviewed Foundation existence-probe receipt written; no original client execution.')


if __name__ == '__main__':
    main()
