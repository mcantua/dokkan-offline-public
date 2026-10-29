#ifndef OD_CREATOR_APK_LIBBASE_H
#define OD_CREATOR_APK_LIBBASE_H
#include <stddef.h>
#include <stdint.h>
/* Extracts only lib/arm64-v8a/libbase.so from an already source-hash-admitted
 * APK memory mapping. No other member content is read or emitted. Caller owns
 * and must clear/free the returned native-only buffer after material admission. */
int od_creator_apk_libbase(const void *apk,size_t apk_bytes,void **library,size_t *library_bytes);
void od_creator_apk_library_clear(void *library,size_t bytes);
#endif
