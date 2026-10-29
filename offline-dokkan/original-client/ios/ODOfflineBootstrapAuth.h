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
/** Known PingAPI response shape. Omitted address fields retain existing native
 * configuration through its actual default-get path. skip_device_token=true
 * is an explicit local offline policy; no device identifier is supplied. */
+ (nullable NSDictionary *)pingPlainJSONCandidate;
/** Creates ping, nonce and sign-in candidate handlers; does not install them.
 * The unified host reserves these paths and wraps only its internally created
 * handlers with canonical owner/scope checks. Only for a trusted native owner.
 * A caller must serialize every handler and contextIsCurrent on the SAME queue;
 * the host wrapper uses main, not the transport queue. Tokens stay in memory,
 * rotate on nonce requests and expire. The local
 * identity does not forward or validate source-server credentials. */
+ (nullable NSArray<ODLocalTransportRoute *> *)candidateRoutesWithExpiresIn:(int32_t)expiresIn
                                                        contextIsCurrent:(BOOL (^)(void))contextIsCurrent
                                                                    error:(NSError * _Nullable * _Nullable)error;
@end
NS_ASSUME_NONNULL_END
