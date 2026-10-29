#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
/** Actual owned collection and team choices; never grants characters or rewards. */
@interface ODCollectionController : UITableViewController
@property (nonatomic, copy, nullable) void (^lockCharacter)(NSNumber *instance, BOOL locked, void (^reply)(NSString * _Nullable error));
- (instancetype)initWithCharacters:(NSArray<NSDictionary *> *)characters
                         selected:(nullable NSArray<NSNumber *> *)selected
                         teamSlot:(NSInteger)slot
                             save:(nullable void (^)(NSArray<NSNumber *> *members, void (^reply)(NSString * _Nullable error)))save;
@end
NS_ASSUME_NONNULL_END
