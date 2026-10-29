#import "ODDuoCreatorQuickAction.h"

static NSString *const ODQuickActionType=@"org.offlinedokkan.integrated-creator";
@interface ODDuoCreatorQuickActionOwner : NSObject
@property(nonatomic,copy) BOOL (^current)(void);
@property(nonatomic,copy) ODDuoCreatorQuickActionAdmission admission;
@property(nonatomic,copy) ODDuoCreatorQuickActionInvocation invoke;
@property(nonatomic,copy) void (^report)(NSDictionary *);
@property(nonatomic,weak) UIWindow *window;
@property(nonatomic,weak) UIViewController *controller;
@property(nonatomic,weak) UIView *renderer;
@property(nonatomic) BOOL sourceActive;
@property(nonatomic) BOOL pending;
@property(nonatomic) BOOL running;
@property(nonatomic) BOOL drainScheduled;
@property(nonatomic) BOOL menuInstalled;
@property(nonatomic) NSUInteger invocationGeneration;
@property(nonatomic,copy) NSString *menuState;
@property(nonatomic,copy) NSDictionary *lastReport;
- (void)emit:(NSString *)outcome;
- (void)scheduleDrain;
- (void)installMenu;
@end
static ODDuoCreatorQuickActionOwner *ODQuickActionOwner;

@implementation ODDuoCreatorQuickActionOwner
- (void)emit:(NSString *)outcome {
    NSDictionary *state=@{@"entry":@"native-app-icon-quick-action",@"interimPlacement":@YES,
        @"menuInstalled":@(self.menuInstalled),@"menuState":self.menuState?:@"not-installed",
        @"pending":@(self.pending),@"presenting":@(self.running),@"outcome":outcome};
    if([self.lastReport isEqual:state])return;
    self.lastReport=state;self.report(state);
}
- (void)installMenu {
    if(self.menuInstalled||!self.current())return;
    UIApplication *app=UIApplication.sharedApplication;
    if(!app)return;
    NSMutableArray<UIApplicationShortcutItem *> *items=[app.shortcutItems mutableCopy]?:[NSMutableArray array];
    BOOL existing=NO;
    for(UIApplicationShortcutItem *item in items)if([item.type isEqual:ODQuickActionType])existing=YES;
    NSArray *staticItems=NSBundle.mainBundle.infoDictionary[@"UIApplicationShortcutItems"];
    NSUInteger staticCount=[staticItems isKindOfClass:NSArray.class]?staticItems.count:0;
    if([staticItems isKindOfClass:NSArray.class])for(id value in staticItems)
        if([value isKindOfClass:NSDictionary.class]&&[value[@"UIApplicationShortcutItemType"] isEqual:ODQuickActionType])existing=YES;
    if(!existing&&staticCount+items.count>=4){self.menuState=@"existing-shortcuts-fill-menu";[self emit:@"menu-registration-unavailable"];return;}
    if(!existing){
        UIApplicationShortcutIcon *icon=[UIApplicationShortcutIcon iconWithType:UIApplicationShortcutIconTypeCompose];
        [items addObject:[[UIApplicationShortcutItem alloc] initWithType:ODQuickActionType
            localizedTitle:@"Unit Creator" localizedSubtitle:@"Open the integrated editor" icon:icon userInfo:nil]];
        app.shortcutItems=items;
    }
    self.menuInstalled=YES;self.menuState=@"registered-not-device-verified";[self emit:@"native-menu-registered"];
}
- (void)scheduleDrain {
    if(!self.pending||self.running||self.drainScheduled)return;
    self.drainScheduled=YES;
    dispatch_async(dispatch_get_main_queue(),^{
        self.drainScheduled=NO;
        if(!self.pending||self.running)return;
        if(!self.current()){self.pending=NO;[self emit:@"native-context-unavailable"];return;}
        UIWindow *window=self.window;UIViewController *controller=self.controller;UIView *renderer=self.renderer;
        if(!window||!controller||!renderer){[self emit:@"waiting-for-original-scene"];return;}
        ODDuoCreatorQuickActionReadiness readiness=self.admission(window,controller,renderer);
        if(readiness==ODDuoCreatorEntryAlreadyOpen){self.pending=NO;[self emit:@"editor-already-open"];return;}
        if(readiness==ODDuoCreatorEntryRejected){self.pending=NO;[self emit:@"native-binding-unavailable"];return;}
        if(readiness!=ODDuoCreatorEntryReady||!self.sourceActive||window.hidden||!window.isKeyWindow||
           window.windowScene.activationState!=UISceneActivationStateForegroundActive||
           window.rootViewController!=controller||!controller.isViewLoaded||controller.view!=renderer||
           renderer.window!=window||controller.presentedViewController||controller.transitionCoordinator){
            [self emit:@"waiting-for-admitted-foreground"];return;
        }
        self.pending=NO;self.running=YES;NSUInteger generation=++self.invocationGeneration;
        [self emit:@"requesting-native-presentation"];
        self.invoke(^(NSError *failure){
            dispatch_async(dispatch_get_main_queue(),^{
                if(!self.running||generation!=self.invocationGeneration)return;
                self.running=NO;
                [self emit:failure?@"native-presentation-rejected":@"native-presentation-request-accepted"];
            });
        });
    });
}
@end

BOOL ODDuoConfigureCreatorQuickAction(BOOL (^current)(void),ODDuoCreatorQuickActionAdmission admission,
    ODDuoCreatorQuickActionInvocation invoke,void (^report)(NSDictionary *),NSError **error) {
    if(!NSThread.isMainThread||ODQuickActionOwner||!current||!admission||!invoke||!report){
        if(error)*error=[NSError errorWithDomain:@"OfflineDokkan.CreatorQuickAction" code:1
            userInfo:@{NSLocalizedDescriptionKey:@"The native Creator entry could not be configured. Existing game and editor data were preserved."}];
        return NO;
    }
    ODDuoCreatorQuickActionOwner *owner=[ODDuoCreatorQuickActionOwner new];
    owner.current=current;owner.admission=admission;owner.invoke=invoke;owner.report=report;
    ODQuickActionOwner=owner;[owner emit:@"configured"];return YES;
}
BOOL ODDuoHandleCreatorQuickAction(UIApplicationShortcutItem *item) {
    ODDuoCreatorQuickActionOwner *owner=ODQuickActionOwner;
    if(!NSThread.isMainThread||!owner||![item.type isEqual:ODQuickActionType])return NO;
    if(!owner.current()){owner.pending=NO;[owner emit:@"native-context-unavailable"];return NO;}
    if(owner.running||owner.pending)return YES;
    owner.pending=YES;[owner emit:@"queued-user-action"];[owner scheduleDrain];return YES;
}
void ODDuoUpdateCreatorQuickAction(UIWindow *window,UIViewController *controller,UIView *renderer,BOOL sourceActive) {
    ODDuoCreatorQuickActionOwner *owner=ODQuickActionOwner;
    if(!NSThread.isMainThread||!owner)return;
    if(!owner.current()){owner.pending=NO;[owner emit:@"native-context-unavailable"];return;}
    owner.window=window;owner.controller=controller;owner.renderer=renderer;owner.sourceActive=sourceActive;
    [owner installMenu];[owner scheduleDrain];
}
void ODDuoDisconnectCreatorQuickAction(UIWindow *window) {
    ODDuoCreatorQuickActionOwner *owner=ODQuickActionOwner;
    if(!NSThread.isMainThread||!owner||owner.window!=window)return;
    owner.window=nil;owner.controller=nil;owner.renderer=nil;owner.sourceActive=NO;
    if(owner.pending)[owner emit:@"waiting-for-original-scene"];
}
