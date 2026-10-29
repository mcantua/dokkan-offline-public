#import "ODAcceptedCreatorResources.h"
#import <CoreFoundation/CoreFoundation.h>
#include "../../content/content.h"
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <math.h>
#include <string.h>

static NSError *ODACError(NSString *code) {
    return [NSError errorWithDomain:@"OfflineDokkan.AcceptedCreatorResources" code:1
                          userInfo:@{NSLocalizedDescriptionKey:code}];
}
static BOOL ODACHex(id value) {
    return [value isKindOfClass:NSString.class]&&[value length]==64&&
        [value rangeOfCharacterFromSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdef"] invertedSet]].location==NSNotFound;
}
static BOOL ODACInteger(id value,long long minimum,long long maximum) {
    return [value isKindOfClass:NSNumber.class]&&CFGetTypeID((__bridge CFTypeRef)value)!=CFBooleanGetTypeID()&&
        isfinite([value doubleValue])&&[value doubleValue]==[value longLongValue]&&
        [value longLongValue]>=minimum&&[value longLongValue]<=maximum;
}
static BOOL ODACName(id value) {
    return [value isKindOfClass:NSString.class]&&[value length]>0&&[value length]<=127&&
        [value rangeOfCharacterFromSet:[[NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.:"] invertedSet]].location==NSNotFound;
}
static BOOL ODACPath(id value) {
    if(![value isKindOfClass:NSString.class]||![value length]||[value length]>500||[value hasPrefix:@"/"]||
       [value rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\\:\000\r\n"]].location!=NSNotFound)return NO;
    for(NSString *part in [value componentsSeparatedByString:@"/"])
        if(!part.length||[part isEqual:@"."]||[part isEqual:@".."])return NO;
    return YES;
}
static BOOL ODACFields(id value,NSArray<NSString *> *fields) {
    return [value isKindOfClass:NSDictionary.class]&&
        [[NSSet setWithArray:[value allKeys]] isEqual:[NSSet setWithArray:fields]];
}
static BOOL ODACCurrent(ODAcceptedCreatorResourceContextCurrent current) {
    if(!NSThread.isMainThread||!current)return NO;
    @try { return current(); } @catch(NSException *exception) { (void)exception;return NO; }
}
static BOOL ODACSameDirectory(struct stat first,struct stat second) {
    return S_ISDIR(first.st_mode)&&S_ISDIR(second.st_mode)&&first.st_dev==second.st_dev&&first.st_ino==second.st_ino&&
        first.st_uid==geteuid()&&second.st_uid==geteuid()&&!(first.st_mode&0022)&&!(second.st_mode&0022);
}
static BOOL ODACSameFile(struct stat first,struct stat second) {
    return S_ISREG(first.st_mode)&&S_ISREG(second.st_mode)&&first.st_dev==second.st_dev&&first.st_ino==second.st_ino&&
        first.st_size==second.st_size&&first.st_mtimespec.tv_sec==second.st_mtimespec.tv_sec&&
        first.st_mtimespec.tv_nsec==second.st_mtimespec.tv_nsec&&first.st_ctimespec.tv_sec==second.st_ctimespec.tv_sec&&
        first.st_ctimespec.tv_nsec==second.st_ctimespec.tv_nsec&&first.st_uid==second.st_uid&&first.st_mode==second.st_mode;
}
static int ODACOpenDirectory(NSURL *url) {
    if(!url.isFileURL||!url.path.isAbsolutePath||url.query||url.fragment)return -1;
    int descriptor=open("/",O_RDONLY|O_DIRECTORY|O_CLOEXEC);
    if(descriptor<0)return -1;
    for(NSString *part in url.path.pathComponents) {
        if([part isEqual:@"/"])continue;
        if(!part.length||[part isEqual:@"."]||[part isEqual:@".."]) { close(descriptor);return -1; }
        int next=openat(descriptor,part.fileSystemRepresentation,O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);
        close(descriptor);if(next<0)return -1;descriptor=next;
    }
    return descriptor;
}

@interface ODAcceptedCreatorResources ()
- (instancetype)initNative;
- (nullable NSDictionary *)descriptor:(NSDictionary *)row;
- (BOOL)preparePacket:(NSDictionary *)packet error:(NSError **)error;
- (BOOL)readOwner:(BOOL)pin;
- (BOOL)directoriesCurrent;
- (void)openDescriptor:(nullable NSDictionary *)entry completion:(ODAcceptedCreatorResourceOpenReply)completion;
@end
@implementation ODAcceptedCreatorResources {
    dispatch_queue_t _io;
    ODAcceptedCreatorResourceContextCurrent _current;
    NSURL *_workspaceURL;
    NSString *_content,*_scope,*_fullSHA,*_projectSHA;
    NSDictionary<NSString *,NSDictionary *> *_resources;
    NSDictionary<NSString *,NSDictionary<NSString *,NSDictionary *> *> *_cpkInputs;
    int _workspaceFD,_capturesFD;
    struct stat _workspaceIdentity,_capturesIdentity,_ownerIdentity;
    NSData *_ownerBytes;
    BOOL _invalidated;
    NSUInteger _authorizationGeneration;
}
- (instancetype)initNative {
    if((self=[super init])) {
        _workspaceFD=-1;_capturesFD=-1;_authorizationGeneration=1;
        _io=dispatch_queue_create("personal.offlinedokkan.accepted-resource-reader",DISPATCH_QUEUE_SERIAL);
    }
    return self;
}
- (void)dealloc {
    if(_workspaceFD>=0)close(_workspaceFD);
    if(_capturesFD>=0)close(_capturesFD);
}
+ (void)prepareAcceptedPacket:(NSDictionary *)packet workspaceURL:(NSURL *)workspace
             contextIsCurrent:(ODAcceptedCreatorResourceContextCurrent)current
                   completion:(void (^)(ODAcceptedCreatorResources *,NSError *))completion {
    if(!completion)return;
    if(!NSThread.isMainThread) {
        dispatch_async(dispatch_get_main_queue(),^{[self prepareAcceptedPacket:packet workspaceURL:workspace contextIsCurrent:current completion:completion];});return;
    }
    if(![packet isKindOfClass:NSDictionary.class]||packet.count!=6||![workspace isKindOfClass:NSURL.class]||!workspace.isFileURL||!workspace.path.isAbsolutePath||workspace.query||workspace.fragment||!ODACCurrent(current)) {
        completion(nil,ODACError(@"ACCEPTED_RESOURCE_CONTEXT_UNAVAILABLE"));return;
    }
    // Core/Session returns immutable NSData. The small metadata dictionaries
    // are snapshotted now; byte copying/parsing/hashing stays off the main queue.
    NSMutableDictionary *snapshot=[packet mutableCopy];
    for(NSString *field in @[@"binding",@"full_bundle_receipt"]) {
        NSDictionary *metadata=snapshot[field];
        if(![metadata isKindOfClass:NSDictionary.class]||metadata.count>13){completion(nil,ODACError(@"ACCEPTED_RESOURCE_PACKET_UNCONFIRMED"));return;}
        NSMutableDictionary *frozen=[NSMutableDictionary dictionary];
        for(id key in metadata) {
            id value=metadata[key];
            if(![key isKindOfClass:NSString.class]||[key length]>64||
               (![value isKindOfClass:NSString.class]&&![value isKindOfClass:NSNumber.class])||
               ([value isKindOfClass:NSString.class]&&[value length]>256)){completion(nil,ODACError(@"ACCEPTED_RESOURCE_PACKET_UNCONFIRMED"));return;}
            frozen[[key copy]]=[value copy];
        }
        snapshot[field]=[frozen copy];
    }
    if(!ODACHex(snapshot[@"full_bundle_sha256"])){completion(nil,ODACError(@"ACCEPTED_RESOURCE_PACKET_UNCONFIRMED"));return;}
    snapshot[@"full_bundle_sha256"]=[snapshot[@"full_bundle_sha256"] copy];
    NSDictionary *input=[snapshot copy];
    ODAcceptedCreatorResources *reader=[[self alloc] initNative];
    reader->_current=[current copy];reader->_workspaceURL=[workspace copy];
    dispatch_async(reader->_io,^{
        NSError *failure=nil;BOOL ready=[reader preparePacket:input error:&failure];
        dispatch_async(dispatch_get_main_queue(),^{
            BOOL deliver=ready;NSError *deliveredFailure=failure;
            if(!ODACCurrent(reader->_current)) { deliver=NO;deliveredFailure=ODACError(@"ACCEPTED_RESOURCE_SCOPE_CHANGED"); }
            completion(deliver?reader:nil,deliveredFailure);
        });
    });
}
- (NSDictionary *)descriptor:(NSDictionary *)row {
    if(!ODACPath(row[@"path"])||!ODACHex(row[@"sha256"])||!ODACInteger(row[@"size"],1,96LL*1024*1024))return nil;
    return @{@"path":[row[@"path"] copy],@"sha256":[row[@"sha256"] copy],@"size":@([row[@"size"] longLongValue])};
}
- (BOOL)preparePacket:(NSDictionary *)packet error:(NSError **)error {
    NSData *projectBytes=[packet[@"project_bytes"] isKindOfClass:NSData.class]?[packet[@"project_bytes"] copy]:nil;
    NSData *definitionBytes=[packet[@"definition_bytes"] isKindOfClass:NSData.class]?[packet[@"definition_bytes"] copy]:nil;
    NSData *bundleBytes=[packet[@"full_bundle_bytes"] isKindOfClass:NSData.class]?[packet[@"full_bundle_bytes"] copy]:nil;
    NSDictionary *binding=packet[@"binding"],*receipt=packet[@"full_bundle_receipt"];
    NSString *bundleHash=packet[@"full_bundle_sha256"];
    BOOL valid=ODACFields(packet,@[@"binding",@"project_bytes",@"definition_bytes",@"full_bundle_bytes",@"full_bundle_sha256",@"full_bundle_receipt"])&&
        ODACFields(binding,@[@"format",@"content_id",@"save_scope",@"definition_id",@"version",@"project_sha256",@"definition_sha256",@"instance_id",@"accepted"])&&
        ODACFields(receipt,@[@"format",@"content_id",@"save_scope",@"profile_id",@"definition_id",@"version",@"instance_id",@"profile_revision",@"projection_generation",@"full_bundle_sha256",@"project_sha256",@"definition_sha256",@"member_count"])&&
        projectBytes.length&&projectBytes.length<=20u*1024u*1024u&&definitionBytes.length&&definitionBytes.length<=16u*1024u*1024u&&bundleBytes.length&&bundleBytes.length<=64u*1024u*1024u&&
        [binding[@"format"] isEqual:@"od-accepted-creator-project-v1"]&&
        [binding[@"accepted"] isKindOfClass:NSNumber.class]&&CFGetTypeID((__bridge CFTypeRef)binding[@"accepted"])==CFBooleanGetTypeID()&&[binding[@"accepted"] boolValue]&&
        ODACName(binding[@"content_id"])&&ODACHex(binding[@"save_scope"])&&ODACName(binding[@"definition_id"])&&
        ODACInteger(binding[@"version"],1,9007199254740991LL)&&ODACInteger(binding[@"instance_id"],1,9007199254740991LL)&&
        ODACHex(binding[@"project_sha256"])&&ODACHex(binding[@"definition_sha256"])&&ODACHex(bundleHash)&&
        [receipt[@"format"] isEqual:@"od-accepted-full-bundle-receipt-v1"]&&[receipt[@"profile_id"] isEqual:@"local-player"]&&
        ODACInteger(receipt[@"version"],1,9007199254740991LL)&&ODACInteger(receipt[@"instance_id"],1,9007199254740991LL)&&
        ODACInteger(receipt[@"profile_revision"],0,9007199254740991LL)&&ODACInteger(receipt[@"projection_generation"],1,9007199254740991LL)&&ODACInteger(receipt[@"member_count"],1,5);
    if(valid)for(NSString *field in @[@"content_id",@"save_scope",@"definition_id",@"version",@"instance_id",@"project_sha256",@"definition_sha256"])
        valid=valid&&[receipt[field] isEqual:binding[field]];
    valid=valid&&[receipt[@"full_bundle_sha256"] isEqual:bundleHash];
    if(valid)valid=od_content_verify_bytes(projectBytes.bytes,(int64_t)projectBytes.length,[binding[@"project_sha256"] UTF8String])==0&&
        od_content_verify_bytes(definitionBytes.bytes,(int64_t)definitionBytes.length,[binding[@"definition_sha256"] UTF8String])==0&&
        od_content_verify_bytes(bundleBytes.bytes,(int64_t)bundleBytes.length,bundleHash.UTF8String)==0;
    NSDictionary *project=valid?[NSJSONSerialization JSONObjectWithData:projectBytes options:0 error:nil]:nil;
    NSDictionary *definition=valid?[NSJSONSerialization JSONObjectWithData:definitionBytes options:0 error:nil]:nil;
    NSDictionary *bundle=valid?[NSJSONSerialization JSONObjectWithData:bundleBytes options:0 error:nil]:nil;
    NSDictionary *descriptor=[definition isKindOfClass:NSDictionary.class]?definition[@"full_bundle"]:nil;
    valid=valid&&[project isKindOfClass:NSDictionary.class]&&[definition isKindOfClass:NSDictionary.class]&&
        ODACFields(bundle,@[@"format",@"content_id",@"profile_id",@"save_scope",@"definition_id",@"version",@"project_sha256",@"source_sha256",@"member_count",@"materialization_utc",@"resources",@"engine_admission",@"tables",@"members",@"transform_links",@"source_dependencies",@"shared_actions"])&&
        [project[@"format"] isEqual:@"dokkan-unit-forge"]&&ODACInteger(project[@"version"],1,1)&&
        [definition[@"format"] isEqual:@"offline-dokkan-definition"]&&ODACInteger(definition[@"schema_version"],1,1)&&
        ODACInteger(definition[@"version"],1,9007199254740991LL)&&[definition[@"definition_id"] isEqual:binding[@"definition_id"]]&&[definition[@"version"] isEqual:binding[@"version"]]&&
        [definition[@"fully_awakened"] isKindOfClass:NSNumber.class]&&CFGetTypeID((__bridge CFTypeRef)definition[@"fully_awakened"])==CFBooleanGetTypeID()&&[definition[@"fully_awakened"] boolValue]&&
        [project[@"source"] isKindOfClass:NSDictionary.class]&&[definition[@"source"] isKindOfClass:NSDictionary.class]&&
        [project[@"source"][@"contentId"] isEqual:binding[@"content_id"]]&&[definition[@"source"][@"content_id"] isEqual:binding[@"content_id"]]&&
        ODACInteger(project[@"source"][@"cardId"],1,9007199254740991LL)&&ODACInteger(definition[@"source"][@"master_id"],1,9007199254740991LL)&&[definition[@"source"][@"master_id"] isEqual:project[@"source"][@"cardId"]]&&
        ODACFields(descriptor,@[@"format",@"projection",@"content_id",@"profile_id",@"save_scope",@"definition_id",@"version",@"project_sha256",@"full_bundle_sha256",@"member_count"])&&
        [descriptor[@"format"] isEqual:@"od-full-creator-binding-v2"]&&[descriptor[@"projection"] isEqual:@"progression-root-v1"]&&[descriptor[@"profile_id"] isEqual:@"local-player"]&&
        ODACInteger(descriptor[@"version"],1,9007199254740991LL)&&ODACInteger(descriptor[@"member_count"],1,5)&&
        [bundle[@"format"] isEqual:@"od-native-creator-full-bundle-v2"]&&[bundle[@"engine_admission"] isEqual:@"pending-master-cipher-resource-and-form-progression-binding"]&&!bundle[@"original_client_attached"]&&
        [bundle[@"profile_id"] isEqual:@"local-player"]&&ODACInteger(bundle[@"version"],1,9007199254740991LL)&&ODACInteger(bundle[@"member_count"],1,5)&&
        ODACInteger(bundle[@"materialization_utc"],0,253402300799000LL)&&[bundle[@"members"] isKindOfClass:NSArray.class]&&
        [bundle[@"members"] count]==[receipt[@"member_count"] unsignedIntegerValue]&&[bundle[@"resources"] isKindOfClass:NSArray.class]&&
        [bundle[@"tables"] isKindOfClass:NSDictionary.class]&&[bundle[@"transform_links"] isKindOfClass:NSArray.class]&&
        [bundle[@"source_dependencies"] isKindOfClass:NSArray.class]&&[bundle[@"shared_actions"] isKindOfClass:NSArray.class];
    if(valid)for(NSString *field in @[@"content_id",@"save_scope",@"definition_id",@"version",@"project_sha256"])
        valid=valid&&[descriptor[field] isEqual:binding[field]]&&[bundle[field] isEqual:binding[field]];
    NSString *source=valid&&[binding[@"content_id"] isKindOfClass:NSString.class]?binding[@"content_id"]:nil;
    if([source hasPrefix:@"sparking:"])source=[source substringFromIndex:9];
    else if([source hasPrefix:@"eclipse:"])source=[source substringFromIndex:8];
    valid=valid&&[source hasPrefix:@"sha256:"]&&source.length==71&&ODACHex([source substringFromIndex:7])&&
        [bundle[@"source_sha256"] isEqual:[source substringFromIndex:7]]&&[descriptor[@"full_bundle_sha256"] isEqual:bundleHash]&&
        [descriptor[@"member_count"] isEqual:receipt[@"member_count"]]&&[bundle[@"member_count"] isEqual:receipt[@"member_count"]];
    if(!valid){if(error)*error=ODACError(@"ACCEPTED_RESOURCE_PACKET_UNCONFIRMED");return NO;}
    NSMutableDictionary *resources=[NSMutableDictionary dictionary],*containers=[NSMutableDictionary dictionary],*hashSizes=[NSMutableDictionary dictionary];
    NSMutableSet *paths=[NSMutableSet set];NSUInteger count=0;
    for(id object in bundle[@"resources"]) {
        NSDictionary *row=[object isKindOfClass:NSDictionary.class]?object:nil;NSString *path=row[@"path"],*kind=row[@"kind"];
        NSString *normalized=ODACPath(path)?path.precomposedStringWithCanonicalMapping.lowercaseString:nil;
        if(!normalized||![kind isKindOfClass:NSString.class]||[paths containsObject:normalized]||++count>50000){if(error)*error=ODACError(@"ACCEPTED_RESOURCE_INDEX_INVALID");return NO;}
        [paths addObject:normalized];
        if([@[@"captured-asset",@"captured-generated-text",@"captured-shared-action-installation-pending"] containsObject:kind]) {
            NSDictionary *entry=ODACFields(row,@[@"path",@"kind",@"sha256",@"size"])?[self descriptor:row]:nil;
            if(!entry||(hashSizes[entry[@"sha256"]]&&![hashSizes[entry[@"sha256"]] isEqual:entry[@"size"]])){if(error)*error=ODACError(@"ACCEPTED_RESOURCE_INDEX_INVALID");return NO;}
            resources[path]=entry;hashSizes[entry[@"sha256"]]=entry[@"size"];
        } else if([kind isEqual:@"captured-cpk-inputs-build-pending"]) {
            NSArray *inputs=row[@"entries"];NSMutableDictionary *entries=[NSMutableDictionary dictionary];NSMutableSet *inputPaths=[NSMutableSet set];
            if(!ODACFields(row,@[@"path",@"kind",@"entries"])||![inputs isKindOfClass:NSArray.class]||!inputs.count){if(error)*error=ODACError(@"ACCEPTED_RESOURCE_CPK_INDEX_INVALID");return NO;}
            for(id input in inputs) {
                NSDictionary *entry=ODACFields(input,@[@"path",@"sha256",@"size"])?[self descriptor:input]:nil;
                NSString *key=entry?[entry[@"path"] precomposedStringWithCanonicalMapping].lowercaseString:nil;
                if(!entry||[inputPaths containsObject:key]||++count>50000||(hashSizes[entry[@"sha256"]]&&![hashSizes[entry[@"sha256"]] isEqual:entry[@"size"]])){if(error)*error=ODACError(@"ACCEPTED_RESOURCE_CPK_INDEX_INVALID");return NO;}
                [inputPaths addObject:key];entries[entry[@"path"]]=entry;hashSizes[entry[@"sha256"]]=entry[@"size"];
            }
            containers[path]=[entries copy];
        } else { if(error)*error=ODACError(@"ACCEPTED_RESOURCE_KIND_UNSUPPORTED");return NO; }
    }
    _content=[binding[@"content_id"] copy];_scope=[binding[@"save_scope"] copy];_fullSHA=[bundleHash copy];_projectSHA=[binding[@"project_sha256"] copy];
    _resources=[resources copy];_cpkInputs=[containers copy];
    // Resolve the trusted native URL off main (including platform aliases such
    // as /var), then traverse every canonical component with NOFOLLOW.
    _workspaceURL=_workspaceURL.URLByStandardizingPath.URLByResolvingSymlinksInPath;
    _workspaceFD=ODACOpenDirectory(_workspaceURL);
    if(_workspaceFD<0||fstat(_workspaceFD,&_workspaceIdentity)||!ODACSameDirectory(_workspaceIdentity,_workspaceIdentity)){if(error)*error=ODACError(@"ACCEPTED_RESOURCE_WORKSPACE_UNAVAILABLE");return NO;}
    _capturesFD=openat(_workspaceFD,"full-bundle-captures",O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);
    if(_capturesFD<0||fstat(_capturesFD,&_capturesIdentity)||!ODACSameDirectory(_capturesIdentity,_capturesIdentity)){if(error)*error=ODACError(@"ACCEPTED_RESOURCE_CAPTURE_ROOT_UNAVAILABLE");return NO;}
    if(![self readOwner:YES]){if(error)*error=ODACError(@"ACCEPTED_RESOURCE_WORKSPACE_SCOPE_MISMATCH");return NO;}
    return YES;
}
- (BOOL)readOwner:(BOOL)pin {
    int descriptor=openat(_workspaceFD,".original-creator-binding.json",O_RDONLY|O_NOFOLLOW|O_CLOEXEC|O_NONBLOCK);
    struct stat before,after;BOOL good=descriptor>=0&&fstat(descriptor,&before)==0&&S_ISREG(before.st_mode)&&before.st_uid==geteuid()&&before.st_nlink==1&&before.st_size>0&&before.st_size<=4096;
    NSMutableData *data=good?[NSMutableData dataWithLength:(NSUInteger)before.st_size]:nil;
    if(good)good=pread(descriptor,data.mutableBytes,data.length,0)==before.st_size&&fstat(descriptor,&after)==0&&ODACSameFile(before,after);
    if(descriptor>=0)close(descriptor);
    if(!good)return NO;
    if(!pin)return ODACSameFile(_ownerIdentity,before)&&[_ownerBytes isEqualToData:data];
    NSDictionary *owner=[NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if(!ODACFields(owner,@[@"format",@"content_id",@"save_scope_sha256",@"native_context_sha256"])||![owner[@"format"] isEqual:@"original-creator-binding-v1"]||
       ![owner[@"content_id"] isEqual:_content]||![owner[@"save_scope_sha256"] isEqual:_scope]||!ODACHex(owner[@"native_context_sha256"]))return NO;
    _ownerIdentity=before;_ownerBytes=[data copy];return YES;
}
- (BOOL)directoriesCurrent {
    int workspace=ODACOpenDirectory(_workspaceURL);struct stat current,held;BOOL good=workspace>=0&&fstat(workspace,&current)==0&&fstat(_workspaceFD,&held)==0&&ODACSameDirectory(_workspaceIdentity,current)&&ODACSameDirectory(_workspaceIdentity,held);
    int captures=good?openat(workspace,"full-bundle-captures",O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC):-1;
    good=good&&captures>=0&&fstat(captures,&current)==0&&fstat(_capturesFD,&held)==0&&ODACSameDirectory(_capturesIdentity,current)&&ODACSameDirectory(_capturesIdentity,held)&&[self readOwner:NO];
    if(workspace>=0)close(workspace);if(captures>=0)close(captures);return good;
}
- (void)openDescriptor:(NSDictionary *)entry completion:(ODAcceptedCreatorResourceOpenReply)completion {
    if(_invalidated||!ODACCurrent(_current)){completion(-1,ODACError(@"ACCEPTED_RESOURCE_SCOPE_CHANGED"));return;}
    if(!entry){completion(-1,ODACError(@"ACCEPTED_RESOURCE_NOT_DECLARED"));return;}
    NSUInteger generation=_authorizationGeneration;
    dispatch_async(_io,^{
        int descriptor=-1;NSError *failure=nil;struct stat before,after,path;
        if([self directoriesCurrent])descriptor=openat(self->_capturesFD,[entry[@"sha256"] UTF8String],O_RDONLY|O_NOFOLLOW|O_CLOEXEC|O_NONBLOCK);
        BOOL good=descriptor>=0&&fstat(descriptor,&before)==0&&S_ISREG(before.st_mode)&&before.st_uid==geteuid()&&before.st_nlink==1&&!(before.st_mode&0222)&&before.st_size==[entry[@"size"] longLongValue]&&
            od_content_verify_readonly_fd(descriptor,[entry[@"size"] longLongValue],[entry[@"sha256"] UTF8String])==0&&
            fstat(descriptor,&after)==0&&ODACSameFile(before,after)&&!(after.st_mode&0222)&&after.st_nlink==1&&
            fstatat(self->_capturesFD,[entry[@"sha256"] UTF8String],&path,AT_SYMLINK_NOFOLLOW)==0&&ODACSameFile(after,path)&&[self directoriesCurrent];
        if(!good){if(descriptor>=0)close(descriptor);descriptor=-1;failure=ODACError(@"ACCEPTED_RESOURCE_BYTES_UNAVAILABLE_OR_CHANGED");}
        dispatch_async(dispatch_get_main_queue(),^{
            int admitted=descriptor;NSError *delivered=failure;
            if(self->_invalidated||generation!=self->_authorizationGeneration||!ODACCurrent(self->_current)){
                if(admitted>=0)close(admitted);admitted=-1;delivered=ODACError(@"ACCEPTED_RESOURCE_SCOPE_CHANGED");
            }
            completion(admitted,delivered);
        });
    });
}
- (void)openDeclaredResource:(NSString *)path completion:(ODAcceptedCreatorResourceOpenReply)completion {
    if(!completion)return;
    if(!NSThread.isMainThread){dispatch_async(dispatch_get_main_queue(),^{[self openDeclaredResource:path completion:completion];});return;}
    [self openDescriptor:ODACPath(path)?_resources[path]:nil completion:completion];
}
- (void)attestDeclaredResource:(NSString *)path completion:(void (^)(NSDictionary *,NSError *))completion {
    if(!completion)return;
    if(!NSThread.isMainThread){dispatch_async(dispatch_get_main_queue(),^{[self attestDeclaredResource:path completion:completion];});return;}
    NSString *requested=[path copy];NSDictionary *entry=ODACPath(requested)?_resources[requested]:nil;
    [self openDescriptor:entry completion:^(int descriptor,NSError *failure){
        if(descriptor<0||failure){completion(nil,failure?:ODACError(@"ACCEPTED_RESOURCE_NOT_DECLARED"));return;}
        close(descriptor);
        completion(@{@"path":entry[@"path"],@"sha256":entry[@"sha256"],@"size":entry[@"size"],
            @"content_id":self->_content,@"save_scope":self->_scope,@"full_bundle_sha256":self->_fullSHA,@"project_sha256":self->_projectSHA},nil);
    }];
}
- (void)openDeclaredCPKInput:(NSString *)entryPath container:(NSString *)containerPath completion:(ODAcceptedCreatorResourceOpenReply)completion {
    if(!completion)return;
    if(!NSThread.isMainThread){dispatch_async(dispatch_get_main_queue(),^{[self openDeclaredCPKInput:entryPath container:containerPath completion:completion];});return;}
    NSDictionary *entry=ODACPath(entryPath)&&ODACPath(containerPath)?_cpkInputs[containerPath][entryPath]:nil;
    [self openDescriptor:entry completion:completion];
}
- (void)invalidate {
    if(!NSThread.isMainThread){dispatch_async(dispatch_get_main_queue(),^{[self invalidate];});return;}
    _invalidated=YES;++_authorizationGeneration;
}
@end
