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
@end
NS_ASSUME_NONNULL_END
