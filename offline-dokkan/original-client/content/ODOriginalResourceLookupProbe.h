#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
/** Optional native observation, never game/route/master readiness authority.
 * Call on main only after actual original initialization and a live original
 * scene. Uses fixed inventory-bound names, never page/request input. The
 * original resolver may populate its ordinary filename cache; no search path,
 * resource file, save, key, or singleton is created or changed by the host.
 */
@interface ODOriginalResourceLookupProbe : NSObject
- (instancetype)init NS_UNAVAILABLE;
/** Bounded explicit observation, not a per-frame callback. All report leaves
 * are booleans; native pointers, resolved paths and file bytes remain private.
 * Unavailable observation does not gate original startup or gameplay.
 */
- (NSDictionary *)observeForOriginalAppController:(id)originalAppController;
@end

/** Loader-internal issuance from its SAME admitted original image snapshot.
 * Resolves exact source function identities without calling getInstance or any
 * original function. Actual resolver calls happen only in the method above.
 */
FOUNDATION_EXPORT ODOriginalResourceLookupProbe * _Nullable
ODCreateOriginalResourceLookupProbeForAdmittedImage(NSURL *loadedImageURL,
    NSData *verifiedImage, NSError * _Nullable * _Nullable error);
NS_ASSUME_NONNULL_END
