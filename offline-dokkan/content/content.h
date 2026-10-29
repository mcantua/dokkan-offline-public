#ifndef OD_CONTENT_H
#define OD_CONTENT_H
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
typedef struct od_content od_content;
/* Host-selected roots only. cache_root must be a private app directory, distinct
 * from the read-only imported source root. Calls on one instance are serial. */
int od_content_open(const char *source_root, const char *cache_root, od_content **out);
void od_content_close(od_content *content);
const char *od_content_error(const od_content *content);
/* Host supplies the exact manifest reference, not a client-chosen path/hash.
 * Copies verified bytes into a content-addressed private cache, atomically.
 * Returns a read-only descriptor at offset zero; caller closes it. No network,
 * symlink traversal, source modification or silent corrupt-cache replacement. */
int od_content_resolve(od_content *content, const char *relative_path,
                       int64_t expected_bytes, const char *sha256, int *descriptor);
/* Verify complete bytes of a caller-owned O_RDONLY regular-file descriptor.
 * Uses pread, so the caller's offset does not change. No writes, cache mutation
 * or path lookup occurs. Size/type/hash and before/after file identity must
 * match. Returns 0 on success, -1 otherwise. Caller retains/closes descriptor. */
int od_content_verify_readonly_fd(int descriptor,int64_t expected_bytes,
                                 const char *sha256);
/* Checks a complete host-resolved dependency set. Empty/unknown lists fail.
 * This does not discover undocumented game dependencies from a stage ID. */
typedef struct { const char *path; int64_t bytes; const char *sha256; } od_content_ref;
int od_content_require(od_content *content, const od_content_ref *refs, int count);
#ifdef __cplusplus
}
#endif
#endif
