#import <UIKit/UIKit.h>
@class ODCreatorSession, ODScopedCreatorTools;

NS_ASSUME_NONNULL_BEGIN
/** Implemented by the SAME trusted native service binding used by original-game
 * transport/master/overlay/save services. Never exposed as a WebView capability.
 * The issuer must pin the master/content, core, local-player save and Creator
 * workspace together while presentation is active; no paths come from a page. */
@protocol ODOriginalCreatorServices <NSObject>
@property(nonatomic, readonly) ODCreatorSession *creatorSession;
@property(nonatomic, readonly, nullable) ODScopedCreatorTools *creatorTools;
- (BOOL)creatorScopeIsCurrent;
/** Enter the verified original-engine pause/save-safe state and hold the binding.
 * Reject if unavailable; do not synthesize an original engine hook. */
- (BOOL)beginCreatorPresentationWithError:(NSError * _Nullable * _Nullable)error;
/** Reconcile/ack the same save's durable Creator projection before dismissal.
 * Failure must retain the service/pause binding and editable controller. */
- (void)prepareCreatorCloseWithCompletion:(void (^)(NSError * _Nullable error))completion;
/** Called only after confirmed save/dismissal, or an opening failure. A false
 * active flag forbids resuming gameplay in a detached/inactive scene. */
- (void)endCreatorPresentationWithActiveScene:(BOOL)active completion:(void (^)(NSError * _Nullable error))completion;
@end

typedef void (^ODOriginalCreatorCloseCompletion)(BOOL saved, NSError * _Nullable error);

/** Presents the actual shared Creator over the admitted original controller.
 * It never replaces the game root, renderer or original input implementation.
 * Retain for the scene/service lifetime, especially across an unconfirmed save. */
@interface ODOriginalCreatorCoordinator : NSObject
- (instancetype)initWithServices:(id<ODOriginalCreatorServices>)services NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@property(nonatomic, readonly) BOOL creatorIsOpen;
@property(nonatomic, readonly, nullable) NSError *lastCloseError;
/** Register once in the original scene-registration glue. Actual foreground
 * callbacks defer while Creator is open; confirmed close releases them only
 * in the still-active admitted scene. No original engine pause is invented. */
- (BOOL)installOriginalSceneLifecycleWithError:(NSError * _Nullable * _Nullable)error;
/** Call from the verified ODDuo scene display callback; admits only its actual
 * RootViewController/CCEAGLView and unchanged root relationship. */
- (BOOL)attachToOriginalWindow:(UIWindow *)window controller:(UIViewController *)controller
                     renderer:(UIView *)renderer error:(NSError * _Nullable * _Nullable)error;
/** Explicit target for a reviewed, user-invoked in-game Creator entry. This API
 * does not choose a menu position, inject a button or open automatically. */
- (BOOL)presentCreatorFromUserActionWithError:(NSError * _Nullable * _Nullable)error;
- (void)requestCloseWithCompletion:(ODOriginalCreatorCloseCompletion)completion;
/** Retry a retained post-dismiss native return failure. The confirmed saved
 * document stays held until reconciliation/lease release succeeds. */
- (void)retryConfirmedReturnWithCompletion:(ODOriginalCreatorCloseCompletion)completion;
/** Initiates asynchronous save/close before native scene teardown. Failure keeps
 * the actual editor/session alive; host must retain/re-attach it. Completion is
 * NOT guaranteed to precede UIKit disconnect and must not be treated as such. */
- (void)prepareForSceneDisconnectionWithCompletion:(ODOriginalCreatorCloseCompletion)completion;
/** Re-layout only the presented editor after actual scene/display changes. */
- (void)refreshCreatorAfterDisplayChange;
@end
NS_ASSUME_NONNULL_END
