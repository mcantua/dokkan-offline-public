/* Original completion UI around the real shared Creator editor. MIT. */
(function () {
  'use strict';
  const host = window.OfflineCreatorHost;
  if (!host || !window.OfflineDokkanCreator) throw Error('The Offline Creator projection is unavailable.');
  document.documentElement.classList.add('offline-creator-host');
  // Legacy internal host uses a neutral placeholder. The real native tools
  // retain their actual scoped/cache-backed artwork and iPhone adapter.
  if (!window.OfflineCreatorTools) resourceThumb = () => 'data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" width="120" height="160" viewBox="0 0 120 160"%3E%3Crect width="120" height="160" fill="%23192737"/%3E%3Cpath d="M60 38l10 20 22 3-16 16 4 22-20-11-20 11 4-22-16-16 22-3z" fill="%23dbb15a"/%3E%3C/svg%3E';
  document.title = 'Unit Creator · Offline Dokkan';
  const originalTemplate = Forge.loadTemplate;
  Forge.loadTemplate = async function (...args) { const project = await originalTemplate.apply(this, args); host.pinSource(project); return project; };
  const CV = window.ForgeCardVersions;
  if (CV) {
    const oldLoad = CV.load, oldCollapse = CV.collapse;
    CV.load = database => oldLoad(database || host.game());
    CV.collapse = (rows, options = {}) => oldCollapse(rows, { database: host.game(), ...options });
    for (const name of ['status', 'badge', 'label', 'finalId', 'isAwakenedFurther', 'isPlayerCard']) {
      const previous = CV[name]; CV[name] = (row, database) => previous(row, database || host.game());
    }
  }
  if (!window.OfflineCreatorTools && window.ForgeSparking) ForgeSparking.mountLibraryEntry = target => {
    if (!target) return;
    const note = document.createElement('p'); note.className = 'hint'; note.textContent = 'Character references come from your selected game database. This Offline host does not distribute a separate wiki or game-data snapshot.'; target.replaceChildren(note);
  };
  const originalCreate = createUnit;
  createUnit = async function (...args) {
    await originalCreate.apply(this, args);
    if (state.project && host.pinSource(state.project)) { scheduleSave(); await flushSave(); }
  };
  // Authored mechanic labels remain UI code; game-specific records were removed
  // from the distributed bundle and are resolved from the selected master.
  Object.assign(window.FORGE_MECHANICS, { efficacies: Object.entries(ForgeGuide.effectNames || {}).map(([id, name]) => ({ id: Number(id), name, description: name, values: [] })) });
  const builder = window.ForgeBuilder;
  window.FORGE_GUIDE_DATA.conditionTypes.push(...(builder?.CONDITIONS || []).map(def => [String(def.type), '', def.label, ...(def.fields || []).map(field => field.label).slice(0, 3)]));
  const groups = new Map((builder?.PASSIVE || []).map(def => [def.eff, def.group]));
  const abilities = host.references.abilities.map(ability => ({ ...ability, label: ForgeGuide.effectNames[ability.eff] || ability.name || 'Inherited ability', about: 'Observed in your selected game database.', values: [], group: groups.get(ability.eff) || 'Special' }));
  Object.assign(window.ForgePassiveCatalogData, { count: abilities.length, abilities });
  let working = false;
  const canonical = value => {
    if (Array.isArray(value)) return '[' + value.map(canonical).join(',') + ']';
    if (value && typeof value === 'object') return '{' + Object.keys(value).sort().map(key => JSON.stringify(key) + ':' + canonical(value[key])).join(',') + '}';
    return JSON.stringify(value);
  };
  // Compare the actual native wire model: JSON drops undefined object fields
  // and serializes undefined array entries as null, just like flushSave's clone.
  const stable = value => canonical(JSON.parse(JSON.stringify(value)));
  async function finish() {
    if (working) return;
    if (!state.project) throw Error('Create or open a saved unit first.');
    working = true; update();
    try {
      let changed = host.pinSource(state.project);
      if (await Forge.hydrateStatGrowth(state.project, options => Native.call('query', options), state.info.schema)) changed = true;
      if (changed) scheduleSave();
      await flushSave();
      const current = state.project, key = current.key, before = stable(current);
      const prepared = await host.call('offlineCreatorPrepare', { key });
      if (!prepared || typeof prepared.snapshot !== 'string' || !prepared.snapshot || !prepared.project || !prepared.context || !Array.isArray(prepared.unchangedTables) || prepared.unchangedTables.some(table => typeof table !== 'string')) throw Error('The Offline host could not prepare a pinned saved unit.');
      // Keep the native snapshot and live-draft guards independent. Returning
      // only a generic stale message hid which boundary failed in the WK host.
      // Codes deliberately contain no project fields, values or native paths.
      if (state.project !== current) throw Error('CREATOR_PREPARE_DRAFT_REPLACED');
      if (stable(current) !== before) throw Error('CREATOR_PREPARE_DRAFT_CHANGED');
      if (prepared.project.key !== key) throw Error('CREATOR_PREPARE_KEY_MISMATCH');
      if (stable(prepared.project) !== before) {
        const error = Error('CREATOR_PREPARE_SAVED_MISMATCH');
        // Value-free diagnostics of the ACTUAL final prepare, not an earlier
        // caller snapshot (Finish may hydrate source growth before saving).
        const a = current.sourceStatGrowth, b = prepared.project.sourceStatGrowth;
        const fields = ['policy', 'sourceGrowType', 'rows'];
        error.savedBoundary = { growthPresent: !!a && !!b, growthFields: fields.filter(key => stable(a?.[key] ?? null) !== stable(b?.[key] ?? null)) };
        if (Array.isArray(a?.rows) && Array.isArray(b?.rows)) {
          error.savedBoundary.sameGrowthRowCount = a.rows.length === b.rows.length;
          for (let i = 0; i < Math.min(a.rows.length, b.rows.length); i++) {
            for (const column of ['lv', 'coef']) {
              const live = a.rows[i]?.[column], saved = b.rows[i]?.[column];if (live === saved) continue;
              error.savedBoundary.firstGrowthDifference = { rowIndex: i, column, liveType: typeof live, savedType: typeof saved, bothFinite: Number.isFinite(live) && Number.isFinite(saved), sameThousandth: Number.isFinite(live) && Number.isFinite(saved) && Math.round(live * 1000) === Math.round(saved * 1000), withinOneULP: Number.isFinite(live) && Number.isFinite(saved) && Math.abs(live - saved) <= Number.EPSILON * Math.max(Math.abs(live), Math.abs(saved)) };
              break;
            }
            if (error.savedBoundary.firstGrowthDifference) break;
          }
        }
        throw error;
      }
      if (prepared.fullBundle === true) {
        if (state.project !== current) throw Error('CREATOR_IMPORT_DRAFT_REPLACED');
        if (stable(current) !== before) throw Error('CREATOR_IMPORT_DRAFT_CHANGED');
        const result = await host.call('offlineCreatorFinish', { key, snapshot: prepared.snapshot });
        if (result?.imported !== true || result.account !== 'local-player' || typeof result.definitionId !== 'string' || !Number.isSafeInteger(result.version) || result.version < 1 || !Number.isSafeInteger(result.instanceId) || result.instanceId < 1 || typeof result.available !== 'boolean') throw Error('Offline import was not confirmed. Your saved project is kept; retry this same unit.');
        const main = result.library?.main_id === result.definitionId;
        status.textContent = (result.available ? 'Saved to your character collection. You can add this unit to a team.' : 'Design updated. Its original collection copy has already been used as training material; finishing again does not create another copy.') + (main ? ' This is your newest created unit.' : '') + ' Your editable project stays here.' + (result.banner?.drawable === true ? ' Its summon banner is ready.' : ' Summon availability is not configured yet.') + ' Battle integration must support this unit’s abilities and resources before it can fight.';
        status.setAttribute('role', 'status'); toast('Unit saved in Offline Dokkan.');
        window.dispatchEvent(new CustomEvent('offline-creator-finished', { detail: { definitionId: result.definitionId, version: result.version, instanceId: result.instanceId, available: result.available, newest: main } }));
        return result;
      }
      const proven = new Set(prepared.unchangedTables);
      const context = { ...prepared.context, isUnchangedMasterRows: async table => proven.has(table) };
      const definition = await OfflineDokkanCreator.projectToDefinition(prepared.project, context);
      if (state.project !== current) throw Error('CREATOR_IMPORT_DRAFT_REPLACED');
      if (stable(current) !== before) throw Error('CREATOR_IMPORT_DRAFT_CHANGED');
      const result = await host.call('offlineCreatorFinish', { key, snapshot: prepared.snapshot, definition });
      if (result?.imported !== true || result.definitionId !== definition.definition_id || result.version !== definition.version || !Number.isSafeInteger(result.instanceId) || result.instanceId < 1 || typeof result.available !== 'boolean') throw Error('Offline import was not confirmed. Your saved project is kept; retry this same unit.');
      const main = result.library?.main_id === result.definitionId;
      status.textContent = (result.available ? 'Saved to your character collection. You can add this unit to a team.' : 'Design updated. Its original collection copy has already been used as training material; finishing again does not create another copy.') + (main ? ' This is your newest created unit.' : '') + ' Your editable project stays here.' + (result.banner?.drawable === true ? ' Its summon banner is ready.' : ' Summon availability is not configured yet.') + ' Battle integration must support this unit’s abilities and resources before it can fight.';
      status.setAttribute('role', 'status'); toast('Unit saved in Offline Dokkan.');
      window.dispatchEvent(new CustomEvent('offline-creator-finished', { detail: { definitionId: result.definitionId, version: result.version, instanceId: result.instanceId, available: result.available, newest: main } }));
      return result;
    } catch (error) {
      status.textContent = humanError(error.message); status.setAttribute('role', 'alert'); throw error;
    } finally { working = false; update(); }
  }
  function humanError(code) {
    const messages = {
      INVALID_INTEGER: 'A number setting is incomplete. Check the editor before finishing.',
      SOURCE_CONTENT_MISMATCH: 'This design belongs to different game data. Open it with its original database.',
      CREATOR_SNAPSHOT_STALE: 'This design changed while finishing. Save it and finish again.',
      CREATOR_PROJECTION_MISMATCH: 'The saved design and prepared settings differ. Save and finish again.',
      CREATOR_PREPARE_DRAFT_REPLACED: 'The open unit changed while preparing. Open the unit you want and finish again.',
      CREATOR_PREPARE_DRAFT_CHANGED: 'This design changed while preparing. Wait for it to save and finish again.',
      CREATOR_PREPARE_KEY_MISMATCH: 'The host prepared a different unit. Your design was not imported.',
      CREATOR_PREPARE_SAVED_MISMATCH: 'The saved design does not match the open unit. Save and finish again.',
      CREATOR_IMPORT_DRAFT_REPLACED: 'The open unit changed before import. Open the unit you want and finish again.',
      CREATOR_IMPORT_DRAFT_CHANGED: 'This design changed before import. Wait for it to save and finish again.',
      CUSTOM_ASSET_INTEGRATION_REQUIRED: 'This saved unit has custom artwork or resource files. Their Offline gameplay integration is not ready. Your full editable unit is kept.',
      CUSTOM_RUNTIME_INTEGRATION_REQUIRED: 'This saved unit has custom gameplay animation bindings. Offline battle playback integration is not ready. Your full editable unit is kept.',
      MULTIFORM_INTEGRATION_REQUIRED: 'This saved unit has linked forms. Their Offline gameplay integration is not ready. Your full editable unit is kept.',
      OFFICIAL_AWAKENING_NOT_SHAREABLE: 'EZA and Super EZA edits use the separate owned-card upgrade flow. They cannot be added as new created units.',
      UNSUPPORTED_MODIFIED_TABLE: 'This unit changes a setting that Offline Dokkan cannot apply yet. Nothing was discarded; your full project remains saved.',
      UNSUPPORTED_CREATOR_PROJECT: 'This unit still needs the full check before it can join your collection. Your design is still saved.',
      FULL_BUNDLE_PAGE_DESCRIPTOR_REJECTED: 'The editor cannot supply its own finished packet. Finish again so the saved account can check the unit.',
      FULL_BUNDLE_SAVE_SCOPE_MISMATCH: 'This unit does not belong to the open saved account. Nothing was added.'
    };
    if (messages[code]) return messages[code];
    if (typeof code === 'string' && code.startsWith('FULL_BUNDLE_')) return 'This unit did not pass the full check, so it was not added to your collection. Your design is still saved.';
    return code;
  }
  const bar = document.createElement('section'); bar.className = 'offline-creator-completion'; bar.setAttribute('aria-label', 'Offline Dokkan unit completion');
  const heading = document.createElement('strong'); heading.textContent = 'Unit Creator · Offline Dokkan';
  const note = document.createElement('p'); note.textContent = 'Create a unit for this game. Finish adds its supported settings to your character collection and keeps the design editable. Your imported source data stays unchanged.';
  const button = document.createElement('button'); button.type = 'button'; button.className = 'button'; button.textContent = 'Finish in Offline Dokkan';
  const status = document.createElement('p'); status.className = 'hint'; status.setAttribute('aria-live', 'polite');
  bar.append(heading, note, button, status); document.querySelector('.workspace').prepend(bar);
  button.onclick = () => finish().catch(error => toast(humanError(error.message), true));
  function update() { button.disabled = working || !state.project; button.textContent = working ? 'Saving to Offline Dokkan…' : 'Finish in Offline Dokkan'; }
  function saveHTML() {
    const check = Forge.validate(state.project);
    const errors = (check.errors || []).map(error => { const item = document.createElement('li'); item.textContent = String(error); return item.outerHTML; }).join('');
    return '<section class="panel"><h2>Finish your unit</h2><p>Your design saves here automatically. Finish adds its supported settings to your collection, ready for team selection. Later edits keep the same character and progress.</p>' +
      (errors ? '<div class="notice"><ul>' + errors + '</ul></div>' : '') +
      '<button type="button" class="button" data-offline-finish' + (working || errors ? ' disabled' : '') + '>Finish in Offline Dokkan</button>' +
      '<p class="hint">Your source database stays unchanged. Battle abilities and animations must be supported by this game before the character can fight.</p></section>';
  }
  document.addEventListener('click', event => {
    if (event.target.closest('[data-offline-finish]')) finish().catch(error => toast(humanError(error.message), true));
  });
  function adaptScreens() {
    document.querySelectorAll('.dk-games').forEach(label => { label.textContent = 'Offline Dokkan'; });
    if (!window.OfflineCreatorTools) document.querySelectorAll('#main [data-dk="sparking"], #main [data-dk="offline"]').forEach(element => element.remove());
  }
  const originalMain = main;
  main = function () { const result = originalMain.apply(this, arguments); adaptScreens(); update(); return result; };
  update();
  window.OfflineCreatorUI = Object.freeze({ finish, humanError, saveHTML });
})();
