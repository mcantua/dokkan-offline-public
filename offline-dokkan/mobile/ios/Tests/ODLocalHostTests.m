#import <XCTest/XCTest.h>
#import "../ODLocalHost.h"
#import "../ODMasterLibrary.h"
#import "../ODCreatorController.h"
#import "../../../adapter/ios/ODNativeCore.h"
#include "../../../content/content.h"
#include "sqlite3.h"
#include <CommonCrypto/CommonDigest.h>
#include <unistd.h>
#include <stdio.h>

static void ODTick(void) { [NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]]; }
static UIWindow *ODWindow(void) {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes)
        if ([scene isKindOfClass:UIWindowScene.class])
            for (UIWindow *window in ((UIWindowScene *)scene).windows) if (window.isKeyWindow) return window;
    return nil;
}
@interface ODLocalHost (OriginalGameVerification)
- (void)openMaster:(NSURL *)master identity:(NSString *)identity source:(NSString *)source;
@end
static BOOL ODHasSourceModePicker(UIView *view) {
    if([view isKindOfClass:UISegmentedControl.class])return YES;
    for(UIView *child in view.subviews)if(ODHasSourceModePicker(child))return YES;
    return NO;
}
@interface ODLocalHostTests : XCTestCase
@end
@implementation ODLocalHostTests
- (id)creatorJS:(NSString *)body web:(WKWebView *)web {
    __block BOOL done=NO;__block id result;__block NSError *failure;
    [web callAsyncJavaScript:body arguments:@{} inFrame:nil inContentWorld:WKContentWorld.pageWorld completionHandler:^(id value,NSError *error){result=value;failure=error;done=YES;}];
    NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:90];while(!done&&deadline.timeIntervalSinceNow>0)ODTick();
    XCTAssertTrue(done);XCTAssertNil(failure);return result;
}
- (id)coreOperation:(NSString *)operation arguments:(NSDictionary *)arguments host:(ODLocalHost *)host command:(NSString *)command {
    ODNativeCore *core=[host valueForKey:@"core"];__block BOOL done=NO;__block id result;__block NSError *failure;
    [core execute:operation profile:@"local-player" command:command arguments:arguments reply:^(id value,NSError *error){result=value;failure=error;done=YES;}];
    NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:30];while(!done&&deadline.timeIntervalSinceNow>0)ODTick();
    XCTAssertTrue(done);XCTAssertNil(failure);return result;
}
- (ODCreatorController *)openSharedCreator:(ODLocalHost *)host {
    NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:30];while([[host valueForKey:@"busy"] boolValue]&&deadline.timeIntervalSinceNow>0)ODTick();
    [host openCreator];deadline=[NSDate dateWithTimeIntervalSinceNow:150];
    ODCreatorController *controller=nil;NSString *startup=nil;
    while(deadline.timeIntervalSinceNow>0){
        id presented=host.presentedViewController;
        if([presented isKindOfClass:ODCreatorController.class])controller=presented;
        if(controller.isViewLoaded&&controller.webView.URL&&!controller.webView.loading){
            startup=[self creatorJS:@"return String(window.__forgeWorkspaceStartup);" web:controller.webView];
            if([startup isEqual:@"ready"]||[startup isEqual:@"failed"])break;
        }ODTick();
    }XCTAssertNotNil(controller);XCTAssertEqualObjects(startup,@"ready");return [startup isEqual:@"ready"]?controller:nil;
}
- (NSDictionary *)checkEmbeddedCreator:(ODLocalHost *)host master:(NSURL *)master library:(NSString *)library {
    [host refreshPlayer];
    NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:30];while(!host.snapshot&&!host.lastError&&deadline.timeIntervalSinceNow>0)ODTick();
    XCTAssertNotNil(host.snapshot);XCTAssertNil(host.lastError);
    NSData *before=[NSData dataWithContentsOfURL:master options:NSDataReadingMappedIfSafe error:nil];
    unsigned char beforeHash[32];CC_SHA256(before.bytes,(CC_LONG)before.length,beforeHash);
    ODCreatorController *creator=[self openSharedCreator:host];if(!creator)return @{};
    NSDictionary *result=[self creatorJS:@"document.querySelectorAll('dialog[open]').forEach(d=>d.close());let battleProtected=false;try{await OfflineGameHost.loadBattle()}catch(error){battleProtected=error.message==='BATTLE_TRUSTED_PLAN_REQUIRED'}if(!battleProtected)throw Error('Isolated native battle runtime did not preserve trusted-plan authority');await createUnit(1002351);if(!state.project||state.project.source.database!=='eclipse')throw Error('Wrong native master source');state.project.cardOverrides.name='Native Offline Creator check';scheduleSave();await flushSave();const key=state.project.key,host=OfflineCreatorHost;const first=await host.call('offlineCreatorPrepare',{key});const original=await OfflineDokkanCreator.projectToDefinition(first.project,{...first.context,isUnchangedMasterRows:async t=>first.unchangedTables.includes(t)});state.project.cardOverrides.name='Native Offline Creator finished';scheduleSave();await flushSave();let stale=false,forged=false,authority=false;try{await host.call('offlineCreatorFinish',{key,snapshot:first.snapshot,definition:original})}catch{stale=true}const prepared=await host.call('offlineCreatorPrepare',{key});const definition=await OfflineDokkanCreator.projectToDefinition(prepared.project,{...prepared.context,isUnchangedMasterRows:async t=>prepared.unchangedTables.includes(t)});const wrong=structuredClone(definition);wrong.card.name='Not the saved project';try{await host.call('offlineCreatorFinish',{key,snapshot:prepared.snapshot,definition:wrong})}catch{forged=true}try{await window.webkit.messageHandlers.OfflineCreator.postMessage({op:'sql',args:{sql:'DELETE FROM cards'}})}catch{authority=true}const imported=await OfflineCreatorUI.finish(),replayed=await OfflineCreatorUI.finish();const versions=await Native.call('listProjectVersions',{key});const named=await Native.call('saveProjectVersion',{key,label:'Native saved version',expectedCurrentRevision:versions.currentRevision});return {isolatedBattleProtected:battleProtected,key,definitionId:imported.definitionId,version:imported.version,instanceId:imported.instanceId,available:imported.available,ownedReplayEqual:imported.instanceId===replayed.instanceId&&replayed.available===true,imported:imported.imported,newest:imported.library.main_id===imported.definitionId,storedName:imported.library.definitions.find(d=>d.definition_id===imported.definitionId)?.name,replayEqual:imported.definitionId===replayed.definitionId&&imported.version===replayed.version&&imported.library.epoch===replayed.library.epoch&&imported.library.revision===replayed.library.revision,staleRejected:stale,forgedProjectionRejected:forged,arbitrarySqlRejected:authority,savedVersion:!!named.saved,bannerDrawable:imported.banner?.drawable,scheme:location.protocol,innerWidth,pageWidth:document.documentElement.scrollWidth,hasSharedEditor:!!document.querySelector('#main')};" web:creator.webView];
    XCTAssertNotNil(result);if(![result isKindOfClass:NSDictionary.class])return @{};
    XCTAssertTrue([result[@"isolatedBattleProtected"] boolValue]);XCTAssertTrue([result[@"imported"] boolValue]);XCTAssertTrue([result[@"newest"] boolValue]);XCTAssertTrue([result[@"replayEqual"] boolValue]);
    XCTAssertTrue([result[@"staleRejected"] boolValue]);XCTAssertTrue([result[@"forgedProjectionRejected"] boolValue]);XCTAssertTrue([result[@"arbitrarySqlRejected"] boolValue]);XCTAssertTrue([result[@"savedVersion"] boolValue]);
    XCTAssertEqualObjects(result[@"storedName"],@"Native Offline Creator finished");XCTAssertEqualObjects(result[@"scheme"],@"app:");XCTAssertFalse([result[@"bannerDrawable"] boolValue]);
    XCTAssertLessThanOrEqual([result[@"pageWidth"] doubleValue],[result[@"innerWidth"] doubleValue]+1);
    XCTAssertGreaterThan([result[@"instanceId"] longLongValue],0);XCTAssertTrue([result[@"available"] boolValue]);XCTAssertTrue([result[@"ownedReplayEqual"] boolValue]);
    if(![result[@"instanceId"] isKindOfClass:NSNumber.class]||[result[@"instanceId"] longLongValue]<1)return result;
    NSDictionary *ownedBefore=[self coreOperation:@"profile.snapshot" arguments:@{} host:host command:nil];
    NSArray *cardsBefore=ownedBefore[@"cards"];NSDictionary *owned=nil;
    for(NSDictionary *card in cardsBefore)if([card[@"instance_id"] isEqual:result[@"instanceId"]])owned=card;
    XCTAssertNotNil(owned);XCTAssertEqualObjects(owned[@"created_definition"][@"definition_id"],result[@"definitionId"]);XCTAssertEqualObjects(owned[@"level"],@1);XCTAssertEqualObjects(owned[@"sa_level"],@1);
    [self coreOperation:@"team.set" arguments:@{@"slot":@0,@"members":@[result[@"instanceId"]]} host:host command:NSUUID.UUID.UUIDString];
    NSDictionary *edited=[self creatorJS:@"state.project.cardOverrides.name='Native Offline Creator edited';scheduleSave();await flushSave();const saved=await OfflineCreatorUI.finish();const retry=await OfflineCreatorUI.finish();return {instanceId:saved.instanceId,version:saved.version,available:saved.available,replay:saved.instanceId===retry.instanceId&&saved.version===retry.version,name:state.project.cardOverrides.name};" web:creator.webView];
    XCTAssertEqualObjects(edited[@"instanceId"],result[@"instanceId"]);XCTAssertEqual([edited[@"version"] longLongValue],[result[@"version"] longLongValue]+1);XCTAssertTrue([edited[@"available"] boolValue]);XCTAssertTrue([edited[@"replay"] boolValue]);
    NSDictionary *ownedAfter=[self coreOperation:@"profile.snapshot" arguments:@{} host:host command:nil];
    XCTAssertEqual([ownedAfter[@"cards"] count],cardsBefore.count);NSDictionary *updatedCard=nil;
    for(NSDictionary *card in ownedAfter[@"cards"])if([card[@"instance_id"] isEqual:result[@"instanceId"]])updatedCard=card;
    XCTAssertEqualObjects(updatedCard[@"level"],owned[@"level"]);XCTAssertEqualObjects(updatedCard[@"sa_level"],owned[@"sa_level"]);XCTAssertEqualObjects(updatedCard[@"potential"],owned[@"potential"]);XCTAssertEqualObjects(updatedCard[@"created_definition"][@"version"],edited[@"version"]);
    BOOL teamRetained=NO;for(NSDictionary *team in ownedAfter[@"teams"])if([team[@"slot"] isEqual:@0]&&[team[@"members"] isEqual:@[result[@"instanceId"]]])teamRetained=YES;XCTAssertTrue(teamRetained);
    NSMutableDictionary *latest=[result mutableCopy];latest[@"version"]=edited[@"version"];latest[@"storedName"]=edited[@"name"];latest[@"owned_edit_retained_instance_and_team"]=@(teamRetained&&[ownedAfter[@"cards"] count]==cardsBefore.count);result=latest;
    WKSnapshotConfiguration *snapshot=[WKSnapshotConfiguration new];snapshot.afterScreenUpdates=YES;
    __block UIImage *image;__block NSError *snapshotFailure;__block BOOL captured=NO;
    [creator.webView takeSnapshotWithConfiguration:snapshot completionHandler:^(UIImage *value,NSError *error){image=value;snapshotFailure=error;captured=YES;}];deadline=[NSDate dateWithTimeIntervalSinceNow:30];while(!captured&&deadline.timeIntervalSinceNow>0)ODTick();
    XCTAssertTrue(captured);XCTAssertNil(snapshotFailure);XCTAssertNotNil(image);if(image)XCTAssertTrue([UIImagePNGRepresentation(image) writeToFile:[library stringByAppendingPathComponent:@"offline-creator.png"] atomically:YES]);
    // Recreate the real controller/session, keeping the actual private store and native core.
    [creator closeCreator];deadline=[NSDate dateWithTimeIntervalSinceNow:10];while(host.presentedViewController&&deadline.timeIntervalSinceNow>0)ODTick();XCTAssertNil(host.presentedViewController);
    creator=[self openSharedCreator:host];if(!creator)return result;
    NSString *body=[NSString stringWithFormat:@"const key=%@;const project=await Native.call('loadProject',{key});const versions=await Native.call('listProjectVersions',{key});return {name:project.cardOverrides.name,versions:versions.versions.length,source:project.source.database};",[[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:result[@"key"] options:NSJSONWritingFragmentsAllowed error:nil] encoding:NSUTF8StringEncoding]];
    NSDictionary *reopened=[self creatorJS:body web:creator.webView];XCTAssertEqualObjects(reopened[@"name"],result[@"storedName"]);XCTAssertGreaterThan([reopened[@"versions"] integerValue],0);XCTAssertEqualObjects(reopened[@"source"],@"eclipse");
    NSData *after=[NSData dataWithContentsOfURL:master options:NSDataReadingMappedIfSafe error:nil];unsigned char afterHash[32];CC_SHA256(after.bytes,(CC_LONG)after.length,afterHash);XCTAssertEqual(before.length,after.length);XCTAssertEqual(memcmp(beforeHash,afterHash,32),0);
    NSMutableDictionary *report=[result mutableCopy];report[@"native_store_reopened"]=reopened;report[@"master_unchanged"]=@(before.length==after.length&&memcmp(beforeHash,afterHash,32)==0);report[@"scope"]=@"Actual shared Creator screens and pinned native master/project/core bridge in our own Offline app; no original game hook or drawable banner";
    XCTAssertTrue([[NSJSONSerialization dataWithJSONObject:report options:NSJSONWritingPrettyPrinted error:nil] writeToFile:[library stringByAppendingPathComponent:@"offline-creator-result.json"] atomically:YES]);
    [creator closeCreator];deadline=[NSDate dateWithTimeIntervalSinceNow:10];while(host.presentedViewController&&deadline.timeIntervalSinceNow>0)ODTick();
    return report;
}
- (void)testRealNativePlayerPersistenceAndRootedContentOnDuo {
    void (^check)(void) = ^{
        NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:20]; UIWindow *window = ODWindow();
        while (!window && deadline.timeIntervalSinceNow > 0) { ODTick(); window = ODWindow(); }
        XCTAssertNotNil(window); if (!window) return;
        ODLocalHost *host = (id)window.rootViewController;
        XCTAssertTrue([host isKindOfClass:ODLocalHost.class]); if (![host isKindOfClass:ODLocalHost.class]) return;
        deadline = [NSDate dateWithTimeIntervalSinceNow:20];
        while (!host.lastError && !host.snapshot && deadline.timeIntervalSinceNow > 0) ODTick();
        XCTAssertEqualObjects(host.lastError, @"PROFILE_NOT_FOUND");
        [host createPlayer];
        deadline = [NSDate dateWithTimeIntervalSinceNow:20];
        while (!host.snapshot && deadline.timeIntervalSinceNow > 0) ODTick();
        XCTAssertNotNil(host.snapshot); XCTAssertNil(host.lastError);
        XCTAssertEqualObjects(host.snapshot[@"profile_id"], @"local-player");
        XCTAssertEqualObjects(host.snapshot[@"cards"], @[]); // No fake game rewards or starter cards.
        NSDictionary *before = host.snapshot;
        NSURL *saves = [host valueForKey:@"saves"];
        NSURL *master = [NSBundle.mainBundle.resourceURL URLByAppendingPathComponent:@"db/reference.db"];
        ODNativeCore *reopened = [[ODNativeCore alloc] initWithSaveURL:[saves URLByAppendingPathComponent:@"player.db"] masterURL:master contentID:before[@"content_id"]];
        __block BOOL done = NO; __block id result; __block NSError *failure;
        [reopened execute:@"profile.snapshot" profile:@"local-player" command:nil arguments:@{} reply:^(id r, NSError *error) { result = r; failure = error; done = YES; }];
        deadline = [NSDate dateWithTimeIntervalSinceNow:20]; while (!done && deadline.timeIntervalSinceNow > 0) ODTick();
        XCTAssertTrue(done); XCTAssertNil(failure); XCTAssertEqualObjects(result, before);
        BOOL persistedEqual = before && [before isEqual:result];
        done = NO; result = nil; failure = nil;
        [reopened execute:@"/user/profile" profile:@"local-player" command:nil arguments:@{} reply:^(id r, NSError *error) { result = r; failure = error; done = YES; }];
        deadline = [NSDate dateWithTimeIntervalSinceNow:20]; while (!done && deadline.timeIntervalSinceNow > 0) ODTick();
        XCTAssertTrue(done); XCTAssertNil(result); XCTAssertEqualObjects(failure.localizedDescription, @"GAME_WIRE_UNVERIFIED");
        BOOL rejectedWire = [failure.localizedDescription isEqual:@"GAME_WIRE_UNVERIFIED"];
        [reopened close];
        XCTAssertFalse(ODHasSourceModePicker(host.view));
        NSURL *otherMaster=[NSBundle.mainBundle.resourceURL URLByAppendingPathComponent:@"db/sparking-reference.db"];
        NSArray *identities=[host valueForKey:@"identities"];
        [host openMaster:otherMaster identity:identities[1] source:@"sparking"];
        deadline=[NSDate dateWithTimeIntervalSinceNow:20];while([[host valueForKey:@"busy"] boolValue]&&deadline.timeIntervalSinceNow>0)ODTick();
        XCTAssertEqualObjects(host.lastError,@"MASTER_MIGRATION_REQUIRED");
        XCTAssertEqualObjects(host.snapshot,before);
        XCTAssertEqualObjects([host valueForKey:@"selectedGame"],@"eclipse");
        XCTAssertFalse([NSFileManager.defaultManager fileExistsAtPath:[saves URLByAppendingPathComponent:@"sparking-player.db"].path]);
        BOOL onePlayer=host.snapshot&&[host.snapshot isEqual:before]&&!ODHasSourceModePicker(host.view);
        [host refreshPlayer];deadline=[NSDate dateWithTimeIntervalSinceNow:20];while([[host valueForKey:@"busy"] boolValue]&&deadline.timeIntervalSinceNow>0)ODTick();XCTAssertNil(host.lastError);
        NSURL *importRoot = [saves URLByAppendingPathComponent:[@"master-import-check-" stringByAppendingString:NSUUID.UUID.UUIDString]];
        ODMasterLibrary *library = [[ODMasterLibrary alloc] initWithDirectory:importRoot];
        __block NSDictionary *imported; __block NSError *importFailure; __block BOOL importDone = NO;
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY,0), ^{
            NSError *error = nil;
            NSDictionary *value = [library importURL:master game:@"eclipse" error:&error];
            dispatch_async(dispatch_get_main_queue(), ^{ imported = value; importFailure = error; importDone = YES; });
        });
        deadline = [NSDate dateWithTimeIntervalSinceNow:90]; while (!importDone && deadline.timeIntervalSinceNow > 0) ODTick();
        XCTAssertTrue(importDone); XCTAssertNil(importFailure); XCTAssertNotNil(imported);
        NSError *selectionFailure = nil;
        XCTAssertTrue([library activateSource:@"eclipse" error:&selectionFailure]);
        NSDictionary *selected = [library activeSelection:&selectionFailure];
        XCTAssertNil(selectionFailure); XCTAssertEqualObjects(selected[@"content_id"], imported[@"content_id"]);
        BOOL importedMaster = imported && [selected[@"content_id"] isEqual:imported[@"content_id"]];
        [NSFileManager.defaultManager removeItemAtURL:importRoot error:nil]; // Only this test's own import directory.
        // One real Darwin filesystem check of the portable resolver, using a host-selected bundled file.
        NSURL *source = [NSBundle.mainBundle.resourceURL URLByAppendingPathComponent:@"cloud-data-provenance.json"];
        NSData *bytes = [NSData dataWithContentsOfURL:source]; XCTAssertNotNil(bytes);
        unsigned char hash[CC_SHA256_DIGEST_LENGTH]; CC_SHA256(bytes.bytes, (CC_LONG)bytes.length, hash);
        char hex[65]; for (int i=0;i<32;i++) snprintf(hex+i*2,3,"%02x",hash[i]);
        NSURL *cache = [saves URLByAppendingPathComponent:[@"content-check-" stringByAppendingString:NSUUID.UUID.UUIDString]];
        XCTAssertTrue([NSFileManager.defaultManager createDirectoryAtURL:cache withIntermediateDirectories:YES attributes:nil error:nil]);
        od_content *content = NULL; int fd = -1;
        int opened = od_content_open(NSBundle.mainBundle.resourcePath.fileSystemRepresentation, cache.fileSystemRepresentation, &content);
        XCTAssertEqual(opened, 0);
        int resolved = opened ? -1 : od_content_resolve(content,"cloud-data-provenance.json",(int64_t)bytes.length,hex,&fd);
        XCTAssertEqual(resolved, 0, @"Darwin rooted content resolver failed: %s", content ? od_content_error(content) : "OPEN_FAILED");
        if (fd >= 0) close(fd); od_content_close(content);
        [NSFileManager.defaultManager removeItemAtURL:cache error:nil]; // Only this test's owned UUID directory.
        XCTAssertEqual(sqlite3_libversion_number(), 3050004);
        NSString *reportDirectory = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject;
        NSDictionary *creatorResult=[self checkEmbeddedCreator:host master:master library:reportDirectory];
        deadline=[NSDate dateWithTimeIntervalSinceNow:20];while([[host valueForKey:@"busy"] boolValue]&&deadline.timeIntervalSinceNow>0)ODTick();
        XCTAssertFalse([[host valueForKey:@"busy"] boolValue]);
        [host openCollection];
        deadline=[NSDate dateWithTimeIntervalSinceNow:30];while(!host.presentedViewController&&deadline.timeIntervalSinceNow>0)ODTick();
        UINavigationController *collectionNavigation=(id)host.presentedViewController;
        XCTAssertTrue([collectionNavigation isKindOfClass:UINavigationController.class]);
        if(![collectionNavigation isKindOfClass:UINavigationController.class])return;
        UITableViewController *collection=(id)collectionNavigation.topViewController;
        [collection.view layoutIfNeeded];
        XCTAssertEqualObjects(collection.title,@"Character List");
        NSInteger ownedRows=[collection.tableView.dataSource tableView:collection.tableView numberOfRowsInSection:0];
        XCTAssertEqual(ownedRows,1);
        UITableViewCell *ownedCell=[collection.tableView.dataSource tableView:collection.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        XCTAssertEqualObjects(ownedCell.textLabel.text,creatorResult[@"storedName"]);
        UIGraphicsImageRenderer *collectionRenderer=[[UIGraphicsImageRenderer alloc] initWithSize:window.bounds.size];
        UIImage *collectionImage=[collectionRenderer imageWithActions:^(UIGraphicsImageRendererContext *ctx){[window drawViewHierarchyInRect:window.bounds afterScreenUpdates:YES];}];
        XCTAssertTrue([UIImagePNGRepresentation(collectionImage) writeToFile:[reportDirectory stringByAppendingPathComponent:@"offline-collection.png"] atomically:YES]);
        [collectionNavigation dismissViewControllerAnimated:NO completion:nil];
        deadline=[NSDate dateWithTimeIntervalSinceNow:10];while(host.presentedViewController&&deadline.timeIntervalSinceNow>0)ODTick();
        NSDictionary *report = @{@"scope":@"Our own Offline Dokkan single-player native foundation; imported source provenance is not a game mode",
            @"sqlite_version":[NSString stringWithUTF8String:sqlite3_libversion()], @"reopened_profile_equal":@(persistedEqual),
            @"profile_persisted":@(persistedEqual), @"single_original_game_profile":@(onePlayer), @"incompatible_source_preserves_player":@(onePlayer), @"source_mode_picker_absent":@(!ODHasSourceModePicker(host.view)), @"unverified_game_wire_rejected":@(rejectedWire),
            @"actual_master_import_and_reselection":@(importedMaster),
            @"embedded_shared_creator_imported":creatorResult[@"imported"]?:@NO, @"actual_owned_collection_screen":@(ownedRows==1&&[ownedCell.textLabel.text isEqual:creatorResult[@"storedName"]]),
            @"rooted_content_darwin_resolved":@(resolved == 0), @"width":@(window.bounds.size.width), @"height":@(window.bounds.size.height),
            @"not_verified":@[@"Our own playable battle scenes", @"Physical Duo folding", @"Touch/keyboard", @"Android runtime", @"Device signing/install"]};
        XCTAssertTrue([[NSJSONSerialization dataWithJSONObject:report options:NSJSONWritingPrettyPrinted error:nil] writeToFile:[reportDirectory stringByAppendingPathComponent:@"offline-native-result.json"] atomically:YES]);
        UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:window.bounds.size];
        UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) { [window drawViewHierarchyInRect:window.bounds afterScreenUpdates:YES]; }];
        XCTAssertTrue([UIImagePNGRepresentation(image) writeToFile:[reportDirectory stringByAppendingPathComponent:@"offline-native-window.png"] atomically:YES]);
    };
    if (NSThread.isMainThread) check(); else dispatch_sync(dispatch_get_main_queue(), check);
}
@end
