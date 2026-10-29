#ifndef OD_CREATOR_OVERLAY_READER_H
#define OD_CREATOR_OVERLAY_READER_H
#include <stdint.h>

/* Private native-host API. It does not install an original-engine hook or
 * establish core ownership. Never expose these calls directly to editor JS. */
typedef struct odov_reader odov_reader;
enum { ODOV_OK=0, ODOV_FOUND=1, ODOV_MISSING=2,
       ODOV_INVALID=-1, ODOV_DATABASE=-2, ODOV_IDENTITY=-3,
       ODOV_REVISION=-4, ODOV_BINDING=-5, ODOV_MEMORY=-6 };

/* Opens an existing private sidecar read-only; preserve the host's exact
 * sha256:<64hex>, eclipse:sha256:<64hex> or sparking:sha256:<64hex> identity.
 * Host independently pins source content and private save identity. Serialize
 * access on the same native content/save queue; each read is a short snapshot. */
int odov_open(const char *path,const char *content_id,const char *save_scope_sha256,
              odov_reader **out);
void odov_close(odov_reader *reader);
void odov_free(char *json);

/* Caller obtains generation from od_projection_snapshot, never profiles.revision.
 * version=0 selects the current head; positive version selects a host-pinned
 * run snapshot. Returned row keeps source IDs and is scoped to one owned
 * instance/definition. MISSING does not authorize silent global fallback. */
int odov_row(odov_reader *reader,const char *owned_instance_key,const char *table,
             int64_t source_row_id,int64_t projection_generation,int64_t version,char **json);
int odov_binding(odov_reader *reader,const char *owned_instance_key,
                 int64_t projection_generation,char **json);
/* Read back the exact durably reconciled compact state for od_projection_ack.
 * This is a projection generation, not the ordinary profile revision. */
int odov_projection_state(odov_reader *reader,int64_t projection_generation,char **state_json);
#endif
