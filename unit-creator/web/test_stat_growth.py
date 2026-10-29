#!/usr/bin/env python3
"""Focused real-master high-cap growth export/apply/reimport check; no app build."""
import json
from pathlib import Path
import re
import sqlite3
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
MASTER = ROOT / 'unit-creator/apk/assets/reference.db'
NODE = r'''
const fs=require('fs'),readline=require('readline'),Forge=require(process.argv[1]);
const lines=readline.createInterface({input:process.stdin});let ready,waiting;
lines.on('line',line=>{const item=JSON.parse(line);if(!ready){ready=item;start().catch(error=>{console.error(error.stack);process.exit(1);});}else{const cb=waiting;waiting=null;if(item.error)cb.reject(Error(item.error));else cb.resolve(item.rows);}});
function query(q){return new Promise((resolve,reject)=>{waiting={resolve,reject};process.stdout.write(JSON.stringify({query:q})+'\n');});}
function check(value,message){if(!value)throw Error(message);}
async function start(){
  const p=await Forge.loadTemplate(query,ready.schema,ready.source,97000001);
  const original=Forge.materialize(p);check(!original.card_growths,'ordinary source growth changed');
  const exports=[];
  for(const cap of [180,200]){
    p.cardOverrides.lv_max=cap;p.cardOverrides.hp_init=10000;p.cardOverrides.hp_max=500000;
    p.cardOverrides.atk_init=5000;p.cardOverrides.atk_max=300000;p.cardOverrides.def_init=4000;p.cardOverrides.def_max=250000;
    await Forge.hydrateStatGrowth(p,query,ready.schema);
    const checkResult=Forge.validate(p);check(!checkResult.errors.length,JSON.stringify(checkResult.errors));
    const tables=Forge.materialize(p),growth=tables.card_growths;
    check(growth.length===cap&&growth[0].coef===0&&growth.at(-1).coef===1,'wrong normalized endpoints');
    check(tables.cards.length===2&&tables.cards.every(c=>c.grow_type===p.targetId&&c.exp_type===925),'root/awakened growth or EXP mismatch');
    check(growth.every((row,i)=>row.id===p.targetId+i&&row.grow_type===p.targetId&&row.lv===i+1),'growth namespace escaped');
    const backup=JSON.parse(JSON.stringify(p));check(Forge.sql(backup).includes('card_growths'),'backup reimport lost growth');
    const legacy=JSON.parse(JSON.stringify(p));delete legacy.sourceStatGrowth;delete legacy.statPolicy;
    check(Forge.validate(legacy).errors.some(x=>/stat|growth/i.test(x)),'legacy validation did not report hydration');
    await Forge.hydrateNativeRecords(legacy,query,ready.schema);
    check(!Forge.validate(legacy).errors.length,'legacy hydration failed');
    const overlap=JSON.parse(JSON.stringify(p));overlap.targetId=97000002;
    check(Forge.validate(overlap).errors.some(x=>x.includes('automatic private')),'unsafe private range accepted');
    exports.push({cap,sql:Forge.sql(p),tables});
  }
  const child=JSON.parse(JSON.stringify(p));child.key+='-form';child.targetId=97001001;
  p.cardOverrides.lv_max=180;
  p.formProjects=[child];
  const ability=Forge.addPassive(p,{name:'Our test transformation',efficacy_type:103,eff_value1:child.targetId,eff_value2:0,eff_value3:0});
  p.transformLinks=[{table:'passive_skills',row:ability.id,targetId:child.targetId,targetKey:child.key}];
  const combined=Forge.materializeAll(p);
  check(combined.card_growths.length===380&&combined.card_exps.length===200,'two forms failed unique curves/sharedEXP dedup');
  fs.writeFileSync(process.argv[2],JSON.stringify({exports,multi:combined}));
  process.stdout.write(JSON.stringify({done:true})+'\n');lines.close();process.stdin.destroy();
}
'''

with sqlite3.connect(f'file:{MASTER}?mode=ro', uri=True) as source:
    source.row_factory = sqlite3.Row
    tables = [r[0] for r in source.execute("SELECT name FROM sqlite_master WHERE type='table'")]
    schema = {table: [dict(row) for row in source.execute('PRAGMA table_info("' + table + '")')] for table in tables}
    chosen = source.execute("SELECT c.id FROM cards c WHERE rarity=5 AND grow_type=50 AND lv_max=150 AND id%10=1 AND hp_max>300 AND passive_skill_set_id IS NOT NULL AND leader_skill_set_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM card_awakening_routes r WHERE r.card_id=c.id AND r.awaked_card_id!=r.card_id AND r.type IN('CardAwakeningRoute::Dokkan','CardAwakeningRoute::Zet')) LIMIT 1").fetchone()[0]
    original_growth = [tuple(row) for row in source.execute('SELECT * FROM card_growths ORDER BY id')]
    with tempfile.TemporaryDirectory() as temp:
        result = Path(temp) / 'result.json'
        process = subprocess.Popen(['node', '-e', NODE, str(ROOT / 'unit-creator/v2/ui/core.js'), str(result)], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        process.stdin.write(json.dumps({'schema': schema, 'source': chosen}) + '\n');process.stdin.flush()
        for line in process.stdout:
            request = json.loads(line)
            if request.get('done'):
                break
            q = request['query'];table = q['table'];filters = q.get('filters', {})
            assert table in schema and all(re.fullmatch(r'[a-zA-Z0-9_]+', key) for key in filters)
            clause = ' AND '.join('"' + key + '"=?' for key in filters)
            rows = [dict(row) for row in source.execute('SELECT * FROM "' + table + '"' + (' WHERE ' + clause if clause else '') + ' LIMIT ?', [*filters.values(), min(int(q.get('limit', 5000)), 5000)])]
            process.stdin.write(json.dumps({'rows': rows}) + '\n');process.stdin.flush()
        assert process.wait(timeout=30) == 0, process.stderr.read()
        data = json.loads(result.read_text())
        applied = sqlite3.connect(Path(temp) / 'applied.db')
        source.backup(applied)
        for export in data['exports']:
            applied.executescript(export['sql'])
            applied.executescript(export['sql'])
            cap = export['cap'];card = applied.execute('SELECT grow_type,exp_type,hp_init,hp_max FROM cards WHERE id=97000001').fetchone()
            assert card == (97000001, 925, 10000, 500000), card
            curve = applied.execute('SELECT lv,coef FROM card_growths WHERE grow_type=97000001 AND lv<=? ORDER BY lv', (cap,)).fetchall()
            assert len(curve) == cap and curve[0] == (1, 0.0) and curve[-1] == (cap, 1.0)
            assert [tuple(row) for row in applied.execute('SELECT * FROM card_growths WHERE id<97000001 ORDER BY id')] == original_growth
        applied.executescript(data['exports'][0]['sql'])
        assert applied.execute('SELECT count(*) FROM card_growths WHERE grow_type=97000001').fetchone()[0] == 180
        assert applied.execute('PRAGMA integrity_check').fetchone()[0] == 'ok'
        applied.close()
print('Real-master high-cap export check passed:180/200, SQL apply/reimport, original curves preserved, root pair, legacy hydration, namespace and multi-form shared EXP.')
