#!/usr/bin/env python3
"""One focused deterministic stat-policy fixture; synthetic data, no game files."""
import ctypes
import json
from pathlib import Path
import sqlite3
import tempfile

HERE = Path(__file__).resolve().parent
library = ctypes.CDLL(str(HERE / 'build/libcardstats-check.so'))
sql = ctypes.CDLL('libsqlite3.so.0')
sql.sqlite3_open_v2.argtypes = [ctypes.c_char_p, ctypes.POINTER(ctypes.c_void_p), ctypes.c_int, ctypes.c_char_p]
sql.sqlite3_close.argtypes = [ctypes.c_void_p]
sql.sqlite3_free.argtypes = [ctypes.c_void_p]
library.od_card_stats.argtypes = [ctypes.c_void_p, ctypes.c_int64, ctypes.c_char_p, ctypes.c_int64, ctypes.c_char_p, ctypes.POINTER(ctypes.c_void_p), ctypes.POINTER(ctypes.c_char_p)]
library.od_stats_muldiv.argtypes = [ctypes.c_int64, ctypes.c_int64, ctypes.c_int64, ctypes.POINTER(ctypes.c_int64)]


def evaluate(db, level, document=None, error=None):
    result = ctypes.c_void_p()
    message = ctypes.c_char_p()
    rc = library.od_card_stats(db, 1, json.dumps(document).encode() if document else None, level,
                               b'master-coefficient-linear-floor-v1', ctypes.byref(result), ctypes.byref(message))
    if error:
        assert rc == -1 and message.value.decode() == error, (rc, message.value)
        assert not result.value
        return
    assert rc == 0, message.value
    try:
        return json.loads(ctypes.string_at(result).decode())
    finally:
        sql.sqlite3_free(result)


with tempfile.TemporaryDirectory() as directory:
    path = Path(directory) / 'fixture.db'
    with sqlite3.connect(path) as db:
        db.executescript('''CREATE TABLE cards(id INTEGER,hp_init INTEGER,hp_max INTEGER,atk_init INTEGER,atk_max INTEGER,def_init INTEGER,def_max INTEGER,lv_max INTEGER,grow_type INTEGER,rarity INTEGER);
        INSERT INTO cards VALUES(1,100,1100,200,2200,300,3300,3,1,5);
        CREATE TABLE card_growths(grow_type INTEGER,lv INTEGER,coef REAL);
        INSERT INTO card_growths VALUES(1,1,0),(1,2,0.25),(1,3,1);''')
    handle = ctypes.c_void_p()
    assert sql.sqlite3_open_v2(str(path).encode(), ctypes.byref(handle), 1, None) == 0
    try:
        assert evaluate(handle, 1)['hp'] == 100
        assert evaluate(handle, 2)['hp'] == 350
        assert evaluate(handle, 3)['hp'] == 1100
        for tier, cap, mid, boost in [('SLR', 180, 90, 10), ('GR', 200, 100, 20)]:
            document = {'card': {'lv_max': cap}, 'rarity': tier, 'stat_policy': 'creator-cap-normalized-v1'}
            assert evaluate(handle, 1, document)['hp'] == 100
            middle = evaluate(handle, mid, document)
            assert middle['hp'] == 348 and middle['atk'] == 697 and middle['def'] == (1045 if tier == 'SLR' else 1046)
            assert middle['final_exclusive']['atk_percent'] == boost
            assert middle['final_exclusive']['included_in_base'] is False
            assert middle['internal_policy'] is True and middle['original_game_rounding_verified'] is False
            assert evaluate(handle, cap, document)['hp'] == 1100
        evaluate(handle, 180, {'card': {'lv_max': 180}, 'rarity': 'SLR'}, 'STATS_CURVE_UNAVAILABLE')
        evaluate(handle, 4, error='STATS_LEVEL_OUT_OF_RANGE')
        evaluate(handle, 1, {'card': {'hp_max': 2**31}}, 'STATS_CARD_UNAVAILABLE')
    finally:
        sql.sqlite3_close(handle)
    with sqlite3.connect(path) as db:
        db.execute('UPDATE card_growths SET coef=0.2501 WHERE lv=2')
    assert sql.sqlite3_open_v2(str(path).encode(), ctypes.byref(handle), 1, None) == 0
    try:
        evaluate(handle, 2, error='STATS_CURVE_UNAVAILABLE')
    finally:
        sql.sqlite3_close(handle)

safe = 9007199254740991
result = ctypes.c_int64()
assert library.od_stats_muldiv(safe, safe, safe, ctypes.byref(result)) == 0 and result.value == safe
assert library.od_stats_muldiv(safe, safe, 1, ctypes.byref(result)) == -1
assert library.od_stats_muldiv(-1, 1, 1, ctypes.byref(result)) == -1
print('Stat policy focused check passed: boundaries, curved midpoints,180/200, explicit policy, bonus isolation, bad curves and overflow.')
