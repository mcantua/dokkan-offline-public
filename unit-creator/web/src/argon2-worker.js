/* Runs Argon2id off the main thread so the page stays smooth while an .eclp file is locked/unlocked. */
"use strict";
importScripts("argon2.js");
self.onmessage = (e) => {
  try {
    const key = self.ForgeArgon2.argon2id(new Uint8Array(e.data.pw), new Uint8Array(e.data.salt), {
      iterations: 3, memoryKiB: 65536, parallelism: 4, tagLength: 32,
      progress: (f) => self.postMessage({ progress: f }),
    });
    self.postMessage({ key: key.buffer }, [key.buffer]);
  } catch (err) {
    self.postMessage({ error: (err && err.message) || String(err) });
  }
};
