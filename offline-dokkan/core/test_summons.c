/* One combined deterministic policy check. This does not verify game-wire compatibility. */
#include "summons.h"
#include <assert.h>
#include <stdio.h>
#include <string.h>

typedef struct { uint64_t sample; unsigned calls; int fail; int reject_first; } random_fixture;

static int fixture_random(void *context, void *bytes, size_t length) {
    random_fixture *f = (random_fixture *)context;
    uint64_t sample = f->reject_first && f->calls == 0 ? 0 : f->sample;
    f->calls++;
    assert(length == sizeof(sample));
    if (f->fail) return 0;
    memcpy(bytes, &sample, length);
    return 1;
}

static const od_summon_entry pool[] = {
    {"ordinary:n", OD_RARITY_N, 988800}, {"created:ur", OD_RARITY_UR, 100},
    {"created:lr", OD_RARITY_LR, 10000}, {"created:slr", OD_RARITY_SLR, 1000},
    {"created:gr", OD_RARITY_GR, 100}
};

static void draw_boundaries_and_validation(void) {
    const uint32_t tickets[] = {0, 988799, 988800, 988899, 988900, 998899, 998900, 999899, 999900, 999999};
    const size_t expected[] = {0, 0, 1, 1, 2, 2, 3, 3, 4, 4};
    od_summon_policy policy = od_summon_starting_policy(10);
    od_summon_plan p, before;
    od_summon_entry invalid[5];
    size_t i;
    assert(od_summon_validate_pool(pool, 5, &policy) == OD_SUMMON_OK);
    for (i = 0; i < sizeof(tickets) / sizeof(tickets[0]); i++) {
        random_fixture r = {1000000u + tickets[i], 0, 0, 0};
        assert(od_summon_make_plan(pool, 5, &policy, "created:gr", 1, (od_pity_state){1, 0},
            OD_SUMMON_SINGLE, 5, fixture_random, &r, &p) == OD_SUMMON_OK);
        assert(p.count == 1 && p.stone_cost == 5 && p.pool_indexes[0] == expected[i]);
        assert(r.calls == 1);
    }
    memcpy(invalid, pool, sizeof(invalid));
    invalid[1].definition_id = invalid[0].definition_id;
    assert(od_summon_validate_pool(invalid, 5, &policy) == OD_SUMMON_INVALID_POOL);
    memcpy(invalid, pool, sizeof(invalid)); invalid[0].weight_ppm--;
    assert(od_summon_validate_pool(invalid, 5, &policy) == OD_SUMMON_INVALID_POOL);
    memcpy(invalid, pool, sizeof(invalid)); invalid[2].rarity = OD_RARITY_UR;
    assert(od_summon_validate_pool(invalid, 5, &policy) == OD_SUMMON_INVALID_POOL);
    policy.multi_count = 0;
    assert(od_summon_validate_pool(pool, 5, &policy) == OD_SUMMON_INVALID_POLICY);
    policy.multi_count = 10;
    memset(&p, 0xa5, sizeof(p)); before = p;
    {
        random_fixture r = {1000000, 0, 0, 0};
        assert(od_summon_make_plan(pool, 5, &policy, "created:gr", 1, (od_pity_state){1, 0},
            OD_SUMMON_MULTI, 49, fixture_random, &r, &p) == OD_SUMMON_INSUFFICIENT_STONES);
        assert(r.calls == 0 && memcmp(&p, &before, sizeof(p)) == 0);
        r.fail = 1;
        assert(od_summon_make_plan(pool, 5, &policy, "created:gr", 1, (od_pity_state){1, 0},
            OD_SUMMON_MULTI, 50, fixture_random, &r, &p) == OD_SUMMON_RANDOM_FAILED);
        assert(memcmp(&p, &before, sizeof(p)) == 0);
        r.fail = 0; r.sample = 0; r.calls = 0;
        assert(od_summon_make_plan(pool, 5, &policy, "created:gr", 1, (od_pity_state){1, 0},
            OD_SUMMON_MULTI, 50, fixture_random, &r, &p) == OD_SUMMON_RANDOM_FAILED);
        assert(r.calls == 128 && memcmp(&p, &before, sizeof(p)) == 0);
        r.sample = 1000000; r.calls = 0; r.reject_first = 1;
        assert(od_summon_make_plan(pool, 5, &policy, "created:gr", 1, (od_pity_state){1, 0},
            OD_SUMMON_SINGLE, 5, fixture_random, &r, &p) == OD_SUMMON_OK);
        assert(r.calls == 2 && p.pool_indexes[0] == 0);
    }
}

static void pity_and_epoch(void) {
    const unsigned thresholds[] = {5, 10, 25, 50};
    od_summon_policy policy = od_summon_starting_policy(10);
    od_summon_plan p, before;
    size_t main;
    for (main = 1; main < 5; main++) {
        unsigned limit = thresholds[main - 1];
        random_fixture r = {1000000, 0, 0, 0};
        assert(od_summon_pity_limit(pool[main].rarity) == limit);
        assert(od_summon_make_plan(pool, 5, &policy, pool[main].definition_id, 7,
            (od_pity_state){7, limit - 1}, OD_SUMMON_MULTI, 50, fixture_random, &r, &p) == OD_SUMMON_OK);
        assert(p.count == 10 && p.stone_cost == 50 && r.calls == 10);
        assert(p.guaranteed && p.main_feature_pulled && p.next_pity.misses == 0);
        assert(p.pool_indexes[9] == main && p.pool_indexes[8] == 0);
        r.calls = 0;
        assert(od_summon_make_plan(pool, 5, &policy, pool[main].definition_id, 7,
            (od_pity_state){7, limit - 2}, OD_SUMMON_MULTI, 50, fixture_random, &r, &p) == OD_SUMMON_OK);
        assert(!p.guaranteed && !p.main_feature_pulled && p.next_pity.misses == limit - 1);
    }
    {
        random_fixture r = {1999900, 0, 0, 0}; /* natural GR */
        assert(od_summon_make_plan(pool, 5, &policy, "created:gr", 7, (od_pity_state){7,49},
            OD_SUMMON_MULTI, 50, fixture_random, &r, &p) == OD_SUMMON_OK);
        assert(!p.guaranteed && p.main_feature_pulled && p.next_pity.misses == 0 && r.calls == 10);
        assert(od_summon_make_plan(pool, 5, &policy, "created:gr", 7, (od_pity_state){7,49},
            OD_SUMMON_SINGLE, 5, fixture_random, &r, &p) == OD_SUMMON_OK);
        assert(p.next_pity.misses == 0);
        r.sample = 1000000;
        assert(od_summon_make_plan(pool, 5, &policy, "created:gr", 7, (od_pity_state){7,49},
            OD_SUMMON_SINGLE, 5, fixture_random, &r, &p) == OD_SUMMON_OK);
        assert(!p.guaranteed && p.next_pity.misses == 49);
        assert(od_summon_make_plan(pool, 5, &policy, "created:gr", 8, (od_pity_state){7,49},
            OD_SUMMON_MULTI, 50, fixture_random, &r, &p) == OD_SUMMON_OK);
        assert(!p.guaranteed && p.next_pity.epoch == 8 && p.next_pity.misses == 1);
        before = p;
        assert(od_summon_make_plan(pool, 5, &policy, "created:gr", 8, (od_pity_state){8,50},
            OD_SUMMON_MULTI, 50, fixture_random, &r, &p) == OD_SUMMON_INVALID_PITY);
        assert(memcmp(&before, &p, sizeof(p)) == 0);
    }
}

static void featured_identity(void) {
    od_featured_list list = {0};
    od_featured_plan p, before;
    char id[32];
    unsigned i;
    for (i = 1; i <= 6; i++) {
        (void)snprintf(id, sizeof(id), "created:%u", i);
        assert(od_featured_upsert(&list, id, 1, OD_REVISION_POLICY_UNDECIDED, &p) == OD_SUMMON_OK);
        assert(p.change == OD_FEATURE_NEW_MAIN && p.featured.epoch == i);
        list = p.featured;
    }
    assert(list.count == 5 && !strcmp(list.entries[0].definition_id, "created:6"));
    assert(!strcmp(list.entries[4].definition_id, "created:2") && !strcmp(p.evicted_id, "created:1"));
    assert(od_featured_upsert(&list, "created:3", 1, OD_REVISION_POLICY_UNDECIDED, &p) == OD_SUMMON_OK);
    assert(p.change == OD_FEATURE_UNCHANGED && p.featured.epoch == 6);
    before = p;
    assert(od_featured_upsert(&list, "created:3", 2, OD_REVISION_POLICY_UNDECIDED, &p) == OD_SUMMON_POLICY_REQUIRED);
    assert(memcmp(&before, &p, sizeof(p)) == 0);
    assert(od_featured_upsert(&list, "created:3", 2, OD_REVISION_KEEP_FEATURE_POSITION_AND_PITY, &p) == OD_SUMMON_OK);
    assert(p.change == OD_FEATURE_UPDATED && p.featured.epoch == 6);
    assert(!strcmp(p.featured.entries[3].definition_id, "created:3") && p.featured.entries[3].revision == 2);
    list = p.featured;
    assert(od_featured_upsert(&list, "created:3", 1, OD_REVISION_POLICY_UNDECIDED, &p) == OD_SUMMON_OK);
    assert(p.change == OD_FEATURE_UNCHANGED && p.featured.entries[3].revision == 2);
    list.epoch = UINT64_MAX;
    before = p;
    assert(od_featured_upsert(&list, "created:7", 1, OD_REVISION_POLICY_UNDECIDED, &p) == OD_SUMMON_INVALID_ARGUMENT);
    assert(memcmp(&before, &p, sizeof(p)) == 0);
}

int main(void) {
    draw_boundaries_and_validation();
    pity_and_epoch();
    featured_identity();
    puts("PASS summons: configured rates/boundaries, safe failure, rejection sampling, all pity thresholds, singles/epoch/natural reset, and featured dedup/FIFO/revision policy");
    return 0;
}
