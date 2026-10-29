/* Same-save authority around the actual iPhone Creator tools. MIT.
 * Generic tools never receive owner files, a second master, SQL writes or keys.
 * The selected-master read operation is separately bounded/readonly in Session. */
(function () {
  'use strict';
  const owner = window.OfflineCreatorHost, IOS = window.__forgeIOS, web = window.__forgeWeb;
  if (!owner || !IOS || !web || !window.ForgeHost) throw Error('The complete native Creator tools are unavailable.');
  const H = web.handlers, selected = 'native:selected-master', fail = message => { throw Error(message); };
  const authority = new Set(['info', 'query', 'cardIndex', 'projects', 'loadProject', 'saveProject', 'deleteProject', 'settings', 'settingsSave', 'listProjectVersions', 'saveProjectVersion', 'loadProjectVersion', 'deleteProjectVersion', 'restoreProjectVersion', 'offlineCreatorPrepare', 'offlineCreatorFinish']);
  const rejectedGame = new Set(['offlineGameSnapshot', 'offlineCardStats', 'offlineTeamSet', 'offlineBattleLoad', 'offlineBattleDispatch']);
  for (const op of authority) H[op] = async args => {
    await owner.ready;
    if (op === 'info') return owner.ready;
    if (op === 'saveProject') owner.pinSource(args.project);
    return owner.call(op, args || {});
  };
  // Compatibility labels identify one pinned readonly master, not two saves.
  IOS.openDb = async kind => { if (!['main', 'sparking'].includes(kind)) fail('Unknown character reference.'); const info = await owner.ready; return { path: selected, schema: info.schema }; };
  IOS.dbPath = async kind => (await IOS.openDb(kind)).path;
  IOS.sql = async (token, sql, params = []) => { if (token !== selected) fail('Use the selected character reference.'); return owner.call('creatorMasterRead', { sql, params }); };
  IOS.queryDatabase = async (kind, args) => { await IOS.openDb(kind); return owner.call('query', args || {}); };
  IOS.saveProjectNow = project => H.saveProject({ project });
  IOS.prepareSparkingSnapshot = async () => { await owner.ready; };
  IOS.storeState = async kind => { await IOS.openDb(kind); const info = await owner.ready; return { version: 1, active: { file: selected, meta: info.meta } }; };
  H.querySparking = args => owner.call('query', args || {});
  web.query = args => owner.call('query', args || {});
  H.sparkingInfo = async () => { const info = await owner.ready; return { ...info, available: true, selectedMaster: true, keyConfigured: !!(await ForgeHost.call('sourceCodecStatus')).configured }; };
  let catalog;
  H.sparkingCatalog = async (args = {}) => {
    if (!catalog) catalog = (async () => {
      const info = await owner.ready, count = Number((await IOS.sql(selected, 'SELECT count(*) AS n FROM cards'))[0]?.n);
      if (!Number.isSafeInteger(count) || count < 0 || count > 10000000) fail('The selected character catalog is too large or invalid.');
      const rows = [];let bytes = 0;
      for (let offset = 0; offset < count; offset += 5000) {
        const page = await owner.call('query', { table: 'cards', offset, limit: 5000 });
        if (!Array.isArray(page) || page.length !== Math.min(5000, count - offset)) fail('The selected character catalog changed while loading.');
        bytes += new TextEncoder().encode(JSON.stringify(page)).length;if (bytes > 64 * 1048576) fail('The selected character catalog exceeds the editor memory budget.');
        rows.push(...page);
      }
      const final = await ForgeCardVersions.collapse(rows, { database: owner.game() }), rank = { seza: 2, eza: 1, '': 0 };
      return final.sort((a, b) => (rank[ForgeCardVersions.status(b, owner.game())] || 0) - (rank[ForgeCardVersions.status(a, owner.game())] || 0) || String(a.name).localeCompare(String(b.name)) || b.rarity - a.rarity || a.id - b.id);
    })().catch(error => { catalog = null;throw error; });
    const search = String(args.search || '').trim().toLowerCase(), offset = Math.max(0, Math.trunc(Number(args.offset) || 0)), limit = Math.max(1, Math.min(120, Math.trunc(Number(args.limit) || 120)));
    const rows = (await catalog).filter(row => !search || String(row.name).toLowerCase().includes(search));
    return { items: rows.slice(offset, offset + limit), more: rows.length > offset + limit, total: rows.length };
  };
  // Import/export adapters retain local media/codec support. Activating a new
  // player master requires the host's explicit close/rebind admission instead
  // of committing ios-native's separate database-state.json behind its back.
  const rebind = async () => fail('Save and return to Offline Dokkan before changing its selected game data. Your imported files and current unit are kept.');
  IOS.commitDb = rebind;IOS.useDb = rebind;IOS.downloadCurrentDatabase = rebind;H.sync = rebind;H.restoreDatabase = rebind;H.syncSparking = rebind;
  const nativeCall = ForgeHost.call.bind(ForgeHost);
  IOS.verifyDb = async (path, strict) => {
    const opened = await nativeCall('sourceDatabaseOpen', { path });
    if (!opened?.readOnly || opened.selectedMaster !== false || typeof opened.handle !== 'string') fail('The source database could not be opened read-only.');
    const read = async (kind, table) => { const result = await nativeCall('sourceDatabaseRead', { handle: opened.handle, kind, ...(table ? { table } : {}) });return result.rows.map(row => Object.fromEntries(result.columns.map((column, i) => [column, row[i]]))); };
    try {
      const integrity = await read('quickCheck');if (!integrity.length || Object.values(integrity[0])[0] !== 'ok') fail('Database integrity check failed.');
      const required = { cards: ['id', 'name', 'rarity', 'element', 'resource_id', 'hp_max', 'atk_max', 'def_max', 'passive_skill_set_id', 'leader_skill_set_id'], card_categories: ['id', 'name'], link_skills: ['id', 'name'], leader_skill_sets: ['id'], leader_skills: ['id', 'leader_skill_set_id'], passive_skill_sets: ['id'], passive_skills: ['id'], passive_skill_set_relations: ['id', 'passive_skill_set_id', 'passive_skill_id'] };
      for (const [table, columns] of Object.entries(required)) {
        const type = await read('tableType', table);if (type[0]?.type !== 'table') fail('Expected game data table: ' + table);
        const found = new Set((await read('tableInfo', table)).map(column => column.name));if (columns.some(column => !found.has(column))) fail('Database is missing game fields: ' + table);
      }
      const count = (await read('cardCount'))[0]?.n;if (!Number.isSafeInteger(count) || count < (strict ? 1000 : 1)) fail('The database contains starter or incomplete card data.');return count;
    } finally { await nativeCall('sourceDatabaseClose', { handle: opened.handle }).catch(() => {}); }
  };
  H.userContentArchive = args => nativeCall('userContentArchive', args || {});
  H.storageCheck = async () => ({ permission: true, public: false, folder: 'Offline Dokkan · Creator downloads', needsChoice: false, old: [] });
  H.storageAccess = async () => { const result = await nativeCall('gameFolderLink', { game: 'dokkan-files' });return { ...result, opened: result?.linked === true }; };
  H.storageDecline = H.storageCheck;
  const downloadLibrary = H.offlineLibrary;
  if (downloadLibrary) H.offlineLibrary = async args => ({ ...await downloadLibrary(args), folder: 'Offline Dokkan · Creator downloads' });
  const toolsWipe = H.wipeData;
  H.wipeData = async (args = {}) => {
    if (args.confirm !== 'DELETE') fail('Not confirmed.');
    const own = await owner.call('wipeCreatorDocuments', { confirm: 'DELETE', units: !!args.units, settings: !!args.settings });
    const tools = await toolsWipe({ ...args, units: false, settings: false });
    if (args.settings) { try { localStorage.clear(); } catch {} }
    return { ...tools, units: own.units, settings: own.settings };
  };
  ForgeHost.call = async (op, args) => {
    if (op === 'secretHint' && ['sparking.db', 'sparking.sprk'].includes(args?.key)) return { hasKey: !!(await nativeCall('sourceCodecStatus')).configured };
    return nativeCall(op, args);
  };
  // Source keys are derived/held only by the native admitted source capability.
  IOS.importSparkingApk = async (file, name, entries) => {
    const path = 'cache/source-codec-' + IOS.uuid4() + '.apk';
    try {
      await ForgeHost.writeBytes(path, file);const result = await nativeCall('sourceCodecImportAPK', { path });
      const resources = await IOS.importArchiveForSparking(file, name, entries);
      return { ...resources, ...result, sourceFormat: 'sparking-apk', formatKeyConfigured: true, note: 'Source format and available resources imported. The selected game master and current unit are unchanged.' };
    }
    finally { await ForgeHost.remove(path).catch(() => {}); }
  };
  window.forgeNative.call = async (op, args = {}) => {
    if (rejectedGame.has(op)) fail('Return to the original Offline Dokkan game to play.');
    const fn = H[op];if (typeof fn !== 'function') fail('This Creator tool is unavailable. Your unit stays saved.');return fn(args);
  };
  window.OfflineCreatorTools = Object.freeze({ selectedMaster: true, nativeTools: true });
})();
