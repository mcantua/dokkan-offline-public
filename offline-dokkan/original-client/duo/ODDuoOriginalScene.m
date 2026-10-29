#import "ODDuoOriginalScene.h"
#import "ODDuoEngineState.h"
#import "ODDuoCreatorQuickAction.h"
#import <QuartzCore/CAMetalLayer.h>
#import <objc/message.h>
#import <objc/runtime.h>
#include <math.h>
#include <string.h>

static ODDuoSceneDisplayHandler ODSceneDisplay;
static ODDuoSceneErrorHandler ODSceneError;
static ODDuoSceneLifecycleHandler ODSceneLifecycle;
static ODDuoOriginalAppControllerProvider ODAppControllerProvider;
static __weak ODDuoOriginalSceneDelegate *ODActiveScene;
/* The original engine outlives a disconnected UIScene. Keep only its forwarded
   background state across scene delegate replacement, not any user/save data. */
static BOOL ODSourceInBackground;
static ODDuoOriginalGamePauseLease *ODCreatorLease;

@interface ODDuoOriginalGamePauseLease ()
@property(nonatomic) ODDuoEngineState engineState;
@property(nonatomic, strong) id source;
@property(nonatomic, strong) UIViewController *controller;
@property(nonatomic, strong) UIView *renderer;
@property(nonatomic, weak) UIWindow *issuedWindow;
@property(nonatomic) BOOL faulted;
- (instancetype)initNative;
@end
@implementation ODDuoOriginalGamePauseLease
- (instancetype)initNative { return [super init]; }
@end
static BOOL ODSameEngine(ODDuoEngineState a,ODDuoEngineState b) {
    return a.image==b.image && a.application==b.application && a.director==b.director;
}

static NSError *ODSceneFailure(NSInteger code) {
    return [NSError errorWithDomain:@"OfflineDokkan.OriginalDuoScene" code:code
        userInfo:@{NSLocalizedDescriptionKey:@"Original-client scene/renderer admission failed; no replacement game interface was created."}];
}
static BOOL ODMethod(Class cls,SEL selector,const char *encoding) {
    Method method=class_getInstanceMethod(cls,selector);
    return method && !strcmp(method_getTypeEncoding(method),encoding);
}
static BOOL ODIvar(Class cls,const char *name,const char *encoding,ptrdiff_t offset) {
    Ivar ivar=class_getInstanceVariable(cls,name);
    return ivar && !strcmp(ivar_getTypeEncoding(ivar),encoding) && ivar_getOffset(ivar)==offset;
}

BOOL ODDuoSetOriginalAppControllerProvider(ODDuoOriginalAppControllerProvider provider,NSError **error) {
    if (!NSThread.isMainThread || !provider || ODAppControllerProvider || ODActiveScene) {
        if (error) *error=ODSceneFailure(10);
        return NO;
    }
    ODAppControllerProvider=[provider copy]; return YES;
}

@interface ODDuoOriginalSceneDelegate ()
- (void)renderer:(UIView *)renderer geometry:(ODDuoDisplaySnapshot *)snapshot;
- (BOOL)resumeDeferred;
- (ODDuoOriginalGamePauseLease *)beginCreatorWindow:(UIWindow *)window
    controller:(UIViewController *)controller renderer:(UIView *)renderer error:(NSError **)error;
- (BOOL)releaseCreator:(ODDuoOriginalGamePauseLease *)lease allowResume:(BOOL)allowResume error:(NSError **)error;
@end

ODDuoOriginalGamePauseLease *ODDuoBeginCreatorPause(UIWindow *window,UIViewController *controller,
                                                   UIView *renderer,NSError **error) {
    if (!NSThread.isMainThread || !ODActiveScene) {
        if (error) *error=ODSceneFailure(11); return nil;
    }
    return [ODActiveScene beginCreatorWindow:window controller:controller renderer:renderer error:error];
}
BOOL ODDuoEndCreatorPause(ODDuoOriginalGamePauseLease *lease,BOOL allowResume,NSError **error) {
    if (!NSThread.isMainThread || !lease || lease!=ODCreatorLease || lease.faulted) {
        if (error) *error=ODSceneFailure(12); return NO;
    }
    ODDuoEngineState state;
    if (!ODDuoInspectPinnedEngine(lease.source,&state) || !ODSameEngine(state,lease.engineState) ||
        !state.paused || !state.stopped) {
        if (error) *error=ODSceneFailure(13); return NO;
    }
    ODDuoOriginalSceneDelegate *scene=ODActiveScene;
    if (scene) return [scene releaseCreator:lease allowResume:allowResume error:error];
    /* Detached scene: the actual stopped source survives in its hidden legacy
       window. Future scene admission will own foreground delivery. */
    ODCreatorLease=nil; return YES;
}

BOOL ODDuoObserveOriginalSceneLifecycle(ODDuoSceneLifecycleHandler handler,NSError **error) {
    if (!NSThread.isMainThread || !handler || ODSceneLifecycle) {
        if (error) *error=ODSceneFailure(8);
        return NO;
    }
    ODSceneLifecycle=[handler copy]; return YES;
}
BOOL ODDuoResumeOriginalSceneGame(NSError **error) {
    if (!NSThread.isMainThread || ![ODActiveScene resumeDeferred]) {
        if (error) *error=ODSceneFailure(9);
        return NO;
    }
    return YES;
}

BOOL ODDuoConfigureOriginalSceneBridge(ODDuoSceneDisplayHandler displayHandler,
                                       ODDuoSceneErrorHandler errorHandler,NSError **error) {
    NSError *observerError=nil;
    if (!NSThread.isMainThread || !displayHandler || !errorHandler || ODSceneDisplay) goto rejected;
    Class app=NSClassFromString(@"AppController");
    Class root=NSClassFromString(@"RootViewController");
    Class renderer=NSClassFromString(@"CCEAGLView");
    if (!app || ![root isSubclassOfClass:UIViewController.class] ||
        ![renderer isSubclassOfClass:UIView.class] ||
        !ODIvar(app,"window","@\"UIWindow\"",8) ||
        !ODIvar(app,"_viewController","@\"RootViewController\"",16) ||
        !ODMethod(app,@selector(application:didFinishLaunchingWithOptions:),"B32@0:8@16@24") ||
        !ODMethod(app,@selector(applicationDidBecomeActive:),"v24@0:8@16") ||
        !ODMethod(app,@selector(applicationWillResignActive:),"v24@0:8@16") ||
        !ODMethod(app,@selector(applicationWillEnterForeground:),"v24@0:8@16") ||
        !ODMethod(app,@selector(applicationDidEnterBackground:),"v24@0:8@16") ||
        !ODMethod(root,@selector(shouldAutorotate),"B16@0:8") ||
        !ODMethod(root,@selector(supportedInterfaceOrientations),"Q16@0:8")) goto rejected;
    if (!ODDuoInstallOriginalRendererObservation(^(UIView *view,ODDuoDisplaySnapshot *snapshot) {
        [ODActiveScene renderer:view geometry:snapshot];
    },&observerError)) {
        if (error) *error=observerError;
        return NO;
    }
    ODSceneDisplay=[displayHandler copy]; ODSceneError=[errorHandler copy];
    return YES;
rejected:
    if (error) *error=ODSceneFailure(1);
    return NO;
}

@implementation ODDuoOriginalSceneDelegate {
    __weak UIView *_renderer;
    UIViewController *_originalController;
    UIWindow *_legacyWindow;
    id _originalDelegate;
    BOOL _updatingDrawable;
    BOOL _active;
    BOOL _background;
    BOOL _sourceBackground;
    BOOL _sourceActive;
    BOOL _foregroundDeferred;
    BOOL _activeDeferred;
    NSUInteger _displayGeneration;
}
- (void)reportFailure:(NSInteger)code {
    if (ODSceneError) ODSceneError(ODSceneFailure(code));
}
- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session
        options:(UISceneConnectionOptions *)options {
    (void)session; (void)options;
    if (!NSThread.isMainThread || !ODSceneDisplay ||
        ![scene isKindOfClass:UIWindowScene.class] || ODActiveScene) {
        [self reportFailure:2]; return;
    }
    id delegate=ODAppControllerProvider ? ODAppControllerProvider() : UIApplication.sharedApplication.delegate;
    Class app=NSClassFromString(@"AppController");
    if (![delegate isKindOfClass:app]) { [self reportFailure:3]; return; }
    /* Admission verified both exact ivars before UIApplicationMain. Only read
       them: the source was compiled with its own ownership conventions. */
    id sourceWindow=object_getIvar(delegate,class_getInstanceVariable(app,"window"));
    id controller=object_getIvar(delegate,class_getInstanceVariable(app,"_viewController"));
    if (![sourceWindow isKindOfClass:UIWindow.class] ||
        ![controller isKindOfClass:NSClassFromString(@"RootViewController")] ||
        ![controller isViewLoaded] || [controller parentViewController] ||
        [sourceWindow rootViewController]!=controller) { [self reportFailure:4]; return; }
    UIView *renderer=[controller view];
    if (![renderer isKindOfClass:NSClassFromString(@"CCEAGLView")] ||
        ![renderer.layer isKindOfClass:CAMetalLayer.class] ||
        !((BOOL(*)(id,SEL))objc_msgSend)(controller,NSSelectorFromString(@"shouldAutorotate")) ||
        [controller supportedInterfaceOrientations]!=26) {
        [self reportFailure:5]; return;
    }
    UIWindowScene *windowScene=(UIWindowScene *)scene;
    CGRect sceneBounds=windowScene.coordinateSpace.bounds;
    if (!isfinite(sceneBounds.size.width) || !isfinite(sceneBounds.size.height) ||
        sceneBounds.size.width<=0 || sceneBounds.size.height<=0) { [self reportFailure:6]; return; }
    UIWindow *window=[[UIWindow alloc] initWithWindowScene:windowScene];
    window.frame=sceneBounds;
    window.backgroundColor=((UIWindow *)sourceWindow).backgroundColor;
    _originalDelegate=delegate; _originalController=controller;
    _legacyWindow=sourceWindow; _renderer=renderer;
    _background=ODSourceInBackground; _sourceBackground=ODSourceInBackground;
    /* Preserve the legacy window for the original delegate's eventual dealloc.
       Its same root/view move into the real scene-owned window. */
    _legacyWindow.hidden=YES; _legacyWindow.rootViewController=nil;
    self.window=window; window.rootViewController=_originalController;
    ODActiveScene=self;
    [window makeKeyAndVisible];
    [renderer setNeedsLayout]; [window layoutIfNeeded];
    if(options.shortcutItem)ODDuoHandleCreatorQuickAction(options.shortcutItem);
}
- (void)renderer:(UIView *)renderer geometry:(ODDuoDisplaySnapshot *)snapshot {
    if (!NSThread.isMainThread || _updatingDrawable || renderer!=_renderer ||
        renderer.window!=self.window || self.window.rootViewController!=_originalController) return;
    CGRect bounds=renderer.bounds;
    CGFloat scale=renderer.traitCollection.displayScale;
    double width=bounds.size.width*scale, height=bounds.size.height*scale;
    if (!isfinite(width) || !isfinite(height) || scale<=0 || width<=0 || height<=0 ||
        ![renderer.layer isKindOfClass:CAMetalLayer.class]) { [self reportFailure:7]; return; }
    _updatingDrawable=YES;
    @try {
        /* Actual +layerClass binds CAMetalLayer. Match the backing drawable to
           the real UIKit view, without a transform, new design resolution,
           guessed C++ entry point or swapBuffers call (that source method is
           a no-op). UIKit's original view retains native touch handling. */
        BOOL scaleChanged=renderer.contentScaleFactor!=scale;
        if (scaleChanged) renderer.contentScaleFactor=scale;
        CAMetalLayer *layer=(CAMetalLayer *)renderer.layer;
        CGSize pixels=CGSizeMake(width,height);
        [CATransaction begin]; [CATransaction setDisableActions:YES];
        layer.contentsScale=scale;
        if (!CGSizeEqualToSize(layer.drawableSize,pixels)) layer.drawableSize=pixels;
        [CATransaction commit];
        /* The original layout stores bounds.size*contentScaleFactor in its
           own pixel-size ivar and runs its existing render tail on main. */
        if (scaleChanged) { [renderer setNeedsLayout]; [renderer layoutIfNeeded]; }
        if (ODSceneDisplay) ODSceneDisplay(_originalController,renderer,snapshot);
        ODDuoUpdateCreatorQuickAction(self.window,_originalController,renderer,
            _active&&_sourceActive&&!_sourceBackground&&!ODCreatorLease);
    } @finally { _updatingDrawable=NO; }
}
- (void)windowScene:(UIWindowScene *)windowScene
        didUpdateCoordinateSpace:(id<UICoordinateSpace>)previousCoordinateSpace
        interfaceOrientation:(UIInterfaceOrientation)previousInterfaceOrientation
        traitCollection:(UITraitCollection *)previousTraitCollection {
    (void)previousCoordinateSpace; (void)previousInterfaceOrientation;
    (void)previousTraitCollection;
    if (ODActiveScene!=self || windowScene!=self.window.windowScene) return;
    [_renderer setNeedsLayout]; [self.window layoutIfNeeded];
    NSUInteger generation=++_displayGeneration;
    __weak ODDuoOriginalSceneDelegate *weakSelf=self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(0.6*NSEC_PER_SEC)),dispatch_get_main_queue(),^{
        ODDuoOriginalSceneDelegate *current=weakSelf;
        if (!current || ODActiveScene!=current || generation!=current->_displayGeneration) return;
        [current->_renderer setNeedsLayout]; [current.window layoutIfNeeded];
    });
}
- (void)forward:(SEL)selector {
    if (_originalDelegate)
        ((void(*)(id,SEL,id))objc_msgSend)(_originalDelegate,selector,UIApplication.sharedApplication);
}
- (BOOL)emit:(ODDuoSceneEvent)event {
    UIView *renderer=_renderer;
    if (!ODSceneLifecycle || !self.window || !_originalController || !renderer) return YES;
    return ODSceneLifecycle(event,self.window,_originalController,renderer);
}
- (void)sceneDidBecomeActive:(UIScene *)scene {
    (void)scene;
    if (ODActiveScene!=self || _active) return;
    if (_background) [self sceneWillEnterForeground:scene];
    _active=YES;
    BOOL admitted=[self emit:ODDuoSceneDidBecomeActive];
    if (ODCreatorLease) admitted=NO;
    if (admitted && _sourceBackground && !_foregroundDeferred) {
        [self forward:@selector(applicationWillEnterForeground:)];
        _sourceBackground=NO; ODSourceInBackground=NO;
    }
    _activeDeferred=!admitted || _sourceBackground || _foregroundDeferred;
    if (!_activeDeferred) {
        [self forward:@selector(applicationDidBecomeActive:)]; _sourceActive=YES;
    }
    [_renderer setNeedsLayout]; [self.window layoutIfNeeded];
    ODDuoUpdateCreatorQuickAction(self.window,_originalController,_renderer,
        _active&&_sourceActive&&!_sourceBackground&&!ODCreatorLease);
}
- (void)windowScene:(UIWindowScene *)windowScene performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem
        completionHandler:(void (^)(BOOL succeeded))completionHandler {
    BOOL accepted=ODActiveScene==self&&windowScene==self.window.windowScene&&
        ODDuoHandleCreatorQuickAction(shortcutItem);
    completionHandler(accepted);
}
- (void)sceneWillResignActive:(UIScene *)scene {
    (void)scene;
    if (ODActiveScene!=self || !_active) return;
    _active=NO; [self emit:ODDuoSceneWillResignActive];
    if (_sourceActive) [self forward:@selector(applicationWillResignActive:)];
    _sourceActive=NO; _activeDeferred=NO;
    ODDuoUpdateCreatorQuickAction(self.window,_originalController,_renderer,NO);
}
- (void)sceneWillEnterForeground:(UIScene *)scene {
    (void)scene;
    if (ODActiveScene!=self || !_background) return;
    _background=NO;
    BOOL admitted=[self emit:ODDuoSceneWillEnterForeground];
    _foregroundDeferred=ODCreatorLease!=nil || !admitted;
    if (!_foregroundDeferred && _sourceBackground) {
        [self forward:@selector(applicationWillEnterForeground:)]; _sourceBackground=NO;
        ODSourceInBackground=NO;
    }
}
- (void)sceneDidEnterBackground:(UIScene *)scene {
    (void)scene;
    if (ODActiveScene!=self || _background) return;
    _background=YES; [self emit:ODDuoSceneDidEnterBackground];
    if (!_sourceBackground) [self forward:@selector(applicationDidEnterBackground:)];
    _sourceBackground=YES; _foregroundDeferred=NO; _activeDeferred=NO;
    ODSourceInBackground=YES;
}
- (BOOL)resumeDeferred {
    if (ODActiveScene!=self || !_active || _background || ODCreatorLease) return NO;
    if (!_foregroundDeferred && !_activeDeferred && !_sourceBackground && _sourceActive) return YES;
    if (!_foregroundDeferred && !_activeDeferred) return NO;
    if (_sourceBackground) {
        [self forward:@selector(applicationWillEnterForeground:)]; _sourceBackground=NO;
        ODSourceInBackground=NO;
    }
    _foregroundDeferred=NO;
    if (!_sourceActive) {
        [self forward:@selector(applicationDidBecomeActive:)]; _sourceActive=YES;
    }
    _activeDeferred=NO;
    [_renderer setNeedsLayout]; [self.window layoutIfNeeded];
    return YES;
}
- (ODDuoOriginalGamePauseLease *)beginCreatorWindow:(UIWindow *)window
        controller:(UIViewController *)controller renderer:(UIView *)renderer error:(NSError **)error {
    ODDuoEngineState before;
    if (ODActiveScene!=self || !_active || _background || ODCreatorLease ||
        window!=self.window || controller!=_originalController || renderer!=_renderer ||
        window.rootViewController!=controller || controller.view!=renderer ||
        renderer.window!=window || controller.presentedViewController ||
        window.windowScene.activationState!=UISceneActivationStateForegroundActive ||
        !ODDuoInspectPinnedEngine(_originalDelegate,&before) ||
        (_sourceBackground ? (!before.paused || !before.stopped) : (before.paused || before.stopped))) {
        if (error) *error=ODSceneFailure(14); return nil;
    }
    ODDuoOriginalGamePauseLease *lease=[[ODDuoOriginalGamePauseLease alloc] initNative];
    lease.source=_originalDelegate; lease.controller=controller; lease.renderer=renderer;
    lease.issuedWindow=window; lease.engineState=before;
    /* Retain first: even a failed postcondition must not implicitly permit a
       resume or a second editor against unknown source state. */
    ODCreatorLease=lease;
    if (!_sourceBackground) [self forward:@selector(applicationDidEnterBackground:)];
    _sourceBackground=YES; ODSourceInBackground=YES; _foregroundDeferred=YES;
    ODDuoEngineState after;
    if (!ODDuoInspectPinnedEngine(_originalDelegate,&after) || !ODSameEngine(before,after) ||
        !after.paused || !after.stopped) {
        lease.faulted=YES;
        if (error) *error=ODSceneFailure(15); return nil;
    }
    return lease;
}
- (BOOL)releaseCreator:(ODDuoOriginalGamePauseLease *)lease allowResume:(BOOL)allowResume error:(NSError **)error {
    if (lease!=ODCreatorLease || lease.source!=_originalDelegate ||
        lease.controller!=_originalController || lease.renderer!=_renderer ||
        self.window.rootViewController!=_originalController) {
        if (error) *error=ODSceneFailure(16); return NO;
    }
    BOOL resume=allowResume && _active && !_background;
    if (resume && (_originalController.presentedViewController || _renderer.window!=self.window)) {
        if (error) *error=ODSceneFailure(17); return NO;
    }
    ODCreatorLease=nil;
    if (resume) {
        if (![self resumeDeferred]) {
            ODCreatorLease=lease;
            if (error) *error=ODSceneFailure(18); return NO;
        }
        ODDuoEngineState resumed;
        if (!ODDuoInspectPinnedEngine(_originalDelegate,&resumed) ||
            !ODSameEngine(resumed,lease.engineState) || resumed.paused || resumed.stopped) {
            /* Hold on an unexpected source result; never treat it as a safe
               completed release. This requires controlled native recovery. */
            lease.faulted=YES; ODCreatorLease=lease;
            if (error) *error=ODSceneFailure(19); return NO;
        }
    } else if (!_background) {
        /* Valid close while inactive: allow the next admitted active callback
           to restore foreground. Explicit veto while currently active remains
           deferred until a later trusted resume or lifecycle transition. */
        _foregroundDeferred=_active; _activeDeferred=_active;
    }
    return YES;
}
- (void)sceneDidDisconnect:(UIScene *)scene {
    (void)scene;
    if (ODActiveScene!=self) return;
    if (_active) [self sceneWillResignActive:scene];
    if (!_background) [self sceneDidEnterBackground:scene];
    [self emit:ODDuoSceneWillDisconnect];
    ODDuoDisconnectCreatorQuickAction(self.window);
    self.window.hidden=YES; self.window.rootViewController=nil;
    _legacyWindow.rootViewController=_originalController;
    _legacyWindow.hidden=YES;
    ODActiveScene=nil; self.window=nil; _renderer=nil;
    _originalController=nil; _legacyWindow=nil; _originalDelegate=nil;
}
@end
