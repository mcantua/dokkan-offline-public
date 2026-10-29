#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
/* Authored controls over the one admitted original scene. No second renderer,
 * window, controller, menu ABI or game capability is created here. All actions
 * return to the configured native owner for a fresh admission check. Main only. */
void ODDuoUpdateInGameActions(UIWindow *window, UIViewController *controller, UIView *renderer,
    BOOL foreground, BOOL creatorVisible, BOOL creatorEnabled,
    BOOL practiceVisible, BOOL practiceEnabled, BOOL practiceRetrySave, BOOL diagnosticVisible,
    dispatch_block_t creatorAction, dispatch_block_t practiceAction,
    void (^diagnosticAction)(UIView *sourceView));
void ODDuoRemoveInGameActions(UIWindow *window);
/* Value-only attachment evidence; no renderer pointers, paths or save fields. */
NSDictionary *ODDuoCopyInGameActionState(void);
NS_ASSUME_NONNULL_END
