#if defined(__APPLE__) && !defined(_DARWIN_C_SOURCE)
#define _DARWIN_C_SOURCE 1
#endif
#define _POSIX_C_SOURCE 200809L
#include "iphone_resources.h"
#include <errno.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sqlite3.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <unistd.h>

struct od_iphone_resources {
 sqlite3 *db;od_asset_catalog *catalog;od_content *content;
 char prefix[513];const char *error;
 int source_root,cache_root;unsigned long publication_serial;
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
 if(r->source_root>=0)close(r->source_root);
 if(r->cache_root>=0)close(r->cache_root);
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
 r->source_root=r->cache_root=-1;
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
 r->source_root=open(source,O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);
 r->cache_root=open(cache,O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);
 if(r->source_root<0||r->cache_root<0)goto reject;
 *out=r;return 0;
reject:od_iphone_resources_close(r);return -1;
}
static int same_catalog_file(struct stat before,struct stat after) {
 if(!S_ISREG(before.st_mode)||!S_ISREG(after.st_mode)||before.st_dev!=after.st_dev||
    before.st_ino!=after.st_ino||before.st_size!=after.st_size)return 0;
#if defined(__APPLE__)
 return before.st_mtimespec.tv_sec==after.st_mtimespec.tv_sec&&before.st_mtimespec.tv_nsec==after.st_mtimespec.tv_nsec;
#else
 return before.st_mtim.tv_sec==after.st_mtim.tv_sec&&before.st_mtim.tv_nsec==after.st_mtim.tv_nsec;
#endif
}
int od_iphone_resources_open_catalog_fd(int fd,int64_t bytes,const char *catalog_hash,
 const char *manifest,const char *ipa,const char *bundle,const char *source,const char *cache,
 od_iphone_resources **out) {
 if(!out)return -1;
 *out=NULL;
 if(fd<0||bytes<100||bytes>128LL*1024*1024||!valid_hash(catalog_hash)||
    !valid_hash(manifest)||!valid_hash(ipa)||!bundle||!source||!cache)return -1;
 int flags=fcntl(fd,F_GETFL);struct stat before,after;
 if(flags<0||(flags&O_ACCMODE)!=O_RDONLY||fstat(fd,&before)||
    !S_ISREG(before.st_mode)||before.st_size!=bytes)return -1;
 unsigned char *snapshot=sqlite3_malloc64((sqlite3_uint64)bytes+32);
 if(!snapshot)return -1;
 int64_t total=0;
 while(total<bytes){
  size_t take=65536;if(bytes-total<(int64_t)take)take=(size_t)(bytes-total);
  ssize_t n=pread(fd,snapshot+(size_t)total,take,(off_t)total);
  if(n<0&&errno==EINTR)continue;
  if(n<=0){sqlite3_free(snapshot);return -1;}
  total+=n;
 }
 if(fstat(fd,&after)||!same_catalog_file(before,after)||
    od_content_verify_bytes(snapshot,bytes,catalog_hash)||
    memcmp(snapshot,"SQLite format 3",16)||snapshot[18]!=1||snapshot[19]!=1){
  sqlite3_free(snapshot);return -1;
 }
 /* SQLite recommends extra zero padding for malformed-image read bounds. The
    admitted image itself is not edited and WAL images are refused, not fixed. */
 memset(snapshot+(size_t)bytes,0,32);
 od_iphone_resources *r=calloc(1,sizeof(*r));
 if(!r){sqlite3_free(snapshot);return -1;}
 r->source_root=r->cache_root=-1;
 if(sqlite3_open_v2(":memory:",&r->db,SQLITE_OPEN_READWRITE|SQLITE_OPEN_CREATE|SQLITE_OPEN_FULLMUTEX,NULL)!=SQLITE_OK){
  sqlite3_free(snapshot);od_iphone_resources_close(r);return -1;
 }
 int loaded=sqlite3_deserialize(r->db,"main",snapshot,(sqlite3_int64)bytes,
  (sqlite3_int64)bytes+32,SQLITE_DESERIALIZE_READONLY|SQLITE_DESERIALIZE_FREEONCLOSE);
 /* FREEONCLOSE frees snapshot on deserialize failure too; never free twice. */
 snapshot=NULL;
 if(loaded!=SQLITE_OK||sqlite3_exec(r->db,"PRAGMA query_only=ON;PRAGMA trusted_schema=OFF",NULL,NULL,NULL)!=SQLITE_OK||
    !expected(r->db,"schema","1")||!expected(r->db,"verified_alias_schema","1")||
    !expected(r->db,"manifest_sha256",manifest)||!expected(r->db,"ipa_sha256",ipa)||
    !expected(r->db,"iphone_bundle_id",bundle)||!meta(r->db,"iphone_app_prefix",r->prefix,sizeof(r->prefix)))goto reject;
 size_t length=strlen(r->prefix);
 if(length<14||strncmp(r->prefix,"Payload/",8)||strcmp(r->prefix+length-5,".app/")||
    strchr(r->prefix+8,'/')!=r->prefix+length-1||od_content_open(source,cache,&r->content))goto reject;
 r->source_root=open(source,O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);
 r->cache_root=open(cache,O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);
 if(r->source_root<0||r->cache_root<0)goto reject;
 *out=r;return 0;
reject:od_iphone_resources_close(r);return -1;
}
static int snapshot_asset_reference(od_iphone_resources *r,const char *path,od_asset_reference *out) {
 /* Legacy resources use the existing catalog handle. FD composition uses
    this same typed assets query against its one immutable admitted snapshot. */
 if(r->catalog)return od_asset_catalog_reference(r->catalog,path,out);
 if(strncmp(path,"assets/",7)||!valid_relative(path)||!strcmp(path,"assets/User")||
    !strncmp(path,"assets/User/",12))return -1;
 sqlite3_stmt *s=NULL;
 if(sqlite3_prepare_v2(r->db,"SELECT bytes,sha256 FROM assets WHERE path=?1",-1,&s,NULL)!=SQLITE_OK)return -1;
 if(sqlite3_bind_text(s,1,path,-1,SQLITE_TRANSIENT)!=SQLITE_OK){sqlite3_finalize(s);return -1;}
 int ok=0;
 if(sqlite3_step(s)==SQLITE_ROW&&sqlite3_column_type(s,0)==SQLITE_INTEGER&&sqlite3_column_type(s,1)==SQLITE_TEXT){
  sqlite3_int64 length=sqlite3_column_int64(s,0);const char *hash=(const char*)sqlite3_column_text(s,1);
  if(length>=0&&length<=INT64_C(8589934592)&&hash&&sqlite3_column_bytes(s,1)==64&&valid_hash(hash)){
   memcpy(out->path,path,strlen(path)+1);memcpy(out->sha256,hash,65);out->bytes=length;
   ok=sqlite3_step(s)==SQLITE_DONE;
  }
 }
 sqlite3_finalize(s);if(!ok)memset(out,0,sizeof(*out));return ok?0:-1;
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
 if(snapshot_asset_reference(r,path,out))return fail(r,"IPHONE_RESOURCE_REFERENCE_INVALID");
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
int od_iphone_resources_asset_reference(od_iphone_resources *r,const char *relative,
 od_asset_reference *out) {
 if(!r||!out)return -1;
 memset(out,0,sizeof(*out));r->error=NULL;
 if(!valid_relative(relative)||strlen(relative)>1017)
  return fail(r,"IPHONE_RESOURCE_PATH_REJECTED");
 char canonical[1025];memcpy(canonical,"assets/",7);memcpy(canonical+7,relative,strlen(relative)+1);
 sqlite3_stmt *s=NULL;
 if(sqlite3_prepare_v2(r->db,"SELECT zip_entry FROM ipa_matches WHERE path=?1",-1,&s,NULL)!=SQLITE_OK)
  return fail(r,"IPHONE_RESOURCE_CATALOG_INVALID");
 int bound=sqlite3_bind_text(s,1,canonical,-1,SQLITE_TRANSIENT);
 int row=bound==SQLITE_OK?sqlite3_step(s):SQLITE_ERROR,ok=0;
 char entry[1537];size_t prefix=strlen(r->prefix);
 if(row==SQLITE_ROW&&sqlite3_column_type(s,0)==SQLITE_TEXT) {
  const char *value=(const char*)sqlite3_column_text(s,0);int n=sqlite3_column_bytes(s,0);
  if(value&&n>0&&(size_t)n>prefix&&n<=1536&&strlen(value)==(size_t)n&&
     !memcmp(value,r->prefix,prefix)&&valid_relative(value+prefix)) {
   memcpy(entry,value,(size_t)n+1);ok=sqlite3_step(s)==SQLITE_DONE;
  }
 }
 sqlite3_finalize(s);
 if(!ok)return fail(r,row==SQLITE_DONE?"IPHONE_RESOURCE_NOT_ADMITTED":"IPHONE_RESOURCE_CATALOG_INVALID");
 /* Reuse exact alias validation; a preferred mapping alone is not enough. */
 if(od_iphone_resources_reference(r,entry+prefix,out))
  return fail(r,"IPHONE_RESOURCE_CATALOG_INVALID");
 if(strcmp(out->path,canonical)) {
  memset(out,0,sizeof(*out));return fail(r,"IPHONE_RESOURCE_CATALOG_INVALID");
 }
 return 0;
}
int od_iphone_resources_visit_aliases(od_iphone_resources *r,
 od_iphone_resource_alias_visitor visitor,void *context) {
 if(!r||!visitor)return -1;
 r->error=NULL;sqlite3_stmt *s=NULL;
 if(sqlite3_prepare_v2(r->db,"SELECT zip_entry FROM ipa_aliases ORDER BY zip_entry LIMIT 20001",-1,&s,NULL)!=SQLITE_OK)
  return fail(r,"IPHONE_RESOURCE_CATALOG_INVALID");
 int row;size_t count=0,prefix=strlen(r->prefix);
 while((row=sqlite3_step(s))==SQLITE_ROW){
  if(count>=20000||sqlite3_column_type(s,0)!=SQLITE_TEXT){sqlite3_finalize(s);return fail(r,"IPHONE_RESOURCE_CATALOG_INVALID");}
  const char *entry=(const char*)sqlite3_column_text(s,0);int length=sqlite3_column_bytes(s,0);
  if(!entry||length<1||(size_t)length<=prefix||length>1536||strlen(entry)!=(size_t)length||
     memcmp(entry,r->prefix,prefix)||!valid_relative(entry+prefix)){
   sqlite3_finalize(s);return fail(r,"IPHONE_RESOURCE_CATALOG_INVALID");
  }
  char relative[1025];size_t n=(size_t)length-prefix;
  if(n>1024){sqlite3_finalize(s);return fail(r,"IPHONE_RESOURCE_CATALOG_INVALID");}
  memcpy(relative,entry+prefix,n+1);od_asset_reference reference;
  if(od_iphone_resources_reference(r,relative,&reference)){
   int unadmitted=r->error&&!strcmp(r->error,"IPHONE_RESOURCE_NOT_ADMITTED");
   sqlite3_finalize(s);return fail(r,unadmitted?"IPHONE_RESOURCE_CATALOG_UNADMITTED_ALIAS":"IPHONE_RESOURCE_CATALOG_INVALID");
  }
  count++;
  if(visitor(relative,&reference,context)){sqlite3_finalize(s);return fail(r,"IPHONE_RESOURCE_VISITOR_ABORTED");}
 }
 sqlite3_finalize(s);
 if(row!=SQLITE_DONE||!count)return fail(r,"IPHONE_RESOURCE_CATALOG_INVALID");
 return 0;
}
static int publishable_resource(const char *relative) {
 if(!valid_relative(relative))return 0;
 static const char *const roots[]={"bgm","se","voice","layout","outgame","character","script","item",
  "ingame","sd_battle","sugoroku","movie","card_category","lua","gasha","packaged_movies",
  "card_transform","potential","dokkan_field","mydata","download_scene","origin","card_metamorphic",
  "kobetu_battle","fonts","shader","card_costume","card","thumb","condition_special","panel_mission",
  "comic_text","dbstory","genkai_battle"};
 static const char *const extensions[]={".cpk",".acb",".awb",".ttf",".otf",".png",".pvr",
  ".ktx",".webp",".vsh",".fsh",".lua",".luac"};
 const char *slash=strchr(relative,'/');if(!slash)return 0;
 size_t root_length=(size_t)(slash-relative);int allowed=0;
 for(size_t i=0;i<sizeof(roots)/sizeof(roots[0]);i++)
  if(strlen(roots[i])==root_length&&!memcmp(relative,roots[i],root_length)){allowed=1;break;}
 if(!allowed)return 0;
 const char *part=relative;
 for(;;){const char *end=strchr(part,'/');size_t n=end?(size_t)(end-part):strlen(part);
  if(n==4&&(!strncasecmp(part,"save",4)||!strncasecmp(part,"User",4)))return 0;
  if(!end)break;
  part=end+1;
 }
 const char *extension=strrchr(part,'.');if(!extension)return 0;
 for(size_t i=0;i<sizeof(extensions)/sizeof(extensions[0]);i++)
  if(!strcasecmp(extension,extensions[i]))return 1;
 return 0;
}
static int same_directory(int left,int right) {
 struct stat a,b;
 return !fstat(left,&a)&&!fstat(right,&b)&&a.st_dev==b.st_dev&&a.st_ino==b.st_ino;
}
static int working_root_safe(od_iphone_resources *r,int root,int boundary) {
 struct stat source,cache,limit;
 int boundary_flags=fcntl(boundary,F_GETFL);
 if(boundary_flags<0||(boundary_flags&O_ACCMODE)!=O_RDONLY||
    fstat(boundary,&limit)||!S_ISDIR(limit.st_mode)||
    fstat(r->source_root,&source)||fstat(r->cache_root,&cache)||
    !S_ISDIR(source.st_mode)||!S_ISDIR(cache.st_mode))return 0;
 int current=dup(root);if(current<0)return 0;
 if(fcntl(current,F_SETFD,FD_CLOEXEC)){close(current);return 0;}
 int safe=0;
 for(int depth=0;depth<128;depth++){
  struct stat here,above;
  if(fstat(current,&here)||!S_ISDIR(here.st_mode)||
     (here.st_dev==source.st_dev&&here.st_ino==source.st_ino)||
     (here.st_dev==cache.st_dev&&here.st_ino==cache.st_ino))break;
  /* Stop inside the app's attested working namespace, before its sandbox
     boundary would make traversal above the container unavailable. */
  if(here.st_dev==limit.st_dev&&here.st_ino==limit.st_ino){safe=1;break;}
  int parent=openat(current,"..",O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);
  if(parent<0)break;
  if(fstat(parent,&above)){close(parent);break;}
  if(here.st_dev==above.st_dev&&here.st_ino==above.st_ino){close(parent);break;}
  close(current);current=parent;
 }
 close(current);return safe;
}
static int existing_published(int parent,const char *name,const od_asset_reference *reference) {
 int fd=openat(parent,name,O_RDONLY|O_NOFOLLOW|O_NONBLOCK|O_CLOEXEC);
 if(fd<0)return errno==ENOENT?1:-1;
 struct stat st,after;
 int ok=!fstat(fd,&st)&&S_ISREG(st.st_mode)&&!(st.st_mode&0222)&&
  !od_content_verify_readonly_fd(fd,reference->bytes,reference->sha256)&&
  !fstat(fd,&after)&&S_ISREG(after.st_mode)&&!(after.st_mode&0222)&&
  st.st_dev==after.st_dev&&st.st_ino==after.st_ino;
 close(fd);return ok?0:-1;
}
static int resource_parent(od_iphone_resources *r,int root,const char *relative,char leaf[256]) {
 char copy[1025];size_t length=strlen(relative);if(length>1024)return -1;
 memcpy(copy,relative,length+1);
 int parent=dup(root);if(parent<0)return -1;
 if(fcntl(parent,F_SETFD,FD_CLOEXEC)){close(parent);return -1;}
 char *part=copy,*slash;
 while((slash=strchr(part,'/'))!=NULL){
  *slash=0;int created=0;
  int next=openat(parent,part,O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);
  if(next<0&&errno==ENOENT){
   if(!mkdirat(parent,part,0700))created=1;
   else if(errno!=EEXIST){close(parent);return -1;}
   next=openat(parent,part,O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);
  }
  if(next<0||same_directory(next,r->source_root)||same_directory(next,r->cache_root)||
     (created&&fsync(parent))){if(next>=0)close(next);close(parent);return -1;}
  close(parent);parent=next;part=slash+1;
 }
 if(!*part||strlen(part)>255){close(parent);return -1;}
 memcpy(leaf,part,strlen(part)+1);return parent;
}
int od_iphone_resources_publish_asset(od_iphone_resources *r,int root,int boundary,const char *relative,int *published) {
 if(published)*published=0;
 if(!r||!published||root<0||boundary<0)return -1;
 if(!publishable_resource(relative))return fail(r,"IPHONE_RESOURCE_PUBLICATION_PATH_REJECTED");
 od_asset_reference reference;
 /* Unknown paths must not create even an empty destination directory. */
 if(od_iphone_resources_asset_reference(r,relative,&reference))return -1;
 struct stat identity;int flags=fcntl(root,F_GETFL);
 if(flags<0||(flags&O_ACCMODE)!=O_RDONLY||fstat(root,&identity)||!S_ISDIR(identity.st_mode)||
    !working_root_safe(r,root,boundary))
  return fail(r,"IPHONE_RESOURCE_PUBLICATION_ROOT_INVALID");
 char leaf[256];int parent=resource_parent(r,root,relative,leaf);
 if(parent<0)return fail(r,"IPHONE_RESOURCE_PUBLICATION_PATH_UNSAFE");
 int existing=existing_published(parent,leaf,&reference);
 if(existing==0){int durable=fsync(parent);close(parent);return durable?fail(r,"IPHONE_RESOURCE_PUBLICATION_NOT_DURABLE"):0;}
 if(existing<0){close(parent);return fail(r,"IPHONE_RESOURCE_PUBLICATION_CONFLICT");}
 int source=-1;
 if(od_content_resolve(r->content,reference.path,reference.bytes,reference.sha256,&source)){
  close(parent);return fail(r,"IPHONE_RESOURCE_CONTENT_UNAVAILABLE");
 }
 char stage[96];int destination=-1;
 for(int i=0;i<128;i++){
  snprintf(stage,sizeof(stage),".od-iphone-resource-%ld-%lu.part",(long)getpid(),++r->publication_serial);
  destination=openat(parent,stage,O_WRONLY|O_CREAT|O_EXCL|O_NOFOLLOW|O_CLOEXEC,0600);
  if(destination>=0||errno!=EEXIST)break;
 }
 if(destination<0){close(source);close(parent);return fail(r,"IPHONE_RESOURCE_PUBLICATION_STAGE_FAILED");}
 int ok=1;int64_t total=0;unsigned char buffer[65536];
 while(total<reference.bytes){
  size_t take=sizeof(buffer);if(reference.bytes-total<(int64_t)take)take=(size_t)(reference.bytes-total);
  ssize_t n=pread(source,buffer,take,(off_t)total);
  if(n<0&&errno==EINTR)continue;
  if(n<=0){ok=0;break;}
  size_t offset=0;
  while(offset<(size_t)n){ssize_t wrote=write(destination,buffer+offset,(size_t)n-offset);
   if(wrote<0&&errno==EINTR)continue;
   if(wrote<=0){ok=0;break;}
   offset+=(size_t)wrote;
  }
  if(!ok)break;
  total+=n;
 }
 close(source);
 if(total!=reference.bytes||fsync(destination)||fchmod(destination,0400)||fsync(destination))ok=0;
 struct stat staged={0};if(fstat(destination,&staged))ok=0;
 if(close(destination))ok=0;
 int review=ok?openat(parent,stage,O_RDONLY|O_NOFOLLOW|O_NONBLOCK|O_CLOEXEC):-1;
 struct stat checked={0};
 if(review<0||fstat(review,&checked)||!S_ISREG(checked.st_mode)||(checked.st_mode&0222)||
    checked.st_dev!=staged.st_dev||checked.st_ino!=staged.st_ino||
    od_content_verify_readonly_fd(review,reference.bytes,reference.sha256))ok=0;
 if(review>=0)close(review);
 if(!ok){unlinkat(parent,stage,0);close(parent);return fail(r,"IPHONE_RESOURCE_PUBLICATION_INTEGRITY_FAILED");}
 int linked=linkat(parent,stage,parent,leaf,0),saved=errno;
 if(linked==0)*published=1;
 /* Only this exclusive staging file is removed; a final/conflicting file stays. */
 int removed=unlinkat(parent,stage,0);
 if(linked&&saved!=EEXIST){close(parent);return fail(r,"IPHONE_RESOURCE_PUBLICATION_FAILED");}
 if(existing_published(parent,leaf,&reference)){close(parent);return fail(r,"IPHONE_RESOURCE_PUBLICATION_CONFLICT");}
 int durable=fsync(parent);close(parent);
 if(removed||durable)return fail(r,"IPHONE_RESOURCE_PUBLICATION_NOT_DURABLE");
 return 0;
}
static FILE *reference_stream(od_iphone_resources *r,const od_asset_reference *reference,
 const char *mode) {
 int fd=-1;
 if(od_content_resolve(r->content,reference->path,reference->bytes,reference->sha256,&fd)) {
  fail(r,"IPHONE_RESOURCE_CONTENT_UNAVAILABLE");errno=EIO;return NULL;
 }
 FILE *stream=fdopen(fd,mode);
 if(!stream){int saved=errno;close(fd);errno=saved;}
 return stream;
}
FILE *od_iphone_resources_fopen_asset_root(od_iphone_resources *r,const char *root,
 const char *path,const char *mode,FILE *(*original)(const char *,const char *)) {
 if(!original||!path||!mode){errno=EINVAL;return NULL;}
 if(!r||!root||(strcmp(mode,"r")&&strcmp(mode,"rb")))return original(path,mode);
 if(root[0]!='/'||!valid_relative(root+1)){errno=EINVAL;return NULL;}
 size_t length=strlen(root);
 if(strncmp(path,root,length)||path[length]!='/')return original(path,mode);
 const char *relative=path+length+1;
 if(!valid_relative(relative)){errno=EINVAL;return NULL;}
 od_asset_reference reference;
 if(od_iphone_resources_asset_reference(r,relative,&reference)) {
  if(r->error&&!strcmp(r->error,"IPHONE_RESOURCE_NOT_ADMITTED"))return original(path,mode);
  errno=EIO;return NULL;
 }
 return reference_stream(r,&reference,mode);
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
 return reference_stream(r,&reference,mode);
}
