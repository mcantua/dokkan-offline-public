#include "schedules.h"
#include <assert.h>
#include <limits.h>
#include <stdio.h>
#include <string.h>

static int64_t central(int y, int m, int d, int h, int minute, int second) {
    od_civil_time c = {y,m,d,h,minute,second,0};
    int64_t value;
    assert(od_schedule_utc_time(&c,OD_ZONE_AMERICA_CHICAGO_2007,OD_FOLD_EARLIER,&value) == OD_SCHEDULE_OK);
    return value;
}

typedef struct { uint64_t value; unsigned calls; int fail; } fixture;
static int random_fixture(void *context, void *out, size_t n) {
    fixture *f = (fixture *)context;
    f->calls++;
    assert(n == sizeof(f->value));
    if (f->fail) return 0;
    memcpy(out,&f->value,n);
    return 1;
}

static void calendar(void) {
    od_civil_time c;
    od_schedule_period p;
    int64_t lower, upper, early, late;
    /* Fixed UTC values cross-checked against the platform IANA America/Chicago database. */
    assert(od_schedule_local_time(INT64_C(1772956799),OD_ZONE_AMERICA_CHICAGO_2007,&c) == OD_SCHEDULE_OK);
    assert(c.year == 2026 && c.month == 3 && c.day == 8 && c.hour == 1 && c.minute == 59 && c.second == 59);
    assert(od_schedule_local_time(INT64_C(1772956800),OD_ZONE_AMERICA_CHICAGO_2007,&c) == OD_SCHEDULE_OK && c.hour == 3 && c.minute == 0);
    assert(od_schedule_local_time(INT64_C(1793516399),OD_ZONE_AMERICA_CHICAGO_2007,&c) == OD_SCHEDULE_OK && c.hour == 1 && c.minute == 59);
    assert(od_schedule_local_time(INT64_C(1793516400),OD_ZONE_AMERICA_CHICAGO_2007,&c) == OD_SCHEDULE_OK && c.hour == 1 && c.minute == 0);
    c = (od_civil_time){2026,11,1,1,30,0,0};
    assert(od_schedule_utc_time(&c,OD_ZONE_AMERICA_CHICAGO_2007,OD_FOLD_EARLIER,&early) == OD_SCHEDULE_OK);
    assert(od_schedule_utc_time(&c,OD_ZONE_AMERICA_CHICAGO_2007,OD_FOLD_LATER,&late) == OD_SCHEDULE_OK && late - early == 3600);
    c = (od_civil_time){2026,3,8,2,30,0,0};
    assert(od_schedule_utc_time(&c,OD_ZONE_AMERICA_CHICAGO_2007,OD_FOLD_EARLIER,&early) == OD_SCHEDULE_OK);
    assert(od_schedule_local_time(early,OD_ZONE_AMERICA_CHICAGO_2007,&c) == OD_SCHEDULE_OK && c.hour == 3 && c.minute == 30);
    assert(od_schedule_nine_month_bounds(central(2026,11,30,12,34,56),OD_ZONE_AMERICA_CHICAGO_2007,&lower,&upper) == OD_SCHEDULE_OK);
    assert(lower == central(2026,2,28,12,34,56) && upper == central(2026,11,30,12,34,56));
    assert(od_schedule_nine_month_bounds(central(2024,11,30,12,34,56),OD_ZONE_AMERICA_CHICAGO_2007,&lower,&upper) == OD_SCHEDULE_OK);
    assert(lower == central(2024,2,29,12,34,56));
    assert(od_schedule_current_period(central(2026,3,7,0,0,0),OD_ZONE_AMERICA_CHICAGO_2007,&p) == OD_SCHEDULE_OK);
    assert(p.week_id == 20260302 && p.weekend_id == 20260307 && p.weekend_active);
    assert(p.weekend_end_utc - p.weekend_start_utc == 47 * 3600);
    assert(od_schedule_current_period(central(2026,10,31,0,0,0),OD_ZONE_AMERICA_CHICAGO_2007,&p) == OD_SCHEDULE_OK);
    assert(p.weekend_active && p.weekend_end_utc - p.weekend_start_utc == 49 * 3600);
    assert(od_schedule_current_period(central(2026,11,2,0,0,0),OD_ZONE_AMERICA_CHICAGO_2007,&p) == OD_SCHEDULE_OK);
    assert(p.week_id == 20261102 && !p.weekend_active);
    c = (od_civil_time){2026,2,29,0,0,0,0};
    assert(od_schedule_utc_time(&c,OD_ZONE_UTC,OD_FOLD_EARLIER,&early) == OD_SCHEDULE_INVALID_ARGUMENT);
    c = (od_civil_time){1970,1,1,0,0,0,0};
    assert(od_schedule_utc_time(&c,OD_ZONE_UTC,OD_FOLD_EARLIER,&early) == OD_SCHEDULE_OK && early == 0);
    assert(od_schedule_local_time(INT64_MAX,OD_ZONE_UTC,&c) == OD_SCHEDULE_OUT_OF_RANGE);
}

static void rotations_and_elder_kai(void) {
    int64_t now = central(2026,11,30,12,0,0), lower, upper;
    od_weekly_rotation prior = {0}, plan, before;
    od_schedule_period period;
    od_elder_kai_plan kai_plan;
    fixture random = {UINT64_MAX,0,0};
    od_historical_banner history[6];
    od_elder_kai_entry kai[] = {{"verified:kai-a",1,1,600000},{"verified:kai-b",1,1,400000}};
    assert(od_schedule_nine_month_bounds(now,OD_ZONE_AMERICA_CHICAGO_2007,&lower,&upper) == OD_SCHEDULE_OK);
    history[0] = (od_historical_banner){"official:boundary",lower,1,1};
    history[1] = (od_historical_banner){"official:recent",now,1,1};
    history[2] = (od_historical_banner){"official:middle",now - 86400,1,1};
    history[3] = (od_historical_banner){"too-old",lower - 1,1,1};
    history[4] = (od_historical_banner){"future",upper + 1,1,1};
    history[5] = (od_historical_banner){"unverified",now,0,1};
    assert(od_schedule_rotate(history,6,"catalog:v1",now,OD_ZONE_AMERICA_CHICAGO_2007,&prior,random_fixture,&random,&plan) == OD_SCHEDULE_OK);
    assert(!strcmp(plan.banner_ids[0],"official:boundary") && !strcmp(plan.banner_ids[1],"official:middle"));
    assert(random.calls == 2 && strcmp(plan.banner_ids[0],plan.banner_ids[1]));
    prior = plan;
    random.fail = 1; random.calls = 0;
    assert(od_schedule_rotate(history,6,"catalog:v1",now + 1,OD_ZONE_AMERICA_CHICAGO_2007,&prior,random_fixture,&random,&plan) == OD_SCHEDULE_OK);
    assert(random.calls == 0 && !memcmp(&prior,&plan,sizeof(plan)));
    before = plan;
    assert(od_schedule_rotate(history,6,"catalog:v2",now,OD_ZONE_AMERICA_CHICAGO_2007,&prior,random_fixture,&random,&plan) == OD_SCHEDULE_POLICY_MISMATCH);
    assert(!memcmp(&before,&plan,sizeof(plan)));
    random.fail = 0;
    assert(od_schedule_rotate(history,6,"catalog:v1",now + 7 * 86400,OD_ZONE_AMERICA_CHICAGO_2007,&prior,random_fixture,&random,&plan) == OD_SCHEDULE_OK);
    assert(strcmp(plan.banner_ids[0],"official:boundary") && strcmp(plan.banner_ids[1],"official:boundary"));
    prior = plan;
    assert(od_schedule_rotate(history,6,"catalog:v1",now,OD_ZONE_AMERICA_CHICAGO_2007,&prior,random_fixture,&random,&plan) == OD_SCHEDULE_POLICY_MISMATCH);
    memset(&prior,0,sizeof(prior));
    assert(od_schedule_rotate(history,1,"catalog:v1",now,OD_ZONE_AMERICA_CHICAGO_2007,&prior,random_fixture,&random,&plan) == OD_SCHEDULE_NOT_ENOUGH_HISTORY);
    assert(od_schedule_current_period(central(2026,10,31,0,0,0),OD_ZONE_AMERICA_CHICAGO_2007,&period) == OD_SCHEDULE_OK);
    random.value = 1000000;
    assert(od_elder_kai_draw(&period,period.weekend_start_utc - 1,kai,2,10,OD_SUMMON_SINGLE,5,random_fixture,&random,&kai_plan) == OD_SCHEDULE_NOT_ACTIVE);
    assert(od_elder_kai_draw(&period,period.weekend_start_utc,kai,2,10,OD_SUMMON_SINGLE,5,random_fixture,&random,&kai_plan) == OD_SCHEDULE_OK);
    assert(kai_plan.count == 1 && kai_plan.stone_cost == 5 && kai_plan.pool_indexes[0] == 0);
    assert(od_elder_kai_draw(&period,period.weekend_end_utc - 1,kai,2,10,OD_SUMMON_MULTI,50,random_fixture,&random,&kai_plan) == OD_SCHEDULE_OK);
    assert(kai_plan.count == 10 && kai_plan.stone_cost == 50);
    assert(od_elder_kai_draw(&period,period.weekend_end_utc,kai,2,10,OD_SUMMON_MULTI,50,random_fixture,&random,&kai_plan) == OD_SCHEDULE_NOT_ACTIVE);
    assert(od_elder_kai_draw(&period,period.weekend_start_utc,kai,2,10,OD_SUMMON_MULTI,49,random_fixture,&random,&kai_plan) == OD_SCHEDULE_INSUFFICIENT_STONES);
    kai[0].super_attack_levels = 2;
    assert(od_elder_kai_draw(&period,period.weekend_start_utc,kai,2,10,OD_SUMMON_SINGLE,5,random_fixture,&random,&kai_plan) == OD_SCHEDULE_INVALID_ARGUMENT);
}

static void tournament(void) {
    od_schedule_period period;
    od_tournament_competitor competitor = {"simulated:one",100,0};
    od_tournament_state prior = {0}, state, before;
    od_tournament_reward_plan reward;
    int64_t points[] = {100,50,20};
    uint32_t rank;
    od_rank_reward first[] = {{"training:item",OD_REWARD_ITEM,1},{"medal:a",OD_REWARD_MEDAL,2},{"stones",OD_REWARD_DRAGON_STONE,5}};
    od_rank_reward_tier tiers[] = {{1,1,first,3},{2,100,first,1}};
    assert(od_schedule_current_period(central(2026,3,7,0,0,0),OD_ZONE_AMERICA_CHICAGO_2007,&period) == OD_SCHEDULE_OK);
    assert(od_tournament_advance(&period,1,42,&competitor,period.weekend_start_utc - 1,&prior,&state) == OD_SCHEDULE_NOT_ACTIVE);
    assert(od_tournament_advance(&period,1,42,&competitor,period.weekend_start_utc + 2 * 3600,&prior,&state) == OD_SCHEDULE_OK);
    assert(state.points == 200);
    prior = state;
    assert(od_tournament_advance(&period,1,42,&competitor,period.weekend_start_utc + 3600,&prior,&state) == OD_SCHEDULE_OK);
    assert(state.points == 200 && state.last_update_utc == prior.last_update_utc);
    before = state;
    assert(od_tournament_advance(&period,1,43,&competitor,period.weekend_end_utc,&prior,&state) == OD_SCHEDULE_POLICY_MISMATCH);
    assert(!memcmp(&before,&state,sizeof(state)));
    competitor.points_per_hour++;
    assert(od_tournament_advance(&period,1,42,&competitor,period.weekend_end_utc,&prior,&state) == OD_SCHEDULE_POLICY_MISMATCH);
    competitor.points_per_hour--;
    assert(od_tournament_advance(&period,1,42,&competitor,period.weekend_end_utc + 86400,&prior,&state) == OD_SCHEDULE_OK);
    assert(state.points == 4700 && state.last_update_utc == period.weekend_end_utc);
    assert(od_tournament_rank(50,points,3,OD_TIES_SHARE_RANK,&rank) == OD_SCHEDULE_OK && rank == 2);
    assert(od_tournament_rank(50,points,3,OD_TIES_PLAYER_AFTER_EQUALS,&rank) == OD_SCHEDULE_OK && rank == 3);
    assert(od_tournament_rewards(&period,period.weekend_end_utc - 1,1,tiers,2,0,&reward) == OD_SCHEDULE_NOT_ACTIVE);
    assert(od_tournament_rewards(&period,period.weekend_end_utc,1,tiers,2,0,&reward) == OD_SCHEDULE_OK);
    assert(reward.weekend_id == period.weekend_id && reward.reward_count == 3);
    assert(reward.rewards[0].quantity == 3 && reward.rewards[1].quantity == 12 && reward.rewards[2].quantity == 50);
    assert(od_tournament_rewards(&period,period.weekend_end_utc,1,tiers,2,1,&reward) == OD_SCHEDULE_ALREADY_SETTLED);
    assert(od_tournament_rewards(&period,period.weekend_end_utc,101,tiers,2,0,&reward) == OD_SCHEDULE_NO_REWARD);
    first[2].base_quantity = INT64_MAX;
    assert(od_tournament_rewards(&period,period.weekend_end_utc,1,tiers,2,0,&reward) == OD_SCHEDULE_OVERFLOW);
}

int main(void) {
    calendar();
    rotations_and_elder_kai();
    tournament();
    puts("PASS schedules: calendar9-month boundaries/leap clamp/DST, stable weekly official rotation, weekend-only Elder Kai, deterministic tournament progress/rank/reward planning and replay guards");
    return 0;
}
