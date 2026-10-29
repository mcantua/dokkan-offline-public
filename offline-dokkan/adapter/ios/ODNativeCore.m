#import "ODNativeCore.h"
#include "../od_bridge.h"
#include "../../original-client/master/overlay_reconcile.h"
#import <CommonCrypto/CommonDigest.h>
#include <sys/stat.h>
#include <errno.h>
#include <string.h>

@interface ODNativeCreatorLease ()
- (instancetype)initWithProfile:(NSString *)profile content:(NSString *)content scope:(NSString *)scope;
@end
@implementation ODNativeCreatorLease
- (instancetype)initWithProfile:(NSString *)profile content:(NSString *)content scope:(NSString *)scope {
    if((self=[super init])) { _profileID=[profile copy];_contentID=[content copy];_saveScopeSHA256=[scope copy]; }
    return self;
}
@end

@implementation ODNativeCore {
    dispatch_queue_t _queue;
    NSURL *_save, *_master;
    NSString *_content;
    od_bridge *_bridge;
    BOOL _closed;
    ODNativeCreatorLease *_creatorLease;
}
- (instancetype)initWithSaveURL:(NSURL *)saveURL masterURL:(NSURL *)masterURL contentID:(NSString *)contentID {
    if ((self = [super init])) {
        _save = [saveURL copy]; _master = [masterURL copy]; _content = [contentID copy];
        _queue = dispatch_queue_create("personal.offlinedokkan.creator-core", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}
- (BOOL)matchesSaveURL:(NSURL *)saveURL masterURL:(NSURL *)masterURL contentID:(NSString *)contentID {
    // These three values never mutate after initialization. Do not read _closed
    // off its owning serial queue; the actual queued operation checks that state.
    return [saveURL isKindOfClass:NSURL.class] && [masterURL isKindOfClass:NSURL.class] &&
           [contentID isKindOfClass:NSString.class] && saveURL.isFileURL && masterURL.isFileURL &&
           [_save isEqual:saveURL] && [_master isEqual:masterURL] && [_content isEqualToString:contentID];
}
static NSError *CoreError(const char *code) {
    return [NSError errorWithDomain:@"OfflineDokkanCore" code:1
                          userInfo:@{NSLocalizedDescriptionKey: code ? [NSString stringWithUTF8String:code] : @"NATIVE_ERROR"}];
}
typedef struct { od_bridge *bridge; const char *profile; } ODProjectionContext;
static int ODProjectionSnapshot(void *opaque,char **json) {
    ODProjectionContext *context=opaque; char *failure=NULL;
    int rc=od_bridge_projection_snapshot(context->bridge,context->profile,json,&failure);
    od_bridge_free(failure); return rc;
}
static int ODProjectionDefinition(void *opaque,int64_t generation,const char *definition,int64_t version,char **json) {
    ODProjectionContext *context=opaque; char *failure=NULL;
    int rc=od_bridge_projection_definition(context->bridge,context->profile,generation,definition,version,json,&failure);
    od_bridge_free(failure); return rc;
}
static int ODProjectionAcknowledge(void *opaque,int64_t generation,const char *state,char **json) {
    ODProjectionContext *context=opaque; char *failure=NULL;
    int rc=od_bridge_projection_ack(context->bridge,context->profile,generation,state,json,&failure);
    od_bridge_free(failure); return rc;
}
static void ODProjectionRelease(void *context,char *json) { (void)context; od_bridge_free(json); }
static int ODProjectionSHA256(void *context,const void *data,size_t length,char hex[65]) {
    (void)context; if ((!data&&length)||!hex) return -1;
    CC_SHA256_CTX hash; CC_SHA256_Init(&hash);
    const unsigned char *bytes=data; size_t done=0;
    while(done<length) {
        size_t count=MIN((size_t)1048576,length-done);
        CC_SHA256_Update(&hash,bytes+done,(CC_LONG)count); done+=count;
    }
    unsigned char digest[CC_SHA256_DIGEST_LENGTH]; CC_SHA256_Final(digest,&hash);
    static const char digits[]="0123456789abcdef";
    for(size_t i=0;i<sizeof(digest);++i) { hex[2*i]=digits[digest[i]>>4]; hex[2*i+1]=digits[digest[i]&15]; }
    hex[64]=0; return 0;
}
static NSDictionary *ODProjectionJSON(const char *json) {
    if(!json)return nil;
    size_t length=strnlen(json,32u*1024u*1024u+1u); if(length>32u*1024u*1024u)return nil;
    NSData *data=[NSData dataWithBytes:json length:length];
    id result=[NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
    return [result isKindOfClass:NSDictionary.class]?result:nil;
}
static BOOL ODProjectionCharacters(NSString *text,NSString *characters,NSUInteger maximum) {
    return [text isKindOfClass:NSString.class] && text.length>0 && text.length<=maximum &&
        [text rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:characters].invertedSet].location==NSNotFound;
}
static NSString *ODProjectionScope(NSDictionary *state,NSString *content,NSString *profile) {
    NSString *identity=state[@"save_identity"], *owner=state[@"profile_id"], *source=state[@"content_id"];
    NSString *identifierChars=@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.:";
    if(!ODProjectionCharacters(identity,@"0123456789abcdef",32)||identity.length!=32 ||
       !ODProjectionCharacters(owner,identifierChars,127)||![owner isEqualToString:profile] ||
       !ODProjectionCharacters(source,identifierChars,256)||![source isEqualToString:content])return nil;
    // All admitted fields above are ASCII and exclude quote/backslash/control
    // bytes. This is exactly compact ASCII JSON [save_identity,profile,content],
    // preserving the native content ID including its provenance prefix.
    NSData *array=[[NSString stringWithFormat:@"[\"%@\",\"%@\",\"%@\"]",identity,owner,source]
        dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:NO];
    char hex[65]; if(!array||ODProjectionSHA256(NULL,array.bytes,array.length,hex)<0)return nil;
    return [NSString stringWithUTF8String:hex];
}
static BOOL ODProjectionOverlayPath(NSURL *overlay,NSURL *save,NSURL *master) {
    if(![overlay isKindOfClass:NSURL.class]||!overlay.isFileURL||!overlay.fileSystemRepresentation ||
       !save.isFileURL||!master.isFileURL||!save.fileSystemRepresentation||!master.fileSystemRepresentation ||
       overlay.query!=nil||overlay.fragment!=nil||
       [overlay.URLByStandardizingPath isEqual:save.URLByStandardizingPath]||
       [overlay.URLByStandardizingPath isEqual:master.URLByStandardizingPath])return NO;
    struct stat target,owner;
    if(lstat(overlay.fileSystemRepresentation,&target)<0)return errno==ENOENT;
    if(!S_ISREG(target.st_mode))return NO;
    if(stat(save.fileSystemRepresentation,&owner)==0&&target.st_dev==owner.st_dev&&target.st_ino==owner.st_ino)return NO;
    if(stat(master.fileSystemRepresentation,&owner)==0&&target.st_dev==owner.st_dev&&target.st_ino==owner.st_ino)return NO;
    return YES;
}
static BOOL ODProjectionGeneration(id value) {
    return [value isKindOfClass:NSNumber.class] && CFGetTypeID((__bridge CFTypeRef)value)!=CFBooleanGetTypeID() &&
        [value longLongValue]>0 && [value longLongValue]<=INT64_C(9007199254740991) &&
        [value doubleValue]==(double)[value longLongValue];
}
static NSDictionary *ODProjectionAdmission(od_bridge *bridge,NSString *profile,NSString *content) {
    char *json=NULL,*failure=NULL;
    int rc=od_bridge_projection_snapshot(bridge,profile.UTF8String,&json,&failure);
    NSDictionary *snapshot=rc>=0?ODProjectionJSON(json):nil;
    NSDictionary *state=[snapshot[@"state"] isKindOfClass:NSDictionary.class]?snapshot[@"state"]:nil;
    NSString *scope=state?ODProjectionScope(state,content,profile):nil;
    NSDictionary *result=nil;
    if(scope&&ODProjectionGeneration(snapshot[@"generation"])&&
        [snapshot[@"applied_generation"] isKindOfClass:NSNumber.class]) {
        result=@{@"content_id":content,@"save_scope_sha256":scope,@"profile_id":profile,
            @"projection_generation":snapshot[@"generation"],@"applied_generation":snapshot[@"applied_generation"],
            @"clean":@([snapshot[@"generation"] isEqual:snapshot[@"applied_generation"]])};
    }
    od_bridge_free(json);od_bridge_free(failure);return result;
}
- (void)originalCreatorProjectionAdmissionForProfile:(NSString *)profile reply:(ODCoreReply)reply {
    NSString *owner=[profile copy];
    dispatch_async(_queue,^{
        NSError *error=nil;NSDictionary *admission=nil;
        if(![owner isKindOfClass:NSString.class]||!owner.length)error=CoreError("INVALID_CREATOR_SCOPE");
        else if([self ensureOpen:&error]) {
            admission=ODProjectionAdmission(self->_bridge,owner,self->_content);
            if(!admission)error=CoreError("CREATOR_PROJECTION_SNAPSHOT_MISMATCH");
        }
        dispatch_async(dispatch_get_main_queue(),^{reply(admission,error);});
    });
}
- (void)originalClientPlayerSnapshotForProfile:(NSString *)profile expectedSaveScopeSHA256:(NSString *)scope reply:(ODCoreReply)reply {
    NSString *owner=[profile copy],*expected=[scope copy];
    dispatch_async(_queue,^{
        NSError *error=nil;NSDictionary *result=nil;
        if(![owner isKindOfClass:NSString.class]||![expected isKindOfClass:NSString.class])error=CoreError("INVALID_ORIGINAL_PLAYER_SCOPE");
        else if([self ensureOpen:&error]) {
            NSDictionary *admission=ODProjectionAdmission(self->_bridge,owner,self->_content);
            if(!admission||![expected isEqualToString:admission[@"save_scope_sha256"]])error=CoreError("ORIGINAL_PLAYER_SCOPE_CHANGED");
            else {
                char *json=NULL,*failure=NULL;
                int rc=od_bridge_offline_player_snapshot(self->_bridge,owner.UTF8String,&json,&failure);
                NSDictionary *player=rc>=0?ODProjectionJSON(json):nil;
                if(!player||![player[@"profile_id"] isEqualToString:owner]||![player[@"content_id"] isEqualToString:self->_content])
                    error=CoreError("ORIGINAL_PLAYER_SNAPSHOT_UNAVAILABLE");
                else result=@{@"admission":admission,@"player_snapshot":player};
                od_bridge_free(json);od_bridge_free(failure);
            }
        }
        dispatch_async(dispatch_get_main_queue(),^{reply(result,error);});
    });
}
- (void)acquireOriginalCreatorLeaseForProfile:(NSString *)profile expectedSaveScopeSHA256:(NSString *)scope
    reply:(ODCoreCreatorLeaseReply)reply {
    NSString *owner=[profile copy],*expected=[scope copy];
    dispatch_async(_queue,^{
        NSError *error=nil;ODNativeCreatorLease *lease=nil;
        if(self->_creatorLease)error=CoreError("CREATOR_EDIT_LEASE_HELD");
        else if(![owner isKindOfClass:NSString.class]||![expected isKindOfClass:NSString.class])error=CoreError("INVALID_CREATOR_SCOPE");
        else if([self ensureOpen:&error]) {
            NSDictionary *admission=ODProjectionAdmission(self->_bridge,owner,self->_content);
            if(!admission||![expected isEqualToString:admission[@"save_scope_sha256"]])error=CoreError("CREATOR_SAVE_SCOPE_CHANGED");
            else if(![admission[@"clean"] boolValue])error=CoreError("CREATOR_PROJECTION_PENDING");
            else {
                lease=[[ODNativeCreatorLease alloc] initWithProfile:owner content:self->_content scope:expected];
                self->_creatorLease=lease;
            }
        }
        dispatch_async(dispatch_get_main_queue(),^{reply(lease,error);});
    });
}
- (void)releaseOriginalCreatorLease:(ODNativeCreatorLease *)lease reply:(ODCoreReply)reply {
    dispatch_async(_queue,^{
        NSError *error=nil;NSDictionary *admission=nil;
        if(!lease||lease!=self->_creatorLease)error=CoreError("CREATOR_LEASE_NOT_CURRENT");
        else if([self ensureOpen:&error]) {
            admission=ODProjectionAdmission(self->_bridge,lease.profileID,self->_content);
            if(!admission||![lease.saveScopeSHA256 isEqualToString:admission[@"save_scope_sha256"]])error=CoreError("CREATOR_SAVE_SCOPE_CHANGED");
            else if(![admission[@"clean"] boolValue])error=CoreError("CREATOR_PROJECTION_PENDING");
            else self->_creatorLease=nil;
        }
        if(error)admission=nil;
        dispatch_async(dispatch_get_main_queue(),^{reply(admission,error);});
    });
}
- (void)executeCreatorOperation:(NSString *)operation profile:(NSString *)profile command:(NSString *)command
    arguments:(NSDictionary *)arguments expectedSaveScopeSHA256:(NSString *)scope
    lease:(ODNativeCreatorLease *)lease reply:(ODCoreReply)reply {
    NSError *encodingError=nil;
    NSData *input=[arguments isKindOfClass:NSDictionary.class]&&[NSJSONSerialization isValidJSONObject:arguments]?
        [NSJSONSerialization dataWithJSONObject:arguments options:0 error:&encodingError]:nil;
    NSString *op=[operation copy],*owner=[profile copy],*intent=[command copy],*expected=[scope copy];
    if(!input) { dispatch_async(dispatch_get_main_queue(),^{reply(nil,CoreError("INVALID_ARGUMENT"));});return; }
    dispatch_async(_queue,^{
        NSError *error=nil;id result=nil;
        if(![@[@"creator.library",@"creator.export",@"creator.finish"] containsObject:op])error=CoreError("UNSUPPORTED_CREATOR_OPERATION");
        else if(!lease||lease!=self->_creatorLease||![lease.profileID isEqualToString:owner]||
            ![lease.contentID isEqualToString:self->_content]||![lease.saveScopeSHA256 isEqualToString:expected])error=CoreError("CREATOR_LEASE_NOT_CURRENT");
        else if([self ensureOpen:&error]) {
            NSDictionary *admission=ODProjectionAdmission(self->_bridge,owner,self->_content);
            if(!admission||![expected isEqualToString:admission[@"save_scope_sha256"]])error=CoreError("CREATOR_SAVE_SCOPE_CHANGED");
            else {
                char *out=NULL,*failure=NULL;
                NSString *args=[[NSString alloc] initWithData:input encoding:NSUTF8StringEncoding];
                int rc=od_bridge_execute(self->_bridge,op.UTF8String,owner.UTF8String,intent.UTF8String,args.UTF8String,&out,&failure);
                if(rc<0)error=CoreError(failure);
                else {
                    result=out?ODProjectionJSON(out):nil;
                    if(!result)error=CoreError("INVALID_CORE_REPLY");
                }
                od_bridge_free(out);od_bridge_free(failure);
            }
        }
        dispatch_async(dispatch_get_main_queue(),^{reply(result,error);});
    });
}
- (void)acceptedCreatorDefinitionForProfile:(NSString *)profile definitionID:(NSString *)definitionID
    version:(int64_t)version expectedSaveScopeSHA256:(NSString *)scope lease:(ODNativeCreatorLease *)lease reply:(ODCoreReply)reply {
    NSString *owner=[profile copy],*definition=[definitionID copy],*expected=[scope copy];
    dispatch_async(_queue,^{
        NSError *error=nil;NSDictionary *packet=nil;
        if(![owner isKindOfClass:NSString.class]||![definition isKindOfClass:NSString.class]||
            ![expected isKindOfClass:NSString.class]||version<1||version>INT64_C(9007199254740991))error=CoreError("INVALID_ACCEPTED_DEFINITION_REQUEST");
        else if((lease&&lease!=self->_creatorLease)||(!lease&&self->_creatorLease)||
            (lease&&(![lease.profileID isEqualToString:owner]||![lease.contentID isEqualToString:self->_content]||
                ![lease.saveScopeSHA256 isEqualToString:expected])))error=CoreError("CREATOR_LEASE_NOT_CURRENT");
        else if([self ensureOpen:&error]) {
            NSDictionary *admission=ODProjectionAdmission(self->_bridge,owner,self->_content);
            if(!admission||![expected isEqualToString:admission[@"save_scope_sha256"]])error=CoreError("CREATOR_SAVE_SCOPE_CHANGED");
            else {
                NSData *args=[NSJSONSerialization dataWithJSONObject:@{@"definition_id":definition,@"version":@(version)} options:0 error:NULL];
                NSString *json=args?[[NSString alloc] initWithData:args encoding:NSUTF8StringEncoding]:nil;
                char *out=NULL,*failure=NULL;
                int rc=json?od_bridge_execute(self->_bridge,"creator.export",owner.UTF8String,NULL,json.UTF8String,&out,&failure):-1;
                size_t length=out?strnlen(out,16u*1024u*1024u+1u):0;
                if(rc<0||!length||length>16u*1024u*1024u)error=CoreError("ACCEPTED_DEFINITION_UNAVAILABLE");
                else {
                    NSData *bytes=[NSData dataWithBytes:out length:length];char hash[65];
                    if(!bytes||ODProjectionSHA256(NULL,bytes.bytes,bytes.length,hash)<0)error=CoreError("ACCEPTED_DEFINITION_UNAVAILABLE");
                    else packet=@{@"definition_bytes":bytes,@"definition_sha256":[NSString stringWithUTF8String:hash],
                        @"definition_id":definition,@"version":@(version),@"profile_id":owner,
                        @"content_id":self->_content,@"save_scope_sha256":expected};
                }
                od_bridge_free(out);od_bridge_free(failure);
            }
        }
        dispatch_async(dispatch_get_main_queue(),^{reply(packet,error);});
    });
}
- (void)acceptedCreatorFullBundleForProfile:(NSString *)profile definitionID:(NSString *)definitionID
    version:(int64_t)version instanceID:(int64_t)instanceID expectedSaveScopeSHA256:(NSString *)scope
    lease:(ODNativeCreatorLease *)lease reply:(ODCoreReply)reply {
    if(!reply)return;
    NSString *owner=[profile copy],*identifier=[definitionID copy],*expected=[scope copy];
    dispatch_async(_queue,^{
        NSError *error=nil;NSDictionary *packet=nil;
        if(![owner isEqualToString:@"local-player"]||![identifier isKindOfClass:NSString.class]||
           ![expected isKindOfClass:NSString.class]||version<1||version>INT64_C(9007199254740991)||
           instanceID<1||instanceID>INT64_C(9007199254740991))error=CoreError("INVALID_ACCEPTED_FULL_BUNDLE_REQUEST");
        else if((lease&&lease!=self->_creatorLease)||(!lease&&self->_creatorLease)||
            (lease&&(![lease.profileID isEqualToString:owner]||![lease.contentID isEqualToString:self->_content]||
                ![lease.saveScopeSHA256 isEqualToString:expected])))error=CoreError("CREATOR_LEASE_NOT_CURRENT");
        else if([self ensureOpen:&error]) {
            void *blob=NULL;size_t count=0;char *document=NULL,*receipt=NULL,*failure=NULL;
            int rc=od_bridge_creator_accepted_bundle(self->_bridge,owner.UTF8String,identifier.UTF8String,
                version,instanceID,expected.UTF8String,&blob,&count,&document,&receipt,&failure);
            size_t length=document?strnlen(document,16u*1024u*1024u+1u):0;
            if(rc<0)error=CoreError(failure);
            else if(!blob||!count||count>64u*1024u*1024u||!length||length>16u*1024u*1024u)error=CoreError("ACCEPTED_FULL_BUNDLE_UNAVAILABLE");
            else {
                NSDictionary *proof=ODProjectionJSON(receipt);char blobHash[65],definitionHash[65];
                BOOL hashes=ODProjectionSHA256(NULL,blob,count,blobHash)==0&&ODProjectionSHA256(NULL,document,length,definitionHash)==0;
                if(!proof||!hashes||![proof[@"format"] isEqual:@"od-accepted-full-bundle-receipt-v1"]||
                   ![proof[@"content_id"] isEqual:self->_content]||![proof[@"profile_id"] isEqual:owner]||
                   ![proof[@"save_scope"] isEqual:expected]||![proof[@"definition_id"] isEqual:identifier]||
                   ![proof[@"version"] isEqual:@(version)]||![proof[@"instance_id"] isEqual:@(instanceID)]||
                   ![proof[@"full_bundle_sha256"] isEqual:[NSString stringWithUTF8String:blobHash]]||
                   ![proof[@"definition_sha256"] isEqual:[NSString stringWithUTF8String:definitionHash]])error=CoreError("ACCEPTED_FULL_BUNDLE_UNCONFIRMED");
                else {
                    NSData *bytes=[NSData dataWithBytes:blob length:count],*definitionBytes=[NSData dataWithBytes:document length:length];
                    if(!bytes||!definitionBytes)error=CoreError("ACCEPTED_FULL_BUNDLE_UNAVAILABLE");
                    else packet=@{@"definition_bytes":definitionBytes,@"definition_sha256":proof[@"definition_sha256"],
                        @"definition_id":identifier,@"version":@(version),@"profile_id":owner,
                        @"content_id":self->_content,@"save_scope_sha256":expected,
                        @"full_bundle_bytes":bytes,@"full_bundle_sha256":proof[@"full_bundle_sha256"],
                        @"full_bundle_receipt":proof};
                }
            }
            od_bridge_free(blob);od_bridge_free(document);od_bridge_free(receipt);od_bridge_free(failure);
        }
        dispatch_async(dispatch_get_main_queue(),^{reply(packet,error);});
    });
}
- (void)creatorFinishReceiptForProfile:(NSString *)profile command:(NSString *)command
    expectedDefinitionBytes:(NSData *)definition expectedSaveScopeSHA256:(NSString *)scope
    lease:(ODNativeCreatorLease *)lease reply:(ODCoreReply)reply {
    NSString *owner=[profile copy],*intent=[command copy],*expected=[scope copy];NSData *bytes=[definition copy];
    dispatch_async(_queue,^{
        NSError *error=nil;NSDictionary *receipt=nil;
        NSString *document=[bytes isKindOfClass:NSData.class]&&bytes.length&&bytes.length<=16u*1024u*1024u&&
            !memchr(bytes.bytes,0,bytes.length)?[[NSString alloc] initWithData:bytes encoding:NSUTF8StringEncoding]:nil;
        if(![owner isKindOfClass:NSString.class]||![intent isKindOfClass:NSString.class]||
            ![expected isKindOfClass:NSString.class]||!document)error=CoreError("INVALID_CREATOR_RECEIPT_REQUEST");
        else if((lease&&lease!=self->_creatorLease)||(!lease&&self->_creatorLease)||
            (lease&&(![lease.profileID isEqualToString:owner]||![lease.contentID isEqualToString:self->_content]||
                ![lease.saveScopeSHA256 isEqualToString:expected])))error=CoreError("CREATOR_LEASE_NOT_CURRENT");
        else if([self ensureOpen:&error]) {
            NSDictionary *admission=ODProjectionAdmission(self->_bridge,owner,self->_content);
            if(!admission||![expected isEqualToString:admission[@"save_scope_sha256"]])error=CoreError("CREATOR_SAVE_SCOPE_CHANGED");
            else {
                char *out=NULL,*failure=NULL;
                int rc=od_bridge_creator_finish_receipt(self->_bridge,owner.UTF8String,intent.UTF8String,document.UTF8String,&out,&failure);
                if(rc<0)error=CoreError(failure);
                else {receipt=ODProjectionJSON(out);if(!receipt)error=CoreError("CREATOR_FINISH_RECEIPT_UNAVAILABLE");}
                od_bridge_free(out);od_bridge_free(failure);
            }
        }
        dispatch_async(dispatch_get_main_queue(),^{reply(receipt,error);});
    });
}
- (void)creatorFinishValidatedBundleForProfile:(NSString *)profile command:(NSString *)command
    definition:(NSDictionary *)definition bundleBytes:(NSData *)bundle
    expectedSaveScopeSHA256:(NSString *)scope lease:(ODNativeCreatorLease *)lease reply:(ODCoreReply)reply {
    NSString *owner=[profile copy],*intent=[command copy],*expected=[scope copy];
    NSData *packet=[bundle copy];
    NSError *encodingError=nil;
    NSData *document=[definition isKindOfClass:NSDictionary.class]&&[NSJSONSerialization isValidJSONObject:definition]?
        [NSJSONSerialization dataWithJSONObject:definition options:NSJSONWritingSortedKeys error:&encodingError]:nil;
    NSString *definitionJSON=document.length&&document.length<=16u*1024u*1024u&&!memchr(document.bytes,0,document.length)?
        [[NSString alloc] initWithData:document encoding:NSUTF8StringEncoding]:nil;
    if(!definitionJSON||![packet isKindOfClass:NSData.class]||!packet.length||packet.length>64u*1024u*1024u||memchr(packet.bytes,0,packet.length)){
        dispatch_async(dispatch_get_main_queue(),^{reply(nil,CoreError("INVALID_ARGUMENT"));});return;
    }
    dispatch_async(_queue,^{
        NSError *error=nil;id result=nil;
        if(![owner isEqualToString:@"local-player"]||![intent isKindOfClass:NSString.class]||![expected isKindOfClass:NSString.class])error=CoreError("INVALID_ARGUMENT");
        else if((lease&&lease!=self->_creatorLease)||(!lease&&self->_creatorLease)||
            (lease&&(![lease.profileID isEqualToString:owner]||![lease.contentID isEqualToString:self->_content]||
                ![lease.saveScopeSHA256 isEqualToString:expected])))error=CoreError("CREATOR_LEASE_NOT_CURRENT");
        else if([self ensureOpen:&error]) {
            NSDictionary *admission=ODProjectionAdmission(self->_bridge,owner,self->_content);
            if(!admission||![expected isEqualToString:admission[@"save_scope_sha256"]])error=CoreError("CREATOR_SAVE_SCOPE_CHANGED");
            else {
                char *out=NULL,*failure=NULL;
                int rc=od_bridge_creator_finish_bundle(self->_bridge,owner.UTF8String,intent.UTF8String,definitionJSON.UTF8String,packet.bytes,packet.length,&out,&failure);
                if(rc<0)error=CoreError(failure);
                else {result=ODProjectionJSON(out);if(!result)error=CoreError("INVALID_CORE_REPLY");}
                od_bridge_free(out);od_bridge_free(failure);
            }
        }
        dispatch_async(dispatch_get_main_queue(),^{reply(result,error);});
    });
}
- (void)synchronizeOriginalCreatorProjectionForProfile:(NSString *)profile overlayURL:(NSURL *)overlayURL reply:(ODCoreReply)reply {
    NSString *owner=[profile copy]; NSURL *overlay=[overlayURL copy];
    dispatch_async(_queue,^{
        NSError *error=nil; NSDictionary *receipt=nil;
        if(![owner isKindOfClass:NSString.class]||!owner.length||
           !ODProjectionOverlayPath(overlay,self->_save,self->_master))error=CoreError("INVALID_PROJECTION_HOST_CONFIGURATION");
        else if([self ensureOpen:&error]) {
            char *snapshotJSON=NULL,*failure=NULL;
            int rc=od_bridge_projection_snapshot(self->_bridge,owner.UTF8String,&snapshotJSON,&failure);
            NSDictionary *snapshot=rc>=0?ODProjectionJSON(snapshotJSON):nil;
            NSDictionary *state=[snapshot[@"state"] isKindOfClass:NSDictionary.class]?snapshot[@"state"]:nil;
            NSString *scope=state?ODProjectionScope(state,self->_content,owner):nil;
            od_bridge_free(snapshotJSON);od_bridge_free(failure);
            if(!scope)error=CoreError("CREATOR_PROJECTION_SNAPSHOT_MISMATCH");
            else {
                ODProjectionContext context={self->_bridge,owner.UTF8String};
                odov_projection_host host={&context,ODProjectionSnapshot,ODProjectionDefinition,
                    ODProjectionAcknowledge,ODProjectionRelease,ODProjectionSHA256};
                char *ackJSON=NULL;
                rc=odov_reconcile(overlay.fileSystemRepresentation,self->_master.fileSystemRepresentation,
                    self->_content.UTF8String,scope.UTF8String,&host,&ackJSON);
                NSDictionary *ack=rc>=0?ODProjectionJSON(ackJSON):nil; odov_free(ackJSON);
                if(rc<0)error=CoreError(rc==ODOV_UNSUPPORTED?"CREATOR_PROJECTION_UNSUPPORTED":
                    rc==ODOV_REVISION?"CREATOR_PROJECTION_STALE":rc==ODOV_IDENTITY?"CREATOR_PROJECTION_IDENTITY_MISMATCH":"CREATOR_PROJECTION_SYNC_FAILED");
                else if(!ack||!ODProjectionGeneration(ack[@"generation"])||!ODProjectionGeneration(ack[@"applied_generation"])||
                    ![ack[@"generation"] isEqual:ack[@"applied_generation"]]||
                    ![scope isEqualToString:ODProjectionScope(ack,self->_content,owner)]||
                    ![ack[@"save_identity"] isEqual:state[@"save_identity"]])error=CoreError("CREATOR_PROJECTION_ACK_MISMATCH");
                else receipt=@{@"content_id":self->_content,@"save_scope_sha256":scope,
                    @"projection_generation":ack[@"generation"],@"applied_generation":ack[@"applied_generation"],@"clean":@YES};
            }
        }
        dispatch_async(dispatch_get_main_queue(),^{reply(receipt,error);});
    });
}
- (BOOL)ensureOpen:(NSError **)error {
    if (_closed) { if (error) *error = CoreError("CLOSED"); return NO; }
    if (_bridge) return YES;
    if (!_save.isFileURL || !_master.isFileURL || [_content length] == 0) {
        if (error) *error = CoreError("INVALID_HOST_CONFIGURATION"); return NO;
    }
    char *failure = NULL;
    int rc = od_bridge_open(_save.fileSystemRepresentation, _master.fileSystemRepresentation, _content.UTF8String, &_bridge, &failure);
    if (rc < 0 && error) *error = CoreError(failure);
    od_bridge_free(failure);
    return rc >= 0;
}
- (void)execute:(NSString *)operation profile:(NSString *)profile command:(NSString *)command
      arguments:(NSDictionary *)arguments reply:(ODCoreReply)reply {
    [self executeInternal:operation profile:profile command:command arguments:arguments policy:NO reply:reply];
}
- (void)executePolicy:(NSString *)operation profile:(NSString *)profile command:(NSString *)command
      fixedHostArguments:(NSDictionary *)arguments reply:(ODCoreReply)reply {
    [self executeInternal:operation profile:profile command:command arguments:arguments policy:YES reply:reply];
}
- (void)executeInternal:(NSString *)operation profile:(NSString *)profile command:(NSString *)command
      arguments:(NSDictionary *)arguments policy:(BOOL)policy reply:(ODCoreReply)reply {
    // Copy caller-owned mutable JSON before scheduling; do not race mutations in another view.
    NSError *encodingError = nil;
    NSData *input = [arguments isKindOfClass:NSDictionary.class] && [NSJSONSerialization isValidJSONObject:arguments] ? [NSJSONSerialization dataWithJSONObject:arguments options:0 error:&encodingError] : nil;
    if (!input) { dispatch_async(dispatch_get_main_queue(), ^{ reply(nil, CoreError("INVALID_ARGUMENT")); }); return; }
    NSString *op = [operation copy], *owner = [profile copy], *intent = [command copy];
    dispatch_async(_queue, ^{
        NSError *error = nil; id result = nil;
        if (self->_creatorLease&&[op hasPrefix:@"creator."]) error=CoreError("CREATOR_EDIT_LEASE_HELD");
        else if ([self ensureOpen:&error]) {
            NSString *args = [[NSString alloc] initWithData:input encoding:NSUTF8StringEncoding];
            char *out = NULL, *failure = NULL;
            int rc = policy ? od_bridge_execute_policy(self->_bridge, op.UTF8String, owner.UTF8String, intent.UTF8String, args.UTF8String, &out, &failure) :
                              od_bridge_execute(self->_bridge, op.UTF8String, owner.UTF8String, intent.UTF8String, args.UTF8String, &out, &failure);
            if (rc < 0) error = CoreError(failure);
            else if (out) {
                NSData *data = [[NSString stringWithUTF8String:out] dataUsingEncoding:NSUTF8StringEncoding];
                result = data ? [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingFragmentsAllowed error:&error] : nil;
                if (!result && !error) error = CoreError("INVALID_CORE_REPLY");
            }
            od_bridge_free(out); od_bridge_free(failure);
        }
        dispatch_async(dispatch_get_main_queue(), ^{ reply(result, error); });
    });
}
- (void)saveOperation:(NSURL *)url importing:(BOOL)importing reply:(ODCoreReply)reply {
    NSURL *approved = [url copy];
    dispatch_async(_queue, ^{
        NSError *error = nil; BOOL ok = NO;
        if (importing&&self->_creatorLease) error=CoreError("CREATOR_EDIT_LEASE_HELD");
        else if (!approved.isFileURL) error = CoreError("INVALID_HOST_CONFIGURATION");
        else if ([self ensureOpen:&error]) {
            char *failure = NULL;
            int rc = importing ? od_bridge_import(self->_bridge, approved.fileSystemRepresentation, &failure) :
                                 od_bridge_export(self->_bridge, approved.fileSystemRepresentation, &failure);
            ok = rc >= 0; if (!ok) error = CoreError(failure); od_bridge_free(failure);
        }
        dispatch_async(dispatch_get_main_queue(), ^{ reply(ok ? @{ @"ok": @YES } : nil, error); });
    });
}
- (void)exportToURL:(NSURL *)url reply:(ODCoreReply)reply { [self saveOperation:url importing:NO reply:reply]; }
- (void)importFromURL:(NSURL *)url reply:(ODCoreReply)reply { [self saveOperation:url importing:YES reply:reply]; }
- (void)close {
    dispatch_async(_queue, ^{ self->_closed = YES; od_bridge_close(self->_bridge); self->_bridge = NULL; });
}
- (void)dealloc {
    // Queued blocks retain the host until completed, so no operation races this final close.
    od_bridge_close(_bridge);
}
@end
