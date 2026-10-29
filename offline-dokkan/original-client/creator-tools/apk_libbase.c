#include "apk_libbase.h"
#include <stdlib.h>
#include <string.h>
#include <zlib.h>
static uint16_t u16(const unsigned char*p){return (uint16_t)(p[0]|((uint16_t)p[1]<<8));}
static uint32_t u32(const unsigned char*p){return u16(p)|((uint32_t)u16(p+2)<<16);}
void od_creator_apk_library_clear(void *buffer,size_t bytes){
 if(buffer){volatile unsigned char*p=buffer;while(bytes--)*p++=0;free(buffer);}
}
int od_creator_apk_libbase(const void *input,size_t length,void **out,size_t *out_bytes){
 if(!out||!out_bytes)return -1;
 *out=NULL;*out_bytes=0;
 if(!input||length<22||length>128*1024*1024)return -1;
 const unsigned char *apk=input;size_t minimum=length>65557?length-65557:0,eocd=SIZE_MAX;
 for(size_t p=length-22;;p--){
  if(u32(apk+p)==0x06054b50&&p+22+u16(apk+p+20)==length){eocd=p;break;}
  if(p==minimum)break;
 }
 if(eocd==SIZE_MAX||u16(apk+eocd+4)||u16(apk+eocd+6)||u16(apk+eocd+8)!=u16(apk+eocd+10))return -1;
 uint32_t count=u16(apk+eocd+10),directory_bytes=u32(apk+eocd+12),directory=u32(apk+eocd+16);
 if(!count||count>20000||directory_bytes>16*1024*1024||directory>eocd||directory_bytes>eocd-directory)return -1;
 size_t pos=directory;unsigned matches=0;uint32_t compressed=0,plain=0,crc=0,local=0;uint16_t method=0;
 static const char selected[]="lib/arm64-v8a/libbase.so";
 for(uint32_t i=0;i<count;i++){
  if(pos>directory+directory_bytes||directory+directory_bytes-pos<46||u32(apk+pos)!=0x02014b50)return -1;
  uint16_t names=u16(apk+pos+28),extra=u16(apk+pos+30),comment=u16(apk+pos+32);
  size_t next=pos+46+(size_t)names+extra+comment;
  if(next>directory+directory_bytes)return -1;
  if(names==sizeof(selected)-1&&!memcmp(apk+pos+46,selected,names)){
   if(++matches!=1||(u16(apk+pos+8)&1)||((u32(apk+pos+38)>>16)&0170000)==0120000)return -1;
   method=u16(apk+pos+10);crc=u32(apk+pos+16);compressed=u32(apk+pos+20);plain=u32(apk+pos+24);local=u32(apk+pos+42);
  }
  pos=next;
 }
 if(matches!=1||pos!=directory+directory_bytes||!plain||plain>16*1024*1024||
    !compressed||compressed>16*1024*1024||local>directory||directory-local<30||u32(apk+local)!=0x04034b50)return -1;
 uint16_t names=u16(apk+local+26),extra=u16(apk+local+28);
 size_t data=(size_t)local+30+names+extra;
 if((u16(apk+local+6)&1)||u16(apk+local+8)!=method||names!=sizeof(selected)-1||
    data>directory||compressed>directory-data||memcmp(apk+local+30,selected,names))return -1;
 if(!(u16(apk+local+6)&8)&&(u32(apk+local+14)!=crc||u32(apk+local+18)!=compressed||u32(apk+local+22)!=plain))return -1;
 unsigned char *buffer=malloc(plain);if(!buffer)return -1;int ok=0;
 if(method==0){if(compressed==plain){memcpy(buffer,apk+data,plain);ok=1;}}
 else if(method==8){
  z_stream stream;memset(&stream,0,sizeof(stream));stream.next_in=(Bytef*)(apk+data);stream.avail_in=compressed;stream.next_out=buffer;stream.avail_out=plain;
  if(inflateInit2(&stream,-MAX_WBITS)==Z_OK){int code=inflate(&stream,Z_FINISH);ok=code==Z_STREAM_END&&stream.total_out==plain&&stream.total_in==compressed;inflateEnd(&stream);}
 }
 if(!ok||(uint32_t)crc32(0,buffer,plain)!=crc){od_creator_apk_library_clear(buffer,plain);return -1;}
 *out=buffer;*out_bytes=plain;return 0;
}
