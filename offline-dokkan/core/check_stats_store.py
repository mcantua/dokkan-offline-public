"""Tiny core integration: same-profile owned level + effective document, no arithmetic retest."""
import copy
import ctypes
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
with tempfile.TemporaryDirectory(prefix='stats-store-',dir=ROOT/'build') as temp:
    work=pathlib.Path(temp);master=work/'master.db'
    card={'id':11,'name':'Synthetic','rarity':5,'element':10,'hp_init':10,'atk_init':20,'def_init':30,'hp_max':110,'atk_max':220,'def_max':330,'lv_max':3,'skill_lv_max':20,'leader_skill_set_id':1,'passive_skill_set_id':1,'exp_type':1,'grow_type':1}
    with sqlite3.connect(master) as db:
        db.execute('CREATE TABLE cards('+','.join(k+(' TEXT' if isinstance(v,str) else ' INTEGER')+(' PRIMARY KEY' if k=='id' else ' NOT NULL') for k,v in card.items())+')');db.execute('INSERT INTO cards VALUES('+','.join('?' for _ in card)+')',list(card.values()))
        db.execute('CREATE TABLE card_growths(id INTEGER PRIMARY KEY,grow_type INTEGER,lv INTEGER,coef REAL)');db.executemany('INSERT INTO card_growths VALUES(?,1,?,?)',[(1,1,0),(2,2,.5),(3,3,1)])
        db.execute('CREATE TABLE card_exps(id INTEGER PRIMARY KEY,exp_type INTEGER,lv INTEGER,exp_total INTEGER)');db.executemany('INSERT INTO card_exps VALUES(?,1,?,?)',[(1,1,0),(2,2,10),(3,3,20)]);db.executemany('INSERT INTO card_exps VALUES(?,25,?,?)',[(1000+i,i,(i-1)*10) for i in range(1,151)])
        db.execute('CREATE TABLE card_awakening_routes(id INTEGER PRIMARY KEY,card_id INTEGER,awaked_card_id INTEGER,type TEXT)')
        for table in ['leader_skill_sets','passive_skill_sets']:
            db.execute(f'CREATE TABLE {table}(id INTEGER PRIMARY KEY)');db.execute(f'INSERT INTO {table} VALUES(1)')
    core=ctypes.c_void_p();assert lib.od_open(str(work/'save.db').encode(),str(master).encode(),b'stats-master',ctypes.byref(core))==0
    def call(op,args=None,cmd=None,error=None,profile='p'):
        out=ctypes.c_void_p();rc=lib.od_execute(core,op.encode(),profile.encode(),cmd.encode() if cmd else None,json.dumps(args or {}).encode(),ctypes.byref(out))
        if error:assert rc<0 and lib.od_last_error(core).decode()==error,(op,lib.od_last_error(core));return
        assert rc==0,(op,lib.od_last_error(core))
        try:return json.loads(ctypes.string_at(out))
        finally:lib.od_free(out)
    call('profile.create',cmd='open');cid=call('card.add',{'master_id':11},'add')['cards'][0]['instance_id']
    initial=call('card.stats',{'instance_id':cid});assert initial['level']==1 and initial['hp']==10
    call('card.experience.grant',{'instance_id':cid,'source':'level2','quantity':10},'xp')
    before=call('profile.snapshot');middle=call('card.stats',{'instance_id':cid})
    assert middle['level']==2 and middle['hp']==60 and middle['internal_policy'] and not middle['original_game_rounding_verified']
    assert call('profile.snapshot')==before
    call('card.stats',{'instance_id':cid,'level':3},error='INVALID_ARGUMENT')
    call('profile.create',cmd='other-open',profile='other');call('card.stats',{'instance_id':cid},profile='other',error='CARD_NOT_OWNED')
    doc={'format':'offline-dokkan-definition','schema_version':1,'definition_id':'gr','version':1,'source':{'content_id':'stats-master','master_id':11},'rarity':'GR','fully_awakened':True,'creator':{'id':'tin','name':'Tin'},'progression_policy':'creator-lr-extended-v1','stat_policy':'creator-cap-normalized-v1','card':dict(card,lv_max=200,hp_max=1000),'tables':{}}
    call('creator.import',{'definition':doc},'created')
    call('inventory.grant',{'source':'fund','rewards':[{'kind':'stone','id':0,'quantity':1}]},'fund')
    call('banner.configure',{'banner_id':'gr','version':1,'epoch':1,'creator_epoch':1,'main_id':'gr','policy':{'lr_ppm':0,'slr_ppm':0,'gr_ppm':1000000,'multi_count':2},'pool':[{'definition_id':'gr','definition_version':1,'master_id':11,'rarity':'GR','weight_ppm':1000000}]},'banner')
    draw=call('summon.draw',{'banner_id':'gr','kind':'single'},'draw');owned=draw['summon']['draws'][0]['instance_id']
    call('card.experience.grant',{'instance_id':owned,'source':'max','quantity':1990},'max')
    resolved=call('card.stats',{'instance_id':owned});assert resolved['level']==resolved['level_cap']==200 and resolved['hp']==1000 and resolved['final_exclusive']['atk_percent']==20 and not resolved['final_exclusive']['included_in_base']
    update=copy.deepcopy(doc);update['version']=2;update['stat_policy']='master-coefficient-linear-floor-v1'
    call('creator.import',{'definition':update},'repolicy',error='STAT_POLICY_CONFLICT')
    assert call('creator.export',{'definition_id':'gr'})==doc
    snapshot=call('profile.snapshot');exported=work/'export.db';assert lib.od_export_save(core,str(exported).encode())==0
    with sqlite3.connect(exported) as db:db.execute("UPDATE owned_cards SET potential='{\"forged\":1}' WHERE id=?",(owned,))
    assert lib.od_import_save(core,str(exported).encode())<0 and call('profile.snapshot')==snapshot
    lib.od_close(core)
print('PASS owned/profile/actual-level stat query, pinned effective GR settings and policy immutability; readonly/no client level injection')
