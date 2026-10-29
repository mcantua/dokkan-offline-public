(function(root, factory) {
  if (typeof module === "object" && module.exports) module.exports = factory();
  else root.ForgeCpk = factory();
})(typeof globalThis !== "undefined" ? globalThis : this, function() {
  "use strict";
  const ALIGN = 2048, MAX_FILES = 5e3, MAX_BYTES = 512 * 1024 * 1024, encoder = new TextEncoder(), widths = { 2: 2, 4: 4, 6: 8, 10: 4 };
  const headerColumns = [["ContentOffset", 6], ["ContentSize", 6], ["TocOffset", 6], ["TocSize", 6], ["Files", 4], ["Version", 2], ["Revision", 2], ["Align", 2], ["Sorted", 2], ["EnableFileName", 2], ["EID", 2], ["CpkMode", 4], ["Tvers", 10], ["EnabledPackedSize", 6], ["EnabledDataSize", 6]], tocColumns = [["DirName", 10], ["FileName", 10], ["FileSize", 4], ["ExtractSize", 4], ["FileOffset", 6], ["ID", 4], ["UserString", 10]];
  function fail(message) {
    throw new Error("CPK: " + message);
  }
  function align(n, a = ALIGN) {
    return Math.ceil(n / a) * a;
  }
  function safe(path) {
    return typeof path === "string" && path.length > 0 && path.length <= 500 && !path.startsWith("/") && !/[\\:\x00-\x1f\x7f%]/.test(path) && path.split("/").every((p) => p && p !== "." && p !== ".." && !p.startsWith(".")) && !/\.(?:db|sqlite|sqlite3)(?:[-.].*)?$/i.test(path);
  }
  function compare(a, b) {
    const x = encoder.encode(a.path), y = encoder.encode(b.path);
    for (let i = 0; i < Math.min(x.length, y.length); i++) if (x[i] !== y[i]) return x[i] - y[i];
    return x.length - y.length;
  }
  function utf(name, columns, rows) {
    var _a, _b, _c;
    const strings = [new Uint8Array(1)], offsets = /* @__PURE__ */ new Map([["", 0]]);
    let stringSize = 1;
    function text(value) {
      value = String(value);
      if (!offsets.has(value)) {
        const b2 = encoder.encode(value);
        offsets.set(value, stringSize);
        stringSize += b2.length + 1;
        strings.push(b2, new Uint8Array(1));
      }
      return offsets.get(value);
    }
    const tableName = text(name), names = columns.map((c) => text(c[0]));
    for (const row of rows) for (const [column, type] of columns) if (type === 10) text((_a = row[column]) != null ? _a : "");
    const rowSize = columns.reduce((n, c) => n + widths[c[1]], 0), rowOffset = 32 + 5 * columns.length, stringOffset = rowOffset + rowSize * rows.length, dataOffset = stringOffset + stringSize, b = new Uint8Array(align(dataOffset, 8)), v = new DataView(b.buffer);
    b.set(encoder.encode("@UTF"));
    v.setUint32(4, b.length - 8);
    v.setUint32(8, rowOffset - 8);
    v.setUint32(12, stringOffset - 8);
    v.setUint32(16, dataOffset - 8);
    v.setUint32(20, tableName);
    v.setUint16(24, columns.length);
    v.setUint16(26, rowSize);
    v.setUint32(28, rows.length);
    let at = 32;
    columns.forEach(([_, type], i) => {
      b[at] = 80 | type;
      v.setUint32(at + 1, names[i]);
      at += 5;
    });
    for (const row of rows) for (const [column, type] of columns) {
      const value = type === 10 ? text((_b = row[column]) != null ? _b : "") : (_c = row[column]) != null ? _c : 0;
      if (type === 2) v.setUint16(at, value);
      else if (type === 6) v.setBigUint64(at, BigInt(value));
      else v.setUint32(at, value);
      at += widths[type];
    }
    at = stringOffset;
    for (const part of strings) {
      b.set(part, at);
      at += part.length;
    }
    return b;
  }
  function packet(magic, table) {
    const b = new Uint8Array(16 + table.length), v = new DataView(b.buffer);
    b.set(encoder.encode(magic));
    v.setUint32(4, 255, true);
    v.setBigUint64(8, BigInt(table.length), true);
    b.set(table, 16);
    return b;
  }
  function layout(input) {
    if (!Array.isArray(input) || !input.length || input.length > MAX_FILES) fail("Choose 1 to " + MAX_FILES + " files for an archive.");
    const seen = /* @__PURE__ */ new Set(), entries = input.map((item) => {
      if (!safe(item.path)) fail("Unsafe archive filename.");
      const path = item.path.normalize("NFC"), normalized = path.toLowerCase();
      if (seen.has(normalized)) fail("Conflicting archive filenames.");
      seen.add(normalized);
      if (!Number.isSafeInteger(item.size) || item.size < 0 || item.size > MAX_BYTES) fail("Invalid archive file size.");
      return { path, size: item.size };
    }).sort(compare);
    const rows = entries.map((e, i) => {
      const split = e.path.lastIndexOf("/");
      return { DirName: split < 0 ? "" : e.path.slice(0, split), FileName: e.path.slice(split + 1), FileSize: e.size, ExtractSize: e.size, FileOffset: 0, ID: i, UserString: "" };
    }), tocOffset = ALIGN, preliminary = packet("TOC ", utf("CpkTocInfo", tocColumns, rows)), contentOffset = align(tocOffset + preliminary.length);
    let position = contentOffset, totalData = 0;
    entries.forEach((e, i) => {
      e.offset = position;
      rows[i].FileOffset = position - tocOffset;
      position = align(position + e.size);
      totalData += e.size;
      if (position > MAX_BYTES) fail("Archive exceeds the 512 MB limit.");
    });
    const totalBytes = position, toc = packet("TOC ", utf("CpkTocInfo", tocColumns, rows)), table = utf("CpkHeader", headerColumns, [{ ContentOffset: contentOffset, ContentSize: totalBytes - contentOffset, TocOffset: tocOffset, TocSize: toc.length, Files: entries.length, Version: 7, Revision: 14, Align: ALIGN, Sorted: 1, EnableFileName: 1, EID: 0, CpkMode: 1, Tvers: "Dokkan Unit Creator", EnabledPackedSize: totalData, EnabledDataSize: totalData }]), cpk = packet("CPK ", table);
    if (cpk.length > ALIGN) fail("Archive header exceeds the native 2048-byte limit.");
    const header = new Uint8Array(contentOffset);
    header.set(cpk);
    header.set(toc, tocOffset);
    return { header, entries, totalBytes, contentOffset, tocOffset };
  }
  function encode(input) {
    const entries = input.map((e) => ({ ...e, data: e.data instanceof Uint8Array ? e.data : new Uint8Array(e.data || []) })), result = layout(entries.map((e) => ({ path: e.path, size: e.data.length }))), bytes = new Uint8Array(result.totalBytes), byPath = new Map(entries.map((e) => [e.path.normalize("NFC"), e.data]));
    bytes.set(result.header);
    for (const entry of result.entries) bytes.set(byPath.get(entry.path), entry.offset);
    return bytes;
  }
  return { layout, encode, safe, ALIGN, MAX_FILES, MAX_BYTES };
});
