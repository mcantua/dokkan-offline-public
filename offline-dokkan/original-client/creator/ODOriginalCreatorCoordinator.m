#import "ODOriginalCreatorCoordinator.h"
#import "../../mobile/ios/ODCreatorController.h"
#import "../../mobile/ios/ODCreatorSession.h"
#import "../duo/ODDuoOriginalScene.h"

typedef NS_ENUM(NSUInteger,ODCreatorPresentationState){ODCreatorIdle,ODCreatorOpening,ODCreatorPresented,ODCreatorClosing};
static NSError *ODCreatorPresentationError(NSInteger code){
    return [NSError errorWithDomain:@"OfflineDokkan.OriginalCreatorPresentation" code:code
        userInfo:@{NSLocalizedDescriptionKey:@"Creator presentation or confirmed save is unavailable. The existing game and editable project are preserved."}];
}

@implementation ODOriginalCreatorCoordinator {
    __weak id<ODOriginalCreatorServices> _services;
    id<ODOriginalCreatorServices> _activeServices;
    __weak UIWindow *_window;
    __weak UIViewController *_originalController;
    __weak UIView *_renderer;
    ODCreatorController *_creator;
    ODCreatorPresentationState _state;
    NSMutableArray<ODOriginalCreatorCloseCompletion> *_closeCompletions;
    BOOL _disconnecting,_closeRequested;
    BOOL _sceneLifecycleInstalled,_deferredOriginalResume;
    NSError *_lastCloseError;
    NSUInteger _closeGeneration;
}
- (instancetype)initWithServices:(id<ODOriginalCreatorServices>)services {
    if((self=[super init])){_services=services;_closeCompletions=[NSMutableArray array];}return self;
}
- (BOOL)creatorIsOpen{return _creator!=nil;}
- (NSError *)lastCloseError{return _lastCloseError;}
- (BOOL)installOriginalSceneLifecycleWithError:(NSError **)error {
    if(!NSThread.isMainThread||_sceneLifecycleInstalled){if(error)*error=ODCreatorPresentationError(9);return NO;}
    BOOL installed=ODDuoObserveOriginalSceneLifecycle(^BOOL(ODDuoSceneEvent event,UIWindow *window,UIViewController *controller,UIView *renderer){
        if(event==ODDuoSceneWillEnterForeground||event==ODDuoSceneDidBecomeActive){
            // Unrelated original-game modals/lifecycle remain source-owned.
            // Only our held editor/save may withhold the original resume.
            if(!self->_creator){self->_deferredOriginalResume=NO;return YES;}
            NSError *admissionError=nil;
            if(![self attachToOriginalWindow:window controller:controller renderer:renderer error:&admissionError]){self->_lastCloseError=admissionError;self->_deferredOriginalResume=YES;return NO;}
            self->_deferredOriginalResume=YES;return NO;
        }
        if(event==ODDuoSceneWillDisconnect)[self prepareForSceneDisconnectionWithCompletion:^(BOOL saved,NSError *failure){(void)saved;self->_lastCloseError=failure;}];
        return YES;
    },error);
    _sceneLifecycleInstalled=installed;return installed;
}
- (BOOL)admittedRelationship {
    Class root=NSClassFromString(@"RootViewController"),render=NSClassFromString(@"CCEAGLView");
    // UIKit may temporarily remove the presenting root's view from its window
    // during our own fullscreen modal. Admit only that already-owned modal.
    BOOL rendererInWindow=_renderer.window==_window;
    BOOL ownedFullscreen=_creator&&_creator.isViewLoaded&&
        _originalController.presentedViewController==_creator&&
        _creator.view.window==_window&&_renderer.window==nil;
    return root&&render&&_window&&_originalController&&_renderer&&
        [_originalController isKindOfClass:root]&&[_renderer isKindOfClass:render]&&
        _window.rootViewController==_originalController&&_originalController.view==_renderer&&
        (rendererInWindow||ownedFullscreen);
}
- (BOOL)activeScene {
    return !_disconnecting&&[self admittedRelationship]&&
        _window.windowScene.activationState==UISceneActivationStateForegroundActive;
}
- (BOOL)canResumeOriginalGameAfterFailedPresentation {
    return NSThread.isMainThread&&!_creator&&[self activeScene]&&
        !_originalController.presentedViewController&&!_originalController.transitionCoordinator;
}
- (BOOL)attachToOriginalWindow:(UIWindow *)window controller:(UIViewController *)controller
                     renderer:(UIView *)renderer error:(NSError **)error {
    if(!NSThread.isMainThread||!window.windowScene||!controller||!renderer||
       (_creator&&(_originalController!=controller||_renderer!=renderer))){if(error)*error=ODCreatorPresentationError(1);return NO;}
    UIWindow *priorWindow=_window;UIViewController *priorController=_originalController;UIView *priorRenderer=_renderer;
    _window=window;_originalController=controller;_renderer=renderer;
    if(![self admittedRelationship]){_window=priorWindow;_originalController=priorController;_renderer=priorRenderer;if(error)*error=ODCreatorPresentationError(2);return NO;}
    _disconnecting=NO;[self refreshCreatorAfterDisplayChange];return YES;
}
- (BOOL)presentCreatorFromUserActionWithError:(NSError **)error {
    id<ODOriginalCreatorServices> services=_services;
    ODCreatorSession *session=services.creatorSession;
    if(!NSThread.isMainThread||_state!=ODCreatorIdle||_creator||![self activeScene]||
       _originalController.presentedViewController||_originalController.transitionCoordinator||
       !services||![session isKindOfClass:ODCreatorSession.class]||![services creatorScopeIsCurrent]){
        if(error)*error=ODCreatorPresentationError(3);return NO;
    }
    NSError *hostError=nil;
    if(![services beginCreatorPresentationWithError:&hostError]){if(error)*error=ODCreatorPresentationError(4);return NO;}
    if(![services creatorScopeIsCurrent]||services.creatorSession!=session||![self activeScene]){
        // The issuer must complete one asynchronous recovery before reporting
        // the failed opening. Starting a second release here races that owner.
        if(error)*error=ODCreatorPresentationError(5);return NO;
    }
    _activeServices=services;_state=ODCreatorOpening;_lastCloseError=nil;
    // The active editor intentionally retains the coordinator through its close
    // completion so an unconfirmed save cannot destroy the binding/document.
    _creator=[[ODCreatorController alloc] initWithSession:session completion:^{[self didCloseAfterConfirmedSave];}];
    _creator.scopedTools=services.creatorTools;
    _creator.closePreparation=^(void (^completion)(NSError *)){
        if(![services creatorScopeIsCurrent]){completion(ODCreatorPresentationError(11));return;}
        [services prepareCreatorCloseWithCompletion:completion];
    };
    _creator.modalInPresentation=YES;
    ODCreatorController *presented=_creator;
    @try {
        [_originalController presentViewController:presented animated:YES completion:^{
            if(self->_creator!=presented||self->_state!=ODCreatorOpening)return;
            self->_state=ODCreatorPresented;
            [self refreshCreatorAfterDisplayChange];
            if(self->_closeRequested)[self beginConfirmedClose];
        }];
    }@catch(NSException *exception){
        (void)exception;
        // UIKit may attach the modal before throwing. Never discard an actual
        // attached editor or release the capabilities needed to flush/close it.
        BOOL attached=presented.presentingViewController!=nil||
            _originalController.presentedViewController==presented||
            (presented.isViewLoaded&&presented.view.window!=nil);
        if(attached){_state=ODCreatorPresented;_lastCloseError=ODCreatorPresentationError(6);}
        else{_creator=nil;_state=ODCreatorIdle;_activeServices=nil;}
        if(error)*error=ODCreatorPresentationError(6);return NO;
    }
    return YES;
}
- (void)completeCloseWaiters:(BOOL)saved error:(NSError *)error {
    NSArray<ODOriginalCreatorCloseCompletion> *callbacks=[_closeCompletions copy];[_closeCompletions removeAllObjects];
    for(ODOriginalCreatorCloseCompletion callback in callbacks)callback(saved,error);
}
- (void)didCloseAfterConfirmedSave {
    if(!NSThread.isMainThread)return;
    id<ODOriginalCreatorServices> services=_activeServices;
    BOOL active=[self activeScene]&&[services creatorScopeIsCurrent];
    _state=ODCreatorClosing;++_closeGeneration;
    [services endCreatorPresentationWithActiveScene:active completion:^(NSError *failure){
        if(failure){
            // Retain the confirmed document/session and both native contexts
            // until the host resolves release; never resume a different save.
            self->_lastCloseError=ODCreatorPresentationError(12);
            [self completeCloseWaiters:YES error:self->_lastCloseError];return;
        }
        BOOL nowActive=[self activeScene]&&[services creatorScopeIsCurrent];
        self->_creator=nil;self->_state=ODCreatorIdle;self->_closeRequested=NO;self->_activeServices=nil;
        NSError *resumeError=nil;
        if(nowActive&&self->_deferredOriginalResume){
            if(ODDuoResumeOriginalSceneGame(&resumeError))self->_deferredOriginalResume=NO;
            else resumeError=ODCreatorPresentationError(10);
        }
        self->_lastCloseError=resumeError;
        if(nowActive){[self->_renderer setNeedsLayout];[self->_window layoutIfNeeded];}
        [self completeCloseWaiters:YES error:resumeError];
    }];
}
- (void)beginConfirmedClose {
    if(!_creator||_state==ODCreatorClosing)return;
    if(_state==ODCreatorOpening&&_closeRequested)return;
    NSUInteger generation=++_closeGeneration;
    if(_state==ODCreatorOpening)_closeRequested=YES;
    else{_closeRequested=NO;_state=ODCreatorClosing;[_creator closeCreator];}
    // Existing controller reports success only after flushSave and dismissal.
    // Its own 30-second save deadline keeps the document open on failure.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,32*NSEC_PER_SEC),dispatch_get_main_queue(),^{
        if(!self->_creator||generation!=self->_closeGeneration)return;
        if(self->_state==ODCreatorClosing)self->_state=ODCreatorPresented;
        self->_closeRequested=NO;
        self->_lastCloseError=ODCreatorPresentationError(7);
        [self completeCloseWaiters:NO error:self->_lastCloseError];
    });
}
- (void)requestCloseWithCompletion:(ODOriginalCreatorCloseCompletion)completion {
    if(!NSThread.isMainThread){dispatch_async(dispatch_get_main_queue(),^{completion(NO,ODCreatorPresentationError(8));});return;}
    if(!_creator){completion(YES,nil);return;}
    [_closeCompletions addObject:[completion copy]];[self beginConfirmedClose];
}
- (void)retryConfirmedReturnWithCompletion:(ODOriginalCreatorCloseCompletion)completion {
    if(!NSThread.isMainThread||!_creator||_state!=ODCreatorClosing||_creator.presentingViewController){completion(NO,ODCreatorPresentationError(13));return;}
    [_closeCompletions addObject:[completion copy]];[self didCloseAfterConfirmedSave];
}
- (void)prepareForSceneDisconnectionWithCompletion:(ODOriginalCreatorCloseCompletion)completion {
    if(!NSThread.isMainThread){dispatch_async(dispatch_get_main_queue(),^{completion(NO,ODCreatorPresentationError(8));});return;}
    _disconnecting=YES;[self requestCloseWithCompletion:completion];
}
- (void)refreshCreatorAfterDisplayChange {
    if(!NSThread.isMainThread||!_creator.isViewLoaded)return;
    [_creator.view setNeedsLayout];[_creator.view layoutIfNeeded];
}
@end
