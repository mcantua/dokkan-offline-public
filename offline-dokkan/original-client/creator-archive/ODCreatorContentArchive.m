#import "ODCreatorContentArchive.h"
#import <CommonCrypto/CommonDigest.h>
#include "zip_stream.h"
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <dirent.h>
#include <errno.h>
#include <stdatomic.h>
#include <math.h>

static NSString *const ODArchiveName=@"Creations-for-reinstall.zip";
static const NSUInteger ODManifestLimit=8*1024*1024,ODGalleryLimit=16*1024*1024;
static BOOL ODMatch(NSString *s,NSString *pattern){return [s isKindOfClass:NSString.class]&&[s rangeOfString:pattern options:NSRegularExpressionSearch].location!=NSNotFound;}
static BOOL ODInteger(id n){return [n isKindOfClass:NSNumber.class]&&CFGetTypeID((__bridge CFTypeRef)n)!=CFBooleanGetTypeID()&&isfinite([n doubleValue])&&[n doubleValue]==[n longLongValue]&&[n longLongValue]>=0;}
static BOOL ODPrivate(NSString *part){
    static NSSet *names;static dispatch_once_t once;dispatch_once(&once,^{names=[NSSet setWithArray:@[@"_databases",@"databases",@"user",@"shared_prefs",@"ai-connections.json",@"credentials.json",@"secrets.json",@"account.txt",@"sprk-format-key.bin",@"sparking-database-format.bin",@"signing",@"key-info.txt"]];});
    return [part hasPrefix:@"."]||[names containsObject:part.lowercaseString];
}
static BOOL ODRelative(NSString *path){
    if(![path isKindOfClass:NSString.class]||!path.length||path.length>500||[path hasPrefix:@"/"]||
       [path rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\\:%"]].location!=NSNotFound||
       [path rangeOfCharacterFromSet:NSCharacterSet.controlCharacterSet].location!=NSNotFound)return NO;
    for(NSString *part in [path componentsSeparatedByString:@"/"])if(!part.length||ODPrivate(part))return NO;
    return YES;
}
static BOOL ODPath(NSString *path){
    if(!ODRelative(path))return NO;
    NSString *key=@"[A-Za-z0-9_-]{1,100}",*uuid=@"[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}";
    if(ODMatch(path,[NSString stringWithFormat:@"^projects/%@\\.json$",key])||
       ODMatch(path,[NSString stringWithFormat:@"^project-versions/%@/(index\\.json|%@\\.version)$",key,uuid])||
       ODMatch(path,[NSString stringWithFormat:@"^patches/%@\\.(json|eclp)$",uuid])||
       ODMatch(path,[NSString stringWithFormat:@"^animation-gallery/%@\\.json$",key]))return YES;
    NSArray *parts=[path componentsSeparatedByString:@"/"];
    if(parts.count<3||![parts[0] isEqual:@"assets"])return NO;
    NSString *prefix=[NSString stringWithFormat:@"^((import|apk|patch|sparking|generated|generated-decoration|generated-lwf|generated-movie)-%@|eclipse|art-download-[0-9]{10,16}-[A-Za-z0-9_-]{6,64}|sparking-source-[A-Za-z0-9_-]{1,80})$",uuid];
    return ODMatch(parts[1],prefix)&&ODMatch(path,@"(?i)\\.(png|jpe?g|webp|gif|bmp|lwf|lua|usm|ogg|mp3|wav|m4a|aac|flac|awb|acb|atlas|plist|json|xml|tmx|bytes|cpk|fsh|vsh|fnt|ttf|otf|strings|txt|bin)$");
}
static BOOL ODDocumentPath(NSString *path){return ODPath(path)&&([path hasPrefix:@"projects/"]||[path hasPrefix:@"project-versions/"]);}
static BOOL ODUnsafe(id value,NSUInteger depth,NSUInteger *nodes){
    if(depth>64||++*nodes>1000000)return YES;
    if([value isKindOfClass:NSDictionary.class])for(id key in value){
        if(![key isKindOfClass:NSString.class]||ODMatch(key,@"(?i)^(__proto__|prototype|constructor|password|api[_-]?key|access[_-]?token|refresh[_-]?token|secret|signing[_-]?key|sparking[_-]?key|credentials)$")||ODUnsafe(value[key],depth+1,nodes))return YES;
    }else if([value isKindOfClass:NSArray.class])for(id item in value)if(ODUnsafe(item,depth+1,nodes))return YES;
    return NO;
}
static BOOL ODSafeDocument(NSData *data,NSString *path){
    if(![data isKindOfClass:NSData.class]||!data.length||data.length>20*1024*1024+65536)return NO;
    NSMutableArray *parts=[NSMutableArray array];
    if([path hasSuffix:@".version"]){const char *p=data.bytes;const char *nl=memchr(p,'\n',MIN(data.length,65536));if(!nl)return NO;
        NSUInteger n=(NSUInteger)(nl-p);[parts addObject:[data subdataWithRange:NSMakeRange(0,n)]];[parts addObject:[data subdataWithRange:NSMakeRange(n+1,data.length-n-1)]];
    }else[parts addObject:data];
    for(NSData *part in parts){id json=[NSJSONSerialization JSONObjectWithData:part options:0 error:nil];NSUInteger nodes=0;if(!json||ODUnsafe(json,0,&nodes))return NO;}return YES;
}
static NSString *ODFinal(CC_SHA256_CTX *context){unsigned char digest[CC_SHA256_DIGEST_LENGTH];CC_SHA256_Final(digest,context);NSMutableString *out=[NSMutableString string];for(size_t i=0;i<sizeof(digest);++i)[out appendFormat:@"%02x",digest[i]];return out;}
static BOOL ODStatSame(struct stat a,struct stat b){return a.st_dev==b.st_dev&&a.st_ino==b.st_ino&&a.st_size==b.st_size&&a.st_nlink==b.st_nlink&&a.st_mtimespec.tv_sec==b.st_mtimespec.tv_sec&&a.st_mtimespec.tv_nsec==b.st_mtimespec.tv_nsec&&a.st_ctimespec.tv_sec==b.st_ctimespec.tv_sec&&a.st_ctimespec.tv_nsec==b.st_ctimespec.tv_nsec;}
static int ODRoot(NSString *path){
    if(!path.isAbsolutePath)return -1;struct stat st;if(lstat(path.fileSystemRepresentation,&st)||!S_ISDIR(st.st_mode)||S_ISLNK(st.st_mode))return -1;
    int fd=open("/",O_RDONLY|O_DIRECTORY|O_CLOEXEC);if(fd<0)return -1;
    for(NSString *part in path.pathComponents){if([part isEqual:@"/"])continue;int next=openat(fd,part.fileSystemRepresentation,O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);close(fd);if(next<0)return -1;fd=next;}return fd;
}
static int ODParent(int root,NSString *path,BOOL create,NSString **leaf){
    NSArray *parts=[path componentsSeparatedByString:@"/"];if(!ODRelative(path)||!parts.count)return -1;
    int fd=dup(root);if(fd<0)return -1;
    for(NSUInteger i=0;i+1<parts.count;++i){NSString *p=parts[i];int next=openat(fd,p.fileSystemRepresentation,O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);
        if(next<0&&errno==ENOENT&&create){if(mkdirat(fd,p.fileSystemRepresentation,0700)&&errno!=EEXIST){close(fd);return -1;}next=openat(fd,p.fileSystemRepresentation,O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);}
        close(fd);if(next<0)return -1;fd=next;}
    *leaf=parts.lastObject;return fd;
}
static int ODFile(int root,NSString *path,BOOL create){NSString *leaf=nil;int parent=ODParent(root,path,create,&leaf);if(parent<0)return -1;
    int fd=openat(parent,leaf.fileSystemRepresentation,(create?O_WRONLY|O_CREAT|O_EXCL:O_RDONLY)|O_NOFOLLOW|O_CLOEXEC,0600);close(parent);
    struct stat st;if(fd>=0&&(fstat(fd,&st)||!S_ISREG(st.st_mode)||st.st_nlink!=1||st.st_size<0||(uint64_t)st.st_size>OD_ARCHIVE_MAX_FILE)){close(fd);errno=EINVAL;return -1;}return fd;
}
static void ODRemoveTree(int parent,const char *name){
    int fd=openat(parent,name,O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);if(fd<0)return;
    DIR *directory=fdopendir(fd);if(!directory){close(fd);return;}struct dirent *entry;
    while((entry=readdir(directory))){if(!strcmp(entry->d_name,".")||!strcmp(entry->d_name,".."))continue;struct stat st;
        if(fstatat(fd,entry->d_name,&st,AT_SYMLINK_NOFOLLOW))continue;
        if(S_ISDIR(st.st_mode))ODRemoveTree(fd,entry->d_name);else unlinkat(fd,entry->d_name,0);}
    closedir(directory);unlinkat(parent,name,AT_REMOVEDIR);
}
typedef struct {int fd;__unsafe_unretained NSData *data;__unsafe_unretained NSMutableData *buffer;CC_SHA256_CTX hash;__unsafe_unretained BOOL(^current)(void);} ODStream;
static ssize_t ODSource(void *raw,uint64_t at,void *bytes,size_t count){ODStream *s=raw;if(!s->current())return -1;ssize_t n;
    if(s->fd>=0){do{n=pread(s->fd,bytes,count,(off_t)at);}while(n<0&&errno==EINTR);}else{if(at>s->data.length)return -1;n=(ssize_t)MIN(count,s->data.length-(NSUInteger)at);memcpy(bytes,(const char *)s->data.bytes+at,(size_t)n);}
    if(n>0)CC_SHA256_Update(&s->hash,bytes,(CC_LONG)n);return n;
}
static int ODSink(void *raw,const void *bytes,size_t count){ODStream *s=raw;if(!s->current())return -1;
    if(s->fd>=0){size_t at=0;while(at<count){ssize_t n=write(s->fd,(const char *)bytes+at,count-at);if(n<0&&errno==EINTR)continue;if(n<=0)return -1;at+=(size_t)n;}}
    else[s->buffer appendBytes:bytes length:count];CC_SHA256_Update(&s->hash,bytes,(CC_LONG)count);return 0;
}
static NSDictionary *ODDigest(int fd,BOOL(^current)(void)){
    struct stat before,after;if(fstat(fd,&before)||!S_ISREG(before.st_mode)||before.st_nlink!=1||before.st_size<0||(uint64_t)before.st_size>OD_ARCHIVE_MAX_FILE)return nil;
    CC_SHA256_CTX hash;CC_SHA256_Init(&hash);char buffer[65536];uint64_t at=0;
    while(at<(uint64_t)before.st_size){if(!current())return nil;size_t n=(size_t)MIN(sizeof(buffer),(uint64_t)before.st_size-at);ssize_t got=pread(fd,buffer,n,(off_t)at);if(got<0&&errno==EINTR)continue;if(got<=0)return nil;CC_SHA256_Update(&hash,buffer,(CC_LONG)got);at+=(uint64_t)got;}
    if(fstat(fd,&after)||!ODStatSame(before,after))return nil;return @{@"bytes":@(at),@"sha256":ODFinal(&hash)};
}
static BOOL ODCollect(int directory,NSString *relative,NSMutableArray *paths,NSUInteger *excluded){
    DIR *dir=fdopendir(dup(directory));if(!dir)return NO;BOOL ok=YES;struct dirent *entry;
    while((entry=readdir(dir))){if(!strcmp(entry->d_name,".")||!strcmp(entry->d_name,".."))continue;NSString *name=[[NSString alloc] initWithUTF8String:entry->d_name];struct stat st;
        if(!name||fstatat(directory,entry->d_name,&st,AT_SYMLINK_NOFOLLOW)||S_ISLNK(st.st_mode)){ok=NO;break;}
        if(ODPrivate(name)){++*excluded;continue;}NSString *path=[relative stringByAppendingFormat:@"/%@",name];
        if(S_ISDIR(st.st_mode)){if(path.length>500||[path componentsSeparatedByString:@"/"].count>64){ok=NO;break;}int child=openat(directory,entry->d_name,O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);ok=child>=0&&ODCollect(child,path,paths,excluded);if(child>=0)close(child);if(!ok)break;}
        else if(S_ISREG(st.st_mode)&&st.st_nlink==1&&ODPath(path)){if(st.st_size<0||(uint64_t)st.st_size>OD_ARCHIVE_MAX_FILE||paths.count>=10000){ok=NO;break;}[paths addObject:path];}
        else ++*excluded;
    }closedir(dir);return ok;
}
static BOOL ODGalleryDocument(NSDictionary *doc){
    if(![doc isKindOfClass:NSDictionary.class])return NO;
    NSSet *fields=[NSSet setWithArray:@[@"format",@"version",@"key",@"createdAt",@"updatedAt",@"draft",@"deletedAt",@"targetId",@"source",@"schema",@"tables",@"assets",@"movieBindings",@"animationStudio",@"provenance",@"sourceDependencies"]];
    for(id field in doc)if(![fields containsObject:field])return NO;
    NSDictionary *source=doc[@"source"],*tables=doc[@"tables"],*schema=doc[@"schema"],*studio=doc[@"animationStudio"];
    if(![doc[@"format"] isEqual:@"dokkan-animation-gallery"]||!ODInteger(doc[@"version"])||[doc[@"version"] intValue]!=1||!ODMatch(doc[@"key"],@"^[A-Za-z0-9_-]{1,100}$")||
       !ODInteger(doc[@"targetId"])||[doc[@"targetId"] longLongValue]<1||[doc[@"targetId"] longLongValue]>1999999000||
       ![source isKindOfClass:NSDictionary.class]||![@[@"eclipse",@"sparking"] containsObject:source[@"database"]]||
       ![tables isKindOfClass:NSDictionary.class]||tables.count!=1||![tables[@"effect_packs"] isKindOfClass:NSArray.class]||[tables[@"effect_packs"] count]>48||
       ![schema isKindOfClass:NSDictionary.class]||schema.count!=1||![schema[@"effect_packs"] isKindOfClass:NSArray.class]||[schema[@"effect_packs"] count]>256||
       ![studio isKindOfClass:NSDictionary.class]||![studio[@"clips"] isKindOfClass:NSArray.class]||[studio[@"clips"] count]>24||
       (studio[@"name"]&&![studio[@"name"] isKindOfClass:NSString.class])||[studio[@"name"] length]>120||
       ![doc[@"assets"] isKindOfClass:NSArray.class]||[doc[@"assets"] count]>256||
       ![doc[@"movieBindings"] isKindOfClass:NSArray.class]||[doc[@"movieBindings"] count]>48)return NO;
    for(id asset in doc[@"assets"]){if(![asset isKindOfClass:NSDictionary.class]||!ODRelative(asset[@"key"])||!ODRelative(asset[@"path"]))return NO;}
    NSUInteger nodes=0;return !ODUnsafe(doc,0,&nodes);
}
static void ODAssetReferences(id value,NSMutableSet *keys){
    if([value isKindOfClass:NSDictionary.class])for(NSString *key in value){id child=value[key];if([key isEqual:@"assetKey"]&&[child isKindOfClass:NSString.class]&&[child length])[keys addObject:child];else ODAssetReferences(child,keys);}
    else if([value isKindOfClass:NSArray.class])for(id child in value)ODAssetReferences(child,keys);
}
static BOOL ODGalleryResources(NSDictionary *doc,NSSet *paths){
    NSMutableSet *keys=[NSMutableSet set];for(NSDictionary *a in doc[@"assets"])[keys addObject:a[@"key"]];ODAssetReferences(doc[@"animationStudio"],keys);
    for(NSString *key in keys){NSString *path=[@"assets/" stringByAppendingString:key];
        if(ODPath(path)){if(![paths containsObject:path])return NO;}
        else{if([key containsString:@"/"]||!ODPath([path stringByAppendingString:@"/probe.txt"]))return NO;BOOL found=NO;
            for(NSString *candidate in paths)if([candidate hasPrefix:[path stringByAppendingString:@"/"]]){found=YES;break;}if(!found)return NO;}}
    return YES;
}

@interface ODRestorePlan : NSObject
@property(nonatomic) int root,stage;
@property(nonatomic,copy) NSString *stageName;
@property(nonatomic,strong) NSMutableArray<NSDictionary *> *installed;
@property(nonatomic,strong) NSDictionary<NSString *,NSData *> *documents;
@property(nonatomic,strong) NSDictionary *result;
@property(nonatomic) BOOL committed;
- (void)finalizePlan;
@end
@implementation ODRestorePlan
- (instancetype)init{if((self=[super init])){_root=-1;_stage=-1;_installed=[NSMutableArray array];}return self;}
- (void)finalizePlan{
    if(_root<0)return;
    if(_stage>=0){close(_stage);_stage=-1;}if(_stageName){ODRemoveTree(_root,_stageName.fileSystemRepresentation);_stageName=nil;}
    if(!_committed)for(NSDictionary *entry in [_installed reverseObjectEnumerator]){NSString *leaf=nil;int parent=ODParent(_root,entry[@"path"],NO,&leaf);if(parent<0)continue;struct stat st;
        if(!fstatat(parent,leaf.fileSystemRepresentation,&st,AT_SYMLINK_NOFOLLOW)&&S_ISREG(st.st_mode)&&
           (uint64_t)st.st_dev==[entry[@"device"] unsignedLongLongValue]&&(uint64_t)st.st_ino==[entry[@"inode"] unsignedLongLongValue]&&st.st_nlink==1&&
           st.st_size==[entry[@"bytes"] longLongValue]&&st.st_mtimespec.tv_sec==[entry[@"mtime"] longLongValue]&&st.st_mtimespec.tv_nsec==[entry[@"mtimeNanos"] longLongValue])unlinkat(parent,leaf.fileSystemRepresentation,0);
        close(parent);}
    close(_root);_root=-1;
}
- (void)dealloc{[self finalizePlan];}
@end

@interface ODCreatorContentArchive ()
- (NSDictionary *)save:(NSDictionary<NSString *,NSData *> *)documents gallery:(NSDictionary *)gallery error:(NSString **)error;
- (NSDictionary *)saveDirect:(NSDictionary<NSString *,NSData *> *)documents gallery:(NSDictionary *)gallery error:(NSString **)error;
- (ODRestorePlan *)prepareRestore:(NSString **)error;
- (ODRestorePlan *)prepareRestoreDirect:(NSString **)error;
@end

@implementation ODCreatorContentArchive {
    NSString *_resources,*_folder;
    BOOL(^_current)(void);
    ODCreatorArchiveSnapshotProvider _snapshot;
    ODCreatorArchiveDocumentsRestorer _restore;
    dispatch_queue_t _queue;
    atomic_bool _revoked,_working;
}
- (instancetype)initWithResourcesRootURL:(NSURL *)resources archiveFolderURL:(NSURL *)folder contextIsCurrent:(BOOL(^)(void))current snapshotProvider:(ODCreatorArchiveSnapshotProvider)snapshot documentsRestorer:(ODCreatorArchiveDocumentsRestorer)restore error:(NSError **)error {
    if(!(self=[super init]))return nil;
    NSString *root=[resources.path.stringByStandardizingPath stringByResolvingSymlinksInPath];
    NSString *external=folder?[folder.path.stringByStandardizingPath stringByResolvingSymlinksInPath]:nil;
    NSString *home=[NSHomeDirectory() stringByResolvingSymlinksInPath];
    struct stat requested;BOOL linked=resources.isFileURL&&(!lstat(resources.fileSystemRepresentation,&requested)&&S_ISLNK(requested.st_mode));
    BOOL linkedArchive=folder.isFileURL&&(!lstat(folder.fileSystemRepresentation,&requested)&&S_ISLNK(requested.st_mode));
    int fd=resources.isFileURL&&!linked?ODRoot(root):-1;
    BOOL valid=fd>=0&&!linkedArchive&&current&&snapshot&&restore&&(!folder||(folder.isFileURL&&external.length&&![external isEqual:root]&&![external hasPrefix:[root stringByAppendingString:@"/"]]&&![external isEqual:home]&&![external hasPrefix:[home stringByAppendingString:@"/"]]));
    if(fd>=0)close(fd);if(!valid){if(error)*error=[NSError errorWithDomain:@"OfflineDokkan.CreatorArchive" code:1 userInfo:@{NSLocalizedDescriptionKey:@"A native Creator workspace and an external archive folder are required."}];return nil;}
    _resources=root;_folder=external;_current=[current copy];_snapshot=[snapshot copy];_restore=[restore copy];
    _queue=dispatch_queue_create("personal.offlinedokkan.creator.archive",DISPATCH_QUEUE_SERIAL);atomic_init(&_revoked,false);atomic_init(&_working,false);return self;
}
- (BOOL)busy{return atomic_load_explicit(&_working,memory_order_acquire);}
- (BOOL)current{return !atomic_load_explicit(&_revoked,memory_order_acquire)&&_current&&_current();}
- (void)invalidate{atomic_store_explicit(&_revoked,true,memory_order_release);}
- (void)finish:(ODCreatorArchiveReply)reply result:(NSDictionary *)result error:(NSString *)error {
    dispatch_async(dispatch_get_main_queue(),^{atomic_store_explicit(&self->_working,false,memory_order_release);reply(result,error);});
}
- (NSDictionary *)status {
    int folder=_folder?ODRoot(_folder):-1;BOOL available=folder>=0,exists=NO;NSString *warning=nil;
    if(folder>=0){struct stat st;if(!fstatat(folder,ODArchiveName.fileSystemRepresentation,&st,AT_SYMLINK_NOFOLLOW)){exists=S_ISREG(st.st_mode)&&st.st_nlink==1&&st.st_size>0&&(uint64_t)st.st_size<=OD_ARCHIVE_MAX_BYTES;if(!exists)warning=@"The saved archive is unavailable or unsafe. Choose the folder again.";}else if(errno!=ENOENT)warning=@"The archive folder could not be read.";close(folder);}
    return @{@"available":@(available),@"exists":@(exists),@"galleryDocuments":@YES,@"folder":@"your chosen Dokkan Files folder",@"name":ODArchiveName,@"warning":warning?:@""};
}
- (void)handleArguments:(NSDictionary *)arguments reply:(ODCreatorArchiveReply)reply {
    if(!NSThread.isMainThread){dispatch_async(dispatch_get_main_queue(),^{[self handleArguments:arguments reply:reply];});return;}
    if(!reply)return;if(![self current]){reply(nil,@"The Creator archive scope is no longer current.");return;}
    if(![arguments isKindOfClass:NSDictionary.class]){reply(nil,@"Invalid archive action.");return;}
    for(id key in arguments)if(![@[@"action",@"gallery"] containsObject:key]){reply(nil,@"Archive paths and storage authority cannot come from a page.");return;}
    NSString *action=arguments[@"action"]?:@"status";
    if([action isEqual:@"status"]){reply([self status],nil);return;}
    if(![@[@"save",@"restore"] containsObject:action]||!_folder){reply(nil,@"Choose an external Dokkan Files folder before saving or restoring creations.");return;}
    if(atomic_exchange_explicit(&_working,true,memory_order_acq_rel)){reply(nil,@"A creations archive operation is already running.");return;}
    if([action isEqual:@"save"]){
        id gallery=arguments[@"gallery"];NSData *copy=gallery?[NSJSONSerialization dataWithJSONObject:gallery options:0 error:nil]:nil;
        if(gallery&&(!copy||copy.length>ODGalleryLimit)){[self finish:reply result:nil error:@"Gallery editing data exceeds its archive limit."];return;}
        NSDictionary *snapshot=copy?[NSJSONSerialization JSONObjectWithData:copy options:0 error:nil]:nil;
        __block BOOL received=NO;
        _snapshot(^(NSDictionary<NSString *,NSData *> *files,NSString *failure){dispatch_async(self->_queue,^{
            if(received)return;received=YES;
            if(failure||![files isKindOfClass:NSDictionary.class]||![self current]){[self finish:reply result:nil error:@"Creator documents could not be read in the current scope."];return;}
            NSString *error=nil;NSDictionary *result=[self save:files gallery:snapshot error:&error];[self finish:reply result:result error:error];
        });});
    }else dispatch_async(_queue,^{
        NSString *failure=nil;ODRestorePlan *plan=[self prepareRestore:&failure];
        if(!plan){[self finish:reply result:nil error:failure];return;}
        dispatch_async(dispatch_get_main_queue(),^{
            if(![self current]){dispatch_async(self->_queue,^{[plan finalizePlan];[self finish:reply result:nil error:@"The Creator scope changed before restoration committed."];});return;}
            __block BOOL received=NO;
            self->_restore(plan.documents,^(NSDictionary *result,NSString *error){dispatch_async(self->_queue,^{
                if(received)return;received=YES;
                if(!error&&[result isKindOfClass:NSDictionary.class]){
                    plan.committed=YES;NSMutableDictionary *combined=[plan.result mutableCopy];
                    for(NSString *field in @[@"restored",@"unchanged"])if(ODInteger(result[field]))combined[field]=@([combined[field] unsignedLongLongValue]+[result[field] unsignedLongLongValue]);
                    combined[@"documents"]=@(plan.documents.count);[plan finalizePlan];[self finish:reply result:combined error:nil];
                }
                else {[plan finalizePlan];[self finish:reply result:nil error:@"Creator document restoration failed. Existing documents were kept."];}
            });});
        });
    });
}
- (NSDictionary *)save:(NSDictionary<NSString *,NSData *> *)documents gallery:(NSDictionary *)gallery error:(NSString **)error {
    __block NSDictionary *result=nil;__block NSString *failure=nil;NSError *coordination=nil;
    NSURL *url=[NSURL fileURLWithPath:[_folder stringByAppendingPathComponent:ODArchiveName]];
    NSFileCoordinator *coordinator=[[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [coordinator coordinateWritingItemAtURL:url options:NSFileCoordinatorWritingForReplacing error:&coordination byAccessor:^(NSURL *coordinated){
        if(![coordinated.path.stringByStandardizingPath isEqual:url.path.stringByStandardizingPath])failure=@"The archive provider returned an unexpected file.";
        else result=[self saveDirect:documents gallery:gallery error:&failure];
    }];
    if(!result&&error)*error=failure?:@"The external archive folder could not be written.";
    return result;
}
- (NSDictionary *)saveDirect:(NSDictionary<NSString *,NSData *> *)documents gallery:(NSDictionary *)gallery error:(NSString **)error {
    NSString *failure=@"Creations could not be archived. The previous archive was preserved.";
    int root=ODRoot(_resources),folder=ODRoot(_folder),output=-1;ODArchiveZip *zip=NULL;
    NSString *temporary=[@".creations-archive-" stringByAppendingString:NSUUID.UUID.UUIDString];
    BOOL published=NO,created=NO;NSDictionary *result=nil;struct stat prior={0};BOOL existed=NO;
    @try {
        if(root<0||folder<0||![self current])return nil;
        if(!fstatat(folder,ODArchiveName.fileSystemRepresentation,&prior,AT_SYMLINK_NOFOLLOW)){
            existed=YES;if(!S_ISREG(prior.st_mode)||prior.st_nlink!=1){failure=@"The existing archive is linked or unsupported. Nothing was replaced.";return nil;}
        }else if(errno!=ENOENT)return nil;
        NSMutableArray<NSString *> *resources=[NSMutableArray array];NSUInteger excluded=0;
        for(NSString *name in @[@"assets",@"patches"]){int fd=openat(root,name.fileSystemRepresentation,O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);
            if(fd<0){if(errno==ENOENT)continue;return nil;}BOOL valid=ODCollect(fd,name,resources,&excluded);close(fd);if(!valid){failure=@"A linked, oversized or unsupported creations folder was found.";return nil;}}
        [resources sortUsingSelector:@selector(compare:)];NSSet *resourcePaths=[NSSet setWithArray:resources];
        NSMutableDictionary<NSString *,NSData *> *virtualFiles=[NSMutableDictionary dictionary];uint64_t documentBytes=0;
        if(documents.count>10000)return nil;
        for(NSString *path in documents){NSData *data=documents[path];if(!ODDocumentPath(path)||!ODSafeDocument(data,path)||data.length>96*1024*1024-documentBytes){failure=@"Creator document data is unsupported, private or too large.";return nil;}
            virtualFiles[path]=[data copy];documentBytes+=data.length;}
        NSMutableDictionary *galleryMeta=nil;NSUInteger galleryCount=0;uint64_t galleryBytes=0;
        if(gallery){
            if(![gallery isKindOfClass:NSDictionary.class]||![gallery[@"format"] isEqual:@"dokkan-animation-gallery-snapshot"]||!ODInteger(gallery[@"version"])||[gallery[@"version"] intValue]!=1||![gallery[@"documents"] isKindOfClass:NSArray.class]||[gallery[@"documents"] count]>1000)return nil;
            for(NSDictionary *doc in gallery[@"documents"]){
                if(!ODGalleryDocument(doc)||!ODGalleryResources(doc,resourcePaths)){failure=@"A gallery document or its referenced resource is missing, private or unsupported.";return nil;}
                NSData *data=[NSJSONSerialization dataWithJSONObject:doc options:0 error:nil];NSString *path=[NSString stringWithFormat:@"animation-gallery/%@.json",doc[@"key"]];
                if(!data||data.length>8*1024*1024||data.length>ODGalleryLimit-galleryBytes||virtualFiles[path])return nil;
                virtualFiles[path]=data;galleryBytes+=data.length;++galleryCount;
            }
            id currentKey=gallery[@"currentKey"]?:@"",lastDeleted=gallery[@"lastDeleted"]?:@"";
            if(![currentKey isKindOfClass:NSString.class]||[currentKey length]>100||![lastDeleted isKindOfClass:NSString.class]||[lastDeleted length]>100)return nil;
            galleryMeta=[@{@"format":@"dokkan-animation-gallery-snapshot",@"version":@1,@"count":@(galleryCount),@"currentKey":currentKey,@"lastDeleted":lastDeleted} mutableCopy];
        }
        if(resources.count+virtualFiles.count>10000||(!resources.count&&!virtualFiles.count)){failure=@"There are no supported saved creations, or the archive exceeds 10,000 files.";return nil;}
        output=openat(folder,temporary.fileSystemRepresentation,O_RDWR|O_CREAT|O_EXCL|O_NOFOLLOW|O_CLOEXEC,0600);
        created=output>=0;
        if(output<0||od_archive_zip_create(output,&zip))return nil;
        NSMutableArray *records=[NSMutableArray array];uint64_t total=0;BOOL(^current)(void)=^BOOL{return [self current];};
        NSMutableArray *paths=[resources mutableCopy];[paths addObjectsFromArray:[[virtualFiles allKeys] sortedArrayUsingSelector:@selector(compare:)]];
        for(NSString *path in paths){
            NSData *data=virtualFiles[path];int file=data?-1:ODFile(root,path,NO);struct stat before={0},after={0};
            if(!data&&(file<0||fstat(file,&before))){if(file>=0)close(file);return nil;}
            uint64_t bytes=data?data.length:(uint64_t)before.st_size;
            if(bytes>OD_ARCHIVE_MAX_TOTAL-total){if(file>=0)close(file);failure=@"Creations exceed the 2 GiB archive limit.";return nil;}
            ODStream stream={.fd=file,.data=data,.current=current};CC_SHA256_Init(&stream.hash);
            BOOL valid=!od_archive_zip_add(zip,path.UTF8String,bytes,ODSource,&stream);
            if(file>=0){valid=valid&&!fstat(file,&after)&&ODStatSame(before,after);close(file);}
            if(!valid||![self current])return nil;
            total+=bytes;[records addObject:@{@"path":path,@"bytes":@(bytes),@"sha256":ODFinal(&stream.hash)}];
        }
        NSMutableDictionary *manifest=[@{@"format":@"dokkan-user-content",@"version":gallery?@2:@1,@"files":records} mutableCopy];if(galleryMeta)manifest[@"gallery"]=galleryMeta;
        NSData *bytes=[NSJSONSerialization dataWithJSONObject:manifest options:0 error:nil];if(!bytes||bytes.length>ODManifestLimit)return nil;
        ODStream source={.fd=-1,.data=bytes,.current=current};CC_SHA256_Init(&source.hash);
        if(od_archive_zip_add(zip,"manifest.json",bytes.length,ODSource,&source)||od_archive_zip_finish(zip)||![self current])return nil;
        struct stat now;int present=fstatat(folder,ODArchiveName.fileSystemRepresentation,&now,AT_SYMLINK_NOFOLLOW);
        if((existed&&(present||!ODStatSame(prior,now)))||(!existed&&(!present||errno!=ENOENT))){failure=@"The external archive changed while saving. It was preserved.";return nil;}
        if(renameat(folder,temporary.fileSystemRepresentation,folder,ODArchiveName.fileSystemRepresentation))return nil;
        published=YES;(void)fsync(folder);
        result=@{@"saved":@YES,@"files":@(paths.count),@"galleryDocuments":@(galleryCount),@"bytes":@(total),@"excluded":@(excluded)};
        return result;
    }@finally{
        if(zip)od_archive_zip_close(zip);if(output>=0)close(output);if(folder>=0){if(created&&!published)unlinkat(folder,temporary.fileSystemRepresentation,0);close(folder);}if(root>=0)close(root);
        if(!result&&error)*error=failure;
    }
}
- (ODRestorePlan *)prepareRestore:(NSString **)error {
    __block ODRestorePlan *result=nil;__block NSString *failure=nil;NSError *coordination=nil;
    NSURL *url=[NSURL fileURLWithPath:[_folder stringByAppendingPathComponent:ODArchiveName]];
    NSFileCoordinator *coordinator=[[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [coordinator coordinateReadingItemAtURL:url options:NSFileCoordinatorReadingWithoutChanges error:&coordination byAccessor:^(NSURL *coordinated){
        if(![coordinated.path.stringByStandardizingPath isEqual:url.path.stringByStandardizingPath])failure=@"The archive provider returned an unexpected file.";
        else result=[self prepareRestoreDirect:&failure];
    }];
    if(!result&&error)*error=failure?:@"The external creations archive could not be read.";return result;
}
- (ODRestorePlan *)prepareRestoreDirect:(NSString **)error {
    NSString *failure=@"The creations archive failed validation. Existing data was preserved.";
    ODRestorePlan *plan=[ODRestorePlan new];BOOL ready=NO;int folder=ODRoot(_folder),archive=-1;ODArchiveZip *zip=NULL;
    @try {
        plan.root=ODRoot(_resources);if(folder<0||plan.root<0||![self current])return nil;
        archive=openat(folder,ODArchiveName.fileSystemRepresentation,O_RDONLY|O_NOFOLLOW|O_CLOEXEC);struct stat before,after;
        if(archive<0||fstat(archive,&before)||!S_ISREG(before.st_mode)||before.st_nlink!=1||od_archive_zip_open(archive,&zip))return nil;
        NSString *stageName=[@".creations-restore-" stringByAppendingString:NSUUID.UUID.UUIDString];
        if(mkdirat(plan.root,stageName.fileSystemRepresentation,0700))return nil;plan.stageName=stageName;
        plan.stage=openat(plan.root,plan.stageName.fileSystemRepresentation,O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);if(plan.stage<0)return nil;
        NSMutableDictionary *actual=[NSMutableDictionary dictionary],*documents=[NSMutableDictionary dictionary],*galleryFiles=[NSMutableDictionary dictionary];
        NSData *manifestBytes=nil;uint64_t total=0,documentBytes=0,galleryBytes=0;BOOL(^current)(void)=^BOOL{return [self current];};
        for(size_t i=0;i<od_archive_zip_count(zip);++i){
            const ODArchiveEntry *entry=od_archive_zip_entry(zip,i);NSString *path=[[NSString alloc] initWithUTF8String:entry->name];
            BOOL manifest=[path isEqual:@"manifest.json"],document=ODDocumentPath(path),gallery=[path hasPrefix:@"animation-gallery/"];
            if(!path||(!manifest&&!ODPath(path))||actual[path]||(!manifest&&actual.count>=10000))return nil;
            if((manifest&&(manifestBytes||entry->bytes>ODManifestLimit))||(document&&(entry->bytes>20*1024*1024+65536||entry->bytes>96*1024*1024-documentBytes))||
               (gallery&&(entry->bytes>8*1024*1024||entry->bytes>ODGalleryLimit-galleryBytes||galleryFiles.count>=1000))||(!manifest&&entry->bytes>OD_ARCHIVE_MAX_TOTAL-total))return nil;
            BOOL memory=manifest||document||gallery;NSMutableData *buffer=memory?[NSMutableData dataWithCapacity:entry->bytes]:nil;
            int file=memory?-1:ODFile(plan.stage,path,YES);if(!memory&&file<0)return nil;
            ODStream sink={.fd=file,.buffer=buffer,.current=current};CC_SHA256_Init(&sink.hash);
            BOOL valid=!od_archive_zip_extract(zip,i,ODSink,&sink);
            if(file>=0){if(fsync(file))valid=NO;if(close(file))valid=NO;}
            if(!valid)return nil;
            if(manifest){manifestBytes=[buffer copy];continue;}
            total+=entry->bytes;actual[path]=@{@"bytes":@(entry->bytes),@"sha256":ODFinal(&sink.hash)};
            if(document){if(!ODSafeDocument(buffer,path))return nil;documents[path]=[buffer copy];documentBytes+=entry->bytes;}
            if(gallery){galleryFiles[path]=[buffer copy];galleryBytes+=entry->bytes;}
        }
        if(fstat(archive,&after)||!ODStatSame(before,after)||!manifestBytes)return nil;
        id manifest=[NSJSONSerialization JSONObjectWithData:manifestBytes options:0 error:nil];
        if(![manifest isKindOfClass:NSDictionary.class]||![manifest[@"format"] isEqual:@"dokkan-user-content"]||!ODInteger(manifest[@"version"])||
           ![@[@1,@2] containsObject:manifest[@"version"]]||![manifest[@"files"] isKindOfClass:NSArray.class]||[manifest[@"files"] count]!=actual.count)return nil;
        for(id field in manifest)if(![@[@"format",@"version",@"files",@"gallery"] containsObject:field])return nil;
        NSMutableSet *listed=[NSMutableSet set];
        for(id record in manifest[@"files"]){if(![record isKindOfClass:NSDictionary.class]||[record count]!=3||!ODPath(record[@"path"])||[listed containsObject:record[@"path"]]||
            !ODInteger(record[@"bytes"])||!ODMatch(record[@"sha256"],@"^[a-f0-9]{64}$"))return nil;
            NSDictionary *got=actual[record[@"path"]];if(!got||![got[@"bytes"] isEqual:record[@"bytes"]]||![got[@"sha256"] isEqual:record[@"sha256"]])return nil;[listed addObject:record[@"path"]];}
        NSMutableArray *galleryDocuments=[NSMutableArray array];
        for(NSString *path in [[galleryFiles allKeys] sortedArrayUsingSelector:@selector(compare:)]){id doc=[NSJSONSerialization JSONObjectWithData:galleryFiles[path] options:0 error:nil];
            if(!ODGalleryDocument(doc)||![path isEqual:[NSString stringWithFormat:@"animation-gallery/%@.json",doc[@"key"]]]||!ODGalleryResources(doc,listed))return nil;[galleryDocuments addObject:doc];}
        NSDictionary *gallery=manifest[@"gallery"];
        if(([manifest[@"version"] intValue]==1&&(gallery||galleryDocuments.count))||([manifest[@"version"] intValue]==2&&!gallery))return nil;
        if(gallery){
            if(![gallery isKindOfClass:NSDictionary.class]||![gallery[@"format"] isEqual:@"dokkan-animation-gallery-snapshot"]||!ODInteger(gallery[@"version"])||[gallery[@"version"] intValue]!=1||
               !ODInteger(gallery[@"count"])||[gallery[@"count"] unsignedIntegerValue]!=galleryDocuments.count)return nil;
            for(id field in gallery)if(![@[@"format",@"version",@"count",@"currentKey",@"lastDeleted"] containsObject:field])return nil;
            for(NSString *field in @[@"currentKey",@"lastDeleted"])if(gallery[field]&&(![gallery[field] isKindOfClass:NSString.class]||[gallery[field] length]>100))return nil;
        }
        NSArray<NSString *> *media=[[[actual allKeys] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id object,__unused NSDictionary *bindings){NSString *path=object;return !ODDocumentPath(path)&&![path hasPrefix:@"animation-gallery/"];}]] sortedArrayUsingSelector:@selector(compare:)];
        /* Validate every conflict before activating even one resource. */
        for(NSString *path in media){int file=ODFile(plan.root,path,NO);if(file<0){if(errno==ENOENT)continue;return nil;}NSDictionary *have=ODDigest(file,current);close(file);
            if(!have||![have isEqual:actual[path]]){failure=@"An existing creation or resource differs. Nothing was overwritten.";return nil;}}
        NSUInteger unchanged=0;
        for(NSString *path in media){if(![self current])return nil;NSString *sourceLeaf=nil,*targetLeaf=nil;int source=ODParent(plan.stage,path,NO,&sourceLeaf),target=ODParent(plan.root,path,YES,&targetLeaf);
            if(source<0||target<0){if(source>=0)close(source);if(target>=0)close(target);return nil;}
            struct stat st;if(fstatat(source,sourceLeaf.fileSystemRepresentation,&st,AT_SYMLINK_NOFOLLOW)||!S_ISREG(st.st_mode)||st.st_nlink!=1){close(source);close(target);return nil;}
            int linked=linkat(source,sourceLeaf.fileSystemRepresentation,target,targetLeaf.fileSystemRepresentation,0);int saved=errno;
            if(!linked){
                [plan.installed addObject:@{@"path":path,@"device":@((uint64_t)st.st_dev),@"inode":@((uint64_t)st.st_ino),@"bytes":@(st.st_size),@"mtime":@(st.st_mtimespec.tv_sec),@"mtimeNanos":@(st.st_mtimespec.tv_nsec)}];(void)fsync(target);
                if(unlinkat(source,sourceLeaf.fileSystemRepresentation,0)){close(source);close(target);return nil;}
            }else if(saved==EEXIST){int file=ODFile(plan.root,path,NO);NSDictionary *have=file>=0?ODDigest(file,current):nil;if(file>=0)close(file);if(!have||![have isEqual:actual[path]]){close(source);close(target);return nil;}++unchanged;}
            else{close(source);close(target);return nil;}
            close(source);close(target);
        }
        NSMutableDictionary *result=[@{@"restored":@(plan.installed.count),@"unchanged":@(unchanged),@"bytes":@(total)} mutableCopy];
        if(gallery){NSMutableDictionary *snapshot=[gallery mutableCopy];snapshot[@"documents"]=galleryDocuments;snapshot[@"verifiedFiles"]=@YES;result[@"gallery"]=snapshot;}
        plan.documents=[documents copy];plan.result=result;ready=YES;return plan;
    }@finally{
        if(zip)od_archive_zip_close(zip);if(archive>=0)close(archive);if(folder>=0)close(folder);
        if(!ready){[plan finalizePlan];if(error)*error=failure;}
    }
}
@end
