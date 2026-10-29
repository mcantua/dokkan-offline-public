#import <Foundation/Foundation.h>
@class ODNativeCore;
NS_ASSUME_NONNULL_BEGIN
/** Native one-use preparation capability for the exact canonical Core object.
 * It grants no guessed save scope. Main can schedule preparation before shell
 * main and receive the real receipt later on the ordinary main run loop, with
 * no synchronous main wait/spin. No WebView/JSON operation exposes this object. */
@interface ODDeferredOriginalPlayerAdmission : NSObject
- (instancetype)init NS_UNAVAILABLE;
- (nullable instancetype)initWithCore:(ODNativeCore *)core saveURL:(NSURL *)save
    masterURL:(NSURL *)master contentID:(NSString *)content;
/** Immutable captured owner identity; no connection/file is opened by getters. */
@property(nonatomic,strong,readonly) ODNativeCore *core;
@property(nonatomic,copy,readonly) NSString *contentID;
/** Main-only. Nil until the actual owner preparation succeeds. Contains only
 * the actual admission metadata, not the player snapshot or source account. */
@property(nonatomic,copy,readonly,nullable) NSDictionary *preparedAdmission;
- (BOOL)matchesCore:(ODNativeCore *)core contentID:(NSString *)content;
/** Call once on main; queue must be a native IO preparation queue. Core still
 * refuses execution on main/any Core owner queue. Completion is async on main
 * and uses fixed errors only. No UI, route admission or service binding occurs. */
- (void)prepareOnQueue:(dispatch_queue_t)queue
    completion:(void (^)(NSError * _Nullable error))completion;
@end
NS_ASSUME_NONNULL_END
