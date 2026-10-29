"""One integrated schedule/tournament/Kai transaction and save scenario; no native builds."""
import copy
import ctypes
import datetime as dt
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
def utc(text):return int(dt.datetime.fromisoformat(text).replace(tzinfo=dt.timezone.utc).timestamp())
with tempfile.TemporaryDirectory(prefix='schedule-',dir=ROOT/'build') as temp:
    work=pathlib.Path(temp);master=work/'master.db';save=work/'save.db'
    with sqlite3.connect(master) as db:
        db.execute('CREATE TABLE cards(id INTEGER PRIMARY KEY,lv_max INTEGER,skill_lv_max INTEGER)')
        db.executemany('INSERT INTO cards VALUES(?,150,20)',[(1,),(2,)])
        for table in ['awakening_items','training_items','support_items','equipment_skill_items','act_items']:
            db.execute(f'CREATE TABLE {table}(id INTEGER PRIMARY KEY)');db.execute(f'INSERT INTO {table} VALUES(1)')
        db.execute('CREATE TABLE quests(id INTEGER PRIMARY KEY,prev_quest_id INTEGER)');db.execute('INSERT INTO quests VALUES(1,0)')
        db.execute('CREATE TABLE sugoroku_maps(id INTEGER PRIMARY KEY,quest_id INTEGER,act INTEGER)');db.execute('INSERT INTO sugoroku_maps VALUES(1,1,1)')
    def opened(path=save):
        c=ctypes.c_void_p();assert lib.od_open(str(path).encode(),str(master).encode(),b'schedule-master',ctypes.byref(c))==0;return c
    core=opened()
    def call(op,args=None,cmd=None,error=None,profile='p'):
        out=ctypes.c_void_p();rc=lib.od_execute(core,op.encode(),profile.encode(),cmd.encode() if cmd else None,json.dumps(args or {},separators=(',',':')).encode(),ctypes.byref(out))
        if error:
            assert rc<0 and lib.od_last_error(core).decode()==error,(op,rc,lib.od_last_error(core));return
        assert rc==0,(op,lib.od_last_error(core))
        try:return json.loads(ctypes.string_at(out))
        finally:lib.od_free(out)
    call('profile.create',{'initial_stamina':20},'open')
    call('inventory.grant',{'source':'seed','rewards':[{'kind':'stone','id':0,'quantity':100}]},'fund')
    cid=call('card.add',{'master_id':1},'card')['cards'][0]['instance_id']
    call('team.set',{'slot':0,'members':[cid]},'team')
    for label in ['a','b']:
        call('banner.configure',{'banner_id':f'history-{label}','version':1,'epoch':1,'main_id':'ur','policy':{'lr_ppm':0,'slr_ppm':0,'gr_ppm':0,'multi_count':2},'pool':[{'definition_id':'ur','master_id':1,'rarity':'UR','weight_ppm':1000000}]},f'banner-{label}')
    saturday=utc('2026-10-31T12:00:00');sunday=utc('2026-11-01T12:00:00');monday=utc('2026-11-02T00:00:00')
    catalog={'catalog_id':'official-v1','zone':0,'history':[{'banner_id':f'history-{label}','version':1,'first_open_utc':utc('2026-09-01T00:00:00'),'verified_official':True,'usable_local_content':True} for label in ['a','b']]}
    call('schedule.catalog.install',catalog,'catalog')
    rotation=call('schedule.rotate',{'catalog_id':'official-v1','now_utc':saturday},'rotate')
    assert set(rotation['banner_ids'])=={'history-a','history-b'}
    assert call('schedule.rotate',{'catalog_id':'official-v1','now_utc':saturday},'same-week')==rotation
    assert call('schedule.rotate',{'catalog_id':'official-v1','now_utc':saturday},'rotate')==rotation
    config={'tournament_id':'wt','version':1,'zone':0,'seed':'000000000000002a','tie_policy':0,'competitors':[{'id':'ai','points_per_hour':10,'extra_points_per_hour_max':0}],'maps':[{'map_id':1,'points':1000}],'reward_tiers':[{'from_rank':1,'to_rank':100,'rewards':[{'kind':'training','id':1,'quantity':2},{'kind':'medal','id':1,'quantity':2},{'kind':'stone','id':0,'quantity':2}]}]}
    call('tournament.configure',config,'wt-config')
    common={'tournament_id':'wt','version':1,'now_utc':saturday}
    initial=call('tournament.snapshot',common,'wt-open')
    assert initial['player_points']==0
    run={'run_id':'live','map_id':1,'team_slot':0,'assets_ready':True,'rewards':[{'kind':'stone','id':0,'quantity':1}]}
    call('run.start',run,'start')
    call('tournament.enroll_run',dict(common,run_id='live'),'enroll')
    call('run.finish',{'run_id':'live','outcome':'clear'},'finish')
    points=call('tournament.record_run',dict(common,run_id='live'),'record')
    assert points['player_points']==1000
    assert call('tournament.record_run',dict(common,run_id='live'),'record')['player_points']==1000
    assert call('tournament.record_run',dict(common,run_id='live'),'record-new')['player_points']==1000
    ahead=call('tournament.snapshot',dict(common,now_utc=sunday),'catchup')
    assert ahead['simulated_competitors'][0]['points']>initial['simulated_competitors'][0]['points']
    lib.od_close(core);core=opened()
    assert call('tournament.snapshot',dict(common,now_utc=sunday),'catchup')==ahead
    # Weekend card banner grants real material instances, with one debit and exact replay.
    kai={'banner_id':'kai','version':1,'zone':0,'multi_count':2,'pool':[{'master_id':2,'verified_elder_kai':True,'super_attack_levels':1,'weight_ppm':1000000}]}
    call('elder_kai.configure',kai,'kai-config')
    pre=call('profile.snapshot')
    drawargs={'banner_id':'kai','version':1,'now_utc':sunday,'kind':'multi'}
    draw=call('elder_kai.draw',drawargs,'kai-draw')
    post=call('profile.snapshot');assert len(post['cards'])==len(pre['cards'])+2
    assert next(x['quantity'] for x in post['inventory'] if x['kind']=='stone')==next(x['quantity'] for x in pre['inventory'] if x['kind']=='stone')-50
    assert call('elder_kai.draw',drawargs,'kai-draw')==draw and call('profile.snapshot')==post
    call('elder_kai.draw',dict(drawargs,now_utc=monday),'weekday-kai',error='NOT_ACTIVE')
    # Claim applies 3/6/10 exactly once; source/run points remain unchanged on retries.
    claimargs=dict(common,now_utc=monday,weekend_id=20261031)
    balance=next(x['quantity'] for x in post['inventory'] if x['kind']=='stone')
    call('inventory.grant',{'source':'overflow-fixture','rewards':[{'kind':'stone','id':0,'quantity':(9007199254740991-balance)//10}]},'fill')
    full=call('profile.snapshot')
    with sqlite3.connect(save) as db:period_before=db.execute('SELECT observed_utc FROM tournament_periods').fetchall()
    # Training/medal credits occur before stone overflow; every intermediate write must roll back.
    call('tournament.claim',claimargs,'claim',error='QUANTITY_OVERFLOW')
    assert call('profile.snapshot')==full
    with sqlite3.connect(save) as db:
        assert db.execute('SELECT observed_utc FROM tournament_periods').fetchall()==period_before
        assert db.execute('SELECT count(*) FROM tournament_claims').fetchone()[0]==0
    call('elder_kai.draw',drawargs,'release-50-stones')
    post=call('profile.snapshot')
    reward=call('tournament.claim',claimargs,'claim')
    before=post;after=call('profile.snapshot');b={(x['kind'],x['id']):x['quantity'] for x in before['inventory']};a={(x['kind'],x['id']):x['quantity'] for x in after['inventory']}
    assert a['stone',0]-b['stone',0]==20 and a['medal',1]-b.get(('medal',1),0)==12 and a['training',1]-b.get(('training',1),0)==6
    assert call('tournament.claim',claimargs,'claim')==reward
    after=call('card.lock',{'instance_id':cid,'locked':True},'after-claim-lock')
    assert call('tournament.claim',claimargs,'claim-new')==reward and call('profile.snapshot')==after
    exported=work/'export.db';assert lib.od_export_save(core,str(exported).encode())==0
    assert lib.od_import_save(core,str(exported).encode())==0 and call('profile.snapshot')==after
    def reject(sql):
        bad=work/'bad.db'
        with sqlite3.connect(exported) as src,sqlite3.connect(bad) as dst:src.backup(dst);dst.execute(sql)
        assert lib.od_import_save(core,str(bad).encode())<0 and call('profile.snapshot')==after
    reject("UPDATE tournament_ai SET state=json_set(state,'$.points',99999999)")
    reject("UPDATE runs SET team_snapshot='[true]'")
    reject("UPDATE inventory SET kind='unsupported' WHERE kind='medal'")
    lib.od_close(core)
    # v4 migration/import preserves source bytes and old player progression/locks.
    old=work/'v4.db'
    with sqlite3.connect(old) as db:
        db.executescript((ROOT/'fixtures/schema-v4.sql').read_text())
        db.execute("INSERT INTO meta VALUES('content','schedule-master')");db.execute("INSERT INTO profiles(id,stamina) VALUES('p',7)")
        db.execute("INSERT INTO owned_cards(id,profile,master_id) VALUES(1,'p',1)");db.execute('INSERT INTO owned_progress(instance_id,locked) VALUES(1,1)')
    digest=hashlib.sha256(old.read_bytes()).hexdigest();core=opened()
    assert lib.od_import_save(core,str(old).encode())==0 and hashlib.sha256(old.read_bytes()).hexdigest()==digest
    assert call('profile.snapshot')['cards'][0]['locked']==1
    lib.od_close(core);core=opened(old);lib.od_close(core)
    with sqlite3.connect(old) as db:assert db.execute('PRAGMA user_version').fetchone()[0]==15
print('PASS persisted rotation/replay, enrolled clear points/AI catchup, Kai debit/grants, once-only 3/6/10 claims, hostile state rejection and v4 migration')
