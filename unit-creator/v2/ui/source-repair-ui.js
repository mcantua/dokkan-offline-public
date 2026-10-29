(function(root) {
  "use strict";
  const supports = (value) => (typeof value === "string" ? value : value == null ? void 0 : value.path) === "ab_script/attack_sp/sp1237.lua";
  async function open(source, { onPreview, onAdd } = {}) {
    var _a;
    const definition = await ForgeSourceRepairs.inspect(source);
    if (!definition) throw Error("This animation differs from the verified original. A corrected copy is not available for this version.");
    const previous = document.getElementById("forge-source-repair-dialog");
    if (previous) previous.close();
    const modal = document.createElement("dialog");
    modal.id = "forge-source-repair-dialog";
    modal.setAttribute("aria-labelledby", "forge-source-repair-title");
    modal.style.cssText = "max-width:620px;width:calc(100% - 32px);max-height:90vh;overflow:auto;border:1px solid #45606d;border-radius:14px;background:#11212c;color:#edf5f8;padding:22px";
    const heading = document.createElement("h2");
    heading.id = "forge-source-repair-title";
    heading.textContent = "Repair dodge timing";
    modal.append(heading);
    const name = document.createElement("p");
    name.textContent = source.label || "Selected animation";
    modal.append(name);
    const explanation = document.createElement("p");
    explanation.textContent = "The original animation has a timing error in its dodge scene. Create a corrected copy using the preparation timing already present later in that animation.";
    modal.append(explanation);
    const note = document.createElement("p");
    note.className = "hint";
    note.textContent = "Normal attacks keep their original timing. Your corrected section includes the original copy so you can restore it later.";
    modal.append(note);
    const status = document.createElement("p");
    status.setAttribute("role", "status");
    status.setAttribute("aria-live", "polite");
    modal.append(status);
    const error = document.createElement("p");
    error.setAttribute("role", "alert");
    modal.append(error);
    const actions = document.createElement("div");
    actions.className = "row";
    actions.style.cssText = "display:flex;flex-wrap:wrap;gap:10px";
    modal.append(actions);
    let active = false, closed = false, fixed = null;
    const controls = [];
    const button = (text, callback) => {
      const b = document.createElement("button");
      b.type = "button";
      b.className = "button ghost";
      b.textContent = text;
      b.onclick = callback;
      actions.append(b);
      controls.push(b);
      return b;
    };
    async function perform(callback, closeAfter) {
      if (active || closed) return;
      active = true;
      error.textContent = "";
      status.textContent = "Checking the original and creating your corrected copy…";
      controls.forEach((b) => b.disabled = true);
      try {
        if (!fixed) fixed = await ForgeSourceRepairs.apply(source, definition.id);
        if (closed) return;
        await callback(fixed);
        if (closeAfter) modal.close();
        else if (!closed) status.textContent = "Corrected preview opened. You can add this copy as a section when you are ready.";
      } catch (e) {
        if (!closed) {
          status.textContent = "";
          error.textContent = e.message || "The corrected copy could not be opened.";
        }
      } finally {
        active = false;
        if (!closed) controls.forEach((b) => b.disabled = false);
      }
    }
    if (typeof onPreview === "function") button("Preview corrected copy", () => {
      void perform(onPreview, false);
    });
    if (typeof onAdd === "function") button("Add corrected section", () => {
      void perform(onAdd, true);
    });
    button("Keep original", () => modal.close());
    modal.addEventListener("close", () => {
      closed = true;
      modal.remove();
    }, { once: true });
    document.body.append(modal);
    modal.showModal();
    (_a = controls[0]) == null ? void 0 : _a.focus();
    return modal;
  }
  root.ForgeSourceRepairUI = { supports, open };
})(typeof window === "object" ? window : globalThis);
