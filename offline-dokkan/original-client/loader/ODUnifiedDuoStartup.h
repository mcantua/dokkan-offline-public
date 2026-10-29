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

/* The production entry's factory is supplied by trusted compiled composition.
 * It is intentionally not invented by this module while the current-client
 * response and master-open contracts remain unresolved. A missing factory
 * makes the explicitly enabled production entry stop before shell main. */
#if defined(OD_UNIFIED_DUO_STARTUP_ENTRY) && OD_UNIFIED_DUO_STARTUP_ENTRY
FOUNDATION_EXPORT ODUnifiedDuoHost * _Nullable ODCreateUnifiedDuoStartupHost(
    NSError * _Nullable * _Nullable error) __attribute__((weak_import));
#endif
NS_ASSUME_NONNULL_END
