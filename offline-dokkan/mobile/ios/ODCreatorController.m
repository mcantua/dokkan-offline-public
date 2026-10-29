#import "ODCreatorController.h"
#import "ODCreatorSession.h"
#import "../../original-client/creator-tools/ODScopedCreatorTools.h"
#import <CommonCrypto/CommonDigest.h>
#import <objc/message.h>
#include <sys/stat.h>

@interface ODCreatorResources : NSObject <WKURLSchemeHandler>
@property(nonatomic) BOOL originalClientMode;
@property(nonatomic, strong) id<WKURLSchemeHandler> toolsHandler;
@end
@implementation ODCreatorResources
- (void)webView:(WKWebView *)webView startURLSchemeTask:(id<WKURLSchemeTask>)task {
    NSURL *url=task.request.URL;NSString *path=url.path?:@"/";
    BOOL allowed=[url.scheme isEqual:@"app"]&&[url.host isEqual:@"local"];
    NSMutableArray *parts=[NSMutableArray array];
    for(NSString *part in path.pathComponents){if([part isEqual:@"/"])continue;if([part isEqual:@"."]||[part isEqual:@".."]||[part containsString:@"\\"]||[part rangeOfCharacterFromSet:NSCharacterSet.controlCharacterSet].location!=NSNotFound){allowed=NO;break;}[parts addObject:part];}
    if(!parts.count)[parts addObject:@"index.html"];
    if(self.originalClientMode&&[parts.firstObject isEqual:@"gameplay"])allowed=NO;
    if(allowed&&self.toolsHandler&&[@[@"__file",@"__net",@"__mirror",@"__thumb"] containsObject:parts.firstObject]){
        [self.toolsHandler webView:webView startURLSchemeTask:task];return;
    }
    allowed=allowed&&[task.request.HTTPMethod isEqual:@"GET"];
    NSURL *base=[NSBundle.mainBundle.resourceURL URLByAppendingPathComponent:@"site" isDirectory:YES];NSURL *file=base;
    for(NSString *part in parts)file=[file URLByAppendingPathComponent:part];
    struct stat st;allowed=allowed&&file.isFileURL&&[file.path hasPrefix:[base.path stringByAppendingString:@"/"]]&&!lstat(file.fileSystemRepresentation,&st)&&S_ISREG(st.st_mode)&&!S_ISLNK(st.st_mode)&&st.st_size<=64*1024*1024;
    NSData *bytes=allowed?[NSData dataWithContentsOfURL:file options:NSDataReadingMappedIfSafe error:nil]:nil;
    NSDictionary *types=@{@"html":@"text/html; charset=utf-8",@"js":@"text/javascript; charset=utf-8",@"css":@"text/css; charset=utf-8",@"json":@"application/json",@"ttf":@"font/ttf",@"woff":@"font/woff",@"woff2":@"font/woff2",@"svg":@"image/svg+xml",@"png":@"image/png",@"wasm":@"application/wasm"};
    NSDictionary *headers=@{@"Content-Type":types[file.pathExtension.lowercaseString]?:@"application/octet-stream",@"Content-Length":[NSString stringWithFormat:@"%lu",(unsigned long)bytes.length],@"Cache-Control":@"no-store",@"Access-Control-Allow-Origin":@"app://local",@"Content-Security-Policy":@"default-src 'self' data: blob:; connect-src 'self'; script-src 'self' 'unsafe-inline' 'wasm-unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; font-src 'self' data:; worker-src 'self' blob:; frame-src 'none'; object-src 'none'; base-uri 'none'"};
    [task didReceiveResponse:[[NSHTTPURLResponse alloc] initWithURL:url statusCode:bytes?200:404 HTTPVersion:@"HTTP/1.1" headerFields:headers]];if(bytes.length)[task didReceiveData:bytes];[task didFinish];
}
- (void)webView:(WKWebView *)webView stopURLSchemeTask:(id<WKURLSchemeTask>)task { [self.toolsHandler webView:webView stopURLSchemeTask:task]; }
@end

@interface ODCreatorController () <WKScriptMessageHandlerWithReply,WKNavigationDelegate>
@property(nonatomic, readwrite) WKWebView *webView;
@end
@implementation ODCreatorController {
    ODCreatorSession *_session;void (^_completion)(void);UILabel *_status;UIView *_toolsCanvas;BOOL _closing,_editorUnavailable;NSUInteger _closeGeneration;
}
- (instancetype)initWithSession:(ODCreatorSession *)session completion:(void (^)(void))completion {
    if((self=[super init])){_session=session;_completion=[completion copy];self.modalPresentationStyle=UIModalPresentationFullScreen;}return self;
}
- (WKWebsiteDataStore *)scopedWebsiteDataStore {
    NSString *scope=self.scopedTools.scopeIdentifier;
    if(![scope isKindOfClass:NSString.class]||scope.length!=64)return nil;
    NSData *seed=[[@"offline-dokkan.creator.webkit-scope.v1\n" stringByAppendingString:scope] dataUsingEncoding:NSUTF8StringEncoding];unsigned char digest[CC_SHA256_DIGEST_LENGTH];CC_SHA256(seed.bytes,(CC_LONG)seed.length,digest);
    digest[6]=(digest[6]&0x0f)|0x50;digest[8]=(digest[8]&0x3f)|0x80;
    NSUUID *identifier=[[NSUUID alloc] initWithUUIDBytes:digest];SEL selector=NSSelectorFromString(@"dataStoreForIdentifier:");
    // Public persistent profile API on supported modern WebKit. Typed dispatch
    // keeps older component SDK headers usable without changing runtime marks.
    if(![WKWebsiteDataStore.class respondsToSelector:selector])return nil;
    id store=((id(*)(id,SEL,id))objc_msgSend)(WKWebsiteDataStore.class,selector,identifier);
    return [store isKindOfClass:WKWebsiteDataStore.class]?store:nil;
}
- (void)viewDidLoad {
    [super viewDidLoad];self.view.backgroundColor=UIColor.systemBackgroundColor;
    UIButton *close=[UIButton buttonWithType:UIButtonTypeSystem];
    NSString *closeTitle=_session.originalClientMode?@"Menu":@"Back to Offline Dokkan";
    [close setTitle:closeTitle forState:UIControlStateNormal];
    close.accessibilityIdentifier=_session.originalClientMode?@"in-game-creator-menu":@"creator-close";
    [close addTarget:self action:@selector(closeCreator) forControlEvents:UIControlEventTouchUpInside];close.translatesAutoresizingMaskIntoConstraints=NO;
    _status=[UILabel new];_status.text=@"Opening Unit Creator…";_status.numberOfLines=0;_status.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody];_status.translatesAutoresizingMaskIntoConstraints=NO;
    WKWebViewConfiguration *config=[WKWebViewConfiguration new];
    WKWebsiteDataStore *store=_session.originalClientMode?[self scopedWebsiteDataStore]:WKWebsiteDataStore.defaultDataStore;
    _editorUnavailable=store==nil;config.websiteDataStore=store?:WKWebsiteDataStore.nonPersistentDataStore;
    ODCreatorResources *resources=[ODCreatorResources new];resources.originalClientMode=_session.originalClientMode;
    resources.toolsHandler=self.scopedTools.schemeHandler;
    [config setURLSchemeHandler:resources forURLScheme:@"app"];
    [config.userContentController addScriptMessageHandlerWithReply:self contentWorld:WKContentWorld.pageWorld name:@"OfflineCreator"];
    if(self.scopedTools)[config.userContentController addScriptMessageHandlerWithReply:self.scopedTools contentWorld:WKContentWorld.pageWorld name:@"ForgeHost"];
    if(self.scopedTools){_toolsCanvas=[UIView new];_toolsCanvas.translatesAutoresizingMaskIntoConstraints=NO;[self.view addSubview:_toolsCanvas];}
    _webView=[[WKWebView alloc] initWithFrame:CGRectZero configuration:config];_webView.navigationDelegate=self;_webView.translatesAutoresizingMaskIntoConstraints=_toolsCanvas!=nil;_webView.opaque=NO;_webView.scrollView.contentInsetAdjustmentBehavior=UIScrollViewContentInsetAdjustmentNever;
    // ForgePlayer deliberately owns editor/preview frames inside this canvas.
    // Root safe-area/close chrome remains constrained; no player frame can
    // fight WK constraints or move the original game renderer/controller.
    UIView *page=_toolsCanvas?:_webView;[(_toolsCanvas?:self.view) addSubview:_webView];[self.view addSubview:close];[self.view addSubview:_status];_status.backgroundColor=UIColor.systemBackgroundColor;UILayoutGuide *safe=self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[[close.topAnchor constraintEqualToAnchor:safe.topAnchor],[close.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:12],[close.heightAnchor constraintGreaterThanOrEqualToConstant:44],[page.topAnchor constraintEqualToAnchor:close.bottomAnchor],[page.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor],[page.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor],[page.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor],[_status.centerXAnchor constraintEqualToAnchor:safe.centerXAnchor],[_status.centerYAnchor constraintEqualToAnchor:safe.centerYAnchor],[_status.widthAnchor constraintLessThanOrEqualToAnchor:safe.widthAnchor constant:-40]]];
    [self.scopedTools attachWebView:_webView presenter:self];
    if(_session.originalClientMode)[self.scopedTools useInGameCreatorMenuWithTarget:self action:@selector(closeCreator)];
    if(_editorUnavailable)_status.text=@"This WebKit runtime could not isolate this save's Creator drafts and gallery. Return to the game; your native saved units are kept.";
    else [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"app://local/index.html"]]];
}
- (void)viewDidLayoutSubviews { [super viewDidLayoutSubviews];if(_toolsCanvas)[self.scopedTools layoutInBounds:_toolsCanvas.bounds safeArea:UIEdgeInsetsZero]; }
- (void)closeCreator {
    if(self.scopedTools.archiveOperationInProgress){_status.hidden=NO;_status.text=@"Finish saving or restoring your creations before returning to the game.";return;}
    if(_closing)return;_closing=YES;NSUInteger generation=++_closeGeneration;self.view.userInteractionEnabled=NO;[self.view endEditing:YES];
    __weak ODCreatorController *weakSelf=self;
    if(_editorUnavailable)[self prepareCloseGeneration:generation];
    else [_webView callAsyncJavaScript:@"if(typeof flushSave==='function')await flushSave();return true;" arguments:@{} inFrame:nil inContentWorld:WKContentWorld.pageWorld completionHandler:^(id result,NSError *error){
        ODCreatorController *me=weakSelf;if(!me||me->_closeGeneration!=generation)return;
        if(error||![result isEqual:@YES]){me->_closing=NO;me.view.userInteractionEnabled=YES;me->_status.hidden=NO;me->_status.text=@"Couldn't confirm the save. Keep your unit open and try again.";return;}
        [me prepareCloseGeneration:generation];
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,30*NSEC_PER_SEC),dispatch_get_main_queue(),^{
        ODCreatorController *me=weakSelf;if(!me||!me->_closing||me->_closeGeneration!=generation)return;
        me->_closeGeneration++;me->_closing=NO;me.view.userInteractionEnabled=YES;me->_status.hidden=NO;me->_status.text=@"The save is taking too long to confirm. Your unit stays open.";
    });
}
- (void)prepareCloseGeneration:(NSUInteger)generation {
    if(!_closing||_closeGeneration!=generation)return;
    void (^preparation)(void (^)(NSError *))=self.closePreparation;__weak ODCreatorController *weakSelf=self;
    if(preparation)preparation(^(NSError *failure){dispatch_async(dispatch_get_main_queue(),^{[weakSelf finishCloseGeneration:generation error:failure];});});
    else [self finishCloseGeneration:generation error:nil];
}
- (void)finishCloseGeneration:(NSUInteger)generation error:(NSError *)error {
    if(!_closing||_closeGeneration!=generation)return;
    if(error){_closing=NO;self.view.userInteractionEnabled=YES;_status.hidden=NO;_status.text=@"Couldn't prepare your saved unit for Offline Dokkan. Your design stays open; try again after the game data is ready.";return;}
    _closing=NO;++_closeGeneration;
    // Revoke on main before any owner lease can be released or rebound.
    [self.scopedTools invalidate];
    [self.webView.configuration.userContentController removeScriptMessageHandlerForName:@"ForgeHost" contentWorld:WKContentWorld.pageWorld];
    [self.webView stopLoading];[self.webView.configuration.userContentController removeScriptMessageHandlerForName:@"OfflineCreator" contentWorld:WKContentWorld.pageWorld];
    void (^completion)(void)=_completion;_completion=nil;[self dismissViewControllerAnimated:YES completion:completion];
}
- (void)userContentController:(WKUserContentController *)controller didReceiveScriptMessage:(WKScriptMessage *)message replyHandler:(void (^)(id,NSString *))reply {
    WKSecurityOrigin *origin=message.frameInfo.securityOrigin;
    if(!message.frameInfo.mainFrame||![origin.protocol isEqual:@"app"]||![origin.host isEqual:@"local"]||![message.body isKindOfClass:NSDictionary.class]){reply(nil,@"UNTRUSTED_CREATOR_FRAME");return;}
    NSDictionary *body=message.body;id args=body[@"args"]?:@{};
    if(![body[@"op"] isKindOfClass:NSString.class]||![args isKindOfClass:NSDictionary.class]){reply(nil,@"INVALID_CREATOR_REQUEST");return;}
    if(self.scopedTools.archiveOperationInProgress&&![@[@"info",@"query",@"querySparking",@"creatorMasterRead",@"cardIndex",@"projects",@"loadProject",@"listProjectVersions",@"loadProjectVersion",@"settings",@"assets",@"patches"] containsObject:body[@"op"]]){reply(nil,@"CREATOR_ARCHIVE_IN_PROGRESS");return;}
    [_session handleOperation:body[@"op"] arguments:args reply:reply];
}
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)action decisionHandler:(void (^)(WKNavigationActionPolicy))decision {
    NSURL *url=action.request.URL;decision([url.scheme isEqual:@"app"]&&[url.host isEqual:@"local"]&&action.targetFrame.mainFrame?WKNavigationActionPolicyAllow:WKNavigationActionPolicyCancel);
}
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation { _status.hidden=YES; }
- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error { _status.hidden=NO;_status.text=@"Couldn't open Unit Creator. Your saved units were kept."; }
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error { [self webView:webView didFailNavigation:navigation withError:error]; }
@end
