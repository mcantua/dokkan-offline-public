#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
typedef BOOL (^ODNativeCreatorNetworkCurrent)(void);
typedef BOOL (^ODNativeCreatorURLAuthorization)(NSURL *url);
/** Native-only explicit tool request grant. AuthorizeURL runs once at mint on
 * the caller's native execution path. Current may run on ANY URL-loading thread:
 * it must use only thread-safe revocation/immutable scope, never UIKit or a
 * synchronous main dispatch. Redirects/new URL/body/auth require a fresh grant.
 * No token/header/JSON switch is exposed to Creator JS or original game code.
 * Decorate after final method/body/headers; body streams are unsupported.
 * HTTPS only, except an explicitly authorized 127.0.0.1 HTTP endpoint.
 * Original game/SDK requests lack this private ticket and remain local-only. */
FOUNDATION_EXPORT NSURLRequest *_Nullable ODNativeCreatorAuthorizedRequest(
    NSURLRequest *request,ODNativeCreatorNetworkCurrent current,
    ODNativeCreatorURLAuthorization authorizeURL,NSError * _Nullable * _Nullable error);
/** Transport-private check. A tag string/header is insufficient: the original
 * opaque ticket must belong to the native-issued weak identity registry. */
FOUNDATION_EXPORT BOOL ODNativeCreatorRequestIsAuthorized(NSURLRequest *request);
NS_ASSUME_NONNULL_END
