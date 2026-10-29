#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>
#import <objc/message.h>
#import <math.h>
#import "InstallerService.h"
#import "DisplayDiagnostics.h"

// TEST-ONLY service object. Never compiled into AppInstaller, never authenticates,
// signs, installs, refreshes or stores credentials. It supplies labelled UI metadata.
@interface AICloudUITestOnlyFixture : NSObject
@property (nonatomic, copy) void (^eventHandler)(NSDictionary *event);
@property (nonatomic, copy) NSDictionary *stateOverrides;
@property (nonatomic) NSUInteger refreshTaps;
@property (nonatomic, readonly) NSDictionary *snapshot;
@property (nonatomic, readonly) NSArray<NSDictionary *> *appRecords;
@end
@implementation AICloudUITestOnlyFixture
- (NSDictionary *)snapshot {
    NSMutableDictionary *state=[@{@"loginStatus":@"signed_in", @"paired":@YES, @"pairingFilePresent":@YES, @"pairingVerified":@YES, @"biometricEnabled":@YES,
             @"backendReady":@YES, @"busy":@NO,
             @"statusMessage":@"TEST-ONLY UI fixture. No Apple account or installation is active."} mutableCopy];
    if(self.stateOverrides)[state addEntriesFromDictionary:self.stateOverrides];return state;
}
- (void)refreshAll { self.refreshTaps += 1; } // UI target routing only; no refresh or account operation.
- (NSArray<NSDictionary *> *)appRecords {
    return @[@{@"name":@"TEST ONLY — Sample App", @"bundleId":@"org.example.cloud-ui-fixture",
               @"expiry":@([NSDate.date timeIntervalSince1970] + 6 * 86400)}];
}
@end

// These declarations expose production selectors to a test-only geometry subclass.
@interface AIHome : UIViewController
- (NSDictionary *)displayGeometry;
@end
@interface AICloudUITestGeometryHome : AIHome
@property (nonatomic, copy) NSString *fixtureRailSide;
@property (nonatomic) BOOL fixtureGeometryEnabled;
@end
@implementation AICloudUITestGeometryHome
- (NSDictionary *)displayGeometry {
    if(!self.fixtureGeometryEnabled)return[super displayGeometry];
    UIEdgeInsets safe=self.view.safeAreaInsets;CGRect bounds=self.view.bounds;
    NSArray *occlusions=@[];
    if(self.fixtureRailSide.length){BOOL right=[self.fixtureRailSide isEqual:@"right"];
        // This explicitly labelled fixture owns its geometry. UIKit may defer or
        // clamp additionalSafeAreaInsets during manual navigation reparenting.
        // Production still computes its layout from this model and actual UIKit
        // safe-area differences; no live reserved-region result is fabricated.
        if(right)safe.right=MAX(safe.right,84.0);else safe.left=MAX(safe.left,84.0);
        CGFloat width=right?safe.right:safe.left;
        occlusions=@[[NSValue valueWithCGRect:CGRectMake(right?bounds.size.width-width:0,0,width,174)]];}
    return [AIDisplayDiagnostics geometryForBounds:bounds safeArea:safe occlusions:occlusions divisions:@[] source:@"TEST-ONLY camera/safe-area fixture; not hardware"];
}
@end

static UIView *AIFindView(UIView *root, BOOL (^predicate)(UIView *)) {
    if (predicate(root)) return root;
    for (UIView *child in root.subviews) { UIView *found = AIFindView(child, predicate); if (found) return found; }
    return nil;
}
static NSString *AIButtonTitle(UIButton *button) {
    return button.configuration.title ?: [button titleForState:UIControlStateNormal] ?: @"";
}
static UIWindow *AIAppWindow(void) {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class]) continue;
        for (UIWindow *window in ((UIWindowScene *)scene).windows) if (window.isKeyWindow) return window;
    }
    return nil;
}
static void AITick(void) {
    [NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.15]];
}
static UIWindow *AIWaitForAppWindow(void) {
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:10];
    UIWindow *window = AIAppWindow();
    while (!window && deadline.timeIntervalSinceNow > 0) { AITick(); window = AIAppWindow(); }
    return window;
}

@interface AppInstallerCloudUITests : XCTestCase
@end
@implementation AppInstallerCloudUITests
- (void)runOnMain:(void (^)(void))block {
    if (NSThread.isMainThread) block(); else dispatch_sync(dispatch_get_main_queue(), block);
}
- (void)attachView:(UIView *)view name:(NSString *)name {
    UIGraphicsImageRendererFormat *format=[UIGraphicsImageRendererFormat defaultFormat];
    format.scale=MAX(1,view.traitCollection.displayScale);
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:view.bounds.size format:format];
    UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    }];
    XCTAttachment *attachment = [XCTAttachment attachmentWithImage:image];
    attachment.name = name; attachment.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:attachment];
}
- (void)requestActualDisplayPhase:(NSString *)phase {
    if (![NSProcessInfo.processInfo.environment[@"AI_CLOUD_DISPLAY_PROBE"] isEqual:@"1"]) {
        NSDictionary *unverified=@{@"phase":phase,@"actualDisplayTransitionVerified":@NO,
            @"scope":@"Panel-power diagnostic not run. The prior hosted Duo runtime aborted in SpringBoard display initialization; this check preserves its default display configuration. Physical folding remains required."};
        XCTAttachment *note=[XCTAttachment attachmentWithData:[NSJSONSerialization dataWithJSONObject:unverified options:NSJSONWritingPrettyPrinted error:NULL] uniformTypeIdentifier:@"public.json"];
        note.name=@"Display transition remains unverified";note.lifetime=XCTAttachmentLifetimeKeepAlways;[self addAttachment:note];
        return;
    }
    NSURL *documents=[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
    NSURL *directory=[documents URLByAppendingPathComponent:@"CloudDisplayControl" isDirectory:YES];
    NSError *error=nil;XCTAssertTrue([NSFileManager.defaultManager createDirectoryAtURL:directory withIntermediateDirectories:YES attributes:nil error:&error]);
    NSString *nonce=NSUUID.UUID.UUIDString;
    NSData *request=[NSJSONSerialization dataWithJSONObject:@{@"nonce":nonce,@"phase":phase} options:0 error:NULL];
    XCTAssertTrue([request writeToURL:[directory URLByAppendingPathComponent:@"request.json"] options:NSDataWritingAtomic error:&error]);
    NSDictionary *response=nil;NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:45];
    while(deadline.timeIntervalSinceNow>0){NSData *data=[NSData dataWithContentsOfURL:[directory URLByAppendingPathComponent:@"response.json"]];id value=data?[NSJSONSerialization JSONObjectWithData:data options:0 error:NULL]:nil;if([value isKindOfClass:NSDictionary.class]&&[value[@"nonce"]isEqual:nonce]){response=value;break;}AITick();}
    XCTAssertNotNil(response,@"The owned-simulator display driver must answer the test request.");
    if(!response)return;
    XCTAssertEqualObjects(response[@"status"],@"ok",@"Documented screen power states must be observed; an unsupported/no-op power control is not a fold pass.");
    if(![response[@"status"]isEqual:@"ok"])return;
    NSDictionary *target=response[@"target_screen"];NSArray *pixels=target[@"pixels"];double scale=[target[@"scale"]doubleValue];
    XCTAssertEqual(pixels.count,2u);XCTAssertGreaterThan(scale,0.0);if(pixels.count!=2||scale<=0)return;
    CGSize expected=CGSizeMake([pixels[0]doubleValue]/scale,[pixels[1]doubleValue]/scale);
    __block BOOL matched=NO;deadline=[NSDate dateWithTimeIntervalSinceNow:12];
    do{UIWindow *current=AIAppWindow();CGSize actual=current.bounds.size;matched=current&&((fabs(actual.width-expected.width)<1&&fabs(actual.height-expected.height)<1)||(fabs(actual.width-expected.height)<1&&fabs(actual.height-expected.width)<1));if(!matched)AITick();}while(!matched&&deadline.timeIntervalSinceNow>0);
    UIWindow *actualWindow=AIAppWindow();
    NSDictionary *observation=@{@"scope":@"Actual owned-simulator documented display-power change; not a physical hinge/fold",@"phase":phase,@"targetPixels":pixels,@"targetScale":@(scale),@"windowBounds":[AIDisplayDiagnostics rect:actualWindow.bounds],@"sceneBounds":[AIDisplayDiagnostics rect:actualWindow.windowScene.coordinateSpace.bounds],@"applicationState":@(UIApplication.sharedApplication.applicationState),@"expectedSceneObserved":@(matched)};
    XCTAttachment *attachment=[XCTAttachment attachmentWithData:[NSJSONSerialization dataWithJSONObject:observation options:NSJSONWritingPrettyPrinted error:NULL] uniformTypeIdentifier:@"public.json"];
    attachment.name=[@"Actual simulator display-power observation — " stringByAppendingString:phase];attachment.lifetime=XCTAttachmentLifetimeKeepAlways;[self addAttachment:attachment];
    XCTAssertTrue(matched,@"Screen power changed but the app scene did not match that real display; actual cross-screen behavior is unverified.");
    XCTAssertEqual(UIApplication.sharedApplication.applicationState,UIApplicationStateActive);
}
- (void)test01ProductionLoginAndSettingsLaunchWithoutAccount {
    [self runOnMain:^{
    XCTAssertTrue(NSThread.isMainThread);
    UIWindow *window = AIWaitForAppWindow(); XCTAssertNotNil(window);
    UINavigationController *navigation = (id)window.rootViewController;
    XCTAssertTrue([navigation isKindOfClass:UINavigationController.class]);
    [navigation popToRootViewControllerAnimated:NO];
    UIViewController *home = navigation.viewControllers.firstObject;
    [home loadViewIfNeeded]; [home.view layoutIfNeeded]; AITick();
    XCTAssertEqualObjects(NSStringFromClass(home.class), @"AIHome");
    UIView *heading = AIFindView(home.view, ^BOOL(UIView *view) {
        return [view isKindOfClass:UILabel.class] && [((UILabel *)view).text isEqual:@"Sign in with Apple ID"];
    });
    XCTAssertNotNil(heading, @"Production login must be the initial screen without credentials.");
    UITextField *email = (id)AIFindView(home.view, ^BOOL(UIView *view) {
        return [view isKindOfClass:UITextField.class] && [view.accessibilityLabel isEqual:@"Apple ID email"];
    });
    UITextField *password = (id)AIFindView(home.view, ^BOOL(UIView *view) {
        return [view isKindOfClass:UITextField.class] && [view.accessibilityLabel isEqual:@"Password"];
    });
    XCTAssertNotNil(email); XCTAssertNotNil(password); XCTAssertTrue(password.secureTextEntry);
    XCTAssertEqual(email.text.length, 0u); XCTAssertEqual(password.text.length, 0u);
    [self attachView:window name:@"Production login — no credentials entered"];
    NSDictionary *actualGeometry=[AIDisplayDiagnostics geometryForView:home.view];
    NSDictionary *report=[AIDisplayDiagnostics reportForView:home.view geometry:actualGeometry layout:@{} state:@{@"scope":@"Actual hosted simulator; model and fallback are recorded in workflow evidence; no physical device"}];
    NSData *reportData=[NSJSONSerialization dataWithJSONObject:report options:NSJSONWritingPrettyPrinted error:NULL];
    XCTAttachment *reportAttachment=[XCTAttachment attachmentWithData:reportData uniformTypeIdentifier:@"public.json"];
    reportAttachment.name=@"Actual simulator display report — not physical hardware";reportAttachment.lifetime=XCTAttachmentLifetimeKeepAlways;[self addAttachment:reportAttachment];
    XCTAssertGreaterThan(home.view.traitCollection.displayScale,0.0);
    XCTAssertEqualWithAccuracy(window.bounds.size.width,window.windowScene.coordinateSpace.bounds.size.width,1.0);
    XCTAssertEqualWithAccuracy(window.bounds.size.height,window.windowScene.coordinateSpace.bounds.size.height,1.0);
    CGRect originalFrame=home.view.frame;
    email.text=@"TEST-ONLY unsent layout state";
    id sceneDelegate=window.windowScene.delegate;
    if([sceneDelegate respondsToSelector:@selector(sceneWillResignActive:)] && [sceneDelegate respondsToSelector:@selector(sceneDidBecomeActive:)]) {
        ((void (*)(id,SEL,id))objc_msgSend)(sceneDelegate,@selector(sceneWillResignActive:),window.windowScene);
        XCTAssertEqualObjects(email.text,@"TEST-ONLY unsent layout state",@"Transient foreground inactivity must not discard unsent nonsecret state.");
        UIView *shield=AIFindView(window,^BOOL(UIView *v){return[v.accessibilityIdentifier isEqual:@"App Installer privacy shield"];});XCTAssertNotNil(shield);
        ((void (*)(id,SEL,id))objc_msgSend)(sceneDelegate,@selector(sceneDidBecomeActive:),window.windowScene);
    }
    [self requestActualDisplayPhase:@"switch_secondary"];
    XCTAssertEqual(AIAppWindow().rootViewController,navigation);XCTAssertEqualObjects(email.text,@"TEST-ONLY unsent layout state");
    [self requestActualDisplayPhase:@"restore_primary"];
    XCTAssertEqual(AIAppWindow().rootViewController,navigation);XCTAssertEqualObjects(email.text,@"TEST-ONLY unsent layout state");
    for(NSValue *sizeValue in @[[NSValue valueWithCGSize:CGSizeMake(466,678)],[NSValue valueWithCGSize:CGSizeMake(669,951)],[NSValue valueWithCGSize:CGSizeMake(466,678)]]) {
        home.view.frame=(CGRect){CGPointZero,sizeValue.CGSizeValue};[home.view setNeedsLayout];[home.view layoutIfNeeded];
        XCTAssertEqualObjects(email.text,@"TEST-ONLY unsent layout state",@"Forced view resizing must preserve unsent nonsecret form state.");
    }
    email.text=nil;home.view.frame=originalFrame;[home.view setNeedsLayout];[home.view layoutIfNeeded];
    UIBarButtonItem *settings = home.navigationItem.rightBarButtonItem;
    XCTAssertEqualObjects(settings.accessibilityLabel, @"Settings");
    XCTAssertTrue([UIApplication.sharedApplication sendAction:settings.action to:settings.target from:settings forEvent:nil]);
    NSDate *transitionDeadline = [NSDate dateWithTimeIntervalSinceNow:3.0];
    do { AITick(); } while (navigation.transitionCoordinator && transitionDeadline.timeIntervalSinceNow > 0);
    XCTAssertNil(navigation.transitionCoordinator, @"Capture Settings only after navigation has settled.");
    UITableViewController *settingsController = (id)navigation.topViewController;
    XCTAssertEqualObjects(settingsController.title, @"Settings");
    XCTAssertTrue([settingsController isKindOfClass:UITableViewController.class]);
    CGRect settingsFrame = [settingsController.view convertRect:settingsController.view.bounds toView:window];
    XCTAssertEqualWithAccuracy(CGRectGetMinX(settingsFrame), 0.0, 1.0);
    XCTAssertEqualWithAccuracy(CGRectGetWidth(settingsFrame), CGRectGetWidth(window.bounds), 1.0);
    NSIndexPath *expiry = [NSIndexPath indexPathForRow:1 inSection:1];
    [settingsController.tableView scrollToRowAtIndexPath:expiry atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
    [settingsController.tableView layoutIfNeeded];
    XCTAssertEqualObjects([settingsController.tableView cellForRowAtIndexPath:expiry].textLabel.text, @"Installer expiry");
    [self attachView:window name:@"Production settings — expiry visible"];
    [navigation popToRootViewControllerAnimated:NO];
    }];
}
- (void)checkVisibleTextBounds:(UIView *)view container:(UIView *)container width:(CGFloat)width {
    if (view.hidden) return;
    if ([view isKindOfClass:UILabel.class] || [view isKindOfClass:UIButton.class]) {
        CGRect frame = [view convertRect:view.bounds toView:container];
        XCTAssertGreaterThanOrEqual(CGRectGetMinX(frame), -1.0);
        XCTAssertLessThanOrEqual(CGRectGetMaxX(frame), width + 1.0);
    }
    for (UIView *child in view.subviews) [self checkVisibleTextBounds:child container:container width:width];
}
- (void)assertTouchTargets:(UIView *)view container:(UIView *)container occlusions:(NSArray *)occlusions {
    if(view.hidden)return;
    if([view isKindOfClass:UIButton.class] || [view isKindOfClass:UILabel.class]) {
        CGRect frame=[view convertRect:view.bounds toView:container];
        if([view isKindOfClass:UIButton.class]){UIButton *button=(id)view;XCTAssertGreaterThanOrEqual(frame.size.width,44.0);XCTAssertGreaterThanOrEqual(frame.size.height,44.0);XCTAssertTrue(button.accessibilityLabel.length>0 || AIButtonTitle(button).length>0);}
        for(NSDictionary *item in occlusions){CGRect cut=CGRectMake([item[@"x"]doubleValue],[item[@"y"]doubleValue],[item[@"width"]doubleValue],[item[@"height"]doubleValue]);XCTAssertFalse(CGRectIntersectsRect(frame,cut),@"A test fixture label or touch target overlaps the simulated camera.");}
    }
    for(UIView *child in view.subviews)[self assertTouchTargets:child container:container occlusions:occlusions];
}
- (void)test02ResponsiveMainUsesLabelledTestOnlyFixture {
    [self runOnMain:^{
    UIWindow *window=AIWaitForAppWindow();XCTAssertNotNil(window);
    UIViewController *original=window.rootViewController;
    void (^originalHandler)(NSDictionary *)=AIInstallerService.shared.eventHandler;
    AICloudUITestGeometryHome *home=[AICloudUITestGeometryHome new];[home loadViewIfNeeded];
    AICloudUITestOnlyFixture *fixture=[AICloudUITestOnlyFixture new];[home setValue:fixture forKey:@"service"];
    UINavigationController *navigation=[[UINavigationController alloc]initWithRootViewController:home];
    UIViewController *host=[UIViewController new];
    @try {
        window.rootViewController=navigation;
        fixture.stateOverrides=@{@"paired":@NO,@"pairingFilePresent":@YES,@"pairingVerified":@NO};
        ((void (*)(id,SEL))objc_msgSend)(home,NSSelectorFromString(@"render"));
        UIButton *unlockConnection=(id)AIFindView(home.view,^BOOL(UIView *v){return[v isKindOfClass:UIButton.class]&&[AIButtonTitle((id)v)isEqual:@"Unlock and check connection"];});
        UIButton *replacePairing=(id)AIFindView(home.view,^BOOL(UIView *v){return[v isKindOfClass:UIButton.class]&&[AIButtonTitle((id)v)isEqual:@"Replace pairing file"];});
        XCTAssertNotNil(unlockConnection,@"Saved-but-unverified pairing must offer unlock without forcing another import.");
        XCTAssertNotNil(replacePairing);
        // Metadata routing only: do not invoke either action or fake any authentication/connection success.
        fixture.stateOverrides=@{@"paired":@NO,@"pairingFilePresent":@NO,@"pairingVerified":@NO};
        ((void (*)(id,SEL))objc_msgSend)(home,NSSelectorFromString(@"render"));
        XCTAssertNotNil(AIFindView(home.view,^BOOL(UIView *v){return[v isKindOfClass:UIButton.class]&&[AIButtonTitle((id)v)isEqual:@"Import pairing file"]; }));
        fixture.stateOverrides=nil;
        ((void (*)(id,SEL))objc_msgSend)(home,NSSelectorFromString(@"render"));
        fixture.stateOverrides=@{@"busy":@YES,@"activeOperationId":@42,@"statusMessage":@"TEST-ONLY progress metadata; no installation is active."};
        ((void (*)(id,SEL,id))objc_msgSend)(home,NSSelectorFromString(@"handleEvent:"),@{@"type":@"progress",@"operationId":@42,@"progress":@0.42,@"message":@"TEST-ONLY progress metadata"});
        [self requestActualDisplayPhase:@"switch_secondary"];
        XCTAssertEqual(AIAppWindow().rootViewController,navigation);XCTAssertEqualWithAccuracy([[home valueForKey:@"displayProgress"]doubleValue],0.42,0.001);
        [self requestActualDisplayPhase:@"restore_primary"];
        XCTAssertEqual(AIAppWindow().rootViewController,navigation);XCTAssertEqualWithAccuracy([[home valueForKey:@"displayProgress"]doubleValue],0.42,0.001);
        fixture.stateOverrides=nil;
        window.rootViewController=host;[host addChildViewController:navigation];[host.view addSubview:navigation.view];[navigation didMoveToParentViewController:host];navigation.view.autoresizingMask=UIViewAutoresizingNone;
        home.fixtureGeometryEnabled=YES;
        NSArray *cases=@[@{ @"width":@390,@"height":@844,@"side":@"" },@{ @"width":@466,@"height":@678,@"side":@"right" },@{ @"width":@669,@"height":@951,@"side":@"right" },@{ @"width":@669,@"height":@951,@"side":@"" },@{ @"width":@951,@"height":@669,@"side":@"" },@{ @"width":@466,@"height":@678,@"side":@"left" },@{ @"width":@669,@"height":@951,@"side":@"" }];
        void (^assertPinnedCancel)(void)=^{
            UIView *hud=[home valueForKey:@"taskHUD"];
            UIButton *cancel=[home valueForKey:@"taskHUDCancel"];
            UIScrollView *scroll=[home valueForKey:@"scroll"];
            XCTAssertFalse(hud.hidden);XCTAssertTrue([cancel isDescendantOfView:hud]);
            XCTAssertGreaterThan(cancel.allTargets.count,0u);
            XCTAssertFalse([cancel isDescendantOfView:scroll],@"Cancel must stay outside the scrolling app list.");
            CGRect before=[cancel convertRect:cancel.bounds toView:home.view];
            scroll.contentOffset=CGPointMake(0,MAX(0,scroll.contentSize.height-scroll.bounds.size.height));
            [home.view layoutIfNeeded];
            CGRect after=[cancel convertRect:cancel.bounds toView:home.view];
            XCTAssertTrue(CGRectEqualToRect(before,after),@"Scrolling to the list end must not move task cancellation.");
            XCTAssertGreaterThanOrEqual(after.size.width,44.0);XCTAssertGreaterThanOrEqual(after.size.height,44.0);
            XCTAssertGreaterThanOrEqual(CGRectGetMinY(hud.frame),home.view.safeAreaInsets.top);
            XCTAssertLessThanOrEqual(CGRectGetMaxY(hud.frame),CGRectGetMinY(home.view.keyboardLayoutGuide.layoutFrame)+1);
            XCTAssertLessThanOrEqual(CGRectGetMaxY(scroll.frame),CGRectGetMinY(hud.frame),@"Pinned task controls must reserve list space.");
            CGPoint center=CGPointMake(CGRectGetMidX(after),CGRectGetMidY(after));
            UIView *hit=[home.view hitTest:center withEvent:nil];
            XCTAssertTrue(hit==cancel || [hit isDescendantOfView:cancel],@"The pinned Cancel button must own its rendered touch point.");
            XCTAssertEqualWithAccuracy(((UIProgressView *)[home valueForKey:@"taskHUDProgress"]).progress,0.42,0.001);
        };
        ((void (*)(id,SEL))objc_msgSend)(home,NSSelectorFromString(@"render"));
        for(NSDictionary *testCase in cases) {
            CGSize size=CGSizeMake([testCase[@"width"]doubleValue],[testCase[@"height"]doubleValue]);
            navigation.view.frame=(CGRect){CGPointZero,size};
            home.fixtureRailSide=testCase[@"side"];
            home.additionalSafeAreaInsets=UIEdgeInsetsZero;[navigation.view setNeedsLayout];[navigation.view layoutIfNeeded];
            for(NSInteger pass=0;pass<3;++pass){[navigation.view setNeedsLayout];[navigation.view layoutIfNeeded];[home.view setNeedsLayout];[home.view layoutIfNeeded];}
            UIButton *install=(id)AIFindView(home.view,^BOOL(UIView *v){return[v isKindOfClass:UIButton.class]&&[AIButtonTitle((id)v)isEqual:@"Install .IPA"];});
            UILabel *apps=(id)AIFindView(home.view,^BOOL(UIView *v){return[v isKindOfClass:UILabel.class]&&[((UILabel *)v).text isEqual:@"Installed apps"];});
            XCTAssertNotNil(install);XCTAssertNotNil(apps);
            CGRect installFrame=[install convertRect:install.bounds toView:home.view],appsFrame=[apps convertRect:apps.bounds toView:home.view];
            XCTAssertGreaterThan(installFrame.size.width,100.0);
            NSDictionary *geometry=[home displayGeometry];
            CGFloat available=home.view.bounds.size.width-[geometry[@"contentInsets"][@"left"]doubleValue]-[geometry[@"contentInsets"][@"right"]doubleValue]-48;
            if(available>=600)XCTAssertGreaterThan(CGRectGetMinX(appsFrame),CGRectGetMaxX(installFrame));else XCTAssertGreaterThan(CGRectGetMinY(appsFrame),CGRectGetMaxY(installFrame));
            if(size.width==669 && home.fixtureRailSide.length)XCTAssertEqual(((UIStackView *)[home valueForKey:@"mainColumns"]).axis,UILayoutConstraintAxisVertical,@"An occluded 669-point root must stack its narrower usable content.");
            [self checkVisibleTextBounds:home.view container:home.view width:home.view.bounds.size.width];
            [self assertTouchTargets:home.view container:home.view occlusions:geometry[@"occlusions"]];
            UIStackView *rail=[home valueForKey:@"rail"];
            if(home.fixtureRailSide.length){
                XCTAssertGreaterThanOrEqual([geometry[@"safeArea"][home.fixtureRailSide] doubleValue],84.0,@"Declared TEST-ONLY side inset must reach production geometry.");
                XCTAssertEqual([geometry[@"occlusions"] count],1u);
                XCTAssertFalse(rail.hidden);XCTAssertGreaterThanOrEqual(rail.frame.origin.y,194.0);
            }
            if(!fixture.stateOverrides) {
                UIButton *refresh=(id)AIFindView(home.view,^BOOL(UIView *v){return[v isKindOfClass:UIButton.class]&&[AIButtonTitle((id)v)isEqual:@"Refresh all"];});
                UIScrollView *scroll=[home valueForKey:@"scroll"];
                [scroll scrollRectToVisible:[refresh convertRect:refresh.bounds toView:scroll] animated:NO];[home.view layoutIfNeeded];
                CGPoint center=[refresh convertPoint:CGPointMake(CGRectGetMidX(refresh.bounds),CGRectGetMidY(refresh.bounds)) toView:home.view];
                UIView *hit=[home.view hitTest:center withEvent:nil];
                XCTAssertTrue(hit==refresh || [hit isDescendantOfView:refresh],@"The rendered refresh button must own its logical touch point.");
                [refresh sendActionsForControlEvents:UIControlEventTouchUpInside];XCTAssertEqual(fixture.refreshTaps,1u);
                fixture.stateOverrides=@{@"busy":@YES,@"activeOperationId":@42,@"statusMessage":@"TEST-ONLY install progress fixture; no installation is active."};
                ((void (*)(id,SEL,id))objc_msgSend)(home,NSSelectorFromString(@"handleEvent:"),@{@"type":@"progress",@"operationId":@42,@"progress":@0.42,@"message":@"TEST-ONLY install progress fixture"});
            }
            XCTAssertEqualWithAccuracy([[home valueForKey:@"displayProgress"]doubleValue],0.42,0.001);
            for(NSInteger pass=0;pass<3;++pass){[home.view setNeedsLayout];[home.view layoutIfNeeded];}
            assertPinnedCancel();
            XCTAssertEqual(navigation.viewControllers.count,1u);
            [self attachView:home.view name:[NSString stringWithFormat:@"TEST-ONLY resize/camera %@ %.0fx%.0f",home.fixtureRailSide,size.width,size.height]];
        }
        [host setOverrideTraitCollection:[UITraitCollection traitCollectionWithPreferredContentSizeCategory:UIContentSizeCategoryAccessibilityExtraExtraExtraLarge] forChildViewController:navigation];
        navigation.view.frame=CGRectMake(0,0,466,678);home.fixtureRailSide=@"right";
        for(NSInteger pass=0;pass<3;++pass){[navigation.view setNeedsLayout];[navigation.view layoutIfNeeded];[home.view setNeedsLayout];[home.view layoutIfNeeded];AITick();}
        XCTAssertEqualObjects(home.traitCollection.preferredContentSizeCategory,UIContentSizeCategoryAccessibilityExtraExtraExtraLarge);
        XCTAssertEqual(((UIStackView *)[home valueForKey:@"mainColumns"]).axis,UILayoutConstraintAxisVertical);
        XCTAssertGreaterThan(((UIButton *)[home valueForKey:@"taskHUDCancel"]).titleLabel.font.pointSize,17.0);
        UIScrollView *largeScroll=[home valueForKey:@"scroll"];
        XCTAssertGreaterThan(largeScroll.contentSize.height,largeScroll.bounds.size.height,@"Large-text fixture must exercise actual list scrolling.");
        assertPinnedCancel();
        [self attachView:home.view name:@"TEST-ONLY maximum accessibility text — pinned native task controls"];
        [host setOverrideTraitCollection:nil forChildViewController:navigation];
        UIBarButtonItem *settings=home.navigationItem.rightBarButtonItem;
        [UIApplication.sharedApplication sendAction:settings.action to:settings.target from:settings forEvent:nil];
        AITick();UIViewController *selected=navigation.topViewController;
        NSDictionary *homeReport=[home valueForKey:@"homeDisplayReportSnapshot"];
        XCTAssertNotNil(homeReport);
        XCTAssertEqualObjects(homeReport[@"geometry"][@"bounds"],homeReport[@"viewBounds"]);
        XCTAssertEqualObjects(homeReport[@"layout"][@"rootView"],homeReport[@"viewBounds"]);
        XCTAssertGreaterThan([homeReport[@"windowBounds"] count],0u,@"Home diagnostics must be captured while its own window is still attached.");
        for(NSValue *value in @[[NSValue valueWithCGSize:CGSizeMake(466,678)],[NSValue valueWithCGSize:CGSizeMake(669,951)],[NSValue valueWithCGSize:CGSizeMake(466,678)]]) {
            navigation.view.frame=(CGRect){CGPointZero,value.CGSizeValue};[navigation.view setNeedsLayout];[navigation.view layoutIfNeeded];
            XCTAssertEqual(navigation.topViewController,selected,@"Forced resize must preserve navigation state.");
            XCTAssertEqualWithAccuracy([[home valueForKey:@"displayProgress"]doubleValue],0.42,0.001);
        }
        NSDictionary *invalid=[AIDisplayDiagnostics geometryForBounds:CGRectMake(0,0,466,678) safeArea:UIEdgeInsetsMake(0,0,34,84) occlusions:@[[NSValue valueWithCGRect:CGRectMake(NAN,0,84,174)],[NSValue valueWithCGRect:CGRectMake(0,0,100000,100000)]] divisions:@[] source:@"TEST-ONLY invalid geometry"];
        XCTAssertEqual([invalid[@"occlusions"]count],0u);XCTAssertEqual([invalid[@"rail"]count],0u);
    } @finally {window.rootViewController=original;AIInstallerService.shared.eventHandler=originalHandler;}
    }];
}
// Inspect text in its laid-out label frame; scrolling is allowed, truncation is not.
- (void)assertReadableLabels:(UIView *)view {
    if(view.hidden || view.alpha<0.01)return;
    if([view isKindOfClass:UILabel.class]) {
        UILabel *label=(id)view;
        if(label.text.length || label.attributedText.length) {
            XCTAssertGreaterThan(label.bounds.size.width,0.0);
            CGSize needed=[label sizeThatFits:CGSizeMake(label.bounds.size.width,CGFLOAT_MAX)];
            XCTAssertLessThanOrEqual(needed.height,ceil(label.bounds.size.height)+1.0,@"Text must fit its own frame at the actual accessibility trait: %@",label.text);
        }
    }
    for(UIView *child in view.subviews)[self assertReadableLabels:child];
}
- (void)assertButtonReachable:(UIButton *)button scroll:(UIScrollView *)scroll root:(UIView *)root {
    XCTAssertNotNil(button);if(!button)return;
    XCTAssertGreaterThanOrEqual(button.bounds.size.width,44.0);
    XCTAssertGreaterThanOrEqual(button.bounds.size.height,44.0);
    XCTAssertGreaterThan(button.allTargets.count,0u,@"A visible action must keep its production target.");
    [scroll scrollRectToVisible:CGRectInset([button convertRect:button.bounds toView:scroll],0,-4) animated:NO];
    [root layoutIfNeeded];AITick();
    CGRect actual=[button convertRect:button.bounds toView:root];
    CGRect viewport=[scroll convertRect:scroll.bounds toView:root];
    XCTAssertGreaterThanOrEqual(CGRectGetMinY(actual),CGRectGetMinY(viewport)-1);
    XCTAssertLessThanOrEqual(CGRectGetMaxY(actual),CGRectGetMaxY(viewport)+1);
    CGPoint point=CGPointMake(CGRectGetMidX(actual),CGRectGetMidY(actual));
    UIView *hit=[root hitTest:point withEvent:nil];
    XCTAssertTrue(hit==button || [hit isDescendantOfView:button],@"The rendered action must own its actual logical touch point.");
}
- (void)test03AccessibilityTextKeepsControlsReadable {
    [self runOnMain:^{
    UIWindow *window=AIWaitForAppWindow();XCTAssertNotNil(window);if(!window)return;
    UIViewController *original=window.rootViewController;
    void (^originalHandler)(NSDictionary *)=AIInstallerService.shared.eventHandler;
    AICloudUITestGeometryHome *home=[AICloudUITestGeometryHome new];[home loadViewIfNeeded];
    AICloudUITestOnlyFixture *fixture=[AICloudUITestOnlyFixture new];[home setValue:fixture forKey:@"service"];
    UINavigationController *navigation=[[UINavigationController alloc]initWithRootViewController:home];
    UIViewController *host=[UIViewController new];
    @try {
        window.rootViewController=host;[host addChildViewController:navigation];
        [host.view addSubview:navigation.view];[navigation didMoveToParentViewController:host];
        navigation.view.autoresizingMask=UIViewAutoresizingNone;
        [host setOverrideTraitCollection:[UITraitCollection traitCollectionWithPreferredContentSizeCategory:UIContentSizeCategoryAccessibilityExtraExtraExtraLarge] forChildViewController:navigation];
        for(NSNumber *width in @[@390,@669]) {
            navigation.view.frame=CGRectMake(0,0,width.doubleValue,844);
            [home setValue:nil forKey:@"screen"];
            ((void (*)(id,SEL))objc_msgSend)(home,NSSelectorFromString(@"render"));
            for(NSInteger pass=0;pass<3;++pass){[navigation.view setNeedsLayout];[navigation.view layoutIfNeeded];[home.view setNeedsLayout];[home.view layoutIfNeeded];AITick();}
            XCTAssertEqualObjects(home.traitCollection.preferredContentSizeCategory,UIContentSizeCategoryAccessibilityExtraExtraExtraLarge);
            UILabel *heading=(id)AIFindView(home.view,^BOOL(UIView *v){return[v isKindOfClass:UILabel.class]&&[((UILabel *)v).text isEqual:@"Your apps. Your iPhone."];});
            XCTAssertNotNil(heading);XCTAssertGreaterThan(heading.font.pointSize,28.0,@"The public accessibility trait must actually enlarge production text.");
            UIView *content=[home valueForKey:@"content"];
            [self assertReadableLabels:content];
            [self checkVisibleTextBounds:content container:home.view width:home.view.bounds.size.width];
            UIScrollView *scroll=[home valueForKey:@"scroll"];
            UIButton *refresh=(id)AIFindView(content,^BOOL(UIView *v){return[v isKindOfClass:UIButton.class]&&[AIButtonTitle((id)v)isEqual:@"Refresh all"];});
            [self assertButtonReachable:refresh scroll:scroll root:home.view];
            XCTAssertGreaterThan(refresh.titleLabel.font.pointSize,17.0,@"The actual rendered button font must follow accessibility text size.");
            XCTAssertEqual(((UIStackView *)[home valueForKey:@"mainColumns"]).axis,UILayoutConstraintAxisVertical);
            [self attachView:home.view name:[NSString stringWithFormat:@"Actual UIKit maximum accessibility trait — TEST-ONLY main width %@",width]];
            UIBarButtonItem *settings=home.navigationItem.rightBarButtonItem;
            [UIApplication.sharedApplication sendAction:settings.action to:settings.target from:settings forEvent:nil];
            NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:3];
            do{AITick();}while(navigation.transitionCoordinator && deadline.timeIntervalSinceNow>0);
            UITableViewController *controller=(id)navigation.topViewController;
            XCTAssertTrue([controller isKindOfClass:UITableViewController.class]);
            if(![controller isKindOfClass:UITableViewController.class])return;
            UITableView *table=controller.tableView;
            XCTAssertEqualObjects(controller.traitCollection.preferredContentSizeCategory,UIContentSizeCategoryAccessibilityExtraExtraExtraLarge);
            for(NSInteger section=0;section<[table numberOfSections];++section)for(NSInteger row=0;row<[table numberOfRowsInSection:section];++row) {
                NSIndexPath *path=[NSIndexPath indexPathForRow:row inSection:section];
                [table scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionMiddle animated:NO];[table layoutIfNeeded];AITick();
                UITableViewCell *cell=[table cellForRowAtIndexPath:path];XCTAssertNotNil(cell);if(!cell)continue;
                XCTAssertGreaterThanOrEqual(cell.bounds.size.height,44.0);
                XCTAssertGreaterThan(cell.textLabel.font.pointSize,17.0);
                [self assertReadableLabels:cell.contentView];
                CGRect text=[cell.textLabel convertRect:cell.textLabel.bounds toView:cell];
                XCTAssertGreaterThanOrEqual(CGRectGetMinX(text),0.0);
                XCTAssertLessThanOrEqual(CGRectGetMaxX(text),cell.bounds.size.width+1);
                if(cell.accessoryView)XCTAssertFalse(CGRectIntersectsRect(text,cell.accessoryView.frame),@"Large text must not collide with the actual Settings accessory.");
                CGPoint center=[cell convertPoint:CGPointMake(CGRectGetMidX(cell.bounds),CGRectGetMidY(cell.bounds)) toView:controller.view];
                UIView *hit=[controller.view hitTest:center withEvent:nil];
                XCTAssertTrue(hit==cell || [hit isDescendantOfView:cell],@"Settings rows must remain reachable by their rendered position.");
            }
            [self attachView:controller.view name:[NSString stringWithFormat:@"Actual UIKit maximum accessibility trait — TEST-ONLY Settings width %@",width]];
            [navigation popToRootViewControllerAnimated:NO];AITick();
        }
    } @finally { [window endEditing:YES];window.rootViewController=original;AIInstallerService.shared.eventHandler=originalHandler; }
    }];
}
- (void)test04KeyboardKeepsFocusedFieldsReachable {
    [self runOnMain:^{
    UIWindow *window=AIWaitForAppWindow();XCTAssertNotNil(window);if(!window)return;
    UIViewController *original=window.rootViewController;
    void (^originalHandler)(NSDictionary *)=AIInstallerService.shared.eventHandler;
    AIHome *home=[AIHome new];[home loadViewIfNeeded];
    AICloudUITestOnlyFixture *fixture=[AICloudUITestOnlyFixture new];
    fixture.stateOverrides=@{@"loginStatus":@"signed_out",@"paired":@NO};[home setValue:fixture forKey:@"service"];
    UINavigationController *navigation=[[UINavigationController alloc]initWithRootViewController:home];
    __block NSUInteger keyboardNotifications=0;__block CGRect notifiedFrame=CGRectNull;
    id observer=[NSNotificationCenter.defaultCenter addObserverForName:UIKeyboardWillChangeFrameNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note){
        NSValue *value=note.userInfo[UIKeyboardFrameEndUserInfoKey];
        if(value){notifiedFrame=value.CGRectValue;keyboardNotifications+=1;}
    }];
    @try {
        window.rootViewController=navigation;
        ((void (*)(id,SEL))objc_msgSend)(home,NSSelectorFromString(@"render"));
        [navigation.view layoutIfNeeded];[home.view layoutIfNeeded];AITick();
        for(NSString *key in @[@"email",@"password",@"code"]) {
            if([key isEqual:@"code"]) {
                [home.view endEditing:YES];
                fixture.stateOverrides=@{@"loginStatus":@"needs_2fa",@"busy":@YES,@"unknown":@NO,@"paired":@NO};
                ((void (*)(id,SEL))objc_msgSend)(home,NSSelectorFromString(@"render"));
                [home.view layoutIfNeeded];AITick();
            }
            UITextField *field=[home valueForKey:key];XCTAssertNotNil(field);if(!field)return;
            // No credentials or plausible verification codes are entered or submitted.
            field.text=@"TEST ONLY — NONSECRET UI MARKER";
            XCTAssertTrue([field becomeFirstResponder]);
            NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:8];BOOL shown=NO;NSUInteger stableGuidePasses=0;CGRect previousGuide=CGRectNull;
            do{
                AITick();[home.view layoutIfNeeded];
                CGRect actualGuide=home.view.keyboardLayoutGuide.layoutFrame;
                shown=keyboardNotifications>0 && actualGuide.size.height>100;
                stableGuidePasses=shown && CGRectEqualToRect(actualGuide,previousGuide) ? stableGuidePasses+1 : 0;
                previousGuide=actualGuide;
            }while((!shown || stableGuidePasses<2) && deadline.timeIntervalSinceNow>0);
            CGRect guide=home.view.keyboardLayoutGuide.layoutFrame;
            CGRect focus=[field convertRect:field.bounds toView:home.view];
            UIScrollView *scroll=[home valueForKey:@"scroll"];
            CGRect viewport=[scroll convertRect:scroll.bounds toView:home.view];
            NSDictionary *observation=@{@"scope":@"Actual public first-responder keyboard and UIKit guide; TEST-ONLY form metadata; no account request",@"field":key,@"keyboardNotificationCount":@(keyboardNotifications),@"notifiedScreenFrame":[AIDisplayDiagnostics rect:notifiedFrame],@"guide":[AIDisplayDiagnostics rect:guide],@"focusedField":[AIDisplayDiagnostics rect:focus],@"scrollViewport":[AIDisplayDiagnostics rect:viewport],@"softwareKeyboardObserved":@(shown),@"physicalKeyboardOrPhoneVerified":@NO};
            XCTAttachment *proof=[XCTAttachment attachmentWithData:[NSJSONSerialization dataWithJSONObject:observation options:NSJSONWritingPrettyPrinted error:NULL] uniformTypeIdentifier:@"public.json"];
            proof.name=[@"Actual keyboard reachability — " stringByAppendingString:key];proof.lifetime=XCTAttachmentLifetimeKeepAlways;[self addAttachment:proof];
            XCTAssertTrue(shown,@"No genuine software keyboard was observed. Keyboard reachability remains untested; no fake keyboard frame is accepted.");
            if(!shown)return;
            XCTAssertTrue(field.isFirstResponder);
            XCTAssertLessThanOrEqual(CGRectGetMaxY(viewport),CGRectGetMinY(guide)+1);
            XCTAssertGreaterThanOrEqual(CGRectGetMinY(focus),CGRectGetMinY(viewport)-1,@"Production must reveal its focused field without test scrolling.");
            XCTAssertLessThanOrEqual(CGRectGetMaxY(focus),CGRectGetMaxY(viewport)+1);
            XCTAssertFalse(CGRectIntersectsRect(focus,guide));
            CGPoint center=CGPointMake(CGRectGetMidX(focus),CGRectGetMidY(focus));UIView *hit=[home.view hitTest:center withEvent:nil];
            XCTAssertTrue(hit==field || [hit isDescendantOfView:field]);
            UIButton *submit=[home valueForKey:@"submitButton"];
            [self assertButtonReachable:submit scroll:scroll root:home.view];
            XCTAssertLessThanOrEqual(CGRectGetMaxY([submit convertRect:submit.bounds toView:home.view]),CGRectGetMinY(guide)+1);
            field.text=nil;[field resignFirstResponder];
        }
    } @finally {
        [NSNotificationCenter.defaultCenter removeObserver:observer];[home.view endEditing:YES];
        for(NSString *key in @[@"email",@"password",@"code"]){UITextField *field=[home valueForKey:key];field.text=nil;}
        window.rootViewController=original;AIInstallerService.shared.eventHandler=originalHandler;
    }
    }];
}

@end
