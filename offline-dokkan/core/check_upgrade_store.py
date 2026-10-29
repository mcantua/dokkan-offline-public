"""One focused official-upgrade, trusted-clock and rank-exclusive integration scenario."""
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
lib.od_execute_clocked.argtypes=[ctypes.c_void_p]+[ctypes.c_char_p]*4+[ctypes.c_int64,ctypes.POINTER(ctypes.c_void_p)]
lib.od_last_error.argtypes=[ctypes.c_void_p];lib.od_last_error.restype=ctypes.c_char_p
lib.od_free.argtypes=[ctypes.c_void_p];lib.od_close.argtypes=[ctypes.c_void_p]
lib.od_export_save.argtypes=lib.od_import_save.argtypes=[ctypes.c_void_p,ctypes.c_char_p]
def utc(s):return int(dt.datetime.fromisoformat(s).replace(tzinfo=dt.timezone.utc).timestamp())
with tempfile.TemporaryDirectory(prefix='upgrade-',dir=ROOT/'build') as temp:
    work=pathlib.Path(temp);master=work/'master.db';save=work/'save.db'
    base={'id':11,'name':'Synthetic official','rarity':4,'element':10,'hp_init':10,'atk_init':20,'def_init':30,'hp_max':1000,'atk_max':2000,'def_max':3000,'lv_max':120,'skill_lv_max':10,'leader_skill_set_id':1,'passive_skill_set_id':1,'exp_type':1,'optimal_awakening_grow_type':0,'aura_scale':1.0}
    cards={11:dict(base),21:dict(base,id=21,optimal_awakening_grow_type=77),31:dict(base,id=31,optimal_awakening_grow_type=88)}
    with sqlite3.connect(master) as db:
        db.execute('CREATE TABLE cards('+','.join(k+(' TEXT' if isinstance(v,str) else ' REAL' if isinstance(v,float) else ' INTEGER')+(' PRIMARY KEY' if k=='id' else ' NOT NULL') for k,v in base.items())+')')
        for card in cards.values():db.execute('INSERT INTO cards VALUES('+','.join('?' for _ in card)+')',list(card.values()))
        db.execute('CREATE TABLE card_awakening_routes(id INTEGER PRIMARY KEY,type TEXT NOT NULL,card_id INTEGER NOT NULL,awaked_card_id INTEGER NOT NULL,card_awakening_set_id INTEGER NOT NULL,optimal_awakening_step INTEGER NOT NULL,optimal_awakening_type INTEGER NOT NULL)')
        db.execute('CREATE TABLE optimal_awakening_growths(id INTEGER PRIMARY KEY,optimal_awakening_grow_type INTEGER NOT NULL,step INTEGER NOT NULL,lv_max INTEGER NOT NULL,skill_lv_max INTEGER NOT NULL,passive_skill_set_id INTEGER NOT NULL,leader_skill_set_id INTEGER NOT NULL)')
        db.execute('CREATE TABLE card_awakening_sets(id INTEGER PRIMARY KEY)');db.execute('INSERT INTO card_awakening_sets VALUES(1)')
        for cid,grow,steps in [(21,77,7),(31,88,8)]:
            for step in range(1,steps+1):
                db.execute('INSERT INTO optimal_awakening_growths VALUES(?,?,?,140,15,1,1)',(cid*10+step,grow,step))
                db.execute("INSERT INTO card_awakening_routes VALUES(?,'CardAwakeningRoute::Optimal',?,?,1,?,?)",(cid*10+step,cid,cid,step,2 if step==8 else 1))
        for table in ['leader_skill_sets','passive_skill_sets']:
            db.execute(f'CREATE TABLE {table}(id INTEGER PRIMARY KEY,name TEXT NOT NULL)');db.execute(f"INSERT INTO {table} VALUES(1,'original')")
        db.execute('CREATE TABLE passive_skills(id INTEGER PRIMARY KEY,name TEXT NOT NULL,efficacy_type INTEGER NOT NULL,eff_value1 INTEGER NOT NULL)');db.execute("INSERT INTO passive_skills VALUES(1,'original',1,100)")
        db.execute('CREATE TABLE passive_skill_set_relations(id INTEGER PRIMARY KEY,passive_skill_set_id INTEGER NOT NULL,passive_skill_id INTEGER NOT NULL)');db.execute('INSERT INTO passive_skill_set_relations VALUES(1,1,1)')
        db.execute('CREATE TABLE leader_skills(id INTEGER PRIMARY KEY,leader_skill_set_id INTEGER NOT NULL,efficacy_type INTEGER NOT NULL,eff_value1 INTEGER NOT NULL)');db.execute('INSERT INTO leader_skills VALUES(1,1,1,100)')
        db.execute('CREATE TABLE card_exps(id INTEGER PRIMARY KEY,exp_type INTEGER,lv INTEGER,exp_total INTEGER)');db.executemany('INSERT INTO card_exps VALUES(?,1,?,?)',[(i,i,(i-1)*100) for i in range(1,141)])
        db.execute('CREATE TABLE quests(id INTEGER PRIMARY KEY,prev_quest_id INTEGER)');db.execute('INSERT INTO quests VALUES(1,0)')
        db.execute('CREATE TABLE sugoroku_maps(id INTEGER PRIMARY KEY,quest_id INTEGER,act INTEGER)');db.execute('INSERT INTO sugoroku_maps VALUES(1,1,1)')
    def opened(path=save):
        c=ctypes.c_void_p();assert lib.od_open(str(path).encode(),str(master).encode(),b'upgrade-master',ctypes.byref(c))==0;return c
    core=opened()
    def call(op,args=None,cmd=None,error=None,profile='p',clock=None):
        out=ctypes.c_void_p();params=[core,op.encode(),profile.encode(),cmd.encode() if cmd else None,json.dumps(args or {},separators=(',',':')).encode()]
        rc=lib.od_execute_clocked(*params,clock,ctypes.byref(out)) if clock is not None else lib.od_execute(*params,ctypes.byref(out))
        if error:assert rc<0 and lib.od_last_error(core).decode()==error,(op,rc,lib.od_last_error(core));return
        assert rc==0,(op,lib.od_last_error(core))
        try:return json.loads(ctypes.string_at(out))
        finally:lib.od_free(out)
    def wallet(state):return next((i['quantity'] for i in state['inventory'] if i['kind']=='stone'),0)
    call('profile.create',{'initial_stamina':20},'open')
    call('inventory.grant',{'source':'fund','rewards':[{'kind':'stone','id':0,'quantity':500}]},'fund')
    instances={cid:call('card.add',{'master_id':cid},f'card-{cid}')['cards'][-1]['instance_id'] for cid in cards}
    assert call('upgrade.status',{'instance_id':instances[11]})['official_eza']==0
    assert call('upgrade.status',{'instance_id':instances[21]})['official_eza']==1
    assert call('upgrade.status',{'instance_id':instances[31]})['official_super_eza']==1
    def custom(cid=11,kind='custom_eza',revision=1,power=200):
        card=dict(cards[cid],aura_scale=1,lv_max=140,skill_lv_max=15,leader_skill_set_id=-101,passive_skill_set_id=-201,optimal_awakening_grow_type=999)
        steps=7 if kind=='custom_eza' else 8
        tables={'leader_skill_sets':[{'id':-101,'name':'Authored leader'}],'leader_skills':[{'id':-501,'leader_skill_set_id':-101,'efficacy_type':1,'eff_value1':power}], 'passive_skill_sets':[{'id':-201,'name':'Authored passive'}],'passive_skills':[{'id':-401,'name':'Authored ability','efficacy_type':1,'eff_value1':power}],'passive_skill_set_relations':[{'id':-301,'passive_skill_set_id':-201,'passive_skill_id':-401}], 'optimal_awakening_growths':[],'card_awakening_routes':[]}
        pattern=[(125,10),(125,11),(130,11),(130,12),(130,13),(135,14),(140,15)]
        if steps==8:pattern.append(pattern[-1])
        for i,(lv,sa) in enumerate(pattern,1):
            tables['optimal_awakening_growths'].append({'id':-i,'optimal_awakening_grow_type':999,'step':i,'lv_max':lv,'skill_lv_max':sa,'passive_skill_set_id':-201,'leader_skill_set_id':-101})
            tables['card_awakening_routes'].append({'id':-1000-i,'type':'CardAwakeningRoute::Optimal','card_id':cid,'awaked_card_id':cid,'card_awakening_set_id':1,'optimal_awakening_step':i,'optimal_awakening_type':2 if i==8 else 1})
        return {'format':'offline-dokkan-official-upgrade','schema_version':1,'version':revision,'source':{'content_id':'upgrade-master','master_id':cid},'kind':kind,'card':card,'tables':tables}
    doc=custom();args={'instance_id':instances[11],'kind':'custom_eza','definition':doc}
    call('card.experience.grant',{'instance_id':instances[11],'source':'xp','quantity':10},'xp')
    before=call('profile.snapshot');bad=copy.deepcopy(args);bad['definition']['card']['exp_type']=999
    call('upgrade.apply',bad,'rollback-upgrade',error='UPGRADE_PROGRESS_CONFLICT')
    assert call('profile.snapshot')==before
    first=call('upgrade.apply',args,'custom-eza')
    assert wallet(before)-wallet(first)==500 and first['cards'][0]['official_upgrade']['label']=='Custom EZA'
    assert first['official_upgrades'][0]['document']==doc and call('upgrade.apply',args,'custom-eza')==first
    call('upgrade.apply',args,'repeat-eza',error='ALREADY_APPLIED')
    call('creator.import',{'definition':doc},'share-official',error='INVALID_DEFINITION')
    assert call('creator.library')['definitions']==[]
    edit=custom(revision=2,power=250)
    edited=call('upgrade.edit',dict(args,definition=edit),'edit')
    assert wallet(edited)==wallet(first) and edited['official_upgrades'][0]['document']==edit
    seza=custom(kind='custom_super_eza',power=300)
    upgraded=call('upgrade.apply',{'instance_id':instances[11],'kind':'custom_super_eza','definition':seza},'custom-seza')
    assert wallet(edited)-wallet(upgraded)==700 and upgraded['cards'][0]['official_upgrade']['custom_super_eza']==1
    call('upgrade.apply',args,'no-downgrade',error='ALREADY_APPLIED')
    call('upgrade.apply',{'instance_id':instances[21],'kind':'custom_eza','definition':custom(21)},'official-has-eza',error='INELIGIBLE')
    call('profile.create',cmd='poor-open',profile='poor');poor_id=call('card.add',{'master_id':11},'poor-card',profile='poor')['cards'][0]['instance_id']
    call('upgrade.apply',dict(args,instance_id=poor_id),'poor-upgrade',profile='poor',error='INSUFFICIENT_STONES')
    def enhanced(power,policy,revision=1):
        return {'format':'offline-dokkan-official-upgrade','schema_version':1,'version':revision,'source':{'content_id':'upgrade-master','master_id':21},'kind':'enhanced','policy_id':'trusted-meta','policy_version':policy,'card':dict(cards[21],lv_max=140,skill_lv_max=15,hp_max=power),'tables':{}}
    policy=enhanced(2000,1);call('upgrade.policy.install',{'definition':policy},'policy')
    before=call('profile.snapshot');enhanced_result=call('upgrade.apply',{'instance_id':instances[21],'kind':'enhanced','policy_id':'trusted-meta','policy_version':1},'enhance')
    assert wallet(before)-wallet(enhanced_result)==300
    assert next(c for c in enhanced_result['cards'] if c['master_id']==21)['official_upgrade']['manual_edits_allowed']==0
    call('upgrade.edit',{'instance_id':instances[21],'kind':'enhanced','definition':policy},'manual-enhanced',error='MANUAL_EDIT_FORBIDDEN')
    call('upgrade.apply',{'instance_id':instances[21],'kind':'custom_super_eza','definition':custom(21,'custom_super_eza')},'manual-through-seza',error='MANUAL_EDIT_FORBIDDEN')
    call('upgrade.apply',{'instance_id':instances[21],'kind':'enhanced','policy_id':'trusted-meta','policy_version':1,'definition':policy},'injected-enhance',error='GENERATED_POLICY_REQUIRED')
    call('upgrade.apply',{'instance_id':instances[21],'kind':'enhanced','policy_id':'trusted-meta','policy_version':1},'repeat-meta',error='ALREADY_APPLIED')
    # A policy with changed labels but identical mechanics cannot charge again.
    no_change=enhanced(2000,2);call('upgrade.policy.install',{'definition':no_change},'no-change-policy')
    call('upgrade.apply',{'instance_id':instances[21],'kind':'enhanced','policy_id':'trusted-meta','policy_version':2},'no-change',error='UPGRADE_HAS_NO_MECHANICAL_CHANGE')
    policy2=enhanced(2500,3);call('upgrade.policy.install',{'definition':policy2},'policy-new')
    later=call('upgrade.apply',{'instance_id':instances[21],'kind':'enhanced','policy_id':'trusted-meta','policy_version':3},'enhance-new')
    assert wallet(enhanced_result)-wallet(later)==300
    call('team.set',{'slot':0,'members':[instances[11]]},'team')
    run={'run_id':'pending','map_id':1,'team_slot':0,'assets_ready':True,'rewards':[{'kind':'stone','id':0,'quantity':1}]}
    call('run.start',run,'start')
    call('upgrade.edit',{'instance_id':instances[11],'kind':'custom_super_eza','definition':custom(kind='custom_super_eza',revision=2,power=350)},'in-use',error='CARD_IN_USE')
    call('run.finish',{'run_id':'pending','outcome':'failed'},'finish')
    # Stable ordinary intent caches before a new host clock is injected, in the same DB.
    for label in ['a','b']:
        call('banner.configure',{'banner_id':label,'version':1,'epoch':1,'main_id':'official','policy':{'lr_ppm':0,'slr_ppm':0,'gr_ppm':0,'multi_count':2},'pool':[{'definition_id':'official','master_id':11,'rarity':'UR','weight_ppm':1000000}]},'banner-'+label)
    saturday=utc('2026-10-31T12:00:00');monday=utc('2026-11-02T00:00:00')
    call('schedule.catalog.install',{'catalog_id':'history','zone':0,'history':[{'banner_id':label,'version':1,'first_open_utc':utc('2026-09-01T00:00:00'),'verified_official':True,'usable_local_content':True} for label in ['a','b']]},'catalog')
    rotated=call('schedule.rotate',{'catalog_id':'history'},'clock-intent',clock=saturday)
    assert rotated['host_now_utc']==saturday
    assert call('schedule.rotate',{'catalog_id':'history'},'clock-intent',clock=saturday+7*86400)==rotated
    call('schedule.rotate',{'catalog_id':'history','now_utc':saturday},'caller-clock',clock=saturday,error='CLOCKED_ARGUMENT_FORBIDDEN')
    call('schedule.rotate',{'catalog_id':'other'},'clock-intent',clock=saturday,error='COMMAND_CONFLICT')
    with sqlite3.connect(save) as db:assert json.loads(db.execute("SELECT input FROM commands WHERE id='clock-intent'").fetchone()[0])=={'catalog_id':'history'}
    # Original tournament reward settings are separate from ordinary Creator sharing/summons.
    exclusive={'format':'offline-dokkan-definition','schema_version':1,'definition_id':'tournament-exclusive:tin-reward','version':1,'source':{'content_id':'upgrade-master','master_id':11},'rarity':'UR','fully_awakened':True,'creator':{'id':'tin','name':'Tin'},'card':dict(base,name='Authored reward'),'tables':{}}
    call('tournament.exclusive.register',{'definition':exclusive},'exclusive')
    call('creator.import',{'definition':exclusive},'exclusive-share',error='TOURNAMENT_EXCLUSIVE_NOT_SHAREABLE')
    call('creator.import',{'definition':exclusive},'exclusive-share-new-profile',profile='poor',error='TOURNAMENT_EXCLUSIVE_NOT_SHAREABLE')
    config={'tournament_id':'wt','version':1,'zone':0,'seed':'000000000000002a','tie_policy':0,'competitors':[{'id':'ai','points_per_hour':1,'extra_points_per_hour_max':0}],'maps':[{'map_id':1,'points':1000}],'reward_tiers':[{'from_rank':1,'to_rank':100,'rewards':[{'kind':'tournament_created','definition_id':exclusive['definition_id'],'definition_version':1,'multiplier_category':'item','quantity':1}]}]}
    call('tournament.configure',config,'wt-config')
    run['run_id']='ranked';call('run.start',run,'ranked-start')
    common={'tournament_id':'wt','version':1}
    call('tournament.enroll_run',dict(common,run_id='ranked'),'enroll',clock=saturday)
    call('run.finish',{'run_id':'ranked','outcome':'clear'},'ranked-clear')
    call('tournament.record_run',dict(common,run_id='ranked'),'record',clock=saturday)
    receipt=call('tournament.claim',dict(common,weekend_id=20261031),'claim',clock=monday)
    assert len(receipt['created_cards'])==3
    assert call('tournament.claim',dict(common,weekend_id=20261031),'claim',clock=monday+86400)==receipt
    assert call('tournament.claim',dict(common,weekend_id=20261031),'claim-new',clock=monday+86400)==receipt
    final=call('profile.snapshot');owned=[c for c in final['cards'] if c['tournament_definition']]
    assert len(owned)==3 and len(final['tournament_definitions'])==1 and all(c['created_definition'] is None and c['official_upgrade'] is None and c['level']==c['sa_level']==1 and c['tournament_definition']['potential_locked']==1 for c in owned)
    call('card.experience.grant',{'instance_id':owned[0]['instance_id'],'source':'exclusive-xp','quantity':11900},'exclusive-xp')
    final=call('profile.snapshot');assert next(c for c in final['cards'] if c['instance_id']==owned[0]['instance_id'])['level']==120
    exported=work/'export.db';assert lib.od_export_save(core,str(exported).encode())==0
    assert lib.od_import_save(core,str(exported).encode())==0 and call('profile.snapshot')==final
    for i,sql in enumerate(["UPDATE official_upgrade_versions SET stone_cost=0 WHERE kind=3", "UPDATE official_upgrade_policies SET document=json_set(document,'$.card.hp_max',99999) WHERE policy_version=3", "UPDATE tournament_exclusive_owned SET version=999"]):
        bad=work/f'bad-{i}.db'
        with sqlite3.connect(exported) as src,sqlite3.connect(bad) as dst:src.backup(dst);dst.execute(sql)
        assert lib.od_import_save(core,str(bad).encode())<0 and call('profile.snapshot')==final
    lib.od_close(core);core=opened();assert call('profile.snapshot')==final;lib.od_close(core)
    legacy=work/'v5.db'
    with sqlite3.connect(legacy) as db:
        db.executescript((ROOT/'fixtures/schema-v5.sql').read_text());db.execute("INSERT INTO meta VALUES('content','upgrade-master')");db.execute("INSERT INTO profiles(id,stamina) VALUES('p',7)")
    digest=hashlib.sha256(legacy.read_bytes()).hexdigest();core=opened()
    assert lib.od_import_save(core,str(legacy).encode())==0 and hashlib.sha256(legacy.read_bytes()).hexdigest()==digest
    assert call('profile.snapshot')['stamina']==7
    lib.od_close(core);core=opened(legacy);lib.od_close(core)
    with sqlite3.connect(legacy) as db:assert db.execute('PRAGMA user_version').fetchone()[0]==12
print('PASS official eligibility/graphs/prices/edit/meta-policy/replay/rollback, pinned original clock intents, exclusive rank grants/provenance/XP, hostile save rejection and v5 migration')
