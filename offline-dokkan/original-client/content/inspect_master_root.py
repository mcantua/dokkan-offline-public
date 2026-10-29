#!/usr/bin/env python3
"""Inspect the pinned prepared engine's reviewed Documents-based master root.

Never executes or changes the engine. Only allowlisted path/ABI facts and body
hashes go to the public receipt. Addresses and disassembly remain under the
ignored private/research-master directory. No source key/provider is followed.
Requires the separately recorded Capstone 5.0.6 cloud dependency.
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct
import sys

ROOT = Path(__file__).resolve().parents[3]
sys.path[:0] = [str(ROOT / "downloads/capstone/runtime"),
                str(ROOT / "offline-dokkan/tools")]
from capstone import Cs, CS_ARCH_ARM64, CS_MODE_LITTLE_ENDIAN
from objc_runtime_metadata import Image

SOURCE_HASH = "efaabfc9b3cdb0e2eeb550b6ea616f5eeb565c6584ad838b765f34539648d222"
SOURCE_BYTES = 55697728
BODY_HASHES = {
    "asset_root_getter": "3e00de787fa9197bfaae073edf88d1cde2f4a878628ba425d050c36b75bef867",
    "path_prefix": "6c0cbc3211c0f9356f5b632126fdafc7de6c3cbcc0ab99a8a10b5d0525ab2402",
    "full_path_resolver": "1a43222687527b80c5ed4e36bac248868cfca9e40aa29346b30d45d07421339b",
}


def function_starts(image):
    payload = None
    pos = 32
    for _ in range(image.unpack("I", 16)[0]):
        command, size = image.unpack("II", pos)
        if command == 0x26:
            if payload is not None:
                raise ValueError("Duplicate function-start metadata")
            payload = image.unpack("II", pos + 8)
        pos += size
    if payload is None:
        raise ValueError("Missing function-start metadata")
    start, size = payload
    if not size or start + size > len(image.data):
        raise ValueError("Invalid function-start metadata")
    cursor, address, result = start, image.base, []
    while cursor < start + size:
        value = shift = 0
        while True:
            if cursor >= start + size or shift >= 64:
                raise ValueError("Invalid function-start encoding")
            byte = image.data[cursor]
            cursor += 1
            value |= (byte & 127) << shift
            shift += 7
            if byte < 128:
                break
        if not value:
            return result
        address += value
        image.offset(address, 4)
        result.append(address)
    raise ValueError("Unterminated function-start metadata")


def selected_functions(image, starts):
    by_hash = {value: key for key, value in BODY_HASHES.items()}
    result = {}
    for start, end in zip(starts, starts[1:]):
        if end - start > 1024 * 1024:
            continue
        body = image.data[image.offset(start):image.offset(end)]
        digest = hashlib.sha256(body).hexdigest()
        if digest in by_hash:
            name = by_hash[digest]
            if name in result:
                raise ValueError("Ambiguous reviewed body")
            result[name] = (start, body)
    if set(result) != set(BODY_HASHES):
        raise ValueError("Reviewed function body changed")
    return result


def imports(image):
    pos, fixup = 32, None
    for _ in range(image.unpack("I", 16)[0]):
        command, size = image.unpack("II", pos)
        if command == 0x80000034:
            fixup = image.unpack("II", pos + 8)
        pos += size
    if fixup is None:
        raise ValueError("Missing chained imports")
    offset, size = fixup
    version, _, table, pool, count, form, compression = image.unpack("7I", offset)
    if (version, form, compression) != (0, 3, 0) or count > 65536:
        raise ValueError("Unsupported chained imports")
    if not (28 <= table <= table + count * 16 <= pool < size):
        raise ValueError("Invalid chained imports")
    names = []
    for index in range(count):
        record, _ = image.unpack("Qq", offset + table + index * 16)
        at = offset + pool + (record >> 32)
        if not offset + pool <= at < offset + size:
            raise ValueError("Invalid import name offset")
        end = image.data.find(b"\0", at, offset + size)
        if end < 0:
            raise ValueError("Unterminated import name")
        names.append(image.data[at:end].decode("ascii"))
    result = {}
    for address in image.binds:
        ordinal = image.at("Q", address)[0] & 0xffffff
        if ordinal >= len(names):
            raise ValueError("Invalid chained import ordinal")
        result[address] = names[ordinal]
    return result


def stub(image, decoder, bindings, target):
    """Resolve only fixed ADRP/LDR import and selector stub operands."""
    registers, symbol, selector = {}, None, None
    try:
        offset = image.offset(target, 24)
    except ValueError:
        return None, None
    for instruction in decoder.disasm(image.data[offset:offset + 24], target):
        ops = instruction.operands
        if instruction.mnemonic == "adrp" and len(ops) == 2:
            registers[instruction.reg_name(ops[0].reg)] = ops[1].imm
        elif instruction.mnemonic == "ldr" and len(ops) == 2 and ops[1].type == 3:
            base = registers.get(instruction.reg_name(ops[1].mem.base))
            if base is None:
                continue
            address = base + ops[1].mem.disp
            if address in bindings:
                symbol = bindings[address]
            if instruction.reg_name(ops[0].reg) == "x1":
                try:
                    candidate = image.string(image.pointer(address))
                    if candidate in {"objectAtIndex:", "UTF8String"}:
                        selector = candidate
                except (ValueError, UnicodeDecodeError):
                    pass
        if instruction.mnemonic in {"br", "ret", "b"}:
            break
    return symbol, selector


def root_calls(image, decoder, bindings, function):
    address, body = function
    registers = {"x8": "indirect-result"}
    facts, private_calls = [], []

    def reg(operand):
        name = decoder.reg_name(operand.reg)
        return "x" + name[1:] if name.startswith("w") else name

    for instruction in decoder.disasm(body, address):
        ops, mnemonic = instruction.operands, instruction.mnemonic
        if mnemonic in {"mov", "movz"} and len(ops) == 2:
            registers[reg(ops[0])] = (ops[1].imm if ops[1].type == 2
                                      else registers.get(reg(ops[1])))
        elif mnemonic == "adrp" and len(ops) == 2:
            registers[reg(ops[0])] = ops[1].imm
        elif mnemonic == "add" and len(ops) == 3 and ops[2].type == 2:
            value = registers.get(reg(ops[1]))
            registers[reg(ops[0])] = (value + ops[2].imm if isinstance(value, int)
                                       else value if ops[2].imm == 0 else None)
        elif mnemonic.startswith("ldr") and len(ops) == 2 and ops[1].type == 3:
            base = registers.get(decoder.reg_name(ops[1].mem.base))
            try:
                registers[reg(ops[0])] = (image.pointer(base + ops[1].mem.disp)
                                           if isinstance(base, int) else None)
            except ValueError:
                registers[reg(ops[0])] = None
        if mnemonic != "bl":
            continue
        symbol, selector = stub(image, decoder, bindings, ops[0].imm)
        result = "result-" + str(len(facts))
        fact = {"kind": "helper", "result": result}
        if symbol == "_NSSearchPathForDirectoriesInDomains":
            fact = {"kind": "search-path", "result": result,
                    "directory": registers.get("x0"), "domain": registers.get("x1"),
                    "expand": registers.get("x2")}
        elif symbol == "_objc_msgSend" and selector:
            fact = {"kind": selector, "result": result,
                    "receiver": registers.get("x0"), "index": registers.get("x2")}
        elif symbol and "basic_string" in symbol and "append" in symbol:
            literal = None
            try:
                if image.string(registers.get("x1")) == "/":
                    literal = "/"
            except (ValueError, TypeError, UnicodeDecodeError):
                pass
            fact = {"kind": "append", "result": result, "literal": literal}
        fact["writes_result"] = registers.get("x0") == "indirect-result"
        fact["input"] = registers.get("x1") if isinstance(registers.get("x1"), str) else None
        facts.append(fact)
        private_calls.append({"call_address": instruction.address, "target": ops[0].imm})
        for index in range(18):
            registers["x" + str(index)] = None
        registers["x0"] = result
    search = [item for item in facts if item["kind"] == "search-path"]
    selected = [item for item in facts if item["kind"] == "objectAtIndex:"]
    utf8 = [item for item in facts if item["kind"] == "UTF8String"]
    append = [item for item in facts if item["kind"] == "append"]
    valid = (len(search) == len(selected) == len(utf8) == len(append) == 1 and
             (search[0]["directory"], search[0]["domain"], search[0]["expand"]) == (9, 1, 1) and
             selected[0]["receiver"] == search[0]["result"] and selected[0]["index"] == 0 and
             utf8[0]["receiver"] == selected[0]["result"] and
             any(item["writes_result"] and item["input"] == utf8[0]["result"] for item in facts) and
             append[0]["writes_result"] and append[0]["literal"] == "/")
    if not valid:
        raise ValueError("Reviewed Documents result flow changed")
    return private_calls


def inspect(source):
    if source.stat().st_size != SOURCE_BYTES:
        raise ValueError("Unreviewed prepared engine size")
    data = source.read_bytes()
    if hashlib.sha256(data).hexdigest() != SOURCE_HASH:
        raise ValueError("Unreviewed prepared engine hash")
    image = Image(data)
    if image.chain_formats != {6}:
        raise ValueError("Unreviewed pointer format")
    functions = selected_functions(image, function_starts(image))
    decoder = Cs(CS_ARCH_ARM64, CS_MODE_LITTLE_ENDIAN)
    decoder.detail = True
    calls = root_calls(image, decoder, imports(image), functions["asset_root_getter"])
    getter, _ = functions["asset_root_getter"]
    resolver, _ = functions["full_path_resolver"]
    tables = []
    for pointer, target in image.rebases.items():
        if target == getter:
            try:
                if image.pointer(pointer - 0x98 + 0x48) == resolver:
                    tables.append(pointer - 0x98)
            except ValueError:
                pass
    if len(tables) != 1:
        raise ValueError("Ambiguous reviewed resource vtable")
    private = ROOT / "offline-dokkan/private/research-master"
    private.mkdir(exist_ok=True)
    index = {"functions": {}, "resource_vtable": tables[0], "calls": calls}
    for label, (address, body) in functions.items():
        index["functions"][label] = {"address": address, "file_offset": image.offset(address),
                                      "body_sha256": BODY_HASHES[label]}
        (private / (label + ".asm")).write_text("\n".join(
            f"{item.address:x} {item.mnemonic} {item.op_str}"
            for item in decoder.disasm(body, address)) + "\n")
    (private / "reviewed-root-index.json").write_text(json.dumps(index, indent=2) + "\n")
    return {
        "schema": "original-master-root-static-v1", "prepared_engine_sha256": SOURCE_HASH,
        "prepared_engine_bytes": SOURCE_BYTES, "reviewed_body_sha256": BODY_HASHES,
        "resource_vtable_slots": {"native_root": 152, "full_path": 72},
        "native_root": {"api": "NSSearchPathForDirectoriesInDomains",
                        "directory_enum": 9, "directory_name": "NSDocumentDirectory",
                        "domain_mask": 1, "domain_name": "NSUserDomainMask",
                        "expand_tilde": True, "array_selector": "objectAtIndex:",
                        "array_index": 0, "string_selector": "UTF8String",
                        "appended_suffix": "/", "result": "own app Documents directory plus /"},
        "master_relative_template": "sqlite/current/%s/database.db",
        "asset_prefix": {"default": "assets", "configured_nonempty_override_exists": True,
                         "provenance": "original-master-main-contract.json and pinned prefix body"},
        "default_master_path": "<own-app-Documents>/assets/sqlite/current/<language>/database.db",
        "limits": {"original_executed": False, "actual_container_path_observed": False,
                   "runtime_prefix_value_observed": False, "prefix_setter_admitted": False,
                   "host_resources_root_used_by_original_getter": False,
                   "source_key_read_or_emitted": False, "source_modified": False,
                   "engine_open_of_staged_plaintext_proven": False,
                   "raw_addresses_or_code_in_public_receipt": False},
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    if args.source.resolve() == args.output.resolve():
        raise SystemExit("Input preserved; receipt cannot replace the engine.")
    try:
        result = inspect(args.source)
        args.output.write_text(json.dumps(result, indent=2) + "\n")
    except (OSError, ValueError, UnicodeError, struct.error):
        raise SystemExit("Root inspection stopped; no arbitrary data or source bytes emitted.")
    print("Reviewed Documents-root receipt written; original engine was not executed.")


if __name__ == "__main__":
    main()
