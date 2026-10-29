#include "source_material.h"
#include <string.h>
/* Public library fingerprints and offsets only, copied from the existing
 * Creator SparkingSetup.java version map. No format key is embedded. */
typedef struct {const char *sha,*version;size_t patch,database;} source_version;
static const source_version versions[]={
 {"9d3f2749e391d990496b632b6adc135492f71e0baec7125d7b613a56e771dca0","6.5.5",648423,487092},
 {"83c0b40f49ae0edb0c91650ff36eb97a528db2c14627333f7023c3a13e0018d4","6.6",665339,495950}
};
void od_source_material_clear(od_source_material *m){
 if(m){volatile unsigned char *p=(volatile unsigned char *)m;for(size_t i=0;i<sizeof(*m);i++)p[i]=0;}
}
static int hex64(const char *s){
 if(!s||s[64]!=0)return 0;
 for(int i=0;i<64;i++)if(!((s[i]>='0'&&s[i]<='9')||(s[i]>='a'&&s[i]<='f')))return 0;
 return 1;
}
int od_source_material_derive(const void *input,size_t length,od_source_sha256 hash,void *context,od_source_material *out){
 if(!out)return OD_SOURCE_INVALID;
 od_source_material_clear(out);
 if(!input||length<600000||length>16u*1024u*1024u||!hash)return OD_SOURCE_INVALID;
 char digest[65]={0};
 if(hash(context,input,length,digest)<0||!hex64(digest))return OD_SOURCE_HASH_FAILED;
 const source_version *v=0;
 for(unsigned i=0;i<sizeof(versions)/sizeof(*versions);i++)if(!strcmp(digest,versions[i].sha)){v=&versions[i];break;}
 if(!v)return OD_SOURCE_UNSUPPORTED;
 const unsigned char *library=(const unsigned char *)input;
 if(v->patch>length||length-v->patch<16||v->database>=length||length-v->database<=64||library[v->database+64]!=0)return OD_SOURCE_MATERIAL_INVALID;
 for(size_t i=0;i<64;i++){
  unsigned char c=library[v->database+i];
  if(!((c>='0'&&c<='9')||(c>='a'&&c<='f')||(c>='A'&&c<='F')))return OD_SOURCE_MATERIAL_INVALID;
 }
 /* Verified SPRK1 pads the16byte source material to the AES256 key width. */
 memcpy(out->sprk_key,library+v->patch,16);
 memcpy(out->database_passphrase,library+v->database,64);
 memcpy(out->source_version,v->version,strlen(v->version)+1);
 memcpy(out->library_sha256,digest,65);
 return OD_SOURCE_OK;
}
