"""Leaf-only ARM64 telemetry. No host/native function pointer invocation.

Every probe replays its exact displaced MOV. No key argument/provider is read.
The sole native stack write is the proved unused cached-open SP+0 ticket slot.
All other writes are below the temporary SP or in the new observer RW segment.
"""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / "downloads/native-probe/runtime"))
from keystone import Ks, KS_ARCH_ARM64, KS_MODE_LITTLE_ENDIAN

BASE = 0x100000000
TEXT_BYTES, DATA_BYTES = 16384, 65536
RECORD_BYTES, RECORDS, RECORD_BASE = 2048, 16, 64
PATH_OFFSET, PATH_MAX, COMPLETE_OFFSET = 80, 1023, 1104
WITNESS_RECORD_OFFSET, WITNESS_TICKET_OFFSET = 36864, 40960
MAGIC = b"ODMOBS1\0"
SITES = {
    "entry": (0x10044FA68, 0xAA0003F6),       # mov x22,x0
    "preferred": (0x10044FABC, 0xAA0003F4),   # mov x20,x0
    "fallback": (0x10044FB00, 0xAA0003F4),    # mov x20,x0
    "finish": (0x10044FB54, 0xAA1403E0),      # mov x0,x20
    "filename": (0x100431934, 0xAA1403E1),    # mov x1,x20
}

def prologue():
    return ["sub sp,sp,#96", "stp x9,x10,[sp,#0]", "stp x11,x12,[sp,#16]",
            "stp x13,x14,[sp,#32]", "stp x15,x16,[sp,#48]",
            "stp x17,x30,[sp,#64]", "mrs x9,nzcv", "str x9,[sp,#80]"]

def epilogue(replay,return_address):
    return ["ldr x9,[sp,#80]", "msr nzcv,x9", "ldp x9,x10,[sp,#0]",
            "ldp x11,x12,[sp,#16]", "ldp x13,x14,[sp,#32]",
            "ldp x15,x16,[sp,#48]", "ldp x17,x30,[sp,#64]",
            "add sp,sp,#96", replay, f"b #{return_address}"]

def constant(reg, value):
    assert 0 <= value < 1 << 32
    return [f"movz {reg},#{value & 65535}", f"movk {reg},#{value >> 16},lsl #16"]

def image_address(reg, scratch, address, text_vm):
    # ADR references this recipe's own code, then subtract its image-relative
    # position. ASLR slide cancels; no absolute runtime pointer is embedded.
    return [f"adr {reg},#{text_vm}", *constant(scratch, text_vm-BASE),
            f"sub {reg},{reg},{scratch}", *constant(scratch,address-BASE),
            f"add {reg},{reg},{scratch}"]

def record(data_vm, prefix, native_sp_offset, owner_register, bad):
    return [f"ldr x11,[sp,#{native_sp_offset}]", f"cbz x11,{bad}",
            "sub x12,x11,#1", "and x12,x12,#15", "lsl x12,x12,#11",
            f"adr x9,#{data_vm}", "add x13,x9,#64", "add x13,x13,x12",
            "ldr x14,[x13]", "cmp x14,x11", f"b.ne {bad}",
            "ldr x14,[x13,#8]", "add x14,x14,#16",
            f"cmp x14,{owner_register}", f"b.ne {bad}"]

def assemble(text_vm):
    data_vm = text_vm + TEXT_BYTES
    functions = {}
    specs = []
    entry = prologue() + [f"adr x9,#{data_vm}", "add x9,x9,#24",
        "entry_active:", "ldaxr x10,[x9]", "add x11,x10,#1",
        "stlxr w12,x11,[x9]", "cbnz w12,entry_active", "cbz x10,entry_no_overlap",
        f"adr x9,#{data_vm}", "mov x10,#1", "str x10,[x9,#32]", "entry_no_overlap:",
        f"adr x9,#{data_vm}", "add x9,x9,#16", "entry_ticket:",
        "ldaxr x10,[x9]", "add x11,x10,#1", "stlxr w12,x11,[x9]",
        "cbnz w12,entry_ticket", "str x11,[sp,#96]",
        "and x12,x10,#15", "lsl x12,x12,#11", f"adr x9,#{data_vm}",
        "add x13,x9,#64", "add x13,x13,x12", "str xzr,[x13,#1104]",
        "str x0,[x13,#8]", "ldr x14,[x0,#16]", "str x14,[x13,#16]",
        "cbz x14,entry_clear_witness",f"adr x15,#{data_vm+WITNESS_TICKET_OFFSET}",
        "ldar x16,[x15]","cbz x16,entry_witness_done",
        f"adr x17,#{data_vm+WITNESS_RECORD_OFFSET}","ldr x16,[x17,#8]",
        "cmp x16,x0","b.ne entry_clear_witness","ldr x16,[x17,#64]",
        "cmp x16,x14","b.eq entry_witness_done","entry_clear_witness:",
        f"adr x15,#{data_vm+WITNESS_TICKET_OFFSET}","stlr xzr,[x15]","entry_witness_done:",
        "mov x14,#-1", "str x14,[x13,#24]", "str x14,[x13,#32]",
        "str x14,[x13,#40]", "stp xzr,xzr,[x13,#48]", "stp xzr,xzr,[x13,#64]",
        "dmb ish", "stlr x11,[x13]"] + epilogue("mov x22,x0",SITES['entry'][0]+4)
    specs.append(("entry", entry))
    for name, off in (("preferred",24),("fallback",32)):
        body = prologue()+record(data_vm,name,96,"x22",name+"_bad")+[
            "sxtw x14,w0",f"str x14,[x13,#{off}]",f"b {name}_done",
            name+"_bad:",f"adr x9,#{data_vm}","mov x14,#1","str x14,[x9,#40]",
            name+"_done:"]+epilogue("mov x20,x0",SITES[name][0]+4)
        specs.append((name,body))
    finish = prologue()+record(data_vm,"finish",96,"x22","finish_bad")+[
        "sxtw x14,w20", "str x14,[x13,#40]", "ldr x14,[x22]", "str x14,[x13,#64]",
        "dmb ish", "add x14,x13,#1104", "stlr x11,[x14]",
        "cbnz w20,finish_no_witness","ldr x14,[x13,#16]","cbnz x14,finish_no_witness",
        "ldr x14,[x13,#64]","cbz x14,finish_no_witness",
        "ldr x14,[x13,#72]","tbz x14,#0,finish_no_witness",
        "ldr x14,[x13,#48]","cmp x14,#1","b.eq finish_preferred_witness",
        "cmp x14,#2","b.ne finish_no_witness","ldr x14,[x13,#32]","b finish_path_result",
        "finish_preferred_witness:","ldr x14,[x13,#24]","finish_path_result:",
        "cbnz x14,finish_no_witness",f"adr x15,#{data_vm+WITNESS_TICKET_OFFSET}",
        "stlr xzr,[x15]",f"adr x16,#{data_vm+WITNESS_RECORD_OFFSET}","mov x17,#0",
        "finish_copy_witness:","ldr x14,[x13,x17]","str x14,[x16,x17]",
        "add x17,x17,#8","cmp x17,#1112","b.lo finish_copy_witness",
        "dmb ish","stlr x11,[x15]","finish_no_witness:",
        f"adr x9,#{data_vm}", "add x9,x9,#48", "stlr x11,[x9]", "b finish_decrement",
        "finish_bad:",f"adr x9,#{data_vm}","mov x14,#1","str x14,[x9,#40]",
        "finish_decrement:",f"adr x9,#{data_vm}","add x9,x9,#24",
        "finish_active:","ldaxr x10,[x9]","cbz x10,finish_underflow",
        "sub x10,x10,#1","stlxr w12,x10,[x9]","cbnz w12,finish_active","b finish_done",
        "finish_underflow:","clrex",f"adr x9,#{data_vm}","mov x14,#1","str x14,[x9,#40]",
        "finish_done:"]+epilogue("mov x0,x20",SITES['finish'][0]+4)
    specs.append(("finish",finish))
    # The actual original path wrapper saved its caller LR at native SP+0x58.
    # Only the two cached-open callers may supply our parent's SP+0 ticket.
    filename = prologue()+["ldr x17,[sp,#184]"]+image_address("x15","x16",0x10044FABC,text_vm)+[
        "cmp x17,x15","mov x17,#1","b.eq filename_parent"]+image_address("x15","x16",0x10044FB00,text_vm)+[
        "ldr x17,[sp,#184]","cmp x17,x15","b.ne filename_done","mov x17,#2",
        "filename_parent:"]+record(data_vm,"filename",192,"x20","filename_bad")+[
        "str x17,[x13,#48]","str xzr,[x13,#56]","str xzr,[x13,#72]",
        "ldrsb w14,[sp,#143]","tbz w14,#31,filename_short","ldr x14,[sp,#128]","b filename_length",
        "filename_short:","uxtb w14,w14","filename_length:","cbz x14,filename_done",
        "cmp x14,#1023","b.hi filename_done","add x16,x13,#80","mov x17,#0",
        "filename_copy:","ldrb w9,[x0,x17]","strb w9,[x16,x17]","add x17,x17,#1",
        "cmp x17,x14","b.lo filename_copy","ldrb w9,[x0,x14]","cbnz w9,filename_done",
        "strb wzr,[x16,x14]","str x14,[x13,#56]","mov x14,#1","str x14,[x13,#72]",
        "b filename_done","filename_bad:",f"adr x9,#{data_vm}","mov x14,#1","str x14,[x9,#40]",
        "filename_done:"]+epilogue("mov x1,x20",SITES['filename'][0]+4)
    specs.append(("filename",filename))
    ks=Ks(KS_ARCH_ARM64,KS_MODE_LITTLE_ENDIAN)
    code=bytearray()
    for name,lines in specs:
        while len(code)%16:code+=b"\0"
        address=text_vm+len(code)
        # Keystone0.9.2 mis-encodes numeric ADR at high arm64 addresses. Emit
        # that one architectural encoding directly; every instruction is still
        # independently decoded and executed by the combined Capstone/Unicorn
        # check at two slides. Labels occupy no instruction word.
        prepared=[];pc=address
        for line in lines:
            if line.startswith("adr "):
                reg,target=line[4:].split(",#");rd=int(reg[1:]);delta=int(target)-pc
                if not -(1<<20)<=delta<(1<<20):raise ValueError("ADR target out of range")
                word=0x10000000|((delta&3)<<29)|(((delta>>2)&0x7ffff)<<5)|rd
                prepared.append(f".word {word}")
            elif line.startswith("b #"):
                delta=int(line[3:])-pc
                if delta%4 or not -(1<<27)<=delta<(1<<27):raise ValueError("Island return out of range")
                prepared.append(f".word {0x14000000|((delta>>2)&0x3ffffff)}")
            else:prepared.append(line)
            if not line.endswith(":"):pc+=4
        encoded,_=ks.asm(";\n".join(prepared),addr=address)
        body=bytes(encoded)
        if not body or len(body)>4096:raise ValueError("Unbounded probe body")
        functions[name]={"vm":address,"bytes":len(body),"assembly":lines}
        code+=body
    if len(code)>TEXT_BYTES:raise ValueError("Probe text exceeds RX segment")
    return bytes(code).ljust(TEXT_BYTES,b"\0"),functions
