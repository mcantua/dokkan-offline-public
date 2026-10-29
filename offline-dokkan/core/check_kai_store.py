"""One combined guaranteed-Kai feeding/atomicity/history/import/semantic-JSON scenario."""
import copy
import ctypes
import hashlib
import json
import pathlib
import sqlite3
import tempfile
ROOT=pathlib.Path(__file__).resolve().parent
lib=ctypes.CDLL(str(ROOT/'build/libodcore.so'))
lib.od_open.argtypes=[ctypes.c_char_p]*3+[ctypes.POINTER(ctypes.c_void_p)]
lib.od_execute.argtypes=[ctypes.c_void_p]+[ctypes.c_char_p]*4+[ctypes.POINTER(ctypes.c_void_p)]
lib.od_last_error.argtypes=[ctypes.c_void_p];lib.od_last_error.restype=ctypes.c_char_p
lib.od_free.argtypes=lib.od_close.argtypes=[ctypes.c_void_p]
lib.od_export_save.argtypes=lib.od_import_save.argtypes=[ctypes.c_void_p,ctypes.c_char_p]
def reorder(x):
    if isinstance(x,dict):return {k:reorder(v) for k,v in reversed(list(x.items()))}
    if isinstance(x,list):return [reorder(v) for v in x]
    return x
with tempfile.TemporaryDirectory(prefix='kai-',dir=ROOT/'build') as temp:
    work=pathlib.Path(temp);master=work/'master.db';save=work/'save.db'
    base={'id':11,'name':'Synthetic target','rarity':4,'element':10,'hp_init':10,'atk_init':20,'def_init':30,'hp_max':1000,'atk_max':2000,'def_max':3000,'lv_max':3,'skill_lv_max':3,'leader_skill_set_id':1,'passive_skill_set_id':1,'exp_type':1,'grow_type':1,'aura_scale':1.0}
    with sqlite3.connect(master) as db:
        db.execute('CREATE TABLE cards('+','.join(k+(' TEXT' if isinstance(v,str) else ' REAL' if isinstance(v,float) else ' INTEGER')+(' PRIMARY KEY' if k=='id' else ' NOT NULL') for k,v in base.items())+')')
        for card in [base,dict(base,id=21,name='Verified material',rarity=3,lv_max=1,skill_lv_max=1),dict(base,id=31,name='Unverified material',rarity=3,lv_max=1,skill_lv_max=1)]:db.execute('INSERT INTO cards VALUES('+','.join('?' for _ in card)+')',list(card.values()))
        db.execute('CREATE TABLE card_awakening_routes(id INTEGER PRIMARY KEY,card_id INTEGER,awaked_card_id INTEGER,type TEXT)')
        for table in ['leader_skill_sets','passive_skill_sets']:
            db.execute(f'CREATE TABLE {table}(id INTEGER PRIMARY KEY)');db.execute(f'INSERT INTO {table} VALUES(1)')
        db.execute('CREATE TABLE quests(id INTEGER PRIMARY KEY,prev_quest_id INTEGER)');db.execute('INSERT INTO quests VALUES(1,0)')
        db.execute('CREATE TABLE sugoroku_maps(id INTEGER PRIMARY KEY,quest_id INTEGER,act INTEGER)');db.execute('INSERT INTO sugoroku_maps VALUES(1,1,1)')
        db.execute('CREATE TABLE card_exps(id INTEGER PRIMARY KEY,exp_type INTEGER,lv INTEGER,exp_total INTEGER)');db.executemany('INSERT INTO card_exps VALUES(?,1,?,?)',[(1,1,0),(2,2,10),(3,3,20)])
        db.execute('CREATE TABLE card_growths(id INTEGER PRIMARY KEY,grow_type INTEGER,lv INTEGER,coef REAL)');db.executemany('INSERT INTO card_growths VALUES(?,1,?,?)',[(1,1,0),(2,2,.5),(3,3,1)])
    def opened(path=save):
        c=ctypes.c_void_p();assert lib.od_open(str(path).encode(),str(master).encode(),b'kai-master',ctypes.byref(c))==0;return c
    core=opened()
    def call(op,args=None,cmd=None,error=None,profile='p'):
        out=ctypes.c_void_p();rc=lib.od_execute(core,op.encode(),profile.encode(),cmd.encode() if cmd else None,json.dumps(args or {},separators=(',',':')).encode(),ctypes.byref(out))
        if error:assert rc<0 and lib.od_last_error(core).decode()==error,(op,rc,lib.od_last_error(core));return
        assert rc==0,(op,lib.od_last_error(core))
        try:return json.loads(ctypes.string_at(out))
        finally:lib.od_free(out)
    serial=0
    def added(master_id=21,profile='p'):
        global serial
        serial+=1;return call('card.add',{'master_id':master_id},f'add-{serial}',profile=profile)['cards'][-1]['instance_id']
    def sa(state,instance):return next(c['sa_level'] for c in state['cards'] if c['instance_id']==instance)
    call('profile.create',{'initial_stamina':20},'open')
    target=added(11);teachers=[added() for _ in range(12)];unverified=added(31)
    policy={'banner_id':'kai-policy','version':1,'zone':0,'multi_count':2,'pool':[{'master_id':21,'verified_elder_kai':True,'super_attack_levels':1,'weight_ppm':1000000}]}
    call('elder_kai.configure',policy,'policy');before=call('profile.snapshot')
    call('elder_kai.configure',reorder(policy),'reordered-policy');assert call('profile.snapshot')==before
    def feed(ids,target_id=target):return {'target_instance_id':target_id,'material_instance_ids':ids,'kai_banner_id':'kai-policy','kai_banner_version':1}
    # Preserve finished-run history containing a teacher; saved teams must be cleared first.
    call('team.set',{'slot':0,'members':[teachers[0]]},'past-team')
    run={'run_id':'past','map_id':1,'team_slot':0,'assets_ready':True,'rewards':[{'kind':'stone','id':0,'quantity':1}]}
    call('run.start',run,'past-start');past=call('run.finish',{'run_id':'past','outcome':'failed'},'past-end')
    call('team.set',{'slot':0,'members':[target]},'target-team')
    call('card.lock',{'instance_id':teachers[1],'locked':True},'lock')
    call('card.sa.train',feed([teachers[1]]),'locked',error='KAI_MATERIAL_LOCKED')
    call('team.set',{'slot':1,'members':[teachers[2]]},'teacher-team')
    call('card.sa.train',feed([teachers[2]]),'in-team',error='KAI_MATERIAL_IN_TEAM')
    call('team.set',{'slot':1,'members':[]},'clear-teacher-team')
    call('team.set',{'slot':2,'members':[teachers[3]]},'run-teacher-team')
    call('run.start',dict(run,run_id='teacher-live',team_slot=2),'teacher-live')
    call('team.set',{'slot':2,'members':[]},'clear-live-team')
    call('card.sa.train',feed([teachers[3]]),'in-run',error='KAI_MATERIAL_IN_RUN')
    call('run.finish',{'run_id':'teacher-live','outcome':'failed'},'teacher-live-end')
    call('run.start',dict(run,run_id='target-live'),'target-live')
    call('card.sa.train',feed([teachers[4]]),'target-in-run',error='CARD_IN_USE')
    call('run.finish',{'run_id':'target-live','outcome':'failed'},'target-live-end')
    before=call('profile.snapshot')
    call('card.sa.train',feed([teachers[0],teachers[0]]),'duplicate',error='INVALID_KAI_MATERIALS')
    call('card.sa.train',feed([True]),'boolean',error='INVALID_KAI_MATERIALS')
    call('card.sa.train',feed([target]),'self',error='KAI_SELF_FEED_FORBIDDEN')
    call('card.sa.train',feed([unverified]),'unverified',error='KAI_MATERIAL_NOT_VERIFIED')
    call('card.sa.train',feed([teachers[0],teachers[4],teachers[5]]),'overcap',error='SUPER_ATTACK_CAP_EXCEEDED')
    call('card.sa.train',dict(feed([teachers[0]]),chance=100),'client-chance',error='INVALID_KAI_MATERIALS')
    call('card.sa.train',dict(feed([teachers[0]]),kai_banner_version=999),'unknown-policy',error='KAI_POLICY_NOT_FOUND')
    call('card.sa.train',dict(feed([teachers[0]]),kai_banner_id='kai-policy\u0000suffix'),'nul-policy',error='INVALID_JSON')
    assert call('profile.snapshot')==before
    call('profile.create',cmd='other-open',profile='other');foreign=added(profile='other')
    call('card.sa.train',feed([foreign]),'foreign',error='KAI_MATERIAL_NOT_OWNED')
    # Force a real persistence failure after baseline/event writes; every write must roll back.
    before=call('profile.snapshot')
    with sqlite3.connect(save) as db:db.execute(f"CREATE TRIGGER fail_kai BEFORE INSERT ON owned_consumptions WHEN NEW.instance_id={teachers[0]} BEGIN SELECT RAISE(ABORT,'synthetic write failure'); END")
    args=feed([teachers[0],teachers[4]])
    call('card.sa.train',args,'feed',error='KAI_DATABASE_ERROR')
    with sqlite3.connect(save) as db:
        assert db.execute('SELECT count(*) FROM sa_training_events').fetchone()[0]==0
        assert db.execute('SELECT count(*) FROM sa_training_baselines').fetchone()[0]==0
        assert db.execute('SELECT count(*) FROM owned_consumptions').fetchone()[0]==0
        db.execute('DROP TRIGGER fail_kai')
    assert call('profile.snapshot')==before
    result=call('card.sa.train',args,'feed');assert sa(result,target)==3 and result['sa_training']['super_attack_levels_added']==2
    assert {teachers[0],teachers[4]}.isdisjoint(c['instance_id'] for c in result['cards'])
    assert call('card.sa.train',reorder(args),'feed')==result
    call('card.sa.train',feed(list(reversed(args['material_instance_ids']))),'feed',error='COMMAND_CONFLICT')
    second_target=added(11)
    call('card.sa.train',feed([teachers[0]],second_target),'spent',error='KAI_MATERIAL_CONSUMED')
    call('card.sa.train',feed([teachers[5]],teachers[0]),'spent-target',error='CARD_CONSUMED')
    call('card.stats',{'instance_id':teachers[0]},error='CARD_NOT_OWNED')
    call('card.lock',{'instance_id':teachers[0],'locked':True},'lock-spent',error='CARD_NOT_OWNED')
    call('card.experience.grant',{'instance_id':teachers[0],'source':'spent','quantity':1},'xp-spent',error='CARD_NOT_OWNED')
    call('team.set',{'slot':3,'members':[teachers[0]]},'team-spent',error='CARD_NOT_OWNED')
    assert call('run.finish',{'run_id':'past','outcome':'failed'},'past-retry')==past
    with sqlite3.connect(save) as db:
        assert db.execute('SELECT master_id FROM owned_cards WHERE id=?',(teachers[0],)).fetchone()==(21,)
        assert teachers[0] in json.loads(db.execute("SELECT team_snapshot FROM runs WHERE id='past'").fetchone()[0])
    # Actual effective Created cap/history survives a later active-definition update.
    doc={'format':'offline-dokkan-definition','schema_version':1,'definition_id':'authored','version':1,'source':{'content_id':'kai-master','master_id':11},'rarity':'UR','fully_awakened':True,'creator':{'id':'tin','name':'Tin'},'card':dict(base,skill_lv_max=4),'tables':{}}
    call('creator.import',{'definition':doc},'created')
    reward={'source':'fund','rewards':[{'kind':'stone','id':0,'quantity':1}]};call('inventory.grant',reward,'fund')
    config={'banner_id':'created','version':1,'epoch':1,'creator_epoch':1,'main_id':'authored','policy':{'lr_ppm':0,'slr_ppm':0,'gr_ppm':0,'multi_count':2},'pool':[{'definition_id':'authored','definition_version':1,'master_id':11,'rarity':'UR','weight_ppm':1000000}]}
    call('banner.configure',config,'banner')
    created=call('summon.draw',{'banner_id':'created','kind':'single'},'created-draw')['summon']['draws'][0]['instance_id']
    call('card.sa.train',feed([teachers[5],teachers[6],teachers[7]],created),'created-feed')
    call('card.sa.train',feed([created],second_target),'modified-teacher',error='KAI_MATERIAL_MODIFIED')
    newer=copy.deepcopy(doc);newer['version']=2;newer['card']['skill_lv_max']=5
    call('creator.import',{'definition':newer},'created-update')
    top=call('card.sa.train',feed([teachers[8]],created),'created-feed-new')
    assert sa(top,created)==5 and top['sa_training']['target_binding']['version']==2
    state=call('profile.snapshot');same=reorder(newer);same['card']['aura_scale']=1
    call('creator.import',{'definition':same},'reordered-document')
    call('inventory.grant',reorder(reward),'reordered-fixed-source')
    assert call('profile.snapshot')==state
    # Scalar distinctions remain real when JSON objects reorder: boolean != numeric value.
    call('profile.create',{'probe':False},'boolean-intent',profile='semantic')
    call('profile.create',{'probe':0},'boolean-intent',profile='semantic',error='COMMAND_CONFLICT')
    final=call('profile.snapshot');exported=work/'export.db';assert lib.od_export_save(core,str(exported).encode())==0
    assert lib.od_import_save(core,str(exported).encode())==0 and call('profile.snapshot')==final
    for sql in [f'DELETE FROM owned_consumptions WHERE instance_id={teachers[0]}',f'UPDATE owned_cards SET sa_level=2 WHERE id={target}',"UPDATE sa_training_events SET target_binding=json_set(target_binding,'$.version',999) WHERE json_extract(target_binding,'$.channel')='created'", "UPDATE commands SET result=json_set(result,'$.sa_training.target_binding.version',999) WHERE id='created-feed'"]:
        bad=work/'bad.db'
        with sqlite3.connect(exported) as src,sqlite3.connect(bad) as dst:src.backup(dst);dst.execute(sql)
        assert lib.od_import_save(core,str(bad).encode())<0 and call('profile.snapshot')==final
    lib.od_close(core);core=opened();assert call('profile.snapshot')==final;lib.od_close(core)
    # v6 baseline SA is preserved rather than reset; source import bytes stay unchanged.
    legacy=work/'v6.db'
    with sqlite3.connect(legacy) as db:
        db.executescript((ROOT/'fixtures/schema-v6.sql').read_text());db.execute("INSERT INTO meta VALUES('content','kai-master')");db.execute("INSERT INTO profiles(id,stamina) VALUES('p',7)")
        db.execute("INSERT INTO owned_cards(id,profile,master_id,sa_level) VALUES(1,'p',11,2)");db.execute("INSERT INTO owned_cards(id,profile,master_id) VALUES(2,'p',21)")
    digest=hashlib.sha256(legacy.read_bytes()).hexdigest();core=opened()
    assert lib.od_import_save(core,str(legacy).encode())==0 and hashlib.sha256(legacy.read_bytes()).hexdigest()==digest
    call('elder_kai.configure',policy,'legacy-policy')
    advanced=call('card.sa.train',feed([2],1),'legacy-feed');assert sa(advanced,1)==3 and advanced['sa_training']['sa_before']==2
    lib.od_close(core);core=opened(legacy);assert sa(call('profile.snapshot'),1)==2;lib.od_close(core)
    with sqlite3.connect(legacy) as db:assert db.execute('PRAGMA user_version').fetchone()[0]==15
print('PASS guaranteed Kai exact+1/cap/role/ownership/locks/team/run guards, atomic failure+retry, tombstone history, pinned-cap updates, semantic JSON retries, hostile import and v6 migration')
