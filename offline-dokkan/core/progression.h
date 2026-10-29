#ifndef OD_PROGRESSION_H
#define OD_PROGRESSION_H

#include <stdint.h>
#include "summons.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
    OD_PROGRESSION_OK = 0,
    OD_PROGRESSION_INVALID_ARGUMENT,
    OD_PROGRESSION_OVERFLOW,
    OD_PROGRESSION_INELIGIBLE,
    OD_PROGRESSION_ALREADY_APPLIED,
    OD_PROGRESSION_INSUFFICIENT_STONES,
    OD_PROGRESSION_MANUAL_EDIT_FORBIDDEN,
    OD_PROGRESSION_POLICY_REQUIRED
} od_progression_status;

/* Our internal enum tags. The game adapter must resolve its actual reward enums first.
 * XP, Zeni and unspecified categories have no invented multiplier in this module. */
typedef enum { OD_REWARD_ITEM = 1, OD_REWARD_MEDAL, OD_REWARD_DRAGON_STONE } od_reward_category;
typedef enum {
    OD_QUANTITY_REWARD = 1, OD_QUANTITY_COST, OD_QUANTITY_REFUND,
    OD_QUANTITY_IMPORT, OD_QUANTITY_EXISTING_BALANCE, OD_QUANTITY_REPLAY
} od_quantity_origin;

/* Only REWARD applies 3x/6x/10x. All other origins preserve the supplied amount.
 * REPLAY is not authority to grant again: return the already committed command result.
 * Reward application and its ledger key belong in one core transaction. On error *out is unchanged. */
od_progression_status od_progression_amount(od_reward_category category,
    od_quantity_origin origin, int64_t base_quantity, int64_t *out);

typedef enum { OD_UPGRADE_CUSTOM_EZA = 1, OD_UPGRADE_CUSTOM_SUPER_EZA, OD_UPGRADE_ENHANCE } od_upgrade_kind;

typedef struct {
    int official_definition;
    int official_eza;
    int official_super_eza;
    int custom_eza;
    int custom_super_eza;
    /* 0 = not Enhanced. Positive value pins the last applied meta policy, not a game enum. */
    uint64_t enhanced_policy_version;
} od_upgrade_target;

typedef struct {
    od_upgrade_kind kind;
    uint64_t stone_cost;
    int manual_edits_allowed;
    int custom_eza;
    int custom_super_eza;
    uint64_t enhanced_policy_version;
    const char *card_label;
} od_upgrade_plan;

/* Eligibility/cost plan only; caller must calculate/validate the effective new definition
 * with the selected policy, then persist it and the debit atomically. A label alone is not
 * a completed EZA/Enhance. Require a nonzero, increasing policy version for Enhance;
 * custom operations take policy_version=0. Same/older Enhance policies cannot be charged again.
 * Higher policy versions are explicitly chosen by caller, never derived from wall-clock time. */
od_progression_status od_upgrade_make_plan(const od_upgrade_target *target,
    od_upgrade_kind kind, uint64_t policy_version, int manual_edits_requested,
    uint64_t available_stones, od_upgrade_plan *out);

typedef enum { OD_EXCLUSIVE_NONE, OD_EXCLUSIVE_SUPER, OD_EXCLUSIVE_GODLY } od_exclusive_kind;
typedef struct {
    unsigned level;
    unsigned super_attack_level;
    int fully_awakened;
    int hidden_potential_locked;
    unsigned addon_count;
    od_exclusive_kind exclusive_kind;
    int exclusive_always_on;
} od_created_card_defaults;

/* Definition is the fully-awakened form selected by caller, not maxed player progression.
 * Use these values when granting a created card instance, not on every load (which would erase
 * earned progress). Existing Creator bonus definitions supply their effects and stacking order. */
od_progression_status od_created_instance_defaults(od_summon_rarity rarity,
    int definition_fully_awakened, od_created_card_defaults *out);

const char *od_progression_status_name(od_progression_status status);

#ifdef __cplusplus
}
#endif
#endif
