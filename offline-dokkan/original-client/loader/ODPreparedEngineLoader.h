#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
/** Establish concrete native pre-load state before original initialization:
 * installed local transport, native-owned paths and excluded source patcher.
 * No page/config JSON can grant this capability. A native-selected startup
 * diagnostic may initialize the authorized client without pretending every
 * initializer was statically audited. Foundation interception is not raw-socket,
 * WebKit-subprocess or kernel isolation; offline behavior needs runtime proof. */
typedef BOOL (^ODPreparedEngineEnvironment)(NSError * _Nullable * _Nullable error);
/** Loads only the hash-pinned private adapted engine, optionally re-signed with
 * an appended signature. No original source patcher bytes are required/shipped.
 * Keeps the image resident; ObjC/game objects cannot safely survive dlclose.
 * Caller must stop startup on failure, and still verify actual HTTP/scene ABI.
 * This API does not make a prepared candidate a verified runnable game. */
FOUNDATION_EXPORT BOOL ODLoadPreparedOriginalEngine(NSURL *preparedImageURL,
    ODPreparedEngineEnvironment configureReviewedEnvironment,
    NSError * _Nullable * _Nullable error);
NS_ASSUME_NONNULL_END
