#import <XCTest/XCTest.h>
#import "InstallerService.h"
#import <sys/stat.h>

@interface AIInstallerService (PairingDocumentReadTestAccess)
- (NSMutableData *)coordinatedPairingBytesFromURL:(NSURL *)url coordinator:(NSFileCoordinator *)coordinator cancellation:(NSProgress *)cancellation;
@end

// Explicit coordination fixture, not an actual Files provider or a successful
// authentication fixture. The original URL deliberately has no file metadata.
@interface AIPairingAccessorFixture : NSFileCoordinator
@property (nonatomic, strong) NSURL *accessorURL;
@property (nonatomic, strong) NSProgress *cancelAtAccessor;
@end
@implementation AIPairingAccessorFixture
- (void)coordinateReadingItemAtURL:(NSURL *)url options:(NSFileCoordinatorReadingOptions)options error:(NSError **)error byAccessor:(void (NS_NOESCAPE ^)(NSURL *))reader {
    if (error) *error = nil;
    [self.cancelAtAccessor cancel];
    reader(self.accessorURL);
}
@end

@interface PairingDocumentReadTests : XCTestCase
@end
@implementation PairingDocumentReadTests
// This method tests the read boundary, not Keychain, LocalAuthentication, a real
// provider, import or device pairing.
- (void)testCoordinatedPairingDocumentAcceptsMaterializedBytesAndRejectsUnsafeReads {
    AIInstallerService *service = AIInstallerService.shared;
    NSURL *directory = [[NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES]
        URLByAppendingPathComponent:[@"pairing-document-fixture-" stringByAppendingString:NSUUID.UUID.UUIDString] isDirectory:YES];
    XCTAssertTrue([NSFileManager.defaultManager createDirectoryAtURL:directory withIntermediateDirectories:NO attributes:nil error:nil]);
    NSURL *document = [directory URLByAppendingPathComponent:@"nonsecret-input"];
    NSData *marker = [@"NONSECRET TEST INPUT: not a pairing record" dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertTrue([marker writeToURL:document options:0 error:nil]);
    XCTestExpectation *done = [self expectationWithDescription:@"Coordinated read cases completed"];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        @try {
            NSProgress *(^token)(void) = ^{ return [NSProgress discreteProgressWithTotalUnitCount:1]; };
            XCTAssertEqualObjects([service coordinatedPairingBytesFromURL:document coordinator:[[NSFileCoordinator alloc] initWithFilePresenter:nil] cancellation:token()], marker);
            NSURL *placeholder = [directory URLByAppendingPathComponent:@"unavailable-provider-metadata"];
            NSNumber *size = nil;
            XCTAssertFalse([placeholder getResourceValue:&size forKey:NSURLFileSizeKey error:nil]);
            AIPairingAccessorFixture *provider = [[AIPairingAccessorFixture alloc] initWithFilePresenter:nil];
            provider.accessorURL = document;
            XCTAssertEqualObjects([service coordinatedPairingBytesFromURL:placeholder coordinator:provider cancellation:token()], marker,
                                  @"A materialized accessor URL must work without original size metadata.");
            NSURL *hardlink = [directory URLByAppendingPathComponent:@"regular-hardlink"];
            XCTAssertTrue([NSFileManager.defaultManager linkItemAtURL:document toURL:hardlink error:nil]);
            provider.accessorURL = hardlink;
            XCTAssertEqualObjects([service coordinatedPairingBytesFromURL:placeholder coordinator:provider cancellation:token()], marker);
            NSProgress *cancelled = token(); provider.cancelAtAccessor = cancelled;
            XCTAssertNil([service coordinatedPairingBytesFromURL:placeholder coordinator:provider cancellation:cancelled]);
            provider.cancelAtAccessor = nil;
            NSURL *empty = [directory URLByAppendingPathComponent:@"empty"];
            XCTAssertTrue([[NSData data] writeToURL:empty options:0 error:nil]);
            NSURL *tooLarge = [directory URLByAppendingPathComponent:@"too-large"];
            XCTAssertTrue([[NSMutableData dataWithLength:1024 * 1024 + 1] writeToURL:tooLarge options:0 error:nil]);
            NSURL *symlink = [directory URLByAppendingPathComponent:@"symbolic-link"];
            XCTAssertTrue([NSFileManager.defaultManager createSymbolicLinkAtURL:symlink withDestinationURL:document error:nil]);
            NSURL *fifo = [directory URLByAppendingPathComponent:@"nonregular-pipe"];
            XCTAssertEqual(mkfifo(fifo.fileSystemRepresentation, 0600), 0);
            for (NSURL *rejected in @[empty, tooLarge, symlink, fifo, directory]) {
                provider.accessorURL = rejected;
                XCTAssertNil([service coordinatedPairingBytesFromURL:placeholder coordinator:provider cancellation:token()]);
            }
            XCTAssertNil([service coordinatedPairingBytesFromURL:[NSURL URLWithString:@"https://example.invalid/never-requested"] coordinator:provider cancellation:token()]);
        } @finally {
            XCTAssertTrue([NSFileManager.defaultManager removeItemAtURL:directory error:nil]);
            [done fulfill];
        }
    });
    [self waitForExpectations:@[done] timeout:10];
}
@end
