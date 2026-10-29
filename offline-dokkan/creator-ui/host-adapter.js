/* Original Offline host adapter for the actual Unit Creator screens. MIT.
 * Only the fixed native OfflineCreator capability is exposed. No SQL writes, paths,
 * network, game keys, inventory grants or generic core operations cross it. */
(function () {
  'use strict';
  const LIMIT = 32 * 1048576, pending = new Map(), fragments = new Map(); let sequence = 0;
  const allowed = new Set(['info', 'query', 'querySparking', 'creatorMasterRead', 'wipeCreatorDocuments', 'cardIndex', 'projects', 'loadProject', 'saveProject', 'deleteProject', 'patches', 'assets', 'settings', 'settingsSave', 'listProjectVersions', 'saveProjectVersion', 'loadProjectVersion', 'deleteProjectVersion', 'restoreProjectVersion', 'offlineCreatorPrepare', 'offlineCreatorFinish', 'offlineGameSnapshot', 'offlineCardStats', 'offlineTeamSet', 'offlineBattleLoad', 'offlineBattleDispatch']);
  function fail(message) { throw Error(message); }
  function reply(message) {
    if (!message || !Number.isSafeInteger(message.id)) return;
    const item = pending.get(message.id); if (!item) return;
    pending.delete(message.id); fragments.delete(message.id); clearTimeout(item.timer);
    message.ok === true ? item.resolve(message.result) : item.reject(Error(String(message.error || 'The Offline host could not complete this action.')));
  }
  window.__offlineCreatorReply = reply;
  window.__offlineCreatorReplyChunk = (id, index, total, text) => {
    const item = pending.get(id); if (!item) return;
    let f = fragments.get(id);
    try {
      if (!Number.isInteger(total) || total < 1 || total > 2048 || !Number.isInteger(index) || index < 0 || index >= total || typeof text !== 'string' || text.length > 24000) fail('Invalid native response chunks.');
      if (!f) { if (index !== 0) fail('Native response chunks are out of order.'); f = { total, next: 0, length: 0, parts: [] }; fragments.set(id, f); }
      if (f.total !== total || f.next !== index || (f.length += text.length) > LIMIT) fail('Native response chunks are incomplete or too large.');
      f.parts.push(text); f.next++;
      if (f.next === total) { const raw = f.parts.join(''); if (new TextEncoder().encode(raw).length > LIMIT) fail('Native response exceeds 32 MiB.'); const message = JSON.parse(raw); if (message.id !== id) fail('Native response identity mismatch.'); reply(message); }
    } catch (e) { reply({ id, ok: false, error: e.message }); }
  };
  function transport(op, args = {}) {
    if (op === 'querySparking' && info && game() !== 'sparking') return Promise.reject(Error('The selected master is Eclipse. A Sparking master is not available in this Creator session.'));
    if (!allowed.has(op)) return Promise.reject(Error('This Offline host does not expose that device or network action. Your unit remains saved in the Creator.'));
    const ios = window.webkit?.messageHandlers?.OfflineCreator;
    if (ios && typeof ios.postMessage === 'function') return Promise.resolve(ios.postMessage({ op, args }));
    if (!window.OfflineCreator || typeof window.OfflineCreator.postMessage !== 'function') return Promise.reject(Error('Open these Creator screens from Offline Dokkan after selecting your own game database.'));
    return new Promise((resolve, reject) => {
      const id = ++sequence, timer = setTimeout(() => { pending.delete(id); fragments.delete(id); reject(Error('The Offline host did not reply. Your last confirmed saved unit is kept.')); }, 120000);
      pending.set(id, { resolve, reject, timer });
      try { const text = JSON.stringify({ id, op, args }); if (new TextEncoder().encode(text).length > 24 * 1048576) fail('This Creator request exceeds 24 MiB.'); window.OfflineCreator.postMessage(text); } catch (e) { reply({ id, ok: false, error: e.message }); }
    });
  }
  const refs = { intros: [], domains: [], counters: [], revivals: [[0, 'No animation']], revivalMusic: {}, abilities: [] };
  window.OfflineCreatorReferences = refs;
  window.FORGE_GUIDE_DATA = { conditionTypes: [], calculationTypes: [], targets: [] };
  window.FORGE_MECHANICS = { efficacies: [] };
  window.ForgePassiveCatalogData = { count: 0, abilities: [] };
  window.ForgeMovieCatalog = { items: [] };
  let info;
  const game = () => info?.offlineCreator?.sourceDatabase;
  function pinSource(project) {
    if (!project?.source || !['eclipse', 'sparking'].includes(game())) fail('The saved unit has no valid selected game source.');
    if (project.source.database && project.source.database !== game()) fail('This unit belongs to a different selected game database.');
    if (project.source.contentId && project.source.contentId !== info.offlineCreator.contentId) fail('This unit belongs to a different selected game master.');
    let changed = project.source.database !== game() || project.source.contentId !== info.offlineCreator.contentId;
    project.source.database = game(); project.source.contentId = info.offlineCreator.contentId;
    for (const form of project.formProjects || []) if (pinSource(form)) changed = true;
    return changed;
  }
  async function rows(table, wanted) {
    const schema = info.schema[table]; if (!schema) return [];
    const names = new Set(schema.map(c => typeof c === 'string' ? c : c.name)), columns = wanted.filter(c => names.has(c));
    if (!columns.length) return [];
    const out = []; let bytes = 0;
    for (let offset = 0; offset < 100000; offset += 5000) {
      const page = await transport('query', { table, columns, offset, limit: 5000 });
      if (!Array.isArray(page) || page.length > 5000) fail('The selected master returned an invalid reference page.');
      bytes += new TextEncoder().encode(JSON.stringify(page)).length; if (bytes > 16 * 1048576) fail('The selected master reference table exceeds the UI memory budget.');
      out.push(...page); if (page.length < 5000) return out;
    }
    fail('The selected master reference table exceeds 100,000 records.');
  }
  async function references() {
    // All names/scene IDs come from the selected user's master at runtime.
    // These compact column projections replace the distributed game snapshots.
    const [cards, passives, relations, fields, fieldEffects] = await Promise.all([
      transport('cardIndex'), rows('passive_skills', ['id', 'name', 'passive_skill_effect_id', 'efficacy_type', 'target_type', 'calc_option', 'exec_timing_type', 'turn', 'probability', 'is_once', 'eff_value1', 'eff_value2', 'eff_value3', 'efficacy_values']),
      rows('passive_skill_set_relations', ['passive_skill_set_id', 'passive_skill_id']), rows('dokkan_fields', ['id', 'name', 'description', 'resource_id', 'dokkan_field_efficacy_set_id']), rows('dokkan_field_efficacies', ['dokkan_field_efficacy_set_id', 'efficacy_type', 'turn'])
    ]);
    if (!Array.isArray(cards)) fail('The selected master character index is invalid.');
    const owners = new Map(), sets = new Map();
    for (const c of cards) { if (!Array.isArray(c) || typeof c[1] !== 'string') continue; if (!owners.has(c[9])) owners.set(c[9], c[1]); }
    for (const r of relations) { const name = owners.get(r.passive_skill_set_id); if (name && !sets.has(r.passive_skill_id)) sets.set(r.passive_skill_id, name); }
    const intro = new Map(), counter = new Map(), revival = new Map(), turns = new Map(), abilities = new Map();
    for (const p of passives) {
      const name = sets.get(p.id) || p.name; if (!name) continue;
      if (sets.has(p.id) && Number.isSafeInteger(p.efficacy_type) && ![0, 103, 1009, 1011].includes(p.efficacy_type) && Number.isSafeInteger(p.calc_option) && Number.isSafeInteger(p.target_type)) {
        const key = [p.efficacy_type, p.calc_option, p.target_type].join('.');
        if (!abilities.has(key)) { if (abilities.size >= 5000) fail('The selected master has too many ability variants for this editor.'); abilities.set(key, { id: key, eff: p.efficacy_type, calc: p.calc_option, target: p.target_type, name: p.name, uses: 0, settings: new Map() }); }
        const ability = abilities.get(key); ability.uses++;
        const defaults = Object.fromEntries(['exec_timing_type', 'turn', 'probability', 'is_once', 'eff_value1', 'eff_value2', 'eff_value3', 'efficacy_values'].map(field => [field, p[field] ?? (field === 'efficacy_values' ? '{}' : 0)])), signature = JSON.stringify(defaults), observed = ability.settings.get(signature);
        if (observed) observed.count++; else ability.settings.set(signature, { count: 1, defaults });
      }
      if (p.passive_skill_effect_id > 0 && !intro.has(p.passive_skill_effect_id)) intro.set(p.passive_skill_effect_id, name);
      if ([120, 128].includes(p.efficacy_type) && p.eff_value3 > 0 && !counter.has(p.eff_value3)) counter.set(p.eff_value3, name);
      if (p.efficacy_type === 109 && p.eff_value2 > 0) { if (!revival.has(p.eff_value2)) revival.set(p.eff_value2, name); if (p.eff_value3 > 0) refs.revivalMusic[p.eff_value2] = p.eff_value3; }
    }
    for (const ability of abilities.values()) if (ability.uses >= 3) { const settings = [...ability.settings.values()].sort((a, b) => b.count - a.count); const { settings: ignored, ...record } = ability; refs.abilities.push({ ...record, defaults: settings[0].defaults }); }
    const ordered = map => [...map].sort((a, b) => a[1].localeCompare(b[1]) || a[0] - b[0]);
    refs.intros.push(...ordered(intro)); refs.counters.push(...ordered(counter)); refs.revivals.push(...ordered(revival));
    for (const effect of fieldEffects) if (effect.efficacy_type === 121 && Number.isInteger(effect.turn) && effect.turn > 0) turns.set(effect.dokkan_field_efficacy_set_id, effect.turn);
    for (const f of fields) if (turns.has(f.dokkan_field_efficacy_set_id)) refs.domains.push([f.id, f.name, f.description, f.resource_id, turns.get(f.dokkan_field_efficacy_set_id)]);
  }
  const ready = (async () => {
    info = await transport('info');
    if (!info || !info.schema || !['eclipse', 'sparking'].includes(game()) || typeof info.offlineCreator.contentId !== 'string') fail('The Offline host must pin a selected user master before opening the Creator.');
    info.sourceDatabase = game();
    info.meta = { ...info.meta, source: 'Dokkan ' + (game() === 'sparking' ? 'Sparking' : 'Eclipse') + ' · Your imported game database', date: info.offlineCreator.contentId };
    await references(); return info;
  })();
  window.OfflineGameHost = Object.freeze({
    ready,
    snapshot: async () => { await ready; return transport('offlineGameSnapshot'); },
    loadBattle: async () => { await ready; return transport('offlineBattleLoad'); },
    dispatchBattle: async command => {
      if (!command || typeof command !== 'object' || Array.isArray(command) || new TextEncoder().encode(JSON.stringify(command)).length > 65536) fail('This battle command is invalid or too large.');
      await ready; return transport('offlineBattleDispatch', { command });
    },
    cardStats: async instanceId => {
      if (!Number.isSafeInteger(instanceId) || instanceId < 1) fail('Choose an owned character.');
      await ready; return transport('offlineCardStats', { instanceId });
    },
    saveTeam: async (slot, members, intentId) => {
      if (!Number.isSafeInteger(slot) || slot < 0 || slot > 19 || !Array.isArray(members) || members.length > 6 || members.some(id => !Number.isSafeInteger(id) || id < 1) || new Set(members).size !== members.length || typeof intentId !== 'string' || !/^[A-Za-z0-9_.:-]{1,100}$/.test(intentId)) fail('Choose up to 6 different owned characters for this team.');
      await ready; return transport('offlineTeamSet', { slot, members, intentId });
    }
  });
  // Raw battle persistence intentionally stays native-only. A game page receives
  // load/dispatch from the isolated trusted coordinator, never storage/CAS.
  window.OfflineCreatorHost = Object.freeze({ ready, call: transport, game, pinSource, references: refs });
  window.forgeNative = { offlineCreator: true, call: async (method, args = {}) => {
    await ready;
    if (method === 'info') return info;
    if (method === 'sparkingInfo') return game() === 'sparking' ? { ...info, available: true } : { available: false, schema: {} };
    if (method === 'saveProject') pinSource(args.project);
    return transport(method, args);
  } };
})();
