#ifndef OD_IPHONE_RESOURCE_PRELOAD_H
#define OD_IPHONE_RESOURCE_PRELOAD_H
#include "iphone_resources.h"
#include <stddef.h>
#ifdef __cplusplus
extern "C" {
#endif

typedef struct od_iphone_resource_preload od_iphone_resource_preload;
typedef struct {
 int readonly_catalog_descriptor;
 int64_t catalog_bytes;
 const char *catalog_sha256;
 const char *manifest_sha256;
 const char *ipa_sha256;
 const char *bundle_id;
 const char *source_root;
 const char *cache_root;
 int attested_asset_root_descriptor;
 int attested_working_boundary_descriptor;
 /* Canonical paths below the native asset root, without assets/ or tutorial0/
    guessing. Native configuration owns the complete requirement list; empty or
    unknown requirements cannot declare startup/content readiness. */
 const char *const *required_asset_relative_paths;
 size_t required_count;
 /* Trusted native scope/currentness check; never a page-supplied boolean.
    Caller owns this context for the preloader lifetime. No concurrent calls. */
 void *context;
 int (*context_is_current)(void *context);
} od_iphone_resource_preload_configuration;

typedef struct {
 size_t configured_required_count;
 size_t verified_alias_count;
 size_t matched_required_count;
 size_t successful_publications;
 size_t newly_published_files;
 size_t existing_verified_files;
 size_t missing_required_count;
 /* -1 until a specific configured publication fails. No private paths leaked. */
 int failed_requirement_index;
 int configured_paths_complete;
 /* Always false: configured publication is not original-client execution,
    decoder verification, complete scene dependency discovery or gameplay. */
 int original_engine_attached;
 int gameplay_verified;
} od_iphone_resource_preload_receipt;

/* Captures/hash-admits exact bytes from an O_RDONLY catalog descriptor into
 * an owned READONLY SQLite memory snapshot; never reopens it by a path. Owns
 * native resource/store handles plus duplicated root/boundary descriptors.
 * Original catalog FD stays caller-owned and its offset is unchanged.
 * All source/cache paths and requirements
 * are trusted native configuration, not WebView arguments. This constructor
 * never creates or publishes resources, installs a hook or launches an engine.
 * Returns 0 success, -1 invalid/incomplete native configuration or admission.
 */
int od_iphone_resource_preload_open(
 const od_iphone_resource_preload_configuration *configuration,
 od_iphone_resource_preload **out);
void od_iphone_resource_preload_close(od_iphone_resource_preload *preload);
const char *od_iphone_resource_preload_error(const od_iphone_resource_preload *preload);
/* Run on the host serial content/preparation queue before loading the original
 * engine. Enumerates exact verified aliases, requires the entire configured
 * path set to be admitted before creating any target, then calls the physical
 * publisher. Existing good files survive retries; any earlier published files
 * also survive a later failure. A native currentness change aborts; the
 * admitted catalog snapshot itself is immutable for this object lifetime.
 * 0 means only these configured paths are durably present. It never grants
 * overall bootstrap/gameplay readiness. Empty/unknown requirement sets fail.
 */
int od_iphone_resource_preload_run(od_iphone_resource_preload *preload,
 od_iphone_resource_preload_receipt *receipt);
#ifdef __cplusplus
}
#endif
#endif
