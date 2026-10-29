#import <Foundation/Foundation.h>
@class ODUnifiedDuoHost;
NS_ASSUME_NONNULL_BEGIN
/** Actual native-only integrated composition. Uses this app's admitted bundle
 * and one canonical Core; profile/scope preparation continues on native IO.
 * Original UI/auth initialization is separate from native-master/gameplay
 * acceptance. No page or configuration chooses inputs or grants acceptance. */
FOUNDATION_EXPORT ODUnifiedDuoHost * _Nullable ODCreateUnifiedDuoStartupHost(
    NSError * _Nullable * _Nullable error);
/** Main-only, value-free composition/host evidence. Never writes a report. */
FOUNDATION_EXPORT NSDictionary * _Nullable ODCopyUnifiedDuoNativeFactoryReport(void);
NS_ASSUME_NONNULL_END
