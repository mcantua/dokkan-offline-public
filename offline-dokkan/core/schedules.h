#ifndef OD_SCHEDULES_H
#define OD_SCHEDULES_H

#include <stddef.h>
#include <stdint.h>
#include "progression.h"

#ifdef __cplusplus
extern "C" {
#endif

/* Internal calendar policy, NOT evidence of the game's event timezone or wire clock.
 * Chicago uses US rules effective since 2007; persist this policy/version with the save.
 * Resolve a future law change by a new explicit policy, never reinterpret existing periods. */
typedef enum { OD_ZONE_UTC, OD_ZONE_AMERICA_CHICAGO_2007 } od_schedule_zone;
typedef enum {
    OD_SCHEDULE_OK, OD_SCHEDULE_INVALID_ARGUMENT, OD_SCHEDULE_OUT_OF_RANGE,
    OD_SCHEDULE_NOT_ENOUGH_HISTORY, OD_SCHEDULE_RANDOM_FAILED,
    OD_SCHEDULE_POLICY_MISMATCH, OD_SCHEDULE_NOT_ACTIVE,
    OD_SCHEDULE_ALREADY_SETTLED, OD_SCHEDULE_NO_REWARD, OD_SCHEDULE_OVERFLOW,
    OD_SCHEDULE_INSUFFICIENT_STONES
} od_schedule_status;

typedef struct { int year, month, day, hour, minute, second, weekday; } od_civil_time;
typedef enum { OD_FOLD_EARLIER, OD_FOLD_LATER } od_schedule_fold;
od_schedule_status od_schedule_local_time(int64_t utc_seconds, od_schedule_zone zone, od_civil_time *out);
/* Spring's missing 2:xx AM shifts forward one hour; November's repeated 1:xx AM uses fold.
 * weekday is derived, not trusted on input. POSIX seconds; no leap-second encoding invented. */
od_schedule_status od_schedule_utc_time(const od_civil_time *local, od_schedule_zone zone,
                                      od_schedule_fold fold, int64_t *out);
/* Exact calendar subtraction: same local wall time 9 months ago, day clamped to month's last day.
 * Lower endpoint is inclusive; upper is the supplied trusted UTC instant. */
od_schedule_status od_schedule_nine_month_bounds(int64_t now_utc, od_schedule_zone zone,
                                                int64_t *lower_utc, int64_t *upper_utc);

typedef struct {
    uint32_t week_id;       /* Monday's local YYYYMMDD */
    int64_t week_start_utc, week_end_utc;
    uint32_t weekend_id;    /* Saturday's local YYYYMMDD */
    int64_t weekend_start_utc, weekend_end_utc;
    int weekend_active;
} od_schedule_period;
/* Own policy: Monday12:00AM weekly rotation; Saturday12:00AM–Monday12:00AM weekend.
 * Boundaries are local civil times, so DST weekends are 47/49 hours, not always 48. */
od_schedule_status od_schedule_current_period(int64_t now_utc, od_schedule_zone zone, od_schedule_period *out);

typedef struct {
    const char *banner_id;
    int64_t first_open_utc;
    int verified_official_history;
    int usable_local_content;
} od_historical_banner;
typedef struct {
    uint32_t week_id;
    int64_t selected_at_utc;
    char catalog_version[OD_DEFINITION_ID_MAX + 1];
    char banner_ids[2][OD_DEFINITION_ID_MAX + 1];
} od_weekly_rotation;

/* Choose 2 DISTINCT eligible historical official banners, uniformly without replacement.
 * Nine-month bounds apply at the persisted selection instant. Keep the choices until the next
 * Monday; do not reroll on launch. Replay in the same week needs the pinned catalog and no RNG.
 * Rates/lineups/exclusivity must already be verified in caller's catalog; this invents none. */
od_schedule_status od_schedule_rotate(const od_historical_banner *history, size_t count,
    const char *catalog_version, int64_t now_utc, od_schedule_zone zone,
    const od_weekly_rotation *prior, od_summon_random random_bytes, void *random_context,
    od_weekly_rotation *out);

typedef struct {
    const char *definition_id;
    int verified_elder_kai; /* resolved from trusted imported definitions, never guessed from a name */
    unsigned super_attack_levels;
    uint32_t weight_ppm;
} od_elder_kai_entry;
typedef struct { unsigned count; size_t pool_indexes[OD_SUMMON_MAX_MULTI]; uint64_t stone_cost; } od_elder_kai_plan;
/* Weekend-only, each permitted definition raises SA by exactly 1. Uses explicit pool weights
 * and explicit multi size, with 5/50 prices and no invented pity/extra slot guarantees.
 * Core debits and grants the resulting material-card instances atomically. */
od_schedule_status od_elder_kai_draw(const od_schedule_period *period, int64_t now_utc,
    const od_elder_kai_entry *pool, size_t count, unsigned multi_count,
    od_summon_kind kind, uint64_t stones, od_summon_random random_bytes, void *random_context,
    od_elder_kai_plan *out);

typedef struct {
    const char *competitor_id;
    uint32_t points_per_hour;
    uint32_t extra_points_per_hour_max;
} od_tournament_competitor;
typedef struct {
    uint32_t weekend_id;
    uint64_t policy_version, seed, competitor_hash;
    int64_t last_update_utc, points;
} od_tournament_state;

/* Deterministic simulated competitors: pin seed/config/version per weekend, persist out.
 * Supplied pace is explicit game design, not a claimed official ranking algorithm.
 * New state is all zeroes. Replayed/backward clocks never grant additional progress;
 * catch-up computes elapsed weekend hours, never activity after its local Monday end. */
od_schedule_status od_tournament_advance(const od_schedule_period *period, uint64_t policy_version,
    uint64_t seed, const od_tournament_competitor *competitor, int64_t now_utc,
    const od_tournament_state *prior, od_tournament_state *out);

typedef enum { OD_TIES_SHARE_RANK, OD_TIES_PLAYER_AFTER_EQUALS } od_rank_tie_policy;
od_schedule_status od_tournament_rank(int64_t player_points, const int64_t *other_points,
    size_t count, od_rank_tie_policy tie_policy, uint32_t *out);

#define OD_TOURNAMENT_MAX_REWARDS 64u
typedef struct { const char *resource_id; od_reward_category category; int64_t base_quantity; } od_rank_reward;
typedef struct { uint32_t rank_from, rank_to; const od_rank_reward *rewards; size_t reward_count; } od_rank_reward_tier;
typedef struct { char resource_id[OD_DEFINITION_ID_MAX + 1]; od_reward_category category; int64_t quantity; } od_planned_rank_reward;
typedef struct {
    uint32_t weekend_id, final_rank;
    size_t reward_count;
    od_planned_rank_reward rewards[OD_TOURNAMENT_MAX_REWARDS];
} od_tournament_reward_plan;

/* Rewards require the weekend to have ended. Actual reward contents/ties are caller-configured.
 * Apply category multipliers exactly once here, then core atomically claims (profile,weekend_id)
 * and grants the returned amounts. Do not run progression_amount(REWARD) on these again.
 * already_settled prevents obvious replay; the core's unique transactional ledger is authoritative. */
od_schedule_status od_tournament_rewards(const od_schedule_period *period, int64_t now_utc,
    uint32_t final_rank, const od_rank_reward_tier *tiers, size_t tier_count,
    int already_settled, od_tournament_reward_plan *out);

const char *od_schedule_status_name(od_schedule_status status);

#ifdef __cplusplus
}
#endif
#endif
