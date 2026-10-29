#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/** Read-only preflight against the supplied 6.6.0 arm64 client's observed ObjC ABI.
 * Does not swizzle, invoke the source patcher, or claim that wire schemas are known. */
FOUNDATION_EXPORT BOOL ODVerifySuppliedGameHTTPABI(NSError **error);
NS_ASSUME_NONNULL_END
