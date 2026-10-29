#!/usr/bin/env python3
"""One real-master, read-only base training facts/EXP-range scenario."""
import bisect
import ctypes as C
import json
from pathlib import Path
import sqlite3

HERE=Path(__file__).resolve().parent
MASTER=HERE.parents[1]/'unit-creator/apk/assets/reference.db'
lib=C.CDLL(str(HERE/'build/libtraining-check.so'));sql=C.CDLL('libsqlite3.so.0')
sql.sqlite3_open_v2.argtypes=[C.c_char_p,C.POINTER(C.c_void_p),C.c_int,C.c_char_p]
sql.sqlite3_close.argtypes=[C.c_void_p];sql.sqlite3_free.argtypes=[C.c_void_p];sql.sqlite3_total_changes.argtypes=[C.c_void_p]
class Amount(C.Structure):_fields_=[('item_id',C.c_int64),('quantity',C.c_int64)]
lib.od_training_catalog.argtypes=[C.c_void_p,C.POINTER(C.c_void_p),C.POINTER(C.c_char_p)]
lib.od_training_preview.argtypes=[C.c_void_p,C.c_int64,C.c_char_p,C.c_int64,C.POINTER(C.c_int64),C.POINTER(Amount),C.c_size_t,C.POINTER(Amount),C.c_size_t,C.POINTER(C.c_int64),C.c_int64,C.POINTER(C.c_void_p),C.POINTER(C.c_char_p)]
def read_result(result):
    try:return json.loads(C.string_at(result).decode())
    finally:sql.sqlite3_free(result)
with sqlite3.connect(f'file:{MASTER}?mode=ro',uri=True) as source:
    card,cap,exp_type,element=source.execute('SELECT id,lv_max,exp_type,element FROM cards WHERE rarity=5 AND lv_max=150 AND exp_type=25 ORDER BY id LIMIT 1').fetchone()
    curve=[r[0] for r in source.execute('SELECT exp_total FROM card_exps WHERE exp_type=? AND lv<=? ORDER BY lv',(exp_type,cap))]
    matching=source.execute('SELECT id,exp,zeni_to_use FROM training_items WHERE element=? ORDER BY exp,id LIMIT 1',(element%10,)).fetchone()
    other=source.execute('SELECT id,exp,zeni_to_use FROM training_items WHERE element!=? ORDER BY exp,id LIMIT 1',(element%10,)).fetchone()
    field=source.execute('SELECT id FROM training_fields WHERE addend>0 ORDER BY id LIMIT 1').fetchone()[0]
    requests=(Amount*2)(Amount(matching[0],2),Amount(other[0],3));inventory=(Amount*2)(Amount(matching[0],2),Amount(other[0],3))
    expected_exp=matching[1]*2+other[1]*3;expected_cost=matching[2]*2+other[2]*3
    zeni=C.c_int64(expected_cost);known=C.c_int64(curve[9]);db=C.c_void_p()
    assert sql.sqlite3_open_v2(str(MASTER).encode(),C.byref(db),1,None)==0
    def preview(level=10,xp=known,document=None,want_error=None):
        result=C.c_void_p();error=C.c_char_p()
        rc=lib.od_training_preview(db,card,json.dumps(document).encode() if document else None,level,C.byref(xp) if xp is not None else None,requests,2,inventory,2,C.byref(zeni),field,C.byref(result),C.byref(error))
        if want_error:
            assert rc==-1 and error.value.decode()==want_error and not result.value,(rc,error.value)
            return
        assert rc==0,error.value
        return read_result(result)
    try:
        result=C.c_void_p();error=C.c_char_p();assert lib.od_training_catalog(db,C.byref(result),C.byref(error))==0,error.value
        catalog=read_result(result)
        assert len(catalog['items'])==source.execute('SELECT count(*) FROM training_items').fetchone()[0]
        assert len(catalog['fields'])==source.execute('SELECT count(*) FROM training_fields').fetchone()[0]
        metadata=next(f for f in catalog['fields'] if f['field_id']==field)
        assert metadata['raw_addend']==source.execute('SELECT addend FROM training_fields WHERE id=?',(field,)).fetchone()[0]
        facts=preview();projection=facts['base_experience_projection']
        assert facts['base_item_exp']==expected_exp and facts['item_zeni_subtotal']==expected_cost
        assert facts['items'][0]['matches_target_type'] and not facts['items'][1]['matches_target_type']
        assert facts['items_available'] and facts['item_zeni_subtotal_affordable']
        assert facts['final_exp'] is None and facts['final_zeni_cost'] is None and not facts['can_commit'] and facts['costs_are_unmultiplied']
        assert projection['experience_lower']==projection['experience_upper']==known.value+expected_exp
        assert projection['level_lower']==projection['level_upper']==bisect.bisect_right(curve,known.value+expected_exp)
        ranged=preview(xp=None)['base_experience_projection']
        assert not ranged['owned_experience_known'] and ranged['experience_lower']==curve[9]+expected_exp and ranged['experience_upper']==curve[10]-1+expected_exp
        inventory[0].quantity-=1
        assert not preview()['items_available'] and preview()['items'][0]['shortfall']==1
        over=preview(level=cap,xp=C.c_int64(curve[-1]))['base_experience_projection']
        assert over['lower_exceeds_cap'] and over['level_lower'] is None and not over['cap_discard_policy_applied']
        unsupported=preview(level=1,xp=C.c_int64(0),document={'card':{'lv_max':200,'exp_type':925}})
        assert not unsupported['base_experience_projection']['available']
        preview(xp=C.c_int64(curve[9]-1),want_error='TRAINING_EXPERIENCE_MISMATCH')
        preview(document={'card':{'lv_max':True}},want_error='TRAINING_TARGET_UNAVAILABLE')
        saved=requests[0].quantity;requests[0].quantity=9007199254740991
        preview(want_error='TRAINING_AMOUNT_OVERFLOW');requests[0].quantity=saved
        saved=requests[1].item_id;requests[1].item_id=requests[0].item_id
        preview(want_error='TRAINING_DUPLICATE_ITEM');requests[1].item_id=saved
        assert sql.sqlite3_total_changes(db)==0
    finally:sql.sqlite3_close(db)
print('Training focused real-master check passed: catalogs, exact baseEXP/itemZeni, no invented bonuses, ownedEXP range/cap facts, deficits, missingcurve/type/overflow/duplicate guards, zero writes.')
