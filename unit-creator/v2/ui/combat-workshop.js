(function(root) {
  "use strict";
  const ACTIONS = ["normal", "dash", "launcher", "combo", "super", "ultimate", "ex", "active", "counter", "dodge", "guard", "charge", "transform"];
  const BINDABLE = ["normal", "super", "ultimate", "ex", "active", "dash", "launcher", "combo", "counter", "dodge", "transform", "intro", "victory"];
  const LABELS = { normal: "Attack", dash: "Dash", launcher: "Launcher", combo: "Combo", super: "Super", ultimate: "Ultimate", ex: "EX", active: "Active", counter: "Counter", dodge: "Dodge", guard: "Guard", charge: "Charge", transform: "Transform", intro: "Intro", victory: "Victory" };
  const KEYS = { j: "normal", k: "super", l: "ultimate", e: "ex", f: "active", d: "dash", u: "launcher", i: "combo", c: "counter", q: "dodge", g: "guard", r: "charge", t: "transform" };
  const html = value => String(value == null ? "" : value).replace(/[&<>"']/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
  const copy = value => JSON.parse(JSON.stringify(value));
  const app = () => typeof state !== "undefined" ? state : root.state;
  const native = (method, args) => (typeof Native !== "undefined" ? Native : root.Native).call(method, args || {});
  const message = (text, error) => { if (typeof toast === "function") toast(text, !!error); };
  const label = action => LABELS[action] || action;
  let current = null, generation = 0;

  function listen(session, target, type, callback, options) {
    target.addEventListener(type, callback, options);
    session.cleanup.push(() => target.removeEventListener(type, callback, options));
  }
  function alive(session) {
    return current === session && generation === session.generation && session.node && session.node.isConnected;
  }
  function stopFrame(session) {
    if (session.frame) root.cancelAnimationFrame(session.frame);
    session.frame = 0;
    session.lastFrame = 0;
  }
  function leave() {
    generation++;
    const session = current;
    current = null;
    if (!session) return;
    stopFrame(session);
    if (session.battle) session.battle.destroy();
    session.cleanup.splice(0).forEach(fn => fn());
    session.floaters.length = 0;
  }
  function option(value, text) { return '<option value="' + html(value) + '">' + html(text) + '</option>'; }
  function projectOptions(session, allowTraining) {
    return (allowTraining ? option("training", "Practice opponent") : option("", "Choose your unit")) +
      (session.currentProject ? option("current", "Current design · " + projectName(session.currentProject)) : "") +
      session.projects.map(p => option("saved:" + p.key, p.name || "Saved unit")).join("");
  }
  function projectName(project) {
    return project && (project.name || project.cardOverrides && project.cardOverrides.name || project.tables && project.tables.cards && project.tables.cards[0] && project.tables.cards[0].name) || "Unit design";
  }
  async function selectedProject(session, value) {
    if (value === "current") return copy(session.currentProject);
    if (value.startsWith("saved:")) return native("loadProject", { key: value.slice(6) });
    throw Error("Choose your current design or a saved Library unit first.");
  }

  async function open(options) {
    leave();
    const config = options && options.tables ? { project: options } : options || {};
    if (!root.ForgeCombat || !root.ForgeCombatProject) throw Error("Combat workshop could not load. Reopen this screen.");
    const session = { generation, cleanup: [], projects: [], currentProject: config.project || app() && app().project, frame: 0, lastFrame: 0, battle: null, playerProject: null, playerData: null, floaters: [], log: [], paused: false, loading: false };
    current = session;
    main('<section class="combat-workshop" id="combat-workshop"><div class="section-heading"><div><h1>Practice battle</h1><p>Try your unit in a quick practice fight on this phone. It’s a rough test, not the real game.</p></div></div><p class="notice" role="status">Loading your saved unit choices…</p></section>');
    session.node = document.querySelector("#combat-workshop");
    try {
      const rows = await native("projects");
      if (!alive(session)) return;
      session.projects = Array.isArray(rows) ? rows : [];
      renderSetup(session);
      listen(session, document, "visibilitychange", () => {
        if (document.hidden && alive(session)) pause(session, true, "Paused while this screen is hidden. Resume when you are ready.");
      });
      listen(session, root, "pagehide", () => { if (current === session) leave(); });
      listen(session, document, "keydown", event => {
        if (!alive(session) || !session.battle || event.repeat || event.ctrlKey || event.altKey || event.metaKey || document.querySelector("dialog[open]")) return;
        if (event.target && event.target.closest("input,select,textarea,[contenteditable=true]")) return;
        const key = event.key.toLowerCase();
        if (key === " ") { event.preventDefault(); pause(session, !session.paused); }
        else if (KEYS[key]) { event.preventDefault(); act(session, KEYS[key]); }
      });
      // Navigation can remove the screen without calling our exported leave().
      const observer = new MutationObserver(() => { if (current === session && !session.node.isConnected) leave(); });
      observer.observe(session.node.parentNode, { childList: true });
      session.cleanup.push(() => observer.disconnect());
    } catch (error) {
      if (!alive(session)) return;
      session.node.querySelector("[role=status]").textContent = error.message;
      session.node.querySelector("[role=status]").classList.add("error");
    }
  }

  function renderSetup(session) {
    session.node.innerHTML = '<div class="section-heading"><div><h1>Practice battle</h1><p>Try your unit in a quick practice fight on this phone. It’s a rough test, not the real game.</p></div></div>' +
      '<details class="beginner-details combat-scope"><summary>What this practice battle does and doesn’t include</summary><p class="hint">It uses your unit’s HP, ATK and DEF with simple practice rules for Ki and damage. Passive skills, Leader Skills, transformations and the game’s enemy behaviour are not included, so test the real thing in Dokkan Eclipse.</p></details>' +
      '<form class="panel combat-setup" id="combat-setup"><h2>Set up a round</h2><div class="field-grid"><label class="field">Your unit<select id="combat-player">' + projectOptions(session, false) + '</select></label><label class="field">Opponent<select id="combat-opponent">' + projectOptions(session, true) + '</select></label></div>' +
      '<fieldset id="combat-training"><legend>Practice opponent</legend><p class="hint">Set how tough the opponent is. It has the same type as your unit.</p><div class="combat-training-grid"><label class="field">HP<input id="combat-training-hp" type="number" min="1" max="10000000" step="1" value="20000" required></label><label class="field">Attack<input id="combat-training-atk" type="number" min="1" max="1000000" step="1" value="3000" required></label><label class="field">Defense<input id="combat-training-def" type="number" min="0" max="1000000" step="1" value="1500" required></label></div></fieldset>' +
      '<button type="submit" class="button" id="combat-start">Start practice round</button><p id="combat-setup-status" role="status" class="hint"></p></form><div id="combat-round" hidden></div>';
    const form = session.node.querySelector("#combat-setup"), player = form.querySelector("#combat-player"), opponent = form.querySelector("#combat-opponent");
    if (session.currentProject) player.value = "current";
    else if (session.projects.length) player.value = "saved:" + session.projects[0].key;
    listen(session, opponent, "change", () => {
      const hidden = opponent.value !== "training";
      form.querySelector("#combat-training").hidden = hidden;
      form.querySelectorAll("#combat-training input").forEach(input => input.disabled = hidden);
    });
    listen(session, form, "submit", event => { event.preventDefault(); startRound(session).catch(error => {
      if (alive(session)) form.querySelector("#combat-setup-status").textContent = error.message;
    }); });
  }

  async function startRound(session, restart) {
    if (!alive(session) || session.loading) return;
    session.loading = true;
    const start = session.node.querySelector("#combat-start"), status = session.node.querySelector("#combat-setup-status");
    start.disabled = true;
    status.textContent = "Preparing the selected units…";
    // Freeze the previous round while a native project load is in flight.
    if (session.battle) pause(session, true);
    try {
      let project, playerData, opponentData, opponentProject;
      if (restart && session.roundConfig) ({ project, playerData, opponentData, opponentProject } = session.roundConfig);
      else {
        const form = session.node.querySelector("#combat-setup");
        project = await selectedProject(session, form.querySelector("#combat-player").value);
        if (!alive(session)) return;
        playerData = root.ForgeCombatProject.fromProject(project);
        const selection = form.querySelector("#combat-opponent").value;
        if (selection === "training") {
          const read = (key, max, min) => {
            const value = Number(form.querySelector("#combat-training-" + key).value);
            if (!Number.isSafeInteger(value) || value < min || value > max) throw Error("Choose a whole training " + key + " value within the shown range.");
            return value;
          };
          opponentData = { unit: { id: "workshop-training", name: "Practice opponent", hp: read("hp", 10000000, 1), atk: read("atk", 1000000, 1), def: read("def", 1000000, 0), element: playerData.unit.element, kiMax: 24 }, warnings: ["Opponent stats are adjustable workshop values, not a game roster record."] };
        } else {
          opponentProject = await selectedProject(session, selection);
          if (!alive(session)) return;
          opponentData = root.ForgeCombatProject.fromProject(opponentProject);
        }
      }
      if (!alive(session)) return;
      stopFrame(session);
      if (session.battle) session.battle.destroy();
      session.playerProject = project;
      session.playerData = playerData;
      session.roundConfig = { project, playerData, opponentData, opponentProject };
      session.seed = Math.floor(Math.random() * 0x7fffffff);
      session.battle = new root.ForgeCombat.Battle({ player: playerData.unit, opponent: opponentData.unit, seed: session.seed });
      session.log = []; session.floaters = []; session.paused = false;
      renderRound(session, opponentData, opponentProject);
      status.textContent = "Round ready. Choose Change matchup to edit these choices.";
      paint(session);
      session.node.querySelector("#combat-setup").hidden = true;
      if (document.hidden) pause(session, true);
      else runFrame(session);
      session.node.querySelector("#combat-round").scrollIntoView({ block: "start" });
      session.node.querySelector("#combat-arena").focus({ preventScroll: true });
    } finally {
      if (alive(session)) { session.loading = false; start.disabled = false; }
    }
  }

  function fighterHTML(side, unit, project) {
    let url = "";
    const resource = project && (project.resourceId || project.tables && project.tables.cards && project.tables.cards[0] && project.tables.cards[0].resource_id || project.source && project.source.cardId);
    if (Number.isSafeInteger(Number(resource)) && Number(resource) > 0 && typeof resourceThumb === "function") url = resourceThumb(Number(resource));
    return '<div class="combat-fighter combat-' + side + '" data-fighter="' + side + '"><span class="combat-fighter-name" title="' + html(unit.name) + '">' + html(unit.name) + '</span><div class="combat-avatar"><span class="combat-silhouette" aria-hidden="true"></span>' + (url ? '<img src="' + html(url) + '" alt="" loading="lazy" referrerpolicy="no-referrer">' : '') + '</div><span class="combat-pose" data-pose="' + side + '">Ready</span></div>';
  }
  function meterHTML(side, unit) {
    return '<section class="combat-meter-card"><h3>' + html(unit.name) + '</h3><div class="combat-meter-label"><span>HP</span><output data-value="' + side + '-hp"></output></div><div class="combat-meter combat-hp" role="meter" aria-label="' + html(unit.name) + ' HP" data-meter="' + side + '-hp"><span></span></div><div class="combat-meter-label"><span>Ki</span><output data-value="' + side + '-ki"></output></div><div class="combat-meter combat-ki" role="meter" aria-label="' + html(unit.name) + ' Ki" data-meter="' + side + '-ki"><span></span></div></section>';
  }
  function renderRound(session, opponentData, opponentProject) {
    const area = session.node.querySelector("#combat-round");
    area.hidden = false;
    const warnings = [...new Set([...(session.playerData.warnings || []), ...(opponentData.warnings || [])])];
    area.innerHTML = '<section class="panel combat-round"><div class="section-heading"><div><p class="eyebrow">LOCAL PRACTICE ROUND</p><h2 id="combat-phase" role="status" aria-live="polite">Playing</h2></div><div class="row"><button class="button ghost" id="combat-pause">Pause</button><button class="button ghost" id="combat-restart">Restart round</button><button class="button ghost" id="combat-change-matchup" aria-controls="combat-setup" aria-expanded="false">Change matchup</button></div></div>' +
      '<div class="combat-meters">' + meterHTML("player", session.playerData.unit) + meterHTML("opponent", opponentData.unit) + '</div>' +
      '<div class="combat-arena" id="combat-arena" tabindex="0" aria-label="Local practice arena. Use the action buttons below."><div class="combat-arena-lines" aria-hidden="true"></div><div class="combat-telegraph" id="combat-telegraph" role="status"></div>' + fighterHTML("player", session.playerData.unit, session.playerProject) + fighterHTML("opponent", opponentData.unit, opponentProject) + '<div id="combat-floaters" aria-hidden="true"></div><div class="combat-arena-status" id="combat-arena-status"></div></div>' +
      '<p class="hint" id="combat-feedback" role="status">Close the distance with Dash, build Ki with Charge, and react to the opponent’s cue.</p><div class="combat-actions" aria-label="Combat actions">' + ACTIONS.map(action => '<div class="combat-action"><button type="button" class="button ghost" data-combat-action="' + action + '" aria-describedby="combat-reason-' + action + '">' + label(action) + '</button><small id="combat-reason-' + action + '"></small></div>').join("") + '</div>' +
      '<details class="combat-help"><summary>Practice rules and optional keyboard controls</summary><p>Each button performs one workshop action. Guard and Charge last for their local action window. React to the opponent’s telegraph with Guard, Dodge, or Counter. Ki, range, recovery, and cooldowns limit your actions. Animation bindings do not change these rules.</p><p>J Attack · D Dash · U Launcher · I Combo · K Super · L Ultimate · E EX · F Active · C Counter · Q Dodge · G Guard · R Charge · T Transform · Space Pause. Keyboard controls are optional; all actions have touch buttons.</p></details></section>' +
      '<section class="panel combat-bindings"><h2>Your local animation bindings</h2><p class="hint">A binding connects your saved sequence to a workshop action label. Arena feedback uses local silhouettes and effects. Play a bound animation separately in the existing animation player.</p><div id="combat-binding-list"></div><button type="button" class="button ghost" id="combat-assign">Assign my Studio sequence</button></section>' +
      (warnings.length ? '<details class="panel combat-warnings"><summary>Unit support and practice limits (' + warnings.length + ')</summary><ul>' + warnings.map(warning => '<li>' + html(warning) + '</li>').join("") + '</ul></details>' : '') +
      '<details class="panel combat-events"><summary>Round events</summary><ol id="combat-event-log" aria-label="Recent round events"></ol></details>';
    // Round controls use their own bounded listeners; remove them on every restart.
    if (session.roundCleanup) session.roundCleanup.splice(0).forEach(fn => fn());
    session.roundCleanup = [];
    const bind = (target, type, fn) => { target.addEventListener(type, fn); session.roundCleanup.push(() => target.removeEventListener(type, fn)); };
    if (!session.roundCleanupRegistered) {
      session.cleanup.push(() => session.roundCleanup.splice(0).forEach(fn => fn()));
      session.roundCleanupRegistered = true;
    }
    area.querySelectorAll("[data-combat-action]").forEach(button => bind(button, "click", () => act(session, button.dataset.combatAction)));
    bind(area.querySelector("#combat-pause"), "click", () => pause(session, !session.paused));
    bind(area.querySelector("#combat-restart"), "click", () => startRound(session, true).catch(error => message(error.message, true)));
    bind(area.querySelector("#combat-change-matchup"), "click", () => {
      pause(session, true, "Round paused. Change the matchup above, or hide setup and resume this round.");
      const form = session.node.querySelector("#combat-setup"), button = area.querySelector("#combat-change-matchup");
      form.hidden = !form.hidden;
      button.setAttribute("aria-expanded", String(!form.hidden));
      button.textContent = form.hidden ? "Change matchup" : "Hide setup";
      if (!form.hidden) form.querySelector("#combat-player").focus();
    });
    bind(area.querySelector("#combat-assign"), "click", () => {
      pause(session, true);
      assignSequence({ project: session.playerProject }).catch(error => message(error.message, true));
    });
    renderBindings(session);
  }

  function renderBindings(session) {
    const node = session.node.querySelector("#combat-binding-list"), bindings = session.playerData.bindings || {};
    const actions = Object.keys(bindings).filter(action => BINDABLE.includes(action));
    node.innerHTML = actions.length ? actions.map(action => '<div class="combat-binding"><span><strong>' + html(label(action)) + '</strong><small>' + html(bindings[action].name || "Saved sequence") + ' · local only</small></span><button class="button ghost small" type="button" data-combat-preview="' + action + '">Play animation</button></div>').join("") : '<p>No local action bindings yet. Compose a sequence in the animation editor, then assign it here.</p>';
    // Replacing this subtree releases its old onclick handlers along with the nodes.
    node.querySelectorAll("[data-combat-preview]").forEach(button => button.onclick = async () => {
      if (!alive(session)) return;
      pause(session, true, "Round paused for the separate animation player.");
      button.disabled = true;
      try {
        const binding = bindings[button.dataset.combatPreview];
        // Whole originals keep their native actor roles even when referenced by a different local action.
        const sourceKind = binding.mode === "original" ? binding.originalSource?.catalog?.kind : null;
        const role = binding.mode === "original" ? (["dodge", "nullify"].includes(sourceKind) ? "defender" : "attacker") : button.dataset.combatPreview === "dodge" ? "defender" : "attacker";
        const text = binding.mode === "original" && binding.originalSource ? binding.originalSource.text : root.ForgeMotion.compile(binding.clips, { damage: false, role });
        await native("previewAnimation", { name: binding.name || label(button.dataset.combatPreview), text, ...root.ForgePreviewBindings.request(session.playerProject, { role }) });
      } catch (error) { if (alive(session)) message(error.message, true); }
      finally { if (alive(session) && button.isConnected) button.disabled = false; }
    });
  }

  function pause(session, paused, feedback) {
    if (!alive(session) || !session.battle) return;
    session.paused = !!paused || document.hidden;
    session.battle.pause(session.paused);
    stopFrame(session);
    if (feedback) session.node.querySelector("#combat-feedback").textContent = feedback;
    paint(session);
    if (!session.paused && !document.hidden) runFrame(session);
  }
  function act(session, action) {
    if (!alive(session) || !session.battle || session.loading) return;
    const result = session.battle.act(action);
    if (!result.ok) session.node.querySelector("#combat-feedback").textContent = result.reason || "This action is unavailable.";
    else session.node.querySelector("#combat-feedback").textContent = label(action) + " used. Watch the opponent’s next cue.";
    paint(session);
  }
  function runFrame(session) {
    if (!alive(session) || session.frame || session.paused || document.hidden) return;
    function tick(now) {
      session.frame = 0;
      if (!alive(session)) { if (current === session) leave(); return; }
      if (document.hidden || session.paused) { pause(session, true); return; }
      if (!session.lastFrame) session.lastFrame = now;
      const elapsed = now - session.lastFrame;
      if (elapsed >= 50) {
        session.lastFrame = now;
        session.battle.advance(Math.min(100, Math.max(0, elapsed)));
        paint(session);
      }
      if (session.battle.snapshot().phase === "playing") session.frame = root.requestAnimationFrame(tick);
    }
    session.frame = root.requestAnimationFrame(tick);
  }
  function meter(session, side, stat, value, max) {
    const safeMax = Math.max(1, Number(max) || 1), safe = Math.max(0, Math.min(safeMax, Number(value) || 0));
    const node = session.node.querySelector('[data-meter="' + side + '-' + stat + '"]');
    node.setAttribute("aria-valuemin", "0"); node.setAttribute("aria-valuemax", String(safeMax)); node.setAttribute("aria-valuenow", String(Math.round(safe)));
    node.firstElementChild.style.width = (100 * safe / safeMax).toFixed(2) + "%";
    session.node.querySelector('[data-value="' + side + '-' + stat + '"]').textContent = Math.ceil(safe).toLocaleString() + " / " + Math.ceil(safeMax).toLocaleString();
  }
  function events(session, rows, snapshot) {
    if (!rows.length) return;
    const layer = session.node.querySelector("#combat-floaters");
    rows.forEach(event => {
      const actor = event.actor === "opponent" ? snapshot.opponent.name : event.actor === "player" ? snapshot.player.name : "Round";
      const binding = event.actor === "player" && event.type === "action" && session.playerData.bindings && session.playerData.bindings[event.action];
      const description = event.message || [actor, label(event.action || event.type), Number.isFinite(event.amount) ? Math.round(event.amount) : "", binding ? binding.name + " (animation reference)" : ""].filter(value => value !== "").join(" · ");
      session.log.push(description);
      if (["damage", "heal", "recover"].includes(event.type) && Number.isFinite(event.amount) && event.amount !== 0 && session.floaters.length < 12) {
        const target = (event.target || event.actor) === "opponent" ? snapshot.opponent : snapshot.player;
        const node = document.createElement("span"); node.className = "combat-damage" + (event.type === "heal" || event.type === "recover" ? " combat-heal" : "");
        node.textContent = (event.type === "heal" || event.type === "recover" ? "+" : "−") + Math.round(Math.abs(event.amount)).toLocaleString();
        node.style.left = Math.max(7, Math.min(93, Number(target.x) || 50)) + "%";
        layer.appendChild(node);
        session.floaters.push({ node, expires: snapshot.elapsed + 950 });
      }
    });
    session.log = session.log.slice(-40);
    session.node.querySelector("#combat-event-log").innerHTML = session.log.map(line => '<li>' + html(line) + '</li>').join("");
  }
  function paint(session) {
    if (!alive(session) || !session.battle) return;
    const snapshot = session.battle.snapshot();
    ["player", "opponent"].forEach(side => {
      const fighter = snapshot[side];
      meter(session, side, "hp", fighter.hp, fighter.maxHp);
      meter(session, side, "ki", fighter.ki, fighter.maxKi);
      const node = session.node.querySelector('[data-fighter="' + side + '"]');
      node.style.left = Math.max(7, Math.min(93, Number(fighter.x) || 0)) + "%";
      node.style.setProperty("--fighter-lift", Math.max(0, Math.min(60, Number(fighter.y) || 0)) + "px");
      node.dataset.pose = fighter.pose || "ready";
      session.node.querySelector('[data-pose="' + side + '"]').textContent = fighter.pose || "Ready";
    });
    ACTIONS.forEach(action => {
      const available = snapshot.available[action], button = session.node.querySelector('[data-combat-action="' + action + '"]');
      button.disabled = !available || !available.enabled || session.loading;
      button.textContent = available && available.label || label(action);
      const reason = available && available.reason || (available && available.cost ? available.cost + " Ki" : "Ready");
      session.node.querySelector("#combat-reason-" + action).textContent = reason + (available && available.cooldown > 0 ? " · " + (available.cooldown / 1000).toFixed(1) + "s" : "");
    });
    const title = session.node.querySelector("#combat-phase"), phase = snapshot.phase === "victory" ? "Victory" : snapshot.phase === "defeat" ? "Defeat" : session.paused ? "Paused" : "Playing";
    if (title.textContent !== phase) title.textContent = phase;
    const pauseButton = session.node.querySelector("#combat-pause"); pauseButton.textContent = session.paused ? "Resume" : "Pause"; pauseButton.disabled = snapshot.phase !== "playing";
    session.node.querySelector("#combat-arena-status").textContent = snapshot.phase !== "playing" ? phase + " · Restart for another round" : session.paused ? "Paused" : "";
    const telegraph = session.node.querySelector("#combat-telegraph"), cue = snapshot.telegraph;
    const cueText = cue && snapshot.phase === "playing" && !session.paused ? "Incoming: " + (cue.label || label(cue.action)) : "";
    if (telegraph.textContent !== cueText) telegraph.textContent = cueText;
    telegraph.classList.toggle("active", !!cueText);
    telegraph.style.setProperty("--cue", cue ? Math.max(0, Math.min(1, cue.remaining / Math.max(1, cue.duration))) : 0);
    events(session, session.battle.drainEvents(), snapshot);
    session.floaters = session.floaters.filter(entry => {
      if (entry.expires > snapshot.elapsed && snapshot.phase === "playing") return true;
      entry.node.remove(); return false;
    });
    session.node.querySelector("#combat-arena").classList.toggle("is-paused", session.paused);
  }

  async function assignSequence(options) {
    const config = options || {}, owner = config.project || current && current.playerProject || app() && app().project;
    if (!owner) throw Error("Open a unit design before assigning an animation.");
    const sequence = config.sequence || owner.animationStudio || owner.composition || {};
    const clips = config.clips || sequence.clips;
    if (!Array.isArray(clips) || !clips.length) throw Error("Compose a sequence in the animation editor first, then assign it to a workshop action.");
    const original = copy(owner), existing = config.action || sequence.purpose || "super";
    const ownedSequences = [owner.animationStudio, owner.composition].filter(Boolean);
    if (!ownedSequences.some(saved => JSON.stringify(saved.clips) === JSON.stringify(clips))) throw Error("Add this sequence to the unit’s animations first so its original resource references are prepared.");
    if (current && current.battle) pause(current, true, "Round paused while assigning a local animation.");
    dialog("Assign a workshop action", '<p>This assignment is local to the combat workshop. It does not install a move or change Eclipse battle rules.</p><form id="combat-assignment"><label class="field">Action<select id="combat-binding-action">' + BINDABLE.map(action => option(action, label(action))).join("") + '</select></label><label class="field">Sequence name<input id="combat-binding-name" maxlength="120" required value="' + html(config.name || sequence.name || "My workshop sequence") + '"></label><p>' + clips.length + ' animation section' + (clips.length === 1 ? "" : "s") + '</p><button class="button" type="submit">Save local assignment</button><p id="combat-assignment-status" class="hint" role="status"></p></form>');
    const form = document.querySelector("#combat-assignment"), action = form.querySelector("#combat-binding-action");
    action.value = BINDABLE.includes(existing) ? existing : "super";
    form.onsubmit = async event => {
      event.preventDefault();
      const button = form.querySelector("button"), status = form.querySelector("#combat-assignment-status");
      if (button.disabled) return;
      button.disabled = true;
      try {
        const name = form.querySelector("#combat-binding-name").value.trim();
        if (!name) throw Error("Name this sequence before saving.");
        const active = app() && app().project;
        // Merge into the live design only when it is still the same actual project.
        const isCurrent = !!(active && original.key && active.key === original.key);
        if (isCurrent && root.ForgeSparkingContent && typeof root.ForgeSparkingContent.ensureAnimations === "function") {
          await root.ForgeSparkingContent.ensureAnimations(active);
          if (!app() || app().project !== active) throw Error("The selected unit changed. Assign the sequence again from its current design.");
          if (!form.isConnected) throw Error("The assignment dialog was closed. Open it again before saving.");
        }
        const base = isCurrent ? active : original;
        const binding = { name, clips: copy(clips) };
        if (sequence.mode) binding.mode = sequence.mode;
        if (sequence.originalSource) binding.originalSource = copy(sequence.originalSource);
        const updated = root.ForgeCombatProject.assign(base, action.value, binding);
        if (isCurrent) {
          app().project = updated;
          scheduleSave();
          await flushSave();
        } else {
          const result = await native("saveProject", { project: updated });
          if (!result || result.saved !== true || result.superseded) throw Error("Saving this assignment could not be confirmed. Reopen the latest unit and try again.");
        }
        if (current && alive(current) && current.playerProject && current.playerProject.key === updated.key) {
          current.playerProject = updated;
          if (current.currentProject && current.currentProject.key === updated.key) current.currentProject = updated;
          current.playerData = root.ForgeCombatProject.fromProject(updated);
          if (current.roundConfig) { current.roundConfig.project = updated; current.roundConfig.playerData = current.playerData; }
          renderBindings(current);
        }
        if (form.isConnected) { status.textContent = "Saved locally. The practice round stays paused."; button.textContent = "Saved"; }
        message("Local workshop assignment saved.");
      } catch (error) {
        if (form.isConnected) { status.textContent = error.message; button.disabled = false; }
      }
    };
  }
  root.ForgeCombatWorkshop = { open, leave, assignSequence };
})(typeof globalThis !== "undefined" ? globalThis : this);
