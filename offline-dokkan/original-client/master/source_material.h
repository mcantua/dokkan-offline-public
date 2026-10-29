#ifndef OD_SPARKING_SOURCE_MATERIAL_H
#define OD_SPARKING_SOURCE_MATERIAL_H
#include <stddef.h>

/* Native-only output. Caller writes permitted scope-specific Keychain items,
 * then calls od_source_material_clear. Never serialize this struct, log it,
 * expose it to JavaScript, or persist it in an ordinary file. */
typedef struct {
 unsigned char sprk_key[32];
 unsigned char database_passphrase[64];
 char source_version[8];
 char library_sha256[65];
} od_source_material;
typedef int (*od_source_sha256)(void *context,const void *bytes,size_t length,char hex[65]);
enum { OD_SOURCE_OK=0,OD_SOURCE_INVALID=-1,OD_SOURCE_UNSUPPORTED=-2,
       OD_SOURCE_MATERIAL_INVALID=-3,OD_SOURCE_HASH_FAILED=-4 };

/* Input is exactly the bounded native-only lib/arm64-v8a/libbase.so member
 * read from the person's original APK. SHA-256 must match the existing Creator
 * SparkingSetup.java public version map before any material is extracted.
 * Callback returns zero on success and writes64lowercase hex digits plusNUL.
 * This helper performs no files, network, ZIP extraction, Keychain or JS calls. */
int od_source_material_derive(const void *library,size_t length,
                              od_source_sha256 hash,void *context,
                              od_source_material *out);
void od_source_material_clear(od_source_material *material);
#endif
