#import "ODOriginalCreatorCoordinator.h"
@class ODNativeCore;
NS_ASSUME_NONNULL_BEGIN
/** Concrete single-save issuer. Construct on a native IO queue, then use on
 * main. All URLs/scope come from the SAME host admission/core, never a page.
 * Select scope-keyed overlay/workspace paths after the native core's
 * originalCreatorProjectionAdmissionForProfile:reply: returns its real scope. */
@interface ODBoundOriginalCreatorServices : NSObject <ODOriginalCreatorServices>
- (nullable instancetype)initWithCore:(ODNativeCore *)core masterURL:(NSURL *)master
    masterBytes:(uint64_t)bytes contentID:(NSString *)contentID sourceDatabase:(NSString *)source
    saveURL:(NSURL *)save workspaceURL:(NSURL *)workspace overlayURL:(NSURL *)overlay
    expectedSaveScopeSHA256:(NSString *)scope contextIsCurrent:(BOOL (^)(void))current
    error:(NSError * _Nullable * _Nullable)error NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@property(nonatomic, readonly) ODOriginalCreatorCoordinator *coordinator;
@property(nonatomic, readonly, nullable) NSError *lastBindingError;
/** A failed opening still holds native capabilities when cleanup could not
 * prove a safe release. Main-thread only. This does not grant permission to
 * resume a changed save or clear a faulted original pause. */
@property(nonatomic, readonly) BOOL failedPresentationNeedsRecovery;
/** Exact content id and save scope captured when this issuer was constructed.
 * This is not a filesystem search. */
- (BOOL)matchesAdmittedContentID:(NSString *)contentID saveScopeSHA256:(NSString *)scope;
/** Host-owned per-request policy; defaults denied. Configure only while closed.
 * No browser value grants personal-network access. */
- (BOOL)configureCreatorNetworkAuthorization:(BOOL (^)(NSURL *url))authorization error:(NSError * _Nullable * _Nullable)error;
- (BOOL)attachToOriginalWindow:(UIWindow *)window controller:(UIViewController *)controller
    renderer:(UIView *)renderer error:(NSError * _Nullable * _Nullable)error;
/** Acquire verified original pause, sync the same save's projection and issue
 * its exact native core capability asynchronously before opening the editor. */
- (void)presentCreatorFromUserActionWithCompletion:(void (^)(NSError * _Nullable error))completion;
/** Retry only a retained failure before an editor was attached. Reconciles
 * the same scope, releases its exact Core lease, then asks the verified source
 * pause API to release. An attached editor must use confirmed save/close.
 * A faulted pause without an issued lease remains blocked for controlled native
 * recovery; this method cannot manufacture that missing release authority. */
- (void)recoverFailedPresentationWithCompletion:(void (^)(NSError * _Nullable error))completion;
/** Native host only. Installs full-unit validation for the saved local-player
 * account. Call on main after the editor lease exists. A page cannot pass these
 * URLs. Missing code leaves the full-unit Finish closed. */
- (BOOL)installFullBundleValidationWithCreatorCoreURL:(NSURL *)core
    dependenciesURL:(NSURL *)dependencies error:(NSError * _Nullable * _Nullable)error;
@end
NS_ASSUME_NONNULL_END
