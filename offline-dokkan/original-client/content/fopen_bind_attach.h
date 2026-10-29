#ifndef OD_FOPEN_BIND_ATTACH_H
#define OD_FOPEN_BIND_ATTACH_H
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#ifdef __cplusplus
extern "C" {
#endif
typedef FILE *(*od_fopen_function)(const char *,const char *);
/* Trusted native loader callbacks, never JS/game/client-supplied callbacks.
 * verify_identity attests the loaded file was hash-verified against the pinned
 * original, or a separately verified root-owned transformation preserving this
 * bind plan. read performs bounded safe memory reads. writable must query live
 * existing VM permissions without changing them. compare_exchange must atomically
 * update only an already-writable aligned pointer, preserving the expected value
 * on mismatch. No callback may mprotect/rebind another image or patch code.
 * All callbacks return0 on success, nonzero on refusal/failure. Pin the image's
 * lifetime and serialize attach/detach with the loader. */
typedef struct {
 void *context;
 int (*verify_identity)(void *,const char *,uintptr_t,intptr_t);
 int (*read)(void *,uintptr_t,void *,size_t);
 int (*writable)(void *,uintptr_t,size_t);
 int (*compare_exchange)(void *,uintptr_t,uintptr_t,uintptr_t);
} od_fopen_bind_host;
enum {
 OD_FOPEN_BIND_OK=0,OD_FOPEN_BIND_INVALID=-1,OD_FOPEN_BIND_IDENTITY=-2,
 OD_FOPEN_BIND_FORMAT=-3,OD_FOPEN_BIND_READ_ONLY=-4,
 OD_FOPEN_BIND_VALUE_CHANGED=-5
};
typedef struct { uintptr_t slot_address,original,replacement;int attached; } od_fopen_binding;
/* This implementation contains one compiled plan for the actual supplied
 * arm64/PTR_64_OFFSET/import-format3 _fopen slot only. It accepts no free-form
 * slot address, RVA, import name or pointer format from a client. */
int od_fopen_bind_attach(const od_fopen_bind_host *host,uintptr_t image_header,
 intptr_t image_slide,od_fopen_function original,od_fopen_function replacement,
 od_fopen_binding *receipt);
int od_fopen_bind_detach(const od_fopen_bind_host *host,uintptr_t image_header,
 intptr_t image_slide,od_fopen_binding *receipt);
#ifdef __cplusplus
}
#endif
#endif
