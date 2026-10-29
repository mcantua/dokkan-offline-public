(function(root, factory) {
  const api = factory();
  if (typeof module === "object" && module.exports) module.exports = api;
  else root.ForgeSourceRepairs = api;
})(typeof window === "object" ? window : globalThis, function() {
  "use strict";
  const definition = Object.freeze({ id: "sp1237-dodge-timing-v1", path: "ab_script/attack_sp/sp1237.lua", label: "Repair dodge timing", description: "Create a corrected copy using the preparation timing already present later in the original animation. The original file stays unchanged.", sourceSHA256: "246ccde576f1093b0bfdf30895526a2c53e5b7f787d45e17c9cae0a4856f63c6", lfSHA256: "e644f74c505bb3f0928bc080bca9622982219b00f7be5d92364766f565efef5e" });
  const digest = async (text) => {
    var _a;
    if (!((_a = globalThis.crypto) == null ? void 0 : _a.subtle)) throw Error("This device cannot verify an animation repair. Update the app or browser.");
    return [...new Uint8Array(await globalThis.crypto.subtle.digest("SHA-256", new TextEncoder().encode(text)))].map((x) => x.toString(16).padStart(2, "0")).join("");
  };
  function candidate(source) {
    return !!source && source.path === definition.path && typeof source.text === "string" && source.text.length <= 2 * 1024 * 1024 && !source.repair;
  }
  async function inspect(source) {
    if (!candidate(source)) return null;
    const sha = await digest(source.text);
    if (sha !== definition.sourceSHA256 && sha !== definition.lfSHA256) return null;
    return { ...definition, sourceSHA256: sha, representation: sha === definition.sourceSHA256 ? "original-crlf" : "exact-lf-normalization" };
  }
  async function apply(source, id) {
    if (id !== definition.id) throw Error("Choose a supported animation repair.");
    const found = await inspect(source);
    if (!found) throw Error("This animation differs from the verified original. Its timing was not changed.");
    const newline = found.representation === "original-crlf" ? "\r\n" : "\n", anchor = "if(_IS_DODGE_ == 1) then" + newline + newline, assignment = "spep_2=spep_1+400;";
    if (source.text.split(anchor).length !== 3 || source.text.split(assignment).length !== 3) throw Error("The original animation structure has changed. No repair was applied.");
    const repairLine = "spep_2 = spep_1 + 400; -- Dokkan Unit Creator repair: original later preparation timing." + newline;
    const text = source.text.split(anchor).join(anchor + repairLine), repair = { id: definition.id, label: definition.label, originalSHA256: found.sourceSHA256, repairedSHA256: await digest(text), representation: found.representation, method: "Copy the original normal-branch spep_2=spep_1+400 assignment into each existing Dodge branch before its first use; normal/hit branches are unchanged.", authoredCopy: true };
    return { ...source, text, repair, originalSource: { path: source.path, text: source.text, sha256: found.sourceSHA256 } };
  }
  async function restore(source) {
    var _a;
    if (((_a = source == null ? void 0 : source.repair) == null ? void 0 : _a.id) !== definition.id || !source.originalSource || typeof source.originalSource.text !== "string") throw Error("The original animation copy is unavailable.");
    const original = source.originalSource, checked = await inspect({ path: original.path, text: original.text });
    if (!checked || checked.sourceSHA256 !== original.sha256 || checked.sourceSHA256 !== source.repair.originalSHA256) throw Error("The saved original animation has changed. Restore was not applied.");
    const next = { ...source, text: original.text };
    delete next.repair;
    delete next.originalSource;
    return next;
  }
  return { candidate, inspect, apply, restore, definition };
});
