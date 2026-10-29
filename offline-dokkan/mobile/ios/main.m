#import <UIKit/UIKit.h>
#import "ODLocalHost.h"
@interface ODLocalScene : UIResponder <UIWindowSceneDelegate>
@property (nonatomic, strong) UIWindow *window;
@end
@implementation ODLocalScene
- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)options {
    if (![scene isKindOfClass:UIWindowScene.class]) return;
    NSURL *support = [NSFileManager.defaultManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask].firstObject;
#if OD_CLOUD_FIXTURES
    NSURL *databases = [NSBundle.mainBundle.resourceURL URLByAppendingPathComponent:@"db"];
    NSData *data = [NSData dataWithContentsOfURL:[NSBundle.mainBundle.resourceURL URLByAppendingPathComponent:@"cloud-data-provenance.json"]];
    NSDictionary *meta = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
    NSMutableArray *identities = [NSMutableArray array];
    for (NSString *game in @[@"eclipse", @"sparking"]) {
        NSString *hash = meta[game][@"reconstructed_sha256"];
        if (![hash isKindOfClass:NSString.class] || hash.length != 64) { identities = nil; break; }
        [identities addObject:[@"sha256:" stringByAppendingString:hash]];
    }
    ODLocalHost *host = [[ODLocalHost alloc] initWithDatabaseDirectory:databases contentIdentities:identities ?: @[] saveDirectory:[support URLByAppendingPathComponent:@"OfflineDokkan"]];
#else
    // Distributable own-app host contains no Bandai/game database or assets.
    ODLocalHost *host = [[ODLocalHost alloc] initWithLibraryDirectory:[support URLByAppendingPathComponent:@"OfflineDokkan/masters"] saveDirectory:[support URLByAppendingPathComponent:@"OfflineDokkan"]];
#endif
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene]; self.window.rootViewController = host; [self.window makeKeyAndVisible];
}
@end
@interface ODLocalApp : UIResponder <UIApplicationDelegate>
@end
@implementation ODLocalApp
@end
int main(int argc, char *argv[]) { @autoreleasepool { return UIApplicationMain(argc, argv, nil, NSStringFromClass(ODLocalApp.class)); } }
