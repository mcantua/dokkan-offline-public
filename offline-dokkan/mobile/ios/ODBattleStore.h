#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
/** Native-only single battle slot. Call serially from the trusted coordinator.
 * Persistence is not a win/reward/settlement authority. No caller supplies paths. */
@interface ODBattleStore : NSObject
- (instancetype)initWithDirectory:(NSURL *)directory source:(NSString *)source contentID:(NSString *)contentID;
- (nullable NSDictionary *)read:(NSError **)error;
/** nil token means absent; returns new opaque token, @NO on conflict, or nil on error. */
- (nullable id)compareAndSwap:(nullable NSString *)expectedToken data:(NSString *)data error:(NSError **)error;
@end
NS_ASSUME_NONNULL_END
