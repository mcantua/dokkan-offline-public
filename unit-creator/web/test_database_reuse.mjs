// No game data, SDK, browser, or network needed. Runs the real iPhone bridge with SQLite fixtures.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import vm from 'node:vm';
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';

const scratch = fs.mkdtempSync(path.join(os.tmpdir(), 'dokkan-db-test-'));
const source = fs.readFileSync(new URL('src/ios-native.js', import.meta.url), 'utf8');
const tables = {
  cards: ['id', 'name', 'rarity', 'element', 'resource_id', 'hp_max', 'atk_max', 'def_max', 'passive_skill_set_id', 'leader_skill_set_id'],
  card_categories: ['id', 'name'], link_skills: ['id', 'name'], leader_skill_sets: ['id'],
  leader_skills: ['id', 'leader_skill_set_id'], passive_skill_sets: ['id'], passive_skills: ['id'],
  passive_skill_set_relations: ['id', 'passive_skill_set_id', 'passive_skill_id'],
};
const server = path.join(scratch, 'server.db'), folder = path.join(scratch, 'Dokkan Files');
fs.mkdirSync(folder);
execFileSync('python3', ['-c', `import sqlite3,json,sys
c=sqlite3.connect(sys.argv[1])
for t,cols in json.loads(sys.argv[2]).items(): c.execute('CREATE TABLE '+t+' ('+','.join(cols)+')')
c.executemany('INSERT INTO cards(id,name) VALUES (?,?)', [(i,'Fixture') for i in range(1001)])
c.commit()`, server, JSON.stringify(tables)]);
const hash = f => ({ sha256: createHash('sha256').update(fs.readFileSync(f)).digest('hex'), bytes: fs.statSync(f).size });
let downloads = 0, etag = '"version-1"', offline = false, failWrite = false, failDownload = false;
function install() {
  const root = fs.mkdtempSync(path.join(scratch, 'install-'));
  const p = rel => path.join(root, rel);
  const copy = (a, b) => { fs.mkdirSync(path.dirname(b), { recursive: true }); fs.copyFileSync(a, b); };
  copy(server, p('db/reference.db'));
  let linked = false;
  const host = {
    async call(op, a = {}) {
      if (op === 'gameFolderLink') { linked = true; return { linked }; }
      if (op === 'gameFolderUnlink') { linked = false; return true; }
      if (op === 'gameFolderStatus') return { linked, ok: linked, name: 'Dokkan Files' };
      if (op === 'gameFolderCopyIn') {
        if (!linked) return { linked: false };
        const f = path.join(folder, a.rel);
        if (!fs.existsSync(f)) return { linked, missing: true };
        copy(f, p(a.to)); return { linked, copied: true, bytes: fs.statSync(f).size };
      }
      if (op === 'gameFolderWrite') {
        if (failWrite) throw Error('Folder became read-only');
        copy(p(a.path), path.join(folder, a.name)); return { linked, written: true };
      }
      if (op === 'sha256') return hash(p(a.path));
      if (op === 'copy') { copy(p(a.path), p(a.to)); return true; }
      if (op === 'sqlClose' || op === 'installDatabases') return true;
      if (op === 'sql') return JSON.parse(execFileSync('python3', ['-c', `import sqlite3,json,sys
c=sqlite3.connect(sys.argv[1]); q=c.execute(sys.argv[2],json.loads(sys.argv[3]))
print(json.dumps({'columns':[x[0] for x in q.description], 'rows':q.fetchall()})); c.close()`, p(a.db), a.sql, JSON.stringify(a.params)], { stdio: ['ignore', 'pipe', 'pipe'] }));
      throw Error('Unexpected native action: ' + op);
    },
    async net() {
      if (offline) throw Error('Offline');
      return { status: 200, headers: new Headers({ ETag: etag, 'Content-Length': String(fs.statSync(server).size) }) };
    },
    async download(url, rel) {
      downloads++;
      if (offline || failDownload) throw Error('Network unavailable');
      copy(server, p(rel)); return { status: 200, bytes: fs.statSync(server).size, finalUrl: url, etag };
    },
    exists: async rel => fs.existsSync(p(rel)),
    readJson: async rel => JSON.parse(fs.readFileSync(p(rel), 'utf8')),
    writeJson: async (rel, data) => { fs.mkdirSync(path.dirname(p(rel)), { recursive: true }); fs.writeFileSync(p(rel), JSON.stringify(data)); },
    move: async (a, b) => fs.renameSync(p(a), p(b)),
    remove: async rel => fs.rmSync(p(rel), { force: true, recursive: true }),
    list: async rel => fs.readdirSync(p(rel)).map(name => ({ name })),
    keepAwake: async () => true,
  };
  const H = {}, window = { ForgeHost: host, __forgeWeb: { handlers: H }, forgeNative: { call: (m, a) => H[m](a) } };
  const context = vm.createContext({ window, document: { documentElement: { classList: { add() {}, remove() {} }, style: {} } },
    localStorage: { getItem: () => null }, fetch: async () => ({ json: async () => ({ date: 'fixture' }) }), TextEncoder, TextDecoder, console });
  vm.runInContext(source, context);
  return { root, H, host, IOS: window.__forgeIOS, p, uninstall: () => fs.rmSync(root, { recursive: true, force: true }) };
}
let passed = 0;
async function check(name, fn) { await fn(); passed++; console.log('PASS ' + name); }
try {
  let app = install();
  await check('first sync saves one verified copy in the linked folder', async () => {
    await app.H.dokkanFiles({ action: 'link' }); await app.H.sync();
    assert.equal(downloads, 1); assert.equal(hash(path.join(folder, 'eclipse-database.db')).sha256, hash(server).sha256);
    assert.deepEqual(fs.readdirSync(folder).sort(), ['eclipse-database.db', 'eclipse-database.json']);
  });
  await check('deleting app storage and relinking restores without a database download', async () => {
    app.uninstall(); app = install(); await app.H.dokkanFiles({ action: 'link' });
    const r = await app.H.sync(); assert.equal(r.databaseReuse.reused, true); assert.equal(downloads, 1); assert.equal(r.count, 1001);
    assert.deepEqual(fs.readdirSync(app.p('cache')), []);
  });
  await check('a changed server version downloads and replaces the saved copy', async () => {
    etag = '"version-2"'; await app.H.sync(); assert.equal(downloads, 2);
    assert.equal(JSON.parse(fs.readFileSync(path.join(folder, 'eclipse-database.json'))).meta.etag, etag);
  });
  await check('a damaged saved file fails its checksum and downloads again', async () => {
    fs.writeFileSync(path.join(folder, 'eclipse-database.db'), 'damaged'); await app.H.sync(); assert.equal(downloads, 3);
  });
  await check('a file with a matching checksum but invalid SQLite is rejected', async () => {
    const f = path.join(folder, 'eclipse-database.db'), s = path.join(folder, 'eclipse-database.json');
    fs.writeFileSync(f, Buffer.alloc(fs.statSync(server).size));
    const meta = JSON.parse(fs.readFileSync(s)); Object.assign(meta, hash(f)); fs.writeFileSync(s, JSON.stringify(meta));
    await app.H.sync(); assert.equal(downloads, 4);
  });
  await check('offline reuse restores the verified copy and reports freshness as unknown', async () => {
    app.uninstall(); app = install(); await app.H.dokkanFiles({ action: 'link' }); offline = true;
    const r = await app.H.sync(); assert.equal(r.databaseReuse.offline, true); assert.equal(downloads, 4);
    assert.match((await app.H.importStatus()).label, /when online/); offline = false;
  });
  await check('folder write failure keeps the working database and reports the problem', async () => {
    execFileSync('python3', ['-c', "import sqlite3,sys; c=sqlite3.connect(sys.argv[1]); c.execute(\"UPDATE cards SET name='Newer fixture' WHERE id=1\"); c.commit()", server]);
    etag = '"version-3"'; failWrite = true; const r = await app.H.sync(); failWrite = false;
    assert.match(r.dokkanFilesWarning, /couldn't save/); assert.equal(r.count, 1001);
  });
  await check('offline reuse cannot downgrade a different active database', async () => {
    const before = fs.readFileSync(app.p('database-state.json'), 'utf8'); offline = true;
    await assert.rejects(app.H.sync()); offline = false;
    assert.equal(fs.readFileSync(app.p('database-state.json'), 'utf8'), before);
  });
  await check('interrupted download preserves active data and cleans temporary files', async () => {
    const before = fs.readFileSync(app.p('database-state.json'), 'utf8'); failDownload = true;
    await assert.rejects(app.H.sync()); failDownload = false;
    assert.equal(fs.readFileSync(app.p('database-state.json'), 'utf8'), before);
    assert.deepEqual(fs.readdirSync(app.p('cache')), []);
  });
  await check('unlinking retains external files and falls back to downloading', async () => {
    await app.H.dokkanFiles({ action: 'unlink' }); const n = downloads; await app.H.sync();
    assert.equal(downloads, n + 1); assert.equal(fs.readdirSync(folder).length, 2);
  });
  await check('linking an existing folder does not overwrite its data', async () => {
    const before = fs.readFileSync(path.join(folder, 'eclipse-database.json'), 'utf8');
    await app.H.dokkanFiles({ action: 'link' });
    assert.equal(fs.readFileSync(path.join(folder, 'eclipse-database.json'), 'utf8'), before);
  });
  await check('missing or malformed saved metadata falls back to a fresh download', async () => {
    fs.writeFileSync(path.join(folder, 'eclipse-database.json'), '{unfinished');
    const n = downloads; await app.H.sync(); assert.equal(downloads, n + 1);
    assert.equal(JSON.parse(fs.readFileSync(path.join(folder, 'eclipse-database.json'))).version, 1);
  });
  console.log(`${passed} passed, 0 failed`);
} finally { fs.rmSync(scratch, { recursive: true, force: true }); }
