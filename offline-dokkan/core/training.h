#ifndef OD_TRAINING_H
#define OD_TRAINING_H
#include <stddef.h>
#include <stdint.h>
#include "sqlite3.h"
#ifdef __cplusplus
extern "C" {
#endif
#define OD_TRAINING_MAX_ITEMS 512
#define OD_TRAINING_MAX_REQUESTS 128
#define OD_TRAINING_MAX_LEVELS 10000

typedef struct {int64_t item_id,quantity;} od_training_amount;
/* Verified source catalog only; field/success metadata are not an inferred training formula. */
int od_training_catalog(sqlite3 *master,char **result,const char **error);
/* Read-only base-item facts. Trusted core must resolve same-profile owned master/definition,
 * actual level/EXP, inventory and Zeni. Clients may not choose these or claim EXP/cost results.
 * known_experience / known_zeni NULL means unknown, not0. field_id0 selects no location.
 * Every result can_commit:false, final EXP/cost unavailable; raw item costs are never multiplied.
 * Complete master curves project only the stated base item gain. Unknown partialEXP gives a range;
 * unsupported/missing extended curves remain unavailable. No cap-discard rule is invented. */
int od_training_preview(sqlite3 *master,int64_t master_id,const char *effective_document,
    int64_t owned_level,const int64_t *known_experience,
    const od_training_amount *requests,size_t request_count,
    const od_training_amount *inventory,size_t inventory_count,
    const int64_t *known_zeni,int64_t field_id,char **result,const char **error);
/* Reusable exact-curve projection for a trusted caller's already resolved immutable curve
 * (including an explicitly authorized Creator extension). No EXP is granted. */
int od_training_project_exp(const int64_t *thresholds,size_t count,int64_t owned_level,
    const int64_t *known_experience,int64_t base_gain,char **result,const char **error);
/* Returns0 success,-1 error; result uses sqlite3_malloc/free; errors static. No schema/save writes. */
#ifdef __cplusplus
}
#endif
#endif
