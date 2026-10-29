#import <XCTest/XCTest.h>
#import "../../../offline-dokkan/mobile/ios/ODCreatorController.h"
#import "../../../offline-dokkan/mobile/ios/ODCreatorSession.h"
#import "../../../offline-dokkan/adapter/ios/ODNativeCore.h"

@interface ODCreatorMenuShotTests : XCTestCase
@end
@implementation ODCreatorMenuShotTests
- (void)testInGameCreatorMenuChrome {
    XCTestExpectation *done=[self expectationWithDescription:@"Creator menu chrome on the hosted Duo simulator"];
    dispatch_async(dispatch_get_main_queue(),^{
        NSString *library=NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSUserDomainMask,YES).firstObject;
        NSURL *master=[NSURL fileURLWithPath:[library stringByAppendingPathComponent:@"menu-master.db"]];
        [@"not-opened" writeToFile:master.path atomically:YES encoding:NSUTF8StringEncoding error:nil];
        NSString *identity=@"sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";
        NSString *scope=@"0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";
        NSURL *save=[NSURL fileURLWithPath:[library stringByAppendingPathComponent:@"menu-player.db"]];
        NSURL *directory=[NSURL fileURLWithPath:[library stringByAppendingPathComponent:@"menu-creator"] isDirectory:YES];
        [NSFileManager.defaultManager createDirectoryAtURL:directory withIntermediateDirectories:YES attributes:nil error:nil];
        ODNativeCore *core=[[ODNativeCore alloc] initWithSaveURL:save masterURL:master contentID:identity];
        ODCreatorSession *session=[[ODCreatorSession alloc] initWithMasterURL:master contentID:identity game:@"eclipse" directory:directory core:core originalClientSaveScopeSHA256:scope lease:nil];
        UIWindow *window=nil;
        for(UIScene *scene in UIApplication.sharedApplication.connectedScenes)
            if([scene isKindOfClass:UIWindowScene.class])
                for(UIWindow *candidate in ((UIWindowScene *)scene).windows)
                    if(candidate.isKeyWindow) window=candidate;
        ODCreatorController *controller=session?[[ODCreatorController alloc] initWithSession:session completion:^{}]:nil;
        if(!session.originalClientMode||!window||!controller){[done fulfill];XCTFail(@"The Creator menu window was not available.");return;}
        window.rootViewController=controller;[window makeKeyAndVisible];[controller loadViewIfNeeded];
        BOOL found=NO;
        for(UIView *view in controller.view.subviews)
            if([view isKindOfClass:UIButton.class]&&[[(UIButton *)view titleForState:UIControlStateNormal] isEqual:@"Menu"]) found=YES;
        XCTAssertTrue(found);
        if(!found){[done fulfill];return;}
        [@"ready" writeToFile:[library stringByAppendingPathComponent:@"creator-menu-ready"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,12*NSEC_PER_SEC),dispatch_get_main_queue(),^{
            UIGraphicsImageRenderer *renderer=[[UIGraphicsImageRenderer alloc] initWithSize:window.bounds.size];
            UIImage *image=[renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
                [window drawViewHierarchyInRect:window.bounds afterScreenUpdates:YES];
            }];
            NSData *png=UIImagePNGRepresentation(image);
            XCTAssertTrue(png.length>0&&[png writeToFile:[library stringByAppendingPathComponent:@"creator-in-game-menu-window.png"] atomically:YES]);
            [done fulfill];
        });
    });
    [self waitForExpectations:@[done] timeout:30];
}
@end
