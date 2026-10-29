#include "fopen_bind_attach.h"
#include <stdlib.h>
#include <string.h>

#define SOURCE_BASE UINT64_C(4294967296)
#define SLOT_VM UINT64_C(4339177888)
#define SEGMENT_VM UINT64_C(4339171328)
#define SEGMENT_BYTES UINT64_C(6012928)
#define SEGMENT_FILE UINT64_C(44204032)
#define FIXUPS_FILE UINT64_C(50839552)
#define FIXUPS_BYTES UINT64_C(265800)
#define IMPORT_RECORD UINT64_C(50852936)
#define IMPORT_INDEX UINT32_C(779)
#define IMPORT_NAME_OFFSET UINT32_C(24462)
#define LIBRARY_ORDINAL UINT32_C(41)
static const char source_sha[]="9d6bf0470c4b4ff7d914740ccf9f1622afa962b763e18bfcf1f6e051bfae0610";
static uint32_t u32(const unsigned char *p) {
 return (uint32_t)p[0]|((uint32_t)p[1]<<8)|((uint32_t)p[2]<<16)|((uint32_t)p[3]<<24);
}
static uint64_t u64(const unsigned char *p) { return u32(p)|((uint64_t)u32(p+4)<<32); }
static int add_slide(uint64_t value,intptr_t slide,uintptr_t *out) {
 if(slide<0) {
  uint64_t amount=(uint64_t)(-(slide+1))+1;
  if(value<amount)return 0;
  value-=amount;
 } else {if(value>UINT64_MAX-(uint64_t)slide)return 0;value+=(uint64_t)slide;}
 if(value>UINTPTR_MAX)return 0;
 *out=(uintptr_t)value;return 1;
}
static int read_file_offset(const od_fopen_bind_host *h,const unsigned char *commands,
 size_t amount,uint64_t offset,void *out,size_t bytes,intptr_t slide) {
 size_t pos=0;int hits=0;uintptr_t address=0;
 while(pos<amount) {
  uint32_t cmd=u32(commands+pos),n=u32(commands+pos+4);
  if(cmd==0x19) {
   uint64_t vm=u64(commands+pos+24),file=u64(commands+pos+40),size=u64(commands+pos+48);
   if(offset>=file&&offset-file<=size&&bytes<=size-(offset-file)) {
    if(vm>UINT64_MAX-(offset-file)||!add_slide(vm+offset-file,slide,&address))return 0;
    hits++;
   }
  }
  pos+=n;
 }
 return hits==1&&h->read(h->context,address,out,bytes)==0;
}
static int validate(const od_fopen_bind_host *h,uintptr_t header,intptr_t slide,uintptr_t *slot) {
 if(!h||!h->verify_identity||!h->read||!h->writable||!h->compare_exchange)return OD_FOPEN_BIND_INVALID;
 if(h->verify_identity(h->context,source_sha,header,slide))return OD_FOPEN_BIND_IDENTITY;
 uintptr_t expected_header=0;
 if(!add_slide(SOURCE_BASE,slide,&expected_header)||expected_header!=header||
    !add_slide(SLOT_VM,slide,slot)||(*slot%8))return OD_FOPEN_BIND_FORMAT;
 unsigned char head[32];
 if(h->read(h->context,header,head,sizeof(head)))return OD_FOPEN_BIND_FORMAT;
 uint32_t count=u32(head+16),amount=u32(head+20),type=u32(head+12);
 if(u32(head)!=0xfeedfacf||u32(head+4)!=0x100000c||u32(head+8)!=0||
    (type!=2&&type!=6)||!count||count>8192||amount<8||amount>4*1024*1024||
    header>UINTPTR_MAX-32-amount)return OD_FOPEN_BIND_FORMAT;
 unsigned char *commands=malloc(amount);if(!commands)return OD_FOPEN_BIND_INVALID;
 int result=OD_FOPEN_BIND_FORMAT;
 if(h->read(h->context,header+32,commands,amount))goto done;
 size_t pos=0;uint32_t segments=0,target_segment=UINT32_MAX,libraries=0;
 int target=0,system_library=0,fixups=0;
 for(uint32_t i=0;i<count;i++) {
  if(pos+8>amount)goto done;
  uint32_t cmd=u32(commands+pos),n=u32(commands+pos+4);
  if(n<8||n%8||n>amount-pos)goto done;
  if(cmd==0x19) {
   if(n<72||u32(commands+pos+64)>(n-72)/80||n!=72+80*u32(commands+pos+64))goto done;
   uint64_t vm=u64(commands+pos+24),bytes=u64(commands+pos+32);
   uint64_t file=u64(commands+pos+40),file_bytes=u64(commands+pos+48);
   if(vm==SEGMENT_VM) {
    if(target||bytes!=SEGMENT_BYTES||file!=SEGMENT_FILE||file_bytes!=SEGMENT_BYTES||
       u32(commands+pos+56)!=3||u32(commands+pos+60)!=3)goto done;
    target=1;target_segment=segments;
   }
   segments++;
  } else if(cmd==0x80000034) {
   if(n!=16||fixups||u32(commands+pos+8)!=FIXUPS_FILE||u32(commands+pos+12)!=FIXUPS_BYTES)goto done;
   fixups=1;
  } else if(cmd==0xc||cmd==0x80000018||cmd==0x8000001f||cmd==0x80000023) {
   libraries++;
   if(libraries==LIBRARY_ORDINAL) {
    if(n<24)goto done;
    uint32_t start=u32(commands+pos+8);const char library[]="/usr/lib/libSystem.B.dylib";
    if(start<24||start>n||sizeof(library)>n-start||memcmp(commands+pos+start,library,sizeof(library)))goto done;
    system_library=1;
   }
  } else if(cmd==0x21||cmd==0x2c) {
   if(n<20||u32(commands+pos+16))goto done;
  }
  pos+=n;
 }
 if(pos!=amount||!target||!system_library||!fixups)goto done;
 unsigned char fix[28];
 if(!read_file_offset(h,commands,amount,FIXUPS_FILE,fix,sizeof(fix),slide))goto done;
 uint32_t starts=u32(fix+4),imports=u32(fix+8),symbols=u32(fix+12),imports_count=u32(fix+16);
 if(u32(fix)||u32(fix+20)!=3||u32(fix+24)||imports_count<=IMPORT_INDEX||imports_count>65536||
    starts<28||starts>FIXUPS_BYTES-22||imports<28||imports>FIXUPS_BYTES||symbols>=FIXUPS_BYTES||
    imports_count>(FIXUPS_BYTES-imports)/16||symbols<imports+(uint64_t)imports_count*16||
    FIXUPS_FILE+(uint64_t)imports+16*IMPORT_INDEX!=IMPORT_RECORD)goto done;
 unsigned char imports_record[16],name[7],segment_count[4],segment_offset[4],segment_start[22];
 if(!read_file_offset(h,commands,amount,IMPORT_RECORD,imports_record,16,slide)||
    u64(imports_record)!=(((uint64_t)IMPORT_NAME_OFFSET<<32)|LIBRARY_ORDINAL)||u64(imports_record+8)||
    symbols>FIXUPS_BYTES-IMPORT_NAME_OFFSET-7||
    !read_file_offset(h,commands,amount,FIXUPS_FILE+symbols+IMPORT_NAME_OFFSET,name,7,slide)||memcmp(name,"_fopen",7))goto done;
 if(!read_file_offset(h,commands,amount,FIXUPS_FILE+starts,segment_count,4,slide)||
    u32(segment_count)!=segments||target_segment>=segments||
    4+(uint64_t)segments*4>FIXUPS_BYTES-starts||
    !read_file_offset(h,commands,amount,FIXUPS_FILE+starts+4+4*target_segment,segment_offset,4,slide))goto done;
 uint32_t relative=u32(segment_offset);
 if(relative<4+4*segments||relative>FIXUPS_BYTES-starts-22||
    !read_file_offset(h,commands,amount,FIXUPS_FILE+starts+relative,segment_start,22,slide)||
    u32(segment_start)<22||u32(segment_start)>FIXUPS_BYTES-starts-relative||
    !((segment_start[4]==0&&segment_start[5]==16)||(segment_start[4]==0&&segment_start[5]==64))||
    ((uint32_t)segment_start[6]|((uint32_t)segment_start[7]<<8))!=6||
    u64(segment_start+8)!=SEGMENT_VM-SOURCE_BASE)goto done;
 result=h->writable(h->context,*slot,sizeof(uintptr_t))==0?OD_FOPEN_BIND_OK:OD_FOPEN_BIND_READ_ONLY;
done:free(commands);return result;
}
static uintptr_t function_bits(od_fopen_function function) {
 uintptr_t value=0;
 _Static_assert(sizeof(function)==sizeof(value),"Only native64-bit pointer ABI is supported");
 memcpy(&value,&function,sizeof(value));return value;
}
int od_fopen_bind_attach(const od_fopen_bind_host *host,uintptr_t header,intptr_t slide,
 od_fopen_function original,od_fopen_function replacement,od_fopen_binding *receipt) {
 if(!receipt||!original||!replacement||original==replacement)return OD_FOPEN_BIND_INVALID;
 memset(receipt,0,sizeof(*receipt));uintptr_t slot=0;
 int code=validate(host,header,slide,&slot);if(code)return code;
 uintptr_t old=function_bits(original),next=function_bits(replacement),current=0;
 if(host->read(host->context,slot,&current,sizeof(current))||current!=old||
    host->compare_exchange(host->context,slot,old,next))return OD_FOPEN_BIND_VALUE_CHANGED;
 receipt->slot_address=slot;receipt->original=old;receipt->replacement=next;receipt->attached=1;
 return OD_FOPEN_BIND_OK;
}
int od_fopen_bind_detach(const od_fopen_bind_host *host,uintptr_t header,intptr_t slide,od_fopen_binding *receipt) {
 if(!receipt||!receipt->attached)return OD_FOPEN_BIND_INVALID;
 uintptr_t slot=0;int code=validate(host,header,slide,&slot);if(code)return code;
 if(slot!=receipt->slot_address||!receipt->original||!receipt->replacement||
    host->compare_exchange(host->context,slot,receipt->replacement,receipt->original))return OD_FOPEN_BIND_VALUE_CHANGED;
 receipt->attached=0;return OD_FOPEN_BIND_OK;
}
