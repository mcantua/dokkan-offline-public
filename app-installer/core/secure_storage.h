#ifndef AI_SECURE_STORAGE_H
#define AI_SECURE_STORAGE_H
#include <stddef.h>
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
/* Native Keychain bridge. No function presents authentication UI.
 * Root must first authorize AISecureStore's foreground session.
 * Keys must be UTF-8 strings prefixed with engine.; no logging is allowed.
 * read(NULL,0,&length) obtains required bytes without exposing the value.
 */
enum { AI_STORE_OK=0, AI_STORE_MISSING=1, AI_STORE_LOCKED=2,
       AI_STORE_ERROR=3, AI_STORE_BUFFER_SMALL=4 };
int32_t ai_secure_read(const char *key, uint8_t *buffer, size_t capacity, size_t *length);
int32_t ai_secure_write(const char *key, const uint8_t *data, size_t length);
int32_t ai_secure_remove(const char *key);
#ifdef __cplusplus
}
#endif
#endif
