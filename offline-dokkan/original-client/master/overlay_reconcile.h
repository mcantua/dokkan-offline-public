#ifndef OD_CREATOR_OVERLAY_RECONCILE_H
#define OD_CREATOR_OVERLAY_RECONCILE_H
#include "overlay_reader.h"
#include <stddef.h>

/* These callbacks belong to the native save owner and execute synchronously on
 * its existing serial queue. Profile is captured in context, not selectable by
 * a web page. JSON callbacks return owned strings released with release_json. */
typedef struct {
 void *context;
 int (*snapshot)(void *context,char **json);
 int (*definition)(void *context,int64_t generation,const char *definition_id,
                    int64_t version,char **json);
 int (*ack)(void *context,int64_t generation,const char *persisted_state,char **json);
 void (*release_json)(void *context,char *json);
 /* Ordinary SHA-256 only, no key. Write 64 lowercase hex digits plus NUL.
  * Like the JSON callbacks, return zero on success and negative on failure. */
 int (*sha256)(void *context,const void *bytes,size_t length,char hex[65]);
} odov_projection_host;

enum { ODOV_HOST=-7, ODOV_UNSUPPORTED=-8, ODOV_CONFLICT=-9 };

/* Host pins the same immutable selected master/content used by its core. Scope
 * is SHA256(compact ASCII JSON [save_identity,profile_id,content_id]). Callback
 * SHA256 is also used for persisted document serialization, not universal JSON
 * canonicalization. Existing immutable versions compare JSON semantically.
 *
 * Workflow: snapshot -> exact-generation definitions -> source admission ->
 * sidecar FULL commit -> native readback -> core ack. An ack failure leaves the
 * core intent pending; the next call reconciles its latest generation. Receipt
 * uses odov_free. This does not attach an original-engine hook.
 */
int odov_reconcile(const char *sidecar_path,const char *readonly_master_path,
                   const char *expected_content_id,const char *save_scope_sha256,
                   const odov_projection_host *host,char **ack_receipt_json);
#endif
