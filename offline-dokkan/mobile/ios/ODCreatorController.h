#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
@class ODCreatorSession, ODScopedCreatorTools;
NS_ASSUME_NONNULL_BEGIN
/** The real shared Creator inside our own Offline app; no original-game hooks. */
@interface ODCreatorController : UIViewController
@property(nonatomic, readonly) WKWebView *webView;
/** Native-issued same-save tools, set before the view is loaded. */
@property(nonatomic, strong, nullable) ODScopedCreatorTools *scopedTools;
/** Trusted native integration only. Called after confirmed flushSave and before
 * dismissal. A failure keeps the actual editable document open; no page can
 * choose this callback or the native projection/save context. */
@property(nonatomic, copy, nullable) void (^closePreparation)(void (^completion)(NSError * _Nullable error));
- (instancetype)initWithSession:(ODCreatorSession *)session completion:(void (^)(void))completion;
- (void)closeCreator;
@end
NS_ASSUME_NONNULL_END
