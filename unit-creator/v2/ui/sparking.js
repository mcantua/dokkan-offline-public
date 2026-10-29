(function(root) {
  "use strict";
  const typeNames = { AGL: "Agility", TEQ: "Technique", INT: "Intelligence", STR: "Strength", PHY: "Physical" };
  const escape = (value) => String(value != null ? value : "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
  function typeLabel(raw) {
    const value = String(raw || "").toUpperCase();
    let side = "", element = "";
    if (/^[SE](AGL|TEQ|INT|STR|PHY)$/.test(value)) {
      side = value[0];
      element = value.slice(1);
    } else if (/^(AGL|TEQ|INT|STR|PHY)-[SE]$/.test(value)) {
      element = value.slice(0, 3);
      side = value.slice(-1);
    } else element = value;
    return (side === "S" ? "Super · " : side === "E" ? "Extreme · " : "") + (typeNames[element] || element || "Unspecified");
  }
  function findCards(cards, query, rarity) {
    const q = String(query || "").trim().toLocaleLowerCase();
    return cards.filter((c) => {
      var _a, _b;
      return (!rarity || c.rarity === rarity) && [c.name, c.title, (_a = c.passive) == null ? void 0 : _a.name, (_b = c.superAttack) == null ? void 0 : _b.name, c.categories, c.links].join(" ").toLocaleLowerCase().includes(q);
    });
  }
  function validRevision(value) {
    return /^[1-9][0-9]{0,14}$/.test(String(value));
  }
  let cached;
  async function load() {
    if (!cached) cached = fetch("data/sparking-reference.json").then((r) => {
      if (!r.ok) throw new Error("The bundled Sparking reference catalogue could not be loaded.");
      return r.json();
    }).then((data) => {
      if (data.schema !== "dokkan-forge-sparking-reference-v1" || !Array.isArray(data.cards) || data.cards.some((c) => c.referenceOnly !== true)) throw new Error("The Sparking catalogue is incompatible.");
      return data;
    }).catch((e) => {
      cached = null;
      throw e;
    });
    return cached;
  }
  function textBlock(label, value) {
    return value ? '<section class="sparking-detail"><h3>' + escape(label) + '</h3><p class="sparking-description">' + escape(value) + "</p></section>" : "";
  }
  function showCard(card, data) {
    const move = (label, value) => (value == null ? void 0 : value.name) || (value == null ? void 0 : value.description) ? textBlock(label, (value.name ? value.name + "\n" : "") + (value.description || "") + (value.condition ? "\nWhen to use: " + value.condition : "")) : "";
    const stats = card.stats || {};
    const html = '<p class="chip teal">WIKI REFERENCE · NOT A PLAYABLE PATCH</p><p>' + escape(card.title) + " · " + escape(card.rarity) + " · " + escape(typeLabel(card.type)) + '</p><p class="hint">This is a community-written character description. It does not include the game’s executable skill logic or animation assets.</p><div class="summary-grid">' + [["Health", stats["hp max"]], ["Attack", stats["atk max"]], ["Defense", stats["def max"]]].map(([label, value]) => '<div class="summary-card"><div><strong class="summary-number">' + escape(value || "Not recorded") + "</strong><p>" + label + " at maximum level</p></div></div>").join("") + "</div>" + textBlock("Leader skill", card.leader) + move("Super Attack", card.superAttack) + move("Ultra Super Attack", card.ultraSuperAttack) + move("Passive skill", card.passive) + move("Active Skill", card.activeSkill) + textBlock("Link skills", card.links) + textBlock("Categories", card.categories) + textBlock("Availability described by the wiki", card.availability) + '<section class="panel"><h3>Source and attribution</h3><p>' + escape(data.attribution) + "</p><p>Text: Creative Commons Attribution-ShareAlike 4.0. This catalogue was adapted from " + escape(data.pagesInspected) + ' wiki pages; it is not a complete server database. No artwork is bundled.</p><p class="hint">Source: ' + escape(card.source.title) + "<br>Revision date: " + escape(card.source.revisionTimestamp) + '</p><div class="row"><button class="button ghost" id="sparking-open-source">Open original wiki revision</button><button class="button ghost" id="sparking-copy-source">Copy source and attribution</button><button class="button subtle" id="sparking-license">Read text license</button></div></section>';
    dialog(card.name, html);
    document.querySelector("#sparking-open-source").addEventListener("click", () => {
      if (!validRevision(card.source.revision)) return toast("This source revision is invalid.", true);
      Native.call("external", { target: "sparkingWiki", revision: String(card.source.revision) }).catch((e) => toast(e.message, true));
    });
    document.querySelector("#sparking-license").addEventListener("click", () => Native.call("external", { target: "sparkingLicense" }).catch((e) => toast(e.message, true)));
    document.querySelector("#sparking-copy-source").addEventListener("click", () => Native.call("copy", { text: card.source.permalink + "\nContributors: " + card.source.history + "\n" + data.attribution + "\n" + data.licenseUrl }).then(() => toast("Source and attribution copied.")).catch((e) => toast(e.message, true)));
  }
  function mountLibraryEntry(target) {
    if (!target) return;
    target.innerHTML = '<section class="panel"><p class="eyebrow">OPTIONAL COMMUNITY REFERENCES</p><h2>Sparking character guide</h2><p>Browse real custom-character descriptions published by the Sparking community wiki. These reference entries include stats and skill descriptions. Playable ECLP patches still require the original downloaded game data and supported assets.</p><button class="button ghost" data-sparking-browse>Browse Sparking references</button><div data-sparking-catalogue hidden></div></section>';
    const button = target.querySelector("[data-sparking-browse]"), area = target.querySelector("[data-sparking-catalogue]");
    button.addEventListener("click", async () => {
      if (!area.hidden) {
        area.hidden = true;
        button.textContent = "Browse Sparking references";
        return;
      }
      button.disabled = true;
      button.textContent = "Loading local reference guide…";
      try {
        let render = function() {
          const cards = findCards(data.cards, query, rarity), size = 24, pages = Math.max(1, Math.ceil(cards.length / size));
          page = Math.max(0, Math.min(page, pages - 1));
          const visible = cards.slice(page * size, (page + 1) * size);
          results.innerHTML = '<p class="hint" role="status" aria-live="polite" tabindex="-1" data-sparking-status>' + cards.length + " matching descriptions" + (cards.length ? " · Page " + (page + 1) + " of " + pages : "") + "</p>" + (visible.length ? '<div class="unit-grid">' + visible.map((c) => {
            var _a;
            return '<button class="unit-tile patch-tile" data-sparking-key="' + escape(c.key) + '"><div class="tile-body"><span class="chip teal">REFERENCE ONLY</span> <span class="chip">' + escape(c.rarity) + "</span><h3>" + escape(c.name) + "</h3><p>" + escape(c.title) + "</p><p>" + escape(typeLabel(c.type)) + "</p><p>" + escape(((_a = c.superAttack) == null ? void 0 : _a.name) || "Attack not recorded") + "</p></div></button>";
          }).join("") + "</div>" : "<p>No descriptions match your search.</p>") + (pages > 1 ? '<nav class="row" aria-label="Sparking reference pages"><button class="button ghost" data-sparking-prev' + (page === 0 ? " disabled" : "") + '>Previous page</button><button class="button ghost" data-sparking-next' + (page === pages - 1 ? " disabled" : "") + ">Next page</button></nav>" : "");
          results.querySelectorAll("[data-sparking-key]").forEach((b) => b.addEventListener("click", () => showCard(data.cards.find((c) => c.key === b.dataset.sparkingKey), data)));
          for (const [selector, delta] of [["[data-sparking-prev]", -1], ["[data-sparking-next]", 1]]) {
            const b = results.querySelector(selector);
            if (b) b.addEventListener("click", () => {
              page += delta;
              render();
              results.querySelector("[data-sparking-status]").focus();
            });
          }
        };
        const data = await load();
        if (!target.isConnected) return;
        let query = "", rarity = "", page = 0;
        area.hidden = false;
        button.textContent = "Hide Sparking references";
        area.innerHTML = '<p class="hint">' + data.cards.length + " character descriptions from " + data.pagesInspected + " public wiki pages. Reference text is available offline. Updated " + escape(data.retrievedAt.slice(0, 10)) + '. These are separate from your editable units and installed patches.</p><div class="source-controls"><label class="field">Find a character or skill<input data-sparking-search placeholder="Gomah, Scout, Gogeta…" type="search"></label><label class="field">Rarity<select data-sparking-rarity><option value="">All rarities</option><option>SSR</option><option>UR</option><option>LR</option></select></label></div><div data-sparking-results></div><p class="hint">' + escape(data.attribution) + " Text licensed under CC BY-SA 4.0. No images or native game data are included.</p>";
        const results = area.querySelector("[data-sparking-results]");
        area.querySelector("[data-sparking-search]").addEventListener("input", (e) => {
          query = e.target.value;
          page = 0;
          render();
        });
        area.querySelector("[data-sparking-rarity]").addEventListener("change", (e) => {
          rarity = e.target.value;
          page = 0;
          render();
        });
        render();
      } catch (e) {
        button.textContent = "Retry loading Sparking references";
        toast(e.message, true);
      } finally {
        button.disabled = false;
      }
    });
  }
  const api = { mountLibraryEntry, findCards, typeLabel, validRevision, escape };
  if (typeof module === "object" && module.exports) module.exports = api;
  else root.ForgeSparking = api;
})(typeof window === "object" ? window : globalThis);
