"use strict";
// 🎲 Random skill names in Dokkan Battle style, for the Leader Skill, Passive Skill, Active Skill
// and Standby / Finish Skills. A dice button sits next to every skill-name box in the Card
// Builder, and "🎲 New skill names" renames them all at once (↶ Undo takes it back).
window.ForgeSkillNames = (() => {
  const pick = (list) => list[Math.floor(Math.random() * list.length)];
  const W = {
    adj: ["Unyielding", "Supreme", "Divine", "Limitless", "Blazing", "Eternal", "Ultimate", "Fierce", "Unbreakable", "Rising", "Furious", "Radiant", "Burning", "Invincible", "Legendary", "Awakened", "Boundless", "Raging", "Mighty", "Absolute", "Fearless", "Peerless", "Unrivaled", "Righteous", "Proud", "Savage", "Silent", "Crimson", "Golden", "Shining", "True", "Untamed", "Relentless", "Glorious", "Valiant"],
    noun: ["Pride", "Spirit", "Will", "Power", "Fury", "Resolve", "Bond", "Soul", "Instinct", "Glory", "Rage", "Hope", "Courage", "Legacy", "Destiny", "Ascension", "Strength", "Might", "Wrath", "Honor", "Dominion", "Vow", "Ambition", "Brilliance", "Determination", "Fighting Spirit", "Battle Instinct", "Warrior's Heart", "Limit", "Miracle"],
    group: ["Warriors", "Saiyans", "Heroes", "Fighters", "Champions", "Allies", "Rivals", "Guardians", "Legends", "the Universe", "the Strong", "Justice"],
    verb: ["Surpass", "Shatter", "Ignite", "Awaken", "Defy", "Conquer", "Unleash", "Break", "Transcend", "Seize", "Overcome", "Embrace"],
    target: ["the Limit", "Fate", "the Heavens", "Destiny", "the Storm", "All Odds", "the Impossible", "the Darkness", "One's Limits", "the Future"],
    attack: ["Strike", "Barrage", "Blast", "Rush", "Assault", "Finale", "Flash", "Impact", "Onslaught", "Cannon", "Wave", "Smash", "Combination", "Flurry", "Crusher"],
    standby: ["Charge", "Gathering", "Focus", "Stance", "Preparation", "Countdown", "Overdrive", "Surge"]
  };
  const PATTERNS = {
    leader: [() => pick(W.adj) + " " + pick(W.noun), () => pick(W.noun) + " of " + pick(W.group), () => pick(W.group).replace(/^the /, "") + "' " + pick(W.noun), () => "Leader of " + pick(W.group), () => pick(W.adj) + " Command"],
    passive: [() => pick(W.adj) + " " + pick(W.noun), () => pick(W.noun) + " of " + pick(W.noun), () => pick(W.verb) + " " + pick(W.target), () => "The " + pick(W.adj) + " " + pick(W.noun), () => pick(W.noun) + " Beyond " + pick(W.target).replace(/^the /i, "")],
    active: [() => pick(W.adj) + " " + pick(W.attack), () => pick(W.noun) + " " + pick(W.attack), () => "Final " + pick(W.attack), () => pick(W.verb) + " " + pick(W.target)],
    standby: [() => pick(W.adj) + " " + pick(W.standby), () => pick(W.noun) + " " + pick(W.standby), () => "Ready to " + pick(W.verb)],
    finish: [() => pick(W.adj) + " " + pick(W.attack), () => "Final " + pick(W.attack), () => pick(W.noun) + " Unleashed"]
  };
  function random(kind, avoid) {
    const list = PATTERNS[kind] || PATTERNS.passive;
    for (let i = 0; i < 12; i++) { const n = pick(list)(); if (n !== avoid) return n; }
    return pick(list)();
  }
  const TABLE_KIND = { leader_skill_sets: "leader", passive_skill_sets: "passive", active_skill_sets: "active", standby_skill_sets: "standby", finish_skill_sets: "finish" };

  // ---------------------------------------------------------------- 🎲 next to name boxes
  function rename(input) {
    const [, table, id, field] = String(input.dataset.bind || "").split(":"), kind = TABLE_KIND[table];
    if (!kind || field !== "name" || !state.project) return;
    const row = (state.project.tables[table] || []).find((r) => r.id === Number(id));
    if (!row) return;
    row.name = random(kind, row.name);
    input.value = row.name;
    input.dispatchEvent(new Event("input", { bubbles: true }));
    input.dispatchEvent(new Event("change", { bubbles: true }));
    scheduleSave();
  }
  // Renames every skill the unit uses (all its passives and leaders, every EZA stage included).
  function renameAll() {
    const p = state.project;
    if (!p) return 0;
    let n = 0;
    for (const [table, kind] of Object.entries(TABLE_KIND)) for (const row of p.tables[table] || []) {
      if (p.awaken && Number(row.id) > 0) continue;   // EZA projects never rename the game's own rows
      row.name = random(kind, row.name);
      n++;
    }
    return n;
  }
  let queued = false;
  function inject() {
    queued = false;
    for (const input of document.querySelectorAll('#bld input[data-bind^="table:"]')) {
      const [, table, , field] = input.dataset.bind.split(":");
      if (field !== "name" || !TABLE_KIND[table] || input.dataset.dice) continue;
      input.dataset.dice = "1";
      const wrap = document.createElement("span");
      wrap.className = "dice-wrap";
      input.parentNode.insertBefore(wrap, input);
      wrap.appendChild(input);
      const b = document.createElement("button");
      b.type = "button";
      b.className = "dice-button";
      b.textContent = "🎲";
      b.title = "Random name";
      b.setAttribute("aria-label", "Random name");
      b.onclick = () => rename(input);
      wrap.appendChild(b);
    }
    const tools = document.querySelector(".bld-tools");
    if (tools && !tools.querySelector(".dice-all") && state.project && !state.project.awaken) {
      const b = document.createElement("button");
      b.type = "button";
      b.className = "button ghost small dice-all";
      b.textContent = "🎲 New skill names";
      b.onclick = () => {
        const n = renameAll();
        if (!n) return toast("This unit has no skills to name yet.", true);
        scheduleSave();
        renderEditor();
        toast("New names for " + n + " skill" + (n === 1 ? "" : "s") + ". Tap 🎲 again for others, or ↶ Undo.");
      };
      const menu = tools.querySelector(".bld-more-menu");
      if (menu) menu.prepend(b); else (tools.querySelector(".ucopy-button") || tools.lastChild)?.after(b);
    }
  }
  new MutationObserver(() => { if (!queued) { queued = true; requestAnimationFrame(inject); } }).observe(document.body, { childList: true, subtree: true });
  return { random, renameAll };
})();
