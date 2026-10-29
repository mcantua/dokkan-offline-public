#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSUInteger, ODDuoCreatorQuickActionReadiness) {
    ODDuoCreatorEntryWaiting,
    ODDuoCreatorEntryReady,
    ODDuoCreatorEntryAlreadyOpen,
    ODDuoCreatorEntryRejected
};
typedef ODDuoCreatorQuickActionReadiness (^ODDuoCreatorQuickActionAdmission)(
    UIWindow *window, UIViewController *controller, UIView *renderer);
typedef void (^ODDuoCreatorQuickActionInvocation)(void (^completion)(NSError * _Nullable error));

/* Interim native app-icon entry, not final placement inside the source game.
   Configure once on main before UIApplicationMain. No shortcut userInfo, URL,
   page data or filesystem path grants a Creator capability. */
BOOL ODDuoConfigureCreatorQuickAction(BOOL (^contextIsCurrent)(void),
    ODDuoCreatorQuickActionAdmission admission, ODDuoCreatorQuickActionInvocation invoke,
    void (^report)(NSDictionary *state), NSError * _Nullable * _Nullable error);
/* YES means this known native action was accepted/coalesced, not that an editor
   appeared. Final asynchronous outcome is reported separately. Unknown actions
   return NO. Safe for actual UIScene cold and warm shortcut delivery. */
BOOL ODDuoHandleCreatorQuickAction(UIApplicationShortcutItem *item);
/* Call only for the admitted original scene. sourceActive means the actual
   source foreground/active callbacks have completed without a held pause. */
void ODDuoUpdateCreatorQuickAction(UIWindow *window, UIViewController *controller,
    UIView *renderer, BOOL sourceActive);
void ODDuoDisconnectCreatorQuickAction(UIWindow *window);
NS_ASSUME_NONNULL_END
