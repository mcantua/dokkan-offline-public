#import <XCTest/XCTest.h>
#import <WebKit/WebKit.h>
#import "../../../offline-dokkan/mobile/ios/ODCreatorController.h"
#import "../../../offline-dokkan/mobile/ios/ODCreatorSession.h"
#import "../../../offline-dokkan/mobile/ios/ODDuoLauncher.h"
#import "../../../offline-dokkan/mobile/ios/ODDuoAccountController.h"
#import "../../../offline-dokkan/adapter/ios/ODNativeCore.h"
#import "../../../offline-dokkan/original-client/master/ODRuntimeForgeCompiler.h"
#import "../../../offline-dokkan/original-client/master/ODRuntimeMasterStore.h"
#include "../../../offline-dokkan/original-client/master/runtime_reader.h"
#import <CommonCrypto/CommonDigest.h>

static NSString *ODFinishHash(NSURL *url){NSData *d=[NSData dataWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:nil];if(!d)return nil;unsigned char h[32];CC_SHA256(d.bytes,(CC_LONG)d.length,h);NSMutableString *s=[NSMutableString string];for(int i=0;i<32;i++)[s appendFormat:@"%02x",h[i]];return s;}
static UIWindow *ODFinishWindow(void){for(UIScene *s in UIApplication.sharedApplication.connectedScenes)if([s isKindOfClass:UIWindowScene.class])for(UIWindow *w in ((UIWindowScene *)s).windows)if(w.isKeyWindow)return w;return nil;}
// Public synthetic n/1000 coefficients only. Report aggregate behavior, never
// a game/user coefficient. This follows Session's actual JSON freeze/disk path.
static NSDictionary *ODFinishNumericProbe(void){
    NSUInteger firstChanges=0,repeatedChanges=0,stringChanges=0;BOOL valid=YES;
    for(NSUInteger n=1;n<=1000;n++){
        NSNumber *input=@((double)n/1000.0);NSDictionary *first=[NSJSONSerialization JSONObjectWithData:[NSJSONSerialization dataWithJSONObject:@{@"coef":input} options:NSJSONWritingSortedKeys error:nil] options:0 error:nil];
        NSDictionary *second=first?[NSJSONSerialization JSONObjectWithData:[NSJSONSerialization dataWithJSONObject:first options:NSJSONWritingSortedKeys error:nil] options:0 error:nil]:nil;
        NSString *text=[NSString stringWithFormat:@"%lu.%03lu",(unsigned long)(n/1000),(unsigned long)(n%1000)];
        NSDictionary *strings=[NSJSONSerialization JSONObjectWithData:[NSJSONSerialization dataWithJSONObject:@{@"coef":text} options:NSJSONWritingSortedKeys error:nil] options:0 error:nil];
        if(!first||!second||!strings){valid=NO;break;}
        if([input doubleValue]!=[first[@"coef"] doubleValue])firstChanges++;
        if([first[@"coef"] doubleValue]!=[second[@"coef"] doubleValue])repeatedChanges++;
        if(![strings[@"coef"] isEqual:text])stringChanges++;
    }
    return @{@"valid":@(valid),@"syntheticCases":@1000,@"numericFirstDecodeChanges":@(firstChanges),@"numericRepeatedDecodeChanges":@(repeatedChanges),@"decimalStringChanges":@(stringChanges)};
}

@interface ODCreatorFinishOnlyTests : XCTestCase
@end
@implementation ODCreatorFinishOnlyTests
- (void)checkAcceptedRuntimeWithSession:(ODCreatorSession *)session diagnosis:(NSDictionary *)diagnosis master:(NSURL *)master directory:(NSURL *)directory completion:(void (^)(NSDictionary *))completion {
    NSDictionary *reference=diagnosis[@"acceptedReference"];NSMutableDictionary *sanitized=[diagnosis mutableCopy];[sanitized removeObjectForKey:@"acceptedReference"];
    if(![diagnosis[@"imported"] boolValue]||![reference isKindOfClass:NSDictionary.class]){completion(sanitized);return;}
    [session acceptedProjectForDefinitionID:reference[@"definitionID"] version:reference[@"version"] reply:^(id packet,NSString *failure){
        if(failure||![packet isKindOfClass:NSDictionary.class]){sanitized[@"phase"]=@"accepted-project";sanitized[@"errorCode"]=failure?:@"ACCEPTED_PROJECT_UNAVAILABLE";completion(sanitized);return;}
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0),^{@autoreleasepool{
            NSError *error=nil;NSURL *site=[NSBundle.mainBundle.resourceURL URLByAppendingPathComponent:@"site" isDirectory:YES];
            ODRuntimeForgeCompiler *compiler=[[ODRuntimeForgeCompiler alloc] initWithTrustedCreatorCore:[site URLByAppendingPathComponent:@"core.js"] compilerScript:[site URLByAppendingPathComponent:@"runtime-forge.js"] error:&error];
            NSDictionary *binding=packet[@"binding"];NSURL *derived=[directory URLByAppendingPathComponent:@"detached-runtime.db"];
            ODRuntimeMasterStore *store=compiler?[[ODRuntimeMasterStore alloc] initWithImmutableMaster:master derivedMaster:derived contentID:binding[@"content_id"] saveScope:binding[@"save_scope"] compiler:compiler error:&error]:nil;
            NSDictionary *first=store?[store compileAcceptedPacket:packet error:&error]:nil,*second=first?[store compileAcceptedPacket:packet error:&error]:nil;
            int64_t actual=0,foreign=0;int lookup=-1,wrong=-1;
            if(second){lookup=od_runtime_card_id(derived.fileSystemRepresentation,[binding[@"content_id"] UTF8String],[binding[@"save_scope"] UTF8String],[binding[@"definition_id"] UTF8String],[binding[@"version"] longLongValue],[binding[@"project_sha256"] UTF8String],[binding[@"definition_sha256"] UTF8String],&actual);
                NSString *scope=binding[@"save_scope"],*prefix=[scope hasPrefix:@"0"]?@"1":@"0";
                NSString *foreignScope=[prefix stringByAppendingString:[scope substringFromIndex:1]];
                wrong=od_runtime_card_id(derived.fileSystemRepresentation,[binding[@"content_id"] UTF8String],foreignScope.UTF8String,[binding[@"definition_id"] UTF8String],[binding[@"version"] longLongValue],[binding[@"project_sha256"] UTF8String],[binding[@"definition_sha256"] UTF8String],&foreign);
            }
            BOOL stable=first&&[first isEqual:second],privateSlot=actual>=97000000&&actual<=98999999,matched=lookup==0&&actual==[first[@"runtime_card_id"] longLongValue],denied=wrong==-3&&foreign==0;
            sanitized[@"runtimeMasterComponent"]=@{@"compiled":@(first!=nil),@"idempotent":@(stable),@"privateSlot":@(privateSlot),@"lookupMatches":@(matched),@"wrongScopeRejected":@(denied),@"originalClientAttached":@NO,@"resourceAdmissionComplete":@NO};
            if(!stable||!privateSlot||!matched||!denied){sanitized[@"phase"]=@"runtime-master";sanitized[@"errorCode"]=@"RUNTIME_MASTER_COMPONENT_FAILED";if(error){sanitized[@"nativeErrorDomain"]=error.domain;sanitized[@"nativeErrorNumber"]=@(error.code);}}
            dispatch_async(dispatch_get_main_queue(),^{completion(sanitized);});
        }});
    }];
}
- (NSString *)scenarioBody { return @"document.querySelectorAll('dialog[open]').forEach(d=>d.close());"
            "const clone=x=>JSON.parse(JSON.stringify(x)),canonical=x=>Array.isArray(x)?'['+x.map(canonical).join(',')+']':x&&typeof x==='object'?'{'+Object.keys(x).sort().map(k=>JSON.stringify(k)+':'+canonical(x[k])).join(',')+'}':JSON.stringify(x),stable=x=>canonical(clone(x));"
            "const allowedRoots=new Set(['format','version','key','createdAt','updatedAt','source','targetId','patch','tables','schema','assets','notes','cardOverrides','sourceStatGrowth','statPolicy','formProjects','animationAssignments','builderAuto','uiLabels','abilityAnimationSources','animationReferences','movieBindings','levelPerk','normalAttackStyle','actionHooks','packedAssets','generatedFiles','sourceDependencies','battlePoseBinding','awaken']);"
            "const diff=(live,saved)=>{const a=clone(live),b=clone(saved),different=[];for(const k of new Set([...Object.keys(a),...Object.keys(b)])){if(canonical(a[k])===canonical(b[k]))continue;const item={field:allowedRoots.has(k)?k:'[other]',liveType:Array.isArray(a[k])?'array':typeof a[k],savedType:Array.isArray(b[k])?'array':typeof b[k]};if(k==='tables')for(const t of new Set([...Object.keys(a.tables||{}),...Object.keys(b.tables||{})])){if(!state.info.schema[t]||canonical(a.tables?.[t])===canonical(b.tables?.[t]))continue;item.table=t;const left=a.tables?.[t],right=b.tables?.[t];if(Array.isArray(left)&&Array.isArray(right)){item.liveRows=left.length;item.savedRows=right.length;for(let r=0;r<Math.min(left.length,right.length);r++){if(canonical(left[r])===canonical(right[r]))continue;item.rowIndex=r;const fields=new Set(state.info.schema[t].map(c=>typeof c==='string'?c:c.name));for(const c of Object.keys(left[r]))if(fields.has(c)&&canonical(left[r][c])!==canonical(right[r][c])){item.column=c;item.liveValueType=typeof left[r][c];item.savedValueType=typeof right[r][c];break;}break;}}break;}different.push(item);if(different.length===8)break;}return different;};"
            "const errorCode=e=>{const s=String(e?.message||'');return /^(CREATOR_|PROJECT_|UNSUPPORTED_|INVALID_|SOURCE_)[A-Z0-9_]{1,100}$/.test(s)?s:'UNCLASSIFIED_FINISH_ERROR';};"
            "let phase='create',lastSaved=null,preparedBeforeFinish=null,numericProof=null,candidateApplied=false;const originalCall=Native.call;Native.call=async function(op,args){const wire=op==='saveProject'?clone(args.project):null;const r=await originalCall.apply(this,arguments);if(op==='saveProject'&&r?.saved===true)lastSaved=wire;return r;};"
            "try{await createUnit(1002351);phase='initial-save';state.project.cardOverrides.name='Native Offline Creator check';scheduleSave();await flushSave();const key=state.project.key,host=OfflineCreatorHost;const first=await host.call('offlineCreatorPrepare',{key});const original=await OfflineDokkanCreator.projectToDefinition(first.project,{...first.context,isUnchangedMasterRows:async t=>first.unchangedTables.includes(t)});"
            "phase='edited-save';state.project.cardOverrides.name='Native Offline Creator finished';scheduleSave();await flushSave();let stale=false,forged=false,authority=false;try{await host.call('offlineCreatorFinish',{key,snapshot:first.snapshot,definition:original})}catch{stale=true}"
            "phase='prepare';preparedBeforeFinish=await host.call('offlineCreatorPrepare',{key});const definition=await OfflineDokkanCreator.projectToDefinition(preparedBeforeFinish.project,{...preparedBeforeFinish.context,isUnchangedMasterRows:async t=>preparedBeforeFinish.unchangedTables.includes(t)});const wrong=clone(definition);wrong.card.name='Not the saved project';try{await host.call('offlineCreatorFinish',{key,snapshot:preparedBeforeFinish.snapshot,definition:wrong})}catch{forged=true}try{await window.webkit.messageHandlers.OfflineCreator.postMessage({op:'sql',args:{sql:'DELETE FROM cards'}})}catch{authority=true}"
            "phase='selected-master-read';const counted=await host.call('creatorMasterRead',{sql:'SELECT count(*) AS n FROM cards',params:[]});let readonlyRejected=true;for(const sql of ['DELETE FROM cards','SELECT 1; SELECT 2','PRAGMA table_info(cards)',`SELECT load_extension('missing')`,`SELECT printf('%20000000s','x')`]){let denied=false;try{await host.call('creatorMasterRead',{sql,params:[]});}catch{denied=true}readonlyRejected=readonlyRejected&&denied;}if(!Number.isSafeInteger(counted?.[0]?.n)||counted[0].n<1||!readonlyRejected)throw Error('INVALID_SELECTED_MASTER_BOUNDARY');phase='finish';let imported;try{imported=await OfflineCreatorUI.finish();}catch(error){const b=error.savedBoundary,d=b?.firstGrowthDifference;if(error.message!=='CREATOR_PREPARE_SAVED_MISMATCH'||!numericProbe?.valid||numericProbe.numericFirstDecodeChanges+numericProbe.numericRepeatedDecodeChanges<1||numericProbe.decimalStringChanges!==0||!b?.sameGrowthRowCount||b.growthFields?.length!==1||b.growthFields[0]!=='rows'||d?.column!=='coef'||!d.bothFinite||!d.sameThousandth||!d.withinOneULP)throw error;numericProof={errorCode:error.message,actualFinishSavedBoundary:b};const hydrate=Forge.hydrateStatGrowth;Forge.hydrateStatGrowth=async function(project,...args){const before=stable(project);await hydrate.call(this,project,...args);const m=project.sourceStatGrowth;if(m?.policy!=='creator-cap-normalized-v1'||!Number.isSafeInteger(m.sourceGrowType)||!Array.isArray(m.rows)||m.rows.length<2||m.rows.length>5000)throw Error('INVALID_DERIVED_GROWTH_METADATA');m.rows=m.rows.map((row,index)=>{const coef=Number(row.coef),scaled=coef*1000,n=Math.round(scaled);if(row.lv!==index+1||!Number.isFinite(coef)||n<0||n>2147483647||Math.abs(scaled-n)>0.000001)throw Error('INVALID_DERIVED_GROWTH_METADATA');return {...row,coef:Math.floor(n/1000)+'.'+String(n%1000).padStart(3,'0')};});return stable(project)!==before;};candidateApplied=true;phase='proof-gated-decimal-retry';imported=await OfflineCreatorUI.finish();}phase='same-intent-retry';const replayed=await OfflineCreatorUI.finish();return {phase,numericProof,candidateApplied,productionFixApplied:false,acceptedReference:{definitionID:imported.definitionId,version:imported.version},imported:imported.imported===true,instancePositive:Number.isSafeInteger(imported.instanceId)&&imported.instanceId>0,sameInstance:imported.instanceId===replayed.instanceId,sameVersion:imported.version===replayed.version,staleRejected:stale,forgedRejected:forged,arbitrarySqlRejected:authority,selectedMasterReadonly:readonlyRejected,scheme:location.protocol};"
            "}catch(error){const out={phase,errorCode:errorCode(error),scheme:location.protocol};if(error.savedBoundary)out.actualFinishSavedBoundary=error.savedBoundary;if(numericProof)out.numericProof=numericProof;out.candidateApplied=candidateApplied;out.productionFixApplied=false;if(lastSaved)out.liveMatchesLastSubmittedSave=stable(state.project)===stable(lastSaved);if(preparedBeforeFinish?.project){out.liveMatchesPrepared=stable(state.project)===stable(preparedBeforeFinish.project);out.preparedMatchesLastSubmittedSave=lastSaved?stable(lastSaved)===stable(preparedBeforeFinish.project):null;out.valueFreeDifferences=diff(state.project,preparedBeforeFinish.project);}return out;}finally{Native.call=originalCall;}"; }
- (void)waitForCreator:(ODCreatorController *)controller deadline:(NSDate *)deadline completion:(void (^)(BOOL))completion {
    if(deadline.timeIntervalSinceNow<=0){completion(NO);return;}
    void (^later)(void)=^{dispatch_after(dispatch_time(DISPATCH_TIME_NOW,100*NSEC_PER_MSEC),dispatch_get_main_queue(),^{[self waitForCreator:controller deadline:deadline completion:completion];});};
    if(!controller.webView.URL||controller.webView.loading){later();return;}
    [controller.webView callAsyncJavaScript:@"return String(window.__forgeWorkspaceStartup);" arguments:@{} inFrame:nil inContentWorld:WKContentWorld.pageWorld completionHandler:^(id value,NSError *error){
        if(error||[value isEqual:@"failed"]){completion(NO);return;}
        if([value isEqual:@"ready"]){completion(YES);return;}later();
    }];
}
- (void)recordResult:(NSDictionary *)result ready:(BOOL)ready master:(NSURL *)master before:(NSString *)before controller:(ODCreatorController *)controller completion:(XCTestExpectation *)completed {
    NSString *library=NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSUserDomainMask,YES).firstObject;
    NSDictionary *report=@{@"scope":@"Hosted genuine Duo WK embedded Creator save/prepare/Finish component only; no original-game launch, physical displays, app package or gameplay proof",@"startupReady":@(ready),@"masterUnchanged":@([before isEqual:ODFinishHash(master)]),@"numericJSONProbe":ODFinishNumericProbe(),@"finish":result};
    NSData *json=[NSJSONSerialization dataWithJSONObject:report options:NSJSONWritingPrettyPrinted|NSJSONWritingSortedKeys error:nil];
    XCTAssertTrue([json writeToFile:[library stringByAppendingPathComponent:@"finish-only-result.json"] atomically:YES]);
    __block BOOL ended=NO;
    void (^finish)(void)=^{if(ended)return;ended=YES;
        XCTAssertTrue([report[@"startupReady"] boolValue]);XCTAssertTrue([report[@"masterUnchanged"] boolValue]);
        XCTAssertNil(result[@"errorCode"],@"Value-free Finish boundary code: %@",result[@"errorCode"]);
        XCTAssertTrue([result[@"imported"] boolValue]);XCTAssertTrue([result[@"instancePositive"] boolValue]);XCTAssertTrue([result[@"sameInstance"] boolValue]);XCTAssertTrue([result[@"sameVersion"] boolValue]);
        XCTAssertTrue([result[@"staleRejected"] boolValue]);XCTAssertTrue([result[@"forgedRejected"] boolValue]);XCTAssertTrue([result[@"arbitrarySqlRejected"] boolValue]);[completed fulfill];
    };
    if(!controller){finish();return;}
    WKSnapshotConfiguration *snapshot=[WKSnapshotConfiguration new];snapshot.afterScreenUpdates=YES;
    [controller.webView takeSnapshotWithConfiguration:snapshot completionHandler:^(UIImage *image,NSError *error){
        NSData *png=image?UIImagePNGRepresentation(image):nil;
        if(png){[png writeToFile:[library stringByAppendingPathComponent:@"finish-only-wk.png"] atomically:YES];[png writeToFile:[library stringByAppendingPathComponent:@"duo-import-confirmation.png"] atomically:YES];}
        [controller.webView callAsyncJavaScript:@"return !!document.querySelector('.offline-import-confirm');" arguments:@{} inFrame:nil inContentWorld:WKContentWorld.pageWorld completionHandler:^(id value,NSError *jsError){
            if([result[@"imported"] boolValue])XCTAssertEqualObjects(value,@YES);
            finish();
        }];
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,15*NSEC_PER_SEC),dispatch_get_main_queue(),finish);
}
- (NSString *)shotDirectory { return NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject; }
- (BOOL)saveWindow:(UIWindow *)window name:(NSString *)name {
    if(window.bounds.size.width<100||window.bounds.size.height<100)return NO;
    UIGraphicsImageRenderer *renderer=[[UIGraphicsImageRenderer alloc] initWithBounds:window.bounds];
    UIImage *image=[renderer imageWithActions:^(UIGraphicsImageRendererContext *context){[window drawViewHierarchyInRect:window.bounds afterScreenUpdates:YES];}];
    NSData *png=UIImagePNGRepresentation(image);
    return png.length>250&&image.size.width>100&&[png writeToFile:[[self shotDirectory] stringByAppendingPathComponent:name] atomically:YES];
}
- (void)saveWeb:(WKWebView *)web name:(NSString *)name completion:(void (^)(BOOL))completion {
    WKSnapshotConfiguration *snapshot=[WKSnapshotConfiguration new];snapshot.afterScreenUpdates=YES;
    [web takeSnapshotWithConfiguration:snapshot completionHandler:^(UIImage *image,NSError *error){
        NSData *png=image?UIImagePNGRepresentation(image):nil;
        BOOL wrote=png.length>250&&image.size.width>100&&[png writeToFile:[[self shotDirectory] stringByAppendingPathComponent:name] atomically:YES];
        completion(wrote&&!error);
    }];
}
- (void)waitUntil:(NSDate *)deadline ready:(BOOL (^)(void))ready completion:(void (^)(BOOL))completion {
    if(ready()){completion(YES);return;}
    if(deadline.timeIntervalSinceNow<=0){completion(NO);return;}
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,100*NSEC_PER_MSEC),dispatch_get_main_queue(),^{[self waitUntil:deadline ready:ready completion:completion];});
}
- (void)testSavedDraftPrepareAndFinishOnDuo {
    XCTestExpectation *completed=[self expectationWithDescription:@"One actual embedded Creator Finish boundary on hosted Duo"];
    // All native work is callback-driven. Never spin a nested run loop inside a
    // main dispatch block while waiting for ODNativeCore's main-queue reply.
    dispatch_async(dispatch_get_main_queue(),^{
        NSString *library=NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSUserDomainMask,YES).firstObject;
        NSURL *master=[NSBundle.mainBundle.resourceURL URLByAppendingPathComponent:@"db/reference.db"];NSString *before=ODFinishHash(master);
        NSURL *owned=[NSURL fileURLWithPath:[library stringByAppendingPathComponent:@"finish-only-state"] isDirectory:YES];
        BOOL directory=[NSFileManager.defaultManager createDirectoryAtURL:owned withIntermediateDirectories:YES attributes:nil error:nil];
        NSString *identity=before?[@"sha256:" stringByAppendingString:before]:nil;
        if(!directory||!identity){[self recordResult:@{@"phase":@"setup",@"errorCode":@"MASTER_SETUP_FAILED"} ready:NO master:master before:before controller:nil completion:completed];return;}
        ODNativeCore *core=[[ODNativeCore alloc] initWithSaveURL:[owned URLByAppendingPathComponent:@"player.db"] masterURL:master contentID:identity];
        __block BOOL coreFinished=NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,30*NSEC_PER_SEC),dispatch_get_main_queue(),^{if(coreFinished)return;coreFinished=YES;[self recordResult:@{@"phase":@"profile-create",@"errorCode":@"CORE_CREATE_TIMEOUT"} ready:NO master:master before:before controller:nil completion:completed];});
        [core execute:@"profile.create" profile:@"local-player" command:@"finish-only-player" arguments:@{} reply:^(id result,NSError *error){
            if(coreFinished)return;coreFinished=YES;
            if(error||![result isKindOfClass:NSDictionary.class]){[self recordResult:@{@"phase":@"profile-create",@"errorCode":@"CORE_CREATE_FAILED"} ready:NO master:master before:before controller:nil completion:completed];return;}
            NSURL *creatorDirectory=[owned URLByAppendingPathComponent:@"creator"];
            ODDuoLauncher *launcher=[[ODDuoLauncher alloc] initWithCore:core masterURL:master contentID:identity game:@"eclipse" creatorDirectory:creatorDirectory];
            UIWindow *window=ODFinishWindow();
            if(!window){[self recordResult:@{@"phase":@"window",@"errorCode":@"NATIVE_WINDOW_UNAVAILABLE"} ready:NO master:master before:before controller:nil completion:completed];return;}
            window.rootViewController=launcher;[window makeKeyAndVisible];[launcher loadViewIfNeeded];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(0.6*NSEC_PER_SEC)),dispatch_get_main_queue(),^{
                if(![self saveWindow:window name:@"duo-launcher.png"]){[self recordResult:@{@"phase":@"launcher",@"errorCode":@"LAUNCHER_SCREENSHOT_FAILED"} ready:NO master:master before:before controller:nil completion:completed];return;}
                [launcher openOfflineDokkan];
                [self waitUntil:[NSDate dateWithTimeIntervalSinceNow:20] ready:^BOOL{return launcher.accountController.accountReady;} completion:^(BOOL accountReady){
                    if(!accountReady||![self saveWindow:window name:@"duo-offline-dokkan-account.png"]){[self recordResult:@{@"phase":@"launcher",@"errorCode":@"ACCOUNT_NOT_READY"} ready:NO master:master before:before controller:nil completion:completed];return;}
                    [launcher openUnitCreator];
                    [self waitUntil:[NSDate dateWithTimeIntervalSinceNow:150] ready:^BOOL{return launcher.creatorController.webView!=nil;} completion:^(BOOL presented){
                        ODCreatorController *controller=launcher.creatorController;
                        if(!presented||!controller){[self recordResult:@{@"phase":@"launcher",@"errorCode":@"CREATOR_NOT_PRESENTED"} ready:NO master:master before:before controller:controller completion:completed];return;}
                        [self waitForCreator:controller deadline:[NSDate dateWithTimeIntervalSinceNow:150] completion:^(BOOL ready){
                            if(!ready){[self recordResult:@{@"phase":@"startup",@"errorCode":@"CREATOR_STARTUP_NOT_READY"} ready:NO master:master before:before controller:controller completion:completed];return;}
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(0.5*NSEC_PER_SEC)),dispatch_get_main_queue(),^{
                                [controller.webView callAsyncJavaScript:@"document.querySelectorAll('dialog[open]').forEach(d=>d.close());return {bar:!!document.querySelector('.offline-creator-completion'),home:!!(document.getElementById('db-quick')||document.getElementById('dk-start'))};" arguments:@{} inFrame:nil inContentWorld:WKContentWorld.pageWorld completionHandler:^(id value,NSError *entryError){
                                    NSDictionary *entry=[value isKindOfClass:NSDictionary.class]?value:nil;
                                    if(entryError||[entry[@"bar"] boolValue]||![entry[@"home"] boolValue]){[self recordResult:@{@"phase":@"launcher",@"errorCode":@"CREATOR_ENTRY_IS_FINISH_SHEET"} ready:YES master:master before:before controller:controller completion:completed];return;}
                                    [self saveWeb:controller.webView name:@"duo-unit-creator.png" completion:^(BOOL wrote){
                                        if(!wrote){[self recordResult:@{@"phase":@"launcher",@"errorCode":@"CREATOR_SCREENSHOT_FAILED"} ready:YES master:master before:before controller:controller completion:completed];return;}
                                        __block BOOL scriptFinished=NO;
                                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,90*NSEC_PER_SEC),dispatch_get_main_queue(),^{if(scriptFinished)return;scriptFinished=YES;[self recordResult:@{@"phase":@"finish",@"errorCode":@"NATIVE_JS_DIAGNOSTIC_TIMEOUT"} ready:YES master:master before:before controller:controller completion:completed];});
                                        [controller.webView callAsyncJavaScript:[self scenarioBody] arguments:@{@"numericProbe":ODFinishNumericProbe()} inFrame:nil inContentWorld:WKContentWorld.pageWorld completionHandler:^(id value,NSError *failure){
                                            if(scriptFinished)return;scriptFinished=YES;
                                            NSDictionary *diagnosis=!failure&&[value isKindOfClass:NSDictionary.class]?value:@{@"phase":@"finish",@"errorCode":@"NATIVE_JS_DIAGNOSTIC_FAILED"};
                                            ODCreatorSession *session=[[ODCreatorSession alloc] initWithMasterURL:master contentID:identity game:@"eclipse" directory:creatorDirectory core:core];
                                            [self checkAcceptedRuntimeWithSession:session diagnosis:diagnosis master:master directory:owned completion:^(NSDictionary *checked){[self recordResult:checked ready:YES master:master before:before controller:controller completion:completed];}];
                                        }];
                                    }];
                                }];
                            });
                        }];
                    }];
                }];
            });
        }];
    });
    [self waitForExpectations:@[completed] timeout:330];
}
@end
