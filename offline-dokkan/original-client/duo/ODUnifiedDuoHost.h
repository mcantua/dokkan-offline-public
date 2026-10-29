#import <Foundation/Foundation.h>
#include <stdint.h>
#import "ODDuoOriginalScene.h"
#import "../ios/ODLocalURLProtocol.h"
@class ODBoundOriginalCreatorServices, ODNativeMasterColdStage, ODDeferredOriginalPlayerAdmission;
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
/** Integrated targets pass empty approvedOrigins: local transport starts
 * deny-all and can be armed once only from the admitted loaded engine's own
 * current native-origin capability before AppDelegate requests. */
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
 * redirected. This detached tool does NOT satisfy original-client integrated
 * startup: its readonly plaintext file is not native opaque-key admission. */
- (BOOL)stagePlaintextDerivedMasterAtURL:(NSURL *)derived byteCount:(uint64_t)bytes
    contentSHA256:(NSString *)sha256 language:(NSString *)language
    error:(NSError * _Nullable * _Nullable)error;
/** Adopt an independently cold-staged disposable opaque working copy on main
 * before install. Its actual own Documents/assets root must match this host's
 * resources root. This records preparation only; native language/prefix,
 * original key/open/schema acceptance remain unobserved and game-data serving
 * stays closed. Original startup/auth/UI may run to collect real evidence.
 * No arbitrary native acceptance boolean/callback is exposed. */
- (BOOL)adoptColdStagedOriginalMaster:(ODNativeMasterColdStage *)stage
    error:(NSError * _Nullable * _Nullable)error;
/** Integrated startup may reach UIApplicationMain before the async core
 * profile/scope reply. Record that reply's exact content id and save scope,
 * then pass the services built from it to bindCreatorServicesWhenReady:. */
- (BOOL)expectDeferredCreatorServicesForContentID:(NSString *)contentID
    saveScopeSHA256:(NSString *)scope error:(NSError * _Nullable * _Nullable)error;
/** Capture the exact canonical Core capability before its actual scope is
 * known. No scope is guessed and no main-thread preparation wait occurs. */
- (BOOL)expectDeferredCreatorServicesForPlayerAdmission:(ODDeferredOriginalPlayerAdmission *)player
    error:(NSError * _Nullable * _Nullable)error;
/** Schedule once on main, including before UIApplicationMain. Native IO
 * returns its real receipt later on main. The caller can then construct
 * same-Core services on IO and bind them through the existing service method.
 * This neither replaces original UI nor opens master/runtime acceptance. */
- (void)prepareDeferredPlayerAdmissionOnQueue:(dispatch_queue_t)queue
    completion:(void (^)(NSError * _Nullable error))completion;
/** Configure internal auth while the captured Core waits for its actual scope.
 * Pending requests issue no token until admission and same-Core services bind.
 * Main only, before install; expiresIn remains explicit offline policy. */
- (BOOL)configureOfflineAuthForDeferredPlayerWithExpiresIn:(int32_t)expiresIn
    error:(NSError * _Nullable * _Nullable)error;
/** Integrated target only, on main before install. Builds the proved local
 * ping/nonce/sign-in routes internally; caller-supplied auth routes remain
 * refused. Identity must match already bound services or their exact deferred
 * admission. Every request obtains the bound issuer's own canonical Core and
 * verifies the local-player/content/save scope asynchronously. expiresIn is
 * explicit offline policy, not a recovered server lifetime. No token is saved.
 * Actual native login remains unverified. Diagnostic behavior is unchanged. */
- (BOOL)configureOfflineAuthForContentID:(NSString *)contentID
    saveScopeSHA256:(NSString *)scope expiresIn:(int32_t)expiresIn
    error:(NSError * _Nullable * _Nullable)error;
/** NO is a fatal startup result to the plugin caller: do not show the old
 * standalone shell as if it were the unified original game. */
- (BOOL)installBeforeApplicationMain:(NSError * _Nullable * _Nullable)error;
/** Main-thread binding after UIApplicationMain. A call from another queue is
 * queued; this method does not wait. A required scene attachment failure is
 * returned without consuming the pending admission, so the same service can
 * retry. The services must match the content id
 * and save scope recorded before install. */
- (void)bindCreatorServicesWhenReady:(ODBoundOriginalCreatorServices *)services
    completion:(void (^)(NSError * _Nullable error))completion;
/** Explicit target for a reviewed native in-game user action. This does not
 * invent/inject a game menu position or automatically open the editor. */
- (void)presentCreatorFromUserActionWithCompletion:(void (^)(NSError * _Nullable error))completion;
/** Reader-relative local auth candidate. The host does not retain the token,
 * write it, or install GET /auth/nonce or POST /auth/sign_in. expiresIn is the
 * caller's signed32 second count, not a recovered server duration. */
- (nullable NSDictionary *)issueOfflineAuthEnvelopeWithNativeTime:(int32_t)nativeTime
                                                        expiresIn:(int32_t)expiresIn
                                                            error:(NSError * _Nullable * _Nullable)error;
/** Omits tutorial and card/support capacities. Rejects pre-server sentinels.
 * Does not copy played-cache values or invent starting stats. */
- (nullable NSDictionary *)freshStatePolicyForSnapshot:(NSDictionary *)snapshot
                                      proposedSections:(nullable NSDictionary *)proposed
                                                 error:(NSError * _Nullable * _Nullable)error;
/* Reports/updates are delivered on main. Unsupported Foundation requests are
   bounded to64 reviewed method/path pairs; dynamic IDs are already redacted by
   the transport. No origin, query, headers, body or raw-socket observation is
   included. Reading startupReport is also main-thread only. */
@property(nonatomic,readonly,copy) NSDictionary *startupReport;
/** Main-only game-data/mutation gate, distinct from original image/auth/UI
 * startup. A cached handle or caller-supplied boolean cannot open this gate. */
@property(nonatomic,readonly) BOOL originalGameDataAdmitted;
@end
NS_ASSUME_NONNULL_END
