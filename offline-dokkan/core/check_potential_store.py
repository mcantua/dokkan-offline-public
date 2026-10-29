"""One focused read-only owned Hidden Potential preview against the supplied masters.
The masters remain ignored/read-only; this source contains no extracted game records.
"""
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
with tempfile.TemporaryDirectory(prefix='potential-owned-',dir=ROOT/'build') as temp:
    for filename in ['reference.db','sparking-reference.db']:
        master=ROOT.parents[1]/'unit-creator/apk/assets'/filename
        content='sha256:'+hashlib.sha256(master.read_bytes()).hexdigest()
        db=sqlite3.connect(master.as_uri()+'?mode=ro',uri=True);db.row_factory=sqlite3.Row
        source=db.execute('SELECT c.* FROM cards c WHERE c.rarity=5 AND c.potential_board_id>0 AND c.leader_skill_set_id>0 AND c.passive_skill_set_id>0 AND NOT EXISTS(SELECT 1 FROM card_awakening_routes r WHERE r.card_id=c.id AND r.awaked_card_id>0) ORDER BY c.id LIMIT 1').fetchone()
        assert source is not None
        save=pathlib.Path(temp)/(filename+'.save');core=ctypes.c_void_p()
        assert lib.od_open(str(save).encode(),str(master).encode(),content.encode(),ctypes.byref(core))==0
        def call(op,args=None,cmd=None,error=None,profile='p'):
            out=ctypes.c_void_p();rc=lib.od_execute(core,op.encode(),profile.encode(),cmd.encode() if cmd else None,json.dumps(args or {}).encode(),ctypes.byref(out))
            if error:assert rc<0 and lib.od_last_error(core).decode()==error,(op,lib.od_last_error(core));return
            assert rc==0,(op,lib.od_last_error(core))
            try:return json.loads(ctypes.string_at(out))
            finally:lib.od_free(out)
        call('profile.create',cmd='open');owned=call('card.add',{'master_id':source['id']},'add')['cards'][0]['instance_id']
        baseline=call('profile.snapshot');full=call('card.potential.preview',{'instance_id':owned})
        assert not full['can_commit'] and full['plan'] is None and full['sa_level']==1
        assert full['graph']['board_id']==source['potential_board_id'] and not full['graph']['activation_policy_verified']
        nodes=full['graph']['nodes'];assert len(nodes)==db.execute('SELECT count(*) FROM potential_squares WHERE potential_board_id=?',(source['potential_board_id'],)).fetchone()[0]
        node=next(n for n in nodes if n['choices']);request={'node_id':node['node_id'],'selected_event_id':node['choices'][0]['event_id']}
        result=call('card.potential.preview',{'instance_id':owned,'requests':[request],'released_node_ids':[]})
        plan=result['plan'];assert not plan['can_commit'] and not plan['materials_satisfied'] and plan['orb_balance_verified']
        assert plan['minimum_sa_level']==node['minimum_sa_level'] and plan['sa_satisfied']==(1>=node['minimum_sa_level'])
        expected={c['item_id']:c['quantity'] for c in node['orb_costs']}
        assert {c['item_id']:c['quantity'] for c in plan['orb_costs']}==expected
        assert all(c['available']==0 and c['shortfall']==c['quantity'] for c in plan['orb_costs'])
        assert result['released_state_is_hypothetical'] and 'potential_orb_inventory' not in result['missing_policy'] and result['orb_balance_verified']
        base={'instance_id':owned,'requests':[request]}
        call('card.potential.preview',dict(base,board_id=source['potential_board_id']),error='POTENTIAL_INVALID_ARGUMENT')
        call('card.potential.preview',dict(base,requests=[True]),error='POTENTIAL_INVALID_ARGUMENT')
        call('card.potential.preview',dict(base,requests=['invalid']),error='POTENTIAL_INVALID_ARGUMENT')
        call('card.potential.preview',dict(base,requests=[dict(request,node_id=True)]),error='POTENTIAL_INVALID_ARGUMENT')
        call('card.potential.preview',dict(base,requests=[dict(request,selected_event_id=0)]),error='POTENTIAL_SELECTION_REQUIRED')
        call('card.potential.preview',dict(base,requests=[request,request]),error='POTENTIAL_DUPLICATE_TARGET')
        foreign=db.execute('SELECT id FROM potential_squares WHERE potential_board_id!=? ORDER BY id LIMIT 1',(source['potential_board_id'],)).fetchone()[0]
        call('card.potential.preview',dict(base,requests=[dict(request,node_id=foreign)]),error='POTENTIAL_NODE_NOT_FOUND')
        call('card.potential.preview',dict(base,released_node_ids=[foreign]),error='POTENTIAL_STATE_INVALID')
        call('card.potential.preview',dict(base,released_node_ids=[node['node_id']]),error='POTENTIAL_ALREADY_RELEASED')
        call('card.potential.preview',dict(base,released_node_ids=[node['node_id'],node['node_id']]),error='POTENTIAL_INVALID_ARGUMENT')
        assert call('profile.snapshot')==baseline
        call('profile.create',cmd='other',profile='other');call('card.potential.preview',{'instance_id':owned},error='CARD_NOT_OWNED',profile='other')
        # Real effective authored settings select another existing master-backed board.
        alternate=db.execute('SELECT id FROM potential_boards WHERE id!=? ORDER BY id LIMIT 1',(source['potential_board_id'],)).fetchone()[0]
        card=dict(source);card['potential_board_id']=alternate
        definition={'format':'offline-dokkan-definition','schema_version':1,'definition_id':'potential-preview','version':1,'source':{'content_id':content,'master_id':source['id']},'rarity':'LR','fully_awakened':True,'creator':{'id':'tin','name':'Tin'},'card':card,'tables':{}}
        call('creator.import',{'definition':definition},'definition')
        call('inventory.grant',{'source':'test-fund','rewards':[{'kind':'stone','id':0,'quantity':1}]},'fund')
        banner={'banner_id':'preview','version':1,'epoch':1,'creator_epoch':1,'main_id':'potential-preview','policy':{'lr_ppm':1000000,'slr_ppm':0,'gr_ppm':0,'multi_count':2},'pool':[{'definition_id':'potential-preview','definition_version':1,'master_id':source['id'],'rarity':'LR','weight_ppm':1000000}]}
        call('banner.configure',banner,'banner');created=call('summon.draw',{'banner_id':'preview','kind':'single'},'draw')['summon']['draws'][0]['instance_id']
        before=call('profile.snapshot');effective=call('card.potential.preview',{'instance_id':created});assert effective['graph']['board_id']==alternate and effective['potential_locked']
        assert call('profile.snapshot')==before
        with sqlite3.connect(save) as state:
            assert state.execute("SELECT count(*) FROM commands WHERE operation='card.potential.preview'").fetchone()[0]==0
            assert state.execute('PRAGMA user_version').fetchone()[0]==12
        # New authoritative Orb vocabulary: real master IDs, 3x once, stable source and UUID.
        rewards=[{'kind':'potential','id':item,'quantity':(amount+2)//3} for item,amount in expected.items()]
        assert rewards and all(db.execute('SELECT 1 FROM potential_items WHERE id=?',(r['id'],)).fetchone() for r in rewards)
        grant={'source':'potential-reward','rewards':rewards}
        credited=call('inventory.grant',grant,'potential-grant')
        assert call('inventory.grant',grant,'potential-grant')==credited
        assert call('inventory.grant',dict(reversed(list(grant.items()))),'potential-source-retry')==credited
        balances={r['id']:r['quantity']*3 for r in rewards}
        assert {r['id']:r['quantity'] for r in credited['inventory'] if r['kind']=='potential'}==balances
        enough=call('card.potential.preview',base)['plan'];assert enough['materials_satisfied'] and not enough['can_commit']
        assert all(c['available']==balances[c['item_id']] and c['shortfall']==0 for c in enough['orb_costs'])
        unknown=db.execute('SELECT max(id)+1 FROM potential_items').fetchone()[0]
        invalid={'source':'invalid-orb','rewards':[rewards[0],{'kind':'potential','id':unknown,'quantity':1}]}
        call('inventory.grant',invalid,'invalid-orb',error='INVALID_REWARD')
        call('inventory.grant',{'source':'bool-orb','rewards':[dict(rewards[0],id=True)]},'bool-orb',error='INVALID_REWARD')
        call('inventory.grant',{'source':'overflow-orb','rewards':[dict(rewards[0],quantity=9007199254740991//3+1)]},'overflow-orb',error='INVALID_REWARD')
        call('inventory.grant',{'source':'potential-reward','rewards':[dict(rewards[0],quantity=999)]},'changed-source',error='REWARD_SOURCE_CONFLICT')
        call('run.start',{'run_id':'orb-client-route','map_id':1,'team_slot':0,'assets_ready':True,'rewards':rewards},'orb-client-route',error='POTENTIAL_TRUSTED_GRANT_REQUIRED')
        assert call('profile.snapshot')==credited
        exported=pathlib.Path(temp)/(filename+'.export');assert lib.od_export_save(core,str(exported).encode())==0
        assert lib.od_import_save(core,str(exported).encode())==0 and call('profile.snapshot')==credited
        bad=pathlib.Path(temp)/(filename+'.bad')
        with sqlite3.connect(exported) as src,sqlite3.connect(bad) as dst:
            src.backup(dst);dst.execute("UPDATE inventory SET item_id=? WHERE kind='potential' AND item_id=?",(unknown,rewards[0]['id']))
        assert lib.od_import_save(core,str(bad).encode())<0 and call('profile.snapshot')==credited
        lib.od_close(core)
        # Legacy migration preserves exact balances; new credits do not require a schema bump.
        legacy=pathlib.Path(temp)/(filename+'.v6')
        with sqlite3.connect(legacy) as state:
            state.executescript((ROOT/'fixtures/schema-v6.sql').read_text());state.execute("INSERT INTO meta VALUES('content',?)",(content,));state.execute("INSERT INTO profiles(id) VALUES('p')")
            state.execute("INSERT INTO inventory VALUES('p','potential',?,7)",(rewards[0]['id'],))
        digest=hashlib.sha256(legacy.read_bytes()).hexdigest();core=ctypes.c_void_p()
        assert lib.od_open(str(save).encode(),str(master).encode(),content.encode(),ctypes.byref(core))==0
        assert lib.od_import_save(core,str(legacy).encode())==0 and hashlib.sha256(legacy.read_bytes()).hexdigest()==digest
        migrated=call('profile.snapshot');assert migrated['inventory']==[{'kind':'potential','id':rewards[0]['id'],'quantity':7}]
        added=call('inventory.grant',{'source':'migrated-orb','rewards':[dict(rewards[0],quantity=1)]},'migrated-orb')
        assert added['inventory'][0]['quantity']==10
        lib.od_close(core);db.close()
print('PASS authoritative Orb master IDs/3x grants/source+UUID replay/atomic rejection/import/v6 migration; supplied Eclipse/Sparking owned/effective boards, source choices/costs/SA, strict foreign/type/duplicate guards, hypothetical-state labels and no save/revision/command mutation')
