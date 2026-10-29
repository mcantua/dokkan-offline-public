#include "asset_catalog.h"
#include <sqlite3.h>
#include <stdlib.h>
#include <string.h>

struct od_asset_catalog { sqlite3 *db; const char *error; };
static int fail(od_asset_catalog *c,const char *error) { if(c)c->error=error;return -1; }
static int valid_hash(const char *s) {
 if(!s||strlen(s)!=64)return 0;
 for(int i=0;i<64;i++)if(!((s[i]>='0'&&s[i]<='9')||(s[i]>='a'&&s[i]<='f')))return 0;
 return 1;
}
static int valid_path(const char *s) {
 if(!s||strncmp(s,"assets/",7)||strlen(s)>1024||!s[7]||
    !strcmp(s,"assets/User")||!strncmp(s,"assets/User/",12))return 0;
 const char *part=s;
 for(const unsigned char *p=(const unsigned char*)s;;p++) {
  if(*p&&(*p<32||*p==127||strchr("\\:%?#",*p)))return 0;
  if(*p=='/'||!*p) {
   size_t n=(const char*)p-part;
   if(!n||n>255||(n==1&&part[0]=='.')||(n==2&&part[0]=='.'&&part[1]=='.'))return 0;
   part=(const char*)p+1;if(!*p)break;
  }
 }
 return 1;
}
const char *od_asset_catalog_error(const od_asset_catalog *c) { return c&&c->error?c->error:"ASSET_CATALOG_UNAVAILABLE"; }
void od_asset_catalog_close(od_asset_catalog *c) { if(c){if(c->db)sqlite3_close_v2(c->db);free(c);} }
static int metadata(sqlite3 *db,const char *key,const char *expected) {
 sqlite3_stmt *s=NULL;int ok=0;
 if(sqlite3_prepare_v2(db,"SELECT value FROM metadata WHERE key=?1",-1,&s,NULL)!=SQLITE_OK)return 0;
 sqlite3_bind_text(s,1,key,-1,SQLITE_STATIC);
 if(sqlite3_step(s)==SQLITE_ROW&&sqlite3_column_type(s,0)==SQLITE_TEXT) {
  const char *value=(const char*)sqlite3_column_text(s,0);
  ok=value&&!strcmp(value,expected)&&sqlite3_column_bytes(s,0)==(int)strlen(expected)&&sqlite3_step(s)==SQLITE_DONE;
 }
 sqlite3_finalize(s);return ok;
}
int od_asset_catalog_open(const char *path,const char *manifest,od_asset_catalog **out) {
 if(!out)return -1;
 *out=NULL;if(!path||!valid_hash(manifest))return -1;
 od_asset_catalog *c=calloc(1,sizeof(*c));if(!c)return -1;
 if(sqlite3_open_v2(path,&c->db,SQLITE_OPEN_READONLY|SQLITE_OPEN_FULLMUTEX,NULL)!=SQLITE_OK||
    sqlite3_db_readonly(c->db,"main")!=1||
    sqlite3_exec(c->db,"PRAGMA trusted_schema=OFF",NULL,NULL,NULL)!=SQLITE_OK||
    !metadata(c->db,"schema","1")||!metadata(c->db,"manifest_sha256",manifest)) {
  od_asset_catalog_close(c);return -1;
 }
 *out=c;return 0;
}
int od_asset_catalog_reference(od_asset_catalog *c,const char *path,od_asset_reference *out) {
 if(!c||!out)return -1;
 memset(out,0,sizeof(*out));c->error=NULL;
 if(!valid_path(path))return fail(c,"ASSET_PATH_REJECTED");
 sqlite3_stmt *s=NULL;
 if(sqlite3_prepare_v2(c->db,"SELECT bytes,sha256 FROM assets WHERE path=?1",-1,&s,NULL)!=SQLITE_OK)
  return fail(c,"ASSET_CATALOG_QUERY_FAILED");
 sqlite3_bind_text(s,1,path,-1,SQLITE_TRANSIENT);int row=sqlite3_step(s),ok=0;
 if(row==SQLITE_ROW&&sqlite3_column_type(s,0)==SQLITE_INTEGER&&sqlite3_column_type(s,1)==SQLITE_TEXT) {
  sqlite3_int64 bytes=sqlite3_column_int64(s,0);const char *hash=(const char*)sqlite3_column_text(s,1);
  if(bytes>=0&&bytes<=INT64_C(8589934592)&&hash&&sqlite3_column_bytes(s,1)==64&&valid_hash(hash)) {
   memcpy(out->path,path,strlen(path)+1);memcpy(out->sha256,hash,65);out->bytes=bytes;
   ok=sqlite3_step(s)==SQLITE_DONE;
  }
 }
 sqlite3_finalize(s);
 if(!ok){memset(out,0,sizeof(*out));return fail(c,row==SQLITE_DONE?"ASSET_NOT_CATALOGED":"ASSET_CATALOG_RECORD_INVALID");}
 return 0;
}
int od_asset_catalog_resolve(od_asset_catalog *catalog,od_content *content,const char *path,int *descriptor) {
 if(!descriptor)return -1;
 *descriptor=-1;od_asset_reference ref;
 if(od_asset_catalog_reference(catalog,path,&ref))return -1;
 if(od_content_resolve(content,ref.path,ref.bytes,ref.sha256,descriptor))
  return fail(catalog,od_content_error(content));
 return 0;
}
