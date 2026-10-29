#ifndef OD_MASTER_ARCHIVE_H
#define OD_MASTER_ARCHIVE_H
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
#define OD_MASTER_ARCHIVE_MAX_SOURCE UINT64_C(4294967295)
#define OD_MASTER_ARCHIVE_MAX_OUTPUT UINT64_C(2147483648)
#define OD_MASTER_ARCHIVE_MAX_ENTRIES 50000
typedef struct {
 uint64_t bytes;
 uint32_t crc32;
 char entry[64];
} od_master_archive_result;
/* Worker-thread helper, links public zlib (-lz). Both descriptors remain owned
 * by the host. Source must be read-only/regular/seekable; output must be a fresh
 * empty, singly-linked private regular staging file, never a published master.
 * game is exactly eclipse or sparking; paths are a fixed allowlist, not input.
 * Source bytes/offset are untouched. On success output is synced/rewound; on
 * failure accepted output is cleared/rewound. Caller removes failed staging
 * files and runs the existing SQLite/schema/SHA importer before publication.
 * No archive resources, encrypted game databases or keys are extracted. */
int od_master_archive_extract(int source_fd, int output_fd, const char *game,
                             od_master_archive_result *result,
                             const char **error);
#ifdef __cplusplus
}
#endif
#endif
