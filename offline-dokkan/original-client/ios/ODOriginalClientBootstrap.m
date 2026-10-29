#import "ODOriginalClientBootstrap.h"
#import "ODLocalURLProtocolBootstrap.h"
#import "ODGameHTTPABI.h"
#import "../duo/ODDuoOriginalScene.h"
#import "../content/ODNativeMasterObservation.h"
#import <CommonCrypto/CommonDigest.h>
#import <objc/runtime.h>
#import <objc/message.h>
#include <mach-o/loader.h>
#include <mach/machine.h>
#include <dlfcn.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

static NSError *ODBootstrapError(NSInteger code, NSString *label) {
    return [NSError errorWithDomain:@"OfflineDokkanBootstrap" code:code
        userInfo:@{NSLocalizedDescriptionKey:label}];
}

static BOOL ODSameInput(struct stat a, struct stat b) {
    return a.st_dev == b.st_dev && a.st_ino == b.st_ino && a.st_size == b.st_size &&
           a.st_mtimespec.tv_sec == b.st_mtimespec.tv_sec && a.st_mtimespec.tv_nsec == b.st_mtimespec.tv_nsec &&
           a.st_ctimespec.tv_sec == b.st_ctimespec.tv_sec && a.st_ctimespec.tv_nsec == b.st_ctimespec.tv_nsec;
}

@interface ODPinnedOriginalInput : NSObject
@property (nonatomic, readonly) int descriptor;
@property (nonatomic, readonly) struct stat identity;
- (instancetype)init NS_UNAVAILABLE;
- (nullable instancetype)initWithURL:(NSURL *)url bytes:(off_t)bytes sha256:(const char *)expected;
- (BOOL)unchanged;
@end

static BOOL ODPreadExact(int fd, void *bytes, size_t length, off_t position) {
    size_t done = 0;
    while (done < length) {
        ssize_t count = pread(fd,(char *)bytes+done,length-done,position+(off_t)done);
        if (count < 0 && errno == EINTR) continue;
        if (count <= 0) return NO;
        done += (size_t)count;
    }
    return YES;
}

static BOOL ODActualDuoHostSDK(ODPinnedOriginalInput *host) {
    struct mach_header_64 header;
    if (!ODPreadExact(host.descriptor,&header,sizeof(header),0) || header.magic != MH_MAGIC_64 ||
        header.cputype != CPU_TYPE_ARM64 || header.filetype != MH_EXECUTE ||
        !header.ncmds || header.ncmds > 4096 || header.sizeofcmds > 4*1024*1024 ||
        sizeof(header)+(uint64_t)header.sizeofcmds > (uint64_t)host.identity.st_size) return NO;
    NSMutableData *commands = [NSMutableData dataWithLength:header.sizeofcmds];
    if (!ODPreadExact(host.descriptor,commands.mutableBytes,commands.length,sizeof(header))) return NO;
    const unsigned char *bytes = commands.bytes;
    size_t position = 0; NSUInteger buildCommands = 0;
    for (uint32_t i = 0; i < header.ncmds; ++i) {
        if (position+sizeof(struct load_command) > commands.length) return NO;
        struct load_command command; memcpy(&command,bytes+position,sizeof(command));
        if (command.cmdsize < sizeof(command) || command.cmdsize % 8 ||
            position+command.cmdsize > commands.length) return NO;
        if (command.cmd == LC_BUILD_VERSION) {
            if (command.cmdsize < sizeof(struct build_version_command)) return NO;
            struct build_version_command build; memcpy(&build,bytes+position,sizeof(build));
            if (build.platform != PLATFORM_IOS || build.sdk != ((27u<<16)|(1u<<8)) || build.minos != ((16u<<16)|(4u<<8)) ||
                sizeof(build)+(uint64_t)build.ntools*sizeof(struct build_tool_version) != command.cmdsize) return NO;
            ++buildCommands;
        } else if (command.cmd == LC_ENCRYPTION_INFO_64) {
            if (command.cmdsize != sizeof(struct encryption_info_command_64)) return NO;
            struct encryption_info_command_64 encryption; memcpy(&encryption,bytes+position,sizeof(encryption));
            if (encryption.cryptid) return NO;
        }
        position += command.cmdsize;
    }
    return position == commands.length && buildCommands == 1;
}

static NSData *ODHostCommands(ODPinnedOriginalInput *file, struct mach_header_64 *header) {
    if (!ODActualDuoHostSDK(file) || !ODPreadExact(file.descriptor,header,sizeof(*header),0)) return nil;
    NSMutableData *data = [NSMutableData dataWithLength:header->sizeofcmds];
    return ODPreadExact(file.descriptor,data.mutableBytes,data.length,sizeof(*header)) ? data : nil;
}

static BOOL ODPreservedShellIdentity(ODPinnedOriginalInput *source, ODPinnedOriginalInput *active) {
    struct mach_header_64 before, after;
    NSData *a = ODHostCommands(source,&before), *b = ODHostCommands(active,&after);
    if (!a || !b) return NO;
    before.ncmds = after.ncmds = 0; before.sizeofcmds = after.sizeofcmds = 0;
    if (memcmp(&before,&after,sizeof(before))) return NO;
    NSMutableArray<NSData *> *normalized[2] = {[NSMutableArray array],[NSMutableArray array]};
    uint64_t bodyStart = UINT64_MAX, sourceSignature = 0, activeSignature = 0;
    NSUInteger pluginCount = 0, sections = 0;
    CC_SHA256_CTX digest; CC_SHA256_Init(&digest);
    const char label[] = "ODNativeHostSections/v1";
    CC_SHA256_Update(&digest,label,sizeof(label));
    for (NSUInteger side = 0; side < 2; ++side) {
        ODPinnedOriginalInput *file = side ? active : source;
        NSData *data = side ? b : a; size_t position = 0; NSUInteger signatures = 0;
        while (position < data.length) {
            struct load_command command; memcpy(&command,(const char *)data.bytes+position,sizeof(command));
            NSMutableData *normalizedCommand = [[data subdataWithRange:NSMakeRange(position,command.cmdsize)] mutableCopy];
            BOOL omit = NO;
            if (command.cmd == LC_CODE_SIGNATURE) {
                if (++signatures > 1 || command.cmdsize != sizeof(struct linkedit_data_command)) return NO;
                struct linkedit_data_command signature; memcpy(&signature,normalizedCommand.bytes,sizeof(signature));
                if (!signature.datasize || (uint64_t)signature.dataoff+signature.datasize > (uint64_t)file.identity.st_size) return NO;
                if (side) activeSignature = signature.dataoff; else sourceSignature = signature.dataoff;
                omit = YES;
            } else if (command.cmd == LC_LOAD_DYLIB) {
                if (command.cmdsize < sizeof(struct dylib_command)) return NO;
                struct dylib_command library; memcpy(&library,normalizedCommand.bytes,sizeof(library));
                if (library.dylib.name.offset < sizeof(library) || library.dylib.name.offset >= command.cmdsize) return NO;
                const char *name = (const char *)normalizedCommand.bytes+library.dylib.name.offset;
                size_t capacity = command.cmdsize-library.dylib.name.offset;
                if (!memchr(name,0,capacity)) return NO;
                if (!strcmp(name,"@executable_path/Frameworks/OfflineDokkanHost.dylib")) {
                    size_t required = sizeof(library)+strlen(name)+1;
                    if (!side || ++pluginCount != 1 || library.dylib.name.offset != sizeof(library) ||
                        library.dylib.timestamp || library.dylib.current_version != 0x10000 || library.dylib.compatibility_version != 0x10000 ||
                        command.cmdsize != ((required+7)&~(size_t)7)) return NO;
                    for (size_t i = strlen(name)+1; i < capacity; ++i) if (name[i]) return NO;
                    omit = YES;
                }
            } else if (command.cmd == LC_SEGMENT_64) {
                if (command.cmdsize < sizeof(struct segment_command_64)) return NO;
                struct segment_command_64 segment; memcpy(&segment,normalizedCommand.bytes,sizeof(segment));
                if (sizeof(segment)+(uint64_t)segment.nsects*sizeof(struct section_64) != command.cmdsize ||
                    segment.fileoff+segment.filesize < segment.fileoff || segment.fileoff+segment.filesize > (uint64_t)file.identity.st_size ||
                    segment.vmsize < segment.filesize) return NO;
                if (!strncmp(segment.segname,"__LINKEDIT",16)) {
                    // Final signing can replace/append its blob. All original
                    // referenced pre-signature import/linkedit bytes below stay exact.
                    struct segment_command_64 stable = segment; stable.vmsize = stable.filesize = 0;
                    memcpy(normalizedCommand.mutableBytes,&stable,sizeof(stable));
                }
                for (uint32_t i = 0; i < segment.nsects; ++i) {
                    struct section_64 section;
                    memcpy(&section,(const char *)normalizedCommand.bytes+sizeof(segment)+i*sizeof(section),sizeof(section));
                    unsigned int type = section.flags&SECTION_TYPE;
                    if (type == S_ZEROFILL || type == S_GB_ZEROFILL || type == S_THREAD_LOCAL_ZEROFILL) continue;
                    if (section.offset < sizeof(struct mach_header_64)+data.length ||
                        section.size > (uint64_t)file.identity.st_size || section.offset+section.size > (uint64_t)file.identity.st_size) return NO;
                    if (!side && section.size && section.offset < bodyStart) bodyStart = section.offset;
                    if (side) {
                        unsigned char packed[52];
                        memcpy(packed,section.segname,16); memcpy(packed+16,section.sectname,16);
                        memcpy(packed+32,&section.addr,8); memcpy(packed+40,&section.size,8); memcpy(packed+48,&section.flags,4);
                        CC_SHA256_Update(&digest,packed,sizeof(packed)); ++sections;
                        unsigned char buffer[65536]; uint64_t done = 0;
                        while (done < section.size) {
                            size_t count = (size_t)MIN((uint64_t)sizeof(buffer),section.size-done);
                            if (!ODPreadExact(file.descriptor,buffer,count,(off_t)(section.offset+done))) return NO;
                            CC_SHA256_Update(&digest,buffer,(CC_LONG)count); done += count;
                        }
                    }
                }
            }
            if (!omit) [normalized[side] addObject:normalizedCommand];
            position += command.cmdsize;
        }
    }
    if (pluginCount != 1 || sections != 29 || ![normalized[0] isEqualToArray:normalized[1]] ||
        !sourceSignature || bodyStart == UINT64_MAX || bodyStart >= sourceSignature ||
        (activeSignature && activeSignature < sourceSignature) || (uint64_t)active.identity.st_size < sourceSignature) return NO;
    unsigned char expected[32] = {0xe6,0x8e,0x1f,0x76,0x4a,0xb9,0xe1,0xaa,0x4e,0x0f,0xa8,0x76,0xb1,0x61,0x2c,0x00,
        0x1a,0x25,0x38,0x30,0x67,0x70,0x25,0x9a,0xaf,0x68,0x19,0x7a,0xf0,0xb0,0x14,0xb6};
    unsigned char actual[32]; CC_SHA256_Final(actual,&digest);
    if (memcmp(actual,expected,sizeof(actual))) return NO;
    // Pin all referenced original file body/import data, not only sections.
    // The exact original code-signature blob is intentionally excluded.
    unsigned char left[65536], right[65536]; uint64_t position = bodyStart;
    while (position < sourceSignature) {
        size_t count = (size_t)MIN((uint64_t)sizeof(left),sourceSignature-position);
        if (!ODPreadExact(source.descriptor,left,count,(off_t)position) ||
            !ODPreadExact(active.descriptor,right,count,(off_t)position) || memcmp(left,right,count)) return NO;
        position += count;
    }
    return [source unchanged] && [active unchanged];
}

static Method ODOwnMethod(Class cls, SEL selector, const char *encoding) {
    unsigned int count = 0; Method result = NULL;
    Method *methods = class_copyMethodList(cls,&count);
    for (unsigned int i = 0; i < count; ++i) {
        if (method_getName(methods[i]) == selector && !strcmp(method_getTypeEncoding(methods[i]),encoding)) {
            result = methods[i]; break;
        }
    }
    free(methods); return result;
}

static BOOL ODMethodBelongsToHost(Method method, ODPinnedOriginalInput *host) {
    Dl_info info;
    if (!method || !dladdr((const void *)method_getImplementation(method),&info) || !info.dli_fname) return NO;
    int descriptor = open(info.dli_fname,O_RDONLY|O_NOFOLLOW|O_CLOEXEC);
    if (descriptor < 0) return NO;
    struct stat identity; BOOL same = fstat(descriptor,&identity) == 0 &&
        identity.st_dev == host.identity.st_dev && identity.st_ino == host.identity.st_ino;
    close(descriptor); return same;
}

static id ODActualOriginalAppController;
static IMP ODShellOriginalLaunch;
static BOOL ODShellLaunchAttempted;
static NSDictionary *ODOriginalMasterLaunchObservation;

NSDictionary *ODCopyOriginalMasterLaunchObservation(void) {
    return NSThread.isMainThread?[ODOriginalMasterLaunchObservation copy]:nil;
}

static BOOL ODShellLaunch(id shell, SEL selector, UIApplication *application, NSDictionary *options) {
    if (!NSThread.isMainThread || ODShellLaunchAttempted || !ODShellOriginalLaunch) return NO;
    ODShellLaunchAttempted = YES;
    // The exact source shell's own implementation simply returns YES. Preserve
    // it on its correct object; never invoke an AppController IMP on this shell.
    if (!((BOOL(*)(id,SEL,UIApplication *,NSDictionary *))ODShellOriginalLaunch)(shell,selector,application,options)) return NO;
    Class game = NSClassFromString(@"AppController");
    ODActualOriginalAppController = [[game alloc] init];
    if (!ODActualOriginalAppController) return NO;
    BOOL originalResult=((BOOL(*)(id,SEL,UIApplication *,NSDictionary *))objc_msgSend)(
        ODActualOriginalAppController,@selector(application:didFinishLaunchingWithOptions:),application,options);
    // Observe the actual original controller, never the preserved shell or its
    // RootViewController. Failure of this optional read cannot alter launch.
    NSDictionary *native=nil;
    @try { native=ODCopyOriginalMasterObservation(ODActualOriginalAppController); }
    @catch(NSException *exception) { (void)exception; }
    ODOriginalMasterLaunchObservation=@{@"schema":@1,@"capturedAfterOriginalLaunch":@YES,
        @"originalLaunchReturnedSuccess":@(originalResult),@"nativeObservationAvailable":@(native!=nil),
        @"nativeMaster":native?:@{@"nativeMasterAccepted":@NO,@"originalSchemaOutcomeObserved":@NO}};
    if(!originalResult)fputs("Offline Dokkan: original-appcontroller-launch-returned-failure.\n",stderr);
    return originalResult;
}

static UISceneConfiguration *ODShellSceneConfiguration(id shell, SEL selector, UIApplication *application,
    UISceneSession *session, UISceneConnectionOptions *options) {
    (void)shell; (void)selector; (void)application; (void)options;
    // The source shell hardcodes its WebView SceneDelegate in this method.
    // Manifest edits alone cannot replace that behavior.
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc] initWithName:@"OfflineDokkanDuo" sessionRole:session.role];
    configuration.delegateClass = ODDuoOriginalSceneDelegate.class;
    return configuration;
}

static void ODShellTerminate(id shell, SEL selector, UIApplication *application) {
    (void)shell;
    if (ODActualOriginalAppController)
        ((void(*)(id,SEL,id))objc_msgSend)(ODActualOriginalAppController,selector,application);
}

static BOOL ODInstallShellBootstrap(NSURL *genuineShellBaselineURL,
    NSArray<NSURL *> *approvedOrigins, NSArray<ODLocalTransportRoute *> *routes,
    ODPreparedOriginalClientLoadImage loadImage, ODOriginalClientRegisterSceneBridge registerSceneBridge,
    NSError **error) {
    static BOOL attempted;
    @synchronized(ODLocalURLProtocol.class) {
        if (attempted || !NSThread.isMainThread || !loadImage || !registerSceneBridge) {
            if (error) *error = ODBootstrapError(10,@"INVALID_DUO_SHELL_STARTUP"); return NO;
        }
        attempted = YES;
    }
    ODPinnedOriginalInput *baseline = [[ODPinnedOriginalInput alloc] initWithURL:genuineShellBaselineURL bytes:332320
        sha256:"18db225cd578fcfc724b1dbf6c0b89eb2213fb05d6113cd52fbc1a1ce006218a"];
    ODPinnedOriginalInput *host = [[ODPinnedOriginalInput alloc] initWithURL:NSBundle.mainBundle.executableURL
        bytes:0 sha256:NULL];
    if (!baseline || !host || !ODPreservedShellIdentity(baseline,host)) {
        if (error) *error = ODBootstrapError(11,@"DUO_SHELL_IDENTITY_MISMATCH"); return NO;
    }
    NSError *failure = nil;
    if (!ODInstallLocalTransportForPinnedBootstrap(approvedOrigins,routes,&failure)) {
        if (error) *error = ODBootstrapError(12,@"DUO_SHELL_LOCAL_TRANSPORT_FAILED"); return NO;
    }
    BOOL loaded = NO;
    @try { loaded = loadImage(&failure); }
    @catch (NSException *exception) { loaded = NO; }
    Class shell = NSClassFromString(@"AppDelegate"), game = NSClassFromString(@"AppController");
    SEL launch = @selector(application:didFinishLaunchingWithOptions:);
    SEL scene = @selector(application:configurationForConnectingSceneSession:options:);
    SEL terminate = @selector(applicationWillTerminate:);
    Method shellLaunch = ODOwnMethod(shell,launch,"B32@0:8@16@24");
    Method shellScene = ODOwnMethod(shell,scene,"@40@0:8@16@24@32");
    if (!loaded || ![baseline unchanged] || ![host unchanged] ||
        !ODVerifySuppliedGameHTTPABI(&failure) || class_getSuperclass(shell) != UIResponder.class ||
        !ODOwnMethod(game,launch,"B32@0:8@16@24") || !ODOwnMethod(game,terminate,"v24@0:8@16") ||
        !ODMethodBelongsToHost(shellLaunch,host) || !ODMethodBelongsToHost(shellScene,host) ||
        class_getInstanceMethod(shell,terminate)) {
        if (error) *error = ODBootstrapError(13,@"DUO_SHELL_IMAGE_ABI_NOT_ADMITTED"); return NO;
    }
    if (!ODDuoSetOriginalAppControllerProvider(^id { return ODActualOriginalAppController; },&failure)) {
        if (error) *error = ODBootstrapError(14,@"DUO_SHELL_PROVIDER_FAILED"); return NO;
    }
    BOOL sceneReady = NO;
    @try { sceneReady = registerSceneBridge(&failure); }
    @catch (NSException *exception) { sceneReady = NO; }
    if (!sceneReady) { if (error) *error = ODBootstrapError(15,@"DUO_SHELL_SCENE_BRIDGE_FAILED"); return NO; }
    ODShellOriginalLaunch = method_getImplementation(shellLaunch);
    IMP originalScene = method_getImplementation(shellScene);
    if (!class_addMethod(shell,terminate,(IMP)ODShellTerminate,"v24@0:8@16") ||
        method_setImplementation(shellLaunch,(IMP)ODShellLaunch) != ODShellOriginalLaunch ||
        method_setImplementation(shellScene,(IMP)ODShellSceneConfiguration) != originalScene) {
        if (error) *error = ODBootstrapError(16,@"DUO_SHELL_HOOK_INSTALLATION_FAILED"); return NO;
    }
    return YES;
}

BOOL ODInstallPreparedDuoShellBootstrap(NSURL *genuineShellBaselineURL,
    NSArray<NSURL *> *origins, NSArray<ODLocalTransportRoute *> *routes,
    ODPreparedOriginalClientLoadImage verifyAndLoadPreparedImage,
    ODOriginalClientRegisterSceneBridge registerSceneBridge, NSError **error) {
    return ODInstallShellBootstrap(genuineShellBaselineURL,origins,routes,
        verifyAndLoadPreparedImage,registerSceneBridge,error);
}

BOOL ODInstallPinnedDuoShellBootstrap(NSURL *genuineShellBaselineURL, NSURL *originalExecutableURL, NSURL *sourcePatcherURL,
    NSArray<NSURL *> *origins, NSArray<ODLocalTransportRoute *> *routes,
    ODOriginalClientLoadImage loadImage, ODOriginalClientRegisterSceneBridge registerSceneBridge, NSError **error) {
    ODPinnedOriginalInput *main = [[ODPinnedOriginalInput alloc] initWithURL:originalExecutableURL bytes:55697728
        sha256:"9d6bf0470c4b4ff7d914740ccf9f1622afa962b763e18bfcf1f6e051bfae0610"];
    ODPinnedOriginalInput *patcher = [[ODPinnedOriginalInput alloc] initWithURL:sourcePatcherURL bytes:5657724
        sha256:"74e47aa75fdbd828fa3918a966b50457e8497143962d5be573cb60f332e055dc"];
    if (!main || !patcher || !loadImage) { if (error) *error = ODBootstrapError(3,@"ORIGINAL_INPUT_IDENTITY_MISMATCH"); return NO; }
    return ODInstallShellBootstrap(genuineShellBaselineURL,origins,routes,^BOOL(NSError **failure) {
        BOOL loaded = loadImage(main.descriptor,patcher.descriptor,failure);
        return loaded && [main unchanged] && [patcher unchanged];
    },registerSceneBridge,error);
}
@implementation ODPinnedOriginalInput
- (instancetype)initWithURL:(NSURL *)url bytes:(off_t)bytes sha256:(const char *)expected {
    if ((self = [super init])) {
        _descriptor = -1;
        if (!url.isFileURL || !url.fileSystemRepresentation) return nil;
        _descriptor = open(url.fileSystemRepresentation,O_RDONLY|O_NOFOLLOW|O_CLOEXEC);
        if (_descriptor < 0 || fstat(_descriptor,&_identity) != 0 || !S_ISREG(_identity.st_mode) ||
            (bytes > 0 ? _identity.st_size != bytes : (_identity.st_size <= 0 || _identity.st_size > 8*1024*1024))) return nil;
        off_t expectedBytes = bytes > 0 ? bytes : _identity.st_size;
        CC_SHA256_CTX context; CC_SHA256_Init(&context);
        unsigned char buffer[65536], digest[CC_SHA256_DIGEST_LENGTH]; off_t total = 0;
        for (;;) {
            ssize_t count = read(_descriptor,buffer,sizeof(buffer));
            if (count < 0 && errno == EINTR) continue;
            if (count < 0) return nil;
            if (!count) break;
            total += count; if (total > expectedBytes) return nil;
            CC_SHA256_Update(&context,buffer,(CC_LONG)count);
        }
        CC_SHA256_Final(digest,&context);
        char hex[65]; const char *digits = "0123456789abcdef";
        for (NSUInteger i = 0; i < sizeof(digest); ++i) { hex[2*i] = digits[digest[i] >> 4]; hex[2*i+1] = digits[digest[i] & 15]; }
        hex[64] = 0;
        if (total != expectedBytes || (expected && strcmp(hex,expected)) || ![self unchanged] || lseek(_descriptor,0,SEEK_SET) != 0) return nil;
    }
    return self;
}
- (BOOL)unchanged {
    struct stat now;
    return _descriptor >= 0 && fstat(_descriptor,&now) == 0 && S_ISREG(now.st_mode) && ODSameInput(_identity,now);
}
- (void)dealloc { if (_descriptor >= 0) close(_descriptor); }
@end

int ODRunPinnedOriginalClient(int argc, char * _Nullable * _Nonnull argv, NSURL *originalExecutableURL, NSURL *sourcePatcherURL,
    NSArray<NSURL *> *approvedOrigins, NSArray<ODLocalTransportRoute *> *routes,
    ODOriginalClientLoadImage loadImage, ODOriginalClientRegisterSceneBridge registerSceneBridge,
    NSError **error) {
    @autoreleasepool {
        // Compiling this source against old headers cannot become Duo-ready by
        // merely editing LC_BUILD_VERSION. Root's hosted builder must also pin
        // and verify the genuine SDK/toolchain provenance and actual displays.
        if (__IPHONE_OS_VERSION_MAX_ALLOWED < 270100) {
            if (error) *error = ODBootstrapError(1,@"GENUINE_DUO_SDK_REQUIRED"); return EXIT_FAILURE;
        }
        static BOOL attempted;
        @synchronized(ODLocalURLProtocol.class) {
            if (attempted || argc < 1 || !argv || !argv[0] || !NSThread.isMainThread || !loadImage || !registerSceneBridge) {
                if (error) *error = ODBootstrapError(2,@"INVALID_ORIGINAL_STARTUP"); return EXIT_FAILURE;
            }
            attempted = YES;
        }
        // Native configured files only; no user-supplied switches to trust or
        // source-provider key fields are accepted by this entry.
        ODPinnedOriginalInput *main = [[ODPinnedOriginalInput alloc] initWithURL:originalExecutableURL bytes:55697728
            sha256:"9d6bf0470c4b4ff7d914740ccf9f1622afa962b763e18bfcf1f6e051bfae0610"];
        ODPinnedOriginalInput *patcher = [[ODPinnedOriginalInput alloc] initWithURL:sourcePatcherURL bytes:5657724
            sha256:"74e47aa75fdbd828fa3918a966b50457e8497143962d5be573cb60f332e055dc"];
        if (!main || !patcher) { if (error) *error = ODBootstrapError(3,@"ORIGINAL_INPUT_IDENTITY_MISMATCH"); return EXIT_FAILURE; }
        NSError *failure = nil;
        // Installation happens before the reviewed image loader executes any
        // original constructors. It cannot contain transports outside Foundation.
        if (!ODInstallLocalTransportForPinnedBootstrap(approvedOrigins,routes,&failure)) {
            if (error) *error = ODBootstrapError(4,@"EARLY_LOCAL_TRANSPORT_FAILED"); return EXIT_FAILURE;
        }
        BOOL loaded = NO;
        @try { loaded = loadImage(main.descriptor,patcher.descriptor,&failure); }
        @catch (NSException *exception) { loaded = NO; }
        if (!loaded || ![main unchanged] || ![patcher unchanged] || !ODVerifySuppliedGameHTTPABI(&failure) ||
            !NSClassFromString(@"AppController")) {
            if (error) *error = ODBootstrapError(5,@"ORIGINAL_IMAGE_NOT_ADMITTED"); return EXIT_FAILURE;
        }
        BOOL sceneReady = NO;
        @try { sceneReady = registerSceneBridge(&failure); }
        @catch (NSException *exception) { sceneReady = NO; }
        if (!sceneReady) { if (error) *error = ODBootstrapError(6,@"ORIGINAL_SCENE_BRIDGE_FAILED"); return EXIT_FAILURE; }
        // Verified from the supplied executable's actual main implementation.
        // Preserve the actual delegate and its Cocos game scene/engine setup.
        return UIApplicationMain(argc,argv,nil,@"AppController");
    }
}
