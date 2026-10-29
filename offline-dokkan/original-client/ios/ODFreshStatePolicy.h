#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
/** Fresh-state gate. Matches protocol/fresh-state-policy.js. Rank facts must
 * already agree between the canonical snapshot and source_rank. Tutorial
 * finished=true and zero capacities are rejected. Native-owned persisted
 * original_client_tutorial supplies its partial start/checkpoint fields;
 * migrated/missing state stays unresolved. The result lists unresolved
 * fields and does not copy player numbers, played-cache values, or a success
 * body. proposed may be nil. */
@interface ODFreshStatePolicy : NSObject
+ (nullable NSDictionary *)evaluateSnapshot:(NSDictionary *)snapshot
                           proposedSections:(nullable NSDictionary *)proposed
                                      error:(NSError * _Nullable * _Nullable)error;
@end
NS_ASSUME_NONNULL_END
