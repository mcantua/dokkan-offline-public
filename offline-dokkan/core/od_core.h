#ifndef OD_CORE_H
#define OD_CORE_H
#include <stddef.h>
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
typedef struct od_core od_core;
/* Internal trusted domain API, not the game's HTTP protocol. Master is always read-only.
 * content_id must identify the exact imported master version (normally its SHA-256).
 * All returned strings use od_free. A core instance must be called serially.
 * Current save schema is v13; validated v1..v12 saves migrate transactionally. */
int od_open(const char *save_path, const char *master_path, const char *content_id, od_core **out);
void od_close(od_core *core);
const char *od_last_error(od_core *core);
int od_execute(od_core *core, const char *operation, const char *profile_id,
               const char *command_id, const char *args_json, char **result_json);
/* Ordinary clocked intents exclude now_utc and all policy/reward/config values.
 * Original args/operation are compared and cached before the trusted time is injected only
 * for a new transaction. Same-ID retries never acquire a different execution clock. */
int od_execute_clocked(od_core *core, const char *operation, const char *profile_id,
               const char *command_id, const char *original_args_json,
               int64_t host_now_utc, char **result_json);
int od_export_save(od_core *core, const char *destination);
int od_import_save(od_core *core, const char *source);
/* Trusted native projection outbox API, deliberately outside od_execute and
 * all WebView operation allowlists. Projection generation changes only when
 * Creator definitions/owned bindings change; it is NOT profiles.revision.
 * Snapshot has {generation,applied_generation,state}. State pins exact content,
 * private save identity, profile, definition versions and owned instances.
 * Fetch documents for that generation, durably reconcile the private sidecar,
 * read its exact persisted state back, then ack. Stale generation/state fails.
 * Same-generation acknowledgements are idempotent; no gameplay state changes. */
int od_projection_snapshot(od_core *core,const char *profile,char **result_json);
int od_projection_definition(od_core *core,const char *profile,int64_t generation,
                              const char *definition_id,int64_t version,char **result_json);
int od_projection_ack(od_core *core,const char *profile,int64_t generation,
                       const char *persisted_state_json,char **result_json);
/* Read own native-provisioned local wire identity or the coherent own-player
 * snapshot with wire_identity. No supplied ID/name, account import, provision
 * operation or second SQLite connection; all JSON uses od_free. */
int od_offline_identity(od_core *core,const char *profile,char **result_json);
int od_offline_player_snapshot(od_core *core,const char *profile,char **result_json);
/* Original-client native authority only, never od_execute/WebView operation
 * names. operation is tutorial.progress or teams.apply; payload is normalized
 * by the admitted own-client adapter, not raw arbitrary HTTP/policy JSON.
 * Scope is checked inside the same write transaction before command replay;
 * expected_revision is required for a new command. Exact command retries
 * preserve their retained result. No starter units, rewards, finished tutorial
 * flag, contents-level default or HTTP response is created by this API. */
int od_original_client_apply(od_core *core,const char *operation,const char *profile,
                              const char *command,const char *expected_save_scope,
                              int64_t expected_revision,const char *payload_json,
                              char **result_json);
/* Read-only interrupted native accepted-project recovery. Exact profile/command
 * must already cache creator.finish with input {definition:expected}; returns
 * that existing result unchanged. Missing/pruned receipts remain unresolved.
 * Never executes or replays Finish; deliberately not an od_execute operation. */
int od_creator_finish_receipt(od_core *core,const char *profile,const char *command,
                              const char *expected_definition_json,char **result_json);
/* Native-only full Creator acceptance after complete scoped bundle validation.
 * bundle_bytes is the exact validator packet. Its SHA-256 must match the
 * definition's full_bundle binding before the save transaction starts.
 * Public creator.import and creator.finish still reject that descriptor.
 * No WebView operation and no original-engine attachment are added here. */
int od_creator_finish_bundle(od_core *core,const char *profile,const char *command,
                              const char *definition_json,const void *bundle_bytes,
                              size_t bundle_length,char **result_json);
/* Native immutable packet retrieval, deliberately not an od_execute operation.
 * The read transaction verifies this save/content scope and a live, unconsumed
 * owned instance at the requested active definition version. It returns exact
 * durable packet/definition bytes and a snapshot receipt with profile revision
 * and projection generation. Every allocation uses od_free; packet_length is
 * explicit. A migrated descriptor without bytes fails recoverably, never
 * reconstructs a guessed packet or grants another owned copy. */
int od_creator_accepted_bundle(od_core *core,const char *profile,const char *definition_id,
                              int64_t version,int64_t instance_id,const char *expected_save_scope,
                              void **packet_bytes,size_t *packet_length,
                              char **definition_json,char **receipt_json);
void od_free(void *memory);
#ifdef __cplusplus
}
#endif
#endif
