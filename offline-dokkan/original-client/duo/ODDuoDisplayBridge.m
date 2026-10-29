#import "ODDuoDisplayBridge.h"
#import <objc/message.h>
#import <objc/runtime.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>

static BOOL ODValidRect(CGRect r) {
    return isfinite(r.origin.x) && isfinite(r.origin.y) &&
           isfinite(r.size.width) && isfinite(r.size.height) &&
           !CGRectIsNull(r) && !CGRectIsEmpty(r);
}
static NSArray *ODRegions(UIView *view, NSString *kindName, BOOL *available, BOOL *complete) {
    *available=NO; *complete=NO;
    Class kinds=NSClassFromString(@"UIViewReservedRegionKind");
    SEL selector=NSSelectorFromString(@"reservedRegionsOfKind:");
    SEL kindSelector=NSSelectorFromString(kindName);
    if (![kinds respondsToSelector:kindSelector] || ![view respondsToSelector:selector]) return @[];
    *available=YES;
    @try {
        id kind=((id(*)(id,SEL))objc_msgSend)(kinds,kindSelector);
        id result=((id(*)(id,SEL,id))objc_msgSend)(view,selector,kind);
        *complete=[result isKindOfClass:NSArray.class];
        return *complete ? result : @[];
    } @catch (__unused NSException *error) { return @[]; }
}

@interface ODDuoDisplaySnapshot ()
@property(nonatomic, readwrite) CGRect bounds;
@property(nonatomic, readwrite) UIEdgeInsets safeArea;
@property(nonatomic, readwrite) CGFloat displayScale;
@property(nonatomic, readwrite) BOOL reservedRegionsAvailable;
@property(nonatomic, readwrite) BOOL reservedRegionReadComplete;
@property(nonatomic, readwrite, copy) NSArray<NSDictionary *> *regions;
@property(nonatomic, readwrite, copy) NSDictionary *sceneGeometry;
@end
@implementation ODDuoDisplaySnapshot
- (BOOL)fixedCanvasWithLogicalSize:(CGSize)size result:(ODDuoViewport *)result {
    if (!self.reservedRegionReadComplete) return NO;
    ODDuoRect cuts[64]; size_t count=0;
    for (NSDictionary *region in self.regions) {
        if (![region[@"kind"] isEqualToString:@"occlusion"] || ![region[@"active"] boolValue]) continue;
        if (count==64) return NO;
        CGRect r=[region[@"frame"] CGRectValue];
        cuts[count++]=(ODDuoRect){r.origin.x,r.origin.y,r.size.width,r.size.height};
    }
    CGRect b=self.bounds; UIEdgeInsets s=self.safeArea;
    return od_duo_viewport((ODDuoRect){b.origin.x,b.origin.y,b.size.width,b.size.height},
        (ODDuoInsets){s.top,s.left,s.bottom,s.right},cuts,count,size.width,size.height,result);
}
@end

@implementation ODDuoDisplayBridge {
    __weak UIView *_renderer;
    ODDuoDisplayHandler _handler;
    NSUInteger _transitionGeneration;
    BOOL _delivering;
}
- (instancetype)initWithRenderer:(UIView *)renderer handler:(ODDuoDisplayHandler)handler {
    NSParameterAssert(renderer); NSParameterAssert(handler);
    if ((self=[super init])) { _renderer=renderer; _handler=[handler copy]; }
    return self;
}
- (void)refresh {
    if (!NSThread.isMainThread || _delivering) return;
    UIView *view=_renderer;
    if (!view || !view.window || !ODValidRect(view.bounds)) return;
    ODDuoDisplaySnapshot *snapshot=[ODDuoDisplaySnapshot new];
    snapshot.bounds=view.bounds; snapshot.safeArea=view.safeAreaInsets;
    snapshot.displayScale=view.traitCollection.displayScale;
    snapshot.reservedRegionsAvailable=YES;
    snapshot.reservedRegionReadComplete=YES;
    NSMutableArray *regions=[NSMutableArray array];
    for (NSString *kind in @[@"occlusionRegionKind",@"divisionRegionKind"]) {
        BOOL occlusion=[kind isEqualToString:@"occlusionRegionKind"];
        BOOL available=NO, complete=NO;
        NSArray *list=ODRegions(view,kind,&available,&complete);
        snapshot.reservedRegionsAvailable &= available;
        snapshot.reservedRegionReadComplete &= complete;
        if (list.count>64) { snapshot.reservedRegionReadComplete=NO; continue; }
        for (id region in list) {
            @try {
                id active=[region valueForKey:@"active"], frame=[region valueForKey:@"frame"];
                if (![active respondsToSelector:@selector(boolValue)] ||
                    ![frame isKindOfClass:NSValue.class] ||
                    strcmp([frame objCType],@encode(CGRect))) {
                    snapshot.reservedRegionReadComplete=NO; continue;
                }
                CGRect r=[frame CGRectValue];
                if (!ODValidRect(r)) { snapshot.reservedRegionReadComplete=NO; continue; }
                [regions addObject:@{@"kind":occlusion?@"occlusion":@"division",
                    @"active":@([active boolValue]),@"frame":[NSValue valueWithCGRect:r]}];
            } @catch (__unused NSException *error) {
                snapshot.reservedRegionReadComplete=NO; continue;
            }
        }
    }
    snapshot.regions=regions;
    UIWindow *window=view.window; UIWindowScene *scene=window.windowScene;
    snapshot.sceneGeometry=scene ? @{@"sceneBounds":[NSValue valueWithCGRect:scene.coordinateSpace.bounds],
        @"windowBounds":[NSValue valueWithCGRect:window.bounds],
        @"rendererInWindow":[NSValue valueWithCGRect:[view convertRect:view.bounds toView:window]],
        @"fillsScene":@(CGRectEqualToRect(window.frame,scene.coordinateSpace.bounds))} : @{};
    _delivering=YES;
    @try { _handler(view,snapshot); }
    @finally { _delivering=NO; }
}
- (void)refreshAfterTransition:(id<UIViewControllerTransitionCoordinator>)coordinator {
    if (!NSThread.isMainThread) return;
    NSUInteger generation=++_transitionGeneration;
    __weak ODDuoDisplayBridge *weakSelf=self;
    [coordinator animateAlongsideTransition:^(__unused id<UIViewControllerTransitionCoordinatorContext> context) {
        [weakSelf refresh];
    } completion:^(__unused id<UIViewControllerTransitionCoordinatorContext> context) {
        ODDuoDisplayBridge *bridge=weakSelf;
        if (!bridge || generation!=bridge->_transitionGeneration) return;
        [bridge refresh];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(0.6*NSEC_PER_SEC)),dispatch_get_main_queue(),^{
            ODDuoDisplayBridge *settled=weakSelf;
            if (settled && generation==settled->_transitionGeneration) [settled refresh];
        });
    }];
}
@end

static IMP ODOriginalLayout;
static Method ODLayoutMethod;
static ODDuoDisplayHandler ODObserver;
static char ODBridgeKey;
static void ODObserveLayout(UIView *view,SEL selector) {
    ((void(*)(id,SEL))ODOriginalLayout)(view,selector);
    if (!ODObserver || !NSThread.isMainThread) return;
    ODDuoDisplayBridge *bridge=objc_getAssociatedObject(view,&ODBridgeKey);
    if (!bridge) {
        bridge=[[ODDuoDisplayBridge alloc] initWithRenderer:view handler:^(UIView *renderer,ODDuoDisplaySnapshot *snapshot) {
            if (ODObserver) ODObserver(renderer,snapshot);
        }];
        objc_setAssociatedObject(view,&ODBridgeKey,bridge,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [bridge refresh];
}
BOOL ODDuoInstallOriginalRendererObservation(ODDuoDisplayHandler handler,NSError **error) {
    if (!NSThread.isMainThread || !handler || ODLayoutMethod) goto rejected;
    Class cls=NSClassFromString(@"CCEAGLView");
    if (!cls || ![cls isSubclassOfClass:UIView.class]) goto rejected;
    unsigned count=0; Method *methods=class_copyMethodList(cls,&count); Method found=NULL;
    for (unsigned i=0;i<count;++i)
        if (method_getName(methods[i])==@selector(layoutSubviews)) found=methods[i];
    free(methods);
    if (!found || strcmp(method_getTypeEncoding(found),"v16@0:8")) goto rejected;
    IMP original=method_getImplementation(found);
    if (!original || original==(IMP)ODObserveLayout) goto rejected;
    ODOriginalLayout=original; ODObserver=[handler copy]; ODLayoutMethod=found;
    method_setImplementation(found,(IMP)ODObserveLayout);
    return YES;
rejected:
    if (error) *error=[NSError errorWithDomain:@"OfflineDokkan.DuoDisplay" code:1
        userInfo:@{NSLocalizedDescriptionKey:@"Renderer observer requires the verified CCEAGLView layout ABI and main-thread installation."}];
    return NO;
}
BOOL ODDuoRemoveOriginalRendererObservation(void) {
    if (!NSThread.isMainThread || !ODLayoutMethod ||
        method_getImplementation(ODLayoutMethod)!=(IMP)ODObserveLayout) return NO;
    method_setImplementation(ODLayoutMethod,ODOriginalLayout);
    ODObserver=nil; ODLayoutMethod=NULL;
    return YES;
}
