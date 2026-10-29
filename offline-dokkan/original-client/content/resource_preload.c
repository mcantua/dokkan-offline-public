#if defined(__APPLE__) && !defined(_DARWIN_C_SOURCE)
#define _DARWIN_C_SOURCE 1
#endif
#define _POSIX_C_SOURCE 200809L
#include "resource_preload.h"
#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#define OD_PRELOAD_MAX_REQUIREMENTS 20000
#define OD_PRELOAD_MAX_CATALOG_BYTES (128LL*1024*1024)
struct od_preload_requirement { char *relative; size_t configured_index; int matched; od_asset_reference reference; };
struct od_iphone_resource_preload {
 od_iphone_resources *resources;
 int root,boundary;
 struct od_preload_requirement *requirements;
 size_t count,alias_count;
 void *context;
 int (*current)(void *);
 const char *error;
};
static int fail(od_iphone_resource_preload *p,const char *code) { if(p)p->error=code;return -1; }
static int directory_dup(int fd) {
 struct stat info;int flags=fcntl(fd,F_GETFL);
 if(flags<0||(flags&O_ACCMODE)!=O_RDONLY||fstat(fd,&info)||!S_ISDIR(info.st_mode))return -1;
 int copy=dup(fd);if(copy<0)return -1;
 if(fcntl(copy,F_SETFD,FD_CLOEXEC)){close(copy);return -1;}
 return copy;
}
static int catalog_dup(int fd) {
 struct stat info;int flags=fcntl(fd,F_GETFL);
 if(flags<0||(flags&O_ACCMODE)!=O_RDONLY||fstat(fd,&info)||!S_ISREG(info.st_mode))return -1;
 int copy=dup(fd);if(copy<0)return -1;
 if(fcntl(copy,F_SETFD,FD_CLOEXEC)){close(copy);return -1;}
 return copy;
}
static int relative_path(const char *s) {
 if(!s||!*s||strlen(s)>1017||*s=='/')return 0;
 const char *part=s;
 for(const unsigned char *at=(const unsigned char*)s;;at++){
  if(*at&&(*at<32||*at==127||strchr("\\:%?#",*at)))return 0;
  if(*at=='/'||!*at){size_t n=(const char*)at-part;
   if(!n||n>255||(n==1&&part[0]=='.')||(n==2&&part[0]=='.'&&part[1]=='.'))return 0;
   part=(const char*)at+1;if(!*at)break;
  }
 }
 return 1;
}
static int requirement_compare(const void *left,const void *right) {
 const struct od_preload_requirement *a=left,*b=right;
 return strcmp(a->relative,b->relative);
}
void od_iphone_resource_preload_close(od_iphone_resource_preload *p) {
 if(!p)return;
 od_iphone_resources_close(p->resources);
 if(p->root>=0)close(p->root);
 if(p->boundary>=0)close(p->boundary);
 for(size_t i=0;i<p->count;i++)free(p->requirements[i].relative);
 free(p->requirements);free(p);
}
const char *od_iphone_resource_preload_error(const od_iphone_resource_preload *p) {
 return p&&p->error?p->error:"IPHONE_PRELOAD_UNAVAILABLE";
}
int od_iphone_resource_preload_open(const od_iphone_resource_preload_configuration *c,
 od_iphone_resource_preload **out) {
 if(!out)return -1;
 *out=NULL;
 if(!c||c->readonly_catalog_descriptor<0||!c->catalog_sha256||!c->manifest_sha256||!c->ipa_sha256||
    !c->bundle_id||!c->source_root||!c->cache_root||!c->context_is_current||
    !c->context_is_current(c->context)||!c->required_asset_relative_paths||
    !c->required_count||c->required_count>OD_PRELOAD_MAX_REQUIREMENTS||
    c->catalog_bytes<100||c->catalog_bytes>OD_PRELOAD_MAX_CATALOG_BYTES)return -1;
 od_iphone_resource_preload *p=calloc(1,sizeof(*p));if(!p)return -1;
 p->root=p->boundary=-1;
 p->context=c->context;p->current=c->context_is_current;
 int catalog=catalog_dup(c->readonly_catalog_descriptor);
 if(catalog<0)goto reject;
 int admitted=od_iphone_resources_open_catalog_fd(catalog,c->catalog_bytes,c->catalog_sha256,
  c->manifest_sha256,c->ipa_sha256,c->bundle_id,c->source_root,c->cache_root,&p->resources);
 close(catalog);
 if(admitted||!p->current(p->context))goto reject;
 p->root=directory_dup(c->attested_asset_root_descriptor);
 p->boundary=directory_dup(c->attested_working_boundary_descriptor);
 if(p->root<0||p->boundary<0)goto reject;
 p->requirements=calloc(c->required_count,sizeof(*p->requirements));if(!p->requirements)goto reject;
 p->count=c->required_count;
 for(size_t i=0;i<p->count;i++){
  const char *relative=c->required_asset_relative_paths[i];if(!relative_path(relative))goto reject;
  p->requirements[i].relative=strdup(relative);if(!p->requirements[i].relative)goto reject;
  p->requirements[i].configured_index=i;
 }
 qsort(p->requirements,p->count,sizeof(*p->requirements),requirement_compare);
 for(size_t i=1;i<p->count;i++)if(!strcmp(p->requirements[i-1].relative,p->requirements[i].relative))goto reject;
 *out=p;return 0;
reject:od_iphone_resource_preload_close(p);return -1;
}
static int match_alias(const char *alias,const od_asset_reference *reference,void *context) {
 od_iphone_resource_preload *p=context;(void)alias;
 if(++p->alias_count>OD_PRELOAD_MAX_REQUIREMENTS||!p->current(p->context))return -1;
 if(strncmp(reference->path,"assets/",7)||!relative_path(reference->path+7))return -1;
 size_t low=0,high=p->count;
 while(low<high){
  size_t middle=low+(high-low)/2;struct od_preload_requirement *r=&p->requirements[middle];
  int order=strcmp(r->relative,reference->path+7);
  if(order<0)low=middle+1;
  else if(order>0)high=middle;
  else {
   if(r->matched&&(r->reference.bytes!=reference->bytes||
      strcmp(r->reference.sha256,reference->sha256)))return -1;
   r->reference=*reference;r->matched=1;break;
  }
 }
 return 0;
}
int od_iphone_resource_preload_run(od_iphone_resource_preload *p,
 od_iphone_resource_preload_receipt *receipt) {
 if(!p||!receipt)return -1;
 memset(receipt,0,sizeof(*receipt));receipt->failed_requirement_index=-1;
 receipt->configured_required_count=p->count;p->error=NULL;p->alias_count=0;
 if(!p->current(p->context))return fail(p,"IPHONE_PRELOAD_CONTEXT_CHANGED");
 for(size_t i=0;i<p->count;i++)p->requirements[i].matched=0;
 int enumerated=od_iphone_resources_visit_aliases(p->resources,match_alias,p);
 receipt->verified_alias_count=p->alias_count;
 if(enumerated){
  if(!p->current(p->context))return fail(p,"IPHONE_PRELOAD_CONTEXT_CHANGED");
  return fail(p,"IPHONE_PRELOAD_ALIAS_ADMISSION_FAILED");
 }
 for(size_t i=0;i<p->count;i++){
  if(p->requirements[i].matched)receipt->matched_required_count++;
  else receipt->missing_required_count++;
 }
 if(receipt->missing_required_count)return fail(p,"IPHONE_PRELOAD_REQUIREMENTS_INCOMPLETE");
 for(size_t i=0;i<p->count;i++){
  if(!p->current(p->context))return fail(p,"IPHONE_PRELOAD_CONTEXT_CHANGED");
  int created=0;
  int result=od_iphone_resources_publish_asset(p->resources,p->root,p->boundary,
   p->requirements[i].relative,&created);
  if(created)receipt->newly_published_files++;
  if(result){receipt->failed_requirement_index=(int)p->requirements[i].configured_index;return fail(p,"IPHONE_PRELOAD_PUBLICATION_FAILED");}
  receipt->successful_publications++;
  if(!created)receipt->existing_verified_files++;
 }
 if(!p->current(p->context))return fail(p,"IPHONE_PRELOAD_CONTEXT_CHANGED");
 receipt->configured_paths_complete=1;
 return 0;
}
