#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
/** The one saved Offline Dokkan account. It shows the open player save.
 * It does not ask which source game to play. */
@interface ODDuoAccountController : UIViewController
@property (nonatomic, readonly) BOOL accountReady;
@property (nonatomic, copy, nullable) void (^setupGameData)(void);
- (void)applySnapshot:(nullable NSDictionary *)snapshot error:(nullable NSString *)error;
@end
NS_ASSUME_NONNULL_END
