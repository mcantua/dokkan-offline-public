"use strict";
// Fewer buttons on repeated rows. Each animated move in the card builder shows "▶ Watch" and
// "Change…"; Change opens a short list of the ways to change that animation (the original
// buttons, relabelled in plain words). Nothing is removed: the list runs the same actions.
window.ForgeSimplify = (() => {
  const PLAIN = [
    [/^Choose$|another character.?s (Active Skill )?animation|^Choose another/i, "🎭 Use another character’s animation"],
    [/^Combine \/ edit/i, "✂ Edit it in the animation editor"],
    [/^My animations$/i, "📁 Use one of my saved animations"],
    [/Replace with an existing game attack/i, "🔁 Swap for a different game attack (its whole move)"]
  ];
  let sheet = null;
  function plain(text) {
    for (const [pattern, label] of PLAIN) if (pattern.test(text.trim())) return label;
    return text.trim();
  }
  function open(title, buttons) {
    if (!sheet) {
      sheet = document.createElement("dialog");
      sheet.className = "shell-sheet simplify-sheet";
      sheet.addEventListener("click", (e) => { if (e.target === sheet) sheet.close(); });
      document.body.append(sheet);
    }
    sheet.innerHTML = '<div class="sheet-head"><h2></h2><button type="button" class="icon-button" data-close aria-label="Close">×</button></div><p class="hint">Choose how to change this animation.</p><div class="simplify-list"></div>';
    sheet.querySelector("h2").textContent = title;
    sheet.querySelector("[data-close]").onclick = () => sheet.close();
    const list = sheet.querySelector(".simplify-list");
    for (const original of buttons) {
      const b = document.createElement("button");
      b.type = "button";
      b.className = "button ghost simplify-choice";
      b.textContent = plain(original.textContent);
      b.disabled = original.disabled;
      b.onclick = () => { sheet.close(); original.click(); };
      list.append(b);
    }
    if (!sheet.open) sheet.showModal();
  }
  function tidy(row) {
    if (row.dataset.simplified === "1") return;
    const buttons = [...row.querySelectorAll("button")];
    if (buttons.length < 3) return;
    row.dataset.simplified = "1";
    const watch = buttons.find((b) => /^Preview$/i.test(b.textContent.trim()));
    const others = buttons.filter((b) => b !== watch);
    if (watch) { watch.textContent = "▶ Watch"; watch.classList.add("simplify-watch"); }
    others.forEach((b) => b.classList.add("simplify-hidden"));
    const change = document.createElement("button");
    change.type = "button";
    change.className = "button ghost small simplify-change";
    change.textContent = "Change…";
    const title = (row.querySelector("span")?.textContent || "Animation").replace(/^🎬\s*/, "");
    change.onclick = () => open(title, others.filter((b) => b.isConnected));
    (watch || others[others.length - 1]).after(change);
  }
  function scan(root = document) { root.querySelectorAll?.(".bld-anim").forEach(tidy); }
  let queued = false;
  new MutationObserver(() => { if (!queued) { queued = true; requestAnimationFrame(() => { queued = false; scan(); }); } }).observe(document.body, { childList: true, subtree: true });
  scan();
  return { scan };
})();
