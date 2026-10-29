#include "progression.h"

#include <limits.h>
#include <string.h>

static int boolean_value(int value) { return value == 0 || value == 1; }

od_progression_status od_progression_amount(od_reward_category category,
    od_quantity_origin origin, int64_t base_quantity, int64_t *out) {
    int64_t multiplier;
    if (!out || base_quantity < 0 || origin < OD_QUANTITY_REWARD || origin > OD_QUANTITY_REPLAY)
        return OD_PROGRESSION_INVALID_ARGUMENT;
    switch (category) {
        case OD_REWARD_ITEM: multiplier = 3; break;
        case OD_REWARD_MEDAL: multiplier = 6; break;
        case OD_REWARD_DRAGON_STONE: multiplier = 10; break;
        default: return OD_PROGRESSION_INVALID_ARGUMENT;
    }
    if (origin != OD_QUANTITY_REWARD) multiplier = 1;
    if (base_quantity > INT64_MAX / multiplier) return OD_PROGRESSION_OVERFLOW;
    *out = base_quantity * multiplier;
    return OD_PROGRESSION_OK;
}

od_progression_status od_upgrade_make_plan(const od_upgrade_target *target,
    od_upgrade_kind kind, uint64_t policy_version, int manual_edits_requested,
    uint64_t available_stones, od_upgrade_plan *out) {
    od_upgrade_plan next;
    if (!target || !out || !boolean_value(target->official_definition) ||
        !boolean_value(target->official_eza) || !boolean_value(target->official_super_eza) ||
        !boolean_value(target->custom_eza) || !boolean_value(target->custom_super_eza) ||
        !boolean_value(manual_edits_requested)) return OD_PROGRESSION_INVALID_ARGUMENT;
    if (!target->official_definition) return OD_PROGRESSION_INELIGIBLE;
    memset(&next, 0, sizeof(next));
    next.kind = kind;
    next.custom_eza = target->custom_eza;
    next.custom_super_eza = target->custom_super_eza;
    next.enhanced_policy_version = target->enhanced_policy_version;
    next.manual_edits_allowed = target->enhanced_policy_version == 0;
    switch (kind) {
        case OD_UPGRADE_CUSTOM_EZA:
            if (policy_version) return OD_PROGRESSION_INVALID_ARGUMENT;
            if (target->official_eza || target->official_super_eza) return OD_PROGRESSION_INELIGIBLE;
            if (target->custom_eza) return OD_PROGRESSION_ALREADY_APPLIED;
            next.stone_cost = 500;
            next.custom_eza = 1;
            next.card_label = "Custom EZA";
            break;
        case OD_UPGRADE_CUSTOM_SUPER_EZA:
            if (policy_version) return OD_PROGRESSION_INVALID_ARGUMENT;
            if (target->official_super_eza) return OD_PROGRESSION_INELIGIBLE;
            if (target->custom_super_eza) return OD_PROGRESSION_ALREADY_APPLIED;
            next.stone_cost = 700;
            next.custom_super_eza = 1;
            next.card_label = "Custom Super EZA";
            break;
        case OD_UPGRADE_ENHANCE:
            if (!target->official_eza && !target->official_super_eza) return OD_PROGRESSION_INELIGIBLE;
            if (!policy_version) return OD_PROGRESSION_POLICY_REQUIRED;
            if (policy_version <= target->enhanced_policy_version) return OD_PROGRESSION_ALREADY_APPLIED;
            next.stone_cost = 300;
            next.enhanced_policy_version = policy_version;
            next.manual_edits_allowed = 0;
            next.card_label = "Enhanced";
            break;
        default: return OD_PROGRESSION_INVALID_ARGUMENT;
    }
    if (manual_edits_requested && !next.manual_edits_allowed) return OD_PROGRESSION_MANUAL_EDIT_FORBIDDEN;
    if (available_stones < next.stone_cost) return OD_PROGRESSION_INSUFFICIENT_STONES;
    *out = next;
    return OD_PROGRESSION_OK;
}

od_progression_status od_created_instance_defaults(od_summon_rarity rarity,
    int definition_fully_awakened, od_created_card_defaults *out) {
    od_created_card_defaults next;
    if (!out || (unsigned)rarity > OD_RARITY_GR || !boolean_value(definition_fully_awakened))
        return OD_PROGRESSION_INVALID_ARGUMENT;
    if (!definition_fully_awakened) return OD_PROGRESSION_INELIGIBLE;
    memset(&next, 0, sizeof(next));
    next.level = 1;
    next.super_attack_level = 1;
    next.fully_awakened = 1;
    next.hidden_potential_locked = 1;
    if (rarity == OD_RARITY_SLR) next.exclusive_kind = OD_EXCLUSIVE_SUPER;
    if (rarity == OD_RARITY_GR) next.exclusive_kind = OD_EXCLUSIVE_GODLY;
    next.exclusive_always_on = next.exclusive_kind != OD_EXCLUSIVE_NONE;
    *out = next;
    return OD_PROGRESSION_OK;
}

const char *od_progression_status_name(od_progression_status status) {
    switch (status) {
        case OD_PROGRESSION_OK: return "OK";
        case OD_PROGRESSION_INVALID_ARGUMENT: return "INVALID_ARGUMENT";
        case OD_PROGRESSION_OVERFLOW: return "OVERFLOW";
        case OD_PROGRESSION_INELIGIBLE: return "INELIGIBLE";
        case OD_PROGRESSION_ALREADY_APPLIED: return "ALREADY_APPLIED";
        case OD_PROGRESSION_INSUFFICIENT_STONES: return "INSUFFICIENT_STONES";
        case OD_PROGRESSION_MANUAL_EDIT_FORBIDDEN: return "MANUAL_EDIT_FORBIDDEN";
        case OD_PROGRESSION_POLICY_REQUIRED: return "POLICY_REQUIRED";
        default: return "UNKNOWN";
    }
}
