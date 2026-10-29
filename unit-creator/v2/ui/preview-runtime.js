(function(root, factory) {
  "use strict";
  const api = factory();
  if (typeof module === "object" && module.exports) module.exports = api;
  else root.ForgePreviewRuntime = api;
})(typeof window === "object" ? window : globalThis, function() {
  "use strict";
  const expected = Object.freeze({ signedHigh: -2147483648, signedMax: -1, unsignedHigh: 2147483648, unsignedMax: 4294967295, complementMax: 0, signedToUnsigned: 4294967295 });
  function observe() {
    try {
      const v = JSON.parse("[2147483648,4294967295,-1]");
      return { signedHigh: v[0] | 0, signedMax: v[1] | 0, unsignedHigh: v[0] >>> 0, unsignedMax: v[1] >>> 0, complementMax: ~v[1], signedToUnsigned: v[2] >>> 0 };
    } catch {
      return null;
    }
  }
  function healthy(sample = observe()) {
    return !!sample && Object.keys(expected).every((key) => Object.prototype.hasOwnProperty.call(sample, key) && sample[key] === expected[key]);
  }
  return Object.freeze({ observe, healthy });
});
