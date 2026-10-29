#!/usr/bin/env python3
"""One read-only real-master board/conditions/selection/orb-budget scenario."""
import ctypes as C
import json
from pathlib import Path
import sqlite3

HERE = Path(__file__).resolve().parent
MASTER = HERE.parents[1] / 'unit-creator/apk/assets/reference.db'
lib = C.CDLL(str(HERE / 'build/libpotential-check.so'))
sql = C.CDLL('libsqlite3.so.0')
sql.sqlite3_open_v2.argtypes = [C.c_char_p, C.POINTER(C.c_void_p), C.c_int, C.c_char_p]
sql.sqlite3_close.argtypes = [C.c_void_p]
sql.sqlite3_free.argtypes = [C.c_void_p]
sql.sqlite3_total_changes.argtypes = [C.c_void_p]
lib.od_potential_load.argtypes = [C.c_void_p, C.c_int64, C.c_char_p, C.POINTER(C.c_void_p), C.POINTER(C.c_char_p)]
lib.od_potential_free.argtypes = [C.c_void_p]
lib.od_potential_view.argtypes = [C.c_void_p, C.POINTER(C.c_void_p), C.POINTER(C.c_char_p)]
class Event(C.Structure):
    _fields_ = [('id',C.c_int64),('resource_id',C.c_int64),('amount',C.c_int64),('kind',C.c_int)]
class Request(C.Structure):
    _fields_ = [('node_id',C.c_int64),('selected_event_id',C.c_int64)]
class Orbs(C.Structure):
    _fields_ = [('item_id',C.c_int64),('quantity',C.c_int64)]
class Cost(C.Structure):
    _fields_ = [('item_id',C.c_int64),('quantity',C.c_int64),('available',C.c_int64),('shortfall',C.c_int64)]
class Effect(C.Structure):
    _fields_ = [('node_id',C.c_int64),('event',Event)]
class Plan(C.Structure):
    _fields_ = [('master_id',C.c_int64),('board_id',C.c_int64),('minimum_sa',C.c_int64),('sa_satisfied',C.c_int),('materials_satisfied',C.c_int),('has_locked_nodes',C.c_int),('cost_count',C.c_size_t),('costs',Cost*256),('effect_count',C.c_size_t),('effects',Effect*512)]
lib.od_potential_cost_plan.argtypes = [C.c_void_p,C.POINTER(C.c_int64),C.c_size_t,C.POINTER(Request),C.c_size_t,C.c_int64,C.POINTER(Orbs),C.c_size_t,C.POINTER(Plan),C.POINTER(C.c_char_p)]
lib.od_potential_plan_view.argtypes = [C.POINTER(Plan),C.POINTER(C.c_void_p),C.POINTER(C.c_char_p)]

def view(function, value):
    result=C.c_void_p();error=C.c_char_p()
    assert function(value,C.byref(result),C.byref(error)) == 0, error.value
    try:return json.loads(C.string_at(result).decode())
    finally:sql.sqlite3_free(result)

with sqlite3.connect(f'file:{MASTER}?mode=ro',uri=True) as source:
    card,board_id=source.execute('SELECT c.id,c.potential_board_id FROM cards c JOIN potential_boards b ON b.id=c.potential_board_id ORDER BY b.id,c.id LIMIT 1').fetchone()
    db=C.c_void_p();board=C.c_void_p();error=C.c_char_p()
    assert sql.sqlite3_open_v2(str(MASTER).encode(),C.byref(db),1,None)==0
    try:
        assert lib.od_potential_load(db,card,None,C.byref(board),C.byref(error))==0,error.value
        metadata=view(lib.od_potential_view,board)
        nodes=metadata['nodes'];assert len(nodes)==source.execute('SELECT count(*) FROM potential_squares WHERE potential_board_id=?',(board_id,)).fetchone()[0]
        graph={node['node_id']:node['linked_nodes'] for node in nodes}
        assert any(a in graph.get(b,[]) for a,neighbors in graph.items() for b in neighbors), 'source reciprocal graph lost'
        assert metadata['links_are_source_adjacency'] and not metadata['activation_policy_verified']
        for node in nodes:
            links=[r[0] for r in source.execute('SELECT prev_potential_square_id FROM potential_square_relations WHERE potential_square_id=? ORDER BY id',(node['node_id'],))]
            assert node['has_start_link']==(None in links) and node['linked_nodes']==[x for x in links if x is not None]
        chosen=[]
        for predicate in [lambda n:n['has_start_link'],lambda n:n['locked'],lambda n:n['minimum_sa_level']>1,lambda n:n['choices']]:
            candidate=next(n for n in nodes if predicate(n) and n not in chosen);chosen.append(candidate)
        ids=[n['node_id'] for n in chosen]
        placeholders=','.join('?' for _ in ids)
        costs=dict(source.execute(f"SELECT json_extract(c.conditions,'$.item_id'),sum(json_extract(c.conditions,'$.quantity')) FROM potential_squares s JOIN potential_square_condition_set_relations r ON r.condition_set_id=s.condition_set_id JOIN potential_square_conditions c ON c.id=r.condition_id WHERE s.id IN({placeholders}) AND c.type='PotentialSquareCondition::PotentialItem' GROUP BY 1",ids))
        requests=(Request*len(chosen))(*[Request(n['node_id'],n['choices'][0]['event_id'] if n['choices'] else 0) for n in chosen])
        items=(Orbs*len(costs))(*[Orbs(item,quantity) for item,quantity in sorted(costs.items())]);plan=Plan()
        assert lib.od_potential_cost_plan(board,None,0,requests,len(requests),1,items,len(items),C.byref(plan),C.byref(error))==0,error.value
        preview=view(lib.od_potential_plan_view,C.byref(plan))
        assert {r['item_id']:r['quantity'] for r in preview['orb_costs']}==costs, 'costs changed or multiplied'
        assert not preview['sa_satisfied'] and preview['materials_satisfied'] and not preview['can_commit'] and preview['has_locked_route_nodes']
        items[0].quantity-=1
        assert lib.od_potential_cost_plan(board,None,0,requests,len(requests),plan.minimum_sa,items,len(items),C.byref(plan),C.byref(error))==0
        assert plan.sa_satisfied and not plan.materials_satisfied and sum(plan.costs[i].shortfall for i in range(plan.cost_count))==1
        selected=next(i for i,n in enumerate(chosen) if n['choices']);saved=requests[selected].selected_event_id;requests[selected].selected_event_id=0
        plan.board_id=-999
        assert lib.od_potential_cost_plan(board,None,0,requests,len(requests),10,items,len(items),C.byref(plan),C.byref(error))==-1 and error.value==b'POTENTIAL_SELECTION_REQUIRED' and plan.board_id==-999
        requests[selected].selected_event_id=saved
        released=(C.c_int64*1)(requests[0].node_id)
        assert lib.od_potential_cost_plan(board,released,1,requests,len(requests),10,items,len(items),C.byref(plan),C.byref(error))==-1 and error.value==b'POTENTIAL_ALREADY_RELEASED'
        copy=requests[1].node_id;requests[1].node_id=requests[0].node_id
        assert lib.od_potential_cost_plan(board,None,0,requests,len(requests),10,items,len(items),C.byref(plan),C.byref(error))==-1 and error.value==b'POTENTIAL_DUPLICATE_TARGET'
        requests[1].node_id=copy
        other=C.c_void_p()
        assert lib.od_potential_load(db,card,b'{"card":{"potential_board_id":true}}',C.byref(other),C.byref(error))==-1 and error.value==b'POTENTIAL_DEFINITION_INVALID'
        assert lib.od_potential_load(db,9007199254740991,json.dumps({'card':{'potential_board_id':board_id}}).encode(),C.byref(other),C.byref(error))==-1 and error.value==b'POTENTIAL_CARD_NOT_FOUND'
        assert sql.sqlite3_total_changes(db)==0
    finally:
        lib.od_potential_free(board);sql.sqlite3_close(db)
print('Potential focused real-master check passed: source cyclic graph, exact raw orb costs/SA/choices, shortfall, replay/duplicate guards, invalid identity/types, no mutation or unlock authorization.')
