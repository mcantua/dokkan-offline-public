// Unit Creator for iPhone: one full-screen web view that runs the Dokkan Unit Creator offline.
// The app's screens and game data are inside the app ("site" folder), served at app://local/.
// Built on Linux with clang + the iPhoneOS SDK (see build-ipa.sh). No storyboard, no asset catalog.
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "Host.h"
#import "Player.h"
#import <sys/utsname.h>
#import <objc/message.h>

static NSString *const kScheme = @"app";
static NSString *const kStartURL = @"app://local/index.html";

// Last screen geometry sent to the page (Host.m's "display" report shows it).
NSDictionary *ForgeDisplayGeometry = nil;

static UIColor *AppBackground(void) {
    return [UIColor colorWithRed:7 / 255.0 green:11 / 255.0 blue:26 / 255.0 alpha:1];
}

#pragma mark - Avoid a retain cycle between the content controller and the view controller

@interface WeakScriptHandler : NSObject <WKScriptMessageHandler>
@property (nonatomic, weak) id<WKScriptMessageHandler> target;
@end

@implementation WeakScriptHandler
- (void)userContentController:(WKUserContentController *)c didReceiveScriptMessage:(WKScriptMessage *)m {
    [self.target userContentController:c didReceiveScriptMessage:m];
}
@end

#pragma mark - The screen

@interface WebViewController : UIViewController <WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler>
@end

@implementation WebViewController {
    WKWebView *_webView;
    ForgeSchemeHandler *_scheme;
    ForgeHost *_host;
    ForgePlayer *_player;
}

- (void)loadView {
    _scheme = [ForgeSchemeHandler new];
    _host = [ForgeHost new];
    WKWebViewConfiguration *config = [WKWebViewConfiguration new];
    [config setURLSchemeHandler:_scheme forURLScheme:kScheme];
    config.websiteDataStore = [WKWebsiteDataStore defaultDataStore];   // keeps saved units between launches
    config.allowsInlineMediaPlayback = YES;
    config.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
    config.preferences.javaScriptCanOpenWindowsAutomatically = NO;
    // "Save file" in the app -> the iPhone's own Save / Share sheet
    WeakScriptHandler *files = [WeakScriptHandler new];
    files.target = self;
    [config.userContentController addScriptMessageHandler:files name:@"ForgeFiles"];
    // files, downloads, secure storage… for the Android features (web/src/ios-native.js)
    [config.userContentController addScriptMessageHandlerWithReply:_host contentWorld:[WKContentWorld pageWorld] name:@"ForgeHost"];

    // Real hardware numbers for the screens' speed settings (Safari hides memory and under-reports
    // processor cores, which would make a top iPhone look like a slow phone and use lite effects).
    NSProcessInfo *pi = [NSProcessInfo processInfo];
    double gb = pi.physicalMemory / 1073741824.0;
    int pow2 = 1; while (pow2 * 2 <= gb && pow2 < 8) pow2 *= 2;   // same rounding as Android's navigator.deviceMemory
    struct utsname un; uname(&un);
    NSString *device = [NSString stringWithFormat:
        @"(function(){var d={memory:%d,memoryGB:%.1f,cores:%lu,maxFps:%ld,machine:%@};window.__forgeNativeDevice=d;"
        "try{Object.defineProperty(Navigator.prototype,'deviceMemory',{get:function(){return d.memory},configurable:true});"
        "Object.defineProperty(Navigator.prototype,'hardwareConcurrency',{get:function(){return d.cores},configurable:true});}catch(e){}})();",
        pow2, gb, (unsigned long)pi.activeProcessorCount, (long)UIScreen.mainScreen.maximumFramesPerSecond,
        [NSString stringWithFormat:@"\"%s\"", un.machine]];
    [config.userContentController addUserScript:[[WKUserScript alloc] initWithSource:device injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES]];

    _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
    _host.webView = _webView;
    _host.presenter = self;
    _webView.navigationDelegate = self;
    _webView.UIDelegate = self;
    _webView.opaque = NO;
    _webView.backgroundColor = AppBackground();
    _webView.scrollView.backgroundColor = AppBackground();
    _webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;  // the page handles the notch itself
    _webView.allowsBackForwardNavigationGestures = NO;
    if (@available(iOS 16.4, *)) _webView.inspectable = YES;
    UIView *root = [[UIView alloc] initWithFrame:CGRectZero];
    root.backgroundColor = AppBackground();
    [root addSubview:_webView];
    self.view = root;
    _player = [[ForgePlayer alloc] initWithMainWebView:_webView controller:self];
    _host.player = _player;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(persist) name:UIApplicationWillResignActiveNotification object:nil];
    [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:kStartURL]]];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [_player layoutInBounds:self.view.bounds safeArea:self.view.safeAreaInsets];
    [self pushGeometry];
}

// Folding / unfolding / rotating: the page stays live (no reload), keeps its place, and the player
// panel moves with the system's own animation.
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [_webView evaluateJavaScript:@"window.__forgeFold&&__forgeFold.begin()" completionHandler:nil];
    __weak WebViewController *weakSelf = self;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> ctx) {
        WebViewController *me = weakSelf; if (!me) return;
        [me->_player layoutInBounds:CGRectMake(0, 0, size.width, size.height) safeArea:me.view.safeAreaInsets];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> ctx) {
        WebViewController *me = weakSelf; if (!me) return;
        [me->_player layoutInBounds:me.view.bounds safeArea:me.view.safeAreaInsets];
        [me pushGeometry];
        // the reserved regions and the page's own layout settle a moment after the fold animation: send and log again
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [weakSelf pushGeometryLogging:YES]; });
        [me->_webView evaluateJavaScript:@"window.__forgeFold&&__forgeFold.end()" completionHandler:nil];
    }];
}

- (void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];
    [_player layoutInBounds:self.view.bounds safeArea:self.view.safeAreaInsets];
    [self pushGeometry];
}

#pragma mark screen edges (iPhone Duo: both displays, every pose)

// The page lays itself out inside the screen's usable area through four CSS variables (--sa-t/r/b/l, see
// web/src/ios.css and docs/IPHONE-DUO-DISPLAY.md). They come from UIKit, not from WebKit's env(): UIKit also knows
// the iPhone Duo "reserved regions" (camera occlusions and the fold) that safe-area insets don't include.
// iOS 27.1 API, looked up at run time because the app is compiled against an older SDK.
static NSArray *ReservedRegions(UIView *v, NSString *kindName) {
    SEL sel = NSSelectorFromString(@"reservedRegionsOfKind:");
    Class kinds = NSClassFromString(@"UIViewReservedRegionKind");
    SEL ks = NSSelectorFromString(kindName);
    if (!kinds || ![v respondsToSelector:sel] || ![kinds respondsToSelector:ks]) return @[];
    @try {
        id kind = ((id (*)(id, SEL))objc_msgSend)(kinds, ks);
        NSArray *list = ((NSArray *(*)(id, SEL, id))objc_msgSend)(v, sel, kind);
        return [list isKindOfClass:[NSArray class]] ? list : @[];
    } @catch (NSException *e) { return @[]; }
}

- (NSDictionary *)geometry {
    UIView *v = self.view;
    CGRect b = v.bounds;
    UIEdgeInsets sa = v.safeAreaInsets, edge = sa;
    NSMutableArray *regions = [NSMutableArray array];
    CGFloat railBottom = 0; NSString *railSide = nil;
    for (NSString *kindName in @[@"occlusionRegionKind", @"divisionRegionKind"]) {
        BOOL occlusion = [kindName hasPrefix:@"occlusion"];
        for (id r in ReservedRegions(v, kindName)) {
            BOOL active = YES; CGRect f = CGRectNull;
            @try { active = [[r valueForKey:@"active"] boolValue]; f = [[r valueForKey:@"frame"] CGRectValue]; } @catch (NSException *e) { continue; }
            if (CGRectIsNull(f) || CGRectIsEmpty(f)) continue;
            [regions addObject:@{ @"kind": occlusion ? @"occlusion" : @"division", @"active": @(active),
                                  @"x": @(f.origin.x), @"y": @(f.origin.y), @"w": @(f.size.width), @"h": @(f.size.height) }];
            if (!active || !occlusion) continue;              // the fold is rendered through; only cameras hide content
            CGRect safeRect = UIEdgeInsetsInsetRect(b, sa);
            CGRect cut = CGRectIntersection(safeRect, f);
            if (CGRectIsNull(cut) || CGRectIsEmpty(cut)) {
                // already outside the safe area: on iPhone Duo this is the status bar / camera column ("rail").
                // Below it the column is free; the page puts its tab bar there (web/src/ios.css .duo-rail).
                BOOL right = sa.right >= 40 && CGRectGetMinX(f) >= b.size.width - sa.right - 1;
                BOOL left = sa.left >= 40 && CGRectGetMaxX(f) <= sa.left + 1;
                if ((right || left) && CGRectGetMaxY(f) > railBottom) { railBottom = CGRectGetMaxY(f); railSide = right ? @"right" : @"left"; }
                continue;
            }
            // a camera inside the safe area near an edge widens that edge by the least amount; one in the middle is left alone
            CGFloat gaps[4] = { CGRectGetMinY(cut), CGRectGetMinX(cut), b.size.height - CGRectGetMaxY(cut), b.size.width - CGRectGetMaxX(cut) };
            CGFloat need[4] = { CGRectGetMaxY(cut) + 4, CGRectGetMaxX(cut) + 4, b.size.height - CGRectGetMinY(cut) + 4, b.size.width - CGRectGetMinX(cut) + 4 };
            int e = -1; for (int i = 0; i < 4; i++) if (gaps[i] <= 48 && (e < 0 || need[i] < need[e])) e = i;
            if (e == 0) edge.top = MAX(edge.top, need[0]);
            if (e == 1) edge.left = MAX(edge.left, need[1]);
            if (e == 2) edge.bottom = MAX(edge.bottom, need[2]);
            if (e == 3) edge.right = MAX(edge.right, need[3]);
        }
    }
    // the page's own web view may sit below the docked animation player: edges are relative to it
    CGRect wf = _webView.hidden ? b : _webView.frame;
    UIEdgeInsets page = UIEdgeInsetsMake(MAX(0, edge.top - CGRectGetMinY(wf)), MAX(0, edge.left - CGRectGetMinX(wf)),
                                         MAX(0, edge.bottom - (b.size.height - CGRectGetMaxY(wf))), MAX(0, edge.right - (b.size.width - CGRectGetMaxX(wf))));
    UIWindowScene *ws = v.window.windowScene;
    UIScreen *sc = ws.screen;
    return @{ @"width": @(b.size.width), @"height": @(b.size.height),
              @"t": @(page.top), @"r": @(page.right), @"b": @(page.bottom), @"l": @(page.left),
              @"edges": @{ @"top": @(edge.top), @"right": @(edge.right), @"bottom": @(edge.bottom), @"left": @(edge.left) },
              @"safe": @{ @"top": @(sa.top), @"right": @(sa.right), @"bottom": @(sa.bottom), @"left": @(sa.left) },
              @"regions": regions,
              @"rail": railSide && CGRectEqualToRect(wf, b) ? @{ @"side": railSide, @"width": @([railSide isEqualToString:@"right"] ? sa.right : sa.left), @"top": @(railBottom) } : @{},
              @"screen": sc ? @{ @"width": @(sc.bounds.size.width), @"height": @(sc.bounds.size.height),
                                 @"nativeWidth": @(sc.nativeBounds.size.width), @"nativeHeight": @(sc.nativeBounds.size.height),
                                 @"scale": @(sc.scale), @"nativeScale": @(sc.nativeScale) } : @{},
              @"displayScale": @(self.traitCollection.displayScale),
              @"sizeClass": [NSString stringWithFormat:@"%ld/%ld", (long)self.traitCollection.horizontalSizeClass, (long)self.traitCollection.verticalSizeClass] };
}

// Sends the usable area to the page and keeps a short log (Library/display-log.jsonl) of every new screen
// shape, with what the page itself measured, for checking the real device (tools/duo-diagnostics on the Mac).
- (void)pushGeometry { [self pushGeometryLogging:NO]; }

- (void)pushGeometryLogging:(BOOL)force {
    if (!_webView || CGRectIsEmpty(self.view.bounds)) return;
    NSDictionary *g = [self geometry];
    ForgeDisplayGeometry = g;
    NSData *json = [NSJSONSerialization dataWithJSONObject:g options:0 error:nil];
    if (!json) return;
    NSString *js = [NSString stringWithFormat:
        @"(function(d){var s=document.documentElement.style;s.setProperty('--sa-t',d.t+'px');s.setProperty('--sa-r',d.r+'px');"
        "s.setProperty('--sa-b',d.b+'px');s.setProperty('--sa-l',d.l+'px');window.__forgeDisplayNative=d;"
        "var c=document.documentElement.classList,r=d.rail||{};c.toggle('duo-rail',!!r.side);c.toggle('duo-rail-left',r.side==='left');"
        "if(r.side){s.setProperty('--rail-w',r.width+'px');s.setProperty('--rail-top',r.top+'px')}"
        "try{window.dispatchEvent(new CustomEvent('forgedisplay',{detail:d}))}catch(e){}"
        "var p=document.createElement('div');p.style.cssText='position:fixed;visibility:hidden;padding:env(safe-area-inset-top) env(safe-area-inset-right) env(safe-area-inset-bottom) env(safe-area-inset-left)';"
        "(document.body||document.documentElement).appendChild(p);var c=getComputedStyle(p),env=[c.paddingTop,c.paddingRight,c.paddingBottom,c.paddingLeft].map(parseFloat);p.remove();"
        "var vv=window.visualViewport;return JSON.stringify({ready:document.readyState,startup:String(window.__forgeWorkspaceStartup),innerWidth:innerWidth,innerHeight:innerHeight,dpr:devicePixelRatio,"
        "visual:vv?[vv.width,vv.height,vv.scale]:null,env:env,pageWidth:document.documentElement.scrollWidth,"
        "clientWidth:document.documentElement.clientWidth})})(%@)",
        [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding]];
    // nothing changed: nothing to do. Layout passes happen often (keyboard, player panel, scrolling bars); restyling
    // the whole page each time made the app lag, so the page only hears about real changes.
    NSString *jsonText = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
    static NSString *lastJSON, *lastKey;
    if (!force && [jsonText isEqualToString:lastJSON]) return;
    lastJSON = jsonText;
    NSString *key = [NSString stringWithFormat:@"%@|%@|%@|%@|%@|%@", g[@"width"], g[@"height"], g[@"t"], g[@"r"], g[@"b"], g[@"l"]];
    BOOL log = force || ![key isEqualToString:lastKey];
    lastKey = key;
    if (!log) {   // just the new edges, no measuring
        NSString *quick = [js substringToIndex:[js rangeOfString:@"var p=document.createElement"].location];
        [_webView evaluateJavaScript:[quick stringByAppendingFormat:@"})(%@)", jsonText] completionHandler:nil];
        return;
    }
    [_webView evaluateJavaScript:js completionHandler:^(id page, NSError *error) {
        if (!log) return;
        NSMutableDictionary *line = [g mutableCopy];
        line[@"time"] = @([[NSDate date] timeIntervalSince1970]);
        line[@"page"] = [page isKindOfClass:[NSString class]] ? [NSJSONSerialization JSONObjectWithData:[page dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil] ?: page : (error.localizedDescription ?: @"");
        NSData *d = [NSJSONSerialization dataWithJSONObject:line options:0 error:nil];
        if (!d) return;
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{   // the log file is written off the main thread
        NSString *lib = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject;
        NSString *path = [lib stringByAppendingPathComponent:@"display-log.jsonl"];
        NSString *old = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil] ?: @"";
        NSArray *lines = [old componentsSeparatedByString:@"\n"];
        if (lines.count > 200) old = [[lines subarrayWithRange:NSMakeRange(lines.count - 150, 150)] componentsJoinedByString:@"\n"];
        old = [old stringByAppendingFormat:@"%@\n", [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding]];
        [old writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
        });
    }];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self pushGeometryLogging:YES];   // a newly loaded page has none of the edges yet
    __weak WebViewController *weakSelf = self;   // once the app has started: a log line with what the page measured
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [weakSelf pushGeometryLogging:YES]; });
}

// Android calls window.forgePersist() when the app goes to the background
- (void)persist {
    [_webView evaluateJavaScript:@"window.forgePersist&&window.forgePersist()" completionHandler:nil];
}

- (UIStatusBarStyle)preferredStatusBarStyle { return UIStatusBarStyleLightContent; }

#pragma mark links

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)action
    decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL *url = action.request.URL;
    NSString *s = url.scheme.lowercaseString;
    if (!url || [s isEqualToString:kScheme] || [s isEqualToString:@"about"] || [s isEqualToString:@"blob"] || [s isEqualToString:@"data"]) {
        decisionHandler(url ? WKNavigationActionPolicyAllow : WKNavigationActionPolicyCancel);
        return;
    }
    // web links (Eclipse site, docs...) open in Safari
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    decisionHandler(WKNavigationActionPolicyCancel);
}

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration
   forNavigationAction:(WKNavigationAction *)action windowFeatures:(WKWindowFeatures *)windowFeatures {
    NSURL *url = action.request.URL;
    if ([url.scheme isEqualToString:@"http"] || [url.scheme isEqualToString:@"https"])
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    return nil;
}

// If iOS drops the page from memory, bring it back instead of a blank screen.
- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:kStartURL]]];
}

#pragma mark alerts from the page

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message
    initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))done {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) { done(); }]];
    [self presentViewController:a animated:YES completion:nil];
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message
    initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))done {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *x) { done(NO); }]];
    [a addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) { done(YES); }]];
    [self presentViewController:a animated:YES completion:nil];
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText
    initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString *))done {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:nil message:prompt preferredStyle:UIAlertControllerStyleAlert];
    [a addTextFieldWithConfigurationHandler:^(UITextField *f) { f.text = defaultText; }];
    __weak UIAlertController *weakA = a;
    [a addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *x) { done(nil); }]];
    [a addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) { done(weakA.textFields.firstObject.text); }]];
    [self presentViewController:a animated:YES completion:nil];
}

#pragma mark saving files (.eclp, .json...)

- (void)userContentController:(WKUserContentController *)controller didReceiveScriptMessage:(WKScriptMessage *)message {
    if (![message.name isEqualToString:@"ForgeFiles"] || ![message.body isKindOfClass:[NSDictionary class]]) return;
    NSDictionary *body = message.body;
    NSString *fileId = [body[@"id"] isKindOfClass:[NSString class]] ? body[@"id"] : nil;
    NSString *b64 = [body[@"base64"] isKindOfClass:[NSString class]] ? body[@"base64"] : nil;
    NSString *name = [body[@"name"] isKindOfClass:[NSString class]] ? body[@"name"] : @"unit.eclp";
    if (!fileId || !b64) return;
    NSData *data = [[NSData alloc] initWithBase64EncodedString:b64 options:NSDataBase64DecodingIgnoreUnknownCharacters];
    if (!data) { [self finish:fileId saved:NO]; return; }
    name = [[name stringByReplacingOccurrencesOfString:@"/" withString:@"_"] stringByReplacingOccurrencesOfString:@":" withString:@"_"];
    if (!name.length) name = @"unit.eclp";

    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *folder = [NSTemporaryDirectory() stringByAppendingPathComponent:@"exports"];
    [fm removeItemAtPath:folder error:nil];                         // keep only the newest export
    [fm createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *path = [folder stringByAppendingPathComponent:name];
    if (![data writeToFile:path atomically:YES]) { [self finish:fileId saved:NO]; return; }

    UIActivityViewController *sheet = [[UIActivityViewController alloc] initWithActivityItems:@[[NSURL fileURLWithPath:path]] applicationActivities:nil];
    __weak WebViewController *weakSelf = self;
    __block BOOL replied = NO;   // iOS can call this twice
    sheet.completionWithItemsHandler = ^(UIActivityType type, BOOL completed, NSArray *items, NSError *error) {
        if (replied) return;
        replied = YES;
        [weakSelf finish:fileId saved:completed];
    };
    UIPopoverPresentationController *pop = sheet.popoverPresentationController;   // iPad / unfolded screens
    if (pop) {
        pop.sourceView = self.view;
        pop.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds), 1, 1);
        pop.permittedArrowDirections = 0;
    }
    UIViewController *top = self;
    while (top.presentedViewController) top = top.presentedViewController;
    [top presentViewController:sheet animated:YES completion:nil];
}

- (void)finish:(NSString *)fileId saved:(BOOL)saved {
    NSData *json = [NSJSONSerialization dataWithJSONObject:@{@"id": fileId, @"saved": @(saved)} options:0 error:nil];
    NSString *detail = json ? [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding] : @"{}";
    NSString *js = [NSString stringWithFormat:@"dispatchEvent(new CustomEvent('forge-file-saved',{detail:%@}))", detail];
    [_webView evaluateJavaScript:js completionHandler:nil];
}
@end

#pragma mark - App + scene

@interface SceneDelegate : UIResponder <UIWindowSceneDelegate>
@property (nonatomic, strong) UIWindow *window;
@end

@implementation SceneDelegate
- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)options {
    if (![scene isKindOfClass:[UIWindowScene class]]) return;
    UIWindow *window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    window.backgroundColor = AppBackground();
    window.rootViewController = [WebViewController new];
    [window makeKeyAndVisible];
    self.window = window;
}

// The screen this window is on changed (e.g. moved between the outer and inner display): lay out again.
- (void)windowScene:(UIWindowScene *)windowScene didUpdateCoordinateSpace:(id<UICoordinateSpace>)previousCoordinateSpace
    interfaceOrientation:(UIInterfaceOrientation)previousInterfaceOrientation traitCollection:(UITraitCollection *)previousTraitCollection {
    [self.window.rootViewController.view setNeedsLayout];
    [self.window.rootViewController.view layoutIfNeeded];
}
@end

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions { return YES; }

- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)session
                              options:(UISceneConnectionOptions *)options {
    UISceneConfiguration *config = [[UISceneConfiguration alloc] initWithName:@"Default" sessionRole:session.role];
    config.delegateClass = [SceneDelegate class];
    return config;
}
@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
