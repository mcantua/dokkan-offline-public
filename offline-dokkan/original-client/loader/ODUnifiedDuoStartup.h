#import <Foundation/Foundation.h>
@class ODUnifiedDuoHost;

NS_ASSUME_NONNULL_BEGIN
/** Native, compiled composition only. The factory owns selection of admitted
 * engine/baseline/resources, local routes and same-player Creator services.
 * It must return an integrated target, not the account or battle harness.
 * No JSON/page configuration may supply executable code or this factory. */
typedef ODUnifiedDuoHost * _Nullable (*ODUnifiedDuoStartupFactory)(NSError * _Nullable * _Nullable error);

/** Install once on main, before the preserved shell reaches UIApplicationMain.
 * A NO result is fatal to the production caller: never fall back to the old
 * shell UI. This does not establish gameplay or network/runtime acceptance. */
FOUNDATION_EXPORT BOOL ODInstallUnifiedDuoStartupFromFactory(
    ODUnifiedDuoStartupFactory factory, NSError * _Nullable * _Nullable error);

/* The production entry resolves the trusted compiled native composition in
 * ODUnifiedDuoNativeFactory.m. A missing factory still stops before shell main.
 * Its original initialization/user gates are separate from native master and
 * actual gameplay acceptance; linking the factory does not prove either. */
#if defined(OD_UNIFIED_DUO_STARTUP_ENTRY) && OD_UNIFIED_DUO_STARTUP_ENTRY
FOUNDATION_EXPORT ODUnifiedDuoHost * _Nullable ODCreateUnifiedDuoStartupHost(
    NSError * _Nullable * _Nullable error) __attribute__((weak_import));
#endif
NS_ASSUME_NONNULL_END
