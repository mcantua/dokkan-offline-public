#import <XCTest/XCTest.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import <Security/Security.h>
#import <objc/runtime.h>
#import <math.h>
#import "SecureStore.h"
#import "InstallerService.h"

// Hosted disposable-simulator Keychain tests only.
// Real biometric/passcode authentication is not tested here. The cancellation
// race case explicitly substitutes a delayed LA callback; it never grants a
// successful production session or reads account secrets. All items are owned
// nonsecret test markers and are removed after each case.
static void (^AIHeldAuthenticationReply)(BOOL, NSError *);
static XCTestExpectation *AIAuthenticationReplyCaptured;
static BOOL AIExpiredLeaseFixturePending;
@interface AISecureStore (AIExpiredLeaseFixture)
+ (BOOL)ai_fixtureConsumeSessionExpiration;
+ (BOOL)leaseExpiredAtTime:(NSTimeInterval)now deadline:(NSTimeInterval)deadline;
@end
@implementation AISecureStore (AIExpiredLeaseFixture)
+ (BOOL)ai_fixtureConsumeSessionExpiration {
    BOOL pending = AIExpiredLeaseFixturePending;
    AIExpiredLeaseFixturePending = NO;
    return pending; // Expired transition only; never grants an authenticated context.
}
@end
@interface AIInstallerService (AIExpiredLeaseTestAccess)
- (BOOL)handleSessionExpiration;
@end
@interface LAContext (AICancellationRaceFixture)
- (BOOL)ai_raceCanEvaluatePolicy:(LAPolicy)policy error:(NSError **)error;
- (void)ai_raceEvaluatePolicy:(LAPolicy)policy localizedReason:(NSString *)reason reply:(void (^)(BOOL, NSError *))reply;
@end
@implementation LAContext (AICancellationRaceFixture)
- (BOOL)ai_raceCanEvaluatePolicy:(LAPolicy)policy error:(NSError **)error {
    if (error) *error = nil;
    return YES; // Scoped race fixture only; never evidence of real system authentication.
}
- (void)ai_raceEvaluatePolicy:(LAPolicy)policy localizedReason:(NSString *)reason reply:(void (^)(BOOL, NSError *))reply {
    AIHeldAuthenticationReply = [reply copy];
    [AIAuthenticationReplyCaptured fulfill];
}
@end
@interface SecureStoreBootstrapTests : XCTestCase
@property (nonatomic, copy) NSString *dummyAccount;
@property (nonatomic) BOOL ownsDummyItem;
@property (nonatomic) BOOL ownsCorruptSetting;
@end

@implementation SecureStoreBootstrapTests
- (NSDictionary *)queryForService:(NSString *)service account:(NSString *)account {
    NSMutableDictionary *query = [@{(__bridge id)kSecClass:(__bridge id)kSecClassGenericPassword,
                                   (__bridge id)kSecAttrService:service} mutableCopy];
    if (account) query[(__bridge id)kSecAttrAccount] = account;
    return query;
}
- (OSStatus)metadataStatus:(NSDictionary *)query {
    NSMutableDictionary *probe = [query mutableCopy];
    probe[(__bridge id)kSecReturnAttributes] = @YES;
    probe[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
    LAContext *context = [LAContext new]; context.interactionNotAllowed = YES;
    probe[(__bridge id)kSecUseAuthenticationContext] = context;
    CFTypeRef attributes = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)probe, &attributes);
    if (attributes) CFRelease(attributes);
    [context invalidate];
    return status;
}
- (BOOL)requireEmptyDisposableTestServices {
    OSStatus settings = [self metadataStatus:[self queryForService:@"org.tin.appinstaller.settings" account:@"biometrics"]];
    OSStatus records = [self metadataStatus:[self queryForService:@"org.tin.appinstaller.secure" account:nil]];
    // Never clear an unexpected existing record to manufacture a fresh state.
    if (settings != errSecItemNotFound || records != errSecItemNotFound) {
        XCTFail(@"Bootstrap tests require the fresh disposable hosted simulator; no existing Keychain item was removed.");
        return NO;
    }
    return YES;
}
- (void)setUp {
    [super setUp];
    [AISecureStore endSession];
    self.dummyAccount = [@"engine.bootstrap-test." stringByAppendingString:NSUUID.UUID.UUIDString];
    self.ownsDummyItem = NO; self.ownsCorruptSetting = NO;
}
- (void)tearDown {
    // Remove only exact test-owned items. No broad service deletion is used.
    if (self.ownsDummyItem) {
        OSStatus status = SecItemDelete((__bridge CFDictionaryRef)[self queryForService:@"org.tin.appinstaller.secure" account:self.dummyAccount]);
        XCTAssertTrue(status == errSecSuccess || status == errSecItemNotFound, @"Remove only the owned dummy item.");
    }
    if (self.ownsCorruptSetting) {
        OSStatus status = SecItemDelete((__bridge CFDictionaryRef)[self queryForService:@"org.tin.appinstaller.settings" account:@"biometrics"]);
        XCTAssertTrue(status == errSecSuccess || status == errSecItemNotFound, @"Remove only the test-created invalid setting.");
    }
    [AISecureStore endSession];
    [super tearDown];
}
- (void)testFreshKeychainPermitsBootstrapProbeWithoutGrantingAuthentication {
    if (![self requireEmptyDisposableTestServices]) return;
    XCTAssertTrue([AISecureStore initialSetupRequired], @"A genuinely empty Keychain must offer first-use device-owner setup.");
    XCTAssertFalse([AISecureStore sessionAuthorized], @"A metadata probe must never authorize a session.");
    XCTAssertTrue([AISecureStore biometricsEnabled], @"Missing settings stay fail-closed until real system authentication succeeds.");
    XCTAssertEqual([self metadataStatus:[self queryForService:@"org.tin.appinstaller.settings" account:@"biometrics"]], errSecItemNotFound,
                   @"The bootstrap probe must not persist a weaker policy before authentication.");
}
- (void)testExistingRecordOrCorruptSettingNeverEnablesFreshBootstrap {
    if (![self requireEmptyDisposableTestServices]) return;
    NSMutableDictionary *dummy = [[self queryForService:@"org.tin.appinstaller.secure" account:self.dummyAccount] mutableCopy];
    const uint8_t placeholder = 0x54; // A nonsecret test marker, never an account/session value.
    dummy[(__bridge id)kSecValueData] = [NSData dataWithBytes:&placeholder length:1];
    dummy[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly;
    OSStatus added = SecItemAdd((__bridge CFDictionaryRef)dummy, NULL);
    XCTAssertEqual(added, errSecSuccess, @"Create one owned nonsecret dummy record.");
    if (added != errSecSuccess) return;
    self.ownsDummyItem = YES;
    XCTAssertFalse([AISecureStore initialSetupRequired], @"An existing engine-service record blocks any missing-setting bootstrap downgrade.");
    XCTAssertTrue([AISecureStore biometricsEnabled], @"Missing settings beside records retain biometric fail-closed policy.");
    XCTAssertFalse([AISecureStore sessionAuthorized], @"The existing-record guard must not authenticate.");
    OSStatus removed = SecItemDelete((__bridge CFDictionaryRef)[self queryForService:@"org.tin.appinstaller.secure" account:self.dummyAccount]);
    XCTAssertEqual(removed, errSecSuccess);
    if (removed != errSecSuccess) return;
    self.ownsDummyItem = NO;

    NSMutableDictionary *setting = [[self queryForService:@"org.tin.appinstaller.settings" account:@"biometrics"] mutableCopy];
    const uint8_t corrupt[] = {0x54, 0x54}; // Invalid setting length; deliberately nonsecret.
    setting[(__bridge id)kSecValueData] = [NSData dataWithBytes:corrupt length:sizeof(corrupt)];
    setting[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly;
    added = SecItemAdd((__bridge CFDictionaryRef)setting, NULL);
    XCTAssertEqual(added, errSecSuccess, @"Create one owned invalid setting to exercise fail-closed behavior.");
    if (added != errSecSuccess) return;
    self.ownsCorruptSetting = YES;
    XCTAssertFalse([AISecureStore initialSetupRequired], @"Corruption is not a genuinely missing configuration.");
    XCTAssertTrue([AISecureStore biometricsEnabled], @"Corrupt settings must not disable biometric protection.");
    XCTAssertFalse([AISecureStore sessionAuthorized], @"No fake LocalAuthentication success is used.");
}
- (void)testCancellingOrdinaryPendingAuthenticationRejectsDelayedSyntheticSuccess {
    if (![self requireEmptyDisposableTestServices]) return;
    // A nonsecret existing record prevents bootstrap/configuration persistence
    // even if this regression fails. No saved credential is touched by the test.
    NSMutableDictionary *dummy = [[self queryForService:@"org.tin.appinstaller.secure" account:self.dummyAccount] mutableCopy];
    const uint8_t marker = 0x54;
    dummy[(__bridge id)kSecValueData] = [NSData dataWithBytes:&marker length:1];
    dummy[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly;
    OSStatus added = SecItemAdd((__bridge CFDictionaryRef)dummy, NULL);
    XCTAssertEqual(added, errSecSuccess);
    if (added != errSecSuccess) return;
    self.ownsDummyItem = YES;

    Method canEvaluate = class_getInstanceMethod(LAContext.class, @selector(canEvaluatePolicy:error:));
    Method fixtureCanEvaluate = class_getInstanceMethod(LAContext.class, @selector(ai_raceCanEvaluatePolicy:error:));
    Method evaluate = class_getInstanceMethod(LAContext.class, @selector(evaluatePolicy:localizedReason:reply:));
    Method fixtureEvaluate = class_getInstanceMethod(LAContext.class, @selector(ai_raceEvaluatePolicy:localizedReason:reply:));
    XCTAssertTrue(canEvaluate && fixtureCanEvaluate && evaluate && fixtureEvaluate);
    if (!canEvaluate || !fixtureCanEvaluate || !evaluate || !fixtureEvaluate) return;
    AIAuthenticationReplyCaptured = [self expectationWithDescription:@"Ordinary authentication reply held by explicit race fixture"];
    XCTestExpectation *completed = [self expectationWithDescription:@"Cancelled authentication reply rejected"];
    method_exchangeImplementations(canEvaluate, fixtureCanEvaluate);
    method_exchangeImplementations(evaluate, fixtureEvaluate);
    @try {
        dispatch_async(dispatch_get_main_queue(), ^{
            // This is the production service's ordinary pending-auth state,
            // isolated from backend readiness and any real system prompt.
            [AIInstallerService.shared setValue:@YES forKey:@"authorizing"];
            [AIInstallerService.shared setValue:@NO forKey:@"biometricMigrationPending"];
            [AISecureStore authenticateSessionWithReason:@"TEST ONLY — delayed callback race" completion:^(BOOL success) {
                XCTAssertFalse(success, @"Service cancellation must invalidate SecureStore's outstanding generation.");
                XCTAssertFalse([AISecureStore sessionAuthorized], @"A late synthetic callback must never establish a reusable session.");
                [completed fulfill];
            }];
        });
        [self waitForExpectations:@[AIAuthenticationReplyCaptured] timeout:5];
        XCTAssertNotNil(AIHeldAuthenticationReply);
        dispatch_async(dispatch_get_main_queue(), ^{
            [AIInstallerService.shared cancel]; // Actual public cancellation, not a mocked generation increment.
            if (AIHeldAuthenticationReply) AIHeldAuthenticationReply(YES, nil);
        });
        [self waitForExpectations:@[completed] timeout:5];
        XCTAssertEqual([self metadataStatus:[self queryForService:@"org.tin.appinstaller.settings" account:@"biometrics"]], errSecItemNotFound,
                       @"This callback race fixture must not persist first-use configuration.");
    } @finally {
        [AISecureStore endSession];
        method_exchangeImplementations(evaluate, fixtureEvaluate);
        method_exchangeImplementations(canEvaluate, fixtureCanEvaluate);
        AIHeldAuthenticationReply = nil; AIAuthenticationReplyCaptured = nil;
        [AIInstallerService.shared setValue:@NO forKey:@"authorizing"];
    }
    // The production monotonic deadline is not affected by calendar time. No
    // successful LocalAuthentication/context or saved account is created here.
    XCTAssertFalse([AISecureStore leaseExpiredAtTime:299.999 deadline:300]);
    XCTAssertTrue([AISecureStore leaseExpiredAtTime:300 deadline:300]);
    XCTAssertTrue([AISecureStore leaseExpiredAtTime:301 deadline:300]);
    XCTAssertTrue([AISecureStore leaseExpiredAtTime:1 deadline:0]);
    XCTAssertTrue([AISecureStore leaseExpiredAtTime:NAN deadline:300]);
    Method consume = class_getClassMethod(AISecureStore.class, @selector(consumeSessionExpiration));
    Method fixtureConsume = class_getClassMethod(AISecureStore.class, @selector(ai_fixtureConsumeSessionExpiration));
    XCTAssertTrue(consume && fixtureConsume);
    if (!consume || !fixtureConsume) return;
    XCTestExpectation *expired = [self expectationWithDescription:@"Expired lease cancels the real native continuation only once"];
    method_exchangeImplementations(consume, fixtureConsume);
    @try {
        dispatch_async(dispatch_get_main_queue(), ^{
            AIInstallerService *service = AIInstallerService.shared;
            void (^previousHandler)(NSDictionary *) = service.eventHandler;
            __block NSUInteger expiryErrors = 0;
            __block BOOL continuationRan = NO;
            @try {
                XCTAssertFalse([AISecureStore sessionAuthorized]);
                service.eventHandler = ^(NSDictionary *event) {
                    if ([event[@"type"] isEqual:@"error"] && [event[@"message"] containsString:@"five-minute unlock expired"]) ++expiryErrors;
                };
                [service setValue:@YES forKey:@"signingForInstall"];
                [service setValue:@YES forKey:@"foregroundRefreshPending"];
                [service setValue:[^{ continuationRan = YES; } copy] forKey:@"pendingDeviceAction"];
                AIExpiredLeaseFixturePending = YES;
                XCTAssertTrue([service handleSessionExpiration]);
                XCTAssertFalse([[service valueForKey:@"signingForInstall"] boolValue]);
                XCTAssertFalse([[service valueForKey:@"foregroundRefreshPending"] boolValue]);
                XCTAssertNil([service valueForKey:@"pendingDeviceAction"]);
                XCTAssertFalse(continuationRan);
                XCTAssertEqualObjects(service.snapshot[@"loginStatus"], @"signed_out", @"Revocation leaves this unauthenticated fixture locked; it does not simulate a real signed-in account.");
                NSNumber *generation = [service valueForKey:@"operationGeneration"];
                XCTAssertFalse([service handleSessionExpiration]);
                XCTAssertEqualObjects([service valueForKey:@"operationGeneration"], generation, @"Repeated polls must not recancel/revoke a new operation.");
                XCTAssertEqual(expiryErrors, 1u);
                XCTAssertFalse([AISecureStore sessionAuthorized]);
            } @finally {
                service.eventHandler = previousHandler;
                AIExpiredLeaseFixturePending = NO;
                [expired fulfill];
            }
        });
        [self waitForExpectations:@[expired] timeout:5];
    } @finally {
        method_exchangeImplementations(consume, fixtureConsume);
        AIExpiredLeaseFixturePending = NO;
    }
}
@end
