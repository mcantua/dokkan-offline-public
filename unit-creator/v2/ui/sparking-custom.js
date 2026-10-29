"use strict";
// Sparking's server hosts its own custom-made content AND copies of the original game files. Only the
// custom-made files are downloaded from Sparking; originals come from Eclipse (same files, shared by
// every unit, cached once). Same rule as the Android download pack (SparkingCustom.java):
// the part of the path that carries an ID (character, effect, stage, card…) is looked up in Eclipse's
// file list for that folder. Sparking packs folders as .cpk; Eclipse serves them unpacked.
window.ForgeSparkingCustom = (() => {
  const listings = new Map();
  const stem = (n) => String(n || "").replace(/\.[A-Za-z0-9]+$/, "");
  function idPart(path) {
    const parts = path.split("/");
    for (let i = 1; i < parts.length; i++) if (/\d/.test(parts[i])) return [parts.slice(0, i).join("/"), stem(parts[i])];
    return [parts.slice(0, -1).join("/"), stem(parts[parts.length - 1])];
  }
  function listing(folder) {
    if (!listings.has(folder)) {
      listings.set(folder, Native.call("browseAssets", { path: folder }).then((d) => d && Array.isArray(d.items) ? d.items : []).catch((e) => {
        if (/\b404\b|not found/i.test(String(e && e.message))) return [];   // Eclipse has no such folder
        listings.delete(folder);
        throw e;
      }));
    }
    return listings.get(folder);
  }
  // true: Eclipse has the original (don't download it from Sparking)
  async function isOriginal(path) {
    if (/^Custom\//.test(path)) return false;
    const [folder, name] = idPart(path);
    return (await listing(folder)).some((item) => stem(item.name) === name);
  }
  // every Eclipse file behind an original path (a .cpk is a folder on Eclipse)
  async function eclipseFiles(path, depth = 0) {
    if (!/\.cpk$/i.test(path)) return [path];
    const out = [], walk = async (folder, d) => {
      if (d > 4 || out.length > 400) return;
      for (const item of await listing(folder)) {
        const p = item.path || folder + "/" + item.name;
        if (item.type === "directory") await walk(p, d + 1);
        else if (/\.(png|jpe?g|webp|lwf|json|atlas|plist|usm|acb|awb|txt|bytes|tmx)$/i.test(p)) out.push(p);
      }
    };
    await walk(path.replace(/\.cpk$/i, ""), depth);
    return out;
  }
  // saves Eclipse's copies where previews look for game files (shared "eclipse" collection)
  async function fetchOriginal(path) {
    const files = await eclipseFiles(path), saved = [];
    if (!files.length) throw Error("Eclipse has no files for " + path);
    for (const file of files) saved.push(await Native.call("downloadAsset", { path: file }));
    return saved;
  }
  return { isOriginal, fetchOriginal, idPart, eclipseFiles };
})();
