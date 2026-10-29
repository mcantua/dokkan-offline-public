// SPDX-License-Identifier: MIT
#import <UIKit/UIKit.h>
@interface CheckController : UIViewController
@property(nonatomic,strong) UILabel *counter;
@end
@implementation CheckController
- (void)showCount { self.counter.text=[NSString stringWithFormat:@"Saved taps: %ld",(long)[NSUserDefaults.standardUserDefaults integerForKey:@"installationCheckTapCount"]]; }
- (void)tap { [NSUserDefaults.standardUserDefaults setInteger:([NSUserDefaults.standardUserDefaults integerForKey:@"installationCheckTapCount"]+1) forKey:@"installationCheckTapCount"]; [NSUserDefaults.standardUserDefaults synchronize]; [self showCount]; }
- (void)viewDidLoad {
    [super viewDidLoad]; self.view.backgroundColor=UIColor.systemBackgroundColor;
    UILabel *title=[UILabel new]; title.text=[NSString stringWithFormat:@"Installation Check v%@",[NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"]]; title.font=[UIFont preferredFontForTextStyle:UIFontTextStyleTitle2]; title.adjustsFontForContentSizeCategory=YES;
    UILabel *notice=[UILabel new]; notice.text=@"TEST ONLY\nThis is a tiny update/data-retention fixture. It does not verify App Installer, signing, refresh, or Duo behavior."; notice.numberOfLines=0;
    self.counter=[UILabel new]; self.counter.accessibilityIdentifier=@"savedTapCounter"; [self showCount];
    UIButton *button=[UIButton buttonWithType:UIButtonTypeSystem]; [button setTitle:@"Add one saved tap" forState:UIControlStateNormal]; [button addTarget:self action:@selector(tap) forControlEvents:UIControlEventTouchUpInside];
    UIStackView *stack=[[UIStackView alloc] initWithArrangedSubviews:@[title,notice,self.counter,button]]; stack.axis=UILayoutConstraintAxisVertical; stack.spacing=20; stack.translatesAutoresizingMaskIntoConstraints=NO; [self.view addSubview:stack];
    UILayoutGuide *safe=self.view.safeAreaLayoutGuide; [NSLayoutConstraint activateConstraints:@[[stack.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:24],[stack.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-24],[stack.topAnchor constraintEqualToAnchor:safe.topAnchor constant:24],[stack.bottomAnchor constraintLessThanOrEqualToAnchor:safe.bottomAnchor constant:-24],[button.heightAnchor constraintGreaterThanOrEqualToConstant:44]]];
}
@end
@interface CheckScene : UIResponder <UIWindowSceneDelegate>
@property(nonatomic,strong) UIWindow *window;
@end
@implementation CheckScene
- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)options { if (![scene isKindOfClass:UIWindowScene.class]) return; self.window=[[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene]; self.window.rootViewController=[CheckController new]; [self.window makeKeyAndVisible]; }
@end
@interface CheckApp : UIResponder <UIApplicationDelegate> @end
@implementation CheckApp @end
int main(int argc,char *argv[]) { @autoreleasepool { return UIApplicationMain(argc,argv,nil,NSStringFromClass(CheckApp.class)); } }
