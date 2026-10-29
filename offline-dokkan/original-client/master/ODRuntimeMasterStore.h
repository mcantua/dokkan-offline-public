#import <Foundation/Foundation.h>
@class ODRuntimeForgeCompiler;
NS_ASSUME_NONNULL_BEGIN
/* Trusted native owner queue only. No WebView operation or arbitrary SQL.
 * Success is a compiled, detached artifact, never engine/resource admission.
 */
@interface ODRuntimeMasterStore : NSObject
- (nullable instancetype)initWithImmutableMaster:(NSURL *)master
                                  derivedMaster:(NSURL *)derived
                                      contentID:(NSString *)content
                                      saveScope:(NSString *)scope
                                       compiler:(ODRuntimeForgeCompiler *)compiler
                                          error:(NSError * _Nullable * _Nullable)error;
/* Packet must come directly from Session's accepted-version registry, not tools.
 * The authoritative owner independently proves the accepted instance/version.
 * Atomic replacement requires a cold engine attach/reload contract elsewhere.
 */
- (nullable NSDictionary *)compileAcceptedPacket:(NSDictionary *)packet error:(NSError * _Nullable * _Nullable)error;
@end
NS_ASSUME_NONNULL_END
