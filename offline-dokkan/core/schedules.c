#include "schedules.h"

#include <limits.h>
#include <stdlib.h>
#include <string.h>

static int id_ok(const char *s) {
    size_t i;
    if (!s || !s[0]) return 0;
    for (i = 0; i <= OD_DEFINITION_ID_MAX; i++) {
        unsigned char c = (unsigned char)s[i];
        if (!c) return 1;
        if (c <= 32 || c > 126) return 0;
    }
    return 0;
}

static int leap(int y) { return y % 4 == 0 && (y % 100 != 0 || y % 400 == 0); }
static int month_days(int y, int m) {
    static const int lengths[] = {0,31,28,31,30,31,30,31,31,30,31,30,31};
    return m == 2 ? 28 + leap(y) : lengths[m];
}

/* Gregorian civil arithmetic; no process-global TZ mutation and no libc time_t width reliance. */
static int64_t days_from_civil(int y, int m, int d) {
    int era, yoe, doy, doe;
    y -= m <= 2;
    era = y / 400;
    yoe = y - era * 400;
    doy = (153 * (m + (m > 2 ? -3 : 9)) + 2) / 5 + d - 1;
    doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
    return (int64_t)era * 146097 + doe - 719468;
}

static od_civil_time civil_from_days(int64_t days) {
    od_civil_time c;
    int64_t z = days + 719468;
    int era = (int)(z / 146097), doe = (int)(z - (int64_t)era * 146097);
    int yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
    int doy = doe - (365 * yoe + yoe / 4 - yoe / 100), mp = (5 * doy + 2) / 153;
    memset(&c, 0, sizeof(c));
    c.day = doy - (153 * mp + 2) / 5 + 1;
    c.month = mp + (mp < 10 ? 3 : -9);
    c.year = yoe + era * 400 + (c.month <= 2);
    c.weekday = (int)((days + 4) % 7);
    if (c.weekday < 0) c.weekday += 7;
    return c;
}

static od_civil_time split_seconds(int64_t seconds) {
    int64_t day = seconds >= 0 ? seconds / 86400 : (seconds - 86399) / 86400;
    int64_t rem = seconds - day * 86400;
    od_civil_time c = civil_from_days(day);
    c.hour = (int)(rem / 3600);
    c.minute = (int)((rem % 3600) / 60);
    c.second = (int)(rem % 60);
    return c;
}

static int valid_civil(const od_civil_time *c) {
    return c && c->year >= 1970 && c->year <= 9999 && c->month >= 1 && c->month <= 12 &&
        c->day >= 1 && c->day <= month_days(c->year, c->month) &&
        c->hour >= 0 && c->hour < 24 && c->minute >= 0 && c->minute < 60 && c->second >= 0 && c->second < 60;
}

static int sunday(int year, int month, int n) {
    int weekday = (int)((days_from_civil(year, month, 1) + 4) % 7);
    return 1 + (7 - weekday) % 7 + (n - 1) * 7;
}

static int64_t max_seconds(void) { return days_from_civil(9999,12,31) * 86400 + 86399; }

od_schedule_status od_schedule_local_time(int64_t utc, od_schedule_zone zone, od_civil_time *out) {
    od_civil_time c;
    int offset = 0;
    if (!out || (zone != OD_ZONE_UTC && zone != OD_ZONE_AMERICA_CHICAGO_2007)) return OD_SCHEDULE_INVALID_ARGUMENT;
    if (utc < 0 || utc > max_seconds()) return OD_SCHEDULE_OUT_OF_RANGE;
    c = split_seconds(utc);
    if (zone == OD_ZONE_AMERICA_CHICAGO_2007) {
        int64_t spring, autumn;
        if (c.year < 2007) return OD_SCHEDULE_OUT_OF_RANGE;
        spring = days_from_civil(c.year,3,sunday(c.year,3,2)) * 86400 + 8 * 3600;
        autumn = days_from_civil(c.year,11,sunday(c.year,11,1)) * 86400 + 7 * 3600;
        offset = utc >= spring && utc < autumn ? -5 * 3600 : -6 * 3600;
    }
    c = split_seconds(utc + offset);
    if (c.year < (zone == OD_ZONE_UTC ? 1970 : 2007)) return OD_SCHEDULE_OUT_OF_RANGE;
    *out = c;
    return OD_SCHEDULE_OK;
}

od_schedule_status od_schedule_utc_time(const od_civil_time *local, od_schedule_zone zone,
                                      od_schedule_fold fold, int64_t *out) {
    int daylight = 0;
    int64_t value;
    if (!out || !valid_civil(local) || (zone != OD_ZONE_UTC && zone != OD_ZONE_AMERICA_CHICAGO_2007) ||
        (fold != OD_FOLD_EARLIER && fold != OD_FOLD_LATER)) return OD_SCHEDULE_INVALID_ARGUMENT;
    value = days_from_civil(local->year,local->month,local->day) * 86400 +
        local->hour * 3600 + local->minute * 60 + local->second;
    if (zone == OD_ZONE_AMERICA_CHICAGO_2007) {
        int spring, autumn;
        if (local->year < 2007) return OD_SCHEDULE_OUT_OF_RANGE;
        spring = sunday(local->year,3,2);
        autumn = sunday(local->year,11,1);
        if (local->month > 3 && local->month < 11) daylight = 1;
        if (local->month == 3 && (local->day > spring || (local->day == spring && local->hour >= 3))) daylight = 1;
        if (local->month == 11 && (local->day < autumn ||
            (local->day == autumn && (local->hour < 1 || (local->hour == 1 && fold == OD_FOLD_EARLIER))))) daylight = 1;
        /* A spring 2:xx input uses standard offset, resolving it to the matching 3:xx daylight instant. */
        value += (daylight ? 5 : 6) * 3600;
    }
    if (value < 0 || value > max_seconds()) return OD_SCHEDULE_OUT_OF_RANGE;
    *out = value;
    return OD_SCHEDULE_OK;
}

od_schedule_status od_schedule_nine_month_bounds(int64_t now, od_schedule_zone zone,
                                                int64_t *lower, int64_t *upper) {
    od_civil_time c;
    od_schedule_status status;
    int months;
    int64_t begin;
    if (!lower || !upper || lower == upper) return OD_SCHEDULE_INVALID_ARGUMENT;
    status = od_schedule_local_time(now, zone, &c);
    if (status != OD_SCHEDULE_OK) return status;
    months = c.year * 12 + c.month - 1 - 9;
    c.year = months / 12;
    c.month = months % 12 + 1;
    if (c.day > month_days(c.year,c.month)) c.day = month_days(c.year,c.month);
    status = od_schedule_utc_time(&c,zone,OD_FOLD_EARLIER,&begin);
    if (status != OD_SCHEDULE_OK) return status;
    *lower = begin;
    *upper = now;
    return OD_SCHEDULE_OK;
}

od_schedule_status od_schedule_current_period(int64_t now, od_schedule_zone zone, od_schedule_period *out) {
    od_schedule_period p;
    od_civil_time c, monday, saturday, next_monday;
    od_schedule_status status;
    int64_t day;
    if (!out) return OD_SCHEDULE_INVALID_ARGUMENT;
    status = od_schedule_local_time(now,zone,&c);
    if (status != OD_SCHEDULE_OK) return status;
    day = days_from_civil(c.year,c.month,c.day) - (c.weekday + 6) % 7;
    monday = civil_from_days(day);
    saturday = civil_from_days(day + 5);
    next_monday = civil_from_days(day + 7);
    memset(&p,0,sizeof(p));
    p.week_id = (uint32_t)(monday.year * 10000 + monday.month * 100 + monday.day);
    p.weekend_id = (uint32_t)(saturday.year * 10000 + saturday.month * 100 + saturday.day);
    status = od_schedule_utc_time(&monday,zone,OD_FOLD_EARLIER,&p.week_start_utc);
    if (status == OD_SCHEDULE_OK) status = od_schedule_utc_time(&next_monday,zone,OD_FOLD_EARLIER,&p.week_end_utc);
    if (status == OD_SCHEDULE_OK) status = od_schedule_utc_time(&saturday,zone,OD_FOLD_EARLIER,&p.weekend_start_utc);
    if (status != OD_SCHEDULE_OK) return status;
    p.weekend_end_utc = p.week_end_utc;
    p.weekend_active = now >= p.weekend_start_utc && now < p.weekend_end_utc;
    *out = p;
    return OD_SCHEDULE_OK;
}

static uint64_t hash_id(const char *s) {
    uint64_t h = UINT64_C(14695981039346656037);
    while (*s) { h ^= (unsigned char)*s++; h *= UINT64_C(1099511628211); }
    return h;
}

static int bounded_random(od_summon_random source, void *context, size_t bound, size_t *out) {
    uint64_t threshold;
    unsigned attempts;
    if (!source || !bound) return 0;
    threshold = (UINT64_C(0) - (uint64_t)bound) % (uint64_t)bound;
    for (attempts = 0; attempts < 128; attempts++) {
        uint64_t value;
        if (!source(context,&value,sizeof(value))) return 0;
        if (value >= threshold) { *out = (size_t)(value % bound); return 1; }
    }
    return 0;
}

od_schedule_status od_schedule_rotate(const od_historical_banner *history, size_t count,
    const char *catalog, int64_t now, od_schedule_zone zone, const od_weekly_rotation *prior,
    od_summon_random random_bytes, void *random_context, od_weekly_rotation *out) {
    od_schedule_period period;
    od_weekly_rotation next;
    od_schedule_status status;
    int64_t lower, upper;
    size_t i, j, eligible_count = 0, first, second, *eligible;
    if (!history || !count || count > 4096 || !id_ok(catalog) || !prior || !out) return OD_SCHEDULE_INVALID_ARGUMENT;
    status = od_schedule_current_period(now,zone,&period);
    if (status != OD_SCHEDULE_OK) return status;
    for (i = 0; i < count; i++) {
        if (!id_ok(history[i].banner_id) || (history[i].verified_official_history != 0 && history[i].verified_official_history != 1) ||
            (history[i].usable_local_content != 0 && history[i].usable_local_content != 1)) return OD_SCHEDULE_INVALID_ARGUMENT;
        for (j = 0; j < i; j++) if (!strcmp(history[i].banner_id,history[j].banner_id)) return OD_SCHEDULE_INVALID_ARGUMENT;
    }
    if (prior->week_id == period.week_id) {
        int found[2] = {0,0};
        if (!id_ok(prior->catalog_version) || strcmp(prior->catalog_version,catalog) ||
            !id_ok(prior->banner_ids[0]) || !id_ok(prior->banner_ids[1]) ||
            !strcmp(prior->banner_ids[0],prior->banner_ids[1]) ||
            prior->selected_at_utc < period.week_start_utc || prior->selected_at_utc >= period.week_end_utc)
            return OD_SCHEDULE_POLICY_MISMATCH;
        status = od_schedule_nine_month_bounds(prior->selected_at_utc,zone,&lower,&upper);
        if (status != OD_SCHEDULE_OK) return status;
        for (i = 0; i < count; i++) for (j = 0; j < 2; j++)
            if (!strcmp(history[i].banner_id,prior->banner_ids[j]) && history[i].verified_official_history &&
                history[i].usable_local_content && history[i].first_open_utc >= lower && history[i].first_open_utc <= upper) found[j] = 1;
        if (!found[0] || !found[1]) return OD_SCHEDULE_POLICY_MISMATCH;
        *out = *prior;
        return OD_SCHEDULE_OK;
    }
    /* A backward clock must not roll an already-persisted week backward and permit another draw. */
    if (prior->week_id > period.week_id) return OD_SCHEDULE_POLICY_MISMATCH;
    status = od_schedule_nine_month_bounds(now,zone,&lower,&upper);
    if (status != OD_SCHEDULE_OK) return status;
    eligible = (size_t *)malloc(count * sizeof(*eligible));
    if (!eligible) return OD_SCHEDULE_OUT_OF_RANGE;
    for (i = 0; i < count; i++) if (history[i].verified_official_history && history[i].usable_local_content &&
        history[i].first_open_utc >= lower && history[i].first_open_utc <= upper) eligible[eligible_count++] = i;
    if (eligible_count < 2) { free(eligible); return OD_SCHEDULE_NOT_ENOUGH_HISTORY; }
    if (!bounded_random(random_bytes,random_context,eligible_count,&first) ||
        !bounded_random(random_bytes,random_context,eligible_count - 1,&second)) { free(eligible); return OD_SCHEDULE_RANDOM_FAILED; }
    if (second >= first) second++;
    memset(&next,0,sizeof(next));
    next.week_id = period.week_id;
    next.selected_at_utc = now;
    memcpy(next.catalog_version,catalog,strlen(catalog) + 1);
    memcpy(next.banner_ids[0],history[eligible[first]].banner_id,strlen(history[eligible[first]].banner_id) + 1);
    memcpy(next.banner_ids[1],history[eligible[second]].banner_id,strlen(history[eligible[second]].banner_id) + 1);
    free(eligible);
    *out = next;
    return OD_SCHEDULE_OK;
}

static uint64_t mix(uint64_t x) {
    x += UINT64_C(0x9e3779b97f4a7c15);
    x = (x ^ (x >> 30)) * UINT64_C(0xbf58476d1ce4e5b9);
    x = (x ^ (x >> 27)) * UINT64_C(0x94d049bb133111eb);
    return x ^ (x >> 31);
}

static int score_at(int64_t elapsed, uint64_t seed, uint64_t id, uint32_t period,
                    const od_tournament_competitor *c, int64_t *out) {
    int64_t total = 0, hour;
    for (hour = 0; hour * 3600 < elapsed; hour++) {
        uint64_t rate = c->points_per_hour + mix(seed ^ id ^ ((uint64_t)period << 32) ^ (uint64_t)hour) % ((uint64_t)c->extra_points_per_hour_max + 1);
        uint64_t seconds = (uint64_t)(elapsed - hour * 3600);
        uint64_t points;
        if (seconds > 3600) seconds = 3600;
        points = rate * seconds / 3600;
        if (points > (uint64_t)INT64_MAX - (uint64_t)total) return 0;
        total += (int64_t)points;
    }
    *out = total;
    return 1;
}

static int valid_period(const od_schedule_period *p) {
    return p && p->weekend_id && p->weekend_start_utc >= 0 && p->weekend_end_utc > p->weekend_start_utc &&
        p->weekend_end_utc - p->weekend_start_utc <= 7 * 86400;
}

od_schedule_status od_elder_kai_draw(const od_schedule_period *period, int64_t now,
    const od_elder_kai_entry *pool, size_t count, unsigned multi_count, od_summon_kind kind,
    uint64_t stones, od_summon_random random_bytes, void *random_context, od_elder_kai_plan *out) {
    od_elder_kai_plan next;
    uint64_t total = 0;
    size_t i, j;
    unsigned draw;
    if (!valid_period(period) || !pool || !count || count > 4096 || multi_count < 2 ||
        multi_count > OD_SUMMON_MAX_MULTI || !random_bytes || !out ||
        (kind != OD_SUMMON_SINGLE && kind != OD_SUMMON_MULTI)) return OD_SCHEDULE_INVALID_ARGUMENT;
    if (now < period->weekend_start_utc || now >= period->weekend_end_utc) return OD_SCHEDULE_NOT_ACTIVE;
    for (i = 0; i < count; i++) {
        if (!id_ok(pool[i].definition_id) || pool[i].verified_elder_kai != 1 || pool[i].super_attack_levels != 1 ||
            !pool[i].weight_ppm || pool[i].weight_ppm > OD_SUMMON_WEIGHT_TOTAL) return OD_SCHEDULE_INVALID_ARGUMENT;
        for (j = 0; j < i; j++) if (!strcmp(pool[i].definition_id,pool[j].definition_id)) return OD_SCHEDULE_INVALID_ARGUMENT;
        total += pool[i].weight_ppm;
    }
    if (total != OD_SUMMON_WEIGHT_TOTAL) return OD_SCHEDULE_INVALID_ARGUMENT;
    memset(&next,0,sizeof(next));
    next.count = kind == OD_SUMMON_SINGLE ? 1 : multi_count;
    next.stone_cost = kind == OD_SUMMON_SINGLE ? 5 : 50;
    if (stones < next.stone_cost) return OD_SCHEDULE_INSUFFICIENT_STONES;
    for (draw = 0; draw < next.count; draw++) {
        size_t ticket;
        uint32_t cumulative = 0;
        if (!bounded_random(random_bytes,random_context,OD_SUMMON_WEIGHT_TOTAL,&ticket)) return OD_SCHEDULE_RANDOM_FAILED;
        for (i = 0; i < count; i++) {
            cumulative += pool[i].weight_ppm;
            if (ticket < cumulative) break;
        }
        next.pool_indexes[draw] = i;
    }
    *out = next;
    return OD_SCHEDULE_OK;
}

od_schedule_status od_tournament_advance(const od_schedule_period *period, uint64_t policy_version,
    uint64_t seed, const od_tournament_competitor *competitor, int64_t now,
    const od_tournament_state *prior, od_tournament_state *out) {
    od_tournament_state next;
    int64_t expected, end;
    uint64_t id;
    if (!valid_period(period) || !policy_version || !competitor || !id_ok(competitor->competitor_id) ||
        !competitor->points_per_hour || !prior || !out) return OD_SCHEDULE_INVALID_ARGUMENT;
    if (now < period->weekend_start_utc && !prior->weekend_id) return OD_SCHEDULE_NOT_ACTIVE;
    id = mix(hash_id(competitor->competitor_id) ^ ((uint64_t)competitor->points_per_hour << 32) ^
             competitor->extra_points_per_hour_max);
    end = now > period->weekend_end_utc ? period->weekend_end_utc : now;
    if (prior->weekend_id) {
        if (prior->weekend_id != period->weekend_id || prior->policy_version != policy_version ||
            prior->seed != seed || prior->competitor_hash != id || prior->points < 0 ||
            prior->last_update_utc < period->weekend_start_utc || prior->last_update_utc > period->weekend_end_utc)
            return OD_SCHEDULE_POLICY_MISMATCH;
        if (!score_at(prior->last_update_utc - period->weekend_start_utc,seed,id,period->weekend_id,competitor,&expected) ||
            expected != prior->points) return OD_SCHEDULE_POLICY_MISMATCH;
        if (end < prior->last_update_utc) end = prior->last_update_utc;
    }
    memset(&next,0,sizeof(next));
    next.weekend_id = period->weekend_id;
    next.policy_version = policy_version;
    next.seed = seed;
    next.competitor_hash = id;
    next.last_update_utc = end;
    if (!score_at(end - period->weekend_start_utc,seed,id,period->weekend_id,competitor,&next.points)) return OD_SCHEDULE_OVERFLOW;
    *out = next;
    return OD_SCHEDULE_OK;
}

od_schedule_status od_tournament_rank(int64_t player, const int64_t *others, size_t count,
    od_rank_tie_policy tie_policy, uint32_t *out) {
    size_t i;
    uint32_t rank = 1;
    if (player < 0 || (count && !others) || count >= UINT32_MAX || !out ||
        (tie_policy != OD_TIES_SHARE_RANK && tie_policy != OD_TIES_PLAYER_AFTER_EQUALS)) return OD_SCHEDULE_INVALID_ARGUMENT;
    for (i = 0; i < count; i++) {
        if (others[i] < 0) return OD_SCHEDULE_INVALID_ARGUMENT;
        if (others[i] > player || (others[i] == player && tie_policy == OD_TIES_PLAYER_AFTER_EQUALS)) rank++;
    }
    *out = rank;
    return OD_SCHEDULE_OK;
}

od_schedule_status od_tournament_rewards(const od_schedule_period *period, int64_t now,
    uint32_t final_rank, const od_rank_reward_tier *tiers, size_t count,
    int already_settled, od_tournament_reward_plan *out) {
    od_tournament_reward_plan next;
    const od_rank_reward_tier *selected = NULL;
    size_t i, j;
    if (!valid_period(period) || !final_rank || !tiers || !count || count > 128 || !out ||
        (already_settled != 0 && already_settled != 1)) return OD_SCHEDULE_INVALID_ARGUMENT;
    if (already_settled) return OD_SCHEDULE_ALREADY_SETTLED;
    if (now < period->weekend_end_utc) return OD_SCHEDULE_NOT_ACTIVE;
    for (i = 0; i < count; i++) {
        if (!tiers[i].rank_from || tiers[i].rank_to < tiers[i].rank_from ||
            tiers[i].reward_count > OD_TOURNAMENT_MAX_REWARDS || (tiers[i].reward_count && !tiers[i].rewards))
            return OD_SCHEDULE_INVALID_ARGUMENT;
        for (j = 0; j < i; j++) if (tiers[i].rank_from <= tiers[j].rank_to && tiers[i].rank_to >= tiers[j].rank_from)
            return OD_SCHEDULE_INVALID_ARGUMENT;
        if (final_rank >= tiers[i].rank_from && final_rank <= tiers[i].rank_to) selected = &tiers[i];
    }
    if (!selected) return OD_SCHEDULE_NO_REWARD;
    memset(&next,0,sizeof(next));
    next.weekend_id = period->weekend_id;
    next.final_rank = final_rank;
    next.reward_count = selected->reward_count;
    for (i = 0; i < selected->reward_count; i++) {
        od_progression_status status;
        if (!id_ok(selected->rewards[i].resource_id)) return OD_SCHEDULE_INVALID_ARGUMENT;
        for (j = 0; j < i; j++) if (selected->rewards[i].category == selected->rewards[j].category &&
            !strcmp(selected->rewards[i].resource_id,selected->rewards[j].resource_id)) return OD_SCHEDULE_INVALID_ARGUMENT;
        status = od_progression_amount(selected->rewards[i].category,OD_QUANTITY_REWARD,selected->rewards[i].base_quantity,&next.rewards[i].quantity);
        if (status == OD_PROGRESSION_OVERFLOW) return OD_SCHEDULE_OVERFLOW;
        if (status != OD_PROGRESSION_OK) return OD_SCHEDULE_INVALID_ARGUMENT;
        next.rewards[i].category = selected->rewards[i].category;
        memcpy(next.rewards[i].resource_id,selected->rewards[i].resource_id,strlen(selected->rewards[i].resource_id) + 1);
    }
    *out = next;
    return OD_SCHEDULE_OK;
}

const char *od_schedule_status_name(od_schedule_status status) {
    switch (status) {
        case OD_SCHEDULE_OK: return "OK";
        case OD_SCHEDULE_INVALID_ARGUMENT: return "INVALID_ARGUMENT";
        case OD_SCHEDULE_OUT_OF_RANGE: return "OUT_OF_RANGE";
        case OD_SCHEDULE_NOT_ENOUGH_HISTORY: return "NOT_ENOUGH_HISTORY";
        case OD_SCHEDULE_RANDOM_FAILED: return "RANDOM_FAILED";
        case OD_SCHEDULE_POLICY_MISMATCH: return "POLICY_MISMATCH";
        case OD_SCHEDULE_NOT_ACTIVE: return "NOT_ACTIVE";
        case OD_SCHEDULE_ALREADY_SETTLED: return "ALREADY_SETTLED";
        case OD_SCHEDULE_NO_REWARD: return "NO_REWARD";
        case OD_SCHEDULE_OVERFLOW: return "OVERFLOW";
        case OD_SCHEDULE_INSUFFICIENT_STONES: return "INSUFFICIENT_STONES";
        default: return "UNKNOWN";
    }
}
