#import "ODOriginalPracticeSession.h"
#import "../../adapter/ios/ODNativeCore.h"
#import <CommonCrypto/CommonDigest.h>
#include <math.h>

static NSError *ODPracticeSessionFailure(void) {
    return [NSError errorWithDomain:@"OfflineDokkan.OriginalPracticeSession" code:1
        userInfo:@{NSLocalizedDescriptionKey:@"ORIGINAL_PRACTICE_SESSION_SAVE_UNAVAILABLE"}];
}
static BOOL ODPracticeSessionTrue(id value) {
    return [value isKindOfClass:NSNumber.class]&&CFGetTypeID((__bridge CFTypeRef)value)==CFBooleanGetTypeID()&&[value boolValue];
}
static BOOL ODPracticeSessionInteger(id value,int64_t *number) {
    if(![value isKindOfClass:NSNumber.class]||CFGetTypeID((__bridge CFTypeRef)value)==CFBooleanGetTypeID())return NO;
    double n=[value doubleValue];if(!isfinite(n)||n<0||n>9007199254740991.0||floor(n)!=n)return NO;
    *number=[value longLongValue];return (double)*number==n;
}
static BOOL ODPracticeSessionHex(NSString *value) {
    return [value isKindOfClass:NSString.class]&&value.length==64&&
        [value rangeOfCharacterFromSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdef"] invertedSet]].location==NSNotFound;
}
static BOOL ODPracticeSessionKnownRevisionRejection(NSError *error) {
    // Core checks retained command/tombstone replay before revision rejection.
    // This exact error therefore proves this command was not committed. A
    // pruned result has a distinct error and must never take this path.
    return [error.domain isEqual:@"OfflineDokkanCore"]&&
        [error.userInfo[NSLocalizedDescriptionKey] isEqual:@"ORIGINAL_PLAYER_REVISION_CHANGED"];
}
static NSString *ODPracticeSessionHash(NSData *data) {
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];CC_SHA256(data.bytes,(CC_LONG)data.length,digest);
    NSMutableString *hex=[NSMutableString stringWithCapacity:64];
    for(NSUInteger i=0;i<sizeof digest;i++)[hex appendFormat:@"%02x",digest[i]];return hex;
}

@interface ODOriginalPracticeSession ()
- (BOOL)matchesEnvelope:(id)envelope revision:(int64_t *)revision;
- (void)performFinish:(BOOL)finish completion:(void (^)(NSError * _Nullable error))completion;
- (void)applyFinish:(BOOL)finish completion:(void (^)(NSError * _Nullable error))completion;
@end
@implementation ODOriginalPracticeSession {
    ODNativeCore *_core;NSString *_content,*_profile,*_scope,*_session,*_parameterHash;
    NSDictionary *_payload;BOOL (^_current)(void);BOOL _busy;
    int64_t _beginRevision,_finishRevision;NSString *_state;
    NSUInteger _beginAttempt,_finishAttempt;
}
- (instancetype)initWithCore:(ODNativeCore *)core contentID:(NSString *)content profileID:(NSString *)profile
        saveScopeSHA256:(NSString *)scope parametersJSON:(NSData *)parameters sourceReceipt:(NSDictionary *)receipt
        contextIsCurrent:(BOOL (^)(void))current {
    if(!NSThread.isMainThread||!core||![content isKindOfClass:NSString.class]||!content.length||
       ![profile isEqual:@"local-player"]||!ODPracticeSessionHex(scope)||!current||!current()||
       ![parameters isKindOfClass:NSData.class]||!parameters.length||parameters.length>65536||
       ![receipt isKindOfClass:NSDictionary.class])return nil;
    int64_t phase=0,bytes=0;NSString *hash=ODPracticeSessionHash(parameters);
    if(![receipt[@"kind"] isEqual:@"original-master-practice-phase3"]||![receipt[@"content_id"] isEqual:content]||
       !ODPracticeSessionInteger(receipt[@"phase_number"],&phase)||phase!=3||
       !ODPracticeSessionInteger(receipt[@"parameter_bytes"],&bytes)||bytes!=(int64_t)parameters.length||
       ![receipt[@"parameter_sha256"] isEqual:hash]||!ODPracticeSessionTrue(receipt[@"source_read_only"])||
       !ODPracticeSessionTrue(receipt[@"core_owned_id_collision_checked"]))return nil;
    if((self=[super init])){
        _core=core;_content=[content copy];_profile=[profile copy];_scope=[scope copy];_current=[current copy];
        _parametersJSON=[parameters copy];_parameterHash=hash;_session=NSUUID.UUID.UUIDString.lowercaseString;
        _payload=@{@"session_id":_session,@"phase_number":@3,@"parameters_sha256":_parameterHash};
        _beginRevision=-1;_finishRevision=-1;_state=@"not-prepared";
    }return self;
}
- (NSString *)state {return NSThread.isMainThread?_state:@"main-thread-required";}
- (BOOL)matchesEnvelope:(id)value revision:(int64_t *)revision {
    if(![value isKindOfClass:NSDictionary.class])return NO;
    NSDictionary *admission=value[@"admission"],*snapshot=value[@"player_snapshot"];
    return [admission isKindOfClass:NSDictionary.class]&&[snapshot isKindOfClass:NSDictionary.class]&&
        [admission[@"profile_id"] isEqual:_profile]&&[admission[@"content_id"] isEqual:_content]&&
        [admission[@"save_scope_sha256"] isEqual:_scope]&&ODPracticeSessionTrue(admission[@"clean"])&&
        [snapshot[@"profile_id"] isEqual:_profile]&&[snapshot[@"content_id"] isEqual:_content]&&
        ODPracticeSessionInteger(snapshot[@"revision"],revision);
}
- (void)prepareWithCompletion:(void (^)(NSError *))completion {[self performFinish:NO completion:completion];}
- (void)persistNativeFinishWithCompletion:(void (^)(NSError *))completion {[self performFinish:YES completion:completion];}
- (void)performFinish:(BOOL)finish completion:(void (^)(NSError *))completion {
    if(!completion)return;
    if(!NSThread.isMainThread){dispatch_async(dispatch_get_main_queue(),^{[self performFinish:finish completion:completion];});return;}
    if(_busy||!_current()||(finish&&!_prepared)){completion(ODPracticeSessionFailure());return;}
    if(finish?_nativeFinishPersisted:_prepared){completion(nil);return;}
    _busy=YES;_state=finish?@"saving-native-finish":@"preparing-session";
    int64_t expected=finish?_finishRevision:_beginRevision;
    if(expected>=0){[self applyFinish:finish completion:completion];return;}
    [_core originalClientPlayerSnapshotForProfile:_profile expectedSaveScopeSHA256:_scope reply:^(id envelope,NSError *failure){
        int64_t revision=0;
        if(failure||!self->_current()||![self matchesEnvelope:envelope revision:&revision]){
            self->_busy=NO;self->_state=finish?@"native-finish-save-unavailable":@"session-preparation-unavailable";
            completion(ODPracticeSessionFailure());return;
        }
        // Retain the first revision for this exact command. Unknown-commit
        // retry must not silently become a new intent or replay combat.
        if(finish)self->_finishRevision=revision;else self->_beginRevision=revision;
        [self applyFinish:finish completion:completion];
    }];
}
- (void)applyFinish:(BOOL)finish completion:(void (^)(NSError *))completion {
    NSString *operation=finish?@"practice.finish":@"practice.begin";
    NSUInteger attempt=finish?_finishAttempt:_beginAttempt;
    NSString *command=[NSString stringWithFormat:@"nativepractice.%@:%@",finish?@"finish":@"begin",_session];
    if(attempt)command=[command stringByAppendingFormat:@":retry%llu",(unsigned long long)attempt];
    int64_t expected=finish?_finishRevision:_beginRevision;
    [_core applyOriginalClientOperation:operation profile:_profile command:command payload:_payload
        expectedSaveScopeSHA256:_scope expectedRevision:expected reply:^(id result,NSError *failure){
            int64_t revision=0,phase=0,preparedRevision=0,finishRevision=0;
            NSDictionary *receipt=[result isKindOfClass:NSDictionary.class]?result[@"mutation_receipt"]:nil;
            BOOL valid=!failure&&self->_current()&&[self matchesEnvelope:result revision:&revision]&&
                [receipt isKindOfClass:NSDictionary.class]&&[receipt[@"kind"] isEqual:@"offline-original-practice-session"]&&
                [receipt[@"profile_id"] isEqual:self->_profile]&&[receipt[@"content_id"] isEqual:self->_content]&&
                [receipt[@"session_id"] isEqual:self->_session]&&[receipt[@"parameters_sha256"] isEqual:self->_parameterHash]&&
                ODPracticeSessionInteger(receipt[@"phase_number"],&phase)&&phase==3&&
                ODPracticeSessionInteger(receipt[@"prepared_revision"],&preparedRevision)&&preparedRevision>0&&preparedRevision<=revision&&
                [receipt[@"state"] isEqual:(finish?@"native-finish-observed":@"prepared")];
            if(valid&&finish)valid=ODPracticeSessionInteger(receipt[@"finish_revision"],&finishRevision)&&
                finishRevision>preparedRevision&&finishRevision==expected+1&&finishRevision<=revision;
            if(valid&&!finish)valid=preparedRevision==expected+1&&receipt[@"finish_revision"]==NSNull.null;
            self->_busy=NO;
            if(!valid){
                if(ODPracticeSessionKnownRevisionRejection(failure)&&attempt<NSUIntegerMax){
                    // A later explicit user retry revalidates the current
                    // scope/revision and uses a new intent for the SAME saved
                    // session. Unknown commit/errors retain the prior intent.
                    if(finish){self->_finishRevision=-1;self->_finishAttempt=attempt+1;}
                    else {self->_beginRevision=-1;self->_beginAttempt=attempt+1;}
                }
                self->_state=finish?@"native-finish-save-unavailable":@"session-preparation-unavailable";completion(ODPracticeSessionFailure());return;
            }
            if(finish)self->_nativeFinishPersisted=YES;else self->_prepared=YES;
            self->_state=finish?@"native-finish-observed":@"prepared";completion(nil);
        }];
}
@end
