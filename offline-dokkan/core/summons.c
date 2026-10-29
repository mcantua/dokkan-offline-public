#include "summons.h"

#include <stdlib.h>
#include <string.h>

static int valid_id(const char *id) {
    size_t n;
    if (!id || !id[0]) return 0;
    for (n = 0; n <= OD_DEFINITION_ID_MAX; n++) {
        unsigned char c = (unsigned char)id[n];
        if (!c) return n > 0;
        if (c <= 32 || c > 126) return 0;
    }
    return 0;
}

static uint64_t id_hash(const char *id) {
    uint64_t value = UINT64_C(14695981039346656037);
    while (*id) { value ^= (unsigned char)*id++; value *= UINT64_C(1099511628211); }
    return value;
}

od_summon_policy od_summon_starting_policy(unsigned multi_count) {
    od_summon_policy p = {10000u, 1000u, 100u, multi_count};
    return p;
}

unsigned od_summon_pity_limit(od_summon_rarity rarity) {
    switch (rarity) {
        case OD_RARITY_UR: return 5;
        case OD_RARITY_LR: return 10;
        case OD_RARITY_SLR: return 25;
        case OD_RARITY_GR: return 50;
        default: return 0;
    }
}

od_summon_status od_summon_validate_pool(const od_summon_entry *pool, size_t count,
                                       const od_summon_policy *policy) {
    uint64_t total = 0, lr = 0, slr = 0, gr = 0;
    size_t slots = 1, i, *seen;
    if (!pool || !policy || !count || count > OD_SUMMON_MAX_POOL)
        return OD_SUMMON_INVALID_ARGUMENT;
    if (policy->multi_count < 2 || policy->multi_count > OD_SUMMON_MAX_MULTI ||
        (uint64_t)policy->lr_ppm + policy->slr_ppm + policy->gr_ppm > OD_SUMMON_WEIGHT_TOTAL)
        return OD_SUMMON_INVALID_POLICY;
    while (slots < count * 2) slots *= 2;
    seen = (size_t *)calloc(slots, sizeof(*seen));
    if (!seen) return OD_SUMMON_NO_MEMORY;
    for (i = 0; i < count; i++) {
        size_t slot;
        const od_summon_entry *entry = &pool[i];
        if (!valid_id(entry->definition_id) || !entry->weight_ppm ||
            entry->weight_ppm > OD_SUMMON_WEIGHT_TOTAL ||
            (unsigned)entry->rarity > OD_RARITY_GR) {
            free(seen); return OD_SUMMON_INVALID_POOL;
        }
        slot = (size_t)id_hash(entry->definition_id) & (slots - 1);
        while (seen[slot]) {
            if (!strcmp(pool[seen[slot] - 1].definition_id, entry->definition_id)) {
                free(seen); return OD_SUMMON_INVALID_POOL;
            }
            slot = (slot + 1) & (slots - 1);
        }
        seen[slot] = i + 1;
        total += entry->weight_ppm;
        if (total > OD_SUMMON_WEIGHT_TOTAL) { free(seen); return OD_SUMMON_INVALID_POOL; }
        switch (entry->rarity) {
            case OD_RARITY_LR: lr += entry->weight_ppm; break;
            case OD_RARITY_SLR: slr += entry->weight_ppm; break;
            case OD_RARITY_GR: gr += entry->weight_ppm; break;
            default: break;
        }
    }
    free(seen);
    if (total != OD_SUMMON_WEIGHT_TOTAL || lr != policy->lr_ppm ||
        slr != policy->slr_ppm || gr != policy->gr_ppm) return OD_SUMMON_INVALID_POOL;
    return OD_SUMMON_OK;
}

/* Rejection sampling avoids modulo bias. A broken random source cannot hang the app forever. */
static int uniform_ticket(od_summon_random source, void *context, uint32_t *ticket) {
    const uint64_t bound = OD_SUMMON_WEIGHT_TOTAL;
    const uint64_t threshold = (UINT64_C(0) - bound) % bound;
    unsigned tries;
    for (tries = 0; tries < 128; tries++) {
        uint64_t sample;
        if (!source(context, &sample, sizeof(sample))) return 0;
        if (sample >= threshold) { *ticket = (uint32_t)(sample % bound); return 1; }
    }
    return 0;
}

od_summon_status od_summon_make_plan(const od_summon_entry *pool, size_t pool_count,
    const od_summon_policy *policy, const char *main_definition_id, uint64_t main_epoch,
    od_pity_state prior_pity, od_summon_kind kind, uint64_t available_stones,
    od_summon_random random_bytes, void *random_context, od_summon_plan *out) {
    od_summon_status status;
    od_summon_plan next;
    size_t main_index = pool_count, i;
    unsigned limit, draw;
    if (!out || !random_bytes || !valid_id(main_definition_id) || !main_epoch ||
        (kind != OD_SUMMON_SINGLE && kind != OD_SUMMON_MULTI)) return OD_SUMMON_INVALID_ARGUMENT;
    status = od_summon_validate_pool(pool, pool_count, policy);
    if (status != OD_SUMMON_OK) return status;
    for (i = 0; i < pool_count; i++)
        if (!strcmp(pool[i].definition_id, main_definition_id)) { main_index = i; break; }
    if (main_index == pool_count) return OD_SUMMON_INVALID_POOL;
    limit = od_summon_pity_limit(pool[main_index].rarity);
    if (!limit) return OD_SUMMON_INVALID_POLICY; /* extra rarity pity must be chosen explicitly */
    if (prior_pity.epoch != main_epoch) { prior_pity.epoch = main_epoch; prior_pity.misses = 0; }
    if (prior_pity.misses >= limit) return OD_SUMMON_INVALID_PITY;
    memset(&next, 0, sizeof(next));
    next.count = kind == OD_SUMMON_SINGLE ? 1u : policy->multi_count;
    next.stone_cost = kind == OD_SUMMON_SINGLE ? 5u : 50u;
    if (available_stones < next.stone_cost) return OD_SUMMON_INSUFFICIENT_STONES;
    for (draw = 0; draw < next.count; draw++) {
        uint32_t ticket, cumulative = 0;
        if (!uniform_ticket(random_bytes, random_context, &ticket)) return OD_SUMMON_RANDOM_FAILED;
        for (i = 0; i < pool_count; i++) {
            cumulative += pool[i].weight_ppm;
            if (ticket < cumulative) break;
        }
        /* Validation guarantees total == 1,000,000 and ticket is strictly below that. */
        if (i == pool_count) return OD_SUMMON_INVALID_POOL;
        next.pool_indexes[draw] = i;
        if (i == main_index) next.main_feature_pulled = 1;
    }
    next.next_pity = prior_pity;
    if (!next.main_feature_pulled && kind == OD_SUMMON_MULTI) {
        next.next_pity.misses++;
        if (next.next_pity.misses >= limit) {
            next.pool_indexes[next.count - 1] = main_index;
            next.main_feature_pulled = 1;
            next.guaranteed = 1;
        }
    }
    if (next.main_feature_pulled) next.next_pity.misses = 0;
    *out = next;
    return OD_SUMMON_OK;
}

od_summon_status od_featured_upsert(const od_featured_list *old, const char *definition_id,
    uint64_t revision, od_feature_revision_policy revision_policy, od_featured_plan *out) {
    od_featured_plan next;
    unsigned i, j;
    if (!old || !out || !valid_id(definition_id) || !revision || old->count > OD_FEATURED_SLOTS ||
        (old->count && !old->epoch)) return OD_SUMMON_INVALID_ARGUMENT;
    for (i = 0; i < old->count; i++) {
        if (!valid_id(old->entries[i].definition_id) || !old->entries[i].revision)
            return OD_SUMMON_INVALID_ARGUMENT;
        for (j = 0; j < i; j++) if (!strcmp(old->entries[i].definition_id, old->entries[j].definition_id))
            return OD_SUMMON_INVALID_ARGUMENT;
    }
    memset(&next, 0, sizeof(next));
    next.featured = *old;
    for (i = 0; i < old->count; i++) {
        if (strcmp(old->entries[i].definition_id, definition_id)) continue;
        if (revision <= old->entries[i].revision) { *out = next; return OD_SUMMON_OK; }
        if (revision_policy != OD_REVISION_KEEP_FEATURE_POSITION_AND_PITY)
            return OD_SUMMON_POLICY_REQUIRED;
        next.featured.entries[i].revision = revision;
        next.change = OD_FEATURE_UPDATED;
        *out = next;
        return OD_SUMMON_OK;
    }
    if (old->epoch == UINT64_MAX) return OD_SUMMON_INVALID_ARGUMENT;
    if (old->count == OD_FEATURED_SLOTS)
        memcpy(next.evicted_id, old->entries[OD_FEATURED_SLOTS - 1].definition_id, sizeof(next.evicted_id));
    next.featured.count = old->count < OD_FEATURED_SLOTS ? old->count + 1 : OD_FEATURED_SLOTS;
    for (i = next.featured.count - 1; i > 0; i--) next.featured.entries[i] = old->entries[i - 1];
    memset(&next.featured.entries[0], 0, sizeof(next.featured.entries[0]));
    memcpy(next.featured.entries[0].definition_id, definition_id, strlen(definition_id) + 1);
    next.featured.entries[0].revision = revision;
    next.featured.epoch++;
    next.change = OD_FEATURE_NEW_MAIN;
    *out = next;
    return OD_SUMMON_OK;
}

const char *od_summon_status_name(od_summon_status status) {
    switch (status) {
        case OD_SUMMON_OK: return "OK";
        case OD_SUMMON_INVALID_ARGUMENT: return "INVALID_ARGUMENT";
        case OD_SUMMON_INVALID_POOL: return "INVALID_POOL";
        case OD_SUMMON_INVALID_POLICY: return "INVALID_POLICY";
        case OD_SUMMON_INSUFFICIENT_STONES: return "INSUFFICIENT_STONES";
        case OD_SUMMON_RANDOM_FAILED: return "RANDOM_FAILED";
        case OD_SUMMON_INVALID_PITY: return "INVALID_PITY";
        case OD_SUMMON_POLICY_REQUIRED: return "POLICY_REQUIRED";
        case OD_SUMMON_NO_MEMORY: return "NO_MEMORY";
        default: return "UNKNOWN";
    }
}
