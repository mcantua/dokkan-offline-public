#ifndef OD_SCHEDULES_STORE_H
#define OD_SCHEDULES_STORE_H

#include "sqlite3.h"
#include "schedules.h"

#ifdef __cplusplus
extern "C" {
#endif

/* Internal trusted-host API only. These are not official game endpoints or client body schemas.
 * Core owns BEGIN IMMEDIATE, command UUID replay, revision, rollback and final COMMIT.
 * The module refuses mutation outside a transaction and never commits independently.
 * Credit receives FINAL amounts, already multiplied once (or unmultiplied material-card draws).
 * Kinds: stone(id0), medal, training, support, equipment, act, and card(master id).
 * The core callback must validate resources, use the same sqlite3 transaction and initialize
 * newly granted owned cards/progression correctly. It must NOT multiply quantities again. */
typedef int (*od_schedule_credit_fn)(void *context, const char *kind, sqlite3_int64 item_id,
                                     sqlite3_int64 final_quantity);
typedef int (*od_schedule_definition_validate_fn)(void *context, const char *settings_document);
typedef int (*od_schedule_definition_grant_fn)(void *context, const char *settings_document,
                                               sqlite3_int64 *owned_instance_id);

const char *od_schedule_store_schema(void); /* CREATE tables, no user_version changes */
const char *od_schedule_store_schema_v2(void); /* additive exclusive registry/ownership schema */
int od_schedule_store_validate(sqlite3 *save, sqlite3 *master,
    od_schedule_definition_validate_fn validate_definition, void *definition_context);
/* 1 exclusive ID exists, 0 absent, -1 invalid/DB failure. Core must reject both 1 and -1
 * when importing a normal Creator definition or installing an ordinary summon entry. */
int od_schedule_store_is_exclusive_id(sqlite3 *save, const char *profile, const char *definition_id);
int od_schedule_store_handles(const char *operation);

/* Return 0 mutation, 1 semantic no-op/replay, -1 failure. Returned JSON uses sqlite3_malloc.
 * Stable error text is static; never includes account data or SQL parameter values.
 * Supported operations: schedule.catalog.install, schedule.rotate, tournament.configure,
 * tournament.snapshot, tournament.enroll_run, tournament.record_run, tournament.claim,
 * elder_kai.configure, elder_kai.draw, tournament.exclusive.register/library.
 * Every clock/config parameter must be host-authoritative.
 * Tournament points are never accepted from clients: enroll an existing started core run during
 * the weekend, then record its persisted clear completion using a pinned map→points policy. */
int od_schedule_store_execute(sqlite3 *save, sqlite3 *master, const char *operation,
    const char *profile, const char *args_json, od_schedule_credit_fn credit, void *credit_context,
    od_summon_random random_bytes, void *random_context,
    od_schedule_definition_validate_fn validate_definition,
    od_schedule_definition_grant_fn grant_definition, void *definition_context,
    char **result_json, const char **error);

#ifdef __cplusplus
}
#endif
#endif
