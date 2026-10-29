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
 * This never calls sqlite3_key, never sets cipher pragmas, never enables
 * extension loading, never uses the patcher Documents/assets path, and never
 * writes the engine's cached handle. The engine's own keyed open is not run.
 * 0 success. -1 argument. -2 source. -3 destination. -4 plaintext verify.
 */
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
} od_engine_master_receipt;
int od_engine_master_attach(int source_fd, int state_dir_fd, const char *state_dir_path,
    const char *language, const char *expected_sha256, uint64_t expected_bytes,
    od_engine_master_receipt *receipt);
/* Re-read the published copy. Never creates or replaces it. */
int od_engine_master_confirm(int source_fd, int state_dir_fd, const char *state_dir_path,
    const char *language, const char *expected_sha256, uint64_t expected_bytes);
#ifdef __cplusplus
}
#endif
#endif
