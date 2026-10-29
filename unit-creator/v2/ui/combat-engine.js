(function(root, factory) {
  if (typeof module === "object" && module.exports) module.exports = factory();
  else root.ForgeCombat = factory();
})(typeof globalThis !== "undefined" ? globalThis : this, function() {
  "use strict";
  const RULES = "Combat Workshop is a local sandbox. Its damage, Ki, timing, movement and action rules are approximations, not Dokkan or Eclipse gameplay rules.";
  const MAX_ADVANCE_MS = 100, STEP_MS = 20, EVENT_LIMIT = 512;
  const ACTIONS = Object.freeze(Object.fromEntries(Object.entries({
    normal:    { label: "Normal attack", cost: 0, cooldown: 360, duration: 220, range: 34, power: 1, kiGain: 2, knockback: 2 },
    super:     { label: "Super attack", cost: 6, cooldown: 1800, duration: 500, range: 100, power: 2.4, knockback: 6 },
    ultimate:  { label: "Ultimate attack", cost: 12, cooldown: 6000, duration: 900, range: 100, power: 4.2, knockback: 12 },
    ex:        { label: "EX attack", cost: 9, cooldown: 3500, duration: 650, range: 100, power: 3.2, knockback: 9 },
    active:    { label: "Active skill", cost: 5, cooldown: 5500, duration: 700, range: 100, power: 2.1, knockback: 4 },
    dash:      { label: "Dash closer", cost: 1, cooldown: 700, duration: 140, range: 100 },
    launcher:  { label: "Launcher", cost: 2, cooldown: 1200, duration: 320, range: 34, power: 0.7 },
    combo:     { label: "Air combo", cost: 3, cooldown: 1800, duration: 550, range: 38, power: 0.7, hits: 3 },
    counter:   { label: "Ready a counter", cost: 2, cooldown: 1000, duration: 0, range: 100, window: 700, reactive: true },
    dodge:     { label: "Dodge", cost: 2, cooldown: 1000, duration: 0, range: 100, window: 600, reactive: true },
    transform: { label: "Transform", cost: 0, cooldown: 0, duration: 650, range: 100, once: true },
    guard:     { label: "Guard", cost: 0, cooldown: 400, duration: 0, range: 100, window: 1400, reactive: true },
    charge:    { label: "Charge Ki", cost: 0, cooldown: 600, duration: 350, range: 100 }
  }).map(([key, value]) => [key, Object.freeze(value)])));
  const copy = value => JSON.parse(JSON.stringify(value));
  const clamp = (value, low, high) => Math.max(low, Math.min(high, value));
  function stat(value, fallback, low, high, label) {
    if (value === undefined) value = fallback;
    if (typeof value !== "number" || !Number.isFinite(value) || value < low || value > high) throw new Error(label + " must be a finite number from " + low + " to " + high + ".");
    return Math.round(value);
  }
  function fighter(input, role) {
    if (!input || typeof input !== "object" || Array.isArray(input)) throw new Error("Choose a " + role + " unit for the Workshop.");
    const id = input.id === undefined ? role : input.id;
    if (!(typeof id === "number" && Number.isSafeInteger(id) || typeof id === "string" && id.length > 0 && id.length <= 128)) throw new Error("The Workshop unit has an invalid identity.");
    const hp = stat(input.hp, 12000, 1, 1e9, "HP"), maxKi = stat(input.kiMax, 24, 1, 1000, "Maximum Ki");
    return { id, name: typeof input.name === "string" && input.name.trim() ? input.name.trim().slice(0, 120) : role === "player" ? "My unit" : "Opponent",
      hp, maxHp: hp, atk: stat(input.atk, 3200, 0, 1e9, "ATK"), def: stat(input.def, 1000, 0, 1e9, "DEF"),
      element: [0,1,2,3,4,10,11,12,13,14,20,21,22,23,24].includes(input.element) ? input.element : null,
      ki: Math.floor(maxKi / 2), maxKi, x: role === "player" ? 25 : 55, y: 0, pose: "idle", transformed: false,
      busyUntil: 0, guardUntil: 0, dodgeUntil: 0, counterUntil: 0, airborneUntil: 0 };
  }
  class Battle {
    constructor({ player, opponent, seed = 1 } = {}) {
      this.player = fighter(player, "player"); this.opponent = fighter(opponent, "opponent");
      if (!(typeof seed === "number" && Number.isFinite(seed) || typeof seed === "string" && seed.length <= 200)) throw new Error("Choose a finite number or short text as the battle seed.");
      let state = 2166136261; for (const character of String(seed)) state = Math.imul(state ^ character.charCodeAt(0), 16777619) >>> 0;
      this._randomState = state || 1; this.elapsed = 0; this.phase = "playing"; this.paused = false; this.destroyed = false;
      this._remainder = 0; this._cooldowns = {}; this._telegraph = null; this._nextAttack = 1000;
      this._events = []; this._pending = []; this._eventNumber = 0; this._listeners = new Map(); this._listenerNumber = 0; this._dispatching = false;
      this._emit("battle-start", { actor: "player", target: "opponent" });
      this._emit("intro", { actor: "player", target: "opponent", action: "intro" });
      this._flush();
    }
    _random() {
      let value = this._randomState; value ^= value << 13; value ^= value >>> 17; value ^= value << 5;
      this._randomState = value >>> 0; return this._randomState / 4294967296;
    }
    _emit(type, detail) {
      const event = Object.freeze(Object.assign({ id: "event-" + ++this._eventNumber, type, elapsed: this.elapsed }, detail || {}));
      this._events.push(event); if (this._events.length > EVENT_LIMIT) this._events.shift();
      this._pending.push(event); return event;
    }
    _flush() {
      if (this._dispatching || this.destroyed) return;
      this._dispatching = true;
      try {
        while (this._pending.length && !this.destroyed) {
          const event = this._pending.shift();
          const listeners = Array.from(this._listeners.values()).filter(item => item.event === event.type || item.event === "*").sort((a,b) => b.priority - a.priority || a.order - b.order);
          for (const item of listeners) {
            if (this.destroyed) break;
            if (this._listeners.get(item.key) !== item) continue;
            if (item.once) this._listeners.delete(item.key);
            try { item.callback(event, this.snapshot()); }
            catch (error) {
              if (event.type !== "hook-error") this._emit("hook-error", { hookId: item.id, eventType: event.type, message: String(error && error.message || "The action callback failed.").slice(0, 200) });
            }
          }
        }
      } finally { this._dispatching = false; }
    }
    on(event, id, callback, options = {}) {
      if (this.destroyed) return () => false;
      if (typeof event !== "string" || !/^(?:\*|[a-z][a-z0-9-]{0,63})$/.test(event) || typeof id !== "string" || !id.trim() || id.length > 128 || typeof callback !== "function") throw new Error("Register a named Workshop event and callback.");
      const priority = options.priority === undefined ? 0 : options.priority;
      if (!Number.isFinite(priority) || Math.abs(priority) > 10000) throw new Error("Choose a finite event priority from -10000 to 10000.");
      const key = event + "\0" + id, item = { key, event, id, callback, once: options.once === true, priority, order: ++this._listenerNumber };
      if (!this._listeners.has(key) && this._listeners.size >= 512) throw new Error("Use no more than 512 local battle callbacks.");
      this._listeners.set(key, item);
      return () => this._listeners.get(key) === item && this._listeners.delete(key);
    }
    _availability(action) {
      const spec = ACTIONS[action], cooldown = Math.max(0, (this._cooldowns[action] || 0) - this.elapsed);
      let reason = "";
      if (this.destroyed) reason = "This Workshop battle is closed.";
      else if (this.phase !== "playing") reason = "Start a new battle to use more actions.";
      else if (this.paused) reason = "Resume the battle first.";
      else if (spec.once && this.player.transformed) reason = "Already transformed this battle.";
      else if (cooldown > 0) reason = "Ready in " + (cooldown / 1000).toFixed(1) + " seconds.";
      else if (this.player.busyUntil > this.elapsed && !spec.reactive) reason = "Finish the current action first.";
      else if (this.player.ki < spec.cost) reason = "Need " + spec.cost + " Ki. Use normal attacks or Charge Ki.";
      else if (Math.abs(this.player.x - this.opponent.x) > spec.range) reason = "Too far away. Dash closer first.";
      else if (action === "combo" && this.opponent.airborneUntil <= this.elapsed) reason = "Launch the opponent first, then use Air combo.";
      else if (action === "charge" && this.player.ki >= this.player.maxKi) reason = "Ki is already full.";
      return { enabled: !reason, reason, label: spec.label, cost: spec.cost, cooldown };
    }
    act(action) {
      if (!Object.prototype.hasOwnProperty.call(ACTIONS, action)) return { ok: false, reason: "Choose a supported Workshop action." };
      if (this._dispatching) return { ok: false, reason: "Wait for the current combat event to finish." };
      const availability = this._availability(action); if (!availability.enabled) return { ok: false, reason: availability.reason };
      const spec = ACTIONS[action], player = this.player, opponent = this.opponent;
      player.ki -= spec.cost; this._cooldowns[action] = this.elapsed + spec.cooldown;
      if (!spec.reactive) { player.busyUntil = this.elapsed + spec.duration; player.guardUntil = 0; player.dodgeUntil = 0; player.counterUntil = 0; }
      player.pose = action;
      const event = this._emit("action", { actor: "player", target: "opponent", action, cost: spec.cost });
      this._emit(action, { actor: "player", target: "opponent", action, stage: "start" });
      if (action === "dash") {
        const old = player.x, side = player.x <= opponent.x ? -1 : 1;
        player.x = clamp(opponent.x + side * 16, 0, 100);
        this._emit("move", { actor: "player", action, from: old, to: player.x });
      } else if (action === "guard") { player.guardUntil = this.elapsed + spec.window; player.dodgeUntil = 0; player.counterUntil = 0; }
      else if (action === "dodge") { player.dodgeUntil = this.elapsed + spec.window; player.guardUntil = 0; player.counterUntil = 0; }
      else if (action === "counter") { player.counterUntil = this.elapsed + spec.window; player.guardUntil = 0; player.dodgeUntil = 0; }
      else if (action === "charge") {
        const amount = Math.min(player.maxKi - player.ki, Math.max(1, Math.round(player.maxKi / 4))); player.ki += amount;
        this._emit("ki", { actor: "player", action, amount });
      } else if (action === "transform") {
        player.transformed = true; player.atk = Math.round(player.atk * 1.35); player.def = Math.round(player.def * 1.2);
        const amount = Math.min(player.maxHp - player.hp, Math.round(player.maxHp * 0.1)); player.hp += amount;
        this._emit("heal", { actor: "player", action, amount });
      } else if (spec.power) {
        for (let hit = 1; hit <= (spec.hits || 1) && this.phase === "playing"; hit++) this._hit("player", action, spec.power, hit);
        if (this.phase === "playing" && action === "launcher") { opponent.airborneUntil = this.elapsed + 1400; opponent.busyUntil = this.elapsed + 450; opponent.y = 28; opponent.pose = "launched"; this._emit("launch", { actor: "player", target: "opponent", action, duration: 1400 }); }
        if (spec.kiGain && this.phase === "playing") { const amount = Math.min(player.maxKi - player.ki, spec.kiGain); player.ki += amount; this._emit("ki", { actor: "player", action, amount }); }
      }
      this._flush(); return { ok: true, event: copy(event) };
    }
    _hit(role, action, power, hit = 1, reduction = 1) {
      if (this.phase !== "playing") return;
      const attacker = this[role], other = role === "player" ? "opponent" : "player", target = this[other];
      const amount = Math.min(target.hp, Math.max(1, Math.round(attacker.atk * 0.22 * power / (1 + target.def / 10000) * reduction)));
      target.hp -= amount;
      if (target.hp > 0) target.pose = "hit";
      this._emit("damage", { actor: role, target: other, action, amount, hit, remainingHp: target.hp, guarded: reduction < 1 });
      if (target.hp > 0) {
        const from = target.x, knockback = role === "player" ? ACTIONS[action]?.knockback || 1 : 2;
        target.x = clamp(target.x + (target.x >= attacker.x ? 1 : -1) * knockback, 0, 100);
        if (from !== target.x) this._emit("move", { actor: other, action, from, to: target.x });
      }
      if (target.hp <= 0) this._finish(other === "opponent" ? "victory" : "defeat");
    }
    _finish(phase) {
      this.phase = phase; this._telegraph = null;
      this.player.pose = phase === "victory" ? "victory" : "defeat"; this.opponent.pose = phase === "victory" ? "defeat" : "victory";
      const winner = phase === "victory" ? "player" : "opponent", loser = winner === "player" ? "opponent" : "player";
      this._emit(phase, { actor: winner, target: loser, action: phase }); this._emit("battle-end", { actor: winner, target: loser, result: phase });
    }
    _enemyAttack() {
      const warning = this._telegraph; this._telegraph = null;
      if (!warning || this.phase !== "playing") return;
      const player = this.player; this.opponent.pose = warning.action;
      this._emit("action", { actor: "opponent", target: "player", action: warning.action });
      if (player.dodgeUntil >= this.elapsed) {
        player.dodgeUntil = 0; player.pose = "dodge"; this._emit("dodge-success", { actor: "player", target: "opponent", action: "dodge", avoidedAction: warning.action });
      } else if (player.counterUntil >= this.elapsed && Math.abs(player.x - this.opponent.x) <= 38) {
        player.counterUntil = 0; player.pose = "counter"; this._emit("counter-hit", { actor: "player", target: "opponent", action: "counter", avoidedAction: warning.action }); this._hit("player", "counter", 1.5);
      } else if (Math.abs(player.x - this.opponent.x) > ACTIONS[warning.action].range) this._emit("miss", { actor: "opponent", target: "player", action: warning.action });
      else {
        const guarding = player.guardUntil >= this.elapsed;
        if (guarding) this._emit("guard-hit", { actor: "player", target: "opponent", action: "guard" });
        this._hit("opponent", warning.action, warning.action === "super" ? 2 : 0.9, 1, guarding ? 0.25 : 1);
      }
      this._nextAttack = this.elapsed + 1350 + Math.floor(this._random() * 650);
    }
    _tick() {
      this.elapsed += STEP_MS;
      for (const role of ["player", "opponent"]) {
        const unit = this[role];
        if (unit.airborneUntil > this.elapsed) unit.y = 28 * Math.sin(Math.PI * Math.min(1, (unit.airborneUntil - this.elapsed) / 1400));
        else unit.y = 0;
        if (unit.busyUntil <= this.elapsed && unit.airborneUntil <= this.elapsed) unit.pose = unit.dodgeUntil > this.elapsed ? "dodge" : unit.counterUntil > this.elapsed ? "counter" : unit.guardUntil > this.elapsed ? "guard" : "idle";
      }
      if (this.opponent.airborneUntil > this.elapsed || this.opponent.busyUntil > this.elapsed) {
        if (this._telegraph) { this._emit("interrupted", { actor: "opponent", target: "player", action: this._telegraph.action }); this._telegraph = null; this._nextAttack = this.opponent.airborneUntil + 400; }
      } else if (this._telegraph) {
        this.opponent.pose = "telegraph";
        if (this.elapsed >= this._telegraph.endsAt) this._enemyAttack();
      } else if (this.elapsed >= this._nextAttack) {
        const action = this.opponent.ki >= ACTIONS.super.cost && this._random() < 0.3 ? "super" : "normal", duration = action === "super" ? 1000 : 700;
        this.opponent.ki = clamp(this.opponent.ki - ACTIONS[action].cost + (action === "normal" ? 2 : 0), 0, this.opponent.maxKi);
        this._telegraph = { action, label: action === "super" ? "Opponent is preparing a Super attack" : "Opponent is preparing an attack", startsAt: this.elapsed, endsAt: this.elapsed + duration, duration, actor: "opponent", target: "player" };
        this.opponent.pose = "telegraph"; this._emit("telegraph", { actor: "opponent", target: "player", action, duration });
      }
      if (this.phase === "playing" && !this._telegraph && this.opponent.airborneUntil <= this.elapsed && Math.abs(this.player.x - this.opponent.x) > 26) this.opponent.x = clamp(this.opponent.x + Math.sign(this.player.x - this.opponent.x) * 0.1, 0, 100);
      this._flush();
    }
    advance(ms) {
      if (typeof ms !== "number" || !Number.isFinite(ms) || ms < 0) throw new Error("Advance the Workshop with a finite, nonnegative number of milliseconds.");
      if (this.destroyed || this.paused || this.phase !== "playing" || this._dispatching) return this.snapshot();
      this._remainder += Math.min(ms, MAX_ADVANCE_MS);
      while (this._remainder >= STEP_MS && !this.paused && !this.destroyed && this.phase === "playing") { this._remainder -= STEP_MS; this._tick(); }
      if (this.phase !== "playing") this._remainder = 0;
      return this.snapshot();
    }
    pause(value) {
      if (typeof value !== "boolean") throw new Error("Pause or resume using true or false.");
      if (!this.destroyed && !this._dispatching && this.paused !== value) { this.paused = value; this._remainder = 0; this._emit(value ? "paused" : "resumed", { actor: "player" }); this._flush(); }
      return this.snapshot();
    }
    snapshot() {
      const publicUnit = unit => ({ id: unit.id, name: unit.name, hp: unit.hp, maxHp: unit.maxHp, atk: unit.atk, def: unit.def, element: unit.element, ki: unit.ki, maxKi: unit.maxKi, x: unit.x, y: unit.y, pose: unit.pose, transformed: unit.transformed,
        busyRemaining: Math.max(0, unit.busyUntil - this.elapsed), guardRemaining: Math.max(0, unit.guardUntil - this.elapsed), dodgeRemaining: Math.max(0, unit.dodgeUntil - this.elapsed), counterRemaining: Math.max(0, unit.counterUntil - this.elapsed), airborneRemaining: Math.max(0, unit.airborneUntil - this.elapsed) });
      const available = {}; for (const action of Object.keys(ACTIONS)) available[action] = this._availability(action);
      const telegraph = this._telegraph ? Object.assign({}, this._telegraph, { remaining: Math.max(0, this._telegraph.endsAt - this.elapsed) }) : null;
      return { phase: this.phase, elapsed: this.elapsed, paused: this.paused, destroyed: this.destroyed, player: publicUnit(this.player), opponent: publicUnit(this.opponent), available, telegraph, rules: RULES };
    }
    drainEvents() { const events = this._events.map(copy); this._events.length = 0; return events; }
    destroy() { if (!this.destroyed) { this.destroyed = true; this._listeners.clear(); this._pending.length = 0; this._events.length = 0; this._telegraph = null; this._remainder = 0; } }
  }
  return { Battle, ACTIONS, RULES, MAX_ADVANCE_MS, STEP_MS, EVENT_LIMIT };
});
