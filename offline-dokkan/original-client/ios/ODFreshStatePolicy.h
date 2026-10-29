#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
/** Fresh-state gate. Matches protocol/fresh-state-policy.js. Rank facts must
 * already agree between the canonical snapshot and source_rank. Tutorial
 * caller-proposed finished flags and zero capacities are rejected. Native-owned
 * original_client_tutorial preserves old unfinished checkpoints or the exact
 * authorized new-profile skip tuple (progress0, finished=true);
 * migrated/missing state stays unresolved. The result lists unresolved
 * fields and does not copy player numbers, played-cache values, or a success
 * body. proposed may be nil. */
@interface ODFreshStatePolicy : NSObject
+ (nullable NSDictionary *)evaluateSnapshot:(NSDictionary *)snapshot
                           proposedSections:(nullable NSDictionary *)proposed
                                      error:(NSError * _Nullable * _Nullable)error;
@end
NS_ASSUME_NONNULL_END
