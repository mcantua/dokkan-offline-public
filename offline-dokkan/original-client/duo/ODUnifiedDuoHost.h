#import <Foundation/Foundation.h>
#include <stdint.h>
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
 * original engine, actual Duo scene and same-save Creator services. Construct
 * services on their native IO queue first, then install this owner on main before
 * UIApplicationMain. Startup diagnostic may omit services/routes/attachment;
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
/** NO is a fatal startup result to the plugin caller: do not show the old
 * standalone shell as if it were the unified original game. */
- (BOOL)installBeforeApplicationMain:(NSError * _Nullable * _Nullable)error;
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
@end
NS_ASSUME_NONNULL_END
