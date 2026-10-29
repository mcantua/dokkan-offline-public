#import "ODUnifiedDuoNativeFactory.h"
#import "ODOriginalDuoStartupDiagnostic.h"
#import "../duo/ODUnifiedDuoHost.h"
#import "../duo/ODDeferredOriginalPlayerAdmission.h"
#import "../../adapter/ios/ODNativeCore.h"
#import "../creator/ODBoundOriginalCreatorServices.h"
#import "../ios/ODOriginalPlayerResourcesAdapter.h"
#import <CommonCrypto/CommonDigest.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>

static NSString * const ODFactoryBundleID=@"org.offlinedokkan.duo";
static NSString * const ODFactoryMasterHash=@"1a8f5a823a6efa7343ff463b92197a574898e03569e2067f3daf8a4f282be4f4";
static const uint64_t ODFactoryMasterBytes=114827264;
static NSString * const ODFactoryModuleHash=@"94472e085540c5502e928e629cb5b153fbbbc8c05a87f859eaa9f0459cb4881c";
static NSString * const ODFactorySchemaHash=@"0db95aef3ea8d86a6fbab4c886aee6c4fc55f16d2f32f5ff370557d73e0c4feb";
// Explicit local issuer policy; not a recovered original server duration.
static const int32_t ODFactoryOfflineTokenSeconds=3600;

static NSError *ODFactoryFailure(void) {
    return [NSError errorWithDomain:@"OfflineDokkan.NativeComposition" code:1
        userInfo:@{NSLocalizedDescriptionKey:@"ORIGINAL_DUO_COMPOSITION_UNAVAILABLE"}];
}
static BOOL ODFactorySameFile(struct stat a,struct stat b) {
    return S_ISREG(b.st_mode)&&b.st_nlink==1&&a.st_dev==b.st_dev&&a.st_ino==b.st_ino&&
        a.st_size==b.st_size&&a.st_mtimespec.tv_sec==b.st_mtimespec.tv_sec&&
        a.st_mtimespec.tv_nsec==b.st_mtimespec.tv_nsec;
}
static int ODFactoryDirectory(NSURL *url) {
    if(!url.isFileURL||!url.path.isAbsolutePath)return -1;
    int fd=open("/",O_RDONLY|O_DIRECTORY|O_CLOEXEC);if(fd<0)return -1;
    for(NSString *part in url.path.pathComponents){
        if([part isEqual:@"/"])continue;
        if([part isEqual:@"."]||[part isEqual:@".."]) {close(fd);return -1;}
        int next=openat(fd,part.fileSystemRepresentation,O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);
        close(fd);if(next<0)return -1;fd=next;
    }
    return fd;
}
/** Keep the exact verified readonly Core input open. This is the plaintext
 * canonical-data reference, never the original opaque-key MAIN working DB. */
static int ODFactoryOpenMaster(NSURL *url,struct stat *identity) {
    int parent=ODFactoryDirectory(url.URLByDeletingLastPathComponent);if(parent<0)return -1;
    int fd=openat(parent,url.lastPathComponent.fileSystemRepresentation,O_RDONLY|O_NOFOLLOW|O_CLOEXEC);
    close(parent);if(fd<0)return -1;
    struct stat before,after;unsigned char header[16];
    BOOL valid=!fstat(fd,&before)&&S_ISREG(before.st_mode)&&before.st_nlink==1&&
        before.st_size==(off_t)ODFactoryMasterBytes&&pread(fd,header,sizeof header,0)==sizeof header&&
        !memcmp(header,"SQLite format 3\0",sizeof header);
    CC_SHA256_CTX hash;CC_SHA256_Init(&hash);unsigned char buffer[65536],digest[CC_SHA256_DIGEST_LENGTH];
    uint64_t done=0;
    while(valid&&done<ODFactoryMasterBytes){
        ssize_t count=pread(fd,buffer,sizeof buffer,(off_t)done);
        if(count<0&&errno==EINTR)continue;
        if(count<=0||(uint64_t)count>ODFactoryMasterBytes-done){valid=NO;break;}
        CC_SHA256_Update(&hash,buffer,(CC_LONG)count);done+=(uint64_t)count;
    }
    CC_SHA256_Final(digest,&hash);NSMutableString *hex=[NSMutableString stringWithCapacity:64];
    for(NSUInteger i=0;i<sizeof digest;i++)[hex appendFormat:@"%02x",digest[i]];
    valid=valid&&done==ODFactoryMasterBytes&&[hex isEqual:ODFactoryMasterHash]&&
        !fstat(fd,&after)&&ODFactorySameFile(before,after);
    if(!valid){close(fd);return -1;}*identity=before;return fd;
}

@interface ODUnifiedNativeComposition : NSObject
@property(nonatomic,strong) ODOriginalDuoStartupInputs *inputs;
@property(nonatomic,strong) ODUnifiedDuoHost *host;
@property(nonatomic,strong) ODNativeCore *core;
@property(nonatomic,strong) ODDeferredOriginalPlayerAdmission *player;
@property(nonatomic,strong) ODOriginalPlayerResourcesAdapter *resources;
@property(nonatomic,strong) ODBoundOriginalCreatorServices *services;
@property(nonatomic,strong) ODResourceResponseProjector *projector;
@property(nonatomic,copy) NSURL *masterURL;
@property(nonatomic,copy) NSURL *saveURL;
@property(nonatomic,copy) NSString *contentID;
@property(nonatomic,copy) NSString *stage;
@property(nonatomic,copy) NSDictionary *lastHostReport;
@property(nonatomic,strong) dispatch_queue_t preparationQueue;
@property(nonatomic) BOOL failed;
- (BOOL)isCurrent;
- (void)preparePlayer;
- (NSDictionary *)report;
@end

@implementation ODUnifiedNativeComposition {
@public
    int _masterFD;
    struct stat _masterIdentity;
}
- (instancetype)init {if((self=[super init])){_masterFD=-1;_stage=@"preparing-native-inputs";}return self;}
- (void)dealloc {if(_masterFD>=0)close(_masterFD);}
- (BOOL)isCurrent {
    if(!NSThread.isMainThread||_failed||![_contentID isKindOfClass:NSString.class]||
       ![NSBundle.mainBundle.bundleIdentifier isEqual:ODFactoryBundleID]||
       ![_core matchesSaveURL:_saveURL masterURL:_masterURL contentID:_contentID])return NO;
    struct stat held,path;
    return !fstat(_masterFD,&held)&&!lstat(_masterURL.fileSystemRepresentation,&path)&&
        ODFactorySameFile(_masterIdentity,held)&&ODFactorySameFile(held,path);
}
- (NSDictionary *)report {
    return @{@"schema":@1,@"purpose":@"integrated-duo-target",@"factoryStage":_stage?:@"unavailable",
        @"sameCanonicalCoreCaptured":@(_core!=nil&&_player!=nil),
        @"canonicalPlayerAdmitted":@(_player.preparedAdmission!=nil),
        @"sameCoreCreatorServicesIssued":@(_services!=nil),@"scopedPlayerProjectorIssued":@(_projector!=nil),
        @"freshNativeInputsOnly":@YES,@"nativeSaveResumeVerified":@NO,
        @"sourceAccountUsed":@NO,@"plaintextReferenceIsNativeMasterAdmission":@NO,
        @"nativeMasterAccepted":@NO,@"actualOfflineLoginVerified":@NO,
        @"actualHomeVerified":@NO,@"actualBattleAndSaveVerified":@NO,
        @"host":_lastHostReport?:@{}};
}
- (void)preparePlayer {
    __weak ODUnifiedNativeComposition *weakSelf=self;
    [_host prepareDeferredPlayerAdmissionOnQueue:_preparationQueue completion:^(NSError *failure){
        ODUnifiedNativeComposition *owner=weakSelf;if(!owner)return;
        if(failure||![owner isCurrent]){owner.failed=YES;owner.stage=@"canonical-player-preparation-failed";return;}
        NSString *scope=[owner.player.preparedAdmission[@"save_scope_sha256"] copy];
        if(!scope.length){owner.failed=YES;owner.stage=@"canonical-player-admission-missing";return;}
        owner.stage=@"issuing-same-core-services";
        dispatch_async(owner.preparationQueue,^{
            BOOL (^current)(void)=^BOOL{ODUnifiedNativeComposition *active=weakSelf;return active&&[active isCurrent];};
            NSURL *workspace=[owner.inputs.writableStateRootURL URLByAppendingPathComponent:[@"creator-" stringByAppendingString:scope] isDirectory:YES];
            NSURL *overlay=[owner.inputs.writableStateRootURL URLByAppendingPathComponent:
                [NSString stringWithFormat:@"creator-overlay-%@.sqlite",scope] isDirectory:NO];
            ODBoundOriginalCreatorServices *services=[[ODBoundOriginalCreatorServices alloc]
                initWithCore:owner.core masterURL:owner.masterURL masterBytes:ODFactoryMasterBytes
                contentID:owner.contentID sourceDatabase:@"sparking" saveURL:owner.saveURL
                workspaceURL:workspace overlayURL:overlay expectedSaveScopeSHA256:scope contextIsCurrent:current error:NULL];
            NSURL *protocolRoot=[owner.inputs.bundleRootURL URLByAppendingPathComponent:@"OriginalClient/Protocol" isDirectory:YES];
            ODResourceResponseProjector *projector=services?[[ODResourceResponseProjector alloc]
                initWithCore:owner.core saveURL:owner.saveURL masterURL:owner.masterURL contentID:owner.contentID
                profileID:@"local-player" saveScopeSHA256:scope
                schemaURL:[protocolRoot URLByAppendingPathComponent:@"cached-resource-response-schema.json"] schemaSHA256:ODFactorySchemaHash
                moduleURL:[protocolRoot URLByAppendingPathComponent:@"resources-projector.js"] moduleSHA256:ODFactoryModuleHash
                nativePolicy:nil contextCurrent:current]:nil;
            dispatch_async(dispatch_get_main_queue(),^{
                if(!services||!projector||![owner isCurrent]||
                   ![owner.player.preparedAdmission[@"save_scope_sha256"] isEqual:scope]){
                    owner.failed=YES;owner.stage=@"same-core-service-issuance-failed";return;
                }
                owner.projector=projector;
                [owner.host bindCreatorServicesWhenReady:services completion:^(NSError *bindingFailure){
                    if(bindingFailure){owner.failed=YES;owner.projector=nil;owner.stage=@"same-core-service-binding-failed";return;}
                    owner.services=services;owner.stage=@"original-client-auth-and-profile-ready";
                }];
            });
        });
    }];
}
@end

static ODUnifiedNativeComposition *ODUnifiedComposition;
static BOOL ODUnifiedFactoryAttempted;

ODUnifiedDuoHost *ODCreateUnifiedDuoStartupHost(NSError **error) {
    if(!NSThread.isMainThread||ODUnifiedFactoryAttempted){if(error)*error=ODFactoryFailure();return nil;}
    ODUnifiedFactoryAttempted=YES;
    ODOriginalDuoStartupInputs *inputs=ODPrepareOriginalDuoStartupInputs(ODOriginalDuoInputsIntegrated,NULL);
    if(!inputs){if(error)*error=ODFactoryFailure();return nil;}
    ODUnifiedNativeComposition *owner=[ODUnifiedNativeComposition new];owner.inputs=inputs;
    owner.masterURL=[inputs.bundleRootURL URLByAppendingPathComponent:@"OriginalClient/Core/reference.db" isDirectory:NO];
    owner->_masterFD=ODFactoryOpenMaster(owner.masterURL,&owner->_masterIdentity);
    if(owner->_masterFD<0){if(error)*error=ODFactoryFailure();return nil;}
    owner.contentID=[@"sha256:" stringByAppendingString:ODFactoryMasterHash];
    owner.saveURL=[inputs.writableStateRootURL URLByAppendingPathComponent:@"player.db" isDirectory:NO];
    owner.core=[[ODNativeCore alloc] initWithSaveURL:owner.saveURL masterURL:owner.masterURL contentID:owner.contentID];
    owner.player=[[ODDeferredOriginalPlayerAdmission alloc] initWithCore:owner.core saveURL:owner.saveURL
        masterURL:owner.masterURL contentID:owner.contentID];
    owner.preparationQueue=dispatch_queue_create("org.offlinedokkan.duo.cold-player",DISPATCH_QUEUE_SERIAL);
    __weak ODUnifiedNativeComposition *weakOwner=owner;
    BOOL (^current)(void)=^BOOL{ODUnifiedNativeComposition *active=weakOwner;return active&&[active isCurrent];};
    owner.resources=[[ODOriginalPlayerResourcesAdapter alloc] initWithProjectorProvider:^ODResourceResponseProjector *{
        ODUnifiedNativeComposition *active=weakOwner;
        return active&&[active isCurrent]?active.projector:nil;
    } contextCurrent:current masterContextCurrent:^BOOL{
        ODUnifiedNativeComposition *active=weakOwner;
        return active&&[active isCurrent]&&active.host.originalGameDataAdmitted;
    }];
    owner.host=[[ODUnifiedDuoHost alloc] initWithPurpose:ODUnifiedDuoIntegratedTarget
        genuineShellBaselineURL:inputs.genuineShellBaselineURL preparedEngineURL:inputs.preparedEngineURL
        resourcesRootURL:inputs.resourcesRootURL writableStateRootURL:inputs.writableStateRootURL
        approvedOrigins:@[] routes:owner.resources.routes creatorServices:nil attachPreparedImage:nil
        contextIsCurrent:current reportHandler:^(NSDictionary *report){ODUnifiedNativeComposition *active=weakOwner;
            if(active)active.lastHostReport=[report copy];} error:NULL];
    if(!owner.player||!owner.resources||!owner.host||
       ![owner.host expectDeferredCreatorServicesForPlayerAdmission:owner.player error:NULL]||
       ![owner.host configureOfflineAuthForDeferredPlayerWithExpiresIn:ODFactoryOfflineTokenSeconds error:NULL]){
        if(error)*error=ODFactoryFailure();return nil;
    }
    owner.stage=@"waiting-for-main-loop-player-admission";ODUnifiedComposition=owner;
    [owner preparePlayer];return owner.host;
}

NSDictionary *ODCopyUnifiedDuoNativeFactoryReport(void) {
    return NSThread.isMainThread?[ODUnifiedComposition report]:nil;
}
