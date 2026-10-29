#!/usr/bin/env python3
"""Conservative allowlisted field/message references in selected original handlers.

These references are partial static observations, never a complete wire schema.
No code bytes, addresses, literal values or unknown strings are emitted.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

TOOLS = Path(__file__).resolve().parents[2] / 'tools'
sys.path.insert(0, str(TOOLS))
from objc_runtime_metadata import Image
from collect_protocol_evidence import PROTOCOL_FIELDS, STATIC_PATHS

METHODS = frozenset(('handleResponseForParsedRequest:originalData:statusCode:error:',
    'handleMyDataWithOriginal:parsedRequest:', 'handleQuestStartWithOriginal:parsedRequest:',
    'handleQuestsBriefingWithOriginal:parsedRequest:', 'handleEventsWithOriginal:parsedRequest:'))
FIELDS = PROTOCOL_FIELDS | frozenset(('method', 'path', 'body', 'headers', 'request',
    'response', 'status_code', 'data', 'error', 'code', 'area_id', 'quest_id', 'stage_id',
    'leader'))
MESSAGES = frozenset(('objectForKey:', 'objectForKeyedSubscript:', 'setObject:forKey:',
    'setObject:forKeyedSubscript:', 'setValue:forKey:', 'mutableCopy', 'copy',
    'JSONObjectWithData:options:error:', 'dataWithJSONObject:options:error:',
    'numberWithInt:', 'numberWithInteger:', 'numberWithBool:', 'array', 'dictionary',
    'count', 'containsString:', 'hasPrefix:', 'isEqualToString:', 'isKindOfClass:',
    'URL', 'path', 'absoluteString', 'HTTPMethod', 'HTTPBody', 'allHTTPHeaderFields',
    'handleMyDataWithOriginal:parsedRequest:', 'handleQuestStartWithOriginal:parsedRequest:',
    'handleQuestsBriefingWithOriginal:parsedRequest:', 'handleEventsWithOriginal:parsedRequest:'))


def sections_and_symbols(image):
    pos, sections, symbols, dynamic = 32, {}, None, None
    for _ in range(image.unpack('I', 16)[0]):
        cmd, length = image.unpack('II', pos)
        if cmd == 2:
            symbols = image.unpack('4I', pos + 8)
        elif cmd == 0xb:
            dynamic = image.unpack('18I', pos + 8)
        elif cmd == 0x19:
            for i in range(image.unpack('I', pos + 64)[0]):
                p = pos + 72 + i * 80
                name = image.data[p:p + 16].split(b'\0', 1)[0]
                address, size = image.unpack('QQ', p + 32)
                sections[name] = (address, size, *image.unpack('II', p + 68))
        pos += length
    if not symbols or not dynamic:
        raise ValueError('No verified indirect symbol tables')
    return sections, symbols, dynamic


def function_starts(image):
    pos, region = 32, None
    for _ in range(image.unpack('I', 16)[0]):
        cmd, length = image.unpack('II', pos)
        if cmd == 0x26:
            region = image.unpack('II', pos + 8)
        pos += length
    if region is None:
        raise ValueError('Missing function starts')
    offset, size = region
    if offset + size > len(image.data) or size > 8 * 1024 * 1024:
        raise ValueError('Invalid function starts')
    end, address, result = offset + size, image.base, []
    while offset < end:
        delta, shift = 0, 0
        while True:
            if offset >= end or shift >= 64:
                raise ValueError('Malformed function delta')
            byte = image.data[offset]; offset += 1
            delta |= (byte & 127) << shift
            if not byte & 128:
                break
            shift += 7
        if not delta:
            break
        address += delta
        if len(result) >= 1000000:
            raise ValueError('Too many function starts')
        result.append(address)
    return result


def selected_handlers(image):
    functions, results = function_starts(image), {}
    base, size = image.sections.get(b'__objc_classlist', (0, 0))
    for i in range(size // 8):
        cl = image.pointer(base + 8 * i)
        ro = image.class_ro(cl)
        if image.string(image.pointer(ro + 24)) != 'LocalResponseHandler':
            continue
        ro = image.class_ro(image.pointer(cl))
        methods = image.pointer(ro + 32)
        flags, count = image.at('II', methods)
        stride = flags & 0xfffc
        if stride != (12 if flags & 0x80000000 else 24) or count > 65536:
            raise ValueError('Invalid selected method list')
        for j in range(count):
            p = methods + 8 + j * stride
            if flags & 0x80000000:
                sel, _, imp = image.at('iii', p)
                sel = p + sel if flags & 0x40000000 else image.pointer(p + sel)
                imp += p + 8
            else:
                sel, imp = image.pointer(p), image.pointer(p + 16)
            name = image.string(sel)
            if name not in METHODS:
                continue
            end = next((x for x in functions if x > imp), None)
            if end is None or end - imp > 16384:
                raise ValueError('Unbounded selected handler')
            results[name] = (imp, end)
    return results


class References:
    def __init__(self, image):
        self.image = image
        self.sections, self.symbols, self.dynamic = sections_and_symbols(image)
        self.starts = function_starts(image)
        self.start_set = frozenset(self.starts)
        self.direct_helpers = {}

    def tag(self, address):
        im = self.image
        for section, label, allowlist in ((b'__objc_selrefs', 'selector', MESSAGES),):
            start, size, _, _ = self.sections.get(section, (0, 0, 0, 0))
            if start <= address < start + size and (address - start) % 8 == 0:
                name = im.string(im.pointer(address))
                return (label, name) if name in allowlist else ('unknown', None)
        start, size, _, _ = self.sections.get(b'__cfstring', (0, 0, 0, 0))
        if start <= address < start + size and (address - start) % 32 == 0:
            ptr, length = im.pointer(address + 16), im.at('Q', address + 24)[0]
            if 0 < length <= 256:
                offset = im.offset(ptr, length)
                try:
                    text = im.data[offset:offset + length].decode('ascii')
                except UnicodeError:
                    return ('unknown', None)
                if text in FIELDS:
                    return ('field', text)
                if text in STATIC_PATHS:
                    return ('route', text)
        return ('address', address)

    def external(self, target):
        im = self.image
        start, size, index, stride = self.sections.get(b'__stubs', (0, 0, 0, 0))
        if not stride or not start <= target < start + size or (target - start) % stride:
            return None
        indirect_index = index + (target - start) // stride
        if indirect_index >= self.dynamic[13]:
            raise ValueError('Invalid indirect import index')
        symbol = im.unpack('I', self.dynamic[12] + indirect_index * 4)[0]
        offset, count, strings, string_size = self.symbols
        if symbol >= count:
            return None
        string_offset = im.unpack('I', offset + symbol * 16)[0]
        if string_offset >= string_size:
            raise ValueError('Invalid symbol string offset')
        # Compare only a tiny approved symbol set; never return unknown symbol names.
        end = min(strings + string_size, strings + string_offset + 96)
        raw = im.data[strings + string_offset:end].split(b'\0', 1)[0]
        allowed = (b'_objc_msgSend', b'_objc_retainAutoreleasedReturnValue', b'_objc_retain',
                   b'_objc_release', b'_objc_autoreleaseReturnValue')
        return raw.decode() if raw in allowed else None

    def inspect(self, name, start, end, tool, source):
        result = subprocess.run([str(tool), '-d', '--no-show-raw-insn',
            '--start-address=' + hex(start), '--stop-address=' + hex(end), str(source)],
            capture_output=True, text=True, timeout=30)
        if result.returncode or len(result.stdout) > 1024 * 1024:
            raise ValueError('Bounded disassembly failed')
        instructions = []
        for line in result.stdout.splitlines():
            match = re.match(r'^\s*([0-9a-f]+):\s+([a-z0-9.]+)\s*(.*)', line)
            if match:
                pc, op, operands = int(match[1], 16), match[2], match[3].split(';', 1)[0].split('<', 1)[0].strip()
                if not start <= pc < end:
                    raise ValueError('Disassembler escaped method span')
                instructions.append((pc, op, operands))
        block_starts = {start}
        for pc, op, operands in instructions:
            if op == 'b' or op.startswith('b.') or op in ('cbz', 'cbnz', 'tbz', 'tbnz'):
                match = re.search(r'(0x[0-9a-f]+)$', operands)
                if match and start <= int(match[1], 16) < end:
                    block_starts.add(int(match[1], 16))
                block_starts.add(pc + 4)
        state, events, fields, routes, unknown_messages = {}, [], set(), set(), 0
        helpers = []
        for pc, op, operands in instructions:
            if pc in block_starts:
                state.clear()
            match = re.fullmatch(r'x(\d+), (0x[0-9a-f]+)', operands)
            if op == 'adrp' and match:
                state[int(match[1])] = ('address', int(match[2], 16)); continue
            match = re.fullmatch(r'x(\d+), x(\d+), #(0x[0-9a-f]+|\d+)', operands)
            if op == 'add' and match:
                dest, base, value = int(match[1]), int(match[2]), int(match[3], 0)
                source_tag = state.get(base)
                state[dest] = self.tag(source_tag[1] + value) if source_tag and source_tag[0] == 'address' else ('unknown', None)
                if state[dest][0] == 'field': fields.add(state[dest][1])
                if state[dest][0] == 'route': routes.add(state[dest][1])
                continue
            match = re.fullmatch(r'x(\d+), \[x(\d+)(?:, #(0x[0-9a-f]+|\d+))?\]', operands)
            if op == 'ldr' and match:
                dest, base, value = int(match[1]), int(match[2]), int(match[3] or '0', 0)
                source_tag = state.get(base)
                state[dest] = self.tag(source_tag[1] + value) if source_tag and source_tag[0] == 'address' else ('unknown', None)
                continue
            match = re.fullmatch(r'x(\d+), x(\d+)', operands)
            if op == 'mov' and match:
                state[int(match[1])] = state.get(int(match[2]), ('unknown', None)); continue
            if op == 'bl':
                target = int(operands.split()[0], 16)
                symbol = self.external(target)
                if target in self.start_set and not start <= target < end and target not in helpers:
                    helpers.append(target)
                selector = state.get(1, ('unknown', None))
                if symbol == '_objc_msgSend' and selector[0] == 'selector':
                    event = {'selector': selector[1]}
                    key = state.get(2 if selector[1] in ('objectForKey:', 'objectForKeyedSubscript:') else 3)
                    if key and key[0] == 'field':event['field'] = key[1]
                    events.append(event)
                elif symbol == '_objc_msgSend':
                    unknown_messages += 1
                if symbol not in ('_objc_retainAutoreleasedReturnValue', '_objc_retain', '_objc_autoreleaseReturnValue'):
                    for register in range(19):state.pop(register, None)
                continue
            if op == 'b' or op.startswith('b.') or op in ('cbz', 'cbnz', 'tbz', 'tbnz'):
                state.clear()
                continue
            # Unsupported register-writing instructions must not preserve stale tags.
            match = re.match(r'[xw](\d+),', operands)
            if match and op not in ('str', 'strb', 'strh', 'stp', 'cmp', 'tst'):
                state.pop(int(match[1]), None)
        code = self.image.data[self.image.offset(start, end - start):self.image.offset(start, end - start) + end - start]
        self.direct_helpers[name] = helpers
        return {'method': name, 'implementation_bytes': len(code),
                'implementation_sha256': hashlib.sha256(code).hexdigest(),
                'allowlisted_field_references': sorted(fields), 'allowlisted_route_references': sorted(routes),
                'message_observations': events, 'unreported_message_count': unknown_messages,
                'complete_schema_established': False, 'runtime_behavior_verified': False}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('input', type=Path)
    parser.add_argument('--objdump', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    try:
        if args.input.stat().st_size > 512 * 1024 * 1024 or args.input.resolve() == args.out.resolve():
            raise ValueError('Invalid source')
        image = Image(args.input.read_bytes()); scanner = References(image)
        handlers = selected_handlers(image)
        observations = [scanner.inspect(n, a, b, args.objdump, args.input) for n, (a, b) in sorted(handlers.items())]
        parent_refs = {}
        for name, _ in sorted(handlers.items()):
            for target in scanner.direct_helpers[name]:
                if target in (a for a, _ in handlers.values()):
                    continue
                parent_refs.setdefault(target, []).append(name)
        helper_observations, skipped = [], 0
        for target, parents in sorted(parent_refs.items()):
            end = next((x for x in scanner.starts if x > target), None)
            if len(helper_observations) >= 32 or end is None or end - target > 4096:
                skipped += 1
                continue
            helper = scanner.inspect('direct-helper-%03d' % (len(helper_observations) + 1),
                                     target, end, args.objdump, args.input)
            helper['direct_callers'] = parents
            helper_observations.append(helper)
        output = {'kind': 'partial-static-allowlisted-handler-references',
            'source_sha256': hashlib.sha256(image.data).hexdigest(),
            'handlers': observations, 'direct_helpers': helper_observations,
            'helper_depth': 1, 'bounded_helpers_skipped': skipped,
            'limits': 'Conservative local instruction windows only. Unknown literals/messages are omitted. Field references and partial patcher edits do not establish a complete original-client request/response schema.'}
        args.out.parent.mkdir(parents=True, exist_ok=True)
        with args.out.open('x') as stream:stream.write(json.dumps(output, indent=2) + '\n')
    except (OSError, ValueError, UnicodeError, subprocess.SubprocessError):
        raise SystemExit('Bounded handler inspection failed; original source and prior output preserved.')
    print('Partial allowlisted handler observations written; no complete schema or runtime proof claimed.')


if __name__ == '__main__':
    main()
