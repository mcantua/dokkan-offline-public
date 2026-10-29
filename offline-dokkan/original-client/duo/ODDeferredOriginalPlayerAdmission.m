#import "ODDeferredOriginalPlayerAdmission.h"
#import "../../adapter/ios/ODNativeCore.h"

static NSError *ODDeferredPlayerFailure(void){return [NSError errorWithDomain:@"OfflineDokkan.DeferredPlayer" code:1
    userInfo:@{NSLocalizedDescriptionKey:@"ORIGINAL_PLAYER_ADMISSION_UNAVAILABLE"}];}
static BOOL ODDeferredPlayerScope(NSString *scope){
    return [scope isKindOfClass:NSString.class]&&scope.length==64&&
        [scope rangeOfCharacterFromSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdef"] invertedSet]].location==NSNotFound;
}
@implementation ODDeferredOriginalPlayerAdmission {
    BOOL _attempted;
    NSDictionary *_preparedAdmission;
}
- (instancetype)initWithCore:(ODNativeCore *)core saveURL:(NSURL *)save masterURL:(NSURL *)master contentID:(NSString *)content {
    if(!(self=[super init]))return nil;
    if(!core||![core matchesSaveURL:save masterURL:master contentID:content])return nil;
    _core=core;_contentID=[content copy];return self;
}
- (NSDictionary *)preparedAdmission {return NSThread.isMainThread?_preparedAdmission:nil;}
- (BOOL)matchesCore:(ODNativeCore *)core contentID:(NSString *)content {
    return core==_core&&[content isEqual:_contentID];
}
- (void)prepareOnQueue:(dispatch_queue_t)queue completion:(void (^)(NSError *))completion {
    if(!completion)return;
    if(!NSThread.isMainThread||!queue||queue==dispatch_get_main_queue()){
        dispatch_async(dispatch_get_main_queue(),^{completion(ODDeferredPlayerFailure());});return;
    }
    if(_attempted){dispatch_async(dispatch_get_main_queue(),^{completion(ODDeferredPlayerFailure());});return;}
    _attempted=YES;
    dispatch_async(queue,^{
        NSDictionary *result=[self->_core prepareOriginalClientLocalPlayerOnPreparationQueueWithError:NULL];
        NSDictionary *admission=[result[@"admission"] isKindOfClass:NSDictionary.class]?result[@"admission"]:nil;
        NSDictionary *snapshot=[result[@"player_snapshot"] isKindOfClass:NSDictionary.class]?result[@"player_snapshot"]:nil;
        BOOL valid=admission&&snapshot&&[admission[@"profile_id"] isEqual:@"local-player"]&&
            [admission[@"content_id"] isEqual:self->_contentID]&&ODDeferredPlayerScope(admission[@"save_scope_sha256"])&&
            [snapshot[@"profile_id"] isEqual:@"local-player"]&&[snapshot[@"content_id"] isEqual:self->_contentID];
        NSDictionary *receipt=valid?[admission copy]:nil;
        dispatch_async(dispatch_get_main_queue(),^{
            self->_preparedAdmission=receipt;
            completion(receipt?nil:ODDeferredPlayerFailure());
        });
    });
}
@end
