#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

/** Native-only access to the unchanged original codec. The opaque context is
 * returned/owned by the original engine and passed directly to that engine's
 * codec. It is never inspected, retained in this capability, exported or saved.
 * All methods run on main. The route owner separately enforces original request
 * provenance and the same current Core/profile/master context before a write.
 */
@interface ODOriginalRequestDecoder : NSObject
- (instancetype)init NS_UNAVAILABLE;
@property(nonatomic,readonly) BOOL verifiedForCurrentEngine;
@property(nonatomic,copy,readonly) NSString *state;
/** Actual native encode/decode of one fixed own JSON probe. Only after original
 * initialization with an active original scene and no pending scene; never
 * accepts HTTP/page-provided probe data. Reuses
 * a successful check while the same engine is current. No gameplay claim. */
- (BOOL)verifyWithOwnJSONForAppController:(id)originalAppController
                                  error:(NSError * _Nullable * _Nullable)error;
/** Exact original POST body, not a plain replacement payload. Requires the
 * current engine's successful native self-check. Strict bounded outer envelope,
 * canonical base64 and minimum prefix/payload checks precede native decoding.
 * The returned object is in-memory request JSON, not trusted progression data;
 * the route must still validate every field before applying its Core command.
 */
- (nullable NSDictionary *)decodeOriginalPOSTBody:(NSData *)body
                                           error:(NSError * _Nullable * _Nullable)error;
@end

/** Loader-internal issuance after its existing image verification/dlopen, using
 * the SAME verified byte snapshot. Resolves original function identities and
 * the context getter's actual source BL target; never reads its provider body
 * or any embedded/runtime key characters. Issuance does not enable decoding.
 */
FOUNDATION_EXPORT ODOriginalRequestDecoder * _Nullable
ODCreateOriginalRequestDecoderForAdmittedImage(NSURL *loadedImageURL,
    NSData *verifiedImage, NSError * _Nullable * _Nullable error);
NS_ASSUME_NONNULL_END
