#import <XCTest/XCTest.h>
#import <math.h>
#import "InstallerService.h"
#import "RefreshCoordinator.h"
#import "../core/app_installer.h"

// Production expiry policy and a real cancellation/reminder regression. These
// tests never authenticate or fake authentication success, refresh, sign or install.
@interface AIInstallerService (RefreshLifecycleTestAccess)
- (void)pauseScheduledWorkForExplicitSignOut;
- (void)poll;
@end
@interface RefreshLifecycleTests : XCTestCase
@end
@implementation RefreshLifecycleTests
- (void)testActualProfileExpiryDrivesForegroundRefreshIncludingEarlierExtension {
    NSTimeInterval now = 1800000000;
    NSArray *onlyLater = @[@{@"expiry":@(now + 5 * 86400.0)}];
    XCTAssertFalse([AIInstallerService foregroundRefreshDueForRecords:onlyLater now:now lastAttempt:nil]);
    NSArray *earlierExtension = @[@{@"expiry":@(now + 5 * 86400.0)}, @{@"expiry":@(now + 86400.0)}];
    XCTAssertTrue([AIInstallerService foregroundRefreshDueForRecords:earlierExtension now:now lastAttempt:nil],
                  @"An earlier real profile expiry must not be hidden by a later main-app expiry.");
    XCTAssertTrue([AIInstallerService foregroundRefreshDueForRecords:@[@{@"expiry":@(now + 2 * 86400.0)}] now:now lastAttempt:nil]);
    XCTAssertFalse([AIInstallerService foregroundRefreshDueForRecords:@[@{@"expiry":@(now + 2 * 86400.0 + 1)}] now:now lastAttempt:nil]);
    XCTAssertTrue([AIInstallerService foregroundRefreshDueForRecords:@[@{@"expiry":@(now - 1)}] now:now lastAttempt:nil]);
    XCTAssertFalse([AIInstallerService foregroundRefreshDueForRecords:@[] now:now lastAttempt:nil]);
    NSArray *invalidExpiry = @[@{@"expiry":@0}, @{@"expiry":@"unknown"}, @{@"expiry":@(NAN)}];
    XCTAssertFalse([AIInstallerService foregroundRefreshDueForRecords:invalidExpiry now:now lastAttempt:nil],
                   @"Unknown/corrupt expiry metadata is not authority to initiate a refresh.");
}
- (void)testForegroundRetryCooldownPreventsRepeatedPromptsWithoutBlockingClockRecovery {
    NSTimeInterval now = 1800000000;
    NSArray *due = @[@{@"expiry":@(now + 86400.0)}];
    XCTAssertFalse([AIInstallerService foregroundRefreshDueForRecords:due now:now lastAttempt:[NSDate dateWithTimeIntervalSince1970:now]]);
    XCTAssertFalse([AIInstallerService foregroundRefreshDueForRecords:due now:now lastAttempt:[NSDate dateWithTimeIntervalSince1970:now - 899]]);
    XCTAssertTrue([AIInstallerService foregroundRefreshDueForRecords:due now:now lastAttempt:[NSDate dateWithTimeIntervalSince1970:now - 900]],
                  @"A later daily open may retry a legitimately due refresh.");
    XCTAssertTrue([AIInstallerService foregroundRefreshDueForRecords:due now:now lastAttempt:[NSDate dateWithTimeIntervalSince1970:now + 3600]],
                  @"A corrected device clock must not suppress refresh until an obsolete future timestamp.");
    XCTAssertFalse([AIInstallerService foregroundRefreshDueForRecords:due now:NAN lastAttempt:nil]);
    XCTAssertFalse([AIInstallerService foregroundRefreshDueForRecords:due now:0 lastAttempt:nil]);

    // Exercise the actual coordinator persistence + genuine engine cancellation event.
    // This calls only the notification-pause policy, never the authenticated sign-out
    // API or a mocked successful login. It must not restart tasks/reminders from poll.
    AIInstallerService *service = AIInstallerService.shared;
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSString *pauseKey = @"org.tin.appinstaller.explicit-signout-reminder-pause";
    NSString *metadataKey = @"org.tin.appinstaller.expiry-metadata";
    id previousPause = [defaults objectForKey:pauseKey];
    id previousMetadata = [defaults objectForKey:metadataKey];
    id previousServicePause = [service valueForKey:@"notificationsSuppressedForExplicitSignOut"];
    @try {
        [AIRefreshCoordinator.shared updateAppRecords:@[@{@"name":@"TEST ONLY — reminder metadata", @"bundleId":@"org.example.reminder-test", @"expiry":@(NSDate.date.timeIntervalSince1970 + 86400)}]];
        XCTAssertNotNil([defaults objectForKey:metadataKey]);
        [service pauseScheduledWorkForExplicitSignOut];
        XCTAssertNil([defaults objectForKey:metadataKey]);
        ai_cancel();
        [service poll];
        XCTAssertNil([defaults objectForKey:metadataKey],
                     @"A current engine cancellation must not recreate reminders after explicit sign-out paused them.");
    } @finally {
        // Restore only nonsecret test-touched notification preferences/state.
        [service setValue:previousServicePause forKey:@"notificationsSuppressedForExplicitSignOut"];
        if (previousPause) [defaults setObject:previousPause forKey:pauseKey]; else [defaults removeObjectForKey:pauseKey];
        if ([previousMetadata isKindOfClass:NSArray.class]) [AIRefreshCoordinator.shared updateAppRecords:previousMetadata];
        else [AIRefreshCoordinator.shared cancelScheduledWork];
    }
}
@end
