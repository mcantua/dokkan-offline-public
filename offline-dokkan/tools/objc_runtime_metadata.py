#!/usr/bin/env python3
"""Bounded static ObjC ABI inspection; never executes or modifies a client.

Output is restricted to reviewed class/selector/ivar names and type encodings.
Supports thin little-endian arm64 and dyld PTR_64/PTR_64_OFFSET chains only.
Unknown formats, encrypted input and pointers into binds fail closed.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct

MAX_FILE = 512 * 1024 * 1024
MAX_FIXUPS = 1000000
CLASSES = frozenset(("HttpAsynConnection", "AppController", "AppDelegate",
    "RootViewController", "Cocos2dxViewController", "Cocos2dxAppController",
    "CCEAGLView", "Cocos2dxGLView", "EAGLView", "ViewController",
    "LocalResponseHandler"))
SELECTORS = frozenset(("init", "dealloc", "startRequest:", "responseData",
    "responseCode", "responseHeaders", "request", "cancel",
    "connectionDidFinishLoading:", "connection:didReceiveResponse:",
    "connection:didReceiveData:", "connection:didFailWithError:",
    "application:didFinishLaunchingWithOptions:", "applicationDidBecomeActive:",
    "application:configurationForConnectingSceneSession:options:",
    "applicationDidEnterBackground:", "applicationWillResignActive:",
    "applicationWillTerminate:", "applicationWillEnterForeground:",
    "viewDidLoad", "viewWillLayoutSubviews", "viewDidLayoutSubviews",
    "viewWillTransitionToSize:withTransitionCoordinator:", "shouldAutorotate",
    "supportedInterfaceOrientations", "preferredInterfaceOrientationForPresentation",
    "viewWillAppear:", "viewDidAppear:", "layoutSubviews", "setFrame:",
    "initWithFrame:", "layerClass", "swapBuffers", "drawView", "setResponseData:", "setResponseCode:",
    "setResponseHeaders:", "setRequest:", "handleRequest:",
    "responseHeader", "setResponseHeader:", "statusString", "setStatusString:",
    "handleRequest:completion:", "handleRequest:completionHandler:",
    "handleAnnouncementsWithOriginal:parsedRequest:",
    "handleEventsWithOriginal:parsedRequest:", "handleMyDataWithOriginal:parsedRequest:",
    "handlePingWithOriginal:", "handleQuestStartWithOriginal:parsedRequest:",
    "handleQuestsBriefingWithOriginal:parsedRequest:",
    "handleResponseForParsedRequest:originalData:statusCode:error:"))
IVARS = frozenset(("_responseData", "_responseCode", "_responseHeaders",
    "_request", "_response", "responseData", "responseCode", "responseHeaders",
    "request", "response", "_connection", "connection", "_delegate", "delegate",
    "_window", "window", "_viewController", "viewController", "_httpRequest",
    "httpRequest", "responseHeader", "_responseHeader", "statusString", "_statusString"))


class Image:
    def __init__(self, data):
        self.data, self.segments, self.sections, self.rebases = data, [], {}, {}
        self.binds, self.chain_formats = set(), set()
        if len(data) < 32 or len(data) > MAX_FILE:
            raise ValueError("Invalid bounded file")
        if self.unpack("I", 0)[0] != 0xfeedfacf or self.unpack("I", 4)[0] != 0x100000c:
            raise ValueError("Only thin little-endian arm64 is supported")
        count, amount = self.unpack("II", 16)
        if count > 8192 or amount > 4 * 1024 * 1024 or 32 + amount > len(data):
            raise ValueError("Invalid commands")
        pos, chains = 32, None
        for _ in range(count):
            cmd, length = self.unpack("II", pos)
            if length < 8 or length % 8 or pos + length > 32 + amount:
                raise ValueError("Invalid load command")
            if cmd == 0x19:
                vm, vmsize, off, size = self.unpack("QQQQ", pos + 24)
                sections = self.unpack("I", pos + 64)[0]
                if length != 72 + sections * 80 or off + size > len(data) or size > vmsize:
                    raise ValueError("Invalid segment")
                self.segments.append((vm, vmsize, off, size))
                for i in range(sections):
                    p = pos + 72 + i * 80
                    name = data[p:p + 16].split(b"\0", 1)[0]
                    address, n, section_offset = self.unpack("QQI", p + 32)
                    if name.startswith(b"__objc_"):
                        if name in self.sections:
                            raise ValueError("Duplicate ObjC section")
                        if (section_offset + n > len(data) or
                                section_offset != off + address - vm or
                                not vm <= address <= address + n <= vm + vmsize):
                            raise ValueError("Invalid ObjC section")
                        self.sections[name] = (address, n)
            elif cmd == 0x80000034:
                if chains is not None or length != 16:
                    raise ValueError("Invalid chained fixups")
                chains = self.unpack("II", pos + 8)
            elif cmd in (0x21, 0x2c):
                if length != (24 if cmd == 0x2c else 20) or self.unpack("I", pos + 16)[0]:
                    raise ValueError("Invalid or encrypted input is unsupported")
            pos += length
        if pos != 32 + amount:
            raise ValueError("Command size mismatch")
        bases = [vm for vm, _, off, size in self.segments if off == 0 and size]
        if len(bases) != 1:
            raise ValueError("Ambiguous image base")
        self.base = bases[0]
        if chains:
            self.chains(*chains)

    def unpack(self, fmt, offset):
        amount = struct.calcsize("<" + fmt)
        if offset < 0 or offset + amount > len(self.data):
            raise ValueError("Read outside image")
        return struct.unpack_from("<" + fmt, self.data, offset)

    def offset(self, address, amount=1):
        matches = [off + address - vm for vm, _, off, size in self.segments
                   if vm <= address and address + amount <= vm + size]
        if len(matches) != 1:
            raise ValueError("Unmapped or ambiguous VM address")
        return matches[0]

    def at(self, fmt, address):
        return self.unpack(fmt, self.offset(address, struct.calcsize("<" + fmt)))

    def pointer(self, address):
        if address in self.binds:
            raise ValueError("Selected metadata needs an unresolved external bind")
        return self.rebases.get(address, self.at("Q", address)[0])

    def string(self, address, limit=512):
        off = self.offset(address)
        # A terminator must lie in the same file-backed segment and within the limit.
        end = min(off + limit, next(o + n for vm, _, o, n in self.segments
                                   if vm <= address < vm + n))
        raw = self.data[off:end].split(b"\0", 1)
        if len(raw) != 2:
            raise ValueError("Unterminated metadata string")
        return raw[0].decode("ascii")

    def chains(self, offset, size):
        if size < 28 or size > 32 * 1024 * 1024 or offset + size > len(self.data):
            raise ValueError("Invalid fixup payload")
        version, starts, _, _, _, _, _ = self.unpack("7I", offset)
        if version != 0 or not 28 <= starts <= size - 4:
            raise ValueError("Unsupported chained fixup header")
        start = offset + starts
        count = self.unpack("I", start)[0]
        if count != len(self.segments) or start + 4 + count * 4 > offset + size:
            raise ValueError("Invalid chain segments")
        for index in range(count):
            rel = self.unpack("I", start + 4 + 4 * index)[0]
            if not rel:
                continue
            p = start + rel
            if p < start + 4 + count * 4 or p + 22 > offset + size:
                raise ValueError("Invalid chain starts")
            length, page_size, fmt, segment_offset, _, pages = self.unpack("IHHQIH", p)
            if (fmt not in (2, 6) or page_size not in (4096, 16384) or
                    length != 22 + pages * 2 or p + length > offset + size):
                raise ValueError("Unsupported chain segment format")
            self.chain_formats.add(fmt)
            vm, vmsize, _, _ = self.segments[index]
            if vm != self.base + segment_offset or pages * page_size > vmsize + page_size - 1:
                raise ValueError("Chain segment identity mismatch")
            for page in range(pages):
                first = self.unpack("H", p + 22 + page * 2)[0]
                if first == 0xffff:
                    continue
                if first & 0x8000 or first >= page_size:
                    raise ValueError("Unsupported multi-start chain")
                page_vm = vm + page * page_size
                location = page_vm + first
                while True:
                    if location + 8 > min(page_vm + page_size, vm + vmsize):
                        raise ValueError("Pointer outside chain page")
                    if location in self.rebases or location in self.binds or len(self.rebases) + len(self.binds) >= MAX_FIXUPS:
                        raise ValueError("Duplicate or excessive chain pointer")
                    value = self.at("Q", location)[0]
                    step = ((value >> 51) & 0xfff) * 4
                    if value >> 63:
                        self.binds.add(location)
                    else:
                        if (value >> 44) & 0x7f:
                            raise ValueError("Reserved rebase bits are nonzero")
                        target = (value & ((1 << 36) - 1)) | (((value >> 36) & 255) << 56)
                        self.rebases[location] = target + (self.base if fmt == 6 else 0)
                    if not step:
                        break
                    location += step

    def types(self, address):
        value = self.string(address)
        if not re.fullmatch(r'[0-9A-Za-z_@#:vBcCsSiIlLqQfd*^?\[\](){}=+\-" ]{1,511}', value):
            raise ValueError("Unexpected type encoding")
        return value

    def methods(self, address, kind):
        if not address:
            return []
        flags, count = self.at("II", address)
        relative = bool(flags & 0x80000000)
        direct = bool(flags & 0x40000000)
        stride = flags & 0xfffc
        if stride != (12 if relative else 24) or count > 65536:
            raise ValueError("Unsupported method list")
        self.offset(address, 8 + count * stride)
        result = []
        for index in range(count):
            p = address + 8 + index * stride
            if relative:
                name, types, _ = self.at("iii", p)
                selector_pointer = p + name
                name_address = selector_pointer if direct else self.pointer(selector_pointer)
                types_address = p + 4 + types
            else:
                name_address, types_address = self.pointer(p), self.pointer(p + 8)
            name = self.string(name_address)
            if name in SELECTORS:
                result.append({"selector": name, "kind": kind, "encoding": self.types(types_address)})
        return result

    def ivars(self, address):
        if not address:
            return []
        stride, count = self.at("II", address)
        if stride != 32 or count > 65536:
            raise ValueError("Unsupported ivar list")
        self.offset(address, 8 + stride * count)
        result = []
        for index in range(count):
            p = address + 8 + index * stride
            name = self.string(self.pointer(p + 8))
            if name in IVARS:
                offset = self.at("I", self.pointer(p))[0]
                alignment, size = self.at("II", p + 24)
                result.append({"name": name, "encoding": self.types(self.pointer(p + 16)),
                               "offset": offset, "bytes": size, "alignment_log2": alignment})
        return result

    def class_ro(self, address):
        # low three data-bits are runtime flags, never part of class_ro_t.
        return self.pointer(address + 32) & ~7

    def inspect(self):
        start, size = self.sections.get(b"__objc_classlist", (0, 0))
        if size % 8 or size > 8 * 65536:
            raise ValueError("Invalid class list")
        results = []
        for item in range(size // 8):
            address = self.pointer(start + item * 8)
            ro = self.class_ro(address)
            name = self.string(self.pointer(ro + 24))
            if name not in CLASSES:
                continue
            meta_ro = self.class_ro(self.pointer(address))
            results.append({"name": name,
                "methods": sorted(self.methods(self.pointer(ro + 32), "instance") +
                                  self.methods(self.pointer(meta_ro + 32), "class"),
                                  key=lambda m: (m["kind"], m["selector"])),
                "ivars": self.ivars(self.pointer(ro + 48))})
        return {"kind": "allowlisted-static-objc-abi", "sha256": hashlib.sha256(self.data).hexdigest(),
                "bytes": len(self.data), "pointer_formats": sorted(self.chain_formats),
                "resolved_rebase_count": len(self.rebases), "unresolved_bind_count": len(self.binds),
                "classes": sorted(results, key=lambda c: c["name"]),
                "method_behavior_verified": False, "runtime_execution_verified": False}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    try:
        if not 32 <= args.input.stat().st_size <= MAX_FILE or args.input.resolve() == args.out.resolve():
            raise ValueError("Invalid input")
        result = Image(args.input.read_bytes()).inspect()
        args.out.parent.mkdir(parents=True, exist_ok=True)
        with args.out.open("x") as stream:
            stream.write(json.dumps(result, indent=2) + "\n")
    except (OSError, ValueError, UnicodeError, struct.error):
        raise SystemExit("Static ObjC collection failed; unsupported/invalid input or existing output preserved.")
    print("Allowlisted static ObjC ABI written; runtime behavior remains unverified.")


if __name__ == "__main__":
    main()
