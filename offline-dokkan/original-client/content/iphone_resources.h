#ifndef OD_IPHONE_RESOURCES_H
#define OD_IPHONE_RESOURCES_H
#include "../../content/asset_catalog.h"
#include <stdio.h>
#ifdef __cplusplus
extern "C" {
#endif
typedef struct od_iphone_resources od_iphone_resources;
/* The host must first verify the immutable private catalog's complete SHA-256.
 * Metadata identity checks alone do not authenticate catalog bytes.
 * Roots are explicit host-selected local directories; no mount, search-path
 * rewrite, source login or network fallback occurs. Use a serial content queue. */
int od_iphone_resources_open(const char *verified_catalog,
 const char *manifest_sha256,const char *ipa_sha256,const char *bundle_id,
 const char *source_root,const char *cache_root,od_iphone_resources **out);
/* FD-only alternative for composition: captures at most128MiB from an
 * O_RDONLY regular catalog descriptor with pread, checks exact captured SHA and
 * before/after identity/size/mtime, then deserializes that exact memory snapshot
 * READONLY. Never reopens the catalog by path or /dev/fd. The caller's offset
 * and source file stay unchanged. Expected manifest/IPA/bundle checks remain.
 * Uses the pinned SQLite3.50.4 with deserialize present and extensions omitted.
 */
int od_iphone_resources_open_catalog_fd(int readonly_catalog_descriptor,
 int64_t catalog_bytes,const char *catalog_sha256,const char *manifest_sha256,
 const char *ipa_sha256,const char *bundle_id,const char *source_root,
 const char *cache_root,od_iphone_resources **out);
void od_iphone_resources_close(od_iphone_resources *resources);
const char *od_iphone_resources_error(const od_iphone_resources *resources);
/* Only exact previously hash-admitted bundle-relative paths are accepted.
 * E.g. "bgm/bgm_009.acb"; absolute paths, URLs and guessed aliases reject. */
int od_iphone_resources_reference(od_iphone_resources *resources,
 const char *bundle_relative_path,od_asset_reference *reference);
int od_iphone_resources_resolve(od_iphone_resources *resources,
 const char *bundle_relative_path,int *readonly_descriptor);
/* Canonical resource-root lookup, e.g. "bgm/bgm_009.acb" below a native
 * assets root. The catalog must name both the canonical assets/... record and
 * its exact verified preferred IPA alias. No guessed tutorial-prefix stripping
 * or merely Android-cataloged resource is admitted. */
int od_iphone_resources_asset_reference(od_iphone_resources *resources,
 const char *asset_relative_path,od_asset_reference *reference);
/* Readonly enumeration of at most 20,000 exact verified bundle aliases.
 * Every row passes the same alias-to-canonical/hash-reference validation as
 * single lookup. Visitor arguments live only for that callback; return 0 to
 * continue. Abort, malformed catalog and an unadmitted catalog alias have
 * distinct fixed errors. No missing row is silently skipped. Calls are serial;
 * visitor must not close resources or reenter enumeration. */
typedef int (*od_iphone_resource_alias_visitor)(const char *bundle_relative_path,
 const od_asset_reference *reference,void *context);
int od_iphone_resources_visit_aliases(od_iphone_resources *resources,
 od_iphone_resource_alias_visitor visitor,void *context);
/* Physically publish one admitted canonical resource beneath an attested
 * native assets-root directory descriptor, for Foundation existence queries
 * and normal libc reads. Root ownership/path attestation is the host's job;
 * it must be the actual native working root. The separate working-boundary FD
 * must attest an own-app directory that contains that root (for example, native
 * Documents). A bounded parent-FD walk ends only at that exact boundary and
 * rejects import/cache roots, their descendants, premature filesystem-root
 * termination, depth exhaustion and failed traversal before child creation.
 * It never needs to walk outside the attested app namespace. Child traversal
 * cannot enter protected roots. Both root and boundary FDs are O_RDONLY dirs;
 * the host retains/attests them and no page/request can choose either FD.
 * Never creates/replaces the root, overwrites an existing file, imports an
 * unadmitted path, publishes a master/key/save, or invents existence results.
 * Creates missing child directories safely; new file is hash-readback-verified,
 * mode 0400 and atomically linked without replacement. Existing matching
 * readonly bytes verify idempotently; conflicting/writable/symlink paths reject.
 * Returns 0 only after directory fsync. *newly_published is set when this call
 * links the final file, including a later durability error; retry the same path.
 * Use on the host's serial content queue, not the main render thread. */
int od_iphone_resources_publish_asset(od_iphone_resources *resources,
 int attested_asset_root_descriptor,int attested_working_boundary_descriptor,
 const char *asset_relative_path,int *newly_published);
/* Separate adapter for the actual native resource root (not the .app bundle).
 * The trusted native host supplies/attests that absolute root; this function
 * never guesses it from Documents, a bundle, a source folder or a request.
 * Only exact root-relative, canonical+IPA-admitted read requests resolve through
 * verified cache descriptors. Unknown paths/write modes preserve original libc;
 * malformed admitted metadata or missing/corrupt admitted content fail closed.
 * This does not install a hook or change the original resource search order. */
FILE *od_iphone_resources_fopen_asset_root(od_iphone_resources *resources,
 const char *actual_asset_root,const char *path,const char *mode,
 FILE *(*original_fopen)(const char *,const char *));
/* ABI-compatible libc read adapter for a separately verified import hook.
 * actual_bundle_root is the host-resolved absolute original .app directory.
 * Read-only requests for exact admitted paths use the verified cache; other
 * requests preserve original libc behavior. A corrupt/missing admitted cache
 * fails closed. This function does not install/rebind any import slot itself.
 * original_fopen must be the preserved libc implementation, never this adapter. */
FILE *od_iphone_resources_fopen(od_iphone_resources *resources,
 const char *actual_bundle_root,const char *path,const char *mode,
 FILE *(*original_fopen)(const char *,const char *));
#ifdef __cplusplus
}
#endif
#endif
