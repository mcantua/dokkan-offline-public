#ifndef OD_SUMMONS_H
#define OD_SUMMONS_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define OD_SUMMON_WEIGHT_TOTAL 1000000u
#define OD_SUMMON_MAX_MULTI 100u
#define OD_SUMMON_MAX_POOL 65536u
#define OD_FEATURED_SLOTS 5u
#define OD_DEFINITION_ID_MAX 127u

typedef enum {
    OD_SUMMON_OK = 0,
    OD_SUMMON_INVALID_ARGUMENT,
    OD_SUMMON_INVALID_POOL,
    OD_SUMMON_INVALID_POLICY,
    OD_SUMMON_INSUFFICIENT_STONES,
    OD_SUMMON_RANDOM_FAILED,
    OD_SUMMON_INVALID_PITY,
    OD_SUMMON_POLICY_REQUIRED,
    OD_SUMMON_NO_MEMORY
} od_summon_status;

/* Internal rarities, NOT claimed to be the game's wire/database enum values. */
typedef enum {
    OD_RARITY_N, OD_RARITY_R, OD_RARITY_SR, OD_RARITY_SSR,
    OD_RARITY_UR, OD_RARITY_LR, OD_RARITY_SLR, OD_RARITY_GR
} od_summon_rarity;

typedef struct {
    const char *definition_id; /* stable identity, not a character's display name */
    od_summon_rarity rarity;
    uint32_t weight_ppm;       /* exact per-definition chance, supplied explicitly */
} od_summon_entry;

typedef struct {
    uint32_t lr_ppm, slr_ppm, gr_ppm;
    unsigned multi_count; /* explicit configuration; no slot count/SSR guarantee invented here */
} od_summon_policy;

/* Starting rates are LR 1%, SLR 0.1%, GR 0.01%. Caller MUST supply a multi count. */
od_summon_policy od_summon_starting_policy(unsigned multi_count);

typedef struct { uint64_t epoch; uint32_t misses; } od_pity_state;
typedef enum { OD_SUMMON_SINGLE = 1, OD_SUMMON_MULTI = 2 } od_summon_kind;

/* Return 1 after filling all requested bytes with secure random data, 0 on failure.
 * Production supplies OS randomness; deterministic callbacks belong only in tests. */
typedef int (*od_summon_random)(void *context, void *bytes, size_t length);

typedef struct {
    unsigned count;
    size_t pool_indexes[OD_SUMMON_MAX_MULTI];
    uint64_t stone_cost;
    od_pity_state next_pity;
    int main_feature_pulled;
    int guaranteed; /* a natural pull never creates an additional guaranteed copy */
} od_summon_plan;

od_summon_status od_summon_validate_pool(const od_summon_entry *pool, size_t count,
                                       const od_summon_policy *policy);
unsigned od_summon_pity_limit(od_summon_rarity rarity);

/* Pure transaction planning: no database changes/debits. On failure, *out is unchanged.
 * Persist the resolved indexes as actual definition IDs, debit and next_pity in one transaction;
 * retries must return that stored outcome, never call this function again for the same command.
 * Pool indexes are valid only against the exact caller-pinned pool/version used by this call. */
od_summon_status od_summon_make_plan(const od_summon_entry *pool, size_t pool_count,
    const od_summon_policy *policy, const char *main_definition_id, uint64_t main_epoch,
    od_pity_state prior_pity, od_summon_kind kind, uint64_t available_stones,
    od_summon_random random_bytes, void *random_context, od_summon_plan *out);

typedef struct {
    char definition_id[OD_DEFINITION_ID_MAX + 1];
    uint64_t revision;
} od_featured_entry;

typedef struct {
    unsigned count;
    uint64_t epoch;
    od_featured_entry entries[OD_FEATURED_SLOTS]; /* newest/main first */
} od_featured_list;

typedef enum {
    OD_REVISION_POLICY_UNDECIDED = 0,
    /* An explicitly chosen policy for new revisions of existing featured definitions.
     * Updates retain feature order and pity. Same/older revisions are no-ops either way. */
    OD_REVISION_KEEP_FEATURE_POSITION_AND_PITY = 1
} od_feature_revision_policy;

typedef enum { OD_FEATURE_UNCHANGED, OD_FEATURE_UPDATED, OD_FEATURE_NEW_MAIN } od_feature_change;

typedef struct {
    od_featured_list featured;
    od_feature_change change;
    char evicted_id[OD_DEFINITION_ID_MAX + 1];
} od_featured_plan;

/* New identity: newest/main, epoch increments, oldest of 5 leaves only the featured list.
 * Caller MUST retain an evicted definition in the ordinary pool. Identical/stale imports do not
 * move features or reset pity. Higher revision needs an explicit policy (never guessed).
 * Update owned instances separately without discarding their player progression. */
od_summon_status od_featured_upsert(const od_featured_list *old, const char *definition_id,
    uint64_t revision, od_feature_revision_policy revision_policy, od_featured_plan *out);

const char *od_summon_status_name(od_summon_status status);

#ifdef __cplusplus
}
#endif
#endif
