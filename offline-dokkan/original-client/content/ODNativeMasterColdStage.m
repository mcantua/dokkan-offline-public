#import "ODNativeMasterColdStage.h"
#import <CommonCrypto/CommonDigest.h>
#include <mach-o/dyld.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>

static BOOL ODColdFail(NSError **error,NSString *code) {
    if(error)*error=[NSError errorWithDomain:@"OfflineDokkan.NativeMasterColdStage" code:1
        userInfo:@{NSLocalizedDescriptionKey:code}];
    return NO;
}
static BOOL ODColdHex(NSString *value) {
    return [value isKindOfClass:NSString.class]&&value.length==64&&
        [value rangeOfCharacterFromSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdef"] invertedSet]].location==NSNotFound;
}
static BOOL ODColdSame(const struct stat *a,const struct stat *b) {
    return a->st_dev==b->st_dev&&a->st_ino==b->st_ino&&a->st_size==b->st_size&&
        a->st_mtimespec.tv_sec==b->st_mtimespec.tv_sec&&a->st_mtimespec.tv_nsec==b->st_mtimespec.tv_nsec;
}
static int ODColdDirectory(NSURL *url) {
    if(!url.isFileURL||!url.path.isAbsolutePath)return -1;
    int fd=open("/",O_RDONLY|O_DIRECTORY|O_CLOEXEC);
    for(NSString *part in url.path.pathComponents){if([part isEqual:@"/"])continue;
        if(fd<0)return -1;
        int next=openat(fd,part.fileSystemRepresentation,O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);
        close(fd);fd=next;
    }
    return fd;
}
static BOOL ODColdMissing(int fd,const char *name) {
    struct stat info;return fstatat(fd,name,&info,AT_SYMLINK_NOFOLLOW)<0&&errno==ENOENT;
}
static BOOL ODColdLinkedDirectory(int parent,const char *name,int descriptor) {
    struct stat live,pinned;return !fstat(descriptor,&pinned)&&S_ISDIR(pinned.st_mode)&&
        !fstatat(parent,name,&live,AT_SYMLINK_NOFOLLOW)&&S_ISDIR(live.st_mode)&&!S_ISLNK(live.st_mode)&&
        live.st_dev==pinned.st_dev&&live.st_ino==pinned.st_ino;
}
static BOOL ODColdOriginalEngineAbsent(void) {
    uint32_t count=_dyld_image_count();
    for(uint32_t i=0;i<count;i++){const char *name=_dyld_get_image_name(i);if(!name)return NO;
        const char *base=strrchr(name,'/');
        if(!strcmp(base?base+1:name,"OriginalDokkanEngine.dylib"))return NO;}
    return YES;
}
static NSString *ODColdHash(int fd,uint64_t bytes) {
    CC_SHA256_CTX hash;CC_SHA256_Init(&hash);unsigned char buffer[65536];uint64_t at=0;
    while(at<bytes){size_t amount=(size_t)MIN((uint64_t)sizeof buffer,bytes-at);
        ssize_t n=pread(fd,buffer,amount,(off_t)at);
        if(n<0&&errno==EINTR)continue;
        if(n<=0)return nil;
        CC_SHA256_Update(&hash,buffer,(CC_LONG)n);at+=(uint64_t)n;
    }
    unsigned char extra;if(pread(fd,&extra,1,(off_t)bytes)!=0)return nil;
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];CC_SHA256_Final(digest,&hash);
    NSMutableString *result=[NSMutableString string];for(NSUInteger i=0;i<sizeof digest;i++)[result appendFormat:@"%02x",digest[i]];
    return result;
}
static BOOL ODColdCopy(int source,int target,uint64_t bytes) {
    unsigned char buffer[65536];uint64_t at=0;
    while(at<bytes){size_t amount=(size_t)MIN((uint64_t)sizeof buffer,bytes-at);
        ssize_t n=pread(source,buffer,amount,(off_t)at);if(n<0&&errno==EINTR)continue;
        if(n<=0)return NO;
        size_t done=0;while(done<(size_t)n){ssize_t wrote=write(target,buffer+done,(size_t)n-done);
            if(wrote<0&&errno==EINTR)continue;if(wrote<=0)return NO;done+=(size_t)wrote;}
        at+=(uint64_t)n;
    }
    return fchmod(target,0600)==0&&fsync(target)==0;
}

@interface ODNativeMasterColdStage ()
+ (nullable instancetype)stageInternalOpaqueMasterAtURL:(NSURL *)source byteCount:(uint64_t)bytes
    contentSHA256:(NSString *)sha256 language:(NSString *)language sourceExportCandidate:(BOOL)candidate
    contextIsCurrent:(BOOL (^)(void))current error:(NSError **)error;
@end

@implementation ODNativeMasterColdStage {
    NSURL *_assetsRootURL,*_documentsURL;NSString *_language,*_sha256;uint64_t _bytes;
    BOOL (^_current)(void);
    int _documents,_assets,_sqlite,_working;
    struct stat _documentsIdentity,_assetsIdentity,_sqliteIdentity,_workingIdentity;
    BOOL _sourceExportCandidate;
}
- (instancetype)initPrivate { if((self=[super init]))_documents=_assets=_sqlite=_working=-1;return self; }
- (void)dealloc { if(_working>=0)close(_working);if(_sqlite>=0)close(_sqlite);if(_assets>=0)close(_assets);if(_documents>=0)close(_documents); }
- (NSURL *)assetsRootURL { return [_assetsRootURL copy]; }
- (NSDictionary *)stagingReport {
    return @{@"schema":@1,@"workingCopyStaged":@(_working>=0),@"separateWritableCopy":@YES,
        @"sourcePreserved":@YES,@"defaultNativeAssetRootOnly":@YES,@"nativeConfiguredPrefixObserved":@NO,
        @"languageSuppliedByNativeCaller":@(!_sourceExportCandidate),
        @"sourceAssetLanguageEnglishCandidate":@(_sourceExportCandidate),
        @"candidateLanguageBasis":_sourceExportCandidate?@"supplied-source-export-asset-path":@"native-caller-contract",
        @"nativeLanguageSelectionObserved":@NO,@"selectedMasterFileObserved":@NO,
        @"originalSeedUsedAsPreferredMaster":@NO,@"plaintextUsedAsNativeCipherMaster":@NO,
        @"sourceKeyReadOrAppliedByHost":@NO,@"foreignSQLiteHandleUsed":@NO,
        @"engineCachedHandleChanged":@NO,@"nativeFlags6Executed":@NO,
        @"originalEngineOpenObserved":@NO,@"nativeCipherCompatibilityVerified":@NO,
        @"originalMasterReady":@NO};
}
+ (instancetype)stageImmutableOpaqueMasterAtURL:(NSURL *)source byteCount:(uint64_t)bytes
        contentSHA256:(NSString *)sha256 observedNativeLanguage:(NSString *)language
        contextIsCurrent:(BOOL (^)(void))current error:(NSError **)error {
    return [self stageInternalOpaqueMasterAtURL:source byteCount:bytes contentSHA256:sha256 language:language
        sourceExportCandidate:NO contextIsCurrent:current error:error];
}
+ (instancetype)stagePinnedSourceExportCandidateAtURL:(NSURL *)source
        contextIsCurrent:(BOOL (^)(void))current error:(NSError **)error {
    // A pinned source asset label is a compatibility attempt, never a claim
    // that engine language configuration was observed or rewritten.
    if(![NSBundle.mainBundle.bundleIdentifier isEqualToString:@"org.offlinedokkan.duo"]){
        ODColdFail(error,@"OWN_INTEGRATED_SOURCE_CANDIDATE_REQUIRED");return nil;}
    return [self stageInternalOpaqueMasterAtURL:source byteCount:114827264
        contentSHA256:@"f37296ef05e31000d9868741b18525a5d41311ccc152acb82c848b7b1c8ef14d"
        language:@"en" sourceExportCandidate:YES contextIsCurrent:current error:error];
}
+ (instancetype)stageInternalOpaqueMasterAtURL:(NSURL *)source byteCount:(uint64_t)bytes
        contentSHA256:(NSString *)sha256 language:(NSString *)language sourceExportCandidate:(BOOL)candidate
        contextIsCurrent:(BOOL (^)(void))current error:(NSError **)error {
    BOOL spelling=[language isKindOfClass:NSString.class]&&language.length==2;
    if(spelling)for(NSUInteger i=0;i<2;i++){unichar c=[language characterAtIndex:i];if(c<'a'||c>'z')spelling=NO;}
    NSString *identity=NSBundle.mainBundle.bundleIdentifier;
    BOOL ownIdentity=[identity isKindOfClass:NSString.class]&&[identity hasPrefix:@"org.offlinedokkan."];
    if(NSThread.isMainThread||!ownIdentity||!source.isFileURL||!source.path.isAbsolutePath||!ODColdHex(sha256)||!spelling||
       bytes<100||bytes>256ull*1024*1024||!current||!current()||!ODColdOriginalEngineAbsent()){
        ODColdFail(error,@"INVALID_NATIVE_MASTER_COLD_STAGE_CONTEXT");return nil;}
    // The exact original bundle seed is a distinct fallback candidate, never a
    // downloaded master. Plaintext has its separate detached compiler tools.
    if([sha256 isEqual:@"667e554a9cfb8c4765f05a1d85f0fdf707ade61562b50e3e5cd98ac52f997ba3"]){
        ODColdFail(error,@"ORIGINAL_MASTER_SEED_IS_FALLBACK_ONLY");return nil;}
    int input=open(source.fileSystemRepresentation,O_RDONLY|O_NOFOLLOW|O_CLOEXEC);
    struct stat before,after,sourcePath;unsigned char header[16];
    BOOL valid=input>=0&&!fstat(input,&before)&&S_ISREG(before.st_mode)&&before.st_nlink==1&&
        !(before.st_mode&0222)&&(uint64_t)before.st_size==bytes&&
        pread(input,header,sizeof header,0)==sizeof header&&memcmp(header,"SQLite format 3",16)!=0&&
        [ODColdHash(input,bytes) isEqual:sha256];
    if(!valid){if(input>=0)close(input);ODColdFail(error,@"IMMUTABLE_OPAQUE_MASTER_SOURCE_REQUIRED");return nil;}
    NSURL *native=[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
    struct stat nativeIdentity;NSURL *documents=nil;
    if(native.isFileURL&&!lstat(native.fileSystemRepresentation,&nativeIdentity)&&S_ISDIR(nativeIdentity.st_mode)&&!S_ISLNK(nativeIdentity.st_mode))documents=native.URLByResolvingSymlinksInPath;
    ODNativeMasterColdStage *stage=[[self alloc] initPrivate];
    stage->_documents=ODColdDirectory(documents);
    if(stage->_documents>=0&&fstat(stage->_documents,&stage->_documentsIdentity)==0&&
       nativeIdentity.st_dev==stage->_documentsIdentity.st_dev&&nativeIdentity.st_ino==stage->_documentsIdentity.st_ino){
        // assets must already be established by the reviewed native resource
        // staging. This method never chooses a source/cache tree as the root.
        stage->_assets=openat(stage->_documents,"assets",O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);
    }
    valid=stage->_assets>=0&&!fstat(stage->_assets,&stage->_assetsIdentity)&&ODColdMissing(stage->_assets,"User");
    if(valid){if(mkdirat(stage->_assets,"sqlite",0700)&&errno!=EEXIST)valid=NO;
        if(valid)stage->_sqlite=openat(stage->_assets,"sqlite",O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);
        valid=valid&&stage->_sqlite>=0&&!fstat(stage->_sqlite,&stage->_sqliteIdentity)&&ODColdMissing(stage->_sqlite,"current");}
    NSString *pending=[@".od-master-cold-" stringByAppendingString:NSUUID.UUID.UUIDString];
    int tree=-1,lang=-1,output=-1;BOOL published=NO,pendingCreated=NO;
    struct stat createdIdentity;BOOL outputCreated=NO;
    if(valid){pendingCreated=mkdirat(stage->_sqlite,pending.fileSystemRepresentation,0700)==0;valid=pendingCreated;}
    if(valid){tree=openat(stage->_sqlite,pending.fileSystemRepresentation,O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);
        valid=tree>=0&&mkdirat(tree,language.UTF8String,0700)==0;}
    if(valid){lang=openat(tree,language.UTF8String,O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);
        if(lang>=0)output=openat(lang,"database.db",O_RDWR|O_CREAT|O_EXCL|O_NOFOLLOW|O_CLOEXEC,0600);
        outputCreated=output>=0&&!fstat(output,&createdIdentity);
        valid=outputCreated&&ODColdCopy(input,output,bytes)&&[ODColdHash(output,bytes) isEqual:sha256]&&
            !fstat(output,&stage->_workingIdentity)&&
            !(stage->_workingIdentity.st_dev==before.st_dev&&stage->_workingIdentity.st_ino==before.st_ino)&&
            !fstat(input,&after)&&ODColdSame(&before,&after)&&after.st_mode==before.st_mode&&after.st_nlink==1&&
            !lstat(source.fileSystemRepresentation,&sourcePath)&&
            !S_ISLNK(sourcePath.st_mode)&&ODColdSame(&before,&sourcePath)&&current()&&
            ODColdMissing(stage->_assets,"User")&&ODColdMissing(stage->_sqlite,"current")&&
            ODColdLinkedDirectory(stage->_documents,"assets",stage->_assets)&&
            ODColdLinkedDirectory(stage->_assets,"sqlite",stage->_sqlite)&&ODColdOriginalEngineAbsent()&&fsync(lang)==0&&fsync(tree)==0;
    }
    if(valid){published=renameatx_np(stage->_sqlite,pending.fileSystemRepresentation,stage->_sqlite,"current",RENAME_EXCL)==0;
        valid=published&&fsync(stage->_sqlite)==0&&fsync(stage->_assets)==0&&current();}
    if(output>=0)close(output);
    if(!published&&pendingCreated){struct stat live;
        if(outputCreated&&lang>=0&&!fstatat(lang,"database.db",&live,AT_SYMLINK_NOFOLLOW)&&
           live.st_dev==createdIdentity.st_dev&&live.st_ino==createdIdentity.st_ino)unlinkat(lang,"database.db",0);
        if(tree>=0)unlinkat(tree,language.UTF8String,AT_REMOVEDIR);
        unlinkat(stage->_sqlite,pending.fileSystemRepresentation,AT_REMOVEDIR);}
    if(lang>=0)close(lang);if(tree>=0)close(tree);close(input);
    // A publication followed by a durability/context error is preserved for
    // explicit native recovery. No existing current tree is ever deleted.
    if(!valid){ODColdFail(error,published?@"NATIVE_MASTER_COPY_PUBLISHED_RECOVERY_REQUIRED":@"NATIVE_MASTER_FRESH_WORKING_TREE_REQUIRED");return nil;}
    stage->_assetsRootURL=[documents URLByAppendingPathComponent:@"assets" isDirectory:YES];
    stage->_documentsURL=[documents copy];
    stage->_sourceExportCandidate=candidate;
    stage->_language=[language copy];stage->_sha256=[sha256 copy];stage->_bytes=bytes;stage->_current=[current copy];
    int currentFD=openat(stage->_sqlite,"current",O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);
    int languageFD=currentFD>=0?openat(currentFD,language.UTF8String,O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC):-1;
    if(languageFD>=0)stage->_working=openat(languageFD,"database.db",O_RDONLY|O_NOFOLLOW|O_CLOEXEC);
    if(languageFD>=0)close(languageFD);if(currentFD>=0)close(currentFD);
    if(stage->_working<0||![stage confirmBeforeOriginalImageLoad:error])return nil;
    return stage;
}
- (BOOL)confirmBeforeOriginalImageLoad:(NSError **)error {
    struct stat docs,assets,sql,file,path;BOOL valid=_current&&_current()&&ODColdOriginalEngineAbsent()&&_working>=0&&
        !fstat(_documents,&docs)&&docs.st_dev==_documentsIdentity.st_dev&&docs.st_ino==_documentsIdentity.st_ino&&
        !lstat(_documentsURL.fileSystemRepresentation,&path)&&S_ISDIR(path.st_mode)&&!S_ISLNK(path.st_mode)&&
        path.st_dev==docs.st_dev&&path.st_ino==docs.st_ino&&
        !fstat(_assets,&assets)&&assets.st_dev==_assetsIdentity.st_dev&&assets.st_ino==_assetsIdentity.st_ino&&
        !lstat(_assetsRootURL.fileSystemRepresentation,&path)&&S_ISDIR(path.st_mode)&&!S_ISLNK(path.st_mode)&&
        path.st_dev==assets.st_dev&&path.st_ino==assets.st_ino&&ODColdMissing(_assets,"User")&&
        !fstat(_sqlite,&sql)&&sql.st_dev==_sqliteIdentity.st_dev&&sql.st_ino==_sqliteIdentity.st_ino&&
        !fstatat(_assets,"sqlite",&path,AT_SYMLINK_NOFOLLOW)&&S_ISDIR(path.st_mode)&&!S_ISLNK(path.st_mode)&&
        path.st_dev==sql.st_dev&&path.st_ino==sql.st_ino&&
        !fstat(_working,&file)&&S_ISREG(file.st_mode)&&file.st_nlink==1&&(file.st_mode&0777)==0600&&
        ODColdSame(&file,&_workingIdentity)&&[ODColdHash(_working,_bytes) isEqual:_sha256];
    int current=valid?openat(_sqlite,"current",O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC):-1;
    int language=current>=0?openat(current,_language.UTF8String,O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC):-1;
    valid=valid&&language>=0&&!fstatat(language,"database.db",&path,AT_SYMLINK_NOFOLLOW)&&
        S_ISREG(path.st_mode)&&!S_ISLNK(path.st_mode)&&ODColdSame(&file,&path)&&_current();
    if(language>=0)close(language);if(current>=0)close(current);
    return valid?YES:ODColdFail(error,@"NATIVE_MASTER_COLD_COPY_CHANGED");
}
@end
