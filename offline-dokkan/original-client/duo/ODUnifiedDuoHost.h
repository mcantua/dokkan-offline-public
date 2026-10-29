#import <Foundation/Foundation.h>
#import "ODDuoOriginalScene.h"
#import "../ios/ODLocalURLProtocol.h"
@class ODBoundOriginalCreatorServices;
NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSUInteger, ODUnifiedDuoPurpose) {
    ODUnifiedDuoStartupDiagnostic,
    ODUnifiedDuoIntegratedTarget
};
/* Runs after the admitted engine's ordinary dyld initialization, before actual
   AppController launch. Attach the reviewed resource/master adapters here; no
   browser-supplied callable/configuration is accepted. */
typedef BOOL (^ODUnifiedDuoImageAttachment)(NSError * _Nullable * _Nullable error);
typedef void (^ODUnifiedDuoReportHandler)(NSDictionary *report);

/** Native composition owner for the preserved genuine27.1 shell, prepared
 * original engine, actual Duo scene and same-save Creator services. Services
 * may be supplied before UIApplicationMain, or bound on main afterward from
 * the async profile/scope reply. Startup diagnostic may omit services/routes/attachment;
 * it observes authorized original startup and does not claim offline gameplay.
 * The resource/state URLs are native-owned capabilities, never page arguments.
 * This module does not establish kernel/raw-socket/WK network isolation. */
@interface ODUnifiedDuoHost : NSObject
- (nullable instancetype)initWithPurpose:(ODUnifiedDuoPurpose)purpose
    genuineShellBaselineURL:(NSURL *)baseline preparedEngineURL:(NSURL *)engine
    resourcesRootURL:(NSURL *)resources writableStateRootURL:(NSURL *)state
    approvedOrigins:(NSArray<NSURL *> *)origins routes:(NSArray<ODLocalTransportRoute *> *)routes
    creatorServices:(nullable ODBoundOriginalCreatorServices *)services
    attachPreparedImage:(nullable ODUnifiedDuoImageAttachment)attach
    contextIsCurrent:(BOOL (^)(void))current
    reportHandler:(ODUnifiedDuoReportHandler)report
    error:(NSError * _Nullable * _Nullable)error NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
/** Copy the plaintext derived master into this host's writable state directory
 * at the reviewed MAIN relative path. Call on main before install. The only
 * source file stays read-only. No key is applied and the engine cache is not
 * redirected. Integrated startup requires this call. */
- (BOOL)stagePlaintextDerivedMasterAtURL:(NSURL *)derived byteCount:(uint64_t)bytes
    contentSHA256:(NSString *)sha256 language:(NSString *)language
    error:(NSError * _Nullable * _Nullable)error;
/** Integrated startup may reach UIApplicationMain before the async core
 * profile/scope reply. Record that reply's exact content id and save scope,
 * then pass the services built from it to bindCreatorServicesWhenReady:. */
- (BOOL)expectDeferredCreatorServicesForContentID:(NSString *)contentID
    saveScopeSHA256:(NSString *)scope error:(NSError * _Nullable * _Nullable)error;
/** NO is a fatal startup result to the plugin caller: do not show the old
 * standalone shell as if it were the unified original game. */
- (BOOL)installBeforeApplicationMain:(NSError * _Nullable * _Nullable)error;
/** Main-thread binding after UIApplicationMain. A call from another queue is
 * queued; this method does not wait. The services must match the content id
 * and save scope recorded before install. */
- (void)bindCreatorServicesWhenReady:(ODBoundOriginalCreatorServices *)services
    completion:(void (^)(NSError * _Nullable error))completion;
/** Explicit target for a reviewed native in-game user action. This does not
 * invent/inject a game menu position or automatically open the editor. */
- (void)presentCreatorFromUserActionWithCompletion:(void (^)(NSError * _Nullable error))completion;
/* Reports/updates are delivered on main. Unsupported Foundation requests are
   bounded to64 reviewed method/path pairs; dynamic IDs are already redacted by
   the transport. No origin, query, headers, body or raw-socket observation is
   included. Reading startupReport is also main-thread only. */
@property(nonatomic,readonly,copy) NSDictionary *startupReport;
@end
NS_ASSUME_NONNULL_END
