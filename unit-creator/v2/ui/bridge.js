(function() {
  "use strict";
  let seq = 0;
  const pending = /* @__PURE__ */ new Map();
  window.__forgeReply = (message) => {
    const item = pending.get(message.id);
    if (!item) return;
    pending.delete(message.id);
    message.ok ? item.resolve(message.result) : item.reject(new Error(message.error || "Operation failed"));
  };
  window.Native = { canConvertOnline: () => {
    var _a, _b;
    return !((_b = (_a = window.webkit) == null ? void 0 : _a.messageHandlers) == null ? void 0 : _b.ForgeIOS);
  }, call: async (method, args = {}) => {
    var _a, _b;
    if (window.forgeNative) return window.forgeNative.call(method, args);
    if ((_b = (_a = window.webkit) == null ? void 0 : _a.messageHandlers) == null ? void 0 : _b.ForgeIOS) return new Promise((resolve, reject) => {
      const id = ++seq;
      pending.set(id, { resolve, reject });
      window.webkit.messageHandlers.ForgeIOS.postMessage(JSON.stringify({ id, method, args }));
    });
    if (window.ForgeAndroid) return new Promise((resolve, reject) => {
      const id = ++seq;
      pending.set(id, { resolve, reject });
      const raw = JSON.stringify({ id, method, args });
      if (raw.length > 24e3 && typeof window.ForgeAndroid.postMessageChunk === "function") {
        const chunks = [];
        for (let start = 0; start < raw.length; ) {
          let end = Math.min(start + 24e3, raw.length);
          const last = raw.charCodeAt(end - 1);
          if (end < raw.length && last >= 55296 && last <= 56319) end--;
          chunks.push(raw.slice(start, end));
          start = end;
        }
        for (let i = 0; i < chunks.length; i++) window.ForgeAndroid.postMessageChunk(id, i, chunks.length, chunks[i]);
      } else window.ForgeAndroid.postMessage(raw);
    });
    if (window.forgeTestBridge) return window.forgeTestBridge(method, args);
    throw new Error("This screen must run inside the Android or desktop app.");
  } };
})();
