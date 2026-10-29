#import "ODUnifiedDuoStartup.h"
#import "../duo/ODUnifiedDuoHost.h"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

static BOOL ODStartupAttempted;
static ODUnifiedDuoHost *ODStartupHost;

static NSString *ODStartupFixedStage(id candidate) {
    if(![candidate isKindOfClass:NSString.class])return @"startup-stage-unavailable";
    NSArray<NSString *> *allowed=@[@"entry-precondition-failed",@"factory-precondition-failed",
        @"native-startup-inputs-unavailable",@"canonical-reference-unavailable",@"canonical-core-unavailable",
        @"native-resource-routes-unavailable",@"native-host-configuration-unavailable",@"opaque-source-candidate-preparation-failed",
        @"deferred-player-configuration-unavailable",@"offline-auth-route-configuration-unavailable",
        @"request-observer-registration-failed",@"prepared-image-load-failed",
        @"native-origin-route-binding-failed",@"native-image-attachment-failed",
        @"bootstrap-installation-failed",@"factory-result-unavailable",@"startup-exception"];
    return [allowed containsObject:candidate]?candidate:@"startup-stage-unavailable";
}
static NSError *ODStartupFailure(id stage) {
    return [NSError errorWithDomain:@"OfflineDokkan.StartupComposition" code:1
        userInfo:@{NSLocalizedDescriptionKey:@"The original-game startup composition is unavailable. No substitute game screen was opened.",
            @"startupStage":ODStartupFixedStage(stage)}];
}

BOOL ODInstallUnifiedDuoStartupFromFactory(ODUnifiedDuoStartupFactory factory, NSError **error) {
    if (!NSThread.isMainThread || ODStartupAttempted || !factory) {
        if (error) *error = ODStartupFailure(@"entry-precondition-failed");
        return NO;
    }
    ODStartupAttempted = YES;
    @try {
        NSError *failure = nil;
        ODUnifiedDuoHost *candidate = factory(&failure);
        if (![candidate isKindOfClass:ODUnifiedDuoHost.class] ||
            ![candidate.startupReport[@"purpose"] isEqual:@"integrated-duo-target"]) {
            if (error) *error = ODStartupFailure(failure.userInfo[@"startupStage"]?:@"factory-result-unavailable");
            return NO;
        }
        if (![candidate installBeforeApplicationMain:&failure]) {
            // Never forward a factory's arbitrary error or native file path.
            if (error) *error = ODStartupFailure(candidate.startupReport[@"stage"]);
            return NO;
        }
        ODStartupHost = candidate;
        return ODStartupHost != nil;
    } @catch (NSException *exception) {
        (void)exception;
        if (error) *error = ODStartupFailure(@"startup-exception");
        return NO;
    }
}

/* Component libraries and hosted Finish fixtures must not acquire a process
 * constructor merely because they reuse this source. Only the explicitly
 * selected original-game production entry enables this path. */
#if defined(OD_UNIFIED_DUO_STARTUP_ENTRY) && OD_UNIFIED_DUO_STARTUP_ENTRY
__attribute__((constructor)) static void ODStartUnifiedOriginalDuo(void) {
    @autoreleasepool {
        NSError *failure=nil;
        if (!ODCreateUnifiedDuoStartupHost ||
            !ODInstallUnifiedDuoStartupFromFactory(ODCreateUnifiedDuoStartupHost, &failure)) {
            fprintf(stderr,"Offline Dokkan: original-game startup failed at %s.\n",
                ODStartupFixedStage(failure.userInfo[@"startupStage"]).UTF8String);
            _exit(EXIT_FAILURE);
        }
    }
}
#endif
