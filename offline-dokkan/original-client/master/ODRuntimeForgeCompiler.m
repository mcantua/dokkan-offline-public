#import "ODRuntimeForgeCompiler.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import <CommonCrypto/CommonDigest.h>
#import <CoreFoundation/CoreFoundation.h>
#include <math.h>
static NSError *ODRuntimeError(NSString *code) {return [NSError errorWithDomain:@"OfflineDokkan.RuntimeForge" code:1 userInfo:@{NSLocalizedDescriptionKey:code}];}
static BOOL ODRFHex(id value){return [value isKindOfClass:NSString.class]&&[value length]==64&&[value rangeOfCharacterFromSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdef"] invertedSet]].location==NSNotFound;}
static BOOL ODRFInteger(id value){return [value isKindOfClass:NSNumber.class]&&CFGetTypeID((__bridge CFTypeRef)value)!=CFBooleanGetTypeID()&&isfinite([value doubleValue])&&[value doubleValue]==[value longLongValue]&&fabs([value doubleValue])<=9007199254740991.0;}
static NSString *ODRFHash(NSData *bytes){unsigned char digest[32];CC_SHA256(bytes.bytes,(CC_LONG)bytes.length,digest);NSMutableString *value=[NSMutableString stringWithCapacity:64];for(int index=0;index<32;index++)[value appendFormat:@"%02x",digest[index]];return value;}
@implementation ODRuntimeForgeCompiler { JSContext *_context; }
- (instancetype)initWithTrustedCreatorCore:(NSURL *)coreURL compilerScript:(NSURL *)scriptURL error:(NSError **)error {
    if(!(self=[super init]))return nil;
    NSData *core=coreURL.isFileURL?[NSData dataWithContentsOfURL:coreURL options:NSDataReadingMappedIfSafe error:nil]:nil;
    NSData *script=scriptURL.isFileURL?[NSData dataWithContentsOfURL:scriptURL options:NSDataReadingMappedIfSafe error:nil]:nil;
    if(!core.length||core.length>1024*1024||!script.length||script.length>64*1024){if(error)*error=ODRuntimeError(@"RUNTIME_COMPILER_SOURCE_INVALID");return nil;}
    NSString *creator=[[NSString alloc]initWithData:core encoding:NSUTF8StringEncoding],*worker=[[NSString alloc]initWithData:script encoding:NSUTF8StringEncoding];
    if(!creator||!worker){if(error)*error=ODRuntimeError(@"RUNTIME_COMPILER_SOURCE_INVALID");return nil;}
    _context=[JSContext new];
    // The evaluated source is fixed app-bundled code. Project fields are always
    // passed as values; no project content is interpolated into executable text.
    [_context evaluateScript:creator];if(!_context.exception)[_context evaluateScript:worker];
    if(_context.exception||![_context[@"ODRuntimeForge"] isObject]){if(error)*error=ODRuntimeError(@"RUNTIME_COMPILER_INIT_FAILED");return nil;}
    return self;
}
- (NSDictionary *)materializeAcceptedProject:(NSDictionary *)project runtimeIDs:(NSArray<NSNumber *> *)ids reservations:(NSArray<NSDictionary *> *)reservations floor:(NSInteger)floor error:(NSError **)error {
    NSDictionary *input=@{@"project":project?:@{},@"runtimeIds":ids?:@[],@"reservations":reservations?:@[],@"floor":@(floor)};
    NSData *bytes=[NSJSONSerialization isValidJSONObject:input]?[NSJSONSerialization dataWithJSONObject:input options:0 error:nil]:nil;
    if(!bytes||bytes.length>20*1024*1024||ids.count!=1||reservations.count>2000||floor<97000001||floor>98999001||floor%1000!=1){if(error)*error=ODRuntimeError(@"RUNTIME_COMPILER_ARGUMENT_INVALID");return nil;}
    _context.exception=nil;
    JSValue *value=[_context[@"ODRuntimeForge"] invokeMethod:@"compile" withArguments:@[input]];
    NSDictionary *result=[value toDictionary];
    if(_context.exception||![result isKindOfClass:NSDictionary.class]||![result[@"tables"] isKindOfClass:NSDictionary.class]||![NSJSONSerialization isValidJSONObject:result]){_context.exception=nil;if(error)*error=ODRuntimeError(@"RUNTIME_FORGE_REJECTED");return nil;}
    NSData *output=[NSJSONSerialization dataWithJSONObject:result options:0 error:nil];
    if(!output||output.length>32*1024*1024){if(error)*error=ODRuntimeError(@"RUNTIME_COMPILER_OUTPUT_LIMIT");return nil;}
    return result;
}
- (NSDictionary *)materializeAcceptedFullBundle:(NSData *)fullBundleBytes projectBytes:(NSData *)projectBytes definitionBytes:(NSData *)definitionBytes acceptedBinding:(NSDictionary *)acceptedBinding runtimeIDs:(NSArray<NSNumber *> *)ids reservations:(NSArray<NSDictionary *> *)reservations floor:(NSInteger)floor error:(NSError **)error {
    NSString *failure=@"RUNTIME_FULL_BUNDLE_ARGUMENT_INVALID";
    if(![fullBundleBytes isKindOfClass:NSData.class]||!fullBundleBytes.length||fullBundleBytes.length>64*1024*1024||
       ![projectBytes isKindOfClass:NSData.class]||!projectBytes.length||projectBytes.length>20*1024*1024||
       ![definitionBytes isKindOfClass:NSData.class]||!definitionBytes.length||definitionBytes.length>16*1024*1024||
       ![acceptedBinding isKindOfClass:NSDictionary.class]||![NSJSONSerialization isValidJSONObject:acceptedBinding]||
       ![ids isKindOfClass:NSArray.class]||ids.count<1||ids.count>5||![reservations isKindOfClass:NSArray.class]||reservations.count>2000||
       floor<97000001||floor>98999001||floor%1000!=1){if(error)*error=ODRuntimeError(failure);return nil;}
    for(NSUInteger index=0;index<ids.count;index++)if(!ODRFInteger(ids[index])||[ids[index] longLongValue]!=floor+1000*(NSInteger)index||[ids[index] longLongValue]>98999001){if(error)*error=ODRuntimeError(failure);return nil;}
    // NSData may be mutable at the call boundary. Hash and parse the same
    // immutable copies; no caller-supplied digest attests these bytes for us.
    NSData *packetBytes=[fullBundleBytes copy],*savedProject=[projectBytes copy],*savedDefinition=[definitionBytes copy];
    NSData *bindingBytes=[NSJSONSerialization dataWithJSONObject:acceptedBinding options:0 error:nil];
    NSDictionary *binding=bindingBytes?[NSJSONSerialization JSONObjectWithData:bindingBytes options:0 error:nil]:nil;
    NSDictionary *project=[NSJSONSerialization JSONObjectWithData:savedProject options:0 error:nil],*definition=[NSJSONSerialization JSONObjectWithData:savedDefinition options:0 error:nil],*bundle=[NSJSONSerialization JSONObjectWithData:packetBytes options:0 error:nil];
    NSSet *fields=[NSSet setWithArray:@[@"format",@"content_id",@"save_scope",@"definition_id",@"version",@"project_sha256",@"definition_sha256",@"instance_id",@"accepted"]];
    BOOL accepted=[binding[@"accepted"] isKindOfClass:NSNumber.class]&&CFGetTypeID((__bridge CFTypeRef)binding[@"accepted"])==CFBooleanGetTypeID()&&[binding[@"accepted"] boolValue];
    NSDictionary *descriptor=[definition isKindOfClass:NSDictionary.class]?definition[@"full_bundle"]:nil;
    NSString *projectSHA=ODRFHash(savedProject),*definitionSHA=ODRFHash(savedDefinition),*bundleSHA=ODRFHash(packetBytes);
    if(![project isKindOfClass:NSDictionary.class]||![definition isKindOfClass:NSDictionary.class]||![bundle isKindOfClass:NSDictionary.class]||
       ![binding isKindOfClass:NSDictionary.class]||![[NSSet setWithArray:binding.allKeys] isEqual:fields]||!accepted||
       ![binding[@"format"] isEqual:@"od-accepted-creator-project-v1"]||![descriptor isKindOfClass:NSDictionary.class]||
       !ODRFHex(binding[@"project_sha256"])||!ODRFHex(binding[@"definition_sha256"])||!ODRFHex(descriptor[@"full_bundle_sha256"])||
       ![projectSHA isEqual:binding[@"project_sha256"]]||![definitionSHA isEqual:binding[@"definition_sha256"]]||![bundleSHA isEqual:descriptor[@"full_bundle_sha256"]]){
        if(error)*error=ODRuntimeError(@"RUNTIME_FULL_BUNDLE_BINDING_MISMATCH");return nil;
    }
    NSDictionary *input=@{@"project":project,@"fullBundle":bundle,@"definition":definition,@"acceptedBinding":binding,@"runtimeIds":[ids copy],@"reservations":reservations,@"floor":@(floor),
        @"nativeByteHashesVerified":@YES,@"nativeByteHashes":@{@"project":projectSHA,@"definition":definitionSHA,@"fullBundle":bundleSHA}};
    NSData *arguments=[NSJSONSerialization isValidJSONObject:input]?[NSJSONSerialization dataWithJSONObject:input options:0 error:nil]:nil;
    if(!arguments||arguments.length>104*1024*1024){if(error)*error=ODRuntimeError(@"RUNTIME_FULL_BUNDLE_ARGUMENT_INVALID");return nil;}
    _context.exception=nil;
    JSValue *value=[_context[@"ODRuntimeForge"] invokeMethod:@"materializeAcceptedFullBundle" withArguments:@[input]];
    NSDictionary *result=[value toDictionary];
    if(_context.exception){
        NSSet *codes=[NSSet setWithArray:@[@"RUNTIME_FULL_BUNDLE_ARGUMENT_INVALID",@"RUNTIME_FULL_BUNDLE_ACCEPTED_BYTES_REQUIRED",@"RUNTIME_FULL_BUNDLE_BINDING_MISMATCH",@"RUNTIME_FULL_BUNDLE_FORGE_VALIDATION_FAILED",@"RUNTIME_FULL_BUNDLE_MATERIALIZATION_CHANGED",@"RUNTIME_FULL_BUNDLE_RESOURCE_ADMISSION_REQUIRED",@"RUNTIME_FULL_BUNDLE_REBASE_OVERLAP_UNSUPPORTED",@"RUNTIME_FULL_BUNDLE_REFERENCE_REWRITE_REQUIRED",@"RUNTIME_FULL_BUNDLE_AUTHORED_SLOT_UNSUPPORTED",@"RUNTIME_FULL_BUNDLE_REJECTED"]];
        NSString *code=[_context.exception[@"message"] toString];_context.exception=nil;
        if(error)*error=ODRuntimeError([codes containsObject:code]?code:@"RUNTIME_FULL_BUNDLE_REJECTED");return nil;
    }
    if(![result isKindOfClass:NSDictionary.class]||![result[@"tables"] isKindOfClass:NSDictionary.class]||![result[@"runtimeIds"] isEqual:ids]||
       ![result[@"members"] isKindOfClass:NSArray.class]||[result[@"members"] count]!=ids.count||![result[@"full_bundle_sha256"] isEqual:bundleSHA]||
       ![result[@"complete_member_materialization"] isEqual:@YES]||![result[@"encoded_references_complete"] isEqual:@YES]||
       ![result[@"encoded_reference_scope"] isEqual:@"private-owned-row-identities-only-v1"]||![result[@"resource_admission_complete"] isEqual:@NO]||
       ![result[@"original_client_attached"] isEqual:@NO]||![result[@"gameplay_ready"] isEqual:@NO]||![NSJSONSerialization isValidJSONObject:result]){
        if(error)*error=ODRuntimeError(@"RUNTIME_FULL_BUNDLE_REJECTED");return nil;
    }
    NSData *output=[NSJSONSerialization dataWithJSONObject:result options:0 error:nil];
    if(!output||output.length>32*1024*1024){if(error)*error=ODRuntimeError(@"RUNTIME_FULL_BUNDLE_OUTPUT_LIMIT");return nil;}
    return result;
}
@end
