#import <Foundation/Foundation.h>
@class ODScopedCreatorStorageContext;
NS_ASSUME_NONNULL_BEGIN
/** Native-only personal-source admission. Keys stay inside native RAM/Keychain;
 * the bridge receives only status and codec result files inside its workspace. */
@interface ODCreatorSourceCodec : NSObject
- (instancetype)initWithStorageContext:(ODScopedCreatorStorageContext *)storage NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
- (BOOL)isAdmitted;
- (NSDictionary *)status;
- (void)importAPKAtRelativePath:(NSString *)path reply:(void (^)(id _Nullable, NSString *_Nullable))reply;
@end
NS_ASSUME_NONNULL_END
