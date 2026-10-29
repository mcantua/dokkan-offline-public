"use strict";
// Help center: plain-language guides, a word list, fixes for common problems, and help for the
// screen you are on. Opens as a full-screen sheet; search filters every topic.
window.ForgeHelp = (() => {
  const go = (view) => `<button type="button" class="button small" data-help-go="${view}">`;
  const TOPICS = [
    { id: "start", group: "Getting started", title: "Make your first unit in 3 steps", views: ["home", "source"], body:
      `<ol class="help-steps"><li><strong>Create.</strong> Tap <em>Create</em>, pick a character you like as a starting point, and choose a fighting style (or a template). Nothing in the game is changed — you get your own new card.</li>
      <li><strong>Customize.</strong> Change the name, stats, Leader Skill, Passive Skill, Super Attacks and more. Every step has examples and ready-made presets. Made a mistake? Tap <em>↶ Undo</em>.</li>
      <li><strong>Play.</strong> On the last step (<em>Save &amp; Play</em>) tap <em>Save game file</em>. Then open Dokkan Eclipse and import the file.</li></ol>
      <div class="row">${go("quick")}⚡ Quick Create</button>${go("source")}Pick a character</button><button type="button" class="button ghost small" data-help-go="templates">★ Templates</button></div>` },
    { id: "templates", group: "Getting started", title: "Templates and presets", views: ["editor"], body:
      `<p>Templates fill in a whole unit for a fighting style (for example <em>Tank</em> or <em>Heavy hitter</em>). Presets add one ready-made piece, such as a strong Passive ability or a Super Attack effect.</p>
      <p>You always see a <strong>preview of what will change</strong> before anything is applied, and you can undo it afterwards.</p>
      <div class="row"><button type="button" class="button small" data-help-go="templates">Open templates &amp; presets</button></div>` },
    { id: "play", group: "Getting started", title: "Put your unit in Dokkan Eclipse", views: ["library"], body:
      `<ol class="help-steps"><li>Open your unit and go to the last step, <em>Save &amp; Play</em>.</li><li>Tap <strong>Save game file (.eclp)</strong> and choose where to save it (Downloads is fine).</li><li>Open <strong>Dokkan Eclipse</strong> and use its patch importer to load the .eclp file. Restart Eclipse if your unit doesn’t appear straight away.</li><li>For <strong>Dokkan Sparking</strong>, tap <strong>Import to Sparking</strong> on the last step instead: it saves the .sprk where Sparking looks and opens the game.</li></ol>
      <p class="hint">Your units are saved on this phone automatically. The .eclp file is only needed for the game.</p>
      <div class="row">${go("library")}Open Library</button></div>` },
    { id: "copyunit", group: "Getting started", title: "Copy things from another unit", views: ["editor"], body:
      `<ol class="help-steps"><li>Open your unit in the Card Builder and tap <strong>⧉ Copy from a unit</strong> at the top.</li><li>Choose <em>A character from the game</em> (any card, including EZA versions) or <em>One of my units</em>.</li><li>Tick what you want: HP/ATK/DEF, Rarity &amp; Type, Leader Skill, Passive Skill (add to yours or replace it), Super Attacks, Active Skill, Standby &amp; Finish Skills, transformation, links, categories, artwork, aura, or <em>Animations only</em> (their animations on your moves).</li><li>Tap <strong>See the changes</strong>. Nothing changes until you tap <strong>Apply to my unit</strong>, and <strong>↶ Undo</strong> takes the whole copy back.</li></ol><p class="hint">Copied abilities keep their conditions, targets and animations, so they work the same way they do on the original card.</p>` },
    { id: "organize", group: "Getting started", title: "Copy passives from one or more characters", views: ["editor"], body:
      `<ol class="help-steps"><li>In the Card Builder open the <strong>Passive Skill</strong> step and tap <strong>⧉ Copy passives from characters</strong>.</li><li>Type a name (for example <em>Vegito</em>) and tap it. Each name appears once.</li><li>The app finds every fully awakened card with exactly that name and takes the strongest passive of each: Super EZA if it has one, otherwise EZA, otherwise the fully awakened passive. Weaker versions are never copied and the same passive is never listed twice.</li><li>Tap <strong>Copy all … passives into mine</strong>. Want only some? Open <strong>Choose which passives</strong> and untick the ones you don't want. <strong>＋ Add a character</strong> adds another name to the same copy.</li><li>Check the result and the new description, then tap <strong>Apply to my unit</strong>. ↶ Undo takes it back.</li><li>Already copied lots of passives? <strong>🧹 Organize &amp; balance</strong> tidies them up the same way.</li></ol>` },
    { id: "special", group: "Getting started", title: "Counters, revivals, intros, Domains & Standby", views: ["editor"], body:
      `<ol class="help-steps"><li><strong>Counters</strong>: on the Passive Skill step tap ＋ Add an ability → Counters enemy's attack, then choose what it counters (normal attacks, Super Attacks…), how hard it hits back (Enormous ×2, Tremendous ×3, Ferocious ×4), how much damage it blocks and which animation plays.</li><li><strong>Revival</strong>: ＋ Add an ability → Revival (Character exclusive); choose how much HP comes back and who revives (the character or an ally).</li><li><strong>Intro</strong>: on the Passive Skill step, pick any character's entrance scene, or make your own with 🎬.</li><li><strong>Domain</strong>: on the 🌐 Domain step, pick a Domain, then choose if it appears with your Active Skill or by itself from a turn. <strong>Customize</strong> renames it and changes its turns, numbers and background.</li><li><strong>Standby &amp; Finish</strong>: on the ⏳ Standby &amp; Finish step, copy one from a character, then rename it and change how long it stands by.</li><li>Active Skills, EX/Ultra Super Attacks and Transformations have their own steps; the cards link to them.</li></ol>` },
    { id: "artwork", group: "Getting started", title: "Change the card artwork", views: ["editor"], body:
      `<ol class="help-steps"><li>Open <strong>Artwork &amp; Aura</strong> and tap <strong>🎨 Change card artwork</strong>.</li><li>Use a character's artwork, <strong>create new art with AI</strong> (your connected AI follows the official Dokkan art rules) or use your own picture.</li><li>Your picture is fitted into the card art, the round portrait, the cut-ins and the thumbnail automatically. For an LR it goes inside the card's animated artwork, so it moves with the game's LR animation.</li></ol>` },
    { id: "music", group: "Animations", title: "Use your own song", views: ["animations"], body:
      `<ol class="help-steps"><li>In <em>Animate</em> tap <strong>🎵 Music</strong>.</li><li>Tap <strong>Upload my own song</strong> and choose an MP3, M4A, WAV, OGG, AAC or FLAC file from your phone or computer.</li><li>It plays across the whole animation and goes into the game with your unit.</li></ol>` },
    { id: "importhub", group: "Your files", title: "Import units, Eclipse & Sparking files, newest data", views: ["library", "assets"], body:
      `<ol class="help-steps"><li>Open <strong>More → Import &amp; update</strong>.</li><li><strong>A unit or game file</strong>: unit backups (.json), Eclipse units (.eclp), Sparking units (.sprk) or a .zip.</li><li><strong>Check for new Eclipse data</strong> / <strong>Download the newest Eclipse data</strong> keep the character list up to date.</li><li><strong>Download artwork &amp; animations</strong> saves everything on your device so nothing has to load later.</li></ol>` },
    { id: "wipe", group: "Your files", title: "Delete my data", views: [], body:
      `<ol class="help-steps"><li>Open <strong>Settings → Your data → 🗑 Delete my data</strong>.</li><li>Tick what should go: your units, your files, downloaded game files, AI connections or app settings.</li><li>Tick “I understand” and tap Delete. This can't be undone — export units you want to keep first.</li></ol>` },
    { id: "animate", group: "Animations", title: "Make an animation", views: ["animations"], body:
      `<ol class="help-steps"><li>Go to <em>Animate</em> and tap <strong>＋ Add a part</strong>. Search for a character or attack and tap <em>＋ Add</em>.</li><li>The <strong>Choose the part to keep</strong> window opens and the move shows in the preview. Tap <strong>▶ Play</strong>. When it reaches the moment you want, tap <strong>Start here</strong> (it pauses so you can see the exact picture). Tap <strong>▶ Play</strong> again and tap <strong>End here</strong> where the part should stop. <strong>◀ 0.1 s / 0.1 s ▶</strong> fine-tune; <strong>▶ Watch my part</strong> checks it. Tap <strong>✓ Done</strong>.</li><li>Add more parts the same way. They play one after another, in the order shown. <strong>✂ Choose the part</strong> on a card changes it later; <strong>⋯</strong> moves it earlier or later, uses another part of the same move, or removes it.</li><li><strong>▶ Play my animation</strong> plays all parts together. Tap <strong>🎵 Music</strong> for a song, then <strong>💾 Save</strong>.</li></ol>
      <div class="row">${go("animations")}Open Animations</button></div>` },
    { id: "movies", group: "Animations", title: "Cut and join game movies", views: ["movies"], body:
      `<p>Use <strong>Combine movie scenes</strong> (on the Animations page) to cut game movie scenes and join them into one movie.</p>
      <ul><li>White marks on a scene’s bar are <strong>cut points</strong>. Starting a scene on one lets your movie be made instantly.</li><li>Changing the picture (size, rotation…) means the phone has to re-encode the movie, which is slower.</li></ul>` },
    { id: "offline", group: "Animations", title: "Make previews load instantly", views: [], body:
      `<p>Open <strong>More → Offline downloads</strong> and download <em>Essentials</em> (about 100–200 MB). After that, animation scripts and character pictures load from your phone. <em>My units</em> and <em>Everything</em> also save the artwork so previews play without waiting.</p>
      <div class="row">${go("offline")}Offline downloads</button></div>` },
    { id: "library", group: "Your files", title: "Library: your units and game files", views: ["library"], body:
      `<p>The Library lists every unit you made or imported, and the game files (.eclp) you saved. Use the search box and filters at the top. Open a unit to keep editing it, or delete what you don’t need.</p>
      <p>Lost something? Every unit keeps <strong>saved versions</strong>: open the unit, tap <em>⋯ More → Saved versions</em>. Unsaved work can be found under <em>Settings → Your data → Recover unsaved designs</em>.</p>` },
    { id: "combat", group: "Tools", title: "Combat practice", views: ["combat"], body:
      `<p>Try your unit in a simple practice battle on this phone. It is only a rough guide — the real result depends on Dokkan Eclipse.</p>` },
    { id: "assets", group: "Tools", title: "Game data & files", views: ["assets"], body:
      `<p>Here you can update the character list from Eclipse and import game files (resource packs). Most people never need this screen — the app works out of the box.</p>` },
    { id: "ai", group: "Tools", title: "AI helpers", views: ["ai"], body:
      `<p>Describe the unit you want in your own words and an AI (such as ChatGPT or Gemini) suggests changes. You always see a list of the changes first and can undo them. You can also create card art.</p>` },
    { id: "words", group: "Words explained", title: "Dokkan words explained", views: ["editor"], body: "", words: [
      ["Ki", "The energy bar of each fighter. 12 Ki launches a Super Attack. LR units can store up to 24 Ki and use an Ultra Super Attack at 18."],
      ["Super Attack", "A special move used when Ki is high enough. It deals big damage and can boost stats."],
      ["Ultra Super Attack", "An LR’s stronger Super Attack, used at 18 Ki."],
      ["Leader Skill", "A boost to your whole team when this unit is the leader, e.g. “Ki +3 and HP, ATK & DEF +170%”."],
      ["Passive Skill", "Abilities that work on their own every battle, e.g. “ATK +100% at the start of each turn”."],
      ["Active Skill", "A powerful move or effect the player can use once when its condition is met (for example from turn 4)."],
      ["Link Skills", "Small bonuses that switch on when two units next to each other share the same Link."],
      ["Categories", "Groups like “Super Saiyans” or “Movie Heroes” that Leader Skills and Passives can boost."],
      ["Type", "AGL, TEQ, INT, STR or PHY. AGL beats STR, STR beats PHY, PHY beats INT, INT beats TEQ, TEQ beats AGL."],
      ["Class", "Super (heroes) or Extreme (villains). Some skills only boost one class."],
      ["Rarity", "N, R, SR, SSR, UR or LR. LR and UR are the strongest."],
      ["EZA / Super EZA", "Extreme Z-Awakening: an upgrade that makes an existing card stronger."],
      ["Damage reduction", "Takes less damage from attacks, e.g. 40% less."],
      ["Guard", "Cuts damage from attacks the unit is weak against."],
      ["Critical hit", "Hits harder and ignores the enemy’s defence boosts."],
      ["Dodge (evade)", "A chance to take no damage at all."],
      ["Additional attack", "An extra attack in the same turn, sometimes a Super Attack."],
      ["Transformation", "Changing into another form during battle, e.g. Goku turning Super Saiyan."],
      ["Stacking", "A boost that keeps the extra stats for the rest of the battle and can build up."],
      [".eclp file", "The game file you import into Dokkan Eclipse to play your unit."]] },
    { id: "slow", group: "Fix a problem", title: "The app or previews are slow", views: [], body:
      `<ul><li>Open <strong>Settings → Animations → Preview quality</strong> and choose <em>Smoothest</em>. Colors and glows look slightly simpler, but playback stays smooth.</li><li>Keep the player on <em>Full screen</em> (the default); the editor rests while you watch.</li><li>Open <strong>Settings → Speed</strong> and turn on <em>Lite effects</em>.</li><li>Download <strong>Essentials</strong> in Offline downloads so previews don’t wait for the Internet.</li><li>Close and reopen the app if your phone has been running it for a long time.</li></ul>
      <div class="row">${go("settings")}Open Settings</button>${go("offline")}Offline downloads</button></div>` },
    { id: "preview", group: "Fix a problem", title: "A preview doesn’t play", views: [], body:
      `<ul><li>Check your Internet connection, or download the files in <strong>Offline downloads</strong>.</li><li>If <em>Offline preview</em> is on, only downloaded files can play. Turn it off in Settings → Animations.</li><li>Update <em>Android System WebView</em> and <em>Chrome</em> from the Play Store.</li></ul>` },
    { id: "lost", group: "Fix a problem", title: "I lost my changes", views: [], body:
      `<ul><li>Tap <strong>↶ Undo</strong> while editing.</li><li>Open the unit, then <em>⋯ More → Saved versions</em> to go back to an earlier copy.</li><li>Open <em>Settings → Your data → Recover unsaved designs</em> for work that wasn’t saved.</li></ul>
      <div class="row">${go("recover")}Recover unsaved designs</button></div>` },
    { id: "storage", group: "Fix a problem", title: "My phone is running out of space", views: [], body:
      `<p>Downloaded previews can use a lot of space. Open <strong>Offline downloads → Player and offline settings</strong> or the <em>Offline preview downloads</em> section on the Animations page to clear them. Your units are not deleted.</p>` }
  ];
  const VIEW_TOPIC = { home: "start", source: "start", editor: "templates", animations: "animate", library: "library", combat: "combat", movies: "movies", assets: "assets", ai: "ai" };
  let sheet = null;
  function body(t) {
    return t.words ? '<dl class="help-words">' + t.words.map(([w, d]) => "<dt>" + esc(w) + "</dt><dd>" + esc(d) + "</dd>").join("") + "</dl>" : t.body;
  }
  const plain = (html) => String(html).replace(/<[^>]+>/g, " ").replace(/&[a-z]+;/g, " ");
  function close() { sheet?.close(); }
  function open(topic) {
    if (!topic) topic = VIEW_TOPIC[state.view] || "start";
    if (!sheet) {
      sheet = document.createElement("dialog");
      sheet.className = "shell-sheet help-sheet";
      sheet.setAttribute("aria-labelledby", "help-title");
      sheet.addEventListener("click", (e) => {
        const b = e.target.closest("[data-help-go]");
        if (b) { e.preventDefault(); close(); ForgeShell.go(b.dataset.helpGo); }
        const t = e.target.closest("[data-help-topic]");
        if (t) { e.preventDefault(); show(t.dataset.helpTopic); }
      });
      document.body.append(sheet);
    }
    sheet.innerHTML = '<div class="sheet-head"><h2 id="help-title">Help</h2><button type="button" class="icon-button" data-sheet-close aria-label="Close help">×</button></div><label class="field help-search">Search help<input type="search" id="help-search" placeholder="e.g. Ki, export, slow, undo…"></label><div class="help-body"><nav class="help-index" aria-label="Help topics"></nav><article class="help-topic" aria-live="polite"></article></div><div class="row sheet-foot"><button type="button" class="button ghost small" data-help-tour>Take the tour again</button></div>';
    sheet.querySelector("[data-sheet-close]").onclick = close;
    sheet.querySelector("[data-help-tour]").onclick = () => { close(); ForgeShell.tour(); };
    const input = sheet.querySelector("#help-search");
    input.oninput = () => index(input.value);
    index("");
    show(topic);
    if (!sheet.open) sheet.showModal();
  }
  function index(query) {
    const q = String(query || "").trim().toLowerCase(), nav = sheet.querySelector(".help-index");
    const word = (text) => new RegExp("(^|[^a-z])" + q.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "i").test(text);
    const score = (t) => !q ? 1 : (word(t.title) ? 4 : 0) + ((t.words || []).some(([w]) => word(w)) ? 3 : 0) + (word(plain(body(t))) ? 2 : 0) + ((t.title + " " + plain(body(t))).toLowerCase().includes(q) ? 1 : 0);
    const hits = TOPICS.map((t) => [t, score(t)]).filter(([, n]) => n > 0).sort((a, b) => b[1] - a[1]).map(([t]) => t);
    const groups = [...new Set(hits.map((t) => t.group))];
    nav.innerHTML = hits.length ? groups.map((g) => "<h3>" + esc(g) + "</h3>" + hits.filter((t) => t.group === g).map((t) => '<button type="button" class="help-link" data-help-topic="' + t.id + '">' + esc(t.title) + "</button>").join("")).join("") : '<p class="hint">Nothing found. Try a simpler word, like “export” or “Ki”.</p>';
    if (q && hits.length) show(hits[0].id, true);
  }
  function show(id, quiet) {
    const t = TOPICS.find((x) => x.id === id) || TOPICS[0], box = sheet.querySelector(".help-topic");
    box.innerHTML = '<p class="eyebrow">' + esc(t.group.toUpperCase()) + "</p><h3>" + esc(t.title) + "</h3>" + body(t);
    sheet.querySelectorAll("[data-help-topic]").forEach((b) => b.classList.toggle("on", b.dataset.helpTopic === t.id));
    if (!quiet) box.scrollIntoView({ block: "nearest" });
  }
  return { open, close, topics: TOPICS, VIEW_TOPIC };
})();
