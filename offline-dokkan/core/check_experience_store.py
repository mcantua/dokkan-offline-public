"""One targeted real master-curve XP/lock/source-ledger/save scenario."""
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
lib.od_free.argtypes=[ctypes.c_void_p];lib.od_close.argtypes=[ctypes.c_void_p]
lib.od_export_save.argtypes=lib.od_import_save.argtypes=[ctypes.c_void_p,ctypes.c_char_p]
with tempfile.TemporaryDirectory(prefix='xp-',dir=ROOT/'build') as temp:
    work=pathlib.Path(temp);master=work/'master.db';save=work/'save.db'
    with sqlite3.connect(master) as db:
        db.execute('CREATE TABLE cards(id INTEGER PRIMARY KEY,lv_max INTEGER,skill_lv_max INTEGER,exp_type INTEGER)')
        db.execute('INSERT INTO cards VALUES(1,5,10,1)')
        db.execute('CREATE TABLE card_exps(id INTEGER PRIMARY KEY,exp_type INTEGER,lv INTEGER,exp_total INTEGER)')
        db.executemany('INSERT INTO card_exps VALUES(?,1,?,?)',[(i,i,x) for i,x in enumerate([0,10,30,60,100],1)])
        db.execute('CREATE TABLE sugoroku_maps(id INTEGER PRIMARY KEY)');db.execute('INSERT INTO sugoroku_maps VALUES(1)')
    def opened(path=save):
        c=ctypes.c_void_p();assert lib.od_open(str(path).encode(),str(master).encode(),b'xp-master',ctypes.byref(c))==0;return c
    core=opened()
    def call(op,args=None,cmd=None,error=None,profile='p'):
        out=ctypes.c_void_p();rc=lib.od_execute(core,op.encode(),profile.encode(),cmd.encode() if cmd else None,json.dumps(args or {},separators=(',',':')).encode(),ctypes.byref(out))
        if error:assert rc<0 and lib.od_last_error(core).decode()==error,(op,rc,lib.od_last_error(core));return
        assert rc==0,(op,lib.od_last_error(core))
        try:return json.loads(ctypes.string_at(out))
        finally:lib.od_free(out)
    call('profile.create',cmd='open')
    card=call('card.add',{'master_id':1},'add')['cards'][0];cid=card['instance_id']
    assert card['experience'] is None and card['locked']==0
    grant={'instance_id':cid,'source':'battle-1-card-1','quantity':15}
    first=call('card.experience.grant',grant,'xp')
    assert first['cards'][0]['experience']==15 and first['cards'][0]['level']==2
    assert call('card.experience.grant',grant,'xp')==first
    assert call('card.experience.grant',grant,'source-retry')==first
    call('card.experience.grant',dict(grant,quantity=16),'source-conflict',error='REWARD_SOURCE_CONFLICT')
    before=call('profile.snapshot')
    call('card.experience.grant',dict(grant,source='too-much',quantity=100),'overflow',error='EXPERIENCE_CAP_EXCEEDED')
    call('card.experience.grant',dict(grant,source='bool',quantity=True),'bool',error='INVALID_ARGUMENT')
    call('card.experience.grant',dict(grant,source='unknown',level=5),'inject',error='INVALID_ARGUMENT')
    assert call('profile.snapshot')==before
    locked=call('card.lock',{'instance_id':cid,'locked':True},'lock')
    assert locked['cards'][0]['locked']==1 and locked['cards'][0]['experience']==15
    call('card.lock',{'instance_id':cid,'locked':1},'integer-lock',error='INVALID_ARGUMENT')
    call('profile.create',cmd='other',profile='other')
    call('card.experience.grant',grant,'foreign',error='CARD_NOT_OWNED',profile='other')
    lib.od_close(core)
    with sqlite3.connect(save) as db:db.execute("INSERT INTO runs VALUES('pending','p',1,1,'xp-master',0,?,0,?,'started',NULL,NULL)",(json.dumps([cid]),json.dumps({'rewards':[{'kind':'stone','id':0,'quantity':1}]})))
    core=opened()
    call('card.experience.grant',dict(grant,source='during-run',quantity=1),'during-run',error='CARD_IN_USE')
    call('run.finish',{'run_id':'pending','outcome':'failed'},'end-run')
    final=call('card.experience.grant',dict(grant,source='cap',quantity=85),'cap')
    assert final['cards'][0]['experience']==100 and final['cards'][0]['level']==5
    exported=work/'export.db';assert lib.od_export_save(core,str(exported).encode())==0
    with sqlite3.connect(exported) as db:db.execute('UPDATE owned_progress SET experience=1')
    assert lib.od_import_save(core,str(exported).encode())<0 and call('profile.snapshot')==final
    lib.od_close(core);core=opened();assert call('profile.snapshot')==final;lib.od_close(core)
    old=work/'v3.db'
    with sqlite3.connect(old) as db:
        db.executescript((ROOT/'fixtures/schema-v3.sql').read_text())
        db.execute("INSERT INTO meta VALUES('content','xp-master')");db.execute("INSERT INTO profiles(id) VALUES('p')")
        db.execute("INSERT INTO owned_cards(id,profile,master_id,level) VALUES(1,'p',1,2)")
    digest=hashlib.sha256(old.read_bytes()).hexdigest();core=opened()
    assert lib.od_import_save(core,str(old).encode())==0 and hashlib.sha256(old.read_bytes()).hexdigest()==digest
    seeded=call('card.experience.grant',{'instance_id':1,'source':'migrated','quantity':5},'migrated')
    assert seeded['cards'][0]['experience']==15 and seeded['cards'][0]['level']==2
    lib.od_close(core);core=opened(old);lib.od_close(core)
    with sqlite3.connect(old) as db:assert db.execute('PRAGMA user_version').fetchone()[0]==13
print('PASS exact master-curve XP/level, source replay/overflow/ownership, lock persistence, in-run protection, hostile XP save rejection and v3 migration')
