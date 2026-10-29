#ifndef OD_JSON_VALUES_H
#define OD_JSON_VALUES_H
#include "sqlite3.h"
/* Same JSON meaning independent of object key order/number spelling. Array order and
 * boolean/string/null distinctions remain exact. Ambiguous duplicate paths are rejected.
 * Return 1 equal, 0 unequal/invalid, -1 on database failure. No mutation or external I/O. */
int od_json_semantic_equal(sqlite3 *database,const char *a,const char *b);
/* Register deterministic od_json_equal(a,b) on an open save/import connection. */
int od_register_json_equal(sqlite3 *database);
#endif
