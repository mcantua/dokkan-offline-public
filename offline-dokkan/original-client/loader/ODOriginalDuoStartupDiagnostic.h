#import <Foundation/Foundation.h>
@class ODUnifiedDuoHost;

NS_ASSUME_NONNULL_BEGIN
/** Native original-client startup only. This factory does not install auth
 * responses, fabricate a player, activate a derived master or enable Creator.
 * The original bundle paths stay intact. The existing FD preloader publishes
 * only the pinned compatible aliases into this app's actual Documents/assets
 * before engine loading. Missing sources fail; an empty directory cannot
 * substitute for verified bytes. Retain/install the result before shell main. */
FOUNDATION_EXPORT ODUnifiedDuoHost * _Nullable ODCreateOriginalDuoStartupDiagnosticHost(
    NSError * _Nullable * _Nullable error);

/** Latest native host report plus the actual post-AppController-launch master
 * observation when available, main thread only. Cache presence is not master
 * selection/schema acceptance. No file is written and no request headers,
 * bodies, account identifiers, pointers or network addresses are added. */
FOUNDATION_EXPORT NSDictionary * _Nullable ODCopyOriginalDuoStartupDiagnosticReport(void);
NS_ASSUME_NONNULL_END
