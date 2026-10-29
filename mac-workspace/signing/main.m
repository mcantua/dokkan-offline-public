#import <UIKit/UIKit.h>
// Provisioning helper only; never install this placeholder over the user's game.
@interface SigningApp : UIResponder <UIApplicationDelegate>
@property(nonatomic,strong) UIWindow *window;
@end
@implementation SigningApp
@end
int main(int argc, char *argv[]) { @autoreleasepool { return UIApplicationMain(argc,argv,nil,NSStringFromClass(SigningApp.class)); } }
