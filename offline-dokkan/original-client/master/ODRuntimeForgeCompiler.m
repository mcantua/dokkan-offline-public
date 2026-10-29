#import "ODRuntimeForgeCompiler.h"
#import <JavaScriptCore/JavaScriptCore.h>
static NSError *ODRuntimeError(NSString *code) {return [NSError errorWithDomain:@"OfflineDokkan.RuntimeForge" code:1 userInfo:@{NSLocalizedDescriptionKey:code}];}
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
@end
