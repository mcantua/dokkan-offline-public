#import "ODResourceResponseProjector.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import <CommonCrypto/CommonDigest.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>

static NSError *ODResourceError(NSString *code) {
    return [NSError errorWithDomain:@"OfflineDokkanResourceProjection" code:1
        userInfo:@{NSLocalizedDescriptionKey:code}];
}
static NSData *ODResourcePinnedFile(NSURL *url,NSString *expected) {
    if(!url.isFileURL||![expected isKindOfClass:NSString.class]||expected.length!=64)return nil;
    int fd=open(url.fileSystemRepresentation,O_RDONLY|O_NOFOLLOW|O_CLOEXEC);if(fd<0)return nil;
    struct stat before,after;NSMutableData *data=nil;
    if(fstat(fd,&before)==0&&S_ISREG(before.st_mode)&&before.st_size>0&&before.st_size<=1024*1024){
        data=[NSMutableData dataWithLength:(NSUInteger)before.st_size];size_t done=0;
        while(done<data.length){
            ssize_t count=read(fd,(char *)data.mutableBytes+done,data.length-done);
            if(count<0&&errno==EINTR)continue;
            if(count<=0){data=nil;break;}done+=(size_t)count;
        }
        if(data&&(fstat(fd,&after)!=0||before.st_dev!=after.st_dev||before.st_ino!=after.st_ino||
            before.st_size!=after.st_size||before.st_mtimespec.tv_sec!=after.st_mtimespec.tv_sec||
            before.st_mtimespec.tv_nsec!=after.st_mtimespec.tv_nsec))data=nil;
    }
    close(fd);if(!data)return nil;
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];CC_SHA256(data.bytes,(CC_LONG)data.length,digest);
    const char digits[]="0123456789abcdef";char hex[65];
    for(NSUInteger i=0;i<sizeof(digest);++i){hex[2*i]=digits[digest[i]>>4];hex[2*i+1]=digits[digest[i]&15];}hex[64]=0;
    return [expected isEqualToString:[NSString stringWithUTF8String:hex]]?[data copy]:nil;
}

@interface ODResourceResponseProjector ()
- (void)evaluateOriginalPlayerMode:(NSInteger)mode decodedTeamBody:(nullable NSDictionary *)body reply:(ODCoreReply)reply;
@end

@implementation ODResourceResponseProjector {
    ODNativeCore *_core;
    NSString *_profile,*_scope,*_content,*_script;
    NSDictionary *_schema;
    ODResourceNativePolicy _policy;
    ODResourceContextCurrent _current;
    dispatch_queue_t _queue;
    JSContext *_context;
}
- (instancetype)initWithCore:(ODNativeCore *)core saveURL:(NSURL *)saveURL masterURL:(NSURL *)masterURL
    contentID:(NSString *)content profileID:(NSString *)profile saveScopeSHA256:(NSString *)scope
    schemaURL:(NSURL *)schemaURL schemaSHA256:(NSString *)schemaHash moduleURL:(NSURL *)moduleURL
    moduleSHA256:(NSString *)moduleHash nativePolicy:(ODResourceNativePolicy)policy contextCurrent:(ODResourceContextCurrent)current {
    if(!core||![core matchesSaveURL:saveURL masterURL:masterURL contentID:content]||
        ![profile isKindOfClass:NSString.class]||!profile.length||![scope isKindOfClass:NSString.class]||scope.length!=64||!current)return nil;
    NSData *schema=ODResourcePinnedFile(schemaURL,schemaHash),*module=ODResourcePinnedFile(moduleURL,moduleHash);
    if(!schema||!module)return nil;
    id parsed=[NSJSONSerialization JSONObjectWithData:schema options:0 error:NULL];
    NSString *script=[[NSString alloc] initWithData:module encoding:NSUTF8StringEncoding];
    if(![parsed isKindOfClass:NSDictionary.class]||!script.length)return nil;
    if((self=[super init])){
        _core=core;_profile=[profile copy];_scope=[scope copy];_content=[content copy];_schema=parsed;_script=script;
        _policy=policy?[policy copy]:nil;_current=[current copy];
        _queue=dispatch_queue_create("personal.offlinedokkan.original-resource-projection",DISPATCH_QUEUE_SERIAL);
    }
    return self;
}
- (void)projectCurrentPlayer:(ODCoreReply)reply {
    [self evaluateOriginalPlayerMode:0 decodedTeamBody:nil reply:reply];
}
- (void)projectCurrentTeams:(ODCoreReply)reply {
    [self evaluateOriginalPlayerMode:1 decodedTeamBody:nil reply:reply];
}
- (void)normalizeOriginalTeamUpdate:(NSDictionary *)decodedBody reply:(ODCoreReply)reply {
    if(![decodedBody isKindOfClass:NSDictionary.class]||![NSJSONSerialization isValidJSONObject:decodedBody]){
        reply(nil,ODResourceError(@"INVALID_ORIGINAL_TEAM_DECODED_BODY"));return;
    }
    NSData *bytes=[NSJSONSerialization dataWithJSONObject:decodedBody options:0 error:NULL];
    if(!bytes||bytes.length>256*1024){reply(nil,ODResourceError(@"ORIGINAL_TEAM_UPDATE_TOO_LARGE"));return;}
    NSDictionary *stable=[NSJSONSerialization JSONObjectWithData:bytes options:0 error:NULL];
    if(![stable isKindOfClass:NSDictionary.class]){reply(nil,ODResourceError(@"INVALID_ORIGINAL_TEAM_DECODED_BODY"));return;}
    [self evaluateOriginalPlayerMode:2 decodedTeamBody:stable reply:reply];
}
- (void)evaluateOriginalPlayerMode:(NSInteger)mode decodedTeamBody:(NSDictionary *)body reply:(ODCoreReply)reply {
    // These modes are private native entrypoints, not caller-selected WebView
    // operations. The only team authority is the actual canonical Core snapshot.
    if(!NSThread.isMainThread){dispatch_async(dispatch_get_main_queue(),^{[self evaluateOriginalPlayerMode:mode decodedTeamBody:body reply:reply];});return;}
    if(!_current()){reply(nil,ODResourceError(@"ORIGINAL_RESOURCE_CONTEXT_CHANGED"));return;}
    if(mode==0&&!_policy){reply(nil,ODResourceError(@"ORIGINAL_RESOURCE_NATIVE_POLICY_UNAVAILABLE"));return;}
    [_core originalClientPlayerSnapshotForProfile:_profile expectedSaveScopeSHA256:_scope reply:^(id envelope,NSError *failure){
        if(failure||![envelope isKindOfClass:NSDictionary.class]||!self->_current()){
            reply(nil,ODResourceError(@"ORIGINAL_RESOURCE_PLAYER_UNAVAILABLE"));return;
        }
        dispatch_async(self->_queue,^{
            NSError *error=nil;id result=nil;
            @try {
                NSDictionary *safeSections=nil;
                if(mode==0){
                    NSDictionary *sections=self->_policy(envelope,&error);
                    NSData *policyJSON=sections&&[NSJSONSerialization isValidJSONObject:sections]?
                        [NSJSONSerialization dataWithJSONObject:sections options:0 error:NULL]:nil;
                    if(error||!policyJSON)error=ODResourceError(@"ORIGINAL_RESOURCE_NATIVE_POLICY_UNAVAILABLE");
                    else safeSections=[NSJSONSerialization JSONObjectWithData:policyJSON options:0 error:NULL];
                }
                if(!error){
                    if(!self->_context){
                        self->_context=[JSContext new];
                        [self->_context evaluateScript:self->_script withSourceURL:[NSURL URLWithString:@"offline-authored:resources-projector"]];
                    }
                    JSContext *context=self->_context;
                    if(context.exception)error=ODResourceError(@"ORIGINAL_RESOURCE_MODULE_UNAVAILABLE");
                    else {
                        NSDictionary *expected=@{@"profile_id":self->_profile,@"content_id":self->_content,@"save_scope_sha256":self->_scope};
                        JSValue *module=context[@"ODResourcesProjector"];
                        NSString *method=mode==1?@"projectTeams":mode==2?@"normalizeTeamUpdate":@"project";
                        NSArray *arguments=mode==1?@[envelope,expected]:mode==2?@[envelope,expected,body]:@[self->_schema,envelope,expected,safeSections];
                        JSValue *value=[module[method] callWithArguments:arguments];
                        id candidate=context.exception?nil:value.toObject;
                        if(![candidate isKindOfClass:NSDictionary.class]||![NSJSONSerialization isValidJSONObject:candidate])
                            error=ODResourceError(mode==2?@"ORIGINAL_TEAM_NORMALIZATION_FAILED":@"ORIGINAL_RESOURCE_PROJECTION_FAILED");
                        else result=candidate;
                    }
                    context.exception=nil;
                }
            } @catch(NSException *exception){error=ODResourceError(@"ORIGINAL_RESOURCE_PROJECTION_FAILED");}
            dispatch_async(dispatch_get_main_queue(),^{
                if(!self->_current()){reply(nil,ODResourceError(@"ORIGINAL_RESOURCE_CONTEXT_CHANGED"));return;}
                reply(result,error);
            });
        });
    }];
}
@end
