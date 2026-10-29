#ifndef OD_CARD_STATS_H
#define OD_CARD_STATS_H
#include <stdint.h>
#include "sqlite3.h"
#ifdef __cplusplus
extern "C" {
#endif
/* Own internal stat policies, not a verified original-game rounding implementation.
 * The trusted caller supplies persisted owned level and effective settings; clients select neither.
 * Creator-normalized policy MUST be pinned in immutable definition.stat_policy. Explicit fallback
 * may select master-coefficient-linear-floor-v1 only; missing coefficients never extrapolate.
 * Base stats exclude every leader/passive/potential/equipment/exclusive bonus. The returned
 * final_exclusive descriptor is applied once AFTER other combat boosts by a future battle evaluator.
 * Returned JSON uses sqlite3_malloc; errors are static strings. No save mutation or schema change. */
int od_card_stats(sqlite3 *master, int64_t master_id, const char *effective_document,
    int64_t level, const char *explicit_policy, char **result, const char **error);
/* Exact overflow-checked floor(a*b/divisor), with a,b/divisor bounded by JSON-safe integers.
 * Exposed for deterministic battle-stat composition; no floating point rounding. */
int od_stats_muldiv(int64_t a, int64_t b, int64_t divisor, int64_t *out);
#ifdef __cplusplus
}
#endif
#endif
