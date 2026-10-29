#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

static UIWindow *UCWindow(void) {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes)
        if ([scene isKindOfClass:UIWindowScene.class])
            for (UIWindow *window in ((UIWindowScene *)scene).windows)
                if (window.isKeyWindow) return window;
    return nil;
}
static WKWebView *UCWeb(UIView *view) {
    if ([view isKindOfClass:WKWebView.class]) return (id)view;
    for (UIView *child in view.subviews) { WKWebView *web = UCWeb(child); if (web) return web; }
    return nil;
}
static void UCTick(void) { [NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]]; }

@interface UCFileNavigation : NSObject <WKNavigationDelegate>
@property(nonatomic) BOOL complete;
@property(nonatomic, strong) NSError *failure;
@end
@implementation UCFileNavigation
- (void)webView:(WKWebView *)web didFinishNavigation:(WKNavigation *)navigation { self.complete = YES; }
- (void)webView:(WKWebView *)web didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error { self.failure = error; self.complete = YES; }
- (void)webView:(WKWebView *)web didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error { self.failure = error; self.complete = YES; }
@end

@interface UnitCreatorCloudTests : XCTestCase
@end
@implementation UnitCreatorCloudTests
- (void)checkStandaloneFileInWindow:(UIWindow *)window library:(NSString *)library {
    NSURL *file = [[NSBundle bundleForClass:self.class] URLForResource:@"UnitCreator-test" withExtension:@"html"];
    XCTAssertNotNil(file); if (!file) return;
    WKWebViewConfiguration *config = [WKWebViewConfiguration new];
    config.websiteDataStore = [WKWebsiteDataStore nonPersistentDataStore];
    __block WKContentRuleList *rules; __block NSError *ruleError; __block BOOL compiled = NO;
    [WKContentRuleListStore.defaultStore compileContentRuleListForIdentifier:@"UnitCreatorFileCheckNoHTTP" encodedContentRuleList:@"[{\"trigger\":{\"url-filter\":\"^https?://\"},\"action\":{\"type\":\"block\"}}]" completionHandler:^(WKContentRuleList *value, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{ rules = value; ruleError = error; compiled = YES; });
    }];
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:20]; while (!compiled && deadline.timeIntervalSinceNow > 0) UCTick();
    XCTAssertTrue(compiled); XCTAssertNil(ruleError); XCTAssertNotNil(rules); if (!rules) return;
    [config.userContentController addContentRuleList:rules];
    WKWebView *fileView = [[WKWebView alloc] initWithFrame:window.bounds configuration:config];
    UCFileNavigation *navigation = [UCFileNavigation new];
    fileView.navigationDelegate = navigation;
    [window addSubview:fileView];
    // Exact-file read access: no adjacent UI/resource folder is granted. HTTP(S) is blocked above.
    [fileView loadFileURL:file allowingReadAccessToURL:file];
    deadline = [NSDate dateWithTimeIntervalSinceNow:120];
    while (!navigation.complete && deadline.timeIntervalSinceNow > 0) UCTick();
    XCTAssertTrue(navigation.complete, @"The actual standalone file navigation must finish");
    XCTAssertNil(navigation.failure);
    if (!navigation.complete || navigation.failure) { [fileView stopLoading]; [fileView removeFromSuperview]; return; }
    NSString *startup; deadline = [NSDate dateWithTimeIntervalSinceNow:120];
    do { startup = [self runJS:@"return String(window.__forgeWorkspaceStartup);" web:fileView]; if ([startup isEqual:@"ready"]) break; UCTick(); } while (deadline.timeIntervalSinceNow > 0);
    XCTAssertEqualObjects(startup, @"ready");
    if ([startup isEqual:@"ready"]) {
        NSDictionary *result = [self runJS:@"await document.fonts.ready;await new Promise(r=>requestAnimationFrame(()=>requestAnimationFrame(r)));const b=document.getElementById('db-quick'),r=b&&b.getBoundingClientRect(),info=await Native.call('info'),spark=await Native.call('sparkingInfo');return {startup:window.__forgeWorkspaceStartup,scheme:location.protocol,homeVisible:!!(r&&r.width>0&&r.height>0&&r.top<innerHeight&&r.bottom>0),nativeBridgeInjected:!!window.ForgeHost,eclipse:info.count,sparking:spark.count,innerWidth:innerWidth,pageWidth:document.documentElement.scrollWidth};" web:fileView];
        XCTAssertEqualObjects(result[@"scheme"], @"file:"); XCTAssertTrue([result[@"homeVisible"] boolValue]);
        XCTAssertFalse([result[@"nativeBridgeInjected"] boolValue]);
        XCTAssertGreaterThan([result[@"eclipse"] integerValue], 1000); XCTAssertGreaterThan([result[@"sparking"] integerValue], 1000);
        XCTAssertLessThanOrEqual([result[@"pageWidth"] doubleValue], [result[@"innerWidth"] doubleValue] + 1);
        NSDictionary *compatibility = [self runJS:@"return await window.__forgeWeb.movies.compatibility.check();" web:fileView];
        XCTAssertTrue([compatibility[@"ready"] boolValue], @"The actual classic worker and bundled WASM must initialize at file://");
        XCTAssertTrue([compatibility[@"version"] isKindOfClass:NSString.class] && [compatibility[@"version"] length] > 0);
        XCTAssertTrue([compatibility[@"vp9"] boolValue]); XCTAssertTrue([compatibility[@"hca"] boolValue]);
        NSMutableDictionary *report = [result mutableCopy];
        report[@"movie_worker_wasm"] = compatibility ?: @{};
        report[@"scope"] = @"Actual self-contained HTML loaded by WebKit fileURL, exact-file read scope and all HTTP(S) blocked; not Safari/Quicklook UI or physical phone proof";
        report[@"network_blocked"] = @YES;
        XCTAssertTrue([[NSJSONSerialization dataWithJSONObject:report options:NSJSONWritingPrettyPrinted error:nil] writeToFile:[library stringByAppendingPathComponent:@"standalone-file-check.json"] atomically:YES]);
        WKSnapshotConfiguration *snapshot = [WKSnapshotConfiguration new]; snapshot.afterScreenUpdates = YES; snapshot.rect = fileView.bounds;
        __block UIImage *image; __block NSError *snapshotError; __block BOOL captured = NO;
        [fileView takeSnapshotWithConfiguration:snapshot completionHandler:^(UIImage *value, NSError *error) { image = value; snapshotError = error; captured = YES; }];
        deadline = [NSDate dateWithTimeIntervalSinceNow:30]; while (!captured && deadline.timeIntervalSinceNow > 0) UCTick();
        XCTAssertTrue(captured); XCTAssertNil(snapshotError); XCTAssertNotNil(image);
        if (image) XCTAssertTrue([UIImagePNGRepresentation(image) writeToFile:[library stringByAppendingPathComponent:@"standalone-file.png"] atomically:YES]);
    }
    [fileView stopLoading]; [fileView removeFromSuperview];
}
- (id)runJS:(NSString *)body web:(WKWebView *)web {
    __block BOOL done = NO;
    __block id answer;
    __block NSError *failure;
    [web callAsyncJavaScript:body arguments:@{} inFrame:nil inContentWorld:WKContentWorld.pageWorld completionHandler:^(id result, NSError *error) {
        answer = result; failure = error; done = YES;
    }];
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:90];
    while (!done && deadline.timeIntervalSinceNow > 0) UCTick();
    XCTAssertTrue(done, @"Native WKWebView JavaScript operation timed out");
    XCTAssertNil(failure, @"Native WKWebView operation failed: %@", failure);
    return answer;
}
- (void)testProductionNativeStartupGeometryAndBothDatabaseBridges {
    void (^check)(void) = ^{
        NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:20];
        UIWindow *window = UCWindow();
        while (!window && deadline.timeIntervalSinceNow > 0) { UCTick(); window = UCWindow(); }
        XCTAssertNotNil(window); if (!window) return;
        WKWebView *web = UCWeb(window.rootViewController.view);
        XCTAssertNotNil(web); if (!web) return;
        // No fixture, login bypass, browser adapter substitution or forced view dimensions.
        deadline = [NSDate dateWithTimeIntervalSinceNow:120];
        NSString *startup;
        do {
            startup = [self runJS:@"return String(window.__forgeWorkspaceStartup);" web:web];
            if ([startup isEqual:@"ready"]) break;
            UCTick();
        } while (deadline.timeIntervalSinceNow > 0);
        XCTAssertEqualObjects(startup, @"ready"); if (![startup isEqual:@"ready"]) return;
        NSDictionary *home = [self runJS:@"await document.fonts.ready;await new Promise(r=>requestAnimationFrame(()=>requestAnimationFrame(r)));const b=document.getElementById('db-quick')||document.querySelector('#main [data-action=\"new\"]'),q=b&&b.getBoundingClientRect();return {visible:!!(q&&q.width>0&&q.height>0&&q.bottom>0&&q.top<innerHeight),placeholder:!!document.querySelector('#main .initial-loading'),heading:document.querySelector('#main h1')?.textContent||b?.textContent||''};" web:web];
        XCTAssertTrue([home[@"visible"] boolValue], @"Home Create button must be laid out in the actual viewport");
        XCTAssertFalse([home[@"placeholder"] boolValue]);
        XCTAssertTrue([home[@"heading"] length] > 0);
        NSDictionary *geometry = [self runJS:@"return {startup:window.__forgeWorkspaceStartup,ios:!!window.forgeNative.ios,bridge:!!window.ForgeHost,innerWidth:innerWidth,innerHeight:innerHeight,pageWidth:document.documentElement.scrollWidth,screenWidth:screen.width,screenHeight:screen.height,bodyReady:!!document.querySelector('#main')&&!document.querySelector('#main .initial-loading')};" web:web];
        XCTAssertTrue([geometry[@"ios"] boolValue]); XCTAssertTrue([geometry[@"bridge"] boolValue]);
        XCTAssertTrue([geometry[@"bodyReady"] boolValue]);
        XCTAssertGreaterThan([geometry[@"innerWidth"] doubleValue], 0);
        XCTAssertEqualWithAccuracy([geometry[@"innerWidth"] doubleValue], window.bounds.size.width, 1);
        XCTAssertLessThanOrEqual([geometry[@"pageWidth"] doubleValue], [geometry[@"innerWidth"] doubleValue] + 1);
        NSString *meta = [NSBundle.mainBundle pathForResource:@"cloud-data-provenance" ofType:@"json"];
        NSDictionary *expected = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:meta] options:0 error:nil];
        XCTAssertNotNil(expected);
        NSMutableDictionary *counts = [NSMutableDictionary dictionary];
        for (NSArray *item in @[@[@"eclipse", @"db/reference.db"], @[@"sparking", @"db/sparking-reference.db"]]) {
            NSString *body = [NSString stringWithFormat:@"const r=await ForgeHost.call('sql',{db:'%@',sql:'SELECT count(*) FROM cards',params:[]});return r.rows[0][0];", item[1]];
            NSNumber *count = [self runJS:body web:web];
            XCTAssertEqualObjects(count, expected[item[0]][@"cards"]);
            XCTAssertGreaterThan(count.integerValue, 1000);
            counts[item[0]] = count ?: @0;
        }
        // One real native safe-file round trip; remove only this check's own file.
        NSNumber *roundtrip = [self runJS:@"const p='cloud-native-check.json';await ForgeHost.writeJson(p,{source:'hosted-native-check',value:128});const r=await ForgeHost.readJson(p);await ForgeHost.remove(p);return r.value;" web:web];
        XCTAssertEqualObjects(roundtrip, @128);
        NSDictionary *crypto = [self runJS:@"const Original=window.Worker;let created=0,replies=0,errors=0;class ObservedWorker extends Original{constructor(...args){super(...args);created++;this.addEventListener('message',e=>{if(e.data&&e.data.key)replies++});this.addEventListener('error',()=>errors++)}}window.Worker=ObservedWorker;try{const e=new TextEncoder(),files=[{path:'metadata.json',bytes:e.encode(JSON.stringify({uuid:'cloud-native-format-check',name:'Native format check',version:1}))},{path:'settings/native-check.json',bytes:e.encode('{\"value\":128}') }],bytes=await ForgeEclp.write(files,{deriveKey:__forgeIOS.deriveKey}),r=await ForgeEclp.read(bytes,{deriveKey:__forgeIOS.deriveKey,maxBytes:1048576,maxFiles:4});return {same:files.every(f=>{const x=r.entries.find(a=>a.path===f.path);return x&&x.bytes.length===f.bytes.length&&x.bytes.every((v,i)=>v===f.bytes[i])}),archiveBytes:bytes.length,workerCreated:created,workerKeyReplies:replies,workerErrors:errors,subtle:!!crypto.subtle,origin:location.origin};}finally{window.Worker=Original}" web:web];
        XCTAssertTrue([crypto[@"same"] boolValue], @"Production ECLP Argon2/AES-GCM/zstd must round-trip bytes at app://");
        XCTAssertEqual([crypto[@"workerCreated"] integerValue], 2);
        XCTAssertEqual([crypto[@"workerKeyReplies"] integerValue], 2, @"Both actual Argon2 workers must finish, without synchronous fallback");
        XCTAssertEqual([crypto[@"workerErrors"] integerValue], 0);
        NSDictionary *codecs = [self runJS:@"const c={codec:'vp09.00.10.08',codedWidth:320,codedHeight:180};let decoder=false,encoder=false;try{decoder=!!window.VideoDecoder&&(await VideoDecoder.isConfigSupported(c)).supported}catch{}try{encoder=!!window.VideoEncoder&&(await VideoEncoder.isConfigSupported({codec:c.codec,width:320,height:180,bitrate:500000,framerate:30})).supported}catch{}return {vp9Decoder:decoder,vp9Encoder:encoder};" web:web];
        NSMutableDictionary *report = [@{@"scope":@"Actual production UIKit/WKWebView sources and native SQL/file bridge on hosted iOS simulator",
            @"geometry":geometry ?: @{}, @"home_content":home ?: @{}, @"native_card_counts":counts,
            @"native_file_roundtrip":@([roundtrip isEqual:@128]),
            @"eclp_production_roundtrip":crypto ?: @{}, @"codec_capabilities":codecs ?: @{},
            @"windowWidth":@(window.bounds.size.width), @"windowHeight":@(window.bounds.size.height),
            @"not_verified":@[@"Physical folding and reserved regions", @"Touch/keyboard interaction", @"Signing or device installation", @"Original database byte fidelity", @"Game import/export/encryption"]} mutableCopy];
        NSString *library = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject;
        NSData *json = [NSJSONSerialization dataWithJSONObject:report options:NSJSONWritingPrettyPrinted error:nil];
        XCTAssertTrue([json writeToFile:[library stringByAppendingPathComponent:@"cloud-native-check.json"] atomically:YES]);
        // WKWebView draws in a separate compositor; UIKit hierarchy snapshots can show old launch tiles.
        WKSnapshotConfiguration *configuration = [WKSnapshotConfiguration new]; configuration.afterScreenUpdates = YES;
        configuration.rect = web.bounds;
        __block UIImage *webImage; __block NSError *snapshotError; __block BOOL captured = NO;
        [web takeSnapshotWithConfiguration:configuration completionHandler:^(UIImage *image, NSError *error) { webImage = image; snapshotError = error; captured = YES; }];
        deadline = [NSDate dateWithTimeIntervalSinceNow:30]; while (!captured && deadline.timeIntervalSinceNow > 0) UCTick();
        XCTAssertTrue(captured); XCTAssertNil(snapshotError); XCTAssertNotNil(webImage);
        if (!webImage) return;
        XCTAssertTrue([UIImagePNGRepresentation(webImage) writeToFile:[library stringByAppendingPathComponent:@"cloud-native-web.png"] atomically:YES]);
        UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:window.bounds.size];
        UIImage *screen = [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
            [window drawViewHierarchyInRect:window.bounds afterScreenUpdates:YES];
            [webImage drawInRect:[web convertRect:web.bounds toView:window]];
        }];
        XCTAttachment *attachment = [XCTAttachment attachmentWithImage:screen];
        attachment.name = @"Actual native window with current WK compositor snapshot"; attachment.lifetime = XCTAttachmentLifetimeKeepAlways;
        [self addAttachment:attachment];
        XCTAssertTrue([UIImagePNGRepresentation(screen) writeToFile:[library stringByAppendingPathComponent:@"cloud-native-window.png"] atomically:YES]);
        [self checkStandaloneFileInWindow:window library:library];
    };
    if (NSThread.isMainThread) check(); else dispatch_sync(dispatch_get_main_queue(), check);
}
@end
