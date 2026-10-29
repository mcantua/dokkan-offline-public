#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
/* Native scoped storage capability. Return a fresh READONLY regular-file FD;
 * ownership transfers to validator. Never construct this from a WebView path.
 */
typedef int (^ODFullCreatorOpenAsset)(NSString *assetKey,NSError * _Nullable * _Nullable error);
@interface ODNativeFullCreatorValidator : NSObject
@property(nonatomic, readonly, copy) NSString *profileID;
@property(nonatomic, readonly, copy) NSString *contentID;
@property(nonatomic, readonly, copy) NSString *saveScope;
- (nullable instancetype)initWithCreatorCoreURL:(NSURL *)core
                       sparkingDependenciesURL:(NSURL *)dependencies
                                     masterURL:(NSURL *)master
                         immutableResourceRoot:(NSURL *)resourceRoot
                                     contentID:(NSString *)content
                                     profileID:(NSString *)profile
                                     saveScope:(NSString *)scope
                                     openAsset:(nullable ODFullCreatorOpenAsset)openAsset
                                         error:(NSError * _Nullable * _Nullable)error;
/* Context: definitionId,version,rarity,materializationUTC (native intent time in
 * milliseconds), optional creatorId/creatorName/statPolicy. Reuse exact context
 * on final validation. The selected master is hashed first; its digest must
 * match the content id. Known references and shared dependencies are checked
 * before any save. Returns definition + exact full_bundle_bytes/hash,
 * original project SHA, source_sha256, member_count, materialization_utc.
 * Assets are captured in private immutable blobs and a duplicate hash is kept
 * only when those stored bytes match. No ownership, Session, or engine grant.
 */
- (nullable NSDictionary *)validateProjectBytes:(NSData *)project
                                       context:(NSDictionary *)context
                                         error:(NSError * _Nullable * _Nullable)error;
@end
NS_ASSUME_NONNULL_END
