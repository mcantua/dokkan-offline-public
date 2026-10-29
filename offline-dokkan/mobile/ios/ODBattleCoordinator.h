#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
typedef void (^ODBattleCoordinatorReply)(id _Nullable result,NSString * _Nullable error);
typedef void (^ODBattleStorageRPC)(NSString *operation,NSDictionary *arguments,ODBattleCoordinatorReply reply);
/** Private native-owned JavaScriptCore worker. No context, storage or planning
 * capability is exposed to a page; public game messages get load/dispatch only. */
@interface ODBattleCoordinator : NSObject
- (instancetype)initWithContentID:(NSString *)contentID storage:(ODBattleStorageRPC)storage;
- (void)load:(ODBattleCoordinatorReply)reply;
- (void)dispatchCommand:(NSDictionary *)command reply:(ODBattleCoordinatorReply)reply;
// Native run coordinator only: never add these to a WebView message switch.
- (void)startTrustedPlan:(NSDictionary *)plan reply:(ODBattleCoordinatorReply)reply;
- (void)openTrustedPlan:(NSDictionary *)reference reply:(ODBattleCoordinatorReply)reply;
@end
NS_ASSUME_NONNULL_END
