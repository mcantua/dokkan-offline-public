#define _POSIX_C_SOURCE 200809L
#include "iphone_resources.h"
#include <errno.h>
#include <sqlite3.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

struct od_iphone_resources {
 sqlite3 *db;od_asset_catalog *catalog;od_content *content;
 char prefix[513];const char *error;
};
static int fail(od_iphone_resources *r,const char *error) {
 if(r)r->error=error;
 return -1;
}
static int valid_relative(const char *p) {
 if(!p||!*p||strlen(p)>1024||*p=='/')return 0;
 const char *part=p;
 for(const unsigned char *s=(const unsigned char*)p;;s++) {
  if(*s&&(*s<32||*s==127||strchr("\\:%?#",*s)))return 0;
  if(*s=='/'||!*s) {
   size_t n=(const char*)s-part;
   if(!n||n>255||(n==1&&part[0]=='.')||(n==2&&part[0]=='.'&&part[1]=='.'))return 0;
   part=(const char*)s+1;if(!*s)break;
  }
 }
 return 1;
}
static int valid_hash(const char *s) {
 if(!s||strlen(s)!=64)return 0;
 for(int n=0;n<64;n++)if(!((s[n]>='0'&&s[n]<='9')||(s[n]>='a'&&s[n]<='f')))return 0;
 return 1;
}
static int meta(sqlite3 *db,const char *key,char *out,size_t capacity) {
 sqlite3_stmt *s=NULL;int ok=0;
 if(sqlite3_prepare_v2(db,"SELECT value FROM metadata WHERE key=?1",-1,&s,NULL)!=SQLITE_OK)return 0;
 sqlite3_bind_text(s,1,key,-1,SQLITE_STATIC);
 if(sqlite3_step(s)==SQLITE_ROW&&sqlite3_column_type(s,0)==SQLITE_TEXT) {
  int n=sqlite3_column_bytes(s,0);const char *value=(const char*)sqlite3_column_text(s,0);
  if(n>=0&&(size_t)n<capacity&&value&&strlen(value)==(size_t)n) {
   memcpy(out,value,(size_t)n+1);ok=sqlite3_step(s)==SQLITE_DONE;
  }
 }
 sqlite3_finalize(s);return ok;
}
static int expected(sqlite3 *db,const char *key,const char *value) {
 char result[513];return meta(db,key,result,sizeof(result))&&!strcmp(result,value);
}
void od_iphone_resources_close(od_iphone_resources *r) {
 if(!r)return;
 if(r->db)sqlite3_close_v2(r->db);
 od_asset_catalog_close(r->catalog);od_content_close(r->content);free(r);
}
const char *od_iphone_resources_error(const od_iphone_resources *r) {
 return r&&r->error?r->error:"IPHONE_RESOURCES_UNAVAILABLE";
}
int od_iphone_resources_open(const char *catalog,const char *manifest,const char *ipa,
 const char *bundle,const char *source,const char *cache,od_iphone_resources **out) {
 if(!out)return -1;
 *out=NULL;
 if(!catalog||!valid_hash(manifest)||!valid_hash(ipa)||!bundle||!source||!cache)return -1;
 od_iphone_resources *r=calloc(1,sizeof(*r));if(!r)return -1;
 if(od_asset_catalog_open(catalog,manifest,&r->catalog)||
    sqlite3_open_v2(catalog,&r->db,SQLITE_OPEN_READONLY|SQLITE_OPEN_FULLMUTEX,NULL)!=SQLITE_OK||
    sqlite3_db_readonly(r->db,"main")!=1||
    sqlite3_exec(r->db,"PRAGMA trusted_schema=OFF",NULL,NULL,NULL)!=SQLITE_OK||
    !expected(r->db,"schema","1")||!expected(r->db,"verified_alias_schema","1")||
    !expected(r->db,"manifest_sha256",manifest)||!expected(r->db,"ipa_sha256",ipa)||
    !expected(r->db,"iphone_bundle_id",bundle)||
    !meta(r->db,"iphone_app_prefix",r->prefix,sizeof(r->prefix)))goto reject;
 size_t length=strlen(r->prefix);
 if(length<14||strncmp(r->prefix,"Payload/",8)||strcmp(r->prefix+length-5,".app/")||
    strchr(r->prefix+8,'/')!=r->prefix+length-1)goto reject;
 if(od_content_open(source,cache,&r->content))goto reject;
 *out=r;return 0;
reject:od_iphone_resources_close(r);return -1;
}
int od_iphone_resources_reference(od_iphone_resources *r,const char *relative,od_asset_reference *out) {
 if(!r||!out)return -1;
 memset(out,0,sizeof(*out));r->error=NULL;
 if(!valid_relative(relative))return fail(r,"IPHONE_RESOURCE_PATH_REJECTED");
 size_t a=strlen(r->prefix),b=strlen(relative);
 if(a+b>1536)return fail(r,"IPHONE_RESOURCE_PATH_REJECTED");
 char entry[1537];memcpy(entry,r->prefix,a);memcpy(entry+a,relative,b+1);
 sqlite3_stmt *s=NULL;
 if(sqlite3_prepare_v2(r->db,"SELECT path,mapping FROM ipa_aliases WHERE zip_entry=?1",-1,&s,NULL)!=SQLITE_OK)
  return fail(r,"IPHONE_RESOURCE_CATALOG_INVALID");
 sqlite3_bind_text(s,1,entry,-1,SQLITE_TRANSIENT);int row=sqlite3_step(s),ok=0;
 char path[1025];
 if(row==SQLITE_ROW&&sqlite3_column_type(s,0)==SQLITE_TEXT&&sqlite3_column_type(s,1)==SQLITE_TEXT) {
  const char *p=(const char*)sqlite3_column_text(s,0),*mapping=(const char*)sqlite3_column_text(s,1);
  int n=sqlite3_column_bytes(s,0),m=sqlite3_column_bytes(s,1);
  if(p&&mapping&&n>=7&&n<=1024&&strlen(p)==(size_t)n&&strlen(mapping)==(size_t)m&&
     !strncmp(p,"assets/",7)&&
     ((!strcmp(mapping,"bundle-root")&&!strcmp(relative,p+7))||
      (!strcmp(mapping,"tutorial-resource-candidate")&&!strncmp(relative,"tutorial0/",10)&&!strcmp(relative+10,p+7)))) {
   memcpy(path,p,(size_t)n+1);ok=sqlite3_step(s)==SQLITE_DONE;
  }
 }
 sqlite3_finalize(s);
 if(!ok)return fail(r,row==SQLITE_DONE?"IPHONE_RESOURCE_NOT_ADMITTED":"IPHONE_RESOURCE_CATALOG_INVALID");
 if(od_asset_catalog_reference(r->catalog,path,out))return fail(r,"IPHONE_RESOURCE_REFERENCE_INVALID");
 return 0;
}
int od_iphone_resources_resolve(od_iphone_resources *r,const char *relative,int *descriptor) {
 if(!descriptor)return -1;
 *descriptor=-1;od_asset_reference reference;
 if(od_iphone_resources_reference(r,relative,&reference))return -1;
 if(od_content_resolve(r->content,reference.path,reference.bytes,reference.sha256,descriptor))
  return fail(r,"IPHONE_RESOURCE_CONTENT_UNAVAILABLE");
 return 0;
}
FILE *od_iphone_resources_fopen(od_iphone_resources *r,const char *bundle,
 const char *path,const char *mode,FILE *(*original)(const char *,const char *)) {
 if(!original||!path||!mode){errno=EINVAL;return NULL;}
 if(!r||!bundle||(strcmp(mode,"r")&&strcmp(mode,"rb")))return original(path,mode);
 size_t root_length=strlen(bundle);
 if(root_length<5||bundle[0]!='/'||strcmp(bundle+root_length-4,".app")||
    !valid_relative(bundle+1)){errno=EINVAL;return NULL;}
 if(strncmp(path,bundle,root_length)||path[root_length]!='/')return original(path,mode);
 const char *relative=path+root_length+1;
 if(!valid_relative(relative)){errno=EINVAL;return NULL;}
 od_asset_reference reference;
 if(od_iphone_resources_reference(r,relative,&reference)) {
  if(r->error&&!strcmp(r->error,"IPHONE_RESOURCE_NOT_ADMITTED"))return original(path,mode);
  errno=EIO;return NULL;
 }
 int fd=-1;
 if(od_content_resolve(r->content,reference.path,reference.bytes,reference.sha256,&fd)) {
  fail(r,"IPHONE_RESOURCE_CONTENT_UNAVAILABLE");errno=EIO;return NULL;
 }
 FILE *stream=fdopen(fd,mode);
 if(!stream){int saved=errno;close(fd);errno=saved;}
 return stream;
}
