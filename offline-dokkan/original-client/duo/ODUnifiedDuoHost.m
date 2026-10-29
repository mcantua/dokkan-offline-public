#import "ODUnifiedDuoHost.h"
#import "ODDuoCreatorQuickAction.h"
#import "ODDeferredOriginalPlayerAdmission.h"
#import "../ios/ODFreshStatePolicy.h"
#import "../ios/ODOfflineBootstrapAuth.h"
#import "../ios/ODOriginalNativeOrigin.h"
#import "../ios/ODLocalURLProtocolBootstrap.h"
#import "creator_late_bind.h"
#import "creator_menu_policy.h"
#import "../content/engine_master_attach.h"
#import "../content/ODNativeMasterColdStage.h"
#import "../ios/ODOriginalClientBootstrap.h"
#import "../loader/ODPreparedEngineLoader.h"
#import "../creator/ODBoundOriginalCreatorServices.h"
#import "../../adapter/ios/ODNativeCore.h"
#include <mach-o/dyld.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>

static ODUnifiedDuoHost *ODInstalledUnifiedHost;
static NSError *ODHostFailure(NSInteger code) {
    NSString *message = code == 11
        ? @"Offline login is not ready. The complete sign-in response and native login path still need verification."
        : @"The native original-game startup or same-save binding is unavailable. Existing files were preserved.";
    return [NSError errorWithDomain:@"OfflineDokkan.UnifiedDuoHost" code:code
        userInfo:@{NSLocalizedDescriptionKey:message}];
}
static BOOL ODHostClosedAuthPath(NSString *path) {
    return [path isEqualToString:@"/ping"] || [path isEqualToString:@"/auth/nonce"] || [path isEqualToString:@"/auth/sign_in"];
}
static BOOL ODHostAuthScopeChanged(NSError *error) {
    // Core emits this fixed code when its atomic admission no longer matches.
    // Never log or forward an arbitrary native error description.
    return [error.domain isEqualToString:@"OfflineDokkanCore"]&&
        [error.userInfo[NSLocalizedDescriptionKey] isEqual:@"ORIGINAL_PLAYER_SCOPE_CHANGED"];
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
static BOOL ODHostHex(NSString *value) {
    return [value isKindOfClass:NSString.class]&&value.length==64&&
        [value rangeOfCharacterFromSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdef"] invertedSet]].location==NSNotFound;
}
static BOOL ODHostContentID(NSString *value) {
    if(![value isKindOfClass:NSString.class])return NO;
    NSString *body=value;
    if([value hasPrefix:@"sparking:"])body=[value substringFromIndex:9];
    else if([value hasPrefix:@"eclipse:"])body=[value substringFromIndex:8];
    return [body hasPrefix:@"sha256:"]&&body.length==71&&ODHostHex([body substringFromIndex:7]);
}
static BOOL ODHostSourcePatcherAbsent(void) {
    NSURL *folder=NSBundle.mainBundle.privateFrameworksURL;
    if(folder){NSString *canonical=ODHostCanonicalURL(folder);int fd=canonical?ODHostDirectory(canonical):-1;
        if(fd<0)return NO;
        BOOL same=ODHostSameDirectory(canonical,fd)&&ODHostSameDirectory(folder.path,fd);
        struct stat st;int present=fstatat(fd,"DokkanSparkingPatcher.dylib",&st,AT_SYMLINK_NOFOLLOW);int code=errno;
        same=same&&ODHostSameDirectory(canonical,fd)&&ODHostSameDirectory(folder.path,fd);close(fd);
        if(!same||!present||code!=ENOENT)return NO;
    }
    uint32_t images=_dyld_image_count();
    for(uint32_t i=0;i<images;++i){const char *name=_dyld_get_image_name(i);if(!name)return NO;
        const char *base=strrchr(name,'/');if(!strcmp(base?base+1:name,"DokkanSparkingPatcher.dylib"))return NO;}
    return YES;
}

@interface ODUnifiedDuoHost ()
- (BOOL)configureOfflineAuthForContentID:(NSString *)contentID saveScopeSHA256:(nullable NSString *)scope
    deferredPlayer:(nullable ODDeferredOriginalPlayerAdmission *)player expiresIn:(int32_t)expiresIn error:(NSError **)error;
@end

@implementation ODUnifiedDuoHost {
    ODUnifiedDuoPurpose _purpose;
    NSURL *_baseline,*_engine;
    NSString *_resources,*_state;
    NSArray<NSURL *> *_origins;
    NSArray<ODLocalTransportRoute *> *_routes;
    ODBoundOriginalCreatorServices *_services;
    ODDeferredOriginalPlayerAdmission *_deferredPlayer;
    BOOL _deferredPlayerPreparationRequested;
    ODUnifiedDuoImageAttachment _attach;
    BOOL (^_current)(void);
    ODUnifiedDuoReportHandler _report;
    BOOL _attempted,_environmentPrepared,_foundationInstalled,_engineLoaded,_imageAttached,_sceneObserved,_creatorAttached,_installed;
    BOOL _requestObserverInstalled,_servicesPending,_lifecycleInstalled,_masterAttached,_masterReadonlyReady,_assetRootHasMaster;
    BOOL _authConfigured,_authInvalidated;
    BOOL _nativeOriginArmed;
    NSUInteger _authGeneration;
    NSString *_authContent,*_authScope;
    NSArray<ODLocalTransportRoute *> *_authIssuerRoutes;
    NSMutableArray<dispatch_block_t> *_pendingAuthRequests;
    NSString *_admittedContent,*_admittedScope,*_masterSourcePath,*_masterLanguage,*_masterSHA,*_masterRelative;
    uint64_t _masterBytes;
    ODNativeMasterColdStage *_originalMasterStage;
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
       (purpose==ODUnifiedDuoIntegratedTarget&&origins.count)){
        if(error)*error=ODHostFailure(1);return nil;
    }
    for (id route in routes) {
        if (![route isKindOfClass:ODLocalTransportRoute.class]) { if (error) *error = ODHostFailure(1); return nil; }
        if (ODHostClosedAuthPath([(ODLocalTransportRoute *)route path])) { if (error) *error = ODHostFailure(11); return nil; }
    }
    _purpose=purpose;_baseline=[baseline copy];_engine=[engine copy];_resources=resourcePath;_state=statePath;
    _origins=[origins copy];_routes=[routes copy];_services=services;_attach=[attach copy];_current=[current copy];_report=[report copy];_stage=@"configured";
    _unsupportedRequests=[NSMutableArray array];
    return self;
}
- (void)dealloc{if(_resourceFD>=0)close(_resourceFD);if(_stateFD>=0)close(_stateFD);}
- (BOOL)originalGameDataAdmitted {
    // No native schema/selected-master acceptance capability exists yet.
    // Original initialization must run before its real outcome can be observed.
    return NO;
}
- (NSDictionary *)startupReport {
    return @{@"schema":@1,@"purpose":_purpose==ODUnifiedDuoStartupDiagnostic?@"original-startup-diagnostic":@"integrated-duo-target",
        @"stage":_stage?:@"unconfigured",@"bootstrapInstalled":@(_installed),@"nativeEnvironmentPrepared":@(_environmentPrepared),
        @"localFoundationTransportInstalled":@(_foundationInstalled),@"preparedEngineLoaded":@(_engineLoaded),
        @"nativeOriginArmed":@(_nativeOriginArmed),
        @"nativeImageAttachmentConfigured":@(_imageAttached),@"originalRendererObserved":@(_sceneObserved),
        @"boundCreatorAttached":@(_creatorAttached),@"registeredRouteCount":@(_routes.count),
        @"originalGameDataAdmitted":@(self.originalGameDataAdmitted),
        @"unsupportedRequestObserverInstalled":@(_requestObserverInstalled),
        @"unsupportedFoundationRequests":[_unsupportedRequests copy],
        @"creatorEntry":_creatorEntryReport?:@{@"outcome":@"not-configured"},
        @"creatorServicesPending":@(_servicesPending&&_services==nil),
        @"deferredCanonicalPlayerPrepared":@(_deferredPlayer.preparedAdmission!=nil&&_admittedScope!=nil),
        @"creatorServicesBound":@(_services!=nil),
        // Staging a file is not observation of the original engine opening it.
        @"derivedMasterStaged":@(_masterAttached),
        @"originalMasterColdStage":_originalMasterStage.stagingReport?:@{@"workingCopyStaged":@NO,@"originalMasterReady":@NO},
        @"originalEngineMasterAttached":@NO,
        @"originalEngineMasterRelativePath":_masterRelative?:@"",
        @"sourceKeyApplied":@NO,@"cachedHandleRedirected":@NO,@"engineKeyedOpenObserved":@NO,
        @"hostKeyedOpenAttempted":@NO,@"keyedOpenRefused":@YES,@"flags6Applied":@NO,@"readonlyMasterReady":@(_masterReadonlyReady),
        @"readonlyPlaintextIsOriginalMasterAdmission":@NO,
        @"engineAssetRootContainsPublishedMaster":@(_assetRootHasMaster),
        @"extensionLoadingEnabled":@NO,@"patcherContractUsed":@NO,
        @"nativeNetworkCoverage":@"Installed Foundation handling only; raw socket, SDK/system and WebKit activity require observation/configuration",
        @"kernelNetworkIsolationEstablished":@NO,@"routeContractsRuntimeVerified":@NO,
        @"offlineAuthReaderRelativeOnly":@YES,@"offlineAuthWireEnvelopeVerified":@YES,
        @"offlineAuthHandlersConfigured":@(_authConfigured),@"offlineAuthOwnerInvalidated":@(_authInvalidated),
        @"offlineAuthHttpRouteAdmitted":@(_authConfigured&&_foundationInstalled&&_nativeOriginArmed),
        @"offlineAuthOriginalClientRuntimeVerified":@NO,@"freshStateSentinelsAdopted":@NO,
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
    if(valid&&_originalMasterStage){
        valid=[_originalMasterStage confirmBeforeOriginalImageLoad:error]&&
            [_originalMasterStage.assetsRootURL.path isEqualToString:_resources];
        // The original engine owns flags6, opaque native key, validation and
        // cached handle. Byte staging must not manufacture acceptance of them.
    }else if(valid&&_masterAttached){
        int source=open(_masterSourcePath.fileSystemRepresentation,O_RDONLY|O_NOFOLLOW|O_CLOEXEC);
        int confirmed=source<0?-2:od_engine_master_confirm(source,_stateFD,_state.UTF8String,_masterLanguage.UTF8String,_masterSHA.UTF8String,_masterBytes);
        int readonly=-1;od_engine_master_receipt gate;memset(&gate,0,sizeof gate);
        int resolved=confirmed?confirmed:od_engine_master_resolve_readonly(source,_stateFD,_state.UTF8String,_masterLanguage.UTF8String,_masterSHA.UTF8String,_masterBytes,OD_ENGINE_MASTER_OPEN_READONLY,NULL,0,0,0,0,&readonly,&gate);
        if(readonly>=0)close(readonly);
        int resource=ODHostDirectory(_resources),matches=0;
        int compared=resolved?resolved:od_engine_master_asset_root_matches(source,_stateFD,_state.UTF8String,resource,_resources.UTF8String,_masterLanguage.UTF8String,&matches);
        if(resource>=0)close(resource);
        if(source>=0)close(source);
        valid=confirmed==0&&resolved==0&&gate.readonly_resolved&&gate.keyed_open_refused&&gate.flags6_refused&&!gate.engine_keyed_open_observed&&!gate.source_key_applied&&!gate.extension_loading_enabled&&compared==0;
        _masterReadonlyReady=valid;_assetRootHasMaster=valid&&matches;
    }
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
        }else host->_stage=host->_servicesPending?@"original-scene-observed-services-pending":@"original-scene-observed-diagnostic-only";
        if(host->_services||host->_servicesPending)ODDuoRefreshQueuedCreatorQuickAction();
        [host emit];
    },^(NSError *failure){
        (void)failure;ODUnifiedDuoHost *host=weakSelf;if(!host)return;
        host->_creatorAttached=NO;host->_stage=@"original-scene-admission-failed";[host emit];
    },error))return NO;
    if(_services){
        if(![_services.coordinator installOriginalSceneLifecycleWithError:error])return NO;
        _lifecycleInstalled=YES;
    }
    if((_services||_servicesPending)&&!ODDuoConfigureCreatorQuickAction(^BOOL{
        ODUnifiedDuoHost *host=weakSelf;return host&&host->_current();
    },^ODDuoCreatorQuickActionReadiness(UIWindow *window,UIViewController *controller,UIView *renderer){
        ODUnifiedDuoHost *host=weakSelf;
        if(host&&host->_current()&&!host.originalGameDataAdmitted)return ODDuoCreatorEntryWaiting;
        od_creator_menu_admission admission={0};
        if(host){
            admission.context_current=host->_current()?1:0;
            admission.creator_already_open=host->_services.coordinator.creatorIsOpen?1:0;
            admission.installed=host->_installed;admission.scene_observed=host->_sceneObserved;
            admission.creator_attached=host->_creatorAttached;admission.services_pending=host->_servicesPending;
            admission.services_bound=host->_services!=nil;
            admission.scene_identity_matches=controller==host->_originalController&&renderer==host->_renderer&&renderer.window==window;
        }
        switch(od_creator_menu_admit(&admission)){
            case OD_CREATOR_MENU_READY:return ODDuoCreatorEntryReady;
            case OD_CREATOR_MENU_ALREADY_OPEN:return ODDuoCreatorEntryAlreadyOpen;
            case OD_CREATOR_MENU_WAITING:return ODDuoCreatorEntryWaiting;
            default:return ODDuoCreatorEntryRejected;
        }
    },^(void (^completion)(NSError *)){
        ODUnifiedDuoHost *host=weakSelf;if(!host){completion(ODHostFailure(8));return;}
        [host presentCreatorFromUserActionWithCompletion:completion];
    },^(NSDictionary *state){
        ODUnifiedDuoHost *host=weakSelf;if(!host)return;host->_creatorEntryReport=[state copy];[host emit];
    },error))return NO;
    return YES;
}
- (BOOL)installBeforeApplicationMain:(NSError **)error {
    BOOL integrated=_purpose==ODUnifiedDuoIntegratedTarget;
    // Actual original initialization precedes native master acceptance. Data
    // providers keep their separate gate closed; no dummy attachment is needed.
    if(!NSThread.isMainThread||_attempted||ODInstalledUnifiedHost||!_current()||
       (integrated&&_services&&![_services creatorScopeIsCurrent])||
       (integrated&&!_services&&!_servicesPending)){
        if(error)*error=ODHostFailure(5);return NO;
    }
    if(integrated&&!_authConfigured){if(error)*error=ODHostFailure(11);return NO;}
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
    // Integrated loading begins with deny-all. The actual admitted native
    // configuration supplies its origin only AFTER ordinary engine loading.
    NSArray<NSURL *> *bootstrapOrigins=integrated?@[]:_origins;
    NSArray<ODLocalTransportRoute *> *bootstrapRoutes=integrated?@[]:_routes;
    BOOL ok=ODInstallPreparedDuoShellBootstrap(_baseline,bootstrapOrigins,bootstrapRoutes,^BOOL(NSError **failure){
        ODUnifiedDuoHost *host=weakSelf;if(!host){if(failure)*failure=ODHostFailure(6);return NO;}
        /* This callback is reached only after the bootstrap has successfully
           installed its actual local Foundation protocol. */
        host->_foundationInstalled=YES;
        ODPreparedEngineEnvironment prepare=^BOOL(NSError **preparationError){
            return [host prepareNativeEnvironment:preparationError];
        };
        ODOriginalNativeOrigin *origin=nil;
        BOOL loaded=integrated?ODLoadPreparedOriginalEngineWithNativeOrigin(host->_engine,prepare,&origin,failure):
            ODLoadPreparedOriginalEngine(host->_engine,prepare,failure);
        host->_engineLoaded=loaded;if(!loaded){host->_stage=@"prepared-image-load-failed";[host emit];return NO;}
        if(integrated){
            host->_nativeOriginArmed=ODRearmLocalTransportForLoadedOriginalOrigin(origin,host->_routes,failure);
            if(!host->_nativeOriginArmed){host->_stage=@"native-origin-route-binding-failed";[host emit];return NO;}
        }
        host->_stage=@"original-initializers-completed";
        if(host->_attach){host->_imageAttached=host->_attach(failure);if(!host->_imageAttached){host->_stage=@"native-image-attachment-failed";[host emit];return NO;}}
        [host emit];return host->_current();
    },^BOOL(NSError **failure){return [weakSelf registerOriginalScene:failure];},error);
    _installed=ok;_stage=ok?@"waiting-for-actual-appcontroller-scene":@"bootstrap-installation-failed";
    if(ok)ODInstalledUnifiedHost=self;[self emit];return ok;
}
- (BOOL)authContextIsCurrent {
    return NSThread.isMainThread&&_authConfigured&&!_authInvalidated&&_current()&&
        _services&&[_services originalClientCoreForContentID:_authContent saveScopeSHA256:_authScope]!=nil;
}
- (BOOL)authSnapshot:(id)result matchesCore:(ODNativeCore *)core issuer:(ODBoundOriginalCreatorServices *)services
        generation:(NSUInteger)generation {
    if(![self authContextIsCurrent]||generation!=_authGeneration||services!=_services||
       [_services originalClientCoreForContentID:_authContent saveScopeSHA256:_authScope]!=core||
       ![result isKindOfClass:NSDictionary.class])return NO;
    NSDictionary *admission=result[@"admission"],*snapshot=result[@"player_snapshot"];
    return [admission isKindOfClass:NSDictionary.class]&&[snapshot isKindOfClass:NSDictionary.class]&&
        [admission[@"profile_id"] isEqual:@"local-player"]&&[admission[@"content_id"] isEqual:_authContent]&&
        [admission[@"save_scope_sha256"] isEqual:_authScope]&&
        [snapshot[@"profile_id"] isEqual:@"local-player"]&&[snapshot[@"content_id"] isEqual:_authContent];
}
- (void)invalidateOfflineAuthForRequest:(ODLocalTransportRequest *)request {
    if(!NSThread.isMainThread)return;
    _authInvalidated=YES;++_authGeneration;
    // The issuer's current predicate is now false. Its ordinary guard clears
    // the private in-memory issue without inspecting a request or writing it.
    [_authIssuerRoutes.firstObject handleRequest:request
        completion:^(ODLocalTransportResponse *response,NSError *failure){(void)response;(void)failure;}];
    NSArray<dispatch_block_t> *pending=[_pendingAuthRequests copy];[_pendingAuthRequests removeAllObjects];
    for(dispatch_block_t request in pending)request();
}
- (void)runOfflineAuthRoute:(ODLocalTransportRoute *)route request:(ODLocalTransportRequest *)request
        completion:(ODLocalTransportCompletion)complete {
    if(!NSThread.isMainThread){
        dispatch_async(dispatch_get_main_queue(),^{[self runOfflineAuthRoute:route request:request completion:complete];});return;
    }
    if(_authInvalidated||!_current()){
        [self invalidateOfflineAuthForRequest:request];complete(nil,ODHostFailure(11));return;
    }
    if(![request isActive]){complete(nil,ODHostFailure(11));return;}
    if(!_services&&_servicesPending){
        // The original request's own transport deadline/cancellation remains
        // authoritative; pending native work is bounded and never blocks main.
        if(_pendingAuthRequests.count>=8){complete(nil,ODHostFailure(11));return;}
        __weak ODUnifiedDuoHost *weakSelf=self;
        [_pendingAuthRequests addObject:^{
            ODUnifiedDuoHost *host=weakSelf;
            if(host)[host runOfflineAuthRoute:route request:request completion:complete];
            else complete(nil,ODHostFailure(11));
        }];return;
    }
    ODBoundOriginalCreatorServices *services=_services;
    ODNativeCore *core=[services originalClientCoreForContentID:_authContent saveScopeSHA256:_authScope];
    if(!core||![self authContextIsCurrent]){[self invalidateOfflineAuthForRequest:request];complete(nil,ODHostFailure(11));return;}
    NSUInteger generation=_authGeneration;
    __weak ODUnifiedDuoHost *weakSelf=self;
    [core originalClientPlayerSnapshotForProfile:@"local-player" expectedSaveScopeSHA256:_authScope
        reply:^(id result,NSError *failure){
            ODUnifiedDuoHost *host=weakSelf;
            if(!host){complete(nil,ODHostFailure(11));return;}
            if(ODHostAuthScopeChanged(failure)){
                [host invalidateOfflineAuthForRequest:request];complete(nil,ODHostFailure(11));return;
            }
            if(failure||![request isActive]){complete(nil,ODHostFailure(11));return;}
            if(![host authSnapshot:result matchesCore:core issuer:services generation:generation]){
                [host invalidateOfflineAuthForRequest:request];complete(nil,ODHostFailure(11));return;
            }
            // Every issuer handler runs on main. No main-only scope predicate
            // is called by the Foundation transport's serial queue.
            [route handleRequest:request completion:^(ODLocalTransportResponse *response,NSError *issuerFailure){
                if(![host authContextIsCurrent]){
                    [host invalidateOfflineAuthForRequest:request];complete(nil,ODHostFailure(11));return;
                }
                if(issuerFailure||!response||![request isActive]){complete(nil,ODHostFailure(11));return;}
                [core originalClientPlayerSnapshotForProfile:@"local-player" expectedSaveScopeSHA256:host->_authScope
                    reply:^(id finalResult,NSError *finalFailure){
                        ODUnifiedDuoHost *owner=weakSelf;
                        if(!owner){complete(nil,ODHostFailure(11));return;}
                        if(ODHostAuthScopeChanged(finalFailure)){
                            [owner invalidateOfflineAuthForRequest:request];complete(nil,ODHostFailure(11));return;
                        }
                        if(finalFailure||![request isActive]){complete(nil,ODHostFailure(11));return;}
                        if(![owner authSnapshot:finalResult matchesCore:core issuer:services generation:generation]){
                            [owner invalidateOfflineAuthForRequest:request];complete(nil,ODHostFailure(11));return;
                        }
                        complete(response,nil);
                    }];
            }];
        }];
}
- (BOOL)configureOfflineAuthForContentID:(NSString *)contentID saveScopeSHA256:(NSString *)scope
        expiresIn:(int32_t)expiresIn error:(NSError **)error {
    return [self configureOfflineAuthForContentID:contentID saveScopeSHA256:scope deferredPlayer:nil expiresIn:expiresIn error:error];
}
- (BOOL)configureOfflineAuthForDeferredPlayerWithExpiresIn:(int32_t)expiresIn error:(NSError **)error {
    if(!NSThread.isMainThread||!_deferredPlayer){if(error)*error=ODHostFailure(11);return NO;}
    return [self configureOfflineAuthForContentID:_admittedContent saveScopeSHA256:_admittedScope
        deferredPlayer:_deferredPlayer expiresIn:expiresIn error:error];
}
- (BOOL)configureOfflineAuthForContentID:(NSString *)contentID saveScopeSHA256:(NSString *)scope
        deferredPlayer:(ODDeferredOriginalPlayerAdmission *)player expiresIn:(int32_t)expiresIn error:(NSError **)error {
    if(!NSThread.isMainThread){if(error)*error=ODHostFailure(11);return NO;}
    BOOL awaitingScope=player&&player==_deferredPlayer&&!scope&&!player.preparedAdmission&&_servicesPending&&!_services&&
        [player.contentID isEqual:contentID]&&[_admittedContent isEqual:contentID];
    BOOL admitted=(_services&&[_services matchesAdmittedContentID:contentID saveScopeSHA256:scope])||
        (!_services&&_servicesPending&&[_admittedContent isEqual:contentID]&&[_admittedScope isEqual:scope])||awaitingScope;
    if(!NSThread.isMainThread||_purpose!=ODUnifiedDuoIntegratedTarget||_attempted||_authConfigured||
       !ODHostContentID(contentID)||(!awaitingScope&&!ODHostHex(scope))||expiresIn<=0||!_current()||!admitted||
       (_services&&![_services originalClientCoreForContentID:contentID saveScopeSHA256:scope])){
        if(error)*error=ODHostFailure(11);return NO;
    }
    for(ODLocalTransportRoute *route in _routes)
        if(ODHostClosedAuthPath(route.path)){if(error)*error=ODHostFailure(11);return NO;}
    _authContent=[contentID copy];_authScope=[scope copy];_authGeneration=1;
    _pendingAuthRequests=[NSMutableArray array];
    __weak ODUnifiedDuoHost *weakSelf=self;
    NSArray<ODLocalTransportRoute *> *issuer=[ODOfflineBootstrapAuth candidateRoutesWithExpiresIn:expiresIn
        contextIsCurrent:^BOOL{return [weakSelf authContextIsCurrent];} error:error];
    if(issuer.count!=3)return NO;
    NSMutableArray<ODLocalTransportRoute *> *routes=[_routes mutableCopy];
    for(ODLocalTransportRoute *route in issuer){
        ODLocalTransportRoute *wrapped=[[ODLocalTransportRoute alloc] initWithMethod:route.method path:route.path
            handler:^(ODLocalTransportRequest *request,ODLocalTransportCompletion complete){
                dispatch_async(dispatch_get_main_queue(),^{
                    ODUnifiedDuoHost *host=weakSelf;
                    if(host)[host runOfflineAuthRoute:route request:request completion:complete];
                    else complete(nil,ODHostFailure(11));
                });
            }];
        if(!wrapped){if(error)*error=ODHostFailure(11);return NO;}[routes addObject:wrapped];
    }
    _authIssuerRoutes=issuer;_routes=[routes copy];_authConfigured=YES;
    _stage=@"offline-auth-handlers-configured";[self emit];return YES;
}
- (NSDictionary *)issueOfflineAuthEnvelopeWithNativeTime:(int32_t)nativeTime expiresIn:(int32_t)expiresIn error:(NSError **)error {
    if (!NSThread.isMainThread || !_current()) { if (error) *error = ODHostFailure(2); return nil; }
    return [ODOfflineBootstrapAuth issueWithNativeTime:nativeTime expiresIn:expiresIn error:error];
}
- (NSDictionary *)freshStatePolicyForSnapshot:(NSDictionary *)snapshot proposedSections:(NSDictionary *)proposed error:(NSError **)error {
    if (!NSThread.isMainThread || !_current()) { if (error) *error = ODHostFailure(2); return nil; }
    return [ODFreshStatePolicy evaluateSnapshot:snapshot proposedSections:proposed error:error];
}
- (BOOL)stagePlaintextDerivedMasterAtURL:(NSURL *)derived byteCount:(uint64_t)bytes contentSHA256:(NSString *)sha256 language:(NSString *)language error:(NSError **)error {
    unichar first=language.length? [language characterAtIndex:0]:0, second=language.length>1?[language characterAtIndex:1]:0;
    if(!NSThread.isMainThread||_attempted||_masterAttached||_originalMasterStage||!derived.isFileURL||!derived.path.isAbsolutePath||
       bytes<100||bytes>256ull*1024ull*1024||![sha256 isKindOfClass:NSString.class]||!ODHostHex(sha256)||
       language.length!=2||first<'a'||first>'z'||second<'a'||second>'z'||[_state containsString:@"/Documents/assets"]){
        if(error)*error=ODHostFailure(9);return NO;
    }
    int source=open(derived.fileSystemRepresentation,O_RDONLY|O_NOFOLLOW|O_CLOEXEC);
    int state=ODHostDirectory(_state);
    struct stat info;
    if(source<0||state<0||fstat(source,&info)||!S_ISREG(info.st_mode)||(uint64_t)info.st_size!=bytes){
        if(source>=0)close(source);if(state>=0)close(state);if(error)*error=ODHostFailure(9);return NO;
    }
    od_engine_master_receipt receipt;
    int result=od_engine_master_attach(source,state,_state.UTF8String,language.UTF8String,sha256.UTF8String,bytes,&receipt);
    int readonly=-1;od_engine_master_receipt gate;memset(&gate,0,sizeof gate);
    int resolved=result?result:od_engine_master_resolve_readonly(source,state,_state.UTF8String,language.UTF8String,sha256.UTF8String,bytes,OD_ENGINE_MASTER_OPEN_READONLY,NULL,0,0,0,0,&readonly,&gate);
    if(readonly>=0)close(readonly);
    close(source);close(state);
    if(result||resolved||!receipt.attached||!receipt.plaintext||!receipt.source_preserved||receipt.source_key_applied||
       receipt.extension_loading_enabled||receipt.patcher_path_used||receipt.cached_handle_redirected||receipt.engine_keyed_open_observed||
       !gate.readonly_resolved||!gate.keyed_open_refused||!gate.flags6_refused||gate.engine_keyed_open_observed||gate.source_key_applied||gate.extension_loading_enabled){
        if(error)*error=ODHostFailure(9);return NO;
    }
    _masterAttached=YES;_masterReadonlyReady=YES;_masterSourcePath=[derived.path copy];_masterLanguage=[language copy];_masterSHA=[sha256 copy];
    _masterBytes=bytes;_masterRelative=[NSString stringWithUTF8String:receipt.relative_path];
    _stage=@"plaintext-master-staged";[self emit];return YES;
}
- (BOOL)adoptColdStagedOriginalMaster:(ODNativeMasterColdStage *)stage error:(NSError **)error {
    if(!NSThread.isMainThread||_attempted||_masterAttached||_originalMasterStage||
       ![stage isKindOfClass:ODNativeMasterColdStage.class]||!_current()||
       ![stage.assetsRootURL.path isEqualToString:_resources]||
       ![stage confirmBeforeOriginalImageLoad:error]){
        if(error)*error=ODHostFailure(9);return NO;
    }
    _originalMasterStage=stage;
    _stage=@"original-master-cold-copy-staged-native-acceptance-pending";[self emit];return YES;
}
- (BOOL)expectDeferredCreatorServicesForContentID:(NSString *)contentID saveScopeSHA256:(NSString *)scope error:(NSError **)error {
    if(!NSThread.isMainThread||_attempted||_services||_servicesPending||_purpose!=ODUnifiedDuoIntegratedTarget||
       !ODHostContentID(contentID)||!ODHostHex(scope)){if(error)*error=ODHostFailure(10);return NO;}
    _admittedContent=[contentID copy];_admittedScope=[scope copy];_servicesPending=YES;_stage=@"creator-services-pending";[self emit];return YES;
}
- (BOOL)expectDeferredCreatorServicesForPlayerAdmission:(ODDeferredOriginalPlayerAdmission *)player error:(NSError **)error {
    if(!NSThread.isMainThread||_purpose!=ODUnifiedDuoIntegratedTarget||_attempted||_services||_servicesPending||
       ![player isMemberOfClass:ODDeferredOriginalPlayerAdmission.class]||!ODHostContentID(player.contentID)||!_current()){
        if(error)*error=ODHostFailure(10);return NO;
    }
    NSDictionary *prepared=player.preparedAdmission;
    if(prepared&&(!ODHostHex(prepared[@"save_scope_sha256"])||![prepared[@"content_id"] isEqual:player.contentID])){
        if(error)*error=ODHostFailure(10);return NO;
    }
    _deferredPlayer=player;_admittedContent=[player.contentID copy];
    _admittedScope=[prepared[@"save_scope_sha256"] copy];_servicesPending=YES;
    _stage=prepared?@"canonical-player-admission-prepared":@"canonical-player-admission-pending";[self emit];return YES;
}
- (void)prepareDeferredPlayerAdmissionOnQueue:(dispatch_queue_t)queue completion:(void (^)(NSError *))completion {
    if(!completion)return;
    if(!NSThread.isMainThread){dispatch_async(dispatch_get_main_queue(),^{completion(ODHostFailure(10));});return;}
    if(!queue||queue==dispatch_get_main_queue()||!_deferredPlayer||_deferredPlayerPreparationRequested||_deferredPlayer.preparedAdmission||!_servicesPending||
       _services||_purpose!=ODUnifiedDuoIntegratedTarget||!_current()){
        completion(ODHostFailure(10));return;
    }
    _deferredPlayerPreparationRequested=YES;ODDeferredOriginalPlayerAdmission *player=_deferredPlayer;
    __weak ODUnifiedDuoHost *weakSelf=self;
    [player prepareOnQueue:queue completion:^(NSError *failure){
        ODUnifiedDuoHost *host=weakSelf;
        if(!host){completion(ODHostFailure(10));return;}
        NSDictionary *prepared=player.preparedAdmission;NSString *scope=prepared[@"save_scope_sha256"];
        BOOL valid=!failure&&host->_current()&&host->_deferredPlayer==player&&host->_servicesPending&&!host->_services&&
            [prepared[@"profile_id"] isEqual:@"local-player"]&&[prepared[@"content_id"] isEqual:host->_admittedContent]&&
            ODHostHex(scope)&&(!host->_admittedScope||[host->_admittedScope isEqual:scope])&&
            (!host->_authScope||[host->_authScope isEqual:scope]);
        if(!valid){
            host->_authInvalidated=YES;++host->_authGeneration;host->_stage=@"canonical-player-admission-failed";
            NSArray<dispatch_block_t> *pending=[host->_pendingAuthRequests copy];[host->_pendingAuthRequests removeAllObjects];
            for(dispatch_block_t request in pending)request();[host emit];completion(ODHostFailure(10));return;
        }
        host->_admittedScope=[scope copy];if(host->_authConfigured)host->_authScope=[scope copy];
        host->_stage=@"canonical-player-admission-prepared";[host emit];completion(nil);
    }];
}
- (void)bindCreatorServicesWhenReady:(ODBoundOriginalCreatorServices *)services completion:(void (^)(NSError *))completion {
    if(!completion)return;
    od_creator_late_bind_input input={0};input.on_main=NSThread.isMainThread;
    od_creator_late_bind_result decision;
    if(!input.on_main){
        if(od_creator_late_bind_decide(&input,&decision)!=OD_LATE_BIND_QUEUE){completion(ODHostFailure(10));return;}
        dispatch_async(dispatch_get_main_queue(),^{[self bindCreatorServicesWhenReady:services completion:completion];});
        return;
    }
    input.installed=_installed;input.services_pending=_servicesPending;input.services_already_bound=_services!=nil;
    input.services_supplied=services!=nil;input.context_current=_current();
    ODNativeCore *serviceCore=services&&_admittedScope?[services originalClientCoreForContentID:_admittedContent saveScopeSHA256:_admittedScope]:nil;
    BOOL sameDeferredCore=!_deferredPlayer||[_deferredPlayer matchesCore:serviceCore contentID:_admittedContent];
    input.content_matches=services&&[services matchesAdmittedContentID:_admittedContent saveScopeSHA256:_admittedScope]&&sameDeferredCore;
    input.scope_current=services&&[services creatorScopeIsCurrent];
    input.scene_observed=_sceneObserved;input.controller_present=_originalController!=nil;input.renderer_present=_renderer!=nil;
    if(od_creator_late_bind_decide(&input,&decision)!=OD_LATE_BIND_ACCEPT_WAITING&&decision.action!=OD_LATE_BIND_ACCEPT_ATTACH){
        completion(ODHostFailure(10));return;
    }
    NSError *failure=nil;
    // Do not consume the pending admission until the observed scene accepts
    // these services. A failed attachment must remain retryable and observable.
    BOOL attached=NO;
    if(decision.try_attach){
        attached=[services attachToOriginalWindow:_renderer.window controller:_originalController renderer:_renderer error:&failure];
        if(!attached){
            _stage=@"creator-service-attachment-failed";[self emit];
            completion(failure?:ODHostFailure(10));return;
        }
    }
    if(decision.install_lifecycle&&!_lifecycleInstalled){
        if(![services.coordinator installOriginalSceneLifecycleWithError:&failure]){
            _stage=@"creator-service-lifecycle-failed";[self emit];
            completion(failure?:ODHostFailure(10));return;
        }
        _lifecycleInstalled=YES;
    }
    _services=services;if(decision.clear_pending)_servicesPending=NO;
    NSArray<dispatch_block_t> *pending=[_pendingAuthRequests copy];[_pendingAuthRequests removeAllObjects];
    for(dispatch_block_t request in pending)request();
    _creatorAttached=attached;
    _stage=attached?@"original-scene-and-creator-bound":@"creator-services-bound-waiting-for-renderer";
    if(decision.refresh_shortcut)ODDuoRefreshQueuedCreatorQuickAction();
    [self emit];completion(nil);
}
- (void)presentCreatorFromUserActionWithCompletion:(void (^)(NSError *))completion {
    if(!completion)return;
    if(!NSThread.isMainThread){dispatch_async(dispatch_get_main_queue(),^{[self presentCreatorFromUserActionWithCompletion:completion];});return;}
    if(!_installed||!self.originalGameDataAdmitted||!_services||!_creatorAttached||!_current()||!_originalController||!_renderer||![_services creatorScopeIsCurrent]){
        completion(ODHostFailure(7));return;
    }
    [_services presentCreatorFromUserActionWithCompletion:completion];
}
@end
