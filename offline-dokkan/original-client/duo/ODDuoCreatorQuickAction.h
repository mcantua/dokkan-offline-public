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

/* Reviewed in-game Creator menu entry. Delivery is the system app-icon
   shortcut because no original menu callback ABI is verified. Configure once
   on main before UIApplicationMain. No shortcut userInfo, URL, page data or
   filesystem path grants a Creator capability. */
BOOL ODDuoConfigureCreatorQuickAction(BOOL (^contextIsCurrent)(void),
    ODDuoCreatorQuickActionAdmission admission, ODDuoCreatorQuickActionInvocation invoke,
    void (^report)(NSDictionary *state), NSError * _Nullable * _Nullable error);
/* Manual native practice entry. Uses the same original-scene delivery and
   readiness checks; configuring it never starts a battle automatically. */
BOOL ODDuoConfigurePracticeQuickAction(BOOL (^contextIsCurrent)(void),
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
/* Re-check a queued shortcut after late service binding. Does not block. */
void ODDuoRefreshQueuedCreatorQuickAction(void);
NS_ASSUME_NONNULL_END
