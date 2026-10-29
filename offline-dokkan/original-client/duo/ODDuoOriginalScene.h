#import "ODDuoDisplayBridge.h"

NS_ASSUME_NONNULL_BEGIN
typedef void (^ODDuoSceneDisplayHandler)(UIViewController *originalController,
                                        UIView *originalRenderer,
                                        ODDuoDisplaySnapshot *snapshot);
typedef void (^ODDuoSceneErrorHandler)(NSError *error);
typedef id _Nullable (^ODDuoOriginalAppControllerProvider)(void);
typedef NS_ENUM(NSUInteger, ODDuoSceneEvent) {
    ODDuoSceneWillResignActive,
    ODDuoSceneDidEnterBackground,
    ODDuoSceneWillEnterForeground,
    ODDuoSceneDidBecomeActive,
    ODDuoSceneWillDisconnect
};
/* Return NO on foreground/active events to withhold the corresponding source
   lifecycle callback while a native-owned Creator save/close is pending.
   Other events are notifications; their return value is ignored. */
typedef BOOL (^ODDuoSceneLifecycleHandler)(ODDuoSceneEvent event, UIWindow *window,
                                           UIViewController *originalController,
                                           UIView *originalRenderer);

/* A genuine SDK27.1 shell may keep its own UIApplication delegate. Supply the
   separately retained, actually launched original AppController through this
   provider; the provider is evaluated only when connecting a scene. The host
   must retain that object for the original engine's lifetime, across disconnect.
   No methods or ivars are copied onto the shell delegate. Main-thread only. */
BOOL ODDuoSetOriginalAppControllerProvider(ODDuoOriginalAppControllerProvider provider,
                                            NSError * _Nullable * _Nullable error);

/* Invoke after loading the admitted original image, before UIApplicationMain.
   The genuine SDK27.1 host's scene configuration must select
   ODDuoOriginalSceneDelegate and disable multiple scenes. No source SDK-field
   modification substitutes for that host. The original AppController performs
   its own launch/engine setup, directly or through the admitted shell plugin. */
BOOL ODDuoConfigureOriginalSceneBridge(ODDuoSceneDisplayHandler displayHandler,
                                       ODDuoSceneErrorHandler errorHandler,
                                       NSError * _Nullable * _Nullable error);
BOOL ODDuoObserveOriginalSceneLifecycle(ODDuoSceneLifecycleHandler handler,
                                          NSError * _Nullable * _Nullable error);
/* Host calls only after its deferred native save/close has actually succeeded.
   Does not bypass a background/disconnected scene or pause a foreground game
   merely because Creator was presented. */
BOOL ODDuoResumeOriginalSceneGame(NSError * _Nullable * _Nullable error);

/* Native-only lease for the reviewed source background/foreground pause path.
   Issuance also checks the actual source-version state; an already internally
   paused/stopped Director is rejected rather than unconditionally resumed.
   A held or faulted lease never auto-resumes when its caller releases references. */
@interface ODDuoOriginalGamePauseLease : NSObject
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
@end
ODDuoOriginalGamePauseLease * _Nullable ODDuoBeginCreatorPause(
    UIWindow *window, UIViewController *controller, UIView *renderer,
    NSError * _Nullable * _Nullable error);
/* Call only after the same native save/projection is committed/reconciled.
   allowResume is permission, not a substitute for current scene/scope checks.
   Inactive/disconnected release keeps the source stopped until a valid future
   foreground. Failure retains the lease and forbids resume. */
BOOL ODDuoEndCreatorPause(ODDuoOriginalGamePauseLease *lease, BOOL allowResume,
                           NSError * _Nullable * _Nullable error);

@interface ODDuoOriginalSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, strong, nullable) UIWindow *window;
@end
NS_ASSUME_NONNULL_END
