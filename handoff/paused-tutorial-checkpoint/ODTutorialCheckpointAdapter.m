#import "ODTutorialCheckpointAdapter.h"
#import "../creator/ODBoundOriginalCreatorServices.h"
#import "../../adapter/ios/ODNativeCore.h"
#import <CoreFoundation/CoreFoundation.h>
#include <stdint.h>
#include <string.h>

// This is a source admission boundary, never a value taken from a page or JSON
// request. The proven constructor is not yet the entire serialized send path.
static const BOOL ODTutorialWireContractComplete=NO;
static NSError *ODTutorialError(NSString *code) {
    return [NSError errorWithDomain:@"OfflineDokkan.TutorialCheckpoint" code:1
        userInfo:@{NSLocalizedDescriptionKey:code}];
}
static BOOL ODTutorialHex(NSString *value) {
    return [value isKindOfClass:NSString.class]&&value.length==64&&
        [value rangeOfCharacterFromSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdef"] invertedSet]].location==NSNotFound;
}
static BOOL ODTutorialInteger(id value,int64_t *out) {
    if(![value isKindOfClass:NSNumber.class]||CFGetTypeID((__bridge CFTypeRef)value)==CFBooleanGetTypeID())return NO;
    const char *kind=[value objCType];if(!kind||!strchr("cCsSiIlLqQ",kind[0])||kind[1])return NO;
    int64_t n=[value longLongValue];if(n<0||n>INT64_C(9007199254740991))return NO;
    if(out)*out=n;return YES;
}
typedef struct {const unsigned char *bytes;NSUInteger length,at;} ODTutorialJSON;
static void ODTutorialSpace(ODTutorialJSON *p) {
    while(p->at<p->length&&strchr(" \t\r\n",p->bytes[p->at])&&p->bytes[p->at])p->at++;
}
static BOOL ODTutorialTake(ODTutorialJSON *p,unsigned char value) {
    ODTutorialSpace(p);if(p->at>=p->length||p->bytes[p->at]!=value)return NO;p->at++;return YES;
}
static BOOL ODTutorialUnsigned(ODTutorialJSON *p,uint64_t maximum,uint64_t *out) {
    ODTutorialSpace(p);NSUInteger first=p->at;uint64_t value=0;
    while(p->at<p->length&&p->bytes[p->at]>='0'&&p->bytes[p->at]<='9') {
        uint64_t digit=p->bytes[p->at++]-'0';if(value>(maximum-digit)/10)return NO;value=value*10+digit;
    }
    if(first==p->at||(p->at-first>1&&p->bytes[first]=='0'))return NO;
    *out=value;return YES;
}
/** Strict tiny source-shape parser. Preserves uint64 lexical precision without
 * parsing opaque timewarp as a floating point number or an application clock.
 * Only two fixed ASCII keys and integer tokens are admitted; duplicates,
 * escaped/unknown keys, fractions, strings and trailing bytes reject.
 * This owns a1024-byte adapter budget, not an asserted source service limit.
 */
static BOOL ODTutorialProgress(NSData *body,int32_t *progress) {
    if(![body isKindOfClass:NSData.class]||!body.length||body.length>1024)return NO;
    ODTutorialJSON p={body.bytes,body.length,0};BOOL seen=NO,time=NO;
    if(!ODTutorialTake(&p,'{'))return NO;
    for(NSUInteger field=0;field<2;field++) {
        if(!ODTutorialTake(&p,'"'))return NO;
        NSUInteger start=p.at;
        while(p.at<p.length&&p.bytes[p.at]>='a'&&p.bytes[p.at]<='z')p.at++;
        NSUInteger length=p.at-start;
        if(p.at>=p.length||p.bytes[p.at++]!='"'||!ODTutorialTake(&p,':'))return NO;
        BOOL isProgress=length==8&&!memcmp(p.bytes+start,"progress",8);
        BOOL isTime=length==8&&!memcmp(p.bytes+start,"timewarp",8);
        uint64_t value=0;
        if(isProgress&&!seen){if(!ODTutorialUnsigned(&p,INT32_MAX,&value)||!value||value==999999)return NO;seen=YES;*progress=(int32_t)value;}
        else if(isTime&&!time){if(!ODTutorialUnsigned(&p,UINT64_MAX,&value)||!value)return NO;time=YES;}
        else return NO;
        ODTutorialSpace(&p);
        if(p.at<p.length&&p.bytes[p.at]=='}'){p.at++;ODTutorialSpace(&p);return seen&&p.at==p.length;}
        if(!ODTutorialTake(&p,','))return NO;
    }
    return NO;
}
@interface ODTutorialIntent : NSObject
@property(nonatomic,copy) NSString *command;
@property(nonatomic) int32_t progress;
@property(nonatomic,strong) NSData *body;
@property(nonatomic,strong) NSMutableArray<ODLocalTransportCompletion> *completions;
@property(nonatomic,strong,nullable) ODLocalTransportResponse *response;
@property(nonatomic,strong,nullable) NSError *error;
@property(nonatomic) BOOL finished;
@end
@implementation ODTutorialIntent @end

@implementation ODTutorialCheckpointAdapter {
    ODBoundOriginalCreatorServices *_services;NSString *_content,*_scope;
    BOOL (^_current)(void);NSMapTable<ODLocalTransportRequest *,ODTutorialIntent *> *_intents;
}
- (instancetype)initWithBoundServices:(ODBoundOriginalCreatorServices *)services contentID:(NSString *)contentID
        saveScopeSHA256:(NSString *)scope contextIsCurrent:(BOOL (^)(void))current {
    if(!NSThread.isMainThread||![services isKindOfClass:ODBoundOriginalCreatorServices.class]||
       ![contentID isKindOfClass:NSString.class]||!contentID.length||!ODTutorialHex(scope)||!current||!current()||
       ![services originalClientCoreForContentID:contentID saveScopeSHA256:scope])return nil;
    if((self=[super init])){_services=services;_content=[contentID copy];_scope=[scope copy];_current=[current copy];
        _intents=[NSMapTable weakToStrongObjectsMapTable];}return self;
}
- (NSDictionary *)sourceReadiness {
    return @{@"schema":@1,@"nativeCheckpointWriterImplemented":@YES,@"requestMethodPUTProven":@YES,
        @"relativeTutorialResourceProven":@YES,@"positiveSigned32CheckpointOnly":@YES,
        @"zeroTimewarpOmittedByConstructor":@YES,@"timewarpUsedAsClock":@NO,
        @"wireContractComplete":@(ODTutorialWireContractComplete),@"httpRouteInstalled":@NO,
        @"nativeCompilationVerified":@NO,@"originalTutorialGameplayVerified":@NO};
}
- (BOOL)matchesSnapshot:(id)value core:(ODNativeCore *)core revision:(int64_t *)revision {
    if(!NSThread.isMainThread||!_current()||[_services originalClientCoreForContentID:_content saveScopeSHA256:_scope]!=core||
       ![value isKindOfClass:NSDictionary.class])return NO;
    NSDictionary *admission=value[@"admission"],*snapshot=value[@"player_snapshot"];
    return [admission isKindOfClass:NSDictionary.class]&&[snapshot isKindOfClass:NSDictionary.class]&&
        [admission[@"profile_id"] isEqual:@"local-player"]&&[admission[@"content_id"] isEqual:_content]&&
        [admission[@"save_scope_sha256"] isEqual:_scope]&&[snapshot[@"profile_id"] isEqual:@"local-player"]&&
        [snapshot[@"content_id"] isEqual:_content]&&ODTutorialInteger(snapshot[@"revision"],revision);
}
- (void)finishIntent:(ODTutorialIntent *)intent response:(ODLocalTransportResponse *)response error:(NSError *)error {
    if(intent.finished)return;
    intent.finished=YES;intent.response=response;intent.error=error;
    NSArray<ODLocalTransportCompletion> *completions=[intent.completions copy];[intent.completions removeAllObjects];
    for(ODLocalTransportCompletion complete in completions)complete(response,error);
}
- (void)handleRequest:(ODLocalTransportRequest *)request completion:(ODLocalTransportCompletion)complete {
    if(!NSThread.isMainThread){dispatch_async(dispatch_get_main_queue(),^{[self handleRequest:request completion:complete];});return;}
    if(!ODTutorialWireContractComplete||!_current()||![request isActive]||
       ![request.method isEqual:@"PUT"]||![request.path isEqual:@"/tutorial"]){complete(nil,ODTutorialError(@"TUTORIAL_REQUEST_CONTRACT_NOT_ADMITTED"));return;}
    int32_t progress=0;
    if(!ODTutorialProgress(request.body,&progress)){complete(nil,ODTutorialError(@"UNSUPPORTED_TUTORIAL_CHECKPOINT_BODY"));return;}
    ODTutorialIntent *intent=[_intents objectForKey:request];
    if(intent){
        if(intent.progress!=progress||![intent.body isEqual:request.body]){complete(nil,ODTutorialError(@"TUTORIAL_NATIVE_REQUEST_CHANGED"));return;}
        if(intent.finished){
            if(intent.error){complete(nil,intent.error);return;}
            ODNativeCore *owner=[_services originalClientCoreForContentID:_content saveScopeSHA256:_scope];
            if(!owner){complete(nil,ODTutorialError(@"TUTORIAL_BOUND_CORE_UNAVAILABLE"));return;}
            [owner originalClientPlayerSnapshotForProfile:@"local-player" expectedSaveScopeSHA256:_scope
                reply:^(id state,NSError *failure){int64_t revision=0;
                    if(failure||![request isActive]||![self matchesSnapshot:state core:owner revision:&revision])
                        complete(nil,failure?:ODTutorialError(@"TUTORIAL_SCOPE_OR_REQUEST_CHANGED"));
                    else complete(intent.response,nil);
                }];return;
        }
        if(intent.completions.count>=4){complete(nil,ODTutorialError(@"TUTORIAL_NATIVE_REQUEST_BUSY"));return;}
        [intent.completions addObject:[complete copy]];return;
    }
    // This is our private per-native-request intent ID. It is NOT a claimed
    // source wire request ID, progress hash, timewarp token or account value.
    intent=[ODTutorialIntent new];intent.command=[@"tutorial:" stringByAppendingString:NSUUID.UUID.UUIDString];
    intent.progress=progress;intent.body=[request.body copy];intent.completions=[NSMutableArray arrayWithObject:[complete copy]];
    [_intents setObject:intent forKey:request];
    ODNativeCore *core=[_services originalClientCoreForContentID:_content saveScopeSHA256:_scope];
    if(!core){[self finishIntent:intent response:nil error:ODTutorialError(@"TUTORIAL_BOUND_CORE_UNAVAILABLE")];return;}
    [core originalClientPlayerSnapshotForProfile:@"local-player" expectedSaveScopeSHA256:_scope reply:^(id before,NSError *failure){
        int64_t revision=0;
        if(failure||![request isActive]||![self matchesSnapshot:before core:core revision:&revision]){
            [self finishIntent:intent response:nil error:failure?:ODTutorialError(@"TUTORIAL_SCOPE_OR_REQUEST_CHANGED")];return;}
        [core applyOriginalClientOperation:@"tutorial.progress" profile:@"local-player" command:intent.command
            payload:@{@"progress":@(intent.progress)} expectedSaveScopeSHA256:self->_scope expectedRevision:revision
            reply:^(id committed,NSError *mutationFailure){
                int64_t currentRevision=0;
                if(mutationFailure||![self matchesSnapshot:committed core:core revision:&currentRevision]){
                    [self finishIntent:intent response:nil error:mutationFailure?:ODTutorialError(@"TUTORIAL_COMMIT_READBACK_UNAVAILABLE")];return;}
                NSDictionary *state=committed[@"player_snapshot"][@"original_client_tutorial"];
                int64_t checkpoint=0;
                id finished=[state isKindOfClass:NSDictionary.class]?state[@"is_finished"]:nil;
                if(![state isKindOfClass:NSDictionary.class]||![state[@"schema"] isEqual:@1]||
                   ![state[@"policy"] isEqual:@"original-tutorial-entry-v1"]||
                   ![finished isKindOfClass:NSNumber.class]||CFGetTypeID((__bridge CFTypeRef)finished)!=CFBooleanGetTypeID()||[finished boolValue]||
                   !ODTutorialInteger(state[@"progress"],&checkpoint)||checkpoint!=intent.progress){
                    [self finishIntent:intent response:nil error:ODTutorialError(@"TUTORIAL_CHECKPOINT_READBACK_CHANGED")];return;}
                // A cancellation after commit never rolls back the durable
                // checkpoint or turns a failed delivery into another grant.
                if(![request isActive]){[self finishIntent:intent response:nil error:ODTutorialError(@"TUTORIAL_DELIVERY_INACTIVE_AFTER_COMMIT")];return;}
                ODLocalTransportResponse *response=[ODLocalTransportResponse plainJSONResponseWithObject:@{}];
                [self finishIntent:intent response:response error:response?nil:ODTutorialError(@"TUTORIAL_PLAIN_RESPONSE_UNAVAILABLE")];
            }];
    }];
}
- (ODLocalTransportRoute *)checkpointRouteWithError:(NSError **)error {
    if(!NSThread.isMainThread||!ODTutorialWireContractComplete||!_current()){
        if(error)*error=ODTutorialError(@"TUTORIAL_REQUEST_CONTRACT_NOT_ADMITTED");return nil;}
    return [[ODLocalTransportRoute alloc] initWithMethod:@"PUT" path:@"/tutorial"
        handler:^(ODLocalTransportRequest *request,ODLocalTransportCompletion complete){[self handleRequest:request completion:complete];}];
}
@end
