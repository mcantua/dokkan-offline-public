#ifndef OD_ORIGINAL_TEAMS_H
#define OD_ORIGINAL_TEAMS_H
#include <sqlite3.h>
#ifdef __cplusplus
extern "C" {
#endif
/* Own storage budgets, not claimed original-game UI limits. */
#define OD_ORIGINAL_TEAM_METADATA_BYTES 4096
#define OD_ORIGINAL_TEAM_APPLY_BYTES (256 * 1024)
#define OD_ORIGINAL_TEAM_REFERENCE_BYTES (32 * 1024)
#define OD_ORIGINAL_TEAM_REFERENCE_IDS 1024
/* Execute only inside the canonical Core's existing migration transaction. */
const char *od_original_teams_schema_sql(void);
/* Full persisted ownership/layout/selection invariant. 1 valid, 0 invalid. */
int od_original_teams_validate(sqlite3 *db);
const char *od_original_teams_validation_sql(void);
const char *od_original_teams_reference_validation_sql(void);
const char *od_original_teams_context_validation_sql(void);
/* JSON property value for player_snapshot.original_client_teams. The caller
 * keeps this inside the same canonical snapshot transaction/revision. */
int od_original_teams_snapshot(sqlite3 *db,const char *profile,char **json,char **error);
/* Native-only normalized own-client update. Caller must hold its existing
 * write transaction and own command-id/revision advancement. This function
 * checks expected_revision, atomically updates layouts + canonical members,
 * and never grants cards. It does not commit the caller's transaction.
 * Returns 0 success / -1 failure; output strings use sqlite3_free(). */
int od_original_teams_apply(sqlite3 *db,const char *profile,
    sqlite3_int64 expected_revision,const char *json,char **error);
#ifdef __cplusplus
}
#endif
#endif
