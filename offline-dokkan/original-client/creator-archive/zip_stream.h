#ifndef OD_CREATOR_ZIP_STREAM_H
#define OD_CREATOR_ZIP_STREAM_H
#include <stddef.h>
#include <stdint.h>
#include <sys/types.h>
#define OD_ARCHIVE_MAX_FILES 10001u
#define OD_ARCHIVE_MAX_FILE (512ull*1024*1024)
#define OD_ARCHIVE_MAX_TOTAL (2ull*1024*1024*1024)
#define OD_ARCHIVE_MAX_BYTES (OD_ARCHIVE_MAX_TOTAL+8ull*1024*1024+10000ull*2048)
typedef struct {
    char name[1501];
    uint32_t bytes, compressed_bytes, crc32;
    uint16_t method, flags;
    uint64_t local_offset, data_offset, end_offset;
} ODArchiveEntry;
typedef struct ODArchiveZip ODArchiveZip;
typedef int (*ODArchiveSink)(void *,const void *,size_t);
typedef ssize_t (*ODArchiveSource)(void *,uint64_t,void *,size_t);
/* Caller retains ownership of fd. All APIs return0 on success, -1 on failure.
   No archive path is ever opened by this ZIP layer. No ZIP64/encryption/links. */
int od_archive_zip_open(int fd,ODArchiveZip **result);
size_t od_archive_zip_count(const ODArchiveZip *zip);
const ODArchiveEntry *od_archive_zip_entry(const ODArchiveZip *zip,size_t index);
int od_archive_zip_extract(ODArchiveZip *zip,size_t index,ODArchiveSink sink,void *context);
void od_archive_zip_close(ODArchiveZip *zip);
int od_archive_zip_create(int fd,ODArchiveZip **result);
int od_archive_zip_add(ODArchiveZip *zip,const char *name,uint64_t bytes,
                       ODArchiveSource source,void *context);
int od_archive_zip_finish(ODArchiveZip *zip);
#endif
