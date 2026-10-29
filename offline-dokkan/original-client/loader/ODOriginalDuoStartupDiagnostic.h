#import <Foundation/Foundation.h>
@class ODUnifiedDuoHost;

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSUInteger, ODOriginalDuoInputPurpose) {
    ODOriginalDuoInputsDiagnostic,
    ODOriginalDuoInputsIntegrated
};
/** Native-only cold-preparation capabilities from the actual own app bundle/
 * sandbox. No page/request/configuration chooses these paths. Diagnostic and
 * integrated identities/purposes stay distinct. This does not create a Host,
 * Core, account, auth response or native-master acceptance receipt. */
@interface ODOriginalDuoStartupInputs : NSObject
@property(nonatomic,readonly,copy) NSURL *bundleRootURL;
@property(nonatomic,readonly,copy) NSURL *genuineShellBaselineURL;
@property(nonatomic,readonly,copy) NSURL *preparedEngineURL;
@property(nonatomic,readonly,copy) NSURL *resourcesRootURL;
@property(nonatomic,readonly,copy) NSURL *writableStateRootURL;
@property(nonatomic,readonly,copy) NSDictionary *compatibleResourceReport;
/** Actual provenance admission, not a caller flag. True only when this own
 * integrated root already had the exact trusted startup receipt. Native state
 * is preserved and fresh-only candidate staging must be skipped. */
@property(nonatomic,readonly) BOOL knownIntegratedRelaunch;
- (instancetype)init NS_UNAVAILABLE;
@end
/** On main before UIApplicationMain/dlopen, reuse the SAME exact original seed,
 * framework/resource admission and off-main FD publication used by diagnostic.
 * Only org.offlinedokkan.startupdiagnostic.duo / Diagnostic or
 * org.offlinedokkan.duo / Integrated is accepted. Diagnostic is always fresh.
 * Integrated relaunch preserves User/current only with its exact previously
 * published own resource/root provenance. Unknown existing trees reject;
 * neither path reads their contents. Returned capabilities stay native-only. */
FOUNDATION_EXPORT ODOriginalDuoStartupInputs * _Nullable ODPrepareOriginalDuoStartupInputs(
    ODOriginalDuoInputPurpose purpose,NSError * _Nullable * _Nullable error);

/** Native original-client startup only. This factory does not install auth
 * responses, fabricate a player, activate a derived master or enable Creator.
 * The original bundle paths stay intact. The existing FD preloader publishes
 * only the pinned compatible aliases into this app's actual Documents/assets
 * before engine loading. Missing sources fail; an empty directory cannot
 * substitute for verified bytes. Retain/install the result before shell main. */
FOUNDATION_EXPORT ODUnifiedDuoHost * _Nullable ODCreateOriginalDuoStartupDiagnosticHost(
    NSError * _Nullable * _Nullable error);

/** Latest native host report plus the actual post-AppController-launch master
 * capture and a fresh bounded observation at report read, main thread only.
 * Cache presence is not master
 * selection/schema acceptance. No file is written and no request headers,
 * bodies, account identifiers, pointers or network addresses are added. */
FOUNDATION_EXPORT NSDictionary * _Nullable ODCopyOriginalDuoStartupDiagnosticReport(void);
NS_ASSUME_NONNULL_END
