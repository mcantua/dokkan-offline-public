#import "ODUnifiedDuoHost.h"
#import "ODDuoCreatorQuickAction.h"
#import "../ios/ODFreshStatePolicy.h"
#import "../ios/ODOfflineBootstrapAuth.h"
#import "../ios/ODOriginalClientBootstrap.h"
#import "../loader/ODPreparedEngineLoader.h"
#import "../creator/ODBoundOriginalCreatorServices.h"
#include <mach-o/dyld.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>

static ODUnifiedDuoHost *ODInstalledUnifiedHost;
static NSError *ODHostFailure(NSInteger code) {
    NSString *message = code == 9
        ? @"Auth routes stay closed because the HTTP JSON envelope is not verified. No success body was installed."
        : @"The native original-game startup or same-save binding is unavailable. Existing files were preserved.";
    return [NSError errorWithDomain:@"OfflineDokkan.UnifiedDuoHost" code:code
        userInfo:@{NSLocalizedDescriptionKey:message}];
}
static BOOL ODHostClosedAuthPath(NSString *path) {
    return [path isEqualToString:@"/auth/nonce"] || [path isEqualToString:@"/auth/sign_in"];
}
static NSString *ODHostCanonicalURL(NSURL *url) {
    if(!url.isFileURL||!url.path.isAbsolutePath)return nil;
    struct stat direct;if(lstat(url.fileSystemRepresentation,&direct)||S_ISLNK(direct.st_mode))return nil;
    return [url.path.stringByStandardizingPath stringByResolvingSymlinksInPath];
}
static int ODHostDirectory(NSString *path) {
    if(!path.isAbsolutePath)return -1;
    int fd=open("/",O_RDONLY|O_DIRECTORY|O_CLOEXEC);if(fd<0)return -1;
    for(NSString *part in path.pathComponents){if([part isEqual:@"/"])continue;
        int next=openat(fd,part.fileSystemRepresentation,O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);close(fd);if(next<0)return -1;fd=next;}
    return fd;
}
static BOOL ODHostSameDirectory(NSString *path,int fd) {
    struct stat pinned,current;return !fstat(fd,&pinned)&&!lstat(path.fileSystemRepresentation,&current)&&
        S_ISDIR(current.st_mode)&&!S_ISLNK(current.st_mode)&&current.st_dev==pinned.st_dev&&current.st_ino==pinned.st_ino;
}
static BOOL ODHostSourcePatcherAbsent(void) {
    NSURL *folder=NSBundle.mainBundle.privateFrameworksURL;
    if(folder){int fd=ODHostDirectory(folder.path);if(fd<0)return NO;
        struct stat st;int present=fstatat(fd,"DokkanSparkingPatcher.dylib",&st,AT_SYMLINK_NOFOLLOW);int code=errno;close(fd);
        if(!present||code!=ENOENT)return NO;
    }
    uint32_t images=_dyld_image_count();
    for(uint32_t i=0;i<images;++i){const char *name=_dyld_get_image_name(i);if(!name)return NO;
        const char *base=strrchr(name,'/');if(!strcmp(base?base+1:name,"DokkanSparkingPatcher.dylib"))return NO;}
    return YES;
}

@implementation ODUnifiedDuoHost {
    ODUnifiedDuoPurpose _purpose;
    NSURL *_baseline,*_engine;
    NSString *_resources,*_state;
    NSArray<NSURL *> *_origins;
    NSArray<ODLocalTransportRoute *> *_routes;
    ODBoundOriginalCreatorServices *_services;
    ODUnifiedDuoImageAttachment _attach;
    BOOL (^_current)(void);
    ODUnifiedDuoReportHandler _report;
    BOOL _attempted,_environmentPrepared,_foundationInstalled,_engineLoaded,_imageAttached,_sceneObserved,_creatorAttached,_installed;
    BOOL _requestObserverInstalled;
    NSMutableArray<NSDictionary *> *_unsupportedRequests;
    NSDictionary *_creatorEntryReport;
    NSString *_stage;
    int _resourceFD,_stateFD;
    __weak UIViewController *_originalController;
    __weak UIView *_renderer;
}
- (instancetype)initWithPurpose:(ODUnifiedDuoPurpose)purpose genuineShellBaselineURL:(NSURL *)baseline
        preparedEngineURL:(NSURL *)engine resourcesRootURL:(NSURL *)resources writableStateRootURL:(NSURL *)state
        approvedOrigins:(NSArray<NSURL *> *)origins routes:(NSArray<ODLocalTransportRoute *> *)routes
        creatorServices:(ODBoundOriginalCreatorServices *)services attachPreparedImage:(ODUnifiedDuoImageAttachment)attach
        contextIsCurrent:(BOOL (^)(void))current reportHandler:(ODUnifiedDuoReportHandler)report error:(NSError **)error {
    if(!(self=[super init]))return nil;_resourceFD=-1;_stateFD=-1;
    NSString *resourcePath=ODHostCanonicalURL(resources),*statePath=ODHostCanonicalURL(state);
    if((purpose!=ODUnifiedDuoStartupDiagnostic&&purpose!=ODUnifiedDuoIntegratedTarget)||!baseline.isFileURL||!engine.isFileURL||
       !resourcePath||!statePath||[statePath isEqual:resourcePath]||[statePath hasPrefix:[resourcePath stringByAppendingString:@"/"]]||
       ![origins isKindOfClass:NSArray.class]||![routes isKindOfClass:NSArray.class]||!current||!report||
       (purpose==ODUnifiedDuoIntegratedTarget&&(!services||!attach||!origins.count||!routes.count))){
        if(error)*error=ODHostFailure(1);return nil;
    }
    for (id route in routes) {
        if (![route isKindOfClass:ODLocalTransportRoute.class]) { if (error) *error = ODHostFailure(1); return nil; }
        if (ODHostClosedAuthPath([(ODLocalTransportRoute *)route path])) { if (error) *error = ODHostFailure(9); return nil; }
    }
    _purpose=purpose;_baseline=[baseline copy];_engine=[engine copy];_resources=resourcePath;_state=statePath;
    _origins=[origins copy];_routes=[routes copy];_services=services;_attach=[attach copy];_current=[current copy];_report=[report copy];_stage=@"configured";
    _unsupportedRequests=[NSMutableArray array];
    return self;
}
- (void)dealloc{if(_resourceFD>=0)close(_resourceFD);if(_stateFD>=0)close(_stateFD);}
- (NSDictionary *)startupReport {
    return @{@"schema":@1,@"purpose":_purpose==ODUnifiedDuoStartupDiagnostic?@"original-startup-diagnostic":@"integrated-duo-target",
        @"stage":_stage?:@"unconfigured",@"bootstrapInstalled":@(_installed),@"nativeEnvironmentPrepared":@(_environmentPrepared),
        @"localFoundationTransportInstalled":@(_foundationInstalled),@"preparedEngineLoaded":@(_engineLoaded),
        @"nativeImageAttachmentConfigured":@(_imageAttached),@"originalRendererObserved":@(_sceneObserved),
        @"boundCreatorAttached":@(_creatorAttached),@"registeredRouteCount":@(_routes.count),
        @"unsupportedRequestObserverInstalled":@(_requestObserverInstalled),
        @"unsupportedFoundationRequests":[_unsupportedRequests copy],
        @"creatorEntry":_creatorEntryReport?:@{@"outcome":@"not-configured"},
        @"nativeNetworkCoverage":@"Installed Foundation handling only; raw socket, SDK/system and WebKit activity require observation/configuration",
        @"kernelNetworkIsolationEstablished":@NO,@"routeContractsRuntimeVerified":@NO,
        @"offlineAuthReaderRelativeOnly":@YES,@"offlineAuthWireEnvelopeVerified":@NO,
        @"offlineAuthHttpRouteAdmitted":@NO,@"freshStateSentinelsAdopted":@NO,
        @"freshStateTutorialAndCapacityUnresolved":@YES,@"freshStateStartingStatsInvented":@NO,
        @"gameplaySaveCustomUnitsVerified":@NO,@"bothDuoDisplaysAccepted":@NO};
}
- (void)emit { if(_report)_report(self.startupReport); }
- (BOOL)prepareNativeEnvironment:(NSError **)error {
    if(!NSThread.isMainThread||!_current()||!ODHostSourcePatcherAbsent()){
        if(error)*error=ODHostFailure(2);return NO;
    }
    _resourceFD=ODHostDirectory(_resources);_stateFD=ODHostDirectory(_state);
    if(_resourceFD<0||_stateFD<0){if(error)*error=ODHostFailure(3);return NO;}
    /* Real capability preparation, not a synthetic containment boolean. The
       designated native state directory must support exclusive durable writes. */
    NSString *probe=[@".duo-startup-" stringByAppendingString:NSUUID.UUID.UUIDString];
    int fd=openat(_stateFD,probe.fileSystemRepresentation,O_WRONLY|O_CREAT|O_EXCL|O_NOFOLLOW|O_CLOEXEC,0600);
    BOOL created=fd>=0,valid=created;const unsigned char marker=1;
    if(valid)valid=write(fd,&marker,1)==1&&fsync(fd)==0;
    if(fd>=0&&close(fd))valid=NO;
    if(created&&unlinkat(_stateFD,probe.fileSystemRepresentation,0))valid=NO;
    valid=valid&&ODHostSameDirectory(_resources,_resourceFD)&&ODHostSameDirectory(_state,_stateFD)&&_current();
    if(!valid){if(error)*error=ODHostFailure(4);return NO;}
    _environmentPrepared=YES;_stage=@"native-environment-prepared";[self emit];return YES;
}
- (BOOL)registerOriginalScene:(NSError **)error {
    __weak ODUnifiedDuoHost *weakSelf=self;
    if(!ODDuoConfigureOriginalSceneBridge(^(UIViewController *controller,UIView *renderer,ODDuoDisplaySnapshot *snapshot){
        (void)snapshot;ODUnifiedDuoHost *host=weakSelf;if(!host)return;
        host->_sceneObserved=YES;host->_originalController=controller;host->_renderer=renderer;
        if(!host->_current()){host->_creatorAttached=NO;host->_stage=@"native-context-no-longer-current";[host emit];return;}
        if(host->_services){NSError *failure=nil;
            host->_creatorAttached=[host->_services attachToOriginalWindow:renderer.window controller:controller renderer:renderer error:&failure];
            host->_stage=host->_creatorAttached?@"original-scene-and-creator-bound":@"creator-binding-not-attached";
        }else host->_stage=@"original-scene-observed-diagnostic-only";
        [host emit];
    },^(NSError *failure){
        (void)failure;ODUnifiedDuoHost *host=weakSelf;if(!host)return;
        host->_creatorAttached=NO;host->_stage=@"original-scene-admission-failed";[host emit];
    },error))return NO;
    if(_services&&![_services.coordinator installOriginalSceneLifecycleWithError:error])return NO;
    if(_services&&!ODDuoConfigureCreatorQuickAction(^BOOL{
        ODUnifiedDuoHost *host=weakSelf;return host&&host->_current();
    },^ODDuoCreatorQuickActionReadiness(UIWindow *window,UIViewController *controller,UIView *renderer){
        ODUnifiedDuoHost *host=weakSelf;
        if(!host||!host->_current())return ODDuoCreatorEntryRejected;
        if(host->_services.coordinator.creatorIsOpen)return ODDuoCreatorEntryAlreadyOpen;
        if(!host->_installed||!host->_sceneObserved)return ODDuoCreatorEntryWaiting;
        if(!host->_creatorAttached||controller!=host->_originalController||renderer!=host->_renderer||renderer.window!=window)
            return ODDuoCreatorEntryRejected;
        return ODDuoCreatorEntryReady;
    },^(void (^completion)(NSError *)){
        ODUnifiedDuoHost *host=weakSelf;if(!host){completion(ODHostFailure(8));return;}
        [host presentCreatorFromUserActionWithCompletion:completion];
    },^(NSDictionary *state){
        ODUnifiedDuoHost *host=weakSelf;if(!host)return;host->_creatorEntryReport=[state copy];[host emit];
    },error))return NO;
    return YES;
}
- (BOOL)installBeforeApplicationMain:(NSError **)error {
    if(!NSThread.isMainThread||_attempted||ODInstalledUnifiedHost||!_current()||
       (_purpose==ODUnifiedDuoIntegratedTarget&&![_services creatorScopeIsCurrent])){
        if(error)*error=ODHostFailure(5);return NO;
    }
    _attempted=YES;_stage=@"installing-genuine-shell-bootstrap";[self emit];
    __weak ODUnifiedDuoHost *weakSelf=self;
    /* The transport supplies only its reviewed method/static-path vocabulary,
       with dynamic identifiers replaced by {id}. Never inspect the request or
       synchronously wait for main from its serial transport callback. */
    _requestObserverInstalled=ODObserveUnsupportedOriginalRequests(^(NSString *method,NSString *path){
        dispatch_async(dispatch_get_main_queue(),^{
            ODUnifiedDuoHost *host=weakSelf;
            if(!host||!host->_current()||host->_unsupportedRequests.count>=64)return;
            NSDictionary *row=@{@"method":method,@"path":path};
            if([host->_unsupportedRequests containsObject:row])return;
            [host->_unsupportedRequests addObject:row];[host emit];
        });
    },error);
    if(!_requestObserverInstalled){_stage=@"request-observer-registration-failed";[self emit];return NO;}
    BOOL ok=ODInstallPreparedDuoShellBootstrap(_baseline,_origins,_routes,^BOOL(NSError **failure){
        ODUnifiedDuoHost *host=weakSelf;if(!host){if(failure)*failure=ODHostFailure(6);return NO;}
        /* This callback is reached only after the bootstrap has successfully
           installed its actual local Foundation protocol. */
        host->_foundationInstalled=YES;
        BOOL loaded=ODLoadPreparedOriginalEngine(host->_engine,^BOOL(NSError **preparationError){
            return [host prepareNativeEnvironment:preparationError];
        },failure);
        host->_engineLoaded=loaded;if(!loaded){host->_stage=@"prepared-image-load-failed";[host emit];return NO;}
        host->_stage=@"original-initializers-completed";
        if(host->_attach){host->_imageAttached=host->_attach(failure);if(!host->_imageAttached){host->_stage=@"native-image-attachment-failed";[host emit];return NO;}}
        [host emit];return host->_current();
    },^BOOL(NSError **failure){return [weakSelf registerOriginalScene:failure];},error);
    _installed=ok;_stage=ok?@"waiting-for-actual-appcontroller-scene":@"bootstrap-installation-failed";
    if(ok)ODInstalledUnifiedHost=self;[self emit];return ok;
}
- (NSDictionary *)issueOfflineAuthEnvelopeWithNativeTime:(int32_t)nativeTime expiresIn:(int32_t)expiresIn error:(NSError **)error {
    if (!NSThread.isMainThread || !_current()) { if (error) *error = ODHostFailure(2); return nil; }
    return [ODOfflineBootstrapAuth issueWithNativeTime:nativeTime expiresIn:expiresIn error:error];
}
- (NSDictionary *)freshStatePolicyForSnapshot:(NSDictionary *)snapshot proposedSections:(NSDictionary *)proposed error:(NSError **)error {
    if (!NSThread.isMainThread || !_current()) { if (error) *error = ODHostFailure(2); return nil; }
    return [ODFreshStatePolicy evaluateSnapshot:snapshot proposedSections:proposed error:error];
}
- (void)presentCreatorFromUserActionWithCompletion:(void (^)(NSError *))completion {
    if(!completion)return;
    if(!NSThread.isMainThread){dispatch_async(dispatch_get_main_queue(),^{[self presentCreatorFromUserActionWithCompletion:completion];});return;}
    if(!_installed||!_services||!_creatorAttached||!_current()||!_originalController||!_renderer||![_services creatorScopeIsCurrent]){
        completion(ODHostFailure(7));return;
    }
    [_services presentCreatorFromUserActionWithCompletion:completion];
}
@end
