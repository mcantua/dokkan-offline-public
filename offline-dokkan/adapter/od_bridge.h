#ifndef OD_BRIDGE_H
#define OD_BRIDGE_H
#include <stddef.h>
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
typedef struct od_bridge od_bridge;
/* Host-only open/backup paths: never take these from WebView/game messages.
 * Replies/errors are owned strings and must use od_bridge_free. Execution is serialized.
 * The host must stop outstanding work before closing. This is our Creator API, not game HTTP. */
int od_bridge_open(const char *save, const char *master, const char *content,
                   od_bridge **out, char **error);
int od_bridge_execute(od_bridge *, const char *operation, const char *profile,
                      const char *command, const char *args, char **result, char **error);
/* Native policy/evaluator only: never forward arbitrary WebView/game request JSON here.
 * The caller pins verified configuration, resolved rewards/assets and the original clock
 * for an intent and retains those exact arguments across retries. */
int od_bridge_execute_policy(od_bridge *, const char *operation, const char *profile,
                      const char *command, const char *args, char **result, char **error);
int od_bridge_export(od_bridge *, const char *host_destination, char **error);
int od_bridge_import(od_bridge *, const char *host_source, char **error);
/* Native projection worker only. Not operation names in either execution table;
 * never route Creator/WebView-selected JSON to these trusted entry points. */
int od_bridge_projection_snapshot(od_bridge *,const char *profile,char **result,char **error);
int od_bridge_projection_definition(od_bridge *,const char *profile,int64_t generation,
                                    const char *definition_id,int64_t version,char **result,char **error);
int od_bridge_projection_ack(od_bridge *,const char *profile,int64_t generation,
                             const char *persisted_state_json,char **result,char **error);
/* Native original-client protocol snapshot, including persistent own offline
 * identity. No new Creator/WebView-selectable operation is added. */
int od_bridge_offline_player_snapshot(od_bridge *,const char *profile,char **result,char **error);
/* Native original-client writes only. No execution-table/WebView entry. The
 * canonical Core owns scope, expected revision, command retry and transaction. */
int od_bridge_original_client_apply(od_bridge *,const char *operation,const char *profile,
                                    const char *command,const char *expected_save_scope,
                                    int64_t expected_revision,const char *payload_json,
                                    char **result,char **error);
/* Read-only exact prior Finish intent receipt. No execute/replay fallback. */
int od_bridge_creator_finish_receipt(od_bridge *,const char *profile,const char *command,
                                     const char *expected_definition_json,char **result,char **error);
/* Native full-bundle save. Not an operation name. Public creator.finish still
 * rejects a full_bundle descriptor. The bundle bytes are the validator packet. */
int od_bridge_creator_finish_bundle(od_bridge *,const char *profile,const char *command,
                                     const char *definition_json,const void *bundle,size_t bundle_length,
                                     char **result,char **error);
/* Native-only accepted full packet read; exact scope/live-owned-version proof
 * and immutable bytes come from one Core snapshot. No WebView operation. */
int od_bridge_creator_accepted_bundle(od_bridge *,const char *profile,const char *definition_id,
                                       int64_t version,int64_t instance_id,const char *expected_save_scope,
                                       void **packet_bytes,size_t *packet_length,
                                       char **definition_json,char **receipt_json,char **error);
void od_bridge_close(od_bridge *);
void od_bridge_free(void *);
#ifdef __cplusplus
}
#endif
#endif
