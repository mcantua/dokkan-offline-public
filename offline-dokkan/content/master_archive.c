#if defined(__APPLE__) && !defined(_DARWIN_C_SOURCE)
#define _DARWIN_C_SOURCE 1
#endif
#define _POSIX_C_SOURCE 200809L
#define _FILE_OFFSET_BITS 64
#include "master_archive.h"
#include <errno.h>
#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>
#include <zlib.h>

#define CENTRAL_LIMIT (64U*1024U*1024U)
#define NAME_LIMIT 4096U
typedef struct {
 char *name;
 uint64_t start, data, end;
 uint32_t compressed, expanded, crc;
 uint16_t flags, method;
 int selected;
} zip_item;
static uint16_t u16(const unsigned char *p){return (uint16_t)(p[0]|(uint16_t)p[1]<<8);}
static uint32_t u32(const unsigned char *p){return (uint32_t)u16(p)|(uint32_t)u16(p+2)<<16;}
static int read_at(int fd,void *data,size_t length,uint64_t offset){
 unsigned char *p=data;
 while(length){ssize_t n=pread(fd,p,length,(off_t)offset);if(n<0&&errno==EINTR)continue;if(n<=0)return -1;p+=n;length-=(size_t)n;offset+=(uint64_t)n;}return 0;
}
static int write_all(int fd,const unsigned char *p,size_t length){
 while(length){ssize_t n=write(fd,p,length);if(n<0&&errno==EINTR)continue;if(n<=0)return -1;p+=n;length-=(size_t)n;}return 0;
}
static int extras_ok(int fd,uint64_t offset,uint16_t length){
 unsigned char header[4];uint64_t end=offset+length;
 while(offset<end){if(end-offset<4||read_at(fd,header,4,offset))return 0;uint16_t tag=u16(header),size=u16(header+2);offset+=4;
  if(tag==1||tag==0x9901||size>end-offset)return 0;
  offset+=size;}
 return offset==end;
}
static int same_source(const struct stat *a,const struct stat *b){
 if(a->st_dev!=b->st_dev||a->st_ino!=b->st_ino||a->st_size!=b->st_size||a->st_mtime!=b->st_mtime||a->st_ctime!=b->st_ctime)return 0;
#if defined(__APPLE__)
 return a->st_mtimespec.tv_nsec==b->st_mtimespec.tv_nsec&&a->st_ctimespec.tv_nsec==b->st_ctimespec.tv_nsec;
#else
 return a->st_mtim.tv_nsec==b->st_mtim.tv_nsec&&a->st_ctim.tv_nsec==b->st_ctim.tv_nsec;
#endif
}
static int names_cmp(const void *a,const void *b){return strcmp(((const zip_item*)a)->name,((const zip_item*)b)->name);}
static int offsets_cmp(const void *a,const void *b){uint64_t x=((const zip_item*)a)->start,y=((const zip_item*)b)->start;return x<y?-1:x>y;}
static int preflight_local(int fd,zip_item *item,uint64_t central){
 unsigned char h[30],name[NAME_LIMIT],descriptor[16];
 if(item->start>central||central-item->start<30||read_at(fd,h,30,item->start)||u32(h)!=0x04034b50U||u16(h+6)!=item->flags||u16(h+8)!=item->method||u16(h+4)>20)return -1;
 uint16_t names=u16(h+26),extra=u16(h+28);size_t expected=strlen(item->name);
 if(names!=expected||item->start+30+names+extra>central||read_at(fd,name,names,item->start+30)||memcmp(name,item->name,names)||!extras_ok(fd,item->start+30+names,extra))return -1;
 if(item->flags&8){if((u32(h+14)&&u32(h+14)!=item->crc)||(u32(h+18)&&u32(h+18)!=item->compressed)||(u32(h+22)&&u32(h+22)!=item->expanded))return -1;}
 else if(u32(h+14)!=item->crc||u32(h+18)!=item->compressed||u32(h+22)!=item->expanded)return -1;
 item->data=item->start+30+names+extra;
 if(item->compressed>central-item->data)return -1;
 item->end=item->data+item->compressed;
 if(item->flags&8){
  if(central-item->end<12||read_at(fd,descriptor,12,item->end))return -1;
  /* CRC can itself equal the optional signature. Prefer the valid unsigned
   * descriptor in that rare case, otherwise require all signed fields. */
  if(u32(descriptor)==item->crc&&u32(descriptor+4)==item->compressed&&u32(descriptor+8)==item->expanded)item->end+=12;
  else {if(u32(descriptor)!=0x08074b50U||central-item->end<16||read_at(fd,descriptor+12,4,item->end+12)||u32(descriptor+4)!=item->crc||u32(descriptor+8)!=item->compressed||u32(descriptor+12)!=item->expanded)return -1;item->end+=16;}
 }
 return 0;
}
static int extract_bytes(int source,int output,const zip_item *item){
 unsigned char input[65536],buffer[65536];uint64_t read=0,written=0;uLong crc=crc32(0L,Z_NULL,0);
 if(item->method==0){
  if(item->compressed!=item->expanded)return -1;
  while(read<item->compressed){size_t n=(uint64_t)sizeof(input)<item->compressed-read?sizeof(input):(size_t)(item->compressed-read);if(read_at(source,input,n,item->data+read)||write_all(output,input,n))return -1;crc=crc32(crc,input,(uInt)n);read+=n;written+=n;}
 }else{
  z_stream stream;memset(&stream,0,sizeof(stream));if(inflateInit2(&stream,-MAX_WBITS)!=Z_OK)return -1;int valid=0;
  for(;;){
   if(!stream.avail_in&&read<item->compressed){size_t n=(uint64_t)sizeof(input)<item->compressed-read?sizeof(input):(size_t)(item->compressed-read);if(read_at(source,input,n,item->data+read))break;stream.next_in=input;stream.avail_in=(uInt)n;read+=n;}
   stream.next_out=buffer;stream.avail_out=sizeof(buffer);uInt before=stream.avail_in;int rc=inflate(&stream,Z_NO_FLUSH);size_t count=sizeof(buffer)-stream.avail_out;
   if(count>item->expanded-written||count>OD_MASTER_ARCHIVE_MAX_OUTPUT-written||write_all(output,buffer,count))break;
   crc=crc32(crc,buffer,(uInt)count);written+=count;
   if(rc==Z_STREAM_END){valid=read==item->compressed&&!stream.avail_in;break;}
   if(rc!=Z_OK||(!count&&before==stream.avail_in))break;
  }
  inflateEnd(&stream);if(!valid)return -1;
 }
 return written==item->expanded&&(uint32_t)crc==item->crc?0:-1;
}
int od_master_archive_extract(int source,int output,const char *game,od_master_archive_result *result,const char **error){
 const char *why="MASTER_ARCHIVE_INVALID";zip_item *items=NULL;unsigned count=0;int accepted=0,ok=0;struct stat before,out,after;
 if(error)*error=NULL;
 if(result)memset(result,0,sizeof(*result));
 const char *shortname=NULL,*assetname=NULL;
 if(game&&!strcmp(game,"eclipse")){shortname="reference.db";assetname="assets/reference.db";}
 else if(game&&!strcmp(game,"sparking")){shortname="sparking-reference.db";assetname="assets/sparking-reference.db";}
 else {why="MASTER_ARCHIVE_GAME_INVALID";goto done;}
 if(!result||source<0||output<0||source==output){why="MASTER_ARCHIVE_FD_INVALID";goto done;}
 int source_flags=fcntl(source,F_GETFL),output_flags=fcntl(output,F_GETFL);
 if(source_flags<0||(source_flags&O_ACCMODE)!=O_RDONLY||output_flags<0||(output_flags&O_ACCMODE)==O_RDONLY||fstat(source,&before)||fstat(output,&out)||!S_ISREG(before.st_mode)||!S_ISREG(out.st_mode)||out.st_size!=0||out.st_nlink!=1||(before.st_dev==out.st_dev&&before.st_ino==out.st_ino)||lseek(output,0,SEEK_SET)<0){why="MASTER_ARCHIVE_FD_INVALID";goto done;}
 accepted=1;
 if(before.st_size<22||(uint64_t)before.st_size>OD_MASTER_ARCHIVE_MAX_SOURCE){why="MASTER_ARCHIVE_SOURCE_LIMIT";goto done;}
 unsigned char tail[65557];size_t tail_size=(uint64_t)before.st_size>sizeof(tail)?sizeof(tail):(size_t)before.st_size;uint64_t tail_at=(uint64_t)before.st_size-tail_size;
 if(read_at(source,tail,tail_size,tail_at))goto done;
 size_t eocd=0;unsigned matches=0;
 for(size_t pos=0;pos+22<=tail_size;pos++)if(u32(tail+pos)==0x06054b50U&&pos+22+u16(tail+pos+20)==tail_size){eocd=pos;matches++;}
 if(matches!=1)goto done;
 const unsigned char *end=tail+eocd;count=u16(end+10);uint64_t central=u32(end+16),central_size=u32(end+12),end_at=tail_at+eocd;
 if(u16(end+4)||u16(end+6)||u16(end+8)!=count||!count||count==65535||count>OD_MASTER_ARCHIVE_MAX_ENTRIES||central_size==UINT32_MAX||central==UINT32_MAX||central_size>CENTRAL_LIMIT||central+central_size!=end_at){why="MASTER_ARCHIVE_DIRECTORY_INVALID";goto done;}
 items=calloc(count,sizeof(*items));if(!items){why="MASTER_ARCHIVE_MEMORY";goto done;}
 uint64_t at=central;unsigned selected=0;
 for(unsigned i=0;i<count;i++){
  unsigned char h[46];if(at>end_at||end_at-at<46||read_at(source,h,sizeof(h),at)||u32(h)!=0x02014b50U)goto done;
  zip_item *item=items+i;uint16_t names=u16(h+28),extra=u16(h+30),comment=u16(h+32);item->flags=u16(h+8);item->method=u16(h+10);item->crc=u32(h+16);item->compressed=u32(h+20);item->expanded=u32(h+24);item->start=u32(h+42);
  if(!names||names>NAME_LIMIT||at+46+names+extra+comment>end_at||u16(h+6)>20||u16(h+34)||item->compressed==UINT32_MAX||item->expanded==UINT32_MAX||item->start==UINT32_MAX||(item->flags&~0x080eU)||(item->method!=0&&item->method!=8)||(item->method==0&&(item->flags&6))||!extras_ok(source,at+46+names,extra))goto done;
  item->name=malloc((size_t)names+1);if(!item->name){why="MASTER_ARCHIVE_MEMORY";goto done;}if(read_at(source,item->name,names,at+46)||memchr(item->name,0,names))goto done;item->name[names]=0;
  item->selected=!strcmp(item->name,shortname)||!strcmp(item->name,assetname);
  if(item->selected){uint32_t mode=u32(h+38)>>16;if((mode&0170000U)&&((mode&0170000U)!=0100000U))goto done;if(u32(h+38)&0x10U)goto done;if(!item->expanded||item->expanded>OD_MASTER_ARCHIVE_MAX_OUTPUT){why="MASTER_ARCHIVE_OUTPUT_LIMIT";goto done;}selected++;}
  if(preflight_local(source,item,central))goto done;
  at+=46+names+extra+comment;
 }
 if(at!=end_at)goto done;
 if(selected!=1){why=selected?"MASTER_ARCHIVE_AMBIGUOUS":"MASTER_ARCHIVE_DATABASE_MISSING";goto done;}
 qsort(items,count,sizeof(*items),names_cmp);for(unsigned i=1;i<count;i++)if(!strcmp(items[i-1].name,items[i].name)){why="MASTER_ARCHIVE_DUPLICATE";goto done;}
 qsort(items,count,sizeof(*items),offsets_cmp);for(unsigned i=1;i<count;i++)if(items[i-1].end>items[i].start)goto done;
 zip_item *chosen=NULL;for(unsigned i=0;i<count;i++)if(items[i].selected)chosen=items+i;
 if(!chosen||extract_bytes(source,output,chosen)){why="MASTER_ARCHIVE_INTEGRITY_FAILED";goto done;}
 if(fstat(source,&after)||!same_source(&before,&after)){why="MASTER_ARCHIVE_SOURCE_CHANGED";goto done;}
 if(fsync(output)||lseek(output,0,SEEK_SET)<0){why="MASTER_ARCHIVE_OUTPUT_FAILED";goto done;}
 result->bytes=chosen->expanded;result->crc32=chosen->crc;memcpy(result->entry,chosen->name,strlen(chosen->name)+1);ok=1;
done:
 if(items){for(unsigned i=0;i<count;i++)free(items[i].name);free(items);}
 if(!ok){if(result)memset(result,0,sizeof(*result));if(accepted&&(ftruncate(output,0)||lseek(output,0,SEEK_SET)<0))why="MASTER_ARCHIVE_OUTPUT_RESET_FAILED";if(error)*error=why;}
 return ok?0:-1;
}
