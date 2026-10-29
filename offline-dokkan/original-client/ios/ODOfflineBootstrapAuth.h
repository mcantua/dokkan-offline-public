#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
/** Local reader-relative auth candidate. Matches protocol/bootstrap-auth.js.
 * Does not build an HTTP body, choose a JSON root wrapper, or admit
 * GET /auth/nonce or POST /auth/sign_in. expiresIn is a caller-supplied
 * signed32 second count, not a recovered server TTL. nativeTime is time(NULL)
 * in signed32 range. The returned dictionary holds the local token; do not
 * log it, write it, or transmit it. No source or server key is used. */
@interface ODOfflineBootstrapAuth : NSObject
+ (nullable NSDictionary *)issueWithNativeTime:(int32_t)nativeTime
                                     expiresIn:(int32_t)expiresIn
                                         error:(NSError * _Nullable * _Nullable)error;
@end
NS_ASSUME_NONNULL_END
