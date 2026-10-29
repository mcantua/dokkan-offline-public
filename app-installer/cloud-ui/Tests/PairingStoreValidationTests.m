#import <XCTest/XCTest.h>
#import "PairingStore.h"

@interface AIPairingStore (PairingFormatTestAccess)
- (BOOL)looksLikePairingData:(NSData *)data;
@end

// Format-only regression: no file/Keychain access, authentication, usable key
// pair, account or device. Rust's separate tests establish the identity proof.
@interface PairingStoreValidationTests : XCTestCase
@end
@implementation PairingStoreValidationTests
- (NSData *)encode:(NSDictionary *)record format:(NSPropertyListFormat)format {
    NSError *error = nil;
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:record format:format options:0 error:&error];
    XCTAssertNotNil(data, @"The nonsecret format fixture must serialize.");
    return data;
}
- (void)testRemotePairingV2ImportAndRecoveryFormatGuardPreservesLegacySupport {
    // These deliberately noncryptographic markers describe field shapes only;
    // they are never a usable/persisted/verified pairing identity.
    NSData *marker32 = [NSMutableData dataWithLength:32];
    NSMutableDictionary *remote = [@{@"app_installer_rp_version":@2, @"identifier":@"TEST ONLY host identifier",
        @"peer_identifier":@"TEST ONLY device identifier", @"public_key":marker32, @"private_key":marker32,
        @"peer_public_key":marker32, @"alt_irk":[NSMutableData dataWithLength:16]} mutableCopy];
    AIPairingStore *store = [[AIPairingStore alloc] initWithDirectory:[NSURL URLWithString:@"file:///nonexistent-format-fixture/"]];
    for (NSNumber *format in @[@(NSPropertyListXMLFormat_v1_0), @(NSPropertyListBinaryFormat_v1_0)]) {
        XCTAssertTrue([store looksLikePairingData:[self encode:remote format:format.unsignedIntegerValue]],
                      @"The format gate shared by protected import and recovered primary must admit pinned-version RP exports.");
    }
    for (NSString *required in @[@"app_installer_rp_version", @"peer_identifier", @"peer_public_key", @"private_key"]) {
        NSMutableDictionary *invalid = [remote mutableCopy]; [invalid removeObjectForKey:required];
        XCTAssertFalse([store looksLikePairingData:[self encode:invalid format:NSPropertyListBinaryFormat_v1_0]],
                       @"An unversioned or unpinned legacy RP export must stay rejected.");
    }
    NSArray *changes = @[@{@"app_installer_rp_version":@1}, @{@"app_installer_rp_version":@2.0},
        @{@"app_installer_rp_version":@YES}, @{@"peer_public_key":[NSMutableData dataWithLength:31]},
        @{@"private_key":@"not binary data"}, @{@"peer_identifier":@""}, @{@"identifier":@"invalid\nidentifier"},
        @{@"identifier":[@"é" stringByPaddingToLength:128 withString:@"é" startingAtIndex:0]},
        @{@"alt_irk":[NSMutableData dataWithLength:17]}, @{@"unknown_field":@"must reject"}];
    for (NSDictionary *change in changes) {
        NSMutableDictionary *invalid = [remote mutableCopy]; [invalid addEntriesFromDictionary:change];
        XCTAssertFalse([store looksLikePairingData:[self encode:invalid format:NSPropertyListBinaryFormat_v1_0]]);
    }
    [remote removeObjectForKey:@"alt_irk"];
    XCTAssertTrue([store looksLikePairingData:[self encode:remote format:NSPropertyListBinaryFormat_v1_0]],
                  @"The discovery hint remains optional; actual peer proof remains mandatory in Rust.");
    NSDictionary *lockdown = @{@"HostID":@"TEST ONLY host", @"SystemBUID":@"TEST ONLY system",
        @"HostCertificate":[NSMutableData dataWithLength:1], @"HostPrivateKey":[NSMutableData dataWithLength:1],
        @"RootCertificate":[NSMutableData dataWithLength:1]};
    XCTAssertTrue([store looksLikePairingData:[self encode:lockdown format:NSPropertyListBinaryFormat_v1_0]],
                  @"The RP addition must preserve the existing Lockdown format gate.");
}
@end
