#ifndef _DARWIN_C_SOURCE
#define _DARWIN_C_SOURCE 1
#endif
#ifndef _POSIX_C_SOURCE
#define _POSIX_C_SOURCE 200809L
#endif
#include "zip_stream.h"
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <errno.h>
#include <zlib.h>

struct ODArchiveZip { int fd,writing,finished; uint64_t bytes,total; size_t count; ODArchiveEntry *entries; };
static uint16_t u16(const unsigned char *p){return (uint16_t)(p[0]|p[1]<<8);}
static uint32_t u32(const unsigned char *p){return (uint32_t)p[0]|(uint32_t)p[1]<<8|(uint32_t)p[2]<<16|(uint32_t)p[3]<<24;}
static void p16(unsigned char *p,uint16_t v){p[0]=(unsigned char)v;p[1]=(unsigned char)(v>>8);}
static void p32(unsigned char *p,uint32_t v){p16(p,(uint16_t)v);p16(p+2,(uint16_t)(v>>16));}
static int read_at(int fd,void *bytes,size_t n,uint64_t at){
    unsigned char *p=bytes;while(n){ssize_t got=pread(fd,p,n,(off_t)at);if(got<0&&errno==EINTR)continue;
        if(got<=0)return -1;p+=got;n-=(size_t)got;at+=(uint64_t)got;}return 0;
}
static int write_at(int fd,const void *bytes,size_t n,uint64_t at){
    const unsigned char *p=bytes;while(n){ssize_t got=pwrite(fd,p,n,(off_t)at);if(got<0&&errno==EINTR)continue;
        if(got<=0)return -1;p+=got;n-=(size_t)got;at+=(uint64_t)got;}return 0;
}
static int append(ODArchiveZip *z,const void *bytes,size_t n){
    if(n>OD_ARCHIVE_MAX_BYTES-z->bytes||write_at(z->fd,bytes,n,z->bytes))return -1;z->bytes+=n;return 0;
}
static int offset_order(const void *a,const void *b){
    const ODArchiveEntry *x=*(const ODArchiveEntry *const *)a,*y=*(const ODArchiveEntry *const *)b;
    return x->local_offset<y->local_offset?-1:x->local_offset>y->local_offset;
}
void od_archive_zip_close(ODArchiveZip *z){if(z){free(z->entries);free(z);}}
size_t od_archive_zip_count(const ODArchiveZip *z){return z?z->count:0;}
const ODArchiveEntry *od_archive_zip_entry(const ODArchiveZip *z,size_t i){return z&&i<z->count?z->entries+i:NULL;}
int od_archive_zip_open(int fd,ODArchiveZip **out){
    if(!out)return -1;*out=NULL;struct stat st;
    if(fstat(fd,&st)||!S_ISREG(st.st_mode)||st.st_size<22||(uint64_t)st.st_size>OD_ARCHIVE_MAX_BYTES)return -1;
    ODArchiveZip *z=calloc(1,sizeof(*z));if(!z)return -1;z->fd=fd;z->bytes=(uint64_t)st.st_size;
    size_t tail=(size_t)(z->bytes<65557?z->bytes:65557);unsigned char *data=malloc(tail);
    if(!data||read_at(fd,data,tail,z->bytes-tail)){free(data);od_archive_zip_close(z);return -1;}
    size_t end=tail;uint64_t directory=0,directory_size=0;uint16_t count=0;
    for(size_t i=tail-22;;--i){
        if(u32(data+i)==0x06054b50&&i+22+u16(data+i+20)==tail){
            if(u16(data+i+4)||u16(data+i+6)||u16(data+i+8)!=u16(data+i+10))break;
            count=u16(data+i+10);directory_size=u32(data+i+12);directory=u32(data+i+16);end=i;break;
        }if(!i)break;
    }
    free(data);
    if(end==tail||!count||count>OD_ARCHIVE_MAX_FILES||directory_size>16*1024*1024||
       directory+directory_size!=z->bytes-tail+end){od_archive_zip_close(z);return -1;}
    z->entries=calloc(count,sizeof(*z->entries));if(!z->entries){od_archive_zip_close(z);return -1;}
    z->count=count;uint64_t at=directory;
    for(size_t i=0;i<count;++i){
        unsigned char c[46],l[30];ODArchiveEntry *e=z->entries+i;
        if(at+46>directory+directory_size||read_at(fd,c,sizeof(c),at)||u32(c)!=0x02014b50)goto fail;
        size_t name=u16(c+28),extra=u16(c+30),comment=u16(c+32);
        if(!name||name>1500||u16(c+34)||at+46+name+extra+comment>directory+directory_size||
           (u32(c+38)&0x10)||((u32(c+38)>>16)&0170000)==0120000)goto fail;
        e->flags=u16(c+8);e->method=u16(c+10);e->crc32=u32(c+16);
        e->compressed_bytes=u32(c+20);e->bytes=u32(c+24);e->local_offset=u32(c+42);
        if((e->flags&~(uint16_t)0x080e)||(e->method!=0&&e->method!=8)||
           (e->method==0&&(e->flags&6))||e->bytes>OD_ARCHIVE_MAX_FILE||
           e->bytes>OD_ARCHIVE_MAX_TOTAL+8*1024*1024-z->total)goto fail;
        z->total+=e->bytes;
        if(read_at(fd,e->name,name,at+46)||memchr(e->name,0,name)||e->name[name-1]=='/')goto fail;
        e->name[name]=0;
        for(size_t j=0;j<i;++j)if(!strcmp(e->name,z->entries[j].name))goto fail;
        if(e->local_offset+30>directory||read_at(fd,l,sizeof(l),e->local_offset)||u32(l)!=0x04034b50||
           u16(l+6)!=e->flags||u16(l+8)!=e->method||u16(l+26)!=name)goto fail;
        unsigned char local_name[1500];
        if(read_at(fd,local_name,name,e->local_offset+30)||memcmp(local_name,e->name,name))goto fail;
        if(!(e->flags&8)&&(u32(l+14)!=e->crc32||u32(l+18)!=e->compressed_bytes||u32(l+22)!=e->bytes))goto fail;
        e->data_offset=e->local_offset+30+name+u16(l+28);
        e->end_offset=e->data_offset+e->compressed_bytes;
        if(e->end_offset>directory)goto fail;
        if(e->flags&8){
            unsigned char descriptor[16];
            if(e->end_offset+12>directory||read_at(fd,descriptor,12,e->end_offset))goto fail;
            size_t skip=u32(descriptor)==0x08074b50?4:0;
            if(skip&&(e->end_offset+16>directory||read_at(fd,descriptor,16,e->end_offset)))goto fail;
            if(u32(descriptor+skip)!=e->crc32||u32(descriptor+skip+4)!=e->compressed_bytes||u32(descriptor+skip+8)!=e->bytes)goto fail;
            e->end_offset+=12+skip;
        }
        at+=46+name+extra+comment;
    }
    if(at!=directory+directory_size)goto fail;
    ODArchiveEntry **order=calloc(count,sizeof(*order));if(!order)goto fail;
    for(size_t i=0;i<count;++i)order[i]=z->entries+i;
    qsort(order,count,sizeof(*order),offset_order);uint64_t previous=0;int valid=1;
    for(size_t i=0;i<count;++i){if(order[i]->local_offset!=previous)valid=0;previous=order[i]->end_offset;}
    free(order);if(!valid||previous!=directory)goto fail;
    *out=z;return 0;
fail:od_archive_zip_close(z);return -1;
}
int od_archive_zip_extract(ODArchiveZip *z,size_t index,ODArchiveSink sink,void *context){
    if(!z||z->writing||index>=z->count||!sink)return -1;
    ODArchiveEntry *e=z->entries+index;unsigned char in[65536],out[65536];
    uint64_t loaded=0,produced=0;uLong crc=crc32(0,NULL,0);
    if(e->method==0){
        if(e->bytes!=e->compressed_bytes)return -1;
        while(loaded<e->bytes){size_t n=(size_t)(e->bytes-loaded);if(n>sizeof(in))n=sizeof(in);
            if(read_at(z->fd,in,n,e->data_offset+loaded)||sink(context,in,n))return -1;
            crc=crc32(crc,in,(uInt)n);loaded+=n;}
        produced=loaded;
    }else{
        z_stream stream;memset(&stream,0,sizeof(stream));if(inflateInit2(&stream,-MAX_WBITS)!=Z_OK)return -1;
        int complete=0,failed=0;
        while(!complete&&!failed){
            if(!stream.avail_in&&loaded<e->compressed_bytes){size_t n=(size_t)(e->compressed_bytes-loaded);if(n>sizeof(in))n=sizeof(in);
                if(read_at(z->fd,in,n,e->data_offset+loaded)){failed=1;break;}loaded+=n;stream.next_in=in;stream.avail_in=(uInt)n;}
            stream.next_out=out;stream.avail_out=sizeof(out);uInt before=stream.avail_in;
            int status=inflate(&stream,Z_NO_FLUSH);size_t n=sizeof(out)-stream.avail_out;
            if(n>e->bytes-produced){failed=1;break;}
            if(n){if(sink(context,out,n)){failed=1;break;}crc=crc32(crc,out,(uInt)n);produced+=n;}
            if(status==Z_STREAM_END){complete=1;if(stream.total_in!=e->compressed_bytes)failed=1;}
            else if(status!=Z_OK||(before==stream.avail_in&&!n))failed=1;
        }
        inflateEnd(&stream);if(failed||!complete)return -1;
    }
    return produced==e->bytes&&(uint32_t)crc==e->crc32?0:-1;
}
int od_archive_zip_create(int fd,ODArchiveZip **out){
    if(!out)return -1;*out=NULL;struct stat st;
    if(fstat(fd,&st)||!S_ISREG(st.st_mode)||st.st_size!=0)return -1;
    ODArchiveZip *z=calloc(1,sizeof(*z));if(!z)return -1;
    z->entries=calloc(OD_ARCHIVE_MAX_FILES,sizeof(*z->entries));if(!z->entries){free(z);return -1;}
    z->fd=fd;z->writing=1;*out=z;return 0;
}
int od_archive_zip_add(ODArchiveZip *z,const char *name,uint64_t bytes,ODArchiveSource source,void *context){
    if(!z||!z->writing||z->finished||!name||!source||z->count>=OD_ARCHIVE_MAX_FILES||
       bytes>OD_ARCHIVE_MAX_FILE||bytes>OD_ARCHIVE_MAX_TOTAL+8*1024*1024-z->total)return -1;
    size_t n=strnlen(name,1501);if(!n||n>1500||name[n-1]=='/')return -1;
    for(size_t i=0;i<z->count;++i)if(!strcmp(name,z->entries[i].name))return -1;
    ODArchiveEntry *e=z->entries+z->count;memcpy(e->name,name,n+1);e->bytes=(uint32_t)bytes;
    e->compressed_bytes=e->bytes;e->flags=0x0800;e->local_offset=z->bytes;
    unsigned char local[30]={0};p32(local,0x04034b50);p16(local+4,20);p16(local+6,e->flags);
    p32(local+18,e->bytes);p32(local+22,e->bytes);p16(local+26,(uint16_t)n);
    if(append(z,local,sizeof(local))||append(z,name,n))return -1;
    e->data_offset=z->bytes;uLong crc=crc32(0,NULL,0);uint64_t at=0;unsigned char buffer[65536];
    while(at<bytes){size_t want=(size_t)(bytes-at);if(want>sizeof(buffer))want=sizeof(buffer);
        ssize_t got=source(context,at,buffer,want);if(got<=0||(size_t)got>want)return -1;
        if(append(z,buffer,(size_t)got))return -1;crc=crc32(crc,buffer,(uInt)got);at+=(uint64_t)got;}
    e->crc32=(uint32_t)crc;e->end_offset=z->bytes;unsigned char encoded[4];p32(encoded,e->crc32);
    if(write_at(z->fd,encoded,sizeof(encoded),e->local_offset+14))return -1;
    z->total+=bytes;z->count++;return 0;
}
int od_archive_zip_finish(ODArchiveZip *z){
    if(!z||!z->writing||z->finished||!z->count)return -1;uint64_t directory=z->bytes;
    for(size_t i=0;i<z->count;++i){ODArchiveEntry *e=z->entries+i;unsigned char c[46]={0};size_t n=strlen(e->name);
        p32(c,0x02014b50);p16(c+4,20);p16(c+6,20);p16(c+8,e->flags);p32(c+16,e->crc32);
        p32(c+20,e->bytes);p32(c+24,e->bytes);p16(c+28,(uint16_t)n);p32(c+42,(uint32_t)e->local_offset);
        if(append(z,c,sizeof(c))||append(z,e->name,n))return -1;}
    uint64_t length=z->bytes-directory;if(directory>UINT32_MAX||length>UINT32_MAX)return -1;
    unsigned char end[22]={0};p32(end,0x06054b50);p16(end+8,(uint16_t)z->count);p16(end+10,(uint16_t)z->count);
    p32(end+12,(uint32_t)length);p32(end+16,(uint32_t)directory);
    if(append(z,end,sizeof(end))||fsync(z->fd))return -1;z->finished=1;return 0;
}
