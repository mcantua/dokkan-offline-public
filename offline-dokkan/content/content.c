#if defined(__APPLE__) && !defined(_DARWIN_C_SOURCE)
#define _DARWIN_C_SOURCE 1
#endif
#define _POSIX_C_SOURCE 200809L
#include "content.h"
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

/* SHA-256, implemented here from FIPS 180-4. No private game/key material. */
typedef struct { uint32_t h[8]; uint64_t bytes; unsigned char block[64]; size_t used; } sha_state;
static const uint32_t sha_k[64] = {
 0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
 0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
 0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
 0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
 0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
 0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
 0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
 0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2};
static uint32_t ror(uint32_t x, unsigned n) { return (x >> n) | (x << (32-n)); }
static void sha_block(sha_state *s, const unsigned char *p) {
 uint32_t w[64],a,b,c,d,e,f,g,h;
 for(int i=0;i<16;i++) w[i]=((uint32_t)p[i*4]<<24)|((uint32_t)p[i*4+1]<<16)|((uint32_t)p[i*4+2]<<8)|p[i*4+3];
 for(int i=16;i<64;i++) { uint32_t x=w[i-15],y=w[i-2]; w[i]=w[i-16]+(ror(x,7)^ror(x,18)^(x>>3))+w[i-7]+(ror(y,17)^ror(y,19)^(y>>10)); }
 a=s->h[0];b=s->h[1];c=s->h[2];d=s->h[3];e=s->h[4];f=s->h[5];g=s->h[6];h=s->h[7];
 for(int i=0;i<64;i++) { uint32_t t=h+(ror(e,6)^ror(e,11)^ror(e,25))+((e&f)^(~e&g))+sha_k[i]+w[i];
  uint32_t u=(ror(a,2)^ror(a,13)^ror(a,22))+((a&b)^(a&c)^(b&c));h=g;g=f;f=e;e=d+t;d=c;c=b;b=a;a=t+u; }
 s->h[0]+=a;s->h[1]+=b;s->h[2]+=c;s->h[3]+=d;s->h[4]+=e;s->h[5]+=f;s->h[6]+=g;s->h[7]+=h;
}
static void sha_init(sha_state *s) {
 static const uint32_t initial[8]={0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19};
 memset(s,0,sizeof(*s)); memcpy(s->h,initial,sizeof(initial));
}
static void sha_add(sha_state *s,const unsigned char *p,size_t n) {
 s->bytes+=n;
 while(n) { size_t take=64-s->used;if(take>n)take=n;memcpy(s->block+s->used,p,take);s->used+=take;p+=take;n-=take;
  if(s->used==64){sha_block(s,s->block);s->used=0;} }
}
static void sha_finish(sha_state *s,char hex[65]) {
 uint64_t bits=s->bytes*8;s->block[s->used++]=0x80;
 if(s->used>56){memset(s->block+s->used,0,64-s->used);sha_block(s,s->block);s->used=0;}
 memset(s->block+s->used,0,56-s->used);for(int i=0;i<8;i++)s->block[63-i]=(unsigned char)(bits>>(i*8));sha_block(s,s->block);
 for(int i=0;i<8;i++)snprintf(hex+i*8,9,"%08x",s->h[i]);
 hex[64]=0;
}

struct od_content { int source,cache; unsigned long serial; const char *error; };
static int fail(od_content *c,const char *why) { if(c)c->error=why;return -1; }
const char *od_content_error(const od_content *c) { return c&&c->error?c->error:"CONTENT_UNAVAILABLE"; }
void od_content_close(od_content *c) { if(c){if(c->source>=0)close(c->source);if(c->cache>=0)close(c->cache);free(c);} }
int od_content_open(const char *source,const char *cache,od_content **out) {
 if(!out)return -1;
 *out=NULL;
 if(!source||!cache)return -1;
 od_content *c=calloc(1,sizeof(*c));if(!c)return -1;c->source=c->cache=-1;
 c->source=open(source,O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);
 c->cache=open(cache,O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);
 struct stat a,b;
 if(c->source<0||c->cache<0||fstat(c->source,&a)||fstat(c->cache,&b)||
    (a.st_dev==b.st_dev&&a.st_ino==b.st_ino)){od_content_close(c);return -1;}
 *out=c;return 0;
}
static int valid_path(const char *s) {
 if(!s||!*s||strlen(s)>4096||*s=='/')return 0;
 const char *part=s;
 for(const unsigned char *p=(const unsigned char*)s;;p++) {
  if(*p&&(*p<32||*p==127||*p=='\\'||*p==':'||*p=='%'||*p=='?'||*p=='#'))return 0;
  if(*p=='/'||!*p) {size_t n=(const char*)p-part;if(!n||(n==1&&part[0]=='.')||(n==2&&part[0]=='.'&&part[1]=='.')||n>255)return 0;
   part=(const char*)p+1;if(!*p)break;}
 }
 return 1;
}
static int source_fd(od_content *c,const char *path) {
 char *copy=strdup(path);if(!copy)return -1;
 int dir=dup(c->source),fd=-1;char *part=copy,*slash;
 while(dir>=0) { slash=strchr(part,'/');if(slash)*slash=0;
  int next=openat(dir,part,O_RDONLY|O_NOFOLLOW|O_CLOEXEC|O_NONBLOCK|(slash?O_DIRECTORY:0));close(dir);dir=-1;
  if(next<0)break;
  if(!slash){fd=next;break;}
  dir=next;part=slash+1;
 }
 free(copy);return fd;
}
static int full_write(int fd,const unsigned char *p,size_t n) {
 while(n){ssize_t done=write(fd,p,n);if(done<0&&errno==EINTR)continue;if(done<=0)return -1;p+=done;n-=(size_t)done;}return 0;
}
static int verify_copy(int from,int to,int64_t expected,const char *hash) {
 struct stat before,after;if(fstat(from,&before)||!S_ISREG(before.st_mode)||before.st_size!=expected)return -1;
 if(lseek(from,0,SEEK_SET)<0)return -1;
 sha_state sha;sha_init(&sha);int64_t total=0;unsigned char buffer[65536];
 for(;;){ssize_t n=read(from,buffer,sizeof(buffer));if(n<0&&errno==EINTR)continue;if(n<0)return -1;if(!n)break;
  if(n>expected-total)return -1;
  if(to>=0&&full_write(to,buffer,(size_t)n))return -1;
  sha_add(&sha,buffer,(size_t)n);total+=n;}
 char hex[65];sha_finish(&sha,hex);
 if(total!=expected||strcmp(hex,hash)||fstat(from,&after)||before.st_dev!=after.st_dev||before.st_ino!=after.st_ino||before.st_size!=after.st_size)return -1;
 return 0;
}
static int cached(od_content *c,const char *hash,int64_t bytes,int *out) {
 int fd=openat(c->cache,hash,O_RDONLY|O_NOFOLLOW|O_CLOEXEC|O_NONBLOCK);
 if(fd<0)return errno==ENOENT?1:fail(c,"CACHE_OPEN_FAILED");
 if(verify_copy(fd,-1,bytes,hash)||lseek(fd,0,SEEK_SET)<0){close(fd);return fail(c,"CACHE_INTEGRITY_FAILED");}
 *out=fd;return 0;
}
int od_content_resolve(od_content *c,const char *path,int64_t bytes,const char *hash,int *out) {
 if(!c||!out)return -1;
 *out=-1;c->error=NULL;
 if(!valid_path(path)||bytes<0||bytes>INT64_MAX/8||!hash||strlen(hash)!=64)return fail(c,"CONTENT_REFERENCE_INVALID");
 for(int i=0;i<64;i++)if(!((hash[i]>='0'&&hash[i]<='9')||(hash[i]>='a'&&hash[i]<='f')))return fail(c,"CONTENT_REFERENCE_INVALID");
 int hit=cached(c,hash,bytes,out);if(hit<=0)return hit;
 int from=source_fd(c,path);if(from<0)return fail(c,"CONTENT_MISSING_OR_UNSAFE");
 char part[96];int to=-1;
 for(int i=0;i<128;i++) {snprintf(part,sizeof(part),".od-content-%ld-%lu.part",(long)getpid(),++c->serial);
  to=openat(c->cache,part,O_WRONLY|O_CREAT|O_EXCL|O_NOFOLLOW|O_CLOEXEC,0600);if(to>=0||errno!=EEXIST)break;}
 if(to<0){close(from);return fail(c,"CACHE_STAGE_FAILED");}
 int ok=verify_copy(from,to,bytes,hash)==0&&fsync(to)==0&&fchmod(to,0400)==0;
 close(from);if(close(to))ok=0;
 if(!ok){unlinkat(c->cache,part,0);return fail(c,"CONTENT_INTEGRITY_FAILED");}
 /* linkat refuses to replace an existing file. Concurrent identical imports are safe. */
 int promoted=linkat(c->cache,part,c->cache,hash,0);int saved_errno=errno;
 unlinkat(c->cache,part,0);
 if(promoted&&saved_errno!=EEXIST)return fail(c,"CACHE_PROMOTION_FAILED");
 if(fsync(c->cache))return fail(c,"CACHE_SYNC_FAILED");
 hit=cached(c,hash,bytes,out);return hit==1?fail(c,"CACHE_PROMOTION_FAILED"):hit;
}
int od_content_require(od_content *c,const od_content_ref *refs,int count) {
 if(!c||!refs||count<1||count>100000)return fail(c,"CONTENT_REQUIREMENTS_UNKNOWN");
 for(int i=0;i<count;i++){int fd=-1;if(od_content_resolve(c,refs[i].path,refs[i].bytes,refs[i].sha256,&fd))return -1;close(fd);}return 0;
}
