(() => {
  "use strict";
  var _a, _b;
  if (location.protocol !== "https:" || location.hostname !== "dokkan-eclipse.com") return;
  const patch = window.__forgePatch;
  if (!patch) return;
  const fields = { patchName: patch.name, description: patch.description, version: patch.version, uuid: patch.uuid, authors: patch.author };
  for (const [name, value] of Object.entries(fields)) {
    const input = document.querySelector('#convert-eclp-form [name="' + name + '"]');
    if (input) {
      input.value = value || "";
      input.dispatchEvent(new Event("input", { bubbles: true }));
    }
  }
  (_a = document.getElementById("forge-converter-help")) == null ? void 0 : _a.remove();
  const box = document.createElement("section");
  box.id = "forge-converter-help";
  Object.assign(box.style, { position: "sticky", top: "0", zIndex: "99999", background: "#152329", color: "#fff", padding: "16px", font: "14px/1.5 system-ui", borderBottom: "2px solid #52d5bb" });
  const title = document.createElement("strong");
  title.textContent = "Dokkan Unit Creator: " + patch.name;
  box.append(title);
  const detail = document.createElement("p");
  detail.style.margin = "6px 0";
  const file = document.getElementById("convert-file");
  const update = () => {
    var _a2;
    detail.textContent = ((_a2 = file == null ? void 0 : file.files) == null ? void 0 : _a2.length) ? "Your patch ZIP is attached. Sign in if needed, choose Convert Zip to ECLP, then use the download link to save your ECLP." : "Your patch ZIP is prepared. Sign in if needed, return to the converter, and choose the patch file. Then convert and download your ECLP.";
  };
  update();
  file == null ? void 0 : file.addEventListener("change", update);
  box.append(detail);
  for (const [label, url] of [["Sign in to Eclipse", "https://dokkan-eclipse.com/account"], ["Return to converter", "https://dokkan-eclipse.com/#convert-eclp"]]) {
    const link = document.createElement("a");
    link.href = url;
    link.textContent = label;
    Object.assign(link.style, { color: "#7ce8d1", marginRight: "20px" });
    box.append(link);
  }
  document.body.prepend(box);
  if (file) (_b = document.getElementById("convert-eclp")) == null ? void 0 : _b.scrollIntoView({ block: "start" });
})();
