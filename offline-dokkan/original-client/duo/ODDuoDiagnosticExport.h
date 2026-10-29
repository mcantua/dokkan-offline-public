#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
/** Explicit user action only. Shares allowlisted JSON through the system sheet
 * using an in-memory item provider. Does not write a file or upload anything.
 * Completion is delivered once on main after dismissal or rejected presentation. */
FOUNDATION_EXPORT void ODDuoPresentDiagnosticReport(NSDictionary * _Nullable report,
    UIViewController *presenter, UIView *sourceView, dispatch_block_t completion);
NS_ASSUME_NONNULL_END
