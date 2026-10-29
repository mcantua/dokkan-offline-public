#import "DisplayDiagnostics.h"
#import <objc/message.h>
#import <sys/utsname.h>
#import <math.h>

static BOOL AIFiniteRect(CGRect frame) {
    return isfinite(frame.origin.x) && isfinite(frame.origin.y) && isfinite(frame.size.width) && isfinite(frame.size.height) && frame.size.width > 0 && frame.size.height > 0;
}
static BOOL AIObjectSignature(NSMethodSignature *signature, NSUInteger arguments) {
    return signature && signature.numberOfArguments == arguments && signature.methodReturnLength == sizeof(id) && signature.methodReturnType[0] == '@';
}
/// Public Apple iOS27.1 declarations, verified against Apple's DocC JSON (see display-evidence.md).
/// Signatures and geometry are checked before invoking a runtime that an older SDK cannot name.
static NSArray<NSValue *> *AIReservedFrames(UIView *view, NSString *kindName, BOOL *available) {
    SEL selector = NSSelectorFromString(@"reservedRegionsOfKind:");
    Class kinds = NSClassFromString(@"UIViewReservedRegionKind");
    Class regionClass = NSClassFromString(@"UIViewReservedRegion");
    SEL kindSelector = NSSelectorFromString(kindName);
    NSMethodSignature *query = [view methodSignatureForSelector:selector];
    NSMethodSignature *kindSignature = [kinds methodSignatureForSelector:kindSelector];
    if (!regionClass || !AIObjectSignature(query,3) || strcmp([query getArgumentTypeAtIndex:2],@encode(id)) != 0 || !AIObjectSignature(kindSignature,2)) return @[];
    @try {
        id kind = ((id (*)(id,SEL))objc_msgSend)(kinds,kindSelector);
        id regions = ((id (*)(id,SEL,id))objc_msgSend)(view,selector,kind);
        if (![regions isKindOfClass:NSArray.class] || [regions count] > 64) return @[];
        *available = YES;
        NSMutableArray *frames = [NSMutableArray array];
        for (id region in regions) {
            if (![region isKindOfClass:regionClass]) continue;
            SEL activeSelector = NSSelectorFromString(@"isActive");
            SEL frameSelector = NSSelectorFromString(@"frame");
            NSMethodSignature *activeSignature = [region methodSignatureForSelector:activeSelector];
            NSMethodSignature *frameSignature = [region methodSignatureForSelector:frameSelector];
            if (!activeSignature || activeSignature.numberOfArguments != 2 || activeSignature.methodReturnLength != sizeof(BOOL) || strcmp(activeSignature.methodReturnType,@encode(BOOL)) != 0 ||
                !frameSignature || frameSignature.numberOfArguments != 2 || frameSignature.methodReturnLength != sizeof(CGRect) || strcmp(frameSignature.methodReturnType,@encode(CGRect)) != 0) continue;
            BOOL active = NO; CGRect frame = CGRectNull;
            NSInvocation *readActive = [NSInvocation invocationWithMethodSignature:activeSignature];
            readActive.selector = activeSelector; [readActive invokeWithTarget:region]; [readActive getReturnValue:&active];
            if (!active) continue;
            NSInvocation *readFrame = [NSInvocation invocationWithMethodSignature:frameSignature];
            readFrame.selector = frameSelector; [readFrame invokeWithTarget:region]; [readFrame getReturnValue:&frame];
            if (AIFiniteRect(frame)) [frames addObject:[NSValue valueWithCGRect:frame]];
        }
        return frames;
    } @catch (__unused NSException *exception) { return @[]; }
}
@implementation AIDisplayDiagnostics
+ (NSDictionary *)rect:(CGRect)r {
    if (!isfinite(r.origin.x) || !isfinite(r.origin.y) || !isfinite(r.size.width) || !isfinite(r.size.height)) return @{};
    return @{@"x":@(r.origin.x),@"y":@(r.origin.y),@"width":@(r.size.width),@"height":@(r.size.height)};
}
+ (NSDictionary *)geometryForView:(UIView *)view {
    BOOL available = NO;
    NSArray *occlusions = AIReservedFrames(view,@"occlusionRegionKind",&available);
    NSArray *divisions = AIReservedFrames(view,@"divisionRegionKind",&available);
    return [self geometryForBounds:view.bounds safeArea:view.safeAreaInsets occlusions:occlusions divisions:divisions source:available ? @"Apple reserved-region runtime" : @"UIKit safe-area fallback (reserved-region API unavailable)"];
}
+ (NSDictionary *)geometryForBounds:(CGRect)bounds safeArea:(UIEdgeInsets)safe occlusions:(NSArray<NSValue *> *)occlusions divisions:(NSArray<NSValue *> *)divisions source:(NSString *)source {
    BOOL valid = AIFiniteRect(bounds) && isfinite(safe.top) && isfinite(safe.left) && isfinite(safe.bottom) && isfinite(safe.right) && safe.top >= 0 && safe.left >= 0 && safe.bottom >= 0 && safe.right >= 0 && safe.top+safe.bottom < bounds.size.height && safe.left+safe.right < bounds.size.width;
    NSMutableArray *keptOcclusions=[NSMutableArray array], *keptDivisions=[NSMutableArray array];
    NSMutableArray *safeFrames=[NSMutableArray array];
    if (valid) {
        for (NSUInteger kind=0;kind<2;++kind) for (NSValue *value in kind==0 ? occlusions : divisions) {
            if (![value isKindOfClass:NSValue.class] || strcmp(value.objCType,@encode(CGRect)) != 0) continue;
            CGRect original = value.CGRectValue;
            if (!AIFiniteRect(original) || original.size.width > bounds.size.width*2 || original.size.height > bounds.size.height*2 || (original.size.width>=bounds.size.width && original.size.height>=bounds.size.height)) continue;
            CGRect frame = CGRectIntersection(bounds,original);
            if (!AIFiniteRect(frame) || CGRectIsNull(frame) || CGRectIsEmpty(frame)) continue;
            [(kind==0 ? keptOcclusions : keptDivisions) addObject:[self rect:frame]];
            if (kind==0) [safeFrames addObject:[NSValue valueWithCGRect:frame]];
        }
    }
    UIEdgeInsets content = safe;
    for (NSValue *value in safeFrames) {
        CGRect frame=value.CGRectValue;
        if (!CGRectIntersectsRect(UIEdgeInsetsInsetRect(bounds,content),frame)) continue;
        CGFloat need[4]={CGRectGetMaxY(frame)-CGRectGetMinY(bounds),CGRectGetMaxX(frame)-CGRectGetMinX(bounds),CGRectGetMaxY(bounds)-CGRectGetMinY(frame),CGRectGetMaxX(bounds)-CGRectGetMinX(frame)};
        CGFloat previous[4]={content.top,content.left,content.bottom,content.right};
        NSUInteger chosen=0;CGFloat cost=CGFLOAT_MAX;
        for(NSUInteger edge=0;edge<4;++edge) if(need[edge]-previous[edge]<cost){chosen=edge;cost=need[edge]-previous[edge];}
        if(chosen==0)content.top=MAX(content.top,need[0]);if(chosen==1)content.left=MAX(content.left,need[1]);
        if(chosen==2)content.bottom=MAX(content.bottom,need[2]);if(chosen==3)content.right=MAX(content.right,need[3]);
    }
    CGRect safeRect = valid ? UIEdgeInsetsInsetRect(bounds,safe) : CGRectZero;
    CGFloat bottom=0,width=0;BOOL right=NO;
    for (NSValue *value in safeFrames) {
        CGRect frame=value.CGRectValue;
        if (CGRectIntersectsRect(safeRect,frame)) continue;
        BOOL atRight=safe.right>=56 && CGRectGetMinX(frame)>=CGRectGetMaxX(bounds)-safe.right-1;
        BOOL atLeft=safe.left>=56 && CGRectGetMaxX(frame)<=CGRectGetMinX(bounds)+safe.left+1;
        if ((atRight||atLeft) && CGRectGetMaxY(frame)>bottom) {bottom=CGRectGetMaxY(frame);right=atRight;width=atRight?safe.right:safe.left;}
    }
    NSDictionary *rail=@{};
    CGFloat top=MAX(bottom+20,CGRectGetMinY(bounds)+safe.top+20);
    if (valid && width>=56 && CGRectGetMaxY(bounds)-safe.bottom-top-16>=106) {
        CGRect frame=CGRectMake(right?CGRectGetMaxX(bounds)-width:CGRectGetMinX(bounds),top,width,106);
        BOOL intersects=NO;
        for (NSValue *occlusion in safeFrames) if(CGRectIntersectsRect(frame,occlusion.CGRectValue)) intersects=YES;
        if (!intersects) rail=@{@"side":right?@"right":@"left",@"frame":[self rect:frame],@"occlusionBottom":@(bottom)};
    }
    return @{@"valid":@(valid),@"source":source ?: @"unknown",@"bounds":[self rect:bounds],
        @"safeArea":@{@"top":@(valid?safe.top:0),@"left":@(valid?safe.left:0),@"bottom":@(valid?safe.bottom:0),@"right":@(valid?safe.right:0)},
        @"contentInsets":@{@"top":@(valid?content.top:0),@"left":@(valid?content.left:0),@"bottom":@(valid?content.bottom:0),@"right":@(valid?content.right:0)},
        @"occlusions":keptOcclusions,@"divisions":keptDivisions,@"rail":rail};
}
+ (NSDictionary *)reportForView:(UIView *)view geometry:(NSDictionary *)geometry layout:(NSDictionary *)layout state:(NSDictionary *)state {
    UIWindow *window=view.window;UIWindowScene *scene=window.windowScene;UIScreen *screen=scene.screen;
    struct utsname hardware;NSString *model=@"unavailable";if(uname(&hardware)==0) model=[NSString stringWithUTF8String:hardware.machine] ?: model;
    NSMutableDictionary *report=[@{@"schema":@1,@"purpose":@"User-requested display diagnostics; not a hardware-verification claim",@"deviceModel":UIDevice.currentDevice.model,@"modelCode":model,
        @"os":UIDevice.currentDevice.systemName,@"osVersion":UIDevice.currentDevice.systemVersion,
        @"windowBounds":[self rect:window.bounds],@"viewBounds":[self rect:view.bounds],@"sceneBounds":[self rect:scene.coordinateSpace.bounds],
        @"geometry":geometry ?: @{},@"layout":layout ?: @{},@"state":state ?: @{},
        @"reportedSDK":[NSBundle.mainBundle objectForInfoDictionaryKey:@"DTSDKName"] ?: @"unavailable",@"physicalTouchOrFoldVerified":@NO,
        @"privacy":@"No serial/UDID, account fields, file paths, app list, credentials, session or pairing data included."} mutableCopy];
    if(screen) {report[@"screenPoints"]=[self rect:screen.bounds];report[@"nativePixels"]=[self rect:screen.nativeBounds];report[@"screenScale"]=@(screen.scale);report[@"nativeScale"]=@(screen.nativeScale);}
    report[@"traitDisplayScale"]=@(view.traitCollection.displayScale);
    report[@"windowMatchesSceneBounds"]=@(window && scene && fabs(window.bounds.size.width-scene.coordinateSpace.bounds.size.width)<1 && fabs(window.bounds.size.height-scene.coordinateSpace.bounds.size.height)<1);
    // Diagnostic comparison only. Layout always follows the scene/view, never screen bounds.
    CGSize ws=window.bounds.size, ds=screen.bounds.size;
    BOOL direct=fabs(ws.width-ds.width)<1 && fabs(ws.height-ds.height)<1;
    BOOL rotated=fabs(ws.width-ds.height)<1 && fabs(ws.height-ds.width)<1;
    report[@"windowMatchesDisplayBounds"]=@(window && screen && (direct || rotated));
    NSURL *metadata=[NSBundle.mainBundle URLForResource:@"BuildMetadata" withExtension:@"json"];
    NSDictionary *build=metadata?[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:metadata] ?: NSData.data options:0 error:NULL]:nil;
    if([build isKindOfClass:NSDictionary.class]) {NSMutableDictionary *safe=[NSMutableDictionary new];for(NSString *key in @[@"compilation_sdk",@"requested_sdk_mark",@"unsigned",@"variant",@"source_commit",@"source_tree_sha256"]) if(build[key])safe[key]=build[key];report[@"build"]=safe;}
    return report;
}
@end

@interface AIDisplayReportController ()
@property (nonatomic, copy) NSDictionary *(^provider)(UIView *);
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, copy) NSString *reportText;
@end
@implementation AIDisplayReportController
- (instancetype)initWithProvider:(NSDictionary *(^)(UIView *))provider {if((self=[super init]))_provider=[provider copy];return self;}
- (void)viewDidLoad {
    [super viewDidLoad];self.title=@"Display report";self.view.backgroundColor=UIColor.systemBackgroundColor;
    self.textView=[UITextView new];self.textView.editable=NO;self.textView.font=[UIFont monospacedSystemFontOfSize:13 weight:UIFontWeightRegular];self.textView.adjustsFontForContentSizeCategory=YES;
    self.textView.translatesAutoresizingMaskIntoConstraints=NO;[self.view addSubview:self.textView];UILayoutGuide *safe=self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[[self.textView.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor],[self.textView.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor],[self.textView.topAnchor constraintEqualToAnchor:safe.topAnchor],[self.textView.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor]]];
    self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareReport)];self.navigationItem.rightBarButtonItem.accessibilityLabel=@"Share display report";
}
- (void)viewDidLayoutSubviews {[super viewDidLayoutSubviews];NSDictionary *report=self.provider?self.provider(self.view):@{};NSData *json=[NSJSONSerialization dataWithJSONObject:report options:NSJSONWritingPrettyPrinted|NSJSONWritingSortedKeys error:NULL];NSString *text=json?[[NSString alloc]initWithData:json encoding:NSUTF8StringEncoding]:@"Display report unavailable.";if(![text isEqual:self.reportText]){self.reportText=text;self.textView.text=text;}}
- (void)shareReport {UIActivityViewController *share=[[UIActivityViewController alloc]initWithActivityItems:@[self.reportText ?: @"Display report unavailable."] applicationActivities:nil];share.popoverPresentationController.barButtonItem=self.navigationItem.rightBarButtonItem;[self presentViewController:share animated:YES completion:nil];}
@end
