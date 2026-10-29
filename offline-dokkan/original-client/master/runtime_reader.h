#ifndef OD_RUNTIME_READER_H
#define OD_RUNTIME_READER_H
#include <stdint.h>
/* Trusted native owner only. Verify/protect the derived file before calling.
 * A returned ID proves a compiled binding, NOT a loaded engine/resource contract.
 * The authoritative core still proves ownership/version and progression.
 * 0 success; -1 argument, -2 open/read, -3 scope/content, -4 binding mismatch.
 */
int od_runtime_card_id(const char *path, const char *content_id,
                      const char *save_scope_sha256,
                      const char *definition_id, int64_t version,
                      const char *project_sha256, const char *definition_sha256,
                      int64_t *runtime_card_id);
#endif
