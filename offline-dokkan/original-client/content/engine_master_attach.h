#ifndef OD_ENGINE_MASTER_ATTACH_H
#define OD_ENGINE_MASTER_ATTACH_H
#include <stddef.h>
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
/* Publish a private working copy of an already-plaintext derived master.
 * The reviewed MAIN relative path is sqlite/current/<language>/database.db.
 * source_fd is read-only. state_dir_fd is the host writable state directory.
 * The published file is mode 0400. This never calls sqlite3_key, never sets
 * cipher pragmas, never enables extension loading, never uses the patcher
 * Documents/assets path, and never writes the engine's cached handle.
 * The engine's own keyed open is not run here.
 * 0 success. -1 argument. -2 source. -3 destination. -4 plaintext verify.
 * resolve_readonly also returns -5 key refused, -6 flags other than readonly
 * refused (including MAIN flags 6), -7 cipher or extension requested, -8
 * patcher path or cached-handle redirect requested.
 * OD_ENGINE_MASTER_OPEN_READONLY is SQLITE_OPEN_READONLY. Pass only that flag.
 */
#define OD_ENGINE_MASTER_OPEN_READONLY 1
typedef struct {
    char relative_path[64];
    int attached;
    int plaintext;
    int source_preserved;
    int source_key_applied;
    int extension_loading_enabled;
    int patcher_path_used;
    int cached_handle_redirected;
    int engine_keyed_open_observed;
    int keyed_open_refused;
    int flags6_refused;
    int readonly_resolved;
} od_engine_master_receipt;
int od_engine_master_attach(int source_fd, int state_dir_fd, const char *state_dir_path,
    const char *language, const char *expected_sha256, uint64_t expected_bytes,
    od_engine_master_receipt *receipt);
/* Re-read the published copy. Never creates or replaces it. */
int od_engine_master_confirm(int source_fd, int state_dir_fd, const char *state_dir_path,
    const char *language, const char *expected_sha256, uint64_t expected_bytes);
/* Open the published copy read-only. key is never read. A key pointer or a
 * nonzero key_length is refused. cipher_requested and extension_requested must
 * be 0. On success *out_fd is O_RDONLY and the caller closes it. */
int od_engine_master_resolve_readonly(int source_fd, int state_dir_fd, const char *state_dir_path,
    const char *language, const char *expected_sha256, uint64_t expected_bytes,
    int requested_sqlite_flags, const void *key, size_t key_length,
    int cipher_requested, int extension_requested, int cached_handle_requested,
    int *out_fd, od_engine_master_receipt *receipt);
/* 0 and *matches 1 only when asset_root's relative master is the published
 * copy and is a different file from source_fd. Does not create files, apply a
 * key, or treat the immutable source as the engine database. Patcher paths
 * return -8. A missing asset-root file returns 0 with *matches 0. */
int od_engine_master_asset_root_matches(int source_fd, int state_dir_fd, const char *state_dir_path,
    int asset_root_fd, const char *asset_root_path, const char *language, int *matches);
#ifdef __cplusplus
}
#endif
#endif
