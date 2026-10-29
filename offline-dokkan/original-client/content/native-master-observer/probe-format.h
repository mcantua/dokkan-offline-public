#ifndef OD_NATIVE_MASTER_PROBE_FORMAT_H
#define OD_NATIVE_MASTER_PROBE_FORMAT_H
#include <stddef.h>
#include <stdint.h>
/* INTERNAL runtime-memory layout, NEVER a page/JSON/wire payload. Raw addresses
 * and master paths stay inside the native reader. No key/provider data exists
 * here. The reader must first admit the exact optional derived image recipe. */
enum { ODMasterProbeRecordBytes=2048, ODMasterProbeRecords=16,
       ODMasterProbePathBytes=1024, ODMasterProbePathComplete=1,
       ODMasterProbeWitnessRecordOffset=36864,
       ODMasterProbeWitnessTicketOffset=40960 };
typedef struct {
    unsigned char magic[8]; /* "ODMOBS1\0" */
    uint64_t version;       /* 1 */
    uint64_t ticketCounter;
    uint64_t activeCalls;
    uint64_t overlappingCallsObserved;
    uint64_t observationFault;
    uint64_t latestCompletedTicket;
    uint64_t recordBytes;   /* 2048 */
} ODMasterProbeHeader;
typedef struct {
    uint64_t ticket;
    uint64_t managerAddress;
    uint64_t cacheAtEntry;
    int64_t preferredPathKeyResult; /* -1 if not observed */
    int64_t fallbackPathKeyResult;  /* -1 if not observed */
    int64_t wrapperResult;          /* 0 success,1 cached reuse,16 schema failure */
    uint64_t lastAttempt;           /* 1 preferred,2 fallback,0 unobserved */
    uint64_t pathBytes;
    uint64_t cacheAtReturn;
    uint64_t flags;
    unsigned char resolvedMasterPath[ODMasterProbePathBytes];
    uint64_t completedTicket;
    unsigned char reserved[936];
} ODMasterProbeRecord;
#if defined(__cplusplus)
static_assert(sizeof(ODMasterProbeHeader)==64,"Probe header layout");
static_assert(sizeof(ODMasterProbeRecord)==2048,"Probe record layout");
static_assert(offsetof(ODMasterProbeRecord,completedTicket)==1104,"Probe completion layout");
#else
_Static_assert(sizeof(ODMasterProbeHeader)==64,"Probe header layout");
_Static_assert(sizeof(ODMasterProbeRecord)==2048,"Probe record layout");
_Static_assert(offsetof(ODMasterProbeRecord,completedTicket)==1104,"Probe completion layout");
#endif
#endif
