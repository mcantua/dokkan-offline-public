#import "ODOriginalDuoStartupDiagnostic.h"
#import "../duo/ODUnifiedDuoHost.h"
#import "../ios/ODOriginalClientBootstrap.h"
#import "../content/resource_preload.h"
#import "../content/startup_provenance.h"
#import "../content/ODNativeMasterObservation.h"
#import <CommonCrypto/CommonDigest.h>
#include <fcntl.h>
#include <dirent.h>
#include <errno.h>
#include <sys/stat.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if defined(OD_ORIGINAL_DUO_DIAGNOSTIC_ENTRY) && OD_ORIGINAL_DUO_DIAGNOSTIC_ENTRY && \
    defined(OD_UNIFIED_DUO_STARTUP_ENTRY) && OD_UNIFIED_DUO_STARTUP_ENTRY
#error Original startup diagnostic and integrated production entries are mutually exclusive.
#endif

static NSDictionary *ODDiagnosticReport;
static NSDictionary *ODDiagnosticResourceReport;
static NSString *ODDiagnosticFactoryStage;

@interface ODOriginalDuoStartupInputs ()
- (instancetype)initWithBundle:(NSURL *)bundle baseline:(NSURL *)baseline engine:(NSURL *)engine
    resources:(NSURL *)resources state:(NSURL *)state compatible:(NSDictionary *)report
    knownIntegratedRelaunch:(BOOL)resumed;
@end
@implementation ODOriginalDuoStartupInputs
- (instancetype)initWithBundle:(NSURL *)bundle baseline:(NSURL *)baseline engine:(NSURL *)engine
        resources:(NSURL *)resources state:(NSURL *)state compatible:(NSDictionary *)report
        knownIntegratedRelaunch:(BOOL)resumed {
    if((self=[super init])){_bundleRootURL=[bundle copy];_genuineShellBaselineURL=[baseline copy];
        _preparedEngineURL=[engine copy];_resourcesRootURL=[resources copy];
        _writableStateRootURL=[state copy];_compatibleResourceReport=[report copy];_knownIntegratedRelaunch=resumed;}
    return self;
}
@end

static void ODInputStage(ODOriginalDuoInputPurpose purpose,NSString *stage) {
    if(purpose==ODOriginalDuoInputsDiagnostic)ODDiagnosticFactoryStage=stage;
}

static NSError *ODDiagnosticFailure(void) {
    return [NSError errorWithDomain:@"OfflineDokkan.OriginalStartupDiagnostic" code:1
        userInfo:@{NSLocalizedDescriptionKey:@"The original-client startup inputs are unavailable. No replacement game was opened."}];
}

/* Walk the actual native path. NSURL's normalized spelling alone must not admit
 * a symlink into another directory. This never opens a save or a key file. */
static int ODDiagnosticDirectory(NSURL *url) {
    if (!url.isFileURL || !url.path.isAbsolutePath) return -1;
    int fd = open("/",O_RDONLY|O_DIRECTORY|O_CLOEXEC);
    if (fd < 0) return -1;
    for (NSString *part in url.path.pathComponents) {
        if ([part isEqualToString:@"/"]) continue;
        if ([part isEqualToString:@"."] || [part isEqualToString:@".."]) { close(fd); return -1; }
        int next = openat(fd,part.fileSystemRepresentation,O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);
        close(fd); if (next < 0) return -1; fd = next;
    }
    return fd;
}

/* Foundation selects these app-owned roots, including iOS's /var alias.
 * Resolve only the trusted root prefix, after refusing a symlink at the root
 * itself. Resource/framework descendants still use the NOFOLLOW FD walk.
 * Reopening the resolved spelling must name that same native directory. */
static NSURL *ODDiagnosticNativeRoot(NSURL *url) {
    if (!url.isFileURL || !url.path.isAbsolutePath) return nil;
    struct stat original,confirmed;
    if (lstat(url.fileSystemRepresentation,&original) || !S_ISDIR(original.st_mode) || S_ISLNK(original.st_mode)) return nil;
    NSURL *canonical = url.URLByResolvingSymlinksInPath;
    int fd = ODDiagnosticDirectory(canonical);
    BOOL valid = fd >= 0 && !fstat(fd,&confirmed) && original.st_dev == confirmed.st_dev && original.st_ino == confirmed.st_ino;
    if (fd >= 0) close(fd);
    return valid ? canonical : nil;
}

static BOOL ODDiagnosticRegularFile(NSURL *url) {
    int parent = ODDiagnosticDirectory(url.URLByDeletingLastPathComponent);
    if (parent < 0) return NO;
    int fd = openat(parent,url.lastPathComponent.fileSystemRepresentation,O_RDONLY|O_NOFOLLOW|O_CLOEXEC);
    struct stat info;
    BOOL valid = fd >= 0 && !fstat(fd,&info) && S_ISREG(info.st_mode) && info.st_size > 0;
    if (fd >= 0) close(fd); close(parent); return valid;
}

static BOOL ODDiagnosticOriginalSeed(NSURL *url) {
    int parent = ODDiagnosticDirectory(url.URLByDeletingLastPathComponent);
    if (parent < 0) return NO;
    int fd = openat(parent,url.lastPathComponent.fileSystemRepresentation,O_RDONLY|O_NOFOLLOW|O_CLOEXEC);
    close(parent); if (fd < 0) return NO;
    struct stat before,after;
    BOOL valid = !fstat(fd,&before) && S_ISREG(before.st_mode) && before.st_size == 535552;
    CC_SHA256_CTX hash; CC_SHA256_Init(&hash);
    unsigned char buffer[65536],digest[CC_SHA256_DIGEST_LENGTH]; off_t done = 0;
    while (valid && done < before.st_size) {
        ssize_t count = pread(fd,buffer,sizeof(buffer),(off_t)done);
        if (count < 0 && errno == EINTR) continue;
        if (count <= 0 || count > before.st_size-done) { valid = NO; break; }
        CC_SHA256_Update(&hash,buffer,(CC_LONG)count); done += count;
    }
    CC_SHA256_Final(digest,&hash);
    valid = valid && done == 535552 && !fstat(fd,&after) && before.st_dev == after.st_dev &&
        before.st_ino == after.st_ino && before.st_size == after.st_size &&
        before.st_mtimespec.tv_sec == after.st_mtimespec.tv_sec && before.st_mtimespec.tv_nsec == after.st_mtimespec.tv_nsec &&
        before.st_ctimespec.tv_sec == after.st_ctimespec.tv_sec && before.st_ctimespec.tv_nsec == after.st_ctimespec.tv_nsec;
    close(fd);
    static const unsigned char expected[CC_SHA256_DIGEST_LENGTH] = {
        0x66,0x7e,0x55,0x4a,0x9c,0xfb,0x8c,0x47,0x65,0xf0,0x5a,0x1d,0x85,0xf0,0xfd,0xf7,
        0x07,0xad,0xe6,0x15,0x62,0xb5,0x0e,0x3e,0x5c,0xd9,0x8a,0xc5,0x2f,0x99,0x7b,0xa3};
    return valid && !memcmp(digest,expected,sizeof(expected));
}

static BOOL ODDiagnosticHasAssets(int fd) {
    if (fd < 0) return NO;
    int copy = dup(fd); if (copy < 0) return NO;
    DIR *directory = fdopendir(copy); if (!directory) { close(copy); return NO; }
    BOOL found = NO; struct dirent *entry;
    while ((entry = readdir(directory))) {
        if (strcmp(entry->d_name,".") && strcmp(entry->d_name,"..")) { found = YES; break; }
    }
    closedir(directory); return found;
}

static BOOL ODDiagnosticNoExistingEngineWorkingTree(int assets) {
    if (assets < 0) return NO;
    /* Unknown/existing native working trees cannot be admitted as a fresh
     * diagnostic staging set. Do not remove, inspect or rewrite their data. */
    struct stat info;
    if (!fstatat(assets,"User",&info,AT_SYMLINK_NOFOLLOW) || errno != ENOENT) return NO;
    int sqlite = openat(assets,"sqlite",O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);
    if (sqlite < 0) return errno == ENOENT;
    int found = fstatat(sqlite,"current",&info,AT_SYMLINK_NOFOLLOW);
    int result = errno; close(sqlite);
    return found < 0 && result == ENOENT;
}

/* Only a previously admitted OWN integrated tree may use this check. Inspect
 * boundary types, never User/current contents, and never follow their links. */
static BOOL ODIntegratedExistingWorkingTreeSafe(int assets) {
    struct stat info;
    if(!fstatat(assets,"User",&info,AT_SYMLINK_NOFOLLOW)){
        if(!S_ISREG(info.st_mode)&&!S_ISDIR(info.st_mode))return NO;
    }else if(errno!=ENOENT)return NO;
    int sqlite=openat(assets,"sqlite",O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);
    if(sqlite<0)return errno==ENOENT;
    int found=fstatat(sqlite,"current",&info,AT_SYMLINK_NOFOLLOW),result=errno;
    close(sqlite);return found==0?S_ISDIR(info.st_mode):(result==ENOENT);
}

static NSURL *ODStartupStateRoot(ODOriginalDuoInputPurpose purpose) {
    NSURL *support=ODDiagnosticNativeRoot([NSFileManager.defaultManager URLForDirectory:NSApplicationSupportDirectory
        inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:NULL]);
    int supportFD=ODDiagnosticDirectory(support);if(supportFD<0)return nil;
    NSString *name=purpose==ODOriginalDuoInputsDiagnostic?@"OriginalClientStartupDiagnostic":@"OriginalClientStartup";
    (void)mkdirat(supportFD,name.UTF8String,0700);
    int stateFD=openat(supportFD,name.UTF8String,O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);
    close(supportFD);if(stateFD<0)return nil;close(stateFD);
    return [support URLByAppendingPathComponent:name isDirectory:YES];
}

enum { ODDiagnosticCompatibleCount = 27 };
typedef struct {
    char *paths[ODDiagnosticCompatibleCount];
    size_t count;
} ODDiagnosticRequiredAliases;

static int ODDiagnosticCollectAlias(const char *original,const od_asset_reference *reference,void *opaque) {
    (void)original;
    ODDiagnosticRequiredAliases *required = opaque;
    if (!reference || strncmp(reference->path,"assets/",7) || !reference->path[7]) return -1;
    const char *relative = reference->path+7;
    for (size_t i=0;i<required->count;++i) if (!strcmp(required->paths[i],relative)) return 0;
    if (required->count >= ODDiagnosticCompatibleCount) return -1;
    char *copy = strdup(relative);
    if (!copy) return -1;
    required->paths[required->count++] = copy;
    return 0;
}

typedef struct {
    int assets,documents,state;
    struct stat assetsIdentity,documentsIdentity,stateIdentity;
    const char *assetsPath,*documentsPath,*statePath;
    int active,resuming;
} ODDiagnosticPreparationContext;

static int ODDiagnosticPreparationCurrent(void *opaque) {
    ODDiagnosticPreparationContext *context = opaque;
    struct stat assets,documents,assetsPath,documentsPath;
    return context && context->active && !fstat(context->assets,&assets) && !fstat(context->documents,&documents) &&
        assets.st_dev == context->assetsIdentity.st_dev && assets.st_ino == context->assetsIdentity.st_ino &&
        documents.st_dev == context->documentsIdentity.st_dev && documents.st_ino == context->documentsIdentity.st_ino &&
        !lstat(context->assetsPath,&assetsPath) && S_ISDIR(assetsPath.st_mode) && !S_ISLNK(assetsPath.st_mode) &&
        assetsPath.st_dev == assets.st_dev && assetsPath.st_ino == assets.st_ino &&
        !lstat(context->documentsPath,&documentsPath) && S_ISDIR(documentsPath.st_mode) && !S_ISLNK(documentsPath.st_mode) &&
        documentsPath.st_dev == documents.st_dev && documentsPath.st_ino == documents.st_ino &&
        (context->state<0||(!lstat(context->statePath,&assetsPath)&&S_ISDIR(assetsPath.st_mode)&&
            !S_ISLNK(assetsPath.st_mode)&&assetsPath.st_dev==context->stateIdentity.st_dev&&
            assetsPath.st_ino==context->stateIdentity.st_ino))&&
        (context->resuming?(od_startup_provenance_read(context->state,context->documents,context->assets)==1&&
            ODIntegratedExistingWorkingTreeSafe(context->assets)):ODDiagnosticNoExistingEngineWorkingTree(context->assets));
}

static BOOL ODDiagnosticPrepareWorkingResources(NSURL *bundle,NSURL *documents,NSURL *integratedState,BOOL *resumed) {
    /* Only the trusted native bundle and actual own Documents root enter here.
     * The existing catalog selects exact admitted aliases; a page or generic
     * "ready" JSON flag cannot supply this list or grant publication. */
    NSURL *originalClient = [bundle URLByAppendingPathComponent:@"OriginalClient" isDirectory:YES];
    NSURL *cache = [originalClient URLByAppendingPathComponent:@"CompatibleResourceCache" isDirectory:YES];
    int source = ODDiagnosticDirectory(originalClient),cacheFD = ODDiagnosticDirectory(cache);
    int boundary = ODDiagnosticDirectory(documents),assets = -1,catalog = -1;
    int state=integratedState?ODDiagnosticDirectory(integratedState):-1;
    if (source >= 0) catalog = openat(source,"byte-identical-assets.sqlite3",O_RDONLY|O_NOFOLLOW|O_CLOEXEC|O_NONBLOCK);
    if (source >= 0 && cacheFD >= 0 && catalog >= 0 && boundary >= 0) {
        (void)mkdirat(boundary,"assets",0700);
        assets = openat(boundary,"assets",O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);
    }
    int provenance=integratedState?(state>=0?od_startup_provenance_read(state,boundary,assets):-1):0;
    BOOL known=provenance==1;
    __block BOOL success = source >= 0 && cacheFD >= 0 && boundary >= 0 && assets >= 0 && catalog >= 0 &&
        provenance>=0&&(known?ODIntegratedExistingWorkingTreeSafe(assets):ODDiagnosticNoExistingEngineWorkingTree(assets));
    __block NSDictionary *report = nil;
    if (success) {
        /* Bulk hashing/copying stays on one preparation queue. This wait is
         * before UIApplicationMain/renderer creation, never inside a frame or
         * a callback that must synchronously return to main. */
        dispatch_queue_t queue = dispatch_queue_create("offlinedokkan.original-resource-preparation",DISPATCH_QUEUE_SERIAL);
        dispatch_sync(queue,^{
            @autoreleasepool {
                const char *catalogSHA = "a45b7c9f308e6d07452fd07ac2eeea28981be034554a73e35094552ba9163384";
                const char *manifestSHA = "2196f85c0d09e41967d6b0c08a1860fe57037c1f172cd8c048e9cad70f0f5a33";
                const char *ipaSHA = "0ea61911a09c4e7735f2d7b32b7b2c6c6977c1f4acf0a9db278049528b662816";
                const char *sourceBundle = "GLB.Dkkn.Sparking.dev";
                ODDiagnosticRequiredAliases required = {0};
                od_iphone_resources *resources = NULL;
                od_iphone_resource_preload *preload = NULL;
                NSURL *assetsURL = [documents URLByAppendingPathComponent:@"assets" isDirectory:YES];
                ODDiagnosticPreparationContext context = {.assets=assets,.documents=boundary,.state=state,
                    .assetsPath=assetsURL.fileSystemRepresentation,.documentsPath=documents.fileSystemRepresentation,
                    .statePath=integratedState.fileSystemRepresentation,.active=1,.resuming=known};
                success = !fstat(assets,&context.assetsIdentity) && !fstat(boundary,&context.documentsIdentity) &&
                    (state<0||!fstat(state,&context.stateIdentity))&&
                    !od_iphone_resources_open_catalog_fd(catalog,36864,catalogSHA,manifestSHA,ipaSHA,sourceBundle,
                        bundle.fileSystemRepresentation,cache.fileSystemRepresentation,&resources) &&
                    !od_iphone_resources_visit_aliases(resources,ODDiagnosticCollectAlias,&required) &&
                    required.count == ODDiagnosticCompatibleCount;
                od_iphone_resources_close(resources);
                if (success) {
                    od_iphone_resource_preload_configuration configuration = {
                        .readonly_catalog_descriptor=catalog,.catalog_bytes=36864,.catalog_sha256=catalogSHA,
                        .manifest_sha256=manifestSHA,.ipa_sha256=ipaSHA,.bundle_id=sourceBundle,
                        .source_root=bundle.fileSystemRepresentation,.cache_root=cache.fileSystemRepresentation,
                        .attested_asset_root_descriptor=assets,.attested_working_boundary_descriptor=boundary,
                        .required_asset_relative_paths=(const char *const *)required.paths,.required_count=required.count,
                        .context=&context,.context_is_current=ODDiagnosticPreparationCurrent};
                    od_iphone_resource_preload_receipt receipt = {0};
                    success = !od_iphone_resource_preload_open(&configuration,&preload) &&
                        !od_iphone_resource_preload_run(preload,&receipt) && receipt.configured_paths_complete &&
                        receipt.successful_publications == ODDiagnosticCompatibleCount &&
                        ODDiagnosticPreparationCurrent(&context);
                    if(success&&state>=0)success=!od_startup_provenance_publish(state,boundary,assets);
                    if (success) report = @{@"configuredCompatibleAliases":@(receipt.configured_required_count),
                        @"verifiedCompatibleAliases":@(receipt.successful_publications),
                        @"newlyPublishedAliases":@(receipt.newly_published_files),
                        @"existingVerifiedAliases":@(receipt.existing_verified_files),
                        @"resumedKnownOwnIntegratedTree":@(known),
                        @"originalBundleResourceCompletenessRuntimeVerified":@NO,@"gameplayVerified":@NO};
                }
                context.active = 0;
                od_iphone_resource_preload_close(preload);
                for (size_t i=0;i<required.count;++i) free(required.paths[i]);
            }
        });
    }
    if (catalog >= 0) close(catalog);
    if (assets >= 0) close(assets);
    if (boundary >= 0) close(boundary);
    if (cacheFD >= 0) close(cacheFD);
    if (source >= 0) close(source);
    if (state >= 0) close(state);
    if(success&&resumed)*resumed=known;
    if (success) ODDiagnosticResourceReport = [report copy];
    return success;
}

ODOriginalDuoStartupInputs *ODPrepareOriginalDuoStartupInputs(ODOriginalDuoInputPurpose purpose,NSError **error) {
    ODInputStage(purpose,@"factory-context");
    if (!NSThread.isMainThread) { if (error) *error = ODDiagnosticFailure(); return nil; }
    if(purpose!=ODOriginalDuoInputsDiagnostic&&purpose!=ODOriginalDuoInputsIntegrated){
        if(error)*error=ODDiagnosticFailure();return nil;}
    NSBundle *bundle = NSBundle.mainBundle;
    /* Never install/run this adapted engine under the supplied original game's
     * identity. Native failure cleanup can delete its working sqlite/current
     * tree; an Application Support probe does not isolate that Documents root.
     * The selected purpose must have its exact own app identity; existing
     * integrated trees also require the previously published own provenance.
     * Shared preparation never converts host purposes. */
    NSString *identity = bundle.bundleIdentifier;
    ODInputStage(purpose,@"own-app-identity");
    NSString *expected=purpose==ODOriginalDuoInputsDiagnostic?@"org.offlinedokkan.startupdiagnostic.duo":@"org.offlinedokkan.duo";
    if (![identity isEqualToString:expected]) {
        if (error) *error = ODDiagnosticFailure(); return nil;
    }
    NSURL *bundleRoot = ODDiagnosticNativeRoot(bundle.resourceURL);
    NSURL *baseline = [bundleRoot URLByAppendingPathComponent:@"OriginalClient/OriginalGenuineDuoShell"];
    NSURL *frameworks = [bundleRoot URLByAppendingPathComponent:@"Frameworks" isDirectory:YES];
    NSURL *canonicalEngine = [frameworks URLByAppendingPathComponent:@"OriginalDokkanEngine.dylib"];
    /* The existing loader admits the exact native bundle spelling as well as
     * its resolved identity. Keep its own expected URL, while preflight walks
     * the canonical root without following arbitrary resource descendants. */
    NSURL *engine = [bundle.privateFrameworksURL URLByAppendingPathComponent:@"OriginalDokkanEngine.dylib"];
    NSURL *dependency = [frameworks URLByAppendingPathComponent:@"AdjustSigSdk.framework/AdjustSigSdk"];
    NSURL *seed = [bundleRoot URLByAppendingPathComponent:@"database.db"];
    NSArray<NSURL *> *documents = [NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *documentRoot = ODDiagnosticNativeRoot(documents.firstObject);
    NSURL *resources = [documentRoot URLByAppendingPathComponent:@"assets" isDirectory:YES];
    ODInputStage(purpose,@"original-startup-inputs");
    if (!ODDiagnosticRegularFile(baseline) || !ODDiagnosticRegularFile(canonicalEngine) ||
        !ODDiagnosticRegularFile(dependency) || !ODDiagnosticOriginalSeed(seed)) {
        if (error) *error = ODDiagnosticFailure(); return nil;
    }
    NSURL *state=nil;
    if(purpose==ODOriginalDuoInputsIntegrated){state=ODStartupStateRoot(purpose);if(!state){
        if(error)*error=ODDiagnosticFailure();return nil;}}
    BOOL resumed=NO;
    ODInputStage(purpose,@"compatible-resource-preload");
    if (!ODDiagnosticPrepareWorkingResources(bundleRoot,documentRoot,state,&resumed)) {
        if (error) *error = ODDiagnosticFailure(); return nil;
    }
    ODInputStage(purpose,@"fresh-working-assets");
    int resourceFD = ODDiagnosticDirectory(resources);
    BOOL ready = ODDiagnosticHasAssets(resourceFD) && (resumed?ODIntegratedExistingWorkingTreeSafe(resourceFD):
        ODDiagnosticNoExistingEngineWorkingTree(resourceFD));
    if (resourceFD >= 0) close(resourceFD);
    if (!ready) { if (error) *error = ODDiagnosticFailure(); return nil; }

    /* Purpose-specific own startup state, separate from Documents/assets and
     * existing save folders. Original seed/resource files are not modified. */
    ODInputStage(purpose,@"diagnostic-state-directory");
    if(!state)state=ODStartupStateRoot(purpose);
    if(!state){if(error)*error=ODDiagnosticFailure();return nil;}
    return [[ODOriginalDuoStartupInputs alloc] initWithBundle:bundleRoot baseline:baseline engine:engine
        resources:resources state:state compatible:ODDiagnosticResourceReport?:@{} knownIntegratedRelaunch:resumed];
}

ODUnifiedDuoHost *ODCreateOriginalDuoStartupDiagnosticHost(NSError **error) {
    ODOriginalDuoStartupInputs *inputs=ODPrepareOriginalDuoStartupInputs(ODOriginalDuoInputsDiagnostic,error);
    if(!inputs)return nil;
    NSError *failure = nil;
    ODDiagnosticFactoryStage=@"native-host-configuration";
    ODUnifiedDuoHost *host = [[ODUnifiedDuoHost alloc] initWithPurpose:ODUnifiedDuoStartupDiagnostic
        genuineShellBaselineURL:inputs.genuineShellBaselineURL preparedEngineURL:inputs.preparedEngineURL resourcesRootURL:inputs.resourcesRootURL
        writableStateRootURL:inputs.writableStateRootURL approvedOrigins:@[] routes:@[] creatorServices:nil attachPreparedImage:nil
        contextIsCurrent:^BOOL { return NSThread.isMainThread; }
        reportHandler:^(NSDictionary *report) {
            NSMutableDictionary *snapshot = [report mutableCopy];
            if (ODDiagnosticResourceReport) snapshot[@"workingCompatibleResources"] = ODDiagnosticResourceReport;
            ODDiagnosticReport = [snapshot copy];
        } error:&failure];
    if (!host && error) *error = ODDiagnosticFailure();
    return host;
}

NSDictionary *ODCopyOriginalDuoStartupDiagnosticReport(void) {
    if(!NSThread.isMainThread||(!ODDiagnosticReport&&!ODDiagnosticFactoryStage))return nil;
    NSMutableDictionary *report=ODDiagnosticReport?[ODDiagnosticReport mutableCopy]:
        [@{@"purpose":@"original-startup-diagnostic",@"stage":ODDiagnosticFactoryStage} mutableCopy];
    NSDictionary *observation=ODCopyOriginalMasterLaunchObservation();
    if(observation)report[@"originalMasterLaunchObservation"]=observation;
    /* Native master initialization can finish asynchronously after launch.
     * Re-read only the existing bounded observation on demand; do not infer
     * schema/codec/selected-file acceptance from a later cached handle. */
    id original=ODCurrentOriginalAppController();NSDictionary *current=nil;
    if(original){@try{current=ODCopyOriginalMasterObservation(original);}@catch(NSException *exception){(void)exception;}}
    report[@"originalMasterCurrentObservation"]=@{@"schema":@1,@"capturedOnReportRead":@YES,
        @"nativeObservationAvailable":@(current!=nil),
        @"nativeMaster":current?:@{@"nativeMasterAccepted":@NO,@"originalSchemaOutcomeObserved":@NO}};
    return [report copy];
}

/* Library/component reuse is inert by default. This explicit diagnostic entry
 * cannot satisfy the integrated factory's purpose check or its release gate. */
#if defined(OD_ORIGINAL_DUO_DIAGNOSTIC_ENTRY) && OD_ORIGINAL_DUO_DIAGNOSTIC_ENTRY
static ODUnifiedDuoHost *ODDiagnosticHost;
__attribute__((constructor)) static void ODStartOriginalDuoDiagnostic(void) {
    @autoreleasepool {
        @try {
            ODUnifiedDuoHost *host = ODCreateOriginalDuoStartupDiagnosticHost(NULL);
            if (host && [host.startupReport[@"purpose"] isEqualToString:@"original-startup-diagnostic"] &&
                [host installBeforeApplicationMain:NULL]) {
                ODDiagnosticHost = host;
                return;
            }
        } @catch (NSException *exception) { (void)exception; }
        // Only source-fixed stage labels enter stderr; never NSError details,
        // filesystem paths, origins, request data or exception descriptions.
        NSString *stage=ODCopyOriginalDuoStartupDiagnosticReport()[@"stage"];
        NSArray<NSString *> *stages=@[@"factory-context",@"own-app-identity",@"original-startup-inputs",
            @"compatible-resource-preload",@"fresh-working-assets",@"diagnostic-state-directory",
            @"native-host-configuration",@"configured",@"installing-genuine-shell-bootstrap",
            @"native-environment-prepared",@"request-observer-registration-failed",@"prepared-image-load-failed",
            @"original-initializers-completed",@"native-image-attachment-failed",
            @"waiting-for-actual-appcontroller-scene",@"bootstrap-installation-failed"];
        if(![stages containsObject:stage?:@""])stage=@"unavailable";
        fprintf(stderr,"Offline Dokkan: original-client startup diagnostic failed at %s.\n",stage.UTF8String);
        _exit(EXIT_FAILURE);
    }
}
#endif
