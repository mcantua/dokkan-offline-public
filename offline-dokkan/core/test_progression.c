/* New progression policy checks only; no summons/core suite rerun. */
#include "progression.h"
#include <assert.h>
#include <limits.h>
#include <stdio.h>
#include <string.h>

static void quantities(void) {
    const int64_t factors[] = {3, 6, 10};
    int cat, origin;
    for (cat = OD_REWARD_ITEM; cat <= OD_REWARD_DRAGON_STONE; cat++) {
        int64_t out = 777, factor = factors[cat - 1];
        assert(od_progression_amount((od_reward_category)cat, OD_QUANTITY_REWARD, 7, &out) == OD_PROGRESSION_OK);
        assert(out == 7 * factor);
        assert(od_progression_amount((od_reward_category)cat, OD_QUANTITY_REWARD, 0, &out) == OD_PROGRESSION_OK && out == 0);
        assert(od_progression_amount((od_reward_category)cat, OD_QUANTITY_REWARD, INT64_MAX / factor, &out) == OD_PROGRESSION_OK);
        assert(out == (INT64_MAX / factor) * factor);
        out = 777;
        assert(od_progression_amount((od_reward_category)cat, OD_QUANTITY_REWARD, INT64_MAX / factor + 1, &out) == OD_PROGRESSION_OVERFLOW);
        assert(out == 777);
        for (origin = OD_QUANTITY_COST; origin <= OD_QUANTITY_REPLAY; origin++) {
            assert(od_progression_amount((od_reward_category)cat, (od_quantity_origin)origin, INT64_MAX, &out) == OD_PROGRESSION_OK);
            assert(out == INT64_MAX);
        }
    }
    {
        int64_t out = 777;
        assert(od_progression_amount((od_reward_category)0, OD_QUANTITY_REWARD, 1, &out) == OD_PROGRESSION_INVALID_ARGUMENT);
        assert(out == 777);
        assert(od_progression_amount(OD_REWARD_ITEM, (od_quantity_origin)0, 1, &out) == OD_PROGRESSION_INVALID_ARGUMENT);
        assert(od_progression_amount(OD_REWARD_ITEM, OD_QUANTITY_REWARD, -1, &out) == OD_PROGRESSION_INVALID_ARGUMENT);
        assert(od_progression_amount(OD_REWARD_ITEM, OD_QUANTITY_REWARD, 1, NULL) == OD_PROGRESSION_INVALID_ARGUMENT);
        assert(out == 777);
    }
}

static void upgrades(void) {
    od_upgrade_target target = {1,0,0,0,0,0};
    od_upgrade_plan plan, before;
    assert(od_upgrade_make_plan(&target, OD_UPGRADE_CUSTOM_EZA, 0, 1, 500, &plan) == OD_PROGRESSION_OK);
    assert(plan.stone_cost == 500 && plan.custom_eza && plan.manual_edits_allowed && !strcmp(plan.card_label, "Custom EZA"));
    before = plan;
    assert(od_upgrade_make_plan(&target, OD_UPGRADE_CUSTOM_EZA, 0, 1, 499, &plan) == OD_PROGRESSION_INSUFFICIENT_STONES);
    assert(memcmp(&before, &plan, sizeof(plan)) == 0);
    target.custom_eza = 1;
    assert(od_upgrade_make_plan(&target, OD_UPGRADE_CUSTOM_EZA, 0, 0, 1000, &plan) == OD_PROGRESSION_ALREADY_APPLIED);
    target.custom_eza = 0;
    assert(od_upgrade_make_plan(&target, OD_UPGRADE_CUSTOM_SUPER_EZA, 0, 1, 700, &plan) == OD_PROGRESSION_OK);
    assert(plan.stone_cost == 700 && plan.custom_super_eza && !strcmp(plan.card_label, "Custom Super EZA"));
    assert(od_upgrade_make_plan(&target, OD_UPGRADE_CUSTOM_SUPER_EZA, 0, 0, 699, &plan) == OD_PROGRESSION_INSUFFICIENT_STONES);
    target.custom_super_eza = 1;
    assert(od_upgrade_make_plan(&target, OD_UPGRADE_CUSTOM_SUPER_EZA, 0, 0, 1000, &plan) == OD_PROGRESSION_ALREADY_APPLIED);
    target.custom_super_eza = 0;
    target.official_eza = 1;
    assert(od_upgrade_make_plan(&target, OD_UPGRADE_CUSTOM_EZA, 0, 0, 1000, &plan) == OD_PROGRESSION_INELIGIBLE);
    assert(od_upgrade_make_plan(&target, OD_UPGRADE_ENHANCE, 0, 0, 300, &plan) == OD_PROGRESSION_POLICY_REQUIRED);
    assert(od_upgrade_make_plan(&target, OD_UPGRADE_ENHANCE, 4, 1, 300, &plan) == OD_PROGRESSION_MANUAL_EDIT_FORBIDDEN);
    assert(od_upgrade_make_plan(&target, OD_UPGRADE_ENHANCE, 4, 0, 299, &plan) == OD_PROGRESSION_INSUFFICIENT_STONES);
    assert(od_upgrade_make_plan(&target, OD_UPGRADE_ENHANCE, 4, 0, 300, &plan) == OD_PROGRESSION_OK);
    assert(plan.stone_cost == 300 && !plan.manual_edits_allowed && plan.enhanced_policy_version == 4 && !strcmp(plan.card_label, "Enhanced"));
    target.enhanced_policy_version = 4;
    assert(od_upgrade_make_plan(&target, OD_UPGRADE_ENHANCE, 4, 0, 300, &plan) == OD_PROGRESSION_ALREADY_APPLIED);
    assert(od_upgrade_make_plan(&target, OD_UPGRADE_ENHANCE, 3, 0, 300, &plan) == OD_PROGRESSION_ALREADY_APPLIED);
    assert(od_upgrade_make_plan(&target, OD_UPGRADE_ENHANCE, 5, 0, 300, &plan) == OD_PROGRESSION_OK);
    assert(plan.enhanced_policy_version == 5);
    target.official_super_eza = 1;
    assert(od_upgrade_make_plan(&target, OD_UPGRADE_CUSTOM_SUPER_EZA, 0, 0, 1000, &plan) == OD_PROGRESSION_INELIGIBLE);
    target.official_eza = target.official_super_eza = 0;
    target.enhanced_policy_version = 0;
    assert(od_upgrade_make_plan(&target, OD_UPGRADE_ENHANCE, 1, 0, 300, &plan) == OD_PROGRESSION_INELIGIBLE);
    target.official_definition = 0;
    assert(od_upgrade_make_plan(&target, OD_UPGRADE_CUSTOM_EZA, 0, 0, 1000, &plan) == OD_PROGRESSION_INELIGIBLE);
    assert(od_upgrade_make_plan(&target, OD_UPGRADE_CUSTOM_SUPER_EZA, 0, 0, 1000, &plan) == OD_PROGRESSION_INELIGIBLE);
}

static void created_defaults(void) {
    int rarity;
    od_created_card_defaults d, before;
    for (rarity = OD_RARITY_N; rarity <= OD_RARITY_GR; rarity++) {
        assert(od_created_instance_defaults((od_summon_rarity)rarity, 1, &d) == OD_PROGRESSION_OK);
        assert(d.level == 1 && d.super_attack_level == 1 && d.fully_awakened);
        assert(d.hidden_potential_locked && d.addon_count == 0);
        if (rarity == OD_RARITY_SLR) assert(d.exclusive_kind == OD_EXCLUSIVE_SUPER && d.exclusive_always_on);
        else if (rarity == OD_RARITY_GR) assert(d.exclusive_kind == OD_EXCLUSIVE_GODLY && d.exclusive_always_on);
        else assert(d.exclusive_kind == OD_EXCLUSIVE_NONE && !d.exclusive_always_on);
    }
    before = d;
    assert(od_created_instance_defaults(OD_RARITY_GR, 0, &d) == OD_PROGRESSION_INELIGIBLE);
    assert(od_created_instance_defaults((od_summon_rarity)-1, 1, &d) == OD_PROGRESSION_INVALID_ARGUMENT);
    assert(memcmp(&before, &d, sizeof(d)) == 0);
}

int main(void) {
    quantities();
    upgrades();
    created_defaults();
    puts("PASS progression: exclusive 3/6/10 rewards, signed-64 overflow and non-reward identity, 500/700/300 eligibility/debits, Enhanced editing/version guards, created-card defaults and always-on exclusive flags");
    return 0;
}
