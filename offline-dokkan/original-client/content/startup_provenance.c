#ifndef _POSIX_C_SOURCE
#define _POSIX_C_SOURCE 200809L
#endif
#ifdef __APPLE__
#ifndef _DARWIN_C_SOURCE
#define _DARWIN_C_SOURCE 1
#endif
#endif
#include "startup_provenance.h"
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdint.h>
#include <string.h>
#include <errno.h>

static const char marker_name[] = "native-startup-provenance-v1.bin";
static const char temporary_name[] = ".native-startup-provenance-v1.pending";
typedef struct {
    char contract[352];
    uint64_t documents_device, documents_inode;
    uint64_t assets_device, assets_inode;
    uint64_t state_device, state_inode;
} od_startup_marker;

static int expected_marker(int state, int documents, int assets, od_startup_marker *out) {
    struct stat s,d,a;
    if(fstat(state,&s)||fstat(documents,&d)||fstat(assets,&a)||
       !S_ISDIR(s.st_mode)||!S_ISDIR(d.st_mode)||!S_ISDIR(a.st_mode)||
       s.st_uid!=geteuid()||d.st_uid!=geteuid()||a.st_uid!=geteuid())return -1;
    memset(out,0,sizeof *out);
    /* Content identities, not user configuration or a claim of native DB
     * acceptance. Core bytes are independently re-admitted by the factory. */
    static const char contract[] =
        "OD-OWN-STARTUP-1\norg.offlinedokkan.duo\n"
        "efaabfc9b3cdb0e2eeb550b6ea616f5eeb565c6584ad838b765f34539648d222\n"
        "a45b7c9f308e6d07452fd07ac2eeea28981be034554a73e35094552ba9163384\n"
        "2196f85c0d09e41967d6b0c08a1860fe57037c1f172cd8c048e9cad70f0f5a33\n"
        "1a8f5a823a6efa7343ff463b92197a574898e03569e2067f3daf8a4f282be4f4\n";
    _Static_assert(sizeof contract<=sizeof out->contract,"Fixed provenance contract fits");
    memcpy(out->contract,contract,sizeof contract);
    out->documents_device=(uint64_t)d.st_dev;out->documents_inode=(uint64_t)d.st_ino;
    out->assets_device=(uint64_t)a.st_dev;out->assets_inode=(uint64_t)a.st_ino;
    out->state_device=(uint64_t)s.st_dev;out->state_inode=(uint64_t)s.st_ino;
    return 0;
}

int od_startup_provenance_read(int state, int documents, int assets) {
    od_startup_marker expected,actual;
    if(expected_marker(state,documents,assets,&expected))return -1;
    int fd=openat(state,marker_name,O_RDONLY|O_NOFOLLOW|O_CLOEXEC|O_NONBLOCK);
    if(fd<0)return errno==ENOENT?0:-1;
    struct stat before,after,named;size_t done=0;
    int valid=!fstat(fd,&before)&&S_ISREG(before.st_mode)&&before.st_uid==geteuid()&&
        (before.st_mode&07777)==0600&&before.st_nlink==1&&before.st_size==(off_t)sizeof actual;
    while(valid&&done<sizeof actual){
        ssize_t count=pread(fd,(char *)&actual+done,sizeof actual-done,(off_t)done);
        if(count<0&&errno==EINTR)continue;
        if(count<=0){valid=0;break;}done+=(size_t)count;
    }
    valid=valid&&done==sizeof actual&&!fstat(fd,&after)&&
        before.st_dev==after.st_dev&&before.st_ino==after.st_ino&&
        before.st_size==after.st_size&&before.st_nlink==after.st_nlink&&
        !fstatat(state,marker_name,&named,AT_SYMLINK_NOFOLLOW)&&
        named.st_dev==before.st_dev&&named.st_ino==before.st_ino&&named.st_nlink==1&&
        !memcmp(&actual,&expected,sizeof actual);
    close(fd);return valid?1:-1;
}

int od_startup_provenance_publish(int state, int documents, int assets) {
    od_startup_marker marker,confirmed;
    if(expected_marker(state,documents,assets,&marker))return -1;
    int existing=od_startup_provenance_read(state,documents,assets);
    if(existing)return existing==1?0:-1;
    /* A stale pending entry is refused, never removed or treated as authority.
     * No exclusive publication can overwrite the only trusted receipt. */
    int fd=openat(state,temporary_name,O_WRONLY|O_CREAT|O_EXCL|O_NOFOLLOW|O_CLOEXEC,0600);
    if(fd<0)return -1;
    size_t done=0;int success=!fchmod(fd,0600);
    while(success&&done<sizeof marker){
        ssize_t count=write(fd,(const char *)&marker+done,sizeof marker-done);
        if(count<0&&errno==EINTR)continue;
        if(count<=0){success=0;break;}done+=(size_t)count;
    }
    if(success)success=!fsync(fd)&&!expected_marker(state,documents,assets,&confirmed)&&
        !memcmp(&marker,&confirmed,sizeof marker);
    if(success)success=!linkat(state,temporary_name,state,marker_name,0);
    /* This file was created by this invocation with O_EXCL. It contains only
     * provenance, never player progress. A pre-existing pending file is left. */
    struct stat opened,named;
    if(fstat(fd,&opened)||fstatat(state,temporary_name,&named,AT_SYMLINK_NOFOLLOW)||
       opened.st_dev!=named.st_dev||opened.st_ino!=named.st_ino||
       unlinkat(state,temporary_name,0))success=0;
    close(fd);
    if(success)success=!fsync(state)&&od_startup_provenance_read(state,documents,assets)==1;
    return success?0:-1;
}
