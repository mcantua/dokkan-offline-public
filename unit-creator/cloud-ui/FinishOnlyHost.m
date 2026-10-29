// Internal hosted WK component diagnostic. Not an Offline Dokkan game client.
#import <UIKit/UIKit.h>
@interface ODFinishScene : UIResponder <UIWindowSceneDelegate>
@property(nonatomic,strong) UIWindow *window;
@end
@implementation ODFinishScene
- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)options {
    if(![scene isKindOfClass:UIWindowScene.class])return;
    self.window=[[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.rootViewController=[UIViewController new];
    self.window.rootViewController.view.backgroundColor=UIColor.systemBackgroundColor;
    [self.window makeKeyAndVisible];
}
@end
@interface ODFinishApp : UIResponder <UIApplicationDelegate>
@end
@implementation ODFinishApp
@end
int main(int argc,char *argv[]) {@autoreleasepool{return UIApplicationMain(argc,argv,nil,NSStringFromClass(ODFinishApp.class));}}
