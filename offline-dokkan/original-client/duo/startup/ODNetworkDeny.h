#ifndef OD_NETWORK_DENY_H
#define OD_NETWORK_DENY_H
#ifndef _DARWIN_C_SOURCE
#define _DARWIN_C_SOURCE 1
#endif
#include <sys/socket.h>
#include <netdb.h>
#include <sys/uio.h>
#include <stddef.h>
#ifdef __cplusplus
extern "C" {
#endif
#define OD_NETWORK_EXPORT __attribute__((visibility("default")))
/* Unique aliases have exactly the original import-name byte lengths, allowing
   a separately reviewed pre-signing adapter to redirect explicit imports.
   These strict stubs are not installed/interposed automatically. */
OD_NETWORK_EXPORT int od_cnct(int, const struct sockaddr *, socklen_t);
OD_NETWORK_EXPORT int od_cncxx(int, const sa_endpoints_t *, sae_associd_t, unsigned int,
                              const struct iovec *, unsigned int, size_t *, sae_connid_t *);
OD_NETWORK_EXPORT int od_dns_fail(const char *, const char *, const struct addrinfo *, struct addrinfo **);
OD_NETWORK_EXPORT ssize_t od_s(int, const void *, size_t, int);
OD_NETWORK_EXPORT ssize_t od_snd(int, const void *, size_t, int, const struct sockaddr *, socklen_t);
OD_NETWORK_EXPORT int od_skt(int, int, int);
OD_NETWORK_EXPORT int od_spairxx(int, int, int, int[2]);
#ifdef __cplusplus
}
#endif
#endif
