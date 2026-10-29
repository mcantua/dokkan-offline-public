#import <Foundation/Foundation.h>
@class ODScopedCreatorStorageContext,ODScopedCreatorHost;
NS_ASSUME_NONNULL_BEGIN
/** Opaque readonly handles for verifying staged import candidates only.
 * No selected-master handle, writable flag, SQL text or filesystem authority is
 * returned to a page. Native read kinds mirror the existing verifier's queries. */
@interface ODCreatorSourceDatabases : NSObject
- (instancetype)initWithStorageContext:(ODScopedCreatorStorageContext *)storage
    host:(ODScopedCreatorHost *)host NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
- (void)handleMessage:(NSDictionary *)message reply:(void (^)(id _Nullable,NSString *_Nullable))reply;
- (void)invalidate;
@end
NS_ASSUME_NONNULL_END
