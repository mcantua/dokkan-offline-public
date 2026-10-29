#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
/** Native foundation for our own original offline game; imported sources do not define game modes. */
@interface ODLocalHost : UIViewController
@property (nonatomic, readonly, nullable) NSDictionary *snapshot;
@property (nonatomic, readonly, nullable) NSString *lastError;
- (instancetype)initWithLibraryDirectory:(NSURL *)library saveDirectory:(NSURL *)saves;
#if OD_CLOUD_FIXTURES
// Explicit private cloud-fixture injection, excluded from distributable host builds.
- (instancetype)initWithDatabaseDirectory:(NSURL *)databases
                       contentIdentities:(NSArray<NSString *> *)contentIdentities
                           saveDirectory:(NSURL *)saves;
#endif
- (void)createPlayer;
- (void)refreshPlayer;
- (void)openCreator;
- (void)openCollection;
- (void)openTeams;
@end
NS_ASSUME_NONNULL_END
