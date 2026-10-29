#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
/** Synchronous private master import. Call from a native worker queue, never a WebView/client path. */
@interface ODMasterLibrary : NSObject
- (instancetype)initWithDirectory:(NSURL *)directory;
- (nullable NSDictionary *)activeSelection:(NSError **)error;
// Explicit source-data setup only. Call from a native worker; network/validation callbacks use its private delegate queue.
- (void)downloadDatabaseForSource:(NSString *)source progress:(void(^)(int64_t,int64_t))progress completion:(void(^)(NSDictionary * _Nullable,NSError * _Nullable))completion;
- (void)cancelDownload;
- (BOOL)activateSource:(NSString *)source error:(NSError **)error;
- (nullable NSDictionary *)selectionForGame:(NSString *)game error:(NSError **)error;
- (nullable NSDictionary *)importURL:(NSURL *)source game:(NSString *)game error:(NSError **)error;
@end
NS_ASSUME_NONNULL_END
