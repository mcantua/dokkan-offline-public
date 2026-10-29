/* One actual supplied-master + native-stats + verified authored-asset scenario. */
'use strict';
const assert = require('node:assert/strict'), fs = require('node:fs'), path = require('node:path');
const {spawn} = require('node:child_process'), readline = require('node:readline'), {createHash} = require('node:crypto');
const Planner = require('./stage-plan.js');
const repo = path.resolve(__dirname, '../..'), master = process.argv[2] || path.join(repo, 'unit-creator/apk/assets/reference.db');
const statsLibrary = process.env.OD_STATS_LIBRARY || path.join(repo, 'offline-dokkan/core/build/libcardstats-check.so');
const script = `import sys,json,sqlite3,ctypes,ctypes.util
dbpath,library=sys.argv[1:]
db=sqlite3.connect('file:'+dbpath+'?mode=ro',uri=True);db.row_factory=sqlite3.Row
sql=ctypes.CDLL(ctypes.util.find_library('sqlite3'));handle=ctypes.c_void_p()
sql.sqlite3_open_v2.argtypes=[ctypes.c_char_p,ctypes.POINTER(ctypes.c_void_p),ctypes.c_int,ctypes.c_char_p]
assert sql.sqlite3_open_v2(dbpath.encode(),ctypes.byref(handle),1,None)==0
lib=ctypes.CDLL(library);lib.od_card_stats.argtypes=[ctypes.c_void_p,ctypes.c_int64,ctypes.c_char_p,ctypes.c_int64,ctypes.c_char_p,ctypes.POINTER(ctypes.c_void_p),ctypes.POINTER(ctypes.c_char_p)]
sql.sqlite3_free.argtypes=[ctypes.c_void_p]
for line in sys.stdin:
 request=json.loads(line)
 try:
  if request['op']=='query':result=[dict(r) for r in db.execute(request['sql'],request['params'])]
  else:
   out=ctypes.c_void_p();error=ctypes.c_char_p()
   rc=lib.od_card_stats(handle,request['masterId'],None,request['level'],b'master-coefficient-linear-floor-v1',ctypes.byref(out),ctypes.byref(error))
   if rc:raise RuntimeError(error.value.decode() if error.value else 'NATIVE_STATS_FAILED')
   try:result=json.loads(ctypes.string_at(out))
   finally:sql.sqlite3_free(out)
  print(json.dumps({'id':request['id'],'result':result}),flush=True)
 except Exception as e:print(json.dumps({'id':request['id'],'error':str(e)}),flush=True)
sql.sqlite3_close.argtypes=[ctypes.c_void_p];sql.sqlite3_close(handle);db.close()
`;
(async () => {
  const child = spawn('python3', ['-u', '-c', script, master, statsLibrary], {stdio: ['pipe', 'pipe', 'inherit']});
  const waiting = new Map(); let serial = 0;
  readline.createInterface({input: child.stdout}).on('line', line => { const answer = JSON.parse(line), promise = waiting.get(answer.id); waiting.delete(answer.id); if (answer.error) promise.reject(Error(answer.error)); else promise.resolve(answer.result); });
  const childDone = new Promise((resolve, reject) => child.on('exit', code => { if (code === 0) resolve(); else reject(Error('Actual source/native stats bridge failed: ' + code)); for (const promise of waiting.values()) promise.reject(Error('Source bridge closed')); }));
  const call = request => new Promise((resolve, reject) => { const id = ++serial; waiting.set(id, {resolve, reject}); child.stdin.write(JSON.stringify({id, ...request}) + '\n'); });
  try {
    const metadata = JSON.parse(fs.readFileSync(path.join(repo, 'unit-creator/docs/latest-native-check.json'), 'utf8'));
    const contentId = 'sha256:' + metadata.original_databases['reference.db'].sha256;
    const source = {provider: 'eclipse', contentId, query: (sql, params) => call({op: 'query', sql, params})};
    const css = fs.readFileSync(path.join(__dirname, 'battle.css')), cssHash = createHash('sha256').update(css).digest('hex');
    const manifest = {format: 'offline-dokkan-stage-dependencies', version: 1, contentId, encounters: [{mapId: 10, battleIndex: 0, roundNo: 1, presentation: 'authored-minimal-v1', dependencies: [{path: 'authored/battle.css', size: css.length, sha256: cssHash}]}]};
    const json = JSON.stringify(manifest), assetManifest = {json, sha256: createHash('sha256').update(json).digest('hex'), resolve: async ref => { assert.equal(ref.path, 'authored/battle.css'); return {verified: ref.size === css.length && ref.sha256 === cssHash, size: css.length, sha256: cssHash}; }};
    const args = {source, mapId: 10, battleIndex: 0, roundNo: 1, assetManifest, nativeStats: request => call({op: 'stats', masterId: request.masterId, level: request.level})};
    const strict = await Planner.planEncounter(args);
    assert.equal(strict.supported, false); assert.ok(strict.unsupported.some(g => g.code === 'STAGE_ENCOUNTER_STATS_POLICY_REQUIRED'));
    const policy = {id: 'offline-static-encounter-v1', version: 1, level: 1, hpScalePpm: 10000000, atkScalePpm: 1000000, defScalePpm: 1000000, attacks: [{slot: 0, multiplierPpm: 1000000}, {slot: 3, multiplierPpm: 1000000}], kiBoardPolicy: 'uniform-six-v1', classPolicy: 'preserve-source-class-v1', presentation: 'authored-minimal-v1'};
    const planned = await Planner.planEncounter({...args, authoredPolicy: policy});
    assert.deepEqual(planned.unsupported, []); assert.equal(planned.supported, true); assert.equal(planned.enemy.name, planned.facts.enemies[0].card.name);
    assert.equal(planned.enemy.hp, planned.facts.nativeStats.hp * 10); assert.equal(planned.enemy.attacks[0].atk, planned.facts.nativeStats.atk);
    assert.equal(planned.enemy.classType, 'neutral'); assert.equal(planned.rewards, null);
    assert.equal(planned.provenance.originalGameParityVerified, false); assert.equal(planned.provenance.originalEnemyAIResolved, false);
    assert.equal(planned.facts.verifiedAssets.length, 1);
    const missing = await Planner.planEncounter({...args, authoredPolicy: policy, assetManifest: {...assetManifest, sha256: '0'.repeat(64)}});
    assert.equal(missing.supported, false); assert.equal(missing.enemy, null); assert.ok(missing.unsupported.some(g => g.code === 'STAGE_MANIFEST_HASH_MISMATCH'));
    console.log('One actual Eclipse map/round/card/native-stat planner scenario passed with explicit authored balance and verified bundled CSS. No original encounter stats/AI, proprietary animation or native battle execution claimed.');
  } finally { child.stdin.end(); await childDone; }
})().catch(error => { console.error(error); process.exitCode = 1; });
