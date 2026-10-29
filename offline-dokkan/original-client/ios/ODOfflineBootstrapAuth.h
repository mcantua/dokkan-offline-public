#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
@class ODLocalTransportRoute;
/** Local auth candidates. Matches protocol/bootstrap-auth.js.
 * The base issueWithNativeTime method does not build an HTTP body or admit
 * GET /auth/nonce or POST /auth/sign_in. expiresIn is a caller-supplied
 * signed32 second count, not a recovered server TTL. nativeTime is time(NULL)
 * in signed32 range. The returned dictionary holds the local token; do not
 * log it, write it, or transmit it. No source or server key is used. */
@interface ODOfflineBootstrapAuth : NSObject
+ (nullable NSDictionary *)issueWithNativeTime:(int32_t)nativeTime
                                     expiresIn:(int32_t)expiresIn
                                         error:(NSError * _Nullable * _Nullable)error;
/** Encodes both candidate bodies once, sharing the same in-memory local issue.
 * The original client's non-zstd JSON path uses the document root directly.
 * Returned strings remain private in memory; no transport, complete sign-in
 * response, runtime acceptance or route authority is supplied by this API. */
+ (nullable NSDictionary *)issuePlainJSONWithNativeTime:(int32_t)nativeTime
                                              expiresIn:(int32_t)expiresIn
                                                  error:(NSError * _Nullable * _Nullable)error;
/** Creates two candidate handlers; does not install or admit them.
 * The unified host still rejects auth routes until the remaining startup and
 * request contracts are verified. Only for a trusted native offline owner.
 * contextIsCurrent runs on the local transport serial queue and must be safe
 * there. Tokens stay in memory, rotate on nonce requests and expire. The local
 * identity does not forward or validate source-server credentials. */
+ (nullable NSArray<ODLocalTransportRoute *> *)candidateRoutesWithExpiresIn:(int32_t)expiresIn
                                                        contextIsCurrent:(BOOL (^)(void))contextIsCurrent
                                                                    error:(NSError * _Nullable * _Nullable)error;
@end
NS_ASSUME_NONNULL_END
