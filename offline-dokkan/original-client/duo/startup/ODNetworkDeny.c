#include "ODNetworkDeny.h"
#include <errno.h>

static int unavailable(void) { errno=ENETUNREACH; return -1; }
int od_cnct(int fd,const struct sockaddr *address,socklen_t length) {
    (void)fd; (void)address; (void)length; return unavailable();
}
int od_cncxx(int fd,const sa_endpoints_t *endpoints,sae_associd_t association,unsigned int flags,
              const struct iovec *vectors,unsigned int count,size_t *length,sae_connid_t *connection) {
    (void)fd; (void)endpoints; (void)association; (void)flags;
    (void)vectors; (void)count; (void)length; (void)connection; return unavailable();
}
int od_dns_fail(const char *host,const char *service,const struct addrinfo *hints,struct addrinfo **result) {
    (void)host; (void)service; (void)hints;
    if (result) *result=NULL;
    return EAI_FAIL;
}
ssize_t od_s(int fd,const void *bytes,size_t count,int flags) {
    (void)fd; (void)bytes; (void)count; (void)flags; return unavailable();
}
ssize_t od_snd(int fd,const void *bytes,size_t count,int flags,
                 const struct sockaddr *destination,socklen_t length) {
    (void)fd; (void)bytes; (void)count; (void)flags; (void)destination; (void)length;
    return unavailable();
}
int od_skt(int domain,int type,int protocol) {
    (void)domain; (void)type; (void)protocol; return unavailable();
}
int od_spairxx(int domain,int type,int protocol,int descriptors[2]) {
    (void)domain; (void)type; (void)protocol; (void)descriptors;
    /* Deliberately strict. Native IPC may require a separate reviewed policy;
       this export must not be mistaken for a runnable constructor admission. */
    return unavailable();
}

/* Actual public Darwin SDK ABI checks; no manually declared libc prototype. */
_Static_assert(__builtin_types_compatible_p(__typeof__(od_cnct),__typeof__(connect)),"connect ABI");
_Static_assert(__builtin_types_compatible_p(__typeof__(od_cncxx),__typeof__(connectx)),"connectx ABI");
_Static_assert(__builtin_types_compatible_p(__typeof__(od_dns_fail),__typeof__(getaddrinfo)),"getaddrinfo ABI");
_Static_assert(__builtin_types_compatible_p(__typeof__(od_s),__typeof__(send)),"send ABI");
_Static_assert(__builtin_types_compatible_p(__typeof__(od_snd),__typeof__(sendto)),"sendto ABI");
_Static_assert(__builtin_types_compatible_p(__typeof__(od_skt),__typeof__(socket)),"socket ABI");
_Static_assert(__builtin_types_compatible_p(__typeof__(od_spairxx),__typeof__(socketpair)),"socketpair ABI");
