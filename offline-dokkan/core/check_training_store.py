"""One real Eclipse/Sparking owned-training preview integration, without training mutations."""
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
with tempfile.TemporaryDirectory(prefix='training-owned-',dir=ROOT/'build') as temp:
    for filename in ['reference.db','sparking-reference.db']:
        master=ROOT.parents[1]/'unit-creator/apk/assets'/filename
        content='sha256:'+hashlib.sha256(master.read_bytes()).hexdigest()
        source=sqlite3.connect(master.as_uri()+'?mode=ro',uri=True);source.row_factory=sqlite3.Row
        card=source.execute('SELECT c.* FROM cards c WHERE c.rarity=5 AND c.lv_max=150 AND c.exp_type=25 AND c.leader_skill_set_id>0 AND c.passive_skill_set_id>0 AND NOT EXISTS(SELECT 1 FROM card_awakening_routes r WHERE r.card_id=c.id AND r.awaked_card_id!=c.id AND r.type IN(\'CardAwakeningRoute::Dokkan\',\'CardAwakeningRoute::Zet\')) ORDER BY c.id LIMIT 1').fetchone();assert card
        item=source.execute('SELECT * FROM training_items ORDER BY exp,id LIMIT 1').fetchone();field=source.execute('SELECT * FROM training_fields WHERE addend>0 ORDER BY id LIMIT 1').fetchone()
        thresholds=[r[0] for r in source.execute('SELECT exp_total FROM card_exps WHERE exp_type=? AND lv<=? ORDER BY lv',(card['exp_type'],card['lv_max']))]
        save=pathlib.Path(temp)/(filename+'.save');core=ctypes.c_void_p();assert lib.od_open(str(save).encode(),str(master).encode(),content.encode(),ctypes.byref(core))==0
        def call(op,args=None,cmd=None,error=None,profile='p'):
            out=ctypes.c_void_p();rc=lib.od_execute(core,op.encode(),profile.encode(),cmd.encode() if cmd else None,json.dumps(args or {}).encode(),ctypes.byref(out))
            if error:assert rc<0 and lib.od_last_error(core).decode()==error,(op,lib.od_last_error(core));return
            assert rc==0,(op,lib.od_last_error(core))
            try:return json.loads(ctypes.string_at(out))
            finally:lib.od_free(out)
        call('profile.create',cmd='open');owned=call('card.add',{'master_id':card['id']},'add')['cards'][0]['instance_id']
        args={'instance_id':owned,'items':[{'item_id':item['id'],'quantity':2}],'field_id':field['id']}
        baseline=call('profile.snapshot');unknown=call('card.training.preview',args)
        assert unknown['instance_id']==owned and unknown['owned_level']==1 and unknown['sa_level']==1 and unknown['effective_level_cap']==150
        assert unknown['final_exp'] is None and unknown['final_zeni_cost'] is None and not unknown['can_commit']
        assert not unknown['zeni_known'] and unknown['item_zeni_subtotal_affordable'] is None
        assert unknown['base_item_exp']==item['exp']*2 and unknown['item_zeni_subtotal']==item['zeni_to_use']*2
        assert not unknown['items_available'] and unknown['items'][0]['available']==0 and unknown['items'][0]['shortfall']==2
        projection=unknown['base_experience_projection'];assert not projection['owned_experience_known'] and projection['experience_upper']==thresholds[1]-1+item['exp']*2
        assert unknown['selected_field']['raw_addend']==field['addend'] and unknown['selected_field']['field_id']==field['id']
        assert call('profile.snapshot')==baseline
        call('inventory.grant',{'source':'training-item','rewards':[{'kind':'training','id':item['id'],'quantity':1}]},'item')
        call('card.experience.grant',{'instance_id':owned,'source':'level2','quantity':thresholds[1]},'level2')
        baseline=call('profile.snapshot');known=call('card.training.preview',args)
        assert known['owned_level']==2 and known['items_available'] and known['items'][0]['available']==3 and known['items'][0]['shortfall']==0
        exact=known['base_experience_projection'];assert exact['owned_experience_known'] and exact['experience_lower']==exact['experience_upper']==thresholds[1]+item['exp']*2
        for key,value in [('level',150),('experience',999),('balance',999),('zeni',999),('master_id',card['id'])]:
            call('card.training.preview',dict(args,**{key:value}),error='TRAINING_INVALID_ARGUMENT')
        call('card.training.preview',dict(args,items=[dict(args['items'][0],quantity=True)]),error='TRAINING_INVALID_ARGUMENT')
        call('card.training.preview',dict(args,items=['bad']),error='TRAINING_INVALID_ARGUMENT')
        call('card.training.preview',dict(args,items=args['items']*2),error='TRAINING_DUPLICATE_ITEM')
        call('card.training.preview',dict(args,field_id=9007199254740991),error='TRAINING_FIELD_UNAVAILABLE')
        call('card.training.preview',dict(args,items=[{'item_id':9007199254740991,'quantity':1}]),error='TRAINING_ITEM_INVALID')
        assert call('profile.snapshot')==baseline
        call('profile.create',cmd='other',profile='other');call('card.training.preview',args,profile='other',error='CARD_NOT_OWNED')
        # Authored cap remains effective; absent extended source curve is an explicit limitation.
        effective=dict(card);effective['lv_max']=200
        doc={'format':'offline-dokkan-definition','schema_version':1,'definition_id':'training-preview','version':1,'source':{'content_id':content,'master_id':card['id']},'rarity':'GR','fully_awakened':True,'progression_policy':'creator-lr-extended-v1','creator':{'id':'tin','name':'Tin'},'card':effective,'tables':{}}
        call('creator.import',{'definition':doc},'definition');call('inventory.grant',{'source':'stones','rewards':[{'kind':'stone','id':0,'quantity':1}]},'stones')
        banner={'banner_id':'preview','version':1,'epoch':1,'creator_epoch':1,'main_id':'training-preview','policy':{'lr_ppm':0,'slr_ppm':0,'gr_ppm':1000000,'multi_count':2},'pool':[{'definition_id':'training-preview','definition_version':1,'master_id':card['id'],'rarity':'GR','weight_ppm':1000000}]}
        call('banner.configure',banner,'banner');created=call('summon.draw',{'banner_id':'preview','kind':'single'},'draw')['summon']['draws'][0]['instance_id']
        baseline=call('profile.snapshot');custom=call('card.training.preview',dict(args,instance_id=created,field_id=0))
        assert custom['effective_level_cap']==200 and custom['selected_field'] is None
        assert custom['base_experience_projection']=={'available':False,'reason':'TRAINING_CURVE_UNAVAILABLE'} and not custom['can_commit']
        assert call('profile.snapshot')==baseline
        with sqlite3.connect(save) as state:
            assert state.execute("SELECT count(*) FROM commands WHERE operation='card.training.preview'").fetchone()[0]==0
            assert state.execute('PRAGMA user_version').fetchone()[0]==14
        lib.od_close(core);source.close()
print('PASS actual Eclipse/Sparking owned-level/SA/effectivecap, real training balances, known/unknown EXP, strict caller override rejection, honest extendedcurve limit and read-only state')
