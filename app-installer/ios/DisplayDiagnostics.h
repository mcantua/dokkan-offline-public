#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
/// Geometry and opt-in display reports. Never reads account fields, device IDs or credentials.
@interface AIDisplayDiagnostics : NSObject
+ (NSDictionary *)geometryForView:(UIView *)view;
/// Pure geometry entry point also used by explicitly labelled simulator fixtures.
+ (NSDictionary *)geometryForBounds:(CGRect)bounds safeArea:(UIEdgeInsets)safeArea occlusions:(NSArray<NSValue *> *)occlusions divisions:(NSArray<NSValue *> *)divisions source:(NSString *)source;
+ (NSDictionary *)reportForView:(UIView *)view geometry:(NSDictionary *)geometry layout:(NSDictionary *)layout state:(NSDictionary *)state;
+ (NSDictionary *)rect:(CGRect)rect;
@end
@interface AIDisplayReportController : UIViewController
- (instancetype)initWithProvider:(NSDictionary * (^)(UIView *view))provider;
@end
NS_ASSUME_NONNULL_END
