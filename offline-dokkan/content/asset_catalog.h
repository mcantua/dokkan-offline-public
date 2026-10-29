#ifndef OD_ASSET_CATALOG_H
#define OD_ASSET_CATALOG_H
#include "content.h"
#ifdef __cplusplus
extern "C" {
#endif
typedef struct od_asset_catalog od_asset_catalog;
typedef struct { char path[1025]; int64_t bytes; char sha256[65]; } od_asset_reference;
/* Host supplies an already checksum-verified, immutable private catalog copy.
 * Expected manifest identity is host-pinned, not chosen by a game/web request.
 * Metadata matching alone does not authenticate the catalog's bytes.
 * Calls sharing content/catalog handles use the host's serial content queue. */
int od_asset_catalog_open(const char *verified_catalog, const char *manifest_sha256,
                          od_asset_catalog **out);
void od_asset_catalog_close(od_asset_catalog *catalog);
const char *od_asset_catalog_error(const od_asset_catalog *catalog);
int od_asset_catalog_reference(od_asset_catalog *catalog, const char *path,
                               od_asset_reference *out);
/* Actual byte verification and read-only FD delivery use the existing resolver.
 * No downloads, account/player state, key material or network fallback. */
int od_asset_catalog_resolve(od_asset_catalog *catalog, od_content *content,
                             const char *path, int *descriptor);
#ifdef __cplusplus
}
#endif
#endif
