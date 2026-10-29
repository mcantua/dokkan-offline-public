// Native services for the Unit Creator screens on iPhone (see Host.m and web/src/ios-host.js).
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Serves app://local/…
///   /…                 the bundled app ("site" folder)
///   /__net?u=URL       any web address, fetched natively (no browser cross-site limits), streamed
///   /__file/PATH       the app's own storage: GET (with Range), HEAD, PUT (write body), DELETE
///   /__mirror/HOST/P   a saved copy of https://HOST/P (downloaded and saved on first use)
@interface ForgeSchemeHandler : NSObject <WKURLSchemeHandler>
@end

/// window.webkit.messageHandlers.ForgeHost.postMessage({op, …}) → Promise (files, downloads, keychain…)
@interface ForgeHost : NSObject <WKScriptMessageHandlerWithReply>
@property (nonatomic, weak, nullable) WKWebView *webView;
@property (nonatomic, weak, nullable) UIViewController *presenter;
@property (nonatomic, strong, nullable) id player;   // ForgePlayer: ops starting with "player"/"server"/"saveDocument"
+ (NSString *)storageRoot;
+ (nullable NSString *)resolve:(NSString *)relative;   // nil if the path leaves storage
@end

NS_ASSUME_NONNULL_END
