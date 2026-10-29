(function(root) {
  "use strict";
  const supports = (path) => typeof path === "string" && /^ab_script\/(training|awaken)\/a[0-9]{4}\.lua$/.test(path);
  async function preview(entry, source, options = {}) {
    if (!supports(source == null ? void 0 : source.path)) throw Error("Choose a training or awakening scene.");
    const mode = source.path.includes("/awaken/") ? "awakening" : "training", table = mode === "training" ? "training_items" : "awakening_items";
    const records = await Native.call("query", { table, limit: 5e3 });
    const rows = records.filter((x) => Number.isSafeInteger(x.id) && x.id > 0 && Number.isInteger(x.rarity) && x.rarity >= 0 && x.rarity <= 4).sort((a, b) => String(a.name).localeCompare(String(b.name)) || a.id - b.id);
    if (!rows.length) throw Error("The active game database has no supported items for this scene. Import a complete game database and try again.");
    const dialog = document.createElement("dialog");
    dialog.style.cssText = "max-width:680px;width:calc(100% - 32px);max-height:90vh;overflow:auto;border:1px solid #45606d;border-radius:14px;background:#11212c;color:#edf5f8;padding:22px";
    const heading = document.createElement("h2");
    heading.id = "forge-item-scene-title";
    heading.textContent = mode === "training" ? "Choose training items" : "Choose awakening medals";
    dialog.setAttribute("aria-labelledby", heading.id);
    dialog.append(heading);
    const help = document.createElement("p");
    help.textContent = "Choose up to five item types. Each selected item appears in the real game animation. Choose no items to see the scene’s empty-item branch. This is a screen animation; it cannot be assigned to a battle move.";
    dialog.append(help);
    const label = document.createElement("label");
    label.className = "field";
    label.textContent = "Find an item by name";
    const search = document.createElement("input");
    search.type = "search";
    search.placeholder = mode === "training" ? "Try Turtle or Sword" : "Try Gregory or Elder Kai";
    label.append(search);
    dialog.append(label);
    const count = document.createElement("p");
    count.setAttribute("role", "status");
    count.setAttribute("aria-live", "polite");
    dialog.append(count);
    const chosen = document.createElement("div");
    dialog.append(chosen);
    const list = document.createElement("div");
    list.style.cssText = "display:grid;gap:8px;margin:12px 0";
    dialog.append(list);
    const pages = document.createElement("div");
    pages.className = "row";
    dialog.append(pages);
    const actions = document.createElement("div");
    actions.className = "row";
    actions.style.marginTop = "18px";
    dialog.append(actions);
    const button = (parent, text, fn) => {
      const b = document.createElement("button");
      b.type = "button";
      b.className = "button ghost";
      b.textContent = text;
      b.onclick = fn;
      parent.append(b);
      return b;
    };
    const selected = /* @__PURE__ */ new Map();
    let offset = 0;
    const size = 30;
    const render = () => {
      var _a, _b;
      const focusKey = (_a = document.activeElement) == null ? void 0 : _a.dataset.trainingItem;
      const query = search.value.trim().toLocaleLowerCase(), matched = rows.filter((x) => String(x.name).toLocaleLowerCase().includes(query));
      if (offset >= matched.length) offset = 0;
      count.textContent = selected.size + " of 5 item types selected · " + matched.length + " matching items";
      chosen.textContent = "";
      if (selected.size) {
        const title = document.createElement("p");
        title.textContent = "Selected items, in animation order:";
        chosen.append(title);
        for (const [id, item] of selected) button(chosen, item.name + " · Remove", () => {
          selected.delete(id);
          render();
        });
      }
      list.textContent = "";
      for (const item of matched.slice(offset, offset + size)) {
        const row = document.createElement("label");
        row.style.cssText = "display:flex;align-items:center;gap:12px;padding:10px;border:1px solid #36515b;border-radius:8px";
        const check = document.createElement("input");
        check.type = "checkbox";
        check.dataset.trainingItem = String(item.id);
        check.checked = selected.has(item.id);
        check.disabled = !check.checked && selected.size === 5;
        const text = document.createElement("span");
        text.textContent = item.name;
        row.append(check, text);
        check.onchange = () => {
          check.checked ? selected.set(item.id, item) : selected.delete(item.id);
          render();
        };
        list.append(row);
      }
      pages.textContent = "";
      if (offset) button(pages, "Previous items", () => {
        offset -= size;
        render();
      });
      if (offset + size < matched.length) button(pages, "More items", () => {
        offset += size;
        render();
      });
      if (focusKey) (_b = list.querySelector('[data-training-item="' + focusKey + '"]')) == null ? void 0 : _b.focus();
    };
    const selectedItems = await new Promise((resolve) => {
      button(actions, "Open animation", () => {
        const result = [...selected.values()].map((x) => ({ id: x.id, rarity: x.rarity }));
        dialog.close();
        resolve(result);
      });
      button(actions, "Cancel", () => {
        dialog.close();
        resolve(null);
      });
      dialog.addEventListener("cancel", () => resolve(null), { once: true });
      dialog.addEventListener("close", () => resolve(null), { once: true });
      search.oninput = () => {
        offset = 0;
        render();
      };
      render();
      document.body.append(dialog);
      dialog.showModal();
      search.focus();
    });
    dialog.remove();
    if (selectedItems === null) return null;
    return Native.call("previewAnimation", { mode, path: source.path, text: source.text, name: source.label || entry.moveName || "Item scene", attackerId: options.attackerId || entry.unitId || 1000010, trainingItems: selectedItems });
  }
  root.ForgeTrainingPicker = { supports, preview };
})(typeof window === "object" ? window : globalThis);
