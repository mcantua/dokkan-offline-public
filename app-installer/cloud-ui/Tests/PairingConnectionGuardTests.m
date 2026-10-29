#import <XCTest/XCTest.h>
#import "PairingStore.h"
#import "InstallerService.h"

@interface AIPairingStore (ConnectionGuardTestAccess)
- (BOOL)looksLikePairingData:(NSData *)data;
@end
@interface AIInstallerService (ConnectionGuardTestAccess)
+ (BOOL)remotePairingTXT:(NSData *)data identifier:(NSString **)identifier authTag:(NSString **)authTag;
@end

@interface PairingConnectionGuardTests : XCTestCase
@end
@implementation PairingConnectionGuardTests
- (void)testPinnedFormatAndDiscoveryMetadataRejectMixedOrUnpinnedInputs {
    // Shapes only: no usable signing identity, secrets, storage, authentication,
    // network discovery or cryptographic peer-verification success is simulated.
    NSData *marker = [NSMutableData dataWithLength:32];
    NSDictionary *valid = @{@"format_version":@2, @"identifier":@"nonsecret host fixture", @"peer_identifier":@"nonsecret peer fixture",
        @"public_key":marker, @"private_key":marker, @"peer_public_key":marker, @"alt_irk":[NSMutableData dataWithLength:16]};
    AIPairingStore *store = [[AIPairingStore alloc] initWithDirectory:[NSURL URLWithString:@"file:///nonexistent-format-only/"]];
    NSData *(^encode)(NSDictionary *, NSPropertyListFormat) = ^(NSDictionary *value, NSPropertyListFormat format) {
        return [NSPropertyListSerialization dataWithPropertyList:value format:format options:0 error:nil];
    };
    for (NSNumber *format in @[@(NSPropertyListXMLFormat_v1_0), @(NSPropertyListBinaryFormat_v1_0)])
        XCTAssertTrue([store looksLikePairingData:encode(valid, format.unsignedIntegerValue)]);
    NSMutableDictionary *longIdentity = [valid mutableCopy]; longIdentity[@"peer_identifier"] = [@"x" stringByPaddingToLength:700 withString:@"x" startingAtIndex:0];
    XCTAssertTrue([store looksLikePairingData:encode(longIdentity, NSPropertyListBinaryFormat_v1_0)], @"Record IDs retain the actual Rust 1024-byte bound, separate from 255-byte TXT IDs.");
    for (NSString *required in @[@"format_version", @"peer_identifier", @"peer_public_key", @"private_key"]) {
        NSMutableDictionary *bad = [valid mutableCopy]; [bad removeObjectForKey:required];
        XCTAssertFalse([store looksLikePairingData:encode(bad, NSPropertyListBinaryFormat_v1_0)]);
    }
    NSArray *badFields = @[@{@"format_version":@1}, @{@"format_version":@2.0}, @{@"format_version":@YES},
        @{@"alt_irk":@"not binary"}, @{@"alt_irk":[NSMutableData dataWithLength:15]}, @{@"HostID":@"mixed legacy identity"},
        @{@"peer_public_key":[NSMutableData dataWithLength:31]}, @{@"unknown":@"reject"}];
    for (NSDictionary *change in badFields) {
        NSMutableDictionary *bad = [valid mutableCopy]; [bad addEntriesFromDictionary:change];
        XCTAssertFalse([store looksLikePairingData:encode(bad, NSPropertyListBinaryFormat_v1_0)]);
    }
    NSMutableDictionary *withoutHint = [valid mutableCopy]; [withoutHint removeObjectForKey:@"alt_irk"];
    XCTAssertTrue([store looksLikePairingData:encode(withoutHint, NSPropertyListBinaryFormat_v1_0)]);

    NSData *name = [@"nonsecret-service" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *tag = [@"AQIDBAUG" dataUsingEncoding:NSASCIIStringEncoding]; // six nonsecret bytes; no trusted peer claim
    NSString *identifier = nil, *authTag = nil;
    NSData *txt = [NSNetService dataFromTXTRecordDictionary:@{@"identifier":name, @"authTag":tag}];
    XCTAssertTrue([AIInstallerService remotePairingTXT:txt identifier:&identifier authTag:&authTag]);
    XCTAssertEqualObjects(identifier, @"nonsecret-service"); XCTAssertEqualObjects(authTag, @"AQIDBAUG");
    NSArray *invalidTXT = @[@{@"rpHI":name, @"rpHA":tag}, @{@"identifier":name},
        @{@"identifier":[@"bad\nname" dataUsingEncoding:NSUTF8StringEncoding], @"authTag":tag},
        @{@"identifier":name, @"authTag":[@"!!!!!!!!" dataUsingEncoding:NSASCIIStringEncoding]}];
    for (NSDictionary *fields in invalidTXT) {
        XCTAssertFalse([AIInstallerService remotePairingTXT:[NSNetService dataFromTXTRecordDictionary:fields] identifier:&identifier authTag:&authTag]);
        XCTAssertNil(identifier); XCTAssertNil(authTag);
    }
    XCTAssertFalse([AIInstallerService remotePairingTXT:[NSMutableData dataWithLength:4097] identifier:&identifier authTag:&authTag]);
}
@end
