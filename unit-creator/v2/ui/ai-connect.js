/* Bring-your-own AI: connect ChatGPT/OpenAI, Gemini, Claude, Grok, OpenRouter or any
   OpenAI-compatible server with your own API key (stored privately on this device by the app),
   or use any AI app through copy & paste. Provides an AI helper that can change the unit through
   reviewed, undoable builder actions, and an AI card-art generator. */
(function() {
  "use strict";
  if (!window.ForgeBuilder) return;
  const B = window.ForgeBuilder, D = window.FORGE_GUIDE_DATA || {};
  const h = (v) => esc(v);
  const fail = (e) => toast(e && e.message || String(e), true);

  // ------------------------------------------------------------ providers
  const PROVIDERS = {
    openai: { name: "ChatGPT / OpenAI", chat: true, image: true, model: "gpt-5-mini", imageModel: "gpt-image-1.5", keys: "platform.openai.com/api-keys", style: "openai" },
    gemini: { name: "Google Gemini", chat: true, image: true, model: "gemini-flash-latest", imageModel: "gemini-3.1-flash-image", keys: "aistudio.google.com/apikey", style: "gemini" },
    anthropic: { name: "Claude (Anthropic)", chat: true, image: false, model: "claude-sonnet-5-5", imageModel: "", keys: "console.anthropic.com/settings/keys", style: "anthropic" },
    xai: { name: "Grok (xAI)", chat: true, image: true, model: "grok-4", imageModel: "grok-imagine-image", keys: "console.x.ai", style: "openai" },
    openrouter: { name: "OpenRouter (hundreds of models)", chat: true, image: false, model: "openrouter/auto", imageModel: "", keys: "openrouter.ai/keys", style: "openai" },
    custom: { name: "Other / self-hosted (OpenAI-compatible)", chat: true, image: true, model: "", imageModel: "", keys: "", style: "openai" }
  };
  let connections = null, active = "";
  async function loadConnections(force = false) {
    if (connections && !force) return connections;
    try {
      const r = await Native.call("aiConnections");
      connections = r.connections || [];
      active = r.active || (connections[0] && connections[0].provider) || "";
    } catch { connections = []; active = ""; }
    return connections;
  }
  const conn = (id = active) => (connections || []).find((c) => c.provider === id);
  const modelOf = (c) => (c && c.model) || (c && PROVIDERS[c.provider].model) || "";
  const imageModelOf = (c) => (c && c.imageModel) || (c && PROVIDERS[c.provider].imageModel) || "";
  function imageProvider() {
    const order = [active, "openai", "gemini", "xai", "custom"];
    for (const id of order) { const c = conn(id); if (c && PROVIDERS[id].image && imageModelOf(c)) return c; }
    return null;
  }

  async function request(provider, path, body, method = "POST", progress) {
    ui.cancel = null;
    const job = (await Native.call("aiStart", { provider, path, method, body })).job;
    const started = Date.now();
    for (;;) {
      await new Promise((r) => setTimeout(r, 900));
      if (ui.cancel) { ui.cancel = null; await Native.call("aiCancel", { job }).catch(() => {}); throw new Error("Canceled."); }
      const r = await Native.call("aiPoll", { job });
      if (r.done) {
        let json = null;
        try { json = JSON.parse(r.text); } catch {}
        if (r.status >= 400 || !json) {
          const message = json && (json.error && (json.error.message || json.error) || json.message) || String(r.text || "").slice(0, 300);
          throw new Error((PROVIDERS[provider] || {}).name + " error" + (r.status ? " " + r.status : "") + ": " + (typeof message === "string" ? message : JSON.stringify(message)).slice(0, 400));
        }
        return json;
      }
      if (progress) progress(Math.round((Date.now() - started) / 1000));
      if (Date.now() - started > 300000) { await Native.call("aiCancel", { job }).catch(() => {}); throw new Error("The AI took longer than 5 minutes. Try again."); }
    }
  }
  async function chat(messages, system, progress) {
    const c = conn();
    if (!c) throw new Error("Connect an AI first.");
    const style = PROVIDERS[c.provider].style, model = modelOf(c);
    if (!model) throw new Error("Choose a chat model for " + PROVIDERS[c.provider].name + " in AI settings.");
    if (style === "anthropic") {
      const r = await request(c.provider, "/messages", { model, max_tokens: 4096, system, messages: messages.map((m) => ({ role: m.role, content: m.content })) }, "POST", progress);
      return (r.content || []).filter((p) => p.type === "text").map((p) => p.text).join("\n");
    }
    if (style === "gemini") {
      const r = await request(c.provider, "/models/" + encodeURIComponent(model) + ":generateContent", { systemInstruction: { parts: [{ text: system }] }, contents: messages.map((m) => ({ role: m.role === "assistant" ? "model" : "user", parts: [{ text: m.content }] })) }, "POST", progress);
      const parts = r.candidates && r.candidates[0] && r.candidates[0].content && r.candidates[0].content.parts || [];
      const text = parts.map((p) => p.text || "").join("");
      if (!text) throw new Error("Gemini returned no text" + (r.promptFeedback && r.promptFeedback.blockReason ? " (" + r.promptFeedback.blockReason + ")" : "") + ".");
      return text;
    }
    const r = await request(c.provider, "/chat/completions", { model, messages: [{ role: "system", content: system }].concat(messages) }, "POST", progress);
    const msg = r.choices && r.choices[0] && r.choices[0].message;
    const content = msg && (typeof msg.content === "string" ? msg.content : Array.isArray(msg.content) ? msg.content.map((p) => p.text || "").join("") : "");
    if (!content) throw new Error("The AI returned an empty reply.");
    return content;
  }
  async function generateImage(prompt, { transparent = false, portrait = true } = {}, progress) {
    const c = imageProvider();
    if (!c) throw new Error("Connect an image-capable AI (OpenAI, Gemini, Grok, or a compatible server) to generate art in the app.");
    const model = imageModelOf(c);
    let b64 = "", mime = "image/png";
    if (c.provider === "gemini") {
      const r = await request(c.provider, "/models/" + encodeURIComponent(model) + ":generateContent", { contents: [{ role: "user", parts: [{ text: prompt + (transparent ? " Plain flat white background, no scenery." : "") }] }], generationConfig: { responseModalities: ["IMAGE"], imageConfig: { aspectRatio: portrait ? "2:3" : "1:1" } } }, "POST", progress);
      const parts = r.candidates && r.candidates[0] && r.candidates[0].content && r.candidates[0].content.parts || [];
      const img = parts.find((p) => p.inlineData || p.inline_data);
      if (!img) throw new Error("Gemini did not return an image. Try a different description" + (parts.length ? ": " + (parts[0].text || "").slice(0, 160) : "."));
      const data = img.inlineData || img.inline_data;
      b64 = data.data; mime = data.mimeType || data.mime_type || "image/png";
    } else {
      const body = { model, prompt, n: 1 };
      if (c.provider === "openai") Object.assign(body, { size: portrait ? "1024x1536" : "1024x1024", output_format: "png", background: transparent ? "transparent" : "auto" });
      else body.response_format = "b64_json";
      if (c.provider === "custom") body.size = portrait ? "1024x1536" : "1024x1024";
      const r = await request(c.provider, "/images/generations", body, "POST", progress);
      const d = r.data && r.data[0];
      if (!d || !d.b64_json) throw new Error("The AI did not return image data. Check the image model name in AI settings.");
      b64 = d.b64_json;
    }
    return { base64: await toPng(b64, mime), provider: c.provider, model };
  }
  async function toPng(b64, mime) {
    if (/png/i.test(mime) && /^iVBORw0KGgo/.test(b64)) return b64;
    const img = new Image();
    img.src = "data:" + mime + ";base64," + b64;
    await img.decode();
    const canvas = document.createElement("canvas");
    canvas.width = img.naturalWidth; canvas.height = img.naturalHeight;
    canvas.getContext("2d").drawImage(img, 0, 0);
    return canvas.toDataURL("image/png").split(",")[1];
  }
  async function listModels(provider) {
    const style = PROVIDERS[provider].style;
    const r = await request(provider, style === "gemini" ? "/models?pageSize=200" : "/models", null, "GET");
    if (style === "gemini") return (r.models || []).map((m) => ({ id: String(m.name || "").replace(/^models\//, ""), image: /image/i.test(m.name), chat: (m.supportedGenerationMethods || []).includes("generateContent") }));
    return (r.data || []).map((m) => ({ id: m.id, image: /image|dall-e|imagine/i.test(m.id), chat: !/image|dall-e|embedding|tts|whisper|moderation|imagine/i.test(m.id) }));
  }

  // ------------------------------------------------------------ settings dialog
  const ui = { cancel: null, busy: false, history: [], pendingActions: null, artResult: null, provider: "" };
  function modal(id, title, html) {
    let d = document.getElementById(id);
    if (!d) { d = document.createElement("dialog"); d.id = id; d.className = "aic-dialog"; document.body.append(d); }
    d.innerHTML = '<div class="aic-head"><h2>' + h(title) + '</h2><button type="button" class="icon-button" data-aic-close aria-label="Close">×</button></div>' + html;
    d.querySelector("[data-aic-close]").onclick = () => d.close();
    if (!d.open) d.showModal();
    return d;
  }
  async function openSettings(focus, notice) {
    await loadConnections(true);
    const pid = focus || ui.provider || active || "openai";
    ui.provider = pid;
    const c = conn(pid) || { provider: pid }, meta = PROVIDERS[pid];
    const list = Object.entries(PROVIDERS).map(([id, p]) => {
      const cc = conn(id);
      return '<button type="button" class="aic-provider' + (id === pid ? " on" : "") + '" data-aic-provider="' + id + '"><strong>' + h(p.name) + "</strong><small>" + (cc ? (id === active ? "● In use · " : "Connected · ") + "key " + h(cc.keyHint || "not needed") : p.image ? "Chat + image generation" : "Chat") + "</small></button>";
    }).join("");
    const d = modal("aic-settings", "Connect your AI", '<p class="hint">Use the AI you like. Paste an API key once: the app stores it privately on this phone and only sends it to that AI company. Usage is billed by the provider to your account. Prefer your normal AI app instead? Use <strong>Copy & paste mode</strong> in the AI helper — it works with any AI app, no key needed.</p><div class="aic-providers">' + list + '</div><section class="aic-form"><h3>' + h(meta.name) + "</h3>" + (meta.keys ? '<p class="hint">Get a key at <strong>' + h(meta.keys) + "</strong>" + (meta.image ? "" : ". This AI writes and edits; for pictures it writes prompts you can use in any image app.") + "</p>" : '<p class="hint">Any server that speaks the OpenAI API (LM Studio, Ollama with an https tunnel, Together, Groq, DeepSeek, Mistral…). Use https://, or http://127.0.0.1 for an AI app running on this phone.</p>') + (pid === "custom" ? '<label class="field">Server address<input id="aic-base" type="url" placeholder="https://api.example.com/v1" value="' + h(c.baseUrl || "") + '"></label>' : "") + '<label class="field">API key' + (c.hasKey ? " (saved " + h(c.keyHint) + " — leave empty to keep it)" : "") + '<input id="aic-key" type="password" autocomplete="off" spellcheck="false" placeholder="' + (c.hasKey ? "••••••••" : "Paste your key") + '"></label><div class="field-grid"><label class="field">Chat model<input id="aic-model" list="aic-models" value="' + h(c.model || meta.model) + '"></label>' + (meta.image ? '<label class="field">Image model<input id="aic-image-model" list="aic-image-models" value="' + h(c.imageModel || meta.imageModel) + '"></label>' : "") + '</div><datalist id="aic-models"></datalist><datalist id="aic-image-models"></datalist><p id="aic-status-s" class="hint" role="status"></p><div class="row"><button type="button" class="button" id="aic-save">Save & test</button>' + (c.hasKey || c.baseUrl ? '<button type="button" class="button ghost" id="aic-models-load">Load model list</button><button type="button" class="button subtle" id="aic-remove">Disconnect</button>' : "") + "</div></section>");
    const status = (t, err) => { const e = d.querySelector("#aic-status-s"); e.textContent = t; e.className = err ? "bld-warn" : "hint"; };
    if (notice) status(notice);
    d.querySelectorAll("[data-aic-provider]").forEach((b) => b.onclick = () => openSettings(b.dataset.aicProvider).catch(fail));
    d.querySelector("#aic-save").onclick = async () => {
      if (ui.busy) return;
      ui.busy = true;
      try {
        const args = { provider: pid, model: d.querySelector("#aic-model").value.trim(), makeActive: true };
        const key = d.querySelector("#aic-key").value.trim();
        if (key) args.apiKey = key;
        if (d.querySelector("#aic-image-model")) args.imageModel = d.querySelector("#aic-image-model").value.trim();
        if (d.querySelector("#aic-base")) args.baseUrl = d.querySelector("#aic-base").value.trim();
        status("Saving…");
        await Native.call("aiSaveConnection", args);
        await loadConnections(true);
        status("Saved. Testing the connection…");
        const reply = await chat([{ role: "user", content: "Reply with exactly: Connected" }], "You are a connection test.", (s) => status("Waiting for " + meta.name + "… " + s + "s"));
        toast(meta.name + " is connected.");
        await openSettings(pid, "✓ Connected. " + meta.name + " replied: " + reply.trim().slice(0, 80));
        refreshPage();
      } catch (e) { status(e.message || String(e), true); } finally { ui.busy = false; }
    };
    const load = d.querySelector("#aic-models-load");
    if (load) load.onclick = async () => {
      try {
        status("Loading models…");
        const models = await listModels(pid);
        d.querySelector("#aic-models").innerHTML = models.filter((m) => m.chat).map((m) => '<option value="' + h(m.id) + '">').join("");
        d.querySelector("#aic-image-models").innerHTML = models.filter((m) => m.image).map((m) => '<option value="' + h(m.id) + '">').join("");
        status(models.length + " models available. Tap a model field to choose one.");
      } catch (e) { status(e.message, true); }
    };
    const remove = d.querySelector("#aic-remove");
    if (remove) remove.onclick = async () => {
      try { await Native.call("aiRemoveConnection", { provider: pid }); await loadConnections(true); openSettings(pid); refreshPage(); toast("Disconnected."); } catch (e) { status(e.message, true); }
    };
  }

  // ------------------------------------------------------------ unit context + actions
  const WHEN = { turnStart: 1, beforeAttack: 11, attacking: 4, attackHits: 5, receiving: 6, afterReceiving: 7, afterKO: 14, afterSpheres: 15, turnEnd: 9 };
  const WHO = { self: 1, allies: 2, alliesExceptSelf: 16, superAllies: 12, extremeAllies: 13, attackedEnemy: 3, allEnemies: 4 };
  const RARITY = { N: 0, R: 1, SR: 2, SSR: 3, UR: 4, TUR: 4, LR: 5 };
  function fieldsDoc(fields) {
    return fields.map((f) => f.kind === "choice" ? f.name + ":" + f.options.map(([v, n]) => v + "=" + n).join("|") : f.kind === "category" ? f.name + ":\"Category name\"" : f.name + "(" + f.min + "-" + f.max + ")").join(", ");
  }
  function catalog() {
    return [
      "PASSIVE abilities (ability key → values): " + B.PASSIVE.map((e) => e.key + " [" + e.label + "]" + (e.fields.length ? " {" + fieldsDoc(e.fields) + "}" : "")).join("; "),
      "CONDITION rules (rule key → fields): " + B.CONDITIONS.map((c) => c.key + " [" + c.label + "]" + (c.fields.length ? " {" + fieldsDoc(c.fields) + "}" : "")).join("; "),
      "SUPER ATTACK effects: " + B.SA_EFFECTS.map((e) => e.key + " [" + e.label + "]" + (e.fields.length ? " {" + fieldsDoc(e.fields) + "}" : "")).join("; "),
      "ACTIVE SKILL effects: " + B.ACTIVE_EFFECTS.map((e) => e.key + " [" + e.label + "]" + (e.fields.length ? " {" + fieldsDoc(e.fields) + "}" : "")).join("; "),
      "Damage classes: " + (D.damageProfiles || []).map((p) => p.key).join(", "),
      "when: " + Object.keys(WHEN).join("|") + "; who: " + Object.keys(WHO).join("|") + "; turns: 1-5 or 99 (rest of battle)"
    ].join("\n");
  }
  function unitSummary() {
    const p = state.project;
    if (!p) return "No unit is open.";
    const c = Forge.card(p), parts = B.elementParts(c.element);
    const lset = (p.tables.leader_skill_sets || []).find((r) => r.id === c.leader_skill_set_id), pset = Forge.primaryPassive(p);
    const rows = pset ? (p.tables.passive_skill_set_relations || []).filter((r) => r.passive_skill_set_id === pset.id).map((r) => (p.tables.passive_skills || []).find((x) => x.id === r.passive_skill_id)).filter(Boolean) : [];
    const supers = (p.tables.card_specials || []).map((rel) => { const s = (p.tables.special_sets || []).find((x) => x.id === rel.special_set_id) || {}; return (rel.style === "Hyper" ? "Ultra" : "Super") + " (" + rel.eball_num_start + " Ki): " + s.name + " — " + String(s.description || "").replace(/\s+/g, " "); });
    const act = (p.tables.active_skill_sets || []).map((s) => s.name + " — " + String(s.effect_description || "").replace(/\s+/g, " ") + " | " + String(s.condition_description || "").replace(/\s+/g, " "));
    const links = Array.from({ length: 7 }, (_, i) => c["link_skill" + (i + 1) + "_id"]).filter(Boolean).map((id) => ((state.links || []).find((l) => l.id === id) || {}).name).filter(Boolean);
    const cats = (p.tables.card_card_categories || []).map((r) => ((state.categories || []).find((x) => x.id === r.card_category_id) || {}).name).filter(Boolean);
    return ["Name: " + c.name + " (started from " + p.source.name + ")", "Rarity " + Forge.rarities[c.rarity] + ", " + (B.CLASSES[parts.cls] || "") + " " + B.TYPES[parts.type] + ", HP " + c.hp_max + " ATK " + c.atk_max + " DEF " + c.def_max + ", cost " + c.cost,
      "Leader: " + (lset ? String(lset.description || "").replace(/\s+/g, " ") : "none"), "Passive '" + (pset ? pset.name : "") + "': " + (rows.map((r) => B.passiveLine(r)).join("; ") || "none"),
      "Supers: " + (supers.join(" || ") || "none"), "Active Skill: " + (act.join(" || ") || "none"), "Links: " + (links.join(", ") || "none"), "Categories: " + (cats.join(", ") || "none")].join("\n");
  }
  function systemPrompt() {
    return "You are the AI helper inside Dokkan Unit Creator, an Android app for building custom Dragon Ball Z Dokkan Battle units for the Dokkan Eclipse private server. Help the user design balanced, fun units in the style of real Dokkan cards (LR/UR leaders usually Ki +3 and HP, ATK & DEF +170% for Categories; passives use ATK & DEF boosts, Ki, damage reduction, crits, dodge, additional attacks and conditions like turn counts or HP). Be friendly and brief.\n\n" +
      "You can change the open unit. When the user asks for changes, explain them in 1-3 sentences and then add ONE fenced code block:\n```json\n{\"actions\":[...]}\n```\nAction types (all fields optional unless noted):\n" +
      '- {"do":"basics","name":"","rarity":"LR|UR|TUR|SSR|SR|R|N","class":"Super|Extreme","type":"AGL|TEQ|INT|STR|PHY","hp":0,"atk":0,"def":0,"cost":0}\n' +
      '- {"do":"leader","name":"","groups":[{"who":"all|types|super|extreme|classTypes|categories","types":["AGL"],"classTypes":["Super AGL"],"categories":["Category name"],"also":["Category name"],"ki":3,"hp":170,"atk":170,"def":170}]}\n' +
      '- {"do":"passive","name":"","replace":true,"abilities":[{"ability":"KEY","values":{},"when":"turnStart","who":"self","turns":1,"chance":100,"once":false,"conditions":[{"rule":"KEY","FIELD":0}],"match":"all|any"}]}  (replace:true removes the current passive abilities first)\n' +
      '- {"do":"super","which":"super|ultra","name":"","ki":12,"damage":"supreme","allEnemies":false,"effects":[{"effect":"KEY","values":{},"who":"self","turns":1,"chance":100}]}\n' +
      '- {"do":"active","kind":"attack|buff","name":"","boost":100,"allEnemies":false,"effects":[{"effect":"KEY","values":{},"who":"self"}],"conditions":[{"rule":"turn","turn":4}],"uses":1,"turns":1}\n' +
      '- {"do":"links","links":["Link Skill name", "... up to 7"]}\n- {"do":"categories","categories":["Category name"]}\n- {"do":"art","prompt":"detailed image prompt for the card artwork"}\n' +
      "Use only the keys below; use real Dokkan Category and Link Skill names. Don't invent IDs.\n" + catalog() + "\n\nCURRENT UNIT\n" + unitSummary();
  }
  function findNamed(rows, name, label) {
    const n = String(name || "").trim().toLocaleLowerCase();
    if (!n) throw new Error("Missing " + label + " name.");
    const exact = rows.find((r) => String(r.name || "").toLocaleLowerCase() === n);
    if (exact) return exact;
    const partial = rows.filter((r) => String(r.name || "").toLocaleLowerCase().includes(n));
    if (partial.length === 1) return partial[0];
    throw new Error("Unknown " + label + ": " + name);
  }
  function conditionSpec(list, match) {
    if (!list || !list.length) return { mode: "all", items: [] };
    return { mode: match === "any" ? "any" : "all", items: list.map((rule) => {
      const def = B.conditionDef(rule.rule || rule.key);
      if (!def) throw new Error("Unknown condition: " + (rule.rule || rule.key));
      const values = {};
      for (const f of def.fields) {
        let v = rule[f.name] !== undefined ? rule[f.name] : rule.values && rule.values[f.name];
        if (f.kind === "category" && v !== undefined && !Number.isFinite(Number(v))) v = findNamed(state.categories || [], v, "Category").id;
        if (v !== undefined) values[f.name] = v;
      }
      return { key: def.key, values };
    }) };
  }
  function passiveRowsOf(p) {
    const set = Forge.primaryPassive(p);
    if (!set) return [];
    const ids = new Set((p.tables.passive_skill_set_relations || []).filter((r) => r.passive_skill_set_id === set.id).map((r) => r.passive_skill_id));
    return (p.tables.passive_skills || []).filter((r) => ids.has(r.id));
  }
  // Applies AI actions to project p (a clone during preview). Returns human-readable changes.
  function applyActions(p, actions, ctx) {
    const schema = state.info.schema, changes = [], extras = { artPrompts: [] };
    // For an EZA of a game card, only the latest EZA step's leader/passive and new Super Attack
    // upgrades can change; the card's own records stay as they are in the game.
    const stageTarget = (kind) => {
      if (!p.awaken) return p;
      const groups = B.stageGroups(p, kind), key = groups[groups.length - 1].key;
      B.ensureStageEditable(p, kind, key);
      return B.stageView(p, kind, key);
    };
    if (!Array.isArray(actions) || !actions.length) throw new Error("The reply has no changes to apply.");
    if (actions.length > 30) throw new Error("Too many changes in one reply.");
    for (const a of actions) {
      const kind = a && a.do;
      if (p.awaken && !["leader", "passive", "art"].includes(kind)) throw new Error("For an EZA, the helper can change the EZA leader and passive skills. Add Super Attack upgrades on the EZA Super Attack tab.");
      if (kind === "basics") {
        if (a.name) { p.cardOverrides.name = String(a.name).slice(0, 80); changes.push("Name → " + p.cardOverrides.name); }
        if (a.rarity !== undefined) { const r = RARITY[String(a.rarity).toUpperCase()]; if (r === undefined) throw new Error("Unknown rarity " + a.rarity); p.cardOverrides.rarity = r; changes.push("Rarity → " + a.rarity); }
        const parts = B.elementParts(Forge.card(p).element);
        let cls = parts.cls || 1, type = parts.type;
        if (a.class) { cls = /extreme/i.test(a.class) ? 2 : 1; }
        if (a.type) { type = B.TYPES.indexOf(String(a.type).toUpperCase()); if (type < 0) throw new Error("Unknown type " + a.type); }
        if (a.class || a.type) { p.cardOverrides.element = B.elementValue(cls, type); changes.push("Class & type → " + B.CLASSES[cls] + " " + B.TYPES[type]); }
        for (const s of ["hp", "atk", "def"]) if (a[s] !== undefined) {
          const v = Math.round(Number(a[s]));
          if (!(v >= 1 && v <= 999999)) throw new Error(s.toUpperCase() + " must be 1-999999.");
          p.cardOverrides[s + "_max"] = v;
          if (Number(Forge.card(p)[s + "_init"]) > v) p.cardOverrides[s + "_init"] = v;
          changes.push(s.toUpperCase() + " → " + v.toLocaleString());
        }
        if (a.cost !== undefined) { p.cardOverrides.cost = Math.max(1, Math.min(999, Math.round(Number(a.cost) || 1))); changes.push("Cost → " + p.cardOverrides.cost); }
      } else if (kind === "leader") {
        const groups = (a.groups || []).map((g) => {
          const out = { who: g.who || "all", ki: g.ki, hp: g.hp !== undefined ? g.hp : g.stats, atk: g.atk !== undefined ? g.atk : g.stats, def: g.def !== undefined ? g.def : g.stats };
          out.types = (g.types || []).map((t) => B.TYPES.indexOf(String(t).toUpperCase())).filter((t) => t >= 0);
          out.classTypes = (g.classTypes || []).map((n) => (B.CLASS_TYPE_OPTIONS.find(([, label]) => label.toLowerCase() === String(n).toLowerCase()) || [])[0]).filter(Boolean);
          out.categories = (g.categories || []).map((n) => findNamed(state.categories || [], n, "Category").id);
          out.also = (g.also || []).map((n) => findNamed(state.categories || [], n, "Category").id);
          return out;
        });
        const set = B.buildLeader(stageTarget("leader"), schema, groups, { official: ctx.subTargets, names: ctx.names, name: a.name !== undefined ? a.name : "" });
        if (!a.name) set.name = B.leaderName(groups, ctx.names);
        changes.push("Leader Skill → " + set.description.replace(/\n/g, " "));
      } else if (kind === "passive") {
        const pv = stageTarget("passive");
        if (a.replace) for (const row of passiveRowsOf(pv)) if (Number(row.efficacy_type) !== 103) Forge.removePassive(p, row.id);
        for (const ab of a.abilities || []) {
          const def = B.passiveDef(ab.ability || ab.key);
          if (!def) throw new Error("Unknown passive ability: " + (ab.ability || ab.key));
          const settings = { timing: WHEN[ab.when] || Number(ab.when) || undefined, target: WHO[ab.who] || undefined, turn: ab.turns || 1, chance: ab.chance !== undefined ? ab.chance : def.chance || 100, once: !!ab.once };
          let row = B.addPassiveAbility(pv, def.key, ab.values || {}, Object.assign(B.newPassiveSettings(def.key), Object.fromEntries(Object.entries(settings).filter(([, v]) => v !== undefined))));
          if (ab.conditions && ab.conditions.length) B.applyCondition(p, schema, row, conditionSpec(ab.conditions, ab.match));
          const cond = ab.conditions && ab.conditions.length ? " (" + B.conditionText(conditionSpec(ab.conditions, ab.match), ctx.names) + ")" : "";
          // the same ability at the same moment is added to the existing one (within meta limits)
          const set1 = Forge.primaryPassive(pv), merged = window.ForgePassiveMerge && set1 ? ForgePassiveMerge.absorb(p, set1.id, row) : { row, merged: false };
          row = merged.row;
          changes.push((merged.merged ? "Passive (combined): " : "Passive: ") + B.passiveLine(row) + cond);
        }
        const s2 = Forge.primaryPassive(pv);
        if (a.name && s2) { s2.name = String(a.name).slice(0, 80); changes.push("Passive name → " + s2.name); }
        if (a.replace) changes.unshift("Removed the previous passive abilities");
        // a brand-new passive gets a written description; additions to an existing one update it
        if (s2 && a.replace) { p.builderAuto = p.builderAuto || {}; p.builderAuto["passive:" + s2.id] = true; if (p.builderLines) delete p.builderLines[s2.id]; }
        if (s2 && window.ForgePassiveMerge) for (const issue of ForgePassiveMerge.balanceIssues(ForgePassiveMerge.setRows(p, s2.id))) changes.push("⚠ Above today's meta: " + issue.text + " (total " + issue.total + ", limit " + issue.cap + ")");
      } else if (kind === "super") {
        const style = a.which === "ultra" ? "Hyper" : "Normal";
        let rel = (p.tables.card_specials || []).filter((r) => r.style === style).sort((x, y) => x.lv_start - y.lv_start)[0];
        const profile = a.damage ? (D.damageProfiles || []).find((x) => x.key === a.damage) : null;
        if (a.damage && !profile) throw new Error("Unknown damage class " + a.damage);
        if (!rel) {
          const made = B.createSuper(p, schema, { style, name: a.name, ki: a.ki, profile: profile || (D.damageProfiles || []).find((x) => x.key === (style === "Hyper" ? "mega-colossal" : "supreme")), profiles: D.damageProfiles, allEnemies: !!a.allEnemies, effects: [] });
          rel = made.rel;
          changes.push("Added " + (style === "Hyper" ? "an Ultra Super Attack" : "a Super Attack"));
        }
        const set = p.tables.special_sets.find((s) => s.id === rel.special_set_id);
        if (a.name) set.name = String(a.name).slice(0, 80);
        if (a.ki) rel.eball_num_start = Math.max(1, Math.min(24, Math.round(Number(a.ki))));
        if (profile) { set.increase_rate = profile.increase_rate; set.lv_bonus = profile.lv_bonus; }
        if (a.allEnemies !== undefined) set.aim_target = a.allEnemies ? 1 : 0;
        if (Array.isArray(a.effects)) {
          p.tables.specials = (p.tables.specials || []).filter((r) => r.special_set_id !== set.id || !B.decodeSpecial(r));
          for (const e of a.effects) {
            const def = B.saDef(e.effect || e.key);
            if (!def) throw new Error("Unknown Super Attack effect: " + (e.effect || e.key));
            B.addSpecialEffect(p, set.id, def.key, e.values || {}, { target: WHO[e.who], turn: e.turns, chance: e.chance });
          }
        }
        p.builderAuto = p.builderAuto || {}; p.builderAuto["sa:" + set.id] = true;
        set.description = B.superText(set, p.tables.specials.filter((r) => r.special_set_id === set.id), D.damageProfiles);
        changes.push((style === "Hyper" ? "Ultra Super Attack" : "Super Attack") + " “" + set.name + "”: " + set.description);
      } else if (kind === "active") {
        const ids = new Set((p.tables.card_active_skills || []).map((r) => r.active_skill_set_id));
        let set = (p.tables.active_skill_sets || []).find((s) => ids.has(s.id));
        if (!set) {
          const view = ctx.activeViews[a.kind === "buff" ? "buff" : "attack"] || {};
          set = B.createActive(p, schema, { name: a.name || "Active Skill", viewId: view.special_view_id, bgmId: view.bgm_id, attack: a.kind === "buff" ? null : { boost: a.boost || 0, allEnemies: !!a.allEnemies } });
          changes.push("Created an Active Skill");
        } else if (a.kind) B.setActiveAttack(p, schema, set, a.kind === "buff" ? null : { boost: a.boost || 0, allEnemies: !!a.allEnemies });
        else if (a.boost !== undefined || a.allEnemies !== undefined) { const cur = B.activeAttack(p, set); if (cur && !cur.inherited) B.setActiveAttack(p, schema, set, { boost: a.boost !== undefined ? a.boost : cur.boost, allEnemies: a.allEnemies !== undefined ? !!a.allEnemies : cur.allEnemies }); }
        if (a.name) set.name = String(a.name).slice(0, 80);
        if (a.uses) set.exec_limit = Math.max(1, Math.min(3, Math.round(a.uses)));
        if (a.turns) set.turn = [1, 2, 3, 4, 99].includes(Number(a.turns)) ? Number(a.turns) : 1;
        if (Array.isArray(a.effects)) {
          p.tables.active_skills = (p.tables.active_skills || []).filter((r) => r.active_skill_set_id !== set.id || Number(r.efficacy_type) === 103);
          for (const e of a.effects) {
            const def = B.activeDef(e.effect || e.key);
            if (!def) throw new Error("Unknown Active Skill effect: " + (e.effect || e.key));
            B.addActiveEffect(p, set.id, def.key, e.values || {}, WHO[e.who]);
          }
        }
        if (a.conditions) B.applyCondition(p, schema, set, conditionSpec(a.conditions, a.match));
        p.builderAuto = p.builderAuto || {}; p.builderAuto["active:" + set.id] = true;
        set.effect_description = B.activeText(p, set, D.damageProfiles);
        changes.push("Active Skill “" + set.name + "”: " + set.effect_description);
      } else if (kind === "links") {
        const ids = [...new Set((a.links || []).map((n) => findNamed(state.links || [], n, "Link Skill").id))].slice(0, 7);
        for (let i = 0; i < 7; i++) p.cardOverrides["link_skill" + (i + 1) + "_id"] = ids[i] || null;
        changes.push("Link Skills → " + ids.map((id) => (state.links.find((l) => l.id === id) || {}).name).join(", "));
      } else if (kind === "categories") {
        const ids = [...new Set((a.categories || []).map((n) => findNamed(state.categories || [], n, "Category").id))];
        p.schema.card_card_categories = p.schema.card_card_categories || state.info.schema.card_card_categories;
        p.tables.card_card_categories = ids.map((id, i) => Object.assign(Forge.rowDefault(p.schema.card_card_categories), { id: -(i + 1), card_id: p.source.cardId, card_category_id: id, num: i + 1 }));
        changes.push("Categories → " + ids.map((id) => (state.categories.find((c) => c.id === id) || {}).name).join(", "));
      } else if (kind === "art") {
        if (a.prompt) extras.artPrompts.push(String(a.prompt).slice(0, 4000));
      } else throw new Error("Unknown action: " + kind);
    }
    const check = Forge.validate(p);
    if (check.errors.length) throw new Error(check.errors[0]);
    return { changes, extras };
  }
  function extractActions(text) {
    const blocks = [...String(text).matchAll(/```(?:json)?\s*([\s\S]*?)```/g)].map((m) => m[1]);
    if (!blocks.length) { const i = text.indexOf('{"actions"'); if (i >= 0) blocks.push(text.slice(i)); }
    for (const block of blocks) {
      try {
        const parsed = JSON.parse(block.trim());
        if (parsed && Array.isArray(parsed.actions)) return parsed.actions;
      } catch {}
    }
    return null;
  }
  async function context() {
    const ctx = { names: { category: (id) => ((state.categories || []).find((c) => c.id === Number(id)) || {}).name }, subTargets: null, activeViews: {} };
    if (!(state.categories || []).length) await loadLookups();
    if (!ui.subTargets && state.info.schema.sub_target_types) {
      const all = [];
      for (let offset = 0; ; offset += 5000) { const rows = await Native.call("query", { table: "sub_target_types", offset, limit: 5000 }); all.push(...rows); if (rows.length < 5000) break; }
      ui.subTargets = all;
    }
    ctx.subTargets = ui.subTargets;
    if (!ui.activeViews) {
      ui.activeViews = {};
      try { for (const r of await Native.call("query", { table: "active_skill_sets", ids: [388, 342], limit: 2 })) ui.activeViews[r.id === 388 ? "attack" : "buff"] = r; } catch {}
    }
    ctx.activeViews = ui.activeViews;
    return ctx;
  }

  // ------------------------------------------------------------ helper (chat)
  const historyKey = () => "forge-ai-chat-" + (state.project ? state.project.key : "none");
  function loadHistory() { try { ui.history = JSON.parse(localStorage.getItem(historyKey()) || "[]").slice(-30); } catch { ui.history = []; } }
  function saveHistory() { try { localStorage.setItem(historyKey(), JSON.stringify(ui.history.slice(-30))); } catch {} }
  function bubble(m, i) {
    const text = String(m.content || ""), actions = m.role === "assistant" ? extractActions(text) : null;
    const prose = text.replace(/```[\s\S]*?```/g, "").trim();
    return '<div class="aic-msg ' + m.role + '"><div class="aic-text">' + h(prose || (actions ? "Here are the changes:" : "")).replace(/\n/g, "<br>") + "</div>" + (actions ? '<div class="aic-actions"><button type="button" class="button small" data-aic-review="' + i + '">Review ' + actions.length + " change" + (actions.length === 1 ? "" : "s") + "</button></div>" : "") + "</div>";
  }
  async function openHelper(prefill) {
    await loadConnections();
    loadHistory();
    const c = conn();
    const chips = [["Design a complete LR unit from my idea", "Design a complete, balanced LR version of this unit: leader, passive, Super Attack, Ultra Super Attack, Active Skill, links and categories."], ["Make my passive stronger", "Make my passive skill stronger but still balanced like a new Dokkan LR."], ["Give it a cool Ultra Super Attack", "Create an Ultra Super Attack with a cool name and fitting effects."], ["Pick Links & Categories", "Choose 7 fitting Link Skills and the right Categories for this character."], ["Explain my unit", "Explain what my unit does in battle in simple words. Don't change anything."], ["Write an art prompt", "Write a detailed prompt for new card art for this character (use an art action)."]];
    const d = modal("aic-helper", "✦ AI helper", '<div class="aic-bar">' + (c ? '<span class="chip teal">' + h(PROVIDERS[c.provider].name) + " · " + h(modelOf(c)) + "</span>" : '<span class="chip">Copy & paste mode — works with any AI app</span>') + '<button type="button" class="button subtle small" id="aic-settings-open">' + (c ? "AI settings" : "Connect an AI") + '</button>' + (ui.history.length ? '<button type="button" class="button subtle small" id="aic-clear">New chat</button>' : "") + '</div><div class="aic-log" id="aic-log">' + (ui.history.length ? ui.history.map(bubble).join("") : '<p class="hint">Ask anything about your unit, Dokkan mechanics, or the app. Ask for changes and the helper prepares them for you to review and apply — every change can be undone.</p>') + '</div><div class="aic-chips">' + chips.map(([n, t]) => '<button type="button" class="bld-chip" data-aic-chip="' + h(t) + '">' + h(n) + "</button>").join("") + '</div><label class="field">Message<textarea id="aic-input" rows="3" maxlength="8000" placeholder="e.g. Make it a Super AGL LR Gogeta with a Fusion leader and a 50% chance to launch an additional Super Attack">' + h(prefill || "") + '</textarea></label><p id="aic-status-h" class="hint" role="status"></p><div class="row">' + (c ? '<button type="button" class="button" id="aic-send">Send</button><button type="button" class="button ghost" id="aic-stop" hidden>Stop</button>' : "") + '<button type="button" class="button ' + (c ? "subtle" : "") + '" id="aic-copy">' + (c ? "Copy & paste instead" : "Copy prompt for my AI app") + '</button></div><details id="aic-paste"' + (c ? "" : " open") + '><summary>Paste a reply from any AI app</summary><p class="hint">Copy the prompt, paste it into ChatGPT, Gemini, Claude, Grok, Copilot or any other AI app, then paste its whole answer here.</p><label class="field">AI reply<textarea id="aic-reply" rows="5"></textarea></label><button type="button" class="button ghost" id="aic-use">Use this reply</button></details><div id="aic-review"></div>');
    const log = d.querySelector("#aic-log"), status = (t, err) => { const e = d.querySelector("#aic-status-h"); if (e) { e.textContent = t; e.className = err ? "bld-warn" : "hint"; } };
    log.scrollTop = log.scrollHeight;
    d.querySelector("#aic-settings-open").onclick = () => { d.close(); openSettings().catch(fail); };
    const clear = d.querySelector("#aic-clear");
    if (clear) clear.onclick = () => { ui.history = []; saveHistory(); openHelper().catch(fail); };
    d.querySelectorAll("[data-aic-chip]").forEach((b) => b.onclick = () => { d.querySelector("#aic-input").value = b.dataset.aicChip; d.querySelector("#aic-input").focus(); });
    d.querySelectorAll("[data-aic-review]").forEach((b) => b.onclick = () => review(ui.history[Number(b.dataset.aicReview)].content, d).catch((e) => status(e.message, true)));
    const send = d.querySelector("#aic-send");
    if (send) send.onclick = async () => {
      const text = d.querySelector("#aic-input").value.trim();
      if (!text || ui.busy) return;
      ui.busy = true; send.disabled = true; d.querySelector("#aic-stop").hidden = false;
      ui.history.push({ role: "user", content: text }); saveHistory();
      log.insertAdjacentHTML("beforeend", bubble(ui.history[ui.history.length - 1]));
      d.querySelector("#aic-input").value = "";
      d.querySelector("#aic-stop").onclick = () => { ui.cancel = true; };
      try {
        await context();
        const reply = await chat(ui.history.slice(-12), systemPrompt(), (s) => status("Thinking… " + s + "s"));
        ui.history.push({ role: "assistant", content: reply }); saveHistory();
        status("");
        openHelper().catch(fail);
        if (extractActions(reply)) { const dd = document.getElementById("aic-helper"); if (dd) review(reply, dd).catch((e) => status(e.message, true)); }
      } catch (e) { status(e.message || String(e), true); ui.history.pop(); saveHistory(); }
      finally { ui.busy = false; send.disabled = false; const stop = d.querySelector("#aic-stop"); if (stop) stop.hidden = true }
    };
    d.querySelector("#aic-copy").onclick = async () => {
      const text = d.querySelector("#aic-input").value.trim() || "Help me improve this unit.";
      await context();
      const full = systemPrompt() + "\n\nCONVERSATION\n" + ui.history.slice(-8).map((m) => (m.role === "user" ? "User: " : "Assistant: ") + m.content).join("\n") + "\nUser: " + text;
      ui.history.push({ role: "user", content: text }); saveHistory();
      await Native.call("copy", { text: full });
      d.querySelector("#aic-paste").open = true;
      status("Prompt copied. Paste it into your AI app, then paste its reply below.");
    };
    d.querySelector("#aic-use").onclick = async () => {
      const reply = d.querySelector("#aic-reply").value.trim();
      if (!reply) return status("Paste the AI's reply first.", true);
      ui.history.push({ role: "assistant", content: reply }); saveHistory();
      await openHelper();
      const dd = document.getElementById("aic-helper");
      if (extractActions(reply)) review(reply, dd).catch((e) => status(e.message, true));
      else status("Saved the reply. It has no changes to apply.");
    };
  }
  async function review(text, d) {
    const actions = extractActions(text);
    if (!actions) throw new Error("This reply has no changes to apply.");
    if (!state.project) throw new Error("Open or create a unit first.");
    const ctx = await context(), baseline = JSON.stringify(state.project), copy = Forge.clone(state.project);
    let result;
    try { result = applyActions(copy, actions, ctx); } catch (e) { d.querySelector("#aic-review").innerHTML = '<div class="bld-warn"><strong>These changes can’t be applied:</strong> ' + h(e.message) + "<br>Ask the AI to fix it, or tell it what went wrong.</div>"; return; }
    const box = d.querySelector("#aic-review");
    box.innerHTML = '<section class="aic-preview"><h3>Review the changes</h3><ul>' + result.changes.map((c) => "<li>" + h(c) + "</li>").join("") + "</ul>" + result.extras.artPrompts.map((pr, i) => '<p class="hint"><strong>Art idea:</strong> ' + h(pr) + '</p><button type="button" class="button ghost small" data-aic-art="' + i + '">Create this art</button>').join("") + '<div class="row">' + (result.changes.length ? '<button type="button" class="button" id="aic-apply">Apply to my unit</button>' : "") + '<button type="button" class="button ghost" id="aic-discard">Not now</button></div></section>';
    box.scrollIntoView({ block: "nearest" });
    box.querySelectorAll("[data-aic-art]").forEach((b) => b.onclick = () => { d.close(); openArt(result.extras.artPrompts[Number(b.dataset.aicArt)]).catch(fail); });
    box.querySelector("#aic-discard").onclick = () => box.textContent="";
    const apply = box.querySelector("#aic-apply");
    if (apply) apply.onclick = async () => {
      if (JSON.stringify(state.project) !== baseline) return review(text, d);
      const live = state.project;
      applyActions(live, actions, ctx);
      if (window.ForgeBuilderUI) ForgeBuilderUI.refreshTexts();
      scheduleSave();
      await flushSave().catch(fail);
      d.close();
      if (state.view === "editor") renderEditor(); else await navigate("editor");
      toast("AI changes applied. Use Undo if you want them back.");
    };
  }

  // ------------------------------------------------------------ art generator
  const POSES = [["super", "unleashing a Super Attack, dynamic foreshortened action pose, energy blast"], ["power", "powering up, clenched fists, explosive aura and flying debris"], ["fly", "flying toward the viewer, motion lines, intense stare"], ["stand", "confident standing pose, arms crossed, cape of energy"], ["portrait", "close-up heroic portrait, determined expression"]];
  const AURA = ["blue", "green", "purple", "red", "orange"];
  function artPrompt(f) {
    const p = state.project, c = p ? Forge.card(p) : null, parts = c ? B.elementParts(c.element) : { type: 0, cls: 1 };
    const subject = f.subject || (c ? c.name : "an original Dragon Ball style warrior");
    const kind = f.kind === "cutout" ? "Character only, full body, isolated on a transparent background, no background scenery, clean edges." : f.kind === "background" ? "Background only: dramatic battle sky and energy, no characters, no text." : "Full card illustration with a dramatic battlefield background.";
    return "Dragon Ball Z Dokkan Battle style card artwork of " + subject + ", " + (POSES.find(([k]) => k === f.pose) || POSES[0])[1] + ". Anime cel shading, bold clean line art, vivid " + AURA[parts.type] + " " + (parts.cls === 2 ? "menacing dark" : "heroic") + " aura, speed lines, glowing ki effects, high detail, dynamic composition, portrait orientation. " + kind + " No text, no logos, no watermark." + (f.extra ? " " + f.extra : "");
  }
  async function openArt(prefillPrompt) {
    await loadConnections();
    const ic = imageProvider(), p = state.project, c = p ? Forge.card(p) : null;
    const d = modal("aic-art", "◈ Create card art with AI", '<p class="hint">' + (ic ? "Generating with <strong>" + h(PROVIDERS[ic.provider].name) + "</strong> (" + h(imageModelOf(ic)) + ")." : "No image AI is connected. You can still copy the prompt into any image app (ChatGPT, Gemini, Grok, Copilot, Midjourney…) and import the picture. Connect OpenAI, Gemini or Grok to generate right here.") + '</p><div class="field-grid"><label class="field">Who is in the art?<input id="aic-subject" value="' + h(c ? c.name : "") + '"></label><label class="field">Pose<select id="aic-pose">' + selection(POSES.map(([k, v]) => [k, v.split(",")[0]]), "super") + '</select></label><label class="field">What to make<select id="aic-kind">' + selection([["cutout", "Character cut-out (transparent background)"], ["full", "Full card art with background"], ["background", "Background only"]], "cutout") + '</select></label><label class="field">Extra details (optional)<input id="aic-extra" placeholder="golden hair, torn gi, red scarf…"></label></div><label class="field">Prompt sent to the AI<textarea id="aic-prompt" rows="5">' + h(prefillPrompt || "") + '</textarea></label><p id="aic-status-a" class="hint" role="status"></p><div class="row">' + (ic ? '<button type="button" class="button" id="aic-generate">Generate art</button>' : "") + (conn() ? '<button type="button" class="button ghost" id="aic-improve">Improve prompt with AI</button>' : "") + '<button type="button" class="button ' + (ic ? "subtle" : "") + '" id="aic-art-copy">Copy prompt</button><button type="button" class="button subtle" id="aic-art-settings">AI settings</button></div><div id="aic-art-result"></div>');
    const status = (t, err) => { const e = d.querySelector("#aic-status-a"); e.textContent = t; e.className = err ? "bld-warn" : "hint"; };
    const form = () => ({ subject: d.querySelector("#aic-subject").value.trim(), pose: d.querySelector("#aic-pose").value, kind: d.querySelector("#aic-kind").value, extra: d.querySelector("#aic-extra").value.trim() });
    const sync = () => { d.querySelector("#aic-prompt").value = artPrompt(form()); };
    if (!prefillPrompt) sync();
    d.querySelectorAll("#aic-subject,#aic-pose,#aic-kind,#aic-extra").forEach((e) => e.oninput = e.onchange = sync);
    d.querySelector("#aic-art-settings").onclick = () => { d.close(); openSettings().catch(fail); };
    d.querySelector("#aic-art-copy").onclick = async () => { await Native.call("copy", { text: d.querySelector("#aic-prompt").value }); status("Prompt copied. Make the picture in your image app, save it, then use Import an image."); showImport(d); };
    const improve = d.querySelector("#aic-improve");
    if (improve) improve.onclick = async () => {
      try {
        status("Improving…");
        const better = await chat([{ role: "user", content: "Rewrite this as one vivid image-generation prompt (max 120 words, no preamble):\n" + d.querySelector("#aic-prompt").value }], "You write prompts for anime card artwork in the style of Dragon Ball Z Dokkan Battle.", (s) => status("Improving… " + s + "s"));
        d.querySelector("#aic-prompt").value = better.replace(/^["'\s]+|["'\s]+$/g, "");
        status("Prompt improved. Generate when ready.");
      } catch (e) { status(e.message, true); }
    };
    const gen = d.querySelector("#aic-generate");
    if (gen) gen.onclick = async () => {
      if (ui.busy) return;
      ui.busy = true; gen.disabled = true;
      try {
        const f = form();
        const result = await generateImage(d.querySelector("#aic-prompt").value, { transparent: f.kind === "cutout" }, (s) => status("Creating your art… " + s + "s (this can take a minute)"));
        const stored = await Native.call("storeAsset", { name: "AI art · " + (f.subject || "card") + ".png", data: result.base64 });
        const url = await Native.call("assetUrl", { key: stored.key });
        ui.artResult = { key: stored.key, url };
        status("Done! Saved to your imported pictures as “AI art · " + (f.subject || "card") + "”.");
        const box = d.querySelector("#aic-art-result");
        box.innerHTML = '<div class="aic-art"><img src="' + h(url) + '" alt="Generated artwork"><div class="row">' + (state.project ? '<button type="button" class="button" id="aic-use-preview">Show on my card preview</button><button type="button" class="button ghost" id="aic-use-game">Put it in the in-game card art</button>' : "") + '<button type="button" class="button subtle" id="aic-again">Generate another</button></div><p class="hint">“In-game card art” opens the artwork editor: choose this picture under Imported pictures, fit it, and apply. It’s then exported with your unit.</p></div>';
        const again = box.querySelector("#aic-again");
        again.onclick = () => gen.click();
        const usePrev = box.querySelector("#aic-use-preview");
        if (usePrev) usePrev.onclick = () => { state.project.previewKey = stored.key; state.previewUrl = url; scheduleSave(); toast("Your card preview now uses this art."); d.close(); if (state.view === "editor") renderEditor(); };
        const useGame = box.querySelector("#aic-use-game");
        if (useGame) useGame.onclick = async () => { d.close(); state.project.previewKey = stored.key; state.previewUrl = url; scheduleSave(); await ForgeArtEditor.open(); toast("Choose “AI art · " + (f.subject || "card") + "” under Imported pictures."); };
      } catch (e) { status(e.message || String(e), true); } finally { ui.busy = false; gen.disabled = false; }
    };
  }
  function showImport(d) {
    const box = d.querySelector("#aic-art-result");
    if (box.querySelector("#aic-import")) return;
    box.insertAdjacentHTML("beforeend", '<div class="row"><button type="button" class="button ghost" id="aic-import">Import an image</button></div>');
    box.querySelector("#aic-import").onclick = async () => { d.close(); if (state.project) await ForgeArtEditor.open(); else await importFile(); };
  }

  // ------------------------------------------------------------ entry points
  function refreshPage() { if (state.view === "ai") renderAI(); else if (state.view === "editor" && state.project) renderEditor(); }
  const priorAI = renderAI;
  renderAI = async function() {
    await priorAI.apply(this, arguments);
    if (state.view !== "ai") return;
    await loadConnections(true);
    const c = conn(), section = document.createElement("section");
    section.className = "panel aic-hub";
    section.innerHTML = '<p class="eyebrow">CONNECT ANY AI</p><h2>' + (c ? "✓ " + h(PROVIDERS[c.provider].name) + " is connected" : "Connect your AI of choice") + "</h2><p class=\"hint\">" + (c ? "The AI helper can now chat and change your unit right here" + (imageProvider() ? ", and generate card art." : ". Connect OpenAI, Gemini or Grok as well to generate pictures.") : "Paste an API key from ChatGPT/OpenAI, Gemini, Claude, Grok, OpenRouter or any OpenAI-compatible server. Or use copy & paste mode with any AI app — no key needed.") + '</p><div class="row"><button type="button" class="button" id="aic-hub-helper">✦ Open AI helper</button><button type="button" class="button ghost" id="aic-hub-art">◈ Create card art</button><button type="button" class="button subtle" id="aic-hub-settings">' + (c ? "AI settings" : "Connect an AI") + "</button></div>";
    const main = document.getElementById("main");
    const first = main.querySelector(".creation-ai-hero, .section-heading");
    if (first) first.after(section); else main.prepend(section);
    section.querySelector("#aic-hub-helper").onclick = () => openHelper().catch(fail);
    section.querySelector("#aic-hub-art").onclick = () => openArt().catch(fail);
    section.querySelector("#aic-hub-settings").onclick = () => openSettings().catch(fail);
  };
  window.ForgeAIConnect = { context, openSettings, openHelper, openArt, chat, generateImage, applyActions, extractActions, systemPrompt, loadConnections, providers: PROVIDERS };
})();
