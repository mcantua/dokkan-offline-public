#import <Foundation/Foundation.h>
@class ODUnifiedDuoHost;

NS_ASSUME_NONNULL_BEGIN
/** Native original-client startup only. This factory does not install auth
 * responses, fabricate a player, activate a derived master or enable Creator.
 * It requires the original resources to have been staged in this app's real
 * Documents/assets directory. Missing inputs fail; no empty substitute tree is
 * created. The caller must retain/install the result before shell main. */
FOUNDATION_EXPORT ODUnifiedDuoHost * _Nullable ODCreateOriginalDuoStartupDiagnosticHost(
    NSError * _Nullable * _Nullable error);

/** Latest native host report, main thread only. No file is written and no
 * request headers, bodies, account identifiers or network addresses are added. */
FOUNDATION_EXPORT NSDictionary * _Nullable ODCopyOriginalDuoStartupDiagnosticReport(void);
NS_ASSUME_NONNULL_END
