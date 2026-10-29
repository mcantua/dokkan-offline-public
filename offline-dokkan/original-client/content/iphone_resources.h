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
void od_iphone_resources_close(od_iphone_resources *resources);
const char *od_iphone_resources_error(const od_iphone_resources *resources);
/* Only exact previously hash-admitted bundle-relative paths are accepted.
 * E.g. "bgm/bgm_009.acb"; absolute paths, URLs and guessed aliases reject. */
int od_iphone_resources_reference(od_iphone_resources *resources,
 const char *bundle_relative_path,od_asset_reference *reference);
int od_iphone_resources_resolve(od_iphone_resources *resources,
 const char *bundle_relative_path,int *readonly_descriptor);
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
