// The animation player (Eclipse's web player) for the Unit Creator on iPhone.
// Same design as the Android app: a private web server on 127.0.0.1 answers every request of the
// player page, and the player shows in a panel over the app (docked or full screen).
// The answers themselves are computed by the app's own code (web/src/ios-preview.js) in the main
// web view; this side only moves bytes, shows views and takes snapshots.
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ForgePlayer : NSObject
@property (nonatomic, weak, nullable) WKWebView *mainWebView;
@property (nonatomic, weak, nullable) UIViewController *controller;
@property (nonatomic, readonly) uint16_t port;
- (instancetype)initWithMainWebView:(WKWebView *)web controller:(UIViewController *)controller;
/// ForgeHost ops starting with "player…" / "server…"
- (void)handle:(NSString *)op message:(NSDictionary *)m reply:(void (^)(id _Nullable, NSString *_Nullable))reply;
- (void)layoutInBounds:(CGRect)bounds safeArea:(UIEdgeInsets)insets;
@end

NS_ASSUME_NONNULL_END
