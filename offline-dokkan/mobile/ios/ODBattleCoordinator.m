#import "ODBattleCoordinator.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import <CommonCrypto/CommonDigest.h>
#include <sys/stat.h>
#include <math.h>

static const NSUInteger ODBattleRPCBytes=24*1024*1024,ODBattleReplyBytes=8*1024*1024;
static BOOL ODBattleObject(id value){return [value isKindOfClass:NSDictionary.class];}
static NSData *ODBattleJSON(id value){if(!value||![NSJSONSerialization isValidJSONObject:@{@"value":value}])return nil;return [NSJSONSerialization dataWithJSONObject:value options:NSJSONWritingFragmentsAllowed error:nil];}
static NSString *ODBattleCode(id code){if(![code isKindOfClass:NSString.class]||![code length]||[code length]>128||[code rangeOfCharacterFromSet:[[NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"] invertedSet]].location!=NSNotFound)return @"BATTLE_COORDINATOR_FAILED";return code;}
@implementation ODBattleCoordinator {
    NSString *_content,*_failure,*_exception;ODBattleStorageRPC _storage;
    dispatch_queue_t _queue;JSContext *_context;NSMutableDictionary *_pending;
}
- (instancetype)initWithContentID:(NSString *)contentID storage:(ODBattleStorageRPC)storage {
    if((self=[super init])){_content=[contentID copy];_storage=[storage copy];_queue=dispatch_queue_create("personal.offlinedokkan.battle-engine",DISPATCH_QUEUE_SERIAL);_pending=[NSMutableDictionary dictionary];}return self;
}
- (void)reply:(ODBattleCoordinatorReply)reply result:(id)result error:(NSString *)error {dispatch_async(dispatch_get_main_queue(),^{reply(result,error);});}
- (BOOL)takeException {BOOL raised=_exception!=nil||_context.exception!=nil;_exception=nil;_context.exception=nil;return raised;}
- (id)jsonValue:(JSValue *)value limit:(NSUInteger)limit {
    @try{
        JSValue *encoded=[_context[@"JSON"] invokeMethod:@"stringify" withArguments:@[value]];
        if([self takeException]||!encoded.isString)return nil;
        NSData *bytes=[[encoded toString] dataUsingEncoding:NSUTF8StringEncoding];
        if(!bytes||bytes.length>limit)return nil;
        return [NSJSONSerialization JSONObjectWithData:bytes options:NSJSONReadingFragmentsAllowed error:nil];
    }@catch(NSException *ignored){(void)ignored;[self takeException];return nil;}
}
- (JSValue *)reject:(NSString *)code {
    JSValue *error=[JSValue valueWithNewErrorFromMessage:code inContext:_context];error[@"code"]=code;
    return [JSValue valueWithNewPromiseRejectedWithReason:error inContext:_context];
}
- (BOOL)open {
    if(_failure)return NO;if(_context)return YES;
    if(!_storage||!_content.length){_failure=@"BATTLE_COORDINATOR_CONFIGURATION_INVALID";return NO;}
    _context=[[JSContext alloc] init];if(!_context){_failure=@"BATTLE_JAVASCRIPTCORE_UNAVAILABLE";return NO;}
    __weak ODBattleCoordinator *weakSelf=self;
    _context.exceptionHandler=^(JSContext *context,JSValue *exception){(void)exception;ODBattleCoordinator *me=weakSelf;if(me)me->_exception=@"BATTLE_RUNTIME_EXCEPTION";context.exception=nil;};
    _context[@"nativeBattleRPC"]=^JSValue *(JSValue *op,JSValue *arguments){ODBattleCoordinator *me=weakSelf;return me?[me nativeRPC:op arguments:arguments]:nil;};
    NSURL *base=[NSBundle.mainBundle.resourceURL URLByAppendingPathComponent:@"site/gameplay" isDirectory:YES];
    // The runtime installs UTF8/native-SHA support before session.js captures
    // crypto. All three scripts are fixed authored bundle resources.
    for(NSString *name in @[@"coordinator-runtime.js",@"battle.js",@"session.js"]){
        NSURL *file=[base URLByAppendingPathComponent:name];struct stat info;
        if(lstat(file.fileSystemRepresentation,&info)||!S_ISREG(info.st_mode)||S_ISLNK(info.st_mode)||info.st_size<=0||info.st_size>2*1024*1024){_failure=@"BATTLE_BUNDLED_RUNTIME_REQUIRED";return NO;}
        NSString *script=[NSString stringWithContentsOfURL:file encoding:NSUTF8StringEncoding error:nil];
        if(!script){_failure=@"BATTLE_BUNDLED_RUNTIME_REQUIRED";return NO;}
        [_context evaluateScript:script withSourceURL:file];if([self takeException]){_failure=@"BATTLE_BUNDLED_RUNTIME_INVALID";return NO;}
    }
    if(!_context[@"OfflineBattleCoordinator"].isObject||!_context[@"OfflineBattleCoordinator"][@"handle"].isObject||!_context[@"OfflineBattleCoordinator"][@"handlePage"].isObject){_failure=@"BATTLE_BUNDLED_COORDINATOR_MISSING";return NO;}
    return YES;
}
- (JSValue *)nativeRPC:(JSValue *)op arguments:(JSValue *)arguments {
    if(!op.isString||!arguments.isObject||arguments.isArray)return [self reject:@"BATTLE_NATIVE_RPC_INVALID"];
    NSString *operation=[op toString];NSDictionary *args=[self jsonValue:arguments limit:ODBattleRPCBytes];
    if(!ODBattleObject(args)||![@[@"read",@"cas",@"sha256"] containsObject:operation])return [self reject:@"BATTLE_NATIVE_RPC_INVALID"];
    if([operation isEqual:@"sha256"]){
        id bytes=args[@"bytes"];if(args.count!=1||![bytes isKindOfClass:NSArray.class]||[bytes count]>4*1024*1024)return [self reject:@"BATTLE_NATIVE_HASH_INVALID"];
        NSMutableData *input=[NSMutableData dataWithLength:[bytes count]];unsigned char *output=input.mutableBytes;NSUInteger index=0;
        for(id item in bytes){
            if(![item isKindOfClass:NSNumber.class]||CFGetTypeID((__bridge CFTypeRef)item)==CFBooleanGetTypeID()||!isfinite([item doubleValue])||[item doubleValue]!=[item longLongValue]||[item longLongValue]<0||[item longLongValue]>255)return [self reject:@"BATTLE_NATIVE_HASH_INVALID"];
            output[index++]=(unsigned char)[item unsignedIntValue];
        }
        unsigned char digest[32];CC_SHA256(input.bytes,(CC_LONG)input.length,digest);NSMutableArray *answer=[NSMutableArray arrayWithCapacity:32];for(int i=0;i<32;i++)[answer addObject:@(digest[i])];
        return [JSValue valueWithNewPromiseResolvedWithResult:answer inContext:_context];
    }
    if(([operation isEqual:@"read"]&&args.count)||([operation isEqual:@"cas"]&&(args.count!=2||!args[@"expectedToken"]||![args[@"data"] isKindOfClass:NSString.class]||(args[@"expectedToken"]!=NSNull.null&&![args[@"expectedToken"] isKindOfClass:NSString.class]))))return [self reject:@"BATTLE_NATIVE_STORAGE_INVALID"];
    NSString *storageOperation=[operation isEqual:@"read"]?@"offlineBattleRead":@"offlineBattleCompareSwap";
    __weak ODBattleCoordinator *weakSelf=self;
    return [JSValue valueWithNewPromiseInContext:_context fromExecutor:^(JSValue *resolve,JSValue *reject){
        ODBattleCoordinator *me=weakSelf;if(!me){return;}
        me->_storage(storageOperation,args,^(id result,NSString *failure){
            ODBattleCoordinator *owner=weakSelf;if(!owner)return;
            dispatch_async(owner->_queue,^{
                ODBattleCoordinator *current=weakSelf;if(!current)return;
                NSData *encoded=ODBattleJSON(result?:NSNull.null);
                if(failure||!encoded||encoded.length>ODBattleRPCBytes){NSString *code=ODBattleCode(failure?:@"BATTLE_NATIVE_REPLY_TOO_LARGE");JSValue *error=[JSValue valueWithNewErrorFromMessage:code inContext:current->_context];error[@"code"]=code;[reject callWithArguments:@[error]];}
                else [resolve callWithArguments:@[result?:NSNull.null]];
                if([current takeException]){current->_failure=@"BATTLE_NATIVE_REPLY_EXCEPTION";}
            });
        });
    }];
}
- (void)complete:(NSString *)identity envelope:(JSValue *)value rejected:(BOOL)rejected {
    ODBattleCoordinatorReply callback=_pending[identity];if(!callback)return;
    [_pending removeObjectForKey:identity];id envelope=[self jsonValue:value limit:ODBattleReplyBytes];
    if(rejected||!ODBattleObject(envelope)||![envelope[@"id"] isEqual:identity]){[self reply:callback result:nil error:@"BATTLE_RUNTIME_REPLY_INVALID_RETRY_SAME_INTENT"];return;}
    if(envelope[@"error"]){id error=envelope[@"error"];[self reply:callback result:nil error:ODBattleCode(ODBattleObject(error)?error[@"code"]:nil)];return;}
    if(!envelope[@"result"]){[self reply:callback result:nil error:@"BATTLE_RUNTIME_REPLY_INVALID_RETRY_SAME_INTENT"];return;}
    [self reply:callback result:envelope[@"result"] error:nil];
}
- (void)invoke:(NSString *)operation arguments:(NSDictionary *)arguments limit:(NSUInteger)limit reply:(ODBattleCoordinatorReply)reply {
    NSData *bytes=ODBattleJSON(arguments);if(!ODBattleObject(arguments)||!bytes||bytes.length>limit){[self reply:reply result:nil error:@"BATTLE_COORDINATOR_REQUEST_INVALID"];return;}
    NSDictionary *args=[NSJSONSerialization JSONObjectWithData:bytes options:0 error:nil];
    dispatch_async(_queue,^{
        @autoreleasepool{
            if(![self open]){[self reply:reply result:nil error:self->_failure];return;}
            if(self->_pending.count>=16){[self reply:reply result:nil error:@"BATTLE_COORDINATOR_BUSY"];return;}
            NSString *identity=NSUUID.UUID.UUIDString;self->_pending[identity]=[reply copy];
            NSDictionary *request=@{@"id":identity,@"op":operation,@"args":args};
            NSString *entry=[@[@"load",@"dispatch"] containsObject:operation]?@"handlePage":@"handle";
            JSValue *promise=[self->_context[@"OfflineBattleCoordinator"] invokeMethod:entry withArguments:@[request]];
            if([self takeException]||!promise.isObject||!promise[@"then"].isObject){[self->_pending removeObjectForKey:identity];[self reply:reply result:nil error:@"BATTLE_RUNTIME_CALL_FAILED_RETRY_SAME_INTENT"];return;}
            __weak ODBattleCoordinator *weakSelf=self;
            void(^success)(JSValue *)=^(JSValue *value){ODBattleCoordinator *me=weakSelf;if(me)dispatch_async(me->_queue,^{[me complete:identity envelope:value rejected:NO];});};
            void(^failure)(JSValue *)=^(JSValue *value){ODBattleCoordinator *me=weakSelf;if(me)dispatch_async(me->_queue,^{[me complete:identity envelope:value rejected:YES];});};
            [promise invokeMethod:@"then" withArguments:@[success,failure]];
            if([self takeException]){[self->_pending removeObjectForKey:identity];[self reply:reply result:nil error:@"BATTLE_RUNTIME_CALL_FAILED_RETRY_SAME_INTENT"];return;}
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,45*NSEC_PER_SEC),self->_queue,^{ODBattleCoordinator *me=weakSelf;if(!me)return;ODBattleCoordinatorReply pending=me->_pending[identity];if(pending){[me->_pending removeObjectForKey:identity];[me reply:pending result:nil error:@"BATTLE_REPLY_TIMED_OUT_RETRY_SAME_INTENT"];}});
        }
    });
}
- (void)load:(ODBattleCoordinatorReply)reply {[self invoke:@"load" arguments:@{} limit:1024 reply:reply];}
- (void)dispatchCommand:(NSDictionary *)command reply:(ODBattleCoordinatorReply)reply {[self invoke:@"dispatch" arguments:@{@"command":command?:@{}} limit:64*1024 reply:reply];}
- (void)startTrustedPlan:(NSDictionary *)plan reply:(ODBattleCoordinatorReply)reply {
    if(!ODBattleObject(plan)||![plan[@"contentId"] isEqual:_content]){[self reply:reply result:nil error:@"BATTLE_TRUSTED_CONTENT_MISMATCH"];return;}
    [self invoke:@"startTrustedPlan" arguments:@{@"plan":plan} limit:512*1024+128 reply:reply];
}
- (void)openTrustedPlan:(NSDictionary *)reference reply:(ODBattleCoordinatorReply)reply {
    if(!ODBattleObject(reference)||![reference[@"contentId"] isEqual:_content]){[self reply:reply result:nil error:@"BATTLE_TRUSTED_CONTENT_MISMATCH"];return;}
    [self invoke:@"openTrustedPlan" arguments:@{@"reference":reference} limit:4096 reply:reply];
}
@end
