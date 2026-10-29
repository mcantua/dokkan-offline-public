#import <Foundation/Foundation.h>
#import "../ios/ODLocalURLProtocol.h"
@class ODBoundOriginalCreatorServices;
NS_ASSUME_NONNULL_BEGIN
/** Native local-player checkpoint persistence for the original tutorial.
 * Uses the existing bound Core only; never constructs another player, sequence,
 * tutorial battle, temporary team or database. No WebView entry is added.
 * Current registration stays closed until final request preparation/body/query
 * is proved. Plain {} is issued only after a matching canonical commit.
 */
@interface ODTutorialCheckpointAdapter : NSObject
- (nullable instancetype)initWithBoundServices:(ODBoundOriginalCreatorServices *)services
    contentID:(NSString *)contentID saveScopeSHA256:(NSString *)scope
    contextIsCurrent:(BOOL (^)(void))current;
- (instancetype)init NS_UNAVAILABLE;
/** Construct an immutable exact native route only when the full current-client
 * request contract is admitted. Does not install/register the route itself.
 * Currently returns nil: final pre-send preparation is still being traced.
 */
- (nullable ODLocalTransportRoute *)checkpointRouteWithError:(NSError * _Nullable * _Nullable)error;
@property(nonatomic,readonly,copy) NSDictionary *sourceReadiness;
@end
NS_ASSUME_NONNULL_END
