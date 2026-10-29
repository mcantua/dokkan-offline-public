#import <Foundation/Foundation.h>
#import "ODResourceResponseProjector.h"

NS_ASSUME_NONNULL_BEGIN
typedef void (^ODOriginalPracticePhaseReply)(NSData *_Nullable unchangedParametersJSON,
    NSDictionary *_Nullable sourceReceipt,NSError *_Nullable error);

/** Read-only source data for a manually requested borrowed-loadout battle.
 * The trusted native factory supplies its actual Core, scope and selected
 * master URL/pin. This never opens another Core, reads a save path, grants
 * units, changes a team or claims native engine/master admission. */
@interface ODOriginalPracticePhaseProvider : NSObject
- (nullable instancetype)initWithCore:(ODNativeCore *)core profileID:(NSString *)profile
    expectedSaveScopeSHA256:(NSString *)scope masterURL:(NSURL *)masterURL
    masterByteCount:(uint64_t)bytes masterSHA256:(NSString *)masterSHA256
    contextCurrent:(ODResourceContextCurrent)current;
/** May be requested from any queue; predicates and completion run on main.
 * The private IO queue reads only the exact pinned master phase3 row.
 * JSON bytes remain unchanged for the original native begin/end parser. */
- (void)loadPhase3WithReply:(ODOriginalPracticePhaseReply)reply;
- (instancetype)init NS_UNAVAILABLE;
@end
NS_ASSUME_NONNULL_END
