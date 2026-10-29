#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
/* Native owner queue only; never register this as a WebView handler. */
@interface ODRuntimeForgeCompiler : NSObject
- (nullable instancetype)initWithTrustedCreatorCore:(NSURL *)coreURL
                                    compilerScript:(NSURL *)scriptURL
                                             error:(NSError * _Nullable * _Nullable)error;
/* Caller proves immutable accepted-project/version/scope first, reserves IDs on
 * the native writer transaction, then validates every returned SQLite row.
 * This class materializes data only; it cannot install rows or mint ownership.
 */
- (nullable NSDictionary *)materializeAcceptedProject:(NSDictionary *)project
                                         runtimeIDs:(NSArray<NSNumber *> *)runtimeIDs
                                       reservations:(NSArray<NSDictionary *> *)reservations
                                              floor:(NSInteger)floor
                                              error:(NSError * _Nullable * _Nullable)error;
/* Separate native-only full-bundle path. Copies and hashes exact accepted
 * project/definition/bundle bytes before materialization. The native owner must
 * independently verify the authoritative live full-bundle receipt and reserve
 * a contiguous 1--5 block cluster on its writer transaction. Resource-bearing
 * bundles stay behind a distinct closed gate until file/CPK rebase is proved.
 * Returns all native root/awakened rows and ordered member mappings. Neither
 * this method nor a JavaScript/native-byte-verification flag grants gameplay,
 * ownership or source-version authority. The old single-project API is intact.
 */
- (nullable NSDictionary *)materializeAcceptedFullBundle:(NSData *)fullBundleBytes
                                           projectBytes:(NSData *)projectBytes
                                        definitionBytes:(NSData *)definitionBytes
                                        acceptedBinding:(NSDictionary *)acceptedBinding
                                             runtimeIDs:(NSArray<NSNumber *> *)runtimeIDs
                                           reservations:(NSArray<NSDictionary *> *)reservations
                                                  floor:(NSInteger)floor
                                                  error:(NSError * _Nullable * _Nullable)error;
@end
NS_ASSUME_NONNULL_END
