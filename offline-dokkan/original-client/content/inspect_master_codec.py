#!/usr/bin/env python3
"""Bounded static MAIN master open/key/cache inspection, without key material.

Only reviewed contract entry points are decoded. Key-provider bodies/data are
never followed. Public output has call roles, small ABI facts and body hashes;
addresses/disassembly are written only under ignored private/research-master.
"""
import argparse
import hashlib
import json
from pathlib import Path

from inspect_master_root import (ROOT, SOURCE_BYTES, SOURCE_HASH, Cs,
                                 CS_ARCH_ARM64, CS_MODE_LITTLE_ENDIAN,
                                 Image, function_starts, imports, stub)

FIELDS = {
    "cached_master_wrapper": ("open_and_key", "cached_master_wrapper_vm"),
    "path_and_key_wrapper": ("open_and_key", "path_and_key_wrapper_vm"),
    "internal_open_shim": ("open_and_key", "internal_open_shim_vm"),
    "internal_open_core": ("open_and_key", "internal_open_core_vm"),
    "internal_key_attach": ("open_and_key", "internal_key_attach_vm"),
    "internal_codec_attach": ("open_and_key", "internal_codec_attach_vm"),
    "close_reopen": ("cache", "close_reopen_vm"),
}
SAFE_INTS = frozenset((0, 1, 2, 3, 4, 6, 16, 24, 32, 64, 65537))


def public_summary(result):
    """Keep exact simple facts; linear tags are not callable ABI evidence."""
    functions = result["functions"]
    summarized = {}
    for label, entry in functions.items():
        calls = []
        for item in entry["calls"]:
            role = item["role"]
            if role == "unfollowed-internal-or-external-helper":
                continue
            row = {"role": role}
            if label in {"internal_open_shim", "path_and_key_wrapper"}:
                row["linear_register_tags"] = item["arguments"]
            elif label == "internal_key_attach" and role == "internal_codec_attach":
                row["linear_key_argument_tag"] = item["arguments"]["arg2"]
                row["linear_key_length_tag"] = item["arguments"]["arg3"]
            calls.append(row)
        summarized[label] = {
            "body_sha256": entry["body_sha256"],
            "entry_is_function_start": entry["entry_is_function_start"],
            "selected_call_roles_in_code_order": calls,
            "unfollowed_helper_count": sum(item["role"] == "unfollowed-internal-or-external-helper"
                                          for item in entry["calls"]),
        }
        if label in {"cached_master_wrapper", "close_reopen"}:
            summarized[label]["reviewed_member_loads"] = entry["reviewed_member_loads"]
            summarized[label]["reviewed_member_stores"] = entry["reviewed_member_stores"]
            summarized[label]["conditional_value_branches"] = entry["conditional_value_branches"]
    result["functions"] = summarized
    result["evidence_model"] = "Bounded linear register tags; not path-sensitive execution or a callable ABI admission"
    return result


def inspect(source):
    if source.stat().st_size != SOURCE_BYTES:
        raise ValueError("Unexpected prepared engine size")
    data = source.read_bytes()
    if hashlib.sha256(data).hexdigest() != SOURCE_HASH:
        raise ValueError("Unexpected prepared engine hash")
    contract = json.loads((ROOT / "offline-dokkan/research/original-master-main-contract.json").read_text())
    if contract.get("source_sha256") != "9d6bf0470c4b4ff7d914740ccf9f1622afa962b763e18bfcf1f6e051bfae0610":
        raise ValueError("Unexpected existing MAIN contract")
    image = Image(data)
    starts = function_starts(image)
    bindings = imports(image)
    entries = {label: contract[group][field] for label, (group, field) in FIELDS.items()}
    roles = {address: label for label, address in entries.items()}
    key_start, key_end = contract["open_and_key"]["key_string_provider_vm_range"]
    decoder = Cs(CS_ARCH_ARM64, CS_MODE_LITTLE_ENDIAN)
    decoder.detail = True
    private = ROOT / "offline-dokkan/private/research-master"
    private.mkdir(exist_ok=True)
    result, index = {}, {}

    def reg(operand):
        value = decoder.reg_name(operand.reg)
        return "x" + value[1:] if value.startswith("w") else value

    def public_value(value):
        if isinstance(value, int):
            return value if value in SAFE_INTS else "unreported-constant-or-address"
        return value if isinstance(value, str) else "unresolved"

    for label, start in entries.items():
        end = min(value for value in starts if value > start)
        if start < key_end and end > key_start:
            raise ValueError("Key-provider body excluded")
        if end - start > 256 * 1024:
            raise ValueError("Reviewed body exceeds bound")
        body = data[image.offset(start):image.offset(end)]
        instructions = list(decoder.disasm(body, start))
        (private / (label + ".asm")).write_text("\n".join(
            f"{item.address:x} {item.mnemonic} {item.op_str}" for item in instructions) + "\n")
        index[label] = {"address": start, "file_offset": image.offset(start),
                        "end_address": end, "body_sha256": hashlib.sha256(body).hexdigest()}
        registers = {"x0": "entry-arg0", "x1": "entry-arg1", "x2": "entry-arg2",
                     "x3": "entry-arg3", "x8": "entry-indirect-result", "xzr": 0}
        calls, loads, stores, conditional_branches = [], [], [], []
        for instruction in instructions:
            ops, mnemonic = instruction.operands, instruction.mnemonic
            if mnemonic in {"mov", "movz"} and len(ops) == 2:
                registers[reg(ops[0])] = (ops[1].imm if ops[1].type == 2
                                          else registers.get(reg(ops[1])))
            elif mnemonic == "adrp" and len(ops) == 2:
                registers[reg(ops[0])] = ops[1].imm
            elif mnemonic in {"add", "sub"} and len(ops) == 3 and ops[2].type == 2:
                value = registers.get(reg(ops[1]))
                displacement = ops[2].imm * (1 if mnemonic == "add" else -1)
                registers[reg(ops[0])] = (value + displacement if isinstance(value, int)
                                           else value if displacement == 0 else None)
            elif mnemonic.startswith("ldr") and len(ops) == 2 and ops[1].type == 3:
                base = registers.get(decoder.reg_name(ops[1].mem.base))
                displacement = ops[1].mem.disp
                if isinstance(base, str) and displacement in {0, 8, 16, 24, 32}:
                    value = base + ".member+" + str(displacement)
                    loads.append({"base": base, "offset": displacement})
                else:
                    # Do not dereference static addresses or possible key bytes.
                    value = None
                registers[reg(ops[0])] = value
            elif mnemonic in {"str", "stur"} and len(ops) == 2 and ops[1].type == 3:
                base = registers.get(decoder.reg_name(ops[1].mem.base))
                if isinstance(base, str) and ops[1].mem.disp in {0, 8, 16, 24, 32}:
                    stores.append({"base": base, "offset": ops[1].mem.disp,
                                   "value": public_value(registers.get(reg(ops[0])))})
            if mnemonic in {"cbz", "cbnz", "tbz", "tbnz"} and ops and ops[0].type == 1:
                conditional_branches.append({"kind": mnemonic,
                                             "value": public_value(registers.get(reg(ops[0])))})
            target = None
            if mnemonic == "bl" and ops and ops[0].type == 2:
                target = ops[0].imm
            elif mnemonic == "b" and ops and ops[0].type == 2 and ops[0].imm in roles:
                target = ops[0].imm
            if target is None:
                continue
            name, _ = stub(image, decoder, bindings, target)
            role = roles.get(target)
            if key_start <= target < key_end:
                role = "opaque-native-key-provider-not-followed"
            elif name == "_strlen":
                role = "strlen"
            elif name and "basic_string" in name:
                role = "standard-string-helper"
            elif name in {"_free", "_malloc", "_memset", "_memcpy", "_memmove"}:
                role = name[1:]
            if role is None:
                role = "unfollowed-internal-or-external-helper"
            row = {"role": role, "arguments": {"arg" + str(i): public_value(registers.get("x" + str(i)))
                                                  for i in range(4)},
                   "indirect_result": public_value(registers.get("x8"))}
            calls.append(row)
            for number in range(18):
                registers["x" + str(number)] = None
            registers["x0"] = "call-result-" + str(len(calls) - 1)
        result[label] = {"body_sha256": hashlib.sha256(body).hexdigest(),
                         "entry_is_function_start": start in starts,
                         "calls": calls, "reviewed_member_loads": loads,
                         "reviewed_member_stores": stores,
                         "conditional_value_branches": conditional_branches}
    (private / "reviewed-codec-index.json").write_text(json.dumps(index, indent=2) + "\n")
    return public_summary({"schema": "original-master-codec-static-v1", "prepared_engine_sha256": SOURCE_HASH,
            "prepared_engine_bytes": SOURCE_BYTES, "functions": result,
            "limits": {"original_executed": False, "key_provider_body_followed": False,
                       "key_values_read_or_emitted": False, "source_modified": False,
                       "public_addresses_or_disassembly_emitted": False,
                       "path_sensitive_runtime_proof": False,
                       "derived_master_codec_compatibility_proven": False,
                       "foreign_sqlite_handle_abi_admitted": False}})


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    if args.source.resolve() == args.output.resolve():
        raise SystemExit("Input preserved; output cannot replace the engine.")
    try:
        result = inspect(args.source)
        args.output.write_text(json.dumps(result, indent=2) + "\n")
    except (OSError, ValueError, UnicodeError):
        raise SystemExit("Codec inspection stopped; source and key material preserved.")
    print("Reviewed MAIN open/codec/cache receipt written; no key provider was followed.")


if __name__ == "__main__":
    main()
