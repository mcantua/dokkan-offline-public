#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
/** Native-only cold capability. Its URL stays in memory and must never be
 * logged, serialized or supplied by a page/configuration. The exact admitted
 * loaded engine supplies the current host and port. No first request is trusted.
 * All creation/current checks run serially on main before AppDelegate requests. */
@interface ODOriginalNativeOrigin : NSObject
- (instancetype)init NS_UNAVAILABLE;
@property(nonatomic,copy,readonly) NSURL *origin;
- (BOOL)isCurrentForLoadedOriginalImage;
@end

/** Loader-internal issuance after its existing whole-image verification and
 * successful dlopen. verifiedImage is the SAME verified byte snapshot, not an
 * independently supplied recipe. No actual endpoint values are published. */
FOUNDATION_EXPORT ODOriginalNativeOrigin * _Nullable ODCreateOriginalNativeOriginForAdmittedImage(
    NSURL *loadedImageURL, NSData *verifiedImage, NSError * _Nullable * _Nullable error);
NS_ASSUME_NONNULL_END
