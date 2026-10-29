"""Focused created-definition transaction/share/migration scenario, synthetic rows only."""
import copy
import ctypes
import hashlib
import json
import pathlib
import sqlite3
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent
lib = ctypes.CDLL(str(ROOT / 'build/libodcore.so'))
lib.od_open.argtypes = [ctypes.c_char_p]*3+[ctypes.POINTER(ctypes.c_void_p)]
lib.od_execute.argtypes = [ctypes.c_void_p]+[ctypes.c_char_p]*4+[ctypes.POINTER(ctypes.c_void_p)]
lib.od_last_error.argtypes = [ctypes.c_void_p];lib.od_last_error.restype = ctypes.c_char_p
lib.od_close.argtypes = [ctypes.c_void_p];lib.od_free.argtypes = [ctypes.c_void_p]
lib.od_export_save.argtypes = lib.od_import_save.argtypes = [ctypes.c_void_p,ctypes.c_char_p]
with tempfile.TemporaryDirectory(prefix='creator-',dir=ROOT/'build') as tmp:
    work=pathlib.Path(tmp);master=work/'master.db';save=work/'player.db'
    card={'id':1,'name':'Synthetic unit','rarity':5,'element':10,'hp_init':10,'atk_init':20,'def_init':30,'hp_max':1000,'atk_max':2000,'def_max':3000,'lv_max':200,'skill_lv_max':30,'leader_skill_set_id':1,'passive_skill_set_id':1,'exp_type':25}
    with sqlite3.connect(master) as db:
        db.execute('CREATE TABLE cards('+','.join(k+(' TEXT' if isinstance(v,str) else ' INTEGER')+(' PRIMARY KEY' if k=='id' else ' NOT NULL') for k,v in card.items())+')')
        for n in range(1,7):
            row=dict(card,id=n);row['lv_max']=150;row['skill_lv_max']=20
            db.execute('INSERT INTO cards VALUES('+','.join('?' for _ in row)+')',list(row.values()))
        db.execute('CREATE TABLE card_exps(id INTEGER PRIMARY KEY,exp_type INTEGER,lv INTEGER,exp_total INTEGER)')
        db.executemany('INSERT INTO card_exps VALUES(?,25,?,?)',[(n,n,(n-1)*1000) for n in range(1,151)])
        db.execute('CREATE TABLE card_awakening_routes(id INTEGER PRIMARY KEY,card_id INTEGER,awaked_card_id INTEGER,type TEXT)')
        db.execute("INSERT INTO card_awakening_routes VALUES(1,6,5,'CardAwakeningRoute::Dokkan')")
        db.execute('CREATE TABLE leader_skill_sets(id INTEGER PRIMARY KEY,name TEXT NOT NULL)')
        db.execute("INSERT INTO leader_skill_sets VALUES(1,'leader')")
        db.execute('CREATE TABLE passive_skill_sets(id INTEGER PRIMARY KEY,name TEXT NOT NULL)')
        db.execute("INSERT INTO passive_skill_sets VALUES(1,'passive')")
        db.execute('CREATE TABLE passive_skills(id INTEGER PRIMARY KEY,efficacy_type INTEGER NOT NULL,efficacy_values TEXT NOT NULL)')
        db.execute("INSERT INTO passive_skills VALUES(1,1,'[100]')")
        db.execute('CREATE TABLE sugoroku_maps(id INTEGER PRIMARY KEY)')
    def opened(path=save):
        c=ctypes.c_void_p();assert lib.od_open(str(path).encode(),str(master).encode(),b'creator-content',ctypes.byref(c))==0
        return c
    core=opened()
    def call(op,args=None,cmd=None,error=None,profile='p'):
        out=ctypes.c_void_p();rc=lib.od_execute(core,op.encode(),profile.encode(),cmd.encode() if cmd else None,json.dumps(args or {},separators=(',',':')).encode(),ctypes.byref(out))
        if error:
            assert rc<0 and lib.od_last_error(core).decode()==error,(op,rc,lib.od_last_error(core));return
        assert rc==0,(op,lib.od_last_error(core))
        try:return json.loads(ctypes.string_at(out))
        finally:lib.od_free(out)
    call('profile.create',cmd='open')
    call('inventory.grant',{'source':'seed','rewards':[{'kind':'stone','id':0,'quantity':100}]},'fund')
    doc={'format':'offline-dokkan-definition','schema_version':1,'definition_id':'custom-gr','version':1,'source':{'content_id':'creator-content','master_id':1},'rarity':'GR','fully_awakened':True,'creator':{'id':'tin-owner','name':'Tin'},'progression_policy':'creator-lr-extended-v1','card':card,'tables':{'passive_skills':[{'id':-1,'efficacy_type':1,'efficacy_values':'[222]'}]}}
    first=call('creator.import',{'definition':doc},'import')
    assert first['main_id']=='custom-gr' and first['epoch']==1 and first['featured']==['custom-gr']
    assert call('creator.import',{'definition':doc},'repeat')==first
    assert call('creator.export',{'definition_id':'custom-gr'})==doc
    before=call('profile.snapshot')
    for i,(path,value,error) in enumerate([
        (['card','hp_max'],True,'INVALID_DEFINITION_STATS'),
        (['source','content_id'],'wrong','INVALID_DEFINITION'),
        (['card','passive_skill_set_id'],999,'DEFINITION_REFERENCE_MISSING'),
        (['sql'],'DROP TABLE cards','INVALID_DEFINITION'),
        (['tables','script_files'],[],'UNSUPPORTED_DEFINITION_TABLE')]):
        bad=copy.deepcopy(doc);where=bad
        for part in path[:-1]:where=where[part]
        where[path[-1]]=value
        call('creator.import',{'definition':bad},f'bad-{i}',error=error)
    bad=copy.deepcopy(doc);bad['card']['id']=bad['source']['master_id']=6
    call('creator.import',{'definition':bad},'unawakened',error='SOURCE_NOT_FULLY_AWAKENED')
    assert call('profile.snapshot')==before
    config={'banner_id':'created','version':1,'epoch':1,'creator_epoch':1,'main_id':'custom-gr','policy':{'lr_ppm':10000,'slr_ppm':1000,'gr_ppm':100,'multi_count':2},'pool':[
        {'definition_id':'ur','master_id':2,'rarity':'UR','weight_ppm':988900},
        {'definition_id':'lr','master_id':3,'rarity':'LR','weight_ppm':10000},
        {'definition_id':'slr','master_id':4,'rarity':'SLR','weight_ppm':1000},
        {'definition_id':'custom-gr','master_id':1,'rarity':'GR','weight_ppm':100,'definition_version':1}]}
    call('banner.configure',config,'configure')
    lib.od_close(core)
    with sqlite3.connect(save) as db:db.execute("UPDATE banner_pity SET misses=49 WHERE profile='p'")
    core=opened()
    draw=call('summon.draw',{'banner_id':'created','kind':'multi'},'draw')
    created=[c for c in draw['cards'] if c['created_definition']]
    assert created and draw['created_definitions']==[{'definition_id':'custom-gr','version':1,'document':doc}]
    assert all(c['level']==c['sa_level']==1 and c['created_definition']['potential_locked']==1 and c['created_definition']['addons']==[] and c['created_definition']['exclusive_kind']==2 and c['created_definition']['exclusive_always_on']==1 for c in created)
    assert call('summon.draw',{'banner_id':'created','kind':'multi'},'draw')==draw
    # The existing Creator extension continues the selected master LR curve; no master rows added.
    instance=created[0]['instance_id'];extended_total=149000;step=1000
    for _ in range(50):
        step=(step*1035+500)//1000;extended_total+=step
    earned=call('card.experience.grant',{'instance_id':instance,'source':'created-cap','quantity':extended_total},'created-cap')
    assert next(c for c in earned['cards'] if c['instance_id']==instance)['level']==200
    doc2=copy.deepcopy(doc);doc2['version']=2;doc2['card']['atk_max']=9999;doc2['tables']['passive_skills'][0]['efficacy_values']='[999]'
    call('creator.import',{'definition':doc2},'update')
    changed_credit=copy.deepcopy(doc2);changed_credit['version']=3;changed_credit['creator']['name']='Different'
    call('creator.import',{'definition':changed_credit},'credit-conflict',error='CREATOR_CREDIT_CONFLICT')
    updated=call('profile.snapshot')
    effective=[c['created_definition'] for c in updated['cards'] if c['created_definition']]
    assert all(d['version']==2 and d['origin_version']==1 for d in effective)
    assert updated['created_definitions']==[{'definition_id':'custom-gr','version':2,'document':doc2}]
    assert call('creator.export',{'definition_id':'custom-gr','version':1})==doc
    call('summon.draw',{'banner_id':'created','kind':'single'},'stale',error='CREATED_BANNER_STALE')
    config['version']=2;config['pool'][-1]['definition_version']=2
    call('banner.configure',config,'new-config')
    # Sharing is the exact settings document; no resource/account files move.
    call('profile.create',cmd='other-open',profile='other')
    call('creator.import',{'definition':call('creator.export',{'definition_id':'custom-gr'})},'shared',profile='other')
    assert call('creator.export',{'definition_id':'custom-gr'},profile='other')==doc2
    for n in range(2,7):
        d=copy.deepcopy(doc);d['definition_id']=f'unit-{n}'
        call('creator.import',{'definition':d},f'fifo-{n}')
    feed=call('creator.library')
    assert feed['featured']==['unit-6','unit-5','unit-4','unit-3','unit-2'] and feed['main_id']=='unit-6' and feed['epoch']==6
    call('summon.draw',{'banner_id':'created','kind':'single'},'new-main-stale',error='CREATED_BANNER_STALE')
    exported=work/'export.db';assert lib.od_export_save(core,str(exported).encode())==0
    current=call('profile.snapshot')
    assert lib.od_import_save(core,str(exported).encode())==0
    assert call('profile.snapshot')==current
    with sqlite3.connect(exported) as db:db.execute("UPDATE created_definitions SET document=json_set(document,'$.card.atk_max',true) WHERE definition_id='custom-gr' AND version=2")
    assert lib.od_import_save(core,str(exported).encode())<0 and call('profile.snapshot')==current
    lib.od_close(core);core=opened();assert call('creator.library')==feed;lib.od_close(core)
    # Frozen v2 schema is ours, not game data; v1-v2 migrations retain source bytes.
    for version in [1,2]:
        legacy=work/f'v{version}.db'
        with sqlite3.connect(legacy) as db:
            db.executescript((ROOT/f'fixtures/schema-v{version}.sql').read_text())
            db.execute("INSERT INTO meta VALUES('content','creator-content')")
            db.execute("INSERT INTO profiles(id,stamina) VALUES('p',7)")
        digest=hashlib.sha256(legacy.read_bytes()).hexdigest()
        core=opened();assert lib.od_import_save(core,str(legacy).encode())==0
        assert call('profile.snapshot')['stamina']==7 and call('creator.library')['featured']==[]
        assert hashlib.sha256(legacy.read_bytes()).hexdigest()==digest
        lib.od_close(core);core=opened(legacy);lib.od_close(core)
        with sqlite3.connect(legacy) as db:assert db.execute('PRAGMA user_version').fetchone()[0]==12
print('PASS created settings/share/update/provenance, typed/master rejection, FIFO/main epoch, pinned summons/defaults/replay, hostile save rejection, v1/v2 migration')
