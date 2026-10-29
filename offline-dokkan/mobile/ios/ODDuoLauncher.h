#import <UIKit/UIKit.h>
@class ODNativeCore, ODCreatorController, ODDuoAccountController, ODLocalHost;
NS_ASSUME_NONNULL_BEGIN
/** First screen of the unified Duo app. Offline Dokkan opens the one saved
 * account. Unit Creator opens the existing editor. Finish still imports into
 * that account's character collection. */
@interface ODDuoLauncher : UIViewController
- (instancetype)initWithCore:(nullable ODNativeCore *)core
                   masterURL:(nullable NSURL *)master
                   contentID:(nullable NSString *)contentID
                        game:(nullable NSString *)game
            creatorDirectory:(nullable NSURL *)directory;
- (instancetype)initWithLibraryDirectory:(NSURL *)library saveDirectory:(NSURL *)saves;
#if OD_CLOUD_FIXTURES
- (instancetype)initWithDatabaseDirectory:(NSURL *)databases
                       contentIdentities:(NSArray<NSString *> *)contentIdentities
                           saveDirectory:(NSURL *)saves;
#endif
- (void)openOfflineDokkan;
- (void)openUnitCreator;
@property (nonatomic, readonly, nullable) ODCreatorController *creatorController;
@property (nonatomic, readonly, nullable) ODDuoAccountController *accountController;
@property (nonatomic, readonly, nullable) ODLocalHost *savedAccountHost;
@end
NS_ASSUME_NONNULL_END
