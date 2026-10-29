#ifndef OD_KAI_TRAINING_H
#define OD_KAI_TRAINING_H
#include "sqlite3.h"
#ifdef __cplusplus
extern "C" {
#endif
/* Runtime: historical_binding=NULL resolves the actual current owned definition and returns
 * immutable source/version metadata. Import: verify that historical binding against retained
 * definition versions and the same owned source. Returned JSON uses sqlite3_malloc. */
typedef int (*od_kai_target_binding_fn)(void *context, sqlite3 *save, const char *profile,
    sqlite3_int64 instance_id, const char *historical_binding, char **binding_json,
    sqlite3_int64 *super_attack_cap);
const char *od_kai_training_schema(void);
/* Caller owns BEGIN IMMEDIATE/command replay/revision/COMMIT. This is guaranteed +1 Kai
 * feeding only. It does not guess general training, EXP, Zeni, chance or field bonuses. */
int od_kai_training_apply(sqlite3 *save, const char *profile, const char *command_id,
    const char *args_json, od_kai_target_binding_fn resolve, void *context,
    char **receipt_json, const char **error);
int od_kai_training_validate(sqlite3 *save, od_kai_target_binding_fn resolve, void *context);
#ifdef __cplusplus
}
#endif
#endif
