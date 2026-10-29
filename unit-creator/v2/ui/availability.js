(function(root, factory) {
  const api = factory(root.FORGE_ANIMATION_AVAILABILITY || {});
  if (typeof module === "object" && module.exports) module.exports = api;
  else root.ForgeAvailability = api;
})(typeof window === "object" ? window : globalThis, function(data) {
  "use strict";
  function issue(path, script) {
    var _a;
    if (path && ((_a = data.paths) == null ? void 0 : _a[path])) return data.paths[path];
    if (!script) return null;
    const name = String(script).replace(/\.lua$/, "") + ".lua";
    const found = Object.keys(data.paths || {}).find((p) => p.startsWith("ab_script/") && p.split("/").pop() === name);
    return found ? data.paths[found] : null;
  }
  function preferred(script) {
    var _a, _b;
    return ((_b = (_a = data.warnings) == null ? void 0 : _a[String(script).replace(/\.lua$/, "")]) == null ? void 0 : _b.preferredPath) || null;
  }
  function message(path, script) {
    const item = issue(path, script);
    return (item == null ? void 0 : item.message) || "";
  }
  return { issue, preferred, message, coverageVersion: data.coverageVersion || "" };
});
