#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "InstallerService.h"
#import "SecureStore.h"

static NSUInteger AIDiscoveryDeniedAuthorizationReads;
static UIApplicationState AIDiscoveryFixtureApplicationState;
@interface AISecureStore (PairingDiscoveryDeniedSessionProbe)
+ (BOOL)ai_discoveryDeniedSessionProbe;
@end
@implementation AISecureStore (PairingDiscoveryDeniedSessionProbe)
+ (BOOL)ai_discoveryDeniedSessionProbe { AIDiscoveryDeniedAuthorizationReads++; return NO; }
@end
@interface UIApplication (PairingDiscoveryLifecycleProbe)
- (UIApplicationState)ai_discoveryLifecycleProbe;
@end
@implementation UIApplication (PairingDiscoveryLifecycleProbe)
- (UIApplicationState)ai_discoveryLifecycleProbe { return AIDiscoveryFixtureApplicationState; }
@end

@interface AIInstallerService (PairingDiscoveryRegressionAccess)
- (void)stopPairingDiscovery;
- (void)finishPairingDiscovery:(NSUInteger)generation;
- (void)startDeviceListNow;
- (void)readEngineState;
- (void)finishBackground:(BOOL)success;
- (void)endBackgroundExecution;
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindService:(NSNetService *)service moreComing:(BOOL)moreComing;
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didNotSearch:(NSDictionary *)error;
- (void)netServiceDidResolveAddress:(NSNetService *)service;
@end

// Test-only probes. No successful authentication, Bonjour search/resolve, socket,
// saved account, raw TXT, Keychain access, or device-list operation is supplied.
@interface AIPairingDiscoveryBrowserProbe : NSNetServiceBrowser
@property(nonatomic) NSUInteger stops;
@end
@implementation AIPairingDiscoveryBrowserProbe
- (void)stop { self.stops++; }
@end

@interface AIPairingDiscoveryServiceProbe : NSNetService
@property(nonatomic) NSUInteger resolutions;
@property(nonatomic) NSUInteger stops;
@property(nonatomic) NSUInteger portReads;
@property(nonatomic) NSUInteger txtReads;
@property(nonatomic) NSTimeInterval requestedTimeout;
@end
@implementation AIPairingDiscoveryServiceProbe
- (void)resolveWithTimeout:(NSTimeInterval)timeout { self.resolutions++; self.requestedTimeout=timeout; }
- (void)stop { self.stops++; }
- (NSInteger)port { self.portReads++; return 49153; }
- (NSData *)TXTRecordData { self.txtReads++; return nil; }
@end

@interface AIPairingDiscoveryCoordinatorProbe : AIInstallerService
@property(nonatomic) NSUInteger listStarts;
@end
@implementation AIPairingDiscoveryCoordinatorProbe
- (void)startDeviceListNow { self.listStarts++; } // Count routing only; never call the engine.
- (void)readEngineState {} // Keep cancellation independent of engine state polling.
- (void)finishBackground:(BOOL)success {}
- (void)endBackgroundExecution {}
@end

@interface AppInstallerPairingDiscoveryTests : XCTestCase @end
@implementation AppInstallerPairingDiscoveryTests
- (void)testBoundedDiscoveryCancellationRejectsLateCallbacksAndFinishesOnce {
    void (^check)(void)=^{
        // Deliberately do not call production init: it installs observers, opens
        // storage and configures the shared background coordinator. alloc supplies
        // zeroed ivars; only explicitly assigned nonsecret discovery state is used.
        AIPairingDiscoveryCoordinatorProbe *coordinator=[AIPairingDiscoveryCoordinatorProbe alloc];
        AIPairingDiscoveryBrowserProbe *browser=[AIPairingDiscoveryBrowserProbe new];
        NSMutableArray *accepted=[NSMutableArray new],*all=[NSMutableArray new];
        [coordinator setValue:@YES forKey:@"discoveringPairing"];
        [coordinator setValue:@100 forKey:@"pairingDiscoveryGeneration"];
        [coordinator setValue:browser forKey:@"pairingBrowser"];
        [coordinator setValue:accepted forKey:@"pairingServices"];
        browser.delegate=(id)coordinator;
        for(NSUInteger index=0;index<20;index++) {
            AIPairingDiscoveryServiceProbe *service=[[AIPairingDiscoveryServiceProbe alloc] initWithDomain:@"local." type:@"_remotepairing._tcp." name:@"TEST-ONLY discovery candidate"];
            [all addObject:service];
            [coordinator netServiceBrowser:browser didFindService:service moreComing:YES];
            XCTAssertEqual(service.resolutions,index<16?1u:0u);
            if(index<16)XCTAssertEqualWithAccuracy(service.requestedTimeout,2,0.001);
        }
        XCTAssertEqual(accepted.count,16u,@"Untrusted advertisements must not create unbounded resolution work.");
        // Probe foreground/backup guards without granting authentication: the
        // denied-session hook can only return NO and must not even be queried
        // until these earlier lifecycle/backup prerequisites pass.
        Method applicationState=class_getInstanceMethod(UIApplication.class,@selector(applicationState));
        Method fixtureState=class_getInstanceMethod(UIApplication.class,@selector(ai_discoveryLifecycleProbe));
        Method authorized=class_getClassMethod(AISecureStore.class,@selector(sessionAuthorized));
        Method denied=class_getClassMethod(AISecureStore.class,@selector(ai_discoveryDeniedSessionProbe));
        method_exchangeImplementations(applicationState,fixtureState);
        method_exchangeImplementations(authorized,denied);
        @try {
            AIDiscoveryDeniedAuthorizationReads=0;
            AIDiscoveryFixtureApplicationState=UIApplicationStateBackground;
            [coordinator setValue:@YES forKey:@"pairingBackupReady"];
            [coordinator netServiceDidResolveAddress:all.firstObject];
            XCTAssertEqual(AIDiscoveryDeniedAuthorizationReads,0u,@"Background callbacks must stop before session/port/TXT handling.");
            AIDiscoveryFixtureApplicationState=UIApplicationStateActive;
            [coordinator setValue:@NO forKey:@"pairingBackupReady"];
            [coordinator netServiceDidResolveAddress:all.firstObject];
            XCTAssertEqual(AIDiscoveryDeniedAuthorizationReads,0u,@"A missing protected backup must stop before session/port/TXT handling.");
            [coordinator setValue:@YES forKey:@"pairingBackupReady"];
            [coordinator netServiceDidResolveAddress:all.firstObject];
            XCTAssertEqual(AIDiscoveryDeniedAuthorizationReads,1u,@"A foreground callback still cannot bypass genuine session authorization.");
            XCTAssertEqual(((AIPairingDiscoveryServiceProbe *)all.firstObject).portReads,0u);
            XCTAssertEqual(((AIPairingDiscoveryServiceProbe *)all.firstObject).txtReads,0u);
        } @finally {
            method_exchangeImplementations(authorized,denied);
            method_exchangeImplementations(applicationState,fixtureState);
        }
        NSUInteger generation=[[coordinator valueForKey:@"pairingDiscoveryGeneration"] unsignedIntegerValue];
        NSTimer *queuedTimeout=[NSTimer timerWithTimeInterval:60 repeats:NO block:^(NSTimer *timer) {
            [coordinator finishPairingDiscovery:generation];
        }]; // Unscheduled: no real timer wait or network work.
        [coordinator setValue:queuedTimeout forKey:@"pairingDiscoveryTimer"];
        // The real cancellation entry point must invalidate discovery even when
        // a native delegate callback was queued before cancellation. ai_cancel is
        // cancellation only; no test initializes credentials or any network work.
        [coordinator cancel];
        XCTAssertFalse([[coordinator valueForKey:@"discoveringPairing"] boolValue]);
        XCTAssertNil([coordinator valueForKey:@"pairingBrowser"]);
        XCTAssertNil([coordinator valueForKey:@"pairingServices"]);
        XCTAssertNil([coordinator valueForKey:@"pairingDiscoveryTimer"]);XCTAssertFalse(queuedTimeout.valid);
        XCTAssertGreaterThan([[coordinator valueForKey:@"pairingDiscoveryGeneration"] unsignedIntegerValue],generation);
        XCTAssertEqual(browser.stops,1u);XCTAssertNil(browser.delegate);
        for(NSUInteger index=0;index<16;index++) {
            AIPairingDiscoveryServiceProbe *service=all[index];
            XCTAssertEqual(service.stops,1u);XCTAssertNil(service.delegate);
            [coordinator netServiceDidResolveAddress:service];
            XCTAssertEqual(service.portReads,0u,@"A cancelled callback must return before port inspection/mutation.");
            XCTAssertEqual(service.txtReads,0u,@"Cancelled callbacks must not inspect or retain raw TXT metadata.");
        }
        [coordinator netServiceBrowser:browser didFindService:all.lastObject moreComing:NO];
        [coordinator netServiceBrowser:browser didNotSearch:@{}];
        [coordinator finishPairingDiscovery:generation];
        XCTAssertEqual(coordinator.listStarts,0u);
        XCTAssertFalse([[coordinator valueForKey:@"authorizing"] boolValue]);
        XCTAssertFalse([[coordinator valueForKey:@"pairingCheckRequested"] boolValue]);

        // A stale timer generation cannot terminate a newer attempt. A current
        // timeout/error completion routes to the guarded list starter exactly once.
        [coordinator setValue:@YES forKey:@"discoveringPairing"];
        [coordinator setValue:@200 forKey:@"pairingDiscoveryGeneration"];
        [coordinator setValue:[NSMutableArray new] forKey:@"pairingServices"];
        [coordinator netServiceDidResolveAddress:all.firstObject];
        XCTAssertEqual(((AIPairingDiscoveryServiceProbe *)all.firstObject).portReads,0u,@"An old service cannot join a newer generation by delivering a late resolution.");
        [coordinator finishPairingDiscovery:generation];
        XCTAssertTrue([[coordinator valueForKey:@"discoveringPairing"] boolValue]);
        XCTAssertEqual(coordinator.listStarts,0u);
        [coordinator finishPairingDiscovery:200];
        [coordinator finishPairingDiscovery:200];
        XCTAssertEqual(coordinator.listStarts,1u,@"A timeout/error race must not try the fallback twice.");
        XCTAssertFalse([[coordinator valueForKey:@"authorizing"] boolValue]);
    };
    if(NSThread.isMainThread)check();else dispatch_sync(dispatch_get_main_queue(),check);
}
@end
