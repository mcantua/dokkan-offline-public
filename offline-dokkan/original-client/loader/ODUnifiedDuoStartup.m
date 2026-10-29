#import "ODUnifiedDuoStartup.h"
#import "../duo/ODUnifiedDuoHost.h"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

static BOOL ODStartupAttempted;
static ODUnifiedDuoHost *ODStartupHost;

static NSError *ODStartupFailure(void) {
    return [NSError errorWithDomain:@"OfflineDokkan.StartupComposition" code:1
        userInfo:@{NSLocalizedDescriptionKey:@"The original-game startup composition is unavailable. No substitute game screen was opened."}];
}

BOOL ODInstallUnifiedDuoStartupFromFactory(ODUnifiedDuoStartupFactory factory, NSError **error) {
    if (!NSThread.isMainThread || ODStartupAttempted || !factory) {
        if (error) *error = ODStartupFailure();
        return NO;
    }
    ODStartupAttempted = YES;
    @try {
        NSError *failure = nil;
        ODUnifiedDuoHost *candidate = factory(&failure);
        if (![candidate isKindOfClass:ODUnifiedDuoHost.class] ||
            ![candidate.startupReport[@"purpose"] isEqual:@"integrated-duo-target"]) {
            if (error) *error = ODStartupFailure();
            return NO;
        }
        if (![candidate installBeforeApplicationMain:&failure]) {
            // Never forward a factory's arbitrary error or native file path.
            if (error) *error = ODStartupFailure();
            return NO;
        }
        ODStartupHost = candidate;
        return ODStartupHost != nil;
    } @catch (NSException *exception) {
        (void)exception;
        if (error) *error = ODStartupFailure();
        return NO;
    }
}

/* Component libraries and hosted Finish fixtures must not acquire a process
 * constructor merely because they reuse this source. Only the explicitly
 * selected original-game production entry enables this path. */
#if defined(OD_UNIFIED_DUO_STARTUP_ENTRY) && OD_UNIFIED_DUO_STARTUP_ENTRY
__attribute__((constructor)) static void ODStartUnifiedOriginalDuo(void) {
    @autoreleasepool {
        if (!ODCreateUnifiedDuoStartupHost ||
            !ODInstallUnifiedDuoStartupFromFactory(ODCreateUnifiedDuoStartupHost, NULL)) {
            fputs("Offline Dokkan: original-game startup composition failed.\n", stderr);
            _exit(EXIT_FAILURE);
        }
    }
}
#endif
