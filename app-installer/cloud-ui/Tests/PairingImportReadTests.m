#import <XCTest/XCTest.h>
#import "InstallerService.h"

@interface AIInstallerService (PairingImportReadTestAccess)
- (NSMutableData *)readPairingDataFromURL:(NSURL *)url coordinator:(NSFileCoordinator *)coordinator progress:(NSProgress *)progress;
@end

// Explicit file-provider coordination fixture, not a real cloud provider. It
// supplies the materialized accessor URL only after the caller requests access.
@interface AIPairingMaterializationFixture : NSFileCoordinator
@property (nonatomic, strong) NSURL *materializedURL;
@property (nonatomic, strong) NSProgress *cancelBeforeAccessor;
@end
@implementation AIPairingMaterializationFixture
- (void)coordinateReadingItemAtURL:(NSURL *)url options:(NSFileCoordinatorReadingOptions)options error:(NSError **)error byAccessor:(void (^)(NSURL *))reader {
    if (error) *error = nil;
    [self.cancelBeforeAccessor cancel];
    reader(self.materializedURL);
}
@end

@interface PairingImportReadTests : XCTestCase
@end
@implementation PairingImportReadTests
- (void)testCoordinatedPairingReadUsesBoundedBytesAndHonorsCancellation {
    NSURL *directory = [[NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES]
        URLByAppendingPathComponent:[@"pairing-read-test-" stringByAppendingString:NSUUID.UUID.UUIDString] isDirectory:YES];
    NSError *error = nil;
    XCTAssertTrue([NSFileManager.defaultManager createDirectoryAtURL:directory withIntermediateDirectories:NO attributes:nil error:&error]);
    NSURL *regular = [directory URLByAppendingPathComponent:@"nonsecret-fixture.plist"];
    NSData *marker = [@"TEST ONLY — nonsecret file-provider import bytes" dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertTrue([marker writeToURL:regular options:0 error:&error]);
    AIInstallerService *service = AIInstallerService.shared;
    NSProgress *cancelledByService = [NSProgress discreteProgressWithTotalUnitCount:1];
    [service setValue:cancelledByService forKey:@"pairingReadProgress"];
    [service setValue:[[NSFileCoordinator alloc] initWithFilePresenter:nil] forKey:@"pairingReadCoordinator"];
    [service cancel];
    XCTAssertTrue(cancelledByService.cancelled, @"The actual public Cancel path must cancel an outstanding provider read.");
    XCTestExpectation *completed = [self expectationWithDescription:@"Bounded coordinated pairing reads finished"];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        @try {
            NSProgress *(^freshProgress)(void) = ^{ return [NSProgress discreteProgressWithTotalUnitCount:1]; };
            NSMutableData *read = [service readPairingDataFromURL:regular coordinator:[[NSFileCoordinator alloc] initWithFilePresenter:nil] progress:freshProgress()];
            XCTAssertEqualObjects(read, marker, @"The real NSFileCoordinator path must read the selected file's actual bytes.");

            NSURL *placeholder = [directory URLByAppendingPathComponent:@"not-materialized-yet.plist"];
            NSNumber *unavailableSize = nil;
            XCTAssertFalse([placeholder getResourceValue:&unavailableSize forKey:NSURLFileSizeKey error:nil]);
            AIPairingMaterializationFixture *provider = [[AIPairingMaterializationFixture alloc] initWithFilePresenter:nil];
            provider.materializedURL = regular;
            read = [service readPairingDataFromURL:placeholder coordinator:provider progress:freshProgress()];
            XCTAssertEqualObjects(read, marker, @"Unavailable original size metadata must not reject a valid materialized accessor URL.");
            XCTAssertNil([service readPairingDataFromURL:placeholder coordinator:provider progress:cancelledByService]);

            NSURL *hardlink = [directory URLByAppendingPathComponent:@"hardlink.plist"];
            XCTAssertTrue([NSFileManager.defaultManager linkItemAtURL:regular toURL:hardlink error:nil]);
            provider.materializedURL = hardlink;
            XCTAssertEqualObjects([service readPairingDataFromURL:placeholder coordinator:provider progress:freshProgress()], marker,
                                  @"Reading an explicitly chosen regular hardlink must not change or reject the user's original file.");

            NSProgress *cancelled = freshProgress();
            provider.cancelBeforeAccessor = cancelled;
            XCTAssertNil([service readPairingDataFromURL:placeholder coordinator:provider progress:cancelled],
                         @"Cancellation after coordination starts must prevent returning pairing bytes.");
            provider.cancelBeforeAccessor = nil;

            NSURL *empty = [directory URLByAppendingPathComponent:@"empty.plist"];
            XCTAssertTrue([[NSData data] writeToURL:empty options:0 error:nil]);
            provider.materializedURL = empty;
            XCTAssertNil([service readPairingDataFromURL:placeholder coordinator:provider progress:freshProgress()]);
            NSURL *oversized = [directory URLByAppendingPathComponent:@"oversized.plist"];
            XCTAssertTrue([[NSMutableData dataWithLength:1024 * 1024 + 1] writeToURL:oversized options:0 error:nil]);
            provider.materializedURL = oversized;
            XCTAssertNil([service readPairingDataFromURL:placeholder coordinator:provider progress:freshProgress()],
                         @"The actual file byte limit must be enforced independently of URL metadata.");
            NSURL *link = [directory URLByAppendingPathComponent:@"link.plist"];
            XCTAssertTrue([NSFileManager.defaultManager createSymbolicLinkAtURL:link withDestinationURL:regular error:nil]);
            provider.materializedURL = link;
            XCTAssertNil([service readPairingDataFromURL:placeholder coordinator:provider progress:freshProgress()]);
            provider.materializedURL = directory;
            XCTAssertNil([service readPairingDataFromURL:placeholder coordinator:provider progress:freshProgress()]);
            XCTAssertNil([service readPairingDataFromURL:[NSURL URLWithString:@"https://example.invalid/not-a-file"] coordinator:provider progress:freshProgress()],
                         @"The reader must never turn a selected URL into a network request.");
        } @finally {
            XCTAssertTrue([NSFileManager.defaultManager removeItemAtURL:directory error:nil], @"Remove only the owned nonsecret fixture directory.");
            [completed fulfill];
        }
    });
    [self waitForExpectations:@[completed] timeout:10];
}
@end
