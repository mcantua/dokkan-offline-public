#import "ODUnifiedDuoHost.h"
#import "ODDuoCreatorQuickAction.h"
#import "creator_late_bind.h"
#import "creator_menu_policy.h"
#import "../content/engine_master_attach.h"
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
    return [NSError errorWithDomain:@"OfflineDokkan.UnifiedDuoHost" code:code
        userInfo:@{NSLocalizedDescriptionKey:@"The native original-game startup or same-save binding is unavailable. Existing files were preserved."}];
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
    BOOL _requestObserverInstalled,_servicesPending,_lifecycleInstalled,_masterAttached,_masterReadonlyReady,_assetRootHasMaster;
    NSString *_admittedContent,*_admittedScope,*_masterSourcePath,*_masterLanguage,*_masterSHA,*_masterRelative;
    uint64_t _masterBytes;
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
       (purpose==ODUnifiedDuoIntegratedTarget&&(!attach||!origins.count||!routes.count))){
        if(error)*error=ODHostFailure(1);return nil;
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
        @"creatorServicesPending":@(_servicesPending&&_services==nil),
        @"creatorServicesBound":@(_services!=nil),
        @"originalEngineMasterAttached":@(_masterAttached),
        @"originalEngineMasterRelativePath":_masterRelative?:@"",
        @"sourceKeyApplied":@NO,@"cachedHandleRedirected":@NO,@"engineKeyedOpenObserved":@NO,
        @"keyedOpenRefused":@YES,@"flags6Applied":@NO,@"readonlyMasterReady":@(_masterReadonlyReady),
        @"engineAssetRootContainsPublishedMaster":@(_assetRootHasMaster),
        @"extensionLoadingEnabled":@NO,@"patcherContractUsed":@NO,
        @"nativeNetworkCoverage":@"Installed Foundation handling only; raw socket, SDK/system and WebKit activity require observation/configuration",
        @"kernelNetworkIsolationEstablished":@NO,@"routeContractsRuntimeVerified":@NO,
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
    if(valid&&_masterAttached){
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
    if(!NSThread.isMainThread||_attempted||ODInstalledUnifiedHost||!_current()||
       (integrated&&_services&&![_services creatorScopeIsCurrent])||
       (integrated&&!_services&&!_servicesPending)||
       (integrated&&!_masterAttached)){
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
- (BOOL)stagePlaintextDerivedMasterAtURL:(NSURL *)derived byteCount:(uint64_t)bytes contentSHA256:(NSString *)sha256 language:(NSString *)language error:(NSError **)error {
    unichar first=language.length? [language characterAtIndex:0]:0, second=language.length>1?[language characterAtIndex:1]:0;
    if(!NSThread.isMainThread||_attempted||_masterAttached||!derived.isFileURL||!derived.path.isAbsolutePath||
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
- (BOOL)expectDeferredCreatorServicesForContentID:(NSString *)contentID saveScopeSHA256:(NSString *)scope error:(NSError **)error {
    if(!NSThread.isMainThread||_attempted||_services||_servicesPending||_purpose!=ODUnifiedDuoIntegratedTarget||
       !ODHostContentID(contentID)||!ODHostHex(scope)){if(error)*error=ODHostFailure(10);return NO;}
    _admittedContent=[contentID copy];_admittedScope=[scope copy];_servicesPending=YES;_stage=@"creator-services-pending";[self emit];return YES;
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
    input.content_matches=services&&[services matchesAdmittedContentID:_admittedContent saveScopeSHA256:_admittedScope];
    input.scope_current=services&&[services creatorScopeIsCurrent];
    input.scene_observed=_sceneObserved;input.controller_present=_originalController!=nil;input.renderer_present=_renderer!=nil;
    if(od_creator_late_bind_decide(&input,&decision)!=OD_LATE_BIND_ACCEPT_WAITING&&decision.action!=OD_LATE_BIND_ACCEPT_ATTACH){
        completion(ODHostFailure(10));return;
    }
    NSError *failure=nil;
    if(decision.install_lifecycle&&!_lifecycleInstalled){
        if(![services.coordinator installOriginalSceneLifecycleWithError:&failure]){completion(failure?:ODHostFailure(10));return;}
        _lifecycleInstalled=YES;
    }
    _services=services;if(decision.clear_pending)_servicesPending=NO;
    if(decision.try_attach&&[services attachToOriginalWindow:_renderer.window controller:_originalController renderer:_renderer error:&failure]){
        _creatorAttached=YES;_stage=@"original-scene-and-creator-bound";
    }else _stage=@"creator-services-bound-waiting-for-renderer";
    if(decision.refresh_shortcut)ODDuoRefreshQueuedCreatorQuickAction();
    [self emit];completion(nil);
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
