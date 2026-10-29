#ifndef OD_PRACTICE_H
#define OD_PRACTICE_H
#include <stddef.h>
#include <sqlite3.h>
#ifdef __cplusplus
extern "C" {
#endif
typedef void (*od_practice_digest)(const void *,size_t,char [65]);
/* Separate own offline ledger, not normal quests, rewards or tutorial progress.
 * Only the canonical Core's native authority may invoke these transaction APIs. */
const char *od_practice_schema_sql(void);
int od_practice_snapshot(sqlite3 *db,const char *profile,char **json,char **error);
int od_practice_validate(sqlite3 *db,sqlite3 *master,od_practice_digest digest);
/* operation is practice.begin or practice.finish. Payload pins a native-issued
 * session_id, phase_number3 and the exact original master parameters SHA.
 * Caller owns scope/revision/command replay, commit and revision advancement.
 * Returns0 mutation /1 already observed /-1 failure; strings use sqlite3_free. */
int od_practice_apply(sqlite3 *db,sqlite3 *master,const char *profile,
    sqlite3_int64 revision,const char *operation,const char *payload,
    od_practice_digest digest,char **json,char **error);
#ifdef __cplusplus
}
#endif
#endif
